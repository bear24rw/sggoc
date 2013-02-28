#include <stdarg.h>
#include <stdio.h>
#include "print_log.h"

FILE *outfile;

void print_log_init(void) {
    outfile = fopen("/tmp/emu.log", "w");
}

void print_log(char *format, ...) {
    va_list ap1, ap2;

    va_start(ap1, format);
    va_copy(ap2, ap1);

    vprintf(format, ap1);
    vfprintf(outfile, format, ap2);

    va_end(ap1);
    va_end(ap2);

    fflush(outfile);
}
