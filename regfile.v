module regfile (
    input         clk,
    input         we,
    input  [4:0]  ra1,
    input  [4:0]  ra2,
    input  [4:0]  wa,
    input  [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2
);
    reg [31:0] rf [0:31];
    assign rd1 = (ra1 != 0) ? rf[ra1] : 32'd0;
    assign rd2 = (ra2 != 0) ? rf[ra2] : 32'd0;
    always @(posedge clk) begin
        if (we && wa != 0)
            rf[wa] <= wd;
    end
endmodule