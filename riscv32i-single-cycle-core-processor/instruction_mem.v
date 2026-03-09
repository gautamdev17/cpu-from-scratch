module instruction_mem #(parameter inum = 64) (input [$clog2(inum)-1:0] instaddr,output reg [31:0]inst);
    // always do $clog when addressing. dont hardcode.
    reg [31:0] imem [inum-1:0];
    always @(*) begin
        inst = imem[instaddr];
    end
endmodule