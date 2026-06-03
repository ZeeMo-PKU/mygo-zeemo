// rtl/nbit_swizzling.sv
module nbit_swizzling #(
    parameter int DATA_WIDTH = 64
) (
    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic [1:0]            sel,
    output logic [DATA_WIDTH-1:0] data_out
);

    // Ensure DATA_WIDTH meets the constraints (>=16, multiple of 8)
    generate
        if (DATA_WIDTH < 16 || (DATA_WIDTH % 8) != 0)
            $error("DATA_WIDTH must be >=16 and a multiple of 8");
    endgenerate

    always_comb begin
        int seg_size;
        case (sel)
            2'd0: seg_size = DATA_WIDTH;
            2'd1: seg_size = DATA_WIDTH / 2;
            2'd2: seg_size = DATA_WIDTH / 4;
            2'd3: seg_size = DATA_WIDTH / 8;
            default: seg_size = 0; // used only to trigger the else branch
        endcase

        if (sel inside {2'd0, 2'd1, 2'd2, 2'd3}) begin
            for (int i = 0; i < DATA_WIDTH; i++) begin
                int segment = i / seg_size;
                int offset  = i % seg_size;
                data_out[i] = data_in[segment * seg_size + (seg_size - 1 - offset)];
            end
        end else begin
            data_out = data_in;
        end
    end

endmodule
