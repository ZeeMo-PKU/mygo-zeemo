module gf_multiplier (
    input  logic [3:0] A,
    input  logic [3:0] B,
    output logic [3:0] result
);

    always_comb begin
        logic [3:0] res;
        logic [4:0] mult;
        
        res  = 4'd0;
        mult = {1'b0, A};  // extend to 5 bits, MSB initially 0
        
        for (int i = 0; i < 4; i++) begin
            if (B[i])
                res = res ^ mult[3:0];
            
            // Shift multiplicand left by 1
            mult = mult << 1;
            
            // Polynomial reduction if MSB is set after shifting
            if (mult[4])
                mult = mult ^ 5'b10011;
        end
        
        result = res;
    end

endmodule
