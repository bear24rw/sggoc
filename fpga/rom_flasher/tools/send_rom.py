import os
import sys
import serial

s = serial.Serial('/dev/ttyS0', 9600)

rom_file = sys.argv[1]
rom_size = os.path.getsize(rom_file)

print "Rom size: %d" % rom_size

rom = open(sys.argv[1], 'rb')

bytes_sent = 0
last_byte_sent = 0

print "Waiting for FPGA to request bytes..."

for byte in rom.read():

    # wait for fpga to tell us to send
    recv = s.read()

    # send next byte
    s.write(byte)

    bytes_sent += 1

    # we should receive back the last byte we sent as an ACK
    if (recv != last_byte_sent):
        error = "RECIEVED BYTE DOES NOT MATCH!"
    else:
        error = ""

    print "Sent %d of %d bytes (sent: %2X | recv: %2X) %s    \r" % \
            (bytes_sent, rom_size, ord(byte), ord(recv), error)

    last_byte_sent = byte
