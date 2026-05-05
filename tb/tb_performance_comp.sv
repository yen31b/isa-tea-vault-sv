`timescale 1ns/1ps

module tb_performance_comp;

    localparam int MAX_CYCLES = 5000;
    
    logic clk, reset;
    logic [31:0] pc_out;
    string program_file;
    
    top #(
        .PROGRAM_FILE("mem/encrypt_standard.mem"), // Default
        .DATA_FILE("tb/tea_data.mem"),
        .AUTH_TIMEOUT(255) // Increased timeout for 32 rounds
    ) dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .alu_result_out(),
        .status_flags_out(),
        .auth_status_out(),
        .auth_fail_out(),
        .access_denied_out(),
        .illegal_access_out()
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task to run a specific memory file and report cycles
    task automatic run_test(input string mem_file, input int final_addr);
        int cycles = 0;
        $display("\n[TEST] Running: %s", mem_file);
        
        // Reload memory (Hierarchical reference to instruction memory)
        $readmemh(mem_file, dut.if_stage.instr_mem);
        
        // Clear result addresses in RAM to avoid false positives from previous runs
        dut.dmem.ram[512] = 8'h0; dut.dmem.ram[513] = 8'h0; dut.dmem.ram[514] = 8'h0; dut.dmem.ram[515] = 8'h0; // 0x200
        dut.dmem.ram[516] = 8'h0; dut.dmem.ram[517] = 8'h0; dut.dmem.ram[518] = 8'h0; dut.dmem.ram[519] = 8'h0; // 0x204
        dut.dmem.ram[768] = 8'h0; dut.dmem.ram[769] = 8'h0; dut.dmem.ram[770] = 8'h0; dut.dmem.ram[771] = 8'h0; // 0x300
        dut.dmem.ram[772] = 8'h0; dut.dmem.ram[773] = 8'h0; dut.dmem.ram[774] = 8'h0; dut.dmem.ram[775] = 8'h0; // 0x304

        // Reset system
        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;
        
        while (cycles < MAX_CYCLES) begin
            @(posedge clk);
            cycles++;
            
            if (cycles % 100 == 0) begin
                $display("  [DEBUG] Cycle %0d: PC=0x%h R3=%0d AUTH=%b", cycles, pc_out, dut.dp.rf.registers[3], dut.auth_status);
            end

            // Detect end: A write to the final address (0x200 or 0x300)
            // Final address is 0x200 (index 512) for encrypt, 0x300 (index 768) for decrypt
            if (dut.mem_write && dut.alu_result == final_addr) begin
                // Wait a bit for the second word to be stored (TEA stores 2 words)
                @(posedge clk);
                cycles++;
                $display(">>> Finished in %0d cycles", cycles);
                disable run_test;
            end
        end
        $display(">>> TIMEOUT reached!");
    endtask

    initial begin
        $dumpfile("vcd/tb_performance_comp.vcd");
        $dumpvars(0, tb_performance_comp);

        $display("====================================================");
        $display("   TEA-Vault Performance Comparison (Cycle Counts)  ");
        $display("====================================================");

        // Test 1: Encrypt Standard
        run_test("mem/encrypt_standard.mem", 32'h200);

        // Test 2: Encrypt Custom
        run_test("mem/encrypt_custom.mem", 32'h200);

        // Test 3: Decrypt Standard
        run_test("mem/decrypt_standard.mem", 32'h300);

        // Test 4: Decrypt Custom
        run_test("mem/decrypt_custom.mem", 32'h300);

        $display("====================================================");
        $finish;
    end

endmodule
