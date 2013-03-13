#include <stdint.h>
#include <gg.h>


int main()
{
    uint8_t x = 0;
    int i;

    // set register 1 bit 6 to enable display
    vdp_set_register(1, (1<<6));

    // set color palette (0x0BGR)
    vdp_set_palette(0, 0x0CCC);     // gray
    vdp_set_palette(1, 0x000F);     // red
    vdp_set_palette(2, 0x00F0);     // green
    vdp_set_palette(3, 0x0F00);     // blue
    vdp_set_palette(4, 0x00FF);     // yellow
    vdp_set_palette(5, 0x0F0F);     // purple
    vdp_set_palette(6, 0x0FF0);     // teal
    vdp_set_palette(7, 0x0000);     // black
    vdp_set_palette(8, 0x0FFF);     // white

    // set the first pattern to a grid
    // color is palette 1
    vdp_set_vram_addr(0);
    for (i=0; i<4; i++) {
        vdp_write_data(0xAA);
        vdp_write_data(0x00);
        vdp_write_data(0x00);
        vdp_write_data(0x00);

        vdp_write_data(0x55);
        vdp_write_data(0x00);
        vdp_write_data(0x00);
        vdp_write_data(0x00);
    }

    // set the next 9 patterns to solid color
    for (i=0; i<9; i++) {
        set_pattern_fill(i+1, i);
    }

    // osmose only draws 20x18 tiles starting at 6x3
    // set first 10 tiles to first 10 patterns
    for (i=0; i<10; i++) {
        set_tile_to_pattern(6+i, 3, i);
    }


    while (1) {
        // update the debug leds
        set_debug(x);
        x++;
    }

    return 0;
}
