#ifndef _GG_
#define _GG_

#define NT_ADDR     0x3800

#define CODE_0  0b00000000  // read vram
#define CODE_1  0b01000000  // write vram
#define CODE_2  0b10000000  // register write
#define CODE_3  0b11000000  // cram write

void vdp_write_control(uint8_t value);
void vdp_write_data(uint8_t value);
void vdp_set_register(uint8_t reg, uint8_t value);
void vdp_set_vram_addr(uint16_t addr);
void vdp_set_palette(uint8_t id, uint16_t color);
void set_pattern_fill(uint16_t id, uint8_t color);
void set_tile_to_pattern(uint8_t x, uint8_t y, uint16_t pattern);
void delay(uint16_t x);
void set_debug(uint8_t x);

#endif
