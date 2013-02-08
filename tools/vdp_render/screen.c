#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
    
/* A coloured pixel. */
typedef struct {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
} pixel_t;

/* A picture. */
typedef struct  {
    pixel_t *pixels;
    size_t width;
    size_t height;
} bitmap_t;
    
/* Given "bitmap", this returns the pixel of bitmap at the point 
   ("x", "y"). */
static pixel_t * pixel_at (bitmap_t * bitmap, int x, int y)
{
    return bitmap->pixels + bitmap->width * y + x;
}
    
/* Write "bitmap" to a PNG file specified by "path"; returns 0 on
   success, non-zero on error. */
static int save_png_to_file (bitmap_t *bitmap, const char *path)
{
    FILE * fp;
    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
    size_t x, y;
    png_byte ** row_pointers = NULL;
    /* "status" contains the return value of this function. At first
       it is set to a value which means 'failure'. When the routine
       has finished its work, it is set to a value which means
       'success'. */
    int status = -1;
    /* The following number is set by trial and error only. I cannot
       see where it it is documented in the libpng manual.
    */
    int pixel_size = 3;
    int depth = 8;
    
    fp = fopen (path, "wb");
    if (! fp) {
        goto fopen_failed;
    }

    png_ptr = png_create_write_struct (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == NULL) {
        goto png_create_write_struct_failed;
    }
    
    info_ptr = png_create_info_struct (png_ptr);
    if (info_ptr == NULL) {
        goto png_create_info_struct_failed;
    }
    
    /* Set up error handling. */

    if (setjmp (png_jmpbuf (png_ptr))) {
        goto png_failure;
    }
    
    /* Set image attributes. */
    png_set_IHDR (png_ptr,
                  info_ptr,
                  bitmap->width,
                  bitmap->height,
                  depth,
                  PNG_COLOR_TYPE_RGB,
                  PNG_INTERLACE_NONE,
                  PNG_COMPRESSION_TYPE_DEFAULT,
                  PNG_FILTER_TYPE_DEFAULT);
    
    /* Initialize rows of PNG. */
    row_pointers = png_malloc (png_ptr, bitmap->height * sizeof (png_byte *));
    for (y = 0; y < bitmap->height; ++y) {
        png_byte *row = 
            png_malloc (png_ptr, sizeof (uint8_t) * bitmap->width * pixel_size);
        row_pointers[y] = row;
        for (x = 0; x < bitmap->width; ++x) {
            pixel_t * pixel = pixel_at (bitmap, x, y);
            *row++ = pixel->red;
            *row++ = pixel->green;
            *row++ = pixel->blue;
        }
    }
    
    /* Write the image data to "fp". */
    png_init_io (png_ptr, fp);
    png_set_rows (png_ptr, info_ptr, row_pointers);
    png_write_png (png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);

    /* The routine has successfully written the file, so we set
       "status" to a value which indicates success. */

    status = 0;
    
    for (y = 0; y < bitmap->height; y++) {
        png_free (png_ptr, row_pointers[y]);
    }
    png_free (png_ptr, row_pointers);
    
 png_failure:
 png_create_info_struct_failed:
    png_destroy_write_struct (&png_ptr, &info_ptr);
 png_create_write_struct_failed:
    fclose (fp);
 fopen_failed:
    return status;
}


int main (int argc, char* argv[])
{
    bitmap_t screen;

    screen.width = 256;
    screen.height = 256;
    screen.pixels = calloc(sizeof(pixel_t), screen.width * screen.height);

    // clear image
    for (int x = 0; x < screen.width; x++) {
        for (int y = 0; y < screen.height; y++) {
            pixel_t *pixel = pixel_at(&screen, x, y);
            pixel->red   = 0xCC;
            pixel->green = 0xCC;
            pixel->blue  = 0xCC;
        }
    }

    uint8_t VRAM[0x4000];
    uint8_t CRAM[64];

    FILE *f;

    f = fopen(argv[1], "rb");

    if (f) {
        fread(VRAM, sizeof(uint8_t), 0x4000, f);
    } else {
        printf("Error opening VRAM file");
        return 1;
    }
    fclose(f);

    f = fopen(argv[2], "rb");

    if (f) {
        fread(CRAM, sizeof(uint8_t), 64, f);
    } else {
        printf("Error opening CRAM file");
        return 1;
    }
    fclose(f);

    int col = 0;
    int row = 0;
    int x = 0;
    int y = 0;

    printf("VRAM: %ld\n", sizeof(VRAM));
    printf("CRAM: %ld\n", sizeof(CRAM));

    for (row = 0; row < 28; row++) {
        for (col = 0; col < 32; col++) {
            printf("Drawing tile: %d,%d\n", col, row);

            // default name table base address
            int name_table_idx = 0x3800;
            int pattern_idx = 0;

            // each entry is 2 bytes
            // table is 32 entries wide
            name_table_idx += (col * 2) + (row * 32 * 2);
            printf("NT idx: 0x%X\n", name_table_idx);

            pattern_idx = VRAM[name_table_idx] | ((VRAM[name_table_idx+1] & 1) << 8);
            printf("Pattern idx: 0x%X\n", pattern_idx);

            // each pattern is 32 bytes long
            int pattern_addr = (pattern_idx*32);
            printf("Pattern addr: 0x%X\n", pattern_addr);

            printf("Line bitplanes: %X %X %X %X\n",
                    VRAM[pattern_addr + 0],
                    VRAM[pattern_addr + 1],
                    VRAM[pattern_addr + 2],
                    VRAM[pattern_addr + 3]
                  );

            for (y = 0; y < 8; y++) {
                for (x = 0; x < 8; x++) {
                    uint8_t color = 0;
                    color |= (VRAM[pattern_addr + y*4 + 0] & (0b10000000 >> x)) ? (1 << 0) : 0;
                    color |= (VRAM[pattern_addr + y*4 + 1] & (0b10000000 >> x)) ? (1 << 1) : 0;
                    color |= (VRAM[pattern_addr + y*4 + 2] & (0b10000000 >> x)) ? (1 << 2) : 0;
                    color |= (VRAM[pattern_addr + y*4 + 3] & (0b10000000 >> x)) ? (1 << 3) : 0;
    
                    pixel_t *pixel = pixel_at(&screen, col*8+x, row*8+y);
                    pixel->red   = 16 *  (CRAM[color*2] & 0b00001111);
                    pixel->green = 16 * ((CRAM[color*2] >> 4) & 0b00001111);
                    pixel->blue  = 16 *  (CRAM[color*2+1] & 0b00001111);
                }
            }
            printf("\n");
        }
    }

    save_png_to_file (&screen, "screen.png");

    return 0;
}
