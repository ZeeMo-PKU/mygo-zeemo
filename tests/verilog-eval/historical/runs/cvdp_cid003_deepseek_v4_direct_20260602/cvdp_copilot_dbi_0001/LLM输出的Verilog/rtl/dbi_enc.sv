module dbi_enc (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [39:0] data_in,
  output logic [39:0] data_out,
  output logic [1:0]  dbi_cntrl
);

  // Internal register storing the previous encoded output
  logic [39:0] prev_data;

  // Combinational determination of control bits
  logic [1:0] ctrl;
  assign ctrl[1] = ($countones(data_in[39:20] ^ prev_data[39:20]) > 5'd10);
  assign ctrl[0] = ($countones(data_in[19: 0] ^ prev_data[19: 0]) > 5'd10);

  // Synchronous update with asynchronous active-low reset
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= '0;
      dbi_cntrl <= '0;
      prev_data <= '0;
    end else begin
      dbi_cntrl <= ctrl;
      data_out  <= { ctrl[1] ? ~data_in[39:20] : data_in[39:20],
                     ctrl[0] ? ~data_in[19: 0] : data_in[19: 0] };
      prev_data <= data_out; // store current encoded output for next comparison
    end
  end

endmodule
