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
use std.textio.all;
use ieee.numeric_std.all;

entity top is
    port(
        CLOCK_50    : in std_logic;

        SW          : in std_logic_vector (9 downto 0);
        KEY         : in std_logic_vector (3 downto 0);

        LEDR        : out std_logic_vector (9 downto 0);
        LEDG        : out std_logic_vector (9 downto 0);

        HEX0        : out std_logic_vector (6 downto 0);
        HEX1        : out std_logic_vector (6 downto 0);
        HEX2        : out std_logic_vector (6 downto 0);
        HEX3        : out std_logic_vector (6 downto 0);

        FL_DQ       : inout std_logic_vector (7 downto 0);
        FL_ADDR     : out std_logic_vector (21 downto 0);
        FL_OE_N     : out std_logic;
        FL_CE_N     : out std_logic;
        FL_WE_N     : out std_logic;
        FL_RST_N    : out std_logic;

        VGA_R       : out std_logic_vector (3 downto 0);
        VGA_G       : out std_logic_vector (3 downto 0);
        VGA_B       : out std_logic_vector (3 downto 0);

        VGA_HS      : out std_logic;
        VGA_VS      : out std_logic;

        UART_RXD    : in std_logic;
        UART_TXD    : out std_logic;

        GPIO_1      : out std_logic_vector (35 downto 0)
    );
end top;

architecture rtl of top is

    -- ----------------------------------------------------
    --                  KEY MAPPING
    -- ----------------------------------------------------

    --signal rst : std_logic := SW(9);
    signal rst   : std_logic;
    signal rst_n : std_logic;

    -- ----------------------------------------------------
    --                  CLOCK DIVIDER
    -- ----------------------------------------------------

    signal z80_clk : std_logic;

    -- ----------------------------------------------------
    --                      Z80
    -- ----------------------------------------------------

    signal z80_addr     : std_logic_vector (15 downto 0);
    signal z80_di       : std_logic_vector (7 downto 0);
    signal z80_do       : std_logic_vector (7 downto 0);
    signal z80_rd_n     : std_logic;
    signal z80_wr_n     : std_logic;
    signal z80_mreq_n   : std_logic;
    signal z80_iorq_n   : std_logic;
    signal z80_wait_n   : std_logic;

    signal z80_m1_n     : std_logic;
    signal z80_halt_n   : std_logic;
    signal z80_int_n    : std_logic;
    signal z80_nmi_n    : std_logic := '1';
    signal z80_busak_n  : std_logic;
    signal z80_busrq_n  : std_logic := '1';

    signal z80_mem_rd   : std_logic := '0';
    signal z80_mem_wr   : std_logic := '0';
    signal z80_io_rd    : std_logic := '0';
    signal z80_io_wr    : std_logic := '0';
    signal z80_irq_rd   : std_logic := '0';

    component tv80s
        port(
            clk     : in std_logic;
            reset_n : in std_logic;

            rd_n    : out std_logic;
            wr_n    : out std_logic;
            mreq_n  : out std_logic;
            iorq_n  : out std_logic;
            wait_n  : in std_logic;

            A       : out std_logic_vector (15 downto 0);
            di      : in std_logic_vector (7 downto 0);
            dout    : out std_logic_vector (7 downto 0);

            m1_n    : out std_logic;
            halt_n  : out std_logic;
            int_n   : in std_logic;
            nmi_n   : in std_logic;
            busrq_n : in std_logic;
            busak_n : out std_logic
            --rfsh_n =>
        );
    end component;
    -- ----------------------------------------------------
    --                      MMU
    -- ----------------------------------------------------

    signal ram_we       : std_logic := '0';
    signal ram_di       : std_logic_vector (7 downto 0) := (others => '0');
    signal ram_do       : std_logic_vector (7 downto 0) := (others => '0');
    signal ram_addr     : std_logic_vector (12 downto 0) := (others => '0');

    signal cart_di      : std_logic_vector (7 downto 0) := (others => '0');
    signal cart_do      : std_logic_vector (7 downto 0) := (others => '0');
    signal cart_addr    : std_logic_vector (15 downto 0) := (others => '0');

    -- ----------------------------------------------------
    --                      IO
    -- ----------------------------------------------------

    signal io_do : std_logic_vector (7 downto 0) := (others => '0');

    -- ----------------------------------------------------
    --                      VDP
    -- ----------------------------------------------------

    signal vdp_v_counter    : std_logic_vector (7 downto 0) := (others => '0');
    signal vdp_h_counter    : std_logic_vector (7 downto 0) := (others => '0');
    signal vdp_control_wr   : std_logic := '0';
    signal vdp_control_rd   : std_logic := '0';
    signal vdp_status       : std_logic_vector (7 downto 0) := (others => '0');
    signal vdp_data_wr      : std_logic := '0';
    signal vdp_data_rd      : std_logic := '0';
    signal vdp_data_o       : std_logic_vector (7 downto 0) := (others => '0');

    -- ----------------------------------------------------
    --                  DEBUG DISPLAY
    -- ----------------------------------------------------

    signal seg0         : std_logic_vector (3 downto 0) := (others => '0');
    signal seg1         : std_logic_vector (3 downto 0) := (others => '0');
    signal seg2         : std_logic_vector (3 downto 0) := (others => '0');
    signal seg3         : std_logic_vector (3 downto 0) := (others => '0');

    signal z80_debug    : std_logic_vector (7 downto 0) := (others => '0');
    --signal debug : std_logic_vector (7 downto 0);

