// tea_unit.sv
// Unidad hardware de cifrado/descifrado TEA (Tiny Encryption Algorithm)
// 32 rondas, DELTA = 0x9e3779b9
//
// Instrucciones soportadas (opcode desde control_unit, encrypt desde top.sv):
//   TEA_ENC  opcode=5'b10100  encrypt=1 → ejecuta tea_enc_round x32 → cifrado
//   TEA_DEC  opcode=5'b10111  encrypt=0 → ejecuta tea_dec_round x32 → descifrado
//
// Interfaz con el pipeline:
//   - tea_enable (control_unit) → start
//   - k_reg[0:3] (key_vault)   → llaves internas
//   - v0_in/v1_in: datos de entrada (desde register file)
//   - v0_out/v1_out: resultado (hacia register file)
//   - done: 1 ciclo cuando los 32 rounds terminan
//   - busy: 1 durante operacion (bloquea fetch de nuevas instrucciones TEA)

module tea_unit (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic        encrypt,          // 1=TEA_ENC, 0=TEA_DEC
    input  logic [31:0] v0_in,
    input  logic [31:0] v1_in,
    input  logic [31:0] k_reg [0:3],     // llaves k0..k3 desde key_vault
    output logic [31:0] v0_out,
    output logic [31:0] v1_out,
    output logic        done,             // pulso de 1 ciclo al terminar
    output logic        busy
);

    localparam [31:0] DELTA     = 32'h9e3779b9;
    localparam [31:0] SUM_START = 32'hC6EF3720; // DELTA*32: suma inicial para descifrado

    // Estados de la maquina de estados
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] RUN  = 2'b01;
    localparam [1:0] DONE = 2'b10;

    logic [1:0]  state;
    logic [5:0]  round;   // contador de rondas 0..31
    logic [31:0] v0_r, v1_r, sum_r;
    logic        enc_r;   // modo capturado al inicio (1=enc, 0=dec)

    // ----------------------------------------------------------------
    // tea_enc_round: calcula una ronda de cifrado TEA (combinacional)
    //   sum_new = sum + DELTA
    //   v0_new  = v0 + (((v1<<4)+k0) ^ (v1+sum_new) ^ ((v1>>5)+k1))
    //   v1_new  = v1 + (((v0_new<<4)+k2) ^ (v0_new+sum_new) ^ ((v0_new>>5)+k3))
    // ----------------------------------------------------------------
    logic [31:0] enc_sum_nxt;
    logic [31:0] enc_v0_nxt;
    logic [31:0] enc_v1_nxt;

    assign enc_sum_nxt = sum_r + DELTA;
    assign enc_v0_nxt  = v0_r + (((v1_r << 4) + k_reg[0]) ^ (v1_r + enc_sum_nxt) ^ ((v1_r >> 5) + k_reg[1]));
    assign enc_v1_nxt  = v1_r + (((enc_v0_nxt << 4) + k_reg[2]) ^ (enc_v0_nxt + enc_sum_nxt) ^ ((enc_v0_nxt >> 5) + k_reg[3]));

    // ----------------------------------------------------------------
    // tea_dec_round: calcula una ronda de descifrado TEA (combinacional)
    //   v1_new  = v1 - (((v0<<4)+k2) ^ (v0+sum) ^ ((v0>>5)+k3))
    //   v0_new  = v0 - (((v1_new<<4)+k0) ^ (v1_new+sum) ^ ((v1_new>>5)+k1))
    //   sum_new = sum - DELTA
    // ----------------------------------------------------------------
    logic [31:0] dec_v1_nxt;
    logic [31:0] dec_v0_nxt;
    logic [31:0] dec_sum_nxt;

    assign dec_v1_nxt  = v1_r - (((v0_r << 4) + k_reg[2]) ^ (v0_r + sum_r) ^ ((v0_r >> 5) + k_reg[3]));
    assign dec_v0_nxt  = v0_r - (((dec_v1_nxt << 4) + k_reg[0]) ^ (dec_v1_nxt + sum_r) ^ ((dec_v1_nxt >> 5) + k_reg[1]));
    assign dec_sum_nxt = sum_r - DELTA;

    // ----------------------------------------------------------------
    // Maquina de estados: IDLE → RUN (32 ciclos) → DONE → IDLE
    // ----------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            round <= 6'd0;
            v0_r  <= 32'd0;
            v1_r  <= 32'd0;
            sum_r <= 32'd0;
            enc_r <= 1'b1;
            done  <= 1'b0;
            busy  <= 1'b0;
        end else begin
            done <= 1'b0; // pulso: solo activo en estado DONE

            case (state)

                IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        v0_r  <= v0_in;
                        v1_r  <= v1_in;
                        sum_r <= encrypt ? 32'd0 : SUM_START;
                        enc_r <= encrypt;
                        round <= 6'd0;
                        busy  <= 1'b1;
                        state <= RUN;
                    end
                end

                RUN: begin
                    if (enc_r) begin
                        // --- tea_enc_round ---
                        v0_r  <= enc_v0_nxt;
                        v1_r  <= enc_v1_nxt;
                        sum_r <= enc_sum_nxt;
                    end else begin
                        // --- tea_dec_round ---
                        v0_r  <= dec_v0_nxt;
                        v1_r  <= dec_v1_nxt;
                        sum_r <= dec_sum_nxt;
                    end

                    if (round == 6'd31)
                        state <= DONE;
                    else
                        round <= round + 6'd1;
                end

                DONE: begin
                    done  <= 1'b1;
                    busy  <= 1'b0;
                    state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

    // Salidas continuas: validas desde el ultimo ciclo RUN en adelante
    assign v0_out = v0_r;
    assign v1_out = v1_r;

endmodule
