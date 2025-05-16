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

    wire uart_tx;
    assign TXD = uart_tx;

    core u_core (
        .clk      (clk),
        .rst_i    (rst_l),
        .pc_out   (pc),
        .instr_out(instr),
        .error    (error),
        .uart_tx  (uart_tx)
    );

    led_driver u_led (
        .pc    (pc),
        .error (error),
        .led   (led)
    );
endmodule