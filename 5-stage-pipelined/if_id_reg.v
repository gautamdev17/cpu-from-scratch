module if_id_reg (
    input clk, rst,
    input stall,   // hold current contents (freeze)
    input flush,   // insert bubble (nop)
    input [31:0] pc_in, pc_plus4_in, inst_in,
    output reg [31:0] pc_out, pc_plus4_out, inst_out
);
    always @(posedge clk) begin
        if (rst || flush) begin
            pc_out       <= 32'b0;
            pc_plus4_out <= 32'b0;
            inst_out     <= 32'b0; // all-zero decodes as R_type/ADD x0,x0,x0 -> harmless nop-ish, RegWrite still needs checking
        end else if (!stall) begin
            pc_out       <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            inst_out     <= inst_in;
        end
        // if stall and not flush: hold current values (do nothing)
    end
endmodule
