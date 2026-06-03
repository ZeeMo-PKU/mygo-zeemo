// rtl/matrix_multiplier.sv
module matrix_multiplier #(
  parameter int ROW_A            = 4,
  parameter int COL_A            = 4,
  parameter int ROW_B            = 4,
  parameter int COL_B            = 4,
  parameter int INPUT_DATA_WIDTH = 8,
  // Conservative safe bit-width to avoid overflow
  parameter int OUTPUT_DATA_WIDTH = $clog2(COL_A) + 2 * INPUT_DATA_WIDTH
) (
  input  logic [ROW_A*COL_A*INPUT_DATA_WIDTH-1:0] matrix_a,
  input  logic [ROW_B*COL_B*INPUT_DATA_WIDTH-1:0] matrix_b,
  output logic [ROW_A*COL_B*OUTPUT_DATA_WIDTH-1:0] matrix_c
);

  // Ensure compatible dimensions
  // synthesis translate_off
  initial begin
    if (COL_A != ROW_B) begin
      $error("Incompatible matrix dimensions: COL_A (%0d) must equal ROW_B (%0d)", COL_A, ROW_B);
      $stop;
    end
  end
  // synthesis translate_on

  // Combinational multiplication
  always_comb begin
    // Local unpacked arrays
    logic [INPUT_DATA_WIDTH-1:0] a [ROW_A][COL_A];
    logic [INPUT_DATA_WIDTH-1:0] b [ROW_B][COL_B];
    logic [OUTPUT_DATA_WIDTH-1:0] c_val;

    // Unpack input matrix A (row-major, LSB = a[0][0])
    for (int i = 0; i < ROW_A; i++) begin
      for (int j = 0; j < COL_A; j++) begin
        a[i][j] = matrix_a[(i*COL_A + j)*INPUT_DATA_WIDTH +: INPUT_DATA_WIDTH];
      end
    end

    // Unpack input matrix B (row-major, LSB = b[0][0])
    for (int i = 0; i < ROW_B; i++) begin
      for (int j = 0; j < COL_B; j++) begin
        b[i][j] = matrix_b[(i*COL_B + j)*INPUT_DATA_WIDTH +: INPUT_DATA_WIDTH];
      end
    end

    // Compute output matrix C and pack it
    for (int i = 0; i < ROW_A; i++) begin
      for (int j = 0; j < COL_B; j++) begin
        c_val = '0;
        for (int k = 0; k < COL_A; k++) begin
          // Multiplication and accumulation with sufficient bit-width
          c_val += a[i][k] * b[k][j];
        end
        // Pack result in row-major order, LSB = c[0][0]
        matrix_c[(i*COL_B + j)*OUTPUT_DATA_WIDTH +: OUTPUT_DATA_WIDTH] = c_val;
      end
    end
  end

endmodule
