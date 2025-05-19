// UART peripheral wrapper for uart_tx
module uart_peripheral #(
    parameter CLK_FREQ = 27,
    parameter BAUD     = 115200
) (
    input        clk,
    input        rst,
    input  [7:0] data_in,
    input        data_valid,
    output       data_ready,
    output       tx
);
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) u_uart_tx (
        .clk(clk),
        .rst(rst),
        .data(data_in),
        .valid(data_valid),
        .ready(data_ready),
        .tx(tx)
    );
endmodule
