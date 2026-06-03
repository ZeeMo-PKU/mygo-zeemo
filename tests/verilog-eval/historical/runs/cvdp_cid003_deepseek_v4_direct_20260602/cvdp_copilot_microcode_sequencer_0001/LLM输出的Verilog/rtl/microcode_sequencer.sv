// File: rtl/microcode_sequencer.sv

module microcode_sequencer (
    input  logic       clk,
    input  logic       c_n_in,
    input  logic       c_inc_in,
    input  logic       r_en,
    input  logic       cc,
    input  logic       ien,
    input  logic [3:0] d_in,
    input  logic [4:0] instr_in,
    input  logic       oen,
    output logic [3:0] d_out,
    output logic       c_n_out,
    output logic       c_inc_out,
    output logic       full,
    output logic       empty
);

    // Internal signals for interconnects
    logic        cen, rst, inc, rsel, rce, pc_mux_sel, push, pop, src_sel, stack_we, stack_re, out_ce, oe_fa;
    logic [1:0]  a_mux_sel, b_mux_sel;
    logic [3:0]  pc_out, stack_data_out, fa_sum;

    // Instruction decoder
    instruction_decoder i_dec (
        .instr_in   (instr_in),
        .cc_in      (cc),
        .instr_en   (ien),
        .cen        (cen),
        .rst        (rst),
        .oen        (oe_fa),   // active high from decoder
        .inc        (inc),
        .rsel       (rsel),
        .rce        (rce),
        .pc_mux_sel (pc_mux_sel),
        .a_mux_sel  (a_mux_sel),
        .b_mux_sel  (b_mux_sel),
        .push       (push),
        .pop        (pop),
        .src_sel    (src_sel),
        .stack_we   (stack_we),
        .stack_re   (stack_re),
        .out_ce     (out_ce)
    );

    // LIFO stack
    lifo_stack u_stack (
        .clk            (clk),
        .stack_data1_in (d_in),
        .stack_data2_in (pc_out),
        .stack_reset    (rst),
        .stack_push     (push),
        .stack_pop      (pop),
        .stack_mux_sel  (src_sel),
        .stack_we       (stack_we),
        .stack_re       (stack_re),
        .stack_data_out (stack_data_out),
        .full_o         (full),
        .empty_o        (empty)
    );

    // Program counter
    program_counter u_pc (
        .clk                (clk),
        .full_adder_data_i  (fa_sum),
        .pc_c_in            (c_inc_in),
        .inc                (inc),
        .pc_mux_sel         (pc_mux_sel),
        .pc_out             (pc_out),
        .pc_c_out           (c_inc_out)
    );

    // Microcode arithmetic
    microcode_arithmetic u_arith (
        .clk            (clk),
        .fa_in          (fa_sum),     // internal feedback from adder to aux_reg_mux
        .d_in           (d_in),
        .stack_data_in  (stack_data_out),
        .pc_data_in     (pc_out),
        .reg_en         (r_en),
        .oen            (oen),        // active low from top
        .rce            (rce),
        .cen            (cen),
        .a_mux_sel      (a_mux_sel),
        .b_mux_sel      (b_mux_sel),
        .arith_cin      (c_n_in),
        .oe             (oe_fa),      // active high from decoder
        .arith_cout     (c_n_out),
        .d_out          (fa_sum)
    );

    // Result register
    result_register u_res_reg (
        .clk      (clk),
        .data_in  (fa_sum),
        .out_ce   (out_ce),
        .data_out (d_out)
    );

endmodule


