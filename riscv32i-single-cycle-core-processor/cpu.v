module cpu (input clk);
    wire [31:0]pc_in
    program_counter pc_inst (
        .pc_in(pc_in),
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out)
    );

    instruction_mem imem (

    );
endmodule