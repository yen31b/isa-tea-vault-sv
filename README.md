# isa-tea-vault-sv

# 🔐 ISA RISC TEA Vault — SystemVerilog

Implementación en SystemVerilog de una arquitectura del set de instrucciones (ISA) tipo RISC con soporte nativo para seguridad informática, desarrollada como Proyecto Grupal I del curso de Arquitectura de Computadores.

---

Este proyecto consiste en el diseño e implementación de un procesador RISC personalizado con extensiones de hardware orientadas a la seguridad de la información. El procesador incluye soporte nativo para:

- **Cifrado de bloques TEA** (*Tiny Encryption Algorithm*) con instrucciones especializadas que aceleran el algoritmo directamente en hardware.
- **Bóveda de llaves criptográficas** (*Key Vault*), una memoria segura de acceso restringido que almacena hasta 4 llaves de 128 bits, inaccesible desde instrucciones de memoria convencionales.

El procesador es simulado con **Icarus Verilog (iverilog)** y las formas de onda son visualizadas con **GTKWave**.

---

## Características Principales

- ISA tipo RISC de instrucciones de 32 bits
- 8 registros de propósito general de 32 bits (`r0`–`r7`)
- Program Counter (PC) y registro de estado
- Memoria RAM de 64 KB mínimo, direccionamiento de 32 bits
- Instrucciones CPU: 
- Instrucciones de Bóveda:
- Instrucciones de cifrado:

---

## 🔐 Seguridad del Diseño


---

## 📁 Estructura del Proyecto

```
risc-tea-vault-sv/
├── README.md
├── Makefile
├── src/
├── tb/
└── docs/

```

---

## Compilación y Simulación

### Requisitos

- [Icarus Verilog](https://steveicarus.github.io/iverilog/) `>= 11.0`
- [GTKWave](http://gtkwave.sourceforge.net/) (opcional, para visualizar formas de onda)
- Python `>= 3.8` (para las herramientas de carga de archivos)


---

## Herramienta de Carga de Archivos

Permite cargar cualquier tipo de archivo (texto, imágenes, binarios) en la memoria RAM del simulador para realizar operaciones de cifrado sobre datos reales.



---

## Documentación

