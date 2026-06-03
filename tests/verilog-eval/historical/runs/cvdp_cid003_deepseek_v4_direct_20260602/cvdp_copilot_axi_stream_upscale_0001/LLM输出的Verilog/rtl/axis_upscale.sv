// rtl/axis_upscale.sv
module axis_upscale (
    input  logic        clk,
    input  logic        resetn,
    input  logic        dfmt_enable,
    input  logic        dfmt_type,
    input  logic        dfmt_se,
    input  logic        s_axis_valid,
    input  logic [23:0] s_axis_data,
    output logic        s_axis_ready,
    input  logic        m_axis_ready,
    output logic        m_axis_valid,
    output logic [31:0] m_axis_data
);

    // Internal register for pipeline stage
    logic        reg_valid;
    logic [31:0] reg_data;

    // Compute the extension bit for the upper 8 bits
    logic extension_bit;
    always_comb begin
        if (dfmt_enable) begin
            if (dfmt_se)
                extension_bit = dfmt_type ? ~s_axis_data[23] : s_axis_data[23];
            else
                extension_bit = 1'b0;
        end else begin
            extension_bit = 1'b0;
        end
    end

    // Next 32-bit data to be stored when transfer occurs
    wire [31:0] next_data = { {8{extension_bit}}, s_axis_data };

    // Backpressure: accept new data only when register is empty or output handshake is possible
    assign s_axis_ready = !reg_valid || m_axis_ready;

    // Pipeline register and handshake logic
    always_ff @(posedge clk) begin
        if (!resetn) begin
            reg_valid <= 1'b0;
            reg_data <= 32'd0;
        end else begin
            if (s_axis_valid && s_axis_ready) begin
                // Load new data
                reg_valid <= 1'b1;
                reg_data <= next_data;
            end else if (m_axis_ready) begin
                // Data was taken, clear valid
                reg_valid <= 1'b0;
            end
            // else hold current state
        end
    end

    // Drive output ports
    assign m_axis_valid = reg_valid;
    assign m_axis_data  = reg_data;

endmodule
