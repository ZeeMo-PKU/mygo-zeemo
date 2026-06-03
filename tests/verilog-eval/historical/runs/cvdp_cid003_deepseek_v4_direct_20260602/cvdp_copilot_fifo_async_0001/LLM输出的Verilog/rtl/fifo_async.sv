// fifo_async.sv
// Asynchronous FIFO with configurable data width and depth
// Uses Gray code pointers and 2-stage synchronizers to transfer pointers
// across clock domains.

module fifo_async #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16          // Number of entries (should be power of 2)
) (
    // Write domain
    input  logic                     w_clk,
    input  logic                     w_rst,
    input  logic                     w_inc,
    input  logic [DATA_WIDTH-1:0]    w_data,

    // Read domain
    input  logic                     r_clk,
    input  logic                     r_rst,
    input  logic                     r_inc,

    // Status and read data
    output logic                     w_full,
    output logic                     r_empty,
    output logic [DATA_WIDTH-1:0]    r_data
);

    // Address width derived from depth
    localparam int ADDR_WIDTH = (DEPTH == 1) ? 1 : $clog2(DEPTH);
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;   // one extra bit for full/empty detection

    // ---------- Pointers ----------
    // Write pointers (binary and Gray)
    logic [PTR_WIDTH-1:0] wptr_bin, wptr_bin_next;
    logic [PTR_WIDTH-1:0] wptr_gray, wptr_gray_next;

    // Read pointers (binary and Gray)
    logic [PTR_WIDTH-1:0] rptr_bin, rptr_bin_next;
    logic [PTR_WIDTH-1:0] rptr_gray, rptr_gray_next;

    // ---------- Synchronizers ----------
    // 2‑stage synchronizer for read Gray pointer → write clock domain
    logic [PTR_WIDTH-1:0] rptr_gray_sync_w_reg, rptr_gray_sync_w;
    // 2‑stage synchronizer for write Gray pointer → read clock domain
    logic [PTR_WIDTH-1:0] wptr_gray_sync_r_reg, wptr_gray_sync_r;

    // Synchronized binary pointers (recovered from Gray)
    logic [PTR_WIDTH-1:0] rptr_bin_sync_w;
    logic [PTR_WIDTH-1:0] wptr_bin_sync_r;

    // ---------- Memory ----------
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ---------- Conversion Functions ----------
    function automatic logic [PTR_WIDTH-1:0] gray2bin (input logic [PTR_WIDTH-1:0] gray);
        gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
        for (int i = PTR_WIDTH-2; i >= 0; i--)
            gray2bin[i] = gray2bin[i+1] ^ gray[i];
    endfunction

    function automatic logic [PTR_WIDTH-1:0] bin2gray (input logic [PTR_WIDTH-1:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    //==================== Write Domain ====================
    // Next write pointer logic
    always_comb begin
        if (w_inc && !w_full)
            wptr_bin_next = wptr_bin + 1'b1;
        else
            wptr_bin_next = wptr_bin;
        wptr_gray_next = bin2gray(wptr_bin_next);
    end

    // Write pointer registers
    always_ff @(posedge w_clk or posedge w_rst) begin
        if (w_rst) begin
            wptr_bin  <= '0;
            wptr_gray <= '0;
        end else begin
            wptr_bin  <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
        end
    end

    // Synchronize read Gray pointer into write clock domain
    always_ff @(posedge w_clk or posedge w_rst) begin
        if (w_rst) begin
            rptr_gray_sync_w_reg <= '0;
            rptr_gray_sync_w     <= '0;
        end else begin
            rptr_gray_sync_w_reg <= rptr_gray;            // crossing from r_clk to w_clk
            rptr_gray_sync_w     <= rptr_gray_sync_w_reg;
        end
    end

    // Recover binary read pointer in write domain
    assign rptr_bin_sync_w = gray2bin(rptr_gray_sync_w);

    // Full flag: MSB different, remaining bits equal
    assign w_full = (wptr_bin[PTR_WIDTH-1] != rptr_bin_sync_w[PTR_WIDTH-1]) &&
                    (wptr_bin[PTR_WIDTH-2:0] == rptr_bin_sync_w[PTR_WIDTH-2:0]);

    //==================== Read Domain =====================
    // Next read pointer logic
    always_comb begin
        if (r_inc && !r_empty)
            rptr_bin_next = rptr_bin + 1'b1;
        else
            rptr_bin_next = rptr_bin;
        rptr_gray_next = bin2gray(rptr_bin_next);
    end

    // Read pointer registers
    always_ff @(posedge r_clk or posedge r_rst) begin
        if (r_rst) begin
            rptr_bin  <= '0;
            rptr_gray <= '0;
        end else begin
            rptr_bin  <= rptr_bin_next;
            rptr_gray <= rptr_gray_next;
        end
    end

    // Synchronize write Gray pointer into read clock domain
    always_ff @(posedge r_clk or posedge r_rst) begin
        if (r_rst) begin
            wptr_gray_sync_r_reg <= '0;
            wptr_gray_sync_r     <= '0;
        end else begin
            wptr_gray_sync_r_reg <= wptr_gray;            // crossing from w_clk to r_clk
            wptr_gray_sync_r     <= wptr_gray_sync_r_reg;
        end
    end

    // Recover binary write pointer in read domain
    assign wptr_bin_sync_r = gray2bin(wptr_gray_sync_r);

    // Empty flag: pointers equal
    assign r_empty = (wptr_bin_sync_r == rptr_bin);

    //==================== Dual-Port Memory ====================
    // Write operation (synchronous to w_clk)
    always_ff @(posedge w_clk) begin
        if (w_inc && !w_full)
            mem[wptr_bin[ADDR_WIDTH-1:0]] <= w_data;
    end

    // Read operation (synchronous to r_clk, registered output)
    always_ff @(posedge r_clk or posedge r_rst) begin
        if (r_rst) begin
            r_data <= '0;
        end else begin
            if (r_inc && !r_empty)
                r_data <= mem[rptr_bin[ADDR_WIDTH-1:0]];
            // When not reading, keep previous value to avoid unnecessary toggling
        end
    end

endmodule
