# Makefile — ISA RISC Seguridad Informática
# Comandos de uso:
#   make all            → compila y corre todos los testbenches disponibles
#   make tb_dmem        → solo data_mem
#   make tb_vault       → solo key_vault
#   make tb_integration → integración P1 + P3
#   make tb_alu         → solo ALU — pendiente P2
#   make tb_tea         → solo TEA — pendiente P4
#   make tb_top         → sistema completo — pendiente todos
#   make wave_dmem      → abre GTKWave para data_mem
#   make wave_vault     → abre GTKWave para key_vault
#   make wave_int       → abre GTKWave para integración
#   make clean          → elimina binarios y .vcd

# ---- Herramientas ----
IV    = iverilog
VVP   = vvp
WAVE  = gtkwave
FLAGS = -g2012

# ---- Directorios ----
SRC = src
TB  = tb
VCD = vcd
MEM = mem

# ---- Binarios de simulación ----
BIN_DMEM  = sim_dmem
BIN_VAULT = sim_vault
BIN_INT   = sim_integration
BIN_ALU   = sim_alu
BIN_TEA   = sim_tea
BIN_TOP   = sim_top

# ============================================================
# TARGET PRINCIPAL
# Cuando P2 y P4 estén listos, cambiar a:
# all: setup tb_dmem tb_vault tb_alu tb_tea tb_integration tb_top
# ============================================================
.PHONY: all
all: setup tb_dmem tb_vault tb_integration

# ============================================================
# SETUP — crear directorios necesarios
# ============================================================
.PHONY: setup
setup:
	@mkdir -p $(VCD) $(MEM)
	@echo "[setup] Directorios $(VCD)/ y $(MEM)/ listos"

# ============================================================
# P3 — data_mem
# ============================================================
.PHONY: tb_dmem
tb_dmem: setup
	@echo "[tb_dmem] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_DMEM) \
		$(SRC)/data_mem.sv \
		$(TB)/tb_data_mem.sv
	@echo "[tb_dmem] Simulando..."
	$(VVP) $(BIN_DMEM)

# ============================================================
# P3 — key_vault
# ============================================================
.PHONY: tb_vault
tb_vault: setup
	@echo "[tb_vault] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_VAULT) \
		$(SRC)/key_vault.sv \
		$(TB)/tb_key_vault.sv
	@echo "[tb_vault] Simulando..."
	$(VVP) $(BIN_VAULT)

# ============================================================
# INTEGRACIÓN P1 + P3
# ============================================================
.PHONY: tb_integration
tb_integration: setup
	@echo "[tb_integration] Compilando P1 + P3..."
	$(IV) $(FLAGS) -o $(BIN_INT) \
		$(SRC)/instruction_decode.sv \
		$(SRC)/control_unit.sv \
		$(SRC)/auth_unit.sv \
		$(SRC)/data_mem.sv \
		$(SRC)/key_vault.sv \
		$(TB)/tb_integration_cpu_vault.sv
	@echo "[tb_integration] Simulando..."
	$(VVP) $(BIN_INT)

# ============================================================
# P2 — ALU, register_file, datapath (pendiente)
# ============================================================
.PHONY: tb_alu
tb_alu: setup
	@echo "[tb_alu] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_ALU) \
		$(SRC)/alu.sv \
		$(TB)/tb_alu.sv
	@echo "[tb_alu] Simulando..."
	$(VVP) $(BIN_ALU)

# ============================================================
# P4 — TEA unit (pendiente)
# ============================================================
.PHONY: tb_tea
tb_tea: setup
	@echo "[tb_tea] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_TEA) \
		$(SRC)/tea_unit.sv \
		$(TB)/tb_tea.sv
	@echo "[tb_tea] Simulando..."
	$(VVP) $(BIN_TEA)

# ============================================================
# SISTEMA COMPLETO — todos los módulos (pendiente)
# ============================================================
.PHONY: tb_top
tb_top: setup
	@echo "[tb_top] Compilando sistema completo..."
	$(IV) $(FLAGS) -o $(BIN_TOP) \
		$(SRC)/instruction_fetch.sv \
		$(SRC)/instruction_decode.v \
		$(SRC)/control_unit.sv \
		$(SRC)/auth_unit.sv \
		$(SRC)/alu.sv \
		$(SRC)/register_file.sv \
		$(SRC)/datapath.sv \
		$(SRC)/data_mem.sv \
		$(SRC)/key_vault.sv \
		$(SRC)/tea_unit.sv \
		$(SRC)/top.sv \
		$(TB)/tb_top.sv
	@echo "[tb_top] Simulando..."
	$(VVP) $(BIN_TOP)

# ============================================================
# GTKWAVE — visualizar señales
# ============================================================
.PHONY: wave_dmem
wave_dmem:
	$(WAVE) $(VCD)/tb_dmem.vcd &

.PHONY: wave_vault
wave_vault:
	$(WAVE) $(VCD)/tb_key_vault.vcd &

.PHONY: wave_int
wave_int:
	$(WAVE) $(VCD)/tb_integration_cpu_vault.vcd &

.PHONY: wave_top
wave_top:
	$(WAVE) $(VCD)/tb_top.vcd &

# ============================================================
# LIMPIEZA
# ============================================================
.PHONY: clean
clean:
	@echo "[clean] Eliminando binarios y VCDs..."
	rm -f $(BIN_DMEM) $(BIN_VAULT) $(BIN_INT) \
	      $(BIN_ALU) $(BIN_TEA) $(BIN_TOP)
	rm -f $(VCD)/*.vcd
	@echo "[clean] Listo"