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

    wire [9:0] y;
    wire [9:0] x;

    reg [3:0] vga_r = 0;
    reg [3:0] vga_g = 0;
    reg [3:0] vga_b = 0;
    reg [5:0] fade = 0;

    wire vga_clk;
    wire in_display_area;

    always @(posedge vga_clk) begin
        if (in_display_area) begin
            if (x > 50 && x < 100) begin
                vga_r <= 4'hF;
                vga_g <= 4'hF;
                vga_b <= 4'hF;
            end else if (x > 100 && x < 150) begin
                vga_r <= 4'hF;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end else if (x > 150 && x < 200) begin
                vga_r <= 4'h0;
                vga_g <= 4'hF;
                vga_b <= 4'h0;
            end else if (x > 200 && x < 250) begin
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'hF;
            end else if (x > 250 && x < 300) begin
                fade <= (300-x);
                vga_r <= fade[5:2];
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end else if (x > 300 && x < 350) begin
                fade <= (350-x);
                vga_r <= 4'h0;
                vga_g <= fade[5:2];
                vga_b <= 4'h0;
            end else if (x > 350 && x < 400) begin
                fade <= (400-x);
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= fade[5:2];
            end else begin
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end
        end else begin
            vga_r <= 4'd00;
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
        .pixel_y(y),
        .pixel_x(x),
        .in_display_area(in_display_area),
        .vga_clk(vga_clk)
    );

endmodule
