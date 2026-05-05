`timescale 1ns/1ps

module tb_image_flow;

    // Instrucciones maximas de programa (1024 x 32-bit = 4 KB)
    parameter INSTR_MEM_SIZE = 1024;
    // RAM de datos: 64 KB
    parameter DATA_MEM_SIZE  = 65536;
    // Limite de ciclos: 300k es suficiente para 120 bloques TEA x 32 rondas
    // (~80k ciclos utiles) con margen de seguridad.
    parameter TEST_CYCLES    = 300000;
    // AUTH_TIMEOUT grande: evita que la sesion expire durante el loop TEA.
    // Con 120 bloques x ~700 ciclos/bloque ~ 84000 ciclos activos.
    parameter AUTH_TIMEOUT   = 8'd255; // maximo de 8 bits

    logic clk;
    logic reset;

    logic [31:0] pc_out;
    logic [31:0] alu_result_out;
    logic [5:0]  status_flags_out;

    top #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .DATA_MEM_SIZE (DATA_MEM_SIZE),
        .PROGRAM_FILE  ("program.mem"),  // ASM ensamblado
        .DATA_FILE     ("data.mem"),      // Datos del archivo cargado
        .AUTH_TIMEOUT  (AUTH_TIMEOUT)    // Sesion activa durante todo el loop
    ) dut (
        .clk             (clk),
        .reset           (reset),
        .pc_out          (pc_out),
        .alu_result_out  (alu_result_out),
        .status_flags_out(status_flags_out)
    );

    // Reloj: periodo 10 ns (100 MHz)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        int  i;
        bit  halted;

        $dumpfile("vcd/tb_image_flow.vcd");
        $dumpvars(0, tb_image_flow);

        // Reset inicial
        reset = 1'b1;
        repeat (10) @(posedge clk);
        reset = 1'b0;

        $display("[tb_image_flow] Simulacion iniciada (limite=%0d ciclos)", TEST_CYCLES);

        i      = 0;
        halted = 0;

        while (i < TEST_CYCLES && !halted) begin
            @(posedge clk);

            // Mostrar las primeras 100 instrucciones para depuracion
            if (i < 100) begin
                $display("Cycle %0d: PC=0x%04h Instr=0x%08h", i, pc_out, dut.instruction);
            end

            // Detectar HALT: JMP 0  (opcode=3, imm=0) -> 0x18000000
            if (dut.instruction == 32'h18000000) begin
                $display("[HALT] Ciclo %0d  PC=0x%04h", i, pc_out);
                halted = 1;
            end

            // Progreso cada 10 000 ciclos
            if (i % 10000 == 0 && i > 0) begin
                $display("[progress] %0d ciclos  PC=0x%04h", i, pc_out);
            end

            i++;
        end

        if (!halted)
            $display("[TIMEOUT] Limite de %0d ciclos alcanzado sin HALT.", TEST_CYCLES);

        $display("[tb_image_flow] Volcando RAM a data.mem...");
        $writememh("data.mem", dut.dmem.ram);
        $display("[tb_image_flow] Listo.");
        $finish;
    end

endmodule
