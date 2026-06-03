// axis_joiner.sv
// Merges three AXI Stream inputs into one output using round-robin priority.

module axis_joiner (
    input  logic        clk,
    input  logic        rst,          // asynchronous active-high reset

    // Slave 1
    input  logic [7:0]  s_axis_tdata_1,
    input  logic        s_axis_tvalid_1,
    output logic        s_axis_tready_1,
    input  logic        s_axis_tlast_1,

    // Slave 2
    input  logic [7:0]  s_axis_tdata_2,
    input  logic        s_axis_tvalid_2,
    output logic        s_axis_tready_2,
    input  logic        s_axis_tlast_2,

    // Slave 3
    input  logic [7:0]  s_axis_tdata_3,
    input  logic        s_axis_tvalid_3,
    output logic        s_axis_tready_3,
    input  logic        s_axis_tlast_3,

    // Master
    output logic [7:0]  m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast,
    output logic [1:0]  m_axis_tuser,

    // Status
    output logic        busy
);

    // Tag IDs for tuser
    localparam [1:0] TAG_ID_1 = 2'b01;
    localparam [1:0] TAG_ID_2 = 2'b10;
    localparam [1:0] TAG_ID_3 = 2'b11;

    // FSM state definitions
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_1,
        STATE_2,
        STATE_3
    } state_t;

    state_t state, next_state;

    // Buffering registers
    logic        buff_valid;
    logic [7:0]  buff_data;
    logic        buff_last;
    logic [1:0]  buff_user;

    // Convenience signals for the currently selected slave
    logic [7:0]  curr_tdata;
    logic        curr_tvalid;
    logic        curr_tlast;
    logic        curr_tready;     // we will assign later

    // State machine synchronous logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= STATE_IDLE;
            buff_valid <= 1'b0;
        end else begin
            state <= next_state;
            // Update buffer
            if (state != STATE_IDLE) begin
                if (buff_valid) begin
                    // buffer is being output
                    if (m_axis_tready) begin
                        buff_valid <= 1'b0;  // consumed
                    end
                end else begin
                    // buffer empty, check if slave transaction occurs
                    if (curr_tvalid && curr_tready) begin
                        if (!m_axis_tready) begin
                            // store in buffer when master not ready
                            buff_valid <= 1'b1;
                            buff_data  <= curr_tdata;
                            buff_last  <= curr_tlast;
                            buff_user  <= (state == STATE_1) ? TAG_ID_1 :
                                           (state == STATE_2) ? TAG_ID_2 : TAG_ID_3;
                        end
                        // else direct pass, no buffering
                    end
                end
            end else begin
                buff_valid <= 1'b0;
            end
        end
    end

    // Next state and slave ready assignment
    always_comb begin
        // Default values
        next_state = state;
        curr_tready = 1'b0;

        case (state)
            STATE_IDLE: begin
                // Priority: slave 1 > 2 > 3
                if (s_axis_tvalid_1) begin
                    next_state = STATE_1;
                end else if (s_axis_tvalid_2) begin
                    next_state = STATE_2;
                end else if (s_axis_tvalid_3) begin
                    next_state = STATE_3;
                end
            end

            STATE_1: begin
                if (buff_valid) begin
                    // output buffer first
                    if (m_axis_tready && buff_last) begin
                        next_state = STATE_IDLE;
                    end
                end else begin
                    // buffer empty, ready to accept from slave
                    curr_tready = 1'b1;
                    if (curr_tvalid && curr_tready) begin
                        if (m_axis_tready) begin
                            // direct pass
                            if (curr_tlast) begin
                                next_state = STATE_IDLE;
                            end
                        end else begin
                            // stored in buffer; wait for master
                            // If this was the last beat, we don't go IDLE now,
                            // because it will be buffered. We'll leave after buffer sent.
                            // So nothing to do here, state stays STATE_1.
                        end
                    end
                end
                // If no transfer occurs, stay in STATE_1
            end

            STATE_2: begin
                if (buff_valid) begin
                    if (m_axis_tready && buff_last) begin
                        next_state = STATE_IDLE;
                    end
                end else begin
                    curr_tready = 1'b1;
                    if (curr_tvalid && curr_tready) begin
                        if (m_axis_tready) begin
                            if (curr_tlast) begin
                                next_state = STATE_IDLE;
                            end
                        end
                    end
                end
            end

            STATE_3: begin
                if (buff_valid) begin
                    if (m_axis_tready && buff_last) begin
                        next_state = STATE_IDLE;
                    end
                end else begin
                    curr_tready = 1'b1;
                    if (curr_tvalid && curr_tready) begin
                        if (m_axis_tready) begin
                            if (curr_tlast) begin
                                next_state = STATE_IDLE;
                            end
                        end
                    end
                end
            end
        endcase
    end

    // Multiplex input signals based on state
    always_comb begin
        case (state)
            STATE_1: begin
                curr_tdata  = s_axis_tdata_1;
                curr_tvalid = s_axis_tvalid_1;
                curr_tlast  = s_axis_tlast_1;
            end
            STATE_2: begin
                curr_tdata  = s_axis_tdata_2;
                curr_tvalid = s_axis_tvalid_2;
                curr_tlast  = s_axis_tlast_2;
            end
            STATE_3: begin
                curr_tdata  = s_axis_tdata_3;
                curr_tvalid = s_axis_tvalid_3;
                curr_tlast  = s_axis_tlast_3;
            end
            default: begin
                curr_tdata  = 8'd0;
                curr_tvalid = 1'b0;
                curr_tlast  = 1'b0;
            end
        endcase
    end

    // Assign slave tready outputs
    assign s_axis_tready_1 = (state == STATE_1) && curr_tready;
    assign s_axis_tready_2 = (state == STATE_2) && curr_tready;
    assign s_axis_tready_3 = (state == STATE_3) && curr_tready;

    // Master output generation
    always_comb begin
        if (buff_valid) begin
            m_axis_tdata  = buff_data;
            m_axis_tlast  = buff_last;
            m_axis_tuser  = buff_user;
            m_axis_tvalid = 1'b1;
        end else if (state != STATE_IDLE && !buff_valid && curr_tvalid && m_axis_tready) begin
            // Direct pass
            m_axis_tdata  = curr_tdata;
            m_axis_tlast  = curr_tlast;
            m_axis_tuser  = (state == STATE_1) ? TAG_ID_1 :
                            (state == STATE_2) ? TAG_ID_2 : TAG_ID_3;
            m_axis_tvalid = 1'b1;
        end else begin
            m_axis_tdata  = 8'd0;
            m_axis_tlast  = 1'b0;
            m_axis_tuser  = 2'b00;
            m_axis_tvalid = 1'b0;
        end
    end

    // Busy output
    assign busy = (state != STATE_IDLE);

endmodule
