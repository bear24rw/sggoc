#include <stdint.h>

__sfr __at (0xBE) vdp_data;
__sfr __at (0xBF) vdp_control;

int main()
{
    int x;

    while (1) {
        // set register 1 bit 6 to enable display
        vdp_control = 1 << 6;
        vdp_control = 0x80 | 0x01;

        // set first palette entry to 3
        vdp_control = 0x00;
        vdp_control = 0xC0;
        vdp_data = 0x03;
    }

    return 0;
}
