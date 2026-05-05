#### Resultados de simulación GTKWave


##### Instruction Fetch

**Señales monitoreadas:** `clk`, `reset`, `jump`, `branch_taken`, `branch_target`, `jump_target`, `pc`, `instruction`

**Comportamiento observado:**
- **Reset (0–10 ns):** `reset`=1, `pc`=0, `instruction`=0x6000A5A5 (palabra precargada)
- **Secuencial (10–30 ns):** Sin saltos, `pc` avanza: 0→4→8→12, cada instrucción cambia según memoria
- **Branch tomado (~40 ns):** `branch_taken`=1 con `branch_target`=20, `pc` salta a 0x14, `instruction`=0x88000000
- **Luego secuencial:** `pc` continúa desde branch: 24, 28, etc.
- **Jump (55 ns):** `jump`=1 con `jump_target`=28, `pc`=0x1C
- **Prioridad (65 ns):** Ambos `jump` y `branch_taken` activos → `pc` toma `jump_target` (32), no branch_target
- **Reset priority (75 ns):** `reset`=1 con jump+branch activos → `pc` vuelve a 0, ignorando saltos

**Conclusión:** Módulo puramente combinacional. Respeta prioridades: reset > jump > branch > pc+4.

---

##### Instruction Decode

**Señales monitoreadas:** `instruction`, `opcode`, `format_type`, `rd`, `rs1`, `rs2`, `rs3`, `imm`, `slot`, `palabra`, `reservado`

**Comportamiento observado (ciclo = 1 ns):**
- **TEST 1 (0 ns) — ADD (FORMAT_R):** opcode=0x04, rd=3, rs1=1, rs2=2, imm=0, format_type=000
- **TEST 2 (1 ns) — SRLI (FORMAT_I):** opcode=0x15, rd=4, rs1=2, imm=0x19 (25), format_type=001
- **TEST 3 (2 ns) — LD (FORMAT_M):** opcode=0x00, rd=5, rs1=6, imm=0x64 (100), format_type=010
- **TEST 4 (3 ns) — BEQ (FORMAT_J):** opcode=0x02, rd=0 (no rd en J), rs1=1, rs2=7, imm=0x2C, format_type=011
- **TEST 5–6 — VAUTH/VSTR (FORMAT_K):** slot y palabra activos, forma_type=100
- **TEST 7–8 — XORTEA (FORMAT_T):** rd,rs1,rs2,rs3 todos presentes, imm=0xA y 0x7FFFF (sign-ext), format_type=101
- **TEST 9 — NOP:** opcode=0x1F, todo en 0, format_type=000

**Conclusión:** Puramente combinacional. Decodificación correcta de 6 formatos. Sign-extension en FORMAT_T funciona (0x7FF→0x7FFFF).

---

##### Control Unit

**Señales monitoreadas:** `opcode`, `zero_flag`, `auth_status` (entradas), `reg_write`, `mem_read`, `mem_write`, `branch`, `branch_taken`, `vault_write`, `tea_enable`, `illegal_access`, `alu_op` (salidas)

**Comportamiento observado (ciclo = 1 ns):**
- **0–2 ns — LD/ST:** reg_write+mem_read+mem_to_reg encendidos para LD; solo mem_write para ST
- **2–4 ns — BEQ:** branch=1, branch_taken refleja zero_flag (0 → tomado; 1 → no tomado)
- **4–14 ns — ALU (ADD/SUB/OR...):** alu_op sigue secuencia 0→1→2→3→4→5, CMP activa flags_write sin reg_write
- **14–21 ns — Vault (auth=1):** vault_write/load_secure/clear se activan correctamente, privileged_instr=1
- **18–21 ns — Vault (auth=0):** illegal_access=1, todas las señales vault=0
- **21–26 ns — BEQADD/XORTEA (auth=1):** tea_enable=1, index_inc=1, alu_op especializados
- **26–28 ns — SRLI/SLLI:** use_imm=1, alu_op=4/5, privileged_instr=1

**Conclusión:** Seguridad por autenticación implementada. Bloquea instrucciones privilegiadas sin auth_status=1.

---

##### Data Memory

**Señales monitoreadas:** `clk`, `reset`, `mem_read`, `mem_write`, `address`, `write_data`, `read_data`

**Comportamiento observado:**
- **Reset (0–5 ns):** `reset`=1, todos en 0
- **TEST 1–3 — ST+LD (10–30 ns):** Patrón repetido:
  - `mem_write`=1 por 1 ciclo en dirección 0, 4, 8 con 0xDEADBEEF, 0xCAFEBABE, 0x12345678
  - `mem_read`=1, `read_data` cambia **instantáneamente** (combinacional, no espera reloj)
- **TEST 2 — Little Endian (40 ns):** 0xAABBCCDD en addr=0x10, bytes internos: [0x10]=DD, [0x11]=CC, [0x12]=BB, [0x13]=AA
- **TEST 3–5 — Múltiples addr (50–100 ns):** Sin interferencia entre direcciones, cada dato aislado

**Conclusión:** `mem_write` es pulso de exactamente 1 ciclo. `read_data`=0 cuando mem_read=0. Byte-addressable con indexing correcto.

---

##### Key Vault

**Señales monitoreadas:** `clk`, `rst`, `auth_status`, `vault_write/load_secure/clear`, `slot`, `word`, `rs1_data`, `exc_out`, `k_reg0..3`

