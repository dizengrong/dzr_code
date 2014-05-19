# -*- coding: utf8 -*-

import wx, threading, TermEmulator, util

ID_TERMINAL = 1

# 使用textctrl实现一个简单的终端模拟
class wxTerm(wx.TextCtrl):
	"""docstring for TermEmulator"""
	def __init__(self, parent, name, session = None, style = wx.TE_MULTILINE| wx.TE_DONTWRAP):
		self.session = session

		wx.TextCtrl.__init__(self, parent, ID_TERMINAL, name, style = style, size = wx.Size(300,200))
		# self.SetBackgroundColour((0,0,0))
		font = wx.Font(10, wx.FONTFAMILY_TELETYPE, wx.FONTSTYLE_NORMAL, wx.FONTSTYLE_NORMAL, False)
		self.SetFont(font)
		# self.SetDefaultStyle(wx.TextAttr(wx.WHITE, wx.NullColor, font))

		self.Bind(wx.EVT_CHAR, self.OnTerminalChar, id = ID_TERMINAL)
		self.Bind(wx.EVT_KEY_DOWN, self.OnTerminalKeyDown, id = ID_TERMINAL)
		self.Bind(wx.EVT_KEY_UP, self.OnTerminalKeyUp, id = ID_TERMINAL)
		self.Bind(wx.EVT_CLOSE, self.OnClose, id = ID_TERMINAL)

		self.Bind(wx.EVT_RIGHT_DOWN, self.OnMouseRightDown, id = ID_TERMINAL)

		self.is_closed = False

		self.termRows = 24
		self.termCols = 80
		self.linesScrolledUp = 0
		self.scrolledUpLinesLen = 0
		self.FillScreen()

		self.termEmulator = TermEmulator.V102Terminal(self.termRows, self.termCols)
		self.termEmulator.SetCallback(self.termEmulator.CALLBACK_SCROLL_UP_SCREEN,
									  self.OnTermEmulatorScrollUpScreen)
		self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UPDATE_LINES,
									  self.OnTermEmulatorUpdateLines)
		self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UPDATE_CURSOR_POS,
									  self.OnTermEmulatorUpdateCursorPos)
		# self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UPDATE_WINDOW_TITLE,
		# 							  self.OnTermEmulatorUpdateWindowTitle)
		self.termEmulator.SetCallback(self.termEmulator.CALLBACK_UNHANDLED_ESC_SEQ,
									  self.OnTermEmulatorUnhandledEscSeq)
	
		self.OnBeginRun()

	def OnMouseRightDown(self, event):
		pt = event.GetPosition()
		self.RightClickContext(event, pt)

	def RightClickContext(self, event, pt):
		menu      = wx.Menu()
		# undo      = menu.Append(wx.ID_UNDO, 'Undo')
		# menu.AppendSeparator()
		# cut       = menu.Append(wx.ID_CUT, 'Cut')
		copy      = menu.Append( wx.ID_COPY, 'Copy' )        
		# paste     = menu.Append( wx.ID_PASTE, 'Paste' )
		menu.AppendSeparator()
		# delete    = menu.Append( wx.ID_DELETE, 'Delete' )
		selectall = menu.Append( wx.ID_SELECTALL, 'Select All' )
		copy.Enable(True)
		# delete.Enable(False)
		selectall.Enable(True)
		# undo.Enable(False)
		# cut.Enable(False)
		# paste.Enable(False)

		# wx.EVT_MENU(menu, wx.ID_PASTE,  self.OnPaste)

		self.PopupMenu(menu, pt)
		menu.Destroy() 

	def OnClose(self, event):
		self.is_closed = True

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
				output = self.session.Read(2048)
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

	def OnResize(self, event):
		rows, cols = self.GetClientSize()
		print "rows: %d, cols: %d\n" % (rows, cols)
		if rows != self.termRows or cols != self.termCols:
			self.termRows = rows
			self.termCols = cols
			self.termEmulator.Resize(self.termRows, self.termCols)

		self.FillScreen()
		self.UpdateDirtyLines(range(self.termRows))

	def FillScreen(self):
		"""
		Fills the screen with blank lines so that we can update terminal
		dirty lines quickly.
		"""
		text = ""
		for i in range(self.termRows):
			for j in range(self.termCols):
				text += ' '
			text += '\n'
			
		text = text.rstrip('\n')
		self.SetValue(text)
		
	def OnTermEmulatorScrollUpScreen(self):
		blankLine = "\n"
		
		for i in range(self.termEmulator.GetCols()):
			blankLine += ' '
		
		#lineLen =  len(self.GetLineText(self.linesScrolledUp))
		lineLen = self.termCols + 2
		self.AppendText(blankLine)
		self.linesScrolledUp += 1
		self.scrolledUpLinesLen += lineLen
		
	def OnTermEmulatorUpdateLines(self):
		# print "screen: %s\n" % (self.termEmulator.GetRawScreen())
		self.UpdateDirtyLines()
		wx.YieldIfNeeded()
		
	def OnTermEmulatorUpdateCursorPos(self):
		self.UpdateCursorPos()
		
	def OnTermEmulatorUpdateWindowTitle(self, title):
		self.SetTitle(title)
		
	def OnTermEmulatorUnhandledEscSeq(self, escSeq):
		print "Unhandled escape sequence: [" + escSeq

	def GetTextCtrlLineStart(self, lineNo):
		lineStart = self.scrolledUpLinesLen 
		# 这个lineStart的位置确定与系统相关，在linux下换行符就是一个字符：'\n'
		# 而在windows下换行符是两个字符：'\r\n'
		# lineStart += (self.termCols + 1) * (lineNo - self.linesScrolledUp)
		lineStart += (self.termCols + 2) * (lineNo - self.linesScrolledUp)
		return lineStart

	def UpdateCursorPos(self):
		row, col = self.termEmulator.GetCursorPos()
		lineNo = self.linesScrolledUp + row
		insertionPoint = self.GetTextCtrlLineStart(lineNo)
		insertionPoint += col 
		# print "row: %d, col: %d, insertionPoint: %d" % (row, col, insertionPoint)
		self.SetInsertionPoint(insertionPoint)

	def UpdateDirtyLines(self, dirtyLines = None):
		text = ""
		curStyle = 0
		curFgColor = 0
		curBgColor = 0
		
		#self.SetTerminalRenditionStyle(curStyle)
		self.SetTerminalRenditionForeground(curFgColor)
		self.SetTerminalRenditionBackground(curBgColor)
		
		screen = self.termEmulator.GetRawScreen()
		screenRows = self.termEmulator.GetRows()
		screenCols = self.termEmulator.GetCols()
		# print "screenCols:%d, termCols:%d" % (screenCols, self.termCols)
		if dirtyLines == None:
			dirtyLines = self.termEmulator.GetDirtyLines()
		
		disableTextColoring = True
		
		for row in dirtyLines:
			text = ""
			# print "screen[%d]: %s|" % (row, screen[row])
			# finds the line starting and ending index
			lineNo = self.linesScrolledUp + row
			lineStart = self.GetTextCtrlLineStart(lineNo)
			# lineText = self.GetLineText(lineNo)
			# lineEnd = lineStart + len(lineText)
			lineEnd = lineStart + self.termCols
			# print "lineStart:%d, lineEnd:%d" % (lineStart, lineEnd)
			
			# delete the line content
			self.Replace(lineStart, lineEnd, "")
			self.SetInsertionPoint(lineStart)
			
			for col in range(screenCols):
				# style, fgcolor, bgcolor = self.termEmulator.GetRendition(row, col)
				
				# if not disableTextColoring and (curStyle != style 
				# 								or curFgColor != fgcolor \
				# 								or curBgColor != bgcolor):
					
				# 	if text != "":
				# 		self.WriteText(text)
				# 		text = ""
					
				# 	if curStyle != style:
				# 		curStyle = style
				# 		#print "Setting style", curStyle
				# 		if style == 0:
				# 			self.SetForegroundColour((0, 0, 0))
				# 			self.SetBackgroundColour((255, 255, 255))
				# 		elif style & self.termEmulator.RENDITION_STYLE_INVERSE:
				# 			self.SetForegroundColour((255, 255, 255))
				# 			self.SetBackgroundColour((0, 0, 0))
				# 		else:
				# 			# skip other styles since TextCtrl doesn't support
				# 			# multiple fonts(bold, italic and etc)
				# 			pass
						
				# 	if curFgColor != fgcolor:
				# 		curFgColor = fgcolor
				# 		#print "Setting foreground", curFgColor
				# 		self.SetTerminalRenditionForeground(curFgColor)
						
				# 	if curBgColor != bgcolor:
				# 		curBgColor = bgcolor
				# 		#print "Setting background", curBgColor
				# 		self.SetTerminalRenditionBackground(curBgColor)
				
				text += screen[row][col]
			self.WriteText(text)

	def OnTerminalKeyDown(self, event):
		# print "KeyDown", event.GetKeyCode()
		event.Skip()

	def OnTerminalKeyUp(self, event):
		# print "KeyUp", event.GetKeyCode()
		event.Skip()
		
	def OnTerminalChar(self, event):
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

	def SetTerminalRenditionForeground(self, fgcolor):
		if fgcolor != 0:
			if fgcolor == 1:
				self.SetForegroundColour((0, 0, 0))
			elif fgcolor == 2:
				self.SetForegroundColour((255, 0, 0))
			elif fgcolor == 3:
				self.SetForegroundColour((0, 255, 0))
			elif fgcolor == 4:
				self.SetForegroundColour((255, 255, 0))
			elif fgcolor == 5:
				self.SetForegroundColour((0, 0, 255))
			elif fgcolor == 6:
				self.SetForegroundColour((255, 0, 255))
			elif fgcolor == 7:
				self.SetForegroundColour((0, 255, 255))                
			elif fgcolor == 8:
				self.SetForegroundColour((255, 255, 255))
		else:
			self.SetForegroundColour((0, 0, 0))

	def SetTerminalRenditionBackground(self, bgcolor):
		if bgcolor != 0:
			if bgcolor == 1:
				self.SetBackgroundColour((0, 0, 0))
			elif bgcolor == 2:
				self.SetBackgroundColour((255, 0, 0))
			elif bgcolor == 3:
				self.SetBackgroundColour((0, 255, 0))
			elif bgcolor == 4:
				self.SetBackgroundColour((255, 255, 0))
			elif bgcolor == 5:
				self.SetBackgroundColour((0, 0, 255))
			elif bgcolor == 6:
				self.SetBackgroundColour((255, 0, 255))
			elif bgcolor == 7:
				self.SetBackgroundColour((0, 255, 255))                
			elif bgcolor == 8:
				self.SetBackgroundColour((255, 255, 255))
		else:
			self.SetBackgroundColour((255, 255, 255))