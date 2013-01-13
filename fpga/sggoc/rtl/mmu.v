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

module mmu(
    output  [7:0]   z80_di,
    input   [7:0]   z80_do,
    input   [15:0]  z80_addr,

    input           z80_mem_rd,
    input           z80_mem_wr,
    input           z80_io_rd,
    input           z80_io_wr,

    output          ram_we,
    output  [7:0]   ram_di,
    input   [7:0]   ram_do,
    output  [13:0]  ram_addr,

    output  [7:0]   cart_di,
    input   [7:0]   cart_do,
    output  [15:0]  cart_addr
);

    // Z80 Address Mapping
    //
    // $0000-$03FF - ROM (unpaged)
    // $0400-$3FFF - ROM mapper slot 0
    // $4000-$7FFF - ROM mapper slot 1
    // $8000-$BFFF - ROM mapper slot 2 - OR - SaveRAM
    // $C000-$DFFF - System RAM
    // $E000-$FFFF - System RAM (mirror)
    // $FFFC - SaveRAM mapper control
    // $FFFD - Mapper slot 0 control
    // $FFFE - Mapper slot 1 control
    // $FFFF - Mapper slot 2 control

    // RAM starts at 0xC000 = 0b1100000000000000
    wire ram_en = (z80_addr[15:14] == 2'b11) 

    // cartridge enable is mutually exclusive with ram enable
    wire cart_en = !ram_en;

    // RAM data is from 0xC000 to 0xDFFF = 0x1FFF bytes
    // 0x1FFF = 0b1111111111111 = 13 bits
    assign ram_addr = z80_addr[12:0];
    assign ram_di = z80_do;
    assign ram_we = z80_mem_wr && ram_en;

    assign cart_di = z80_do;
    assign cart_addr = z80_addr;

    assign z80_di = (z80_mem_rd && cart_en) ? cart_do :
                    (z80_mem_rd && ram_en)  ? ram_do  :
                    'hAA;


endmodule
