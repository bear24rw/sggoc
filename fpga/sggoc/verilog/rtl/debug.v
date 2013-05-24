module debug(
    input clk_50,
    input clk,
    input rst,
    input UART_RXD,
    output UART_TXD,
    output reg z80_clk,
    output reg z80_rst,
    input z80_mem_rd,
    input z80_mem_wr,
    input [15:0] z80_addr
);

    // ----------------------------------------------------
    //                      UART
    // ----------------------------------------------------

    reg transmit;
    wire rx_done;
    wire tx_done;

    wire [7:0] rx_data;
    reg [7:0] tx_data = 0;

    uart uart(
        .sys_clk(clk_50),
        .sys_rst(rst),

        .uart_rx(UART_RXD),
        .uart_tx(UART_TXD),

        .divisor(50000000/115200/16),

        .rx_data(rx_data),
        .tx_data(tx_data),

        .rx_done(rx_done),
        .tx_done(tx_done),

        .tx_wr(transmit)
    );

    // the receive line only goes high for one clock
    // cycle so we need to latch it. if we are currently
    // transmitting we obviously don't have a new byte yet

    reg new_byte = 0;

    always @(posedge rst, posedge transmit, posedge rx_done) begin
        if (rst)
            new_byte <= 0;
        else if (transmit)
            new_byte <= 0;
        else
            new_byte <= 1;
    end

    // the tx_done line only goes high for one clock
    // cycle so we need to latch it. if we are currently
    // transmitting we obviously haven't finished sending it

    reg tx_done_latched = 0;

    always @(posedge rst, posedge transmit, posedge tx_done) begin
        if (rst)
            tx_done_latched <= 0;
        else if (transmit)
            tx_done_latched <= 0;
        else
            tx_done_latched <= 1;
    end

    // ----------------------------------------------------
    //                 STATE MACHINE
    // ----------------------------------------------------

    localparam S_CLK_LOW            = 0;    // pull z80 clock low
    localparam S_CLK_HIGH           = 1;    // pull z80 clock high
    localparam S_CHECK_NEW          = 2;    // check if z80 address changed
    localparam S_LOAD_ADDR_HIGH     = 3;    // load high byte of z80 address into tx buffer
    localparam S_UART_TX_HIGH       = 4;    // trigger uart tx
    localparam S_UART_TX_WAIT_HIGH  = 5;    // wait for uart to finish
    localparam S_LOAD_ADDR_LOW      = 6;    // load low byte z80 address into tx buffer
    localparam S_UART_TX_LOW        = 7;    // trigger uart tx
    localparam S_UART_TX_WAIT_LOW   = 8;    // wait for uart to finish

    reg [3:0] state = S_CLK_LOW;

    reg [15:0] old_z80_addr = 0;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tx_data <= 0;
            transmit <= 0;
            z80_clk <= 0;
            old_z80_addr = 0;
            state <= S_CLK_LOW;
        end else begin
            case (state)

                //
                // Pulse z80 clock
                //

                S_CLK_LOW: begin
                    z80_clk <= 0;
                    state <= S_CLK_HIGH;
                end

                S_CLK_HIGH: begin
                    z80_clk <= 1;
                    state <= S_CHECK_NEW;
                end

                //
                // Check if address changed
                //

                S_CHECK_NEW: begin
                    if (z80_mem_rd || z80_mem_wr) begin
                        if (z80_addr != old_z80_addr) begin
                            old_z80_addr <= z80_addr;
                            state <= S_LOAD_ADDR_HIGH;
                        end else begin
                            state <= S_CLK_LOW;
                        end
                    end else begin
                        state <= S_CLK_LOW;
                    end
                end

                //
                // Send high byte of address
                //

                S_LOAD_ADDR_HIGH: begin
                    tx_data <= z80_addr[15:8];
                    state <= S_UART_TX_HIGH;
                end

                S_UART_TX_HIGH: begin
                    transmit <= 1;
                    state = S_UART_TX_WAIT_HIGH;
                end

                S_UART_TX_WAIT_HIGH: begin
                    transmit = 0;
                    if (tx_done_latched) begin
                        state = S_LOAD_ADDR_LOW;
                    end
                end

                //
                // Send low byte of address
                //

                S_LOAD_ADDR_LOW: begin
                    tx_data <= z80_addr[7:0];
                    state <= S_UART_TX_LOW;
                end

                S_UART_TX_LOW: begin
                    transmit <= 1;
                    state = S_UART_TX_WAIT_LOW;
                end

                S_UART_TX_WAIT_LOW: begin
                    transmit = 0;
                    if (tx_done_latched) begin
                        state = S_CLK_LOW;
                    end
                end
            endcase
        end
    end

endmodule
