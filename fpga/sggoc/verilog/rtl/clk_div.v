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

module clk_div(
    input clk_in,
    output reg clk_out = 0
);

    // default the clock divider to 1Hz
    // the DE1 has a 50MHz oscillator so
    // toggle every 25 million clocks
    parameter COUNT = 25000000;

    // register needs to be ln(25000000)/ln(2)
    // bits wide to handle 1Hz
    reg [24:0] counter = 0;

    always @(posedge clk_in) begin

        // if we have counted up to our desired value
        if (counter == COUNT) begin
            clk_out <= ~clk_out;    // toggle the output clock
            counter <= 0;           // reset the counter
        end else begin
            counter <= counter + 1; // increment the counter every pulse
        end

    end

endmodule
