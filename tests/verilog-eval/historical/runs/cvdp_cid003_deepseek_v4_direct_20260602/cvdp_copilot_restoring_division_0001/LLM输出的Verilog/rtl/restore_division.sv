//================================================================================
// Module: restoring_division
// Description: A parameterized restoring division module for unsigned integers.
//              Performs division using the restoring division algorithm.
//              Supports variable width via WIDTH parameter.
//================================================================================

module restoring_division #(
    parameter WIDTH = 6
) (
    input logic clk,
    input logic rst,              // active-low asynchronous reset
    input logic start,            // start signal (active-high)
    input logic [WIDTH-1:0] dividend,
    input logic [WIDTH-1:0] divisor,
    output logic [WIDTH-1:0] quotient,
    output logic [WIDTH-1:0] remainder,
    output logic valid            // high for one cycle when result is ready
);

    //--------------------------------------------------------------------------
    // Local parameters
    //--------------------------------------------------------------------------
    // Determine if WIDTH is a power of two (2^n)
    localparam IS_POWER_OF_TWO = (WIDTH != 0) && ((WIDTH & (WIDTH - 1)) == 0);
    // Number of iterations: WIDTH if power of two, else WIDTH+1
    localparam NUM_STEPS = IS_POWER_OF_TWO ? WIDTH : (WIDTH + 1);
    // Counter width to cover [0, NUM_STEPS-1]
    localparam COUNTER_WIDTH = $clog2(NUM_STEPS);

    //--------------------------------------------------------------------------
    // State encoding
    //--------------------------------------------------------------------------
    typedef enum logic [0:0] {
        IDLE,
        COMPUTE
    } state_t;

    state_t state;

    //--------------------------------------------------------------------------
    // Internal registers
    //--------------------------------------------------------------------------
    // Combined register: upper half = current remainder (WIDTH bits),
    // lower half = dividend / developing quotient (WIDTH bits)
    logic [2*WIDTH-1:0] Q_reg;
    logic [WIDTH-1:0]   divisor_reg;
    logic [COUNTER_WIDTH-1:0] step_counter;

    //--------------------------------------------------------------------------
    // Compute next Q_reg value (one iteration of restoring division)
    //--------------------------------------------------------------------------
    function logic [2*WIDTH-1:0] next_Q(input logic [2*WIDTH-1:0] curr_Q,
                                        input logic [WIDTH-1:0] div);
        logic [2*WIDTH-1:0] Q_shifted;
        // Shift left by one, appending a zero in the LSB
        Q_shifted = {curr_Q[2*WIDTH-2:0], 1'b0};

        // If the shifted upper part is >= divisor, subtract and set quotient LSB to 1
        if (Q_shifted[2*WIDTH-1:WIDTH] >= div) begin
            // new remainder = shifted remainder - divisor
            logic [WIDTH-1:0] new_rem;
            new_rem = Q_shifted[2*WIDTH-1:WIDTH] - div;
            // lower part: shift-in zero, force LSB to 1
            logic [WIDTH-1:0] lower_part;
            lower_part = Q_shifted[WIDTH-1:0] | { {(WIDTH-1){1'b0}}, 1'b1 };
            next_Q = {new_rem, lower_part};
        end else begin
            // negative result: restore; just keep shifted version (LSB stays 0)
            next_Q = Q_shifted;
        end
    endfunction

    //--------------------------------------------------------------------------
    // Main sequential logic (async reset, synchronous state machine)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state        <= IDLE;
            Q_reg        <= '0;
            divisor_reg  <= '0;
            step_counter <= '0;
            valid        <= 1'b0;
            quotient     <= '0;
            remainder    <= '0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;   // deassert valid when idle
                    if (start) begin
                        // Load dividend into lower half, zero the upper half
                        Q_reg       <= {{(WIDTH){1'b0}}, dividend};
                        divisor_reg <= divisor;
                        step_counter <= '0;
                        state       <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    if (step_counter < NUM_STEPS - 1) begin
                        // Regular iteration: shift and conditionally subtract
                        Q_reg        <= next_Q(Q_reg, divisor_reg);
                        step_counter <= step_counter + 1'b1;
                        valid        <= 1'b0;   // result not ready yet
                    end else if (step_counter == NUM_STEPS - 1) begin
                        // Final iteration: compute result and assert valid
                        logic [2*WIDTH-1:0] final_Q;
                        final_Q = next_Q(Q_reg, divisor_reg);
                        quotient  <= final_Q[WIDTH-1:0];
                        remainder <= final_Q[2*WIDTH-1:WIDTH];
                        valid     <= 1'b1;
                        state     <= IDLE;
                        step_counter <= '0;
                    end
                end
            endcase
        end
    end

endmodule
