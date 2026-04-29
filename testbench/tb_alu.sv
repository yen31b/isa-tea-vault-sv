`timescale 1ns / 1ps

module tb_alu;
    logic [31:0] a, b, c;
    logic [3:0]  alu_op;
    logic [31:0] result;
    logic [5:0]  flags;

    alu dut (
        .a(a),
        .b(b),
        .c(c),
        .alu_op(alu_op),
        .result(result),
        .flags(flags)
    );

    initial begin
        $monitor("Time: %0t | Op: %h | A: %h | B: %h | C: %h | Res: %h | Flags: %b", 
                 $time, alu_op, a, b, c, result, flags);

        // Test ADD
        a = 32'h00000001; b = 32'h00000002; alu_op = 4'b0000; #10;
        
        // Test SUB
        a = 32'h0000000A; b = 32'h00000003; alu_op = 4'b0001; #10;
        
        // Test AND
        a = 32'h000000FF; b = 32'h0000FF00; alu_op = 4'b0010; #10;
        
        // Test XORTEA (A ^ B ^ C)
        a = 32'hAAAA_AAAA; b = 32'h5555_5555; c = 32'hFFFF_FFFF; alu_op = 4'b1010; #10;
        
        // Test Zero Flag
        a = 32'h00000005; b = 32'h00000005; alu_op = 4'b0001; #10;

        $finish;
    end
endmodule
