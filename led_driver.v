module led_driver (
    input  [31:0] pc,
    input         error,
    output [5:0]  led
);
    wire [5:0] data = pc[31:26];
    assign led = error ? 6'b111111 : ~data;
endmodule