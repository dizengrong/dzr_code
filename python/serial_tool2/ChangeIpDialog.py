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
## Class ChangeIpDialog
###########################################################################

class ChangeIpDialog ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"修改本机ip", pos = wx.DefaultPosition, size = wx.Size( 317,250 ), style = wx.DEFAULT_DIALOG_STYLE )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer17 = wx.BoxSizer( wx.VERTICAL )
		
		bSizer18 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText17 = wx.StaticText( self, wx.ID_ANY, u"选择网卡：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText17.Wrap( -1 )
		bSizer18.Add( self.m_staticText17, 0, wx.ALL, 5 )
		
		m_choice8Choices = []
		self.m_choice8 = wx.Choice( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, m_choice8Choices, 0 )
		self.m_choice8.SetSelection( 0 )
		bSizer18.Add( self.m_choice8, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		bSizer17.Add( bSizer18, 0, wx.EXPAND, 5 )
		
		sbSizer1 = wx.StaticBoxSizer( wx.StaticBox( self, wx.ID_ANY, u"模式一" ), wx.VERTICAL )
		
		self.m_button15 = wx.Button( self, wx.ID_OK, u"点我自动获取ip", wx.DefaultPosition, wx.DefaultSize, 0 )
		sbSizer1.Add( self.m_button15, 0, wx.ALIGN_CENTER|wx.ALL, 1 )
		
		
		bSizer17.Add( sbSizer1, 0, wx.EXPAND, 2 )
		
		sbSizer4 = wx.StaticBoxSizer( wx.StaticBox( self, wx.ID_ANY, u"模式二" ), wx.VERTICAL )
		
		bSizer23 = wx.BoxSizer( wx.VERTICAL )
		
		bSizer24 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText25 = wx.StaticText( self, wx.ID_ANY, u"ip地址：    ", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText25.Wrap( -1 )
		bSizer24.Add( self.m_staticText25, 0, wx.ALL, 5 )
		
		self.m_textCtrl12 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer24.Add( self.m_textCtrl12, 1, wx.ALL, 5 )
		
		
		bSizer23.Add( bSizer24, 1, wx.EXPAND, 5 )
		
		bSizer25 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText26 = wx.StaticText( self, wx.ID_ANY, u"子网掩码：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText26.Wrap( -1 )
		bSizer25.Add( self.m_staticText26, 0, wx.ALL, 5 )
		
		self.m_textCtrl14 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer25.Add( self.m_textCtrl14, 1, wx.ALL, 5 )
		
		
		bSizer23.Add( bSizer25, 1, wx.EXPAND, 5 )
		
		bSizer26 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText27 = wx.StaticText( self, wx.ID_ANY, u"默认网关：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText27.Wrap( -1 )
		bSizer26.Add( self.m_staticText27, 0, wx.ALL, 5 )
		
		self.m_textCtrl15 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer26.Add( self.m_textCtrl15, 1, wx.ALL, 5 )
		
		
		bSizer23.Add( bSizer26, 1, wx.EXPAND, 5 )
		
		self.m_button20 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer23.Add( self.m_button20, 0, wx.ALIGN_CENTER, 5 )
		
		
		sbSizer4.Add( bSizer23, 1, wx.EXPAND, 1 )
		
		
		bSizer17.Add( sbSizer4, 0, wx.EXPAND, 2 )
		
		
		self.SetSizer( bSizer17 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.m_button15.Bind( wx.EVT_BUTTON, self.OnChangeIpMode1 )
		self.m_button20.Bind( wx.EVT_BUTTON, self.OnChangeIpMode2 )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnChangeIpMode1( self, event ):
		event.Skip()
	
	def OnChangeIpMode2( self, event ):
		event.Skip()
	

