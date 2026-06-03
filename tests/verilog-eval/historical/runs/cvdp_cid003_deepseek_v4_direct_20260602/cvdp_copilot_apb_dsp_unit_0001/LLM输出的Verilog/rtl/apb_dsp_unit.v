module apb_dsp_unit (
    input           pclk,
    input           presetn,
    input   [9:0]   paddr,
    input           pselx,
    input           penable,
    input           pwrite,
    input   [7:0]   pwdata,
    output  wire    pready,
    output  reg  [7:0] prdata,
    output  reg     pslverr,
    output  reg     sram_valid
);

    // Internal registers
    reg [7:0] r_operand_1;
    reg [7:0] r_operand_2;
    reg [2:0] r_Enable;          // 0:disable, 1:add, 2:mul, 3:write
    reg [7:0] r_write_address;
    reg [7:0] r_write_data;
    reg [7:0] result_reg;

    // 1 KB SRAM (1024 x 8)
    reg [7:0] mem [0:1023];

    // APB state machine
    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_t;

    state_t state, next_state;

    // Captured APB transaction parameters
    reg [9:0] addr_latch;
    reg       write_latch;
    reg [7:0] wdata_latch;

    // Operation trigger
    reg       op_req;
    reg [2:0] op_mode;

    // PREADY is always high – no wait states
    assign pready = 1'b1;

    // State machine sequential logic
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            state <= IDLE;
            // Reset all registers
            r_operand_1     <= 8'h00;
            r_operand_2     <= 8'h00;
            r_Enable        <= 3'd0;
            r_write_address <= 8'h00;
            r_write_data    <= 8'h00;
            result_reg      <= 8'h00;
            prdata          <= 8'h00;
            pslverr         <= 1'b0;
            sram_valid      <= 1'b0;
            op_req          <= 1'b0;
            op_mode         <= 3'd0;
            // Memory is not reset, but would be X; acceptable
        end else begin
            // Default assignments
            pslverr <= 1'b0;
            sram_valid <= 1'b0;   // will be overridden in op processing if needed

            case (state)
                IDLE: begin
                    if (pselx && !penable) begin
                        // Capture transaction details
                        addr_latch  <= paddr;
                        write_latch <= pwrite;
                        wdata_latch <= pwdata;
                        state <= SETUP;
                    end
                end
                SETUP: begin
                    if (!pselx) begin
                        // Transaction aborted
                        state <= IDLE;
                    end else if (penable) begin
                        state <= ACCESS;
                    end
                end
                ACCESS: begin
                    if (write_latch) begin
                        // write transaction
                        case (addr_latch)
                            6'd0: r_operand_1 <= wdata_latch;
                            6'd1: r_operand_2 <= wdata_latch;
                            6'd2: begin
                                r_Enable <= wdata_latch[2:0];
                                if (wdata_latch[2:0] != 3'd0) begin
                                    op_req  <= 1'b1;
                                    op_mode <= wdata_latch[2:0];
                                end else begin
                                    op_req <= 1'b0;  // cancel pending operation
                                end
                            end
                            6'd3: r_write_address <= wdata_latch;
                            6'd4: r_write_data    <= wdata_latch;
                            // Address 5 is result_reg, read-only: ignore writes
                            default: if (addr_latch >= 6 && addr_latch < 1024)
                                         mem[addr_latch] <= wdata_latch;
                        endcase
                    end else begin
                        // read transaction
                        case (addr_latch)
                            6'd0: prdata <= r_operand_1;
                            6'd1: prdata <= r_operand_2;
                            6'd2: prdata <= {5'd0, r_Enable};  // upper bits zero
                            6'd3: prdata <= r_write_address;
                            6'd4: prdata <= r_write_data;
                            6'd5: prdata <= result_reg;
                            default: if (addr_latch >= 6 && addr_latch < 1024)
                                         prdata <= mem[addr_latch];
                                     else
                                         prdata <= 8'h00;
                        endcase
                    end
                    state <= IDLE;
                end
            endcase

            // Operation processing (triggered after APB write to r_Enable)
            if (op_req) begin
                // Use zero-extended 8‑bit operand addresses to index 10‑bit memory space
                wire [9:0] op1_addr = {2'b00, r_operand_1};
                wire [9:0] op2_addr = {2'b00, r_operand_2};
                wire [9:0] wr_addr  = {2'b00, r_write_address};

                case (op_mode)
                    3'd1: begin // Addition
                        result_reg <= mem[op1_addr] + mem[op2_addr];
                        r_Enable   <= 3'd0;
                    end
                    3'd2: begin // Multiplication
                        result_reg <= mem[op1_addr] * mem[op2_addr];
                        r_Enable   <= 3'd0;
                    end
                    3'd3: begin // Data Writing mode
                        mem[wr_addr] <= r_write_data;
                        sram_valid   <= 1'b1;    // pulse for one cycle
                        r_Enable     <= 3'd0;
                    end
                    default: ; // should not happen
                endcase
                op_req <= 1'b0;
            end
        end
    end

endmodule
