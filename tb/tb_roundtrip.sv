`timescale 1ns/1ps

// tb_roundtrip.sv — Prueba de fuego: Encrypt → Decrypt = Plaintext original
//
// Ejecuta 4 pruebas:
//   1. encrypt_standard → decrypt_standard → compara con original
//   2. encrypt_custom   → decrypt_custom   → compara con original
//   3. encrypt_standard → decrypt_custom   → compara con original (cross-check)
//   4. encrypt_custom   → decrypt_standard → compara con original (cross-check)

module tb_roundtrip;

    localparam int MAX_CYCLES = 5000;

    logic clk, reset;
    logic [31:0] pc_out;

    // Plaintext original esperado: v0=0x01234567, v1=0x89ABCDEF
    localparam [31:0] EXPECTED_V0 = 32'h01234567;
    localparam [31:0] EXPECTED_V1 = 32'h89ABCDEF;

    int pass_count = 0;
    int fail_count = 0;

    top #(
        .PROGRAM_FILE("mem/encrypt_standard.mem"),
        .DATA_FILE("tb/tea_data.mem"),
        .AUTH_TIMEOUT(255)
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

    // --- Helper: Read a 32-bit word from byte-addressable RAM ---
    function automatic [31:0] read_ram_word(input int byte_addr);
        read_ram_word = {dut.dmem.ram[byte_addr+3],
                         dut.dmem.ram[byte_addr+2],
                         dut.dmem.ram[byte_addr+1],
                         dut.dmem.ram[byte_addr+0]};
    endfunction

    // --- Helper: Restore original plaintext at 0x100 ---
    task automatic restore_plaintext();
        // v0 = 0x01234567 at byte address 0x100 (index 256)
        dut.dmem.ram[256] = 8'h67;
        dut.dmem.ram[257] = 8'h45;
        dut.dmem.ram[258] = 8'h23;
        dut.dmem.ram[259] = 8'h01;
        // v1 = 0x89ABCDEF at byte address 0x104 (index 260)
        dut.dmem.ram[260] = 8'hEF;
        dut.dmem.ram[261] = 8'hCD;
        dut.dmem.ram[262] = 8'hAB;
        dut.dmem.ram[263] = 8'h89;
    endtask

    // --- Helper: Clear result areas 0x200 and 0x300 ---
    task automatic clear_results();
        int i;
        for (i = 512; i < 520; i = i + 1) dut.dmem.ram[i] = 8'h0; // 0x200-0x207
        for (i = 768; i < 776; i = i + 1) dut.dmem.ram[i] = 8'h0; // 0x300-0x307
    endtask

    // --- Run a program until it writes to final_addr ---
    task automatic run_program(input string mem_file, input int final_addr);
        int cycles;
        cycles = 0;

        $readmemh(mem_file, dut.if_stage.instr_mem);

        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;

        while (cycles < MAX_CYCLES) begin
            @(posedge clk);
            cycles = cycles + 1;

            // Detect end: wait for the SECOND store (final_addr + 4)
            if (dut.mem_write && dut.alu_result == (final_addr + 4)) begin
                @(posedge clk); // Let it commit
                cycles = cycles + 1;
                $display("    Program finished in %0d cycles", cycles);
                disable run_program;
            end
        end
        $display("    TIMEOUT!");
    endtask

    // --- Full roundtrip test: encrypt then decrypt ---
    task automatic roundtrip_test(
        input string test_name,
        input string encrypt_file,
        input string decrypt_file
    );
        logic [31:0] result_v0, result_v1;
        logic [31:0] cipher_v0, cipher_v1;

        $display("\n============================================");
        $display("  TEST: %s", test_name);
        $display("============================================");

        // Prepare clean state
        restore_plaintext();
        clear_results();

        // Step 1: Encrypt
        $display("  [1] Encrypting with: %s", encrypt_file);
        run_program(encrypt_file, 32'h200);

        cipher_v0 = read_ram_word(512); // 0x200
        cipher_v1 = read_ram_word(516); // 0x204
        $display("    Ciphertext: v0=0x%h  v1=0x%h", cipher_v0, cipher_v1);

        if (cipher_v0 == EXPECTED_V0 && cipher_v1 == EXPECTED_V1) begin
            $display("    [WARNING] Ciphertext equals plaintext — encryption may have failed!");
        end

        // Copy ciphertext to 0x200 (already there) — decrypt reads from 0x200
        // Step 2: Decrypt
        $display("  [2] Decrypting with: %s", decrypt_file);
        run_program(decrypt_file, 32'h300);

        result_v0 = read_ram_word(768); // 0x300
        result_v1 = read_ram_word(772); // 0x304
        $display("    Recovered: v0=0x%h  v1=0x%h", result_v0, result_v1);
        $display("    Expected:  v0=0x%h  v1=0x%h", EXPECTED_V0, EXPECTED_V1);

        if (result_v0 == EXPECTED_V0 && result_v1 == EXPECTED_V1) begin
            $display("    >>> [PASS] Roundtrip successful!");
            pass_count = pass_count + 1;
        end else begin
            $display("    >>> [FAIL] Data mismatch!");
            fail_count = fail_count + 1;
        end
    endtask

    // === Main test sequence ===
    initial begin
        $dumpfile("vcd/tb_roundtrip.vcd");
        $dumpvars(0, tb_roundtrip);

        $display("====================================================");
        $display("   TEA-Vault Roundtrip Verification (Encrypt+Decrypt)");
        $display("====================================================");

        // Test 1: Standard → Standard
        roundtrip_test(
            "Standard Encrypt + Standard Decrypt",
            "mem/encrypt_standard.mem",
            "mem/decrypt_standard.mem"
        );

        // Test 2: Custom → Custom
        roundtrip_test(
            "Custom Encrypt + Custom Decrypt",
            "mem/encrypt_custom.mem",
            "mem/decrypt_custom.mem"
        );

        // Test 3: Cross — Standard Encrypt + Custom Decrypt
        roundtrip_test(
            "Standard Encrypt + Custom Decrypt (Cross)",
            "mem/encrypt_standard.mem",
            "mem/decrypt_custom.mem"
        );

        // Test 4: Cross — Custom Encrypt + Standard Decrypt
        roundtrip_test(
            "Custom Encrypt + Standard Decrypt (Cross)",
            "mem/encrypt_custom.mem",
            "mem/decrypt_standard.mem"
        );

        $display("\n====================================================");
        $display("   RESULTS: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("====================================================");

        if (fail_count == 0)
            $display("   ALL TESTS PASSED!");
        else
            $display("   SOME TESTS FAILED!");

        $finish;
    end

endmodule
