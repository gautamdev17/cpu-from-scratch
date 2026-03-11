module sign_extended_offset #(parameter XLEN = 32) (input [31:0]inst,input [2:0]instr_format,output reg [XLEN-1:0]immsext);
    always @(*) begin
        case (instr_format)
            3'b001: immsext = {{20{inst[XLEN-1]}},inst[31:20]};//i-type
            3'b010: immsext = {{20{inst[XLEN-1]}},inst[31:25],inst[11:7]};//s-type
            /* the b-type is decoded like this:
            inst[31] = imm[12];
            inst[30:25] = imm[10:5];
            inst[11:8] = imm[4:1];
            inst[7] = imm[11]         
            imm[0] = 0;  */
            3'b011: immsext = {{19{inst[XLEN-1]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};//b-type
            /* the j-type is decoded like this:
            inst[31] = imm[20];
            inst[30:21] = imm[10:1];
            inst[20] = imm[11];
            inst[19:12] = imm[19:12];           */
            3'b101: immsext = {{11{inst[XLEN-1]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};//jal-j
            3'b100: immsext = {inst[31:12],12'b0};//lui-u
        endcase
    end
endmodule