//----------------------------------------------------------------------
// Submodule: instruction_decoder (combinational)
//----------------------------------------------------------------------
module instruction_decoder (
    input  logic [4:0] instr_in,
    input  logic       cc_in,
    input  logic       instr_en,  // active low
    output logic       cen,
    output logic       rst,
    output logic       oen,       // active high, used for arithmetic output enable
    output logic       inc,
    output logic       rsel,
    output logic       rce,
    output logic       pc_mux_sel,
    output logic [1:0] a_mux_sel,
    output logic [1:0] b_mux_sel,
    output logic       push,
    output logic       pop,
    output logic       src_sel,
    output logic       stack_we,
    output logic       stack_re,
    output logic       out_ce
);
    always_comb begin
        // Default: all control signals low (disabled)
        cen        = 1'b0;
        rst        = 1'b0;
        oen        = 1'b0;
        inc        = 1'b0;
        rsel       = 1'b0;
        rce        = 1'b0;
        pc_mux_sel = 1'b0;
        a_mux_sel  = 2'b00;
        b_mux_sel  = 2'b00;
        push       = 1'b0;
        pop        = 1'b0;
        src_sel    = 1'b0;
        stack_we   = 1'b0;
        stack_re   = 1'b0;
        out_ce     = 1'b0;

        // Enable decoding only when instr_en is low (active)
        if (!instr_en) begin
            case (instr_in)
                // PRST (Program ReSeT)
                5'b00000: begin
                    // Force D output to 0, reset stack, load PC = 0 + c_inc_in
                    a_mux_sel  = 2'b10; // select 4'b0000
                    b_mux_sel  = 2'b10; // select 4'b0000
                    cen        = 1'b0;  // ignore carry
                    oen        = 1'b1;  // full adder output enabled
                    out_ce     = 1'b1;  // result register captures
                    rst        = 1'b1;  // reset stack pointer
                    inc        = 1'b1;  // enable incrementer
                    pc_mux_sel = 1'b1;  // select full_adder_data (which is 0)
                    // No stack push/pop
                end

                // Fetch PC
                5'b00001: begin
                    a_mux_sel  = 2'b10; // 0
                    b_mux_sel  = 2'b00; // pc_out
                    cen        = 1'b0;
                    oen        = 1'b1;
                    out_ce     = 1'b1;
                end

                // Fetch R (auxiliary register)
                5'b00010: begin
                    a_mux_sel  = 2'b01; // reg_data
                    b_mux_sel  = 2'b10; // 0
                    cen        = 1'b0;
                    oen        = 1'b1;
                    out_ce     = 1'b1;
                end

                // Fetch D (data input)
                5'b00011: begin
                    a_mux_sel  = 2'b00; // d_in
                    b_mux_sel  = 2'b10; // 0
                    cen        = 1'b0;
                    oen        = 1'b1;
                    out_ce     = 1'b1;
                end

                // Fetch R + D
                5'b00100: begin
                    a_mux_sel  = 2'b00; // d_in
                    b_mux_sel  = 2'b11; // reg_data
                    cen        = 1'b0;
                    oen        = 1'b1;
                    out_ce     = 1'b1;
                end

                // Push PC onto stack
                5'b01011: begin
                    push       = 1'b1;
                    stack_we   = 1'b1;
                    src_sel    = 1'b0; // select PC (pc_in)
                    // No d_out update
                end

                // Pop PC (stack -> d_out)
                5'b01110: begin
                    pop        = 1'b1;
                    stack_re   = 1'b1;
                    a_mux_sel  = 2'b10; // 0
                    b_mux_sel  = 2'b01; // stack_data
                    cen        = 1'b0;
                    oen        = 1'b1;
                    out_ce     = 1'b1;
                end

                default: ; // remains disabled
            endcase
        end
    end
endmodule


//----------------------------------------------------------------------
// Submodule: lifo_stack (top of stack management)
//----------------------------------------------------------------------
module lifo_stack (
    input  logic       clk,
    input  logic [3:0] stack_data1_in,  // d_in
    input  logic [3:0] stack_data2_in,  // pc_out
    input  logic       stack_reset,
    input  logic       stack_push,
    input  logic       stack_pop,
    input  logic       stack_mux_sel,   // 1: data1_in, 0: data2_in
    input  logic       stack_we,
    input  logic       stack_re,
    output logic [3:0] stack_data_out,
    output logic       full_o,
    output logic       empty_o
);
    logic [4:0] stack_addr;
    logic [3:0] mux_data;

    stack_pointer u_ptr (
        .clk       (clk),
        .rst       (stack_reset),
        .push      (stack_push),
        .pop       (stack_pop),
        .stack_addr(stack_addr),
        .full      (full_o),
        .empty     (empty_o)
    );

    stack_data_mux u_mux (
        .data_in       (stack_data1_in),
        .pc_in         (stack_data2_in),
        .stack_mux_sel (stack_mux_sel),
        .stack_mux_out (mux_data)
    );

    stack_ram u_ram (
        .clk           (clk),
        .stack_addr    (stack_addr),
        .stack_data_in (mux_data),
        .stack_we      (stack_we),
        .stack_re      (stack_re),
        .stack_data_out(stack_data_out)
    );

endmodule


