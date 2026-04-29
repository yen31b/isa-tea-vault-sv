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

    initial begin
        $monitor("Time: %0t | Op: %h | Auth: %b | Res: %h | Flags: %b | Illegal: %b", 
                 $time, alu_op, auth_in, result, flags, illegal_op);

        auth_in = 0;
        // Test ADD
        a = 32'h00000001; b = 32'h00000002; alu_op = 4'b0000; #10;
        
        // Test SUB
        a = 32'h0000000A; b = 32'h00000003; alu_op = 4'b0001; #10;
        
        // Test XORTEA without AUTH (Should fail)
        a = 32'hAAAA_AAAA; b = 32'h5555_5555; c = 32'hFFFF_FFFF; alu_op = 4'b1010; #10;
        
        // Test XORTEA with AUTH (Should succeed)
        auth_in = 1; #10;
        
        // Test beqadd increment logic with AUTH
        // Case: A == B (Should set Z flag)
        auth_in = 1; a = 32'd32; b = 32'd32; c = 32'd10; alu_op = 4'b1011; #10;
        
        // Case: A != B (Should NOT set Z flag)
        a = 32'd32; b = 32'd31; c = 32'd10; #10;

        $finish;
    end
endmodule
