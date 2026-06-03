module ethernet_parser (
    input wire clk,
    input wire rst,
    input wire vld,
    input wire sof,
    input wire [31:0] data,
    input wire eof,
    output wire ack,
    output reg [15:0] field,
    output reg field_vld
);

    localparam IDLE       = 2'd0,
               EXTRACTING = 2'd1,
               DONE       = 2'd2,
               FAIL_FINAL = 2'd3;

    reg [1:0] state, next_state;
    reg [3:0] beat_cnt, next_beat_cnt;
    reg [15:0] temp_extracted_field, next_temp;
    reg       early_eof, next_early_eof;

    assign ack = 1'b1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            beat_cnt <= 4'd0;
            temp_extracted_field <= 16'd0;
            field <= 16'd0;
            field_vld <= 1'b0;
            early_eof <= 1'b0;
        end else begin
            state <= next_state;
            beat_cnt <= next_beat_cnt;
            temp_extracted_field <= next_temp;
            field <= next_field;
            field_vld <= next_field_vld;
            early_eof <= next_early_eof;
        end
    end

    reg [15:0] next_field;
    reg        next_field_vld;

    always @(*) begin
        next_state = state;
        next_beat_cnt = beat_cnt;
        next_temp = temp_extracted_field;
        next_field = field;
        next_field_vld = field_vld;
        next_early_eof = early_eof;

        case (state)
            IDLE: begin
                next_field = 16'd0;
                next_field_vld = 1'b0;
                next_beat_cnt = 4'd0;
                next_temp = 16'd0;
                next_early_eof = 1'b0;
                if (vld && sof) begin
                    next_state = EXTRACTING;
                    next_beat_cnt = 4'd1;
                    next_early_eof = eof;
                end
            end

            EXTRACTING: begin
                next_field = 16'd0;
                next_field_vld = 1'b0;
                if (early_eof) begin
                    next_state = IDLE;
                    next_beat_cnt = 4'd0;
                    next_temp = 16'd0;
                    next_early_eof = 1'b0;
                end else if (vld) begin
                    if (eof) begin
                        next_state = IDLE;
                        next_beat_cnt = 4'd0;
                        next_temp = 16'd0;
                        next_early_eof = 1'b0;
                    end else begin
                        if (beat_cnt == 4'd1) begin
                            next_temp = data[31:16];
                            next_state = DONE;
                            next_field = data[31:16];
                            next_field_vld = 1'b1;
                            next_beat_cnt = beat_cnt + 4'd1;
                        end else begin
                            next_beat_cnt = beat_cnt + 4'd1;
                        end
                    end
                end
            end

            DONE: begin
                if (eof) begin
                    next_state = FAIL_FINAL;
                    next_field = 16'd0;
                    next_field_vld = 1'b0;
                    next_early_eof = 1'b0;
                end else begin
                    next_state = DONE;
                    next_field = field;
                    next_field_vld = 1'b1;
                end
            end

            FAIL_FINAL: begin
                next_state = IDLE;
                next_field = 16'd0;
                next_field_vld = 1'b0;
                next_beat_cnt = 4'd0;
                next_temp = 16'd0;
                next_early_eof = 1'b0;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
