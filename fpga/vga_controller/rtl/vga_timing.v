`include "constants.vh"

module vga_timing (
    input clk_50,
    input rst,

    //output reg [3:0] vga_r = 0,
    //output reg [3:0] vga_g = 0,
    //output reg [3:0] vga_b = 0,

    output reg [9:0] h_sync_cnt = 0,
    output reg [9:0] v_sync_cnt = 0,

    output reg vga_hs = 0,
    output reg vga_vs = 0,

    output reg vga_clk = 0
);

    always @(posedge clk_50)
        vga_clk = ~vga_clk;

    always @(posedge vga_clk) begin
        if (rst) begin

            h_sync_cnt <= 0;
            v_sync_cnt <= 0;
            vga_hs     <= 0;
            vga_vs     <= 0;

        end else begin

            if (h_sync_cnt >= (`h_sync_pulse_cnt + `h_fron_porch_cnt) && 
                h_sync_cnt <= (`h_visible_cnt    + `h_back_porch_cnt))
                vga_hs <= 1;
            else
                vga_hs <= 0;

            if (h_sync_cnt == `h_line_cnt) begin
                h_sync_cnt <= 0;
                vga_hs     <= 0;

            end else
                h_sync_cnt <= h_sync_cnt + 1;
                
            if (v_sync_cnt >= (`v_sync_pulse_cnt + `v_fron_porch_cnt) && 
                v_sync_cnt <= (`v_visible_cnt    + `v_back_porch_cnt))
                vga_vs <= 1;
            else
                vga_vs <= 0;

            if (v_sync_cnt == `v_fram_cnt) begin
                v_sync_cnt <= 0;
                vga_vs     <= 0;

            end else
                v_sync_cnt <= v_sync_cnt + 1;

        end

    end

endmodule
