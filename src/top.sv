// top.sv — Integración completa del procesador ISA RISC + Bóveda de llaves
//
// Pipeline conceptual de 5 etapas (implementación single-cycle):
//   IF  → instruction_fetch
//   ID  → instruction_decode + control_unit
//   EX  → datapath (register_file + alu)
//   MEM → data_mem  |  key_vault  |  auth_unit
//   WB  → write-back mux dentro de datapath (mem_to_reg)
//
// Correcciones de señales aplicadas aquí:
//   1. Direcciones de registros: instruction_decode produce 4-bit (16 registros)
//   2. Inmediato de 21-bit → 32-bit: sign-extension
//   3. Branch/jump target = PC + sign_ext(imm)
//   4. zero_flag viene directo de la ALU (combinatorial) para decisiones BEQ/BEQADD
//   5. auth_unit.auth_status → datapath (status_reg AUTH flag) y control_unit
//   6. vault_exc → datapath (status_reg EXC flag)
//   7. WB mux: mem_to_reg selecciona entre resultado ALU y dato de memoria

`timescale 1ns / 1ps

module top #(
    parameter INSTR_MEM_SIZE = 1024,           // Número de instrucciones de 32 bits
    parameter PROGRAM_FILE   = "program.mem",  // Archivo de instrucciones (IF)
    parameter DATA_MEM_SIZE  = 65536,          // 64 KB RAM de datos
    parameter AUTH_SECRET    = 32'hA5A5A5A5,  // Contraseña interna para VAUTH
    parameter AUTH_TIMEOUT   = 8'd64          // Ciclos de validez de la sesión
)(
    input  logic clk,
    input  logic reset,

    // Salidas de observabilidad / debug
    output logic [31:0] pc_out,
    output logic [31:0] alu_result_out,
    output logic [5:0]  status_flags_out,
    output logic        auth_status_out,
    output logic        auth_fail_out,
    output logic        access_denied_out,
    output logic        illegal_access_out
);

    // ============================================================
    // Señales internas
    // ============================================================

    // --- IF stage ---
    logic [31:0] pc;
    logic [31:0] instruction;
    logic        branch_taken_to_if;
    logic        jump_to_if;
    logic [31:0] branch_target;
    logic [31:0] jump_target;

    // --- ID stage ---
    logic [4:0]  opcode;
    logic [3:0]  rd_addr, rs1_addr, rs2_addr, rs3_addr; // 4-bit: 16 registros (r0-r15)
    logic [18:0] imm;
    logic [2:0]  format_type;
    logic [2:0]  slot;
    logic [2:0]  palabra;
    logic [16:0] reservado;

    // Inmediato extendido a 32 bits (con signo)
    logic [31:0] imm_ext;

    // --- Control Unit ---
    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        use_imm;
    logic        branch;
    logic        jump;
    logic        branch_taken;
    logic        flags_write;
    logic        vault_write;
    logic        vault_load_secure;
    logic        vault_clear;
    logic        auth_check;
    logic        auth_clear;
    logic        tea_enable;
    logic        index_inc;
    logic        illegal_access;
    logic        privileged_instr;
    logic [3:0]  alu_op;

    // --- Auth Unit ---
    logic        auth_status;
    logic        auth_fail;
    logic        access_denied;
    logic [7:0]  auth_timer;

    // --- Key Vault ---
    logic        vault_exc;
    logic [31:0] k_reg0, k_reg1, k_reg2, k_reg3;

    // --- Datapath ---
    logic [31:0] alu_result;
    logic [31:0] reg_data_1;   // rs1 — para VAUTH y VSTR
    logic [31:0] reg_data_2;   // rs2 — para ST
    logic        alu_zero;     // flag Z combinatorial de la ALU
    logic [5:0]  status_flags;

    // --- Data Memory ---
    logic [31:0] mem_read_data;

    // ============================================================
    // Extensión de signo del inmediato e targets de salto
    // ============================================================

    // Sign-extend inmediato de 19 a 32 bits
    assign imm_ext = {{13{imm[18]}}, imm};

    // Targets de salto: PC-relativo con offset de bytes
    assign branch_target = pc + imm_ext;
    assign jump_target   = pc + imm_ext;

    // Conectar señales de salto hacia la etapa IF
    assign branch_taken_to_if = branch_taken;
    assign jump_to_if          = jump;

    // ============================================================
    // IF — Etapa 1: Instruction Fetch
    // ============================================================
    instruction_fetch #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .PROGRAM_FILE  (PROGRAM_FILE)
    ) if_stage (
        .clk          (clk),
        .reset        (reset),
        .branch_taken (branch_taken_to_if),
        .jump         (jump_to_if),
        .branch_target(branch_target),
        .jump_target  (jump_target),
        .pc           (pc),
        .instruction  (instruction)
    );

    // ============================================================
    // ID — Etapa 2: Instruction Decode
    // ============================================================
    instruction_decode id_stage (
        .instruction(instruction),
        .opcode     (opcode),
        .rd         (rd_addr),
        .rs1        (rs1_addr),
        .rs2        (rs2_addr),
        .rs3        (rs3_addr),
        .imm        (imm),
        .format_type(format_type),
        .slot       (slot),
        .palabra    (palabra),
        .reservado  (reservado)
    );

    // ============================================================
    // ID — Control Unit
    // La zero_flag se conecta directamente desde la ALU (combinatorial)
    // para que BEQ/BEQADD vean el resultado de la resta actual.
    // ============================================================
    control_unit cu (
        .opcode          (opcode),
        .zero_flag       (alu_zero),       // directo de ALU, no del SR
        .auth_status     (auth_status),    // de auth_unit

        .reg_write       (reg_write),
        .mem_read        (mem_read),
        .mem_write       (mem_write),
        .mem_to_reg      (mem_to_reg),
        .use_imm         (use_imm),
        .branch          (branch),
        .jump            (jump),
        .branch_taken    (branch_taken),
        .flags_write     (flags_write),
        .vault_write     (vault_write),
        .vault_load_secure(vault_load_secure),
        .vault_clear     (vault_clear),
        .auth_check      (auth_check),
        .auth_clear      (auth_clear),
        .tea_enable      (tea_enable),
        .index_inc       (index_inc),
        .illegal_access  (illegal_access),
        .privileged_instr(privileged_instr),
        .alu_op          (alu_op)
    );

    // ============================================================
    // Security — Auth Unit (controla acceso a bóveda y TEA)
    // auth_value = reg_data_1 (rs1) — el registro que se pasa en VAUTH rs1
    // ============================================================
    auth_unit #(
        .SECRET     (AUTH_SECRET),
        .AUTH_TIMEOUT(AUTH_TIMEOUT)
    ) auth (
        .clk           (clk),
        .reset         (reset),
        .auth_check    (auth_check),
        .auth_clear    (auth_clear),
        .privileged_instr(privileged_instr),
        .auth_value    (reg_data_1),       // rs1_data del register file
        .auth_status   (auth_status),
        .auth_fail     (auth_fail),
        .access_denied (access_denied),
        .auth_timer    (auth_timer)
    );

    // ============================================================
    // Security — Key Vault
    // slot   → campo [26:24] de la instrucción (K/SEC)
    // word   → campo [23:21] (palabra de la llave dentro del slot)
    // rs1_data → reg_data_1 (dato a escribir en VSTR)
    // ============================================================
    key_vault #(
        .NUM_SLOTS (4),
        .WORDS_PER (4),
        .DATA_WIDTH(32)
    ) vault_inst (
        .clk              (clk),
        .rst              (reset),
        .vault_write      (vault_write),
        .vault_load_secure(vault_load_secure),
        .vault_clear      (vault_clear),
        .auth_status      (auth_status),
        .slot             (slot),
        .word             (palabra),       // índice de palabra dentro del slot
        .rs1_data         (reg_data_1),    // dato fuente para VSTR
        .exc_out          (vault_exc),
        .k_reg0           (k_reg0),
        .k_reg1           (k_reg1),
        .k_reg2           (k_reg2),
        .k_reg3           (k_reg3)
    );

    // ============================================================
    // EX — Etapa 3: Datapath (Register File + ALU + Status Register)
    //
    // Notas de conexión:
    //   rs1_addr en formato K (VSTR/VLD/VCLR/VAUTH): instruction_decode pone rs1
    //     en [20:18] y los expone como rs1_3b → rs1_addr. Correcto.
    //   Para XORTEA: rs1→a, rs2→b, rs3→c en la ALU.
    //   alu_src_b = use_imm: 1 para SRLI/SLLI, 0 para instrucciones R.
    //   mem_to_reg: 1 solo para LD (registro destino recibe dato de memoria).
    // ============================================================
    datapath dp (
        .clk           (clk),
        .reset         (reset),
        .reg_write     (reg_write),
        .alu_op        (alu_op),
        .alu_src_b     (use_imm),
        .mem_to_reg    (mem_to_reg),
        .rs1_addr      (rs1_addr),
        .rs2_addr      (rs2_addr),
        .rs3_addr      (rs3_addr),
        .rd_addr       (rd_addr),
        .immediate     (imm_ext),
        .mem_data_in   (mem_read_data),    // dato leído de RAM → WB mux
        .auth_status_in(auth_status),      // de auth_unit
        .vault_exc_in  (vault_exc),        // de key_vault
        .alu_result    (alu_result),
        .reg_data_1    (reg_data_1),
        .reg_data_2    (reg_data_2),
        .alu_zero      (alu_zero),
        .status_flags  (status_flags)
    );

    // ============================================================
    // MEM — Etapa 4: Data Memory
    //
    // address   = alu_result (base + offset calculado por ALU con ADD)
    // write_data = reg_data_2 (rs2, el registro fuente de ST)
    // read_data  → WB mux en datapath vía mem_data_in
    // ============================================================
    data_mem #(
        .MEM_SIZE  (DATA_MEM_SIZE),
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) dmem (
        .clk       (clk),
        .reset     (reset),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .address   (alu_result),
        .write_data(reg_data_2),
        .read_data (mem_read_data)
    );

    // ============================================================
    // Salidas de debug
    // ============================================================
    assign pc_out           = pc;
    assign alu_result_out   = alu_result;
    assign status_flags_out = status_flags;
    assign auth_status_out  = auth_status;
    assign auth_fail_out    = auth_fail;
    assign access_denied_out= access_denied;
    assign illegal_access_out = illegal_access;

endmodule
