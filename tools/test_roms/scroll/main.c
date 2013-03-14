#include <stdint.h>
#include <gg.h>

int main()
{
    uint8_t x = 0;
    uint8_t y = 0;
    uint16_t i;
    uint16_t ptrn = 0;
    uint16_t color = 0;

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

    // set all 9 patterns to solid colors
    for (i=0; i<9; i++) {
        set_pattern_fill(i, i);
    }

    // osmose only draws 20x18 tiles starting at 6x3

    // draw a border
    for (y=0; y<18; y++) set_tile_to_pattern(6    , 3+y  , 1);  // left
    for (y=0; y<18; y++) set_tile_to_pattern(6+19 , 3+y  , 2);  // right
    for (x=0; x<20; x++) set_tile_to_pattern(6+x  , 3    , 3);  // top
    for (x=0; x<20; x++) set_tile_to_pattern(6+x  , 3+17 , 4);  // bottom

    // scroll all the way right then back again
    delay(5000); for (x=0; x<255; x++) {delay(3000); vdp_set_register(8, x); }
    delay(5000); for (x=0; x<255; x++) {delay(3000); vdp_set_register(8, 255-x); }


    // scroll all the way up then back again
    delay(5000); for (y=0; y<255; y++) {delay(3000); vdp_set_register(9, y); }
    delay(5000); for (y=0; y<255; y++) {delay(3000); vdp_set_register(9, 255-y); }

    // update the debug leds
    while (1) {
        x++;
        set_debug(x);
        delay(1000);
    }

    return 0;
}
