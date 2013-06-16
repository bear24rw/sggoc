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

entity debug is
    port(
        clk_50      : in std_logic;
        clk         : in std_logic;
        rst         : in std_logic;
        UART_RXD    : in std_logic;
        UART_TXD    : out std_logic;
        z80_clk     : out std_logic;
        z80_rst     : out std_logic;
        z80_mem_rd  : in std_logic;
        z80_mem_wr  : in std_logic;
        z80_addr    : in std_logic_vector (15 downto 0)
    );
end debug;

architecture rtl of debug is

    signal transmit : std_logic := '0';
    signal rx_done  : std_logic := '0';
    signal tx_done  : std_logic := '0';

    signal rx_data  : std_logic_vector (7 downto 0) := (others => '0');
    signal tx_data  : std_logic_vector (7 downto 0) := (others => '0');

    signal new_byte : std_logic := '0';

    signal tx_done_latched : std_logic := '0';

    type state_type is (
        S_CLK_LOW,              -- pull z80 clock low
        S_CLK_HIGH,             -- pull z80 clock high
        S_CHECK_NEW,            -- check if z80 address changed
        S_LOAD_ADDR_HIGH,       -- load high byte of z80 address into tx buffer
        S_UART_TX_HIGH,         -- trigger uart tx
        S_UART_TX_WAIT_HIGH,    -- wait for uart to finish
        S_LOAD_ADDR_LOW,        -- load low byte z80 address into tx buffer
        S_UART_TX_LOW,          -- trigger uart tx
        S_UART_TX_WAIT_LOW      -- wait for uart to finish
    );

    signal state : state_type := S_CLK_LOW;

    signal old_z80_addr : std_logic_vector (15 downto 0) := (others => '0');

    subtype slv is std_logic_vector;

begin

    -- -----------------------------------------------------
    --                      UART
    -- -----------------------------------------------------

    uart : entity work.uart
        port map(
            sys_clk => clk_50,
            sys_rst => rst,

            uart_rx => UART_RXD,
            uart_tx => UART_TXD,

            --divisor => 50000000/115200/16 := 27,
            divisor => x"001b",

            rx_data => rx_data,
            tx_data => tx_data,

            rx_done => rx_done,
            tx_done => tx_done,

            tx_wr => transmit
        );

    -- the receive line only goes high for one clock
    -- cycle so we need to latch it. if we are currently
    -- transmitting we obviously don't have a new byte yet

    process(rst, transmit, rx_done) begin
        if (rst = '1') then
            new_byte <= '0';
        elsif (transmit = '1') then
            new_byte <= '0';
        else
            new_byte <= '1';
        end if;
    end process;

    -- the tx_done line only goes high for one clock
    -- cycle so we need to latch it. if we are currently
    -- transmitting we obviously haven't finished sending it

    process(rst, transmit, tx_done) begin
        if (rst = '1') then
            tx_done_latched <= '0';
        elsif (transmit = '1') then
            tx_done_latched <= '0';
        else
            tx_done_latched <= '1';
        end if;
    end process;

    -- -----------------------------------------------------
    --                 STATE MACHINE
    -- -----------------------------------------------------

    process(clk, rst) begin
        if (rst = '1') then
            tx_data <= (others => '0');
            old_z80_addr <= (others => '0');
            transmit <= '0';
            z80_clk <= '0';
            state <= S_CLK_LOW;
        else
            case (state) is

                --
                -- Pulse z80 clock
                --

                when S_CLK_LOW =>
                    z80_clk <= '0';
                    state <= S_CLK_HIGH;

                when S_CLK_HIGH =>
                    z80_clk <= '1';
                    state <= S_CHECK_NEW;

                --
                -- Check if address changed
                --

                when S_CHECK_NEW =>
                    if (z80_mem_rd = '1' or z80_mem_wr = '1') then
                        if (z80_addr /= old_z80_addr) then
                            old_z80_addr <= z80_addr;
                            state <= S_LOAD_ADDR_HIGH;
                        else
                            state <= S_CLK_LOW;
                        end if;
                    else
                        state <= S_CLK_LOW;
                    end if;

                --
                -- Send high byte of address
                --

                when S_LOAD_ADDR_HIGH =>
                    tx_data <= z80_addr(15 downto 8);
                    state <= S_UART_TX_HIGH;

                when S_UART_TX_HIGH =>
                    transmit <= '1';
                    state <= S_UART_TX_WAIT_HIGH;

                when S_UART_TX_WAIT_HIGH =>
                    transmit <= '0';
                    if (tx_done_latched = '1') then
                        state <= S_LOAD_ADDR_LOW;
                    end if;

                --
                -- Send low byte of address
                --

                when S_LOAD_ADDR_LOW =>
                    tx_data <= z80_addr(7 downto 0);
                    state <= S_UART_TX_LOW;

                when S_UART_TX_LOW =>
                    transmit <= '1';
                    state <= S_UART_TX_WAIT_LOW;

                when S_UART_TX_WAIT_LOW =>
                    transmit <= '0';
                    if (tx_done_latched = '1') then
                        state <= S_CLK_LOW;
                    end if;
            end case;
        end if;
    end process;
end rtl;
