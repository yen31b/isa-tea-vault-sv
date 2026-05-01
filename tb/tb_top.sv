`timescale 1ns/1ps

module tb_top;

    localparam int INSTR_MEM_SIZE = 1024;
    localparam int PROGRAM_WORDS   = 16;
    localparam int TEST_CYCLES     = 13;

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
    logic [31:0] expected_sll;

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

    initial begin
        $dumpfile("vcd/tb_top.vcd");
        $dumpvars(0, tb_top);

        // Patrón de referencia para validar IF
        $readmemh("tb/tb_program.mem", expected_instr);

        expected_sll = 32'd19 << 32'd2;
        errors = 0;
        reset  = 1'b1;

        // Mantener reset por 2 ciclos
        repeat (2) @(posedge clk);
        #1;
        check_fetch("reset");

        reset = 1'b0;

        // Verificar fetch y efecto funcional de MOV-imm/BEQ/JMP/CMP/SRL/SLL.
        for (cycle = 0; cycle < TEST_CYCLES; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
            check_fetch($sformatf("cycle_%0d", cycle));

            case (cycle)
                0: check_reg("MOV r3,#19", 3, 32'd19);
                1: check_reg("MOV r4,#2",  4, 32'd2);
                2: check_reg("SLL r5,r3,r4", 5, expected_sll);
                3: check_reg("SRL r6,r5,r4", 6, 32'd19);
                4: check_flag_z("CMP r6,r3 => Z=1", 1'b1);
                5: begin
                    check_pc("BEQ tomado a indice 7", 32'h0000001C);
                    check_reg("BEQ salta MOV r0,r2", 0, 32'd0);
                end
                6: begin
                    check_pc("JMP tomado a indice 9", 32'h00000024);
                    check_reg("JMP salta MOV r7,r1", 7, 32'd0);
                end
                default: begin end
            endcase
        end

        if (errors == 0) begin
            $display("[PASS] tb_top: fetch desde tb/tb_program.mem sin errores.");
        end else begin
            $display("[FAIL] tb_top: total de errores = %0d", errors);
        end

        $finish;
    end

endmodule
