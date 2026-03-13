module tb;
    reg clk, rst;
    
    cpu dut(.clk(clk), .rst(rst));
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        rst = 1;
        #10;
        rst = 0;
        #500;
        $finish;
    end

    // print every cycle
    always @(posedge clk) begin
        $display("t=%0t | pc=%h | inst=%h | writereg=%0d | write_data=%h | write_en=%b",
            $time,
            dut.pc_out,
            dut.inst,
            dut.rfile.writereg,
            dut.rfile.write_data,
            dut.rfile.write_en);
    end

endmodule