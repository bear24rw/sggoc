sdcc -mz80 main.c && hex2bin -p 00 main.ihx && mv main.bin main.gg && hexdump -v -e '1/1 "%02X\n"' main.gg > main.gg.linear
