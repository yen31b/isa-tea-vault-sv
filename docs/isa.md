# TEA-Vault ISA Green Sheet

Reference manual for the custom RISC-based Instruction Set Architecture (ISA) with TEA (Tiny Encryption Algorithm) acceleration and Secure Key Vault support.

## 1. Instruction Formats

The ISA uses 32-bit fixed-length instructions. There are 6 primary formats. Register fields are **4 bits** wide, addressing **16 general-purpose registers** (r0–r15).

| Format | 31-27 | 26-23 | 22-19 | 18-15 | 14-11 | 10-0 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **R (Type R)** | Opcode(5) | rd(4) | rs1(4) | rs2(4) | \- | Unused (15 bits) |
| **I (Type I)** | Opcode(5) | rd(4) | rs1(4) | | | Immediate (19 bits) [18:0] |
| **M (Memory)** | Opcode(5) | rd/rs2(4) | rs1(4) | | | Immediate (19 bits) [18:0] |
| **J (Jump/Branch)** | Opcode(5) | rs1(4) | rs2(4) | | | Immediate (19 bits) [18:0] |

| Format | 31-27 | 26-24 | 23-21 | 20-17 | 16-0 |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **K (Key Vault)** | Opcode(5) | slot(3) | word(3) | rs1(4) | Reserved (17 bits) |

| Format | 31-27 | 26-23 | 22-19 | 18-15 | 14-11 | 10-0 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **T (TEA Accel)** | Opcode(5) | rd(4) | rs1(4) | rs2(4) | rs3(4) | Immediate (11 bits) |

---

## 2. Instruction Reference Table

| Mnemonic | Opcode (Bin) | Opcode (Hex) | Format | Description | Operation |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **LD** | `00000` | `0x00` | M | Load Word | `Reg[rd] = Mem[Reg[rs1] + imm]` |
| **ST** | `00001` | `0x01` | M | Store Word | `Mem[Reg[rs1] + imm] = Reg[rs2]` |
| **BEQ** | `00010` | `0x02` | J | Branch if Equal | `if (Reg[rs1] == Reg[rs2]) PC += imm` |
| **JMP** | `00011` | `0x03` | J | Jump | `PC += imm` |
| **ADD** | `00100` | `0x04` | R | Add | `Reg[rd] = Reg[rs1] + Reg[rs2]` |
| **SUB** | `00101` | `0x05` | R | Subtract | `Reg[rd] = Reg[rs1] - Reg[rs2]` |
| **OR** | `00110` | `0x06` | R | Logical OR | `Reg[rd] = Reg[rs1] \| Reg[rs2]` |
| **XOR** | `00111` | `0x07` | R | Logical XOR | `Reg[rd] = Reg[rs1] ^ Reg[rs2]` |
| **SRL** | `01000` | `0x08` | R | Shift Right Log. | `Reg[rd] = Reg[rs1] >> Reg[rs2]` |
| **SLL** | `01001` | `0x09` | R | Shift Left Log. | `Reg[rd] = Reg[rs1] << Reg[rs2]` |
| **CMP** | `01010` | `0x0A` | R | Compare | `Flags = Status(Reg[rs1] - Reg[rs2])` |
| **MUL** | `01011` | `0x0B` | R | Multiply | `Reg[rd] = Reg[rs1] * Reg[rs2]` |
| **MOV** | `01100` | `0x0C` | I | Move Immediate | `Reg[rd] = imm` |
| **AND** | `01101` | `0x0D` | R | Logical AND | `Reg[rd] = Reg[rs1] & Reg[rs2]` |
| **VSTR** | `01110` | `0x0E` | K | Vault Store | `Vault[slot][word] = Reg[rs1]` (Priv) |
| **VLD** | `01111` | `0x0F` | K | Vault Load | `Internal_Key_Reg = Vault[slot][word]` (Priv) |
| **VCLR** | `10000` | `0x10` | K | Vault Clear | `Clear Vault[slot]` (Priv) |
| **VAUTH** | `10001` | `0x11` | K | Authenticate | `Authenticate with Reg[rs1]` |
| **VLOGOUT** | `10010` | `0x12` | K | Logout | `Clear Auth Status` |
| **BEQADD** | `10011` | `0x13` | T | TEA Loop Branch | `if(rs1==rs2) { PC+=imm; rs3++ }` (Priv) |
| **XORTEA** | `10100` | `0x14` | T | TEA Round XOR | `Reg[rd] = rs1 ^ rs2 ^ rs3` (Priv) |
| **SRLI** | `10101` | `0x15` | I | SRL Immediate | `Reg[rd] = Reg[rs1] >> imm` |
| **SLLI** | `10110` | `0x16` | I | SLL Immediate | `Reg[rd] = Reg[rs1] << imm` |
| **NOP** | `11111` | `0x1F` | R | No Operation | No-op |

