`timescale 1ns / 1ps

module datapath (
    input  logic        clk,
    input  logic        reset,

    // Control signals from Control Unit
    input  logic        reg_write,
    input  logic [3:0]  alu_op,
    input  logic        alu_src_b,   // 0: register, 1: immediate
    input  logic        mem_to_reg,  // 0: ALU result, 1: memory data (for LD)

    // Register addresses (from Instruction Decoder)
    input  logic [3:0]  rs1_addr,
    input  logic [3:0]  rs2_addr,
    input  logic [3:0]  rs3_addr,
    input  logic [3:0]  rd_addr,

    // Data from outside
    input  logic [31:0] immediate,
    input  logic [31:0] mem_data_in, // From Data Memory (WB mux)

    // Auth / exception from external units
    input  logic        auth_status_in, // From auth_unit
    input  logic        vault_exc_in,   // From key_vault

    // Outputs
    output logic [31:0] alu_result,
    output logic [31:0] reg_data_1,  // rs1 data — needed by auth_unit (VAUTH)
    output logic [31:0] reg_data_2,  // rs2 data — needed by data_mem (ST)
    output logic        alu_zero,    // Direct combinatorial zero flag — for BEQ
    output logic [5:0]  status_flags
);

    // Internal signals
    logic [31:0] rs1_data, rs2_data, rs3_data;
    logic [31:0] alu_operand_b;
    logic [31:0] write_data_rf;  // WB mux output
    logic [5:0]  alu_flags;
    logic        illegal_op;
    logic        exc_combined;

    assign exc_combined = illegal_op | vault_exc_in;

    // --- Write-back MUX: ALU result OR memory load data ---
    assign write_data_rf = mem_to_reg ? mem_data_in : alu_result;

    // --- Register File ---
    register_file rf (
        .clk(clk),
        .reset(reset),
        .we(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs3_addr(rs3_addr),
        .rd_addr(rd_addr),
        .write_data(write_data_rf),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data)
    );

    // Operand selection MUX for ALU input B
    assign alu_operand_b = alu_src_b ? immediate : rs2_data;

    // --- ALU ---
    alu main_alu (
        .a(rs1_data),
        .b(alu_operand_b),
        .c(rs3_data),
        .alu_op(alu_op),
        .auth_in(auth_status_in),
        .result(alu_result),
        .flags(alu_flags),
        .illegal_op(illegal_op)
    );

    // Direct combinatorial zero flag for branch decisions (BEQ/BEQADD)
    assign alu_zero = alu_flags[0];

    // --- Status Register ---
    // AUTH flag tracks auth_unit.auth_status; EXC tracks illegal ops + vault errors
    status_reg sr (
        .clk(clk),
        .reset(reset),
        .we(1'b1),              // Always capture ALU flags
        .alu_flags(alu_flags),
        .auth_in(auth_status_in),
        .exc_in(exc_combined),
        .set_auth(1'b1),        // Keep AUTH flag in sync with auth_unit
        .set_exc(exc_combined),
        .current_flags(status_flags)
    );

    assign reg_data_1 = rs1_data;
    assign reg_data_2 = rs2_data;

endmodule
