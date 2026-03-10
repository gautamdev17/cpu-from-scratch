module decoder (input [31:0]inst,output reg [3:0]alu_sel);// should decide on output
    wire [6:0]opcode;
    assign opcode = inst[6:0];
    wire [6:0]funct7;
    assign funct7 = inst[31:25];
    wire [2:0]funct3;
    assign funct3 = inst[14:12];
    always @(*) begin
        case(opcode)
            7'b0110011: //r-type
                case({funct3,funct7[5]}) // onyl need 5th bit, cuz look at the riscv_card sheet
                    4'h0: alu_sel = 4'h0;//ADD
                    4'h1: //SUB
                    4'h8: //XOR
                    4'hC: //OR
                    4'hE: //AND
                    4'h2: //SLL
                    4'hA: //SRL
                    4'hB: //SRA
                    4'h4: //SLT
                    4'h6: //SLTU
                endcase
            7'b0010011: //i-type
                case(funct3)
                    3'h0: //ADDI
                    3'h4: //XORI
                    3'h6: //ORI
                    3'h7: //ANDI
                    3'h1: //SLLI //ignoring imm[5:11] since there is no other case with this (opcode,funct3) comb
                    3'h5: //SRLI & SRAI
                          if(funct7[5]) // imm[5:11] found equivalent to imm[5:11]
                            //SRLI
                          else
                            //SRAI
                    3'h2: //SLTI
                    3'h3: //SLTIU
                endcase
            7'b0000011: //i-type (loads)
                case(funct3)
                    3'h0: //LB
                    3'h1: //LH
                    3'h2: //LW
                    3'h4: //LBU
                    3'h5: //LHU
                endcase
            7'b0100011: //s-type
                case(funct3)
                    3'h0: //SB
                    3'h1: //SH
                    3'h2: //SW
                endcase
            7'b1100011: //b-type
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
                    //jal j-type
            7'b1100111:
                    //jalr i-type
        endcase
    end
endmodule