# Test kit for the 5-stage RV32I pipeline (pipcpu)

## Files
- `program.hex` — assembled test program (71 instructions), ready for `$readmemh`.
- `program.py` / `asm.py` — the little hand-written RV32I assembler that generated `program.hex`. Edit `program.py` and rerun `python3 program.py` to change the test program.
- `golden_sim.py` — a non-pipelined **golden functional simulator** in Python. It executes `program.hex` architecturally and prints/records the expected final register file (`expected.txt`). This is how `testbench.v`'s expected values were derived — not by hand, so no arithmetic slip-ups.
- `testbench.v` — self-checking Icarus testbench. Instantiates `cpu_pipe`, runs it for 400 cycles, then compares every register against the golden model and prints PASS/FAIL per register.

## How to run
Put `testbench.v` and `program.hex` next to your CPU source files (`cpu_pipe.v`, `alu.v`, `data_mem.v`, `decoder.v`, `ex_mem_reg.v`, `forwarding_unit.v`, `hazard_detection_unit.v`, `id_ex_reg.v`, `if_id_reg.v`, `instruction_mem.v`, `mem_wb_reg.v`, `program_counter.v`, `register_file.v`, `sign_extend.v`), then:

```bash
iverilog -g2012 -o sim.out testbench.v cpu_pipe.v alu.v data_mem.v decoder.v ex_mem_reg.v forwarding_unit.v hazard_detection_unit.v id_ex_reg.v if_id_reg.v instruction_mem.v mem_wb_reg.v program_counter.v register_file.v sign_extend.v
vvp sim.out
```

(I already ran this myself with iverilog to make sure it compiles and the expected values are correct — see chat for the run log.)

## What the program exercises
1. All R-type ALU ops (add/sub/and/or/xor/sll/srl/sra/slt/sltu) and all I-type ALU ops (addi/andi/ori/xori/slli/srli/srai/slti/sltiu), including a negative operand for the shifts.
2. RAW hazards: back-to-back dependent instructions (EX/MEM forward) and one-gap dependent instructions (MEM/WB forward).
3. Load-use hazard (`lw` immediately followed by an instruction using the loaded value) — requires a pipeline stall.
4. Store/load round-trip at a non-zero offset.
5. Writes to `x0` (must be discarded).
6. Branches: not-taken and taken for BEQ/BNE, signed BLT/BGE, and a signed-vs-unsigned corner case (BLT vs BLTU on `-1` and `1`) to check sign handling specifically.
7. Forward `jal`, and `jalr` to an address computed at runtime (via `addi` + `jalr`), checking the link register (`pc+4`) in both cases.
8. `lui` and `auipc`.
9. A small backward-branch loop (3 iterations) — exercises taken/not-taken transitions on a backward target, i.e. PC redirection to a lower address.
10. Terminates in a `beq x0,x0,L_END` self-loop so the simulator settles into a steady state instead of running off the end of instruction memory.

## Two real findings from this run
- **`SRLI`/`SRAI` are swapped in `decoder.v`.** For the I-type shift-right-immediate case, the code picks `alu_sel = SRLI` when `funct7[5]==1` and `SRAI` when `funct7[5]==0` — that's backwards versus the R-type case right above it (which does it correctly) and versus the RV32I spec (bit 30 set = arithmetic). Test evidence: `srai x19, x12, 1` with `x12 = -8` produced `0x7ffffffc` (logical shift) instead of the correct `0xfffffffc` (arithmetic, sign-preserving).
- **The register file has no reset for its storage array** — only reads of `x0` are forced to zero through a mux; `x0`'s and any never-written register's raw storage stays `X` in simulation (and would be undefined on real hardware without explicit init). Not a bug in this test program (every register it *reads* was written first), but worth knowing if you add code paths that read a register before writing it.

## On your original question — does it have branch prediction?
No. It's static **predict-not-taken**: `pc_in` always defaults to `pc+4` in IF, and branches/JAL/JALR are resolved in EX, at which point a taken branch/jump flushes IF/ID and ID/EX and redirects the PC — a fixed 2-cycle penalty on every taken branch or jump, 0 on not-taken. No BTB, no dynamic predictor, no speculative fetch down the taken path.
