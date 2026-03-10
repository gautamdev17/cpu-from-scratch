module decoder (input [6:0]opcode,funct7,input [2:0]funct3,output control_signals);// should decide on output
    always @(*) begin
        case(opcode)
            7'b0110011: //r-type
                case({funct3,funct7[5]}) // onyl need 5th bit, cuz look at the riscv_card sheet
                    4'h0: //ADD
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
            7'b0000011: //i-type (loads)
            7'b0100011: //s-type
            7'b1100011: //b-type
        endcase
    end
endmodule