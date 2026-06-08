`timescale 1ns / 1ps

module pwm_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [7:0] duty,
    output reg        pwm_out
);
    reg [7:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 8'h00;
        else
            counter <= counter + 8'h01;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_out <= 1'b0;
        else if (en)
            pwm_out <= (counter < duty);
        else
            pwm_out <= 1'b0;
    end
endmodule
