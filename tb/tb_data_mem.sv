// Testbench para data_mem.sv

`timescale 1ns/1ps

module tb_data_mem;

    // ---- Señales ----
    logic        clk, rst, mem_read, mem_write;
    logic [31:0] address, write_data, read_data;

    // ---- Instancia del módulo bajo prueba ----
    data_mem dut (
        .clk        (clk),
        .reset      (rst),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (address),
        .write_data (write_data),
        .read_data  (read_data)
    );

    // ---- Clock: periodo de 10ns ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Tarea auxiliar: escribir y verificar ----
    task automatic test_store_load(
        input [31:0] addr,
        input [31:0] data,
        input string label
    );
        // ST: escribir
        address    = addr;
        write_data = data;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk); #1;
        mem_write = 0;

        // LD: leer un ciclo después
        mem_read = 1;
        address  = addr;
        #1; // lectura combinacional

        if (read_data === data)
            $display("  PASS [%s] addr=0x%08h esperado=0x%08h leido=0x%08h",
                     label, addr, data, read_data);
        else
            $error("  FAIL [%s] addr=0x%08h esperado=0x%08h leido=0x%08h",
                   label, addr, data, read_data);

        mem_read = 0;
    endtask

    // ---- Pruebas principales ----
    initial begin
        $dumpfile("vcd/tb_dmem.vcd");
        $dumpvars(0, tb_dmem);

        // Reset
        rst       = 1;
        mem_read  = 0;
        mem_write = 0;
        address   = 0;
        write_data = 0;
        @(posedge clk); #1;
        rst = 0;

        $display("\n=== tb_dmem: Iniciando pruebas ===\n");


        // TEST 1: Escritura y lectura

        $display("--- TEST 1: ST y LD ---");
        test_store_load(32'h00000000, 32'hDEADBEEF, "T1-addr0");
        test_store_load(32'h00000004, 32'hCAFEBABE, "T1-addr4");
        test_store_load(32'h00000008, 32'h12345678, "T1-addr8");


        // TEST 2: Verificar Little Endian
        // Escribir 0xAABBCCDD en 0x10
        // Internamente debe quedar:
        //   ram[0x10] = DD, ram[0x11] = CC, ram[0x12] = BB, ram[0x13] = AA

        $display("\n--- TEST 2: Verificar Little Endian ---");
        address    = 32'h00000010;
        write_data = 32'hAABBCCDD;
        mem_write  = 1; mem_read = 0;
        @(posedge clk); #1;
        mem_write = 0;

        // Verificar bytes internos directamente
        if (dut.ram[32'h10] === 8'hDD)
            $display("  PASS ram[0x10]=0x%02h (esperado DD - LSB)", dut.ram[32'h10]);
        else
            $error("  FAIL ram[0x10]=0x%02h (esperado DD)", dut.ram[32'h10]);

        if (dut.ram[32'h11] === 8'hCC)
            $display("  PASS ram[0x11]=0x%02h (esperado CC)", dut.ram[32'h11]);
        else
            $error("  FAIL ram[0x11]=0x%02h (esperado CC)", dut.ram[32'h11]);

        if (dut.ram[32'h12] === 8'hBB)
            $display("  PASS ram[0x12]=0x%02h (esperado BB)", dut.ram[32'h12]);
        else
            $error("  FAIL ram[0x12]=0x%02h (esperado BB)", dut.ram[32'h12]);

        if (dut.ram[32'h13] === 8'hAA)
            $display("  PASS ram[0x13]=0x%02h (esperado AA - MSB)", dut.ram[32'h13]);
        else
            $error("  FAIL ram[0x13]=0x%02h (esperado AA)", dut.ram[32'h13]);


        // TEST 3: Múltiples direcciones sin interferencia
        $display("\n--- TEST 3: Múltiples direcciones ---");
        test_store_load(32'h00000020, 32'h11111111, "T3-addr20");
        test_store_load(32'h00000024, 32'h22222222, "T3-addr24");
        test_store_load(32'h00000028, 32'h33333333, "T3-addr28");

        // Verificar que addr 0x20 no fue alterada
        mem_read = 1; address = 32'h00000020; #1;
        if (read_data === 32'h11111111)
            $display("  PASS no-interferencia addr=0x20 sigue siendo 0x11111111");
        else
            $error("  FAIL interferencia detectada en addr=0x20, leido=0x%08h", read_data);
        mem_read = 0;

        // TEST 4: Lectura sin escritura previa (desde .mem)
        // program.mem carga 0xDEADBEEF en addr 0x00 (bytes: EF BE AD DE)
        $display("\n--- TEST 4: Datos pre-cargados desde program.mem ---");
        // Nota: este test solo pasa si program.mem está en mem/
        // Si no existe el archivo, ram queda en X y el test falla con warning
        mem_read = 1; address = 32'h00000000; #1;
        $display("  INFO addr=0x00 leido=0x%08h (esperado 0xDEADBEEF si .mem cargado)",
                 read_data);
        mem_read = 0;

        // TEST 5: Valores borde

        $display("\n--- TEST 5: Valores borde ---");
        test_store_load(32'h00000000, 32'hFFFFFFFF, "T5-all-ones");
        test_store_load(32'h00000000, 32'h00000000, "T5-all-zeros");
        test_store_load(32'h0000FFFC, 32'hBEEFCAFE, "T5-max-addr"); // última palabra de 64KB

        $display("\n=== tb_dmem: Pruebas completadas ===\n");
        $finish;
    end

endmodule