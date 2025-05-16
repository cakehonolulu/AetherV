module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,
    input  [31:0] instr,
    output reg        we,
    output reg        use_imm,
    output reg [3:0]  alu_op,
    output reg [31:0] imm,
    output reg        error
);
    always @(*) begin
        // Defaults
        we      = 0;
        use_imm = 0;
        alu_op  = 4'b0000;
        imm     = 32'd0;
        error   = 0;

        case (opcode)
            // ADDI (I‑type)
            7'b0010011: begin
                if (funct3 == 3'b000) begin
                    we      = 1;
                    use_imm = 1;
                    alu_op  = 4'b0000;              // ADD operation
                    // sign‑extend bits [31:20]
                    imm     = {{20{instr[31]}}, instr[31:20]};
                end else begin
                    error = 1;
                end
            end

            default: begin
                error = 1;
            end
        endcase
    end
endmodule