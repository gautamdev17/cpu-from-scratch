module cpu (input clk,rst);
    localparam R_type = 3'b000;
    localparam I_type = 3'b001;
    localparam S_type = 3'b010;
    localparam B_type = 3'b011;
    localparam U_type = 3'b100;
    localparam J_type = 3'b101;

    wire [31:0]pc_out,inst,readout1,readout2,c,immsext,data;
    reg [31:0]pc_in,b,write_data;
    localparam INUM = 64;
    wire [3:0]alu_sel;
    wire [2:0]instr_type,funct3;
    wire ALUb,RegWrite,ALUorMem,WriteMem,jalr,lui,auipc,jump;

    reg branch_cond;//this is a boolean, decides if a branch should be take or not
    // handling what the pc value should be
    always @(*) begin
        if(branch_cond)
            pc_in = pc_out + immsext;
        else if(jalr)
            pc_in = readout2 + immsext;
        else
            pc_in = pc_out + 32'd4;
    end

    program_counter #(.XLEN(32)) pc_inst(
        .pc_in(pc_in),
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out)
    );

    instruction_mem #(.inum(64)) imem(
        .instaddr(pc_out[$clog2(INUM)+1:2]),
        .inst(inst)
    );

    decoder dec(
        .inst(inst),
        .alu_sel(alu_sel),
        .instr_type(instr_type),
        .funct3(funct3),
        .ALUb(ALUb),
        .RegWrite(RegWrite),
        .ALUorMem(ALUorMem),
        .WriteMem(WriteMem),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc),
        .jump(jump)
    );
    
    always @(*) begin
        // if(!ALUorMem)
        //     write_data = c;
        // else if(lui)
        //     write_data = immsext
        // else
        //     write_data = data;
        //case({uji_writebacks,ALUorMem})

        //endcase
        //write_en is well handled in the regfile,chec once if havin doubts
        if(!ALUorMem)
            write_data = c;
        else if(lui)
            write_data = immsext;
        else if(auipc)
            write_data = pc_out + immsext;
        else if(jump | jalr)
            write_data = pc_out + 4;
        else
            write_data = data;
    end
    /*
    i need to expand this:
    lui - rd = immsext
    auipc - rd = pc_out + immsext
    jal,jalr - rd = pc_out + 4
    */

    register_file #(.XLEN(32)) rfile(
        .readreg1(inst[19:15]),
        .readreg2(inst[25:20]),
        .writereg(inst[11:7]), // any instruction writing in reg will be in rd which is inst[11:7]
        .clk(clk),
        .write_en(RegWrite),
        .write_data(write_data),
        .readout1(readout1),
        .readout2(readout2)
    );

    always @(*) begin
        if(!ALUb)
            b = readout2;
        else
            b = immsext;
    end

    alu #(.XLEN(32)) alu_inst(
        .a(readout1),
        .b(b),
        .alu_sel(alu_sel),
        .c(c)
    );

    sign_extend #(.XLEN(32)) sext(
        .inst(inst),
        .instr_type(instr_type),
        .immsext(immsext)
    );

    data_mem dmem(
        .addr(c), //addr input is always the output of alu, some base + offset,i.e,reg+imm bro
        .wr_data(readout2), //only s-type insts write directly to sec mem
        .wr_en(WriteMem),
        .clk(clk),
        .data(data)
    );

    //going to write control signals
    /*  
    mux before alu: 
    so a mux before alu 'b', sel line will be instr format.  
    for R,B 'b' = rs2.
    for I,S,JALR 'b' = sext(imm)
    rest no alu use, some adders
    */
    
    // handling instructions that play with the program conter
    always @(*) begin
        branch_cond = 0; // u always miss defaults, keep it in mind while architecting
        case(instr_type)
            B_type: begin // if the inst is branch
                case(funct3) // check which branch instruction
                    // choose if to branch or not based on alu ka result
                    3'h0: branch_cond = ~(|c);//BEQ
                    3'h1: branch_cond = |c;//BNE
                    3'h4: branch_cond = c[0];//BLT
                    3'h5: branch_cond = ~c[0];//BGE
                    3'h6: branch_cond = c[0];//BLTU
                    3'h7: branch_cond = ~c[0];//BGEU
                endcase
            end
            J_type:
                branch_cond = 1; // does same function as branch_cond, just the alu part it doesnt do
                // so i gave the same reg
            // jalr is taken care by the deocder
            // so no need extra cases
        endcase
    end
endmodule