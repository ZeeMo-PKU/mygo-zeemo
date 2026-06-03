module clock_divider (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  sel,
    output logic        clk_out
);

    logic [2:0] counter;

    // 3-bit counter, free-running
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'b0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    // Output logic: select the appropriate counter bit based on sel
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else begin
            case (sel)
                2'b00:   clk_out <= counter[0];   // div2
                2'b01:   clk_out <= counter[1];   // div4
                2'b10:   clk_out <= counter[2];   // div8
                default: clk_out <= 1'b0;         // invalid sel
            endcase
        end
    end

endmodule
