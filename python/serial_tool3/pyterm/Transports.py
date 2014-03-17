# -*- coding: UTF-8 -*-

#-------------------------------------------------------------------------------
# Name:        pyterm.Transports
# Purpose:     Receiver and transmitter transports for the Terminal Widget.
#
# Original
# Authors:      Thomas Pani
#
# History:
#   None (at the moment).
#
# Created:     29-August-2006
# Copyright:   (c) 2006 by Thomas Pani
# Licence:     MIT
#-------------------------------------------------------------------------------


import Queue
import time
import threading
import select

import serial


class Transport:
    def __init__(self, receive_callback):
        self.alive = True
        self.receive_callback = receive_callback
        self.transmit_queue = Queue.Queue()
        
        # start media->terminal thread
        self.receiver_thread = threading.Thread(target=self.receiver, name='Receiver')
        self.receiver_thread.setDaemon(1)
        self.receiver_thread.start()
        # start terminal->media thread
        self.transmitter_thread = threading.Thread(target=self.transmitter, name='Transmitter')
        self.transmitter_thread.setDaemon(1)
        self.transmitter_thread.start()
        
    def stop(self):
        self.alive = False
        
    def transmit(self, char):
        self.transmit_queue.put(char)
        
    def _received(self, char):
        self.receive_callback(char)
    
    def receiver(self):
        pass
    
    def transmitter(self):
        pass
    
class LocalEchoTransport(Transport):
    def __init__(self, receive_callback):
        self.tr_shortcut = Queue.Queue()
        Transport.__init__(self, receive_callback)
    
    def receiver(self):
        while self.alive:
            char = self.tr_shortcut.get()
            self._received(char)
            
    def transmitter(self):
        while self.alive:
            char = self.transmit_queue.get()
            self.tr_shortcut.put(char)

class SerialTransport(Transport):
    def __init__(self, receive_callback, port_configuration):
        self.serial = serial.Serial(port_configuration.port,
                                    port_configuration.speed,
                                    port_configuration.bits,
                                    port_configuration.parity,
                                    port_configuration.stopbits,
                                    None,        # timeout
                                    port_configuration.rtscts,
                                    port_configuration.xonxoff
                                    )
        Transport.__init__(self, receive_callback)
    
    def receiver(self):
        while self.alive:
            try:
                char = self.serial.read(1)
                if char:
                    self._received(char)
            except select.error:
                pass
            
    def transmitter(self):
        while self.alive:
            char = self.transmit_queue.get()
            self.serial.write(char)

