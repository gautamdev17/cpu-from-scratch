module data_mem #(parameter XLEN = 32) (input [$clog2(XLEN):0]addr,output reg [XLEN-1:0]data);
    reg [XLEN-1:0] dmem [XLEN-1:0];
    always @(*) begin
        data = dmem[addr];
    end
endmodule