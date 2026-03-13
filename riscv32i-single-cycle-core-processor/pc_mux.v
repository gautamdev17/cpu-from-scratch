module pc_mux (input branch_cond,jalr,input [31:0]pc_out,immsext,readout2,output reg [31:0]pc_in);
    always @(*) begin
        if(branch_cond)
            pc_in = pc_out + immsext;
        else if(jalr)
            pc_in = readout2 + immsext;
        else
            pc_in = pc_out + 32'd4;
    end
endmodule