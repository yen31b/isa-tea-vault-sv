module instruction_decode (
	input logic [31:0] instruction,  //Tamaño de las instrucciones (32 bits)
	
	output logic [4:0] opcode, // tamaño del op (5 bits)
	output logic [3:0] rd,     // 4 bits — compatible con register_file de 16 entradas
	output logic [3:0] rs1,
	output logic [3:0] rs2,
	output logic [3:0] rs3,
	output logic [18:0] imm,   // 19 bits para formatos I/M/J (con 4-bit regs)
	output logic [2:0] format_type, // Bits para el tipo de formato de instruccion
	output logic [2:0] slot,
	output logic [2:0] palabra,
	output logic [16:0] reservado
	);
	
	// Formatos
	localparam FORMAT_R = 3'b000;
	localparam FORMAT_I = 3'b001;
	localparam FORMAT_M = 3'b010;
	localparam FORMAT_J = 3'b011;
	localparam FORMAT_K = 3'b100;
	localparam FORMAT_T = 3'b101;
	
always @(*) begin

    //Se define bits para los operandos y el opcode

		opcode = instruction[31:27];
		
		rd  = 4'b0000;
		rs1 = 4'b0000;
		rs2 = 4'b0000;
		rs3 = 4'b0000;
		imm = 19'b0;
		slot = 3'b000;
		palabra = 3'b000;
		reservado = 17'b0;
		format_type = FORMAT_R;
		
		
		case(opcode)
		
		
		//El decoder primero identifica el opcode y luego interpreta los campos segun el formato de instruccion correspondiente.

		//------------------------
		// Formato R
		// [31:27 opcode][26:23 rd][22:19 rs1][18:15 rs2][14:0 unused]
		//-------------------------
		
		      5'b00100, // ADD
            5'b00101, // SUB
            5'b00110, // OR
            5'b00111, // XOR
            5'b01000, // SRL
            5'b01001, // SLL
            5'b01011, // MUL
				5'b01010, // CMP
            5'b01101: begin // AND
				
				  format_type = FORMAT_R;
				  
				  rd  = instruction[26:23];
				  rs1 = instruction[22:19];
				  rs2 = instruction[18:15];

				  
	         end

            5'b01100: begin // MOV (FORMAT_I: rd <- imm)
                format_type = FORMAT_I;
                rd  = instruction[26:23];
                rs1 = 4'd0;
                imm = instruction[18:0];
            end
				
				
				
				//--------------------------------
            // FORMATO I
            // [31:27 opcode][26:23 rd][22:19 rs1][18:0 imm(19 bits)]
            //--------------------------------
				
            5'b10101, // SRLI
            5'b10110: begin // SLLI

                format_type = FORMAT_I;

                rd  = instruction[26:23];
                rs1 = instruction[22:19];
                imm = instruction[18:0];
            end
				
				
				
				 //--------------------------------
            // FORMATO M
            // [31:27 opcode][26:23 rd/rs2][22:19 rs1][18:0 imm(19 bits)]
            //--------------------------------
            5'b00000: begin // LD
                format_type = FORMAT_M;
                rd  = instruction[26:23];
                rs1 = instruction[22:19];
                imm = instruction[18:0];
                rs2 = 4'd0;
            end
            5'b00001: begin // ST
                format_type = FORMAT_M;
                rs2 = instruction[26:23];
                rs1 = instruction[22:19];
                imm = instruction[18:0];
                rd  = 4'd0;
            end
				
				
				
				 //--------------------------------
            // FORMATO J
            // [31:27 opcode][26:23 rs1][22:19 rs2][18:0 imm(19 bits)]
            //--------------------------------
				
				// BEQ usa rs1, rs2 e imm.
           // JMP solo usa imm; rs1 y rs2 se ignoran.
            5'b00010, // BEQ
            5'b00011: begin // JMP

                format_type = FORMAT_J;

                rs1 = instruction[26:23];
                rs2 = instruction[22:19];
                imm = instruction[18:0];
            end
				
				
				//--------------------------------
            // FORMATO K (vault)
            // [31:27 opcode][26:24 slot(3)][23:21 word(3)][20:17 rs1(4)][16:0 reserved(17)]
            //--------------------------------
            5'b01110, //VSTR
            5'b01111, //VLD
            5'b10000, //VCLR
            5'b10001, //VAUTH
            5'b10010: begin  //VLOGOUT
				
				
				// VSTR/VAUTH: registro general fuente
            // VLD: destino seguro k0-k3

                format_type = FORMAT_K;

                slot    = instruction[26:24]; // k dest /slot 
                palabra = instruction[23:21];
                rs1     = instruction[20:17]; // Para VAUTH rs1 queda en bits [20:17]
				    reservado = instruction[16:0];
            end
				
				
				//--------------------------------
            // FORMATO T (TEA)
            // [31:27 opcode][26:23 rd][22:19 rs1][18:15 rs2][14:11 rs3][10:0 imm(11 bits)]
            //--------------------------------
            5'b10011, // BEQADD
            5'b10100: begin //XORTEA

                format_type = FORMAT_T;

                rd  = instruction[26:23];
                rs1 = instruction[22:19];
                rs2 = instruction[18:15];
                rs3 = instruction[14:11];
                imm = {{8{instruction[10]}}, instruction[10:0]};// Extension con signo (11->19 bits)
            end
				
				5'b11111: begin // NOP
					format_type = FORMAT_R;
					// todos los campos quedan en 0 por los valores por defecto
			 end

			default: begin
					format_type = FORMAT_R;
	
	         end
	   endcase
		
	end
	

endmodule	
	


