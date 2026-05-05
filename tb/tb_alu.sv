`timescale 1ns / 1ps

module tb_alu;
    logic [31:0] a, b, c;
    logic [3:0]  alu_op;
    logic        auth_in;
    logic [31:0] result;
    logic [5:0]  flags;
    logic        illegal_op;

    alu dut (
        .a(a),
        .b(b),
        .c(c),
        .alu_op(alu_op),
        .auth_in(auth_in),
        .result(result),
        .flags(flags),
        .illegal_op(illegal_op)
    );

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

    initial begin
        $dumpfile("vcd/tb_alu.vcd");
        $dumpvars(0, tb_alu);
        $monitor("Time: %0t | Op: %h | Auth: %b | A: %h | B: %h | C: %h | Res: %h | Flags: %b | Illegal: %b", 
                 $time, alu_op, auth_in, a, b, c, result, flags, illegal_op);

        auth_in = 0;
        
        // 1. ADD
        a = 32'h00000010; b = 32'h00000020; alu_op = ALU_ADD; #10;
        
        // 2. SUB
        a = 32'h00000050; b = 32'h00000010; alu_op = ALU_SUB; #10;
        
        // 3. AND
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = ALU_AND; #10;
        
        // 4. OR
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = ALU_OR; #10;
        
        // 5. XOR
        a = 32'hAAAAAAAA; b = 32'h55555555; alu_op = ALU_XOR; #10;
        
        // 6. SRL
        a = 32'h80000000; b = 32'd4; alu_op = ALU_SRL; #10;
        
        // 7. SLL
        a = 32'h00000001; b = 32'd8; alu_op = ALU_SLL; #10;
        
        // 8. MUL
        a = 32'd12; b = 32'd10; alu_op = ALU_MUL; #10;
        
        // 9. MOV
        a = 32'h12345678; alu_op = ALU_MOV; #10;
        
        // 10. XORTEA without AUTH - Should fail
        a = 32'h11111111; b = 32'h22222222; c = 32'h33333333; alu_op = ALU_XORTEA; #10;
        
        // 11. XORTEA with AUTH - Should succeed
        auth_in = 1; #10;
        
        // 12. BEQADD - Case A == B (Z=1)
        a = 32'd10; b = 32'd10; c = 32'd5; alu_op = ALU_BEQADD; #10;
        
        // 13. BEQADD - Case A != B (Z=0)
        a = 32'd10; b = 32'd20; #10;

        $finish;
    end
endmodule
