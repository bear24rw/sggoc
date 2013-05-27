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

entity vdp_background is
    --generic(
        -- reciprocal: |_2**35 / 224_| + 1
        -- constant rec : integer := 153391689 + 1
    --);
    port(
        clk                 : in std_logic;
        pixel_x             : in std_logic_vector (9 downto 0);
        pixel_y             : in std_logic_vector (9 downto 0);
        scroll_x            : in std_logic_vector (7 downto 0);
        scroll_y            : in std_logic_vector (7 downto 0);
        disable_x_scroll    : in std_logic;
        disable_y_scroll    : in std_logic;
        name_table_addr     : in std_logic_vector (13 downto 0);
        vram_d              : in std_logic_vector (7 downto 0);
        vram_a              : out std_logic_vector (13 downto 0);
        color               : out std_logic_vector (5 downto 0);
        priority            : out std_logic
    );
end vdp_background;

architecture rtl of vdp_background is

    signal flip_x           : std_logic := '0';                                     -- flip tile horizontally
    signal palette          : std_logic := '0';                                     -- use upper half of palette
    signal palette_latch    : std_logic := '0';                                     -- hold it until we start outputting that tile
    signal priority_latch   : std_logic := '0';                                     -- tile priority (behind or infront of sprite)
    signal line_t           : std_logic_vector (2 downto 0) := (others => '0');     -- line within the tile
    signal tile_idx         : std_logic_vector (8 downto 0) := (others => '0');     -- which tile (0-512)

    -- bitplanes (4th one comes directly from vram_d)
    signal data0 : std_logic_vector (7 downto 0) := (others => '0');
    signal data1 : std_logic_vector (7 downto 0) := (others => '0');
    signal data2 : std_logic_vector (7 downto 0) := (others => '0');

    -- shift register for bitplanes
    signal shift0 : std_logic_vector (7 downto 0) := (others => '0');
    signal shift1 : std_logic_vector (7 downto 0) := (others => '0');
    signal shift2 : std_logic_vector (7 downto 0) := (others => '0');
    signal shift3 : std_logic_vector (7 downto 0) := (others => '0');

    signal tile_addr : std_logic_vector (13 downto 0) := (others => '0');
    signal data_addr : std_logic_vector (13 downto 0) := (others => '0');

    -- setting to 10 bits changes conditional expression below
    signal x : std_logic_vector (9 downto 0) := (others => '0');
    signal y : std_logic_vector (9 downto 0) := (others => '0');

    subtype slv is std_logic_vector;

begin

    process(clk) begin
        if rising_edge(clk) then

            -- x scroll: increasing value moves screen left
            -- y scroll: increasing value moves screen up, wraps at row 28 (28 rows-- 8 lines / row = 224)
            if ((disable_x_scroll = '1') and (y(7 downto 3) <  2)) then
                x <= pixel_x;
            else
                x <= slv(unsigned(pixel_x) - unsigned(scroll_x));
            end if;

            -- y <= (disable_y_scroll and x(7 downto 3) < 24) ? pixel_y : ((pixel_y + scroll_y) - ((((pixel_y + scroll_y)*rec) srl 35)*224));
            if ((disable_y_scroll = '1') and (x(7 downto 3) < 24)) then
                y <= pixel_y;
            else
                y <= slv(unsigned(pixel_y) + unsigned(scroll_y) mod integer(224));
            end if;

            -- x(7 downto 3) = current tile on x
            -- y(7 downto 3) = current tile on y
            -- y(2 downto 0) = current line within line

            tile_addr <= slv(unsigned(name_table_addr) + unsigned(x(7 downto 3))*integer(2) + unsigned(y(7 downto 3))*integer(32*2));
            -- hmm, data_addr is 14 bits wide, but we're assigning it to something which is 15 bits wide?...
            --data_addr <= slv(unsigned(tile_idx)*"100000" + unsigned(line_t)*"100");
            data_addr <= slv(unsigned(tile_idx)*"10000" + unsigned(line_t)*"100");

            case(x(2 downto 0)) is
                when "000" => vram_a <= tile_addr;
                when "001" => vram_a <= slv(unsigned(tile_addr) + 1);
                when "010" => vram_a <= (others => '0');
                when "011" => vram_a <= data_addr;
                when "100" => vram_a <= slv(unsigned(data_addr) + 1);
                when "101" => vram_a <= slv(unsigned(data_addr) + 2);
                when "110" => vram_a <= slv(unsigned(data_addr) + 3);
                when "111" => vram_a <= (others => '0');
                --when others => vram_a <= x"xxxx";
                --when others => vram_a <= slv(to_unsigned(x, vram_a'length));
                when others =>
            end case;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case (x(2 downto 0)) is
                when "000" => tile_idx(7 downto 0) <= vram_d;
                when "001" =>
                    tile_idx(8)     <= vram_d(0);
                    flip_x          <= vram_d(1);
                    line_t(0)       <= y(0) xor vram_d(2);
                    line_t(1)       <= y(1) xor vram_d(2);
                    line_t(2)       <= y(2) xor vram_d(2);
                    palette_latch   <= vram_d(3);
                    priority_latch  <= vram_d(4);
                when "100" => data0 <= vram_d;
                when "101" => data1 <= vram_d;
                when "110" => data2 <= vram_d;
                when others =>
            end case;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            if (x(2 downto 0) = "111") then
                if (flip_x = '0') then
                    shift0 <= data0;
                    shift1 <= data1;
                    shift2 <= data2;
                    shift3 <= vram_d;
                else
                    shift0 <= data0(0) & data0(1) & data0(2) & data0(3) & data0(4) & data0(5) & data0(6) & data0(7);
                    shift1 <= data1(0) & data1(1) & data1(2) & data1(3) & data1(4) & data1(5) & data1(6) & data1(7);
                    shift2 <= data2(0) & data2(1) & data2(2) & data2(3) & data2(4) & data2(5) & data2(6) & data2(7);
                    shift3 <= vram_d(0) & vram_d(1) & vram_d(2) & vram_d(3) & vram_d(4) & vram_d(5) & vram_d(6) & vram_d(7);
                end if;
                palette <= palette_latch;
                priority <= priority_latch;
            else
                shift0(7 downto 1) <= shift0(6 downto 0);
                shift1(7 downto 1) <= shift1(6 downto 0);
                shift2(7 downto 1) <= shift2(6 downto 0);
                shift3(7 downto 1) <= shift3(6 downto 0);
            end if;
        end if;
    end process;

    -- each color is two bytes so shift left 1
    -- palette selects upper half of CRAM
    color(0) <= '0';
    color(1) <= shift0(7);
    color(2) <= shift1(7);
    color(3) <= shift2(7);
    color(4) <= shift3(7);
    color(5) <= palette;

end rtl;
