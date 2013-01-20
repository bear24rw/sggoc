module vdp_background (
    input clk,
    input rst,

    input [9:0] x,
    input [9:0] y,

    input [13:0] name_table_addr,

    output reg [13:0] vram_a,
    input [7:0] vram_d,

    output [4:0] color
);

    reg [8:0] tile_idx;
    reg [13:0] tile_addr;
    reg [13:0] data_addr;
    reg [2:0] tile_y;
    reg flip_x = 0;
    reg palette;

    reg [7:0] data0;
    reg [7:0] data1;
    reg [7:0] data2;
    reg [7:0] data3;

    reg [7:0] shift0;
    reg [7:0] shift1;
    reg [7:0] shift2;
    reg [7:0] shift3;

    // row/col are every 8 pixels
    wire [4:0] row  = y[7:3];
    wire [4:0] col  = x[7:3];

    always @(posedge clk) begin
        
        //tile_addr <= name_table_addr + (col*2) + (row*32*2);
        tile_addr <= name_table_addr + (col<<1) + (row<<6);
        //data_addr <= (tile_idx*32) + (y & 10'b111)*4;
        data_addr <= (tile_idx<<5) + (y & 10'b111)<<2;

        case(x[2:0])
            0: vram_a <= tile_addr + 0;
            1: vram_a <= tile_addr + 1;
            3: vram_a <= data_addr + 0;
            4: vram_a <= data_addr + 1;
            5: vram_a <= data_addr + 2;
            6: vram_a <= data_addr + 3;
        endcase
    end

    always @(posedge clk) begin
        case (x[2:0])
            1: tile_idx[7:0] <= vram_d;
            2: tile_idx[8] <= vram_d[0];
            4: data0 <= vram_d;
            5: data1 <= vram_d;
            6: data2 <= vram_d;
        endcase
    end

    always @(posedge clk) begin
        case (x[2:0])
            7: begin
                shift0 <= data0;
                shift1 <= data1;
                shift2 <= data2;
                shift3 <= vram_d;
            end
            default: begin
                shift0[7:1] <= shift0[6:0];
                shift1[7:1] <= shift1[6:0];
                shift2[7:1] <= shift2[6:0];
                shift3[7:1] <= shift3[6:0];
            end
        endcase
    end

    assign color[0] = shift0[7];
    assign color[1] = shift1[7];
    assign color[2] = shift2[7];
    assign color[3] = shift3[7];
    assign color[4] = 0;

endmodule
