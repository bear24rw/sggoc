/***************************************************************************
 *   Copyright (C) 2012 by Max Thrun                                       *
 *   Copyright (C) 2012 by Samir Silbak                                    *
 *                                                                         *
 *   (SSGoC) Sega Game Gear on a Chip                                      *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.              *
 ***************************************************************************/

module vdp(
    input clk_50,
    input clk,
    input rst,

    input               control_wr,
    input               control_rd,
    input      [7:0]    control_i,
    output reg [7:0]    control_o,

    input               data_wr,
    input               data_rd,
    input      [7:0]    data_i,
    output reg [7:0]    data_o,

    output     [7:0]    vdp_v_counter,
    output     [7:0]    vdp_h_counter,

    output reg [3:0]    VGA_R,
    output reg [3:0]    VGA_G,
    output reg [3:0]    VGA_B,

    output              VGA_HS,
    output              VGA_VS
);

    // ----------------------------------------------------
    //                      REGISTERS
    // ----------------------------------------------------

    reg [7:0] register [0:10];

    initial begin
        register[0] <= 'h26;   // mode control 1
        register[1] <= 'he2;   // mode control 2
        register[2] <= 'hff;   // name table base address
        register[3] <= 'hff;   // color table base address
        register[4] <= 'hff;   // background pattern generator base address
        register[5] <= 'hff;   // sprite attribute table base address
        register[6] <= 'hff;   // sprite pattern generator base address
        register[7] <= 'h00;   // overscan/backdrop color
        register[8] <= 'hf0;   // background X scroll
        register[9] <= 'h00;   // background Y scroll
        register[10] <= 'hff;  // line counter
    end

    // name table base address
    wire [13:0] nt_base_addr = {register[2][3:1], 11'd0};

    // ----------------------------------------------------
    //                      VRAM
    // ----------------------------------------------------

    reg  [13:0] vram_addr_a;
    wire [13:0] vram_addr_b;
    wire [ 7:0] vram_do_a;
    wire [ 7:0] vram_do_b;
    reg  [ 7:0] vram_di_a;
    reg  [ 7:0] vram_di_b;
    wire        vram_we_a;
    reg         vram_we_b;

    vram vram(
        // port a = cpu side
        .clk_a(clk),
        .we_a(vram_we_a),
        .addr_a(vram_addr_a),
        .do_a(vram_do_a),
        .di_a(vram_di_a),

        // port b = vdp side
        .clk_b(~vga_clk),
        .we_b(1'b0),
        .addr_b(vram_addr_b),
        .do_b(vram_do_b),
        .di_b(vram_di_b)
    );

    // ----------------------------------------------------
    //                      CRAM
    // ----------------------------------------------------

    reg [7:0] CRAM [0:63];

    // ----------------------------------------------------
    //                      VDP BACKGROUND
    // ----------------------------------------------------

    wire [5:0] bg_color;
    wire priority;

    vdp_background vdp_background(
        .clk(vga_clk),
        .rst(rst),
        .x(pixel_x),
        .y(pixel_y),
        .name_table_addr(nt_base_addr),
        .vram_a(vram_addr_b),
        .vram_d(vram_do_b),
        .color(bg_color),
        .priority(priority)
    );

    // ----------------------------------------------------
    //                      VGA TIMING
    // ----------------------------------------------------

    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire in_display_area;
    wire vga_clk;

    vga_timing vga_timing (
        .clk_50(clk_50),
        .rst(rst),
        .vga_hs(VGA_HS),
        .vga_vs(VGA_VS),
        .pixel_y(pixel_y),
        .pixel_x(pixel_x),
        .in_display_area(in_display_area),
        .vga_clk(vga_clk)
    );

    always @(posedge vga_clk) begin
        if (in_display_area) begin

            if (pixel_x < 256 && pixel_y < 192) begin
                VGA_R <= CRAM[bg_color][3:0];
                VGA_G <= CRAM[bg_color][7:4];
                VGA_B <= CRAM[bg_color+1][3:0];
            end else begin
                // color palette
                if (pixel_y >= 256 && pixel_x < 256) begin
                    VGA_R <= CRAM[pixel_x[7:3]*2][3:0];
                    VGA_G <= CRAM[pixel_x[7:3]*2][7:4];
                    VGA_B <= CRAM[pixel_x[7:3]*2+1][3:0];
                end else begin
                    // grid lines
                    if (pixel_x[2:0] == 3'b111 || pixel_y[2:0] == 3'b111) begin
                        VGA_G <= 4'hC;
                        VGA_R <= 4'hC;
                        VGA_B <= 4'hC;
                    end else begin
                        VGA_G <= 4'h0;
                        VGA_R <= 4'h0;
                        VGA_B <= 4'h0;
                    end
                end
           end

        end else begin
            VGA_R <= 4'd00;
            VGA_G <= 4'd00;
            VGA_B <= 4'd00;
        end
    end

    // ----------------------------------------------------
    //                  CONTROL LOGIC
    // ----------------------------------------------------

    reg second_byte = 0;
    reg [1:0] code = 0;
    reg [7:0] read_buffer = 0;
    reg [7:0] cram_latch;

    // vram write enable when we're not writing to cram
    assign vram_we_a = data_wr && (code != 3'h3);

    // keep track of the last state so we can detect edges
    reg last_control_rd = 0;
    reg last_control_wr = 0;
    reg last_data_rd = 0;
    reg last_data_wr = 0;

    always @(posedge clk) begin

        if (control_wr && !last_control_wr) begin

            if (second_byte == 0) begin
                vram_addr_a[7:0] <= control_i;
                second_byte <= 1;
            end else begin
                vram_addr_a[13:8] <= control_i[5:0];
                code <= control_i[7:6];
                second_byte <= 0;
                // check for register write instead
                if (control_i[7:6] == 2'h2) begin
                    register[control_i[3:0]] <= vram_addr_a[7:0];
                end
            end

        end else if (control_rd && !last_control_rd) begin

            second_byte <= 0;
            vram_addr_a <= vram_addr_a + 1;
            read_buffer <= vram_do_a;

        end else if (data_rd && !last_data_rd) begin

            second_byte <= 0;
            vram_addr_a <= vram_addr_a + 1;
            data_o <= read_buffer;
            read_buffer <= vram_do_a;

        end else if (data_wr && !last_data_wr) begin

            second_byte <= 0;
            vram_addr_a <= vram_addr_a + 1;

            if (code == 3) begin
                if (vram_addr_a[0] == 0) begin
                    cram_latch <= data_i;
                end else begin
                    $display("[VDP] Writing cram addr %x with %x %x", vram_addr_a[5:0]-1, data_i, cram_latch);
                    CRAM[vram_addr_a[5:0]-1] <= cram_latch;
                    CRAM[vram_addr_a[5:0]]   <= data_i;
                end
            end else begin
                vram_di_a <= data_i;
                read_buffer <= data_i;
            end

        end

        last_control_rd <= control_rd;
        last_control_wr <= control_wr;
        last_data_rd <= data_rd;
        last_data_wr <= data_wr;

    end

endmodule
