-- ---------------------------------------------------------------------- --
--   Copyright (C) 2012 by Max Thrun                                       *
--   Copyright (C) 2012 by Samir Silbak                                    *
--                                                                         *
--   (SSGoC) Sega Game Gear on a Chip                                      *
--                                                                         *
--   This program is free software; you can redistribute it and/or modify  *
--   it under the terms of the GNU General Public License as published by  *
--   the Free Software Foundation; either version 2 of the License, or     *
--   (at your option) any later version.                                   *
--                                                                         *
--   This program is distributed in the hope that it will be useful,       *
--   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
--   GNU General Public License for more details.                          *
--                                                                         *
--   You should have received a copy of the GNU General Public License     *
--   along with this program; if not, write to the                         *
--   Free Software Foundation, Inc.,                                       *
--   51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.              *
-- ---------------------------------------------------------------------- --

-- http://code.google.com/p/bizhawk/source/browse/trunk/BizHawk.Emulation/Consoles/Sega/SMS/MemoryMap.Sega.cs
-- http://www.smspower.org/Development/Mappers?from=Development.Mapper

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity mem_mapper is
    generic(
        -- each bank is 16KB (2**14 = 16384 = 0x4000)
        constant BANK_SIZE : integer := 2**14;

        -- if the addr falls into slot 1 or 2 we need
        -- to rezero it so we can index into the bank
        -- correctly. easiest way to do this is to just
        -- mask off anything bigger than the bank size

        --constant BANK_SIZE_MASK : integer := 2**14 - 1

        constant BANK_SIZE_MASK : integer := 2**14 - 1
    );
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        wr          : in std_logic;
        di          : in std_logic_vector (7 downto 0);
        addr        : in std_logic_vector (15 downto 0);

        -- biggest flash addr = 255 * 0x4000 + 0x3FFF = 4 194 303
        flash_addr  : out std_logic_vector (21 downto 0)
    );
end mem_mapper;

    -- Z80 Address Mapping
    --
    -- $0000-$03FF - ROM (unpaged)
    -- $0400-$3FFF - ROM mapper slot 0
    -- $4000-$7FFF - ROM mapper slot 1
    -- $8000-$BFFF - ROM mapper slot 2 - OR - SaveRAM
    -- $C000-$DFFF - System RAM
    -- $E000-$FFFF - System RAM (mirror)
    -- $FFFC - SaveRAM mapper control
    -- $FFFD - Mapper slot 0 control
    -- $FFFE - Mapper slot 1 control
    -- $FFFF - Mapper slot 2 control

architecture rtl of mem_mapper is

    -- mapping registers
    -- value of the register points to which rom
    -- bank to use for the given slot
    -- ex. if 'rom_bank_0' = 5 then
    -- slot 0 will point to bank 5
    signal rom_bank_0 : std_logic_vector (7 downto 0) := x"00";
    signal rom_bank_1 : std_logic_vector (7 downto 0) := x"01";
    signal rom_bank_2 : std_logic_vector (7 downto 0) := x"02";

    subtype slv is std_logic_vector;

begin
    -- check if this memory write was to the
    -- mapping registers
    process(clk, rst) begin
        if (rst = '1') then
            rom_bank_0 <= x"00";
            rom_bank_1 <= x"01";
            rom_bank_2 <= x"02";
        elsif rising_edge(clk) then
            if (wr = '1') then
                case addr is
                    when x"FFFD" => rom_bank_0 <= di; --$display("[mem] Bank 0 set to %02x", di);
                    when x"FFFE" => rom_bank_1 <= di; --$display("[mem] Bank 1 set to %02x", di);
                    when x"FFFF" => rom_bank_2 <= di; --$display("[mem] Bank 2 set to %02x", di);
                    when others =>
                end case;
            end if;
        end if;
    end process;

    -- calculate the flash address in flash
    -- memory based on the mapping registers
    process(clk) begin
        if rising_edge(clk) then
            if   (addr <= x"03FF") then flash_addr (15 downto 0) <= addr;
            --elsif(addr <= x"3FFF") then flash_addr <= (rom_bank_0 * BANK_SIZE + addr);
            elsif(addr <= x"3FFF") then flash_addr (15 downto 0) <= slv(unsigned(rom_bank_0) * (BANK_SIZE) + (unsigned(addr)) and (to_unsigned(BANK_SIZE_MASK, 16)));
            elsif(addr <= x"7FFF") then flash_addr (15 downto 0) <= slv(unsigned(rom_bank_1) * (BANK_SIZE) + (unsigned(addr)) and (to_unsigned(BANK_SIZE_MASK, 16)));
            elsif(addr <= x"BFFF") then flash_addr (15 downto 0) <= slv(unsigned(rom_bank_2) * (BANK_SIZE) + (unsigned(addr)) and (to_unsigned(BANK_SIZE_MASK, 16)));
            else flash_addr (15 downto 0) <= x"DEAD";
            end if;
        end if;
    end process;
end rtl;
