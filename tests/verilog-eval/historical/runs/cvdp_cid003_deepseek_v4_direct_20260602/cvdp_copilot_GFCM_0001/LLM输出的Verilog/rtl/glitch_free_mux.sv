// File: rtl/glitch_free_mux.sv
// Glitch-Free Clock Multiplexer
// Switches between clk1 and clk2 based on sel.
// resets asynchronously when rst_n is low (clkout = 0).

module glitch_free_mux (
    input  logic clk1,
    input  logic clk2,
    input  logic sel,
    input  logic rst_n,
    output logic clkout
);

    // Synchronise sel into clk1 domain (2 FFs)
    logic sel_sync1_r1, sel_sync1_r2;
    always_ff @(posedge clk1 or negedge rst_n) begin
        if (!rst_n) begin
            sel_sync1_r1 <= 1'b0;
            sel_sync1_r2 <= 1'b0;
        end else begin
            sel_sync1_r1 <= sel;
            sel_sync1_r2 <= sel_sync1_r1;
        end
    end
    wire sel_sync1 = sel_sync1_r2;

    // Synchronise sel into clk2 domain (2 FFs)
    logic sel_sync2_r1, sel_sync2_r2;
    always_ff @(posedge clk2 or negedge rst_n) begin
        if (!rst_n) begin
            sel_sync2_r1 <= 1'b0;
            sel_sync2_r2 <= 1'b0;
        end else begin
            sel_sync2_r1 <= sel;
            sel_sync2_r2 <= sel_sync2_r1;
        end
    end
    wire sel_sync2 = sel_sync2_r2;

    // Synchronise clk2 enable into clk1 domain (2 FFs)
    logic clk2_en_sync_r1, clk2_en_sync_r2;
    always_ff @(posedge clk1 or negedge rst_n) begin
        if (!rst_n) begin
            clk2_en_sync_r1 <= 1'b0;
            clk2_en_sync_r2 <= 1'b0;
        end else begin
            clk2_en_sync_r1 <= clk2_en;
            clk2_en_sync_r2 <= clk2_en_sync_r1;
        end
    end
    wire synced_clk2_en = clk2_en_sync_r2;

    // clk1 enable – updated on falling edge of clk1 (glitch‑free)
    logic clk1_en;
    always_ff @(negedge clk1 or negedge rst_n) begin
        if (!rst_n) begin
            clk1_en <= 1'b0;
        end else begin
            // Enable clk1 when sel==0 and clk2 is disabled
            clk1_en <= (!sel_sync1) && (!synced_clk2_en);
        end
    end

    // Synchronise clk1 enable into clk2 domain (2 FFs)
    logic clk1_en_sync_r1, clk1_en_sync_r2;
    always_ff @(posedge clk2 or negedge rst_n) begin
        if (!rst_n) begin
            clk1_en_sync_r1 <= 1'b0;
            clk1_en_sync_r2 <= 1'b0;
        end else begin
            clk1_en_sync_r1 <= clk1_en;
            clk1_en_sync_r2 <= clk1_en_sync_r1;
        end
    end
    wire synced_clk1_en = clk1_en_sync_r2;

    // clk2 enable – updated on falling edge of clk2 (glitch‑free)
    logic clk2_en;
    always_ff @(negedge clk2 or negedge rst_n) begin
        if (!rst_n) begin
            clk2_en <= 1'b0;
        end else begin
            // Enable clk2 when sel==1 and clk1 is disabled
            clk2_en <= (sel_sync2) && (!synced_clk1_en);
        end
    end

    // Output clock: gated by enables, forced low during reset
    assign clkout = rst_n ? ((clk1 & clk1_en) | (clk2 & clk2_en)) : 1'b0;

endmodule
