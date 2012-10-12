/***************************************************************************
 *   Copyright (C) 2012 by Max Thrun                                       *
 *   Copyright (C) 2012 by Samir Silbak                                    *
 *                                                                         *
 *   (SSGoC) Sega Game Gear on a Chip                                              *
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
    
    wire rst = ~KEY[0];
    wire clk;
    clk_div #(.COUNT(500000)) clk_div(CLOCK_50, clk);
   
    reg transmit;
    wire received;
    wire is_receiving;
    wire is_transmitting;
    wire recv_error;
    wire [7:0] rx_byte;
    reg [7:0] tx_byte = 0;

    assign LEDG[0] = is_receiving;
    assign LEDG[1] = is_transmitting;
    assign LEDR[0] = recv_error;

    uart uart(
        .clk(CLOCK_50),
        .rst(rst),
        .rx(UART_RXD),
        .tx(UART_TXD),
        .transmit(transmit),
        .received(received),
        .rx_byte(rx_byte),
        .tx_byte(tx_byte),
        .is_receiving(is_receiving),
        .is_transmitting(is_transmitting),
        .recv_error(recv_error)
    );

    // the receive line only goes high for one clock
    // cycle so we need to latch it. if we are currently
    // transmitting we obviously don't have a new byte yet

    reg new_byte = 0;

    always @(posedge rst, posedge transmit, posedge received) begin
        if (rst)
            new_byte <= 0;
        else if (transmit)
            new_byte <= 0;
        else
            new_byte <= 1;
    end

    assign LEDG[2] = new_byte;


    localparam S_REQUEST = 0;
    localparam S_RECV    = 1;
    localparam S_WRITE   = 2;

    reg [2:0] state = S_REQUEST;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= S_REQUEST;
            tx_byte <= 0; 
            transmit <= 0;
        end else begin
            case (state)
                // we want to request the next byte
                // trigger the uart to transmit and
                // then go to RECV state to wait for
                // the data
                S_REQUEST: begin
                    transmit = 1;
                    state = S_RECV;
                end

                // wait for the new data byte
                // clear the transmit flag so we only
                // transmit one byte
                S_RECV: begin
                    transmit = 0;

                    // if we got a new byte, send it back to ACK
                    // go to REQUEST state to get another one
                    if (new_byte) begin
                        tx_byte = rx_byte;
                        state = S_REQUEST;
                    end
                end
            endcase
        end
    end


endmodule

// vim: set textwidth=60:

