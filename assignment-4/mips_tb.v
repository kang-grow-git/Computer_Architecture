`timescale 1ns / 1ps

module mips_tb;
    reg         clk;
    reg         rst_n;
    wire [31:0] pc_out;
    wire [31:0] alu_result;

    mips uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc_out),
        .alu_result(alu_result)
    );

    wire [31:0] t0 = uut.u_datapath.u_reg_file.rf[8];
    wire [31:0] t1 = uut.u_datapath.u_reg_file.rf[9];
    wire [31:0] t2 = uut.u_datapath.u_reg_file.rf[10];

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("mips.vcd");
        $dumpvars(0, mips_tb);
    end

    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;

        $display("===========================================");
        $display("   Assignment 4 Simulation Start           ");
        $display("===========================================");

        repeat (40) begin
            @(negedge clk);
            #1;
            $display("PC: 0x%08h | $t0=%0d | $t1=%0d | $t2=0x%08h",
                     pc_out, t0, t1, t2);
        end

        $display("===========================================");
        $display("   Verification                            ");
        $display("===========================================");
        if (t0 == 32'd10)
            $display("PASS: $t0 = 10");
        else
            $display("FAIL: $t0 = %0d (expected 10)", t0);

        if (t1 == 32'd5)
            $display("PASS: $t1 = 5");
        else
            $display("FAIL: $t1 = %0d (expected 5)", t1);

        if (t2 !== 32'h00000099)
            $display("PASS: $t2 != 0x99 (actual 0x%08h, never executed addi)", t2);
        else
            $display("FAIL: $t2 became 0x99");

        $display("===========================================");
        $finish;
    end
endmodule
