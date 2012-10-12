/***************************************************************************
 *   Copyright (C) 2012 by Max Thrun                                       *
 *   Copyright (C) 2012 by Ian Cathey                                      *
 *   Copyright (C) 2012 by Mark Labbato                                    *
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
        
        // increment the counter every pulse
        counter = counter + 1;

        // if we have counted up to our desired value
        if (counter == COUNT) begin
            // toggle the output clock
            clk_out = ~clk_out;
            // reset the counter
            counter = 0;
        end

    end

endmodule
        
