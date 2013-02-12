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

module cartridge(
    input clk,
    input rst,
    input rd,
    input wr,
    input [15:0] addr,
    input [7:0] di,
    output [7:0] do,
    output reg wait_n,

    // physical flash connections
    inout [7:0] FL_DQ,
    output [21:0] FL_ADDR,
    output FL_OE_N,
    output FL_CE_N,
    output FL_WE_N,
    output FL_RST_N
);
    // ----------------------------------------------------
    //                 STATE MACHINE
    // ----------------------------------------------------

    localparam S_IDLE       = 0;
    localparam S_READ       = 1;

    reg [2:0] state = S_IDLE;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            wait_n <= 1;
            flash_read <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (rd) begin               // is z80 requesting a read?
                        wait_n = 0;             // tell z80 to wait
                        flash_read = 1;         // tell flash to read
                        state = S_READ;         // wait for read to complete
                    end
                end
                S_READ: begin
                    if (flash_done) begin       // did the flash finish reading?
                        flash_read = 0;         // yes, deassert write line
                        wait_n = 1;             // tell z80 were done
                        state = S_IDLE;         // go back and wait for another read
                    end
                end
            endcase
        end
    end

    // ----------------------------------------------------
    //                  MEM MAPPER
    // ----------------------------------------------------

    wire [21:0] flash_addr;

    mem_mapper mem_mapper (
        .rst(rst),
        .wr(wr),

        .di(di),
        .addr(addr),
        .flash_addr(flash_addr)
    );

    // ----------------------------------------------------
    //                     FLASH
    // ----------------------------------------------------

    reg flash_read = 0;
    reg flash_done = 0;

    Altera_UP_Flash_Memory_UP_Core_Standalone flash (
        .i_clock(clk),
        .i_reset_n(~rst),
        .i_address(flash_addr),
        .i_read(flash_read),
        .o_done(flash_done),
        .o_data(do),

        .i_data(0),
        .i_write(0),
        .i_erase(0),

        .FL_ADDR(FL_ADDR),
        .FL_DQ(FL_DQ),
        .FL_CE_N(FL_CE_N),
        .FL_OE_N(FL_OE_N),
        .FL_WE_N(FL_WE_N),
        .FL_RST_N(FL_RST_N)
    );

endmodule
