// precision_counter_axi.sv
// AXI4-Lite Slave for a high-precision countdown counter

`timescale 1ns / 1ps

module precision_counter_axi #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
) (
    // Clock and reset
    input  wire                                 axi_aclk,
    input  wire                                 axi_aresetn,

    // AXI Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]        axi_awaddr,
    input  wire                                 axi_awvalid,
    output reg                                  axi_awready,

    // AXI Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]        axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]    axi_wstrb,
    input  wire                                 axi_wvalid,
    output reg                                  axi_wready,

    // AXI Write Response Channel
    output reg  [1:0]                           axi_bresp,
    output reg                                  axi_bvalid,
    input  wire                                 axi_bready,

    // AXI Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]        axi_araddr,
    input  wire                                 axi_arvalid,
    output reg                                  axi_arready,

    // AXI Read Data Channel
    output reg  [C_S_AXI_DATA_WIDTH-1:0]        axi_rdata,
    output reg  [1:0]                           axi_rresp,
    output reg                                  axi_rvalid,
    input  wire                                 axi_rready,

    // Control outputs
    output wire                                 axi_ap_done,
    output wire                                 irq
);

    //--------------------------------------------------------------------------
    // Local parameters – register addresses (word aligned)
    //--------------------------------------------------------------------------
    localparam [C_S_AXI_ADDR_WIDTH-1:0] ADDR_CTL        = 'h00;
    localparam [C_S_AXI_ADDR_WIDTH-1:0] ADDR_T          = 'h10;
    localparam [C_S_AXI_ADDR_WIDTH-1:0] ADDR_V          = 'h20;
    localparam [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IRQ_MASK   = 'h24;
    localparam [C_S_AXI_ADDR_WIDTH-1:0] ADDR_IRQ_THRESH = 'h28;

    //--------------------------------------------------------------------------
    // Internal registers (the design registers)
    //--------------------------------------------------------------------------
    reg [31:0] ctl_reg;
    reg [31:0] t_reg;
    reg [31:0] v_reg;
    reg [31:0] irq_mask_reg;
    reg [31:0] irq_thresh_reg;

    //--------------------------------------------------------------------------
    // AXI write/read state machines
    //--------------------------------------------------------------------------
    localparam WST_IDLE = 2'b00, WST_DATA = 2'b01, WST_RESP = 2'b10;
    localparam RST_IDLE = 1'b0,  RST_RESP = 1'b1;

    reg [1:0] wstate;
    reg       rstate;

    // Storage for pending write/read addresses and data
    reg [C_S_AXI_ADDR_WIDTH-1:0] write_addr;
    reg [C_S_AXI_DATA_WIDTH-1:0] write_data;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] write_strb;
    reg [C_S_AXI_ADDR_WIDTH-1:0] read_addr;

    //--------------------------------------------------------------------------
    // Combinational outputs
    //--------------------------------------------------------------------------
    assign axi_ap_done = (v_reg == 32'h0);
    assign irq         = ctl_reg[0] && irq_mask_reg[0] && (v_reg == irq_thresh_reg);

    //--------------------------------------------------------------------------
    // Main synchronous block
    //--------------------------------------------------------------------------
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            // Reset all registers and state
            ctl_reg        <= 32'h0;
            t_reg          <= 32'h0;
            v_reg          <= 32'h0;
            irq_mask_reg   <= 32'h0;
            irq_thresh_reg <= 32'h0;

            wstate         <= WST_IDLE;
            rstate         <= RST_IDLE;

            write_addr     <= 0;
            write_data     <= 0;
            write_strb     <= 0;
            read_addr      <= 0;

            axi_awready    <= 1'b0;
            axi_wready     <= 1'b0;
            axi_bvalid     <= 1'b0;
            axi_bresp      <= 2'b00;
            axi_arready    <= 1'b0;
            axi_rvalid     <= 1'b0;
            axi_rresp      <= 2'b00;
            axi_rdata      <= 32'h0;
        end else begin
            // Defaults for ready/valid signals (to avoid latches)
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            // axi_bresp, axi_rresp, axi_rdata are assigned in the state machines

            //------------------------------------------------------------------
            // AXI Write State Machine
            //------------------------------------------------------------------
            case (wstate)
                WST_IDLE: begin
                    if (axi_awvalid) begin
                        axi_awready <= 1'b1;
                        write_addr  <= axi_awaddr;

                        if (axi_wvalid) begin
                            // Both address and data in same cycle
                            axi_wready  <= 1'b1;
                            write_data  <= axi_wdata;
                            write_strb  <= axi_wstrb;
                            wstate      <= WST_RESP;
                        end else begin
                            wstate <= WST_DATA;
                        end
                    end
                end

                WST_DATA: begin
                    if (axi_wvalid) begin
                        axi_wready <= 1'b1;
                        write_data <= axi_wdata;
                        write_strb <= axi_wstrb;
                        wstate     <= WST_RESP;
                    end
                end

                WST_RESP: begin
                    axi_bvalid <= 1'b1;
                    // Determine response status
                    if ((write_addr == ADDR_CTL) ||
                        (write_addr == ADDR_T) ||
                        (write_addr == ADDR_V) ||
                        (write_addr == ADDR_IRQ_MASK) ||
                        (write_addr == ADDR_IRQ_THRESH)) begin
                        axi_bresp <= 2'b00;   // OKAY
                    end else begin
                        axi_bresp <= 2'b10;   // SLVERR
                    end

                    if (axi_bready) begin
                        axi_bvalid <= 1'b0;
                        wstate     <= WST_IDLE;
                        // The actual register update is performed later in this block
                    end
                end
            endcase

            //------------------------------------------------------------------
            // AXI Read State Machine
            //------------------------------------------------------------------
            case (rstate)
                RST_IDLE: begin
                    if (axi_arvalid) begin
                        axi_arready <= 1'b1;
                        read_addr   <= axi_araddr;
                        rstate      <= RST_RESP;
                    end
                end

                RST_RESP: begin
                    axi_rvalid <= 1'b1;

                    case (read_addr)
                        ADDR_CTL:        axi_rdata <= ctl_reg;
                        ADDR_T:          axi_rdata <= t_reg;
                        ADDR_V:          axi_rdata <= v_reg;
                        ADDR_IRQ_MASK:   axi_rdata <= irq_mask_reg;
                        ADDR_IRQ_THRESH: axi_rdata <= irq_thresh_reg;
                        default:         axi_rdata <= 32'h0;
                    endcase

                    if ((read_addr == ADDR_CTL) ||
                        (read_addr == ADDR_T) ||
                        (read_addr == ADDR_V) ||
                        (read_addr == ADDR_IRQ_MASK) ||
                        (read_addr == ADDR_IRQ_THRESH)) begin
                        axi_rresp <= 2'b00;
                    end else begin
                        axi_rresp <= 2'b10;
                    end

                    if (axi_rready) begin
                        axi_rvalid <= 1'b0;
                        rstate     <= RST_IDLE;
                    end
                end
            endcase

            //------------------------------------------------------------------
            // Register updates and counting logic
            //------------------------------------------------------------------
            reg [31:0] ctl_next, t_next, v_next, irq_mask_next, irq_thresh_next;
            // Start from current values
            ctl_next        = ctl_reg;
            t_next          = t_reg;
            v_next          = v_reg;
            irq_mask_next   = irq_mask_reg;
            irq_thresh_next = irq_thresh_reg;

            // Detect a completed write transaction
            if ((wstate == WST_RESP) && axi_bready) begin
                case (write_addr)
                    ADDR_CTL: begin
                        // Apply write strobes
                        for (integer i = 0; i < (C_S_AXI_DATA_WIDTH/8); i = i + 1) begin
                            if (write_strb[i]) ctl_next[i*8 +: 8] = write_data[i*8 +: 8];
                        end
                        // Writing to control register resets elapsed time
                        t_next = 32'h0;
                    end

                    ADDR_T: begin
                        for (integer i = 0; i < (C_S_AXI_DATA_WIDTH/8); i = i + 1) begin
                            if (write_strb[i]) t_next[i*8 +: 8] = write_data[i*8 +: 8];
                        end
                    end

                    ADDR_V: begin
                        for (integer i = 0; i < (C_S_AXI_DATA_WIDTH/8); i = i + 1) begin
                            if (write_strb[i]) v_next[i*8 +: 8] = write_data[i*8 +: 8];
                        end
                    end

                    ADDR_IRQ_MASK: begin
                        for (integer i = 0; i < (C_S_AXI_DATA_WIDTH/8); i = i + 1) begin
                            if (write_strb[i]) irq_mask_next[i*8 +: 8] = write_data[i*8 +: 8];
                        end
                    end

                    ADDR_IRQ_THRESH: begin
                        for (integer i = 0; i < (C_S_AXI_DATA_WIDTH/8); i = i + 1) begin
                            if (write_strb[i]) irq_thresh_next[i*8 +: 8] = write_data[i*8 +: 8];
                        end
                    end

                    default: begin
                        // Invalid address – no register update
                    end
                endcase
            end

            // Apply counter behaviour **only if a write to the respective register did NOT
            // happen in this cycle** (writes already updated the *_next values).
            // Decrement v (if not written to v, and countdown is running)
            if (!((wstate == WST_RESP) && axi_bready && (write_addr == ADDR_V))) begin
                if (ctl_reg[0] && (v_reg > 0)) begin
                    v_next = v_reg - 1;
                end
            end

            // Increment t only when countdown is done (v_next == 0) and we are not
            // writing to t_reg or ctl_reg this cycle.
            if (!((wstate == WST_RESP) && axi_bready && (write_addr == ADDR_CTL)) &&
                !((wstate == WST_RESP) && axi_bready && (write_addr == ADDR_T))) begin
                if (v_next == 0) begin
                    t_next = t_next + 1;
                end
            end

            // Update the design registers
            ctl_reg        <= ctl_next;
            t_reg          <= t_next;
            v_reg          <= v_next;
            irq_mask_reg   <= irq_mask_next;
            irq_thresh_reg <= irq_thresh_next;
        end
    end

endmodule
