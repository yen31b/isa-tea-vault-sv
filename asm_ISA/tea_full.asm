// TEA Full Verification: Encrypt and then Decrypt
// r0=v0, r1=v1, r2=sum, r3=i, r8=delta, r12=32
// r9, r10, r11: temporals

// --- 1. Autenticacion ---
MOV r0, 0xA5A5
SLLI r0, r0, 16
MOV r10, 0xA5A5
OR r0, r0, r10 
VAUTH r0
NOP

// --- 2. Carga de Llaves en Boveda ---
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

// --- 3. Carga k_regs desde Boveda ---
VLD 0, 0, r0
VLD 0, 1, r0
VLD 0, 2, r0
VLD 0, 3, r0

// --- 4. Inicializacion de Datos ---
MOV r10, 0x100
LD r0, r10, 0 
LD r1, r10, 4

MOV r8, 0x9E37
SLLI r8, r8, 16
MOV r10, 0x79B9
OR r8, r8, r10

MOV r2, 0 // sum = 0
MOV r3, 0 // i = 0
MOV r12, 32 // limit

// --- 5. Bucle de Encriptacion ---
// loop_enc: (PC = 164)
ADD r2, r2, r8
SLLI r9, r1, 4
ADDK r9, r9, 0 
ADD r10, r1, r2
SRLI r11, r1, 5
ADDK r11, r11, 1 
XORTEA r9, r9, r10, r11
ADD r0, r0, r9
SLLI r9, r0, 4
ADDK r9, r9, 2 
ADD r10, r0, r2
SRLI r11, r0, 5
ADDK r11, r11, 3 
XORTEA r9, r9, r10, r11
ADD r1, r1, r9
MOV r10, 1
ADD r3, r3, r10
CMP r3, r12
BEQ r3, r12, 8 
JMP -76 // loop_enc

// Guardar resultado cifrado temporal (opcional)
MOV r10, 0x200
ST r0, r10, 0
ST r1, r10, 4

// --- 6. Inicializacion para Descifrado ---
// sum = delta * 32 = 0xC6EF3720
MOV r2, 0xC6EF
SLLI r2, r2, 16
MOV r10, 0x3720
OR r2, r2, r10
MOV r3, 0 // i = 0

// --- 7. Bucle de Descifrado ---
// loop_dec: (PC = 276)
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
SUB r2, r2, r8 // sum -= delta
MOV r10, 1
ADD r3, r3, r10
CMP r3, r12
BEQ r3, r12, 8 
JMP -76 // loop_dec

// --- 8. Guardar Resultado Final ---
MOV r10, 0x300
ST r0, r10, 0
ST r1, r10, 4
NOP
