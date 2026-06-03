module serial_in_parallel_out_8bit (
    input  logic clock,
    input  logic serial_in,
    output logic [7:0] parallel_out
);

    // 8-bit shift register
    always_ff @(posedge clock) begin
        // Shift left: discard MSB, new serial_in goes to LSB
        parallel_out <= {parallel_out[6:0], serial_in};
    end

endmodule
