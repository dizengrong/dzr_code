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
## Class OpenSessionDialog
###########################################################################

class OpenSessionDialog ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"打开会话", pos = wx.DefaultPosition, size = wx.Size( 304,211 ), style = wx.DEFAULT_DIALOG_STYLE )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer19 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_listCtrl2 = wx.ListCtrl( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LC_REPORT|wx.LC_SINGLE_SEL )
		bSizer19.Add( self.m_listCtrl2, 1, wx.ALL|wx.EXPAND, 2 )
		
		bSizer20 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_button15 = wx.Button( self, wx.ID_OK, u"打开", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer20.Add( self.m_button15, 1, wx.ALL|wx.EXPAND, 2 )
		
		self.m_button16 = wx.Button( self, wx.ID_ANY, u"删除", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer20.Add( self.m_button16, 1, wx.ALL|wx.EXPAND, 2 )
		
		
		bSizer19.Add( bSizer20, 0, wx.EXPAND, 2 )
		
		
		self.SetSizer( bSizer19 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.m_listCtrl2.Bind( wx.EVT_LIST_ITEM_ACTIVATED, self.OnItemActivated )
		self.m_button15.Bind( wx.EVT_BUTTON, self.OnOpenSession )
		self.m_button16.Bind( wx.EVT_BUTTON, self.OnDeleteSession )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnItemActivated( self, event ):
		event.Skip()
	
	def OnOpenSession( self, event ):
		event.Skip()
	
	def OnDeleteSession( self, event ):
		event.Skip()
	

