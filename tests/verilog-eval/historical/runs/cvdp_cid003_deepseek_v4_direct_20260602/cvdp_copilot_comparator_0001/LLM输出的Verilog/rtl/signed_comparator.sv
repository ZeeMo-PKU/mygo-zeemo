module signed_unsigned_comparator #(
    parameter WIDTH = 5
) (
    input  logic [WIDTH-1:0] i_A,
    input  logic [WIDTH-1:0] i_B,
    input  logic             i_enable,
    input  logic             i_mode,
    output logic             o_greater,
    output logic             o_less,
    output logic             o_equal
);

    logic a_gt, a_lt, a_eq;

    always_comb begin
        if (i_mode) begin
            // Signed mode: interpret inputs as signed integers
            a_gt = $signed(i_A) > $signed(i_B);
            a_lt = $signed(i_A) < $signed(i_B);
            a_eq = $signed(i_A) == $signed(i_B);
        end else begin
            // Magnitude mode: interpret inputs as unsigned integers
            a_gt = i_A > i_B;
            a_lt = i_A < i_B;
            a_eq = i_A == i_B;
        end
    end

    // Enable gating of outputs
    assign o_greater = i_enable & a_gt;
    assign o_less    = i_enable & a_lt;
    assign o_equal   = i_enable & a_eq;

endmodule
