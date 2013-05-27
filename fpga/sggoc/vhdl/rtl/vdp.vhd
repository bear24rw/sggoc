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

entity vdp is
    port(
        clk_50          : in std_logic;
        z80_clk         : in std_logic;
        rst             : in std_logic;

        control_wr      : in std_logic;
        control_rd      : in std_logic;
        control_i       : in std_logic_vector (7 downto 0);
        status          : out std_logic_vector (7 downto 0);

        data_wr         : in std_logic;
        data_rd         : in std_logic;
        data_i          : in std_logic_vector (7 downto 0);
        data_o          : out std_logic_vector (7 downto 0);

        irq_n           : out std_logic;

        vdp_h_counter   : out std_logic_vector (7 downto 0);
        vdp_v_counter   : out std_logic_vector (7 downto 0);

        VGA_R           : out std_logic_vector (3 downto 0);
        VGA_G           : out std_logic_vector (3 downto 0);
        VGA_B           : out std_logic_vector (3 downto 0);

        VGA_HS          : out std_logic;
        VGA_VS          : out std_logic
    );
end vdp;

architecture rtl of vdp is

    subtype slv is std_logic_vector;

    -- ----------------------------------------------------
    --                      REGISTERS
    -- ----------------------------------------------------

    --    reg(0) <= x"00";    -- mode control 1
    --    reg(1) <= x"00";    -- mode control 2
    --    reg(2) <= x"0e";    -- name table base address (0x3800)
    --    reg(3) <= x"00";    -- color table base address
    --    reg(4) <= x"00";    -- background pattern generator base address
    --    reg(5) <= x"7e";    -- sprite attribute table base address (0x3F00)
    --    reg(6) <= x"00";    -- sprite pattern generator base address
    --    reg(7) <= x"00";    -- overscan/backdrop color
    --    reg(8) <= x"00";    -- background X scroll
    --    reg(9) <= x"00";    -- background Y scroll
    --    reg(10) <= x"ff";   -- line counter

    type reg_lut is array (0 to 10) of std_logic_vector (7 downto 0);
    signal reg : reg_lut := (x"00",x"00",x"0e",x"00",x"00",x"7e",x"00",x"00",x"00",x"00",x"ff");

    -- name table base address
    signal nt_base_addr     : std_logic_vector (13 downto 0) := (others => '0');
    signal irq_vsync_en     : std_logic := '0';
    signal irq_line_en      : std_logic := '0';
    signal scroll_x         : std_logic_vector (7 downto 0) := (others => '0');
    signal scroll_y         : std_logic_vector (7 downto 0) := (others => '0');
    signal disable_x_scroll : std_logic := '0';
    signal disable_y_scroll : std_logic := '0';
    signal m1               : std_logic := '0';
    signal m2               : std_logic := '0';
    signal m3               : std_logic := '0';
    signal m4               : std_logic := '0';
    signal blank            : std_logic := '0';

    signal mode_4_192 : std_logic := '0';

    -- ----------------------------------------------------
    --                      VRAM
    -- ----------------------------------------------------

    signal vram_addr_a  : std_logic_vector (13 downto 0) := (others => '0');
    signal vram_addr_b  : std_logic_vector (13 downto 0) := (others => '0');
    signal vram_do_a    : std_logic_vector (7 downto 0) := (others => '0');
    signal vram_do_b    : std_logic_vector (7 downto 0) := (others => '0');
    signal vram_di_a    : std_logic_vector (7 downto 0) := (others => '0');
    signal vram_di_b    : std_logic_vector (7 downto 0) := (others => '0');
    signal vram_we_a    : std_logic := '0';
    signal vram_we_b    : std_logic := '0';

    -- ----------------------------------------------------
    --                      CRAM
    -- ----------------------------------------------------

    type CRAM_LUT is array (0 to 63) of std_logic_vector (7 downto 0);
    signal CRAM : CRAM_LUT := ((others => (others => '0')));

    signal bg_color : std_logic_vector (5 downto 0) := (others => '0');
    signal priority : std_logic := '0';

    signal pixel_x          : std_logic_vector (9 downto 0) := (others => '0');
    signal pixel_y          : std_logic_vector (9 downto 0) := (others => '0');
    signal in_display_area  : std_logic := '0';
    signal vga_clk          : std_logic := '0';

    signal vga_red : std_logic_vector (3 downto 0) := (others => '0');
    signal vga_grn : std_logic_vector (3 downto 0) := (others => '0');
    signal vga_blu : std_logic_vector (3 downto 0) := (others => '0');

    -- ----------------------------------------------------
    --                    COUNTERS
    -- ----------------------------------------------------

    signal v_counter : std_logic_vector (8 downto 0) := (others => '0');
    signal h_counter : std_logic_vector (8 downto 0) := (others => '0');

    signal line_complete : std_logic := '0';

    -- ----------------------------------------------------
    --                       IRQ
    -- ----------------------------------------------------

    signal irq_vsync_pending : std_logic := '0';
    signal irq_line_pending  : std_logic := '0';

    signal line_counter : std_logic_vector (7 downto 0) := (others => '0');
    signal line_irq     : std_logic := '0';

    -- ----------------------------------------------------
    --                  CONTROL LOGIC
    -- ----------------------------------------------------

    signal code         : std_logic_vector (1 downto 0) := (others => '0');
    signal read_buffer  : std_logic_vector (7 downto 0) := (others => '0');
    signal cram_latch   : std_logic_vector (7 downto 0) := (others => '0');

    -- keep track of the last state so we can detect edges
    signal last_control_rd  : std_logic := '0';
    signal last_control_wr  : std_logic := '0';
    signal last_data_rd     : std_logic := '0';
    signal last_data_wr     : std_logic := '0';

    signal control_rd_edge : std_logic := '0';
    signal control_wr_edge : std_logic := '0';
    signal data_rd_edge    : std_logic := '0';
    signal data_wr_edge    : std_logic := '0';

    signal status_r : std_logic_vector (7 downto 0) := (others => '0');

    --
    -- SECOND BYTE FLAG
    --

    -- Flag to indicate if the control port is recieving the
    -- first or second byte. After first byte is recieved flag
    -- is set. After second byte is recieved or any other port
    -- is read/write the flag is cleared
    signal second_byte : std_logic := '0';

    -- vram address is set by two writes to the control port
    -- every other port just increments the address
    signal next_vram_addr_a : std_logic_vector (13 downto 0) := (others => '0');
    signal addr_hold        : std_logic_vector (7 downto 0)  := (others => '0');

