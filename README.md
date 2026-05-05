# isa-tea-vault-sv

# 🔐 ISA RISC TEA Vault — SystemVerilog

Implementación en SystemVerilog de una arquitectura del set de instrucciones (ISA) tipo RISC con soporte nativo para seguridad informática, desarrollada como Proyecto Grupal I del curso de Arquitectura de Computadores.

---

Este proyecto consiste en el diseño e implementación de un procesador RISC personalizado con extensiones de hardware orientadas a la seguridad de la información. El procesador incluye soporte nativo para:

- **Cifrado de bloques TEA** (*Tiny Encryption Algorithm*) con instrucciones especializadas que aceleran el algoritmo directamente en hardware.
- **Bóveda de llaves criptográficas** (*Key Vault*), una memoria segura de acceso restringido que almacena hasta 4 llaves de 128 bits, inaccesible desde instrucciones de memoria convencionales.
- **Control de autorización** (*Authentication Unit*) para validar acceso a recursos protegidos.

El procesador es simulado con **Icarus Verilog (iverilog)** y las formas de onda son visualizadas con **GTKWave**.

---

## Características Principales

### Procesador
- ISA tipo RISC de instrucciones de 32 bits
- 16 registros de propósito general de 32 bits (`r0`–`r15`)
- Program Counter (PC) y registro de estado (flags: Zero, Carry, Overflow)
- Memoria RAM de 64 KB, direccionamiento de 32 bits

### Instrucciones CPU
- Aritméticas: `ADD`, `SUB`, `MUL`, `CMP`
- Lógicas: `AND`, `OR`, `XOR`
- Desplazamientos: `SLL`, `SRL`
- Memoria: `LD` (carga), `ST` (almacena)
- Control de flujo: `JMP`, `BEQ` (branch if equal)
- Movimiento inmediato: `MOV`

### Instrucciones de Bóveda (Vault)
- `VSTR`: Almacenar clave en bóveda (privilegiado)
- `VLD`: Cargar clave desde bóveda (privilegiado)
- `VCLR`: Limpiar ranura de bóveda (privilegiado)
- `VAUTH`: Autenticar con contraseña
- `VLOGOUT`: Logout, limpiar estado de autenticación

### Instrucciones de Cifrado TEA
- `XORTEA`: Triple XOR para aceleración de TEA
- `BEQADD`: Loop branch especializado para TEA (privilegiado)

---

## 📁 Estructura del Proyecto

```
isa-tea-vault-sv/
├── README.md                      # Este archivo
├── Makefile                       # Automatización de compilación y simulación
├── extract_data.py                # Herramienta para extraer datos de archivos
├── load_file.py                   # Cargador de archivos → memoria RAM
│
├── src/                           # Módulos SystemVerilog
│   ├── top.sv                     # Top-level del sistema
│   ├── datapath.sv                # Ruta de datos principal
│   ├── control_unit.sv            # Unidad de control
│   ├── alu.sv                     # Unidad aritmético-lógica
│   ├── register_file.sv           # Banco de registros (16 × 32 bits)
│   ├── instruction_fetch.sv       # Etapa de fetch
│   ├── instruction_decode.sv      # Decodificador de instrucciones
│   ├── data_mem.sv                # Memoria de datos (64 KB)
│   ├── key_vault.sv               # Bóveda de llaves (4 slots × 128 bits)
│   ├── auth_unit.sv               # Unidad de autenticación
│   └── status_reg.sv              # Registro de estado (flags)
│
├── tb/                            # Testbenches
│   ├── tb_top.sv                  # Test del sistema completo
│   ├── tb_datapath.sv             # Test de ruta de datos
│   ├── tb_control_unit.sv         # Test de unidad de control
│   ├── tb_alu.sv                  # Test de ALU
│   ├── tb_register_file.sv        # Test de banco de registros
│   ├── tb_instruction_fetch.sv    # Test de fetch
│   ├── tb_instruction_decode.sv   # Test de decodificador
│   ├── tb_data_mem.sv             # Test de memoria de datos
│   ├── tb_key_vault.sv            # Test de bóveda de llaves
│   ├── tb_auth_unit.sv            # Test de autenticación
│   ├── tb_integration_cpu_vault.sv # Test de integración CPU ↔ Vault
│   ├── tb_tea_system.sv           # Test de sistema TEA completo
│   ├── tb_verify_system.sv        # Test de verificación
│   ├── tb_program.mem             # Programa de prueba
│   ├── tea_encrypt.mem            # Datos para cifrado TEA
│   ├── tea_data.mem               # Datos de prueba TEA
│   ├── verify_data.mem            # Datos de verificación
│   └── verify_vault_ram.mem       # Estado de verificación (RAM + Vault)
│
├── asm_ISA/                       # Ensamblador y código assembly
│   └── tea_full.asm               # Programa completo de cifrado TEA
│
├── TEA/                           # Referencia de algoritmo TEA
│   └── tea.s                      # Implementación en assembly
│
├── tools/                         # Utilidades
│   └── asm.py                     # Ensamblador custom → machine code
│
├── sim/                           # Simulador (generado durante compilación)
├── sim_verify                     # Ejecutable de verificación
├── mem/                           # Archivos de memoria
│   └── program.mem                # Programa inicial
│
├── docs/                          # Documentación
│   └── isa.md                     # Green sheet: referencia de ISA
│
└── vcd/                           # Archivos de forma de onda para GTKWave
    ├── dmem_trace.vcd
    ├── vault_trace.vcd
    ├── auth_trace.vcd
    ├── ctrl_trace.vcd
    ├── decode_trace.vcd
    ├── fetch_trace.vcd
    ├── integration_trace.vcd
    ├── alu_trace.vcd
    ├── tea_trace.vcd
    └── top_trace.vcd
```

