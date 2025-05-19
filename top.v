module top (
    input        clk,
    input        rst_i,
    output [5:0] led,
    output       TXD
);
    // POR + button reset
    localparam POR_BITS = 12;
    reg [POR_BITS-1:0] por_cnt = 0;
    wire por_done = &por_cnt;
    always @(posedge clk) if (!por_done) por_cnt <= por_cnt + 1;
    wire rst_l = ~(rst_i | ~por_done);

    wire [31:0] pc, instr;
    wire        error;

    wire [7:0] logger_uart_data;
    wire       logger_uart_valid, logger_uart_ready;

    // System active: run until error and logger is done
    wire system_active = !error || logger_uart_valid;

    core u_core (
        .clk      (clk),
        .rst_i    (rst_l),
        .system_active(system_active),
        .pc_out   (pc),
        .instr_out(instr),
        .error    (error)
    );

    logger_uart u_logger (
        .clk(clk),
        .rst(rst_l),
        .error(error),
        .instr_in(instr),
        .pc_in(pc),
        .uart_data(logger_uart_data),
        .uart_valid(logger_uart_valid),
        .uart_ready(logger_uart_ready)
    );

    uart_peripheral u_uart (
        .clk(clk),
        .rst(rst_l),
        .data_in(logger_uart_data),
        .data_valid(logger_uart_valid),
        .data_ready(logger_uart_ready),
        .tx(TXD)
    );

    led_driver u_led (
        .pc    (pc),
        .error (error),
        .system_active(system_active),
        .led   (led)
    );
endmodule