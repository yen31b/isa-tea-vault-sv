`timescale 1ns/1ps

module tb_top;

    localparam int INSTR_MEM_SIZE = 1024;
    localparam int PROGRAM_WORDS   = 16;  // indices 0..15
    localparam int TEST_CYCLES     = 15;  // ciclos 0..14 cubren instrucciones 0..14

    logic clk;
    logic reset;

    logic [31:0] pc_out;
    logic [31:0] alu_result_out;
    logic [5:0]  status_flags_out;
    logic        auth_status_out;
    logic        auth_fail_out;
    logic        access_denied_out;
    logic        illegal_access_out;

    logic [31:0] expected_instr [0:INSTR_MEM_SIZE-1];
    logic [31:0] observed_instruction;

    int errors;
    int cycle;
    int idx;

    // Referencia jerarquica a la instruccion que sale de IF dentro de top.
    assign observed_instruction = dut.instruction;

    top #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .PROGRAM_FILE("tb/tb_program.mem")
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

    // Clock 100 MHz equivalente (10 ns periodo)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic check_fetch(input string tag);
        begin
            idx = pc_out[31:2];

            if (pc_out[1:0] != 2'b00) begin
                $display("[ERROR] %s: PC no alineado a palabra: 0x%08h", tag, pc_out);
                errors = errors + 1;
            end

            if (idx < 0 || idx >= PROGRAM_WORDS) begin
                $display("[ERROR] %s: indice fuera de rango idx=%0d pc=0x%08h", tag, idx, pc_out);
                errors = errors + 1;
            end else if (^observed_instruction === 1'bx) begin
                $display("[ERROR] %s: instruccion en X en pc=0x%08h idx=%0d", tag, pc_out, idx);
                errors = errors + 1;
            end else if (observed_instruction !== expected_instr[idx]) begin
                $display("[ERROR] %s: pc=0x%08h idx=%0d esperado=0x%08h obtenido=0x%08h",
                         tag, pc_out, idx, expected_instr[idx], observed_instruction);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: pc=0x%08h instr=0x%08h", tag, pc_out, observed_instruction);
            end
        end
    endtask

    task automatic check_reg(
        input string tag,
        input int reg_idx,
        input logic [31:0] expected
    );
        logic [31:0] got;
        begin
            got = dut.dp.rf.registers[reg_idx];
            if (got !== expected) begin
                $display("[ERROR] %s: r%0d esperado=0x%08h obtenido=0x%08h", tag, reg_idx, expected, got);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: r%0d=0x%08h", tag, reg_idx, got);
            end
        end
    endtask

    task automatic check_mem_word0(
        input string tag,
        input logic [31:0] expected
    );
        logic [31:0] got;
        begin
            got = {dut.dmem.ram[3], dut.dmem.ram[2], dut.dmem.ram[1], dut.dmem.ram[0]};
            if (got !== expected) begin
                $display("[ERROR] %s: MEM[0] esperado=0x%08h obtenido=0x%08h", tag, expected, got);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: MEM[0]=0x%08h", tag, got);
            end
        end
    endtask

    task automatic check_vault_word(
        input string tag,
        input int slot_idx,
        input int word_idx,
        input logic [31:0] expected
    );
        logic [31:0] got;
        begin
            got = dut.vault_inst.vault[slot_idx][word_idx];
            if (got !== expected) begin
                $display("[ERROR] %s: VAULT[%0d][%0d] esperado=0x%08h obtenido=0x%08h",
                         tag, slot_idx, word_idx, expected, got);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: VAULT[%0d][%0d]=0x%08h", tag, slot_idx, word_idx, got);
            end
        end
    endtask

    task automatic check_kreg(
        input string tag,
        input int idx_k,
        input logic [31:0] expected
    );
        logic [31:0] got;
        begin
            got = dut.k_reg[idx_k];
            if (got !== expected) begin
                $display("[ERROR] %s: k_reg[%0d] esperado=0x%08h obtenido=0x%08h",
                         tag, idx_k, expected, got);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: k_reg[%0d]=0x%08h", tag, idx_k, got);
            end
        end
    endtask

    task automatic log_vault_trace(
        input string tag,
        input int slot_idx,
        input int word_idx,
        input logic [31:0] src_value
    );
        logic [31:0] vault_word;
        logic [31:0] k0_word;
        begin
            vault_word = dut.vault_inst.vault[slot_idx][word_idx];
            k0_word    = dut.k_reg[word_idx];
            $display("[TRACE] %s: slot=%0d word=%0d rs1=0x%08h vault=0x%08h k_reg[%0d]=0x%08h auth=%0b denied=%0b",
                     tag, slot_idx, word_idx, src_value, vault_word, word_idx, k0_word,
                     auth_status_out, access_denied_out);
        end
    endtask

    task automatic check_pc(
        input string tag,
        input logic [31:0] expected_pc
    );
        begin
            if (pc_out !== expected_pc) begin
                $display("[ERROR] %s: PC esperado=0x%08h obtenido=0x%08h", tag, expected_pc, pc_out);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: PC=0x%08h", tag, pc_out);
            end
        end
    endtask

    task automatic check_flag_z(
        input string tag,
        input logic expected
    );
        begin
            if (status_flags_out[0] !== expected) begin
                $display("[ERROR] %s: Z esperada=%0b obtenida=%0b", tag, expected, status_flags_out[0]);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: Z=%0b", tag, status_flags_out[0]);
            end
        end
    endtask

    task automatic check_auth(
        input string tag,
        input logic expected
    );
        begin
            if (auth_status_out !== expected) begin
                $display("[ERROR] %s: AUTH esperada=%0b obtenida=%0b", tag, expected, auth_status_out);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: AUTH=%0b", tag, auth_status_out);
            end
        end
    endtask

    task automatic check_auth_fail(
        input string tag,
        input logic expected
    );
        begin
            if (auth_fail_out !== expected) begin
                $display("[ERROR] %s: auth_fail esperada=%0b obtenida=%0b", tag, expected, auth_fail_out);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: auth_fail=%0b", tag, auth_fail_out);
            end
        end
    endtask

    task automatic check_access_denied(
        input string tag,
        input logic expected
    );
        begin
            if (access_denied_out !== expected) begin
                $display("[ERROR] %s: access_denied esperada=%0b obtenida=%0b", tag, expected, access_denied_out);
                errors = errors + 1;
            end else begin
                $display("[ OK ] %s: access_denied=%0b", tag, access_denied_out);
            end
        end
    endtask

    initial begin
        $dumpfile("vcd/tb_top.vcd");
        $dumpvars(0, tb_top);

        // Patrón de referencia para validar IF
        $readmemh("tb/tb_program.mem", expected_instr);

        errors = 0;
        reset  = 1'b1;

        // Mantener reset por 2 ciclos
        repeat (2) @(posedge clk);
        #1;
        check_fetch("reset");

        reset = 1'b0;

        // Verificar fetch y efectos de instrucciones de autenticacion.
        // Ciclos 0..14 cubren instrucciones 0..14 del tb_program.mem
        for (cycle = 0; cycle < TEST_CYCLES; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
            check_fetch($sformatf("cycle_%0d", cycle));

            // Monitor inline: imprime estado de boveda en el mismo ciclo que la instruccion
            if (dut.vault_write) begin
                $display("[MONITOR] VSTR pc=0x%08h slot=%0d word=%0d rs1=0x%08h vault=0x%08h auth=%0b denied=%0b",
                         pc_out, dut.slot, dut.palabra, dut.reg_data_1,
                         dut.vault_inst.vault[dut.slot][dut.palabra],
                         auth_status_out, access_denied_out);
            end
            if (dut.vault_load_secure) begin
                $display("[MONITOR] VLD  pc=0x%08h slot=%0d word=%0d vault=0x%08h k_reg[%0d]=0x%08h auth=%0b denied=%0b",
                         pc_out, dut.slot, dut.palabra,
                         dut.vault_inst.vault[dut.slot][dut.palabra],
                         dut.palabra, dut.k_reg[dut.palabra],
                         auth_status_out, access_denied_out);
            end
            if (dut.vault_clear) begin
                $display("[MONITOR] VCLR pc=0x%08h slot=%0d w0=0x%08h w1=0x%08h w2=0x%08h w3=0x%08h auth=%0b denied=%0b",
                         pc_out, dut.slot,
                         dut.vault_inst.vault[dut.slot][0],
                         dut.vault_inst.vault[dut.slot][1],
                         dut.vault_inst.vault[dut.slot][2],
                         dut.vault_inst.vault[dut.slot][3],
                         auth_status_out, access_denied_out);
            end

            case (cycle)
                // --- Construccion del password 0xA5A5A5A5 ---
                0: check_reg("MOV r0,#0xA5A5", 0, 32'h0000A5A5);
                1: check_reg("MOV r4,#16",     4, 32'd16);
                2: check_reg("SLL r0,r0,r4",   0, 32'hA5A50000);
                3: check_reg("MOV r1,#0xA5A5", 1, 32'h0000A5A5);
                4: check_reg("OR r0,r0,r1 (password)", 0, 32'hA5A5A5A5);

                // --- VAUTH con password correcto ---
                5: begin
                    check_auth("VAUTH r0 correcto -> AUTH=1", 1'b1);
                end

                // --- VSTR con sesion activa ---
                6: begin
                    check_auth("VSTR: sesion activa", 1'b1);
                    check_access_denied("VSTR: sin denegacion", 1'b0);
                    log_vault_trace("VSTR ejecutado", 0, 0, dut.dp.rf.registers[0]);
                    check_vault_word("VSTR guarda password en vault[0][0]", 0, 0, 32'hA5A5A5A5);
                end

                // --- VLD con sesion activa ---
                7: begin
                    check_auth("VLD: sesion activa", 1'b1);
                    check_access_denied("VLD: sin denegacion", 1'b0);
                    log_vault_trace("VLD ejecutado", 0, 0, dut.dp.rf.registers[0]);
                    check_kreg("VLD carga k0 desde vault[0][0]", 0, 32'hA5A5A5A5);
                end

                // --- VLOGOUT ---
                8: begin
                    check_auth("VLOGOUT -> AUTH=0", 1'b0);
                end

                // --- Construccion de password incorrecto ---
                9: check_reg("MOV r2,#0xDEAD", 2, 32'h0000DEAD);

                // --- VAUTH con password incorrecto ---
                10: begin
                    check_auth("VAUTH r2 incorrecto -> AUTH=0", 1'b0);
                    check_auth_fail("VAUTH r2 incorrecto -> auth_fail=1", 1'b1);
                end

                // --- VSTR sin autenticacion -> access denied ---
                11: begin
                    check_access_denied("VSTR sin auth -> access_denied=1", 1'b1);
                    log_vault_trace("VSTR bloqueado por falta de auth", 0, 0, dut.dp.rf.registers[0]);
                    check_vault_word("VSTR sin auth no modifica vault[0][0]", 0, 0, 32'hA5A5A5A5);
                end

                // --- Re-autenticacion con password correcto ---
                12: begin
                    check_auth("VAUTH r0 re-auth -> AUTH=1", 1'b1);
                end

                // --- VCLR con sesion activa ---
                13: begin
                    check_auth("VCLR: sesion activa", 1'b1);
                    check_access_denied("VCLR: sin denegacion", 1'b0);
                    check_vault_word("VCLR borra vault[0][0]", 0, 0, 32'h00000000);
                end

                // --- VLOGOUT final (NOP se esta fetcheando en este ciclo) ---
                14: begin
                    check_auth("VLOGOUT final -> AUTH=0", 1'b0);
                    if (illegal_access_out !== 1'b0) begin
                        $display("[ERROR] NOP activo (pc=0x%08h): illegal_access inesperado=%0b",
                                 pc_out, illegal_access_out);
                        errors = errors + 1;
                    end else begin
                        $display("[ OK ] NOP fetcheado en pc=0x%08h: instr=0x%08h sin illegal_access",
                                 pc_out, observed_instruction);
                    end
                end

                default: begin end
            endcase
        end

        if (errors == 0) begin
            $display("[PASS] tb_top: prueba de autenticacion completada sin errores.");
        end else begin
            $display("[FAIL] tb_top: total de errores = %0d", errors);
        end

        $finish;
    end

endmodule
