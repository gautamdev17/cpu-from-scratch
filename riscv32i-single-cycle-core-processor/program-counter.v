module program_counter(input clk,input [31:0]next_pc, output [31:0]current_pc) begin
    always @(posedge clk) begin
        if(beqtrue) // beqtrue = (both equal)&&(beq inst)
            pc<=pc+3'd4+offset
        else
            pc<=pc+3'd4;
    end
end