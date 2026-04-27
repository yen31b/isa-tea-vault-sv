module instruction_decode (
	input logic [31:0] instruction,  //Tamaño de las instrucciones (32 bits)
	
	output logic [4:0] opcode, // tamaño del op (5 bits) 
	output logic [2:0] rd, 
	output logic [2:0] rs1,
	output logic [2:0] rs2,
	output logic [2:0] rs3,
	output logic [20:0] imm,
	output logic [2:0] format_type, // Bits para el tipo de formato de instruccion
	output logic [2:0] slot,
	output logic [2:0] palabra,
	output logic [17:0] reservado
	);
	
	// Formatos
	localparam FORMAT_R = 3'b000;
	localparam FORMAT_I = 3'b001;
	localparam FORMAT_M = 3'b010;
	localparam FORMAT_J = 3'b011;
	localparam FORMAT_K = 3'b100;
	localparam FORMAT_T = 3'b101;
	
always_comb begin

    //Se define bits para los operandos y el opcode


		opcode = instruction[31:27];
		
		rd  = 3'b000;
		rs1 = 3'b000;
		rs2 = 3'b000;
		rs3 = 3'b000;
		imm = 21'b0;
		slot = 3'b000;
		palabra = 3'b000;
		reservado = 18'b0;
		format_type = FORMAT_R;
		
		
		case(opcode)
		
		
		//El decoder primero identifica el opcode y luego interpreta los campos segun el formato de instruccion correspondiente.
		
		
		
		//------------------------
		// Formato R
		//-------------------------
		
		      5'b00100, // ADD
            5'b00101, // SUB
            5'b00110, // OR
            5'b00111, // XOR
            5'b01000, // SRL
            5'b01001, // SLL
            5'b01011, // MUL
				5'b01010, // CMP
            5'b01100, // MOV
            5'b01101: begin // AND
				
					  
					  format_type = FORMAT_R;
					  
					  rd = instruction[26:24];
					  rs1 = instruction[23:21];
					  rs2 = instruction[20:18];

					  
	         end
				
				
				
				//--------------------------------
            // FORMATO I
            //--------------------------------
				
            5'b10101, // SRLI
            5'b10110: begin // SLLI

                format_type = FORMAT_I;

                rd  = instruction[26:24];
                rs1 = instruction[23:21];
                imm = instruction[20:0];
            end
				
				
				
				 //--------------------------------
            // FORMATO M
            //--------------------------------
            5'b00000, // LD
            5'b00001: begin // ST

                format_type = FORMAT_M;

                rd  = instruction[26:24]; //LD: rd destino / ST: Registro fuente a guardar rs2
                rs1 = instruction[23:21];  // registro base
                imm = instruction[20:0];   //offset
            end
				
				
				
				 //--------------------------------
            // FORMATO J
            //--------------------------------
				
				// BEQ usa rs1, rs2 e imm.
           // JMP solo usa imm; rs1 y rs2 se ignoran.
            5'b00010, // BEQ
            5'b00011: begin // JMP

                format_type = FORMAT_J;

                rs1 = instruction[26:24];
                rs2 = instruction[23:21];
                imm = instruction[20:0];
            end
				
				
				//--------------------------------
            // FORMATO K (vault)
            //--------------------------------
            5'b01110, //VSTR
            5'b01111, //VLD
            5'b10000, //VCLR
            5'b10001, //VAUTH
            5'b10010: begin  //VLOGOUT

                format_type = FORMAT_K;

                slot  = instruction[26:24]; // k register /slot 
                palabra = instruction[23:21];
                rs1 = instruction[20:18]; //Para VAUTH rs1 queda en bits [20:18]
					 reservado = instruction[17:0];
            end
				
				
				//--------------------------------
            // FORMATO T (TEA)
            //--------------------------------
            5'b10011, // BEQADD
            5'b10100: begin //XORTEA

                format_type = FORMAT_T;

                rd  = instruction[26:24];
                rs1 = instruction[23:21];
                rs2 = instruction[20:18];
                rs3 = instruction[17:15];
                imm = {6'b000000, instruction[14:0]}; // offset/inmediato de 15 bits extendido a 21
            end
				
				default: begin
					format_type = FORMAT_R;
	
	         end
	   endcase
		
	end
	

endmodule	
	


