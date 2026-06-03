// rtl/static_branch_predict.sv
module static_branch_predict (
    input  logic [31:0] fetch_rdata_i,       // fetched instruction
    input  logic [31:0] fetch_pc_i,          // program counter of the instruction
    input  logic        fetch_valid_i,       // validity of the instruction
    output logic        predict_branch_taken_o, // branch prediction taken flag
    output logic [31:0] predict_branch_pc_o     // predicted target address
);

    // Opcodes for RISC-V RV32I instructions
    localparam OPCODE_BRANCH = 7'h63;
    localparam OPCODE_JAL    = 7'h6F;
    localparam OPCODE_JALR   = 7'h67;

    // Alias for the instruction bits
    logic [31:0] instr;
    assign instr = fetch_rdata_i;

    // Instruction type identification signals
    logic instr_j;    // uncompressed JAL or compressed jump (both have opcode 7'h6F)
    logic instr_b;    // uncompressed branch or compressed branch (both have opcode 7'h63)
    logic instr_jalr; // uncompressed JALR
    logic instr_cj;   // flag for compressed jump (unused beyond documentation)
    logic instr_cb;   // flag for compressed branch (unused beyond documentation)

    assign instr_j    = (instr[6:0] == OPCODE_JAL);
    assign instr_b    = (instr[6:0] == OPCODE_BRANCH);
    assign instr_jalr = (instr[6:0] == OPCODE_JALR);

    // Compressed instructions are not distinguished from their uncompressed
    // equivalents for prediction purposes. Set these flags to 0.
    assign instr_cj = 1'b0;
    assign instr_cb = 1'b0;

    // Immediate extraction for each instruction type
    logic [31:0] imm_j_type;   // Immediate for uncompressed jump (JAL)
    logic [31:0] imm_b_type;   // Immediate for uncompressed branch
    logic [31:0] imm_cj_type;  // Immediate for compressed jump
    logic [31:0] imm_cb_type;  // Immediate for compressed branch

    // Uncompressed jump immediate (J-type) – also correct for decompressed C.J/C.JAL
    assign imm_j_type = {
        {12{instr[31]}},   // replicate sign bit 12 times
        instr[19:12],
        instr[20],
        instr[30:21],
        1'b0
    };

    // Uncompressed branch immediate (B-type) – also correct for decompressed C.BEQZ/C.BNEZ
    assign imm_b_type = {
        {19{instr[31]}},   // replicate sign bit 19 times
        instr[31],
        instr[7],
        instr[30:25],
        instr[11:8],
        1'b0
    };

    // For compressed instructions the immediate extraction is identical to the
    // uncompressed form once the decompressor has produced the 32‑bit equivalent.
    assign imm_cj_type = imm_j_type;
    assign imm_cb_type = imm_b_type;

    // Immediate used for target address calculation
    logic [31:0] branch_imm;
    always_comb begin
        unique case (1'b1)
            instr_b:    branch_imm = imm_b_type;
            instr_j:    branch_imm = imm_j_type;
            instr_jalr: branch_imm = {{20{instr[31]}}, instr[31:20]}; // I‑type immediate for JALR
            default:    branch_imm = 32'b0;
        endcase
    end

    // Branch taken indication: branches taken if offset is negative (sign bit = 1)
    logic instr_b_taken;
    assign instr_b_taken = instr_b && branch_imm[31];

    // Prediction output logic
    // Jumps (JAL, JALR, compressed jump) are always predicted taken.
    // Branches are predicted taken only when the sign bit of the immediate is 1.
    assign predict_branch_taken_o = fetch_valid_i && (instr_j || instr_jalr || instr_b_taken);

    // Predicted target address: PC + sign‑extended immediate/offset
    assign predict_branch_pc_o = fetch_pc_i + branch_imm;

endmodule
