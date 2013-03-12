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

void set_tile_to_pattern(uint16_t tile, uint16_t pattern)
{
    vdp_set_vram_addr(NT_ADDR + 2*tile);
    vdp_data = pattern;
    vdp_data = 0;
}

void delay(uint16_t x)
{
    uint16_t i;
    for (i=0; i<1000*x; i++);
}

int main()
{
    uint8_t x = 0;
    uint16_t i;
    uint16_t tile = 0;
    uint16_t ptrn = 0;
    uint16_t color = 0;

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

    // set all 512 patterns to solid colors
    for (i=0; i<512; i++) {
        set_pattern_fill(i, color);
        if (color == 8) {
            color = 0;
        } else {
            color++;
        }

    }

    // loop through each tile and set it to every pattern
    for (tile=0; tile<32*28; tile++) {
        set_tile_to_pattern(tile, 2);
    }

    while (1) {
        // update the debug leds
        debug = x;
        x++;
    }

    return 0;
}
