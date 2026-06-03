// piso_8bit.sv
// 8-bit Parallel In Serial Out shift register with continuous incrementing patterns.
// Generates 8-bit patterns MSB first, starting with 8'b0000_0001 and incrementing by 1 every 8 cycles.

module piso_8bit (
    input  logic clk,         // clock
    input  logic rst,         // asynchronous active LOW reset
    output logic serial_out   // serial output, 1 bit per cycle
);

    // Internal registers
    logic [7:0] pattern_reg;   // holds the value to be transmitted, incrementing each cycle of 8
    logic [7:0] shift_reg;     // shift register for serialization
    logic [2:0] counter;       // counts 0..7 to track which bit is being transmitted

    // Shift register operation and pattern generation
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            pattern_reg <= 8'b0000_0001;  // first pattern after reset
            shift_reg   <= 8'b0000_0001;  // load pattern into shift reg
            counter     <= 3'd0;          // ready to transmit MSB on first clock
        end else begin
            if (counter == 3'd0) begin
                // First clock of the 8-cycle block: output MSB, no shift
                shift_reg <= pattern_reg;   // load the current pattern
                counter   <= 3'd1;
            end else if (counter == 3'd7) begin
                // Last (8th) clock: shift out LSB and prepare for next pattern
                shift_reg   <= {shift_reg[6:0], 1'b0};  // shift left (LSB becomes 0)
                pattern_reg <= pattern_reg + 1;          // increment pattern by 1
                counter     <= 3'd0;                      // wrap back to 0
            end else begin
                // Intermediate clocks (2..7): shift left one position
                shift_reg <= {shift_reg[6:0], 1'b0};
                counter   <= counter + 1;
            end
        end
    end

    // Output mux: force serial_out LOW while reset is active (LOW)
    assign serial_out = rst ? shift_reg[7] : 1'b0;

endmodule
