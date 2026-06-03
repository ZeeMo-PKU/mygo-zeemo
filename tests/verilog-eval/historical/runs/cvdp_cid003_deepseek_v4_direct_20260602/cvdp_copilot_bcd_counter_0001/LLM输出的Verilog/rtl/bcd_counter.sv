// rtl/bcd_counter.sv
module bcd_counter (
    input  logic       clk,
    input  logic       rst,
    output logic [3:0] ms_hr,
    output logic [3:0] ls_hr,
    output logic [3:0] ms_min,
    output logic [3:0] ls_min,
    output logic [3:0] ms_sec,
    output logic [3:0] ls_sec
);

    // Asynchronous reset, synchronous counting
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ms_hr  <= 4'd0;
            ls_hr  <= 4'd0;
            ms_min <= 4'd0;
            ls_min <= 4'd0;
            ms_sec <= 4'd0;
            ls_sec <= 4'd0;
        end else begin
            // -- Seconds ------------------------------------------
            if (ls_sec != 4'd9) begin
                ls_sec <= ls_sec + 1'd1;
            end else begin               // ls_sec == 9
                ls_sec <= 4'd0;
                if (ms_sec != 4'd5) begin
                    ms_sec <= ms_sec + 1'd1;
                end else begin           // ms_sec == 5 → wrap seconds
                    ms_sec <= 4'd0;
                    // -- Minutes ------------------------------------
                    if (ls_min != 4'd9) begin
                        ls_min <= ls_min + 1'd1;
                    end else begin       // ls_min == 9
                        ls_min <= 4'd0;
                        if (ms_min != 4'd5) begin
                            ms_min <= ms_min + 1'd1;
                        end else begin   // ms_min == 5 → wrap minutes
                            ms_min <= 4'd0;
                            // -- Hours -------------------------------
                            // 23:59:59 → 00:00:00
                            if (ms_hr == 4'd2 && ls_hr == 4'd3) begin
                                ms_hr <= 4'd0;
                                ls_hr <= 4'd0;
                            end else if (ls_hr != 4'd9) begin
                                ls_hr <= ls_hr + 1'd1;
                            end else begin   // ls_hr == 9, ms_hr is 0 or 1
                                ls_hr <= 4'd0;
                                ms_hr <= ms_hr + 1'd1;
                            end
                        end
                    end
                end
            end
        end
    end

endmodule
