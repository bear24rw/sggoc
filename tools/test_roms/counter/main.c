#include <stdint.h>
#include <gg.h>

int main()
{
    uint8_t x = 0;

    while (1) {
        x++;
        set_debug(x);
        delay(1000);
    }

    return 0;
}
