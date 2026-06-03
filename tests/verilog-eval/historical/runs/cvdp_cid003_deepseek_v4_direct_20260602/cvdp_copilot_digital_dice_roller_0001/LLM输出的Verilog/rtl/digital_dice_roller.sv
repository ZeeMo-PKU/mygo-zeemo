module digital_dice_roller (
    input  logic       clk,
    input  logic       reset_n,  // active low asynchronous reset
    input  logic       button,
    output logic [2:0] dice_value
);

    typedef enum logic { IDLE, ROLLING } state_t;
    state_t state, next_state;
    logic [2:0] count;

    // Combinational next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE:    if (button) next_state = ROLLING;
            ROLLING: if (!button) next_state = IDLE;
        endcase
    end

    // Sequential logic with asynchronous reset
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state      <= IDLE;
            count      <= 3'd1;
            dice_value <= 3'd0;
        end else begin
            state <= next_state;

            // Counter control
            if (state == IDLE && next_state == ROLLING) begin
                // Just entered ROLLING state → start from 1
                count <= 3'd1;
            end else if (state == ROLLING && next_state == ROLLING) begin
                // Still in ROLLING state → increment with wrap
                count <= (count == 3'd6) ? 3'd1 : count + 3'd1;
            end
            // When leaving ROLLING, count is left unchanged.

            // Capture the dice value when leaving ROLLING
            if (state == ROLLING && next_state == IDLE) begin
                dice_value <= count;
            end
        end
    end

endmodule
