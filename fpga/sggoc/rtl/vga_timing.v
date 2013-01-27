`define     h_sync_pulse_cnt    10'd095
`define     h_fron_porch_cnt    10'd045
`define     h_visible_cnt       10'd640
`define     h_back_porch_cnt    10'd020
`define     h_line_cnt          10'd800

`define     v_sync_pulse_cnt    10'd002
`define     v_fron_porch_cnt    10'd032
`define     v_visible_cnt       10'd480
`define     v_back_porch_cnt    10'd014
`define     v_fram_cnt          10'd528

module vga_timing (
    input clk_50,
    input rst,

    output vga_hs,
    output vga_vs,

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
        end else begin

            if (scan_x == `h_line_cnt-1) begin
                scan_x <= 0;
                scan_y <= scan_y + 1;
            end else
                scan_x <= scan_x + 1;

            if (scan_y == `v_fram_cnt)
                scan_y <= 0;

        end
    end

    assign vga_hs = (scan_x >= `h_sync_pulse_cnt);
    assign vga_vs = (scan_y >= `v_sync_pulse_cnt);

    assign pixel_x = scan_x - (`h_sync_pulse_cnt + `h_fron_porch_cnt);
    assign pixel_y = scan_y - (`v_sync_pulse_cnt + `v_fron_porch_cnt);
    assign in_display_area = (scan_x >= `h_sync_pulse_cnt + `h_fron_porch_cnt) &&
                             (scan_y >= `v_sync_pulse_cnt + `v_fron_porch_cnt) &&
                             (scan_x <  `h_sync_pulse_cnt + `h_fron_porch_cnt + `h_visible_cnt) &&
                             (scan_y <  `v_sync_pulse_cnt + `v_fron_porch_cnt + `v_visible_cnt);

endmodule
