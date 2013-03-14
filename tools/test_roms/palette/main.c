#include <stdint.h>
#include <gg.h>

int main()
{
    uint8_t x = 0;

    while (1) {
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

        // update the debug leds
        set_debug(x);
        x++;
    }

    return 0;
}
