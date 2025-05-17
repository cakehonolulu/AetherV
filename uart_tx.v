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

    reg [2:0] state, next_state;
    reg [31:0] cycle_cnt;       // *** widened to 32 bits ***
    reg [2:0]  bit_cnt;         // which data bit we're on
    reg [7:0]  tx_data_latch;   // holds the byte during transmission
    reg        tx_reg;          // drives the serial line

    assign tx = tx_reg;

    // Sequential state register
    always @(posedge clk or negedge rst) begin
        if (!rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Next‑state logic (combinational — use blocking “=”)
    always @(*) begin
        case (state)
            S_IDLE:
                if (valid) next_state = S_START;
                else       next_state = S_IDLE;
            S_START:
                if (cycle_cnt == CYCLE-1) next_state = S_SEND_BYTE;
                else                      next_state = S_START;
            S_SEND_BYTE:
                if (cycle_cnt == CYCLE-1 && bit_cnt == 3'd7)
                    next_state = S_STOP;
                else
                    next_state = S_SEND_BYTE;
            S_STOP:
                if (cycle_cnt == CYCLE-1) next_state = S_IDLE;
                else                      next_state = S_STOP;
            default:
                next_state = S_IDLE;
        endcase
    end

    // drive “ready”
    always @(posedge clk or negedge rst) begin
        if (!rst)
            ready <= 1'b0;
        else if (state == S_IDLE)
            ready <= !valid;
        else if (state == S_STOP && cycle_cnt == CYCLE-1)
            ready <= 1'b1;
    end

    // latch the data byte
    always @(posedge clk or negedge rst) begin
        if (!rst)
            tx_data_latch <= 8'd0;
        else if (state == S_IDLE && valid)
            tx_data_latch <= data;
    end

    // count bits during S_SEND_BYTE
    always @(posedge clk or negedge rst) begin
        if (!rst)
            bit_cnt <= 3'd0;
        else if (state == S_SEND_BYTE) begin
            if (cycle_cnt == CYCLE-1)
                bit_cnt <= bit_cnt + 3'd1;
        end else
            bit_cnt <= 3'd0;
    end

    // baud‑rate counter — all literals widened to 32 bits
    always @(posedge clk or negedge rst) begin
        if (!rst)
            cycle_cnt <= 32'd0;
        else if ((state == S_SEND_BYTE && cycle_cnt == CYCLE-1)
                 || next_state != state)
            cycle_cnt <= 32'd0;
        else
            cycle_cnt <= cycle_cnt + 32'd1;
    end

    // generate TX line
    always @(posedge clk or negedge rst) begin
        if (!rst)
            tx_reg <= 1'b1;
        else begin
            case (state)
                S_IDLE, S_STOP:    tx_reg <= 1'b1;              // idle or stop bit
                S_START:           tx_reg <= 1'b0;              // start bit
                S_SEND_BYTE:       tx_reg <= tx_data_latch[bit_cnt];
                default:           tx_reg <= 1'b1;
            endcase
        end
    end

endmodule
