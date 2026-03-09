module program_counter #(parameter XLEN = 32) (input [XLEN-1:0] pc_in,sign_extoffset,input clk,jump,rst,output reg [XLEN-1:0] pc_out);
    always @(posedge clk) begin
        if (rst)
            pc_out<=32'b0;
        else if(jump) // if some jump inst must be executed
            pc_out<=pc_in+(sign_extoffset);
        else
            pc_out<=pc_in+32'd4;
    end
endmodule