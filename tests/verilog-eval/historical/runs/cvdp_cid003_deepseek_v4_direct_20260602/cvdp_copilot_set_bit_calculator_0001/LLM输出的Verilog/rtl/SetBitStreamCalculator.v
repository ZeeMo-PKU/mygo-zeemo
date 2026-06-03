module SetBitStreamCalculator #(
    parameter p_max_set_bit_count_width = 8
) (
    input  wire i_bit_in,
    input  wire i_clk,
    input  wire i_ready,
    input  wire i_rst_n,
    output reg  [p_max_set_bit_count_width-1:0] o_set_bit_count
);
    // Saturation maximum: all bits set to 1
    localparam MAX = {p_max_set_bit_count_width{1'b1}};

    // Previous state of i_ready for edge detection
    reg i_ready_prev;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // Asynchronous active-low reset
            o_set_bit_count <= 0;
            i_ready_prev    <= 1'b0;
        end else begin
            // Update previous ready state
            i_ready_prev <= i_ready;

            // Detect rising edge of i_ready
            if (i_ready && !i_ready_prev) begin
                // On assertion edge: reset count to 0, do not count this cycle's i_bit_in
                o_set_bit_count <= 0;
            end else if (i_ready) begin
                // i_ready is high and not the first clock after assertion
                // Increment if bit is 1 and count is not yet saturated
                if (i_bit_in && o_set_bit_count < MAX) begin
                    o_set_bit_count <= o_set_bit_count + 1;
                end
                // If saturated, no change (count holds at MAX)
            end
            // When i_ready is low, o_set_bit_count holds its current value
        end
    end
endmodule
