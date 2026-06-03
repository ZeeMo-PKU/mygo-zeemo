module hebbian_rule (
    input logic clk,
    input logic rst,
    input logic start,
    input logic signed [3:0] a,
    input logic signed [3:0] b,
    input logic [1:0] gate_select,
    output logic signed [3:0] w1,
    output logic signed [3:0] w2,
    output logic signed [3:0] bias,
    output logic [3:0] present_state,
    output logic [3:0] next_state
);
    // State encoding
    typedef enum logic [3:0] {
        S0 = 4'd0,
        S1 = 4'd1,
        S2 = 4'd2,
        S3 = 4'd3,
        S4 = 4'd4,
        S5 = 4'd5,
        S6 = 4'd6,
        S7 = 4'd7,
        S8 = 4'd8,
        S9 = 4'd9,
        S10 = 4'd10
    } state_t;

    state_t state, next_state_int;
    logic [1:0] iter_count;
    logic signed [3:0] x1, x2, target;
    logic signed [3:0] w1_reg, w2_reg, bias_reg;

    assign present_state = state;
    assign next_state = next_state_int;
    assign w1 = w1_reg;
    assign w2 = w2_reg;
    assign bias = bias_reg;

    // Combinational next state logic
    always_comb begin
        next_state_int = state;
        case (state)
            S0: if (start) next_state_int = S1; else next_state_int = S0;
            S1: begin
                case (gate_select)
                    2'b00: next_state_int = S2;
                    2'b01: next_state_int = S3;
                    2'b10: next_state_int = S4;
                    2'b11: next_state_int = S5;
                    default: next_state_int = S2;
                endcase
            end
            S2: next_state_int = S6;
            S3: next_state_int = S6;
            S4: next_state_int = S6;
            S5: next_state_int = S6;
            S6: next_state_int = S7;
            S7: next_state_int = S8;
            S8: next_state_int = S9;
            S9: begin
                if (iter_count == 2'd3)
                    next_state_int = S10;
                else
                    next_state_int = S1;
            end
            S10: next_state_int = S0;
            default: next_state_int = S0;
        endcase
    end

    // Sequential logic for state and data
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S0;
            iter_count <= 0;
            x1 <= 0;
            x2 <= 0;
            target <= 0;
            w1_reg <= 0;
            w2_reg <= 0;
            bias_reg <= 0;
        end else begin
            state <= next_state_int;
            case (state)
                S0: if (start) begin
                    iter_count <= 0;
                    w1_reg <= 0;
                    w2_reg <= 0;
                    bias_reg <= 0;
                end
                S1: begin
                    x1 <= a;
                    x2 <= b;
                end
                S2: begin
                    if ((x1 == 4'sd1) && (x2 == 4'sd1))
                        target <= 4'sd1;
                    else
                        target <= -4'sd1;  // -1
                end
                S3: begin
                    if ((x1 == 4'sd1) || (x2 == 4'sd1))
                        target <= 4'sd1;
                    else
                        target <= -4'sd1;
                end
                S4: begin
                    if (!((x1 == 4'sd1) && (x2 == 4'sd1)))
                        target <= 4'sd1;
                    else
                        target <= -4'sd1;
                end
                S5: begin
                    if (!((x1 == 4'sd1) || (x2 == 4'sd1)))
                        target <= 4'sd1;
                    else
                        target <= -4'sd1;
                end
                // S6: no operation
                // S7: no operation (deltas computed in S8 using x1,x2,target)
                S8: begin
                    // Compute deltas using simple mux logic (since target and inputs are ±1)
                    w1_reg <= w1_reg + ((target == 4'sd1) ? x1 : -x1);
                    w2_reg <= w2_reg + ((target == 4'sd1) ? x2 : -x2);
                    bias_reg <= bias_reg + target;
                end
                S9: begin
                    if (iter_count != 2'd3)
                        iter_count <= iter_count + 1;
                    // else remain at 3 (done)
                end
                // S10: no operation, just transition
            endcase
        end
    end

endmodule
