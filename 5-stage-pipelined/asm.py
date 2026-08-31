import sys

regs = {f"x{i}": i for i in range(32)}

def r(name): return regs[name]

def enc_r(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7<<25)|(rs2<<20)|(rs1<<15)|(funct3<<12)|(rd<<7)|opcode

def enc_i(imm, rs1, funct3, rd, opcode):
    imm &= 0xFFF
    return (imm<<20)|(rs1<<15)|(funct3<<12)|(rd<<7)|opcode

def enc_s(imm, rs2, rs1, funct3, opcode):
    imm &= 0xFFF
    imm11_5 = (imm>>5)&0x7F
    imm4_0 = imm&0x1F
    return (imm11_5<<25)|(rs2<<20)|(rs1<<15)|(funct3<<12)|(imm4_0<<7)|opcode

def enc_b(imm, rs2, rs1, funct3, opcode):
    imm &= 0x1FFF
    b12 = (imm>>12)&1
    b11 = (imm>>11)&1
    b10_5 = (imm>>5)&0x3F
    b4_1 = (imm>>1)&0xF
    return (b12<<31)|(b10_5<<25)|(rs2<<20)|(rs1<<15)|(funct3<<12)|(b4_1<<8)|(b11<<7)|opcode

def enc_u(imm, rd, opcode):
    return ((imm & 0xFFFFF)<<12)|(rd<<7)|opcode

def enc_j(imm, rd, opcode):
    imm &= 0x1FFFFF
    b20 = (imm>>20)&1
    b19_12 = (imm>>12)&0xFF
    b11 = (imm>>11)&1
    b10_1 = (imm>>1)&0x3FF
    return (b20<<31)|(b10_1<<21)|(b11<<20)|(b19_12<<12)|(rd<<7)|opcode

R_OP=0b0110011
I_OP=0b0010011
LOAD_OP=0b0000011
S_OP=0b0100011
B_OP=0b1100011
J_OP=0b1101111
JALR_OP=0b1100111
LUI_OP=0b0110111
AUIPC_OP=0b0010111

def add(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),0,r(rd),R_OP)
def sub(rd,rs1,rs2): return enc_r(0x20,r(rs2),r(rs1),0,r(rd),R_OP)
def sll(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),1,r(rd),R_OP)
def slt(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),2,r(rd),R_OP)
def sltu(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),3,r(rd),R_OP)
def xor(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),4,r(rd),R_OP)
def srl(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),5,r(rd),R_OP)
def sra(rd,rs1,rs2): return enc_r(0x20,r(rs2),r(rs1),5,r(rd),R_OP)
def orr(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),6,r(rd),R_OP)
def andd(rd,rs1,rs2): return enc_r(0,r(rs2),r(rs1),7,r(rd),R_OP)

def addi(rd,rs1,imm): return enc_i(imm,r(rs1),0,r(rd),I_OP)
def slti(rd,rs1,imm): return enc_i(imm,r(rs1),2,r(rd),I_OP)
def sltiu(rd,rs1,imm): return enc_i(imm,r(rs1),3,r(rd),I_OP)
def xori(rd,rs1,imm): return enc_i(imm,r(rs1),4,r(rd),I_OP)
def ori(rd,rs1,imm): return enc_i(imm,r(rs1),6,r(rd),I_OP)
def andi(rd,rs1,imm): return enc_i(imm,r(rs1),7,r(rd),I_OP)
def slli(rd,rs1,sh): return enc_i(sh&0x1F,r(rs1),1,r(rd),I_OP)
def srli(rd,rs1,sh): return enc_i(sh&0x1F,r(rs1),5,r(rd),I_OP)
def srai(rd,rs1,sh): return enc_i((0x20<<5)|(sh&0x1F),r(rs1),5,r(rd),I_OP)

def lw(rd,rs1,imm): return enc_i(imm,r(rs1),2,r(rd),LOAD_OP)
def sw(rs2,rs1,imm): return enc_s(imm,r(rs2),r(rs1),2,S_OP)

def beq(rs1,rs2,imm): return enc_b(imm,r(rs2),r(rs1),0,B_OP)
def bne(rs1,rs2,imm): return enc_b(imm,r(rs2),r(rs1),1,B_OP)
def blt(rs1,rs2,imm): return enc_b(imm,r(rs2),r(rs1),4,B_OP)
def bge(rs1,rs2,imm): return enc_b(imm,r(rs2),r(rs1),5,B_OP)
def bltu(rs1,rs2,imm): return enc_b(imm,r(rs2),r(rs1),6,B_OP)
def bgeu(rs1,rs2,imm): return enc_b(imm,r(rs2),r(rs1),7,B_OP)

def jal(rd,imm): return enc_j(imm,r(rd),J_OP)
def jalr(rd,rs1,imm): return enc_i(imm,r(rs1),0,r(rd),JALR_OP)

def lui(rd,imm20): return enc_u(imm20,r(rd),LUI_OP)
def auipc(rd,imm20): return enc_u(imm20,r(rd),AUIPC_OP)

def nop(): return addi('x0','x0',0)
