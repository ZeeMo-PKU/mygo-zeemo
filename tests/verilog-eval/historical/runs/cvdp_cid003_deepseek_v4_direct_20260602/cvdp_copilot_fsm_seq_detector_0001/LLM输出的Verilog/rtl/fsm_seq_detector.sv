module fsm_seq_detector (
    input bit clk_in,
    input logic rst_in,
    input logic seq_in,
    output logic seq_detected
);

    typedef enum logic [2:0] {
        S0 = 3'b000,
        S1 = 3'b001,
        S2 = 3'b010,
        S3 = 3'b011,
        S4 = 3'b100,
        S5 = 3'b101,
        S6 = 3'b110,
        S7 = 3'b111
    } state_t;

    state_t cur_state, next_state;
    logic seq_detected_w;

    // Next state and output combinational logic
    always_comb begin
        // Default assignments
        next_state = cur_state;
        seq_detected_w = 1'b0;

        case (cur_state)
            S0: begin
                if (seq_in)
                    next_state = S1;
                else
                    next_state = S0;
            end
            S1: begin
                if (seq_in)
                    next_state = S1;
                else
                    next_state = S2;
            end
            S2: begin
                if (seq_in)
                    next_state = S3;
                else
                    next_state = S0;
            end
            S3: begin
                if (seq_in)
                    next_state = S4;
                else
                    next_state = S2;
            end
            S4: begin
                if (seq_in)
                    next_state = S1;
                else
                    next_state = S5;
            end
            S5: begin
                if (seq_in)
                    next_state = S3;
                else
                    next_state = S6;
            end
            S6: begin
                if (seq_in)
                    next_state = S1;
                else
                    next_state = S7;
            end
            S7: begin
                if (seq_in) begin
                    seq_detected_w = 1'b1;
                    next_state = S1;
                end else begin
                    next_state = S0;
                end
            end
            default: next_state = S0;
        endcase
    end

    // Sequential state and output register
    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            cur_state <= S0;
            seq_detected <= 1'b0;
        end else begin
            cur_state <= next_state;
            seq_detected <= seq_detected_w;
        end
    end

endmodule
