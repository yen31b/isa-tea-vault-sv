# Makefile for ISA RISC TEA Vault Simulation

IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

SRC = src/alu.sv src/register_file.sv src/status_reg.sv src/datapath.sv
TB_ALU = testbench/tb_alu.sv
TB_REG = testbench/tb_register_file.sv

# Default target
all: alu_sim reg_sim

# ALU Simulation
alu_sim: $(SRC) $(TB_ALU)
	$(IVERILOG) -g2012 -o alu_sim.vvp src/alu.sv $(TB_ALU)
	$(VVP) alu_sim.vvp

# Register File Simulation
reg_sim: $(SRC) $(TB_REG)
	$(IVERILOG) -g2012 -o reg_sim.vvp src/register_file.sv $(TB_REG)
	$(VVP) reg_sim.vvp

clean:
	rm -f *.vvp *.vcd

.PHONY: all clean alu_sim reg_sim
