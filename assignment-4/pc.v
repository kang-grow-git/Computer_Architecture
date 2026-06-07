//==============================================================================
// Program Counter (PC)
//==============================================================================
// Description:
// 32-bit register that holds the current instruction address.
// Updates on the rising edge of the clock unless enabled is low (indicating a stall).
//==============================================================================
`timescale 1ns / 1ps

module pc (
    input  wire        clk,
    input  wire        rst_n,    // Active-low reset
    input  wire        en,       // Enable signal (0 = Stall, 1 = Update)
    input  wire [31:0] pc_next,  // Next PC value
    output reg  [31:0] pc        // Current PC value
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'd0;
        end else if (en) begin   
            pc <= pc_next;
        end
    end
endmodule