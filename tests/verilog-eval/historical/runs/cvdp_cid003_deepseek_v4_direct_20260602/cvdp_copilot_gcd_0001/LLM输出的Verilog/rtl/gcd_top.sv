module gcd_top #(
    parameter WIDTH = 4
) (
    input logic clk,
    input logic rst,
    input logic [WIDTH-1:0] A,
    input logic [WIDTH-1:0] B,
    input logic go,
    output logic [WIDTH-1:0] OUT,
    output logic done
);
    logic [1:0] controlpath_state;
    logic equal, greater_than;

    gcd_controlpath #(WIDTH) control (
        .clk(clk),
        .rst(rst),
        .go(go),
        .equal(equal),
        .greater_than(greater_than),
        .controlpath_state(controlpath_state),
        .done(done)
    );

    gcd_datapath #(WIDTH) datapath (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .controlpath_state(controlpath_state),
        .OUT(OUT),
        .equal(equal),
        .greater_than(greater_than)
    );
endmodule
