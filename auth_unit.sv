module auth_unit #(
    parameter SECRET        = 32'hA5A5A5A5, //Es la contraseña interna del procesador.
    parameter AUTH_TIMEOUT  = 8'd64 //Define cuántos ciclos dura la autenticación antes de expirar.
)(
    input  logic        clk, //clk es el reloj.
    input  logic        reset, //reset reinicia el módulo.

    input  logic        auth_check,       // viene de VAUTH, revisa si el valor ingresado es correcto
    input  logic        auth_clear,       // viene de VLOGOUT, y es para cerrar la sesion
    input  logic        privileged_instr, // VSTR, VLD, VCLR, XORTEA, BEQADD...
    input  logic [31:0] auth_value,       // valor que viene del registro usando en VAUTH (rs1)

    output logic        auth_status, //Es el bit que dice si el procesador está autenticado.
    output logic        auth_fail, //Se activa cuando VAUTH falla.
    output logic        access_denied, //Se activa cuando alguien intenta ejecutar una instrucción privilegiada sin estar autenticado.
    output logic [7:0]  auth_timer //Es el contador interno, cuenta cuántos ciclos faltan antes de que expire la autenticación.
);

    always_ff @(posedge clk or posedge reset) begin // Este bloque se ejecuta en cada flanco positivo del reloj o cuando se activa reset.
        if (reset) begin
            auth_status  <= 1'b0; //pone los valores en cero
            auth_timer   <= 8'd0;
            auth_fail    <= 1'b0;
            access_denied <= 1'b0;
        end

        else begin //Si no hay reset, el módulo trabaja normalmente.
            auth_fail     <= 1'b0; //Estas señales se limpian en cada ciclo.
            access_denied <= 1'b0;

            // VLOGOUT
            if (auth_clear) begin //Si se ejecuta VLOGOUT: cierra sesion inmediatamente
                auth_status <= 1'b0; 
                auth_timer  <= 8'd0;
            end

            // VAUTH //Si se ejecuta VAUTH, entra aquí.
            else if (auth_check) begin
                if (auth_value == SECRET) begin //Compara el valor del registro con la contraseña interna.
                    auth_status <= 1'b1; //Si la contraseña es correcta: AUTH = 1 Y timer = 64
                    auth_timer  <= AUTH_TIMEOUT;
                end
                else begin
                    auth_status <= 1'b0; //Si la contraseña es incorrecta:AUTH = 0, timer = 0, auth_fail = 1
                    auth_timer  <= 8'd0;
                    auth_fail   <= 1'b1;
                end
            end

            // Instrucción privilegiada
            else if (privileged_instr) begin //Entra aquí si se ejecuta una instrucción protegida.
                if (auth_status) begin
                    auth_timer <= AUTH_TIMEOUT; //Si ya estaba autenticado, permite la operación y reinicia el timer.
																//Esto perimte que se aplique si sigo usando bóveda/TEA, la sesión se mantiene activa
                end
                else begin //Si no estaba autenticado:
                    access_denied <= 1'b1; //Indica error de acceso
                end
            end

            // Conteo normal del timer
            else if (auth_status) begin //Si no hubo VAUTH, ni VLOGOUT, ni instrucción privilegiada, pero sigo autenticado, entonces el timer baja.
                if (auth_timer > 8'd1) begin //Si todavía queda tiempo, resta 1 ciclo.
                    auth_timer <= auth_timer - 8'd1;
                end
                else begin //Si el timer llegó al final:
                    auth_status <= 1'b0; // se hace auto-logout
                    auth_timer  <= 8'd0;
                end
            end
        end
    end

endmodule