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

-- http://www.altera.com/support/examples/verilog/ver-single-port-ram.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
    generic(
        constant WIDTH      : integer := 8; -- 8 bits wide
        constant ADDR_BITS  : integer := 13 -- 2**13 (KB) deep
    );
    port(
        clk     : in std_logic;
        we      : in std_logic;
        addr    : in std_logic_vector (ADDR_BITS-1 downto 0);
        di      : in std_logic_vector (7 downto 0);
        do      : out std_logic_vector (7 downto 0)
    );
end ram;

architecture rtl of ram is

    type ram_lut is array (0 to (2**ADDR_BITS)-1) of std_logic_vector (WIDTH-1 downto 0);
    signal ram : ram_lut;

    signal addr_reg : std_logic_vector (ADDR_BITS-1 downto 0) := (others => '0');

begin
    process(clk) begin
        if rising_edge(clk) then
            -- if write enable store new value
            if (we = '1') then
                ram((to_integer(unsigned(addr)))) <= di;
            end if;
            -- save this addr so we can continue to output it
            addr_reg <= addr;
        end if;
    end process;

    -- continuous assignment implies read returns NEW data
    -- this is the natural behavior of the TriMatrix memory
    do <= ram((to_integer(unsigned(addr_reg))));

end rtl;
