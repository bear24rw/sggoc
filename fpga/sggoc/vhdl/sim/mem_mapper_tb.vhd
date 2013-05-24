--/*************************************************************************
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
--**************************************************************************/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all

entity mem_mapper_tb is
end mem_mapper_tb;

architecture behavior of mem_mapper_tb is

    component mem_mapper
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
    end component;

    --signal clk      : std_logic := '0';
    --signal rst      : std_logic := '0';
    signal wr_n     : std_logic := '1';
    signal addr     : std_logic_vector (15 downto 0) := (others => '0');
    signal phy_addr : std_logic_vector (21 downto 0) := (others => '0');

    procedure disp_sig is
        variable sig_out : line;
        alias swrite is write [line, string, side, width];
    end disp_sig;

begin
    dut : mem_mapper
        port map(
            --clk => clk,
            --rst => rst,
            wr => wr_n,
            di => di,
            addr => addr,
            flash_addr => phy_addr
        );

    for addr in 0 to 2**16-1 loop
        wait 1 ns;
        hwrite(sig_out, addr);
        swrite(sig_out, "|");
        hwrite(sig_out, phy_addr);
    end loop
end behavior;
