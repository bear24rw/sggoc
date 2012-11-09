`define     rgb {vga_r, vga_g, vga_b}
`define     red {4'd15, 4'd0, 4'd0}
`define     green {4'd0, 4'd15, 4'd0}
`define     blue {4'd0, 4'd0, 4'd15}

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
