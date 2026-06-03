// rtl/packet_controller.sv
module packet_controller (
    input  logic        clk,
    input  logic        rst,
    input  logic        rx_valid_i,
    input  logic [7:0]  rx_data_8_i,
    input  logic        tx_done_tick_i,
    output logic        tx_start_o,
    output logic [7:0]  tx_data_8_o
);

    // FSM state encoding
    localparam S_IDLE            = 3'd0,
               S_GOT_8_BYTES    = 3'd1,
               S_RECV_CHECKSUM  = 3'd2,
               S_BUILD_RESPONSE = 3'd3,
               S_SEND_FIRST_BYTE = 3'd4,
               S_RESPONSE_READY = 3'd5;

    // Internal registers
    logic [2:0] state, next_state;
    logic [2:0] byte_cnt;               // counts 0..7 for incoming bytes
    logic [7:0] byte_buf [0:7];         // stores the received 8 bytes
    logic [7:0] tx_bytes [0:4];         // response bytes: [H_high H_low Res_high Res_low Cksum]
    logic [2:0] tx_byte_idx;            // index of byte being transmitted (0..4)
    logic [7:0] sum_reg;                // registered checksum of incoming packet

    // Derived signals
    wire [15:0] header = {byte_buf[0], byte_buf[1]};
    wire        header_ok = (header == 16'hBACD);
    wire [7:0]  sum_all = byte_buf[0] + byte_buf[1] + byte_buf[2] + byte_buf[3]
                        + byte_buf[4] + byte_buf[5] + byte_buf[6] + byte_buf[7];

    // Extract incoming fields
    wire [15:0] num1   = {byte_buf[2], byte_buf[3]};
    wire [15:0] num2   = {byte_buf[4], byte_buf[5]};
    wire [7:0]  opcode = byte_buf[6];

    // Compute result based on opcode
    wire [15:0] result =
        (opcode == 8'h00) ? (num1 + num2) :
        (opcode == 8'h01) ? (num1 - num2) :
        16'h0000;

    // Outgoing packet building
    wire [7:0] header_h = 8'hAB;
    wire [7:0] header_l = 8'hCD;
    wire [7:0] result_h = result[15:8];
    wire [7:0] result_l = result[7:0];
    wire [7:0] checksum_out = 8'd0 - (header_h + header_l + result_h + result_l); // 2's complement

    //----------------------------------------------------------------------
    // Combinational state transitions
    //----------------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE: begin
                // After receiving the 8th byte, move to checking
                if (byte_cnt == 3'd7 && rx_valid_i)
                    next_state = S_GOT_8_BYTES;
            end
            S_GOT_8_BYTES: begin
                if (header_ok)
                    next_state = S_RECV_CHECKSUM;
                else
                    next_state = S_IDLE;
            end
            S_RECV_CHECKSUM: begin
                if (sum_reg == 8'h00)
                    next_state = S_BUILD_RESPONSE;
                else
                    next_state = S_IDLE;
            end
            S_BUILD_RESPONSE: begin
                next_state = S_SEND_FIRST_BYTE;
            end
            S_SEND_FIRST_BYTE: begin
                if (tx_done_tick_i)
                    next_state = S_RESPONSE_READY;
            end
            S_RESPONSE_READY: begin
                if (tx_done_tick_i && tx_byte_idx == 3'd4)
                    next_state = S_IDLE;
                // else stay in S_RESPONSE_READY
            end
            default: next_state = S_IDLE;
        endcase
    end

    //----------------------------------------------------------------------
    // Sequential logic (state, counters, buffers)
    //----------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= S_IDLE;
            byte_cnt   <= 3'd0;
            sum_reg    <= 8'd0;
            tx_byte_idx <= 3'd0;
            // Optionally clear arrays (not strictly necessary but clean)
            byte_buf   <= '{default:8'd0};
            tx_bytes   <= '{default:8'd0};
        end else begin
            state <= next_state;

            // byte_cnt and byte_buf management
            if (state == S_IDLE) begin
                if (rx_valid_i) begin
                    byte_buf[byte_cnt] <= rx_data_8_i;
                    byte_cnt <= byte_cnt + 1;
                end
            end else if (state != S_IDLE && next_state == S_IDLE) begin
                byte_cnt <= 3'd0;
            end

            // sum_reg update
            if (state == S_GOT_8_BYTES && header_ok)
                sum_reg <= sum_all;

            // Build response packet (one cycle before transmission)
            if (state == S_BUILD_RESPONSE) begin
                tx_bytes[0] <= header_h;
                tx_bytes[1] <= header_l;
                tx_bytes[2] <= result_h;
                tx_bytes[3] <= result_l;
                tx_bytes[4] <= checksum_out;
                tx_byte_idx <= 3'd0;
            end

            // Transmission byte index control
            if (state == S_SEND_FIRST_BYTE) begin
                if (tx_done_tick_i)
                    tx_byte_idx <= 3'd1;
            end else if (state == S_RESPONSE_READY) begin
                if (tx_done_tick_i) begin
                    if (tx_byte_idx < 3'd4)
                        tx_byte_idx <= tx_byte_idx + 1;
                    else
                        tx_byte_idx <= 3'd5; // sent last byte, go to IDLE
                end
            end
        end
    end

    //----------------------------------------------------------------------
    // Output assignments
    //----------------------------------------------------------------------
    always_comb begin
        tx_start_o = 1'b0;
        tx_data_8_o = 8'd0;

        if (state == S_SEND_FIRST_BYTE) begin
            tx_start_o = 1'b1;
            tx_data_8_o = tx_bytes[0];
        end else if (state == S_RESPONSE_READY && tx_byte_idx < 3'd5) begin
            tx_start_o = 1'b1;
            tx_data_8_o = tx_bytes[tx_byte_idx];
        end
    end

endmodule
