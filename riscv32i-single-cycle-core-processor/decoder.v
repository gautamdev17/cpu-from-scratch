module decoder (input [31:0]inst,output reg [3:0]alu_sel,output reg [2:0]instr_type);// should decide on output
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
    wire [2:0]funct3;
    assign funct3 = inst[14:12];

    always @(*) begin
        alu_sel = 4'h0;
        instr_type = R_type;
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
                    3'h0: //LB
                    3'h1: //LH
                    3'h2: //LW
                    3'h4: //LBU
                    3'h5: //LHU
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
                case(funct3)
                    3'h0: //BEQ
                    3'h1: //BNE
                    3'h4: //BLT
                    3'h5: //BGE
                    3'h6: //BLTU
                    3'h7: //BGEU
                endcase
            end
            // jal & jalr
            J_op: begin
                instr_type = J_type;
                    //jal j-type
            end
            I_jalr_op: begin
                instr_type = I_type;
                    //jalr i-type
            end
            //u-type
            U_lui_op: begin
                instr_type = U_type;
                    //lui
            end
            U_auipc_op: begin
                instr_type = U_type;
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
endmodule