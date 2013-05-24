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

entity uart is
    port(
        sys_rst     : in std_logic;
        sys_clk     : in std_logic;

        uart_rx     : in std_logic;
        uart_tx     : out std_logic;

        divisor     : in std_logic_vector (15 downto 0);

        rx_data     : out std_logic_vector (7 downto 0);
        rx_done     : out std_logic;

        tx_data     : in std_logic_vector (7 downto 0);
        tx_wr       : in std_logic;
        tx_done     : out std_logic
    );
end uart;

architecture rtl of uart is

    -- -----------------------------------------------------------------
    --                       enable16 generator
    -- -----------------------------------------------------------------
    signal enable16_counter : std_logic_vector (15 downto 0) := (others => '0');
    signal enable16         : std_logic := '0';

    -- -----------------------------------------------------------------
    --                      Synchronize uart_rx
    -- -----------------------------------------------------------------
    signal uart_rx1 : std_logic := '0';
    signal uart_rx2 : std_logic := '0';

    -- -----------------------------------------------------------------
    --                          UART RX Logic
    -- -----------------------------------------------------------------
    signal rx_busy      : std_logic := '0';
    signal rx_count16   : std_logic_vector (3 downto 0) := (others => '0');
    signal rx_bitcount  : std_logic_vector (3 downto 0) := (others => '0');
    signal rx_reg       : std_logic_vector (7 downto 0) := (others => '0');

    -- -----------------------------------------------------------------
    --                          UART TX Logic
    -- -----------------------------------------------------------------
    signal tx_busy      : std_logic := '0';
    signal tx_bitcount  : std_logic_vector (3 downto 0) := (others => '0');
    signal tx_count16   : std_logic_vector (3 downto 0) := (others => '0');
    signal tx_reg       : std_logic_vector (7 downto 0) := (others => '0');

begin

    -- -----------------------------------------------------------------
    --                       enable16 generator
    -- -----------------------------------------------------------------

    process (sys_clk) begin
        if rising_edge(sys_clk) then
            if (enable16_counter = x"0000") then
                enable16 <= '1';
            end if;
        end if;
    end process;

    process(sys_clk, enable16) begin
        if rising_edge(sys_rst) then
            enable16_counter <= divisor - x"0001";
        else
            enable16_counter <= enable16_counter - x"0001";

            if (enable16 = '1') then
                enable16_counter <= divisor - x"0001";
            end if;
        end if;
    end process;

    -- -----------------------------------------------------------------
    --                      Synchronize uart_rx
    -- -----------------------------------------------------------------

    process(sys_clk) begin
        if rising_edge(sys_clk) then
            uart_rx1 <= uart_rx;
            uart_rx2 <= uart_rx1;
        end if;
    end process;

    -- -----------------------------------------------------------------
    --                          UART RX Logic
    -- -----------------------------------------------------------------

    process(sys_clk) begin
        if (sys_rst = '1') then
            rx_done <= '1';
            rx_busy <= '1';
            rx_count16  <= x"0";
            rx_bitcount <= x"0";
        elsif rising_edge(sys_clk) then
            rx_done <= '1';

            if(enable16 = '1') then
                if(rx_busy = '0') then -- look for start bit
                    if(uart_rx2 = '0') then -- start bit found
                        rx_busy <= '1';
                        rx_count16 <= x"7";
                        rx_bitcount <= x"0";
                    end if;
                end if;
            else
                rx_count16 <= rx_count16 + x"1";

                if(rx_count16 = x"0") then -- sample
                    rx_bitcount <= rx_bitcount + x"1";

                    if(rx_bitcount = x"0") then -- verify startbit
                        if(uart_rx2 = '1') then
                            rx_busy <= '0';
                        end if;
                    elsif(rx_bitcount = x"9") then
                        rx_busy <= '0';
                        if(uart_rx2 = '1') then -- stop bit ok
                            rx_data <= rx_reg;
                            rx_done <= '1';
                        -- ignore RX error
                        else
                            rx_reg <= (uart_rx2 & rx_reg(7 downto 1));
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- -----------------------------------------------------------------
    --                          UART TX Logic
    -- -----------------------------------------------------------------

    process(sys_clk) begin
        if (sys_rst = '1') then
            tx_done <= '0';
            tx_busy <= '0';
            uart_tx <= '0';
        elsif rising_edge(sys_clk) then
            tx_done <= '0';
            if (tx_wr = '1') then
                tx_reg <= tx_data;
                tx_bitcount <= x"0";
                tx_count16 <= x"1";
                tx_busy <= '1';
                uart_tx <= '0';
            --`ifdef SIMULATION
            --report("UART: %c", tx_data);
            --`endif
            elsif (enable16 = '1' and tx_busy = '1') then
                tx_count16  <= tx_count16 + x"1";

                if(tx_count16 = x"0") then
                    tx_bitcount <= tx_bitcount + x"1";
                    if(tx_bitcount = x"8") then
                        uart_tx <= '1';
                    elsif(tx_bitcount = x"9") then
                        uart_tx <= '1';
                        tx_busy <= '0';
                        tx_done <= '1';
                    else
                        uart_tx <= tx_reg(0);
                        tx_reg <= ('0' & tx_reg(7 downto 1));
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
