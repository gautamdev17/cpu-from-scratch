module program_counter(input clk,input [31:0]next_pc, output reg [31:0]curr_pc);
    always @(posedge clk) begin
        if(jump) // jump instruction is true--> move to that instruction
            // figure out with j type
        else
            curr_pc<=next_pc+3'd4;
    end
endmodule