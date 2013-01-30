sdcc -mz80 --no-std-crt0 --code-loc 16384 main.c && hex2bin -p 00 main.ihx && mv main.bin main.gg
