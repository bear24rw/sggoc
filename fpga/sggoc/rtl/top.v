module top(
    input CLOCK_50,

    input [9:0] SW,
    input [3:0] KEY,

    output [9:0] LEDR,
    output [7:0] LEDG,

    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,

    inout [7:0] FL_DQ,
    output [21:0] FL_ADDR,
    output FL_OE_N,
    output FL_CE_N,
    output FL_WE_N,
    output FL_RST_N
);
    // ----------------------------------------------------
    //                  KEY MAPPING
    // ----------------------------------------------------

    wire reset_n = KEY[0];

    // ----------------------------------------------------
    //                  CLOCK DIVIDER
    // ----------------------------------------------------

    wire sys_clk;
    //clk_div #(.COUNT(7)) clk_div(CLOCK_50, sys_clk);
    clk_div clk_div(CLOCK_50, sys_clk);

    // ----------------------------------------------------
    //                      Z80
    // ----------------------------------------------------

    wire [15:0] z80_addr;
    wire [7:0] z80_di;
    wire [7:0] z80_do;
    wire z80_rd_n;
    wire z80_wr_n;
    wire z80_mreq_n;
    wire z80_iorq_n;
    wire z80_wait_n;

    wire z80_m1_n;
    wire z80_halt_n;
    wire z80_int_n;
    wire z80_nmi_n;
    wire z80_busak_n;
    wire z80_busrq_n = 1;

    tv80s z80(
        .clk(sys_clk),
        .reset_n(reset_n),

        .rd_n(z80_rd_n),
        .wr_n(z80_wr_n),
        .mreq_n(z80_mreq_n),
        .iorq_n(z80_iorq_n),
        .wait_n(z80_wait_n),

        .A(z80_addr),
        .di(z80_di),
        .dout(z80_do),

        .m1_n(z80_m1_n),
        .halt_n(z80_halt_n),
        .int_n(z80_int_n),
        .nmi_n(z80_nmi_n),
        .busrq_n(z80_busrq_n),
        .busak_n(z80_busak_n)
    );

    wire z80_mem_rd = (!z80_mreq_n && !z80_rd_n);
    wire z80_mem_wr = (!z80_mreq_n && !z80_wr_n);
    wire z80_io_rd = (!z80_iorq_n && !z80_rd_n);
    wire z80_io_wr = (!z80_iorq_n && !z80_wr_n);

    // ----------------------------------------------------
    //                      MMU
    // ----------------------------------------------------

    wire ram_we;
    wire [7:0] ram_di;
    wire [7:0] ram_do;
    wire [12:0] ram_addr;

    wire [7:0] cart_di;
    wire [7:0] cart_do;
    wire [21:0] cart_addr;

    mmu mmu(
        .z80_di(z80_di),
        .z80_do(z80_do),
        .z80_addr(z80_addr),

        .z80_mem_rd(z80_mem_rd),
        .z80_mem_wr(z80_mem_wr),
        .z80_io_rd(z80_io_rd),
        .z80_io_rd(z80_io_wr),

        .ram_we(ram_we),
        .ram_di(ram_di),
        .ram_do(ram_do),
        .ram_addr(ram_addr),

        .cart_di(cart_di),
        .cart_do(cart_do),
        .cart_addr(cart_addr)
    );

    // ----------------------------------------------------
    //                      RAM
    // ----------------------------------------------------

    ram sys_ram(
        .clk(CLOCK_50),
        .we(ram_we),
        .addr(ram_addr),
        .do(ram_do),
        .di(ram_di)
    );

    // ----------------------------------------------------
    //                  CARTRIDGE
    // ----------------------------------------------------

    cartridge cartridge(
        .clk(CLOCK_50),
        .rst(~reset_n),
        .rd(z80_mem_rd),
        .wr(z80_mem_wr),
        .wait_n(z80_wait_n),

        .addr(cart_addr),
        .di(cart_di),
        .do(cart_do),

        .FL_DQ(FL_DQ),
        .FL_ADDR(FL_ADDR),
        .FL_OE_N(FL_OE_N),
        .FL_CE_N(FL_CE_N),
        .FL_WE_N(FL_WE_N),
        .FL_RST_N(FL_RST_N)
    );

    // ----------------------------------------------------
    //                  DEBUG DISPLAY
    // ----------------------------------------------------

    seven_seg s0(z80_addr[3:0], HEX0);
    seven_seg s1(z80_addr[7:4], HEX1);
    seven_seg s2(z80_addr[11:8], HEX2);
    seven_seg s3(z80_addr[15:12], HEX3);

    assign LEDG[0] = z80_m1_n;
    assign LEDG[1] = z80_mreq_n;
    assign LEDG[2] = z80_iorq_n;
    assign LEDG[3] = z80_rd_n;
    assign LEDG[4] = z80_wr_n;
    assign LEDG[5] = z80_halt_n;

    assign LEDR = z80_di;

endmodule
