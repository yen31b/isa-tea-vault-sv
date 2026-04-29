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
    logic        illegal_op;
    logic        current_auth;

    assign current_auth = status_flags[4]; // AUTH flag from status register

    // --- Register File ---
    register_file rf (
        .clk(clk),
        .reset(reset),
        .we(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs3_addr(rs3_addr),
        .rd_addr(rd_addr),
        .write_data(alu_result), 
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data)
    );

    // Operand selection MUXes
    assign alu_operand_b = alu_src_b ? immediate : rs2_data;
    assign alu_operand_c = rs3_data; 

    // --- ALU ---
    alu main_alu (
        .a(rs1_data),
        .b(alu_operand_b),
        .c(alu_operand_c),
        .alu_op(alu_op),
        .auth_in(current_auth),
        .result(alu_result),
        .flags(alu_flags),
        .illegal_op(illegal_op)
    );

    // --- Status Register ---
    status_reg sr (
        .clk(clk),
        .reset(reset),
        .we(1'b1), // Update arithmetic flags
        .alu_flags(alu_flags),
        .auth_in(1'b0), // From Security Unit (external)
        .exc_in(illegal_op),  // Trigger exception if op is illegal
        .set_auth(1'b0),
        .set_exc(illegal_op),
        .current_flags(status_flags)
    );

    assign reg_data_2 = rs2_data;

endmodule
