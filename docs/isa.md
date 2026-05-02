# TEA-Vault ISA Green Sheet

Reference manual for the custom RISC-based Instruction Set Architecture (ISA) with TEA (Tiny Encryption Algorithm) acceleration and Secure Key Vault support.

## 1. Instruction Formats

The ISA uses 32-bit fixed-length instructions. There are 6 primary formats:

| Format | 31-27 | 26-24 | 23-21 | 20-18 | 17-15 | 14-0 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **R (Type R)** | Opcode | rd | rs1 | rs2 | \- | Unused (18 bits) |
| **I (Type I)** | Opcode | rd | rs1 | \- | \- | Immediate (21 bits) |
| **M (Memory)** | Opcode | rd/rs2| rs1 | \- | \- | Immediate (21 bits) |
| **J (Jump/Branch)** | Opcode | rs1 | rs2 | \- | \- | Immediate (21 bits) |
| **K (Key Vault)** | Opcode | slot | word | rs1 | \- | Unused (18 bits) |
| **T (TEA Accel)** | Opcode | rd | rs1 | rs2 | rs3 | Immediate (15 bits)|

*Note: In most formats, register fields are 3 bits, addressing registers r0 to r7.*

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
| **VCLR** | `10000` | `10` | K | Vault Clear | `Clear Vault[slot]` (Priv) |
| **VAUTH** | `10001` | `11` | K | Authenticate | `Authenticate with Reg[rs1]` |
| **VLOGOUT** | `10010` | `12` | K | Logout | `Clear Auth Status` |
| **BEQADD** | `10011` | `13` | T | TEA Loop Branch | `if(rs1==rs2) { PC+=imm; r3++ }` (Priv) |
| **XORTEA** | `10100` | `14` | T | TEA Round XOR | `Reg[rd] = rs1 ^ rs2 ^ rs3` (Priv) |
| **SRLI** | `10101` | `15` | I | SRL Immediate | `Reg[rd] = Reg[rs1] >> imm` |
| **SLLI** | `10110` | `16` | I | SLL Immediate | `Reg[rd] = Reg[rs1] << imm` |

---

## 3. Register Reference

The processor contains 32 general-purpose registers, though current instruction encoding primarily exposes **r0-r7**.

| Register | Name | Description |
| :--- | :--- | :--- |
| **r0** | `zero` | Constant value 0 (usually by convention, check `register_file.sv`) |
| **r1 - r7** | `gen` | General purpose registers |
| **r8 - r31**| `ext` | Extended registers (accessible via modified formats) |

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
- `slot`: Index of the key in the vault (0-7).
- `word`: Index of the 32-bit word within the key.

### TEA Instructions
- **XORTEA**: Performs a three-way XOR, a common operation in TEA rounds to merge state, keys, and constants.
- **BEQADD**: Optimized for TEA loops. Checks if a loop counter has reached a limit and increments an index register in a single cycle if the branch is taken.

---

## 5. Memory Map (Conceptual)
- **Instruction Memory**: Read by Instruction Fetch.
- **Data Memory**: Accessed via `LD` and `ST`.
- **Key Vault**: Secure internal storage, not mapped to the main memory space.
