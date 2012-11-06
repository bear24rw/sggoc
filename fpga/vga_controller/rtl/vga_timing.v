`include "constants.vh"

module vga_timing (
    input clk_50,
    input rst,

    output reg vga_hs = 0,
    output reg vga_vs = 0,

    output reg vga_clk = 0,

    output reg [9:0] h_sync_cnt = 0,
    output reg [9:0] v_sync_cnt = 0
);

    always @(posedge clk_50)
        vga_clk = ~vga_clk;

    always @(posedge vga_clk) begin
        if (rst) begin
            h_sync_cnt <= 0;
            v_sync_cnt <= 0;
            vga_hs     <= 1;
            vga_vs     <= 1;
        end else begin

            if (h_sync_cnt > `h_sync_pulse_cnt)
                vga_hs <= 0;
            else
                vga_hs <= 1;

            if (h_sync_cnt == `h_line_cnt) begin
                h_sync_cnt <= 0;
                v_sync_cnt <= v_sync_cnt + 1;
            end else
                h_sync_cnt <= h_sync_cnt + 1;
                
            if (v_sync_cnt > `v_sync_pulse_cnt) 
                vga_vs <= 0;
            else
                vga_vs <= 1;

            if (v_sync_cnt == `v_fram_cnt) 
                v_sync_cnt <= 0;

        end

    end

endmodule
