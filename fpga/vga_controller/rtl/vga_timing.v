`include "constants.vh"

module vga_timing (
    input clk_50,
    input rst,

    output reg vga_hs = 0,
    output reg vga_vs = 0,

    output reg vga_clk = 0,

    output reg [9:0] scan_y = 0,
    output reg [9:0] scan_x = 0
);

    always @(posedge clk_50)
        vga_clk = ~vga_clk;

    always @(posedge vga_clk) begin
        if (rst) begin
            scan_y <= 0;
            scan_x <= 0;
            vga_hs <= 1;
            vga_vs <= 1;
        end else begin

            if (scan_y > `h_sync_pulse_cnt)
                vga_hs <= 1;
            else
                vga_hs <= 0;

            if (scan_y == `h_line_cnt) begin
                scan_y <= 0;
                scan_x <= scan_x + 1;
            end else
                scan_y <= scan_y + 1;
                
            if (scan_x > `v_sync_pulse_cnt) 
                vga_vs <= 1;
            else
                vga_vs <= 0;

            if (scan_x == `v_fram_cnt) 
                scan_x <= 0;

        end

    end

endmodule
