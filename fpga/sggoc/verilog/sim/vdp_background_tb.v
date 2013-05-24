/***************************************************************************
 *   Copyright (C) 2012 by Ian Cathey                                      *
 *                                                                         *
 *   Embedded System - Project 1                                           *
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

module vdp_background_tb();

    reg clk = 0;
    reg rst = 0;
    reg [9:0] x = 0;
    reg [9:0] y = 0;
    reg [13:0] name_table_addr = 14'h3800;
    wire [13:0] vram_a;
    wire [7:0] vram_d;
    wire [4:0] color;
    reg [9:0] SW = 2;

    vdp_background uut(
        clk, 
        rst,
        x,
        y,
        name_table_addr,
        vram_a,
        vram_d,
        color,
        SW
    );

    reg [7:0] VRAM [0:16384];

    initial begin
        $readmemh("osmose.vram.linear", VRAM);
    end

    assign vram_d = VRAM[vram_a];

    always
        #1 clk = ~clk;

    always @(posedge clk) begin
        x <= x + 1;
        if (x == 256) begin
            x <= 0;
            y <= y + 1;
            if (y == 256) begin
                $finish;
            end
        end
    end
    //reg [8:0] test;
    initial begin
        //$monitor("[%d] | vram_a: %x", uut.x[2:0], uut.vram_a);
        $monitor("(%d,%d) [%d,%d] | data_addr: %x | vram_a: %x | vram_d: %x | data: %x %x %x | color: %x",
            uut.col, uut.row, uut.x[2:0], uut.y[2:0], uut.data_addr, vram_a, vram_d, uut.data0, uut.data1, uut.data2, uut.color);
        //$monitor("%d", vram_a);
        //$monitor("%x", color);
    end
/*
    always @(posedge clk) begin
        case (x[2:0])
            0: test <= 0;
            1: test <= 1;
            2: test <= 2;
            3: test <= 3;
            4: test <= 4;
            5: test <= 5;
            6: test <= 6;
            7: test <= 7;
            default: test <= 'hx;
        endcase
    end
*/
endmodule
