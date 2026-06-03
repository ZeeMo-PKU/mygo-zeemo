// rtl/sync_lifo.sv

module sync_lifo
#(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 3
) (
    input  logic                     clock,
    input  logic                     reset,
    input  logic                     write_en,
    input  logic                     read_en,
    input  logic [DATA_WIDTH-1:0]   data_in,
    output logic                     empty,
    output logic                     full,
    output logic [DATA_WIDTH-1:0]   data_out
);

    localparam int DEPTH = 2**ADDR_WIDTH;

    // Stack pointer (number of elements currently stored)
    logic [ADDR_WIDTH:0] sp;   // size one bit wider than ADDR_WIDTH to hold DEPTH

    // Memory array
    logic [DATA_WIDTH-1:0] mem [DEPTH];

    // Combinational control signals
    logic do_write;
    logic do_read;
    logic [ADDR_WIDTH:0] write_addr;

    assign full  = (sp == DEPTH);
    assign empty = (sp == 0);

    assign do_write = write_en && !full;
    assign do_read  = read_en  && !empty;

    // Write address: if also reading, replace the popped top;
    // otherwise store at current free location.
    assign write_addr = do_read ? (sp - 1) : sp;

    // Stack pointer update
    logic [ADDR_WIDTH:0] sp_next;
    assign sp_next = sp + (do_write ? 1 : 0) - (do_read ? 1 : 0);

    always_ff @(posedge clock) begin
        if (reset) begin
            sp <= '0;
        end else begin
            sp <= sp_next;
        end
    end

    // Data output register
    always_ff @(posedge clock) begin
        if (reset) begin
            data_out <= '0;
        end else if (do_read) begin
            data_out <= mem[sp - 1];
        end
    end

    // Memory write and reset clear
    always_ff @(posedge clock) begin
        if (reset) begin
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= '0;
            end
        end else if (do_write) begin
            mem[write_addr] <= data_in;
        end
    end

endmodule
