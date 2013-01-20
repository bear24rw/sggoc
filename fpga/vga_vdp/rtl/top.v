`include "constants.vh"

module top (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [7:0] LEDG,
    output [9:0] LEDR,

    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,

    input UART_RXD,
    output UART_TXD,

    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,

    output [1:0] GPIO_1,
    
    output VGA_HS,
    output VGA_VS
);

    wire clk = CLOCK_50;
    wire rst = ~(KEY[0]);
    wire start = ~KEY[3];

    // ----------------------------------------------------
    //                      UART
    // ----------------------------------------------------

    reg transmit;
    wire rx_done;
    wire tx_done;

    wire [7:0] rx_data;
    reg [7:0] tx_data = 0;

    uart uart(
        .sys_clk(clk),
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
    //                      RAM
    // ----------------------------------------------------

    reg [13:0] vram_addr_a;
    wire [13:0] vram_addr_b;
    wire [7:0] vram_do_a;
    wire [7:0] vram_do_b;
    reg [7:0] vram_di_a;
    reg [7:0] vram_di_b;
    reg vram_we_a;
    reg vram_we_b;

    ram vram( 
        .clk(vga_clk),

        // port a = uart side
        .we_a(vram_we_a),
        .addr_a(vram_addr_a),
        .do_a(vram_do_a),
        .di_a(vram_di_a),

        // port a = vdp side
        .we_b(1'b0),
        .addr_b(vram_addr_b),
        .do_b(vram_do_b),
        .di_b(vram_di_b)
    );


    // ----------------------------------------------------
    //                 STATE MACHINE
    // ----------------------------------------------------

    localparam S_IDLE       = 0;    // don't do anything, wait for reset
    localparam S_REQUEST    = 1;    // request next data byte from uart
    localparam S_RECV       = 2;    // wait for data byte
    localparam S_WRITE      = 3;    // write data to ram
    localparam S_WRITE_WAIT = 5;    // wait for write to finish

    reg [3:0] state = S_IDLE;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tx_data <= 0;
            transmit <= 0;
            vram_we_a = 0;
            vram_addr_a = 0;
            state <= S_IDLE;
        end else begin
            case (state)

                S_IDLE: begin
                    if (start) begin
                        state = S_REQUEST;
                    end
                end

                // we want to request the next byte.
                // trigger the uart to transmit and
                // then go to RECV state to wait for
                // the data
                S_REQUEST: begin
                    transmit = 1;
                    state = S_RECV;
                end

                // clear the transmit flag so we only
                // transmit one byte. check to see if
                // we recieved a new byte
                S_RECV: begin
                    transmit = 0;

                    // if we got a new byte, send it back to ACK.
                    // go to WRITE to put it in flash
                    if (new_byte) begin
                        tx_data = rx_data;
                        state = S_WRITE;
                    end
                end

                S_WRITE: begin
                    vram_di_a = rx_data;
                    vram_we_a = 1;
                    state = S_REQUEST;
                end

                S_WRITE_WAIT: begin
                    vram_we_a = 0;
                    vram_addr_a = vram_addr_a + 1;

                    state = S_REQUEST;
                end

            endcase
        end
    end



    // ----------------------------------------------------
    //                         VDP
    // ----------------------------------------------------

    wire [4:0] bg_color;

    vdp_background vdp_background(
        .clk(vga_clk),
        .rst(rst),
        .x(pixel_x),
        .y(pixel_y),
        .name_table_addr(nt_base_addr),
        .vram_a(vram_addr_b),
        .vram_d(vram_do_b),
        .color(bg_color)
    );

    reg [7:0] CRAM [0:63];

    initial begin
        $readmemh("osmose.cram.linear", CRAM);
    end

    reg [7:0] r [0:10];

    initial begin
        r[0] <= 'h26;   // mode control 1
        r[1] <= 'he2;   // mode control 2
        r[2] <= 'hff;   // name table base address
        r[3] <= 'hff;   // color table base address
        r[4] <= 'hff;   // background pattern generator base address
        r[5] <= 'hff;   // sprite attribute table base address
        r[6] <= 'hff;   // sprite pattern generator base address
        r[7] <= 'h00;   // overscan/backdrop color
        r[8] <= 'hf0;   // background X scroll
        r[9] <= 'h00;   // background Y scroll
        r[10] <= 'hff;  // line counter
    end

    // sprite attribute table base address
    wire [13:0] sat_base_addr = {r[5][6:1], 8'd0};

    // name table base address
    //wire [13:0] nt_base_addr = {r[2][3:1], 10'd0};
    wire [13:0] nt_base_addr = 14'h3800;

    // overscan / backdrop color
    wire [3:0] overscan_color = r[7][3:0];

    // starting column/row
    wire [4:0] starting_col = r[8][7:3];
    wire [4:0] starting_row = r[9][7:3];

    // fine x/y scroll
    wire [2:0] fine_x_scroll = r[8][2:0];
    wire [2:0] fine_y_scroll = r[9][2:0];

    reg [3:0] cram_idx = 0;

    wire [9:0] pixel_y;
    wire [9:0] pixel_x;

    reg [3:0] vga_r = 0;
    reg [3:0] vga_g = 0;
    reg [3:0] vga_b = 0;

    wire vga_clk;
    wire in_display_area;

    always @(posedge vga_clk) begin
        if (in_display_area) begin

            if (pixel_x < 256 && pixel_y < 192) begin
                if (bg_color == 5'b00000) begin
                    vga_r <= 4'hC;
                    vga_g <= 4'hC;
                    vga_b <= 4'hC;
                end else begin
                    vga_r <= CRAM[bg_color<<1][3:0];
                    vga_g <= CRAM[bg_color<<1][7:4];
                    vga_b <= CRAM[(bg_color<<1)+1][3:0];
                end
            end else begin
               vga_g <= 4'hF;
               vga_r <= 4'h0;
               vga_b <= 4'h0;
           end 

        end else begin
            vga_r <= 4'd00;
            vga_g <= 4'd00;
            vga_b <= 4'd00;
        end
    end

    assign VGA_R = vga_r;
    assign VGA_G = vga_g;
    assign VGA_B = vga_b;

    assign GPIO_1[0] = VGA_HS;
    assign GPIO_1[1] = VGA_VS;

    vga_timing vga_timing (
        .clk_50(clk),
        .rst(rst),
        .vga_hs(VGA_HS),
        .vga_vs(VGA_VS),
        .pixel_y(pixel_y),
        .pixel_x(pixel_x),
        .in_display_area(in_display_area),
        .vga_clk(vga_clk)
    );

    // ----------------------------------------------------
    //                  STATUS LEDS
    // ----------------------------------------------------

    assign LEDG[0] = rx_done;
    assign LEDG[1] = tx_done;
    assign LEDG[2] = transmit;
    assign LEDG[3] = new_byte;
    assign LEDR = vram_addr_a[9:0];

    seven_seg ss0(state, HEX0);

    seven_seg ss3(CRAM[bg_color][7:4], HEX3);
    seven_seg ss2(CRAM[bg_color][3:0], HEX2);

endmodule
