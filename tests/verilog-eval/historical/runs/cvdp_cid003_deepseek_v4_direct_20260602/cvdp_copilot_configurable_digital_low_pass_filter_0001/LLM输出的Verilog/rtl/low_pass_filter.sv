module low_pass_filter #(
    parameter int DATA_WIDTH  = 16,
    parameter int COEFF_WIDTH = 16,
    parameter int NUM_TAPS    = 8
) (
    input  logic clk,
    input  logic reset,
    input  logic [DATA_WIDTH*NUM_TAPS-1:0] data_in,
    input  logic                           valid_in,
    input  logic [COEFF_WIDTH*NUM_TAPS-1:0] coeffs,
    output logic [$clog2(NUM_TAPS)+DATA_WIDTH+COEFF_WIDTH-1:0] data_out,
    output logic                                                valid_out
);

    // --------------------------------------------------------------------
    // Local parameters
    // --------------------------------------------------------------------
    localparam int MUL_WIDTH = DATA_WIDTH + COEFF_WIDTH;                      // NBW_MULT
    localparam int OUT_WIDTH = MUL_WIDTH + $clog2(NUM_TAPS);                  // output bit width

    // --------------------------------------------------------------------
    // Registered versions of data_in and coeffs
    // --------------------------------------------------------------------
    logic [DATA_WIDTH*NUM_TAPS-1:0]   data_in_r;
    logic [COEFF_WIDTH*NUM_TAPS-1:0]  coeffs_r;

    always_ff @(posedge clk) begin : input_registers
        if (reset) begin
            data_in_r <= '0;
            coeffs_r  <= '0;
        end else if (valid_in) begin
            data_in_r <= data_in;
            coeffs_r  <= coeffs;
        end
    end

    // --------------------------------------------------------------------
    // Unpack registered vectors into arrays of signed values
    // first sample (index 0) corresponds to the most significant chunk
    // --------------------------------------------------------------------
    logic signed [DATA_WIDTH-1:0]  data_arr  [0:NUM_TAPS-1];
    logic signed [COEFF_WIDTH-1:0] coeff_arr [0:NUM_TAPS-1];

    always_comb begin : unpack_arrays
        for (int i = 0; i < NUM_TAPS; i++) begin
            data_arr [i] = data_in_r[(NUM_TAPS-1-i)*DATA_WIDTH +: DATA_WIDTH];
            coeff_arr[i] = coeffs_r [(NUM_TAPS-1-i)*COEFF_WIDTH +: COEFF_WIDTH];
        end
    end

    // --------------------------------------------------------------------
    // Element‑wise multiplication (reverse order of coefficients)
    // --------------------------------------------------------------------
    logic signed [MUL_WIDTH-1:0] prod [0:NUM_TAPS-1];

    always_comb begin : multiply
        for (int i = 0; i < NUM_TAPS; i++) begin
            prod[i] = data_arr[i] * coeff_arr[NUM_TAPS-1-i];
        end
    end

    // --------------------------------------------------------------------
    // Summation with an adder tree
    // --------------------------------------------------------------------
    logic signed [OUT_WIDTH-1:0] sum;

    always_comb begin : sum_products
        sum = '0;
        for (int i = 0; i < NUM_TAPS; i++) begin
            sum = sum + prod[i];   // prod[i] is automatically sign‑extended
        end
    end

    assign data_out = sum;

    // --------------------------------------------------------------------
    // Output validity (registered valid_in)
    // --------------------------------------------------------------------
    always_ff @(posedge clk) begin : output_valid
        if (reset) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
        end
    end

endmodule
