module hamming_code_receiver (
    input  logic [7:0] data_in,
    output logic [3:0] data_out
);
    logic c1, c2, c3;
    assign c1 = data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
    assign c2 = data_in[2] ^ data_in[3] ^ data_in[6] ^ data_in[7];
    assign c3 = data_in[1] ^ data_in[3] ^ data_in[5] ^ data_in[7];

    logic [2:0] syndrome;
    assign syndrome = {c1, c2, c3};

    logic [6:0] corrected_bits; // bits 6:0 correspond to data_in[7:1]
    always_comb begin
        case (syndrome)
            3'd0: corrected_bits = data_in[7:1];
            3'd1: corrected_bits = {data_in[7:2], ~data_in[1]};
            3'd2: corrected_bits = {data_in[7:3], ~data_in[2], data_in[1]};
            3'd3: corrected_bits = {data_in[7:4], ~data_in[3], data_in[2:1]};
            3'd4: corrected_bits = {data_in[7:5], ~data_in[4], data_in[3:1]};
            3'd5: corrected_bits = {data_in[7:6], ~data_in[5], data_in[4:1]};
            3'd6: corrected_bits = {data_in[7], ~data_in[6], data_in[5:1]};
            3'd7: corrected_bits = {~data_in[7], data_in[6:1]};
            default: corrected_bits = data_in[7:1];
        endcase
    end

    assign data_out[0] = corrected_bits[2]; // data_in[3] (Data bit 1)
    assign data_out[1] = corrected_bits[4]; // data_in[5] (Data bit 2)
    assign data_out[2] = corrected_bits[5]; // data_in[6] (Data bit 3)
    assign data_out[3] = corrected_bits[6]; // data_in[7] (Data bit 4)

endmodule
