module decoder (input [6:0]opcode,funct7,input [2:0]funct3,output control_signals);
    always @(*) begin
        case(opcode)
            7'b0110011: //r-type
            7'b0010011: //i-type
            7'b0000011: //i-type (loads)
            7'b
        endcase
    end
endmodule