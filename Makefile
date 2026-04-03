all: sim

sim:
	iverilog -o test.vvp alu_tb.v ALU_me.v 
	vvp test.vvp

wave:
	gtkwave alu.vcd

clean:
	rm -f *.vvp *.vcd
