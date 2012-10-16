`include "constants.vh"

module vga (
    input clk_50,
    input rst,

    output reg [3:0] vga_r = 0,
    output reg [3:0] vga_g = 0,
    output reg [3:0] vga_b = 0,

    output reg vga_hs = 0,
    output reg vga_vs = 0
);

    reg clk_25 = 0;

    /* keep track of each frame 
    and line count of disp */
    reg [9:0] fram_cnt = 0;
    reg [9:0] line_cnt = 0;
    //reg [3:0] vga_cntr = 0;

    reg [3:0] next_state = 0;

    supply0 gnd;

    always @ (posedge clk_50)
        clk_25 = ~clk_25;

    always @ (posedge clk_25) begin
        if (rst) begin
            next_state <= `v_sync;
            fram_cnt   <= 0;
            line_cnt   <= 0;
        end

        else begin
            //vga_cntr <= vga_cntr + 1;
            vga_hs   <= 1;
            vga_vs   <= 1;

            if (line_cnt == `h_line_cnt) begin
                line_cnt <= 0;
                
                if  (fram_cnt == `v_fram_cnt) fram_cnt <= 0;
                else fram_cnt <= fram_cnt + 1;

            end else 
                line_cnt <= line_cnt + 1;

            case (next_state)
                
                `v_sync: begin 
                    vga_vs <= 0;
                    
                    if (fram_cnt == `v_sync_cnt && line_cnt == `h_line_cnt)
                        next_state <= `v_fron_porch;
                end

                `v_fron_porch: begin 
                    
                    if (fram_cnt == `v_fron_porch_cnt && line_cnt == `h_line_cnt)
                        next_state <= `h_sync;
                end

                `h_sync: begin
                    vga_hs <= 0;

                    if (line_cnt == `h_sync_cnt)
                        next_state <= `h_fron_porch;
                end

                `h_fron_porch: begin
                    vga_hs <= 0;

                    if (line_cnt == `h_fron_porch_cnt)
                        next_state <= `drive_pixels;
                end
                
                `drive_pixels: begin
                    `rgb <= `red;

                    if (line_cnt == `h_visible_cnt || fram_cnt == `v_visible_cnt)
                        next_state <= `h_back_porch;
                end

                `h_back_porch: begin

                    if (line_cnt == `h_back_porch_cnt)
                        if (fram_cnt == (`v_fram_cnt - `v_back_porch_cnt))
                            next_state <= `v_back_porch;
                        else
                            next_state <= `h_sync;
                end

                `v_back_porch: begin

                    if (fram_cnt == `v_back_porch_cnt && line_cnt == `h_line_cnt)
                        if (fram_cnt == (`v_fram_cnt - `v_back_porch_cnt))
                            next_state <= `v_sync;
                end

                //default:

            endcase

        end

    end

endmodule
