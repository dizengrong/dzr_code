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
## Class SaveSessionDialog
###########################################################################

class SaveSessionDialog ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"保存会话", pos = wx.DefaultPosition, size = wx.Size( 322,148 ), style = wx.DEFAULT_DIALOG_STYLE )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer15 = wx.BoxSizer( wx.VERTICAL )
		
		bSizer18 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_staticText21 = wx.StaticText( self, wx.ID_ANY, u"当前连接信息：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText21.Wrap( -1 )
		bSizer18.Add( self.m_staticText21, 1, 0, 2 )
		
		
		bSizer15.Add( bSizer18, 1, wx.EXPAND, 1 )
		
		bSizer16 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText24 = wx.StaticText( self, wx.ID_ANY, u"会话名称：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText24.Wrap( -1 )
		bSizer16.Add( self.m_staticText24, 0, wx.ALIGN_CENTER|wx.LEFT|wx.RIGHT, 2 )
		
		self.m_textCtrl15 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer16.Add( self.m_textCtrl15, 1, wx.ALIGN_CENTER, 2 )
		
		
		bSizer15.Add( bSizer16, 1, wx.EXPAND, 1 )
		
		bSizer17 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_checkBox2 = wx.CheckBox( self, wx.ID_ANY, u"记录日志", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer17.Add( self.m_checkBox2, 0, wx.ALIGN_CENTER|wx.LEFT|wx.RIGHT, 2 )
		
		self.m_filePicker1 = wx.FilePickerCtrl( self, wx.ID_ANY, wx.EmptyString, u"Select a file", u"*.*", wx.DefaultPosition, wx.DefaultSize, wx.FLP_SAVE|wx.FLP_USE_TEXTCTRL )
		self.m_filePicker1.Enable( False )
		
		bSizer17.Add( self.m_filePicker1, 1, wx.ALIGN_CENTER, 2 )
		
		
		bSizer15.Add( bSizer17, 1, wx.EXPAND, 1 )
		
		self.m_button13 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_button13.SetDefault() 
		bSizer15.Add( self.m_button13, 0, wx.ALIGN_BOTTOM|wx.ALIGN_CENTER|wx.TOP, 2 )
		
		
		self.SetSizer( bSizer15 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.m_checkBox2.Bind( wx.EVT_CHECKBOX, self.onRecordLog )
		self.m_button13.Bind( wx.EVT_BUTTON, self.OnSaveSession )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def onRecordLog( self, event ):
		event.Skip()
	
	def OnSaveSession( self, event ):
		event.Skip()
	

