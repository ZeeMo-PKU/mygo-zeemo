// File: rtl/reverse_bits.v
// Module: reverse_bits
// Description:
//   This module takes a 32-bit unsigned input `num_in` and produces a 32-bit
//   output `num_out` where the bit order is completely reversed. The least
//   significant bit (LSB) of `num_in` becomes the most significant bit (MSB)
//   of `num_out`, the second LSB becomes the second MSB, and so on.
//   The implementation is purely combinational and synthesizable.
//
// Inputs:
//   num_in  - 32-bit unsigned input vector
// Outputs:
//   num_out - 32-bit unsigned output vector (bit-reversed version of num_in)
//
// Example:
//   num_in  = 32'b00000000000000000000000000000001 -> num_out = 32'b10000000000000000000000000000000

module reverse_bits (
    input  wire [31:0] num_in,   // 32-bit input number
    output wire [31:0] num_out   // bit-reversed 32-bit output
);

    // Use a generate loop to connect each output bit to the corresponding
    // reversed input bit.
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : bit_reverse
            // num_out[i] gets the bit from the opposite end of num_in
            assign num_out[i] = num_in[31 - i];
        end
    endgenerate

endmodule
