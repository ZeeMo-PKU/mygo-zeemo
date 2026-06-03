// rtl/vga_controller.sv
module vga_controller (
    input  logic        clock,
    input  logic        reset,
    input  logic [7:0]  color_in,
    output logic        hsync,
    output logic        vsync,
    output logic [7:0]  red,
    output logic [7:0]  green,
    output logic [7:0]  blue,
    output logic [9:0]  next_x,
    output logic [9:0]  next_y,
    output logic        sync,
    output logic        clk,
    output logic        blank
);

    // VGA 640x480 timing constants
    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_PULSE  = 96;
    localparam H_BACK   = 48;
    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_PULSE  = 2;
    localparam V_BACK   = 33;

    typedef enum logic [1:0] {
        H_ST_ACTIVE,
        H_ST_FRONT,
        H_ST_PULSE,
        H_ST_BACK
    } h_state_t;

    typedef enum logic [1:0] {
        V_ST_ACTIVE,
        V_ST_FRONT,
        V_ST_PULSE,
        V_ST_BACK
    } v_state_t;

    h_state_t h_state;
    v_state_t v_state;
    logic [9:0] h_counter;
    logic [9:0] v_counter;
    logic       line_done;

    // Direct / constant outputs
    assign sync = 1'b0;
    assign clk  = clock;

    // Single always_ff block for all sequential logic
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            h_state   <= H_ST_ACTIVE;
            v_state   <= V_ST_ACTIVE;
            h_counter <= 10'd0;
            v_counter <= 10'd0;
            line_done <= 1'b0;
            hsync     <= 1'b1;
            vsync     <= 1'b1;
            red       <= 8'd0;
            green     <= 8'd0;
            blue      <= 8'd0;
            next_x    <= 10'd0;
            next_y    <= 10'd0;
            blank     <= 1'b0;
        end else begin
            // Horizontal state machine and counter
            case (h_state)
                H_ST_ACTIVE: begin
                    if (h_counter < H_ACTIVE - 1) begin
                        h_counter <= h_counter + 10'd1;
                    end else begin
                        h_counter <= 10'd0;
                        h_state   <= H_ST_FRONT;
                    end
                end
                H_ST_FRONT: begin
                    if (h_counter < H_FRONT - 1) begin
                        h_counter <= h_counter + 10'd1;
                    end else begin
                        h_counter <= 10'd0;
                        h_state   <= H_ST_PULSE;
                    end
                end
                H_ST_PULSE: begin
                    if (h_counter < H_PULSE - 1) begin
                        h_counter <= h_counter + 10'd1;
                    end else begin
                        h_counter <= 10'd0;
                        h_state   <= H_ST_BACK;
                    end
                end
                H_ST_BACK: begin
                    if (h_counter < H_BACK - 1) begin
                        h_counter <= h_counter + 10'd1;
                    end else begin
                        h_counter <= 10'd0;
                        h_state   <= H_ST_ACTIVE;
                    end
                end
                default: begin
                    h_counter <= 10'd0;
                    h_state   <= H_ST_ACTIVE;
                end
            endcase

            // line_done pulse at the end of the back porch
            line_done <= (h_state == H_ST_BACK) && (h_counter == (H_BACK - 1));

            // Vertical state machine – advances only when a horizontal line completes
            if ((h_state == H_ST_BACK) && (h_counter == (H_BACK - 1))) begin
                case (v_state)
                    V_ST_ACTIVE: begin
                        if (v_counter < V_ACTIVE - 1) begin
                            v_counter <= v_counter + 10'd1;
                        end else begin
                            v_counter <= 10'd0;
                            v_state   <= V_ST_FRONT;
                        end
                    end
                    V_ST_FRONT: begin
                        if (v_counter < V_FRONT - 1) begin
                            v_counter <= v_counter + 10'd1;
                        end else begin
                            v_counter <= 10'd0;
                            v_state   <= V_ST_PULSE;
                        end
                    end
                    V_ST_PULSE: begin
                        if (v_counter < V_PULSE - 1) begin
                            v_counter <= v_counter + 10'd1;
                        end else begin
                            v_counter <= 10'd0;
                            v_state   <= V_ST_BACK;
                        end
                    end
                    V_ST_BACK: begin
                        if (v_counter < V_BACK - 1) begin
                            v_counter <= v_counter + 10'd1;
                        end else begin
                            v_counter <= 10'd0;
                            v_state   <= V_ST_ACTIVE;
                        end
                    end
                    default: begin
                        v_counter <= 10'd0;
                        v_state   <= V_ST_ACTIVE;
                    end
                endcase
            end

            // Sync, blank, coordinates and color outputs (registered)
            hsync  <= (h_state != H_ST_PULSE);
            vsync  <= (v_state != V_ST_PULSE);
            blank  <= (h_state != H_ST_ACTIVE) || (v_state != V_ST_ACTIVE);
            next_x <= (h_state == H_ST_ACTIVE) ? h_counter : 10'd0;
            next_y <= (v_state == V_ST_ACTIVE) ? v_counter : 10'd0;

            if ((h_state == H_ST_ACTIVE) && (v_state == V_ST_ACTIVE)) begin
                red   <= {color_in[7:5], 5'd0};
                green <= {color_in[4:2], 5'd0};
                blue  <= {color_in[1:0], 6'd0};
            end else begin
                red   <= 8'd0;
                green <= 8'd0;
                blue  <= 8'd0;
            end
        end
    end

endmodule
