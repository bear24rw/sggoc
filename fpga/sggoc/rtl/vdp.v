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
    input z80_clk,
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
    wire [7:0]  scroll_y         = register[9];
    wire        disable_x_scroll = register[0][6];
    wire        disable_y_scroll = register[0][7];
    wire        mode_4           = register[0][2];
    wire        blank            = !register[1][6];

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
        .clk_a(~vga_clk),
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
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .scroll_x(scroll_x),
        .scroll_y(scroll_y),
        .disable_x_scroll(disable_x_scroll),
        .disable_y_scroll(disable_y_scroll),
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
        // cropped screen that is actually drawn
        if ((pixel_x >=  8*8 && pixel_x < (8+20)*8) &&
            (pixel_y >= 3*8 && pixel_y < (3+18)*8)) begin
            vga_r <= blank ? 4'h0 : CRAM[bg_color][3:0];
            vga_g <= blank ? 4'h0 : CRAM[bg_color][7:4];
            vga_b <= blank ? 4'h0 : CRAM[bg_color+1][3:0];
        // gray out screen outside the crop area
        end else if (pixel_x < 256 && pixel_y < 192) begin
            vga_r <= CRAM[bg_color][3:0] >> 3;
            vga_g <= CRAM[bg_color][7:4] >> 3;
            vga_b <= CRAM[bg_color+1][3:0] >> 3;
        // palette
        end else if (pixel_y >= 256 && pixel_x < 256) begin
            vga_r <= CRAM[pixel_x[7:3]*2][3:0];
            vga_g <= CRAM[pixel_x[7:3]*2][7:4];
            vga_b <= CRAM[pixel_x[7:3]*2+1][3:0];
        // we only support mode 4, indicate an error if we're in a different mode
        end else if (!mode_4) begin
            vga_r <= 4'hF;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end else if (data_wr && (code != 2'd3)) begin
            vga_r <= 4'h0;
            vga_g <= 4'hF;
            vga_b <= 4'h0;
        end else if (data_wr && (code == 2'd3)) begin
            vga_r <= 4'hF;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end else if (control_rd) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'hF;
        end else if (control_wr) begin
            vga_r <= 4'hF;  // yellow
            vga_g <= 4'hF;
            vga_b <= 4'h0;
        end else if (data_rd) begin
            vga_r <= 4'hF;  // purple
            vga_g <= 4'h0;
            vga_b <= 4'hF;
        // grid
        end else if (pixel_x[2:0] == 3'b111 || pixel_y[2:0] == 3'b111) begin
            vga_g <= 4'h1;
            vga_r <= 4'h1;
            vga_b <= 4'h1;
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

    // h counter
    always @(posedge vga_clk) begin
        if (pixel_x < 256)
            vdp_h_counter <= pixel_x[7:0];
        else
            vdp_h_counter <= 256;
    end

    // v counter
    always @(posedge vga_clk) begin
        if (line_complete) begin
            if (pixel_y <= 'hDA)
                vdp_v_counter <= pixel_y;
            else if (pixel_y < 'd262)
                vdp_v_counter <= 'hD5 + (pixel_y - 'hDB);
            else
                vdp_v_counter <= 'hFF;
        end
    end

    // ----------------------------------------------------
    //                       IRQ
    // ----------------------------------------------------

    // frame interrupt

    initial status = 0;

    always @(posedge vga_clk) begin
        if (pixel_y == 193) begin
            $display("[vdp] Vsync IRQ");
            status[7] <= 1;
        end else if (control_rd) begin
            status[7] <= 0;
        end
    end

    wire irq_vsync_pending = (status[7] && irq_vsync_en);

    // line interrupt

    reg [7:0] line_counter = 0;
    reg       line_irq = 0;

    always @(posedge vga_clk) begin
        if (line_complete) begin
            if (pixel_y > 193) begin
                line_counter <= register[10];
            end else begin
                if (line_counter == 'h00) begin
                    line_counter <= register[10];
                    line_irq <= 1;
                end else begin
                    line_counter <= line_counter - 1;
                end
            end
        end else if (control_rd) begin
            line_irq <= 0;
        end
    end

    // disable line counter irq for now since it causes corruption
    // disabling it in osmose too seems to have no effect
    //wire irq_line_pending = (line_irq && irq_line_en);
    wire irq_line_pending = 0;

    assign irq_n = (irq_vsync_pending || irq_line_pending) ? 0 : 1;

    // ----------------------------------------------------
    //                  CONTROL LOGIC
    // ----------------------------------------------------

    reg [1:0] code = 0;
    reg [7:0] read_buffer = 0;
    reg [7:0] cram_latch = 0;

    //
    // CONTROL / DATA EDGE DETECTION
    //

    // keep track of the last state so we can detect edges
    reg last_control_rd = 0;
    reg last_control_wr = 0;
    reg last_data_rd = 0;
    reg last_data_wr = 0;

    always @(posedge z80_clk, posedge rst) begin
        if (rst) begin
            last_control_rd <= 0;
            last_control_wr <= 0;
            last_data_rd <= 0;
            last_data_wr <= 0;
        end else begin
            last_control_rd <= control_rd;
            last_control_wr <= control_wr;
            last_data_rd <= data_rd;
            last_data_wr <= data_wr;
        end
    end

    wire control_rd_edge = control_rd && !last_control_rd;
    wire control_wr_edge = control_wr && !last_control_wr;
    wire data_rd_edge    = data_rd    && !last_data_rd;
    wire data_wr_edge    = data_wr    && !last_data_wr;

    //
    // SECOND BYTE FLAG
    //

    // Flag to indicate if the control port is recieving the
    // first or second byte. After first byte is recieved flag
    // is set. After second byte is recieved or any other port
    // is read/write the flag is cleared

    reg second_byte = 0;

    always @(posedge z80_clk, posedge rst) begin
        if (rst) begin
            second_byte <= 0;
        end else begin
            if (control_wr_edge) begin
                second_byte <= !second_byte;
            end else if (control_rd_edge || data_wr_edge || data_rd_edge) begin
                second_byte <= 0;
            end
        end
    end

    //
    // VRAM ADDRESS
    //

    // vram address is set by two writes to the control port
    // every other port just increments the address

    reg [13:0] next_vram_addr_a = 0;
    reg [ 7:0] addr_hold = 0;

    always @(posedge z80_clk) begin
        vram_addr_a <= next_vram_addr_a;

        if (control_wr_edge) begin
            if (second_byte == 0) begin
                addr_hold <= control_i;
            end else begin
                if (control_i[7:6] == 0) begin
                    next_vram_addr_a <= {control_i[5:0], addr_hold} + 1;
                end else begin
                    next_vram_addr_a[7:0] <= addr_hold;
                    next_vram_addr_a[13:8] <= control_i[5:0];
                end
            end
        end else if (control_rd_edge || data_wr_edge || data_rd_edge) begin
            next_vram_addr_a <= vram_addr_a + 1;
        end
    end

    // vram write enable when we're not writing to cram
    assign vram_we_a = data_wr && (code != 2'h3);


    always @(posedge z80_clk, posedge rst) begin

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
            data_o <= 8'h0;
        end else begin

            if (control_wr_edge) begin

                if (second_byte) begin
                    code <= control_i[7:6];
                    // check for register write instead
                    if (control_i[7:6] == 2'h2) begin
                        register[control_i[3:0]] <= addr_hold;
                        $display("[VDP] reg %d set to %x", control_i[3:0], addr_hold);
                    end else begin
                        #1 $display("[VDP] setting vram addr to %x code %d", next_vram_addr_a, code);
                    end
                end

            end else if (control_rd_edge) begin

                read_buffer <= vram_do_a;
                $display("[VDP] reading control");

            end else if (data_rd_edge) begin

                data_o <= read_buffer;
                read_buffer <= vram_do_a;
                $display("[VDP] reading data");

            end else if (data_wr_edge) begin

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
        end

    end

endmodule
