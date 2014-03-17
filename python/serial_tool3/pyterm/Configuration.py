# -*- coding: UTF-8 -*-

#-------------------------------------------------------------------------------
# Name:        pyterm.Configuration
# Purpose:     Handle configuration related tasks.
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


import os
import cPickle as pickle
import ConfigParser

import serial
import wx

from pyterm.Helpers import scan_ports


class Configuration:
    def __init__(self):
        # adjust some paths
        sp = wx.StandardPaths.Get()
        wx.GetApp().SetAppName('pyTerm')
        self.config_path = sp.GetUserConfigDir()
        self.config_file = os.path.join(self.config_path, '.pyTerm')
        # create the config parser
        self.config_parser = ConfigParser.ConfigParser()
        self.config_parser.read((self.config_file))
        
        # hardcoded default settings
        available = scan_ports()
        if available:
            self.serial__port = available[0]
        else:
            self.serial__port = ''
        self.serial__speed = 9600
        self.serial__parity = None
        self.serial__bits = 8
        self.serial__stopbits = 1
        self.serial__flow_control = None
        
        self.local_echo = False
        
        # create objects out of config
        self.read_config()
        
    def read_option(self, section, option):
            if self.config_parser.has_option(section, option):
                exec('''self.%s__%s = self.config_parser.get('%s', '%s')''' \
                     % (section, option, section, option))
            
    def read_option_int(self, section, option):
            if self.config_parser.has_option(section, option):
                exec('''self.%s__%s = int(self.config_parser.get('%s', '%s'))''' \
                     % (section, option, section, option))
            
    def read_config(self):
        
        # if the config file exists, read it
        if os.path.exists(self.config_file):
            if self.config_parser.has_section('serial'):
                self.read_option('serial', 'port')
                self.read_option_int('serial', 'speed')
                self.read_option('serial', 'parity')
                self.read_option_int('serial', 'bits')
                self.read_option_int('serial', 'stopbits')
                self.read_option('serial', 'flow_control')
           
            if self.config_parser.has_section('general'):
                if self.config_parser.has_option('general', 'local_echo'):
                    self.local_echo = self.config_parser.getboolean('general', 'local_echo')
        
        # create the configuration object
        self.port_configuration = PortConfiguration(self.serial__port,
                                                    self.serial__speed,
                                                    self.serial__parity,
                                                    self.serial__bits,
                                                    self.serial__stopbits,
                                                    self.serial__flow_control)
    
    def write_config(self):
        # create configuration file of not existing
        if not os.path.exists(self.config_file):
            f = open(self.config_file, 'w')
            f.close()
        
        # create serial section if not existing
        if not self.config_parser.has_section('serial'):
            self.config_parser.add_section('serial')
        if not self.config_parser.has_section('general'):
            self.config_parser.add_section('general')

        # write all the options
        self.config_parser.set('serial', 'port',
                               self.port_configuration.port)
        self.config_parser.set('serial', 'speed',
                               self.port_configuration.speed)
        self.config_parser.set('serial', 'parity',
                               self.port_configuration.parity_s)
        self.config_parser.set('serial', 'bits',
                               self.port_configuration.bits)
        self.config_parser.set('serial', 'stopbits',
                               self.port_configuration.stopbits)
        self.config_parser.set('serial', 'flow_control',
                               self.port_configuration.flow_control_s)
        
        self.config_parser.set('general', 'local_echo',
                               str(self.local_echo))
        
        self.config_parser.write(open(self.config_file, 'w'))
        
        
class PortConfiguration:
    def __init__(self, port, speed, parity, bits, stopbits, flow_control):
        self.port = port
        self.speed = speed
        self.bits = bits
        self.stopbits = stopbits
        
        
        parity = str(parity).lower()
        if parity == 'none':
            self.parity = serial.PARITY_NONE
        elif parity == 'even':
            self.parity = serial.PARITY_EVEN
        elif parity == 'odd':
            self.parity = serial.PARITY_ODD
        else:
            raise ValueError('Invalid parity %s' % repr(parity))
        self.parity_s = parity
        
        if flow_control == None or flow_control == 'none':
            self.rtscts = False
            self.xonxoff = False
            flow_control = 'none'
        elif flow_control == 'RTS/CTS':
            self.rtscts = True
            self.xonxoff = False
        elif flow_control == 'Xon/Xoff':
            self.rtscts = None
            self.xonxoff = False
        else:
            raise ValueError('Invalid flow control %s' % repr(flow_control))
        self.flow_control_s = flow_control

    def __str__(self):
        return self.GetString()
    
    def GetString(self):
        return '%s: %d,%d,%s,%d' % \
            (self.port, self.speed, self.bits, self.parity, self.stopbits)
