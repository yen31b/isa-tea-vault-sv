module control_unit (
    input  logic [4:0] opcode,//recibe opcode de 5 bits que viene del instruction_decode
    input  logic       zero_flag, // Recibe bandera zero, para instrucciones como BEQ
    input  logic       auth_status, //  1 si puede usar boveda y TEA o 0 no puede usar boveda y TEA

    output logic       reg_write, //activa escritura en el banco de registros
    output logic       mem_read,  // activa lectura en memoria
    output logic       mem_write, //Activa escritura en memoria
    output logic       mem_to_reg,// Indica que el dato que se esribira viene de memoria
                                  // mem_to_reg = 1 → escribe dato leído de RAM
                                  //mem_to_reg = 0 → escribe resultado de ALU/TEA
  	 output logic       use_imm,   //Indica que la ALU debe usar un inmediato en vez de un segundo registro.
 
    output logic       branch,  //Indica que la instrucción es un branch condicional, BEQ.
    output logic       jump,    //Indica que la instrucción es un salto incondicional, como JMP.
    output logic       branch_taken, //Indica si el branch realmente se toma.(1 fue tomado o 0 si no fue tomado)
    output logic       flags_write, //Indica que se deben actualizar las banderas del procesador.

    output logic       vault_write, //Activa escritura en la bóveda.
    output logic       vault_load_secure, //Carga una palabra de la bóveda hacia un registro seguro interno
    output logic       vault_clear, //Borra una llave de la bóveda.
    output logic       auth_check,// Activa la verificación de autenticación. se usa solo para VAUTH rs1
    output logic       auth_clear, //Cierra la sesión autenticada. Se usa solo para VLOGOUT

    output logic       tea_enable,//Activa la unidad TEA.
    output logic       index_inc, //Indica que se debe incrementar el índice del loop. Se usa para BEQADD
    output logic       illegal_access, //Se activa cuando alguien intenta usar una instrucción no permitida.

	 output logic privileged_instr,
	 
    output logic [3:0] alu_op //Indica qué operación debe hacer la ALU.
);

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
    localparam OP_TEA_ENC = 5'b10100;
    localparam OP_SRLI    = 5'b10101;
    localparam OP_SLLI    = 5'b10110;
    localparam OP_TEA_DEC = 5'b10111;

    // -----------------------------
    // ALU OPERATIONS
    // -----------------------------
    localparam ALU_ADD = 4'd0; //Define el código interno que se le manda a la ALU para hacer suma.
    localparam ALU_SUB = 4'd1;
    localparam ALU_OR  = 4'd2;
    localparam ALU_XOR = 4'd3;
    localparam ALU_SRL = 4'd4;
    localparam ALU_SLL = 4'd5;
    localparam ALU_MUL = 4'd6;
    localparam ALU_MOV = 4'd7;
    localparam ALU_AND = 4'd8;

    always_comb begin

        // -----------------------------
        // VALORES POR DEFECTO, TODO EN CERO
        // -----------------------------
        reg_write         = 1'b0;
        mem_read          = 1'b0;
        mem_write         = 1'b0;
        mem_to_reg        = 1'b0;
        use_imm           = 1'b0;

        branch            = 1'b0;
        jump              = 1'b0;
        branch_taken      = 1'b0;
        flags_write       = 1'b0;

        vault_write       = 1'b0;
        vault_load_secure = 1'b0;
        vault_clear       = 1'b0;
        auth_check        = 1'b0;
        auth_clear        = 1'b0;

        tea_enable        = 1'b0;
        index_inc         = 1'b0;
        illegal_access    = 1'b0;
		  
		  privileged_instr = 1'b0;

        alu_op            = ALU_ADD;

        case (opcode)

            // -----------------------------
            // INSTRUCCIONES DE MEMORIA
            // -----------------------------
            OP_LD: begin
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                reg_write  = 1'b1;
                use_imm    = 1'b0;
                alu_op     = ALU_ADD; // base + offset
            end

            OP_ST: begin
                mem_write = 1'b1;
                use_imm   = 1'b0;
                alu_op    = ALU_ADD; // base + offset
            end

            // -----------------------------
            // CONTROL DE BRANCH Y JUMP
            // -----------------------------
            OP_BEQ: begin
                branch       = 1'b1;
                branch_taken = zero_flag;
                alu_op       = ALU_SUB; // rs1 - rs2
            end

            OP_JMP: begin
                jump = 1'b1;
            end

            // -----------------------------
            // ALU INSTRUCCIONES TYPO-R
            // -----------------------------
            OP_ADD: begin
                reg_write = 1'b1;
                alu_op    = ALU_ADD;
            end

            OP_SUB: begin
                reg_write = 1'b1;
                alu_op    = ALU_SUB;
            end

            OP_OR: begin
                reg_write = 1'b1;
                alu_op    = ALU_OR;
            end

            OP_XOR: begin
                reg_write = 1'b1;
                alu_op    = ALU_XOR;
            end

            OP_SRL: begin
                reg_write = 1'b1;
                alu_op    = ALU_SRL;
            end

            OP_SLL: begin
                reg_write = 1'b1;
                alu_op    = ALU_SLL;
            end

            OP_CMP: begin
                flags_write = 1'b1;
                alu_op      = ALU_SUB;
            end

            OP_MUL: begin
                reg_write = 1'b1;
                alu_op    = ALU_MUL;
            end

            OP_MOV: begin
                reg_write = 1'b1;
                alu_op    = ALU_MOV;
            end

            OP_AND: begin
                reg_write = 1'b1;
                alu_op    = ALU_AND;
            end

            // -----------------------------
            // INSTRUCCIONES DEL VAULT
            // -----------------------------
            OP_VAUTH: begin
                auth_check = 1'b1;
            end

            OP_VLOGOUT: begin
                auth_clear = 1'b1;
            end

            OP_VSTR: begin
				    privileged_instr = 1'b1;
                if (auth_status) begin
                    vault_write = 1'b1;
                end
                else begin
                    illegal_access = 1'b1;
                end
            end

            OP_VLD: begin
					 privileged_instr = 1'b1;
                if (auth_status) begin
                    vault_load_secure = 1'b1;
                end
                else begin
                    illegal_access = 1'b1;
                end
            end

            OP_VCLR: begin
					 privileged_instr = 1'b1;
                if (auth_status) begin
                    vault_clear = 1'b1;
                end
                else begin
                    illegal_access = 1'b1;
                end
            end

            // -----------------------------
            // INSTRUCCIONES TEA
            // -----------------------------
            OP_BEQADD: begin
					 privileged_instr = 1'b1;
				
                if (auth_status) begin
                    branch       = 1'b1;
                    branch_taken = zero_flag;
                    index_inc    = 1'b1;
                    alu_op       = ALU_SUB;
                end
                else begin
                    illegal_access = 1'b1;
                end
            end

            OP_TEA_ENC: begin
					 privileged_instr = 1'b1;
                if (auth_status) begin
                    tea_enable = 1'b1;
                    reg_write  = 1'b1;
                end
                else begin
                    illegal_access = 1'b1;
                end
            end

            OP_TEA_DEC: begin
					 privileged_instr = 1'b1;
                if (auth_status) begin
                    tea_enable = 1'b1;
                    reg_write  = 1'b1;
                end
                else begin
                    illegal_access = 1'b1;
                end
            end

            // -----------------------------
            //  OPERACIONES DE DESPLAZAMIENTOS CON INMEDIATO
            // -----------------------------
            OP_SRLI: begin
				    privileged_instr = 1'b1;
                reg_write = 1'b1;
                use_imm   = 1'b1;
                alu_op    = ALU_SRL;
            end

            OP_SLLI: begin
				    privileged_instr = 1'b1;
                reg_write = 1'b1;
                use_imm   = 1'b1;
                alu_op    = ALU_SLL;
            end

            // -----------------------------
            // OPCODE NO DEFINIDO
            // -----------------------------
            default: begin
                illegal_access = 1'b1;
            end

        endcase
    end

endmodule


// En esta ISA, las operaciones aritméticas, lógicas, memoria, bóveda y TEA trabajan
// principalmente con registros. Los únicos inmediatos usados por la ALU corresponden a
// SRLI y SLLI; las etiquetas de salto se interpretan como campos de control del PC, no
// como operandos inmediatos de ALU.