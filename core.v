module core (
    input         clk,
    input         rst_i,
    output [31:0] pc_out,
    output [31:0] instr_out,
    output        error
);
    // FETCH
    wire [31:0] next_pc;
    wire        pc_sel;
    reg         halt = 0;

    pc #(.WIDTH(32)) u_pc (
        .clk(clk), .rst_i(rst_i),
        .next_pc(next_pc), .pc_sel(pc_sel),
        .halt(halt), .pc(pc_out)
    );
    instr_mem #(.ADDR_WIDTH(10)) u_imem (
        .addr(pc_out[11:2]), .instr(instr_out)
    );

    // DECODE
    wire [6:0] opcode = instr_out[6:0];
    wire [2:0] funct3 = instr_out[14:12];
    wire [6:0] funct7 = instr_out[31:25];
    wire [4:0] rd     = instr_out[11:7], rs1 = instr_out[19:15], rs2 = instr_out[24:20];
    wire        we, use_imm;
    wire [3:0]  alu_op;
    wire [31:0] imm;
    control_unit u_ctrl (
        .opcode(opcode), .funct3(funct3), .funct7(funct7), .instr(instr_out),
        .we(we), .use_imm(use_imm), .alu_op(alu_op), .imm(imm),
        .error(error)
    );

    // EXECUTE & WB
    wire [31:0] reg_rs1, reg_rs2, alu_b, alu_out;
    assign alu_b = use_imm ? imm : reg_rs2;
    regfile u_rf (
        .clk(clk), .we(we), .ra1(rs1), .ra2(rs2),
        .wa(rd), .wd(alu_out), .rd1(reg_rs1), .rd2(reg_rs2)
    );
    alu u_alu (
        .a(reg_rs1), .b(alu_b), .opcode(alu_op), .y(alu_out)
    );

    assign next_pc = pc_out + 4;
    assign pc_sel  = 1'b0;
endmodule