module car_parking_system #(
    parameter int TOTAL_SPACES = 12
) (
    input logic clk,
    input logic reset,
    input logic vehicle_entry_sensor,
    input logic vehicle_exit_sensor,
    output logic [$clog2(TOTAL_SPACES)-1:0] available_spaces,
    output logic [$clog2(TOTAL_SPACES)-1:0] count_car,
    output logic led_status,
    output logic [6:0] seven_seg_display_available_tens,
    output logic [6:0] seven_seg_display_available_units,
    output logic [6:0] seven_seg_display_count_tens,
    output logic [6:0] seven_seg_display_count_units
);

    localparam int WIDTH = $clog2(TOTAL_SPACES);

    typedef enum logic [1:0] {
        IDLE,
        ENTRY,
        EXIT,
        FULL
    } state_t;

    state_t state, next_state;

    // Sequential part: state register, counters and LED
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            available_spaces <= TOTAL_SPACES;
            count_car <= 0;
        end else begin
            state <= next_state;

            // Update on state entry
            if (state == IDLE && next_state == ENTRY) begin
                available_spaces <= available_spaces - 1;
                count_car <= count_car + 1;
            end else if (state == IDLE && next_state == EXIT) begin
                available_spaces <= available_spaces + 1;
                count_car <= count_car - 1;
            end else if (state == FULL && next_state == EXIT) begin
                available_spaces <= available_spaces + 1;
                count_car <= count_car - 1;
            end
        end
    end

    // Next state combinatorics
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (vehicle_entry_sensor && available_spaces > 0)
                    next_state = ENTRY;
                else if (vehicle_entry_sensor && available_spaces == 0)
                    next_state = FULL;
                else if (vehicle_exit_sensor)
                    next_state = EXIT;
                else
                    next_state = IDLE;
            end
            ENTRY: begin
                if (!vehicle_entry_sensor)
                    next_state = IDLE;
                else
                    next_state = ENTRY;
            end
            EXIT: begin
                if (!vehicle_exit_sensor)
                    next_state = IDLE;
                else
                    next_state = EXIT;
            end
            FULL: begin
                if (vehicle_exit_sensor)
                    next_state = EXIT;
                else if (!vehicle_entry_sensor)
                    next_state = IDLE;
                else
                    next_state = FULL;
            end
            default: next_state = IDLE;
        endcase
    end

    // LED status: 1 = spaces available, 0 = full
    assign led_status = (available_spaces > 0);

    // 7-segment decoder (active high: bit6=A, bit5=B, ..., bit0=G)
    function automatic logic [6:0] seg_decode(input logic [3:0] digit);
        case (digit)
            4'd0:    seg_decode = 7'b1111110;
            4'd1:    seg_decode = 7'b0110000;
            4'd2:    seg_decode = 7'b1101101;
            4'd3:    seg_decode = 7'b1111001;
            4'd4:    seg_decode = 7'b0110011;
            4'd5:    seg_decode = 7'b1011011;
            4'd6:    seg_decode = 7'b1011111;
            4'd7:    seg_decode = 7'b1110000;
            4'd8:    seg_decode = 7'b1111111;
            4'd9:    seg_decode = 7'b1111011;
            default: seg_decode = 7'b0000000;
        endcase
    endfunction

    // Split available spaces into tens and units
    wire [6:0] avail_tens = seg_decode(available_spaces / 10);
    wire [6:0] avail_units = seg_decode(available_spaces % 10);

    // Split car count into tens and units
    wire [6:0] count_tens = seg_decode(count_car / 10);
    wire [6:0] count_units = seg_decode(count_car % 10);

    assign seven_seg_display_available_tens = avail_tens;
    assign seven_seg_display_available_units = avail_units;
    assign seven_seg_display_count_tens = count_tens;
    assign seven_seg_display_count_units = count_units;

endmodule
