module vdp_background (
    input               clk,
    input       [9:0]   pixel_x,
    input       [9:0]   pixel_y,
    input       [7:0]   scroll_x,
    input       [7:0]   scroll_y,
    input               disable_x_scroll,
    input               disable_y_scroll,
    input       [2:0]   name_table_base,
    input       [7:0]   vram_data,
    output reg  [13:0]  vram_addr,
    output      [5:0]   color,
    output reg          priority_
);

    reg flip_x;             // flip tile horizontally
    reg palette;            // use upper half of palette
    reg palette_latch;      // hold it until we start outputting that tile
    reg priority_latch;     // tile priority (behind or infront of sprite)
    reg [2:0] line;         // line within the tile
    reg [8:0] tile_idx;     // which tile (0-512)

    // bitplanes (4th one comes directly from vram_data)
    reg [7:0] data0;
    reg [7:0] data1;
    reg [7:0] data2;

    // shift register for bitplanes
    reg [7:0] shift0;
    reg [7:0] shift1;
    reg [7:0] shift2;
    reg [7:0] shift3;

    // pixel location with scroll applied
    // x scroll: increasing value moves screen left
    // y scroll: increasing value moves screen up, wraps at row 28 (28 rows * 8 lines / row = 224)
    // scroll_lock_x locks the top 2 rows = 16 pixels
    // scroll_lock_y locks the last 8 columns (32 total columns - 8 = 24 = 192 pixels)
    wire [7:0] x = (disable_x_scroll && pixel_y < 16 ) ? pixel_x : (pixel_x - {2'b0, scroll_x});
    wire [7:0] y = (disable_y_scroll && pixel_x > 192) ? pixel_y : (pixel_y + {2'b0, scroll_y}) % 224;

    // tile indices
    wire [4:0] tile_x = x[7:3];
    wire [4:0] tile_y = y[7:3];

    // current column index
    wire [2:0] tile_column = x[2:0];

    wire [13:0] name_addr = {2'b00, name_table_base, tile_y, tile_x, 1'b0};
    wire [13:0] pattern_addr = {tile_idx, line, 2'b0};

    always @(posedge clk) begin

        case(tile_column)
            0: vram_addr <= name_addr;
            1: vram_addr <= name_addr + 1;
            2: vram_addr <= 'h0;
            3: vram_addr <= pattern_addr;
            4: vram_addr <= pattern_addr + 1;
            5: vram_addr <= pattern_addr + 2;
            6: vram_addr <= pattern_addr + 3;
            7: vram_addr <= 'h0;
        endcase

        case (tile_column)
            1: tile_idx[7:0] <= vram_data;
            2: begin
                tile_idx[8]    <= vram_data[0];
                flip_x         <= vram_data[1];
                line[0]        <= y[0]^vram_data[2];
                line[1]        <= y[1]^vram_data[2];
                line[2]        <= y[2]^vram_data[2];
                palette_latch  <= vram_data[3];
                priority_latch <= vram_data[4];
            end
            4: data0 <= vram_data;
            5: data1 <= vram_data;
            6: data2 <= vram_data;
        endcase

        if (tile_column == 3'd7) begin
            if (flip_x == 1'b0) begin
                shift0 <= data0;
                shift1 <= data1;
                shift2 <= data2;
                shift3 <= vram_data;
            end else begin
                shift0 <= {data0[0], data0[1], data0[2], data0[3], data0[4], data0[5], data0[6], data0[7]};
                shift1 <= {data1[0], data1[1], data1[2], data1[3], data1[4], data1[5], data1[6], data1[7]};
                shift2 <= {data2[0], data2[1], data2[2], data2[3], data2[4], data2[5], data2[6], data2[7]};
                shift3 <= {vram_data[0], vram_data[1], vram_data[2], vram_data[3], vram_data[4], vram_data[5], vram_data[6], vram_data[7]};
            end
            palette <= palette_latch;
            priority_ <= priority_latch;
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
