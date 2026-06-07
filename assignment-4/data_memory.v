//==============================================================================
// Data Memory
//==============================================================================
// Description:
// Synchronous Write / Asynchronous Read RAM.
// Used for Load/Store instructions.
// 
// Parameters:
// - WIDTH: Data width (32 bits)
// - DEPTH: Memory depth (256 words)
//==============================================================================
`timescale 1ns / 1ps

module data_memory #(
    parameter WIDTH = 32,
    parameter DEPTH = 256
)(
    input  wire        clk,
    input  wire        mem_write_en,  // Write Enable
    input  wire [31:0] addr,          // Address (Byte aligned input, converted internal)
    input  wire [31:0] write_data,    // Data to write
    output wire [31:0] read_data      // Data read port
);
    reg [WIDTH-1:0] ram [0:DEPTH-1];
    assign read_data = ram[addr[31:2]];
    always @(posedge clk) begin
        if (mem_write_en) begin
            ram[addr[31:2]] <= write_data;
        end
    end
endmodule