/***************************************************************************
 *   Copyright (C) 2012 by Max Thrun                                       *
 *   Copyright (C) 2012 by Samir Silbak                                    *
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

module top(
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [7:0] LEDG,
    output [9:0] LEDR,
    output [6:0] HEX0,
    input UART_RXD,
    output UART_TXD,

    inout [7:0] FL_DQ,
    output [21:0] FL_ADDR,
    output FL_OE_N,
    output FL_CE_N,
    output FL_WE_N,
    output FL_RST_N
);
    
    wire clk = CLOCK_50;
    wire rst = ~KEY[0];
    wire skip_erase = SW[0];    // skips the erase cycle if sw[0] = 1

    // ----------------------------------------------------
    //                      UART
    // ----------------------------------------------------

    reg transmit;
    wire rx_done;
    wire tx_done;

    wire [7:0] rx_data;
    reg [7:0] tx_data = 0;

    uart uart(
        .sys_clk(clk),
        .sys_rst(rst),

        .uart_rx(UART_RXD),
        .uart_tx(UART_TXD),

        .divisor(50000000/9600/16),

        .rx_data(rx_data),
        .tx_data(tx_data),

        .rx_done(rx_done),
        .tx_done(tx_done),

        .tx_wr(transmit)
    );

    // the receive line only goes high for one clock
    // cycle so we need to latch it. if we are currently
    // transmitting we obviously don't have a new byte yet

    reg new_byte = 0;

    always @(posedge rst, posedge transmit, posedge rx_done) begin
        if (rst)
            new_byte <= 0;
        else if (transmit)
            new_byte <= 0;
        else
            new_byte <= 1;
    end

    // ----------------------------------------------------
    //                     FLASH
    // ----------------------------------------------------

    reg [21:0] flash_addr = 0;
    reg [7:0] flash_data = 0;
    reg flash_write = 0;
    reg flash_erase = 0;
    reg flash_done = 0;

    Altera_UP_Flash_Memory_UP_Core_Standalone flash (
        .i_clock(clk),
        .i_reset_n(~rst),
        .i_address(flash_addr),
        .i_data(flash_data),
        .i_read(0),
        .i_write(flash_write),
        .i_erase(flash_erase),
        .o_data(),
        .o_done(flash_done),

        .FL_ADDR(FL_ADDR),
        .FL_DQ(FL_DQ),
        .FL_CE_N(FL_CE_N),
        .FL_OE_N(FL_OE_N),
        .FL_WE_N(FL_WE_N),
        .FL_RST_N(FL_RST_N)
    );


    // ----------------------------------------------------
    //                 STATE MACHINE
    // ----------------------------------------------------

    localparam S_ERASE      = 0;    // erase flash chip
    localparam S_ERASE_WAIT = 1;    // wait for erase to finish
    localparam S_REQUEST    = 2;    // request next data byte from uart
    localparam S_RECV       = 3;    // wait for data byte
    localparam S_WRITE      = 4;    // write data to flash chip
    localparam S_WRITE_WAIT = 5;    // wait for write to finish

    reg [2:0] state = S_ERASE;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= S_ERASE;
            tx_data <= 0;
            transmit <= 0;
            flash_erase <= 0;
            flash_write <= 0;
            flash_data <= 0;
            flash_addr <= 0;
        end else begin
            case (state)

                S_ERASE: begin
                    if (skip_erase)
                        state = S_REQUEST;
                    else
                        flash_addr = ~(22'b0); // erase whole chip (all 1's)
                        flash_erase = 1;
                        state = S_ERASE_WAIT;
                end

                S_ERASE_WAIT: begin
                    if (flash_done) begin
                        flash_erase = 0;
                        state = S_REQUEST;
                    end
                end

                // we want to request the next byte.
                // trigger the uart to transmit and
                // then go to RECV state to wait for
                // the data
                S_REQUEST: begin
                    transmit = 1;
                    state = S_RECV;
                end

                // clear the transmit flag so we only
                // transmit one byte. check to see if
                // we recieved a new byte
                S_RECV: begin
                    transmit = 0;

                    // if we got a new byte, send it back to ACK.
                    // go to WRITE to put it in flash
                    if (new_byte) begin
                        tx_data = rx_data;
                        state = S_WRITE;
                    end
                end

                S_WRITE: begin
                    flash_data = rx_data;
                    flash_write = 1;
                    state = S_WRITE_WAIT;
                end

                S_WRITE_WAIT: begin
                    if (flash_done) begin
                        flash_addr = flash_addr + 1;
                        flash_write = 0;
                        state = S_REQUEST;
                    end
                end

            endcase
        end
    end

    // ----------------------------------------------------
    //                  STATUS LEDS
    // ----------------------------------------------------

    assign LEDG[0] = rx_done;
    assign LEDG[1] = tx_done;
    assign LEDG[2] = transmit;
    assign LEDG[3] = new_byte;
    assign LEDG[4] = flash_erase;
    assign LEDG[5] = flash_write;
    assign LEDG[6] = flash_done;
    //assign LEDR = (flash_erase) ? FL_ADDR[21:11] : rx_data;
    assign LEDR = FL_ADDR[9:0];

    seven_seg ss(state, HEX0);

endmodule

// vim: set textwidth=60:

