import os
import sys
import serial

s = serial.Serial('/dev/ttyS0', 115200)

rom_file = sys.argv[1]
rom_size = os.path.getsize(rom_file)

print "Rom size: %d" % rom_size

rom = open(sys.argv[1], 'rb')

bytes_read = 0
percent_read = 0.0

print "Waiting for FPGA to send bytes..."

for byte in rom.read():

    # wait for fpga to send us next byte
    recv = s.read()

    bytes_read += 1
    percent_read = float(bytes_read)/float(rom_size)*100.0

    # make sure the byte from the fpga matches the byte in the file
    if (recv != byte):
        print "RECIEVED BYTE DOES NOT MATCH!"
        print "Recv: %2X | Byte: %2X" % (ord(recv), ord(byte))
        sys.exit()

    print "[%.2f] %d / %d (read: %2X | recv: %2X)" % \
            (percent_read, bytes_read, rom_size, ord(byte), ord(recv) )

