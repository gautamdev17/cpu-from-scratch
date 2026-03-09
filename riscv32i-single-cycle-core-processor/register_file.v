module register_file #(parameter XLEN = 32) (input [$clog(XLEN)-1:0] readreg1,readreg2,writereg,input clk,write_en,input [31:0]write_data,
output reg [31:0] readout1,readout2);
    reg [XLEN-1:0] x [31:0]; // register memory
    //reg [width-1:0] array_name [0:no.ofelements-1];
    //caution:x0 mustbe always wired to zero. readin it is foine, writing is bad.

    // combinational read
    always @(*) begin
        readout1 = (readreg1 == 5'b0) ? 32'b0 : x[readreg1]; //creates mux
        readout2 = (readreg2 == 5'b0) ? 32'b0 : x[readreg2];
    end

    //sequential write
    always @(posedge clk) begin
        if(write_en && writereg!=5'b0)
            x[writereg]<=write_data;
    end
endmodule