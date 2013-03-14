/***************************************************************************
 *   Copyright (C) 2013 by Max Thrun                                       *
 *   Copyright (C) 2013 by Samir Silbak                                    *
 *                                                                         *
 *   (SSGoC) Sega Game Gear on a Chip                                      *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.              *
 ***************************************************************************/

module io(
    input           clk,
    input           rst,
    output  [7:0]   io_do,

    input   [7:0]   z80_do,
    input   [15:0]  z80_addr,
    input           z80_io_rd,
    input           z80_io_wr,

    output          vdp_data_rd,
    output          vdp_data_wr,
    output          vdp_control_rd,
    output          vdp_control_wr,

    input   [7:0]   vdp_data_o,
    input   [7:0]   vdp_status,
    input   [7:0]   vdp_v_counter,
    input   [7:0]   vdp_h_counter
);

    // ----------------------------------------------------
    //                GG SPECIFIC REGISTERS
    // ----------------------------------------------------

    reg [7:0] gg_reg [0:6];

    initial begin
        gg_reg[0] <= 8'hC0;
        gg_reg[1] <= 8'h7F;
        gg_reg[2] <= 8'hFF;
        gg_reg[3] <= 8'h00;
        gg_reg[4] <= 8'hFF;
        gg_reg[5] <= 8'h00;
        gg_reg[6] <= 8'hFF;
    end

    always @(posedge rst) begin
        gg_reg[0] <= 8'hC0;
        gg_reg[1] <= 8'h7F;
        gg_reg[2] <= 8'hFF;
        gg_reg[3] <= 8'h00;
        gg_reg[4] <= 8'hFF;
        gg_reg[5] <= 8'h00;
        gg_reg[6] <= 8'hFF;
    end

    // ----------------------------------------------------
    //              MEMORY CONTROL REGISTER
    // ----------------------------------------------------

    reg [7:0] mem_control = 8'hA4;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            mem_control <= 8'hA4;
        end else if (z80_io_wr && port == 0) begin
            mem_control <= z80_do;
        end
    end

    // ----------------------------------------------------
    //                  PORT DECODING
    // ----------------------------------------------------

    wire [2:0] port = {z80_addr[7], z80_addr[6], z80_addr[0]};

    // ----------------------------------------------------
    //                VDP CONTROL LINES
    // ----------------------------------------------------

    assign vdp_data_wr    = z80_io_wr && port == 4;
    assign vdp_data_rd    = z80_io_rd && port == 4;
    assign vdp_control_wr = z80_io_wr && port == 5;
    assign vdp_control_rd = z80_io_rd && port == 5;

    // ----------------------------------------------------
    //                Z80 INPUT MUX
    // ----------------------------------------------------

    assign io_do = (z80_addr == 0) ? gg_reg[0] :
                   (z80_addr == 1) ? gg_reg[1] :
                   (z80_addr == 2) ? gg_reg[2] :
                   (z80_addr == 3) ? gg_reg[3] :
                   (z80_addr == 4) ? gg_reg[4] :
                   (z80_addr == 5) ? gg_reg[5] :
                   (z80_addr == 6) ? gg_reg[6] :
                   (port == 0) ? mem_control :          // 0x3E - memory control
                   (port == 1) ? 8'hFF :                // 0x3F - io port control
                   (port == 2) ? vdp_v_counter :        // 0x7E - v counter
                   (port == 3) ? vdp_h_counter :        // 0x7F - h counter
                   (port == 4) ? vdp_data_o :           // 0xBE - vdp data
                   (port == 5) ? vdp_status :           // 0xBF - vdp control
                   (port == 6) ? 8'hFF :                // 0xDC - io port a/b
                   (port == 7) ? 8'hFF :                // 0xDD - io port b/misc
                   8'hFF;

    // ----------------------------------------------------
    //                  SIMULATION
    // ----------------------------------------------------

    always @(posedge z80_io_rd) begin
        case (port)
            0: $display("[IO READ] mem control");
            1: $display("[IO READ] io port control");
            2: $display("[IO READ] vdp v counter: %d", vdp_v_counter);
            3: $display("[IO READ] vdp h counter: %d", vdp_h_counter);
            4: $display("[IO READ] vdp data");
            5: $display("[IO READ] vdp control");
            6: $display("[IO READ] port a/b");
            7: $display("[IO READ] port b/misc");
            default: $display("[IO READ] port %d", port);
        endcase
    end

    always @(posedge z80_io_wr) begin
        case (port)
            0: $display("[IO WRITE] mem control");
            1: $display("[IO WRITE] io port control");
            2: $display("[IO WRITE] vdp v counter: %d");
            3: $display("[IO WRITE] vdp h counter: %d");
            4: $display("[IO WRITE] vdp data");
            5: $display("[IO WRITE] vdp control");
            6: $display("[IO WRITE] port a/b");
            7: $display("[IO WRITE] port b/misc");
            default: $display("[IO WRITE] port %d", port);
        endcase
    end

endmodule
