// Testbench para key_vault.sv

// Casos de prueba:
//   1. VSTR con auth=1 → escritura exitosa
//   2. VSTR con auth=0 → exc_out=1, bóveda no modificada
//   3. VLD con auth=1 → k_internal cargado correctamente
//   4. VLD con auth=0 → exc_out=1, k_internal no modificado
//   5. VCLR con auth=1 → slot borrado completamente
//   6. VCLR con auth=0 → exc_out=1, slot no borrado
//   7. Llave completa de 128 bits (4 palabras en slot 0)
//   8. Múltiples slots sin interferencia

`timescale 1ns/1ps

module tb_key_vault;

    // Señales
    logic        clk, rst;
    logic        vault_write, vault_load_secure, vault_clear;
    logic        auth_status;
    logic [2:0]  slot, palabra;
    logic [31:0] rs1_data;
    logic        exc_out;
    logic [31:0] k_reg [0:3];

    // Instancia
    key_vault dut (
        .clk                (clk),
        .rst                (rst),
        .vault_write        (vault_write),
        .vault_load_secure  (vault_load_secure),
        .vault_clear        (vault_clear),
        .auth_status        (auth_status),
        .slot               (slot),
        .palabra            (palabra),
        .rs1_data           (rs1_data),
        .exc_out            (exc_out),
        .k_reg              (k_reg)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // pulso de 1 ciclo
    task automatic pulso(ref logic señal);
        señal = 1; @(posedge clk); #1; señal = 0;
    endtask

    // Pruebas
    initial begin
        $dumpfile("vcd/tb_key_vault.vcd");
        $dumpvars(0, tb_key_vault);

        // Reset
        rst = 1; vault_write = 0; vault_load_secure = 0;
        vault_clear = 0; auth_status = 0;
        slot = 0; palabra = 0; rs1_data = 0;
        @(posedge clk); #1; rst = 0;

        $display("\n=== tb_key_vault: Iniciando pruebas ===\n");

        // TEST 1: VSTR con auth=1 → debe escribir en bóveda
        
        $display("--- TEST 1: VSTR autenticado ---");
        auth_status = 1;
        slot = 3'd0; palabra = 3'd0; rs1_data = 32'hA1B2C3D4;
        pulso(vault_write);

        // Verificar que el dato quedó en vault[0][0]
        if (dut.vault[0][0] === 32'hA1B2C3D4)
            $display("  PASS vault[0][0]=0x%08h", dut.vault[0][0]);
        else
            $error("  FAIL vault[0][0]=0x%08h (esperado 0xA1B2C3D4)", dut.vault[0][0]);

        if (exc_out === 1'b0)
            $display("  PASS exc_out=0 (sin excepción)");
        else
            $error("  FAIL exc_out=1 (no debería haber excepción)");

        
        // TEST 2: VSTR sin auth → debe generar excepción
        
        $display("\n--- TEST 2: VSTR sin autenticación ---");
        auth_status = 0;
        slot = 3'd1; palabra = 3'd0; rs1_data = 32'hDEADBEEF;
        pulso(vault_write);

        if (exc_out === 1'b1)
            $display("  PASS exc_out=1 (excepción generada correctamente)");
        else
            $error("  FAIL exc_out=0 (debería haber excepción)");

        // Verificar que la bóveda NO fue modificada
        if (dut.vault[1][0] === 32'h0)
            $display("  PASS vault[1][0] sigue en 0 (no modificado)");
        else
            $error("  FAIL vault[1][0]=0x%08h (fue modificado sin auth)", dut.vault[1][0]);

        
        // TEST 3: VLD con auth=1 → k_reg debe cargarse
        
        $display("\n--- TEST 3: VLD autenticado ---");
        auth_status = 1;
        // Primero escribir algo en vault[0][1]
        slot = 3'd0; palabra = 3'd1; rs1_data = 32'hE5F60718;
        pulso(vault_write);
        // Ahora VLD: cargar vault[0][1] → k_internal[1]
        slot = 3'd0; palabra = 3'd1;
        pulso(vault_load_secure);

        if (k_reg[1] === 32'hE5F60718)
            $display("  PASS k_reg[1]=0x%08h (cargado correctamente)", k_reg[1]);
        else
            $error("  FAIL k_reg[1]=0x%08h (esperado 0xE5F60718)", k_reg[1]);

        
        // TEST 4: VLD sin auth → excepción, k_reg no cambia
        
        $display("\n--- TEST 4: VLD sin autenticación ---");
        auth_status = 0;
        slot = 3'd0; palabra = 3'd0;
        pulso(vault_load_secure);

        if (exc_out === 1'b1)
            $display("  PASS exc_out=1 (excepción correcta)");
        else
            $error("  FAIL exc_out=0 (debería haber excepción)");

        // k_reg[0] no debería haber cambiado (sigue en 0 del reset)
        if (k_reg[0] === 32'h0)
            $display("  PASS k_reg[0] no modificado (sigue en 0)");
        else
            $error("  FAIL k_reg[0]=0x%08h (fue modificado sin auth)", k_reg[0]);

        
        // TEST 5: VCLR con auth=1 → slot borrado
        
        $display("\n--- TEST 5: VCLR autenticado ---");
        auth_status = 1;
        // Escribir las 4 palabras del slot 0
        slot = 3'd0;
        for (int i = 0; i < 4; i++) begin
            palabra = i[2:0]; rs1_data = 32'hCAFEBABE;
            pulso(vault_write);
        end
        // Ahora borrar slot 0
        slot = 3'd0;
        pulso(vault_clear);

        if (dut.vault[0][0] === 32'h0 && dut.vault[0][1] === 32'h0 &&
            dut.vault[0][2] === 32'h0 && dut.vault[0][3] === 32'h0)
            $display("  PASS slot 0 borrado completamente");
        else
            $error("  FAIL slot 0 no fue borrado correctamente");

        
        // TEST 6: VCLR sin auth → excepción
        
        $display("\n--- TEST 6: VCLR sin autenticación ---");
        // Primero escribir en slot 2 con auth
        auth_status = 1;
        slot = 3'd2; palabra = 3'd0; rs1_data = 32'h11223344;
        pulso(vault_write);
        // Intentar borrar sin auth
        auth_status = 0;
        slot = 3'd2;
        pulso(vault_clear);

        if (exc_out === 1'b1)
            $display("  PASS exc_out=1 (excepción correcta)");
        else
            $error("  FAIL exc_out=0 (debería haber excepción)");

        if (dut.vault[2][0] === 32'h11223344)
            $display("  PASS vault[2][0] no fue borrado");
        else
            $error("  FAIL vault[2][0] fue borrado sin auth");

        
        // TEST 7: Llave completa de 128 bits en slot 1
        
        $display("\n--- TEST 7: Llave 128 bits completa ---");
        auth_status = 1;
        slot = 3'd1;
        // Escribir 4 palabras
        palabra = 3'd0; rs1_data = 32'hA1B2C3D4; pulso(vault_write);
        palabra = 3'd1; rs1_data = 32'hE5F60718; pulso(vault_write);
        palabra = 3'd2; rs1_data = 32'h293A4B5C; pulso(vault_write);
        palabra = 3'd3; rs1_data = 32'h6D7E8F90; pulso(vault_write);

        // Cargar las 4 palabras a k_reg
        slot = 3'd1;
        palabra = 3'd0; pulso(vault_load_secure);
        palabra = 3'd1; pulso(vault_load_secure);
        palabra = 3'd2; pulso(vault_load_secure);
        palabra = 3'd3; pulso(vault_load_secure);

        if (k_reg[0]===32'hA1B2C3D4 && k_reg[1]===32'hE5F60718 &&
            k_reg[2]===32'h293A4B5C && k_reg[3]===32'h6D7E8F90)
            $display("  PASS llave 128 bits cargada correctamente en k_reg[0..3]");
        else
            $error("  FAIL k_reg=[%h, %h, %h, %h]",
                   k_reg[0], k_reg[1], k_reg[2], k_reg[3]);

        
        // TEST 8: Sin interferencia entre slots
        
        $display("\n--- TEST 8: No interferencia entre slots ---");
        auth_status = 1;
        // Escribir en slot 3
        slot = 3'd3; palabra = 3'd0; rs1_data = 32'hBEEFCAFE;
        pulso(vault_write);

        // Verificar que slot 1 sigue igual
        if (dut.vault[1][0] === 32'hA1B2C3D4)
            $display("  PASS slot 1 no fue afectado por escritura en slot 3");
        else
            $error("  FAIL slot 1 fue alterado");

        $display("\n=== tb_key_vault: Pruebas completadas ===\n");
        $finish;
    end

endmodule