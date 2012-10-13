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
    input UART_RXD,
    output UART_TXD
);
    
    wire clk = CLOCK_50;
    wire rst = ~KEY[0];
   
    reg transmit;
    wire rx_done;
    wire tx_done;

    wire [7:0] rx_data;
    reg [7:0] tx_data = 0;

    assign LEDG[0] = rx_done;
    assign LEDG[1] = tx_done;
    assign LEDG[2] = transmit;
    assign LEDR = rx_data;

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

    assign LEDG[3] = new_byte;


    localparam S_REQUEST = 0;
    localparam S_RECV    = 1;
    localparam S_WRITE   = 2;

    reg [2:0] state = S_REQUEST;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= S_REQUEST;
            tx_data <= 0;
            transmit <= 0;
        end else begin
            case (state)
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

                    // if we got a new byte, send it back to ACK
                    // go to REQUEST state to get another one
                    if (new_byte) begin
                        tx_data = rx_data;
                        state = S_REQUEST;
                    end
                end
            endcase
        end
    end


endmodule

// vim: set textwidth=60:

