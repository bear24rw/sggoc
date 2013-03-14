#include <stdint.h>
#include "gg.h"

__sfr __at (0xBE) vdp_data;
__sfr __at (0xBF) vdp_control;
__sfr __at (0x01) debug;

void vdp_write_control(uint8_t value) { vdp_control = value; }
void vdp_write_data(uint8_t value) { vdp_data = value; }

void vdp_set_register(uint8_t reg, uint8_t value)
{
    vdp_control = value;
    vdp_control = CODE_2 | reg;
}

void vdp_set_vram_addr(uint16_t addr)
{
    vdp_control = addr;
    vdp_control = CODE_1 | (addr >> 8);
}

void vdp_set_palette(uint8_t id, uint16_t color)
{
    vdp_control = id << 1;  // each palette entry is two bytes
    vdp_control = CODE_3;

    vdp_data = color;
    vdp_data = color >> 8;
}

void set_pattern_fill(uint16_t id, uint8_t color)
{
    uint8_t i;

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

void set_tile_to_pattern(uint8_t x, uint8_t y, uint16_t pattern)
{
    vdp_set_vram_addr(NT_ADDR + 2*(y*32+x));
    vdp_data = pattern;
    vdp_data = 0;
}

void delay(uint16_t x)
{
    uint16_t i = 0;
    for (i=0; i<x; i++) {}
}

void set_debug(uint8_t x) { debug = x; }
