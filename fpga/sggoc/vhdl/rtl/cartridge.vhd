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

entity cartridge is
    port(
            clk      : in std_logic;
            z80_clk  : in std_logic;
            rst      : in std_logic;
            rd       : in std_logic;
            wr       : in std_logic;
            addr     : in std_logic_vector (15 downto 0);
            di       : in std_logic_vector (7 downto 0);
            do       : out std_logic_vector (7 downto 0);
            wait_n   : out std_logic;

            -- physical flash connections
            FL_DQ    : inout std_logic_vector (7 downto 0);
            FL_ADDR  : out std_logic_vector (21 downto 0);
            FL_OE_N  : out std_logic;
            FL_CE_N  : out std_logic;
            FL_WE_N  : out std_logic;
            FL_RST_N : out std_logic
        );
end cartridge;

architecture rtl of cartridge is

    --constant S_WAIT_READ_START : integer := 0;
    --constant S_WAIT_FLASH      : integer := 1;
    --constant S_DEASSERT_WAIT   : integer := 2;
    --constant S_WAIT_READ_END   : integer := 3;

    --signal state : std_logic_vector (2 downto 0) := S_WAIT_READ_START;

    type state_type is (
        S_WAIT_READ_START,
        S_WAIT_FLASH,
        S_DEASSERT_WAIT,
        S_WAIT_READ_END
    );

    signal state : state_type;

    signal flash_addr   : std_logic_vector (21 downto 0) := (others => '0');

    signal flash_do     : std_logic_vector (7 downto 0) := (others => '0');
    signal flash_read   : std_logic := '0';
    signal flash_done   : std_logic := '0';

begin

    -- --------------------------------------------------
    --                 STATE MACHINE
    -- --------------------------------------------------

    process(clk, rst) begin
        if (rst = '1') then
            state <= S_WAIT_READ_START;
            wait_n <= '1';
            flash_read <= '0';
        elsif rising_edge(clk) then
            case state is
                when S_WAIT_READ_START =>
                    if (rd = '1') then              -- is z80 requesting a read?
                        wait_n <= '0';              -- tell z80 to wait
                        flash_read <= '1';          -- tell flash to read
                        state <= S_WAIT_FLASH;      -- wait for read to complete
                    end if;
                when S_WAIT_FLASH =>
                    if (flash_done = '1') then      -- did the flash finish reading?
                        flash_read <= '0';          -- yes, deassert write line
                        do <= flash_do;             -- latch the flash output
                        state <= S_DEASSERT_WAIT;   -- tell z80 we are done
                    end if;
                when S_DEASSERT_WAIT =>
                    wait_n <= '1';                  -- tell z80 were done
                    state <= S_WAIT_READ_END;       -- wait until the read cycle is over
                when S_WAIT_READ_END =>
                    if (rd /= '1') then              -- is the read cycle over?
                        state <= S_WAIT_READ_START; -- go back and wait for another read
                    end if;
            end case;
        end if;
    end process;

    -- --------------------------------------------------
    --                   MEM MAPPER
    -- --------------------------------------------------

    mem_mapper : entity work.mem_mapper
        port map(
            clk => z80_clk,
            rst => rst,
            wr => wr,

            di => di,
            addr => addr,
            flash_addr => flash_addr
        );

    -- --------------------------------------------------
    --                     FLASH
    -- --------------------------------------------------

    flash : entity work.Altera_UP_Flash_Memory_UP_Core_Standalone
        port map(
            i_clock => clk,
            i_reset_n => (not rst),
            i_address => flash_addr,
            i_read => flash_read,
            o_done => flash_done,
            o_data => flash_do,

            i_data => (others => '0'),
            i_write => '0',
            i_erase => '0',

            FL_ADDR => FL_ADDR,
            FL_DQ => FL_DQ,
            FL_CE_N => FL_CE_N,
            FL_OE_N => FL_OE_N,
            FL_WE_N => FL_WE_N,
            FL_RST_N => FL_RST_N
        );
end rtl;
