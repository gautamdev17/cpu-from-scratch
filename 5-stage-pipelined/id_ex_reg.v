module id_ex_reg (
    input clk, rst,
    input flush, // bubble insert (load-use stall OR branch/jump squash)

    // data
    input [31:0] pc_in, pc_plus4_in,
    input [31:0] readout1_in, readout2_in, immsext_in,
    input [4:0]  rs1_in, rs2_in, rd_in,

    // control
    input [3:0] alu_sel_in,
    input [2:0] instr_type_in, funct3_in,
    input ALUb_in, RegWrite_in, ALUorMem_in, WriteMem_in,
    input jalr_in, lui_in, auipc_in, jump_in,

    output reg [31:0] pc_out, pc_plus4_out,
    output reg [31:0] readout1_out, readout2_out, immsext_out,
    output reg [4:0]  rs1_out, rs2_out, rd_out,

    output reg [3:0] alu_sel_out,
    output reg [2:0] instr_type_out, funct3_out,
    output reg ALUb_out, RegWrite_out, ALUorMem_out, WriteMem_out,
    output reg jalr_out, lui_out, auipc_out, jump_out
);
    always @(posedge clk) begin
        if (rst || flush) begin
            pc_out <= 32'b0; pc_plus4_out <= 32'b0;
            readout1_out <= 32'b0; readout2_out <= 32'b0; immsext_out <= 32'b0;
            rs1_out <= 5'b0; rs2_out <= 5'b0; rd_out <= 5'b0;
            alu_sel_out <= 4'b0; instr_type_out <= 3'b0; funct3_out <= 3'b0;
            ALUb_out <= 1'b0; RegWrite_out <= 1'b0; ALUorMem_out <= 1'b0; WriteMem_out <= 1'b0;
            jalr_out <= 1'b0; lui_out <= 1'b0; auipc_out <= 1'b0; jump_out <= 1'b0;
            // NOTE: RegWrite_out and WriteMem_out forced to 0 explicitly here -
            // this is the actual safety net for bubbles, not reliance on rd==0.
        end else begin
            pc_out <= pc_in; pc_plus4_out <= pc_plus4_in;
            readout1_out <= readout1_in; readout2_out <= readout2_in; immsext_out <= immsext_in;
            rs1_out <= rs1_in; rs2_out <= rs2_in; rd_out <= rd_in;
            alu_sel_out <= alu_sel_in; instr_type_out <= instr_type_in; funct3_out <= funct3_in;
            ALUb_out <= ALUb_in; RegWrite_out <= RegWrite_in; ALUorMem_out <= ALUorMem_in; WriteMem_out <= WriteMem_in;
            jalr_out <= jalr_in; lui_out <= lui_in; auipc_out <= auipc_in; jump_out <= jump_in;
        end
    end
endmodule
