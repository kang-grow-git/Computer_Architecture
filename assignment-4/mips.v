//==============================================================================
// MIPS Processor Top Level Module
//==============================================================================
// Description:
// This module interconnects the Datapath and Control Unit to form the complete
// 5-stage Pipelined MIPS Processor.
//
// Key Features:
// - 5-Stage Pipeline: Fetch, Decode, Execute, Memory, Writeback
// - Hazard Handling: Forwarding (EX, ID) and Stalling (Load-Use, Branch)
// - Branch Prediction: Early Branch Resolution (ID Stage)
// - Instructions: R-type, lw, sw, beq, addi, j (Jump)
//==============================================================================
`timescale 1ns / 1ps

module mips (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] pc_out,      // Current PC (for debugging)
    output wire [31:0] alu_result   // Current ALU result (for debugging)
);
    // --- Internal Connection Wires ---

    // Decode Stage Signals
    wire [31:0] instr_D;
    wire       reg_write_D, mem_to_reg_D, mem_write_D, branch_D;
    wire       alu_src_D, reg_dst_D, jump_D;
    wire [2:0] alu_ctrl_D;
    wire [4:0] rs_D, rt_D;

    // Execute/Memory/Writeback Stage Signals (for Hazard Unit)
    wire [4:0] rs_E, rt_E, write_reg_E, write_reg_M, write_reg_W;
    wire       reg_write_E, mem_to_reg_E, mem_to_reg_M;
    wire       reg_write_M, reg_write_W;

    // Hazard Control Signals
    wire [1:0] forward_a_D, forward_b_D; // Forwarding to ID (Branch)
    wire [1:0] forward_a_E, forward_b_E; // Forwarding to EX (ALU)
    wire       stall_F, stall_D, flush_E; // Pipeline Stalls/Flushes

    // --- Control Unit Instance ---
    // Decodes instructions in the ID stage and generates control signals.
    control_unit u_control (
        .opcode(instr_D[31:26]), 
        .funct(instr_D[5:0]),
        .mem_to_reg(mem_to_reg_D), 
        .mem_write(mem_write_D), 
        .branch(branch_D),
        .alu_src(alu_src_D), 
        .reg_dst(reg_dst_D), 
        .reg_write(reg_write_D), 
        .jump(jump_D), 
        .alu_ctrl(alu_ctrl_D)
    );

    // --- Hazard Unit Instance ---
    // Detects data dependencies and load-use hazards to control pipeline flow.
    hazard_unit u_hazard (
        // Forwarding Sources (EX, MEM, WB stages)
        .rs_E(rs_E), .rt_E(rt_E),
        .write_reg_E(write_reg_E), .reg_write_E(reg_write_E), .mem_to_reg_E(mem_to_reg_E),
        .write_reg_M(write_reg_M), .reg_write_M(reg_write_M), .mem_to_reg_M(mem_to_reg_M),
        .write_reg_W(write_reg_W), .reg_write_W(reg_write_W),
        
        // Stall/Flush Sources (ID stage)
        .rs_D(rs_D), .rt_D(rt_D),
        .branch_D(branch_D),
        
        // Outputs
        .forward_a_E(forward_a_E), .forward_b_E(forward_b_E),
        .forward_a_D(forward_a_D), .forward_b_D(forward_b_D),
        .stall_F(stall_F), .stall_D(stall_D), .flush_E(flush_E)
    );

    // --- Datapath Instance ---
    // Contains the registers, ALU, Muxes, and Pipeline Registers.
    datapath u_datapath (
        .clk(clk), .rst_n(rst_n),
        
        // Inputs from Control Unit
        .reg_write_D(reg_write_D), .mem_to_reg_D(mem_to_reg_D), .mem_write_D(mem_write_D),
        .alu_ctrl_D(alu_ctrl_D), .alu_src_D(alu_src_D), .reg_dst_D(reg_dst_D), 
        .branch_D(branch_D), .jump_D(jump_D),
        
        // Inputs from Hazard Unit
        .forward_a_E(forward_a_E), .forward_b_E(forward_b_E),
        .forward_a_D(forward_a_D), .forward_b_D(forward_b_D),
        .stall_F(stall_F), .stall_D(stall_D), .flush_E(flush_E),
        
        // Outputs to Hazard Unit
        .rs_D(rs_D), .rt_D(rt_D),
        .rs_E(rs_E), .rt_E(rt_E), 
        .write_reg_E(write_reg_E), .reg_write_E(reg_write_E), .mem_to_reg_E(mem_to_reg_E),
        .write_reg_M(write_reg_M), .reg_write_M(reg_write_M), .mem_to_reg_M(mem_to_reg_M), 
        .write_reg_W(write_reg_W), .reg_write_W(reg_write_W),
        
        // Debug Outputs & Internal Instruction Wire
        .instr_D(instr_D), 
        .pc_out(pc_out), 
        .alu_result_out(alu_result)
    );
endmodule
