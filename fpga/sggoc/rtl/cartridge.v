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
    output reg [7:0] do,
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

    localparam S_WAIT_READ_START = 0;
    localparam S_WAIT_FLASH      = 1;
    localparam S_DEASSERT_WAIT   = 2;
    localparam S_WAIT_READ_END   = 3;

    reg [2:0] state = S_WAIT_READ_START;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= S_WAIT_READ_START;
            wait_n <= 1;
            flash_read <= 0;
        end else begin
            case (state)
                S_WAIT_READ_START: begin
                    if (rd) begin                   // is z80 requesting a read?
                        wait_n <= 0;                // tell z80 to wait
                        flash_read <= 1;            // tell flash to read
                        state <= S_WAIT_FLASH;      // wait for read to complete
                    end
                end
                S_WAIT_FLASH: begin
                    if (flash_done) begin           // did the flash finish reading?
                        flash_read <= 0;            // yes, deassert write line
                        do <= flash_do;             // latch the flash output
                        state <= S_DEASSERT_WAIT;   // tell z80 we are done
                    end
                end
                S_DEASSERT_WAIT: begin
                        wait_n <= 1;                // tell z80 were done
                        state <= S_WAIT_READ_END;   // wait until the read cycle is over
                end
                S_WAIT_READ_END: begin
                    if (!rd) begin                  // is the read cycle over?
                        state <= S_WAIT_READ_START; // go back and wait for another read
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

    reg [7:0] flash_do;
    reg       flash_read = 0;
    reg       flash_done = 0;

    Altera_UP_Flash_Memory_UP_Core_Standalone flash (
        .i_clock(clk),
        .i_reset_n(~rst),
        .i_address(flash_addr),
        .i_read(flash_read),
        .o_done(flash_done),
        .o_data(flash_do),

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
