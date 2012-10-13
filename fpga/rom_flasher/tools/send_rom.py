import os
import sys
import serial

s = serial.Serial('/dev/ttyS0', 9600)

rom_file = sys.argv[1]
rom_size = os.path.getsize(rom_file)

print "Rom size: %d" % rom_size

rom = open(sys.argv[1], 'rb')

bytes_sent = 0
percent_sent = 0.0
last_byte_sent = chr(0)

print "Waiting for FPGA to request bytes..."

for byte in rom.read():

    # wait for fpga to tell us to send
    recv = s.read()

    # send next byte
    s.write(byte)

    bytes_sent += 1
    percent_sent = float(bytes_sent)/float(rom_size)*100.0

    # we should receive back the last byte we sent as an ACK
    if (recv != last_byte_sent):
        print "RECIEVED BYTE DOES NOT MATCH!"
        print "Recv: %2X | Last Sent: %2X" % (ord(recv), ord(last_byte_sent))
        sys.exit()

    print "[%.2f] %d / %d (sent: %2X | recv: %2X)" % \
            (percent_sent, bytes_sent, rom_size, ord(byte), ord(recv) )

    last_byte_sent = byte
