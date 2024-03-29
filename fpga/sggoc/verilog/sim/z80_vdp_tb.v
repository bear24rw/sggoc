`define TV80_CORE_PATH z80_vdp_tb.z80.i_tv80_core

module z80_vdp_tb;

    reg z80_clk = 0;
    reg z80_rst = 0;

    // ----------------------------------------------------
    //                      CLOCK
    // ----------------------------------------------------

    always
        z80_clk = #1 ~z80_clk;

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
    wire z80_wait_n = 1;

    wire z80_m1_n;
    wire z80_halt_n;
    wire z80_int_n = 1;
    wire z80_nmi_n = 1;
    wire z80_busak_n;
    wire z80_busrq_n = 1;

    tv80s z80(
        .clk(z80_clk),
        .reset_n(~z80_rst),

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
    wire [15:0] cart_addr;

    mmu mmu(
        .z80_di(z80_di),
        .z80_do(z80_do),
        .z80_addr(z80_addr),

        .z80_mem_rd(z80_mem_rd),
        .z80_mem_wr(z80_mem_wr),
        .z80_io_rd(z80_io_rd),
        .z80_io_wr(z80_io_wr),

        .ram_we(ram_we),
        .ram_di(ram_di),
        .ram_do(ram_do),
        .ram_addr(ram_addr),

        .cart_di(cart_di),
        .cart_do(cart_do),
        .cart_addr(cart_addr),

        .vdp_control_wr(vdp_control_wr),
        .vdp_control_rd(vdp_control_rd),
        .vdp_control_o(vdp_control_o),

        .vdp_data_wr(vdp_data_wr),
        .vdp_data_rd(vdp_data_rd),
        .vdp_data_o(vdp_data_o),

        .vdp_v_counter(vdp_v_counter),
        .vdp_h_counter(vdp_h_counter)
    );

    // ----------------------------------------------------
    //                      RAM
    // ----------------------------------------------------

    async_mem ram (
        .addr(z80_addr[14:0]),

        .rd_cs(1),
        .rd_data(ram_do),

        .wr_cs(ram_we),
        .wr_data(ram_di),
        .wr_clk(z80_clk)
    );

    // ----------------------------------------------------
    //                      ROM
    // ----------------------------------------------------

    async_mem rom (
        .addr(z80_addr[14:0]),

        .rd_cs(1),
        .rd_data(cart_do),

        .wr_cs(0),
        .wr_data(0),
        .wr_clk(0)
    );

    initial begin
        $readmemh("main.gg.linear", z80_vdp_tb.rom.mem);
    end

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
        .clk_50(z80_clk),
        .clk(z80_clk),
        .rst(z80_rst),

        .control_wr(vdp_control_wr),
        .control_rd(vdp_control_rd),
        .control_o(vdp_control_o),
        .control_i(z80_do),

        .data_wr(vdp_data_wr),
        .data_rd(vdp_data_rd),
        .data_o(vdp_data_o),
        .data_i(z80_do),

        .vdp_v_counter(),
        .vdp_h_counter(),

        .VGA_R(),
        .VGA_G(),
        .VGA_B(),
        .VGA_HS(),
        .VGA_VS()
    );

    // ----------------------------------------------------
    //                      DEBUG
    // ----------------------------------------------------

    reg [7:0] z80_debug;

    always @(posedge z80_clk) begin
        if (z80_addr[7:0] == 'h01 && z80_io_wr)
            z80_debug <= z80_do;
    end

    // ----------------------------------------------------
    //                      SIM
    // ----------------------------------------------------

    integer idx;
    initial begin
        $dumpfile("z80_vdp_tb.vcd");
        $dumpvars(0, z80_vdp_tb);
        //for (idx=0; idx<(2**14)-1; idx=idx+1) $dumpvars(0, vdp.vram.ram[idx]);
    end

    initial begin
        /*
        $monitor("rst: %d | addr: %x | io r:%x w:%x | mem r:%x w:%x | di: %x | do: %d | debug: %d",
            z80_rst, z80_addr,
            z80_io_rd, z80_io_wr,
            z80_mem_rd, z80_mem_rd,
            z80_di, z80_do,
            z80_debug);
        */
        $monitor("second byte: %d", vdp.second_byte);
        #100 z80_rst = 0;
        #100 z80_rst = 1;
        #100 z80_rst = 0;
        #100000;
        $finish;
    end

    reg [7:0] state;
    initial
        state = 0;

    op_decode op_d();
/*
    always @(posedge z80_clk)
    begin : inst_decode
        if ((`TV80_CORE_PATH.mcycle[6:0] == 1) &&
            (`TV80_CORE_PATH.tstate[6:0] == 8))
        begin
            op_d.decode (`TV80_CORE_PATH.IR[7:0], state);
        end
        else if (`TV80_CORE_PATH.mcycle[6:0] != 1)
            state = 0;
    end
*/


endmodule
