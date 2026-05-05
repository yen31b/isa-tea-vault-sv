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
BIN_FLOW   = sim_image_flow

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
# FLOW: IMAGE/BUFFER PROCESSING
# ============================================================
# FLOW: compilacion del testbench de flujo (solo compilar)
# ============================================================
.PHONY: compile_flow
compile_flow: setup
	@echo "[compile_flow] Compilando testbench de flujo..."
	$(IV) $(FLAGS) -o sim_image_flow \
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
		$(TB)/tb_image_flow.sv
	@echo "[compile_flow] Binario listo: $(BIN_FLOW)"

# sim_flow = compilar + ejecutar (uso standalone: make sim_flow)
.PHONY: sim_flow
sim_flow: compile_flow
	@echo "[sim_flow] Ejecutando simulacion..."
	$(VVP) sim_image_flow

# Direcciones parametrizables (override con POEM_ADDR=0x... o IMG_ADDR=0x...)
# Rango valido: >= 0x0100 y que el archivo quepa dentro de 64KB (0xFFFF)
POEM_ADDR ?= 0x1000   # NewHorizon.txt: 960 bytes padded
IMG_ADDR  ?= 0x1000   # BlueShield.png: 1480 bytes padded

.PHONY: assemble_encrypt
assemble_encrypt:
	@echo "[asm] Ensamblando encrypt_buffer.asm..."
	$(PYTHON) -c "import sys; sys.path.append('tools'); import asm; f=open('program.mem', 'w', encoding='ascii'); sys.stdout=f; sys.argv=['', 'asm_ISA/encrypt_buffer.asm']; asm.main(); f.close()"

.PHONY: assemble_decrypt
assemble_decrypt:
	@echo "[asm] Ensamblando decrypt_buffer.asm..."
	$(PYTHON) -c "import sys; sys.path.append('tools'); import asm; f=open('program.mem', 'w', encoding='ascii'); sys.stdout=f; sys.argv=['', 'asm_ISA/decrypt_buffer.asm']; asm.main(); f.close()"

# ============================================================
# POEM FLOW: NewHorizon.txt  (958 bytes -> 960 padded)
# Uso: make test_poem_encrypt
#      make test_poem_encrypt POEM_ADDR=0x2000
# ============================================================
.PHONY: test_poem_encrypt
test_poem_encrypt: compile_flow assemble_encrypt
	@echo "[poem] Cargando NewHorizon.txt en $(POEM_ADDR)..."
	$(PYTHON) file_loader/load_file.py --input file_loader/NewHorizon.txt --output data.mem --address $(POEM_ADDR)
	@echo "[poem] Cifrando..."
	$(VVP) $(BIN_FLOW)
	@echo "[poem] Extrayendo cifrado..."
	$(PYTHON) file_loader/extract_data.py --memory data.mem --address $(POEM_ADDR) --size 960 --output encrypted_poem.bin
	@echo "[poem] Cifrado guardado en encrypted_poem.bin (addr=$(POEM_ADDR))"

.PHONY: test_poem_decrypt
test_poem_decrypt: compile_flow assemble_decrypt
	@echo "[poem] Cargando encrypted_poem.bin en $(POEM_ADDR)..."
	$(PYTHON) file_loader/load_file.py --input encrypted_poem.bin --output data.mem --address $(POEM_ADDR)
	@echo "[poem] Descifrando..."
	$(VVP) $(BIN_FLOW)
	@echo "[poem] Extrayendo resultado final..."
	$(PYTHON) file_loader/extract_data.py --memory data.mem --address $(POEM_ADDR) --size 960 --output decrypted_poem.txt
	@echo "[poem] Listo! Revisa decrypted_poem.txt (addr=$(POEM_ADDR))"

# ============================================================
# IMAGE FLOW: BlueShield.png  (1477 bytes -> 1480 padded)
# Uso: make test_img_encrypt
#      make test_img_encrypt IMG_ADDR=0x2000
# ============================================================
.PHONY: test_img_encrypt
test_img_encrypt: compile_flow assemble_encrypt
	@echo "[img] Cargando BlueShield.png en $(IMG_ADDR)..."
	$(PYTHON) file_loader/load_file.py --input file_loader/BlueShield.png --output data.mem --address $(IMG_ADDR)
	@echo "[img] Cifrando..."
	$(VVP) $(BIN_FLOW)
	@echo "[img] Extrayendo imagen cifrada..."
	$(PYTHON) file_loader/extract_data.py --memory data.mem --address $(IMG_ADDR) --size 1480 --output encrypted_img.bin
	@echo "[img] Cifrado guardado en encrypted_img.bin (addr=$(IMG_ADDR))"

