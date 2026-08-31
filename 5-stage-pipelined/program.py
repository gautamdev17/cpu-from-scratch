import sys
sys.path.insert(0,'.')
from asm import *

# Two-pass assembler with labels.
# Each entry: either ('label', name) or (mnemonic, args...) where branch/jal args use label name (string) for target.

prog = [
  # ---- 1. basic R-type / I-type ALU coverage ----
  ('addi','x1','x0',10),        # x1=10
  ('addi','x2','x0',3),         # x2=3
  ('add','x3','x1','x2'),       # x3=13
  ('sub','x4','x1','x2'),       # x4=7
  ('and_','x5','x1','x2'),      # x5 = 10&3=2
  ('or_','x6','x1','x2'),       # x6 = 11
  ('xor_','x7','x1','x2'),      # x7 = 9
  ('slt','x8','x2','x1'),       # 3<10 => 1
  ('sltu','x9','x2','x1'),      # 1
  ('sll','x10','x1','x2'),      # 10<<3=80
  ('srl','x11','x1','x2'),      # 10>>3=1
  ('addi','x12','x0',-8),       # x12 = -8 (0xFFFFFFF8)
  ('sra','x13','x12','x2'),     # -8>>>3 = -1 arithmetic
  ('andi','x14','x1',0x0F),     # 10&15=10
  ('ori','x15','x1',0x0F),      # 10|15=15
  ('xori','x16','x1',0x0F),     # 10^15=5
  ('slli','x17','x1',2),        # 40
  ('srli','x18','x1',1),        # 5
  ('srai','x19','x12',1),       # -4
  ('slti','x20','x2',10),       # 3<10 =>1
  ('sltiu','x21','x2',10),      # 1

  # ---- 2. RAW hazards: back-to-back (needs EX/MEM forward) ----
  ('addi','x1','x0',5),
  ('add','x2','x1','x1'),       # depends immediately on x1 -> EX/MEM forward
  ('add','x3','x2','x1'),       # depends on x2 from previous (1 gap) -> MEM/WB or EX/MEM? 1 instr between -> EX/MEM forward too (2 stage gap)
  ('addi','x4','x3',0),       # depends on x3, 2 instrs later -> MEM/WB forward

  # ---- 3. load-use hazard (must stall) ----
  ('addi','x5','x0',100),
  ('sw','x5','x0',0),           # mem[0] = 100
  ('lw','x6','x0',0),           # x6 = 100
  ('addi','x7','x6',1),         # immediately uses loaded value -> load-use stall needed

  # ---- 4. store/load different offsets, negative offset ----
  ('addi','x8','x0',0x55),
  ('sw','x8','x0',20),
  ('lw','x9','x0',20),

  # ---- 5. write to x0 must be ignored ----
  ('addi','x0','x0',999),       # x0 must remain 0
  ('add','x10','x0','x0'),      # x10 = 0

  # ---- 6. branches: not-taken then taken, various compares ----
  ('addi','x1','x0',5),
  ('addi','x2','x0',5),
  ('bne','x1','x2','L_SKIP1'),   # not taken (equal)
  ('addi','x11','x0',111),       # executes (fallthrough)
  ('L_SKIP1',None),
  ('beq','x1','x2','L_TAKEN1'),  # taken (equal) -> skip next
  ('addi','x11','x0',222),       # should be SKIPPED (flushed)
  ('L_TAKEN1',None),
  ('addi','x12','x0',333),       # executes after taken branch

  ('addi','x1','x0',1),
  ('addi','x2','x0',2),
  ('blt','x1','x2','L_BLT'),     # 1<2 taken
  ('addi','x13','x0',444),       # skipped
  ('L_BLT',None),
  ('bge','x2','x1','L_BGE'),     # 2>=1 taken
  ('addi','x13','x0',555),       # skipped
  ('L_BGE',None),
  ('addi','x14','x0',666),       # executes

  ('addi','x1','x0',-1),         # 0xFFFFFFFF (unsigned huge, signed -1)
  ('addi','x2','x0',1),
  ('blt','x1','x2','L_BLTsigned'),  # signed: -1 < 1 -> taken
  ('addi','x15','x0',777),          # skipped
  ('L_BLTsigned',None),
  ('bltu','x1','x2','L_SKIPu'),     # unsigned: 0xFFFFFFFF < 1 -> false, not taken
  ('addi','x16','x0',888),          # executes (fallthrough)
  ('L_SKIPu',None),
  ('addi','x17','x0',999),          # executes

  # ---- 7. jal / jalr, link register correctness ----
  ('jal','x20','L_JALTARGET'),      # x20 = pc+4 (return addr), jump forward
  ('addi','x21','x0',1000),         # skipped
  ('L_JALTARGET',None),
  ('addi','x22','x0',2000),         # executes
  ('addi','x23','x0',('ABS','L_JALRTARGET')),  # x23 = absolute address of L_JALRTARGET
  ('jalr','x24','x23',0),           # target = x23+0 = L_JALRTARGET, x24=link (pc+4)
  ('addi','x25','x0',3000),         # SKIPPED: jalr jumps over this
  ('L_JALRTARGET',None),

  # ---- 8. lui / auipc ----
  ('lui','x26',0xABCDE),            # x26 = 0xABCDE000
  ('auipc','x27',0x1),              # x27 = pc + 0x1000

  # ---- 9. backward branch / tiny loop (counts down) ----
  ('addi','x28','x0',3),            # loop counter
  ('addi','x29','x0',0),            # accumulator
  ('L_LOOP',None),
  ('addi','x29','x29',1),
  ('addi','x28','x28',-1),
  ('bne','x28','x0','L_LOOP'),      # backward branch, taken twice, not-taken once

  ('addi','x30','x0',0x7FF),        # marker: reached end
  ('addi','x31','x0',0x7FF),

  ('L_END',None),
  ('beq','x0','x0','L_END'),        # infinite loop at end (halt)
]

