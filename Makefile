# Makefile — ISA RISC Seguridad Informática
# Comandos de uso:
#   make all            → compila y corre todos los testbenches disponibles
#   make tb_dmem        → solo data_mem
#   make tb_vault       → solo key_vault
#   make tb_auth        → solo auth_unit
#   make tb_ctrl          → solo control_unit 
#   make tb_decode        → solo instruction_decode 
#   make tb_fetch         → solo instruction_fetch 
#   make tb_integration → integración P1 + P3
#   make tb_alu         → solo ALU — pendiente P2
#   make tb_tea         → prueba de encriptación y descifrado TEA real
#   make tb_top         → sistema completo — pendiente todos
#   make wave_dmem      → abre GTKWave para data_mem
#   make wave_vault     → abre GTKWave para key_vault
#   make wave_auth        → GTKWave auth_unit
#   make wave_ctrl        → GTKWave control_unit
#   make wave_decode      → GTKWave instruction_decode
#   make wave_fetch       → GTKWave instruction_fetch
#   make wave_int       → abre GTKWave para integración
#   make clean          → elimina binarios y .vcd

# ---- Herramientas ----
IV    = iverilog
VVP   = vvp
WAVE  = gtkwave
FLAGS = -g2012
PYTHON = python3

# ---- Directorios ----
SRC = src
TB  = tb
VCD = vcd
MEM = mem

# ---- Binarios de simulación ----
BIN_DMEM   = sim_dmem
BIN_VAULT  = sim_vault
BIN_AUTH   = sim_auth
BIN_CTRL   = sim_ctrl
BIN_DECODE = sim_decode
BIN_FETCH  = sim_fetch
BIN_INT    = sim_integration
BIN_ALU    = sim_alu
BIN_TEA    = sim_tea
BIN_TOP    = sim_top
BIN_PERF   = sim_perf
BIN_ROUND  = sim_roundtrip

# ============================================================
# TARGET PRINCIPAL
# Cuando P2 y P4 estén listos, cambiar a:
# all: setup tb_dmem tb_vault tb_alu tb_tea tb_integration tb_top
# ============================================================
.PHONY: all
all: setup tb_dmem tb_vault tb_auth tb_ctrl tb_decode tb_fetch tb_integration tb_tea

# ============================================================
# SETUP — crear directorios necesarios
# ============================================================
.PHONY: setup
setup:
	@mkdir -p $(VCD) $(MEM)
	@echo "[setup] Directorios $(VCD)/ y $(MEM)/ listos"



# ============================================================
# data memory
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
# key_vault
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
# auth_unit
# ============================================================
.PHONY: tb_auth
tb_auth: setup
	@echo "[tb_auth] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_AUTH) \
		$(SRC)/auth_unit.sv \
		$(TB)/tb_auth_unit.sv
	@echo "[tb_auth] Simulando..."
	$(VVP) $(BIN_AUTH)
 
# ============================================================
# control_unit
# ============================================================
.PHONY: tb_ctrl
tb_ctrl: setup
	@echo "[tb_ctrl] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_CTRL) \
		$(SRC)/control_unit.sv \
		$(TB)/tb_control_unit.sv
	@echo "[tb_ctrl] Simulando..."
	$(VVP) $(BIN_CTRL)
 
# ============================================================
# instruction_decode
# ============================================================
.PHONY: tb_decode
tb_decode: setup
	@echo "[tb_decode] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_DECODE) \
		$(SRC)/instruction_decode.sv \
		$(TB)/tb_instruction_decode.sv
	@echo "[tb_decode] Simulando..."
	$(VVP) $(BIN_DECODE)
 
# ============================================================
# instruction_fetch
# Necesita tb_program.mem en la raíz del proyecto
# ============================================================
.PHONY: tb_fetch
tb_fetch: setup
	@echo "[tb_fetch] Compilando..."
	$(IV) $(FLAGS) -o $(BIN_FETCH) \
		$(SRC)/instruction_fetch.sv \
		$(TB)/tb_instruction_fetch.sv
	@cp $(TB)/tb_program.mem .
	@echo "[tb_fetch] Simulando..."
	$(VVP) $(BIN_FETCH)

# ============================================================
# Iintegracion CPU + vault
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
# ALU, register_file, datapath 
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
# TEA Full Verification (Encrypt + Decrypt)
# ============================================================
.PHONY: tb_tea
tb_tea: setup
	@echo "[tb_tea] Ensamblando programa TEA..."
	@$(PYTHON) tools/asm.py asm_ISA/tea_full.asm > tb/tea_encrypt.mem
	@echo "[tb_tea] Compilando procesador..."
	$(IV) $(FLAGS) -o $(BIN_TEA) \
		$(SRC)/status_reg.sv \
		$(SRC)/alu.sv \
		$(SRC)/register_file.sv \
		$(SRC)/datapath.sv \
		$(SRC)/instruction_fetch.sv \
		$(SRC)/instruction_decode.sv \
		$(SRC)/control_unit.sv \
		$(SRC)/auth_unit.sv \
		$(SRC)/data_mem.sv \
		$(SRC)/key_vault.sv \
		$(SRC)/top.sv \
		$(TB)/tb_tea_system.sv
	@echo "[tb_tea] Simulando..."
	$(VVP) $(BIN_TEA)

