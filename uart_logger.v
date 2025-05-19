module logger_uart #(
    parameter CLK_FREQ = 27,
    parameter BAUD     = 115200
)(
    input        clk,
    input        rst,
    input        error,
    input [31:0] instr_in,
    input [31:0] pc_in,
    output reg  [7:0] uart_data,
    output reg        uart_valid,
    input             uart_ready
);
    localparam MSG_LEN = 50;
    localparam PREFIX_LEN = 26;
    localparam SUFFIX_LEN = 8;
    localparam PC_LEN = 8;
    
    // Message prefix as a string
    localparam [8*PREFIX_LEN-1:0] PREFIX = {
        "RV32I: Unhandled opcode 0x"
    };
    localparam [8*SUFFIX_LEN-1:0] SUFFIX = {
        " @ PC 0x"
    };

    reg [31:0] instr_reg, pc_reg;
    reg [5:0] byte_idx;

    // State machine for logger
    localparam S_IDLE = 2'd0, S_SEND = 2'd1, S_DONE = 2'd2;
    reg [1:0] state;

    // Hex digit to ASCII
    function [7:0] hx;
        input [3:0] d;
        hx = (d < 10) ? (8'd48 + {4'b0, d}) : (8'd55 + {4'b0, d});
    endfunction

    // Sequential logic
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state      <= S_IDLE;
            instr_reg  <= 32'd0;
            pc_reg     <= 32'd0;
            byte_idx   <= 0;
            uart_valid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    uart_valid <= 1'b0;
                    if (error) begin
                        state     <= S_SEND;
                        instr_reg <= instr_in;
                        pc_reg    <= pc_in;
                        byte_idx  <= 0;
                    end
                end
                S_SEND: begin
                    uart_valid <= 1'b1;
                    if (uart_valid && uart_ready) begin
                        if (byte_idx == MSG_LEN-1)
                            state <= S_DONE;
                        byte_idx <= byte_idx + 1;
                    end
                end
                S_DONE: begin
                    uart_valid <= 1'b0;
                end
                default: begin
                    state <= S_IDLE;
                    uart_valid <= 1'b0;
                end
            endcase
        end
    end

    // Combinational logic for uart_data
    always @(*) begin
        if (state != S_SEND || byte_idx >= MSG_LEN) begin
            uart_data = 8'h00;
        end else if (byte_idx < PREFIX_LEN) begin
            uart_data = PREFIX[8*(PREFIX_LEN-1-byte_idx) +: 8];
        end else if (byte_idx < PREFIX_LEN + 8) begin
            uart_data = hx(instr_reg[4*(7-(byte_idx-PREFIX_LEN)) +: 4]);
        end else if (byte_idx < PREFIX_LEN + 8 + SUFFIX_LEN) begin
            uart_data = SUFFIX[8*(SUFFIX_LEN-1-(byte_idx-(PREFIX_LEN+8))) +: 8];
        end else begin
            uart_data = hx(pc_reg[4*(7-(byte_idx-(PREFIX_LEN+8+SUFFIX_LEN))) +: 4]);
        end
    end
endmodule
