// File: rtl/16qam_demapper.sv
// QAM16 Demapper with Error Detection on Interpolated Values

module qam16_demapper_interpolated #(
    parameter int N = 4,                  // Number of original input symbols (even, >=2)
    parameter int OUT_WIDTH = 4,          // Bit width of each output symbol (fixed)
    parameter int IN_WIDTH = 3,           // Bit width of each I/Q component (fixed)
    parameter int ERROR_THRESHOLD = 1    // Maximum allowed absolute difference for interpolated values
) (
    input  logic [(N + N/2)*IN_WIDTH - 1 : 0] I,   // Packed real components
    input  logic [(N + N/2)*IN_WIDTH - 1 : 0] Q,   // Packed imaginary components
    output logic [N*OUT_WIDTH - 1 : 0] bits,       // Demapped data bits
    output logic error_flag                         // Global error flag
);

    localparam int M = N + N/2;   // Total number of input symbols (mapped + interpolated)

    // Extract individual signed I and Q values from the packed inputs
    logic signed [IN_WIDTH-1:0] i_val [0:M-1];
    logic signed [IN_WIDTH-1:0] q_val [0:M-1];
    genvar gi;
    generate
        for (gi = 0; gi < M; gi++) begin : gen_extract
            assign i_val[gi] = I[(gi+1)*IN_WIDTH -1 -: IN_WIDTH];
            assign q_val[gi] = Q[(gi+1)*IN_WIDTH -1 -: IN_WIDTH];
        end
    endgenerate

    // -----------------------------------------------------------------------
    // Error detection on interpolated values
    // -----------------------------------------------------------------------
    logic error_local;
    always_comb begin
        error_local = 1'b0;
        for (int k = 0; k < N/2; k++) begin
            int left_idx   = 3*k;         // First mapped sample of the group
            int interp_idx = 3*k + 1;     // Interpolated sample
            int right_idx  = 3*k + 2;     // Second mapped sample

            // Expected interpolated value = (left + right) / 2
            // Use IN_WIDTH+1 bits to avoid overflow during addition
            logic signed [IN_WIDTH:0] sum_I, sum_Q;
            logic signed [IN_WIDTH:0] expected_I, expected_Q;
            sum_I = i_val[left_idx] + i_val[right_idx];
            sum_Q = q_val[left_idx] + q_val[right_idx];
            expected_I = sum_I >>> 1;   // Arithmetic right shift realizes signed division by 2
            expected_Q = sum_Q >>> 1;

            // Difference between actual interpolated and expected values
            logic signed [IN_WIDTH:0] diff_I, diff_Q;
            diff_I = i_val[interp_idx] - expected_I;
            diff_Q = q_val[interp_idx] - expected_Q;

            // Absolute value of the differences
            logic [IN_WIDTH:0] abs_diff_I, abs_diff_Q;
            abs_diff_I = (diff_I[IN_WIDTH] == 1'b1) ? (~diff_I + 1'b1) : diff_I;
            abs_diff_Q = (diff_Q[IN_WIDTH] == 1'b1) ? (~diff_Q + 1'b1) : diff_Q;

            // Raise flag if any absolute difference exceeds the threshold
            if ((abs_diff_I > ERROR_THRESHOLD) || (abs_diff_Q > ERROR_THRESHOLD))
                error_local = 1'b1;
        end
    end
    assign error_flag = error_local;

    // -----------------------------------------------------------------------
    // Demapping: convert each mapped I/Q component into 2-bit groups
    // -----------------------------------------------------------------------
    logic [1:0] i_bits_mapped [0:N-1];
    logic [1:0] q_bits_mapped [0:N-1];
    generate
        for (genvar gk = 0; gk < N/2; gk++) begin : gen_demap
            // Two mapped samples per group: indices 3*gk and 3*gk+2
            // Assign them to output symbols 2*gk and 2*gk+1 respectively
            localparam int idx1 = 2*gk;
            localparam int idx2 = 2*gk + 1;

            // Mapping: -3 -> 00, -1 -> 01, 1 -> 10, 3 -> 11
            assign i_bits_mapped[idx1] = (i_val[3*gk] == -3) ? 2'b00 :
                                         (i_val[3*gk] == -1) ? 2'b01 :
                                         (i_val[3*gk] == 1)  ? 2'b10 :
                                         (i_val[3*gk] == 3)  ? 2'b11 : 2'b00;

            assign q_bits_mapped[idx1] = (q_val[3*gk] == -3) ? 2'b00 :
                                         (q_val[3*gk] == -1) ? 2'b01 :
                                         (q_val[3*gk] == 1)  ? 2'b10 :
                                         (q_val[3*gk] == 3)  ? 2'b11 : 2'b00;

            assign i_bits_mapped[idx2] = (i_val[3*gk+2] == -3) ? 2'b00 :
                                         (i_val[3*gk+2] == -1) ? 2'b01 :
                                         (i_val[3*gk+2] == 1)  ? 2'b10 :
                                         (i_val[3*gk+2] == 3)  ? 2'b11 : 2'b00;

            assign q_bits_mapped[idx2] = (q_val[3*gk+2] == -3) ? 2'b00 :
                                         (q_val[3*gk+2] == -1) ? 2'b01 :
                                         (q_val[3*gk+2] == 1)  ? 2'b10 :
                                         (q_val[3*gk+2] == 3)  ? 2'b11 : 2'b00;
        end
    endgenerate

    // -----------------------------------------------------------------------
    // Pack final output bits: each symbol = {I_bits, Q_bits}
    // -----------------------------------------------------------------------
    generate
        for (genvar gs = 0; gs < N; gs++) begin : gen_pack
            assign bits[(gs+1)*OUT_WIDTH -1 -: OUT_WIDTH] = {i_bits_mapped[gs], q_bits_mapped[gs]};
        end
    endgenerate

endmodule
