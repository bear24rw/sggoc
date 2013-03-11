/***************************************************************************
 *   Copyright (C) 2012 by Max Thrun                                       *
 *   Copyright (C) 2012 by Samir Silbak                                    *
 *                                                                         *
 *   (SSGoC) Sega Game Gear on a Chip                                      *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.              *
 ***************************************************************************/

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
    output FL_RST_N,

    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,

    output VGA_HS,
    output VGA_VS,

    input UART_RXD,
    output UART_TXD,

    output [35:0] GPIO_1
);

    // ----------------------------------------------------
    //                  KEY MAPPING
    // ----------------------------------------------------

    wire rst = SW[9];

    // ----------------------------------------------------
    //                  CLOCK DIVIDER
    // ----------------------------------------------------

    wire z80_clk;

    //clk_div #(.COUNT(7)) clk_div(CLOCK_50, cpu_clk);
    clk_div #(.COUNT(8)) clk_div(CLOCK_50, z80_clk);

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
    wire z80_nmi_n = 1;
    wire z80_busak_n;
    wire z80_busrq_n = 1;

    tv80s z80(
        .clk(z80_clk),
        .reset_n(~rst),

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
        .busak_n(z80_busak_n),
        .rfsh_n()
    );

    wire z80_mem_rd = (!z80_mreq_n && !z80_rd_n);
    wire z80_mem_wr = (!z80_mreq_n && !z80_wr_n);
    wire z80_io_rd = (!z80_iorq_n && !z80_rd_n);
    wire z80_io_wr = (!z80_iorq_n && !z80_wr_n);
    wire z80_irq_rd = (!z80_iorq_n && !z80_m1_n);

    // ----------------------------------------------------
    //                      MMU
    // ----------------------------------------------------

    wire ram_we;
    wire [7:0] ram_di;
    wire [7:0] ram_do;
    wire [12:0] ram_addr;

    wire [7:0] cart_di;
    wire [7:0] cart_do;
    wire [15:0] cart_addr;

    mmu mmu(
        .z80_di(z80_di),
        .z80_do(z80_do),
        .z80_addr(z80_addr),

        .z80_mem_rd(z80_mem_rd),
        .z80_mem_wr(z80_mem_wr),
        .z80_io_rd(z80_io_rd),
        .z80_io_wr(z80_io_wr),
        .z80_irq_rd(z80_irq_rd),

        .ram_we(ram_we),
        .ram_di(ram_di),
        .ram_do(ram_do),
        .ram_addr(ram_addr),

        .cart_di(cart_di),
        .cart_do(cart_do),
        .cart_addr(cart_addr),

        .vdp_control_wr(vdp_control_wr),
        .vdp_control_rd(vdp_control_rd),
        .vdp_status(vdp_status),

        .vdp_data_wr(vdp_data_wr),
        .vdp_data_rd(vdp_data_rd),
        .vdp_data_o(vdp_data_o),

        .vdp_v_counter(vdp_v_counter),
        .vdp_h_counter(vdp_h_counter)
    );

    // ----------------------------------------------------
    //                      RAM
    // ----------------------------------------------------

    ram sys_ram(
        .clk(z80_clk),
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
        .rst(rst),
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
    //                          VDP
    // ----------------------------------------------------

    wire [7:0] vdp_v_counter;
    wire [7:0] vdp_h_counter;
    wire       vdp_control_wr;
    wire       vdp_control_rd;
    wire [7:0] vdp_status;
    wire       vdp_data_wr;
    wire       vdp_data_rd;
    wire [7:0] vdp_data_o;

    vdp vdp(
        .clk_50(CLOCK_50),
        .clk(z80_clk),
        .rst(rst),

        .control_wr(vdp_control_wr),
        .control_rd(vdp_control_rd),
        .status(vdp_status),
        .control_i(z80_do),

        .data_wr(vdp_data_wr),
        .data_rd(vdp_data_rd),
        .data_o(vdp_data_o),
        .data_i(z80_do),

        .irq_n(z80_int_n),
        .vdp_v_counter(vdp_v_counter),
        .vdp_h_counter(vdp_h_counter),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS)
    );

    // ----------------------------------------------------
    //                  DEBUG DISPLAY
    // ----------------------------------------------------

    reg [7:0] z80_debug;

    always @(posedge z80_clk) begin
        if (z80_addr[7:0] == 'h1 && z80_io_wr)
            z80_debug <= z80_do;
    end

    assign LEDR = z80_debug;

    wire [7:0] seg0 = rst ? 'hF : z80_addr[3:0];
    wire [7:0] seg1 = rst ? 'hE : z80_addr[7:4];
    wire [7:0] seg2 = rst ? 'hE : z80_addr[11:8];
    wire [7:0] seg3 = rst ? 'hB : z80_addr[15:12];

    seven_seg s0(seg0, HEX0);
    seven_seg s1(seg1, HEX1);
    seven_seg s2(seg2, HEX2);
    seven_seg s3(seg3, HEX3);

    assign LEDG[0] = z80_m1_n;
    assign LEDG[1] = z80_mreq_n;
    assign LEDG[2] = z80_iorq_n;
    assign LEDG[3] = z80_rd_n;
    assign LEDG[4] = z80_wr_n;
    assign LEDG[5] = z80_halt_n;
    assign LEDG[6] = z80_wait_n;
    assign LEDG[7] = z80_clk;

    //assign LEDG = z80_di;

    //wire [7:0] debug;

    //assign debug[0] = z80_clk;
    //assign debug[1] = z80_do;
    //assign debug[2] = vdp_control_rd;
    //assign debug[3] = vdp_control_wr;
    //assign debug[4] = vdp_status;
    //assign debug[5] = vdp_data_rd;
    //assign debug[6] = vdp_data_wr;
    //assign debug[7] = vdp_data_o;

    //assign GPIO_1[25] = debug[0];
    //assign GPIO_1[23] = debug[1];
    //assign GPIO_1[21] = debug[2];
    //assign GPIO_1[19] = debug[3];
    //assign GPIO_1[17] = debug[4];
    //assign GPIO_1[15] = debug[5];
    //assign GPIO_1[13] = debug[6];
    //assign GPIO_1[11] = debug[7];

endmodule
