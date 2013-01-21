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

// http://www.altera.com/support/examples/verilog/ver-single-port-ram.html

module ram(
    input clk_a,
    input clk_b,
    input we_a,
    input we_b,
    input [ADDR_BITS-1:0] addr_a,
    input [ADDR_BITS-1:0] addr_b,
    input [7:0] di_a,
    input [7:0] di_b,
    output reg [7:0] do_a,
    output reg [7:0] do_b
);

    parameter WIDTH     = 8;    // 8 bits wide
    parameter ADDR_BITS = 14;   // 2**13 (8KB) deep
    
    reg [WIDTH-1:0] ram[(2**ADDR_BITS)-1:0];


    always @(posedge clk_a) begin
        if (we_a) begin
            ram[addr_a] <= di_a;
            do_a <= di_a;
        end else begin
            do_a <= ram[addr_a];
        end
    end

    always @(posedge clk_b) begin
        if (we_b) begin
            ram[addr_b] <= di_b;
            do_b <= di_b;
        end else begin
            do_b <= ram[addr_b];
        end
    end
    
endmodule
