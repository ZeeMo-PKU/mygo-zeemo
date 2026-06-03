module thermostat (
    input wire i_clk,
    input wire i_rst,                     // active low
    input wire [5:0] i_temp_feedback,
    input wire i_fan_on,
    input wire i_enable,
    input wire i_fault,
    input wire i_clr,
    output reg o_heater_full,
    output reg o_heater_medium,
    output reg o_heater_low,
    output reg o_aircon_full,
    output reg o_aircon_medium,
    output reg o_aircon_low,
    output reg o_fan,
    output reg [2:0] o_state
);

    // State encoding
    localparam HEAT_LOW  = 3'b000,
               HEAT_MED  = 3'b001,
               HEAT_FULL = 3'b010,
               AMBIENT   = 3'b011,
               COOL_LOW  = 3'b100,
               COOL_MED  = 3'b101,
               COOL_FULL = 3'b110;

    reg [2:0] state;

    // State register with asynchronous reset
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            state <= AMBIENT;
        end else begin
            // Clear fault or disable
            if (i_clr) begin
                state <= AMBIENT;
            end else if (!i_enable) begin
                state <= AMBIENT;
            end else begin
                // Normal temperature feedback evaluation (cold priority first, then hot)
                if (i_temp_feedback[5]) begin           // full_cold
                    state <= HEAT_FULL;
                end else if (i_temp_feedback[4]) begin   // medium_cold
                    state <= HEAT_MED;
                end else if (i_temp_feedback[3]) begin   // low_cold
                    state <= HEAT_LOW;
                end else if (i_temp_feedback[0]) begin   // full_hot
                    state <= COOL_FULL;
                end else if (i_temp_feedback[1]) begin   // medium_hot
                    state <= COOL_MED;
                end else if (i_temp_feedback[2]) begin   // low_hot
                    state <= COOL_LOW;
                end else begin
                    state <= AMBIENT;
                end
            end
        end
    end

    // Output register with asynchronous reset and override logic
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            o_heater_full   <= 1'b0;
            o_heater_medium <= 1'b0;
            o_heater_low    <= 1'b0;
            o_aircon_full   <= 1'b0;
            o_aircon_medium <= 1'b0;
            o_aircon_low    <= 1'b0;
            o_fan           <= 1'b0;
            o_state         <= AMBIENT;
        end else begin
            if (i_fault) begin
                // Fault override: all control outputs forced to 0
                o_heater_full   <= 1'b0;
                o_heater_medium <= 1'b0;
                o_heater_low    <= 1'b0;
                o_aircon_full   <= 1'b0;
                o_aircon_medium <= 1'b0;
                o_aircon_low    <= 1'b0;
                o_fan           <= 1'b0;
                o_state         <= state;   // state may still transition
            end else if (!i_enable) begin
                // Disable: all outputs forced to 0, state forced to AMBIENT
                o_heater_full   <= 1'b0;
                o_heater_medium <= 1'b0;
                o_heater_low    <= 1'b0;
                o_aircon_full   <= 1'b0;
                o_aircon_medium <= 1'b0;
                o_aircon_low    <= 1'b0;
                o_fan           <= 1'b0;
                o_state         <= state;   // state is guaranteed AMBIENT
            end else begin
                // Normal operation: decode state
                case (state)
                    HEAT_FULL: begin
                        o_heater_full   <= 1'b1;
                        o_heater_medium <= 1'b0;
                        o_heater_low    <= 1'b0;
                        o_aircon_full   <= 1'b0;
                        o_aircon_medium <= 1'b0;
                        o_aircon_low    <= 1'b0;
                    end
                    HEAT_MED: begin
                        o_heater_full   <= 1'b0;
                        o_heater_medium <= 1'b1;
                        o_heater_low    <= 1'b0;
                        o_aircon_full   <= 1'b0;
                        o_aircon_medium <= 1'b0;
                        o_aircon_low    <= 1'b0;
                    end
                    HEAT_LOW: begin
                        o_heater_full   <= 1'b0;
                        o_heater_medium <= 1'b0;
                        o_heater_low    <= 1'b1;
                        o_aircon_full   <= 1'b0;
                        o_aircon_medium <= 1'b0;
                        o_aircon_low    <= 1'b0;
                    end
                    COOL_FULL: begin
                        o_heater_full   <= 1'b0;
                        o_heater_medium <= 1'b0;
                        o_heater_low    <= 1'b0;
                        o_aircon_full   <= 1'b1;
                        o_aircon_medium <= 1'b0;
                        o_aircon_low    <= 1'b0;
                    end
                    COOL_MED: begin
                        o_heater_full   <= 1'b0;
                        o_heater_medium <= 1'b0;
                        o_heater_low    <= 1'b0;
                        o_aircon_full   <= 1'b0;
                        o_aircon_medium <= 1'b1;
                        o_aircon_low    <= 1'b0;
                    end
                    COOL_LOW: begin
                        o_heater_full   <= 1'b0;
                        o_heater_medium <= 1'b0;
                        o_heater_low    <= 1'b0;
                        o_aircon_full   <= 1'b0;
                        o_aircon_medium <= 1'b0;
                        o_aircon_low    <= 1'b1;
                    end
                    AMBIENT: begin
                        o_heater_full   <= 1'b0;
                        o_heater_medium <= 1'b0;
                        o_heater_low    <= 1'b0;
                        o_aircon_full   <= 1'b0;
                        o_aircon_medium <= 1'b0;
                        o_aircon_low    <= 1'b0;
                    end
                    default: begin
                        o_heater_full   <= 1'b0;
                        o_heater_medium <= 1'b0;
                        o_heater_low    <= 1'b0;
                        o_aircon_full   <= 1'b0;
                        o_aircon_medium <= 1'b0;
                        o_aircon_low    <= 1'b0;
                    end
                endcase
                // Fan: on if any heating/cooling output is active OR user fan_on
                o_fan <= ((state != AMBIENT) || i_fan_on);
                o_state <= state;
            end
        end
    end

endmodule
