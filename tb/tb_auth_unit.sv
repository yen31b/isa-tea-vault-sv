//Casos de prueba:
//   1. Reset valores en 0
//   2. VAUTH con password correcto: auth_status=1, timer=64
//   3. VAUTH con password incorrecto: auth_fail=1, auth_status=0
//   4. VLOGOUT: auth_status=0, timer=0
//   5. Instrucción privilegiada con auth=1: reinicia timer
//   6. Instrucción privilegiada sin auth: access_denied=1
//   7. Timer countdown: auto-logout al llegar a 0
//   8. Timer se reinicia con instrucción privilegiada antes de expirar

`timescale 1ns/1ps

module tb_auth_unit;

    // ---- Señales ----
    logic        clk, reset;
    logic        auth_check, auth_clear, privileged_instr;
    logic [31:0] auth_value;
    logic        auth_status, auth_fail, access_denied;
    logic [7:0]  auth_timer;

    // ---- Instancia ----
    auth_unit #(
        .SECRET       (32'hA5A5A5A5),
        .AUTH_TIMEOUT (8'd64)
    ) dut (
        .clk              (clk),
        .reset            (reset),
        .auth_check       (auth_check),
        .auth_clear       (auth_clear),
        .privileged_instr (privileged_instr),
        .auth_value       (auth_value),
        .auth_status      (auth_status),
        .auth_fail        (auth_fail),
        .access_denied    (access_denied),
        .auth_timer       (auth_timer)
    );

    // ---- Clock ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Tarea: avanzar N ciclos sin señales activas ----
    task automatic ciclos(input int n);
        repeat(n) @(posedge clk); #1;
    endtask

    // ---- Tarea: check genérico ----
    task automatic check(input logic signal, input logic esperado, input string label);
        if (signal === esperado)
            $display("\033[32m    [PASS]\033[0m %s = %b", label, signal);
        else
            $display("\033[31m    [FAIL]\033[0m %s = %b (esperado %b)", label, signal, esperado);
    endtask

    task automatic check_val(input logic [7:0] val, input logic [7:0] esperado, input string label);
        if (val === esperado)
            $display("\033[32m    [PASS]\033[0m %s = %0d", label, val);
        else
            $display("\033[31m    [FAIL]\033[0m %s = %0d (esperado %0d)", label, val, esperado);
    endtask

    initial begin
        $dumpfile("vcd/tb_auth_unit.vcd");
        $dumpvars(0, tb_auth_unit);

        // Inicializar señales
        reset            = 1;
        auth_check       = 0;
        auth_clear       = 0;
        privileged_instr = 0;
        auth_value       = 32'b0;

        $display("\n\033[36m=== tb_auth_unit: Iniciando pruebas ===\033[0m\n");

        // --------------------------------------------------
        // TEST 1: Reset
        // --------------------------------------------------
        $display("\033[36m----TEST 1: Reset----\033[0m");
        ciclos(2);
        reset = 0;
        @(posedge clk); #1;

        check(auth_status,  1'b0, "auth_status=0");
        check(auth_fail,    1'b0, "auth_fail=0");
        check(access_denied,1'b0, "access_denied=0");
        check_val(auth_timer, 8'd0, "auth_timer=0");

        // --------------------------------------------------
        // TEST 2: VAUTH con password correcto
        // --------------------------------------------------
        $display("\n\033[36m----TEST 2: VAUTH password correcto----\033[0m");
        auth_value  = 32'hA5A5A5A5; // SECRET correcto
        auth_check  = 1;
        @(posedge clk); #1;
        auth_check  = 0;

        check(auth_status,  1'b1,  "auth_status=1");
        check(auth_fail,    1'b0,  "auth_fail=0");
        check_val(auth_timer, 8'd64, "auth_timer=64");

        // --------------------------------------------------
        // TEST 3: VAUTH con password incorrecto
        // Primero logout para limpiar sesión
        // --------------------------------------------------
        $display("\n\033[36m----TEST 3: VAUTH password incorrecto----\033[0m");
        auth_clear = 1;
        @(posedge clk); #1;
        auth_clear = 0;

        auth_value = 32'hDEADBEEF; // password incorrecto
        auth_check = 1;
        @(posedge clk); #1;
        auth_check = 0;

        check(auth_status,  1'b0, "auth_status=0");
        check(auth_fail,    1'b1, "auth_fail=1");
        check_val(auth_timer, 8'd0, "auth_timer=0");

        // Verificar que auth_fail se limpia al ciclo siguiente
        @(posedge clk); #1;
        check(auth_fail, 1'b0, "auth_fail se limpia solo");

        // --------------------------------------------------
        // TEST 4: VLOGOUT cierra sesión
        // --------------------------------------------------
        $display("\n\033[36m----TEST 4: VLOGOUT----\033[0m");
        // Primero autenticarse
        auth_value = 32'hA5A5A5A5;
        auth_check = 1;
        @(posedge clk); #1;
        auth_check = 0;
        check(auth_status, 1'b1, "auth_status=1 antes de logout");

        // Ahora logout
        auth_clear = 1;
        @(posedge clk); #1;
        auth_clear = 0;

        check(auth_status,   1'b0, "auth_status=0 tras VLOGOUT");
        check_val(auth_timer, 8'd0, "auth_timer=0 tras VLOGOUT");

        // --------------------------------------------------
        // TEST 5: Instrucción privilegiada con auth=1
        // Timer debe reiniciarse a 64
        // --------------------------------------------------
        $display("\n\033[36m----TEST 5: Instrucción privilegiada con auth=1----\033[0m");
        // Autenticarse
        auth_value = 32'hA5A5A5A5;
        auth_check = 1;
        @(posedge clk); #1;
        auth_check = 0;

        // Dejar pasar algunos ciclos para que baje el timer
        ciclos(5);
        $display("    INFO timer tras 5 ciclos = %0d", auth_timer);

        // Ejecutar instrucción privilegiada — timer debe volver a 64
        privileged_instr = 1;
        @(posedge clk); #1;
        privileged_instr = 0;

        check(auth_status,   1'b1,  "auth_status sigue en 1");
        check_val(auth_timer, 8'd64, "auth_timer reiniciado a 64");
        check(access_denied, 1'b0,  "access_denied=0");

        // --------------------------------------------------
        // TEST 6: Instrucción privilegiada SIN auth → access_denied
        // --------------------------------------------------
        $display("\n\033[36m----TEST 6: Instrucción privilegiada sin autenticación----\033[0m");
        // Cerrar sesión primero
        auth_clear = 1;
        @(posedge clk); #1;
        auth_clear = 0;
        check(auth_status, 1'b0, "sin auth antes del test");

        // Intentar instrucción privilegiada
        privileged_instr = 1;
        @(posedge clk); #1;
        privileged_instr = 0;

        check(access_denied, 1'b1, "access_denied=1");
        check(auth_status,   1'b0, "auth_status sigue en 0");

        // Verificar que access_denied se limpia al ciclo siguiente
        @(posedge clk); #1;
        check(access_denied, 1'b0, "access_denied se limpia solo");

        // --------------------------------------------------
        // TEST 7: Timer countdown → auto-logout
        // Usar AUTH_TIMEOUT pequeño para no esperar 64 ciclos
        // Se instancia con timeout=64 pero probamos conteo bajando manualmente
        // --------------------------------------------------
        $display("\n\033[36m----TEST 7: Auto-logout por timeout----\033[0m");
        // Autenticarse
        auth_value = 32'hA5A5A5A5;
        auth_check = 1;
        @(posedge clk); #1;
        auth_check = 0;
        check_val(auth_timer, 8'd64, "timer inicia en 64");

        // Esperar 63 ciclos sin hacer nada — timer debe llegar a 1
        ciclos(63);
        $display("    INFO timer tras 63 ciclos = %0d (esperado 1)", auth_timer);
        check(auth_status, 1'b1, "auth_status sigue en 1 (timer=1)");

        // Un ciclo más → auto-logout
        ciclos(1);
        $display("    INFO timer tras 64 ciclos = %0d (esperado 0)", auth_timer);
        check(auth_status,   1'b0, "auth_status=0 (auto-logout)");
        check_val(auth_timer, 8'd0, "auth_timer=0 tras auto-logout");

        // --------------------------------------------------
        // TEST 8: Timer se reinicia con instrucción privilegiada
        // antes de que expire
        // --------------------------------------------------
        $display("\n\033[36m----TEST 8: Timer reiniciado antes de expirar sesion----\033[0m");
        // Autenticarse
        auth_value = 32'hA5A5A5A5;
        auth_check = 1;
        @(posedge clk); #1;
        auth_check = 0;

        // Esperar 60 ciclos — timer en 4
        ciclos(60);
        $display("    INFO timer tras 60 ciclos = %0d (esperado ~4)", auth_timer);

        // Instrucción privilegiada antes de que expire lo que hace es reiniciar el timer
        privileged_instr = 1;
        @(posedge clk); #1;
        privileged_instr = 0;

        check_val(auth_timer, 8'd64, "timer reiniciado a 64 antes de expirar");
        check(auth_status,    1'b1,  "auth_status en 1");

        $finish;
    end

endmodule