module cpu (input clk,rst);
    wire [31:0]pc_in,pc_out,inst,readout1,readout2,c,immsext,data;
    localparam INUM = 64;
    wire [3:0]alu_sel;
    wire [2:0]instr_type;

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
        .instr_type(instr_type)
    );
    
    register_file #(.XLEN(32)) rfile(
        .readreg1(inst[19:15]),
        .readreg2(inst[25:20]),
        .writereg(inst[11:7]),
        .clk(clk),
        .write_en(smtg from decoder or mux),
        .write_data(from alu or sec mem),
        .readout1(readout1),
        .readout2(readout2)
    );

    alu #(.XLEN(32)) alu_inst(
        .a(readout1),
        .b(either readout1 or immsext),
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
endmodule