module unpack_one_hot (
    input  wire        sign,
    input  wire        size,
    input  wire [2:0]  one_hot_selector,
    input  wire [255:0] source_reg,
    output reg  [511:0] destination_reg
);

    integer i;

    always @* begin
        destination_reg = 512'b0;
        case (one_hot_selector)
            3'b001: begin
                // 1-bit -> 8-bit unpacking (use lower 64 bits of source_reg)
                for (i = 0; i < 64; i = i + 1) begin
                    destination_reg[i*8 +: 8] = sign ? {8{source_reg[i]}} : {7'b0, source_reg[i]};
                end
            end

            3'b010: begin
                // 2-bit -> 8-bit unpacking (use lower 128 bits of source_reg)
                for (i = 0; i < 64; i = i + 1) begin
                    destination_reg[i*8 +: 8] = sign ? {{6{source_reg[i*2+1]}}, source_reg[i*2 +: 2]} :
                                                       {6'b0, source_reg[i*2 +: 2]};
                end
            end

            3'b100: begin
                if (size) begin
                    // 8-bit -> 16-bit unpacking (32 segments)
                    for (i = 0; i < 32; i = i + 1) begin
                        destination_reg[i*16 +: 16] = sign ? {{8{source_reg[i*8+7]}}, source_reg[i*8 +: 8]} :
                                                             {8'b0, source_reg[i*8 +: 8]};
                    end
                end else begin
                    // 4-bit -> 8-bit unpacking (64 segments)
                    for (i = 0; i < 64; i = i + 1) begin
                        destination_reg[i*8 +: 8] = sign ? {{4{source_reg[i*4+3]}}, source_reg[i*4 +: 4]} :
                                                           {4'b0, source_reg[i*4 +: 4]};
                    end
                end
            end

            default: begin
                // Direct assignment (zero-extends to 512 bits)
                destination_reg = source_reg;
            end
        endcase
    end

endmodule
