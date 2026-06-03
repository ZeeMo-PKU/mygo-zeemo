module encoder_64b66b (
    input  logic        clk_in,
    input  logic        rst_in,
    input  logic [63:0] encoder_data_in,
    input  logic [ 7:0] encoder_control_in,
    output logic [65:0] encoder_data_out
);

    logic [65:0] next_encoder_data_out;

    // Combinational logic for next output value
    always_comb begin
        if (encoder_control_in == 8'b00000000) begin
            next_encoder_data_out = {2'b01, encoder_data_in};   // pure data
        end else begin
            next_encoder_data_out = {2'b10, 64'd0};             // control present (not supported)
        end
    end

    // Asynchronous reset, single-cycle registered output
    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            encoder_data_out <= 66'd0;
        end else begin
            encoder_data_out <= next_encoder_data_out;
        end
    end

endmodule
