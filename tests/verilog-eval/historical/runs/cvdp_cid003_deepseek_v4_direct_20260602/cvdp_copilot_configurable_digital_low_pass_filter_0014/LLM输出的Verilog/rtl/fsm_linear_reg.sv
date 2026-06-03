module fsm_linear_reg #(
    parameter DATA_WIDTH = 16
) (
    input  logic                         clk,
    input  logic                         reset,
    input  logic                         start,
    input  logic signed [DATA_WIDTH-1:0] x_in,
    input  logic signed [DATA_WIDTH-1:0] w_in,
    input  logic signed [DATA_WIDTH-1:0] b_in,
    output logic signed [2*DATA_WIDTH-1:0] result1,
    output logic signed [DATA_WIDTH:0]     result2,
    output logic                           done
);

    // FSM state encoding
    localparam IDLE    = 2'd0;
    localparam COMPUTE = 2'd1;
    localparam DONE    = 2'd2;

    // Internal registers
    logic [1:0] state, next_state;
    logic       comp_cnt;               // 0: first cycle of COMPUTE, 1: second cycle
    logic signed [2*DATA_WIDTH-1:0] result1_temp;
    logic signed [DATA_WIDTH:0]     result2_temp;

    // Next state logic
    always_comb begin
        next_state = state;  // default stay
        case (state)
            IDLE:    if (start) next_state = COMPUTE;
            COMPUTE: if (comp_cnt) next_state = DONE;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic for state, control and outputs
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state         <= IDLE;
            comp_cnt      <= 1'b0;
            result1       <= '0;
            result2       <= '0;
            done          <= 1'b0;
            result1_temp  <= '0;
            result2_temp  <= '0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    comp_cnt <= 1'b0;
                    result1  <= '0;
                    result2  <= '0;
                    done     <= 1'b0;
                end

                COMPUTE: begin
                    done <= 1'b0;
                    if (comp_cnt == 1'b0) begin
                        // First cycle: compute temporary values
                        result1_temp <= (w_in * x_in) >>> 1;
                        result2_temp <= b_in + (x_in >>> 2);
                        comp_cnt     <= 1'b1;
                        result1      <= '0;
                        result2      <= '0;
                    end else begin  // comp_cnt == 1'b1
                        // Second cycle: load outputs
                        result1  <= result1_temp;
                        result2  <= result2_temp;
                        comp_cnt <= 1'b0;
                    end
                end

                DONE: begin
                    done     <= 1'b1;
                    comp_cnt <= 1'b0;
                    // result1 and result2 retain their loaded values
                end

                default: begin
                    comp_cnt <= 1'b0;
                    result1  <= '0;
                    result2  <= '0;
                    done     <= 1'b0;
                end
            endcase
        end
    end

endmodule
