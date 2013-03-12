sdcc -mz80 --data-loc 0xC000 --stack-loc 0xDFFF --code-size 0xC000 main.c && hex2bin -p 00 main.ihx && mv main.bin main.gg && hexdump -v -e '1/1 "%02X\n"' main.gg > main.gg.linear
