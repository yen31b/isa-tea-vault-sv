`timescale 1ns / 1ps

module tb_datapath;
    logic        clk, reset;
    logic        reg_write;
    logic [3:0]  alu_op;
    logic        alu_src_b;
    logic        alu_src_c;
    logic [2:0]  rs1_addr, rs2_addr, rs3_addr, rd_addr;
    logic [31:0] immediate;
    logic [31:0] mem_data_in;
    
    logic [31:0] alu_result;
    logic [31:0] reg_data_2;
    logic [5:0]  status_flags;

    datapath dut (.*);

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1; reg_write = 0; alu_op = 0; alu_src_b = 0; alu_src_c = 0;
        rs1_addr = 0; rs2_addr = 0; rs3_addr = 0; rd_addr = 0;
        immediate = 0; mem_data_in = 0;
        #15 reset = 0;
        
        @(posedge clk); #1; // Wait for write to complete
        // 1. Write 10 to r1: r1 = r0 + 10
        reg_write = 1; rd_addr = 3'd1; rs1_addr = 3'd0; immediate = 32'd10; alu_op = 4'b0000; alu_src_b = 1; 
        
        @(posedge clk); #1;
        // 2. Write 20 to r2: r2 = r0 + 20
        rd_addr = 3'd2; immediate = 32'd20; 
        
        @(posedge clk); #1;
        // 3. ADD r1 + r2 -> r3
        rd_addr = 3'd3; rs1_addr = 3'd1; rs2_addr = 3'd2; alu_op = 4'b0000; alu_src_b = 0; 
        
        @(posedge clk); #1;
        reg_write = 0;
        
        #10;
        $display("Result in r3 (ALU Out): %d (Expected: 30)", alu_result);
        $display("Flags: %b", status_flags);

        $finish;
    end
endmodule
