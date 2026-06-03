module fibonacci_series (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] fib_out,
    output logic        overflow_flag
);

    logic [31:0] regA, regB;
    logic        ovfl_det;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            regA          <= 32'h0;
            regB          <= 32'h1;
            ovfl_det      <= 1'b0;
            overflow_flag <= 1'b0;
            fib_out       <= 32'h0;
        end else begin
            overflow_flag <= 1'b0; // default low
            if (ovfl_det) begin
                // cycle after overflow detection: reset sequence and assert flag
                regA          <= 32'h0;
                regB          <= 32'h1;
                fib_out       <= 32'h0;
                overflow_flag <= 1'b1;
                ovfl_det      <= 1'b0;
            end else begin
                logic [32:0] next_fib = {1'b0, regA} + {1'b0, regB};
                if (next_fib[32]) begin
                    // overflow detected; keep last valid values, set flag for next cycle
                    ovfl_det <= 1'b1;
                    fib_out  <= regB; // output last valid Fibonacci number
                end else begin
                    // normal update
                    regA    <= regB;
                    regB    <= next_fib[31:0];
                    fib_out <= next_fib[31:0];
                end
            end
        end
    end

endmodule