---

## 🔐 Seguridad del Diseño

### Bóveda de Llaves (Key Vault)
- **4 slots** de almacenamiento, cada uno con **4 palabras de 32 bits** (128 bits totales)
- **Acceso privilegiado** mediante instrucciones especiales (`VSTR`, `VLD`, `VCLR`)
- **Imposible acceder** a través de instrucciones de carga/almacenamiento convencionales
- Las llaves permanecen **encriptadas internamente** durante su uso

### Autenticación
- La unidad de autenticación (*Authentication Unit*) valida acceso a operaciones de bóveda
- Estados: Desautenticado, Autenticando, Autenticado
- Se requiere contraseña correcta antes de cualquier operación de bóveda
- `VLOGOUT` limpia el estado de autenticación ("Cierre de sesión")

### Control de Privilegios
- Instrucciones privilegiadas: `VSTR`, `VLD`, `VCLR`, `XORTEA`, `BEQADD`
- Solo ejecutables en modo supervisor (cuando `auth_status == AUTHENTICATED`)

---

## Compilación y Simulación

### Requisitos

- [Icarus Verilog](https://steveicarus.github.io/iverilog/) `>= 11.0`
- [GTKWave](http://gtkwave.sourceforge.net/) (opcional, para visualizar formas de onda)
- Python `>= 3.8` (para herramientas de carga de archivos y ensamblador)

### Instalación en Linux

```bash
# Debian/Ubuntu
sudo apt-get install iverilog gtkwave

# macOS (con Homebrew)
brew install iverilog gtkwave
```

### Instalación en Windows
Descargar desde:
- [Icarus Verilog Binaries](https://steveicarus.github.io/iverilog/)
- [GTKWave](http://gtkwave.sourceforge.net/)

---

## Uso por medio del Makefile

### Compilar y ejecutar todos los testbenches

```bash
make all
```

### Compilar testbenches individuales

```bash
make tb_dmem        # Test de memoria de datos
make tb_vault       # Test de bóveda de llaves
make tb_auth        # Test de autenticación
make tb_ctrl        # Test de unidad de control
make tb_decode      # Test de decodificador de instrucciones
make tb_fetch       # Test de fetch de instrucciones
make tb_alu         # Test de ALU
make tb_integration # Test de integración CPU + Vault
make tb_tea         # Test de cifrado TEA completo
make tb_top         # Test del sistema completo
```

### Visualizar formas de onda

```bash
make wave_dmem      # GTKWave de memoria de datos
make wave_vault     # GTKWave de bóveda de llaves
make wave_auth      # GTKWave de autenticación
make wave_ctrl      # GTKWave de unidad de control
make wave_decode    # GTKWave de decodificador
make wave_fetch     # GTKWave de fetch
make wave_int       # GTKWave de integración
```

### Clean

```bash
make clean          # Elimina binarios, .vcd y archivos generados
```

---

## Tools

### Carga de Archivos (`load_file.py`)

Permite cargar archivos arbitrarios (texto, imágenes, binarios) en la memoria RAM del simulador:

```bash
python3 load_file.py archivo.txt
```

Genera un archivo `.mem`.

### Extractor de Datos (`extract_data.py`)

Extrae secciones de datos desde archivos para cifrado:

```bash
python3 extract_data.py entrada.bin --start 0 --length 1024
```

### Ensamblador (`tools/asm.py`)

Convierte código assembly de la ISA a machine code:

```bash
python3 tools/asm.py tea_full.asm -o program.mem
```

---

## Documentación

*-* La documentación de la ISA se encuentra en [docs/isa.md](docs/isa.md), que muestra el instruction reference sheet:

- **Formatos de instrucción**: R, I, M, J, K (Vault), T (TEA)
- **Tabla de referencias**: Todos los opcodes y operaciones
- **Ejemplos de uso**: Código assembly para operaciones comunes
- **Casos de uso**: Cifrado TEA, manejo de bóveda, autenticación

*-* En [docs/microarchitecture.md](docs/microarchitecture.md) se presenta el diagrama de bloques y organización interna.
*-* En [docs/simulation.md](docs/simulation.md) se presenta la descripción del modelado de la simulación.

---

## Testing

1. **Tests unitarios**: Se puede probar cada módulo por medio de un testbench especifico (`tb_*.sv`)
2. **Tests de integración**: Verificación de interacción entre módulos.
3. **Simulación completa**: Test del sistema completo en top.

- En todos los testbenches se generan archivos `.vcd` para análisis de las señales en GTKWave.

---

