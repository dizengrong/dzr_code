# -*- coding: utf8 -*-

import wx

FROM_TYPE_PORT = 1		# 来自端口的输出
FROM_TYPE_SYS  = 2		# 系统消息
FROM_TYPE_SEND = 3		# 发送给端口的消息

#----------------------------------------------------------------------
# Create an own event type, so that GUI updates can be delegated
# this is required as on some platforms only the main thread can
# access the GUI without crashing. wxMutexGuiEnter/wxMutexGuiLeave
# could be used too, but an event is more elegant.

SERIALRX = wx.NewEventType()
# bind to serial data receive events
EVT_SERIALRX = wx.PyEventBinder(SERIALRX, 0)


class SerialRxEvent(wx.PyCommandEvent):
	eventType = SERIALRX
	def __init__(self, windowID, data, from_type):
		wx.PyCommandEvent.__init__(self, self.eventType, windowID)
		self.data      = data
		self.from_type = from_type

	def Clone(self):
		self.__class__(self.GetId(), self.data)

#----------------------------------------------------------------------