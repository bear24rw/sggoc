#include <stdint.h>

__sfr __at (0x01) debug;

int main()
{
    uint8_t x = 0;

    while (1) {
        debug = x;
        x++;
    }

    return 0;
}
