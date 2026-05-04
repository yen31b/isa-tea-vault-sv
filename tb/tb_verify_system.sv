`timescale 1ns/1ps

module tb_verify_system;

    localparam int INSTR_MEM_SIZE = 1024;
    localparam int TEST_CYCLES     = 30; 

    logic clk;
    logic reset;

    logic [31:0] pc_out;
    logic [31:0] alu_result_out;
    logic [5:0]  status_flags_out;
    logic        auth_status_out;
    logic        auth_fail_out;
    logic        access_denied_out;
    logic        illegal_access_out;

    int errors;
    int cycle;

    top #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .PROGRAM_FILE("tb/verify_vault_ram.mem"),
        .DATA_FILE("tb/verify_data.mem")
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
        $dumpfile("vcd/tb_verify_system.vcd");
        $dumpvars(0, tb_verify_system);

        errors = 0;
        reset  = 1'b1;
        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        for (cycle = 0; cycle < TEST_CYCLES; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
            
            $display("[T=%0t] Cycle %0d: PC=0x%h AUTH=%b r0=0x%h", $time, cycle, pc_out, auth_status_out, dut.dp.rf.registers[0]);

            case (cycle)
                6: if (auth_status_out !== 1'b1) begin
                    $display("[ERROR] VAUTH fallo: AUTH sigue en 0 en ciclo 6");
                    errors++;
                end

                9: if (dut.vault_inst.vault[0][0] !== 32'h00001234) begin
                    $display("[ERROR] VSTR fallo en vault[0][0]: obtenido 0x%h", dut.vault_inst.vault[0][0]);
                    errors++;
                end

                14: if (dut.k_reg0 !== 32'h00001234) begin
                    $display("[ERROR] VLD fallo en k_reg0: obtenido 0x%h", dut.k_reg0);
                    errors++;
                end

                20: if (dut.dp.rf.registers[3] !== 32'h44332211) begin
                    $display("[ERROR] LD RAM[0] fallo: obtenido 0x%h", dut.dp.rf.registers[3]);
                    errors++;
                end

                22: if (dut.dp.rf.registers[5] !== 32'h88776655) begin
                    $display("[ERROR] LD RAM[4] fallo: obtenido 0x%h", dut.dp.rf.registers[5]);
                    errors++;
                end
            endcase
        end

        if (errors == 0) begin
            $display("\n[PASS] Sistema verificado exitosamente.");
        end else begin
            $display("\n[FAIL] Se encontraron %0d errores en la verificacion.", errors);
        end

        $finish;
    end

endmodule
