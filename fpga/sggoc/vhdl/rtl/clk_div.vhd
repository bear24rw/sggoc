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

entity clk_div is
    generic(
        -- default the clock divider to 1Hz
        -- the DE1 has a 50MHz oscillator so
        -- toggle every 25 million clocks
        COUNT : integer := 25000000
    );
    port(
        clk_in  : in std_logic;
        rst     : in std_logic;
        clk_out : out std_logic
    );
end clk_div;

architecture rtl of clk_div is

    -- register needs to be ln(25000000)/ln(2)
    -- bits wide to handle 1Hz
    signal counter : natural range 0 to 2**25-1;
    signal z80_clk : std_logic := '0';

begin
    process(clk_in, rst) begin
        if (rst = '1') then
            counter <= 0;
        elsif rising_edge(clk_in) then

            -- if we have counted up to our desired value
            if (counter = COUNT) then
                z80_clk <= (not z80_clk);   -- toggle the output clock
                counter <= 0;               -- reset the counter
            else
                counter <= counter + 1;     -- increment the counter every pulse
            end if;
        end if;
    end process;

    clk_out <= z80_clk;

end rtl;