.PHONY: test_img_decrypt
test_img_decrypt: compile_flow assemble_decrypt
	@echo "[img] Cargando encrypted_img.bin en $(IMG_ADDR)..."
	$(PYTHON) file_loader/load_file.py --input encrypted_img.bin --output data.mem --address $(IMG_ADDR)
	@echo "[img] Descifrando..."
	$(VVP) $(BIN_FLOW)
	@echo "[img] Extrayendo imagen recuperada..."
	$(PYTHON) file_loader/extract_data.py --memory data.mem --address $(IMG_ADDR) --size 1480 --output decrypted_img.png
	@echo "[img] Listo! Revisa decrypted_img.png (addr=$(IMG_ADDR))"

# ============================================================
# SHIELD.JPG CON DIRECCION PARAMETRIZABLE
#
# Uso:
#   make test_shield_encrypt               → usa SHIELD_ADDR=0x2000 (default)
#   make test_shield_encrypt SHIELD_ADDR=0x3000
#   make test_shield_decrypt SHIELD_ADDR=0x3000
#
# IMPORTANTE: usa el mismo SHIELD_ADDR en encrypt y decrypt.
# Shield.jpg: 20039 bytes → 20040 padded.
# Rango valido: 0x0100 <= SHIELD_ADDR, SHIELD_ADDR+20040 <= 0xFFFF
# ============================================================
SHIELD_ADDR ?= 0x2000
SHIELD_SIZE  = 20040

.PHONY: test_shield_encrypt
test_shield_encrypt: compile_flow assemble_encrypt
	@echo "[shield] Cargando Shield.jpg en direccion $(SHIELD_ADDR)..."
	$(PYTHON) file_loader/load_file.py --input file_loader/Shield.jpg --output data.mem --address $(SHIELD_ADDR)
	@echo "[shield] Cifrando (limite: 300 000 ciclos)..."
	$(VVP) $(BIN_FLOW)
	@echo "[shield] Extrayendo imagen cifrada..."
	$(PYTHON) file_loader/extract_data.py --memory data.mem --address $(SHIELD_ADDR) --size $(SHIELD_SIZE) --output encrypted_shield.bin
	@echo "[shield] Cifrado guardado en encrypted_shield.bin (addr=$(SHIELD_ADDR))"

.PHONY: test_shield_decrypt
test_shield_decrypt: compile_flow assemble_decrypt
	@echo "[shield] Cargando cifrado previo (encrypted_shield.bin) en $(SHIELD_ADDR)..."
	$(PYTHON) file_loader/load_file.py --input encrypted_shield.bin --output data.mem --address $(SHIELD_ADDR)
	@echo "[shield] Descifrando (limite: 300 000 ciclos)..."
	$(VVP) $(BIN_FLOW)
	@echo "[shield] Extrayendo imagen recuperada..."
	$(PYTHON) file_loader/extract_data.py --memory data.mem --address $(SHIELD_ADDR) --size $(SHIELD_SIZE) --output decrypted_shield.jpg
	@echo "[shield] Listo! Revisa decrypted_shield.jpg (addr=$(SHIELD_ADDR))"


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
	@echo "[clean] === Binarios de simulacion ==="
	rm -f $(BIN_DMEM) $(BIN_VAULT) $(BIN_AUTH) $(BIN_CTRL) \
	      $(BIN_DECODE) $(BIN_FETCH) $(BIN_INT) $(BIN_ALU) \
	      $(BIN_TEA) $(BIN_TOP) $(BIN_PERF) $(BIN_ROUND) $(BIN_FLOW)
	@echo "[clean] === Binarios .vvp huerfanos (formato antiguo) ==="
	rm -f compile_test.vvp sim_ctrl_test.vvp sim_decode_test.vvp \
	      sim_fetch_test.vvp sim_integ_test.vvp sim_regfile_test.vvp
	@echo "[clean] === Archivos VCD ==="
	rm -f $(VCD)/*.vcd
	@echo "[clean] === Archivos de programa y datos ==="
	rm -f program.mem data.mem tb_program.mem
	@echo "[clean] === Salidas de tests (poema, imagen y otros) ==="
	rm -f encrypted_poem.bin decrypted_poem.txt
	rm -f encrypted_img.bin  decrypted_img.png
	rm -f encrypted_shield.bin decrypted_shield.jpg
	rm -f cifrado.bin
	@echo "[clean] Listo"

