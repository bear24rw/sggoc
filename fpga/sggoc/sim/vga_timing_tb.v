module vga_timing_tb ();

    reg clk = 0;
    reg rst = 0;
    wire vga_hs;
    wire vga_vs;
    wire vga_clk;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire in_display_area;

    vga_timing uut(
        .clk_50(clk),
        .rst(rst),
        .vga_hs(vga_hs),
        .vga_vs(vga_vs),
        .vga_clk(vga_clk),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .in_display_area(in_display_area)
    );

    always
        #1 clk = ~clk;

    initial begin
        $dumpfile("vga_timing_tb.vcd");
        $dumpvars(0, vga_timing_tb);
    end

    initial begin
        #5000000 $finish;
    end

endmodule

