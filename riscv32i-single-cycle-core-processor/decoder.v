module decoder (input [31:0]inst,output reg [3:0]alu_sel,output reg [2:0]instr_format);// should decide on output
    localparam R_format = 3'b000;
    localparam I_format = 3'b001;
    localparam S_format = 3'b010;
    localparam B_format = 3'b011;
    localparam U_format = 3'b100;
    localparam J_format = 3'b101;
    wire [6:0]opcode;
    assign opcode = inst[6:0];
    wire [6:0]funct7;
    assign funct7 = inst[31:25];
    wire [2:0]funct3;
    assign funct3 = inst[14:12];
    always @(*) begin
        case(opcode)
            7'b0110011: begin //r-type
                instr_format = R_format;
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
            7'b0010011: begin //i-type
                instr_format = I_format;
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
            7'b0000011: //i-type (loads)
                instr_format = I_format;
                case(funct3)
                    3'h0: //LB
                    3'h1: //LH
                    3'h2: //LW
                    3'h4: //LBU
                    3'h5: //LHU
                endcase
            7'b0100011: //s-type
                instr_format = S_format;
                case(funct3)
                    3'h0: //SB
                    3'h1: //SH
                    3'h2: //SW
                endcase
            7'b1100011: //b-type
                instr_format = B_format;
                case(funct3)
                    3'h0: //BEQ
                    3'h1: //BNE
                    3'h4: //BLT
                    3'h5: //BGE
                    3'h6: //BLTU
                    3'h7: //BGEU
                endcase
            // jal & jalr
            7'b1101111:
                instr_format = J_format;
                    //jal j-type
            7'b1100111:
                instr_format = I_format;
                    //jalr i-type
            //u-type
            7'b0110111:
                instr_format = U_format;
                    //lui
            7'b0010111:
                instr_format = U_format;
                    //auipc
        endcase
    end
endmodule