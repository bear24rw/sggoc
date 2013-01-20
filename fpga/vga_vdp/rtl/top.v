`include "constants.vh"

module top (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [9:0] LEDR,

    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,

    output [1:0] GPIO_1,
    
    output VGA_HS,
    output VGA_VS
);

    wire rst = ~(KEY[0]);
    wire clk = CLOCK_50;

    wire [13:0] vram_addr;
    wire [7:0] vram_do;

    ram vram( 
        .clk(vga_clk),
        .we(1'b0),
        .addr(vram_addr),
        .do(vram_do),
        .di()
    );

    wire [4:0] bg_color;

    vdp_background vdp_background(
        .clk(vga_clk),
        .rst(rst),
        .x(pixel_x),
        .y(pixel_y),
        .name_table_addr(nt_base_addr),
        .vram_a(vram_addr),
        .vram_d(vram_do),
        .color(bg_color)
    );

    reg [7:0] CRAM [0:63];

    initial begin
        $readmemh("osmose.cram.linear", CRAM);
    end

    reg [7:0] r [0:10];

    initial begin
        r[0] <= 'h26;   // mode control 1
        r[1] <= 'he2;   // mode control 2
        r[2] <= 'hff;   // name table base address
        r[3] <= 'hff;   // color table base address
        r[4] <= 'hff;   // background pattern generator base address
        r[5] <= 'hff;   // sprite attribute table base address
        r[6] <= 'hff;   // sprite pattern generator base address
        r[7] <= 'h00;   // overscan/backdrop color
        r[8] <= 'hf0;   // background X scroll
        r[9] <= 'h00;   // background Y scroll
        r[10] <= 'hff;  // line counter
    end

    // sprite attribute table base address
    wire [13:0] sat_base_addr = {r[5][6:1], 8'd0};

    // name table base address
    //wire [13:0] nt_base_addr = {r[2][3:1], 10'd0};
    wire [13:0] nt_base_addr = 14'h3800;

    // overscan / backdrop color
    wire [3:0] overscan_color = r[7][3:0];

    // starting column/row
    wire [4:0] starting_col = r[8][7:3];
    wire [4:0] starting_row = r[9][7:3];

    // fine x/y scroll
    wire [2:0] fine_x_scroll = r[8][2:0];
    wire [2:0] fine_y_scroll = r[9][2:0];

    reg [3:0] cram_idx = 0;

    wire [9:0] pixel_y;
    wire [9:0] pixel_x;

    reg [3:0] vga_r = 0;
    reg [3:0] vga_g = 0;
    reg [3:0] vga_b = 0;

    wire vga_clk;
    wire in_display_area;

    always @(posedge vga_clk) begin
        if (in_display_area) begin

            if (pixel_x < 256 && pixel_y < 192) begin
                if (bg_color == 5'b00000) begin
                    vga_r <= 4'hF;
                    vga_g <= 4'hF;
                    vga_b <= 4'hF;
                end else begin
                    vga_r <= CRAM[bg_color<<1][3:0];
                    vga_g <= CRAM[bg_color<<1][7:4];
                    vga_b <= 4'hF; //CRAM[(bg_color<<1)+1][3:0];
                end
            end else begin
               vga_g <= 4'hF;
               vga_r <= 4'h0;
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
        .pixel_y(pixel_y),
        .pixel_x(pixel_x),
        .in_display_area(in_display_area),
        .vga_clk(vga_clk)
    );

endmodule
