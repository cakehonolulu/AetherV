module uart_tx
#(
    parameter CLK_FREQ = 27,       // clock frequency (MHz)
    parameter BAUD     = 115200    // serial baud rate
)
(
    input         clk,            // system clock
    input         rst,            // async reset, active‑low
    input  [7:0]  data,           // byte to send
    input         valid,          // byte is valid
    output reg    ready,          // ready for next byte
    output        tx              // serial line
);

    // number of clock cycles per baud tick
    localparam integer CYCLE = CLK_FREQ * 1_000_000 / BAUD;

    // transmitter states
    localparam S_IDLE      = 3'd1;
    localparam S_START     = 3'd2;
    localparam S_SEND_BYTE = 3'd3;
    localparam S_STOP      = 3'd4;

    reg [2:0] state;
    reg [31:0] cycle_cnt;       // *** widened to 32 bits ***
    reg [2:0]  bit_cnt;         // which data bit we're on
    reg [7:0]  tx_data_latch;   // holds the byte during transmission
    reg        tx_reg;          // drives the serial line
    reg        active;          // gating register

    assign tx = tx_reg;

    // Simplified UART transmitter with gating
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state         <= S_IDLE;
            cycle_cnt     <= 32'd0;
            bit_cnt       <= 3'd0;
            tx_data_latch <= 8'd0;
            tx_reg        <= 1'b1;
            ready         <= 1'b0;
            active        <= 1'b1;
        end else if (active) begin
            case (state)
                S_IDLE: begin
                    tx_reg <= 1'b1;
                    ready  <= !valid;
                    bit_cnt <= 3'd0;
                    cycle_cnt <= 32'd0;
                    if (valid) begin
                        tx_data_latch <= data;
                        state <= S_START;
                        ready <= 1'b0;
                    end
                end
                S_START: begin
                    tx_reg <= 1'b0;
                    if (cycle_cnt == CYCLE-1) begin
                        state <= S_SEND_BYTE;
                        cycle_cnt <= 32'd0;
                    end else begin
                        cycle_cnt <= cycle_cnt + 1;
                    end
                end
                S_SEND_BYTE: begin
                    tx_reg <= tx_data_latch[bit_cnt];
                    if (cycle_cnt == CYCLE-1) begin
                        cycle_cnt <= 32'd0;
                        if (bit_cnt == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        cycle_cnt <= cycle_cnt + 1;
                    end
                end
                S_STOP: begin
                    tx_reg <= 1'b1;
                    if (cycle_cnt == CYCLE-1) begin
                        state <= S_IDLE;
                        ready <= 1'b1;
                        cycle_cnt <= 32'd0;
                    end else begin
                        cycle_cnt <= cycle_cnt + 1;
                    end
                end
                default: begin
                    state <= S_IDLE;
                    tx_reg <= 1'b1;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
