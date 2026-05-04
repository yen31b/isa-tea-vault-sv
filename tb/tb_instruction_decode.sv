`timescale 1ns/1ps

module tb_instruction_decode;

    // Entrada al DUT
    logic [31:0] instruction; //variable que el testbench va cambiando para probar distintas instrucciones

    // Salidas del DUT que queremos probar 
    logic [4:0]  opcode;
    logic [4:0]  rd;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rs3;
    logic [20:0] imm;
    logic [2:0]  format_type;
    logic [2:0]  slot;
    logic [2:0]  palabra;
    logic [17:0] reservado;

    // Constantes de formato, iguales a las del decoder
    localparam FORMAT_R = 3'b000;
    localparam FORMAT_I = 3'b001;
    localparam FORMAT_M = 3'b010;
    localparam FORMAT_J = 3'b011;
    localparam FORMAT_K = 3'b100;
    localparam FORMAT_T = 3'b101;

    int errors = 0; //sirve para contar cuantas pruebas fallan

    // Instancia del módulo que se va a probar
    instruction_decode dut (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .rs3(rs3),
        .imm(imm),
        .format_type(format_type),
        .slot(slot),
        .palabra(palabra),
        .reservado(reservado)
    );

    // -------------------------
    // Funciones para codificar instrucciones
    // -------------------------

    function automatic logic [31:0] encR(
        input logic [4:0] op,
        input logic [2:0] rd_i,
        input logic [2:0] rs1_i,
        input logic [2:0] rs2_i
    );
        encR = {op, rd_i, rs1_i, rs2_i, 18'b0};
    endfunction

    function automatic logic [31:0] encI(
        input logic [4:0] op,
        input logic [2:0] rd_i,
        input logic [2:0] rs1_i,
        input logic [20:0] imm_i
    );
        encI = {op, rd_i, rs1_i, imm_i};
    endfunction

    function automatic logic [31:0] encM(
        input logic [4:0] op,
        input logic [2:0] rd_i,
        input logic [2:0] rs1_i,
        input logic [20:0] imm_i
    );
        encM = {op, rd_i, rs1_i, imm_i};
    endfunction

    function automatic logic [31:0] encJ(
        input logic [4:0] op,
        input logic [2:0] rs1_i,
        input logic [2:0] rs2_i,
        input logic [20:0] imm_i
    );
        encJ = {op, rs1_i, rs2_i, imm_i};
    endfunction

// [17:0]  ceros
    function automatic logic [31:0] encK(
        input logic [4:0] op,
        input logic [2:0] slot_i,
        input logic [2:0] palabra_i,
        input logic [2:0] rs1_i,
        input logic [17:0] reservado_i
    );
        encK = {op, slot_i, palabra_i, rs1_i, reservado_i};
    endfunction



    function automatic logic [31:0] encT(
        input logic [4:0] op,
        input logic [2:0] rd_i,
        input logic [2:0] rs1_i,
        input logic [2:0] rs2_i,
        input logic [2:0] rs3_i,
        input logic [14:0] imm15_i
    );
        encT = {op, rd_i, rs1_i, rs2_i, rs3_i, imm15_i};
    endfunction

    // -------------------------
    // Tarea para comparar salidas
    // -------------------------

    task automatic check_decode(
        input string name,
        input logic [31:0] instr_i, // recibe la instruccion que vamos a probar
        input logic [4:0]  exp_opcode, //valores que esperamos salgan del decoder
        input logic [4:0]  exp_rd,
        input logic [4:0]  exp_rs1,
        input logic [4:0]  exp_rs2,
        input logic [4:0]  exp_rs3,
        input logic [20:0] exp_imm,
        input logic [2:0]  exp_format_type,
        input logic [2:0]  exp_slot,
        input logic [2:0]  exp_palabra,
        input logic [17:0] exp_reservado
    );
        int before_errors;
        begin
            before_errors = errors;
            instruction = instr_i; //Le damos una instrucción al decoder y esperamos 1 ns para que actualice sus salidas.
            #1; // Espera para que always_comb actualice las salidas

            if (opcode !== exp_opcode) begin //Si el opcode real no es igual al esperado, imprime error y suma 1 al contador de errores.
                $display("\033[31m[ERROR]\033[0m %s opcode esperado=%b obtenido=%b", name, exp_opcode, opcode);
                errors++;
            end

            if (rd !== exp_rd) begin
                $display("\033[31m[ERROR]\033[0m %s rd esperado=%b obtenido=%b", name, exp_rd, rd);
                errors++;
            end

            if (rs1 !== exp_rs1) begin
                $display("\033[31m[ERROR]\033[0m %s rs1 esperado=%b obtenido=%b", name, exp_rs1, rs1);
                errors++;
            end

            if (rs2 !== exp_rs2) begin
                $display("\033[31m[ERROR]\033[0m %s rs2 esperado=%b obtenido=%b", name, exp_rs2, rs2);
                errors++;
            end

            if (rs3 !== exp_rs3) begin
                $display("\033[31m[ERROR]\033[0m %s rs3 esperado=%b obtenido=%b", name, exp_rs3, rs3);
                errors++;
            end

            if (imm !== exp_imm) begin
                $display("\033[31m[ERROR]\033[0m %s imm esperado=%b obtenido=%b", name, exp_imm, imm);
                errors++;
            end

            if (format_type !== exp_format_type) begin
                $display("\033[31m[ERROR]\033[0m %s format_type esperado=%b obtenido=%b", name, exp_format_type, format_type);
                errors++;
            end

            if (slot !== exp_slot) begin
                $display("\033[31m[ERROR]\033[0m %s slot esperado=%b obtenido=%b", name, exp_slot, slot);
                errors++;
            end

            if (palabra !== exp_palabra) begin
                $display("\033[31m[ERROR]\033[0m %s palabra esperado=%b obtenido=%b", name, exp_palabra, palabra);
                errors++;
            end

            if (reservado !== exp_reservado) begin
                $display("\033[31m[ERROR]\033[0m %s reservado esperado=%b obtenido=%b", name, exp_reservado, reservado);
                errors++;
            end

            if (errors == before_errors) begin
                $display("\033[32m[OK]\033[0m %s instr=0x%08h", name, instr_i);
            end
        end
    endtask

    initial begin
        $dumpfile("instruction_decode.vcd"); //Primero  se genera el archivo para GTKWave:
        $dumpvars(0, tb_instruction_decode);

        $display("\033[36mIniciando pruebas de instruction_decode...\033[0m");

        // Formato R: ADD opcode=00100, rd=3, rs1=1, rs2=2
        check_decode(
            "ADD formato R",
            encR(5'b00100, 3'd3, 3'd1, 3'd2),        // opcode = 00100
            5'b00100, 3'd3, 3'd1, 3'd2, 3'd0, 21'd0, // rd =3
            FORMAT_R, 3'd0, 3'd0, 18'd0              // rs1 = 1
        );                                           // rs2 = 2
                                                    //esperamos el decoder saque estos mismos valores 
        // Formato I: SRLI opcode=10101, rd=4, rs1=2, imm=25
        check_decode(
            "SRLI formato I",                         //opcode = 10101
            encI(5'b10101, 3'd4, 3'd2, 21'd25),       // rd = 4
            5'b10101, 3'd4, 3'd2, 3'd0, 3'd0, 21'd25, // rs1 = 2
            FORMAT_I, 3'd0, 3'd0, 18'd0               // imm = 25
        );                                            // format = FORMAT_I

        // Formato M: LD opcode=00000, rd=5, rs1=6, imm=100
        check_decode(
            "LD formato M",                            // opcode = 00000
            encM(5'b00000, 3'd5, 3'd6, 21'd100),       // rd = 5
            5'b00000, 3'd5, 3'd6, 3'd0, 3'd0, 21'd100, // rs1 = 6
            FORMAT_M, 3'd0, 3'd0, 18'd0                // imm = 100
        );

        // Formato J: BEQ opcode=00010, rs1=1, rs2=7, imm=44
        check_decode(
            "BEQ formato J",                          // opcode = 00010
            encJ(5'b00010, 3'd1, 3'd7, 21'd44),       // rs1 = 1 
            5'b00010, 3'd0, 3'd1, 3'd7, 3'd0, 21'd44, // rs2 = 7
            FORMAT_J, 3'd0, 3'd0, 18'd0               //imm = 44
        );

        // Formato K: VAUTH opcode=10001, slot=0, palabra=0, rs1=3, reservado=0
        check_decode(
            "VAUTH formato K",                       // opcode = 10001
            encK(5'b10001, 3'd0, 3'd0, 3'd3, 18'd0), // slot = 0
            5'b10001, 3'd0, 3'd3, 3'd0, 3'd0, 21'd0, // palabra = 0
            FORMAT_K, 3'd0, 3'd0, 18'd0              // rs1 = 3
        );                                           // reservado = 0
                                                  
        // Formato K: VSTR opcode=01110, slot=2, palabra=1, rs1=5, reservado=12
        check_decode(
            "VSTR formato K",                         // opcode = 01110
            encK(5'b01110, 3'd2, 3'd1, 3'd5, 18'd12), // slot = 2
            5'b01110, 3'd0, 3'd5, 3'd0, 3'd0, 21'd0,  // palabra = 1
            FORMAT_K, 3'd2, 3'd1, 18'd12              // rs1 = 5
        );                                            // reservado = 12

        // Formato T: XORTEA opcode=10100, rd=1, rs1=2, rs2=3, rs3=4, imm15=10 positivo
        check_decode(
            "XORTEA formato T imm positivo",                 // opcode = 10100
            encT(5'b10100, 3'd1, 3'd2, 3'd3, 3'd4, 15'd10),  // rd = 1
            5'b10100, 3'd1, 3'd2, 3'd3, 3'd4, 21'd10,        // rs1 = 2
            FORMAT_T, 3'd0, 3'd0, 18'd0                      // rs2 = 3
        );                                                   // rs3 = 4
                                                             // imm = 10
        // Formato T con inmediato negativo: imm15 = 15'b111111111111111 debe extenderse a 21 bits con unos
        check_decode(
            "XORTEA formato T imm negativo",                 //opcode = 
            encT(5'b10100, 3'd1, 3'd2, 3'd3, 3'd4, 15'h7FFF),
            5'b10100, 3'd1, 3'd2, 3'd3, 3'd4, 21'h1FFFFF,
            FORMAT_T, 3'd0, 3'd0, 18'd0
        );

        // Opcode no reconocido: debe caer en default, formato R y campos en cero excepto opcode
        check_decode(
            "Opcode desconocido", // format_type = FORMAT_R, campos vacios  = 0, opcode = 11111 
            {5'b11111, 27'd0},
            5'b11111, 3'd0, 3'd0, 3'd0, 3'd0, 21'd0,
            FORMAT_R, 3'd0, 3'd0, 18'd0
        );

        if (errors == 0) begin
            $display("\033[32mTODAS LAS PRUEBAS PASARON.\033[0m");
        end else begin
            $display("\033[31mPRUEBAS FALLIDAS. Total de errores: %0d\033[0m", errors);
        end

        $finish;
    end

endmodule