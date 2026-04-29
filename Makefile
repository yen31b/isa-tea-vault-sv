# Makefile for ISA RISC TEA Vault Simulation

IVERILOG = iverilog
VVP = vvp
FLAGS = -g2012

# Source files
SRC_ALU  = src/alu.sv
SRC_REG  = src/register_file.sv
SRC_SR   = src/status_reg.sv
SRC_DP   = src/datapath.sv

# Testbench files
TB_ALU = testbench/tb_alu.sv
TB_REG = testbench/tb_register_file.sv
TB_DP  = testbench/tb_datapath.sv

# Default target
all: alu reg dp

# ALU Simulation
alu: $(SRC_ALU) $(TB_ALU)
	$(IVERILOG) $(FLAGS) -o alu_sim.vvp $(SRC_ALU) $(TB_ALU)
	$(VVP) alu_sim.vvp

# Register File Simulation
reg: $(SRC_REG) $(TB_REG)
	$(IVERILOG) $(FLAGS) -o reg_sim.vvp $(SRC_REG) $(TB_REG)
	$(VVP) reg_sim.vvp

# Datapath Simulation
dp: $(SRC_ALU) $(SRC_REG) $(SRC_SR) $(SRC_DP) $(TB_DP)
	$(IVERILOG) $(FLAGS) -o dp_sim.vvp $(SRC_ALU) $(SRC_REG) $(SRC_SR) $(SRC_DP) $(TB_DP)
	$(VVP) dp_sim.vvp

clean:
	rm -f *.vvp *.vcd

.PHONY: all clean alu reg dp
