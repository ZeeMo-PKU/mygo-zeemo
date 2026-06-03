// Moving Average of last 8 12-bit samples
// Output is truncated integer average (sum >> 3)
module moving_average (
    input wire clk,
    input wire reset,
    input wire [11:0] data_in,
    output reg [11:0] data_out
);

    // Buffer holds the last 8 samples (most recent at index 0)
    reg [11:0] buffer [0:7];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            // Clear all registers
            for (i = 0; i < 8; i = i + 1)
                buffer[i] <= 12'd0;
            data_out <= 12'd0;
        end else begin
            // Compute the new sum using incoming data and the 7 previous samples
            // (the oldest sample buffer[7] is dropped)
            reg [14:0] new_sum;
            new_sum = {3'd0, data_in} 
                    + {3'd0, buffer[0]}
                    + {3'd0, buffer[1]}
                    + {3'd0, buffer[2]}
                    + {3'd0, buffer[3]}
                    + {3'd0, buffer[4]}
                    + {3'd0, buffer[5]}
                    + {3'd0, buffer[6]};

            // Output truncated average (right shift by 3)
            data_out <= new_sum[14:3];

            // Shift in the new sample, moving all others one position right
            buffer[0] <= data_in;
            buffer[1] <= buffer[0];
            buffer[2] <= buffer[1];
            buffer[3] <= buffer[2];
            buffer[4] <= buffer[3];
            buffer[5] <= buffer[4];
            buffer[6] <= buffer[5];
            buffer[7] <= buffer[6];
        end
    end

endmodule
