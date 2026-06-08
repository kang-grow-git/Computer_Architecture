//==============================================================================
// MIPS PWM Motor Controller Testbench
//==============================================================================
`timescale 1ns / 1ps

module mips_tb;
    reg         clk;
    reg         rst_n;
    reg  [7:0]  switches;

    wire        pwm_out;
    wire [31:0] pc_out;
    wire [31:0] alu_result;

    // Observation-only aliases for GTKWave. These do not drive design state.
    wire [7:0]  pwm_duty   = uut.u_datapath.u_data_mem.pwm_duty;
    wire        pwm_enable = uut.u_datapath.u_data_mem.pwm_enable;
    wire        mem_write  = uut.u_datapath.mem_write_M;
    wire [31:0] mem_addr   = uut.u_datapath.alu_result_M_reg;
    wire [31:0] write_data = uut.u_datapath.write_data_M;
    wire [31:0] read_data  = uut.u_datapath.read_data_M;

    reg [7:0] last_logged_duty;
    reg       last_logged_enable;

    mips uut (
        .clk(clk),
        .rst_n(rst_n),
        .switches(switches),
        .pwm_out(pwm_out),
        .pc_out(pc_out),
        .alu_result(alu_result)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("mips.vcd");
        $dumpvars(0, mips_tb);
    end

    initial begin
        last_logged_duty = 8'hxx;
        last_logged_enable = 1'bx;
    end

    initial begin
        rst_n = 1'b0;
        switches = 8'h00;
        #40;
        rst_n = 1'b1;

        $display("===========================================");
        $display("   MIPS PWM Motor Controller PBL Test      ");
        $display("===========================================");

        #30000 switches = 8'h40;
        #30000 switches = 8'h80;
        #30000 switches = 8'hC8;
        #30000 switches = 8'hFF;

        // Rapid switch changes exercise the polling loop without bypassing MMIO.
        #10000 switches = 8'h10;
        #500  switches = 8'hF0;
        #500  switches = 8'h20;
        #500  switches = 8'hFF;

        // Reset edge case: PWM enable and duty return to zero, then software restarts.
        #10000 rst_n = 1'b0;
        #40    rst_n = 1'b1;
        #20000 switches = 8'h00;
        #30000 switches = 8'hFF;
        #30000;

        $display("===========================================");
        $display("   Simulation Complete                     ");
        $display("===========================================");
        $finish;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_logged_duty <= 8'hxx;
            last_logged_enable <= 1'bx;
        end else begin
            if (mem_write && (mem_addr == 32'h00000098) && (write_data[7:0] !== last_logged_duty)) begin
                $display("%0t ps: CPU sw duty 0x%02h from switches 0x%02h", $time, write_data[7:0], switches);
                last_logged_duty <= write_data[7:0];
            end
            if (mem_write && (mem_addr == 32'h0000009C) && (write_data[0] !== last_logged_enable)) begin
                $display("%0t ps: CPU sw enable %0d", $time, write_data[0]);
                last_logged_enable <= write_data[0];
            end
        end
    end
endmodule
