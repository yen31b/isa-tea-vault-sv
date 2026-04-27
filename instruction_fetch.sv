//Este módulo implementa la etapa de fetch en una arquitectura Harvard simplificada.
//Usa una memoria exclusiva para instrucciones, mientras que la RAM de datos se
//maneja en otro módulo. Esto evita conflictos entre traer instrucciones y acceder a datos
//con LD/ST.

module instruction_fetch #(
    parameter INSTR_MEM_SIZE = 1024, //Define cuántas instrucciones caben en la memoria de instrucciones.
    parameter PROGRAM_FILE = "program.mem"//Define el nombre del archivo desde donde se cargan las instrucciones.
)(
    input  logic        clk, //Es el reloj. El PC se actualiza en cada flanco positivo del reloj.
    input  logic        reset, //Sirve para reiniciar el PC a cero.

    input  logic        branch_taken, //Indica que un branch, como BEQ, sí se debe tomar.
    input  logic        jump, //Indica que se debe hacer un salto incondicional, como JMP.
    input  logic [31:0] branch_target, //Dirección a la que debe ir el PC si el branch se toma.
    input  logic [31:0] jump_target, //Dirección a la que debe ir el PC si hay un JMP.

    output logic [31:0] pc, //Es el valor actual del Program Counter.
    output logic [31:0] instruction //Es la instrucción leída desde memoria.
);

    // Memoria separada solo para instrucciones(HARVARD)
    logic [31:0] instr_mem [0:INSTR_MEM_SIZE-1]; //Esto crea una memoria de instrucciones.

    initial begin
        $readmemh(PROGRAM_FILE, instr_mem);
    end //Esto carga el archivo program.mem dentro de instr_mem.

    // Como cada instrucción mide 32 bits = 4 bytes,
    // se usa pc[31:2] para convertir dirección en índice.
    assign instruction = instr_mem[pc[31:2]];

    always_ff @(posedge clk or posedge reset) begin //Luego viene la actualización del PC:
        if (reset) begin //Si reset = 1, el PC vuelve a cero.
            pc <= 32'd0; 
        end
        else begin //Si no hay reset, entonces el CPU decide cuál será el siguiente PC.
            if (jump) begin
                pc <= jump_target; //Si hay un JMP, el PC cambia directamente a la dirección jump_target.
            end
            else if (branch_taken) begin //Si no hubo JMP, pero sí un branch tomado, el PC cambia a branch_target.
                pc <= branch_target;
            end
            else begin
                pc <= pc + 32'd4; //Si no hay salto ni branch, el CPU ejecuta la siguiente instrucción normal.
            end
        end
    end

endmodule

