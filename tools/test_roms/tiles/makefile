CC=sdcc -V -mz80 -I..

all: main.gg.linear

crt0.rel: ../crt0.s
	sdasz80 -l -o crt0.rel ../crt0.s

main.rel: main.c
	$(CC) -c main.c

gg.rel: ../gg.c ../gg.h
	$(CC) -c ../gg.c

main.ihx: main.rel gg.rel crt0.rel
	$(CC) --no-peep --no-std-crt0 -o main.ihx crt0.rel gg.rel main.rel

main.bin: main.ihx
	hex2bin -p 00 main.ihx

main.gg: main.bin
	mv main.bin main.gg

main.gg.linear: main.gg
	hexdump -v -e '1/1 "%02X\n"' main.gg > main.gg.linear

clean:
	rm -f *.asm *.ihx *.lk *.lst *.map *.rel *.sym *.gg* *.noi

