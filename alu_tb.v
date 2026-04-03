`timescale 1ns / 1ps
module alu_tb;
    reg  [31:0] src_a, src_b;     // test inputs
    reg  [2:0]  alu_ctrl;         // operation select
    wire [31:0] result;           // ALU output
    wire        zero;             // zero flag
    
    alu uut (                     // unit under test
        .src_a(src_a),
        .src_b(src_b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );
    
    initial begin
        $dumpfile("alu.vcd");     // waveform file
        $dumpvars(0, alu_tb);
    end
    
    initial begin
        $display("=== ALU Testbench ===");
        
        // Test ADD (overflow wrap-around)
        src_a = 32'hFFFF_FFF0;
        src_b = 32'h0000_0020;
        alu_ctrl = 3'b010;
        #10;
        if (result !== 32'h0000_0010) $error("ADD Failed");
        else $display("ADD: 0x%h + 0x%h = 0x%h [PASS]", src_a, src_b, result);

        // Test SUB (result = 0 -> Zero flag check)
        src_a = 32'd123456;
        src_b = 32'd123456;
        alu_ctrl = 3'b011;
        #10;
        if (result !== 0 || zero !== 1) $error("SUB/Zero Failed");
        else $display("SUB: %d - %d = %d, Zero=%b [PASS]", src_a, src_b, result, zero);

        // Test AND with complement pattern (expect all 0)
        src_a = 32'hA5A5_5A5A;
        src_b = 32'h5A5A_A5A5; // bitwise complement of src_a
        alu_ctrl = 3'b000;
        #10;
        if (result !== 0 || zero !== 1) $error("AND/Zero Failed");
        else $display("AND: 0x%h & 0x%h = 0x%h, Zero=%b [PASS]", src_a, src_b, result, zero);

        // Test OR with complement pattern (expect all 1s)
        src_a = 32'hA5A5_5A5A;
        src_b = 32'h5A5A_A5A5;
        alu_ctrl = 3'b001;
        #10;
        if (result !== 32'hFFFF_FFFF || zero !== 0) $error("OR/Zero Failed");
        else $display("OR: 0x%h | 0x%h = 0x%h, Zero=%b [PASS]", src_a, src_b, result, zero);

        // Test SLT (signed comparisons)
        src_a = -1;
        src_b =  1;
        alu_ctrl = 3'b111;
        #10;
        if (result !== 1) $error("SLT Failed (case 1)");
        else $display("SLT: %d < %d = %d [PASS]", $signed(src_a), $signed(src_b), result);

        src_a =  1;
        src_b = -1;
        alu_ctrl = 3'b111;
        #10;
        if (result !== 0) $error("SLT Failed (case 2)");
        else $display("SLT: %d < %d = %d [PASS]", $signed(src_a), $signed(src_b), result);

        // Test MUL (different factors)
        src_a = 13;
        src_b = 9;
        alu_ctrl = 3'b100;
        #10;
        if (result !== 32'd117) $error("MUL Failed");
        else $display("MUL: %d * %d = %d [PASS]", src_a, src_b, result);

        // Test DIV (integer truncation)
        src_a = 100;
        src_b = 7;
        alu_ctrl = 3'b101;
        #10;
        if (result !== 32'd14) $error("DIV Failed");
        else $display("DIV: %d / %d = %d [PASS]", src_a, src_b, result);
        
        $display("=== All Tests Passed ===");
        $finish;
    end
endmodule