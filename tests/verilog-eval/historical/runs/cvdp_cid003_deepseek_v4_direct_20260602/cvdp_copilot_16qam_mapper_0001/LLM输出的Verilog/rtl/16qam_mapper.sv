// File: rtl/16qam_mapper.sv
module qam16_mapper_interpolated #(
    parameter int N         = 4,
    parameter int IN_WIDTH  = 4,
    parameter int OUT_WIDTH = 3
) (
    input  logic [N*IN_WIDTH-1:0]                      bits,
    output logic [(N + N/2)*OUT_WIDTH-1:0]              I,
    output logic [(N + N/2)*OUT_WIDTH-1:0]              Q
);

    // derived constants
    localparam int TOTAL_SYMBOLS = N;
    localparam int TOTAL_OUT     = N + N/2;

    // 2-bit to 3-bit signed mapping for QAM16
    function automatic logic signed [OUT_WIDTH-1:0] map_2bits(input logic [1:0] bits_in);
        case (bits_in)
            2'b00: map_2bits = -3;
            2'b01: map_2bits = -1;
            2'b10: map_2bits =  1;
            2'b11: map_2bits =  3;
            default: map_2bits = 'x;  // should never occur
        endcase
    endfunction

    // internal arrays
    logic signed [OUT_WIDTH-1:0] mapped_I [0:TOTAL_SYMBOLS-1];
    logic signed [OUT_WIDTH-1:0] mapped_Q [0:TOTAL_SYMBOLS-1];
    logic signed [OUT_WIDTH-1:0] final_I [0:TOTAL_OUT-1];
    logic signed [OUT_WIDTH-1:0] final_Q [0:TOTAL_OUT-1];

    always_comb begin
        // Step 1: map every input symbol
        for (int i = 0; i < TOTAL_SYMBOLS; i++) begin
            logic [IN_WIDTH-1:0] sym = bits[i*IN_WIDTH +: IN_WIDTH];
            mapped_I[i] = map_2bits(sym[IN_WIDTH-1:IN_WIDTH-2]);  // upper two bits -> I
            mapped_Q[i] = map_2bits(sym[1:0]);                     // lower two bits -> Q
        end

        // Step 2: interpolate between consecutive symbols and assemble output order
        for (int i = 0; i < N/2; i++) begin
            int idx1 = 2*i;
            int idx2 = 2*i + 1;

            // compute sums with one extra bit to avoid overflow
            logic signed [OUT_WIDTH:0] sum_I = mapped_I[idx1] + mapped_I[idx2];
            logic signed [OUT_WIDTH:0] sum_Q = mapped_Q[idx1] + mapped_Q[idx2];

            // exact division by 2 (sum is always even)
            logic signed [OUT_WIDTH-1:0] interp_I = sum_I >>> 1;
            logic signed [OUT_WIDTH-1:0] interp_Q = sum_Q >>> 1;

            int base = 3*i;   // output index for this pair
            final_I[base]   = mapped_I[idx1];
            final_I[base+1] = interp_I;
            final_I[base+2] = mapped_I[idx2];

            final_Q[base]   = mapped_Q[idx1];
            final_Q[base+1] = interp_Q;
            final_Q[base+2] = mapped_Q[idx2];
        end

        // Step 3: pack the final arrays into flat output vectors (I, Q)
        for (int i = 0; i < TOTAL_OUT; i++) begin
            I[i*OUT_WIDTH +: OUT_WIDTH] = final_I[i];
            Q[i*OUT_WIDTH +: OUT_WIDTH] = final_Q[i];
        end
    end

endmodule