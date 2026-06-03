// APB Write Controller with Timeout and Event-Based Triggering
// Supports three prioritized events: A (highest), B, C (lowest).

module apb_controller (
    input  logic        clk,
    input  logic        reset_n,
    
    // Event inputs
    input  logic        select_a_i,
    input  logic        select_b_i,
    input  logic        select_c_i,
    input  logic [31:0] addr_a_i,
    input  logic [31:0] data_a_i,
    input  logic [31:0] addr_b_i,
    input  logic [31:0] data_b_i,
    input  logic [31:0] addr_c_i,
    input  logic [31:0] data_c_i,
    
    // APB slave interface
    input  logic        apb_pready_i,
    output logic        apb_psel_o,
    output logic        apb_penable_o,
    output logic        apb_pwrite_o,
    output logic [31:0] apb_paddr_o,
    output logic [31:0] apb_pwdata_o
);

    // FSM state encoding
    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_t;
    
    state_t state;
    
    // Internal storage for selected address and data
    logic [31:0] saved_addr;
    logic [31:0] saved_data;
    
    // Timeout counter (counts cycles in ACCESS with pready low, max 14 before timeout)
    logic [3:0] timeout_cnt;
    
    // Sequential logic: state machine, output registers, timeout counter
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            saved_addr <= 32'h0;
            saved_data <= 32'h0;
            timeout_cnt <= 4'b0;
            apb_psel_o <= 1'b0;
            apb_penable_o <= 1'b0;
            apb_pwrite_o <= 1'b0;
            apb_paddr_o <= 32'h0;
            apb_pwdata_o <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    // Capture highest-priority event if any
                    if (select_a_i) begin
                        saved_addr <= addr_a_i;
                        saved_data <= data_a_i;
                        state <= SETUP;
                    end else if (select_b_i) begin
                        saved_addr <= addr_b_i;
                        saved_data <= data_b_i;
                        state <= SETUP;
                    end else if (select_c_i) begin
                        saved_addr <= addr_c_i;
                        saved_data <= data_c_i;
                        state <= SETUP;
                    end else begin
                        state <= IDLE;
                    end
                    
                    // In IDLE all APB outputs are inactive
                    apb_psel_o <= 1'b0;
                    apb_penable_o <= 1'b0;
                    apb_pwrite_o <= 1'b0;
                    apb_paddr_o <= 32'h0;
                    apb_pwdata_o <= 32'h0;
                    timeout_cnt <= 4'b0;
                end
                
                SETUP: begin
                    // Assert PSEL, set write, drive address and data, PENABLE remains low
                    apb_psel_o <= 1'b1;
                    apb_penable_o <= 1'b0;
                    apb_pwrite_o <= 1'b1;
                    apb_paddr_o <= saved_addr;
                    apb_pwdata_o <= saved_data;
                    state <= ACCESS;
                    timeout_cnt <= 4'b0;
                end
                
                ACCESS: begin
                    // Maintain all outputs, assert PENABLE
                    apb_psel_o <= 1'b1;
                    apb_penable_o <= 1'b1;
                    apb_pwrite_o <= 1'b1;
                    apb_paddr_o <= saved_addr;
                    apb_pwdata_o <= saved_data;
                    
                    if (apb_pready_i) begin
                        // Transaction completed successfully
                        state <= IDLE;
                        timeout_cnt <= 4'b0;
                    end else begin
                        // Check timeout: after 15 cycles in ACCESS (cnt reaches 14) without ready
                        if (timeout_cnt == 4'd14) begin
                            // Timeout: abort transaction, next cycle goes to IDLE with outputs 0
                            state <= IDLE;
                            timeout_cnt <= 4'b0;
                        end else begin
                            // Continue waiting, increment timeout counter
                            timeout_cnt <= timeout_cnt + 1;
                            state <= ACCESS;
                        end
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
