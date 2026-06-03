`module cvdp_prbs_gen #(
    parameter int CHECK_MODE = 0,   // 0: generator, 1: checker
    parameter int POLY_LENGTH = 31, // number of shift register stages
    parameter int POLY_TAP = 3,     // tap position (1-indexed) to XOR with POLY_LENGTH
    parameter int WIDTH = 16        // width of data bus
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic [WIDTH-1:0]    data_in,
    output logic [WIDTH-1:0]    data_out
);

    // Internal LFSR state
    logic [POLY_LENGTH-1:0] lfsr;

    always_ff @(posedge clk) begin
        if (rst) begin
            lfsr <= '1;
            data_out <= '1;
        end else begin
            // Temporary variables for combinational update within the clock cycle
            logic [POLY_LENGTH-1:0] lfsr_next = lfsr;
            logic [WIDTH-1:0]       data_out_next;

            for (int i = 0; i < WIDTH; i++) begin
                // Generate feedback bit: XOR of MSB (index POLY_LENGTH-1) and tap (index POLY_TAP-1)
                logic feedback = lfsr_next[POLY_LENGTH-1] ^ lfsr_next[POLY_TAP-1];

                if (CHECK_MODE == 0) begin
                    // Generator mode: output the LSB (bit being shifted out)
                    data_out_next[i] = lfsr_next[0];
                end else begin
                    // Checker mode: compute error bit (XOR of input data and expected bit)
                    data_out_next[i] = data_in[i] ^ lfsr_next[0];
                end

                // Shift right: insert feedback at MSB, shift others down
                lfsr_next = {feedback, lfsr_next[POLY_LENGTH-1:1]};
            end

            lfsr <= lfsr_next;
            data_out <= data_out_next;
        end
    end

endmodule`