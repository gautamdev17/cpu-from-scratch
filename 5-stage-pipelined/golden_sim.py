# Golden (non-pipelined) functional simulator to compute expected architectural state.
import struct

words = [int(l.strip(),16) for l in open('program.hex') if l.strip()]

def sext(v,bits):
    if v & (1<<(bits-1)):
        v -= (1<<bits)
    return v

x = [0]*32
dmem = bytearray(1024)
pc = 0
steps = 0
MAXSTEPS = 2000

def rd_dmem_w(addr):
    return int.from_bytes(dmem[addr:addr+4],'little')

def wr_dmem_w(addr,val):
    dmem[addr:addr+4] = (val & 0xFFFFFFFF).to_bytes(4,'little')

while steps < MAXSTEPS:
    steps += 1
    idx = pc//4
    if idx >= len(words):
        break
    inst = words[idx]
    opcode = inst & 0x7F
    rd = (inst>>7)&0x1F
    funct3 = (inst>>12)&0x7
    rs1 = (inst>>15)&0x1F
    rs2 = (inst>>20)&0x1F
    funct7 = (inst>>25)&0x7F
    i_imm = sext(inst>>20,12)
    s_imm = sext(((inst>>25)<<5)|((inst>>7)&0x1F),12)
    b_imm = sext((((inst>>31)&1)<<12)|(((inst>>7)&1)<<11)|(((inst>>25)&0x3F)<<5)|(((inst>>8)&0xF)<<1),13)
    u_imm = inst & 0xFFFFF000
    j_imm = sext((((inst>>31)&1)<<20)|(((inst>>12)&0xFF)<<12)|(((inst>>20)&1)<<11)|(((inst>>21)&0x3FF)<<1),21)
    next_pc = pc+4
    a = x[rs1] & 0xFFFFFFFF
    b = x[rs2] & 0xFFFFFFFF
    if opcode == 0b0110011: # R
        if funct3==0: res = (a-b) if funct7==0x20 else (a+b)
        elif funct3==1: res = (a << (b&0x1F))
        elif funct3==2: res = 1 if sext(a,32) < sext(b,32) else 0
        elif funct3==3: res = 1 if a < b else 0
        elif funct3==4: res = a ^ b
        elif funct3==5: res = (sext(a,32) >> (b&0x1F)) & 0xFFFFFFFF if funct7==0x20 else (a >> (b&0x1F))
        elif funct3==6: res = a | b
        elif funct3==7: res = a & b
        x[rd] = res & 0xFFFFFFFF if rd!=0 else 0
    elif opcode == 0b0010011: # I-ALU
        if funct3==0: res = a + i_imm
        elif funct3==2: res = 1 if sext(a,32) < i_imm else 0
        elif funct3==3: res = 1 if a < (i_imm & 0xFFFFFFFF) else 0
        elif funct3==4: res = a ^ (i_imm & 0xFFFFFFFF)
        elif funct3==6: res = a | (i_imm & 0xFFFFFFFF)
        elif funct3==7: res = a & (i_imm & 0xFFFFFFFF)
        elif funct3==1: res = a << (inst>>20 & 0x1F)
        elif funct3==5:
            sh = (inst>>20)&0x1F
            res = (sext(a,32) >> sh) & 0xFFFFFFFF if funct7==0x20 else (a >> sh)
        x[rd] = res & 0xFFFFFFFF if rd!=0 else 0
    elif opcode == 0b0000011: # LOAD (only LW modeled, matches hw)
        addr = (a + i_imm) & 0xFFFFFFFF
        x[rd] = rd_dmem_w(addr) if rd!=0 else 0
    elif opcode == 0b0100011: # STORE (only SW modeled)
        addr = (a + s_imm) & 0xFFFFFFFF
        wr_dmem_w(addr, b)
    elif opcode == 0b1100011: # BRANCH
        taken = False
        if funct3==0: taken = (a==b)
        elif funct3==1: taken = (a!=b)
        elif funct3==4: taken = sext(a,32) < sext(b,32)
        elif funct3==5: taken = sext(a,32) >= sext(b,32)
        elif funct3==6: taken = a < b
        elif funct3==7: taken = a >= b
        if taken:
            if pc==pc and b_imm==0 and rs1==0 and rs2==0 and funct3==0:
                # infinite self-loop marker (L_END: beq x0,x0,L_END)
                break
            next_pc = pc + b_imm
    elif opcode == 0b1101111: # JAL
        if rd!=0: x[rd] = pc+4
        next_pc = pc + j_imm
    elif opcode == 0b1100111: # JALR
        t = (a + i_imm) & 0xFFFFFFFE
        if rd!=0: x[rd] = pc+4
        next_pc = t
    elif opcode == 0b0110111: # LUI
        x[rd] = u_imm if rd!=0 else 0
    elif opcode == 0b0010111: # AUIPC
        x[rd] = (pc + u_imm) & 0xFFFFFFFF if rd!=0 else 0
    else:
        raise Exception(f"unknown opcode {opcode:07b} at pc={pc}")
    pc = next_pc & 0xFFFFFFFF

print(f"golden sim halted after {steps} steps at pc={pc}")
for i in range(32):
    print(f"x{i:<2d} = 0x{x[i] & 0xFFFFFFFF:08x}")

# emit a verilog $readmemh-friendly expected file + a .vh header with defines for testbench checks
with open('expected.txt','w') as f:
    for i in range(32):
        f.write(f"{x[i] & 0xFFFFFFFF:08x}\n")
