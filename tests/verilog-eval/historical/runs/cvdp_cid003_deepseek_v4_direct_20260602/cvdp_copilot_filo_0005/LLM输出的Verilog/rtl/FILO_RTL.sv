module FILO_RTL #(
    parameter DATA_WIDTH = 8,
    parameter FILO_DEPTH = 16
)(
    input  logic clk,
    input  logic reset,
    input  logic push,
    input  logic pop,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic full,
    output logic empty
);

    localparam ADDR_W = (FILO_DEPTH == 1) ? 1 : $clog2(FILO_DEPTH);

    // Internal memory array
    logic [DATA_WIDTH-1:0] mem [0:FILO_DEPTH-1];

    // Stack pointer: next free location (0 to FILO_DEPTH)
    integer top_ptr;

    // Combinational status signals
    assign empty = (top_ptr == 0);
    assign full  = (top_ptr == FILO_DEPTH);

    // Feedthrough condition (empty and simultaneous push & pop)
    wire feedthrough = empty && push && pop;

    // Write control signals
    logic wr_en;
    logic [ADDR_W-1:0] wr_addr;

    always_comb begin
        if (push && !full && !feedthrough) begin
            wr_en = 1'b1;
            if (pop && !empty)  // simultaneous push pop, not empty
                wr_addr = top_ptr - 1;
            else
                wr_addr = top_ptr;
        end else begin
            wr_en = 1'b0;
            wr_addr = '0;
        end
    end

    // Memory write
    always_ff @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= data_in;
        end
    end

    // Pointer and data_out register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            top_ptr  <= 0;
            data_out <= 'x;
        end else begin
            // data_out update
            if (feedthrough) begin
                data_out <= data_in;
            end else if (pop && !empty) begin
                data_out <= mem[top_ptr - 1];
            end

            // top_ptr update
            if (!feedthrough) begin
                if (push && !full && pop && !empty) begin
                    // Simultaneous push and pop (not empty): pointer unchanged
                end else if (push && !full) begin
                    top_ptr <= top_ptr + 1;
                end else if (pop && !empty) begin
                    top_ptr <= top_ptr - 1;
                end
            end
        end
    end

endmodule
