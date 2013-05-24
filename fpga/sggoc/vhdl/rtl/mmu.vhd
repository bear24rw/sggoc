-- ---------------------------------------------------------------------- --
--   Copyright (C) 2012 by Max Thrun                                      --
--   Copyright (C) 2012 by Samir Silbak                                   --
--                                                                        --
--   (SSGoC) Sega Game Gear on a Chip                                     --
--                                                                        --
--   This program is free software; you can redistribute it and/or modify --
--   it under the terms of the GNU General Public License as published by --
--   the Free Software Foundation; either version 2 of the License, or    --
--   (at your option) any later version.                                  --
--                                                                        --
--   This program is distributed in the hope that it will be useful,      --
--   but WITHOUT ANY WARRANTY; without even the implied warranty of       --
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        --
--   GNU General Public License for more details.                         --
--                                                                        --
--   You should have received a copy of the GNU General Public License    --
--   along with this program; if not, write to the                        --
--   Free Software Foundation, Inc.,                                      --
--   51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.             --
-- ---------------------------------------------------------------------- --

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity mmu is
    port(
        clk         : in std_logic;

        z80_di      : out std_logic_vector (7 downto 0);
        z80_do      : in std_logic_vector (7 downto 0);
        z80_addr    : in std_logic_vector (15 downto 0);

        z80_mem_rd  : in std_logic;
        z80_mem_wr  : in std_logic;
        z80_io_rd   : in std_logic;
        z80_io_wr   : in std_logic;
        z80_irq_rd  : in std_logic;

        ram_we      : out std_logic;
        ram_di      : out std_logic_vector (7 downto 0);
        ram_do      : in std_logic_vector (7 downto 0);
        ram_addr    : out std_logic_vector (12 downto 0);

        cart_di     : out std_logic_vector (7 downto 0);
        cart_do     : in std_logic_vector (7 downto 0);
        cart_addr   : out std_logic_vector (15 downto 0);

        io_do       : in std_logic_vector (7 downto 0)
    );
end mmu;

architecture rtl of mmu is

    -- ----------------------------------------------------
    --               Z80 ADDRESS MAPPING
    -- ----------------------------------------------------

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

    signal ram_en  : std_logic := '0';
    signal cart_en : std_logic := '0';

begin

    -- ----------------------------------------------------
    --                      RAM
    -- ----------------------------------------------------

    process(clk) begin
        if rising_edge(clk) then
            -- RAM starts at 0xC000 = 0b1100000000000000
            if (z80_addr(15 downto 14) = "11") then
                ram_en <= '1';
            else
                ram_en <= '0';
            end if;
        end if;
    end process;

    process(clk, z80_mem_wr, ram_en, z80_do) begin
        if rising_edge(clk) then
            if (z80_mem_wr = '1' and ram_en = '1') then
                ram_we <= '1';
            else
                ram_we <= '0';
            end if;
        end if;
    end process;

    -- RAM data is from 0xC000 to 0xDFFF = 0x1FFF bytes
    -- 0x1FFF = 0b1111111111111 = 13 bits
    ram_addr <= z80_addr(12 downto 0);
    ram_di <= z80_do;

    -- ----------------------------------------------------
    --                      CARTRIDGE
    -- ----------------------------------------------------

    -- cartridge enable is mutually exclusive with ram enable
    cart_en <= (not ram_en);
    cart_di <= z80_do;
    cart_addr <= z80_addr;

    -- ----------------------------------------------------
    --                      OUTPUT MUX
    -- ----------------------------------------------------

    process(clk) begin
        if rising_edge(clk) then
            if    (z80_irq_rd = '1') then z80_di <= x"FF";
            elsif (z80_io_rd = '1') then z80_di <= io_do;
            elsif (z80_mem_rd = '1' and cart_en = '1') then z80_di <= cart_do;
            elsif (z80_mem_rd = '1' and ram_en = '1') then z80_di <= ram_do;
            else z80_di <= x"FF";
            end if;
        end if;
    end process;
end rtl;
