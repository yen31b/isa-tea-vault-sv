`timescale 1ns/1ps
// tb_tea.sv — Testbench para tea_unit
// Valida cifrado (TEA_ENC) y descifrado (TEA_DEC) con round-trip
// Uso: make tb_tea

module tb_tea;

    // ---------------------------------------------------------------
    // Señales del DUT
    // ---------------------------------------------------------------
    logic        clk, rst;
    logic        start, encrypt;
    logic [31:0] v0_in, v1_in;
    logic [31:0] k_reg [0:3];
    logic [31:0] v0_out, v1_out;
    logic        done, busy;

    // ---------------------------------------------------------------
    // Instancia del DUT
    // ---------------------------------------------------------------
    tea_unit dut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .encrypt (encrypt),
        .v0_in   (v0_in),
        .v1_in   (v1_in),
        .k_reg   (k_reg),
        .v0_out  (v0_out),
        .v1_out  (v1_out),
        .done    (done),
        .busy    (busy)
    );

    // ---------------------------------------------------------------
    // Reloj: periodo 10 ns
    // ---------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // VCD
    // ---------------------------------------------------------------
    initial begin
        $dumpfile("vcd/tb_tea.vcd");
        $dumpvars(0, tb_tea);
    end

    // ---------------------------------------------------------------
    // Contadores de resultados
    // ---------------------------------------------------------------
    integer pass_cnt, fail_cnt;

    // ---------------------------------------------------------------
    // Tarea: reset
    // ---------------------------------------------------------------
    task apply_reset;
        rst     = 1'b1;
        start   = 1'b0;
        encrypt = 1'b1;
        v0_in   = 32'd0;
        v1_in   = 32'd0;
        k_reg[0] = 32'd0; k_reg[1] = 32'd0;
        k_reg[2] = 32'd0; k_reg[3] = 32'd0;
        repeat(3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
    endtask

    // ---------------------------------------------------------------
    // Tarea: lanza una operacion TEA y espera done
    //   Llama despues de haber configurado k_reg y encrypt/v0_in/v1_in
    //   al terminar: v0_out, v1_out contienen el resultado
    // ---------------------------------------------------------------
    task run_and_wait;
        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        @(negedge clk);
        start = 1'b0;
        // Espera done con timeout de 60 ciclos (~32 rounds + margen)
        fork
            begin : wait_done_blk
                wait(done === 1'b1);
            end
            begin : timeout_blk
                repeat(60) @(posedge clk);
                $display("ERROR: TIMEOUT esperando done en ciclo %0t", $time);
                $finish;
            end
        join_any
        disable fork;
        @(posedge clk); // dejar que FSM transite a IDLE
    endtask

    // ---------------------------------------------------------------
    // Tarea: verificar resultado
    // ---------------------------------------------------------------
    task check_result;
        input [127:0] name_unused; // solo para legibilidad en el log
        input [31:0]  exp_v0, exp_v1;
        input [31:0]  got_v0, got_v1;
        if (got_v0 === exp_v0 && got_v1 === exp_v1) begin
            $display("  PASS: v0=0x%08h  v1=0x%08h", got_v0, got_v1);
            pass_cnt++;
        end else begin
            $display("  FAIL: esperado v0=0x%08h v1=0x%08h  |  obtenido v0=0x%08h v1=0x%08h",
                     exp_v0, exp_v1, got_v0, got_v1);
            fail_cnt++;
        end
    endtask

    // ---------------------------------------------------------------
    // Variables auxiliares
    // ---------------------------------------------------------------
    logic [31:0] plain_v0, plain_v1;
    logic [31:0] cipher_v0, cipher_v1;
    logic [31:0] dec_v0, dec_v1;

    // ---------------------------------------------------------------
    // Secuencia de pruebas
    // ---------------------------------------------------------------
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        apply_reset();

        // ===========================================================
        // TEST 1: Round-trip con llave arbitraria
        //   Plaintext : v0=0x12345678, v1=0x9ABCDEF0
        //   Key       : {0xDEADBEEF, 0xCAFEBABE, 0x12345678, 0xFEDCBA98}
        // ===========================================================
        $display("\n[Test 1] TEA_ENC + TEA_DEC  (llave arbitraria)");

        plain_v0 = 32'h12345678;
        plain_v1 = 32'h9ABCDEF0;
        k_reg[0] = 32'hDEADBEEF; k_reg[1] = 32'hCAFEBABE;
        k_reg[2] = 32'h12345678; k_reg[3] = 32'hFEDCBA98;

        // --- Cifrado (TEA_ENC) ---
        encrypt = 1'b1;
        v0_in   = plain_v0;
        v1_in   = plain_v1;
        run_and_wait();
        cipher_v0 = v0_out;
        cipher_v1 = v1_out;
        $display("  Cifrado  → v0=0x%08h  v1=0x%08h", cipher_v0, cipher_v1);

        // Verificar que ciphertext difiere del plaintext
        if (cipher_v0 !== plain_v0 || cipher_v1 !== plain_v1) begin
            $display("  PASS: cifrado altera los datos");
            pass_cnt++;
        end else begin
            $display("  FAIL: ciphertext == plaintext (no hubo cifrado)");
            fail_cnt++;
        end

        // --- Descifrado (TEA_DEC) ---
        encrypt = 1'b0;
        v0_in   = cipher_v0;
        v1_in   = cipher_v1;
        run_and_wait();
        dec_v0 = v0_out;
        dec_v1 = v1_out;
        $display("  Descifrado → v0=0x%08h  v1=0x%08h", dec_v0, dec_v1);

        check_result("round-trip T1", plain_v0, plain_v1, dec_v0, dec_v1);

        repeat(2) @(posedge clk);

        // ===========================================================
        // TEST 2: Round-trip con llave cero
        //   Plaintext : v0=0xFFFFFFFF, v1=0xA5A5A5A5
        //   Key       : {0, 0, 0, 0}
        // ===========================================================
        $display("\n[Test 2] TEA_ENC + TEA_DEC  (llave cero)");

        plain_v0 = 32'hFFFFFFFF;
        plain_v1 = 32'hA5A5A5A5;
        k_reg[0] = 32'd0; k_reg[1] = 32'd0;
        k_reg[2] = 32'd0; k_reg[3] = 32'd0;

        encrypt = 1'b1;
        v0_in   = plain_v0;
        v1_in   = plain_v1;
        run_and_wait();
        cipher_v0 = v0_out;
        cipher_v1 = v1_out;
        $display("  Cifrado  → v0=0x%08h  v1=0x%08h", cipher_v0, cipher_v1);

        encrypt = 1'b0;
        v0_in   = cipher_v0;
        v1_in   = cipher_v1;
        run_and_wait();
        dec_v0 = v0_out;
        dec_v1 = v1_out;
        $display("  Descifrado → v0=0x%08h  v1=0x%08h", dec_v0, dec_v1);

        check_result("round-trip T2", plain_v0, plain_v1, dec_v0, dec_v1);

        repeat(2) @(posedge clk);

        // ===========================================================
        // TEST 3: Round-trip con plaintext cero y llave arbitraria
        //   Plaintext : v0=0x00000000, v1=0x00000000
        //   Key       : {0xAABBCCDD, 0x11223344, 0x55667788, 0x99AABBCC}
        // ===========================================================
        $display("\n[Test 3] TEA_ENC + TEA_DEC  (plaintext cero)");

        plain_v0 = 32'h00000000;
        plain_v1 = 32'h00000000;
        k_reg[0] = 32'hAABBCCDD; k_reg[1] = 32'h11223344;
        k_reg[2] = 32'h55667788; k_reg[3] = 32'h99AABBCC;

        encrypt = 1'b1;
        v0_in   = plain_v0;
        v1_in   = plain_v1;
        run_and_wait();
        cipher_v0 = v0_out;
        cipher_v1 = v1_out;
        $display("  Cifrado  → v0=0x%08h  v1=0x%08h", cipher_v0, cipher_v1);

        encrypt = 1'b0;
        v0_in   = cipher_v0;
        v1_in   = cipher_v1;
        run_and_wait();
        dec_v0 = v0_out;
        dec_v1 = v1_out;
        $display("  Descifrado → v0=0x%08h  v1=0x%08h", dec_v0, dec_v1);

        check_result("round-trip T3", plain_v0, plain_v1, dec_v0, dec_v1);

        repeat(2) @(posedge clk);

        // ===========================================================
        // TEST 4: Verificacion de señales busy y done
        // ===========================================================
        $display("\n[Test 4] Señales busy / done");

        k_reg[0] = 32'h00000001; k_reg[1] = 32'h00000002;
        k_reg[2] = 32'h00000003; k_reg[3] = 32'h00000004;
        encrypt  = 1'b1;
        v0_in    = 32'hCAFECAFE;
        v1_in    = 32'hBEEFBEEF;

        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        @(negedge clk);
        start = 1'b0;

        // Ciclo 1 despues de start: debe estar busy
        @(posedge clk);
        if (busy === 1'b1) begin
            $display("  PASS: busy=1 durante la operacion");
            pass_cnt++;
        end else begin
            $display("  FAIL: busy deberia ser 1 durante operacion");
            fail_cnt++;
        end

        // Esperar done
        fork
            begin : wb4
                wait(done === 1'b1);
            end
            begin : tb4
                repeat(60) @(posedge clk);
                $display("  ERROR: TIMEOUT en Test 4");
                $finish;
            end
        join_any
        disable fork;

        $display("  PASS: done=1 recibido al completar 32 rondas");
        pass_cnt++;

        @(posedge clk);
        // Despues de done, busy debe ser 0
        if (busy === 1'b0) begin
            $display("  PASS: busy=0 tras done");
            pass_cnt++;
        end else begin
            $display("  FAIL: busy deberia ser 0 tras done");
            fail_cnt++;
        end

        // ===========================================================
        // Resumen
        // ===========================================================
        repeat(2) @(posedge clk);
        $display("\n============================================");
        $display("  RESULTADO FINAL: %0d PASS  /  %0d FAIL", pass_cnt, fail_cnt);
        $display("============================================\n");
        $finish;
    end

endmodule