begin

    -- name table base address
    nt_base_addr     <= reg(2)(3 downto 1) & slv(to_unsigned(0, 11));
    irq_vsync_en     <= reg(1)(5);
    irq_line_en      <= reg(0)(4);
    scroll_x         <= reg(8);
    scroll_y         <= reg(9);
    disable_x_scroll <= reg(0)(6);
    disable_y_scroll <= reg(0)(7);
    m1               <= reg(1)(4);
    m2               <= reg(0)(1);
    m3               <= reg(1)(3);
    m4               <= reg(0)(2);
    blank            <= not reg(1)(6);

    -- m4: 1 = use mode 4, 0 = use tms modes (selected with m1 m2 m3)
    -- m2: 1 = m1/m3 change screen height in mode 4
    -- m1: 1 = 224 lines if m2=1
    -- m3: 1 = 240 lines if m2=1

    mode_4_192 <= (m4 and (not m2)) or (m4 and m2 and (not m1) and (not m3));

    -- ----------------------------------------------------
    --                      VRAM
    -- ----------------------------------------------------

    vram : entity work.vram
        port map(
            -- port a = cpu side
            clk_a => (not vga_clk),
            we_a => vram_we_a,
            addr_a => vram_addr_a,
            do_a => vram_do_a,
            di_a => vram_di_a,

            -- port b = vdp side
            clk_b => (not vga_clk),
            we_b => '0',
            addr_b => vram_addr_b,
            do_b => vram_do_b,
            di_b => vram_di_b
        );

    -- ----------------------------------------------------
    --                      VDP BACKGROUND
    -- ----------------------------------------------------

    vdp_background : entity work.vdp_background
        port map(
            clk => vga_clk,
            pixel_x => pixel_x,
            pixel_y => pixel_y,
            scroll_x => scroll_x,
            scroll_y => scroll_y,
            disable_x_scroll => disable_x_scroll,
            disable_y_scroll => disable_y_scroll,
            name_table_addr => nt_base_addr,
            vram_a => vram_addr_b,
            vram_d => vram_do_b,
            color => bg_color,
            priority => priority
        );

    -- ----------------------------------------------------
    --                      VGA TIMING
    -- ----------------------------------------------------

    vga_timing : entity work.vga_timing
        port map(
            clk_50 => clk_50,
            rst => rst,
            vga_hs => VGA_HS,
            vga_vs => VGA_VS,
            pixel_y => pixel_y,
            pixel_x => pixel_x,
            in_display_area => in_display_area,
            vga_clk => vga_clk
        );

    process(vga_clk) begin
        if rising_edge(vga_clk) then
            -- cropped screen that is actually drawn
            if ((pixel_x >= 8*8 and pixel_x < (8+20)*8) and
                (pixel_y >= 3*8 and pixel_y < (3+18)*8)) then
                if (blank = '1') then
                    vga_red <= x"0";
                    vga_grn <= x"0";
                    vga_blu <= x"0";
                else
                    vga_red <= CRAM(to_integer(unsigned(bg_color)))(3 downto 0);
                    vga_grn <= CRAM(to_integer(unsigned(bg_color)))(7 downto 4);
                    vga_blu <= CRAM(to_integer(unsigned((bg_color+1))))(3 downto 0);
                end if;
            -- gray out screen outside the crop area
            elsif (pixel_x < 256 and pixel_y < 192) then
                vga_red <= slv(shift_right(unsigned(CRAM(to_integer(unsigned(bg_color)))(3 downto 0)), 3));
                vga_grn <= slv(shift_right(unsigned(CRAM(to_integer(unsigned(bg_color)))(7 downto 4)), 3));
                vga_blu <= slv(shift_right(unsigned(CRAM(to_integer(unsigned((bg_color+1))))(3 downto 0)), 3));
            -- palette
            elsif (pixel_y >= 262 and pixel_x < 256) then
                vga_red <= CRAM(to_integer(unsigned(pixel_x(7 downto 3)))*2)(3 downto 0);
                vga_grn <= CRAM(to_integer(unsigned(pixel_x(7 downto 3)))*2)(7 downto 4);
                vga_blu <= CRAM(to_integer(unsigned(pixel_x(7 downto 3)))*2+1)(3 downto 0);
            elsif (data_wr = '1' and (code /= 3)) then
                vga_red <= x"0";
                vga_grn <= x"F";
                vga_blu <= x"0";
            elsif (data_wr = '1' and (code = 3)) then
                vga_red <= x"F";
                vga_grn <= x"0";
                vga_blu <= x"0";
            elsif (control_rd = '1') then
                vga_red <= x"0";
                vga_grn <= x"0";
                vga_blu <= x"F";
            elsif (control_wr = '1') then
                vga_red <= x"F";  -- yellow
                vga_grn <= x"F";
                vga_blu <= x"0";
            elsif (data_rd = '1') then
                vga_red <= x"F";  -- purple
                vga_grn <= x"0";
                vga_blu <= x"F";
            -- ntsc size outline
            elsif (pixel_y = 262 or pixel_x = 342) then
                vga_red <= x"8";
                vga_grn <= x"8";
                vga_blu <= x"8";
            -- grid
            elsif (pixel_x(2 downto 0) = "111" or pixel_y(2 downto 0) = "111") then
                vga_grn <= x"1";
                vga_red <= x"1";
                vga_blu <= x"1";
            -- we only support mode 4 with 192 lines
            -- indicate an error if we're in a different mode
            elsif (mode_4_192 /= '1') then
                vga_red <= x"3";
                vga_grn <= x"0";
                vga_blu <= x"0";
            else
                vga_grn <= x"0";
                vga_red <= x"0";
                vga_blu <= x"0";
            end if;
        end if;
    end process;

    process(vga_clk) begin
        if rising_edge(vga_clk) then
            if (in_display_area = '1') then
                VGA_R <= vga_red;
                VGA_G <= vga_grn;
                VGA_B <= vga_blu;
            else
                VGA_R <= x"0";
                VGA_G <= x"0";
                VGA_B <= x"0";
            end if;
        end if;
    end process;

    -- ----------------------------------------------------
    --                    COUNTERS
    -- ----------------------------------------------------

    -- NTSC 256x192
    -- each scanline = 342 pixels
    -- each frame    = 262 scanlines

    -- h counter
    process(vga_clk) begin
        if rising_edge(vga_clk) then
            if (pixel_x = 342) then
                line_complete <= '1';
            end if;
            if (pixel_x < 342) then
                h_counter <= pixel_x(8 downto 0);
            else
                -- 342
                h_counter <= slv(to_unsigned(342, h_counter'length));
            end if;
        end if;
    end process;

    -- v counter
    process(vga_clk) begin
        if rising_edge(vga_clk) then
            if (line_complete = '1') then
                if (pixel_y <= x"DA") then
                    v_counter(7 downto 0) <= pixel_y(7 downto 0);
                elsif (pixel_y < 262) then
                    v_counter <= x"D5" + (pixel_y(8 downto 0) - x"DB");
                else
                    v_counter(7 downto 0) <= x"FF";
                end if;
            end if;
        end if;
    end process;

    vdp_v_counter <= v_counter(7 downto 0);
    vdp_h_counter <= h_counter(8 downto 1);

    -- ----------------------------------------------------
    --                       IRQ
    -- ----------------------------------------------------

    -- frame interrupt

    -- active area is 192 lines (0-191)
    process (vga_clk) begin
        if rising_edge(vga_clk) then
            if (pixel_y = 192 and pixel_x = 0) then
                report("[vdp] Vsync IRQ");
                status_r(7) <= '1';
            elsif (control_rd = '1') then
                status_r(7) <= '0';
            end if;
        end if;
    end process;

    -- line interrupt

    process(vga_clk) begin
        if rising_edge(vga_clk) then
            if (line_complete = '1') then
                if (pixel_y >= 193) then
                    line_counter <= reg(10);
                --elsif
                else
                    if (line_counter = x"00") then
                        line_counter <= reg(10);
                        line_irq <= '1';
                    else
                        line_counter <= line_counter - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- disable line counter irq for now since it causes corruption
    -- disabling it in osmose too seems to have no effect
    -- irq_line_pending <= (line_irq and irq_line_en);
    --irq_n <= (irq_vsync_pending or irq_line_pending) ?? 0 : 1;
    process(vga_clk) begin
        if rising_edge(vga_clk) then
            if (status_r(7) = '1' and irq_vsync_en = '1') then
                irq_vsync_pending <= '1';
            else
                irq_vsync_pending <= '0';
            end if;
        end if;
    end process;

    status(7) <= status_r(7);

    process(vga_clk) begin
        if rising_edge(vga_clk) then
            if (irq_vsync_pending = '1' or irq_line_pending = '1') then
                irq_n <= '0';
            else
                irq_n <= '1';
            end if;
        end if;
    end process;

    -- ----------------------------------------------------
    --                  CONTROL LOGIC
    -- ----------------------------------------------------

    --
    -- CONTROL / DATA EDGE DETECTION
    --

    process(z80_clk, rst) begin
        if (rst = '1') then
            last_control_rd <= '0';
            last_control_wr <= '0';
            last_data_rd <= '0';
            last_data_wr <= '0';
        elsif rising_edge(z80_clk) then
            last_control_rd <= control_rd;
            last_control_wr <= control_wr;
            last_data_rd <= data_rd;
            last_data_wr <= data_wr;
        end if;
    end process;

    process(z80_clk) begin
        if rising_edge(z80_clk) then
            if (control_rd = '1' and (last_control_rd /= '1')) then
                control_rd_edge <= '1';
            else
                control_rd_edge <= '0';
            end if;
            if (control_wr = '1' and (last_control_wr /= '1')) then
                control_wr_edge <= '1';
            else
                control_wr_edge <= '0';
            end if;
            if (data_rd = '1' and (last_data_rd /= '1')) then
                data_rd_edge <= '1';
            else
                data_rd_edge <= '0';
            end if;
            if (data_wr = '1' and (last_data_wr /= '1')) then
                data_wr_edge <= '1';
            else
                data_wr_edge <= '0';
            end if;
        end if;
    end process;

    --
    -- SECOND BYTE FLAG
    --

    process(z80_clk, rst) begin
        if (rst = '1') then
            second_byte <= '0';
        elsif rising_edge(z80_clk) then
            if (control_wr_edge = '1') then
                second_byte <= (not second_byte);
            elsif (control_rd_edge = '1' or data_wr_edge = '1' or data_rd_edge = '1') then
                second_byte <= '0';
            end if;
        end if;
    end process;

    --
    -- VRAM ADDRESS
    --

    process(z80_clk) begin
        if rising_edge(z80_clk) then
            vram_addr_a <= next_vram_addr_a;

            if (control_wr_edge = '1') then
                if (second_byte = '0') then
                    addr_hold <= control_i;
                --elsif
                else
                    if (control_i(7 downto 6) = 0) then
                        next_vram_addr_a <= control_i(5 downto 0) & (addr_hold) + 1;
                    else
                        next_vram_addr_a(7 downto 0) <= addr_hold;
                        next_vram_addr_a(13 downto 8) <= control_i(5 downto 0);
                    end if;
                end if;
            elsif (control_rd_edge  = '1' or data_wr_edge = '1' or data_rd_edge = '1') then
                next_vram_addr_a <= vram_addr_a + 1;
            end if;
        end if;
    end process;

    -- vram write enable when we're not writing to cram
    process(z80_clk) begin
        if rising_edge(z80_clk) then
            if (data_wr = '1' and code /= 3) then
                vram_we_a <= '1';
            else
                vram_we_a <= '0';
            end if;
        end if;
    end process;

    process(z80_clk, rst) begin

        if (rst = '1') then
            reg(0) <= x"00";    -- mode control 1
            reg(1) <= x"00";    -- mode control 2
            reg(2) <= x"0e";    -- name table base address (0x3800)
            reg(3) <= x"00";    -- color table base address
            reg(4) <= x"00";    -- background pattern generator base address
            reg(5) <= x"7e";    -- sprite attribute table base address (0x3F00)
            reg(6) <= x"00";    -- sprite pattern generator base address
            reg(7) <= x"00";    -- overscan/backdrop color
            reg(8) <= x"00";    -- background X scroll
            reg(9) <= x"00";    -- background Y scroll
            reg(10) <= x"ff";   -- line counter
            data_o <= x"00";
        elsif rising_edge(z80_clk) then

            if (control_wr_edge = '1') then

                if (second_byte = '1') then
                    code <= control_i(7 downto 6);
                    -- check for register write instead
                    if (control_i(7 downto 6) = 2) then
                        reg(to_integer(unsigned(control_i(3 downto 0)))) <= addr_hold;
                        --$display("[VDP] reg %d set to %x", control_i(3 downto 0), addr_hold);
                    else
                        --#1 $display("[VDP] setting vram addr to %x code %d", next_vram_addr_a, code);
                    end if;
                end if;

            elsif (control_rd_edge = '1') then

                read_buffer <= vram_do_a;
                report("[VDP] reading control");

            elsif (data_rd_edge = '1') then

                data_o <= read_buffer;
                read_buffer <= vram_do_a;
                report("[VDP] reading data");

            elsif (data_wr_edge = '1') then

                if (code = 3) then
                    if (vram_addr_a(0) = '0') then
                        cram_latch <= data_i;
                    else
                        --$display("[VDP] Writing cram addr %x with %x%x", vram_addr_a(5 downto 0)-1, data_i, cram_latch);
                        CRAM(to_integer(unsigned(vram_addr_a(5 downto 0)))-1) <= cram_latch;
                        CRAM(to_integer(unsigned(vram_addr_a(5 downto 0))))   <= data_i;
                    end if;
                else
                    --$display("[VDP] Writing vram addr %x with %x", vram_addr_a, data_i);
                    vram_di_a <= data_i;
                    read_buffer <= data_i;
                end if;
            end if;
        end if;
    end process;
end rtl;
