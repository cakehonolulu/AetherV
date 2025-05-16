/*
 * logger_uart.v
 *
 * Monitors the core error signal. On detecting a decoding/execution error,
 * prints over UART: "RV32I: Unhandled opcode 0x%08X @ PC 0x%08X" exactly once, then stops.
 */
module logger_uart #(
    parameter CLK_FREQ = 27,      // MHz
    parameter BAUD     = 115200    // baud rate
)(
    input        clk,            // system clock
    input        rst,            // active-low async reset
    input        error,          // error signal from core
    input [31:0] instr_in,       // instruction word
    input [31:0] pc_in,          // program counter at error
    output       tx              // UART transmit line
);

    // UART transmitter interface
    reg        uart_valid;
    wire       uart_ready;
    reg [7:0]  uart_data;

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(   BAUD)       
    ) u_uart_tx (
        .clk(clk),
        .rst(rst),
        .data(uart_data),
        .valid(uart_valid),
        .ready(uart_ready),
        .tx(tx)
    );

    // Total bytes: 26 prefix + 8 instr + 8 middle + 8 pc = 50
    localparam MSG_LEN = 50;

    // State
    reg        error_seen;
    reg        error_seen_d;
    reg [31:0] instr_reg;
    reg [31:0] pc_reg;
    reg [5:0]  byte_idx;

    // Capture rising error and latch data
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            error_seen   <= 1'b0;
            instr_reg    <= 32'd0;
            pc_reg       <= 32'd0;
            error_seen_d <= 1'b0;
        end else begin
            // delay register for one-cycle start
            error_seen_d <= error_seen;
            if (error && !error_seen) begin
                error_seen <= 1'b1;
                instr_reg  <= instr_in;
                pc_reg     <= pc_in;
            end
        end
    end

    // 4-bit to ASCII hex
    function [7:0] hx;
        input [3:0] d;
        begin hx = (d<10) ? 8'd48+d : 8'd55+d; end
    endfunction

    // Pick next byte
    always @(*) begin
        uart_data = 8'h00;
        if (!error_seen_d || byte_idx>=MSG_LEN) begin
            uart_data = 8'h00;
        end else if (byte_idx<26) begin
            // explicit prefix
            case (byte_idx)
                0: uart_data="R"; 1:uart_data="V"; 2:uart_data="3"; 3:uart_data="2";
                4:uart_data="I"; 5:uart_data=":"; 6:uart_data=" ";
                7:uart_data="U"; 8:uart_data="n"; 9:uart_data="h";
                10:uart_data="a";11:uart_data="n";12:uart_data="d";
                13:uart_data="l";14:uart_data="e";15:uart_data="d";
                16:uart_data=" ";
                17:uart_data="o";18:uart_data="p";19:uart_data="c";
                20:uart_data="o";21:uart_data="d";22:uart_data="e";
                23:uart_data=" ";
                24:uart_data="0";25:uart_data="x";
            endcase
        end else if (byte_idx<26+8) begin
            // instr hex
            uart_data = hx(instr_reg[4*(7-(byte_idx-26))+:4]);
        end else if (byte_idx<26+8+8) begin
            // middle " @ PC 0x"
            case(byte_idx-(26+8))
                0:uart_data=" ";
                1:uart_data="@";
                2:uart_data=" ";
                3:uart_data="P";
                4:uart_data="C";
                5:uart_data=" ";
                6:uart_data="0";
                7:uart_data="x";
            endcase
        end else begin
            // pc hex
            uart_data = hx(pc_reg[4*(7-(byte_idx-(26+8+8)))+:4]);
        end
    end

    // Drive valid & index, start one cycle after error
    reg uart_ready_d;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            uart_valid   <= 1'b0;
            byte_idx     <= 6'd0;
            uart_ready_d <= 1'b0;
        end else begin
            // only remember “ready” if we were already valid
            uart_ready_d <= uart_ready & uart_valid;

            if (error_seen_d && byte_idx < MSG_LEN) begin
            uart_valid <= 1'b1;
            // increment only when ready was asserted *while* we were valid last cycle
            if (uart_ready_d) begin
                byte_idx <= byte_idx + 1;
            end
            end else begin
            uart_valid <= 1'b0;
            end
        end
    end


endmodule
