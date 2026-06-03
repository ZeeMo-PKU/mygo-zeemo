// perfect_squares_generator.sv
// Module that generates sequential perfect squares with saturation.
// After reset, output starts at 1 and then generates 4, 9, 16, ...
// If the next square exceeds 32'hFFFFFFFF, the output saturates at that maximum.

module perfect_squares_generator (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] sqr_o
);

    // Internal counter (base number). Starts at 1 after reset.
    logic [31:0] b;
    // Saturation flag to prevent wrap-around after overflow.
    logic        saturated;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            b         <= 32'd1;
            sqr_o     <= 32'd1;
            saturated <= 1'b0;
        end else begin
            if (!saturated) begin
                // Compute the square of (b + 1) to determine the next output.
                automatic logic [63:0] next_square = 64'(b + 32'd1) * 64'(b + 32'd1);
                if (next_square > 64'hFFFFFFFF) begin
                    sqr_o     <= 32'hFFFFFFFF;
                    saturated <= 1'b1;
                end else begin
                    sqr_o <= next_square[31:0];
                    b     <= b + 32'd1;
                end
            end else begin
                // Once saturated, keep output at maximum.
                sqr_o <= 32'hFFFFFFFF;
            end
        end
    end

endmodule
