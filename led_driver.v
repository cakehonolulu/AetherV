module led_driver (
    input  [31:0] pc,
    input         error,
    input         system_active,
    output [5:0]  led
);
    wire [5:0] data = pc[31:26];
    assign led = (system_active && !error) ? ~data : 6'b111111;
endmodule