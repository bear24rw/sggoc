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

entity vram is
    generic(
        constant WIDTH      : integer := 8;
        constant ADDR_BITS  : integer := 14
    );
    port(
        clk_a   : in std_logic;
        clk_b   : in std_logic;
        we_a    : in std_logic;
        we_b    : in std_logic;
        addr_a  : in std_logic_vector (ADDR_BITS-1 downto 0);
        addr_b  : in std_logic_vector (ADDR_BITS-1 downto 0);
        di_a    : in std_logic_vector (7 downto 0);
        di_b    : in std_logic_vector (7 downto 0);
        do_a    : out std_logic_vector (7 downto 0);
        do_b    : out std_logic_vector (7 downto 0)
    );
end vram;

architecture rtl of vram is

    type ram_lut is array ((2**ADDR_BITS)-1 downto 0) of std_logic_vector (WIDTH-1 downto 0);
    signal ram : ram_lut;

begin
    process(clk_a) begin
        if rising_edge(clk_a) then
            if (we_a = '1') then
                ram((to_integer(unsigned(addr_a)))) <= di_a;
                do_a <= di_a;
            else
                do_a <= ram((to_integer(unsigned(addr_a))));
            end if;
        end if;
    end process;

    process(clk_b) begin
        if rising_edge(clk_b) then
            if (we_b = '1') then
                ram((to_integer(unsigned(addr_b)))) <= di_b;
                do_b <= di_b;
            else
                do_b <= ram((to_integer(unsigned(addr_b))));
            end if;
        end if;
    end process;
end rtl;
