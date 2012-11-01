`include "constants.vh"

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

    wire [9:0] h_sync_cnt;
    wire [9:0] v_sync_cnt;

    reg [3:0] vga_r = 0;
    reg [3:0] vga_g = 0;
    reg [3:0] vga_b = 0;

    wire vga_clk;

    wire vga_hs;
    wire vga_vs;

    always @ (posedge vga_clk) begin
        if (h_sync_cnt == 600 && v_sync_cnt == 400) begin
            vga_r <= 4'd15;
            vga_g <= 4'd0;
            vga_b <= 4'd0;
        end

    end

    assign VGA_R = vga_r;
    assign VGA_G = vga_g;
    assign VGA_B = vga_b;

vga_timing vga_timing (
    .clk_50(clk),
    .rst(rst),
    //.vga_r(VGA_R),
    //.vga_g(VGA_G),
    //.vga_b(VGA_B),
    .vga_hs(VGA_HS),
    .vga_vs(VGA_VS),
    .h_sync_cnt(h_sync_cnt),
    .v_sync_cnt(v_sync_cnt),
    .vga_clk(vga_clk)
);

endmodule
