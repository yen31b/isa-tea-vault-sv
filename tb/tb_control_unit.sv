//Este testbench sirve para probar automáticamente si el módulo control_unit 
//activa correctamente las señales de control según el opcode, zero_flag y auth_status.


`timescale 1ns/1ps

module tb_control_unit;
    // Entradas del modulo 

    logic [4:0] opcode; //indica qué instrucción se está ejecutando
    logic       zero_flag; //se usa para BEQ y BEQADD
    logic       auth_status; //indica si el procesador está autenticado para usar vault/TEA
    
    //Salidas que se van a revisar
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic       mem_to_reg;
    logic       use_imm;

    logic       branch;
    logic       jump;
    logic       branch_taken;
    logic       flags_write;

    logic       vault_write;
    logic       vault_load_secure;
    logic       vault_clear;
    logic       auth_check;
    logic       auth_clear;

    logic       tea_enable;
    logic       index_inc;
    logic       illegal_access;
    logic       privileged_instr;

    logic [3:0] alu_op;

    int errors; // Sirve para contar cuántas pruebas fallaron.

    // -----------------------------
    // OPCODES
    // -----------------------------
    localparam OP_LD      = 5'b00000;
    localparam OP_ST      = 5'b00001;
    localparam OP_BEQ     = 5'b00010;
    localparam OP_JMP     = 5'b00011;
    localparam OP_ADD     = 5'b00100;
    localparam OP_SUB     = 5'b00101;
    localparam OP_OR      = 5'b00110;
    localparam OP_XOR     = 5'b00111;
    localparam OP_SRL     = 5'b01000;
    localparam OP_SLL     = 5'b01001;
    localparam OP_CMP     = 5'b01010;
    localparam OP_MUL     = 5'b01011;
    localparam OP_MOV     = 5'b01100;
    localparam OP_AND     = 5'b01101;
    localparam OP_VSTR    = 5'b01110;
    localparam OP_VLD     = 5'b01111;
    localparam OP_VCLR    = 5'b10000;
    localparam OP_VAUTH   = 5'b10001;
    localparam OP_VLOGOUT = 5'b10010;
    localparam OP_BEQADD  = 5'b10011;
    localparam OP_XORTEA  = 5'b10100;
    localparam OP_SRLI    = 5'b10101;
    localparam OP_SLLI    = 5'b10110;

    // -----------------------------
    // ALU OPS
    // -----------------------------
    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_OR  = 4'd2;
    localparam ALU_XOR = 4'd3;
    localparam ALU_SRL = 4'd4;
    localparam ALU_SLL = 4'd5;
    localparam ALU_MUL = 4'd6;
    localparam ALU_MOV = 4'd7;
    localparam ALU_AND = 4'd8;

    // -----------------------------
    // Instanciación del módulo bajo prueba
    // -----------------------------
    control_unit dut (
        .opcode(opcode),
        .zero_flag(zero_flag),
        .auth_status(auth_status),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .use_imm(use_imm),

        .branch(branch),
        .jump(jump),
        .branch_taken(branch_taken),
        .flags_write(flags_write),

        .vault_write(vault_write),
        .vault_load_secure(vault_load_secure),
        .vault_clear(vault_clear),
        .auth_check(auth_check),
        .auth_clear(auth_clear),

        .tea_enable(tea_enable),
        .index_inc(index_inc),
        .illegal_access(illegal_access),
        .privileged_instr(privileged_instr),

        .alu_op(alu_op)
    );

    // Funcion que tiene todas las salidas para compararlas fácilmente
    function automatic logic [21:0] get_outputs;
        begin
            get_outputs = {
                reg_write,
                mem_read,
                mem_write,
                mem_to_reg,
                use_imm,

                branch,
                jump,
                branch_taken,
                flags_write,

                vault_write,
                vault_load_secure,
                vault_clear,
                auth_check,
                auth_clear,

                tea_enable,
                index_inc,
                illegal_access,
                privileged_instr,

                alu_op
            };
        end
    endfunction

    // Funcion que sirve para escribir que esperamos de cada instrucción
    function automatic logic [21:0] expected(
        input logic exp_reg_write,
        input logic exp_mem_read,
        input logic exp_mem_write,
        input logic exp_mem_to_reg,
        input logic exp_use_imm,

        input logic exp_branch,
        input logic exp_jump,
        input logic exp_branch_taken,
        input logic exp_flags_write,

        input logic exp_vault_write,
        input logic exp_vault_load_secure,
        input logic exp_vault_clear,
        input logic exp_auth_check,
        input logic exp_auth_clear,

        input logic exp_tea_enable,
        input logic exp_index_inc,
        input logic exp_illegal_access,
        input logic exp_privileged_instr,

        input logic [3:0] exp_alu_op
    );
        begin
            expected = {
                exp_reg_write,
                exp_mem_read,
                exp_mem_write,
                exp_mem_to_reg,
                exp_use_imm,

                exp_branch,
                exp_jump,
                exp_branch_taken,
                exp_flags_write,

                exp_vault_write,
                exp_vault_load_secure,
                exp_vault_clear,
                exp_auth_check,
                exp_auth_clear,

                exp_tea_enable,
                exp_index_inc,
                exp_illegal_access,
                exp_privileged_instr,

                exp_alu_op
            };
        end
    endfunction

    //Funcion que imprime todas las señales actuales, se utiliza solo cuando hay error

    task automatic print_outputs;
        begin
            $display("    reg_write=%b mem_read=%b mem_write=%b mem_to_reg=%b use_imm=%b",
                     reg_write, mem_read, mem_write, mem_to_reg, use_imm);

            $display("    branch=%b jump=%b branch_taken=%b flags_write=%b",
                     branch, jump, branch_taken, flags_write);

            $display("    vault_write=%b vault_load_secure=%b vault_clear=%b auth_check=%b auth_clear=%b",
                     vault_write, vault_load_secure, vault_clear, auth_check, auth_clear);

            $display("    tea_enable=%b index_inc=%b illegal_access=%b privileged_instr=%b alu_op=%0d",
                     tea_enable, index_inc, illegal_access, privileged_instr, alu_op);
        end
    endtask

    task automatic check_control(
        //Entradas que recibe 
        input string name, //nombre de la prueba
        input logic [4:0] op_i, //opcode que queremos probar
        input logic zero_i, //valor de zero_flag
        input logic auth_i, //valor de auth_status
        input logic [21:0] expected_outputs //salidas esperadas
    );
        logic [21:0] actual_outputs;
        begin
            //Se asignan las entradas
            opcode = op_i;
            zero_flag = zero_i;
            auth_status = auth_i;

            #1; // Espera de 1ns

            actual_outputs = get_outputs(); //Luego se obtienen las salidas reales:

            if (actual_outputs !== expected_outputs) begin  //Si las salidas reales son iguales a las esperadas, imprime [OK].
                $display("[ERROR] %s", name); 
                $display("    opcode=%b zero_flag=%b auth_status=%b", op_i, zero_i, auth_i);
                $display("    esperado=%b", expected_outputs);
                $display("    obtenido=%b", actual_outputs);
                print_outputs();
                errors++;
            end
            else begin //Si no, imprime [ERROR] y suma un error.
                $display("[OK] %s opcode=%b zero=%b auth=%b", name, op_i, zero_i, auth_i);
            end
        end
    endtask

    initial begin
        $dumpfile("control_unit.vcd"); //Primero genera el archivo para GTKWave:
        $dumpvars(0, tb_control_unit);

        errors = 0; //inicializa errores:

        $display("Iniciando pruebas de control_unit..."); //Empieza a llamar pruebas con check_control.

        // Orden del vector esperado:
        // reg_write, mem_read, mem_write, mem_to_reg, use_imm,
        // branch, jump, branch_taken, flags_write,
        // vault_write, vault_load_secure, vault_clear, auth_check, auth_clear,
        // tea_enable, index_inc, illegal_access, privileged_instr,
        // alu_op

        // -----------------------------
        // Memoria
        // -----------------------------
        check_control("LD",
            OP_LD, 1'b0, 1'b0,
            expected(
                1, 1, 0, 1, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_ADD
            )
        );

        check_control("ST",
            OP_ST, 1'b0, 1'b0,
            expected(
                0, 0, 1, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_ADD
            )
        );

        // -----------------------------
        // Branch y jump
        // -----------------------------
        check_control("BEQ no tomado",
            OP_BEQ, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                1, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_SUB
            )
        );

        check_control("BEQ tomado",
            OP_BEQ, 1'b1, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                1, 0, 1, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_SUB
            )
        );

        check_control("JMP",
            OP_JMP, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_ADD
            )
        );

        // -----------------------------
        // ALU tipo R
        // -----------------------------
        check_control("ADD",
            OP_ADD, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_ADD
            )
        );

        check_control("SUB",
            OP_SUB, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_SUB
            )
        );

        check_control("OR",
            OP_OR, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_OR
            )
        );

        check_control("XOR",
            OP_XOR, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_XOR
            )
        );

        check_control("SRL",
            OP_SRL, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_SRL
            )
        );

        check_control("SLL",
            OP_SLL, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_SLL
            )
        );

        check_control("CMP",
            OP_CMP, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 1,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_SUB
            )
        );

        check_control("MUL",
            OP_MUL, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_MUL
            )
        );

        check_control("MOV",
            OP_MOV, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_MOV
            )
        );

        check_control("AND",
            OP_AND, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                ALU_AND
            )
        );

        // -----------------------------
        // Autenticación
        // -----------------------------
        check_control("VAUTH",
            OP_VAUTH, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 1, 0,
                0, 0, 0, 0,
                ALU_ADD
            )
        );

        check_control("VLOGOUT",
            OP_VLOGOUT, 1'b0, 1'b1,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 1,
                0, 0, 0, 0,
                ALU_ADD
            )
        );

        // -----------------------------
        // Vault autenticado
        // -----------------------------
        check_control("VSTR autenticado",
            OP_VSTR, 1'b0, 1'b1,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                1, 0, 0, 0, 0,
                0, 0, 0, 1,
                ALU_ADD
            )
        );

        check_control("VLD autenticado",
            OP_VLD, 1'b0, 1'b1,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 0, 1,
                ALU_ADD
            )
        );

        check_control("VCLR autenticado",
            OP_VCLR, 1'b0, 1'b1,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 1, 0, 0,
                0, 0, 0, 1,
                ALU_ADD
            )
        );

        // -----------------------------
        // Vault sin autenticación
        // -----------------------------
        check_control("VSTR sin autenticacion",
            OP_VSTR, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 1, 1,
                ALU_ADD
            )
        );

        check_control("VLD sin autenticacion",
            OP_VLD, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 1, 1,
                ALU_ADD
            )
        );

        check_control("VCLR sin autenticacion",
            OP_VCLR, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 1, 1,
                ALU_ADD
            )
        );

        // -----------------------------
        // TEA y BEQADD
        // -----------------------------
        check_control("BEQADD autenticado zero=1",
            OP_BEQADD, 1'b1, 1'b1,
            expected(
                0, 0, 0, 0, 0,
                1, 0, 1, 0,
                0, 0, 0, 0, 0,
                0, 1, 0, 1,
                ALU_SUB
            )
        );

        check_control("BEQADD autenticado zero=0",
            OP_BEQADD, 1'b0, 1'b1,
            expected(
                0, 0, 0, 0, 0,
                1, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 1, 0, 1,
                ALU_SUB
            )
        );

        check_control("BEQADD sin autenticacion",
            OP_BEQADD, 1'b1, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 1, 1,
                ALU_ADD
            )
        );

        check_control("XORTEA autenticado",
            OP_XORTEA, 1'b0, 1'b1,
            expected(
                1, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                1, 0, 0, 1,
                ALU_ADD
            )
        );

        check_control("XORTEA sin autenticacion",
            OP_XORTEA, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 1, 1,
                ALU_ADD
            )
        );

        // -----------------------------
        // Desplazamientos con inmediato
        // Nota: aquí se espera privileged_instr=1 porque así está en tu código actual.
        // -----------------------------
        check_control("SRLI",
            OP_SRLI, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 1,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 1,
                ALU_SRL
            )
        );

        check_control("SLLI",
            OP_SLLI, 1'b0, 1'b0,
            expected(
                1, 0, 0, 0, 1,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 1,
                ALU_SLL
            )
        );

        // -----------------------------
        // Opcode ilegal
        // -----------------------------
        check_control("Opcode no definido",
            5'b11111, 1'b0, 1'b0,
            expected(
                0, 0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 1, 0,
                ALU_ADD
            )
        );

        if (errors == 0) begin
            $display("TODAS LAS PRUEBAS DE CONTROL_UNIT PASARON."); //Si salio correcto, la terminal muestra el mensaje.
        end
        else begin
            $display("PRUEBAS FALLIDAS. Total de errores: %0d", errors); //Si no entonces hay prueba fallida. 
        end

        $finish;
    end

endmodule

// Para compilar este archivo: iverilog.exe -g2012 -o control_sim.vvp control_unit.sv tb_control_unit.sv
// Para ver las señales: vvp.exe control_sim.vvp
//                       gtkwave.exe control_unit.vcd