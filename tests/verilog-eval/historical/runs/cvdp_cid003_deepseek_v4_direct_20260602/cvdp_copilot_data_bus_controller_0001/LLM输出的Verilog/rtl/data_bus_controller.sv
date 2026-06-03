module data_bus_controller #(
  parameter AFINITY = 0
)(
  input         clk,
  input         rst_n,

  output        m0_read,
  input         m0_valid,
  input [31:0]  m0_data,

  output        m1_read,
  input         m1_valid,
  input [31:0]  m1_data,

  input         s_read,
  output        s_valid,
  output [31:0] s_data
);

  // Internal state
  logic pending_valid;
  logic [31:0] pending_data;

  // Slave consumes current transaction this cycle
  wire slave_accept = s_read && pending_valid;

  // Buffer can accept a new transaction if it is or will become free
  wire buffer_ready = !pending_valid || slave_accept;

  // Arbitration: select master based on validity and AFINITY
  wire m0_sel = buffer_ready && ( (m0_valid && m1_valid) ? (AFINITY == 0) : m0_valid );
  wire m1_sel = buffer_ready && ( (m0_valid && m1_valid) ? (AFINITY == 1) : m1_valid );

  // Master ready outputs
  assign m0_read = m0_sel;
  assign m1_read = m1_sel;

  // New transaction is accepted this cycle
  wire new_accepted = (m0_sel & m0_valid) | (m1_sel & m1_valid);

  // Next state logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_valid <= 1'b0;
      pending_data  <= 32'b0;
    end else begin
      if (new_accepted) begin
        pending_valid <= 1'b1;
        if (m0_sel & m0_valid)
          pending_data <= m0_data;
        else   // m1_sel & m1_valid
          pending_data <= m1_data;
      end else begin
        // No new transaction, clear if consumed by slave
        pending_valid <= pending_valid & ~slave_accept;
      end
    end
  end

  // Slave interface outputs
  assign s_valid = pending_valid;
  assign s_data  = pending_data;

endmodule
