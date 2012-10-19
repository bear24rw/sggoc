`define     rgb {vga_r, vga_g, vga_b}
`define     rgb_gnd {9{gnd}}
`define     red {4'd15, 4'd0, 4'd0}
`define     green {4'd0, 4'd15, 4'd0}
`define     blue {4'd0, 4'd0, 4'd15}

/* states for horizontal line and 
vertical frame */

/*`define     v_sync              03'd000
`define     v_fron_porch        03'd001
`define     v_back_porch        03'd002

`define     h_sync              03'd003
`define     h_fron_porch        03'd004
`define     h_back_porch        03'd005

`define     drive_pixels        03'd006*/

/* timing for horizontal line and
vertical frame */

`define     h_sync_pulse_cnt    10'd094
`define     h_fron_porch_cnt    10'd044
`define     h_visible_cnt       10'd639
`define     h_back_porch_cnt    10'd019
`define     h_line_cnt          10'd799

`define     v_sync_pulse_cnt    10'd001
`define     v_fron_porch_cnt    10'd031
`define     v_visible_cnt       10'd479
`define     v_back_porch_cnt    10'd013
`define     v_fram_cnt          10'd527

// vim: set filetype=verilog:
