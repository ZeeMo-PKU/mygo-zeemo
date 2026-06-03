// rtl/factorial.sv
module factorial (
    input  logic        clk,
    input  logic        arst_n,
    input  logic [4:0]  num_in,
    input  logic        start,
    output logic        busy,
    output logic        done,
    output logic [63:0] fact
);

    typedef enum logic [1:0] {
        IDLE,
        BUSY,
        DONE
    } state_t;

    state_t       state, next_state;
    logic [4:0]   captured_num;
    logic [4:0]   counter;
    logic [63:0]  product;
    logic [63:0]  fact_reg;

    // State registers and synchronous logic
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            state        <= IDLE;
            captured_num <= '0;
            counter      <= '0;
            product      <= '0;
            fact_reg     <= '0;
        end else begin
            state     <= next_state;
            case (state)
                IDLE: begin
                    if (start) begin
                        captured_num <= num_in;
                        if (num_in == 5'd0) begin
                            // 0! = 1, go directly to DONE
                            product <= 64'd1;
                        end else begin
                            product <= 64'd1;
                            counter <= 5'd1;
                        end
                    end
                end

                BUSY: begin
                    // In each BUSY cycle, multiply by current counter and increment
                    product <= product * counter;
                    counter <= counter + 1'b1;
                end

                DONE: begin
                    // Latch the final result
                    fact_reg <= product;
                end

                default: ;
            endcase
        end
    end

    // Next state logic (combinational)
    always_comb begin
        next_state = state;  // default: stay
        case (state)
            IDLE: begin
                if (start) begin
                    if (num_in == 5'd0)
                        next_state = DONE;
                    else
                        next_state = BUSY;
                end
            end

            BUSY: begin
                // After the current multiplication, if counter was equal to captured_num,
                // this was the last iteration, go to DONE.
                if (counter == captured_num)
                    next_state = DONE;
                else
                    next_state = BUSY;
            end

            DONE: begin
                // Always return to IDLE after one cycle in DONE
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output assignments
    assign busy = (state == BUSY);
    assign done = (state == DONE);
    assign fact = fact_reg;

endmodule
