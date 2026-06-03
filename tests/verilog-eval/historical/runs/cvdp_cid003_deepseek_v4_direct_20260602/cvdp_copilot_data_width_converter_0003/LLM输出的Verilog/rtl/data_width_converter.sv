// data_width_converter.sv
// Concatenates four 32-bit input words into one 128-bit output word.
// Output is valid one clock cycle after the fourth valid input of a consecutive group.
// Any gap in data_valid resets the internal accumulation.

module data_width_converter (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] data_in,
    input  logic        data_valid,
    output logic [127:0] o_data_out,
    output logic        o_data_out_valid
);

    // 2‑bit counter tracks number of valid words received in the current group (0 to 3)
    logic [1:0] cnt;
    // Storage for the first three 32‑bit words
    logic [31:0] word0, word1, word2;
    // Registered output data and valid flag
    logic [127:0] out_reg;
    logic         out_valid;

    // Sequential update on positive clock edge; asynchronous active‑high reset
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt       <= 2'd0;
            word0     <= 32'd0;
            word1     <= 32'd0;
            word2     <= 32'd0;
            out_reg   <= 128'd0;
            out_valid <= 1'b0;
        end else begin
            // Default: deassert valid output (pulse lasts one cycle)
            out_valid <= 1'b0;

            if (data_valid) begin
                case (cnt)
                    2'd0 : begin
                        word0 <= data_in;
                        cnt   <= 2'd1;
                    end
                    2'd1 : begin
                        word1 <= data_in;
                        cnt   <= 2'd2;
                    end
                    2'd2 : begin
                        word2 <= data_in;
                        cnt   <= 2'd3;
                    end
                    2'd3 : begin
                        // Fourth word completes a 128‑bit group.
                        // Form output from the three stored words and the current input.
                        out_reg   <= {word0, word1, word2, data_in};
                        out_valid <= 1'b1;
                        cnt       <= 2'd0; // ready for next group
                    end
                endcase
            end else begin
                // data_valid low: break consecutive requirement -> reset counter
                cnt <= 2'd0;
            end
        end
    end

    // Connect registered outputs to module ports
    assign o_data_out       = out_reg;
    assign o_data_out_valid = out_valid;

endmodule
