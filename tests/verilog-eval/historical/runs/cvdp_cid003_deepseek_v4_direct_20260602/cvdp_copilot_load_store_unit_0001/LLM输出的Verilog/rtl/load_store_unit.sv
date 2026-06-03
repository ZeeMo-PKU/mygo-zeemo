module load_store_unit (
    input  logic        clk,
    input  logic        rst_n,

    // Data-Cache Interface
    output logic        dmem_req_o,
    input  logic        dmem_gnt_i,
    output logic [31:0] dmem_req_addr_o,
    output logic        dmem_req_we_o,
    output logic [3:0]  dmem_req_be_o,
    output logic [31:0] dmem_req_wdata_o,
    input  logic        dmem_rvalid_i,
    input  logic [31:0] dmem_rsp_rdata_i,

    // Execution Stage Interface
    input  logic        ex_if_req_i,
    input  logic        ex_if_we_i,
    input  logic [1:0]  ex_if_type_i,
    input  logic [31:0] ex_if_wdata_i,
    input  logic [31:0] ex_if_addr_base_i,
    input  logic [31:0] ex_if_addr_offset_i,
    output logic        ex_if_ready_o,

    // Writeback Interface
    output logic [31:0] wb_if_rdata_o,
    output logic        wb_if_rvalid_o
);

    typedef enum logic [1:0] {IDLE, REQ_SENT, WAIT_RVALID} state_t;
    state_t state, next_state;

    logic aligned;
    logic [31:0] effective_addr;

    // Internal registers for accepted requests
    logic [31:0] addr_reg;
    logic        we_reg;
    logic [3:0]  be_reg;
    logic [31:0] wdata_reg;

    // Writeback pipeline registers
    logic        wb_rvalid_reg;
    logic [31:0] wb_rdata_reg;

    // Effective address is combinational
    assign effective_addr = ex_if_addr_base_i + ex_if_addr_offset_i;

    // Alignment check (combinational)
    always_comb begin
        case (ex_if_type_i)
            2'b00:   aligned = 1'b1;                         // byte, always aligned
            2'b01:   aligned = (effective_addr[0] == 1'b0);   // halfword, LSB must be 0
            2'b10:   aligned = (effective_addr[1:0] == 2'b00);// word, LSBs must be 00
            default: aligned = 1'b0;                          // reserved, misaligned
        endcase
    end

    // Capture request information on acceptance
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg  <= 32'h0;
            we_reg    <= 1'b0;
            be_reg    <= 4'h0;
            wdata_reg <= 32'h0;
        end else if (state == IDLE && ex_if_req_i && aligned) begin
            addr_reg  <= effective_addr;
            we_reg    <= ex_if_we_i;
            wdata_reg <= ex_if_wdata_i;
            // Byte enable generation
            case (ex_if_type_i)
                2'b00:   be_reg <= (1 << effective_addr[1:0]);
                2'b01:   be_reg <= effective_addr[1] ? 4'b1100 : 4'b0011;
                2'b10:   be_reg <= 4'b1111;
                default: be_reg <= 4'b0;
            endcase
        end
    end

    // FSM state transition
    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (ex_if_req_i && aligned) next_state = REQ_SENT;
            REQ_SENT: if (dmem_gnt_i) begin
                if (we_reg) next_state = IDLE;              // store: transaction done
                else begin                                   // load: wait for rvalid
                    if (dmem_rvalid_i) next_state = IDLE;    // data already available
                    else next_state = WAIT_RVALID;
                end
            end
            WAIT_RVALID: if (dmem_rvalid_i) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    // ex_if_ready_o with one-cycle latency after accept/completion
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) ex_if_ready_o <= 1'b1;
        else ex_if_ready_o <= (next_state == IDLE);
    end

    // Data-cache request outputs (driven by internal state)
    assign dmem_req_o        = (state == REQ_SENT);
    assign dmem_req_we_o     = (state == REQ_SENT) ? we_reg    : 1'b0;
    assign dmem_req_addr_o   = (state == REQ_SENT) ? addr_reg  : 32'h0;
    assign dmem_req_be_o     = (state == REQ_SENT) ? be_reg    : 4'h0;
    assign dmem_req_wdata_o  = (state == REQ_SENT) ? wdata_reg : 32'h0;

    // Writeback logic – provide rvalid and rdata one cycle after dmem_rvalid_i
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_rvalid_reg <= 1'b0;
            wb_rdata_reg  <= 32'h0;
        end else begin
            // Capture load response when rvalid is asserted
            if ((state == WAIT_RVALID && dmem_rvalid_i) ||
                (state == REQ_SENT && !we_reg && dmem_gnt_i && dmem_rvalid_i)) begin
                wb_rvalid_reg <= 1'b1;
                wb_rdata_reg  <= dmem_rsp_rdata_i;
            end else begin
                wb_rvalid_reg <= 1'b0; // valid only for one cycle
            end
        end
    end

    assign wb_if_rvalid_o = wb_rvalid_reg;
    assign wb_if_rdata_o  = wb_rdata_reg;

endmodule
