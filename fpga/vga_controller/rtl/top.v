module top (
    input CLOCK_50,
    input [3:0] KEY,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);

wire rst = ~(KEY[0]);
wire clk = CLOCK_50;

wire [3:0] vga_r;
wire [3:0] vga_g;
wire [3:0] vga_b;

wire vga_hs;
wire vga_vs;

vga vga_timing (
    .clk_50(clk),
    .rst(rst),
    .vga_r(VGA_R),
    .vga_g(VGA_G),
    .vga_b(VGA_B),
    .vga_hs(VGA_HS),
    .vga_vs(VGA_VS)
);

endmodule
