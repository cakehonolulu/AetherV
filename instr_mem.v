module instr_mem #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input  [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] instr
);
    // 2^ADDR_WIDTH entries
    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    initial $readmemh("prog.hex", mem);
    assign instr = mem[addr];
endmodule