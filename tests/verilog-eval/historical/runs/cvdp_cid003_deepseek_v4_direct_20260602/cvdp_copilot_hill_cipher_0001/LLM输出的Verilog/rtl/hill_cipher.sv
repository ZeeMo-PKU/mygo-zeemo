module hill_cipher (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [14:0] plaintext,
    input  logic [44:0] key,
    output logic [14:0] ciphertext,
    output logic        done
);

    // FSM state definition
    typedef enum logic [1:0] { IDLE, COMP0, COMP1, COMP2 } state_t;
    state_t state;

    // Captured plaintext and key matrices (flat view of 3x3 key)
    logic [4:0] P0, P1, P2;
    logic [4:0] K00, K01, K02,
                K10, K11, K12,
                K20, K21, K22;

    // Registered partial results for rows 0 and 1
    logic [4:0] C0_reg, C1_reg;

    // Combinational modulo‑26 results for each row
    wire [4:0] row0_mod = (K00*P0 + K01*P1 + K02*P2) % 26;
    wire [4:0] row1_mod = (K10*P0 + K11*P1 + K12*P2) % 26;
    wire [4:0] row2_mod = (K20*P0 + K21*P1 + K22*P2) % 26;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            done       <= 1'b0;
            ciphertext <= 15'd0;
        end else begin
            // default values for signals that are only set in some states
            done       <= 1'b0;
            ciphertext <= ciphertext;  // retain value, will be overwritten when valid

            case (state)
                IDLE: begin
                    if (start) begin
                        // Latch plaintext letters
                        P0 <= plaintext[14:10];
                        P1 <= plaintext[9:5];
                        P2 <= plaintext[4:0];

                        // Latch key matrix elements
                        K00 <= key[44:40]; K01 <= key[39:35]; K02 <= key[34:30];
                        K10 <= key[29:25]; K11 <= key[24:20]; K12 <= key[19:15];
                        K20 <= key[14:10]; K21 <= key[9:5];   K22 <= key[4:0];

                        state <= COMP0;
                    end
                end

                COMP0: begin
                    C0_reg <= row0_mod;
                    state  <= COMP1;
                end

                COMP1: begin
                    C1_reg <= row1_mod;
                    state  <= COMP2;
                end

                COMP2: begin
                    // Assemble final ciphertext: {row0, row1, row2}
                    ciphertext <= {C0_reg, C1_reg, row2_mod};
                    done       <= 1'b1;
                    state      <= IDLE;
                end
            endcase
        end
    end

endmodule
