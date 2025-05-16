module pc #(
    parameter WIDTH = 32
) (
    input                  clk,
    input                  rst_i,
    input  [WIDTH-1:0]     next_pc,
    input                  pc_sel,
    input                  halt,
    output reg [WIDTH-1:0] pc
);
    always @(posedge clk or negedge rst_i) begin
        if (!rst_i)
            pc <= 0;
        else if (!halt) begin
            if (pc_sel)
                pc <= next_pc;
            else
                pc <= pc + 4;
        end
    end
endmodule
