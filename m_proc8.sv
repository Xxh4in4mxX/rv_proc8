module m_proc8(w_clk);
    input wire w_clk;
    reg [31:0] P1_ir=32'h13, P1_pc=0, P2_pc=0, P3_pc=0;
    reg [31:0] P2_r1=0, P2_s2=0, P2_r2=0, P2_tpc=0;
    reg [31:0] P3_alu=0, P3_ldd=0;
    reg P2_r=0, P2_s=0, P2_b=0, P2_ld=0, P3_s=0, P3_b=0, P3_ld=0;
    reg [4:0]  P2_rd=0, P2_rs1=0, P2_rs2=0, P3_rd=0;
    reg P1_v=0, P2_v=0, P3_v=0;
    wire [31:0] w_npc, w_ir, w_imm, w_r1, w_r2, w_s2, w_rt;
    wire [31:0] w_alu, w_ldd, w_tpc, w_pcin, w_in1, w_in2, w_in3;
    wire w_r, w_i, w_s, w_b, w_u, w_j, w_ld, w_tkn;
    reg [31:0] r_pc=0;
    wire w_miss = P2_b & w_tkn & P2_v;

    m_mux m0 (
        .w_in1(w_npc),
        .w_in2(P2_tpc),
        .w_control(w_miss),
        .w_out(w_pcin)
    );
    m_adder m2 (
        .w_in1(32'h4),
        .w_in2(r_pc),
        .w_out(w_npc)
    );
    m_am_imem m3 (r_pc, w_ir);
    m_gen_imm m4 (P1_ir, w_imm, w_r, w_i, w_s, w_b, w_u, w_j, w_ld);
    m_RF2 m5 
endmodule

module m_mux(
    input   wire [31:0] w_in1,
    input   wire [31:0] w_in2,
    input   wire w_control,
    output  wire [31:0] w_out
);
    assign  w_out = (w_control) ? w_in1 : w_in2;
endmodule

module m_adder(
    input   wire [31:0] w_in1,
    input   wire [31:0] w_in2,
    output  wire [31:0] w_out
);
    assign w_out = w_in1 + w_in2;
endmodule

module m_am_imem(
    input   wire [31:0] w_pc,
    output  wire [31:0] w_insn
);
    reg [31:0] mem [0:63];
    assign w_insn = mem[w_pc[7:2]];
    integer i; initial for (i=0; i <64; i=i+1) mem[i] = 32'd0;
endmodule

module m_gen_imm(
    input   wire [31:0] w_ir,
    output  wire [31:0] w_imm,
    output  wire w_r, w_i, w_s, w_b, w_u, w_j, w_ld;
);
    m_get_type m1 (w_ir[6:2], w_r, w_i, w_s, w_b, w_u, w_j);
endmodule

module m_get_type(
    input   wire [4:0]  w_opcode,
    output  wire w_r, w_i, w_s, w_b, w_u, w_j
);
    assign w_j = (w_opcode==5'b11011);
    assign w_b = (w_opcode==5'b11000);
    assign w_s = (w_opcode==5'b01000);
    assign w_r = (w_opcode==5'b01100);
    assign w_u = (w_opcode==5'b01101 || w_opcode==5'b00101);
    assign w_i = ~(w_j | w_b | w_s | w_r | w_u);
endmodule

module m_get_imm(
    input   wire [31:0] w_ir,
    input   wire w_r, w_i, w_s, w_b, w_u, w_j,
    output  wire [31:0] w_imm
);
    assign w_imm = (w_i) ? {{20{w_ir[31]}}, w_ir[31:20]}:
                    (w_s) ? {{20{w_ir[31]}}, w_ir[31:25], w_ir[11:7]}:
                    (w_b) ? {{20{w_ir[31]}}, w_ir[7], w_ir[30:25], w_ir[11:8], 1'b0}:
                    (w_u) ? {w_ir[31:12], 12'b0}:
                    (w_j) ? {{12{w_ir[31]}}, w_ir[19:12], w_ir[20], w_ir[30:21], 1'b0}:0;
endmodule

module m_RF2(
    input wire w_clk, w_we,
    input wire [4:0] w_ra1, w_ra2, w_wa,
    output wire [31:0] w_rd1, w_rd2,
    input wire [31:0] w_wd
);
    reg [31:0] mem[0:31];
    wire w_bp1 = (w_we & w_ra1==w_wa);
    wire w_bp2 = (w_we & w_ra2==w_wa);

    assign w_rd1 = (w_ra1==5'd0) ? 32'd0 : (w_bp1) ? w_wd : mem[w_ra1];
    assign w_rd2 = (w_ra1==5'd0) ? 32'd0 : (w_bp2) ? w_wd : mem[w_ra2];
    always_ff @( posedge w_clk ) begin : _update
        if (w_we)
            mem[w_wa]   <=  w_wd;
    end
    always_ff @( posedge w_clk ) begin : _finish
        if (w_we & w_wa == 5'd30)
            $finish;
    end
    integer i; initial for (i=0; i < 32; i=i+1) mem[i]=32'd0;
endmodule

module m_alu(
    input   wire [31:0] w_in1,
    input   wire [31:0] w_in2,
    output  wire [31:0] w_out,
    output  wire w_tkn
);
    assign w_out = w_in1 + w_in2;
    assign w_tkn = w_in1 != w_in2;
endmodule

module m_am_dmem(
    input   wire w_clk, w_we,
    input   wire [31:0] w_adr, w_wd,
    output  wire [31:0] w_rd
);
    reg [31:0] mem [0:63];
    assign w_rd = mem[w_adr[7:2]];
    always_ff @( posedge w_clk ) begin : _update
        if (w_we)
            mem[w_adr[7:2]]     <=      w_wd;
    end
    integer i; initial for (i=0; i <64; i=i+1) mem[i] = 32'd0;
endmodule