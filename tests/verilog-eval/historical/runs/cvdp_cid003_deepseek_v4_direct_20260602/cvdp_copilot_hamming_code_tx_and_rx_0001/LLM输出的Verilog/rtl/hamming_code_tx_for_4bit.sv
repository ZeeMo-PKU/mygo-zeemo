module hamming_code_tx_for_4bit (
    input  logic [3:0] data_in,
    output logic [7:0] data_out
);

    // Redundant bit fixed to 0
    assign data_out[0] = 1'b0;

    // Parity bit at position 1 (even parity over data_in[0], data_in[1], data_in[3])
    assign data_out[1] = data_in[0] ^ data_in[1] ^ data_in[3];

    // Parity bit at position 2 (even parity over data_in[0], data_in[2], data_in[3])
    assign data_out[2] = data_in[0] ^ data_in[2] ^ data_in[3];

    // Direct data bits
    assign data_out[3] = data_in[0];
    assign data_out[5] = data_in[1];
    assign data_out[6] = data_in[2];
    assign data_out[7] = data_in[3];

    // Parity bit at position 4 (even parity over data_in[1], data_in[2], data_in[3])
    assign data_out[4] = data_in[1] ^ data_in[2] ^ data_in[3];

endmodule
