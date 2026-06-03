module dig_stopwatch #(
    parameter int CLK_FREQ = 50_000_000
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        start_stop,
    output logic [5:0]  seconds,
    output logic [5:0]  minutes,
    output logic        hour
);

    // Divider counter width
    localparam DIV_WIDTH = (CLK_FREQ > 1) ? $clog2(CLK_FREQ) : 1;

    // Internal registers
    logic [DIV_WIDTH-1:0] div_cnt;
    logic                 one_sec_pulse;
    logic [5:0]           r_seconds, r_minutes;
    logic                 r_hour;

    // Generate one-second pulse when divider reaches max and stopwatch is running
    assign one_sec_pulse = (div_cnt == CLK_FREQ - 1) && start_stop;

    // Clock divider with pause support
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt <= '0;
        end else if (start_stop) begin
            if (div_cnt == CLK_FREQ - 1)
                div_cnt <= '0;
            else
                div_cnt <= div_cnt + 1'b1;
        end
        // If start_stop is low, div_cnt holds its value (paused)
    end

    // Stopwatch time counters: seconds, minutes, hour
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            r_seconds <= 6'd0;
            r_minutes <= 6'd0;
            r_hour    <= 1'b0;
        end else if (one_sec_pulse) begin
            // Only count if hour has not been reached yet
            if (r_hour == 1'b0) begin
                if (r_seconds == 6'd59) begin
                    r_seconds <= 6'd0;
                    if (r_minutes == 6'd59) begin
                        r_minutes <= 6'd0;
                        r_hour    <= 1'b1;
                    end else begin
                        r_minutes <= r_minutes + 1'b1;
                    end
                end else begin
                    r_seconds <= r_seconds + 1'b1;
                end
            end
            // Once hour is set, the counters stay at 1 hour, 0 minutes, 0 seconds
        end
    end

    // Output assignments
    assign seconds = r_seconds;
    assign minutes = r_minutes;
    assign hour    = r_hour;

endmodule
