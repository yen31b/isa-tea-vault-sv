`timescale 1ns / 1ps

module tb_datapath;
    logic        clk, reset;
    logic        reg_write;
    logic [3:0]  alu_op;
    logic        alu_src_b;
    logic        mem_to_reg;
    logic [3:0]  rs1_addr, rs2_addr, rs3_addr, rd_addr;
    logic [31:0] immediate;
    logic [31:0] mem_data_in;
    logic        auth_status_in;
    logic        vault_exc_in;
    
    logic [31:0] alu_result;
    logic [31:0] reg_data_1;
    logic [31:0] reg_data_2;
    logic        alu_zero;
    logic [5:0]  status_flags;
    
    // TEA / Vault extensions
    logic        index_inc;
    logic [31:0] k0, k1, k2, k3;

    datapath dut (.*);

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("vcd/tb_datapath.vcd");
        $dumpvars(0, tb_datapath);
        reset = 1; reg_write = 0; alu_op = 0; alu_src_b = 0; mem_to_reg = 0;
        index_inc = 0; k0 = 0; k1 = 0; k2 = 0; k3 = 0;
        rs1_addr = 0; rs2_addr = 0; rs3_addr = 0; rd_addr = 0;
        immediate = 0; mem_data_in = 0;
        auth_status_in = 0; vault_exc_in = 0;
        #15 reset = 0;
        
        @(posedge clk); #1;
        // 1. Attempt privileged XORTEA without AUTH (Should trigger EXC)
        alu_op = 4'b1010; rs1_addr = 4'd1; rs2_addr = 4'd2; rs3_addr = 4'd3; reg_write = 0;
        
        @(posedge clk); #1;
        $display("After unauthorized XORTEA - Flags: %b (Expected bit 5 to be 1)", status_flags);
        
        // 2. Normal ADD: r1 = r0 + 10
        reg_write = 1; rd_addr = 4'd1; rs1_addr = 4'd0; immediate = 32'd10; alu_op = 4'b0000; alu_src_b = 1; 
        
        @(posedge clk); #1;
        // 3. Normal ADD: r2 = r0 + 20
        rd_addr = 4'd2; immediate = 32'd20; 
        
        @(posedge clk); #1;
        // 4. ADD r1 + r2 -> r3
        rd_addr = 4'd3; rs1_addr = 4'd1; rs2_addr = 4'd2; alu_op = 4'b0000; alu_src_b = 0; 
        
        @(posedge clk); #1;
        reg_write = 0;
        
        #10;
        $display("Result in r3 (ALU Out): %d (Expected: 30)", alu_result);
        $display("Flags: %b", status_flags);

        $finish;
    end
endmodule
