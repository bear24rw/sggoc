module vdp_background (
    input               clk,
    input       [9:0]   pixel_x,
    input       [9:0]   pixel_y,
    input       [7:0]   scroll_x,
    input       [7:0]   scroll_y,
    input               disable_x_scroll,
    input               disable_y_scroll,
    input       [13:0]  name_table_addr,
    input       [7:0]   vram_d,
    output reg  [13:0]  vram_a,
    output      [5:0]   color,
    output reg          priority

);

    reg flip_x;             // flip tile horizontally
    reg palette;            // use upper half of palette
    reg palette_latch;      // hold it until we start outputting that tile
    reg priority_latch;     // tile priority (behind or infront of sprite)
    reg [2:0] line;         // line within the tile
    reg [8:0] tile_idx;     // which tile (0-512)

    // bitplanes (4th one comes directly from vram_d)
    reg [7:0] data0;
    reg [7:0] data1;
    reg [7:0] data2;

    // shift register for bitplanes
    reg [7:0] shift0;
    reg [7:0] shift1;
    reg [7:0] shift2;
    reg [7:0] shift3;

    reg [13:0] tile_addr = 0;
    reg [13:0] data_addr = 0;

    wire [7:0] x = (disable_x_scroll && y[7:3] < 2) ? pixel_x : pixel_x - scroll_x;
    wire [7:0] y = (disable_y_scroll && x[7:3] > 24) ? pixel_y : scroll_y + pixel_y;

    always @(posedge clk) begin

        // x[7:3] = current tile on x
        // y[7:3] = current tile on y
        // y[2:0] = current line within line

        tile_addr <= name_table_addr + (x[7:3]*2) + (y[7:3]*32*2);
        data_addr <= (tile_idx*32) + (line*4);

        case(x[2:0])
            0: vram_a <= tile_addr;
            1: vram_a <= tile_addr + 1;
            2: vram_a <= 'h0;
            3: vram_a <= data_addr;
            4: vram_a <= data_addr + 1;
            5: vram_a <= data_addr + 2;
            6: vram_a <= data_addr + 3;
            7: vram_a <= 'h0;
            default: vram_a <= 'hxxxx;
        endcase
    end

    always @(posedge clk) begin
        case (x[2:0])
            1: tile_idx[7:0] <= vram_d;
            2: begin
                tile_idx[8]    <= vram_d[0];
                flip_x         <= vram_d[1];
                line[0]        <= y[0]^vram_d[2];
                line[1]        <= y[1]^vram_d[2];
                line[2]        <= y[2]^vram_d[2];
                palette_latch  <= vram_d[3];
                priority_latch <= vram_d[4];
            end
            4: data0 <= vram_d;
            5: data1 <= vram_d;
            6: data2 <= vram_d;
        endcase
    end

    always @(posedge clk) begin
        if (x[2:0] == 3'b111) begin
            if (flip_x == 1'b0) begin
                shift0 <= data0;
                shift1 <= data1;
                shift2 <= data2;
                shift3 <= vram_d;
            end else begin
                shift0 <= {data0[0], data0[1], data0[2], data0[3], data0[4], data0[5], data0[6], data0[7]};
                shift1 <= {data1[0], data1[1], data1[2], data1[3], data1[4], data1[5], data1[6], data1[7]};
                shift2 <= {data2[0], data2[1], data2[2], data2[3], data2[4], data2[5], data2[6], data2[7]};
                shift3 <= {vram_d[0], vram_d[1], vram_d[2], vram_d[3], vram_d[4], vram_d[5], vram_d[6], vram_d[7]};
            end
            palette <= palette_latch;
            priority <= priority_latch;
        end else begin
            shift0[7:1] <= shift0[6:0];
            shift1[7:1] <= shift1[6:0];
            shift2[7:1] <= shift2[6:0];
            shift3[7:1] <= shift3[6:0];
        end
    end

    // each color is two bytes so shift left 1
    // palette selects upper half of CRAM
    assign color[0] = 0;
    assign color[1] = shift0[7];
    assign color[2] = shift1[7];
    assign color[3] = shift2[7];
    assign color[4] = shift3[7];
    assign color[5] = palette;

endmodule
