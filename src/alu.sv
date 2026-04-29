`timescale 1ns / 1ps

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,      
    input  logic [3:0]  alu_op, 
    input  logic        auth_in,    // Authentication bit from status register
    output logic [31:0] result,
    output logic [5:0]  flags,
    output logic        illegal_op  // High if a privileged op is attempted without AUTH
);

    logic z, n, carry, v;
    // Extraemos los bits de signo fuera para evitar la advertencia de Icarus
    logic a_sign, b_sign, res_sign;
    assign a_sign = a[31];
    assign b_sign = b[31];
    assign res_sign = result[31];
    
    always_comb begin
        result = 32'b0;
        carry = 1'b0;
        v = 1'b0; 
        illegal_op = 1'b0;

        case (alu_op)
            4'b0000: begin // ADD
                {carry, result} = a + b;
                v = (a_sign == b_sign) && (res_sign != a_sign);
            end
            4'b0001: begin // SUB / CMP
                {carry, result} = a - b;
                v = (a_sign != b_sign) && (res_sign != a_sign);
            end
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a >> b[4:0];
            4'b0110: result = a << b[4:0];
            4'b1000: result = a * b;
            4'b1001: result = a;    
            4'b1010: begin // XORTEA (Privileged)
                if (auth_in) begin
                    result = a ^ b ^ c;
                end else begin
                    result = 32'b0;
                    illegal_op = 1'b1;
                end
            end
            4'b1011: begin // BEQADD logic (Privileged)
                if (auth_in) begin
                    result = a + 1;
                end else begin
                    result = 32'b0;
                    illegal_op = 1'b1;
                end
            end
            default: result = 32'b0;
        endcase
    end

    assign z = (alu_op == 4'b1011) ? (a == b) : (result == 32'b0);
    assign n = res_sign;
    
    assign flags = {2'b0, v, carry, n, z};

endmodule
