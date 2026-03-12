module cpu (input clk,rst);
    localparam R_type = 3'b000;
    localparam I_type = 3'b001;
    localparam S_type = 3'b010;
    localparam B_type = 3'b011;
    localparam U_type = 3'b100;
    localparam J_type = 3'b101;

    wire [31:0]pc_in,pc_out,inst,readout1,readout2,c,immsext,data,b;
    localparam INUM = 64;
    wire [3:0]alu_sel;
    wire [2:0]instr_type,funct3;
    wire ALUb,RegWrite;

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
        .RegWrite(RegWrite)
    );
    
    register_file #(.XLEN(32)) rfile(
        .readreg1(inst[19:15]),
        .readreg2(inst[25:20]),
        .writereg(inst[11:7]), // any instruction writing in reg will be in rd which is inst[11:7]
        .clk(clk),
        .write_en(RegWrite),
        .write_data(from alu or sec mem),
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
        .wr_en(smtg from decoder,muxes),
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
    always @(*) begin
        case(instr_type)
            B_type: begin
                case(funct3)
                    3'h0: 
                endcase
            end
        endcase
    end
endmodule