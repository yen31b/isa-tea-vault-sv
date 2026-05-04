# TEA (Tiny Encryption Algorithm) - RISC-V Assembly
# Cifrado y descifrado de un bloque de 64 bits con llave de 128 bits
# 32 rondas, DELTA = 0x9e3779b9
#
# Convención de registros usada:
#   a0 = puntero a v[2]  (bloque a cifrar/descifrar)
#   a1 = puntero a key[4] (llave de 128 bits)
#
# Registros internos:
#   t0 = v0
#   t1 = v1
#   t2 = sum
#   t3 = contador i (0..31)
#   t4 = temporal para subexpresiones
#   t5 = temporal para subexpresiones
#   t6 = DELTA = 0x9e3779b9
#   s0 = key[0]
#   s1 = key[1]
#   s2 = key[2]
#   s3 = key[3]

    .section .data
# Bloque de entrada: v[0]=0x01234567, v[1]=0x89ABCDEF
v:      .word 0x01234567, 0x89ABCDEF

# Llave de 128 bits: key[0..3]
key:    .word 0xA56BABCD, 0x00000000, 0xFFFFFFFF, 0x13579BDF

# Etiquetas para mensajes
msg_orig:       .string "\n=== TEA Demo ===\nOriginal:    v0=0x"
msg_mid:        .string "  v1=0x"
msg_enc:        .string "\nCifrado:     v0=0x"
msg_dec:        .string "\nDescifrado:  v0=0x"
msg_newline:    .string "\n"

    .section .bss
    .align 4
stack_space:
    .skip 4096           # 4KB stack space

    .section .text
    .globl _start

# ─────────────────────────────────────────────
# _start: punto de entrada, orquesta el demo
# ─────────────────────────────────────────────
_start:
    # Inicializar stack pointer
    la   sp, stack_space + 4096   # sp al final del stack

    # Imprimir valores originales
    la   a0, msg_orig
    call print_str

    la   a0, v
    lw   a0, 0(a0)
    call print_hex

    la   a0, msg_mid
    call print_str

    la   a0, v
    lw   a0, 4(a0)
    call print_hex

    # ── Cifrar ──
    la   a0, v
    la   a1, key
    call tea_encrypt

    # Imprimir cifrado
    la   a0, msg_enc
    call print_str

    la   a0, v
    lw   a0, 0(a0)
    call print_hex

    la   a0, msg_mid
    call print_str

    la   a0, v
    lw   a0, 4(a0)
    call print_hex

    # ── Descifrar ──
    la   a0, v
    la   a1, key
    call tea_decrypt

    # Imprimir descifrado
    la   a0, msg_dec
    call print_str

    la   a0, v
    lw   a0, 0(a0)
    call print_hex

    la   a0, msg_mid
    call print_str

    la   a0, v
    lw   a0, 4(a0)
    call print_hex

    la   a0, msg_newline
    call print_str

    # Salir
    li   a7, 93          # syscall exit
    li   a0, 0
    ecall

# ─────────────────────────────────────────────
# tea_encrypt(a0=*v, a1=*key)
# ─────────────────────────────────────────────
tea_encrypt:
    addi sp, sp, -48
    sw   ra,  44(sp)
    sw   s0,  40(sp)
    sw   s1,  36(sp)
    sw   s2,  32(sp)
    sw   s3,  28(sp)

    # Cargar v0, v1
    lw   t0, 0(a0)       # t0 = v0
    lw   t1, 4(a0)       # t1 = v1

    # Cargar key[0..3]
    lw   s0, 0(a1)       # s0 = key[0]
    lw   s1, 4(a1)       # s1 = key[1]
    lw   s2, 8(a1)       # s2 = key[2]
    lw   s3, 12(a1)      # s3 = key[3]

    # sum = 0, i = 0, DELTA
    li   t2, 0                   # sum = 0
    li   t3, 0                   # i = 0
    li   t6, 0x9e3779b9          # DELTA (nota: li maneja el signo en RV32)

enc_loop:
    # if i >= 32 -> salir
    li   t4, 32
    bge  t3, t4, enc_done

    # sum += DELTA
    add  t2, t2, t6

    # v0 += ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1])
    slli t4, t1, 4       # v1 << 4
    add  t4, t4, s0      # + key[0]

    add  t5, t1, t2      # v1 + sum

    srli t4, t1, 5       # reutilizo t4: v1 >> 5  (temporal)
    # Necesito tres valores: guardo el XOR parcial en t4
    # Recalculo paso a paso:
    slli t4, t1, 4
    add  t4, t4, s0      # A = (v1<<4) + key[0]

    add  t5, t1, t2      # B = v1 + sum
    xor  t4, t4, t5      # A ^ B

    srli t5, t1, 5
    add  t5, t5, s1      # C = (v1>>5) + key[1]
    xor  t4, t4, t5      # A ^ B ^ C

    add  t0, t0, t4      # v0 += resultado

    # v1 += ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3])
    slli t4, t0, 4
    add  t4, t4, s2      # A = (v0<<4) + key[2]

    add  t5, t0, t2      # B = v0 + sum
    xor  t4, t4, t5      # A ^ B

    srli t5, t0, 5
    add  t5, t5, s3      # C = (v0>>5) + key[3]
    xor  t4, t4, t5      # A ^ B ^ C

    add  t1, t1, t4      # v1 += resultado

    addi t3, t3, 1       # i++
    j    enc_loop

