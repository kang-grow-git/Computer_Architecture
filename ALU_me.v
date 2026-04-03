`timescale 1ns / 1ps
module alu (
    input  wire [31:0] src_a,      // operand A
    input  wire [31:0] src_b,      // operand B
    input  wire [2:0]  alu_ctrl,   // operation select
    output reg  [31:0] result,     // result
    output wire        zero        // zero flag
);
    always @(*) begin
        case (alu_ctrl)
            3'b000: result = src_a & src_b;                        // AND
            3'b001: result = src_a | src_b;                        // OR
            3'b010: result = src_a + src_b;                        // ADD
            3'b011: result = src_a - src_b;                        // SUB
            3'b100: result = src_a * src_b;                        // mul
            3'b101: result = src_a / src_b;                        // div
            3'b110: result = ($signed(src_a) < $signed(src_b)) ? 1 : 0;
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule