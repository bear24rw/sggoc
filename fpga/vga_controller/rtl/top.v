`include "constants.vh"

module top (
    input CLOCK_50,
    input [3:0] KEY,

    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,

    output [1:0] GPIO_1,
    
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

    always @(posedge vga_clk) begin
        if (h_sync_cnt >= `h_visible_cnt && h_sync_cnt < `h_back_porch_cnt &&
            v_sync_cnt >= `v_visible_cnt && v_sync_cnt < `v_back_porch_cnt) begin
            vga_r <= 4'd15;
            vga_g <= 4'd00;
            vga_b <= 4'd00;
        end
    end

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
        .h_sync_cnt(h_sync_cnt),
        .v_sync_cnt(v_sync_cnt),
        .vga_clk(vga_clk)
    );

endmodule
