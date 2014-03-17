# -*- coding: UTF-8 -*-

#-------------------------------------------------------------------------------
# Name:        pyterm.Helpers
# Purpose:     Various helper functions.
#
# Original
# Authors:      Thomas Pani
#
# History:
#   None (at the moment).
#
# Created:     30-August-2006
# Copyright:   (c) 2006 by Thomas Pani
# Licence:     MIT
#-------------------------------------------------------------------------------


import serial


def scan_ports():
    # find available ports
    available = []
    for i in range(256):
        try:
            s = serial.Serial(i)
            available.append(s.portstr)
            s.close()   # explicit close 'cause of delayed GC in java
        except serial.SerialException:
            pass
    return available
