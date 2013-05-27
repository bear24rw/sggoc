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
use std.textio.all;

entity io is
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        io_do           : out std_logic_vector (7 downto 0);

        z80_do          : in std_logic_vector (7 downto 0);
        z80_addr        : in std_logic_vector (15 downto 0);
        z80_io_rd       : in std_logic;
        z80_io_wr       : in std_logic;

        vdp_data_rd     : out std_logic;
        vdp_data_wr     : out std_logic;
        vdp_control_rd  : out std_logic;
        vdp_control_wr  : out std_logic;

        vdp_data_o      : in std_logic_vector (7 downto 0);
        vdp_status      : in std_logic_vector (7 downto 0);
        vdp_v_counter   : in std_logic_vector (7 downto 0);
        vdp_h_counter   : in std_logic_vector (7 downto 0)
    );
end io;

architecture rtl of io is

    -- http://www-ee.uta.edu/Online/Zhu/spring_2007/tutorial/how_to_print_objexts.txt
    function to_string(sv: Std_Logic_Vector) return string is
        use Std.TextIO.all;
        variable bv: bit_vector(sv'range) := to_bitvector(sv);
        variable lp: line;
    begin
        write(lp, bv);
        return lp.all;
    end;

    -- 8 bits wide, 7 deep
    type gg_reg_lut is array (6 downto 0) of std_logic_vector (7 downto 0);
    signal gg_reg : gg_reg_lut;

    signal mem_control : std_logic_vector (7 downto 0) := x"A4";

    subtype slv is std_logic_vector;

    signal port_io : std_logic_vector (2 downto 0);

begin

    -- ----------------------------------------------------
    --                GG SPECIFIC REGISTERS
    -- ----------------------------------------------------

    --process begin
    --    gg_reg(0) <= x"C0";
    --    gg_reg(1) <= x"7F";
    --    gg_reg(2) <= x"FF";
    --    gg_reg(3) <= x"00";
    --    gg_reg(4) <= x"FF";
    --    gg_reg(5) <= x"00";
    --    gg_reg(6) <= x"FF";
    --    wait;
    --end process;

    -- ----------------------------------------------------
    --              MEMORY CONTROL REGISTER
    -- ----------------------------------------------------

    process(rst) begin
        if (rst = '1') then
            gg_reg(0) <= x"C0";
            gg_reg(1) <= x"7F";
            gg_reg(2) <= x"FF";
            gg_reg(3) <= x"00";
            gg_reg(4) <= x"FF";
            gg_reg(5) <= x"00";
            gg_reg(6) <= x"FF";
        end if;
    end process;

    process(clk, rst) begin
        if (rst = '1') then
            mem_control <= x"A4";
        elsif rising_edge(clk) then
            if (z80_io_wr = '1' and port_io = 0) then
                mem_control <= z80_do;
            else
                mem_control <= x"A4";
            end if;
        end if;
    end process;

    -- ----------------------------------------------------
    --                  PORT DECODING
    -- ----------------------------------------------------

    port_io <= (z80_addr(7) & z80_addr(6) & z80_addr(0));

    -- ----------------------------------------------------
    --                VDP CONTROL LINES
    -- ----------------------------------------------------

    process(clk) begin
        if rising_edge(clk) then
            if (z80_io_wr = '1' and port_io = 4) then
                vdp_data_wr <= '1';
            else
                vdp_data_wr <= '0';
            end if;
            if (z80_io_wr = '1' and port_io = 4) then
                vdp_data_rd <= '1';
            else
                vdp_data_rd <= '0';
            end if;
            if (z80_io_wr = '1' and port_io = 5) then
                vdp_control_wr <= '1';
            else
                vdp_control_wr <= '0';
            end if;
            if (z80_io_wr = '1' and port_io = 5) then
                vdp_control_rd <= '1';
            else
                vdp_control_rd <= '0';
            end if;
        end if;
    end process;

    -- ----------------------------------------------------
    --                  OUTPUT MUX
    -- ----------------------------------------------------

    -- new vhdl (vhdl-2008) i believe supports "??" as conditional operators
    process(clk) begin
        if rising_edge(clk) then
            if    (z80_addr = x"0000") then io_do <= gg_reg(0);
            elsif (z80_addr = x"0001") then io_do <= gg_reg(1);
            elsif (z80_addr = x"0002") then io_do <= gg_reg(2);
            elsif (z80_addr = x"0003") then io_do <= gg_reg(3);
            elsif (z80_addr = x"0004") then io_do <= gg_reg(4);
            elsif (z80_addr = x"0005") then io_do <= gg_reg(5);
            elsif (z80_addr = x"0006") then io_do <= gg_reg(6);
            elsif (port_io  = "000") then io_do <= mem_control;        -- 0x3E - memory control
            elsif (port_io  = "001") then io_do <= x"FF";              -- 0x3F - io port control
            elsif (port_io  = "010") then io_do <= vdp_v_counter;      -- 0x7E - v counter
            elsif (port_io  = "011") then io_do <= vdp_h_counter;      -- 0x7F - h counter
            elsif (port_io  = "100") then io_do <= vdp_data_o;         -- 0xBE - vdp data
            elsif (port_io  = "101") then io_do <= vdp_status;         -- 0xBF - vdp control
            elsif (port_io  = "110") then io_do <= x"FF";              -- 0xDC - io port a/b
            elsif (port_io  = "111") then io_do <= x"FF";              -- 0xDD - io port b/misc
            else io_do <= x"FF";
            end if;
        end if;
    end process;

    -- ----------------------------------------------------
    --                  SIMULATION
    -- ----------------------------------------------------

    -- http://www.velocityreviews.com/forums/t582675-how-to-write-text-in-vhdl.html
    process(z80_io_rd) begin
        if (z80_io_rd = '1') then
            case (port_io) is
                when "000" => report("[IO READ] mem control");
                when "001" => report("[IO READ] io port control");
                when "010" => report("[IO READ] vdp v counter: " & to_string(vdp_v_counter));
                when "011" => report("[IO READ] vdp h counter: " & to_string(vdp_h_counter));
                when "100" => report("[IO READ] vdp data");
                when "101" => report("[IO READ] vdp control");
                when "110" => report("[IO READ] port a/b");
                when "111" => report("[IO READ] port b/misc");
                when others => report("[IO READ] port " & to_string(port_io));
            end case;
        end if;
    end process;

    process (z80_io_wr) begin
        if (z80_io_wr = '1') then
            case (port_io) is
                -- remember to make a note here in verilog version, values were not printed...
                when "000" => report("[IO WRITE] mem control");
                when "001" => report("[IO WRITE] io port control");
                when "010" => report("[IO WRITE] vdp v counter: " & to_string(vdp_v_counter));
                when "011" => report("[IO WRITE] vdp h counter: " & to_string(vdp_h_counter));
                when "100" => report("[IO WRITE] vdp data");
                when "101" => report("[IO WRITE] vdp control");
                when "110" => report("[IO WRITE] port a/b");
                when "111" => report("[IO WRITE] port b/misc");
                when others => report("[IO WRITE] port " & to_string(port_io));
            end case;
        end if;
    end process;
end rtl;
