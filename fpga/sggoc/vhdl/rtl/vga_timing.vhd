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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity vga_timing is
    generic(
        constant h_sync_pulse_cnt : integer := 095;
        constant h_fron_porch_cnt : integer := 045;
        constant h_visible_cnt    : integer := 640;
        constant h_back_porch_cnt : integer := 020;
        constant h_line_cnt       : integer := 800;

        constant v_sync_pulse_cnt : integer := 002;
        constant v_fron_porch_cnt : integer := 032;
        constant v_visible_cnt    : integer := 480;
        constant v_back_porch_cnt : integer := 014;
        constant v_fram_cnt       : integer := 528
    );
    port(
        clk_50          : in std_logic;
        rst             : in std_logic;

        vga_hs          : out std_logic;
        vga_vs          : out std_logic;

        vga_clk         : out std_logic;
        pixel_x         : out std_logic_vector (9 downto 0);
        pixel_y         : out std_logic_vector (9 downto 0);
        in_display_area : out std_logic
    );
end vga_timing;

architecture rtl of vga_timing is

    signal scan_x : natural range 0 to 2**10-1 := 0; -- easier for incrementation...
    signal scan_y : natural range 0 to 2**10-1 := 0; -- easier for incrementation...
    --signal scan_x : std_logic_vector (9 downto 0) := (others => '0');
    --signal scan_y : std_logic_vector (9 downto 0) := (others => '0');

    signal clk_25 : std_logic := '0';

    subtype slv is std_logic_vector;

begin
    process(clk_50) begin
        if rising_edge(clk_50) then
            clk_25 <= (not clk_25);
        end if;
    end process;

    process(clk_25, rst) begin
        if (rst = '1') then
            scan_x <= 0;
            scan_y <= 0;
        elsif rising_edge(clk_25) then
            if (scan_x = h_line_cnt-1) then
                scan_x <= 0;
                scan_y <= scan_y + 1;
            else
                scan_x <= scan_x + 1;
            end if;

            if (scan_y = v_fram_cnt) then
                scan_y <= 0;
            end if;
        end if;
    end process;

    process(clk_25) begin
        if rising_edge(clk_25) then
            if (scan_x >= h_sync_pulse_cnt) then
                vga_hs <= '1';
            else
                vga_hs <= '0';
            end if;
            if (scan_y >= v_sync_pulse_cnt) then
                vga_vs <= '1';
            else
                vga_vs <= '0';
            end if;
            if (scan_x >= h_sync_pulse_cnt + h_fron_porch_cnt) and
               (scan_y >= v_sync_pulse_cnt + v_fron_porch_cnt) and
               (scan_x <  h_sync_pulse_cnt + h_fron_porch_cnt + h_visible_cnt) and
               (scan_y <  v_sync_pulse_cnt + v_fron_porch_cnt + v_visible_cnt) then
               in_display_area <= '1';
           else
               in_display_area <= '0';
           end if;
       end if;
   end process;

   vga_clk <= clk_25;

   pixel_x <= slv(to_unsigned(scan_x, pixel_x'length) - (h_sync_pulse_cnt + h_fron_porch_cnt));
   pixel_y <= slv(to_unsigned(scan_y, pixel_y'length) - (v_sync_pulse_cnt + v_fron_porch_cnt));

end rtl;
