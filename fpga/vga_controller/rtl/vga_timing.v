`include "constants.vh"

module vga_timing (
    input clk_50,
    input rst,

    output reg vga_hs = 0,
    output reg vga_vs = 0,

    output reg vga_clk = 0,
    output [9:0] pixel_x,
    output [9:0] pixel_y,
    output in_display_area
);

    reg [9:0] scan_x = 0;
    reg [9:0] scan_y = 0;

    always @(posedge clk_50)
        vga_clk = ~vga_clk;

    always @(posedge vga_clk) begin
        if (rst) begin
            scan_x <= 0;
            scan_y <= 0;
            vga_hs <= 0;
            vga_vs <= 0;
        end else begin

            if (scan_x == `h_line_cnt) begin
                scan_x <= 0;
                scan_y <= scan_y + 1;
            end else
                scan_x <= scan_x + 1;

            if (scan_y == `v_fram_cnt)
                scan_y <= 0;

            if (scan_x > `h_sync_pulse_cnt)
                vga_hs <= 1;
            else
                vga_hs <= 0;
                
            if (scan_y > `v_sync_pulse_cnt)
                vga_vs <= 1;
            else
                vga_vs <= 0;

        end
    end

    assign pixel_x = scan_x - (`h_sync_pulse_cnt + `h_fron_porch_cnt);
    assign pixel_y = scan_y - (`v_sync_pulse_cnt + `v_fron_porch_cnt);
    assign in_display_area = (scan_x < `h_visible_cnt) && (scan_y < `v_visible_cnt);

endmodule
