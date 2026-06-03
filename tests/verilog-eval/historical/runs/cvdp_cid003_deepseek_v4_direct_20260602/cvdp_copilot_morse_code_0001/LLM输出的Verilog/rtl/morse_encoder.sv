module morse_encoder (
    input  logic [7:0] ascii_in,
    output logic [9:0] morse_out,
    output logic [3:0] morse_length
);

    always_comb begin
        case (ascii_in)
            // Uppercase letters
            8'h41: begin  // A
                morse_out   = 10'b0000000001; // ".-" -> dot=0, dash=1 -> 01, right-aligned
                morse_length = 4'd2;
            end
            8'h42: begin  // B
                morse_out   = 10'b0000001000; // "-..." -> 1000
                morse_length = 4'd4;
            end
            8'h43: begin  // C
                morse_out   = 10'b0000001010; // "-.-." -> 1010
                morse_length = 4'd4;
            end
            8'h44: begin  // D
                morse_out   = 10'b0000000100; // "-.." -> 100
                morse_length = 4'd3;
            end
            8'h45: begin  // E
                morse_out   = 10'b0000000000; // "." -> 0
                morse_length = 4'd1;
            end
            8'h46: begin  // F
                morse_out   = 10'b0000000010; // "..-." -> 0010
                morse_length = 4'd4;
            end
            8'h47: begin  // G
                morse_out   = 10'b0000000110; // "--." -> 110
                morse_length = 4'd3;
            end
            8'h48: begin  // H
                morse_out   = 10'b0000000000; // "...." -> 0000
                morse_length = 4'd4;
            end
            8'h49: begin  // I
                morse_out   = 10'b0000000000; // ".." -> 00
                morse_length = 4'd2;
            end
            8'h4A: begin  // J
                morse_out   = 10'b0000000111; // ".---" -> 0111
                morse_length = 4'd4;
            end
            8'h4B: begin  // K
                morse_out   = 10'b0000000101; // "-.-" -> 101
                morse_length = 4'd3;
            end
            8'h4C: begin  // L
                morse_out   = 10'b0000000100; // ".-.." -> 0100
                morse_length = 4'd4;
            end
            8'h4D: begin  // M
                morse_out   = 10'b0000000011; // "--" -> 11
                morse_length = 4'd2;
            end
            8'h4E: begin  // N
                morse_out   = 10'b0000000010; // "-." -> 10
                morse_length = 4'd2;
            end
            8'h4F: begin  // O
                morse_out   = 10'b0000000111; // "---" -> 111
                morse_length = 4'd3;
            end
            8'h50: begin  // P
                morse_out   = 10'b0000000110; // ".--." -> 0110
                morse_length = 4'd4;
            end
            8'h51: begin  // Q
                morse_out   = 10'b0000001101; // "--.-" -> 1101
                morse_length = 4'd4;
            end
            8'h52: begin  // R
                morse_out   = 10'b0000000010; // ".-." -> 010
                morse_length = 4'd3;
            end
            8'h53: begin  // S
                morse_out   = 10'b0000000000; // "..." -> 000
                morse_length = 4'd3;
            end
            8'h54: begin  // T
                morse_out   = 10'b0000000001; // "-" -> 1
                morse_length = 4'd1;
            end
            8'h55: begin  // U
                morse_out   = 10'b0000000001; // "..-" -> 001
                morse_length = 4'd3;
            end
            8'h56: begin  // V
                morse_out   = 10'b0000000001; // "...-" -> 0001
                morse_length = 4'd4;
            end
            8'h57: begin  // W
                morse_out   = 10'b0000000011; // ".--" -> 011
                morse_length = 4'd3;
            end
            8'h58: begin  // X
                morse_out   = 10'b0000001001; // "-..-" -> 1001
                morse_length = 4'd4;
            end
            8'h59: begin  // Y
                morse_out   = 10'b0000001011; // "-.--" -> 1011
                morse_length = 4'd4;
            end
            8'h5A: begin  // Z
                morse_out   = 10'b0000001100; // "--.." -> 1100
                morse_length = 4'd4;
            end

            // Digits
            8'h30: begin  // 0
                morse_out   = 10'b0000011111; // "-----" -> 11111
                morse_length = 4'd5;
            end
            8'h31: begin  // 1
                morse_out   = 10'b0000001111; // ".----" -> 01111
                morse_length = 4'd5;
            end
            8'h32: begin  // 2
                morse_out   = 10'b0000000111; // "..---" -> 00111
                morse_length = 4'd5;
            end
            8'h33: begin  // 3
                morse_out   = 10'b0000000011; // "...--" -> 00011
                morse_length = 4'd5;
            end
            8'h34: begin  // 4
                morse_out   = 10'b0000000001; // "....-" -> 00001
                morse_length = 4'd5;
            end
            8'h35: begin  // 5
                morse_out   = 10'b0000000000; // "....." -> 00000
                morse_length = 4'd5;
            end
            8'h36: begin  // 6
                morse_out   = 10'b0000010000; // "-...." -> 10000
                morse_length = 4'd5;
            end
            8'h37: begin  // 7
                morse_out   = 10'b0000011000; // "--..." -> 11000
                morse_length = 4'd5;
            end
            8'h38: begin  // 8
                morse_out   = 10'b0000011100; // "---.." -> 11100
                morse_length = 4'd5;
            end
            8'h39: begin  // 9
                morse_out   = 10'b0000011110; // "----." -> 11110
                morse_length = 4'd5;
            end

            default: begin
                morse_out   = 10'd0;
                morse_length = 4'd0;
            end
        endcase
    end

endmodule
