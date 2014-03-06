# -*- coding: UTF-8 -*-

#-------------------------------------------------------------------------------
# Name:        pyterm.Terminal
# Purpose:     A Terminal Emulation Widget.
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


import threading

import wx

# from Transports import LocalEchoTransport, SerialTransport


class Terminal(wx.Panel):
    def __init__(self, *args, **kwds):
        wx.Panel.__init__(self, *args, **kwds)
        self.SetDoubleBuffered(True)

        self.min_dimensions = (20, 6)
        self.dimensions = (80, 24)
        self.isDrawing = False
        self.log = ''
        self.transports = []

        self.__init_coords()
        self.__init_fonts()
        self.__init_char_dimensions()
        self.__init_colors()
        self.lines = ['']

        self.__set_properties()
        
        # self.local_echo_tr = LocalEchoTransport(self.InsertChar)
            
        self.Bind(wx.EVT_CHAR, self.OnChar)
        self.Bind(wx.EVT_PAINT, self.OnPaint)
        self.Bind(wx.EVT_SIZE, self.OnSize)
        self.Bind(wx.EVT_WINDOW_DESTROY, self.OnDestroy)

        self.turn = 1
        self.timer = wx.Timer(self, 1)
        self.Bind(wx.EVT_TIMER, self.OnTimer, self.timer)
        self.timer.Start(700)
        self.paint_for_sursor = False

        # for test
        self.test_timer = wx.Timer(self, 1)
        self.Bind(wx.EVT_TIMER, self.OnTestTimer, self.test_timer)
        self.timer.Start(1)
        self.cmd_list = open("Terminal.py", 'r').read().split('\n')

    def OnTestTimer(self, event):
        if len(self.cmd_list) > 0:
            cmd = self.cmd_list[0]
            self.cmd_list = self.cmd_list[1:]
            for ch in cmd:
                self.InsertChar(ch)
            self.InsertChar('\n')

    def OnTimer(self, event):
        self.turn = (self.turn + 1) % 2
        self.paint_for_sursor = True
        self.Refresh()


    def __set_properties(self):
        self.SetMinSize((self.dimensions[0] * self.fw,
                         self.dimensions[1] * self.fh))

    def __init_coords(self):
        self.cx = 0      # carret x  (pos)
        self.cy = 0      # carret y  (pos)

    def __init_fonts(self):
        '''Set a nice font, font's width and font's height.'''
        
        if wx.Platform == "__WXMSW__":
            self.font = wx.Font(12, wx.MODERN, wx.NORMAL, wx.BOLD)
        else:
            self.font = wx.Font(12, wx.MODERN, wx.NORMAL, wx.BOLD, False)
        if wx.Platform == "__WXMAC__":
            self.font.SetNoAntiAliasing()
        
        dc = wx.ClientDC(self)
        dc.SetFont(self.font)
        self.fw = dc.GetCharWidth()             # font width  (px)
        self.fh = dc.GetCharHeight()            # font height (px)

    def __init_char_dimensions(self):
        '''Set bw, bh, sh, sw.'''

        self.bw, self.bh = self.GetClientSize()    # body width/height (px)

        self.sh = self.bh / self.fh          # screen height (pos)
        self.sw = (self.bw / self.fw) - 1    # screen height (pos)
        
    def __init_colors(self):
        self.fgColor = wx.NamedColour('WHITE')
        self.bgColor = wx.NamedColour('BLACK')

    def OnPaint(self, event):
        '''Paint event handler.'''
        
        dc = wx.PaintDC(self)
        if self.isDrawing:
            return

        if self.paint_for_sursor == True:
            print("Aa")
            self.paint_for_sursor = False
            self.UpdateCursor(dc)
            return

        self.isDrawing = True
        self.UpdateView(dc)
        self.isDrawing = False

    def UpdateCursor(self, dc=None):
        if dc is None:
            dc = wx.ClientDC(self)
        if dc.Ok():
            self.KeepCursorOnScreen()
            self.FlashingCursor(dc)

    def UpdateView(self, dc=None):
        '''Keep cursor on screen and draw the entire widget.'''
        
        if dc is None:
            dc = wx.ClientDC(self)
        if dc.Ok():
            self.KeepCursorOnScreen()
            self.Draw(dc)

    def KeepCursorOnScreen(self):
        '''Do a line break or scroll if the cursor would get off the screen.'''
        
        if self.cx > self.sw:
            self.BreakLine()
        if self.cy > self.sh - 1:
            self.log = self.log + self.lines[0]
            del self.lines[0]
            self.cVert(-1)
            
            
    def BreakLine(self):
        '''Do a line break.'''
        
        if self.IsLine(self.cy):
            t = self.lines[self.cy]
            self.lines = self.lines[:self.cy] + [t[:self.cx],t[self.cx:]] + self.lines[self.cy+1:]
            self.cVert(1)
            
    def Draw(self, odc):
        '''Draw background, lines and cursor.'''
        
        bmp = wx.EmptyBitmap(max(1, self.bw), max(1, self.bh))
        dc = wx.BufferedDC(odc, bmp)
        if dc.Ok():
            dc.SetFont(self.font)
            dc.SetBackgroundMode(wx.SOLID)
            dc.SetTextBackground(self.bgColor)
            dc.SetTextForeground(self.fgColor)
            dc.SetBrush(wx.Brush(self.bgColor))
            dc.Clear()
            dc.DrawRectangle(0, 0, self.bw, self.bh)
            for line in range(0, self.sh):
                self.DrawLine(line, dc)
            self.DrawCursor(dc)

    def FlashingCursor(self, odc):
        bmp = wx.EmptyBitmap(max(1, self.bw), max(1, self.bh))
        dc = wx.BufferedDC(odc, bmp)
        if dc.Ok():
            dc.SetFont(self.font)
            dc.SetBackgroundMode(wx.SOLID)
            dc.SetTextBackground(self.bgColor)
            dc.SetTextForeground(self.fgColor)
            dc.SetBrush(wx.Brush(self.bgColor))
            dc.Clear()
            dc.DrawRectangle(0, 0, self.bw, self.bh)
            for line in range(0, self.sh):
                self.DrawLine(line, dc)
            if self.turn == 1:
                self.DrawCursor(dc)

    def DrawLine(self, line, dc):
        '''Draw a single line.'''
        
        if self.IsLine(line):
            l = line
            t = self.lines[l]
            dc.SetTextForeground(self.fgColor)
            dc.SetTextBackground(self.bgColor)
            try:
                dc.DrawText(t, 0, (line) * self.fh)
            except UnicodeDecodeError:
                pass

    def DrawCursor(self, dc):
        '''Draw the cursor.'''
        
        if len(self.lines) < self.cy:
            self.cy = len(self.lines)-1

        x = self.cx * self.fw    # get some real
        y = self.cy * self.fh    # pixel coordinates
        dc.SetBrush(wx.Brush(self.fgColor))
        dc.SetPen(wx.Pen(self.fgColor))
        dc.DrawRectangle(x, y, 1, self.fh)
            
    def cVert(self, num):
        '''Move the carret vertical about num positions
        and set horizontal position.'''
        
        self.cy = self.cy + num
        self.cx = min(self.cx, len(self.lines[self.cy]))

    def cHoriz(self, num):
        '''Move the carret horizontal about num positions.'''
        
        self.cx = self.cx + num

    def IsLine(self, lineNum):
        '''Tell whether lineNum is a valid line.'''
        
        return (0 <= lineNum) and (lineNum < len(self.lines))
    
    def OnChar(self, event):
        '''EVT_CHAR event handler.'''
        
        key = event.KeyCode
        self.NormalChar(key, event)
        return 0
    
    def NormalChar(self, key, event):
        '''If key is a ASCII keycode ]31;256[ or RETURN insert the character;
        otherwise bell.'''
        
        if key == wx.WXK_RETURN or \
           key == wx.WXK_TAB or \
           key > 31 and key < 256:
            # self.TransportsTransmit(chr(key))
            self.InsertChar(chr(key))
        else:
            wx.Bell()
        
    def TransportsTransmit(self, char):
        '''Transmit char over all registered transports.'''
        
        for transport in self.transports:
            transport.transmit(char)
    
    def InsertChar(self, char):
        '''Insert char at the current carret position.'''

        if char in ('\n', '\r\n', '\r'):
            self.BreakLine()        
        
        elif char == '\t':
            for i in range(4):
                t = self.lines[self.cy] + ' '     # insert char
                self.SetTextLine(self.cy, t)      # set the new text
                self.cHoriz(1)                    # move carret
        
        elif self.IsLine(self.cy):
            t = self.lines[self.cy] + char    # insert char
            self.SetTextLine(self.cy, t)      # set the new text
            self.cHoriz(1)                    # move carret
        
        self.Refresh()
            
    def SetTextLine(self, line, text):
        '''Set text for line.'''
        
        if self.IsLine(line):
            self.lines[line] = text

    def OnSize(self, event):
        self.__init_char_dimensions()

    def ClearScreen(self):
        self.log = self.log + ''.join(self.lines)
        self.lines = ['']
        self.__init_coords()
        self.Refresh()
        
    def GetLog(self):
        return self.log + ''.join(self.lines)
    
    def ClearLog(self):
        self.log = ''

    def OnDestroy(self, event):
        for transport in self.transports:
            transport.stop()

    def SetLocalEcho(self, state):
        if state:
            self.transports.append(self.local_echo_tr)
        elif self.local_echo_tr in self.transports:
            self.transports.remove(self.local_echo_tr)
    
    def SetPortConfiguration(self, port_configuration):
        self.serial_tr = SerialTransport(self.InsertChar, port_configuration)
        self.transports.append(self.serial_tr)

    def SendFile(self, path):
        #FIXME: sendfile
        def send_file(path):
            fd = open(path, 'r')
            while 1:
                line = fd.readline()
                if not line:
                    break
                for char in line:
                    self.TransportsTransmit(char)
            self.Refresh()
            fd.close()
        
        self.sender_thread = threading.Thread(target=send_file, name='Sender', args=(path,))
        self.sender_thread.setDaemon(1)
        self.sender_thread.start()
