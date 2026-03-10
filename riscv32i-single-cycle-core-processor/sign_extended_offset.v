module #(parameter immlen = 12,parameter XLEN = 32) sign_extended_offset(input [XLEN-1:0]inst,output reg [XLEN-1:0]immsext);
    wire [6:0]opcode;
    assign opcode = inst[6:0];
    always @(*) begin
        case (opcode)
            7'b0010011: //i-type arith-logic ops
            7'b0000011: //i-type loads
            7'b0100011: //s-type
            7'b1100011: //b-type
            7'b1101111: //jal
            7'b1100111: //jalr
            7'b0110111: //lui
        endcase
    end
endmodule