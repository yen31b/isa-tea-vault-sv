// TEA Decryption: Custom Version (XORTEA, ADDK, BEQADD)
// Optimized: Single VAUTH session, no unnecessary NOPs
// r0=v0, r1=v1, r2=sum, r3=i, r8=delta, r12=31
// r9, r10, r11: temporals

// --- 1. Autenticacion ---
MOV r0, 0xA5A5
SLLI r0, r0, 16
MOV r10, 0xA5A5
OR r0, r0, r10 
VAUTH r0
NOP

// --- 2. Carga de Llaves en Boveda y k_regs ---
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

// --- 3. Inicializacion de Datos (sesion sigue activa, se refresca con ADDK/XORTEA) ---
MOV r10, 0x200
LD r0, r10, 0 
LD r1, r10, 4
MOV r8, 0x9E37
SLLI r8, r8, 16
MOV r10, 0x79B9
OR r8, r8, r10
// sum = delta * 32 = 0xC6EF3720
MOV r2, 0xC6EF
SLLI r2, r2, 16
MOV r10, 0x3720
OR r2, r2, r10
MOV r3, 0 // i = 0
MOV r12, 31 // limit

// --- 4. Bucle de Descifrado ---
// loop_dec
SLLI r9, r0, 4
ADDK r9, r9, 2 
ADD r10, r0, r2
SRLI r11, r0, 5
ADDK r11, r11, 3 
XORTEA r9, r9, r10, r11
SUB r1, r1, r9
SLLI r9, r1, 4
ADDK r9, r9, 0 
ADD r10, r1, r2
SRLI r11, r1, 5
ADDK r11, r11, 1 
XORTEA r9, r9, r10, r11
SUB r0, r0, r9
SUB r2, r2, r8
BEQADD r3, r12, 8
JMP -64 // loop_dec (16 instructions * 4)

// --- 5. Cerrar sesion y guardar resultado ---
VLOGOUT
MOV r10, 0x300
ST r0, r10, 0
ST r1, r10, 4
NOP
