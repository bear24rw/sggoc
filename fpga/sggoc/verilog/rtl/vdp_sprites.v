module vdp_sprites (
    input             clk,
    input      [ 8:0] pixel_x,
    input      [ 8:0] pixel_y,
    input      [ 7:0] vram_data,
    output reg [13:0] vram_addr,
    input      [ 5:0] attribute_table,
    input             pattern_table,
    input             shift,
    input             size,
    output reg        overflow,
    output reg [ 5:0] color
);
    // special y value which indicates that no more sprites are active
    `define LAST_SPRITE   8'hD0
    `define HIDDEN_SPRITE 8'hE0

    `define WAIT             0
    `define FIND_ACTIVE      1
    `define FETCH_ACTIVE     2
    `define WAIT_TO_DRAW     7
    `define DRAW             8

    reg [7:0] state = 0;

    reg [7:0] fetch_step = 0;

    reg [5:0] sprite /* verilator public */ = 0;

    reg [3:0] active_total = 0;
    reg [3:0] active_count = 0;
    wire [2:0] active_index = active_count[2:0];

    reg [5:0] active_sprites     [0:7];
    reg [3:0] active_lines       [0:7];
    reg [7:0] active_x_positions [0:7];
    reg [7:0] active_patterns    [0:7];
    reg [7:0] active_bitplanes_0 [0:7];
    reg [7:0] active_bitplanes_1 [0:7];
    reg [7:0] active_bitplanes_2 [0:7];
    reg [7:0] active_bitplanes_3 [0:7];

    always @(posedge clk) begin
        case (state)
            `WAIT: begin
                if (pixel_x == 256) begin
                    sprite <= 0;
                    vram_addr <= {attribute_table, 2'b0, /*sprite*/ 6'd0};
                    active_total <= 0;
                    active_count <= 0;
                    state <= `FIND_ACTIVE;
                end
            end
            `FIND_ACTIVE: begin
                if (pixel_y >= {1'b0, vram_data} && pixel_y < {1'b0, vram_data} + (size ? 16 : 8) && vram_data != `HIDDEN_SPRITE && vram_data != `LAST_SPRITE) begin
                    if (active_total == 8) begin
                        overflow <= 1;
                    end else begin
                        overflow <= 0;
                        active_sprites[active_index] <= sprite;
                        active_lines[active_index] <= pixel_y[3:0] - vram_data[3:0];
                        active_count <= active_count + 1;
                        active_total <= active_total + 1;
                    end
                end
                if (sprite == 63 || active_total == 8 || vram_data == `LAST_SPRITE) begin
                    active_count <= 0;
                    fetch_step <= 0;
                    state <= `FETCH_ACTIVE;
                end else begin
                    sprite <= sprite + 1;
                    vram_addr <= vram_addr + 1;
                end
            end
            `FETCH_ACTIVE: begin
                if (active_count == active_total) begin
                    state <= `WAIT_TO_DRAW;
                end else begin
                    case (fetch_step)
                        0: vram_addr <= {attribute_table, 1'b1, active_sprites[active_index], 1'b0}; // x position
                        1: vram_addr <= {attribute_table, 1'b1, active_sprites[active_index], 1'b1}; // pattern
                        2: begin end
                        3: vram_addr <= {pattern_table, active_patterns[active_index], active_lines[active_index][2:0], 2'd0}; // bitplane 0
                        4: vram_addr <= {pattern_table, active_patterns[active_index], active_lines[active_index][2:0], 2'd1}; // bitplane 1
                        5: vram_addr <= {pattern_table, active_patterns[active_index], active_lines[active_index][2:0], 2'd2}; // bitplane 2
                        6: vram_addr <= {pattern_table, active_patterns[active_index], active_lines[active_index][2:0], 2'd3}; // bitplane 3
                    endcase
                    case (fetch_step)
                        1: active_x_positions[active_index] <= vram_data - (shift ? 8 : 0);
                        2: active_patterns[active_index]    <= size ? {vram_data[7:1], active_lines[active_index][3]} : vram_data;
                        3: begin end
                        4: active_bitplanes_0[active_index] <= vram_data;
                        5: active_bitplanes_1[active_index] <= vram_data;
                        6: active_bitplanes_2[active_index] <= vram_data;
                        7: active_bitplanes_3[active_index] <= vram_data;
                    endcase
                    if (fetch_step == 7) begin
                        fetch_step <= 0;
                        active_count <= active_count + 1;
                    end else begin
                        fetch_step <= fetch_step + 1;
                    end
                end
            end
            `WAIT_TO_DRAW: begin
                if (pixel_x == 0) begin
                    state <= `DRAW;
                end
            end
            `DRAW: begin
                active_x_positions[0] <= active_x_positions[0] - 1;
                active_x_positions[1] <= active_x_positions[1] - 1;
                active_x_positions[2] <= active_x_positions[2] - 1;
                active_x_positions[3] <= active_x_positions[3] - 1;
                active_x_positions[4] <= active_x_positions[4] - 1;
                active_x_positions[5] <= active_x_positions[5] - 1;
                active_x_positions[6] <= active_x_positions[6] - 1;
                active_x_positions[7] <= active_x_positions[7] - 1;

                if (active_total > 0 && active_x_positions[0] < 8) begin
                    color[1] <= active_bitplanes_0[0][active_x_positions[0][2:0]];
                    color[2] <= active_bitplanes_1[0][active_x_positions[0][2:0]];
                    color[3] <= active_bitplanes_2[0][active_x_positions[0][2:0]];
                    color[4] <= active_bitplanes_3[0][active_x_positions[0][2:0]];
                    color[5] <= 1;
                end else if (active_total > 1 && active_x_positions[1] < 8) begin
                    color[1] <= active_bitplanes_0[1][active_x_positions[1][2:0]];
                    color[2] <= active_bitplanes_1[1][active_x_positions[1][2:0]];
                    color[3] <= active_bitplanes_2[1][active_x_positions[1][2:0]];
                    color[4] <= active_bitplanes_3[1][active_x_positions[1][2:0]];
                    color[5] <= 1;
                end else if (active_total > 2 && active_x_positions[2] < 8) begin
                    color[1] <= active_bitplanes_0[2][active_x_positions[2][2:0]];
                    color[2] <= active_bitplanes_1[2][active_x_positions[2][2:0]];
                    color[3] <= active_bitplanes_2[2][active_x_positions[2][2:0]];
                    color[4] <= active_bitplanes_3[2][active_x_positions[2][2:0]];
                    color[5] <= 1;
                end else if (active_total > 3 && active_x_positions[3] < 8) begin
                    color[1] <= active_bitplanes_0[3][active_x_positions[3][2:0]];
                    color[2] <= active_bitplanes_1[3][active_x_positions[3][2:0]];
                    color[3] <= active_bitplanes_2[3][active_x_positions[3][2:0]];
                    color[4] <= active_bitplanes_3[3][active_x_positions[3][2:0]];
                    color[5] <= 1;
                end else if (active_total > 4 && active_x_positions[4] < 8) begin
                    color[1] <= active_bitplanes_0[4][active_x_positions[4][2:0]];
                    color[2] <= active_bitplanes_1[4][active_x_positions[4][2:0]];
                    color[3] <= active_bitplanes_2[4][active_x_positions[4][2:0]];
                    color[4] <= active_bitplanes_3[4][active_x_positions[4][2:0]];
                    color[5] <= 1;
                end else if (active_total > 5 && active_x_positions[5] < 8) begin
                    color[1] <= active_bitplanes_0[5][active_x_positions[5][2:0]];
                    color[2] <= active_bitplanes_1[5][active_x_positions[5][2:0]];
                    color[3] <= active_bitplanes_2[5][active_x_positions[5][2:0]];
                    color[4] <= active_bitplanes_3[5][active_x_positions[5][2:0]];
                    color[5] <= 1;
                end else if (active_total > 6 && active_x_positions[6] < 8) begin
                    color[1] <= active_bitplanes_0[6][active_x_positions[6][2:0]];
                    color[2] <= active_bitplanes_1[6][active_x_positions[6][2:0]];
                    color[3] <= active_bitplanes_2[6][active_x_positions[6][2:0]];
                    color[4] <= active_bitplanes_3[6][active_x_positions[6][2:0]];
                    color[5] <= 1;
                end else if (active_total > 7 && active_x_positions[7] < 8) begin
                    color[1] <= active_bitplanes_0[7][active_x_positions[7][2:0]];
                    color[2] <= active_bitplanes_1[7][active_x_positions[7][2:0]];
                    color[3] <= active_bitplanes_2[7][active_x_positions[7][2:0]];
                    color[4] <= active_bitplanes_3[7][active_x_positions[7][2:0]];
                    color[5] <= 1;
                end else begin
                    color <= 0;
                end

                if (pixel_x == 255) begin
                    state <= `WAIT;
                end
            end
        endcase
    end

endmodule
