module alu #(parameter XLEN = 32) (input [XLEN-1:0]a,b,input [3:0]alu_sel,output reg [XLEN-1:0] c,output reg carry,logical);
    always @(*) begin
        case (alu_sel)
            4'h0: c = a + b; //ADD
            4'h1: c = a - b; //SUB
            4'h2: logical = a < b; //SLTU
            4'h3:
            begin
                
            end //SLT figure this out
            4'h4: c = a & b;//AND
            4'h5: c = a | b;//OR
            4'h6: c = a ^ b;//XOR
            4'h7: c = a << b[4:0];//SLL
            4'h8: c = a >> b[4:0];//SRL
            4'h9: c = {a[XLEN-1],a >> b[4:0]};//SRA
            default: c = 32'b0;
        endcase
    end
endmodule

/*
signed vs unsigned compare



*/