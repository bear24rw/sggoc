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

// http://code.google.com/p/bizhawk/source/browse/trunk/BizHawk.Emulation/Consoles/Sega/SMS/MemoryMap.Sega.cs
// http://www.smspower.org/Development/Mappers?from=Development.Mapper

module mem_mapper(
    input rst,
    input wr,
    input [7:0] di,
    input [15:0] addr,

    // biggest flash addr = 255 * 0x4000 + 0x3FFF = 4 194 303
    output [21:0] flash_addr
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

    // each bank is 16KB (2**14 = 16384 = 0x4000)
    localparam BANK_SIZE         = 16'h4000;

    // if the addr falls into slot 1 or 2 we need
    // to rezero it so we can index into the bank
    // correctly. easiest way to do this is to just
    // mask off anything bigger than the bank size
    localparam BANK_SIZE_MASK    = 16'h3FFF;

    // mapping registers
    // value of the register points to which rom
    // bank to use for the given slot
    // ex. if 'rom_bank_0' = 5 then
    // slot 0 will point to bank 5
    reg [7:0] rom_bank_0 = 'h0;
    reg [7:0] rom_bank_1 = 'h1;
    reg [7:0] rom_bank_2 = 'h2;

    // check if this memory write was to the
    // mapping registers
    always @(posedge rst, posedge wr) begin
        if (rst) begin
            rom_bank_0 <= 'h0;
            rom_bank_1 <= 'h1;
            rom_bank_2 <= 'h2;
        end else if (wr) begin
            case (addr)
                'hFFFD: begin rom_bank_0 <= di; $display("[mem] Bank 0 set to %02x", di); end
                'hFFFE: begin rom_bank_1 <= di; $display("[mem] Bank 1 set to %02x", di); end
                'hFFFF: begin rom_bank_2 <= di; $display("[mem] Bank 2 set to %02x", di); end
            endcase
        end
    end

    // calculate the flash address in flash
    // memory based on the mapping registers
    assign flash_addr =
        (addr <= 'h03FF) ? addr :
        (addr <= 'h3FFF) ? (rom_bank_0 * BANK_SIZE + (addr & BANK_SIZE_MASK)) :
        (addr <= 'h7FFF) ? (rom_bank_1 * BANK_SIZE + (addr & BANK_SIZE_MASK)) :
        (addr <= 'hBFFF) ? (rom_bank_2 * BANK_SIZE + (addr & BANK_SIZE_MASK)) :
        22'hDEAD;

endmodule
