// TEA Decryption: Dynamic Buffer Version (Fixed Offsets)
// Metadata: [0x00F8] = start_addr, [0x00FC] = size
// Una instrucción por línea (compatible con asm.py)

// --- 1. Autenticacion ---
MOV r0, 0xA5A5
SLLI r0, r0, 16
MOV r10, 0xA5A5
OR r0, r0, r10
VAUTH r0
NOP

// --- 2. Carga de Llaves (mismas que encrypt) ---
MOV r9, 0x0011
SLLI r9, r9, 16
MOV r10, 0x2233
OR r9, r9, r10
VSTR 0, 0, r9

MOV r9, 0x4455
SLLI r9, r9, 16
MOV r10, 0x6677
OR r9, r9, r10
VSTR 0, 1, r9

MOV r9, 0x8899
SLLI r9, r9, 16
MOV r10, 0xAABB
OR r9, r9, r10
VSTR 0, 2, r9

MOV r9, 0xCCDD
SLLI r9, r9, 16
MOV r10, 0xEEFF
OR r9, r9, r10
VSTR 0, 3, r9

VLD 0, 0, r0
VLD 0, 1, r0
VLD 0, 2, r0
VLD 0, 3, r0

// --- 3. Carga de Metadatos ---
MOV r13, 0x00F8
LD r14, r13, 0    // r14 = start_addr
LD r15, r13, 4    // r15 = size
ADD r15, r15, r14 // r15 = end_addr (exclusive)
MOV r10, 0
ADD r10, r10, r14 // r10 = ptr

// --- 4. Constantes TEA ---
MOV r8, 0x9E37
SLLI r8, r8, 16
MOV r9, 0x79B9
OR r8, r8, r9     // r8 = delta = 0x9E3779B9
MOV r12, 31       // limit inner rounds

// ============================================================
// loop_outer: (PC = instrucción 41, byte 164)
// ============================================================
LD r0, r10, 0
LD r1, r10, 4
MOV r2, 0xC6EF              // sum = delta * 32 high
SLLI r2, r2, 16
MOV r9, 0x3720              // sum low
OR r2, r2, r9               // r2 = 0xC6EF3720
MOV r3, 0                   // round counter = 0

// ============================================================
// loop_inner: (PC = instrucción 48, byte 192)
// ============================================================
SLLI r9, r0, 4              // r9 = v0 << 4
ADDK r9, r9, 2              // r9 ^= k[2]
ADD r11, r0, r2             // r11 = v0 + sum
SRLI r13, r0, 5             // r13 = v0 >> 5
ADDK r13, r13, 3            // r13 ^= k[3]
XORTEA r9, r9, r11, r13    // r9 = r9 ^ r11 ^ r13
SUB r1, r1, r9              // v1 -= r9
SLLI r9, r1, 4              // r9 = v1 << 4
ADDK r9, r9, 0              // r9 ^= k[0]
ADD r11, r1, r2             // r11 = v1 + sum
SRLI r13, r1, 5             // r13 = v1 >> 5
ADDK r13, r13, 1            // r13 ^= k[1]
XORTEA r9, r9, r11, r13    // r9 = r9 ^ r11 ^ r13
SUB r0, r0, r9              // v0 -= r9
SUB r2, r2, r8              // sum -= delta
BEQADD r3, r12, 8          // if r3 == r12 skip next, else r3++
JMP -64                     // to loop_inner (16 instrs back = -64 bytes)

// --- 7. Guardar y avanzar ---
ST r0, r10, 0
ST r1, r10, 4
MOV r9, 8
ADD r10, r10, r9
CMP r10, r15
BEQ r10, r15, 8
JMP -120                    // to loop_outer (30 instrs back = -120 bytes)

VLOGOUT
NOP
JMP 0                       // Halt
