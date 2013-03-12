module mem_mapper_tb;

    reg wr_n = 1;
    reg [15:0] addr = 0;
    reg [7:0] di = 0;

    wire [21:0] phy_addr;

    mem_mapper uut(
        .wr_n(wr_n),
        .addr(addr),
        .di(di),
        .physical_addr(phy_addr)
    );

    initial begin

        // loop through all the addresses
        for (addr=0; addr<'hFFFF; addr=addr+1) begin
            #1 $display("%4x | %x", addr, phy_addr);
        end

        $stop;
    end

endmodule


