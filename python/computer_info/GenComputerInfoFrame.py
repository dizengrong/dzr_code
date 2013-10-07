# -*- coding: utf-8 -*- 

###########################################################################
## Python code generated with wxFormBuilder (version Oct  8 2012)
## http://www.wxformbuilder.org/
##
## PLEASE DO "NOT" EDIT THIS FILE!
###########################################################################

import wx
import wx.xrc

###########################################################################
## Class GetComputerInfo
###########################################################################

class GetComputerInfo ( wx.Frame ):
	
	def __init__( self, parent ):
		wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = u"获取系统信息", pos = wx.DefaultPosition, size = wx.Size( 255,110 ), style = wx.DEFAULT_FRAME_STYLE|wx.TAB_TRAVERSAL )
		
		self.SetSizeHintsSz( wx.Size( 232,99 ), wx.DefaultSize )
		
		bSizer23 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_button14 = wx.Button( self, wx.ID_ANY, u"点我生成系统信息", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer23.Add( self.m_button14, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		self.m_button15 = wx.Button( self, wx.ID_ANY, u"退出", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer23.Add( self.m_button15, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		
		self.SetSizer( bSizer23 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.m_button14.Bind( wx.EVT_BUTTON, self.OnGenerateComputerInfo )
		self.m_button15.Bind( wx.EVT_BUTTON, self.OnExit )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnGenerateComputerInfo( self, event ):
		event.Skip()
	
	def OnExit( self, event ):
		event.Skip()
	

