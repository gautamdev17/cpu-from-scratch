module alu #(parameter XLEN = 32) (input [XLEN-1:0]a,b,input [3:0]alu_sel,output reg [XLEN-1:0] c);
    always @(*) begin
        c = 32'b0;
        case (alu_sel)
            4'h0: c = a + b; //ADD
            4'h1: c = a-b; //SUB
            4'h2: c = {31'b0,a<b}; //SLTU
            4'h3: c = {31'b0,$signed(a) < $signed(b)}; //SLT figure this out, i wanted to do pure hw implementation
            4'h4: c = a & b;//AND
            4'h5: c = a | b;//OR
            4'h6: c = a ^ b;//XOR
            4'h7: c = a << b[4:0];//SLL
            4'h8: c = a >> b[4:0];//SRL
            4'h9: c = $signed(a) >>> b[4:0];//SRA, preserving the sign of the number
            /*
            4'hA: c = {31'b0,(a==b)};//BEQ
            4'hB: c = {31'b0,(a!=b)};//BNE
            4'hC: c = {31'b0,($signed(a)<$signed(b))};//BLT
            4'hD: c = {31'b0,(($signed(a)>$signed(b)) | ($signed(a)==$signed(b)))};//BGE
            4'hE: c = {31'b0,(a<b)};//BLTU
            4'hF: c = {31'b0,((a>b) | (a==b))};//BGEU
            */
            // logical left = arithmetic left, but logical right ≠ arithmetic right
            // my idea: c = {b{a[XLEN-1]},(a >> b[4:0])[XLEN-1:b]}; ---> variable indexing and constant wont allow this
        endcase
    end
endmodule

// update this: carry not required, not mentioned in isa
// updated