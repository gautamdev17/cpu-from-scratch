module cpu_pipe (input clk, rst);
    localparam R_type = 3'b000;
    localparam I_type = 3'b001;
    localparam S_type = 3'b010;
    localparam B_type = 3'b011;
    localparam U_type = 3'b100;
    localparam J_type = 3'b101;
    localparam INUM = 256;

    // =========================================================
    // Hazard/flush control wires (declared up front, used everywhere)
    // =========================================================
    wire pc_stall, if_id_stall, id_ex_flush_hazard;
    wire branch_taken;          // resolved in EX
    wire pc_src_flush;          // = branch_taken, flushes IF/ID and ID/EX

    // =========================================================
    // ===================  IF STAGE  =========================
    // =========================================================
    reg  [31:0] pc_in;
    wire [31:0] pc_out;
    wire [31:0] inst_if;
    wire [31:0] pc_plus4_if;

    assign pc_plus4_if = pc_out + 32'd4;

    // pc_in mux: branch/jump target (from EX) > jalr target (from EX) > pc+4
    // both branch and jalr targets are resolved in EX and fed back here
    wire [31:0] ex_branch_target, ex_jalr_target;
    wire        ex_jalr_taken;

    always @(*) begin
        if (pc_stall)
            pc_in = pc_out;              // hold: next state = current state
        else if (branch_taken)
            pc_in = ex_branch_target;
        else if (ex_jalr_taken)
            pc_in = ex_jalr_target;
        else
            pc_in = pc_out + 32'd4;
    end

    program_counter #(.XLEN(32)) pc_inst (
        .pc_in(pc_in), .clk(clk), .rst(rst),
        .pc_out(pc_out)
    );
    // program_counter has no enable port (confirmed by reading program_counter.v),
    // so stall is implemented by feeding pc_in = pc_out when pc_stall is asserted -
    // the reg still gets clocked but latches its own current value, net effect = frozen.

    instruction_mem #(.inum(256)) imem (
        .instaddr(pc_out[$clog2(INUM)+1:2]),
        .inst(inst_if)
    );

    // =========================================================
    // ==================  IF/ID REGISTER  =====================
    // =========================================================
    wire [31:0] pc_id, pc_plus4_id, inst_id;

    if_id_reg IFID (
        .clk(clk), .rst(rst),
        .stall(if_id_stall),
        .flush(pc_src_flush),
        .pc_in(pc_out), .pc_plus4_in(pc_plus4_if), .inst_in(inst_if),
        .pc_out(pc_id), .pc_plus4_out(pc_plus4_id), .inst_out(inst_id)
    );

    // =========================================================
    // ===================  ID STAGE  ==========================
    // =========================================================
    wire [3:0] alu_sel_id;
    wire [2:0] instr_type_id, funct3_id;
    wire ALUb_id, RegWrite_id, ALUorMem_id, WriteMem_id;
    wire jalr_id, lui_id, auipc_id, jump_id;
    wire [31:0] readout1_id, readout2_id, immsext_id;
    wire [4:0] rs1_id, rs2_id, rd_id;

    assign rs1_id = inst_id[19:15];
    assign rs2_id = inst_id[24:20];
    assign rd_id  = inst_id[11:7];

    decoder dec (
        .inst(inst_id),
        .alu_sel(alu_sel_id), .instr_type(instr_type_id), .funct3(funct3_id),
        .ALUb(ALUb_id), .RegWrite(RegWrite_id), .ALUorMem(ALUorMem_id), .WriteMem(WriteMem_id),
        .jalr(jalr_id), .lui(lui_id), .auipc(auipc_id), .jump(jump_id)
    );

    // ---- writeback wires from WB stage, needed here for regfile write port ----
    wire [31:0] wb_write_data;
    wire [4:0]  wb_rd;
    wire        wb_RegWrite;

    wire [31:0] readout1_raw, readout2_raw;
    register_file #(.XLEN(32)) rfile (
        .readreg1(rs1_id), .readreg2(rs2_id), .writereg(wb_rd),
        .clk(clk), .write_en(wb_RegWrite), .write_data(wb_write_data),
        .readout1(readout1_raw), .readout2(readout2_raw)
    );
    // BUG (found via golden-model mismatch): register_file's combinational read
    // does NOT see a write landing on the SAME clock edge - the read always@(*)
    // block re-evaluates using the OLD x[] contents, since the write's non-blocking
    // assignment only lands after this delta cycle. So when WB writes rd in the same
    // cycle ID is reading that same register, ID reads stale (or x, pre-reset) data.
    // Fix: bypass the regfile output directly with wb_write_data when write-reg ==
    // read-reg and a write is actually happening this cycle (classic "write-through" fix).
    assign readout1_id = (wb_RegWrite && wb_rd != 5'b0 && wb_rd == rs1_id) ? wb_write_data : readout1_raw;
    assign readout2_id = (wb_RegWrite && wb_rd != 5'b0 && wb_rd == rs2_id) ? wb_write_data : readout2_raw;

    sign_extend #(.XLEN(32)) sext (
        .inst(inst_id), .instr_type(instr_type_id), .immsext(immsext_id)
    );

    // =========================================================
    // Hazard detection (uses ID/EX.rd + IF/ID decoded rs1/rs2)
    // =========================================================
    // (forward-declared here so HDU's port connections below can bind them)
    wire [4:0]  rs1_ex, rs2_ex, rd_ex;
    wire ALUb_ex, RegWrite_ex, ALUorMem_ex, WriteMem_ex;
    hazard_detection_unit HDU (
        .id_ex_rd(rd_ex), .id_ex_ALUorMem(ALUorMem_ex),
        .if_id_rs1(rs1_id), .if_id_rs2(rs2_id),
        .pc_stall(pc_stall), .if_id_stall(if_id_stall), .id_ex_flush(id_ex_flush_hazard)
    );

    // =========================================================
    // ==================  ID/EX REGISTER  =====================
    // =========================================================
    wire [31:0] pc_ex, pc_plus4_ex;
    wire [31:0] readout1_ex, readout2_ex, immsext_ex;
    wire [3:0] alu_sel_ex;
    wire [2:0] instr_type_ex, funct3_ex;
    wire jalr_ex, lui_ex, auipc_ex, jump_ex;

    id_ex_reg IDEX (
        .clk(clk), .rst(rst),
        .flush(id_ex_flush_hazard || pc_src_flush),
        .pc_in(pc_id), .pc_plus4_in(pc_plus4_id),
        .readout1_in(readout1_id), .readout2_in(readout2_id), .immsext_in(immsext_id),
        .rs1_in(rs1_id), .rs2_in(rs2_id), .rd_in(rd_id),
        .alu_sel_in(alu_sel_id), .instr_type_in(instr_type_id), .funct3_in(funct3_id),
        .ALUb_in(ALUb_id), .RegWrite_in(RegWrite_id), .ALUorMem_in(ALUorMem_id), .WriteMem_in(WriteMem_id),
        .jalr_in(jalr_id), .lui_in(lui_id), .auipc_in(auipc_id), .jump_in(jump_id),

        .pc_out(pc_ex), .pc_plus4_out(pc_plus4_ex),
        .readout1_out(readout1_ex), .readout2_out(readout2_ex), .immsext_out(immsext_ex),
        .rs1_out(rs1_ex), .rs2_out(rs2_ex), .rd_out(rd_ex),
        .alu_sel_out(alu_sel_ex), .instr_type_out(instr_type_ex), .funct3_out(funct3_ex),
        .ALUb_out(ALUb_ex), .RegWrite_out(RegWrite_ex), .ALUorMem_out(ALUorMem_ex), .WriteMem_out(WriteMem_ex),
        .jalr_out(jalr_ex), .lui_out(lui_ex), .auipc_out(auipc_ex), .jump_out(jump_ex)
    );

    // =========================================================
    // ===================  EX STAGE  ==========================
    // =========================================================
    wire [1:0] forwardA, forwardB;
    wire [31:0] ex_mem_alu_out, mem_wb_writeback_val; // fwd sources (declared below, forward-refd here)

    // (forward-declared here so FWD's port connections below can bind them)
    wire [4:0]  rd_mem;
    wire RegWrite_mem, ALUorMem_mem, WriteMem_mem;
    forwarding_unit FWD (
        .id_ex_rs1(rs1_ex), .id_ex_rs2(rs2_ex),
        .ex_mem_rd(rd_mem), .ex_mem_RegWrite(RegWrite_mem),
        .mem_wb_rd(wb_rd), .mem_wb_RegWrite(wb_RegWrite),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    reg [31:0] alu_a, alu_b_pre_imm_mux, alu_b;
    always @(*) begin
        case (forwardA)
            2'b10: alu_a = ex_mem_alu_out;      // forward from EX/MEM
            2'b01: alu_a = wb_write_data;        // forward from MEM/WB (same value regfile writes)
            default: alu_a = readout1_ex;
        endcase
        case (forwardB)
            2'b10: alu_b_pre_imm_mux = ex_mem_alu_out;
            2'b01: alu_b_pre_imm_mux = wb_write_data;
            default: alu_b_pre_imm_mux = readout2_ex;
        endcase
        // ALUb still selects imm vs (possibly-forwarded) reg value, exactly like single-cycle
        if (!ALUb_ex)
            alu_b = alu_b_pre_imm_mux;
        else
            alu_b = immsext_ex;
    end

    wire [31:0] alu_c_ex;
    alu #(.XLEN(32)) alu_inst (
        .a(alu_a), .b(alu_b), .alu_sel(alu_sel_ex), .c(alu_c_ex)
    );

    // store data also needs forwarding (independent of ALUb, stores always use readout2/rs2)
    wire [31:0] store_data_ex;
    assign store_data_ex = alu_b_pre_imm_mux; // same forwarded rs2 value, pre-immediate-mux

    // branch condition, computed off (forwarded) ALU result - identical logic to single-cycle
    reg branch_cond_ex;
    always @(*) begin
        branch_cond_ex = 1'b0;
        case (instr_type_ex)
            B_type: begin
                case (funct3_ex)
                    3'h0: branch_cond_ex = ~(|alu_c_ex);      // BEQ
                    3'h1: branch_cond_ex = |alu_c_ex;         // BNE
                    3'h4: branch_cond_ex = alu_c_ex[0];       // BLT
                    3'h5: branch_cond_ex = ~alu_c_ex[0];      // BGE
                    3'h6: branch_cond_ex = alu_c_ex[0];       // BLTU
                    3'h7: branch_cond_ex = ~alu_c_ex[0];      // BGEU
                endcase
            end
            J_type: branch_cond_ex = 1'b1; // JAL always taken
        endcase
    end
    assign branch_taken     = branch_cond_ex;
    assign ex_branch_target = pc_ex + immsext_ex;
    assign ex_jalr_taken    = jalr_ex;
    assign ex_jalr_target   = alu_a + immsext_ex; // alu_a = forwarded readout1 (rs1 base for jalr)
    assign pc_src_flush     = branch_taken || ex_jalr_taken;

    wire [31:0] pc_target_ex; // for auipc writeback value (pc + imm)
    assign pc_target_ex = pc_ex + immsext_ex;

    // =========================================================
    // ==================  EX/MEM REGISTER  =====================
    // =========================================================
    wire [31:0] pc_plus4_mem, pc_target_mem, immsext_mem, store_data_mem;
    wire jalr_mem, lui_mem, auipc_mem, jump_mem;

    ex_mem_reg EXMEM (
        .clk(clk), .rst(rst),
        .pc_plus4_in(pc_plus4_ex), .alu_out_in(alu_c_ex), .store_data_in(store_data_ex),
        .pc_target_in(pc_target_ex), .immsext_in(immsext_ex), .rd_in(rd_ex),
        .RegWrite_in(RegWrite_ex), .ALUorMem_in(ALUorMem_ex), .WriteMem_in(WriteMem_ex),
        .jalr_in(jalr_ex), .lui_in(lui_ex), .auipc_in(auipc_ex), .jump_in(jump_ex),

        .pc_plus4_out(pc_plus4_mem), .alu_out_out(ex_mem_alu_out), .store_data_out(store_data_mem),
        .pc_target_out(pc_target_mem), .immsext_out(immsext_mem), .rd_out(rd_mem),
        .RegWrite_out(RegWrite_mem), .ALUorMem_out(ALUorMem_mem), .WriteMem_out(WriteMem_mem),
        .jalr_out(jalr_mem), .lui_out(lui_mem), .auipc_out(auipc_mem), .jump_out(jump_mem)
    );

    // =========================================================
    // ===================  MEM STAGE  =========================
    // =========================================================
    wire [31:0] data_mem_out;
    data_mem dmem (
        .addr(ex_mem_alu_out), .wr_data(store_data_mem), .wr_en(WriteMem_mem),
        .clk(clk), .data(data_mem_out)
    );

    // =========================================================
    // ==================  MEM/WB REGISTER  =====================
    // =========================================================
    wire [31:0] pc_plus4_wb, alu_out_wb, mem_data_wb, pc_target_wb, immsext_wb;
    wire ALUorMem_wb;
    wire lui_wb, auipc_wb, jump_wb, jalr_wb;

    mem_wb_reg MEMWB (
        .clk(clk), .rst(rst),
        .pc_plus4_in(pc_plus4_mem), .alu_out_in(ex_mem_alu_out), .mem_data_in(data_mem_out),
        .pc_target_in(pc_target_mem), .immsext_in(immsext_mem), .rd_in(rd_mem),
        .RegWrite_in(RegWrite_mem), .ALUorMem_in(ALUorMem_mem),
        .jalr_in(jalr_mem), .lui_in(lui_mem), .auipc_in(auipc_mem), .jump_in(jump_mem),

        .pc_plus4_out(pc_plus4_wb), .alu_out_out(alu_out_wb), .mem_data_out(mem_data_wb),
        .pc_target_out(pc_target_wb), .immsext_out(immsext_wb), .rd_out(wb_rd),
        .RegWrite_out(wb_RegWrite), .ALUorMem_out(ALUorMem_wb),
        .jalr_out(jalr_wb), .lui_out(lui_wb), .auipc_out(auipc_wb), .jump_out(jump_wb)
    );

    // =========================================================
    // ===================  WB STAGE  ==========================
    // =========================================================
    // identical mux structure to the original single-cycle write_data mux
    reg [31:0] wb_write_data_r;
    always @(*) begin
        if (lui_wb)
            wb_write_data_r = immsext_wb;
        else if (auipc_wb)
            wb_write_data_r = pc_target_wb;
        else if (jump_wb | jalr_wb)
            wb_write_data_r = pc_plus4_wb;
        else if (ALUorMem_wb)
            wb_write_data_r = mem_data_wb;
        else
            wb_write_data_r = alu_out_wb;
    end
    assign wb_write_data = wb_write_data_r;

endmodule