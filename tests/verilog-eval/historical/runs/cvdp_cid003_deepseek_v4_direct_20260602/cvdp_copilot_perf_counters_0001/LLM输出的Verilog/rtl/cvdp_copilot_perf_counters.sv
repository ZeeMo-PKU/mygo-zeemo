// rtl/cvdp_copilot_perf_counters.sv
// Performance counter module: increments on cpu_trig_i, readable only via sw_req_i,
// and resets to zero one cycle after a read.

module cvdp_copilot_perf_counters #(
  parameter CNT_W = 32  // Counter width (default 32 bits)
) (
  input  wire                 clk,
  input  wire                 reset,      // Asynchronous, active-high
  input  wire                 sw_req_i,   // Software read request
  input  wire                 cpu_trig_i, // CPU trigger event
  output wire [CNT_W-1:0]     p_count_o   // Performance counter output (0 when not read)
);

  logic [CNT_W-1:0] count;         // Internal counter
  logic             reset_count;   // Flag to reset counter next cycle

  // Counter logic with asynchronous reset
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      count       <= '0;
      reset_count <= 1'b0;
    end else begin
      // If a reset was flagged from a previous read, clear the counter
      if (reset_count) begin
        count       <= '0;
        reset_count <= 1'b0;
      end else begin
        // Normal increment on trigger (modulo 2^CNT_W automatically handles overflow)
        if (cpu_trig_i)
          count <= count + 1'b1;
      end

      // Schedule a reset for the next cycle if a read was requested now
      if (sw_req_i)
        reset_count <= 1'b1;
    end
  end

  // Output the counter value only during a software read, otherwise zero
  assign p_count_o = sw_req_i ? count : {CNT_W{1'b0}};

endmodule