---

## 3. Register Reference

The processor contains **16 general-purpose registers** of 32 bits each, addressed with 4-bit fields.

| Register | Name | Description |
| :--- | :--- | :--- |
| **r0** | `zero` | Constant value 0 (by convention) |
| **r1 – r15** | `gen` | General purpose registers |

### Suggested TEA Register Allocation (without XORTEA/BEQADD)

| Register | Use | Notes |
| :--- | :--- | :--- |
| **r0** | v0 | Data block word 0 |
| **r1** | v1 | Data block word 1 |
| **r2** | sum | TEA accumulator |
| **r3** | i | Loop counter (0..31) |
| **r4** | DELTA | Constant `0x9e3779b9` |
| **r5** | key[0] | Key word 0 (loaded from memory) |
| **r6** | key[1] | Key word 1 |
| **r7** | key[2] | Key word 2 |
| **r8** | key[3] | Key word 3 |
| **r9** | temp1 | Temporary for sub-expressions |
| **r10** | temp2 | Temporary for sub-expressions |
| **r11** | limit (32) | Loop limit constant |
| **r12–r15** | free | Base addresses, scratch, etc. |

### Status Flags (6 bits)
- **bit 0**: Zero (Z) - Result is zero
- **bit 1**: Negative (N) - Result is negative
- **bit 2**: Carry (C) - Carry out from MSB
- **bit 3**: Overflow (V) - Arithmetic overflow
- **bits 4-5**: Reserved

---

## 4. Key Vault & TEA Extension

### Security Model
Instructions marked as **(Priv)** require the processor to be in an `Authenticated` state. This state is entered by executing `VAUTH` with a valid key in `rs1`.

### Vault Structure
The Vault contains multiple **slots**, each holding a cryptographic key divided into multiple **words**.
- `slot`: Index of the key in the vault (0-7). Encoded with 3 bits.
- `word`: Index of the 32-bit word within the key. Encoded with 3 bits.

### TEA Instructions
- **XORTEA**: Performs a three-way XOR, a common operation in TEA rounds to merge state, keys, and constants.
- **BEQADD**: Optimized for TEA loops. Checks if a loop counter has reached a limit and increments an index register in a single cycle if the branch is taken.

---

## 5. Memory Map (Conceptual)
- **Instruction Memory**: Read by Instruction Fetch.
- **Data Memory**: Accessed via `LD` and `ST`.
- **Key Vault**: Secure internal storage, not mapped to the main memory space.

---

## 6. Encoding Details

### Bit Field Extraction per Format

| Format | Field | Bits |
| :--- | :--- | :--- |
| **R** | opcode | [31:27] |
| | rd | [26:23] |
| | rs1 | [22:19] |
| | rs2 | [18:15] |
| **I** | opcode | [31:27] |
| | rd | [26:23] |
| | rs1 | [22:19] |
| | imm | [18:0] (19 bits, sign-extended to 32) |
| **M** | opcode | [31:27] |
| | rd (LD) / rs2 (ST) | [26:23] |
| | rs1 (base) | [22:19] |
| | imm (offset) | [18:0] (19 bits, sign-extended to 32) |
| **J** | opcode | [31:27] |
| | rs1 | [26:23] |
| | rs2 | [22:19] |
| | imm (offset) | [18:0] (19 bits, sign-extended to 32) |
| **K** | opcode | [31:27] |
| | slot | [26:24] (3 bits) |
| | word | [23:21] (3 bits) |
| | rs1 | [20:17] (4 bits) |
| | reserved | [16:0] (17 bits) |
| **T** | opcode | [31:27] |
| | rd | [26:23] |
| | rs1 | [22:19] |
| | rs2 | [18:15] |
| | rs3 | [14:11] |
| | imm | [10:0] (11 bits, sign-extended to 19→32) |