enc_done:
    # Guardar v0, v1 de vuelta
    sw   t0, 0(a0)
    sw   t1, 4(a0)

    lw   ra,  44(sp)
    lw   s0,  40(sp)
    lw   s1,  36(sp)
    lw   s2,  32(sp)
    lw   s3,  28(sp)
    addi sp, sp, 48
    ret

# ─────────────────────────────────────────────
# tea_decrypt(a0=*v, a1=*key)
# ─────────────────────────────────────────────
tea_decrypt:
    addi sp, sp, -48
    sw   ra,  44(sp)
    sw   s0,  40(sp)
    sw   s1,  36(sp)
    sw   s2,  32(sp)
    sw   s3,  28(sp)

    lw   t0, 0(a0)
    lw   t1, 4(a0)

    lw   s0, 0(a1)
    lw   s1, 4(a1)
    lw   s2, 8(a1)
    lw   s3, 12(a1)

    # sum = DELTA * 32 = 0x9e3779b9 * 32
    # En 32 bits: 0x9e3779b9 * 32 = 0xC6EF3720  (con overflow intencional)
    li   t2, 0xC6EF3720          # sum inicial para descifrado
    li   t3, 0                   # i = 0
    li   t6, 0x9e3779b9          # DELTA

dec_loop:
    li   t4, 32
    bge  t3, t4, dec_done

    # v1 -= ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3])
    slli t4, t0, 4
    add  t4, t4, s2

    add  t5, t0, t2
    xor  t4, t4, t5

    srli t5, t0, 5
    add  t5, t5, s3
    xor  t4, t4, t5

    sub  t1, t1, t4      # v1 -= resultado

    # v0 -= ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1])
    slli t4, t1, 4
    add  t4, t4, s0

    add  t5, t1, t2
    xor  t4, t4, t5

    srli t5, t1, 5
    add  t5, t5, s1
    xor  t4, t4, t5

    sub  t0, t0, t4      # v0 -= resultado

    # sum -= DELTA
    sub  t2, t2, t6

    addi t3, t3, 1
    j    dec_loop

dec_done:
    sw   t0, 0(a0)
    sw   t1, 4(a0)

    lw   ra,  44(sp)
    lw   s0,  40(sp)
    lw   s1,  36(sp)
    lw   s2,  32(sp)
    lw   s3,  28(sp)
    addi sp, sp, 48
    ret

# ─────────────────────────────────────────────
# print_hex: imprime a0 como 8 dígitos hex
# ─────────────────────────────────────────────
print_hex:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s0, 24(sp)
    sw   s1, 20(sp)

    mv   s0, a0          # guardar valor a imprimir
    li   s1, 28          # s1 = shift (28..0, paso -4)

hex_loop:
    # Extraer nibble: (valor >> shift) & 0xF
    srl  t4, s0, s1
    andi t4, t4, 0xF

    # Convertir a ASCII
    li   t5, 10
    blt  t4, t5, hex_digit
    addi t4, t4, 55      # 'A'-10 = 55  →  A=65, B=66...
    j    hex_print
hex_digit:
    addi t4, t4, 48      # '0' = 48

hex_print:
    # write(1, &char, 1)
    addi sp, sp, -8
    sb   t4, 0(sp)       # guardar byte en stack (sb no sw, es 1 byte)
    mv   a1, sp
    li   a2, 1
    li   a0, 1
    li   a7, 64
    ecall
    addi sp, sp, 8

    # Siguiente nibble o terminar
    addi s1, s1, -4
    bge  s1, zero, hex_loop   # mientras shift >= 0, continuar
    # shift llegó a -4: todos los nibbles impresos

hex_done:
    lw   ra, 28(sp)
    lw   s0, 24(sp)
    lw   s1, 20(sp)
    addi sp, sp, 32
    ret

# ─────────────────────────────────────────────
# print_str: imprime string en a0 (null-terminated)
# ─────────────────────────────────────────────
print_str:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s0,  8(sp)

    mv   s0, a0
    # calcular longitud
    mv   t0, a0
str_len:
    lb   t1, 0(t0)
    beqz t1, str_len_done
    addi t0, t0, 1
    j    str_len
str_len_done:
    sub  a2, t0, s0      # longitud

    mv   a1, s0
    li   a0, 1           # stdout
    li   a7, 64          # syscall write
    ecall

    lw   ra, 12(sp)
    lw   s0,  8(sp)
    addi sp, sp, 16
    ret
    