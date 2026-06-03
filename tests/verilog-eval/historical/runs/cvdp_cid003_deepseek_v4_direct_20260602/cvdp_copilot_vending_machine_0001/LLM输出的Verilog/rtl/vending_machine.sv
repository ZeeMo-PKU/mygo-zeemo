// rtl/vending_machine.sv
module vending_machine (
    input  logic        clk,
    input  logic        rst,
    input  logic        item_button,
    input  logic [2:0]  item_selected,
    input  logic [3:0]  coin_input,
    input  logic        cancel,
    output logic        dispense_item,
    output logic        return_change,
    output logic [4:0]  item_price,
    output logic [4:0]  change_amount,
    output logic [2:0]  dispense_item_id,
    output logic        error,
    output logic        return_money
);

    // FSM states
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_ITEM_SEL,
        ST_PAYMENT_VAL,
        ST_DISPENSE,
        ST_RET_CHANGE,
        ST_RET_MONEY
    } state_t;

    state_t state, next_state;

    // Internal registers
    logic [2:0] selected_item_id;
    logic [4:0] item_price_reg;
    logic [5:0] coins_accumulated;   // 6 bits to allow reasonable accumulation

    // Edge detection for toggle signals
    logic item_button_d, cancel_d;

    // Next values for registered signals
    logic [2:0] next_selected_item_id;
    logic [4:0] next_item_price_reg;
    logic [5:0] next_coins_accumulated;

    // Rising‑edge detection (combinational)
    logic posedge_item_button, posedge_cancel;
    assign posedge_item_button = item_button && !item_button_d;
    assign posedge_cancel      = cancel      && !cancel_d;

    // Continuous item price output
    assign item_price = item_price_reg;

    // ------------------------------------------------------------------------
    // Combinational next‑state and output logic
    // ------------------------------------------------------------------------
    always_comb begin
        // Defaults: hold state, keep registered values, outputs low
        next_state                 = state;
        next_selected_item_id      = selected_item_id;
        next_item_price_reg        = item_price_reg;
        next_coins_accumulated     = coins_accumulated;

        dispense_item    = 1'b0;
        return_change    = 1'b0;
        error            = 1'b0;
        return_money     = 1'b0;
        dispense_item_id = 1'b0;
        change_amount    = 5'b0;

        case (state)
            ST_IDLE: begin
                if (posedge_item_button) begin
                    next_state = ST_ITEM_SEL;
                    next_coins_accumulated = 6'b0;
                    next_selected_item_id  = 3'b0;
                    next_item_price_reg    = 5'b0;
                end else if (coin_input != 4'b0) begin
                    next_state = ST_RET_MONEY;
                end else begin
                    next_coins_accumulated = 6'b0;
                    next_selected_item_id  = 3'b0;
                    next_item_price_reg    = 5'b0;
                end
            end

            ST_ITEM_SEL: begin
                if (posedge_cancel) begin
                    next_state = ST_RET_MONEY;
                end else if (coin_input != 4'b0) begin
                    next_state = ST_RET_MONEY;
                end else if (item_selected inside {3'd1, 3'd2, 3'd3, 3'd4}) begin
                    next_state = ST_PAYMENT_VAL;
                    next_selected_item_id = item_selected;
                    unique case (item_selected)
                        3'd1: next_item_price_reg = 5'd5;
                        3'd2: next_item_price_reg = 5'd10;
                        3'd3: next_item_price_reg = 5'd15;
                        3'd4: next_item_price_reg = 5'd20;
                        default: next_item_price_reg = 5'd0;
                    endcase
                end else if (item_selected != 3'b0) begin
                    next_state = ST_RET_MONEY;
                end
            end

            ST_PAYMENT_VAL: begin
                if (posedge_cancel) begin
                    next_state = ST_RET_MONEY;
                end else if (coin_input != 4'b0) begin
                    if (coin_input inside {4'd1, 4'd2, 4'd5, 4'd10}) begin
                        next_coins_accumulated = coins_accumulated + coin_input;
                        if (next_coins_accumulated >= item_price_reg) begin
                            next_state = ST_DISPENSE;
                        end else begin
                            next_state = ST_PAYMENT_VAL;
                        end
                    end else begin
                        next_state = ST_RET_MONEY;
                    end
                end
            end

            ST_DISPENSE: begin
                dispense_item    = 1'b1;
                dispense_item_id = selected_item_id;

                if (coins_accumulated > item_price_reg) begin
                    next_state = ST_RET_CHANGE;
                end else begin
                    next_state = ST_IDLE;
                    // exact amount; clear accumulators when going to IDLE
                    next_coins_accumulated = 6'b0;
                    next_selected_item_id  = 3'b0;
                    next_item_price_reg    = 5'b0;
                end
            end

            ST_RET_CHANGE: begin
                return_change = 1'b1;
                change_amount = coins_accumulated - item_price_reg;
                next_state = ST_IDLE;
                next_coins_accumulated = 6'b0;
                next_selected_item_id  = 3'b0;
                next_item_price_reg    = 5'b0;
            end

            ST_RET_MONEY: begin
                error = 1'b1;
                if (coins_accumulated > 0) begin
                    return_money = 1'b1;
                end
                next_state = ST_IDLE;
                next_coins_accumulated = 6'b0;
                next_selected_item_id  = 3'b0;
                next_item_price_reg    = 5'b0;
            end

            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------------------
    // Sequential register updates
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state              <= ST_IDLE;
            coins_accumulated  <= 6'b0;
            selected_item_id   <= 3'b0;
            item_price_reg     <= 5'b0;
            item_button_d     <= 1'b0;
            cancel_d          <= 1'b0;
        end else begin
            item_button_d <= item_button;
            cancel_d      <= cancel;
            state         <= next_state;

            coins_accumulated <= next_coins_accumulated;
            selected_item_id  <= next_selected_item_id;
            item_price_reg    <= next_item_price_reg;
        end
    end

endmodule
