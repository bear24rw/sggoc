as-z80 -gols crt0.o crt0.s && \
sdcc -V -c -mz80 --no-std-crt0 --stack-auto main.c -o main.o && \
sdcc -V -mz80 --no-peep --no-std-crt0 --stack-auto crt0.o main.o && \
mv crt0.ihx main.ihx && \
hex2bin -p 00 main.ihx && \
mv main.bin main.gg && \
hexdump -v -e '1/1 "%02X\n"' main.gg > main.gg.linear
