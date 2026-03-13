module data_mem (input [31:0]addr,wr_data,input wr_en,clk,output reg [31:0]data);
    reg [7:0] dmem [1023 :0]; //using 2**32 just for design now. ill change while simulation
    // addressability is byte, addresses is 32-bit space, so 2^32 spaces available
    // 2^32 = 2^2GiB = 4 GiB of memory
    // should support all instructions like lw,lh,lb
    // so my output will be 32 bit sized. based on control signals(instruction),it can branch the sizes
    always @(*) begin
        data = {dmem[addr+3],dmem[addr+2],dmem[addr+1],dmem[addr]};
    end
    always @(posedge clk) begin
        if(wr_en)
        {dmem[addr+3],dmem[addr+2],dmem[addr+1],dmem[addr]} <= wr_data;
    end
endmodule

/*
a good microarchitect must view all instructions that the block he is desiging is supporting,
and then only give the spec
*/