`timescale 1ns/1ps

module tb_instruction_fetch;

    logic clk;
    logic reset;

    logic branch_taken;
    logic jump;
    logic [31:0] branch_target;
    logic [31:0] jump_target;

    logic [31:0] pc;
    logic [31:0] instruction;

    int errors;  //Sirve para contar cuántas pruebas fallaron.

    // Instancia del módulo bajo prueba
    instruction_fetch #(
        .INSTR_MEM_SIZE(16), // Tamaño de la memoria de instrucciones
        .PROGRAM_FILE("tb_program.mem")
    ) dut (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .jump(jump),
        .branch_target(branch_target),
        .jump_target(jump_target),
        .pc(pc),
        .instruction(instruction)
    );

    // Generador de reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Tarea para revisar PC e instrucción
    task automatic check_state(
        input string name,  // nombre de la prueba 
        input logic [31:0] expected_pc, // PC esperado
        input logic [31:0] expected_instruction // Intruccion esperada
    );
        begin
            #1; //espera 1 ns antes de revisar

            if (pc !== expected_pc) begin
                $display("\033[31m[ERROR]\033[0m %s: PC esperado=0x%08h, obtenido=0x%08h", // Si el PC actual no es igual al PC esperado,
                         name, expected_pc, pc);                            // imprime error y aumenta el contador de errores.
                errors++;
            end

            if (instruction !== expected_instruction) begin
                $display("\033[31m[ERROR]\033[0m %s: instruccion esperada=0x%08h, obtenida=0x%08h", // Si la instrucción actual no coincide con la esperada,
                         name, expected_instruction, instruction);                  // imprime error y aumenta errors.
                errors++;
            end

            if ((pc === expected_pc) && (instruction === expected_instruction)) begin
                $display("\033[32m[OK]\033[0m %s: PC=0x%08h instruction=0x%08h", //Este mensaje confirma que tanto el pc como la instrucción fueron correctos.
                         name, pc, instruction);
            end
        end
    endtask

    initial begin
        $dumpfile("instruction_fetch.vcd"); //Este archivo guarda las ondas de simulación para verlas en GTKWave.
        $dumpvars(0, tb_instruction_fetch);


    // Inicializacion de valores antes de empezar la prueba
        errors = 0;

        branch_taken = 0;
        jump = 0;
        branch_target = 32'd0;
        jump_target = 32'd0;

        $display("\033[36mIniciando pruebas de instruction_fetch...\033[0m");

        // -----------------------------
        // TEST 1: Reset
        // -----------------------------
        reset = 1;
        @(posedge clk);
        check_state("RESET lleva PC a 0", 32'd0, 32'h23280000);

        reset = 0;

        // -----------------------------
        // TEST 2: Avance secuencial
        // -----------------------------
        @(posedge clk);
        check_state("PC avanza a 4", 32'd4, 32'hac400019);

        @(posedge clk);
        check_state("PC avanza a 8", 32'd8, 32'h05c00064);

        @(posedge clk);
        check_state("PC avanza a 12", 32'd12, 32'h11e0002c);

        // -----------------------------
        // TEST 3: Branch tomado
        // branch_target = 20
        // pc[31:2] = 20 / 4 = 5
        // instruccion esperada = instr_mem[5]
        // -----------------------------
        branch_taken = 1;
        branch_target = 32'd20;
        jump = 0;

        @(posedge clk);
        check_state("Branch tomado hacia PC=20", 32'd20, 32'h7234000c);

        branch_taken = 0;

        // -----------------------------
        // TEST 4: Luego del branch, sigue secuencial
        // PC pasa de 20 a 24
        // instr_mem[6] = a14e000a
        // -----------------------------
        @(posedge clk);
        check_state("Despues del branch avanza a PC=24", 32'd24, 32'ha14e000a);

        // -----------------------------
        // TEST 5: Jump incondicional
        // jump_target = 28
        // pc[31:2] = 28 / 4 = 7
        // instr_mem[7] = a14e7fff
        // -----------------------------
        jump = 1;
        jump_target = 32'd28;
        branch_taken = 0;

        @(posedge clk);
        check_state("Jump hacia PC=28", 32'd28, 32'ha14e7fff);

        jump = 0;

        // -----------------------------
        // TEST 6: Jump tiene prioridad sobre branch
        // branch_target = 8
        // jump_target = 32
        // Debe ir a 32, no a 8
        // pc[31:2] = 32 / 4 = 8
        // instr_mem[8] = f8000000
        // -----------------------------
        branch_taken = 1;
        branch_target = 32'd8;

        jump = 1;
        jump_target = 32'd32;

        @(posedge clk);
        check_state("Jump tiene prioridad sobre branch", 32'd32, 32'hf8000000);

        branch_taken = 0;
        jump = 0;

        // -----------------------------
        // TEST 7: Reset tiene prioridad
        // -----------------------------
        reset = 1;
        branch_taken = 1;
        branch_target = 32'd20;
        jump = 1;
        jump_target = 32'd28;

        @(posedge clk);
        check_state("Reset tiene prioridad sobre jump y branch", 32'd0, 32'h23280000);

        reset = 0;
        branch_taken = 0;
        jump = 0;

        // -----------------------------
        // Resultado final
        // -----------------------------
        if (errors == 0) begin
            $display("\033[32mTODAS LAS PRUEBAS DE FETCH PASARON.\033[0m");
        end
        else begin
            $display("\033[31mPRUEBAS FALLIDAS. Total de errores: %0d\033[0m", errors);
        end

        $finish;
    end

endmodule