begin

    rst <= SW(9);

    -- ----------------------------------------------------
    --                  CLOCK DIVIDER
    -- ----------------------------------------------------

    clk_div : entity work.clk_div
        generic map(
            COUNT => 7
        )
        port map(
            clk_in => CLOCK_50,
            rst => rst,
            clk_out => z80_clk
        );

    -- ----------------------------------------------------
    --                      Z80
    -- ----------------------------------------------------

    rst_n <= (not rst);

    z80 : tv80s
        port map(
            clk => z80_clk,
            --reset_n => (not rst),
            reset_n => rst_n,

            rd_n => z80_rd_n,
            wr_n => z80_wr_n,
            mreq_n => z80_mreq_n,
            iorq_n => z80_iorq_n,
            wait_n => z80_wait_n,

            A => z80_addr,
            di => z80_di,
            dout => z80_do,

            m1_n => z80_m1_n,
            halt_n => z80_halt_n,
            int_n => z80_int_n,
            nmi_n => z80_nmi_n,
            busrq_n => z80_busrq_n,
            busak_n => z80_busak_n
            --rfsh_n =>
        );

    process(z80_clk) begin
        if rising_edge(z80_clk) then
            if ((z80_mreq_n /= '1') and (z80_rd_n /= '1')) then
                z80_mem_rd <= '1';
            end if;
            if ((z80_mreq_n /= '1') and (z80_wr_n /= '1')) then
                z80_mem_wr <= '1';
            end if;
            if ((z80_iorq_n /= '1') and (z80_rd_n /= '1')) then
                z80_io_rd <= '1';
            end if;
            if ((z80_iorq_n /= '1') and (z80_wr_n /= '1')) then
                z80_io_wr <= '1';
            end if;
            if ((z80_iorq_n /= '1') and (z80_m1_n /= '1')) then
                z80_irq_rd <= '1';
            end if;
        end if;
    end process;

    -- ----------------------------------------------------
    --                      MMU
    -- ----------------------------------------------------

    mmu : entity work.mmu
        port map(

            clk => CLOCK_50,

            z80_di => z80_di,
            z80_do => z80_do,
            z80_addr => z80_addr,

            z80_mem_rd => z80_mem_rd,
            z80_mem_wr => z80_mem_wr,
            z80_io_rd => z80_io_rd,
            z80_io_wr => z80_io_wr,
            z80_irq_rd => z80_irq_rd,

            ram_we => ram_we,
            ram_di => ram_di,
            ram_do => ram_do,
            ram_addr => ram_addr,

            cart_di => cart_di,
            cart_do => cart_do,
            cart_addr => cart_addr,

            io_do => io_do
        );

    -- ----------------------------------------------------
    --                      IO
    -- ----------------------------------------------------

    io : entity work.io
        port map(
            clk => z80_clk,
            rst => rst,

            io_do => io_do,

            z80_do => z80_do,
            z80_addr => z80_addr,
            z80_io_rd => z80_io_rd,
            z80_io_wr => z80_io_wr,

            vdp_data_rd => vdp_data_rd,
            vdp_data_wr => vdp_data_wr,
            vdp_control_rd => vdp_control_rd,
            vdp_control_wr => vdp_control_wr,

            vdp_data_o => vdp_data_o,
            vdp_status => vdp_status,
            vdp_v_counter => vdp_v_counter,
            vdp_h_counter => vdp_h_counter
        );

    -- ----------------------------------------------------
    --                      RAM
    -- ----------------------------------------------------

    sys_ram : entity work.ram
        port map(
            clk => z80_clk,
            we => ram_we,
            addr => ram_addr,
            do => ram_do,
            di => ram_di
        );

    -- ----------------------------------------------------
    --                  CARTRIDGE
    -- ----------------------------------------------------

    cartridge : entity work.cartridge
        port map(
            clk => CLOCK_50,
            z80_clk => z80_clk,
            rst => rst,
            rd => z80_mem_rd,
            wr => z80_mem_wr,
            wait_n => z80_wait_n,

            addr => cart_addr,
            di => cart_di,
            do => cart_do,

            FL_DQ => FL_DQ,
            FL_ADDR => FL_ADDR,
            FL_OE_N => FL_OE_N,
            FL_CE_N => FL_CE_N,
            FL_WE_N => FL_WE_N,
            FL_RST_N => FL_RST_N
        );

    -- ----------------------------------------------------
    --                      VDP
    -- ----------------------------------------------------

    vdp : entity work.vdp
        port map(
            clk_50 => CLOCK_50,
            z80_clk => z80_clk,
            rst => rst,

            control_wr => vdp_control_wr,
            control_rd => vdp_control_rd,
            status => vdp_status,
            control_i => z80_do,

            data_wr => vdp_data_wr,
            data_rd => vdp_data_rd,
            data_o => vdp_data_o,
            data_i => z80_do,

            irq_n => z80_int_n,
            vdp_v_counter => vdp_v_counter,
            vdp_h_counter => vdp_h_counter,

            VGA_R => VGA_R,
            VGA_G => VGA_G,
            VGA_B => VGA_B,
            VGA_HS => VGA_HS,
            VGA_VS => VGA_VS
        );

    -- ----------------------------------------------------
    --                  DEBUG DISPLAY
    -- ----------------------------------------------------

    process(z80_clk) begin
        if rising_edge(z80_clk) then
            if (z80_addr(7 downto 0) = x"1" and z80_io_wr = '1') then
                z80_debug <= z80_do;
            end if;
        end if;
    end process;

    LEDR(7 downto 0) <= z80_debug;

    process(z80_clk, rst) begin
        if (rst = '1') then
            seg0 <= x"F";
            seg1 <= x"E";
            seg2 <= x"E";
            seg3 <= x"B";
        elsif rising_edge(z80_clk) then
            seg0 <= z80_addr(3 downto 0);
            seg1 <= z80_addr(7 downto 4);
            seg2 <= z80_addr(11 downto 8);
            seg3 <= z80_addr(15 downto 12);
        end if;
    end process;

    s0 : entity work.seven_seg port map(seg0, HEX0);
    s1 : entity work.seven_seg port map(seg1, HEX1);
    s2 : entity work.seven_seg port map(seg2, HEX2);
    s3 : entity work.seven_seg port map(seg3, HEX3);

    LEDG(0) <= z80_m1_n;
    LEDG(1) <= z80_mreq_n;
    LEDG(2) <= z80_iorq_n;
    LEDG(3) <= z80_rd_n;
    LEDG(4) <= z80_wr_n;
    LEDG(5) <= z80_halt_n;
    LEDG(6) <= z80_wait_n;
    LEDG(7) <= z80_clk;

    --LEDG <= z80_di;

    --debug(0) <= z80_clk;
    --debug(1) <= z80_do;
    --debug(2) <= vdp_control_rd;
    --debug(3) <= vdp_control_wr;
    --debug(4) <= vdp_status;
    --debug(5) <= vdp_data_rd;
    --debug(6) <= vdp_data_wr;
    --debug(7) <= vdp_data_o;

    --GPIO_1(25) <= debug(0);
    --GPIO_1(23) <= debug(1);
    --GPIO_1(21) <= debug(2);
    --GPIO_1(19) <= debug(3);
    --GPIO_1(17) <= debug(4);
    --GPIO_1(15) <= debug(5);
    --GPIO_1(13) <= debug(6);
    --GPIO_1(11) <= debug(7);

end rtl;
