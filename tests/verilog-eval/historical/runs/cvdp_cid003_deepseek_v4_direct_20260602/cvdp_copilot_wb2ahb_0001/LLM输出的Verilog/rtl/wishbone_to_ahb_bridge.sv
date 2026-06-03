// rtl/wishbone_to_ahb_bridge.sv
//
// Wishbone to AHB bridge.
// Translates Wishbone single cycles into AHB single (burst SINGLE) transfers.
// Handles byte, halfword and word transactions based on sel_i.
// Performs address alignment and data alignment for endian conversion.
// Invalid sel_i patterns result in an immediate acknowledge without
// starting an AHB transaction.
//
// Assumes that clk_i and hclk are the same clock for this implementation.

module wishbone_to_ahb_bridge (
    // Wishbone bus (from WB master)
    input  wire        clk_i,
    input  wire        rst_i,        // active low
    input  wire        cyc_i,
    input  wire        stb_i,
    input  wire [3:0]  sel_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] data_i,
    output reg  [31:0] data_o,
    output reg         ack_o,

    // AHB bus (to AHB slave)
    input  wire        hclk,
    input  wire        hreset_n,     // active low
    input  wire [31:0] hrdata,
    input  wire [1:0]  hresp,        // not used in this design
    input  wire        hready,
    output reg  [1:0]  htrans,
    output reg  [2:0]  hsize,
    output reg  [2:0]  hburst,
    output reg         hwrite,
    output reg  [31:0] haddr,
    output reg  [31:0] hwdata
);

    // ------------------------------------------------------------------------
    // State machine definitions
    // ------------------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE,   // No transaction in progress
        ADDR,   // AHB address phase
        DATA,   // AHB data phase
        FAKE    // Invalid sel_i – fake acknowledge, no AHB cycle
    } state_t;

    state_t state, next_state;

    // AHB transfer type
    localparam [1:0] HTRANS_IDLE   = 2'b00,
                     HTRANS_BUSY   = 2'b01,
                     HTRANS_NONSEQ = 2'b10;

    // ------------------------------------------------------------------------
    // Reset combining
    // ------------------------------------------------------------------------
    wire rst_n = rst_i && hreset_n;   // asynchronous reset, active low

    // ------------------------------------------------------------------------
    // Attribute latching registers
    // ------------------------------------------------------------------------
    reg [31:0] addr_latched;
    reg        we_latched;
    reg [3:0]  sel_latched;
    reg [31:0] wdata_latched;
    reg [2:0]  hsize_latched;          // AHB HSIZE derived from sel_i

    // ------------------------------------------------------------------------
    // Derived signals
    // ------------------------------------------------------------------------
    wire [31:0] size_in_bytes = 1 << hsize_latched;   // 1, 2 or 4
    wire [31:0] addr_mask     = ~(size_in_bytes - 1);
    wire [31:0] haddr_aligned = addr_latched & addr_mask;
    wire [1:0]  byte_offset   = addr_latched[1:0];   // byte lane for alignment

    wire        valid_sel;          // true when sel_i represents a supported transfer
    assign valid_sel = (sel_i == 4'b1111) || (sel_i == 4'b0011) || (sel_i == 4'b1100) ||
                       (sel_i == 4'b0001) || (sel_i == 4'b0010) || (sel_i == 4'b0100) || (sel_i == 4'b1000);

    // Read‑data mask based on transfer size
    wire [31:0] read_mask = (size_in_bytes == 1) ? 32'h000000FF :
                            (size_in_bytes == 2) ? 32'h0000FFFF : 32'hFFFFFFFF;

    // ------------------------------------------------------------------------
    // State register & latching of transaction attributes
    // ------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            addr_latched  <= 0;
            we_latched    <= 0;
            sel_latched   <= 0;
            wdata_latched <= 0;
            hsize_latched <= 0;
        end else begin
            state <= next_state;

            // Latch new transaction attributes when starting from IDLE
            if (state == IDLE && cyc_i && stb_i) begin
                addr_latched  <= addr_i;
                we_latched    <= we_i;
                sel_latched   <= sel_i;
                wdata_latched <= data_i;

                // Determine HSIZE from sel_i
                case (sel_i)
                    4'b1111:         hsize_latched <= 3'b010; // word
                    4'b0011, 4'b1100: hsize_latched <= 3'b001; // halfword
                    default:         hsize_latched <= 3'b000; // byte (and fallback)
                endcase
            end
        end
    end

    // ------------------------------------------------------------------------
    // Next‑state logic
    // ------------------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cyc_i && stb_i) begin
                    if (valid_sel)
                        next_state = ADDR;
                    else
                        next_state = FAKE;
                end
            end
            ADDR: begin
                if (hready) next_state = DATA;
            end
            DATA: begin
                if (hready) next_state = IDLE;
            end
            FAKE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // ------------------------------------------------------------------------
    // AHB output registers (updated based on next_state for minimum latency)
    // ------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            htrans <= HTRANS_IDLE;
            hsize  <= 3'b000;
            hburst <= 3'b000;   // always SINGLE
            hwrite <= 1'b0;
            haddr  <= 0;
            hwdata <= 0;
        end else begin
            hburst <= 3'b000;   // fixed
            case (next_state)
                IDLE: begin
                    htrans <= HTRANS_IDLE;
                    hsize  <= 3'b000;
                    hwrite <= 1'b0;
                    haddr  <= 32'd0;
                    hwdata <= 32'd0;
                end
                ADDR: begin
                    htrans <= HTRANS_NONSEQ;
                    hsize  <= hsize_latched;
                    hwrite <= we_latched;
                    haddr  <= haddr_aligned;
                    if (we_latched)
                        hwdata <= wdata_latched << (8 * byte_offset);
                    else
                        hwdata <= 32'd0;
                end
                DATA: begin
                    htrans <= HTRANS_BUSY;
                    // Hold address and control constant during data phase
                    hsize  <= hsize_latched;
                    hwrite <= we_latched;
                    haddr  <= haddr_aligned;
                    if (we_latched)
                        hwdata <= wdata_latched << (8 * byte_offset);
                    // for reads hwdata remains as previously driven
                    else
                        hwdata <= hwdata;
                end
                FAKE: begin
                    htrans <= HTRANS_IDLE;
                    hsize  <= 3'b000;
                    hwrite <= 1'b0;
                    haddr  <= 32'd0;
                    hwdata <= 32'd0;
                end
                default: begin
                    htrans <= HTRANS_IDLE;
                    hsize  <= 3'b000;
                    hwrite <= 1'b0;
                    haddr  <= 32'd0;
                    hwdata <= 32'd0;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Wishbone read data and acknowledge generation
    // ------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            data_o <= 32'd0;
            ack_o  <= 1'b0;
        end else begin
            ack_o <= 1'b0;                      // default

            // Capture read data when a read transaction completes
            if (state == DATA && hready && !we_latched) begin
                data_o <= (hrdata >> (8 * byte_offset)) & read_mask;
            end

            // Assert acknowledge on transaction completion (real or fake)
            if ((state == DATA && hready) || (state == FAKE)) begin
                ack_o <= 1'b1;
            end
        end
    end

endmodule
