import sys

OPCODES = {
    'LD': 0, 'ST': 1, 'BEQ': 2, 'JMP': 3,
    'ADD': 4, 'SUB': 5, 'OR': 6, 'XOR': 7,
    'SRL': 8, 'SLL': 9, 'CMP': 10, 'MUL': 11,
    'MOV': 12, 'AND': 13, 'VSTR': 14, 'VLD': 15,
    'VCLR': 16, 'VAUTH': 17, 'VLOGOUT': 18,
    'BEQADD': 19, 'XORTEA': 20, 'SRLI': 21, 'SLLI': 22,
    'ADDK': 23, 'SUBK': 24, 'NOP': 31
}

def reg(s):
    return int(s.strip('r, '))

def assemble(line, pc):
    parts = line.replace(',', ' ').split()
    if not parts: return None
    op_name = parts[0].upper()
    if op_name not in OPCODES: return None
    
    op = OPCODES[op_name]
    instr = (op & 0x1F) << 27
    
    try:
        if op_name in ['ADD', 'SUB', 'OR', 'XOR', 'SRL', 'SLL', 'MUL', 'AND']:
            # Format R: rd, rs1, rs2
            rd = reg(parts[1])
            rs1 = reg(parts[2])
            rs2 = reg(parts[3])
            instr |= (rd & 0xF) << 23
            instr |= (rs1 & 0xF) << 19
            instr |= (rs2 & 0xF) << 15
        elif op_name == 'CMP':
            # Format R: rs1, rs2
            rs1 = reg(parts[1])
            rs2 = reg(parts[2])
            instr |= (rs1 & 0xF) << 19
            instr |= (rs2 & 0xF) << 15
        elif op_name in ['MOV']:
            # Format I: rd, imm
            rd = reg(parts[1])
            imm = int(parts[2], 0) & 0x7FFFF
            instr |= (rd & 0xF) << 23
            instr |= imm
        elif op_name in ['SRLI', 'SLLI']:
            # Format I: rd, rs1, imm
            rd = reg(parts[1])
            rs1 = reg(parts[2])
            imm = int(parts[3], 0) & 0x7FFFF
            instr |= (rd & 0xF) << 23
            instr |= (rs1 & 0xF) << 19
            instr |= imm
        elif op_name == 'LD':
            # Format M: rd, rs1, imm
            rd = reg(parts[1])
            rs1 = reg(parts[2])
            imm = int(parts[3], 0) & 0x7FFFF
            instr |= (rd & 0xF) << 23
            instr |= (rs1 & 0xF) << 19
            instr |= imm
        elif op_name == 'ST':
            # Format M: rs2, rs1, imm
            rs2 = reg(parts[1])
            rs1 = reg(parts[2])
            imm = int(parts[3], 0) & 0x7FFFF
            instr |= (rs2 & 0xF) << 23
            instr |= (rs1 & 0xF) << 19
            instr |= imm
        elif op_name == 'BEQ':
            # Format J: rs1, rs2, imm
            rs1 = reg(parts[1])
            rs2 = reg(parts[2])
            imm = int(parts[3], 0) & 0x7FFFF
            instr |= (rs1 & 0xF) << 23
            instr |= (rs2 & 0xF) << 19
            instr |= imm
        elif op_name == 'JMP':
            # Format J: imm
            imm = int(parts[1], 0) & 0x7FFFF
            instr |= imm
        elif op_name in ['VSTR', 'VLD', 'VCLR', 'VAUTH', 'VLOGOUT']:
            # Format K: slot, word, rs1 (for VAUTH only rs1)
            if op_name == 'VAUTH':
                rs1 = reg(parts[1])
                instr |= (rs1 & 0xF) << 17
            elif op_name == 'VLOGOUT':
                pass
            else:
                slot = int(parts[1])
                word = int(parts[2])
                rs1 = reg(parts[3])
                instr |= (slot & 0x7) << 24
                instr |= (word & 0x7) << 21
                instr |= (rs1 & 0xF) << 17
        elif op_name in ['BEQADD', 'XORTEA', 'ADDK', 'SUBK']:
            # Format T: rd, rs1, rs2, rs3, imm
            # For ADDK/SUBK: rd, rs1, k_idx
            if op_name in ['ADDK', 'SUBK']:
                rd = reg(parts[1])
                rs1 = reg(parts[2])
                imm = int(parts[3]) & 0x7FF
                instr |= (rd & 0xF) << 23
                instr |= (rs1 & 0xF) << 19
                instr |= imm
            elif op_name == 'XORTEA':
                rd = reg(parts[1])
                rs1 = reg(parts[2])
                rs2 = reg(parts[3])
                rs3 = reg(parts[4])
                instr |= (rd & 0xF) << 23
                instr |= (rs1 & 0xF) << 19
                instr |= (rs2 & 0xF) << 15
                instr |= (rs3 & 0xF) << 11
            elif op_name == 'BEQADD':
                rs1 = reg(parts[1])
                rs2 = reg(parts[2])
                imm = int(parts[3], 0) & 0x7FF
                instr |= (rs1 & 0xF) << 23 # Wait! rs1 is used as rd too
                instr |= (rs1 & 0xF) << 22 # Wait! instruction_decode mapping
                # BEQADD: rd=26:23, rs1=22:19, rs2=18:15, imm=10:0
                instr |= (rs1 & 0xF) << 23 # rd = rs1
                instr |= (rs1 & 0xF) << 19 # rs1
                instr |= (rs2 & 0xF) << 15 # rs2
                instr |= imm
        elif op_name == 'NOP':
            pass
    except Exception as e:
        print(f"Error in line {pc//4}: {line} -> {e}")
        return None
        
    return f"{instr:08X}"

def main():
    if len(sys.argv) < 2: return
    with open(sys.argv[1], 'r') as f:
        lines = f.readlines()
    
    pc = 0
    for line in lines:
        line = line.split('//')[0].split('#')[0].strip()
        if not line: continue
        hex_str = assemble(line, pc)
        if hex_str:
            print(hex_str)
            pc += 4

if __name__ == '__main__':
    main()
