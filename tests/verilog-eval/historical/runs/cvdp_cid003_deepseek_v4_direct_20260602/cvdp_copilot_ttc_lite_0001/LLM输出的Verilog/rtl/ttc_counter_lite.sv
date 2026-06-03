// Module: ttc_counter_lite
// Lightweight timer/counter with AXI-Lite interface
module ttc_counter_lite (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  axi_addr,
    input  logic [31:0] axi_wdata,
    input  logic        axi_write_en,
    input  logic        axi_read_en,
    output logic [31:0] axi_rdata,
    output logic        interrupt
);

    // Internal signals
    logic        enable;
    logic        interval_mode;
    logic        interrupt_enable;
    logic        status_write;

    // Register storage
    logic [15:0] count, count_prev;
    logic [15:0] match_reg, reload_reg;
    logic [31:0] control_reg;
    logic        match_flag;

    // Wire from control register
    assign enable           = control_reg[0];
    assign interval_mode    = control_reg[1];
    assign interrupt_enable = control_reg[2];

    // Status write detection
    assign status_write = axi_write_en && (axi_addr == 4'h4);

    // Sequential logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            count       <= 16'd0;
            count_prev  <= 16'd0;
            match_flag  <= 1'b0;
            match_reg   <= 16'd0;
            reload_reg  <= 16'd0;
            control_reg <= 32'd0;
        end else begin
            // ----- Counter update -----
            if (enable) begin
                if (interval_mode) begin
                    if (count == match_reg)
                        count <= reload_reg;          // Reload on match
                    else
                        count <= count + 16'd1;       // Increment
                end else begin                          // Non-interval mode
                    if (count < match_reg)
                        count <= count + 16'd1;       // Increment while below match
                    // else hold at match value
                end
            end

            // ----- Edge detection for match flag -----
            count_prev <= count;   // store previous cycle's count

            if (status_write)
                match_flag <= 1'b0;                     // Clear on status write
            else if (enable && (count == match_reg) && (count_prev != match_reg))
                match_flag <= 1'b1;                     // Rising edge of match

            // ----- AXI Write operations -----
            if (axi_write_en) begin
                case (axi_addr)
                    4'h1: match_reg   <= axi_wdata[15:0]; // Match value register
                    4'h2: reload_reg  <= axi_wdata[15:0]; // Reload value register
                    4'h3: control_reg <= axi_wdata;       // Control register
                    // 4'h4: status write – no stored register (clear handled above)
                    default: ; // Ignore others
                endcase
            end
        end
    end

    // ----- Read data multiplexer -----
    logic [31:0] read_data;
    always_comb begin
        if (axi_read_en) begin
            unique case (axi_addr)
                4'h0: read_data = {16'd0, count};
                4'h1: read_data = {16'd0, match_reg};
                4'h2: read_data = {16'd0, reload_reg};
                4'h3: read_data = control_reg;
                4'h4: read_data = {31'd0, (match_flag & interrupt_enable)};
                default: read_data = 32'd0;
            endcase
        end else begin
            read_data = 32'd0;
        end
    end

    assign axi_rdata = read_data;

    // ----- Interrupt output (combinational) -----
    assign interrupt = match_flag & interrupt_enable;

endmodule
