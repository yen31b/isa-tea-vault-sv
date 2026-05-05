#!/usr/bin/env python3
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
    with open(input_path, 'rb') as f:
        data = bytearray(f.read())

    original_size = len(data)
    
    # --- PARCHE DE PADDING (8 bytes para TEA) ---
    padding = (8 - (len(data) % 8)) % 8
    if padding > 0:
        data.extend(b'\x00' * padding)
    
    size = len(data) # Tamaño ajustado
    addr = int(address, 0)
    end  = addr + size # Usamos el fin exclusivo para la comparacion

    if addr + size > 65536:
        print("Error: el archivo no cabe en la RAM")
        sys.exit(1)

    if addr < 0x0100:
        print("Error: Direccion reservada para metadatos (< 0x0100)")
        sys.exit(1)

    with open(output_path, 'w') as f:
        f.write(f"// Archivo: {os.path.basename(input_path)}\n")
        f.write(f"// Tamano Original: {original_size} bytes\n")
        f.write(f"// Tamano Padded: {size} bytes\n")
        
        # Metadata
        f.write("@000000F8\n")
        f.write(f"{(addr >> 0) & 0xFF:02X}\n")
        f.write(f"{(addr >> 8) & 0xFF:02X}\n")
        f.write(f"{(addr >> 16) & 0xFF:02X}\n")
        f.write(f"{(addr >> 24) & 0xFF:02X}\n")
        
        f.write("@000000FC\n")
        f.write(f"{(size >> 0) & 0xFF:02X}\n")
        f.write(f"{(size >> 8) & 0xFF:02X}\n")
        f.write(f"{(size >> 16) & 0xFF:02X}\n")
        f.write(f"{(size >> 24) & 0xFF:02X}\n")

        # Data
        f.write(f"\n@{addr:08X}\n")
        for byte in data:
            f.write(f"{byte:02X}\n")

    print(f"Archivo cargado exitosamente:")
    print(f"  Tamano original: {original_size} bytes")
    print(f"  Tamano ajustado: {size} bytes (con padding)")
    print(f"  Direccion:       0x{addr:04X}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--address', required=True)
    args = parser.parse_args()
    load_file(args.input, args.output, args.address)
