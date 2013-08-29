# -*- coding: utf8 -*-

import wx, serialRxEvent, threading

# 使用textctrl实现一个简单的终端模拟
class TermEmulator(wx.TextCtrl):
	"""docstring for TermEmulator"""
	def __init__(self, parent, id, name, style = wx.TE_MULTILINE | wx.TE_DONTWRAP|wx.TE_RICH|wx.VSCROLL):
		wx.TextCtrl.__init__(self, parent, id, name, style = style)
		self.SetBackgroundColour((0,0,0))
		font = wx.Font(10, wx.FONTFAMILY_TELETYPE, wx.FONTSTYLE_NORMAL, wx.FONTSTYLE_NORMAL, False)
		# self.SetFont(font)
		self.SetDefaultStyle(wx.TextAttr(wx.WHITE, wx.NullColor, font))

		self.Bind(serialRxEvent.EVT_SERIALRX, self.OnSerialRead)
		self.is_send_succ = False
		self.send_event   = threading.Event()
		self.send_event.clear()
	

	def AppendToOutput(self, text, color=None):
		# promt = datetime.datetime.now().strftime("%H:%M:%S> ")
		if text[-1:] != '\n':
			text = text + '\n'
		promt  = ">> "
		start1 = self.GetLastPosition()
		self.AppendText(promt)
		end1   = self.GetLastPosition()
		self.SetStyle(start1, end1, wx.TextAttr(wx.GREEN))

		start2 = self.GetLastPosition()
		self.AppendText(text)
		end2 = self.GetLastPosition()
		if color is not None:
			self.SetStyle(start2, end2, wx.TextAttr(color))


	def OnSerialRead(self, event):
		"""Handle input from the serial port.
			每次发送数据给设备之后，设备接收完毕后会返回该数据以表示接收成功
		"""
		text = event.data
		print "receive: %s" % (text)
		if event.from_type == serialRxEvent.FROM_TYPE_PORT:
			color = None
			self.AppendToOutput(text, color)
		elif event.from_type == serialRxEvent.FROM_TYPE_SYS:
			color = wx.RED
			self.AppendToOutput(text, color)
		elif event.from_type == serialRxEvent.FROM_TYPE_SEND:
			color = wx.Color(red=153, green=151)
			self.last_send_text = text
			self.AppendToOutput(text, color)
			# self.send_event.set()
		
