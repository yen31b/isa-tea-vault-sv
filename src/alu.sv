`timescale 1ns / 1ps

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,      
    input  logic [3:0]  alu_op, 
    input  logic        auth_in,    // Authentication bit from status register
    
    // TEA / Vault extensions
    input  logic [31:0] k0, k1, k2, k3,
    input  logic [1:0]  imm_idx,    // Seleccionador de llave (bits del inmediato)

    output logic [31:0] result,
    output logic [5:0]  flags,
    output logic        illegal_op  // High if a privileged op is attempted without AUTH
);

    logic z, n, carry, v;
    // Sign bits for overflow/flag calculation
    logic a_sign, b_sign, res_sign;
    assign a_sign = a[31];
    assign b_sign = b[31];
    assign res_sign = result[31];

    // Cantidad de desplazamiento (evita 'constant select in always_*' de iverilog)
    logic [4:0] shamt;
    assign shamt = b[4:0];

    // ALU Operation Codes
    localparam ALU_ADD    = 4'd0;
    localparam ALU_SUB    = 4'd1;
    localparam ALU_OR     = 4'd2;
    localparam ALU_XOR    = 4'd3;
    localparam ALU_SRL    = 4'd4;
    localparam ALU_SLL    = 4'd5;
    localparam ALU_MUL    = 4'd6;
    localparam ALU_MOV    = 4'd7;
    localparam ALU_AND    = 4'd8;
    localparam ALU_XORTEA = 4'd10;
    localparam ALU_BEQADD = 4'd11;
    localparam ALU_ADDK   = 4'd12;
    localparam ALU_SUBK   = 4'd13;

    // Selector de llave segura
    logic [31:0] selected_key;
    always_comb begin
        case (imm_idx)
            2'd0: selected_key = k0;
            2'd1: selected_key = k1;
            2'd2: selected_key = k2;
            2'd3: selected_key = k3;
            default: selected_key = 32'b0;
        endcase
    end

    always_comb begin
        result = 32'b0;
        carry = 1'b0;
        v = 1'b0; 
        illegal_op = 1'b0;

        case (alu_op)
            ALU_ADD: begin 
                {carry, result} = a + b;
                v = (a_sign == b_sign) && (res_sign != a_sign);
            end
            ALU_SUB: begin 
                {carry, result} = a - b;
                v = (a_sign != b_sign) && (res_sign != a_sign);
            end
            ALU_OR:     result = a | b;
            ALU_XOR:    result = a ^ b;
            ALU_SRL:    result = a >> shamt;
            ALU_SLL:    result = a << shamt;

            ALU_MUL:    result = a * b;
            ALU_MOV:    result = b;
            ALU_AND:    result = a & b;
            
            ALU_XORTEA: begin // Triple XOR (Privileged)
                if (auth_in) begin
                    result = a ^ b ^ c;
                end else begin
                    result = 32'b0;
                    illegal_op = 1'b1;
                end
            end
            
            ALU_BEQADD: begin // Increment index (Privileged)
                if (auth_in) begin
                    result = a + 1; // Incrementa el registro rs1
                end else begin
                    result = 32'b0;
                    illegal_op = 1'b1;
                end
            end

            ALU_ADDK: begin // Add with Vault Key (Privileged)
                if (auth_in) begin
                    result = a + selected_key;
                end else begin
                    result = 32'b0;
                    illegal_op = 1'b1;
                end
            end

            ALU_SUBK: begin // Sub with Vault Key (Privileged)
                if (auth_in) begin
                    result = a - selected_key;
                end else begin
                    result = 32'b0;
                    illegal_op = 1'b1;
                end
            end

            default: result = 32'b0;
        endcase
    end

    assign z = (alu_op == ALU_BEQADD) ? (a == b) : (result == 32'b0);
    assign n = res_sign;
    
    assign flags = {2'b0, v, carry, n, z};

endmodule
