// Complex number multiplier with one-cycle latency and asynchronous active-low reset.
// Inputs: 16-bit signed real and imaginary parts for two complex numbers.
// Outputs: 32-bit signed real and imaginary parts of the product.
// Latency: 1 clock cycle.
module complex_multiplier (
    input logic                   clk,
    input logic                   arst_n,
    input logic signed [15:0]     a_real,
    input logic signed [15:0]     a_imag,
    input logic signed [15:0]     b_real,
    input logic signed [15:0]     b_imag,
    output logic signed [31:0]    result_real,
    output logic signed [31:0]    result_imag
);

    // Internal 32-bit signed products
    logic signed [31:0] ac, bd, ad, bc;

    // 33-bit internal sums to avoid overflow before truncation
    logic signed [32:0] real_sum, imag_sum;

    // Combinational multiplication and sum/difference
    assign ac = a_real * b_real;
    assign bd = a_imag * b_imag;
    assign ad = a_real * b_imag;
    assign bc = a_imag * b_real;

    assign real_sum = ac - bd;          // (a*c) - (b*d)
    assign imag_sum = ad + bc;          // (a*d) + (b*c)

    // Output registers with asynchronous active-low reset
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            result_real <= 32'sd0;
            result_imag <= 32'sd0;
        end else begin
            // Truncate the 33-bit full-precision sums to 32-bit outputs
            result_real <= real_sum[31:0];
            result_imag <= imag_sum[31:0];
        end
    end

endmodule
