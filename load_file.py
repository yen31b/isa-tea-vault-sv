#!/usr/bin/env python3
# Herramienta para cargar un archivo a formato .mem de Verilog
# Uso: python load_file.py --input archivo.txt --output memory.mem --address 0x1000

import argparse
import os
import sys

def detect_type(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    types = {
        '.txt': 'texto', '.png': 'imagen PNG', '.jpg': 'imagen JPEG',
        '.jpeg': 'imagen JPEG', '.bmp': 'imagen BMP', '.bin': 'binario',
        '.pdf': 'PDF', '.c': 'codigo C', '.py': 'codigo Python'
    }
    return types.get(ext, 'desconocido')

def load_file(input_path, output_path, address):
    # leer el archivo como bytes
    with open(input_path, 'rb') as f:
        data = f.read()

    size = len(data)
    addr = int(address, 0)
    end  = addr + size - 1

    # verificar que cabe en la RAM (64KB)
    if addr + size > 65536:
        print("Error: el archivo no cabe en la RAM desde esa direccion")
        sys.exit(1)

    # escribir el archivo .mem
    with open(output_path, 'w') as f:
        f.write(f"// Archivo: {os.path.basename(input_path)}\n")
        f.write(f"// Tipo: {detect_type(input_path)}\n")
        f.write(f"// Tamano: {size} bytes\n")
        f.write(f"// Rango: 0x{addr:08X} - 0x{end:08X}\n")
        f.write(f"\n")
        f.write(f"@{addr:08X}\n")
        for byte in data:
            f.write(f"{byte:02X}\n")

    print(f"Archivo cargado:")
    print(f"  Entrada:   {input_path} ({detect_type(input_path)})")
    print(f"  Tamano:    {size} bytes")
    print(f"  Salida:    {output_path}")
    print(f"  Inicio:    0x{addr:08X}")
    print(f"  Fin:       0x{end:08X}")

parser = argparse.ArgumentParser(description='Carga un archivo a formato .mem de Verilog')
parser.add_argument('--input',   required=True, help='Archivo de entrada')
parser.add_argument('--output',  required=True, help='Archivo .mem de salida')
parser.add_argument('--address', required=True, help='Direccion inicial (ej: 0x1000)')
args = parser.parse_args()

if not os.path.isfile(args.input):
    print(f"Error: no se encontro el archivo '{args.input}'")
    sys.exit(1)

load_file(args.input, args.output, args.address)
