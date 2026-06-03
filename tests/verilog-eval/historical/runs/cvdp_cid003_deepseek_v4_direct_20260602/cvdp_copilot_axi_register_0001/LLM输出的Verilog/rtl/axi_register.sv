module axi_register #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input  logic                     clk_i,
    input  logic                     rst_n_i,
    // Write address channel
    input  logic [ADDR_WIDTH-1:0]    awaddr_i,
    input  logic                     awvalid_i,
    output logic                     awready_o,
    // Write data channel
    input  logic [DATA_WIDTH-1:0]    wdata_i,
    input  logic                     wvalid_i,
    output logic                     wready_o,
    input  logic [(DATA_WIDTH/8)-1:0] wstrb_i,
    // Write response channel
    output logic [1:0]               bresp_o,
    output logic                     bvalid_o,
    input  logic                     bready_i,
    // Read address channel
    input  logic [ADDR_WIDTH-1:0]    araddr_i,
    input  logic                     arvalid_i,
    output logic                     arready_o,
    // Read data channel
    output logic [DATA_WIDTH-1:0]    rdata_o,
    output logic [1:0]               rresp_o,
    output logic                     rvalid_o,
    input  logic                     rready_i,
    // Hardware control/status signals
    output logic [19:0]              beat_o,
    output logic                     start_o,
    output logic                     writeback_o,
    input  logic                     done_i
);

    // Register offsets
    localparam logic [ADDR_WIDTH-1:0] BEAT_ADDR      = 'h100;
    localparam logic [ADDR_WIDTH-1:0] START_ADDR     = 'h200;
    localparam logic [ADDR_WIDTH-1:0] DONE_ADDR      = 'h300;
    localparam logic [ADDR_WIDTH-1:0] WRITEBACK_ADDR = 'h400;
    localparam logic [ADDR_WIDTH-1:0] ID_ADDR        = 'h500;

    // AXI response codes
    localparam logic [1:0] OKAY   = 2'b00;
    localparam logic [1:0] SLVERR = 2'b10;

    // Internal registers
    logic [19:0] beat_reg;
    logic        start_reg;
    logic        writeback_reg;
    logic        done_reg;        // sticky done flag
    logic        done_i_d1;       // previous value of done_i for edge detection

    // Write state machine (3 states)
    enum logic [1:0] {
        W_IDLE,
        WAIT_DATA,
        W_RESP
    } wstate, wstate_next;

    logic [ADDR_WIDTH-1:0]    waddr_reg;
    logic [DATA_WIDTH-1:0]    wdata_reg;
    logic [(DATA_WIDTH/8)-1:0] wstrb_reg;

    // Read state machine
    enum logic {
        R_IDLE,
        R_RESP
    } rstate, rstate_next;

    logic [ADDR_WIDTH-1:0] raddr_reg;

    // Check if all byte strobes are active
    logic full_write;
    assign full_write = &wstrb_reg;

    // Address decode functions
    function logic is_valid_read_addr(input [ADDR_WIDTH-1:0] addr);
        return (addr == BEAT_ADDR)  ||
               (addr == START_ADDR) ||
               (addr == DONE_ADDR)  ||
               (addr == WRITEBACK_ADDR) ||
               (addr == ID_ADDR);
    endfunction

    function logic is_valid_write_addr(input [ADDR_WIDTH-1:0] addr);
        // All five addresses are valid (ID is read-only but still addressable for error response)
        return (addr == BEAT_ADDR)  ||
               (addr == START_ADDR) ||
               (addr == DONE_ADDR)  ||
               (addr == WRITEBACK_ADDR) ||
               (addr == ID_ADDR);
    endfunction

    // --------------------------------------------------------------------------
    // Done status: set on rising edge of done_i, cleared by write to DONE register
    // --------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            done_i_d1 <= 1'b0;
            done_reg  <= 1'b0;
        end else begin
            done_i_d1 <= done_i;
            if (wstate == WAIT_DATA && wvalid_i && wready_o && (waddr_reg == DONE_ADDR) && full_write && wdata_i[0])
                done_reg <= 1'b0;          // clear done flag on write
            else if (done_i && !done_i_d1)
                done_reg <= 1'b1;          // set on rising edge
        end
    end

    // --------------------------------------------------------------------------
    // Synchronous registers and write state machine update
    // --------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            wstate    <= W_IDLE;
            waddr_reg <= '0;
            wdata_reg <= '0;
            wstrb_reg <= '0;
            beat_reg     <= '0;
            start_reg    <= '0;
            writeback_reg <= '0;
        end else begin
            wstate <= wstate_next;

            // Capture write address
            if (wstate == W_IDLE && awvalid_i && awready_o) begin
                waddr_reg <= awaddr_i;
            end

            // Capture write data and strobes, then update registers if full write
            if (wstate == WAIT_DATA && wvalid_i && wready_o) begin
                wdata_reg <= wdata_i;
                wstrb_reg <= wstrb_i;
                // Update based on address if full strobe
                if (&wstrb_i) begin   // full_write computed on the captured strobes
                    case (waddr_reg)
                        BEAT_ADDR:      beat_reg     <= wdata_i[19:0];
                        START_ADDR:     start_reg    <= wdata_i[0];
                        WRITEBACK_ADDR: writeback_reg <= wdata_i[0];
                        default:        ; // DONE and ID handled elsewhere or ignored
                    endcase
                end
            end
        end
    end

    // Write state next-state logic
    always_comb begin
        wstate_next = wstate;
        case (wstate)
            W_IDLE:     if (awvalid_i && awready_o)   wstate_next = WAIT_DATA;
            WAIT_DATA:  if (wvalid_i && wready_o)     wstate_next = W_RESP;
            W_RESP:     if (bvalid_o && bready_i)     wstate_next = W_IDLE;
        endcase
    end

    // --------------------------------------------------------------------------
    // Write channel control signals
    // --------------------------------------------------------------------------
    assign awready_o = (wstate == W_IDLE);
    assign wready_o  = (wstate == WAIT_DATA);
    assign bvalid_o  = (wstate == W_RESP);

    // Write response: OKAY for valid writable addresses or partial writes,
    // SLVERR for ID (read-only) or invalid addresses
    assign bresp_o = (wstate == W_RESP) ? 
                     ( is_valid_write_addr(waddr_reg) ? 
                       (waddr_reg == ID_ADDR ? SLVERR : OKAY) 
                       : SLVERR ) 
                     : OKAY;

    // --------------------------------------------------------------------------
    // Read state machine
    // --------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rstate    <= R_IDLE;
            raddr_reg <= '0;
        end else begin
            rstate <= rstate_next;
            if (rstate == R_IDLE && arvalid_i && arready_o)
                raddr_reg <= araddr_i;
        end
    end

    always_comb begin
        rstate_next = rstate;
        case (rstate)
            R_IDLE: if (arvalid_i && arready_o)   rstate_next = R_RESP;
            R_RESP: if (rvalid_o && rready_i)     rstate_next = R_IDLE;
        endcase
    end

    assign arready_o = (rstate == R_IDLE);
    assign rvalid_o  = (rstate == R_RESP);

    // Read data and response
    always_comb begin
        if (rstate == R_RESP) begin
            rresp_o = is_valid_read_addr(raddr_reg) ? OKAY : SLVERR;
            case (raddr_reg)
                BEAT_ADDR:      rdata_o = { {(DATA_WIDTH-20){1'b0}}, beat_reg };
                START_ADDR:     rdata_o = { {(DATA_WIDTH-1){1'b0}},  start_reg };
                DONE_ADDR:      rdata_o = { {(DATA_WIDTH-1){1'b0}},  done_reg };
                WRITEBACK_ADDR: rdata_o = { {(DATA_WIDTH-1){1'b0}},  writeback_reg };
                ID_ADDR:        rdata_o = { {(DATA_WIDTH-32){1'b0}}, 32'h0001_0001 };
                default:        rdata_o = '0;
            endcase
        end else begin
            rdata_o = '0;
            rresp_o = OKAY;
        end
    end

    // --------------------------------------------------------------------------
    // Output assignments
    // --------------------------------------------------------------------------
    assign beat_o      = beat_reg;
    assign start_o     = start_reg;
    assign writeback_o = writeback_reg;

endmodule
