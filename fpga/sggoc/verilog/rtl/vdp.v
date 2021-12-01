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

    output              irq_n,

    output [7:0]        v_counter,
    output [7:0]        h_counter,

    output reg [8:0]    pixel_x,
    output reg [8:0]    pixel_y,

    output reg [3:0]    color_r,
    output reg [3:0]    color_g,
    output reg [3:0]    color_b
);

    // ----------------------------------------------------
    //                      REGISTERS
    // ----------------------------------------------------

    reg [7:0] register [0:10];

    initial begin
        register[0] = 'h00;    // mode control 1
        register[1] = 'h00;    // mode control 2
        register[2] = 'h0e;    // name table base address (0x3800)
        register[3] = 'h00;    // color table base address
        register[4] = 'h00;    // background pattern generator base address
        register[5] = 'h7e;    // sprite attribute table base address (0x3F00)
        register[6] = 'h00;    // sprite pattern generator base address
        register[7] = 'h00;    // overscan/backdrop color
        register[8] = 'h00;    // background X scroll
        register[9] = 'h00;    // background Y scroll
        register[10] = 'hff;   // line counter
    end

    wire [13:0] name_table_base_addr                 = {register[2][3:1], 11'd0};
    wire [13:0] sprite_attribute_table_base_addr     = {register[5][6:1],  8'd0};
    wire [13:0] sprite_pattern_table_table_base_addr = {register[6][2  ], 12'd0};

    wire        irq_vsync_en     = register[1][5];
    wire        irq_line_en      = register[0][4];
    wire [7:0]  scroll_x         = register[8];
    wire [7:0]  scroll_y         = register[9];
    wire        disable_x_scroll = register[0][6];
    wire        disable_y_scroll = register[0][7];
    wire        m1               = register[1][4];
    wire        m2               = register[0][1];
    wire        m3               = register[1][3];
    wire        m4               = register[0][2];
    wire        blank            = !register[1][6];
    wire [3:0]  overscan_color   = register[7][3:0];

    // m4: 1 = use mode 4, 0 = use tms modes (selected with m1 m2 m3)
    // m2: 1 = m1/m3 change screen height in mode 4
    // m1: 1 = 224 lines if m2=1
    // m3: 1 = 240 lines if m2=1

    wire mode_4_192 = (m4 && !m2) || (m4 && m2 && !m1 && !m3);

    // ----------------------------------------------------
    //                      VRAM
    // ----------------------------------------------------

    reg  [13:0] vram_addr_a;
    wire [13:0] vram_addr_b;
    wire [ 7:0] vram_do_a;
    wire [ 7:0] vram_do_b;
    reg  [ 7:0] vram_di_a;
    wire        vram_we_a;

    vram vram(
        // port a = cpu side
        .clk_a(~clk),
        .we_a(vram_we_a),
        .addr_a(vram_addr_a),
        .do_a(vram_do_a),
        .di_a(vram_di_a),

        // port b = vdp side
        .clk_b(~clk),
        .we_b(1'b0),
        .addr_b(vram_addr_b),
        .do_b(vram_do_b),
        .di_b(8'b0)
    );

    // ----------------------------------------------------
    //                      CRAM
    // ----------------------------------------------------

    reg [7:0] CRAM [0:63];

    // ----------------------------------------------------
    //                      VDP BACKGROUND
    // ----------------------------------------------------

    wire [5:0] bg_color;

    vdp_background vdp_background(
        .clk(clk),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .scroll_x(scroll_x),
        .scroll_y(scroll_y),
        .disable_x_scroll(disable_x_scroll),
        .disable_y_scroll(disable_y_scroll),
        .name_table_base(register[2][3:1]),
        .vram_addr(vram_addr_b),
        .vram_data(vram_do_b),
        .color(bg_color),
        .priority_()
    );

    always @(posedge clk) begin
        color_r <= blank ? 4'h0 : CRAM[bg_color][3:0];
        color_g <= blank ? 4'h0 : CRAM[bg_color][7:4];
        color_b <= blank ? 4'h0 : CRAM[bg_color+1][3:0];
    end

    // ----------------------------------------------------
    //                    COUNTERS
    // ----------------------------------------------------

    // NTSC 256x192
    // each scanline = 342 pixels
    // each frame    = 262 scanlines

    // counters read by the cpu have weird jumps:
    // v: 00-DA, D5-FF
    // h: 00-93, E9-FF

    assign v_counter = pixel_y <= 9'hda ? pixel_y
                     : pixel_y - 6;

    assign h_counter = pixel_x[8:1] <= 8'h93 ? pixel_x[8:1]
                     : pixel_x[8:1] + 85;

    always @(posedge clk) begin
        if (pixel_x == 341) begin
            pixel_x <= 0;
            pixel_y <= pixel_y == 261 ? 0 : pixel_y + 1;
        end else begin
            pixel_x <= pixel_x + 1;
        end
    end

    // ----------------------------------------------------
    //                       IRQ
    // ----------------------------------------------------

    // frame interrupt

    reg interrupt_flag = 0;

    // active area is 192 lines (0-191)
    always @(posedge clk) begin
        if (pixel_y == 192 && pixel_x == 0) begin
            interrupt_flag <= 1;
        end else if (control_rd) begin
            interrupt_flag <= 0;
        end
    end

    wire irq_vsync_pending = (interrupt_flag && irq_vsync_en);

    assign irq_n = !irq_vsync_pending;

    // ----------------------------------------------------
    //                  CONTROL LOGIC
    // ----------------------------------------------------

    `define CODE_VRAM_READ  2'b00
    `define CODE_VRAM_WRITE 2'b01
    `define CODE_REG_WRITE  2'b10
    `define CODE_CRAM_WRITE 2'b11

    reg is_second_byte = 0;
    reg [7:0] first_byte = 0;
    reg [1:0] code = 0;
    reg [13:0] ram_addr = 0;
    reg [7:0] cram_latch = 0;

    //
    // CONTROL / DATA EDGE DETECTION
    //

    // keep track of the last state so we can detect edges
    reg last_control_rd = 0;
    reg last_control_wr = 0;
    reg last_data_rd = 0;
    reg last_data_wr = 0;

    always @(posedge clk) begin
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

    // vram write enable when we're not writing to cram
    assign vram_we_a = data_wr && (code != `CODE_CRAM_WRITE);

    always @(posedge clk) begin
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
            is_second_byte <= 0;
            data_o <= 8'h0;
        end else begin
            if (control_wr_edge) begin
                is_second_byte <= !is_second_byte;
            end else if (control_rd_edge || data_wr_edge || data_rd_edge) begin
                is_second_byte <= 0;
            end

            if (control_wr_edge) begin
                if (is_second_byte) begin
                    code <= control_i[7:6];
                    case (control_i[7:6])
                        `CODE_REG_WRITE:
                            register[control_i[3:0]] <= first_byte;
                        `CODE_VRAM_READ,
                        `CODE_VRAM_WRITE,
                        `CODE_CRAM_WRITE:
                            ram_addr <= {control_i[5:0], first_byte};
                    endcase
                end else begin
                    first_byte <= control_i;
                end
            end else if (control_rd_edge) begin
                control_o <= { interrupt_flag, 1'b0, 1'b0, 5'b0 };
            end else if (data_rd_edge) begin
                data_o <= vram_do_a;
                ram_addr <= ram_addr + 1;
            end else if (data_wr_edge) begin
                ram_addr <= ram_addr + 1;
                if (code == `CODE_CRAM_WRITE) begin
                    // actual write only takes place on the odd address
                    if (vram_addr_a[0] == 0) begin
                        cram_latch <= data_i;
                    end else begin
                        CRAM[ram_addr[5:0]-1] <= cram_latch;
                        CRAM[ram_addr[5:0]  ] <= data_i;
                    end
                end else begin
                    vram_di_a <= data_i;
                    data_o <= data_i;
                end
            end

            vram_addr_a <= ram_addr;
        end
    end

endmodule
