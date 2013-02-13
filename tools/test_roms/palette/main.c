#include <stdint.h>

__sfr __at (0xBE) vdp_data;
__sfr __at (0xBF) vdp_control;
__sfr __at (0x01) debug;

int main()
{
    uint8_t x = 0;

    while (1) {
        // set register 1 bit 6 to enable display
        vdp_control = 1 << 6;
        vdp_control = 0x80 | 0x01;

        // start at palette entry 0
        vdp_control = 0x00;
        vdp_control = 0xC0;

        // red
        vdp_data = 0x0F;
        vdp_data = 0x00;

        // green
        vdp_data = 0xF0;
        vdp_data = 0x00;

        // blue
        vdp_data = 0x00;
        vdp_data = 0x0F;

        // white
        vdp_data = 0xFF;
        vdp_data = 0x0F;

        // update the debug leds
        debug = x;
        x++;
    }

    return 0;
}
