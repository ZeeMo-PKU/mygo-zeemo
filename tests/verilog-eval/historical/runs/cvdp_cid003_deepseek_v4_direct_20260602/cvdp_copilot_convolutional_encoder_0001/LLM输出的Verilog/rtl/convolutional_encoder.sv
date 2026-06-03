module convolutional_encoder (
    input logic clk,
    input logic rst,
    input logic data_in,
    output logic encoded_bit1,
    output logic encoded_bit2
);

    // 2-bit shift register holding the previous two input bits
    // shift_reg[0]: one clock cycle delayed bit (x)
    // shift_reg[1]: two clock cycles delayed bit (x^2)
    logic [1:0] shift_reg;

    // Shift register update with asynchronous reset
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 2'b00;
        end else begin
            // Shift in the new data and move the older bits
            shift_reg <= {shift_reg[0], data_in};
        end
    end

    // Comb encoded outputs. During reset both outputs are forced to 0.
    // g1(x) = x^2 + x + 1  -> 111 -> taps: current input, shift_reg[0], shift_reg[1]
    assign encoded_bit1 = rst ? 1'b0 : (data_in ^ shift_reg[0] ^ shift_reg[1]);
    // g2(x) = x^2 + 1      -> 101 -> taps: current input, shift_reg[1]
    assign encoded_bit2 = rst ? 1'b0 : (data_in ^ shift_reg[1]);

endmodule
