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
    output reg [7:0]    status,

    input               data_wr,
    input               data_rd,
    input      [7:0]    data_i,
    output reg [7:0]    data_o,

    output              irq_n,

    output reg [7:0]    vdp_v_counter,
    output reg [7:0]    vdp_h_counter,

    output [3:0]        VGA_R,
    output [3:0]        VGA_G,
    output [3:0]        VGA_B,

    output              VGA_HS,
    output              VGA_VS
);

    // ----------------------------------------------------
    //                      REGISTERS
    // ----------------------------------------------------

    reg [7:0] register [0:10];

    initial begin
        register[0] <= 'h00;    // mode control 1
        register[1] <= 'h00;    // mode control 2
        register[2] <= 'h0e;    // name table base address (0x3800)
        register[3] <= 'h00;    // color table base address
        register[4] <= 'h00;    // background pattern generator base address
        register[5] <= 'h7e;    // sprite attribute table base address (0x3F00)
        register[6] <= 'h00;    // sprite pattern generator base address
        register[7] <= 'h00;    // overscan/backdrop color
        register[8] <= 'h00;    // background X scroll
        register[9] <= 'h00;    // background Y scroll
        register[10] <= 'hff;   // line counter
    end

    // name table base address
    wire [13:0] nt_base_addr     = {register[2][3:1], 11'd0};
    wire        irq_vsync_en     = register[1][5];
    wire        irq_line_en      = register[0][4];
    wire [7:0]  scroll_x         = register[8];
    wire        disable_x_scroll = register[0][6];

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
        .line_complete(line_complete),
        .pixel_x(pixel_x),
        .scroll_x(scroll_x),
        .disable_x_scroll(disable_x_scroll),
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

    reg [3:0] vga_r = 0;
    reg [3:0] vga_g = 0;
    reg [3:0] vga_b = 0;

    always @(posedge vga_clk) begin
        // screen
        if (pixel_x < 256 && pixel_y < 192) begin
            vga_r <= CRAM[bg_color][3:0];
            vga_g <= CRAM[bg_color][7:4];
            vga_b <= CRAM[bg_color+1][3:0];
        // palette
        end else if (pixel_y >= 256 && pixel_x < 256) begin
            vga_r <= CRAM[pixel_x[7:3]*2][3:0];
            vga_g <= CRAM[pixel_x[7:3]*2][7:4];
            vga_b <= CRAM[pixel_x[7:3]*2+1][3:0];
        // grid
        end else if (pixel_x[2:0] == 3'b111 || pixel_y[2:0] == 3'b111) begin
            vga_g <= 4'hC;
            vga_r <= 4'hC;
            vga_b <= 4'hC;
        end else if (data_wr && (code != 2'd3)) begin
            vga_g <= 4'hF;
            vga_r <= 4'h0;
            vga_b <= 4'h0;
        end else if (data_wr && (code == 2'd3)) begin
            vga_g <= 4'h0;
            vga_r <= 4'hF;
            vga_b <= 4'h0;
        end else begin
            vga_g <= 4'h0;
            vga_r <= 4'h0;
            vga_b <= 4'h0;
        end
    end

    assign VGA_R = in_display_area ? vga_r : 4'd0;
    assign VGA_G = in_display_area ? vga_g : 4'd0;
    assign VGA_B = in_display_area ? vga_b : 4'd0;

    // ----------------------------------------------------
    //                    COUNTERS
    // ----------------------------------------------------

    // NTSC 256x192

    initial vdp_v_counter = 0;
    initial vdp_h_counter = 0;

    wire line_complete = (pixel_x == 256);

    always @(posedge vga_clk) begin
        if (pixel_x < 256)
            vdp_h_counter <= pixel_x[7:0];
        else
            vdp_h_counter <= 0;
    end

    always @(posedge vga_clk) begin
        if (line_complete) begin
            if (pixel_y < 'hDA)
                vdp_v_counter <= pixel_y;
            else if (pixel_y < 'hFF)
                vdp_v_counter <= 'hD5 + (pixel_y - 'hDA);
            else
                vdp_v_counter <= 0;
        end
    end

    // ----------------------------------------------------
    //                       IRQ
    // ----------------------------------------------------

    always @(posedge vga_clk) begin
        if (line_complete && pixel_y == 8'hC1) begin
            $display("[vdp] Vsync IRQ");
            status[7] <= 1;
        end else if (control_rd) begin
            status[7] <= 0;
        end
    end

    assign irq_n = (status[7] && irq_vsync_en) ? 0 : 1;

    // ----------------------------------------------------
    //                  CONTROL LOGIC
    // ----------------------------------------------------

    reg second_byte = 0;
    reg [1:0] code = 0;
    reg [7:0] read_buffer = 0;
    reg [7:0] cram_latch = 0;

    // vram write enable when we're not writing to cram
    assign vram_we_a = data_wr && (code != 2'h3);

    // keep track of the last state so we can detect edges
    reg last_control_rd = 0;
    reg last_control_wr = 0;
    reg last_data_rd = 0;
    reg last_data_wr = 0;

    reg [13:0] next_vram_addr_a;
    always @(posedge clk) begin
        vram_addr_a <= next_vram_addr_a;
    end

    always @(posedge clk, posedge rst) begin

        if (rst) begin
            register[0] <= 'h00;    // mode control 1
            register[1] <= 'h00;    // mode control 2
            register[2] <= 'h0e;    // name table base address (0x3800)
            register[3] <= 'h00;    // color table base address
            register[4] <= 'h00;    // background pattern generator base address
            register[5] <= 'h7e;    // sprite attribute table base address (0x3F00)
            register[6] <= 'h00;    // sprite pattern generator base address
            register[7] <= 'h00;    // overscan/backdrop color
            register[8] <= 'h00;    // background X scroll
            register[9] <= 'h00;    // background Y scroll
            register[10] <= 'hff;   // line counter
            second_byte <= 0;
            data_o <= 8'h0;
            last_control_wr <= 0;
            last_control_rd <= 0;
            last_data_wr <= 0;
            last_data_rd <= 0;
        end else begin

            if (control_wr && !last_control_wr) begin

                if (second_byte == 0) begin
                    next_vram_addr_a[7:0] <= control_i;
                    second_byte <= 1;
                end else begin
                    next_vram_addr_a[13:8] <= control_i[5:0];
                    code <= control_i[7:6];
                    second_byte <= 0;
                    // check for register write instead
                    if (control_i[7:6] == 2'h2) begin
                        register[control_i[3:0]] <= vram_addr_a[7:0];
                        $display("[VDP] reg %d set to %x", control_i[3:0], vram_addr_a[7:0]);
                    end else begin
                        #1 $display("[VDP] setting vram addr to %x code %d", next_vram_addr_a, code);
                    end
                end

            end else if (control_rd && !last_control_rd) begin

                second_byte <= 0;
                next_vram_addr_a <= vram_addr_a + 1;
                read_buffer <= vram_do_a;
                $display("[VDP] reading control");

            end else if (data_rd && !last_data_rd) begin

                second_byte <= 0;
                next_vram_addr_a <= vram_addr_a + 1;
                data_o <= read_buffer;
                read_buffer <= vram_do_a;
                $display("[VDP] reading data");

            end else if (data_wr && !last_data_wr) begin

                second_byte <= 0;
                next_vram_addr_a <= vram_addr_a + 1;

                if (code == 3) begin
                    if (vram_addr_a[0] == 0) begin
                        cram_latch <= data_i;
                    end else begin
                        $display("[VDP] Writing cram addr %x with %x%x", vram_addr_a[5:0]-1, data_i, cram_latch);
                        CRAM[vram_addr_a[5:0]-1] <= cram_latch;
                        CRAM[vram_addr_a[5:0]]   <= data_i;
                    end
                end else begin
                    $display("[VDP] Writing vram addr %x with %x", vram_addr_a, data_i);
                    vram_di_a <= data_i;
                    read_buffer <= data_i;
                end

            end

            last_control_rd <= control_rd;
            last_control_wr <= control_wr;
            last_data_rd <= data_rd;
            last_data_wr <= data_wr;
        end

    end

endmodule
