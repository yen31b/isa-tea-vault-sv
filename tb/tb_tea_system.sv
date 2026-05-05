`timescale 1ns/1ps

module tb_tea_system;

    localparam int INSTR_MEM_SIZE = 1024;
    localparam int TEST_CYCLES     = 2000; 

    logic clk;
    logic reset;

    logic [31:0] pc_out;
    logic [31:0] alu_result_out;
    logic [5:0]  status_flags_out;
    logic        auth_status_out;
    logic        auth_fail_out;
    logic        access_denied_out;
    logic        illegal_access_out;

    top #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .PROGRAM_FILE("tb/tea_encrypt.mem"),
        .DATA_FILE("tb/tea_data.mem")
    ) dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        .status_flags_out(status_flags_out),
        .auth_status_out(auth_status_out),
        .auth_fail_out(auth_fail_out),
        .access_denied_out(access_denied_out),
        .illegal_access_out(illegal_access_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("vcd/tb_tea_system.vcd");
        $dumpvars(0, tb_tea_system);

        reset  = 1'b1;
        repeat (5) @(posedge clk);
        #1;
        reset = 1'b0;

        for (int i = 0; i < TEST_CYCLES; i++) begin
            @(posedge clk);
            if (i % 200 == 0) $display("Cycle %0d: PC=0x%h AUTH=%b", i, pc_out, auth_status_out);
        end
        
        $display("\n--- Resultados de TEA (Cifrado + Descifrado) ---");
        // RAM address 0x300 = index 768
        $display("Original v0: 0x01234567 | Recuperado v0: 0x%h%h%h%h", dut.dmem.ram[771], dut.dmem.ram[770], dut.dmem.ram[769], dut.dmem.ram[768]);
        $display("Original v1: 0x89ABCDEF | Recuperado v1: 0x%h%h%h%h", dut.dmem.ram[775], dut.dmem.ram[774], dut.dmem.ram[773], dut.dmem.ram[772]);
        
        if ({dut.dmem.ram[771], dut.dmem.ram[770], dut.dmem.ram[769], dut.dmem.ram[768]} == 32'h01234567 &&
            {dut.dmem.ram[775], dut.dmem.ram[774], dut.dmem.ram[773], dut.dmem.ram[772]} == 32'h89ABCDEF) begin
            $display("\n[PASS] TEA Funcional: Los datos originales se recuperaron correctamente!");
        end else begin
            $display("\n[FAIL] Los datos recuperados no coinciden con los originales.");
        end

        $finish;
    end

endmodule
