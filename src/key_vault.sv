// key_vault.sv
// Vault/Boveda de Llaves, acceso para instrucciones VSTR, VLD, VCLR
//
// - 4 keys de 128 bits
// - Acceso controlado por la señal auth_status de auth_unit.sv 
// - Registros internos para seguridad son k0–k3
// - Señales que que vienen desde la unidad de control control_unit.sv:
//   vault_write para VSTR
//   vault_load_secure para VLD
//   vault_clear para VCLR
//   auth_status (desde auth_unit.sv) para indicar si hay sesión autenticada que este activa para acceder a la boveda

module key_vault #(
    parameter NUM_SLOTS  = 4,   // 4 keys
    parameter WORDS_PER  = 4,   // 4 palabras de 32 bits/key = 128 bits
    parameter DATA_WIDTH = 32  // ancho de cada palabra
)(
    input  logic clk,
    input  logic rst,
    //señales de control
    input  logic vault_write,    // VSTR: escribir palabra en boveda
    input  logic vault_load_secure, // VLD: cargar palabra a registro seguro interno
    input  logic vault_clear,   // VCLR: borrar slot completo
    input  logic auth_status,  // tiene que ser 1 para confirmar que esta autenticado 

    // Operandos de instruction_decode y register_file
    input  logic [2:0] slot, 
    input  logic [2:0] word, 
    input  logic [DATA_WIDTH-1:0] rs1_data, // dato a escribir

    // Señal de excepción que va al Status Register
    output logic exc_out,    // 1 = intento de acceso no autorizado

    // Registros seguros k0–k3 para usar en instrucciones TEA
    output logic [DATA_WIDTH-1:0] k_reg [0:3]
);

    // Almacenamiento interno de llaves
    // vault[slot][palabra] = 32 bits
    logic [DATA_WIDTH-1:0] vault [0:NUM_SLOTS-1][0:WORDS_PER-1];

    // Registros internos seguros k0–k3
    // Se cargan con VLD y se usan solo en instrucciones TEA
    logic [DATA_WIDTH-1:0] k_internal [0:3];
    assign k_reg = k_internal;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            exc_out <= 1'b0;
            // clear registros seguros
            k_internal[0] <= 32'b0;
            k_internal[1] <= 32'b0;
            k_internal[2] <= 32'b0;
            k_internal[3] <= 32'b0;
            // clear vault completa
            for (int i = 0; i < NUM_SLOTS; i++)
                for (int j = 0; j < WORDS_PER; j++)
                    vault[i][j] <= 32'b0;
        end
        else begin
            exc_out <= 1'b0; // limpiar exception cada ciclo por defecto

            // VSTR: escribir palabra de 32 bits en boveda
            // auth_status = 1
            // Si no esta autenticado entonces genera exception exc_out=1 y no modifica/accede la boveda
            if (vault_write) begin
                if (auth_status)
                    vault[slot][word] <= rs1_data;
                else
                    exc_out <= 1'b1;
            end

            // VLD: cargar palabra de boveda a registro seguro interno
            // El dato va a k_internal[palabra], NO a un registro normal de proposito general del register file
            // auth_status = 1
            else if (vault_load_secure) begin
                if (auth_status)
                    k_internal[word] <= vault[slot][word];
                else
                    exc_out <= 1'b1;
            end

            // VCLR: borrar slot completo (4 palabras)
             // auth_status = 1
             // Si no esta autenticado entonces genera exception exc_out=1 y no modifica/accede la boveda
             // Si esta autenticado entonces borra las 4 palabras del slot indicado a 0, pero NO genera exception
             // VCLR no afecta los registros seguros k_internal[0-3], solo borra el slot de la boveda
             // VCLR no tiene efecto si el slot ya esta vacio (todas las palabras en 0), pero tampoco genera exception
            // auth_status = 1
            else if (vault_clear) begin
                if (auth_status) begin
                    vault[slot][0] <= 32'b0;
                    vault[slot][1] <= 32'b0;
                    vault[slot][2] <= 32'b0;
                    vault[slot][3] <= 32'b0;
                end
                else
                    exc_out <= 1'b1;
            end
        end
    end

endmodule