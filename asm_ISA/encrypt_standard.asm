// TEA Encryption: Standard Version (No XORTEA, ADDK, BEQADD)
// r0=v0, r1=v1, r2=sum, r3=i, r4-r7=k0-k3, r8=delta, r12=32
// r9, r10, r11: temporals

// --- 1. Autenticacion (Setup consistency) ---
MOV r0, 0xA5A5
SLLI r0, r0, 16
MOV r10, 0xA5A5
OR r0, r0, r10 
VAUTH r0
NOP

// --- 2. Carga de Llaves en Registros Estándar ---
MOV r4, 0x0011
SLLI r4, r4, 16
MOV r10, 0x2233
OR r4, r4, r10

MOV r5, 0x4455
SLLI r5, r5, 16
MOV r10, 0x6677
OR r5, r5, r10

MOV r6, 0x8899
SLLI r6, r6, 16
MOV r10, 0xAABB
OR r6, r6, r10

MOV r7, 0xCCDD
SLLI r7, r7, 16
MOV r10, 0xEEFF
OR r7, r7, r10

// --- 3. Inicializacion de Datos ---
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

// --- 4. Bucle de Encriptacion ---
// loop_enc
ADD r2, r2, r8
SLLI r9, r1, 4
ADD r9, r9, r4 // + k0
ADD r10, r1, r2
SRLI r11, r1, 5
ADD r11, r11, r5 // + k1
XOR r9, r9, r10
XOR r9, r9, r11
ADD r0, r0, r9

SLLI r9, r0, 4
ADD r9, r9, r6 // + k2
ADD r10, r0, r2
SRLI r11, r0, 5
ADD r11, r11, r7 // + k3
XOR r9, r9, r10
XOR r9, r9, r11
ADD r1, r1, r9

MOV r10, 1
ADD r3, r3, r10
CMP r3, r12
BEQ r3, r12, 8 
JMP -88 // loop_enc (22 instructions * 4)

// --- 5. Guardar Resultado ---
MOV r10, 0x200
ST r0, r10, 0
ST r1, r10, 4
NOP
