module palindrome_detect #(
    parameter N = 3
) (
    input  logic clk,
    input  logic reset,
    input  logic bit_stream,
    output logic palindrome_detected
);
    // Shift register to hold the last N bits
    logic [N-1:0] shift_reg;

    // Counter to track how many valid bits have been shifted in
    logic [$clog2(N+1)-1:0] bit_count;

    always_ff @(posedge clk) begin
        if (reset) begin
            shift_reg <= '0;
            bit_count <= '0;
        end else begin
            // Shift in the new bit on every clock
            shift_reg <= {shift_reg[N-2:0], bit_stream};

            // Increment bit counter until N, then hold
            if (bit_count < N)
                bit_count <= bit_count + 1;
        end
    end

    // Combinational logic to check palindrome condition
    logic all_pairs_equal;
    always_comb begin
        all_pairs_equal = 1'b1;
        for (int i = 0; i < N/2; i++) begin
            if (shift_reg[i] != shift_reg[N-1-i])
                all_pairs_equal = 1'b0;
        end
    end

    // Output is only valid after N bits have been received
    assign palindrome_detected = (bit_count == N) && all_pairs_equal;

endmodule
