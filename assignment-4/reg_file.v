//==============================================================================
// Register File
//==============================================================================
// Description:
// 32x32-bit General Purpose Registers (GPR).
// - Read Ports: 2 (Async output)
// - Write Port: 1 (Sync write on clock edge)
// - Register 0 ($0) is hardwired to 0.
//==============================================================================
`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,        // Clock
    input  wire        we3,        // Write Enable
    input  wire [4:0]  wa3,        // Write Address
    input  wire [31:0] wd3,        // Write Data
    input  wire [4:0]  ra1,        // Read Address 1
    input  wire [4:0]  ra2,        // Read Address 2
    output wire [31:0] rd1,        // Read Data 1
    output wire [31:0] rd2         // Read Data 2
);
    reg [31:0] rf [31:0];          // 32 registers x 32 bits
    
    always @(posedge clk) begin
        if (we3 && (wa3 != 5'd0))  // write if enabled, skip $0
            rf[wa3] <= wd3;        // write to register
    end
    
    assign rd1 = (ra1 == 5'd0) ? 32'd0 : rf[ra1];  // $0 always 0
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : rf[ra2];  // $0 always 0
endmodule