// rtl/caesar_cipher.sv
// Caesar cipher encryption module
module caesar_cipher (
    input  logic [7:0] input_char,
    input  logic [3:0] key,
    output logic [7:0] output_char
);

    always_comb begin
        // Uppercase letters: A-Z (65-90)
        if (input_char >= "A" && input_char <= "Z") begin
            output_char = ((input_char - "A") + key) % 26 + "A";
        end
        // Lowercase letters: a-z (97-122)
        else if (input_char >= "a" && input_char <= "z") begin
            output_char = ((input_char - "a") + key) % 26 + "a";
        end
        // Non‑alphabetic characters pass through unchanged
        else begin
            output_char = input_char;
        end
    end

endmodule