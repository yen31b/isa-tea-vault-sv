`timescale 1ns / 1ps

module datapath (
    input  logic        clk,
    input  logic        reset,
    
    // Control signals from Control Unit
    input  logic        reg_write,
    input  logic [3:0]  alu_op,
    input  logic        alu_src_b,   // 0: register, 1: immediate
    input  logic        alu_src_c,   // For xortea
    
    // Register addresses (from Instruction Decoder)
    input  logic [2:0]  rs1_addr,
    input  logic [2:0]  rs2_addr,
    input  logic [2:0]  rs3_addr,
    input  logic [2:0]  rd_addr,
    
    // Data from outside
    input  logic [31:0] immediate,
    input  logic [31:0] mem_data_in, // From Data Memory
    
    // Outputs to outside
    output logic [31:0] alu_result,
    output logic [31:0] reg_data_2,  // For Store operations
    output logic [5:0]  status_flags
);

    // Internal signals
    logic [31:0] rs1_data, rs2_data, rs3_data;
    logic [31:0] alu_operand_b, alu_operand_c;
    logic [5:0]  alu_flags;

    // --- Register File ---
    register_file rf (
        .clk(clk),
        .reset(reset),
        .we(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs3_addr(rs3_addr),
        .rd_addr(rd_addr),
        .write_data(alu_result), // Placeholder: in real CPU, data might come from mem or ALU
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data)
    );

    // Operand selection MUXes
    assign alu_operand_b = alu_src_b ? immediate : rs2_data;
    assign alu_operand_c = rs3_data; // Simple connection for now

    // --- ALU ---
    alu main_alu (
        .a(rs1_data),
        .b(alu_operand_b),
        .c(alu_operand_c),
        .alu_op(alu_op),
        .result(alu_result),
        .flags(alu_flags)
    );

    // --- Status Register ---
    status_reg sr (
        .clk(clk),
        .reset(reset),
        .we(1'b1), // Update on every cycle for now (simplification)
        .alu_flags(alu_flags),
        .auth_in(1'b0), // From Security Unit (external)
        .exc_in(1'b0),  // From Security Unit (external)
        .set_auth(1'b0),
        .set_exc(1'b0),
        .current_flags(status_flags)
    );

    assign reg_data_2 = rs2_data;

endmodule