# ============================================================
# SISTEMA COMPLETO 
# ============================================================
.PHONY: tb_top
tb_top: setup
	@echo "[tb_top] Compilando sistema completo..."
	$(IV) $(FLAGS) -o $(BIN_TOP) \
		$(SRC)/status_reg.sv \
		$(SRC)/alu.sv \
		$(SRC)/register_file.sv \
		$(SRC)/datapath.sv \
		$(SRC)/instruction_fetch.sv \
		$(SRC)/instruction_decode.sv \
		$(SRC)/control_unit.sv \
		$(SRC)/auth_unit.sv \
		$(SRC)/data_mem.sv \
		$(SRC)/key_vault.sv \
		$(SRC)/top.sv \
		$(TB)/tb_top.sv
	@echo "[tb_top] Simulando..."
	$(VVP) $(BIN_TOP)

# ============================================================
# PERFORMANCE COMPARISON
# ============================================================
.PHONY: tb_perf
tb_perf: setup
	@echo "[tb_perf] Compilando comparativa de rendimiento..."
	$(IV) $(FLAGS) -o $(BIN_PERF) \
		$(SRC)/status_reg.sv \
		$(SRC)/alu.sv \
		$(SRC)/register_file.sv \
		$(SRC)/datapath.sv \
		$(SRC)/instruction_fetch.sv \
		$(SRC)/instruction_decode.sv \
		$(SRC)/control_unit.sv \
		$(SRC)/auth_unit.sv \
		$(SRC)/data_mem.sv \
		$(SRC)/key_vault.sv \
		$(SRC)/top.sv \
		$(TB)/tb_performance_comp.sv
	@echo "[tb_perf] Simulando..."
	$(VVP) $(BIN_PERF)

# ============================================================
# ROUNDTRIP VERIFICATION (Encrypt + Decrypt = Original)
# ============================================================
.PHONY: tb_roundtrip
tb_roundtrip: setup
	@echo "[tb_roundtrip] Compilando prueba de fuego..."
	$(IV) $(FLAGS) -o $(BIN_ROUND) \
		$(SRC)/status_reg.sv \
		$(SRC)/alu.sv \
		$(SRC)/register_file.sv \
		$(SRC)/datapath.sv \
		$(SRC)/instruction_fetch.sv \
		$(SRC)/instruction_decode.sv \
		$(SRC)/control_unit.sv \
		$(SRC)/auth_unit.sv \
		$(SRC)/data_mem.sv \
		$(SRC)/key_vault.sv \
		$(SRC)/top.sv \
		$(TB)/tb_roundtrip.sv
	@echo "[tb_roundtrip] Simulando..."
	$(VVP) $(BIN_ROUND)

# ============================================================
# VERIFICACION INTEGRAL
# ============================================================
.PHONY: tb_verify
tb_verify: setup
	@echo "[tb_verify] Compilando..."
	$(IV) $(FLAGS) -o sim_verify \
		$(SRC)/status_reg.sv \
		$(SRC)/alu.sv \
		$(SRC)/register_file.sv \
		$(SRC)/datapath.sv \
		$(SRC)/instruction_fetch.sv \
		$(SRC)/instruction_decode.sv \
		$(SRC)/control_unit.sv \
		$(SRC)/auth_unit.sv \
		$(SRC)/data_mem.sv \
		$(SRC)/key_vault.sv \
		$(SRC)/top.sv \
		$(TB)/tb_verify_system.sv
	@echo "[tb_verify] Simulando..."
	$(VVP) sim_verify

# ============================================================
# GTKWAVE — visualizar señales
# ============================================================
.PHONY: wave_dmem
wave_dmem:
	$(WAVE) $(VCD)/tb_dmem.vcd &

.PHONY: wave_vault
wave_vault:
	$(WAVE) $(VCD)/tb_key_vault.vcd &

.PHONY: wave_auth
wave_auth:
	$(WAVE) $(VCD)/tb_auth_unit.vcd &
 
.PHONY: wave_ctrl
wave_ctrl:
	$(WAVE) $(VCD)/tb_control_unit.vcd &
 
.PHONY: wave_decode
wave_decode:
	$(WAVE) $(VCD)/tb_instruction_decode.vcd &
 
.PHONY: wave_fetch
wave_fetch:
	$(WAVE) $(VCD)/tb_instruction_fetch.vcd &
 

.PHONY: wave_int
wave_int:
	$(WAVE) $(VCD)/tb_integration_cpu_vault.vcd &

.PHONY: wave_tea
wave_tea:
	$(WAVE) $(VCD)/tb_tea_system.vcd &

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
	      $(BIN_ALU) $(BIN_TEA) $(BIN_TOP) \
	      $(BIN_AUTH) $(BIN_CTRL) $(BIN_DECODE) $(BIN_FETCH)
	rm -f $(VCD)/*.vcd
	rm -f tb_program.mem
	@echo "[clean] Listo"
