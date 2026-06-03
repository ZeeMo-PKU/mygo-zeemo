// rtl/APBGlobalHistoryRegister.v
// 8-bit APB-accessible global history shift register for branch prediction.

module APBGlobalHistoryRegister (
    // Clock and Reset
    input  wire        pclk,
    input  wire        presetn,          // active-low asynchronous reset

    // APB Interface
    input  wire [9:0]  paddr,
    input  wire        pselx,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  pwdata,
    output reg         pready,
    output reg         pslverr,
    output reg  [7:0]  prdata,

    // History Shift Control
    input  wire        history_shift_valid,
    input  wire        clk_gate_en,

    // Status & Interrupts
    output wire        history_full,
    output wire        history_empty,
    output wire        error_flag,
    output wire        interrupt_full,
    output wire        interrupt_error
);

    // Internal gated clock for power efficiency.
    // clk_gate_en toggles only on negative edge of pclk → no glitches.
    wire gated_pclk = pclk & clk_gate_en;

    // Internal registers
    reg [7:0] control_register;
    reg [7:0] train_history;
    reg [7:0] predict_history;

    //----------------------------------------------------------------------
    // APB write operations (gated_pclk domain)
    //----------------------------------------------------------------------
    always @(posedge gated_pclk or negedge presetn) begin
        if (!presetn) begin
            control_register <= 8'b0;
            train_history   <= 8'b0;
        end else if (pselx && penable && pwrite) begin
            case (paddr)
                10'h00: control_register <= pwdata;
                10'h01: train_history   <= pwdata;
                // 0x02 is a read-only register, write ignored.
            endcase
        end
    end

    //----------------------------------------------------------------------
    // APB pready, pslverr and prdata (gated_pclk domain)
    //----------------------------------------------------------------------
    always @(posedge gated_pclk or negedge presetn) begin
        if (!presetn) begin
            pready <= 1'b0;
        end else begin
            pready <= 1'b1;   // always driven high after reset
        end
    end

    // ERROR signal: asserted for invalid addresses during an active access.
    always @(posedge gated_pclk or negedge presetn) begin
        if (!presetn) begin
            pslverr <= 1'b0;
        end else if (pselx && penable) begin
            if ((paddr != 10'h00) && (paddr != 10'h01) && (paddr != 10'h02))
                pslverr <= 1'b1;
            else
                pslverr <= 1'b0;
        end else begin
            pslverr <= 1'b0;
        end
    end

    // Read data return (held stable when pready is high)
    always @(posedge gated_pclk or negedge presetn) begin
        if (!presetn) begin
            prdata <= 8'b0;
        end else if (pselx && penable && !pwrite) begin
            case (paddr)
                10'h00: prdata <= {4'b0, control_register[3:0]};   // reserved bits read 0
                10'h01: prdata <= {1'b0, train_history[6:0]};     // bit7 reserved, read 0
                10'h02: prdata <= predict_history;
                default: prdata <= 8'b0;
            endcase
        end else begin
            prdata <= 8'b0;   // no active read
        end
    end

    //----------------------------------------------------------------------
    // History shift register update (history_shift_valid domain)
    // Asynchronous clear via presetn
    //----------------------------------------------------------------------
    always @(posedge history_shift_valid or negedge presetn) begin
        if (!presetn) begin
            predict_history <= 8'b0;
        end else begin
            // Misprediction has highest priority
            if (control_register[2]) begin           // train_mispredicted
                predict_history <= {train_history[6:0], control_register[3]};
            end else if (control_register[0]) begin  // predict_valid
                predict_history <= {predict_history[6:0], control_register[1]};
            end
            // else no update
        end
    end

    //----------------------------------------------------------------------
    // Status and interrupt outputs (combinational)
    //----------------------------------------------------------------------
    assign history_full   = (predict_history == 8'hFF);
    assign history_empty  = (predict_history == 8'h00);
    assign error_flag     = pslverr;
    assign interrupt_full = history_full;
    assign interrupt_error= error_flag;

endmodule