**Comportamiento observado:**
- **TEST 1 — VSTR auth=1 (~10 ns):** vault_write pulso, rs1_data=0xA1B2C3D4, exc_out=0, dato escrito internamente
- **TEST 2 — VSTR auth=0 (~20 ns):** vault_write sin auth → exc_out pulsa 1 ciclo
- **TEST 3 — VLD auth=1 (~30 ns):** vault_load_secure pulso → k_reg1 pasa de 0→0xE5F60718 al siguiente ciclo
- **TEST 4 — VLD auth=0 (~50 ns):** Sin auth → exc_out pulsa, k_reg no cambia
- **TEST 5 — VCLR auth=1 (~60 ns):** vault_clear borra bóveda interna, pero k_reg no afectados
- **TEST 6 — VCLR auth=0 (~100 ns):** exc_out pulsa
- **TEST 7 — Llave 128 bits (~120 ns):** 4 palabras cargadas secuencialmente en k_reg0..3

**Conclusión:** Seguridad por auth_status. `exc_out` es pulso de 1 ciclo. k_reg se cargan solo con VLD, no con VSTR.

---

##### Authentication Unit

**Señales monitoreadas:** `clk`, `reset`, `auth_check`, `auth_clear`, `privileged_instr`, `auth_value`, `auth_status`, `auth_fail`, `access_denied`, `auth_timer`

**Comportamiento observado (ciclo = 10 ns, timer en hexadecimal):**
- **TEST 1 — Reset (0–20 ns):** Todos en 0
- **TEST 2 — VAUTH OK (~20 ns):** auth_check pulso con auth_value=0xA5A5A5A5 → auth_status=1, **auth_timer=0x40 (64)**
- **TEST 3 — VAUTH FAIL (~40 ns):** auth_value=0xDEADBEEF → **auth_fail pulsa 1 ciclo**, auth_status=0
- **TEST 4 — VLOGOUT (~50 ns):** auth_clear pulso → auth_status=0, auth_timer=0
- **TEST 5 — Countdown normal (~120–500 ns):** auth_timer baja 1 cada ciclo: 0x40→0x3F→0x3E...→0x01→0x00, luego auto-logout
- **TEST 6 — Instrucción privilegiada + auth=1:** privileged_instr pulso → **auth_timer reinicia a 0x40** (no se ejecuta countdown), mantiene sesión activa
- **TEST 7 — Privilegiado sin auth (~60 ns):** **access_denied pulsa 1 ciclo**, auth_status no cambia
- **TEST 8 — Auto-logout (~630 ns):** Cuando timer llega a 0, auth_status cae a 0 automáticamente

**Conclusión:** Máquina de estados de seguridad con timeout. Pulsos de 1 ciclo para errores. Prioridad: auth_clear > auth_check > privileged_instr > countdown.

---

##### Datapath

**Señales monitoreadas:** `clk`, `reset`, `reg_write`, `alu_op[3:0]`, `alu_src_b`, `mem_to_reg`, `rd_addr[3:0]`, `rs1_addr[3:0]`, `rs2_addr[3:0]`, `immediate[31:0]`, `mem_data_in[31:0]`, `alu_result[31:0]`, `reg_data_1[31:0]`, `reg_data_2[31:0]`, `alu_zero`, `status_flags[5:0]`

**Distribución de status_flags\[5:0\]:** `[5]=EXC`, `[4]=AUTH`, `[3]=V`, `[2]=C`, `[1]=N`, `[0]=Z`

**Comportamiento observado (ciclo = 10 ns):**
- **Reset (0–15 ns):** `reset`=1, todas las señales en 0, `status_flags`=0x00
- **Ciclo idle (~25 ns):** Primer ciclo post-reset con alu_op=0 y entradas en 0 → ALU computa 0+0=0, Z=1, EXC=0 → `status_flags`=0x01
- **TEST 1 — XORTEA sin AUTH (~26 ns):** `alu_op`=0xA (XORTEA), `auth_status_in`=0 → `alu_result`=0x00000000, `illegal_op`=1; al siguiente ciclo (~35 ns): Z=1, EXC=1 → `status_flags`=0x21
- **TEST 2 — ADD r1 = r0 + 10 (~36 ns):** `reg_write`=1, `rd_addr`=1, `rs1_addr`=0, `immediate`=0xA, `alu_src_b`=1, `alu_op`=0 → `alu_result`=0x0000000A (combinatorial inmediato); captura en ~45 ns: Z=0, EXC=1 (sticky, `set_exc`=0 no lo borra) → `status_flags`=0x20
- **TEST 3 — ADD r2 = r0 + 20 (~46 ns):** `rd_addr`=2, `immediate`=0x14 → `alu_result`=0x00000014; `status_flags` permanece 0x20
- **TEST 4 — ADD r3 = r1 + r2 (~56 ns):** `rd_addr`=3, `rs1_addr`=1, `rs2_addr`=2, `alu_src_b`=0 → `reg_data_1`=0x0000000A, `reg_data_2`=0x00000014, `alu_result`=0x0000001E (30)

**Comportamientos clave verificados:**
- `alu_result` es puramente combinacional: cambia instantáneamente con los inputs
- Write-back al register file es sincrónico: el dato escrito en ciclo N se puede leer en ciclo N+1
- EXC flag es **sticky**: una vez activado por `illegal_op`, persiste hasta que `set_exc` vuelva a pulsar (no se borra automáticamente al desaparecer la excepción)
- `mem_to_reg`=0 en todos los tests → `write_data_rf` toma siempre el resultado de la ALU, no `mem_data_in`

**Conclusión:** Datapath integra correctamente ALU, register file y status register. El mux de write-back funciona. La flag EXC refleja operaciones privilegiadas sin autenticación y es sticky por diseño del status_reg.