# ---- assemble ----
def is_label_decl(entry):
    return entry[1] is None and isinstance(entry[0],str) and entry[0] not in ('nop',)

# pass 1: compute addresses
addr = 0
labels = {}
instr_list = []
for entry in prog:
    if entry[1] is None and isinstance(entry[0],str):
        labels[entry[0]] = addr
    else:
        instr_list.append((addr, entry))
        addr += 4

def resolve(mn, args, pc):
    args = list(args)
    branch_ops = {'beq','bne','blt','bge','bltu','bgeu'}
    if mn in branch_ops:
        target = labels[args[2]]
        args[2] = target - pc
    elif mn == 'jal':
        target = labels[args[1]]
        args[1] = target - pc
    for i,a in enumerate(args):
        if isinstance(a,tuple) and a[0]=='ABS':
            args[i] = labels[a[1]]
    return args

words = []
mnmap = {
 'addi':addi,'slti':slti,'sltiu':sltiu,'xori':xori,'ori':ori,'andi':andi,
 'slli':slli,'srli':srli,'srai':srai,
 'add':add,'sub':sub,'sll':sll,'slt':slt,'sltu':sltu,'xor_':xor,'srl':srl,'sra':sra,'or_':orr,'and_':andd,
 'lw':lw,'sw':sw,
 'beq':beq,'bne':bne,'blt':blt,'bge':bge,'bltu':bltu,'bgeu':bgeu,
 'jal':jal,'jalr':jalr,'lui':lui,'auipc':auipc,
}

for pc, entry in instr_list:
    mn = entry[0]
    args = resolve(mn, entry[1:], pc)
    fn = mnmap[mn]
    w = fn(*args) & 0xFFFFFFFF
    words.append(w)

with open('program.hex','w') as f:
    for w in words:
        f.write(f"{w:08x}\n")

print(f"assembled {len(words)} instructions")
print("labels:", labels)
