//==============================================================================
// Instruction Memory
//==============================================================================
// Description:
// Read-only memory that stores the program code.
// Initialized from the file "memfile.dat".
//
// Parameters:
// - WIDTH: Data width (32 bits)
// - DEPTH: Memory depth (256 words)
//==============================================================================
`timescale 1ns / 1ps

module instruction_memory #(
    parameter WIDTH = 32,
    parameter DEPTH = 256
)(
    input  wire [31:0] addr,       // Byte address (Must be word aligned)
    output wire [31:0] rd          // Instruction Read Data
);
    reg [WIDTH-1:0] ram [0:DEPTH-1];
    
    initial begin
        $readmemh("memfile.dat", ram);  // load program
    end
    
    assign rd = ram[addr[31:2]];   // word aligned
endmodule