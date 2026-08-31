module forwarding_unit (
    input [4:0] id_ex_rs1, id_ex_rs2,
    input [4:0] ex_mem_rd,
    input       ex_mem_RegWrite,
    input [4:0] mem_wb_rd,
    input       mem_wb_RegWrite,

    output reg [1:0] forwardA, // selects ALU operand a source
    output reg [1:0] forwardB  // selects ALU operand b source (only when ALUb selects reg, i.e. R/B-type)
);
    // encoding: 2'b00 = no forward (use id_ex readout as-is)
    //           2'b10 = forward from EX/MEM (most recent producer)
    //           2'b01 = forward from MEM/WB
    // EX/MEM checked first: it's the more recent instruction, so it wins if both match (RAW chain of 2)
    always @(*) begin
        forwardA = 2'b00;
        if (ex_mem_RegWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1))
            forwardA = 2'b10;
        else if (mem_wb_RegWrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1))
            forwardA = 2'b01;

        forwardB = 2'b00;
        if (ex_mem_RegWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2))
            forwardB = 2'b10;
        else if (mem_wb_RegWrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2))
            forwardB = 2'b01;
    end
endmodule
