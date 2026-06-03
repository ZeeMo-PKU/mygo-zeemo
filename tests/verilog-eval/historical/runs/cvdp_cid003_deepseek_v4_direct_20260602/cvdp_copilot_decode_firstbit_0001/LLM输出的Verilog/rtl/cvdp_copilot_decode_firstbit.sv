// File: rtl/cvdp_copilot_decode_firstbit.sv
module cvdp_copilot_decode_firstbit #(
  parameter int InWidth_g = 32,
  parameter int InReg_g   = 1,
  parameter int OutReg_g  = 1,
  parameter int PlRegs_g  = 1
) (
  input  logic                  Clk,
  input  logic                  Rst,
  input  logic [InWidth_g-1:0] In_Data,
  input  logic                  In_Valid,
  output logic [($clog2(InWidth_g)-1):0] Out_FirstBit,
  output logic                          Out_Found,
  output logic                          Out_Valid
);

  localparam int BinBits_c   = $clog2(InWidth_g);   // number of index bits
  localparam int PaddedWidth = 1 << BinBits_c;      // nearest power-of-two width
  localparam int Levels      = $clog2(PaddedWidth); // depth of priority tree (=BinBits_c)

  // ------------------------------------------------------------------------
  // Optional input register
  // ------------------------------------------------------------------------
  logic [InWidth_g-1:0] In_Data_reg;
  logic                 In_Valid_reg;

  generate
    if (InReg_g) begin : g_in_reg
      always_ff @(posedge Clk or posedge Rst) begin
        if (Rst) begin
          In_Data_reg  <= '0;
          In_Valid_reg <= 1'b0;
        end else begin
          In_Data_reg  <= In_Data;
          In_Valid_reg <= In_Valid;
        end
      end
    end
  endgenerate

  logic [InWidth_g-1:0] data_in_used;
  logic                 valid_in_used;

  assign data_in_used  = InReg_g ? In_Data_reg  : In_Data;
  assign valid_in_used = InReg_g ? In_Valid_reg : In_Valid;

  // Zero-pad to power-of-two width
  logic [PaddedWidth-1:0] padded_data;
  assign padded_data = {{(PaddedWidth-InWidth_g){1'b0}}, data_in_used};

  // ------------------------------------------------------------------------
  // Pipelined priority encoder
  // ------------------------------------------------------------------------
  // Stage arrays: data_stage[i], prefix_stage[i], valid_stage[i]
  // i = 0: input stage; i = Levels: final output of encoder
  logic [PaddedWidth-1:0] data_stage   [0:Levels];
  logic [Levels-1:0]      prefix_stage [0:Levels];
  logic                   valid_stage  [0:Levels];

  assign data_stage  [0] = padded_data;
  assign prefix_stage[0] = '0;
  assign valid_stage [0] = valid_in_used;

  generate
    for (genvar i = 0; i < Levels; i++) begin : level
      localparam int Wi   = PaddedWidth >> i; // current segment width
      localparam int half = Wi >> 1;          // width of lower/upper halves

      wire [half-1:0] lower = data_stage[i][half-1:0];
      wire [half-1:0] upper = data_stage[i][Wi-1:half];

      wire lower_found = |lower;
      wire upper_found = |upper;
      wire bit         = lower_found ? 1'b0 : (upper_found ? 1'b1 : 1'b0);

      wire next_valid = valid_stage[i] & (lower_found | upper_found);

      wire [PaddedWidth-1:0] next_data = lower_found
                                         ? {{(PaddedWidth-half){1'b0}}, lower}
                                         : upper_found
                                           ? {{(PaddedWidth-half){1'b0}}, upper}
                                           : {PaddedWidth{1'b0}};

      // Build prefix: set bit at position (Levels-1-i)
      wire [Levels-1:0] bit_mask = 1 << (Levels-1-i);
      wire [Levels-1:0] next_prefix = (prefix_stage[i] & ~bit_mask) | (bit ? bit_mask : '0);

      if (i < PlRegs_g) begin : reg_stage
        logic [PaddedWidth-1:0] data_s;
        logic [Levels-1:0]      prefix_s;
        logic                   valid_s;

        always_ff @(posedge Clk or posedge Rst) begin
          if (Rst) begin
            data_s   <= '0;
            prefix_s <= '0;
            valid_s  <= 1'b0;
          end else begin
            data_s   <= next_data;
            prefix_s <= next_prefix;
            valid_s  <= next_valid;
          end
        end

        assign data_stage  [i+1] = data_s;
        assign prefix_stage[i+1] = prefix_s;
        assign valid_stage [i+1] = valid_s;
      end else begin : comb_stage
        assign data_stage  [i+1] = next_data;
        assign prefix_stage[i+1] = next_prefix;
        assign valid_stage [i+1] = next_valid;
      end
    end
  endgenerate

  // Final decoded result (after pipeline)
  logic [BinBits_c-1:0] int_firstbit;
  logic                 int_found;
  logic                 int_valid;

  assign int_firstbit = prefix_stage[Levels][BinBits_c-1:0];
  assign int_found    = valid_stage[Levels];
  assign int_valid    = valid_stage[Levels];

  // ------------------------------------------------------------------------
  // Optional output register
  // ------------------------------------------------------------------------
  generate
    if (OutReg_g) begin : g_out_reg
      logic [BinBits_c-1:0] out_ff_reg;
      logic                 out_found_reg;
      logic                 out_valid_reg;

      always_ff @(posedge Clk or posedge Rst) begin
        if (Rst) begin
          out_ff_reg    <= '0;
          out_found_reg <= 1'b0;
          out_valid_reg <= 1'b0;
        end else begin
          out_ff_reg    <= int_firstbit;
          out_found_reg <= int_found;
          out_valid_reg <= int_valid;
        end
      end

      assign Out_FirstBit = out_ff_reg;
      assign Out_Found    = out_found_reg;
      assign Out_Valid    = out_valid_reg;
    end else begin : g_out_comb
      assign Out_FirstBit = int_firstbit;
      assign Out_Found    = int_found;
      assign Out_Valid    = int_valid;
    end
  endgenerate

endmodule
