module decoder (input [31:0]inst,//decoding the instruction
output reg [3:0]alu_sel,//for selection of alu operation
output reg [2:0]instr_type,//for sext
output [2:0]funct3,//for finding which B-type instruction
output ALUb,RegWrite,ALUorMem,WriteMem,
output reg jalr,lui,auipc,jump);//fior figuring out what does to ALU ka 'b'
    localparam R_type = 3'b000;
    localparam I_type = 3'b001;
    localparam S_type = 3'b010;
    localparam B_type = 3'b011;
    localparam U_type = 3'b100;
    localparam J_type = 3'b101;

    localparam R_op = 7'b0110011;
    localparam I_op = 7'b0010011;
    localparam I_load_op = 7'b0000011;
    localparam S_op = 7'b0100011;
    localparam B_op = 7'b1100011;
    localparam J_op = 7'b1101111;
    localparam I_jalr_op = 7'b1100111;
    localparam U_lui_op = 7'b0110111;
    localparam U_auipc_op = 7'b0010111;

    wire [6:0]opcode;
    assign opcode = inst[6:0];
    wire [6:0]funct7;
    assign funct7 = inst[31:25];
    assign funct3 = inst[14:12];
    reg load;

    always @(*) begin
        alu_sel = 4'h0;
        instr_type = R_type;
        load = 1'b0;
        jalr = 1'b0;
        lui = 1'b0;
        auipc = 1'b0;
        jump = 1'b0;
        case(opcode)
            R_op: begin //r-type
                instr_type = R_type;
                case({funct3,funct7[5]})// onyl need 5th bit, cuz look at the riscv_card sheet
                    4'h0: alu_sel = 4'h0;//ADD
                    4'h1: alu_sel = 4'h1;//SUB
                    4'h8: alu_sel = 4'h6;//XOR
                    4'hC: alu_sel = 4'h5;//OR
                    4'hE: alu_sel = 4'h4;//AND
                    4'h2: alu_sel = 4'h7;//SLL
                    4'hA: alu_sel = 4'h8;//SRL
                    4'hB: alu_sel = 4'h9;//SRA
                    4'h4: alu_sel = 4'h3; //SLT
                    4'h6: alu_sel = 4'h2;//SLTU
                endcase
            end
            I_op: begin //i-type
                instr_type = I_type;
                case(funct3)
                    3'h0: alu_sel = 4'h0;//ADDI // needs a mux to take either from reg file or sext immediate
                    3'h4: alu_sel = 4'h6;//XORI
                    3'h6: alu_sel = 4'h5;//ORI
                    3'h7: alu_sel = 4'h4;//ANDI
                    3'h1: alu_sel = 4'h7;//SLLI //ignoring imm[5:11] since there is no other case with this (opcode,funct3) comb
                    3'h5: begin //SRLI & SRAI
                          if(funct7[5]) // imm[5:11] found equivalent to imm[5:11]
                            alu_sel = 4'h8;//SRLI
                          else
                            alu_sel = 4'h9;//SRAI
                    end
                    3'h2: alu_sel = 4'h3;//SLTI
                    3'h3: alu_sel = 4'h2;//SLTIU
                endcase
            end
            I_load_op: begin //i-type (loads)
                instr_type = I_type;
                case(funct3)
                    3'h0: load = 1'b1;//LB
                    3'h1: load = 1'b1;//LH
                    3'h2: load = 1'b1;//LW
                    3'h4: load = 1'b1;//LBU
                    3'h5: load = 1'b1;//LHU
                endcase
            end
            S_op: begin //s-type
                instr_type = S_type;
                case(funct3)
                    3'h0: //SB
                    3'h1: //SH
                    3'h2: //SW
                endcase
            end
            B_op: begin //b-type
                instr_type = B_type;
                // we need to tell which function it is outside, they need for the contro;l signals
                case(funct3)
                    3'h0: alu_sel = 4'h1;//BEQ
                    3'h1: alu_sel = 4'h1;//BNE
                    3'h4: alu_sel = 4'h3;//BLT
                    3'h5: alu_sel = 4'h3;//BGE
                    3'h6: alu_sel = 4'h2;//BLTU
                    3'h7: alu_sel = 4'h2;//BGEU
                endcase
            end
            // jal & jalr
            J_op: begin
                instr_type = J_type;
                jump = 1'b1;
                //include rd write here
                    //jal j-type
            end
            I_jalr_op: begin
                instr_type = I_type;
                jalr = 1'b1;
                //include rd write here
                    //jalr i-type
            end
            //u-type
            U_lui_op: begin
                instr_type = U_type;
                lui = 1'b1;
                    //lui
            end
            U_auipc_op: begin
                instr_type = U_type;
                auipc = 1'b1;
                    //auipc
            end
            // ditched the block below. reason: say if alu_sel is not assigned for an opcode, we need default for that
            // defaults are wriiten at the top of the always block
            // default: begin
            //     alu_sel = 4'h0;
            //     instr_type = R_type;
            // end
        endcase
    end

    // alu 'b' is rs2 when its r-type or b-type
    // check mux in cpu for clarity
    assign ALUb = !((instr_type==R_type) | (instr_type==B_type));
    // r,i,j,u type instructions write to reg
    assign RegWrite = !((instr_type==S_type) |(instr_type==B_type));
    // either alu or sec mem should write to reg
    /*13-05-2026,11:11 AM, at library, didnt shower today man
    i need to expand this:
    lui - rd = immsext
    auipc - rd = pc_out + immsext
    jal,jalr - rd = pc_out + 4
    */
    assign ALUorMem = load;
    //so wr_en for dmem is like only given for store instructions so easy.
    assign WriteMem = (instr_type==S_type);
endmodule