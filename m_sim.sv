`timescale 1ns/100ps
`default_nettype none
module m_sim(w_clk, w_cc);
    input wire w_clk;
    input wire [31:0] w_cc;
    m_proc8 m (w_clk);
    initial begin
        $display("CC\tr_pc\tP1\tP2\tP3\t\tw_in1\tw_in2\tw_alu");
        `define MM m.m3.mem
        `include "asm.txt"
    end
    initial #99 forever #100 $display("CC%1d %h %h %h %h %d %d %d",
    w_cc, m.r_pc, m.P1_pc, m.P2_pc, m.P3_pc,
    m.w_in1, m.w_in2, m.w_alu);
endmodule

module m_top_wrapper();
    reg r_clk=0; initial #150 forever #50 r_clk = ~r_clk;
    reg [31:0] r_cc = 0;
    always @( posedge r_clk ) begin : _increment_r_cc
        if (r_cc==20) $finish;
        r_cc <= r_cc + 1;
    end
    m_sim m(r_clk, r_cc);
    initial $dumpvars(0, m);
endmodule