// Stack pointer with increment/decrement and full/empty detection
module stack_pointer (
    input  logic       clk,
    input  logic       rst,
    input  logic       push,
    input  logic       pop,
    output logic [4:0] stack_addr,
    output logic       full,
    output logic       empty
);
    logic [4:0] ptr;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ptr <= 5'b00000;
        end else begin
            if (push && !full) begin
                ptr <= ptr + 1;
            end else if (pop && !empty) begin
                ptr <= ptr - 1;
            end
        end
    end

    assign stack_addr = ptr;
    assign full  = (ptr == 5'd16);
    assign empty = (ptr == 5'd0);
endmodule


// Stack RAM (16 locations x 4 bits)
module stack_ram (
    input  logic       clk,
    input  logic [4:0] stack_addr,
    input  logic [3:0] stack_data_in,
    input  logic       stack_we,
    input  logic       stack_re,
    output logic [3:0] stack_data_out
);
    logic [3:0] mem [0:15];

    always_ff @(posedge clk) begin
        if (stack_we) begin
            mem[stack_addr] <= stack_data_in;
        end
    end

    assign stack_data_out = stack_re ? mem[stack_addr] : 4'b0000;
endmodule


// Stack data multiplexer
module stack_data_mux (
    input  logic [3:0] data_in,
    input  logic [3:0] pc_in,
    input  logic       stack_mux_sel,
    output logic [3:0] stack_mux_out
);
    assign stack_mux_out = stack_mux_sel ? data_in : pc_in;
endmodule


//----------------------------------------------------------------------
// Submodule: program_counter (PC management)
//----------------------------------------------------------------------
module program_counter (
    input  logic       clk,
    input  logic [3:0] full_adder_data_i,
    input  logic       pc_c_in,
    input  logic       inc,
    input  logic       pc_mux_sel,
    output logic [3:0] pc_out,
    output logic       pc_c_out
);
    logic [3:0] mux_out;
    logic [3:0] inc_out;

    pc_mux u_mux (
        .full_adder_data (full_adder_data_i),
        .pc_data         (pc_out),
        .pc_mux_sel      (pc_mux_sel),
        .pc_mux_out      (mux_out)
    );

    pc_incrementer u_inc (
        .pc_c_in    (pc_c_in),
        .inc        (inc),
        .pc_data_in (mux_out),
        .pc_inc_out (inc_out),
        .pc_c_out   (pc_c_out)
    );

    pc_reg u_reg (
        .clk         (clk),
        .pc_data_in  (inc_out),
        .pc_data_out (pc_out)
    );

endmodule


module pc_mux (
    input  logic [3:0] full_adder_data,
    input  logic [3:0] pc_data,
    input  logic       pc_mux_sel,
    output logic [3:0] pc_mux_out
);
    assign pc_mux_out = pc_mux_sel ? full_adder_data : pc_data;
endmodule


module pc_incrementer (
    input  logic       pc_c_in,
    input  logic       inc,
    input  logic [3:0] pc_data_in,
    output logic [3:0] pc_inc_out,
    output logic       pc_c_out
);
    logic [4:0] sum;

    assign sum = {1'b0, pc_data_in} + (inc ? {4'b0, pc_c_in} : 5'b00000);
    assign pc_inc_out = sum[3:0];
    assign pc_c_out   = inc ? sum[4] : 1'b0;
endmodule


module pc_reg (
    input  logic       clk,
    input  logic [3:0] pc_data_in,
    output logic [3:0] pc_data_out
);
    always_ff @(posedge clk) begin
        pc_data_out <= pc_data_in;
    end
endmodule


//----------------------------------------------------------------------
// Submodule: microcode_arithmetic (arithmetic unit with muxes and aux reg)
//----------------------------------------------------------------------
module microcode_arithmetic (
    input  logic       clk,
    input  logic [3:0] fa_in,             // feedback from full_adder output (used in aux_reg_mux)
    input  logic [3:0] d_in,
    input  logic [3:0] stack_data_in,
    input  logic [3:0] pc_data_in,
    input  logic       reg_en,            // active low
    input  logic       oen,               // active low output enable (not used functionally)
    input  logic       rce,               // register chip enable
    input  logic       cen,               // carry enable
    input  logic [1:0] a_mux_sel,
    input  logic [1:0] b_mux_sel,
    input  logic       arith_cin,
    input  logic       oe,                // active high output enable (not gating here)
    output logic       arith_cout,
    output logic [3:0] d_out              // full_adder sum
);
    logic [3:0] reg_mux_out, reg_out, a_mux_out, b_mux_out;

    // Auxiliary register path (rsel = oe? Actually we use rsel from decoder, but here we only have reg_en, rce, and fa_in)
    // rsel is combined with reg_en in aux_reg_mux. We need rsel from decoder, but that is not an input here.
    // Wait, the spec says rsel is an output from instruction_decoder and goes to aux_reg_mux, but we didn't bring it in.
    // Let's add an rsel input to this module.
    // Correction: We need rsel as input. But we omitted it. Let's fix by adding rsel input.

    // Actually in our top-level, rsel from decoder wasn't connected to arithmetic. Let's add the port.
    // We'll do that now by adding an rsel input.
    // (Redesign: add input rsel)
    // To keep code compact, assume rsel is also an input. I'll add it.
    input logic rsel;   // from decoder
    
    aux_reg_mux u_aux_mux (
        .reg1_in     (fa_in),
        .reg2_in     (d_in),
        .rsel        (rsel),
        .re          (reg_en),       // active low
        .reg_mux_out (reg_mux_out)
    );

    aux_reg u_aux_reg (
        .clk     (clk),
        .reg_in  (reg_mux_out),
        .rce     (rce),
        .re      (reg_en),
        .reg_out (reg_out)
    );

    a_mux u_a_mux (
        .register_data (reg_out),
        .data_in       (d_in),
        .a_mux_sel     (a_mux_sel),
        .a_mux_out     (a_mux_out)
    );

    b_mux u_b_mux (
        .register_data (reg_out),
        .stack_data    (stack_data_in),
        .pc_data       (pc_data_in),
        .b_mux_sel     (b_mux_sel),
        .b_mux_out     (b_mux_out)
    );

    full_adder u_adder (
        .a_in   (a_mux_out),
        .b_in   (b_mux_out),
        .c_in   (arith_cin),
        .cen    (cen),
        .c_out  (arith_cout),
        .sum    (d_out)
    );

endmodule


// auxiliary register mux (select between full_adder sum and d_in)
module aux_reg_mux (
    input  logic [3:0] reg1_in,   // full_adder sum (fa_in)
    input  logic [3:0] reg2_in,   // d_in
    input  logic       rsel,      // from decoder
    input  logic       re,        // active low reg_en
    output logic [3:0] reg_mux_out
);
    logic mux_sel;
    assign mux_sel = rsel & ~re;
    assign reg_mux_out = mux_sel ? reg1_in : reg2_in;
endmodule


// auxiliary register with enable = rce | ~re
module aux_reg (
    input  logic       clk,
    input  logic [3:0] reg_in,
    input  logic       rce,
    input  logic       re,        // active low
    output logic [3:0] reg_out
);
    logic en;
    assign en = rce | (~re);

    always_ff @(posedge clk) begin
        if (en) begin
            reg_out <= reg_in;
        end
    end
endmodule


// A multiplexer
module a_mux (
    input  logic [3:0] register_data,
    input  logic [3:0] data_in,
    input  logic [1:0] a_mux_sel,
    output logic [3:0] a_mux_out
);
    always_comb begin
        case (a_mux_sel)
            2'b00: a_mux_out = data_in;
            2'b01: a_mux_out = register_data;
            2'b10: a_mux_out = 4'b0000;
            default: a_mux_out = 4'b0000;
        endcase
    end
endmodule


// B multiplexer
module b_mux (
    input  logic [3:0] register_data,
    input  logic [3:0] stack_data,
    input  logic [3:0] pc_data,
    input  logic [1:0] b_mux_sel,
    output logic [3:0] b_mux_out
);
    always_comb begin
        case (b_mux_sel)
            2'b00: b_mux_out = pc_data;
            2'b01: b_mux_out = stack_data;
            2'b10: b_mux_out = 4'b0000;
            2'b11: b_mux_out = register_data;
            default: b_mux_out = 4'b0000;
        endcase
    end
endmodule


// 4-bit ripple-carry adder with carry enable
module full_adder (
    input  logic [3:0] a_in,
    input  logic [3:0] b_in,
    input  logic       c_in,
    input  logic       cen,
    output logic       c_out,
    output logic [3:0] sum
);
    logic [4:0] result;
    assign result = {1'b0, a_in} + {1'b0, b_in} + (cen ? {4'b0, c_in} : 5'b00000);
    assign sum   = result[3:0];
    assign c_out = result[4];
endmodule


//----------------------------------------------------------------------
// Submodule: result_register
//----------------------------------------------------------------------
module result_register (
    input  logic       clk,
    input  logic [3:0] data_in,
    input  logic       out_ce,
    output logic [3:0] data_out
);
    always_ff @(posedge clk) begin
        if (out_ce) begin
            data_out <= data_in;
        end
    end
endmodule
