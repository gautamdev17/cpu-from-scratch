module hazard_detection_unit (
    input [4:0] id_ex_rd,
    input       id_ex_ALUorMem,   // 1 = id_ex instruction is a LOAD
    input [4:0] if_id_rs1, if_id_rs2, // rs1/rs2 as decoded straight from IF/ID.inst

    output pc_stall,       // freeze PC
    output if_id_stall,    // freeze IF/ID reg
    output id_ex_flush      // bubble ID/EX reg (insert nop)
);
    // classic load-use hazard: instruction in EX is a load, and the instruction
    // currently in ID needs that load's destination register as a source
    wire hazard;
    assign hazard = id_ex_ALUorMem &&
                    (id_ex_rd != 5'b0) &&
                    ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    assign pc_stall    = hazard;
    assign if_id_stall = hazard;
    assign id_ex_flush = hazard;
endmodule
