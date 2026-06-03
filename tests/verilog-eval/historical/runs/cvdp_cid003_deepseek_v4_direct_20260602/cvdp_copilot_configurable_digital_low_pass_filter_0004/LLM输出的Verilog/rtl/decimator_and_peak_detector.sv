// File: rtl/decimator_and_peak_detector.sv
// Advanced decimator with adaptive peak detection
module advanced_decimator_with_adaptive_peak_detection #(
    parameter int N          = 8,
    parameter int DATA_WIDTH = 16,
    parameter int DEC_FACTOR = 4
) (
    input  logic clk,
    input  logic reset,
    input  logic valid_in,
    input  logic [DATA_WIDTH*N-1:0] data_in,
    output logic valid_out,
    output logic [DATA_WIDTH*(N/DEC_FACTOR)-1:0] data_out,
    output logic signed [DATA_WIDTH-1:0] peak_value
);

    // Internal registers for input data and validation
    logic signed [DATA_WIDTH*N-1:0] data_in_reg;
    logic                           valid_in_reg;

    // Register inputs on clock edge; async reset clears them
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_reg  <= '0;
            valid_in_reg <= 1'b0;
        end else begin
            data_in_reg  <= data_in;
            valid_in_reg <= valid_in;
        end
    end

    // Unpack the registered input into an array of signed samples
    logic signed [DATA_WIDTH-1:0] samples [0:N-1];
    generate
        for (genvar i = 0; i < N; i++) begin : gen_unpack
            assign samples[i] = data_in_reg[DATA_WIDTH*i +: DATA_WIDTH];
        end
    endgenerate

    // Decimation step: select every DEC_FACTOR sample
    localparam int DEC_OUT_COUNT = N / DEC_FACTOR;
    logic signed [DATA_WIDTH-1:0] dec_samples [0:DEC_OUT_COUNT-1];
    generate
        for (genvar i = 0; i < DEC_OUT_COUNT; i++) begin : gen_decimate
            assign dec_samples[i] = samples[i*DEC_FACTOR];
        end
    endgenerate

    // Combinational peak detection among the decimated samples
    always_comb begin
        peak_value = dec_samples[0];
        for (int i = 1; i < DEC_OUT_COUNT; i++) begin
            if (dec_samples[i] > peak_value)
                peak_value = dec_samples[i];
        end
    end

    // Pack the decimated samples into the output data bus
    generate
        for (genvar i = 0; i < DEC_OUT_COUNT; i++) begin : gen_pack
            assign data_out[DATA_WIDTH*i +: DATA_WIDTH] = dec_samples[i];
        end
    endgenerate

    // Valid out is the registered valid input (1 clock cycle latency)
    assign valid_out = valid_in_reg;

endmodule