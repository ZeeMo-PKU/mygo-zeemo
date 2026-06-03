// Copyright (c) 2023
// Module: cvdp_copilot_apb_gpio
// Description: APB-compatible GPIO module with configurable width, interrupt generation,
//              edge/level sensitivity, and active-high/low polarity.
// Parameter:
//   GPIO_WIDTH = 8 (default)
// Features:
//   - APB slave interface (pready always high, pslverr always low)
//   - Two-stage synchronizer for gpio_in
//   - Register-based control for output data, output enable, interrupts
//   - Interrupts per pin with enable, type (edge/level), and polarity
//   - Combined interrupt output (OR of all enabled interrupts)
//   - Undefined addresses return 0 on read, write ignored

module cvdp_copilot_apb_gpio #(
  parameter GPIO_WIDTH = 8
) (
  input  logic                  pclk,
  input  logic                  preset_n,

  // APB slave interface
  input  logic                  psel,
  input  logic [7:2]            paddr,
  input  logic                  penable,
  input  logic                  pwrite,
  input  logic [31:0]           pwdata,
  output logic [31:0]           prdata,
  output logic                  pready,
  output logic                  pslverr,

  // GPIO external interface
  input  logic [GPIO_WIDTH-1:0] gpio_in,
  output logic [GPIO_WIDTH-1:0] gpio_out,
  output logic [GPIO_WIDTH-1:0] gpio_enable,
  output logic [GPIO_WIDTH-1:0] gpio_int,
  output logic                  comb_int
);

  // --------------------------------------------------------------------------
  // Local parameters for address decoding (paddr[4:2] mapping)
  // --------------------------------------------------------------------------
  localparam ADDR_IN         = 3'b000; // 0x00
  localparam ADDR_OUT        = 3'b001; // 0x04
  localparam ADDR_EN         = 3'b010; // 0x08
  localparam ADDR_INT_EN     = 3'b011; // 0x0C
  localparam ADDR_INT_TYPE   = 3'b100; // 0x10
  localparam ADDR_INT_POL    = 3'b101; // 0x14
  localparam ADDR_INT_STATE  = 3'b110; // 0x18

  // --------------------------------------------------------------------------
  // Registers
  // --------------------------------------------------------------------------
  logic [GPIO_WIDTH-1:0] reg_out, reg_en, reg_int_en, reg_int_type, reg_int_pol;

  // Synchronizer stages
  logic [GPIO_WIDTH-1:0] sync_stage1, sync_stage2;   // sync_stage2 = synchronized gpio_in
  logic [GPIO_WIDTH-1:0] last_sync_in;               // previous synchronized value

  // Internal signals
  logic [GPIO_WIDTH-1:0] level_cond, edge_cond, raw_int;

  // --------------------------------------------------------------------------
  // Synchronization logic (two-stage flip-flop for gpio_in)
  // --------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      sync_stage1  <= '0;
      sync_stage2  <= '0;
      last_sync_in <= '0;
    end else begin
      sync_stage1  <= gpio_in;
      sync_stage2  <= sync_stage1;
      last_sync_in <= sync_stage2;
    end
  end

  // --------------------------------------------------------------------------
  // APB register write logic
  // --------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge preset_n) begin
    if (!preset_n) begin
      reg_out      <= '0;
      reg_en       <= '0;
      reg_int_en   <= '0;
      reg_int_type <= '0;
      reg_int_pol  <= '0;
    end else if (psel && penable && pwrite) begin
      case (paddr[4:2])  // decode address
        ADDR_OUT:      reg_out      <= pwdata[GPIO_WIDTH-1:0];
        ADDR_EN:       reg_en       <= pwdata[GPIO_WIDTH-1:0];
        ADDR_INT_EN:   reg_int_en   <= pwdata[GPIO_WIDTH-1:0];
        ADDR_INT_TYPE: reg_int_type <= pwdata[GPIO_WIDTH-1:0];
        ADDR_INT_POL:  reg_int_pol  <= pwdata[GPIO_WIDTH-1:0];
        default: ; // writes to other addresses have no effect
      endcase
    end
  end

  // --------------------------------------------------------------------------
  // APB read data logic
  // --------------------------------------------------------------------------
  always_comb begin
    prdata = '0;  // default: all zeros (covers invalid addresses)
    case (paddr[4:2])
      ADDR_IN:        prdata = {{(32-GPIO_WIDTH){1'b0}}, sync_stage2};
      ADDR_OUT:       prdata = {{(32-GPIO_WIDTH){1'b0}}, reg_out};
      ADDR_EN:        prdata = {{(32-GPIO_WIDTH){1'b0}}, reg_en};
      ADDR_INT_EN:    prdata = {{(32-GPIO_WIDTH){1'b0}}, reg_int_en};
      ADDR_INT_TYPE:  prdata = {{(32-GPIO_WIDTH){1'b0}}, reg_int_type};
      ADDR_INT_POL:   prdata = {{(32-GPIO_WIDTH){1'b0}}, reg_int_pol};
      ADDR_INT_STATE: prdata = {{(32-GPIO_WIDTH){1'b0}}, gpio_int};
      default: ;      // keep prdata = 0
    endcase
  end

  // APB always-ready, no errors
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

  // --------------------------------------------------------------------------
  // GPIO output signals
  // --------------------------------------------------------------------------
  assign gpio_out    = reg_out;
  assign gpio_enable = reg_en;

  // --------------------------------------------------------------------------
  // Interrupt generation
  // --------------------------------------------------------------------------
  // Level condition: active level matches polarity
  assign level_cond = (sync_stage2 == reg_int_pol);

  // Edge condition: transition to active level (must be a combinational pulse of one cycle)
  // edge_cond = (sync_stage2 == pol) && (last_sync_in != pol)
  assign edge_cond  = (sync_stage2 == reg_int_pol) & (last_sync_in != reg_int_pol);

  // Raw interrupt: masked by enable, type selects edge or level
  // Type: 0 -> level, 1 -> edge
  for (genvar i = 0; i < GPIO_WIDTH; i++) begin : gen_int
    assign raw_int[i] = reg_int_en[i] ?
                        (reg_int_type[i] ? edge_cond[i] : level_cond[i]) :
                        1'b0;
  end

  assign gpio_int = raw_int;

  // Combined interrupt output
  assign comb_int = |gpio_int;

endmodule
