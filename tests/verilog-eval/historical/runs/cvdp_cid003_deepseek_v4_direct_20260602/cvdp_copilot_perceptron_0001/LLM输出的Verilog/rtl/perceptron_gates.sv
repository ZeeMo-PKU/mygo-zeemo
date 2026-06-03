// rtl/perceptron_gates.sv
module perceptron_gates (
    input  logic                clk,
    input  logic                rst_n,
    input  logic signed [3:0]   x1,
    input  logic signed [3:0]   x2,
    input  logic                learning_rate,
    input  logic signed [3:0]   threshold,
    input  logic [1:0]          gate_select,
    output logic signed [3:0]   percep_w1,
    output logic signed [3:0]   percep_w2,
    output logic signed [3:0]   percep_bias,
    output logic [3:0]          present_addr,
    output logic                stop,
    output logic [2:0]          input_index,
    output logic signed [3:0]   y_in,
    output logic signed [3:0]   y,
    output logic signed [3:0]   prev_percep_wt_1,
    output logic signed [3:0]   prev_percep_wt_2,
    output logic signed [3:0]   prev_percep_bias
);

    // -------------------------------------------------------------------------
    // Gate target submodule instantiation
    // -------------------------------------------------------------------------
    logic signed [3:0] o1, o2, o3, o4;
    gate_target u_gate_target (
        .gate_select(gate_select),
        .o_1       (o1),
        .o_2       (o2),
        .o_3       (o3),
        .o_4       (o4)
    );

    // -------------------------------------------------------------------------
    // Internal registers and signals
    // -------------------------------------------------------------------------
    localparam [3:0] ST_INIT_W      = 4'd0;
    localparam [3:0] ST_COMPUTE_Y   = 4'd1;
    localparam [3:0] ST_SELECT_T    = 4'd2;
    localparam [3:0] ST_UPDATE_W    = 4'd3;
    localparam [3:0] ST_CHECK_CONV  = 4'd4;   // not used for critical logic
    localparam [3:0] ST_EPOCH_END   = 4'd5;

    // Microcode ROM (6 entries, each 3-bit opcode)
    localparam [2:0] OP_INIT_W     = 3'd0;
    localparam [2:0] OP_COMPUTE_Y  = 3'd1;
    localparam [2:0] OP_SELECT_T   = 3'd2;
    localparam [2:0] OP_UPDATE_W   = 3'd3;
    localparam [2:0] OP_CHECK_CONV = 3'd4;
    localparam [2:0] OP_EPOCH_END  = 3'd5;

    logic [2:0] rom [0:5] = '{
        OP_INIT_W,
        OP_COMPUTE_Y,
        OP_SELECT_T,
        OP_UPDATE_W,
        OP_CHECK_CONV,
        OP_EPOCH_END
    };
    wire [2:0] micro_op = rom[present_addr];

    // State register (microcode ROM address)
    logic [3:0] state;
    assign present_addr = state;
    wire [3:0] next_state;

    // Datapath registers
    logic signed [3:0] percep_w1_reg, percep_w2_reg, percep_bias_reg;
    logic [2:0]        input_index_reg;
    logic              stop_reg;
    logic signed [3:0] y_in_reg, y_reg;
    logic signed [3:0] prev_wt1_reg, prev_wt2_reg, prev_bias_reg;
    logic              epoch_update_flag;   // 1 if any (wt,bias) update nonzero in the current epoch

    // Target value register, loaded in SELECT_T state
    logic signed [3:0] target_val;

    // Weight update values computed in UPDATE_W state
    logic signed [3:0] wt1_upd, wt2_upd, bias_upd;

    // Convergence condition (end of epoch, no updates)
    wire converged = (input_index_reg == 3'd3) && (epoch_update_flag == 1'b0);

    // -------------------------------------------------------------------------
    // Next-state logic (combinational)
    // -------------------------------------------------------------------------
    always_comb begin
        case (state)
            ST_INIT_W     : next_state = ST_COMPUTE_Y;
            ST_COMPUTE_Y  : next_state = ST_SELECT_T;
            ST_SELECT_T   : next_state = ST_UPDATE_W;
            ST_UPDATE_W   : next_state = ST_CHECK_CONV;
            ST_CHECK_CONV : next_state = ST_EPOCH_END;
            ST_EPOCH_END  : next_state = converged ? ST_EPOCH_END : ST_COMPUTE_Y;
            default       : next_state = ST_COMPUTE_Y;
        endcase
    end

    // -------------------------------------------------------------------------
    // Sequential logic
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ST_INIT_W;
            percep_w1_reg    <= 4'd0;
            percep_w2_reg    <= 4'd0;
            percep_bias_reg  <= 4'd0;
            input_index_reg  <= 3'd0;
            stop_reg         <= 1'b0;
            y_in_reg         <= 4'd0;
            y_reg            <= 4'd0;
            prev_wt1_reg     <= 4'd0;
            prev_wt2_reg     <= 4'd0;
            prev_bias_reg    <= 4'd0;
            epoch_update_flag <= 1'b0;
            target_val       <= 4'd0;
            wt1_upd          <= 4'd0;
            wt2_upd          <= 4'd0;
            bias_upd         <= 4'd0;
        end else begin
            // Default assignment
            state <= next_state;

            // ---- State-specific actions ----
            case (micro_op)
                OP_INIT_W: begin
                    percep_w1_reg    <= 4'd0;
                    percep_w2_reg    <= 4'd0;
                    percep_bias_reg  <= 4'd0;
                    input_index_reg  <= 3'd0;
                    stop_reg         <= 1'b0;
                    epoch_update_flag <= 1'b0;
                end

                OP_COMPUTE_Y: begin
                    // Compute y_in and y using current weights, x1, x2
                    y_in_reg <= $signed(percep_bias_reg)
                              + ($signed(percep_w1_reg) * $signed(x1))
                              + ($signed(percep_w2_reg) * $signed(x2));
                    y_reg    <= (($signed(percep_bias_reg)
                                + ($signed(percep_w1_reg) * $signed(x1))
                                + ($signed(percep_w2_reg) * $signed(x2))) > $signed(threshold)) ? 4'd1 :
                                (($signed(percep_bias_reg)
                                + ($signed(percep_w1_reg) * $signed(x1))
                                + ($signed(percep_w2_reg) * $signed(x2))) < $signed(threshold)) ? -4'd1 : 4'd0;
                end

                OP_SELECT_T: begin
                    // Select target based on input_index and gate type
                    case (input_index_reg)
                        3'd0: target_val <= o1;
                        3'd1: target_val <= o2;
                        3'd2: target_val <= o3;
                        3'd3: target_val <= o4;
                        default: target_val <= 4'd0;
                    endcase
                end

                OP_UPDATE_W: begin
                    // Compute updates
                    if (learning_rate && (y_reg != target_val)) begin
                        wt1_upd  <= $signed(x1) * $signed(target_val);
                        wt2_upd  <= $signed(x2) * $signed(target_val);
                        bias_upd <= $signed(target_val);
                    end else begin
                        wt1_upd  <= 4'd0;
                        wt2_upd  <= 4'd0;
                        bias_upd <= 4'd0;
                    end

                    // Apply updates to current weights
                    percep_w1_reg   <= $signed(percep_w1_reg) + $signed(wt1_upd);
                    percep_w2_reg   <= $signed(percep_w2_reg) + $signed(wt2_upd);
                    percep_bias_reg <= $signed(percep_bias_reg) + $signed(bias_upd);

                    // Store updates as previous iteration values
                    prev_wt1_reg  <= wt1_upd;
                    prev_wt2_reg  <= wt2_upd;
                    prev_bias_reg <= bias_upd;

                    // Mark epoch as having a nonzero update
                    if (wt1_upd != 4'd0 || wt2_upd != 4'd0 || bias_upd != 4'd0)
                        epoch_update_flag <= 1'b1;
                end

                OP_EPOCH_END: begin
                    if (converged) begin
                        stop_reg <= 1'b1;
                        // Keep input_index unchanged
                    end else begin
                        // Prepare next epoch: clear flag and reset index
                        input_index_reg  <= 3'd0;
                        epoch_update_flag <= 1'b0;
                    end
                    // If in the middle of an epoch, just advance input index
                    if (!converged && input_index_reg != 3'd3) begin
                        input_index_reg <= input_index_reg + 1;
                    end
                end

                default: ; // OP_CHECK_CONV does nothing
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------------------------
    assign percep_w1        = percep_w1_reg;
    assign percep_w2        = percep_w2_reg;
    assign percep_bias      = percep_bias_reg;
    assign stop             = stop_reg;
    assign input_index      = input_index_reg;
    assign y_in             = y_in_reg;
    assign y                = y_reg;
    assign prev_percep_wt_1 = prev_wt1_reg;
    assign prev_percep_wt_2 = prev_wt2_reg;
    assign prev_percep_bias = prev_bias_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: gate_target
// -----------------------------------------------------------------------------
module gate_target (
    input  logic [1:0]          gate_select,
    output logic signed [3:0]   o_1,
    output logic signed [3:0]   o_2,
    output logic signed [3:0]   o_3,
    output logic signed [3:0]   o_4
);
    always_comb begin
        unique case (gate_select)
            2'b00: begin // AND
                o_1 =  4'd1;
                o_2 = -4'd1;
                o_3 = -4'd1;
                o_4 = -4'd1;
            end
            2'b01: begin // OR
                o_1 =  4'd1;
                o_2 =  4'd1;
                o_3 =  4'd1;
                o_4 = -4'd1;
            end
            2'b10: begin // NAND (identical to OR per specification)
                o_1 =  4'd1;
                o_2 =  4'd1;
                o_3 =  4'd1;
                o_4 = -4'd1;
            end
            2'b11: begin // NOR
                o_1 =  4'd1;
                o_2 = -4'd1;
                o_3 = -4'd1;
                o_4 = -4'd1;
            end
            default: begin
                o_1 = '0;
                o_2 = '0;
                o_3 = '0;
                o_4 = '0;
            end
        endcase
    end
endmodule
