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

entity seven_seg is
    port(
        value   : in std_logic_vector (3 downto 0);
        seg     : out std_logic_vector (6 downto 0)
    );
end seven_seg;

architecture rtl of seven_seg is begin

    -- translate the bcd lookup value into the correct number, letter, or
    -- symbol if the display is not enabled just keep it blank default to
    -- a unused symbol to indicate an error

    process(value) begin
        case value is
            when x"0" => seg <= "1000000";
            when x"1" => seg <= "1111001";
            when x"2" => seg <= "0100100";
            when x"3" => seg <= "0110000";
            when x"4" => seg <= "0011001";
            when x"5" => seg <= "0010010";
            when x"6" => seg <= "0000010";
            when x"7" => seg <= "1111000";
            when x"8" => seg <= "0000000";
            when x"9" => seg <= "0010000";
            when x"A" => seg <= "0001000";
            when x"B" => seg <= "0000011";
            when x"C" => seg <= "1000110";
            when x"D" => seg <= "0100001";
            when x"E" => seg <= "0000110";
            when x"F" => seg <= "0001110";
            when others => seg <= "1110110";
        end case;
    end process;
end rtl;
