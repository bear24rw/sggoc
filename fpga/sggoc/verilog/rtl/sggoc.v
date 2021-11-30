module sggoc(
    input clk,
    input rst,

    output ram_we,
    output [7:0] ram_di,
    input [7:0] ram_do,
    output [12:0] ram_addr,

    output [21:0] rom_addr,
    input  [ 7:0] rom_do,

    input start_button,

    input joypad_up,
    input joypad_down,
    input joypad_left,
    input joypad_right,
    input joypad_a,
    input joypad_b,

    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);

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
    wire z80_m1_n;
    wire z80_int_n;

    tv80s z80(
        .clk(clk),
        .reset_n(~rst),

        .rd_n(z80_rd_n),
        .wr_n(z80_wr_n),
        .mreq_n(z80_mreq_n),
        .iorq_n(z80_iorq_n),

        .A(z80_addr),
        .di(z80_di),
        .dout(z80_do),

        .m1_n(z80_m1_n),
        .int_n(z80_int_n),

        .nmi_n(1'b1),
        .busrq_n(1'b1),
        .wait_n(1'b1),

        .halt_n(),
        .busak_n(),
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

    wire [7:0] cart_di;
    //wire [7:0] cart_do;
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
        .cart_do(rom_do),
        .cart_addr(cart_addr),

        .io_do(io_do)
    );

    // ----------------------------------------------------
    //                  MEM MAPPER
    // ----------------------------------------------------

    mem_mapper mem_mapper (
        .clk(clk),
        .rst(rst),
        .wr(z80_mem_wr),

        .di(cart_di),
        .addr(cart_addr),
        .rom_addr(rom_addr)
    );

    // ----------------------------------------------------
    //                      IO
    // ----------------------------------------------------

    wire [7:0] io_do;

    io io(
        .clk(clk),
        .rst(rst),

        .io_do(io_do),

        .z80_do(z80_do),
        .z80_addr(z80_addr),
        .z80_io_rd(z80_io_rd),
        .z80_io_wr(z80_io_wr),

        .vdp_data_rd(vdp_data_rd),
        .vdp_data_wr(vdp_data_wr),
        .vdp_data_o(vdp_data_o),

        .vdp_control_rd(vdp_control_rd),
        .vdp_control_wr(vdp_control_wr),
        .vdp_control_o(vdp_control_o),

        .vdp_v_counter(vdp_v_counter),
        .vdp_h_counter(vdp_h_counter),

        .start_button(start_button),

        .joypad_up(joypad_up),
        .joypad_down(joypad_down),
        .joypad_left(joypad_left),
        .joypad_right(joypad_right),
        .joypad_a(joypad_a),
        .joypad_b(joypad_b)
    );

    // ----------------------------------------------------
    //                          VDP
    // ----------------------------------------------------

    wire [7:0] vdp_v_counter;
    wire [7:0] vdp_h_counter;
    wire       vdp_control_wr;
    wire       vdp_control_rd;
    wire [7:0] vdp_control_o;
    wire       vdp_data_wr;
    wire       vdp_data_rd;
    wire [7:0] vdp_data_o;

    vdp vdp(
        .clk_50(clk),
        .z80_clk(clk),
        .rst(rst),

        .control_wr(vdp_control_wr),
        .control_rd(vdp_control_rd),
        .control_o(vdp_control_o),
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

    /*
    initial begin
        $monitor("rst: %d | addr: %x | io r:%x w:%x | mem r:%x w:%x | di: %x | do: %d",
            rst, z80_addr,
            z80_io_rd, z80_io_wr,
            z80_mem_rd, z80_mem_wr,
            z80_di, z80_do);
    end
    */

endmodule

