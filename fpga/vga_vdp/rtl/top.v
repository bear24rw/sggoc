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

    output [35:0] GPIO_1,

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
    //                      VDP VRAM
    // ----------------------------------------------------

    reg [13:0] vram_addr_a;
    wire [13:0] vram_addr_b;
    wire [7:0] vram_do_a;
    wire [7:0] vram_do_b;
    reg [7:0] vram_di_a;
    reg [7:0] vram_di_b;
    reg vram_we_a;
    reg vram_we_b;

    vram vram(
        // port a = uart side
        .clk_a(vga_clk),
        .we_a(vram_we_a),
        .addr_a(vram_addr_a),
        .do_a(vram_do_a),
        .di_a(vram_di_a),

        // port b = vdp side
        .clk_b(~vga_clk),
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

    always @(posedge vga_clk, posedge rst) begin
        if (rst) begin
            tx_data <= 0;
            transmit <= 0;
            vram_we_a <= 0;
            vram_addr_a <= 0;
            state <= S_IDLE;
        end else begin
            case (state)

                S_IDLE: begin
                    if (start) begin
                        state <= S_REQUEST;
                    end
                end

                // we want to request the next byte.
                // trigger the uart to transmit and
                // then go to RECV state to wait for
                // the data
                S_REQUEST: begin
                    transmit <= 1;
                    state <= S_RECV;
                end

                // clear the transmit flag so we only
                // transmit one byte. check to see if
                // we recieved a new byte
                S_RECV: begin
                    transmit <= 0;

                    // if we got a new byte, send it back to ACK.
                    // go to WRITE to put it in flash
                    if (new_byte) begin
                        vram_we_a <= 1;
                        tx_data <= rx_data;
                        state <= S_WRITE;
                    end
                end

                S_WRITE: begin
                    vram_di_a <= rx_data;
                    state <= S_WRITE_WAIT;
                end

                S_WRITE_WAIT: begin
                    vram_we_a <= 0;
                    vram_addr_a <= vram_addr_a + 1;
                    state <= S_REQUEST;
                end

            endcase
        end
    end

    // ----------------------------------------------------
    //                      VDP REGISTERS
    // ----------------------------------------------------

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

    // name table base address
    wire [13:0] nt_base_addr = {r[2][3:1], 11'd0};

    // ----------------------------------------------------
    //                      VDP BACKGROUND
    // ----------------------------------------------------

    wire [4:0] bg_color;
    wire priority;

    vdp_background vdp_background(
        .clk(vga_clk),
        .rst(rst),
        .x(pixel_x),
        .y(pixel_y),
        .name_table_addr(nt_base_addr),
        .vram_a(vram_addr_b),
        .vram_d(vram_do_b),
        .color(bg_color),
        .priority(priority)
    );

    // ----------------------------------------------------
    //                      VDP CRAM
    // ----------------------------------------------------

    reg [7:0] CRAM [0:63];

    initial begin
        $readmemh("osmose.cram.linear", CRAM);
    end

    // ----------------------------------------------------
    //                  OUTPUT LOGIC
    // ----------------------------------------------------

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
                vga_r <= CRAM[bg_color][3:0];
                vga_g <= CRAM[bg_color][7:4];
                vga_b <= CRAM[bg_color+1][3:0];
            end else begin
                // color palette
                if (pixel_y >= 256 && pixel_x < 256) begin
                    vga_r <= CRAM[pixel_x[7:3]*2][3:0];
                    vga_g <= CRAM[pixel_x[7:3]*2][7:4];
                    vga_b <= CRAM[pixel_x[7:3]*2+1][3:0];
                end else begin
                    // grid lines
                    if (pixel_x[2:0] == 3'b111 || pixel_y[2:0] == 3'b111) begin
                        vga_g <= 4'hC;
                        vga_r <= 4'hC;
                        vga_b <= 4'hC;
                    end else begin
                        vga_g <= 4'h0;
                        vga_r <= 4'h0;
                        vga_b <= 4'h0;
                    end
                end

           end

        end else begin
            vga_r <= 4'd00;
            vga_g <= 4'd00;
            vga_b <= 4'd00;
        end
    end

    // ----------------------------------------------------
    //                      VGA TIMING
    // ----------------------------------------------------

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
    //assign LEDR = vram_addr_a[9:0];

    assign LEDR[0] = bg_color[0];
    assign LEDR[1] = bg_color[1];
    assign LEDR[2] = bg_color[2];
    assign LEDR[3] = bg_color[3];

    //seven_seg ss0(state, HEX0);
    //seven_seg ss3(bg_color[3:0], HEX3);
    //seven_seg ss2(CRAM[SW][3:0], HEX2);

   /*
   seven_seg ss0(vram_addr_b[3:0], HEX0);
   seven_seg ss1(vram_addr_b[7:4], HEX1);
   seven_seg ss2(vram_addr_b[11:8], HEX2);
   seven_seg ss3(vram_addr_b[13:12], HEX3);
   */

   //seven_seg ss0(vram_do_b[3:0], HEX0);
   //seven_seg ss1(vram_do_b[7:4], HEX1);

   seven_seg ss0(bg_color[3:0], HEX0);
   //seven_seg ss1(bg_color[4], HEX1);

    wire [7:0] debug;

    /*
    assign debug[0] = SW[0];
    assign debug[1] = SW[1];
    assign debug[2] = SW[2];
    assign debug[3] = SW[3];
    assign debug[5] = SW[4];
    */
    assign debug[0] = VGA_VS;
    assign debug[1] = VGA_HS;
    assign debug[2] = vram_do_b[2];
    assign debug[3] = vram_do_b[3];
    assign debug[4] = vram_do_b[4];
    assign debug[5] = vram_do_b[5];
    assign debug[6] = vram_do_b[6];
    assign debug[7] = vram_do_b[7];

    assign GPIO_1[25] = debug[0];
    assign GPIO_1[23] = debug[1];
    assign GPIO_1[21] = debug[2];
    assign GPIO_1[19] = debug[3];
    assign GPIO_1[17] = debug[4];
    assign GPIO_1[15] = debug[5];
    assign GPIO_1[13] = debug[6];
    assign GPIO_1[11] = debug[7];


endmodule
