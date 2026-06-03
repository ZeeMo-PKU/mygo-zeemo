// cascaded_adder.sv
// Cascaded adder module: sums IN_DATA_NS elements of IN_DATA_WIDTH bits each.
// Introduces 2 cycles of latency.
module cascaded_adder #(
    parameter IN_DATA_WIDTH = 16,
    parameter IN_DATA_NS = 4
) (
    input logic clk,
    input logic rst_n,
    input logic i_valid,
    input logic [IN_DATA_WIDTH*IN_DATA_NS-1:0] i_data,
    output logic o_valid,
    output logic [IN_DATA_WIDTH + $clog2(IN_DATA_NS)-1:0] o_data
);

    localparam OUT_WIDTH = IN_DATA_WIDTH + $clog2(IN_DATA_NS);
    
    // Internal registers
    logic [IN_DATA_WIDTH*IN_DATA_NS-1:0] data_reg;
    logic [OUT_WIDTH-1:0] sum;
    logic i_valid_d1;

    // Unpack data_reg for easy indexing
    logic [IN_DATA_WIDTH-1:0] data_array [0:IN_DATA_NS-1];
    for (genvar i = 0; i < IN_DATA_NS; i++) begin
        assign data_array[i] = data_reg[i*IN_DATA_WIDTH +: IN_DATA_WIDTH];
    end

    // Combinational cascaded sum
    always_comb begin
        sum = '0;
        for (int i = 0; i < IN_DATA_NS; i++) begin
            sum = sum + data_array[i];
        end
    end

    // Sequential logic: reset, input register, output register, valid pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= '0;
            i_valid_d1 <= 1'b0;
            o_valid <= 1'b0;
            o_data <= '0;
        end else begin
            if (i_valid) begin
                data_reg <= i_data;
            end
            i_valid_d1 <= i_valid;
            o_data <= sum;
            o_valid <= i_valid_d1;
        end
    end

endmodule
