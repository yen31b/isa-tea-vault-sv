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
    output logic [DATA_WIDTH-1:0] k_reg0,
    output logic [DATA_WIDTH-1:0] k_reg1,
    output logic [DATA_WIDTH-1:0] k_reg2,
    output logic [DATA_WIDTH-1:0] k_reg3
);

    // Almacenamiento interno de llaves
    // vault[slot][palabra] = 32 bits
    logic [DATA_WIDTH-1:0] vault [0:NUM_SLOTS-1][0:WORDS_PER-1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            exc_out <= 1'b0;
            // clear registros seguros
            k_reg0 <= 32'b0;
            k_reg1 <= 32'b0;
            k_reg2 <= 32'b0;
            k_reg3 <= 32'b0;
            // clear vault completa
            for (int i = 0; i < NUM_SLOTS; i++)
                for (int j = 0; j < WORDS_PER; j++)
                    vault[i][j] <= 32'b0;
        end
        else begin
            exc_out <= 1'b0; // limpiar exception cada ciclo por defecto

            // VSTR: escribir palabra de 32 bits en boveda
            if (vault_write) begin
                if (auth_status) begin
                    case (slot)
                        3'd0: case (word)
                            3'd0: vault[0][0] <= rs1_data;
                            3'd1: vault[0][1] <= rs1_data;
                            3'd2: vault[0][2] <= rs1_data;
                            3'd3: vault[0][3] <= rs1_data;
                        endcase
                        3'd1: case (word)
                            3'd0: vault[1][0] <= rs1_data;
                            3'd1: vault[1][1] <= rs1_data;
                            3'd2: vault[1][2] <= rs1_data;
                            3'd3: vault[1][3] <= rs1_data;
                        endcase
                        3'd2: case (word)
                            3'd0: vault[2][0] <= rs1_data;
                            3'd1: vault[2][1] <= rs1_data;
                            3'd2: vault[2][2] <= rs1_data;
                            3'd3: vault[2][3] <= rs1_data;
                        endcase
                        3'd3: case (word)
                            3'd0: vault[3][0] <= rs1_data;
                            3'd1: vault[3][1] <= rs1_data;
                            3'd2: vault[3][2] <= rs1_data;
                            3'd3: vault[3][3] <= rs1_data;
                        endcase
                    endcase
                end
                else
                    exc_out <= 1'b1;
            end

            // VLD: cargar palabra de boveda a registro seguro interno
            else if (vault_load_secure) begin
                if (auth_status) begin
                    case (word)
                        3'd0: k_reg0 <= vault[slot][0];
                        3'd1: k_reg1 <= vault[slot][1];
                        3'd2: k_reg2 <= vault[slot][2];
                        3'd3: k_reg3 <= vault[slot][3];
                    endcase
                end
                else
                    exc_out <= 1'b1;
            end

            // VCLR: borrar slot completo (4 palabras)
            else if (vault_clear) begin
                if (auth_status) begin
                    case (slot)
                        3'd0: begin vault[0][0] <= 32'b0; vault[0][1] <= 32'b0; vault[0][2] <= 32'b0; vault[0][3] <= 32'b0; end
                        3'd1: begin vault[1][0] <= 32'b0; vault[1][1] <= 32'b0; vault[1][2] <= 32'b0; vault[1][3] <= 32'b0; end
                        3'd2: begin vault[2][0] <= 32'b0; vault[2][1] <= 32'b0; vault[2][2] <= 32'b0; vault[2][3] <= 32'b0; end
                        3'd3: begin vault[3][0] <= 32'b0; vault[3][1] <= 32'b0; vault[3][2] <= 32'b0; vault[3][3] <= 32'b0; end
                    endcase
                end
                else
                    exc_out <= 1'b1;
            end
        end
    end

endmodule