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
# 数据全部转移给TermEmulator来控制，提供方法来获取数据

import threading
import wx

#--------------------------
import os
import sys
# import pty
import threading
import select

# import fcntl
# import termios
import struct
# import tty
import TermEmulator
#--------------------------

class Terminal(wx.ScrolledWindow):
	def __init__(self, *args, **kwds):
		wx.ScrolledWindow.__init__(self, *args, **kwds)
		self.SetDoubleBuffered(True)

		self.session = session
		self.termRows = 24
		self.termCols = 80
		self.isDrawing = False
		self.log = ''
		self.is_closed = False


		self.__init_coords()
		self.__init_fonts()
		self.__init_char_dimensions()
		self.__init_colors()
		self.lines = ['']

		self.__set_properties()
		
		self.Bind(wx.EVT_CHAR, self.OnChar)
		self.Bind(wx.EVT_PAINT, self.OnPaint)
		self.Bind(wx.EVT_SIZE, self.OnSize)
		self.Bind(wx.EVT_WINDOW_DESTROY, self.OnDestroy)

		self.turn = 1
		self.timer = wx.Timer(self, 1)
		self.Bind(wx.EVT_TIMER, self.OnTimer, self.timer)
		self.timer.Start(700)

		self.line_num = 1

		self.__init_term_emulator()
		self.linesScrolledUp = 0

		self.OnBeginRun()


	def __init_term_emulator(self):
		self.termEmulator = TermEmulator.V102Terminal(self.termRows, self.termCols)
		# self.termEmulator.SetCallback(self.termEmulator.CALLBACK_SCROLL_UP_SCREEN,
		# 							  self.OnTermEmulatorScrollUpScreen)
		self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UPDATE_LINES,
									  self.OnTermEmulatorUpdateLines)
		# self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UPDATE_CURSOR_POS,
		# 							  self.OnTermEmulatorUpdateCursorPos)
		# self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UPDATE_WINDOW_TITLE,
		# 							  self.OnTermEmulatorUpdateWindowTitle)
		# self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UNHANDLED_ESC_SEQ,
		# 							  self.OnTermEmulatorUnhandledEscSeq)
		# self.termEmulator.SetCallback(self.termEmulator.CALLBACK_NEWLINE, 
		# 							  self.BreakLine)
		self.termEmulator.SetCallback(self.termEmulator.CALLBACK_PUSHCHAR, 
									  self.InsertChar)

	def OnBeginRun(self):
		rows, cols = self.termEmulator.GetSize()
		if rows != self.termRows or cols != self.termCols:
			self.termRows = rows
			self.termCols = cols
			self.termEmulator.Resize(self.termRows, self.termCols)
			
		self.read_thread = threading.Thread(target = self.ReadProcessOutput)
		self.waitingForOutput = True
		self.stopOutputNotifier = False
		self.read_thread.start()

	def ReadProcessOutput(self):
		while self.is_closed != False or self.session.IsAlive():
			output = ""
			try:
				# print "read from device"
				output = self.session.Read(512)
			except Exception, e:
				print "read process exception: %s" % (e)
			
			# if output != "":
			# 	print "Received: ",
			# 	util.PrintStringAsAscii(output)

			if output != "":
				try:
					wx.CallAfter(self.ReadCallBack, output)
				except:
					pass

	def ReadCallBack(self, output):
		self.termEmulator.ProcessInput(output)
		self.session.Log(output)

		# resets text control's foreground and background
		self.SetForegroundColour((0, 0, 0))
		self.SetBackgroundColour((255, 255, 255))
		
		self.waitingForOutput = True
		
	def OnTermEmulatorScrollUpScreen(self):
		self.linesScrolledUp += 1
		self.Refresh()
		
	def OnTermEmulatorUpdateLines(self):
		# self.UpdateDirtyLines()
		# wx.YieldIfNeeded()
		# print(self.termEmulator.GetLines())
		self.Refresh()
		
	def OnTermEmulatorUpdateCursorPos(self):
		self.UpdateCursorPos()
		
	def OnTermEmulatorUpdateWindowTitle(self, title):
		self.SetTitle(title)
		
	def OnTermEmulatorUnhandledEscSeq(self, escSeq):
		print "Unhandled escape sequence: [" + escSeq
		
	def OnTimer(self, event):
		self.turn = (self.turn + 1) % 2
		self.Refresh()

	def __set_properties(self):
		self.SetMinSize((self.termCols * self.fw, self.termRows * self.fh))

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
		print("self.fw, self.fh: ", self.fw, self.fh)

	def __init_char_dimensions(self):
		'''Set bw, bh, sh, sw.'''

		self.bw, self.bh = self.GetClientSize()    # body width/height (px)
		print("self.bw, self.bh: ", self.bw, self.bh)

		self.sh = self.bh / self.fh          # screen height (pos)
		self.sw = (self.bw / self.fw) - 1    # screen height (pos)
		print("self.sh, self.sw: ", self.sh, self.sw)
		self.maxWidth  = (self.sw + 1) * self.fw
		self.maxHeight = 2 * self.sh * self.fh
		self.max_line  = 2 * self.sh
		self.SetVirtualSize((self.maxWidth, self.maxHeight))
		self.SetScrollRate(self.fw, self.fh)
		
	def __init_colors(self):
		self.fgColor = wx.NamedColour('WHITE')
		self.bgColor = wx.NamedColour('BLACK')

	def OnPaint(self, event):
		'''Paint event handler.'''
		
		dc = wx.PaintDC(self)
		self.PrepareDC(dc)
		if self.isDrawing:
			return

		self.isDrawing = True
		self.UpdateView(dc)
		self.isDrawing = False

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
		if self.cy > self.max_line - 1:
			self.log = self.log + self.lines[0]
			del self.lines[0]
			self.cVert(-1)

	def BreakLine(self):
		'''Do a line break.'''
		self.line_num = self.line_num + 1
		if self.line_num > self.sh:
			self.Scroll(-1, max(0, min(self.maxHeight / self.fh, self.line_num) - self.sh))

		if self.IsLine(self.cy):
			t = self.lines[self.cy]
			self.lines = self.lines[:self.cy] + [t[:self.cx],t[self.cx:]] + self.lines[self.cy+1:]
			self.cVert(1)
			
	def Draw(self, odc):
		'''Draw background, lines and cursor.'''
		
		bmp = wx.EmptyBitmap(max(1, self.maxWidth), max(1, self.maxHeight))
		dc = wx.BufferedDC(odc, bmp)
		if dc.Ok():
			dc.SetFont(self.font)
			dc.SetBackgroundMode(wx.SOLID)
			dc.SetTextBackground(self.bgColor)
			dc.SetTextForeground(self.fgColor)
			dc.SetBrush(wx.Brush(self.bgColor))
			dc.Clear()
			dc.DrawRectangle(0, 0, self.maxWidth, self.maxHeight)
			self.DrawLines(dc)
			if self.turn == 1:
				self.DrawCursor(dc)

	def DrawLines(self, dc):
		dc.SetTextForeground(self.fgColor)
		dc.SetTextBackground(self.bgColor)
		for line in range(0, self.cy + 1):
			if self.IsLine(line):
				t = self.lines[line]
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

		# row, col = self.termEmulator.GetCursorPos()
		# lineNo = self.linesScrolledUp + row
		# if lineNo > self.max_line:
		# 	lineNo = self.max_line
		# x = col * self.fw
		# y = lineNo * self.fh
		# dc.SetBrush(wx.Brush(self.fgColor))
		# dc.SetPen(wx.Pen(self.fgColor))
		# dc.DrawRectangle(x, y, 1, self.fh)
			
	def cVert(self, num):
		'''Move the carret vertical about num positions
		and set horizontal position.'''
		
		self.cy = self.cy + num
		self.cx = min(self.cx, len(self.lines[self.cy]))

	def cHoriz(self, num):
		'''Move the carret horizontal about num positions.'''
		
		self.cx = self.cx + num
		# print(self.cx)

	def IsLine(self, lineNum):
		'''Tell whether lineNum is a valid line.'''
		return (0 <= lineNum) and (lineNum < len(self.lines))
	
	def OnChar(self, event):
		'''EVT_CHAR event handler.'''
		
		if self.session is None:
			return
		ascii = event.GetKeyCode()
		print "ASCII =", ascii
		
		keystrokes = None
		
		if ascii < 256:
			 keystrokes = chr(ascii)
		elif ascii == wx.WXK_UP:
			keystrokes = "\033[A"
		elif ascii == wx.WXK_DOWN:
			keystrokes = "\033[B"
		elif ascii == wx.WXK_RIGHT:
			keystrokes = "\033[C"
		elif ascii == wx.WXK_LEFT:
			keystrokes = "\033[D"

		if keystrokes != None:
			#print "Sending:",
			#PrintStringAsAscii(keystrokes)
			#print ""            
			# os.write(self.processIO, keystrokes)
			self.session.Write(keystrokes)
		else:
			wx.Bell()
	
	def NormalChar(self, key, event):
		'''If key is a ASCII keycode ]31;256[ or RETURN insert the character;
		otherwise bell.'''
		
		if key == wx.WXK_RETURN or key == wx.WXK_TAB or key > 31 and key < 256:
			# self.InsertChar(chr(key))
			self.termEmulator.ProcessInput(chr(key))
		else:
			wx.Bell()
	
	def InsertChar(self, char):
		'''Insert char at the current carret position.'''
		# print("InsertChar:", char)
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
		pass
