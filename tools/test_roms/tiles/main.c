#include <stdint.h>

__sfr __at (0xBE) vdp_data;
__sfr __at (0xBF) vdp_control;
__sfr __at (0x01) debug;

#define NT_ADDR     0x3800

void vdp_set_vram_addr(uint16_t addr)
{
    vdp_control = addr;
    vdp_control = (addr >> 8) | 0x40;
}

void set_pattern_fill(int id, int color)
{
    int i;

    // set address to pattern id
    // each pattern is 32 bytes
    vdp_set_vram_addr(id*32);

    // loop over 8 lines
    for (i=0; i<8; i++) {
        vdp_data = ((color >> 0) & 0x01) ? 0xFF : 0x00;
        vdp_data = ((color >> 1) & 0x01) ? 0xFF : 0x00;
        vdp_data = ((color >> 2) & 0x01) ? 0xFF : 0x00;
        vdp_data = ((color >> 3) & 0x01) ? 0xFF : 0x00;
    }

}

int main()
{
    uint8_t x = 0;
    int i;

    // set register 1 bit 6 to enable display
    vdp_control = 1 << 6;
    vdp_control = 0x80 | 0x01;

    // start at palette entry 0
    vdp_control = 0x00;
    vdp_control = 0xC0;

    // MSB              LSB
    // --------BBBBGGGGRRRR

    // gray
    vdp_data = 0xCC;
    vdp_data = 0x0C;

    // red
    vdp_data = 0x0F;
    vdp_data = 0x00;

    // green
    vdp_data = 0xF0;
    vdp_data = 0x00;

    // blue
    vdp_data = 0x00;
    vdp_data = 0x05;

    // yellow
    vdp_data = 0xFF;
    vdp_data = 0x00;

    // purple
    vdp_data = 0x0F;
    vdp_data = 0x0F;

    // teal
    vdp_data = 0xF0;
    vdp_data = 0x0F;

    // black
    vdp_data = 0x00;
    vdp_data = 0x00;

    // white
    vdp_data = 0xFF;
    vdp_data = 0x0F;

    // set address to name table
    // gg cuts off first 24 lines
    // (24 lines) / (8 lines / tile) * (32 tiles / line) * (2 bytes / tile) = 192 bytes
    // drawing starts at 7th tile?? (6 tiles) * (2 bytes / tile) = 12 bytes
    vdp_set_vram_addr(NT_ADDR + 192 + 12);

    // set the first 8 tiles to the first 8 patterns
    for (i=0; i<8; i++) {
        vdp_data = i;
        vdp_data = 0;
    }

    // set the first pattern to a grid
    // color is palette 1
    vdp_set_vram_addr(0);
    for (i=0; i<4; i++) {
        vdp_data = ((1 >> 0) & 0x01) ? 0xAA : 0x00;
        vdp_data = ((1 >> 1) & 0x01) ? 0xAA : 0x00;
        vdp_data = ((1 >> 2) & 0x01) ? 0xAA : 0x00;
        vdp_data = ((1 >> 3) & 0x01) ? 0xAA : 0x00;

        vdp_data = ((1 >> 0) & 0x01) ? 0x55 : 0x00;
        vdp_data = ((1 >> 1) & 0x01) ? 0x55 : 0x00;
        vdp_data = ((1 >> 2) & 0x01) ? 0x55 : 0x00;
        vdp_data = ((1 >> 3) & 0x01) ? 0x55 : 0x00;
    }

    // set the first 8 patterns to solid color
    for (i=0; i<8; i++) {
        set_pattern_fill(i+1, i+1);
    }


    while (1) {
        // update the debug leds
        debug = x;
        x++;
    }

    return 0;
}
