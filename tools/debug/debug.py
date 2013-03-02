import os
import sys
import serial

s = serial.Serial('/dev/ttyS0', 115200)

while True:

    # wait for fpga to send us next byte
    high = s.read()
    low = s.read()

    print "%02X%02X" % (ord(high), ord(low))
