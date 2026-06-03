// rtl/sync_serial_communication_top.sv

module tx_block (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [63:0] data_in,
    input  logic [2:0]  sel,
    output logic        serial_out,
    output logic        done,
    output logic        serial_clk
);
    typedef enum logic [1:0] {IDLE, SHIFT, DONE} state_t;
    state_t state, next_state;
    logic [63:0] shift_reg;
    logic [6:0]  bit_cnt;

    // State machine
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state      <= IDLE;
            shift_reg  <= '0;
            bit_cnt    <= 0;
            done       <= 0;
            serial_out <= 0;
        end else begin
            done <= 0; // default
            case (state)
                IDLE: begin
                    serial_out <= 0;
                    if (sel != 0) begin
                        shift_reg <= data_in;
                        case (sel)
                            3'h1: bit_cnt <= 8;
                            3'h2: bit_cnt <= 16;
                            3'h3: bit_cnt <= 32;
                            3'h4: bit_cnt <= 64;
                            default: bit_cnt <= 0;
                        endcase
                        state <= SHIFT;
                    end
                end

                SHIFT: begin
                    serial_out <= shift_reg[0]; // LSB first
                    shift_reg  <= shift_reg >> 1;
                    if (bit_cnt == 1)
                        state <= DONE;
                    else
                        bit_cnt <= bit_cnt - 1;
                end

                DONE: begin
                    done <= 1;
                    // wait for reset
                end
            endcase
        end
    end

    // Gated serial clock, inverted from clk during active transmission
    assign serial_clk = (state == SHIFT) ? ~clk : 1'b0;
endmodule

module rx_block (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        data_in,
    input  logic [2:0]  sel,
    input  logic        serial_clk,
    output logic [63:0] data_out,
    output logic        done
);
    typedef enum logic {IDLE, RECEIVE, DONE} rx_state_t;
    rx_state_t rx_state;
    logic [63:0] shift_reg;
    integer      bit_pos; // used as index

    // Derive bit width from sel (combinational, stable during reception)
    logic [6:0] width;
    always_comb begin
        case (sel)
            3'h1:   width = 8;
            3'h2:   width = 16;
            3'h3:   width = 32;
            3'h4:   width = 64;
            default: width = 0;
        endcase
    end

    // Double synchronized rising-edge detector for 'done' in clk domain
    logic rx_done_sync1, rx_done_sync2, rx_done_sync2_prev;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_done_sync1      <= 1'b0;
            rx_done_sync2      <= 1'b0;
            rx_done_sync2_prev <= 1'b0;
            done               <= 1'b0;
        end else begin
            rx_done_sync1      <= (rx_state == DONE);
            rx_done_sync2      <= rx_done_sync1;
            rx_done_sync2_prev <= rx_done_sync2;
            done               <= rx_done_sync2 && !rx_done_sync2_prev;
        end
    end

    // Shift logic clocked by serial_clk
    always_ff @(posedge serial_clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_state  <= IDLE;
            shift_reg <= '0;
            bit_pos   <= 0;
        end else begin
            case (rx_state)
                IDLE: begin
                    if (sel != 0) begin
                        rx_state      <= RECEIVE;
                        bit_pos       <= 1;         // next capture at index 1
                        shift_reg[0]  <= data_in;   // capture first bit (LSB)
                    end
                end

                RECEIVE: begin
                    shift_reg[bit_pos] <= data_in;
                    if (bit_pos == (width - 1))
                        rx_state <= DONE;
                    else
                        bit_pos <= bit_pos + 1;
                end

                DONE: begin
                    // stay until reset
                end
            endcase
        end
    end

    // Reconstruct parallel output
    assign data_out = (sel == 3'h1) ? {56'h0, shift_reg[7:0]}  :
                      (sel == 3'h2) ? {48'h0, shift_reg[15:0]} :
                      (sel == 3'h3) ? {32'h0, shift_reg[31:0]} :
                      (sel == 3'h4) ? shift_reg                 :
                                       64'h0;
endmodule

module sync_serial_communication_top (
    input  logic        clk,
    input  logic        reset_n,
    input  logic [63:0] data_in,
    input  logic [2:0]  sel,
    output logic [63:0] data_out,
    output logic        done
);
    logic serial_data;
    logic serial_clk;

    tx_block u_tx (
        .clk        (clk),
        .reset_n    (reset_n),
        .data_in    (data_in),
        .sel        (sel),
        .serial_out (serial_data),
        .done       (),                // not used at top level
        .serial_clk (serial_clk)
    );

    rx_block u_rx (
        .clk        (clk),
        .reset_n    (reset_n),
        .data_in    (serial_data),
        .sel        (sel),
        .serial_clk (serial_clk),
        .data_out   (data_out),
        .done       (done)
    );
endmodule
