//==============================================================================
// Data Memory with MMIO for the PBL PWM Motor Controller
//==============================================================================
// Address map:
//   0x0000-0x008F : normal RAM
//   0x0090        : switches, read-only, zero-extended to 32 bits
//   0x0098        : PWM duty, write register, reads return current value
//   0x009C        : PWM enable, write register, reads return current value
//==============================================================================
`timescale 1ns / 1ps

module data_memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mem_write_en,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire [7:0]  switches,

    output wire        pwm_out,
    output reg  [31:0] read_data
);
    localparam ADDR_SWITCHES   = 32'h00000090;
    localparam ADDR_PWM_DUTY   = 32'h00000098;
    localparam ADDR_PWM_ENABLE = 32'h0000009C;

    reg [31:0] ram [0:63];
    wire [31:0] ram_out;
    assign ram_out = ram[addr[7:2]];

    reg [7:0] pwm_duty;
    reg       pwm_enable;

    pwm_controller u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        .en(pwm_enable),
        .duty(pwm_duty),
        .pwm_out(pwm_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_duty <= 8'h00;
            pwm_enable <= 1'b0;
        end else if (mem_write_en) begin
            case (addr)
                ADDR_SWITCHES:   ;
                ADDR_PWM_DUTY:   pwm_duty <= write_data[7:0];
                ADDR_PWM_ENABLE: pwm_enable <= write_data[0];
                default:         ram[addr[7:2]] <= write_data;
            endcase
        end
    end

    always @(*) begin
        case (addr)
            ADDR_SWITCHES:   read_data = {24'b0, switches};
            ADDR_PWM_DUTY:   read_data = {24'b0, pwm_duty};
            ADDR_PWM_ENABLE: read_data = {31'b0, pwm_enable};
            default:         read_data = ram_out;
        endcase
    end
endmodule
