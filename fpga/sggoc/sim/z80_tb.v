`define TV80_CORE_PATH z80_tb.z80.i_tv80_core

module z80_tb;

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

    //assign z80_di = ROM[z80_addr];

    wire rom_rd_cs = !z80_mreq_n & !z80_rd_n & !z80_addr[15];
    wire ram_rd_cs = !z80_mreq_n & !z80_rd_n &  z80_addr[15];
    wire ram_wr_cs = !z80_mreq_n & !z80_wr_n &  z80_addr[15];


    // ----------------------------------------------------
    //                      RAM
    // ----------------------------------------------------

    async_mem ram (
        // Outputs
        .rd_data(z80_di),
        // Inputs
        .wr_clk(z80_clk),
        .wr_data(z80_do),
        .wr_cs(ram_wr_cs),
        .addr(z80_addr[14:0]),
        .rd_cs(ram_rd_cs)
    );

    // ----------------------------------------------------
    //                      ROM
    // ----------------------------------------------------

    async_mem rom (
        // Outputs
        .rd_data(z80_di),
        // Inputs
        .wr_clk(),
        .wr_data(),
        .wr_cs(1'b0),
        .addr(z80_addr[14:0]),
        .rd_cs(rom_rd_cs)
    );

    initial begin
        $readmemh("main.gg.linear", z80_tb.rom.mem);
    end


    // ----------------------------------------------------
    //                      IO
    // ----------------------------------------------------

    reg [7:0] z80_debug;

    always @(posedge z80_clk) begin
        if (z80_addr[7:0] == 'h01 && z80_io_wr)
            z80_debug <= z80_do;
    end

    // ----------------------------------------------------
    //                      SIM
    // ----------------------------------------------------

    initial begin
        $dumpfile("z80_tb.vcd");
        $dumpvars(0, z80_tb);
    end

    initial begin
        $monitor("rst: %d | addr: %x | io r:%x w:%x | mem r:%x w:%x | di: %x | do: %d | debug: %d",
            z80_rst, z80_addr,
            z80_io_rd, z80_io_wr,
            z80_mem_rd, z80_mem_rd,
            z80_di, z80_do,
            z80_debug);
        #100 z80_rst = 0;
        #100 z80_rst = 1;
        #100 z80_rst = 0;
        #10000;
        $finish;
    end

    reg [7:0] state;
    initial
        state = 0;

    op_decode op_d();

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


endmodule
