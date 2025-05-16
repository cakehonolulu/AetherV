module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  opcode,   // simple ALU op code
    output reg [31:0] y
);
    always @* begin
        case (opcode)
            4'd0: y = a + b;    // ADD/ADDI
            4'd1: y = a - b;    // SUB
            // add more ops as needed
            default: y = 32'hDEADBEEF;
        endcase
    end
endmodule