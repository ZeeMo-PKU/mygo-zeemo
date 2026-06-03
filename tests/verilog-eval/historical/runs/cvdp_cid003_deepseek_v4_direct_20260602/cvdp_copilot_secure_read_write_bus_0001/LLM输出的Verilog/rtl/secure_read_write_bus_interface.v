// secure_read_write_bus_interface.v
// 
// Parameterized read/write bus with 8-bit configurable key authorization.
// Access is granted only when the input key matches the internal parameterized key.
// A capture pulse (i_capture_pulse) acts as a clock; internal registers and outputs
// update on its rising edge. An asynchronous active-low reset clears all internal
// registers and outputs.

module secure_read_write_bus_interface #(
    parameter p_configurable_key = 8'hAA,  // internal 8‑bit authorization key
    parameter p_data_width       = 8,      // data width in bits
    parameter p_addr_width       = 8       // address width in bits
) (
    input  wire                      i_capture_pulse,   // capture clock (rising edge)
    input  wire                      i_reset_bar,       // asynchronous active-low reset
    input  wire [p_addr_width-1:0]   i_addr,            // target address
    input  wire [p_data_width-1:0]   i_data_in,         // write data
    input  wire [7:0]                i_key_in,          // initiator key
    input  wire                      i_read_write_enable, // 1 = read, 0 = write
    output reg  [p_data_width-1:0]   o_data_out,        // read data output
    output reg                       o_error            // error flag (1 = key mismatch)
);

    // Internal memory (register-based for asynchronous reset support)
    reg [p_data_width-1:0] mem [0:(1<<p_addr_width)-1];

    // Authorization check combinational signal
    wire key_match = (i_key_in == p_configurable_key);

    //---------------------------------------------------------------------------
    // Asynchronous reset and edge-triggered operation
    //---------------------------------------------------------------------------
    integer i;

    always @(posedge i_capture_pulse or negedge i_reset_bar) begin
        if (!i_reset_bar) begin
            // Clear all internal registers and outputs (memory cleared)
            for (i = 0; i < (1<<p_addr_width); i = i + 1) begin
                mem[i] <= '0;
            end
            o_data_out <= '0;
            o_error    <= 1'b0;
        end else begin
            // Default error output: cleared if no mismatch in this cycle
            o_error <= 1'b0;

            if (i_read_write_enable) begin
                // Read operation
                if (key_match) begin
                    o_data_out <= mem[i_addr];
                end else begin
                    // Mismatch: output 0, error high
                    o_data_out <= '0;
                    o_error    <= 1'b1;
                end
            end else begin
                // Write operation
                if (key_match) begin
                    mem[i_addr] <= i_data_in;
                end else begin
                    o_error <= 1'b1;
                end
                // Data output remains unchanged (should be 0 per spec, but
                // we set it explicitly below to guarantee known value)
                o_data_out <= '0;
            end
        end
    end

endmodule
