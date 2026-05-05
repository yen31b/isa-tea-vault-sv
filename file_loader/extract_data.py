#!/usr/bin/env python3
# Herramienta para extraer datos de un volcado de memoria .mem
# Uso: python extract_data.py --memory memory_dump.txt --address 0x2000 --size 4096 --output resultado.bin

import argparse
import os
import sys

def parse_mem(mem_path):
    # leer el archivo .mem y guardar los bytes en un diccionario {direccion: byte}
    memory = {}
    current_addr = 0

    with open(mem_path, 'r') as f:
        for line in f:
            # quitar comentarios
            if '//' in line:
                line = line[:line.index('//')]
            line = line.strip()
            if not line:
                continue

            # direccion con @
            if line.startswith('@'):
                current_addr = int(line[1:], 16)
                continue

            # bytes en hex
            for token in line.split():
                try:
                    memory[current_addr] = int(token, 16) & 0xFF
                except ValueError:
                    # Manejar valores 'xx' o indeterminados del simulador
                    memory[current_addr] = 0x00
                current_addr += 1

    return memory

def extract_data(mem_path, address, size, output_path):
    addr = int(address, 0)
    sz   = int(size, 0)

    print(f"Leyendo: {mem_path}")
    memory = parse_mem(mem_path)

    # extraer bytes del rango pedido
    data = bytearray()
    sin_datos = 0
    for i in range(sz):
        a = addr + i
        if a in memory:
            data.append(memory[a])
        else:
            data.append(0x00)
            sin_datos += 1

    with open(output_path, 'wb') as f:
        f.write(data)

    print(f"Extraccion completada:")
    print(f"  Inicio:  0x{addr:08X}")
    print(f"  Fin:     0x{addr + sz - 1:08X}")
    print(f"  Tamano:  {sz} bytes")
    print(f"  Salida:  {output_path}")
    if sin_datos > 0:
        print(f"  Advertencia: {sin_datos} bytes no inicializados (se rellenaron con 0x00)")

parser = argparse.ArgumentParser(description='Extrae datos de un volcado de memoria .mem')
parser.add_argument('--memory',  required=True, help='Archivo .mem de entrada')
parser.add_argument('--address', required=True, help='Direccion de inicio (ej: 0x2000)')
parser.add_argument('--size',    required=True, help='Cantidad de bytes a extraer')
parser.add_argument('--output',  required=True, help='Archivo de salida')
args = parser.parse_args()

if not os.path.isfile(args.memory):
    print(f"Error: no se encontro el archivo '{args.memory}'")
    sys.exit(1)

extract_data(args.memory, args.address, args.size, args.output)
