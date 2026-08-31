module ex_mem_reg (
    input clk, rst,

    input [31:0] pc_plus4_in,
    input [31:0] alu_out_in,      // ALU result (address for load/store, or result for writeback)
    input [31:0] store_data_in,   // possibly-forwarded rs2 value, for stores
    input [31:0] pc_target_in,    // pc_out + immsext (auipc result / branch target, reused for auipc writeback)
    input [31:0] immsext_in,      // needed for lui writeback
    input [4:0]  rd_in,

    input RegWrite_in, ALUorMem_in, WriteMem_in,
    input jalr_in, lui_in, auipc_in, jump_in,

    output reg [31:0] pc_plus4_out,
    output reg [31:0] alu_out_out,
    output reg [31:0] store_data_out,
    output reg [31:0] pc_target_out,
    output reg [31:0] immsext_out,
    output reg [4:0]  rd_out,

    output reg RegWrite_out, ALUorMem_out, WriteMem_out,
    output reg jalr_out, lui_out, auipc_out, jump_out
);
    always @(posedge clk) begin
        if (rst) begin
            pc_plus4_out <= 32'b0; alu_out_out <= 32'b0; store_data_out <= 32'b0;
            pc_target_out <= 32'b0; immsext_out <= 32'b0; rd_out <= 5'b0;
            RegWrite_out <= 1'b0; ALUorMem_out <= 1'b0; WriteMem_out <= 1'b0;
            jalr_out <= 1'b0; lui_out <= 1'b0; auipc_out <= 1'b0; jump_out <= 1'b0;
        end else begin
            pc_plus4_out <= pc_plus4_in;
            alu_out_out <= alu_out_in;
            store_data_out <= store_data_in;
            pc_target_out <= pc_target_in;
            immsext_out <= immsext_in;
            rd_out <= rd_in;
            RegWrite_out <= RegWrite_in;
            ALUorMem_out <= ALUorMem_in;
            WriteMem_out <= WriteMem_in;
            jalr_out <= jalr_in; lui_out <= lui_in; auipc_out <= auipc_in; jump_out <= jump_in;
        end
    end
endmodule
