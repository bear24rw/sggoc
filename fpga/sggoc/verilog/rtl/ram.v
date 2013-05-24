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
    input clk,
    input we,
    input [ADDR_BITS-1:0] addr,
    input [7:0] di,
    output [7:0] do
);

    parameter WIDTH     = 8;    // 8 bits wide
    parameter ADDR_BITS = 13;   // 2**13 (8KB) deep

    reg [WIDTH-1:0] ram[(2**ADDR_BITS)-1:0];

    reg [ADDR_BITS-1:0] addr_reg = 0;

    always @(posedge clk) begin

        // if write enable store new value
        if (we) ram[addr] <= di;

        // save this addr so we can continue to output it
        addr_reg <= addr;

    end

    // continuous assignment implies read returns NEW data
    // this is the natural behavior of the TriMatrix memory
    // blocks in single port mode
    assign do = ram[addr_reg];

endmodule
