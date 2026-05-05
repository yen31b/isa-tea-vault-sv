`timescale 1ns / 1ps

module tb_register_file;
    logic        clk, reset, we;
    logic [3:0]  rs1_addr, rs2_addr, rs3_addr, rd_addr;
    logic [31:0] write_data;
    logic [31:0] rs1_data, rs2_data, rs3_data;

    register_file dut (.*);

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("vcd/tb_register_file.vcd");
        $dumpvars(0, tb_register_file);
        reset = 1; we = 0;
        rs1_addr = 0; rs2_addr = 0; rs3_addr = 0; rd_addr = 0; write_data = 0;
        #15 reset = 0;

        // Write to r1
        rd_addr = 4'd1; write_data = 32'hBEEF_CAFE; we = 1; #10;
        
        // Write to r15 (Test upper range of 16 registers)
        rd_addr = 4'd15; write_data = 32'hDEAD_BEEF; we = 1; #10;
        
        we = 0;
        // Read r1 and r15
        rs1_addr = 4'd1; rs2_addr = 4'd15; #10;
        
        $display("r1_data: %h (Expected: BEEF_CAFE)", rs1_data);
        $display("r15_data: %h (Expected: DEAD_BEEF)", rs2_data);

        $finish;
    end
endmodule
