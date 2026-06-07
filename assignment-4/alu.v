//==============================================================================
// Arithmetic Logic Unit (ALU)
//==============================================================================
// Description:
// Performs 32-bit arithmetic and logical operations.
//
// Operations (alu_ctrl):
// - 000: AND
// - 001: OR
// - 010: ADD
// - 110: SUB
// - 111: SLT (Set Less Than)
//==============================================================================
`timescale 1ns / 1ps

module alu (
    input  wire [31:0] src_a,      // Operand A
    input  wire [31:0] src_b,      // Operand B
    input  wire [2:0]  alu_ctrl,   // Operation control
    output reg  [31:0] result,     // ALU Result
    output wire        zero        // Zero Flag (1 if result == 0)
);
    always @(*) begin
        case (alu_ctrl)
            3'b000: result = src_a & src_b;                        // AND
            3'b001: result = src_a | src_b;                        // OR
            3'b010: result = src_a + src_b;                        // ADD
            3'b110: result = src_a - src_b;                        // SUB
            3'b111: result = ($signed(src_a) < $signed(src_b)) ? 1 : 0; // SLT
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule