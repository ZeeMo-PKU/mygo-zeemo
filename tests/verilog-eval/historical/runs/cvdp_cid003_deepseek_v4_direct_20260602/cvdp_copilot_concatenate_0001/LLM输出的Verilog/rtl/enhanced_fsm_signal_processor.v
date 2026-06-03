module enhanced_fsm_signal_processor (
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire        i_enable,
    input  wire        i_clear,
    input  wire        i_ack,
    input  wire        i_fault,
    input  wire [4:0]  i_vector_1,
    input  wire [4:0]  i_vector_2,
    input  wire [4:0]  i_vector_3,
    input  wire [4:0]  i_vector_4,
    input  wire [4:0]  i_vector_5,
    input  wire [4:0]  i_vector_6,
    output reg         o_ready,
    output reg         o_error,
    output reg  [1:0]  o_fsm_status,
    output reg  [7:0]  o_vector_1,
    output reg  [7:0]  o_vector_2,
    output reg  [7:0]  o_vector_3,
    output reg  [7:0]  o_vector_4
);

    // FSM state encoding
    localparam IDLE    = 2'b00;
    localparam PROCESS = 2'b01;
    localparam READY   = 2'b10;
    localparam FAULT   = 2'b11;

    reg [1:0] state, next_state;

    // 32-bit concatenation bus
    wire [31:0] concat_bus = {i_vector_1, i_vector_2, i_vector_3,
                              i_vector_4, i_vector_5, i_vector_6, 2'b11};

    // Next-state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (i_fault)
                    next_state = FAULT;
                else if (i_enable)
                    next_state = PROCESS;
                else
                    next_state = IDLE;
            end
            PROCESS: begin
                if (i_fault)
                    next_state = FAULT;
                else
                    next_state = READY;
            end
            READY: begin
                if (i_fault)
                    next_state = FAULT;
                else if (i_ack)
                    next_state = IDLE;
                else
                    next_state = READY;
            end
            FAULT: begin
                if (i_clear && !i_fault)
                    next_state = IDLE;
                else
                    next_state = FAULT;
            end
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic (register update)
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state        <= IDLE;
            o_ready      <= 1'b0;
            o_error      <= 1'b0;
            o_fsm_status <= IDLE;
            o_vector_1   <= 8'd0;
            o_vector_2   <= 8'd0;
            o_vector_3   <= 8'd0;
            o_vector_4   <= 8'd0;
        end else begin
            state        <= next_state;
            o_fsm_status <= next_state;

            case (next_state)
                PROCESS: begin
                    o_ready    <= 1'b0;
                    o_error    <= 1'b0;
                    o_vector_1 <= concat_bus[31:24];
                    o_vector_2 <= concat_bus[23:16];
                    o_vector_3 <= concat_bus[15:8];
                    o_vector_4 <= concat_bus[7:0];
                end
                READY: begin
                    o_ready <= 1'b1;
                    o_error <= 1'b0;
                    // output vectors retain their values (no update)
                end
                FAULT: begin
                    o_ready    <= 1'b0;
                    o_error    <= 1'b1;
                    o_vector_1 <= 8'd0;
                    o_vector_2 <= 8'd0;
                    o_vector_3 <= 8'd0;
                    o_vector_4 <= 8'd0;
                end
                default: begin // IDLE
                    o_ready    <= 1'b0;
                    o_error    <= 1'b0;
                    o_vector_1 <= 8'd0;
                    o_vector_2 <= 8'd0;
                    o_vector_3 <= 8'd0;
                    o_vector_4 <= 8'd0;
                end
            endcase
        end
    end

endmodule
