module secure_read_write_register_bank #(
    parameter p_address_width = 8,
    parameter p_data_width    = 8,
    parameter p_unlock_code_0 = 8'hAB,
    parameter p_unlock_code_1 = 8'hCD
) (
    input  wire [p_address_width-1:0] i_addr,
    input  wire [p_data_width-1:0]    i_data_in,
    input  wire                       i_read_write_enable,  // 0 = write, 1 = read
    input  wire                       i_capture_pulse,
    input  wire                       i_rst_n,
    output reg  [p_data_width-1:0]    o_data_out
);

    //----------------------------------------------------------------------
    // Local states for the unlock state machine
    //----------------------------------------------------------------------
    localparam S_LOCKED      = 2'd0;
    localparam S_WAIT_ADDR1  = 2'd1;
    localparam S_UNLOCKED    = 2'd2;

    //----------------------------------------------------------------------
    // Internal registers
    //----------------------------------------------------------------------
    reg [1:0]                              state;
    reg [p_data_width-1:0]  mem [0:(1<<p_address_width)-1];

    //----------------------------------------------------------------------
    // State machine and output data register
    //----------------------------------------------------------------------
    always @(posedge i_capture_pulse or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state      <= S_LOCKED;
            o_data_out <= {p_data_width{1'b0}};
        end else begin
            // default output is zero, overridden only on valid reads
            o_data_out <= {p_data_width{1'b0}};

            if (i_read_write_enable == 1'b0) begin   // write operation
                case (state)
                    S_LOCKED: begin
                        if (i_addr == 'h0) begin
                            if (i_data_in == p_unlock_code_0)
                                state <= S_WAIT_ADDR1;
                            else
                                state <= S_LOCKED;   // remains locked
                        end else begin
                            state <= S_LOCKED;       // no change
                        end
                    end
                    S_WAIT_ADDR1: begin
                        if (i_addr == 'h1) begin
                            if (i_data_in == p_unlock_code_1)
                                state <= S_UNLOCKED;
                            else
                                state <= S_LOCKED;   // wrong code -> lock
                        end else begin
                            state <= S_LOCKED;       // any other address resets the sequence
                        end
                    end
                    S_UNLOCKED: begin
                        if (i_addr == 'h0) begin
                            if (i_data_in != p_unlock_code_0)
                                state <= S_LOCKED;
                            // else stays unlocked
                        end else if (i_addr == 'h1) begin
                            if (i_data_in != p_unlock_code_1)
                                state <= S_LOCKED;
                            // else stays unlocked
                        end else begin
                            // write to any other address, remain unlocked
                        end
                    end
                    default: state <= S_LOCKED;
                endcase
            end else begin                             // read operation
                // state machine unchanged on reads
                // output data only when fully unlocked and not reading address 0/1
                if ((state == S_UNLOCKED) && (i_addr != 'h0) && (i_addr != 'h1)) begin
                    o_data_out <= mem[i_addr];
                end
            end
        end
    end

    //----------------------------------------------------------------------
    // Memory write logic
    //----------------------------------------------------------------------
    always @(posedge i_capture_pulse or negedge i_rst_n) begin
        if (i_rst_n) begin   // normal operation
            if (i_read_write_enable == 1'b0) begin   // write operation
                // Write unconditionally to addresses 0 and 1 (used for unlocking),
                // write to other addresses only when fully unlocked.
                if ((i_addr == 'h0) || (i_addr == 'h1) || (state == S_UNLOCKED)) begin
                    mem[i_addr] <= i_data_in;
                end
            end
        end
        // else: during reset, memory content is not affected
    end

endmodule
