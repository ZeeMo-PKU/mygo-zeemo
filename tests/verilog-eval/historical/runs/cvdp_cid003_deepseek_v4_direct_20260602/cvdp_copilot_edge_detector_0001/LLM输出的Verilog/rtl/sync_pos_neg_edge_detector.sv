module sync_pos_neg_edge_detector (
    input  logic i_clk,
    input  logic i_rstb,             // active-low asynchronous reset
    input  logic i_detection_signal, // glitch-free, debounced input
    output logic o_positive_edge_detected,
    output logic o_negative_edge_detected
);

    // Previous value of the detection signal
    logic prev_detection;

    // Asynchronous reset, active low
    always_ff @(posedge i_clk or negedge i_rstb) begin
        if (!i_rstb) begin
            prev_detection <= 1'b0;
        end else begin
            prev_detection <= i_detection_signal;
        end
    end

    // Edge detection: combinational logic evaluates on current and previous values.
    // Outputs are asserted for one full clock cycle (until prev_detection is updated).
    assign o_positive_edge_detected = !prev_detection &  i_detection_signal;
    assign o_negative_edge_detected =  prev_detection & !i_detection_signal;

endmodule
