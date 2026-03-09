module instruction_mem #(parameter inum = 64) (input [$clog2(inum)-1:0] instaddr,output reg [31:0]inst);
    // always do $clog when addressing. dont hardcode.
    reg [31:0] imem [inum-1:0];
    initial $readmemh("program.hex", imem); // added this
    // about this line:
    // $readmemh("file.hex", array) - loads hex file into memory array at sim start
    // each line in file = one 32bit instruction in hex (no 0x prefix)
    // runs once at time 0 before simulation begins
    // for FPGA replace with proper memory initialization
    // this is for loading the memory with all risc v instructions
    always @(*) begin
        inst = imem[instaddr];
    end
endmodule