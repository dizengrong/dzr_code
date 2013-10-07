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
## Class MyLicenseControlFrame
###########################################################################

class MyLicenseControlFrame ( wx.Frame ):
	
	def __init__( self, parent ):
		wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = u"license管理", pos = wx.DefaultPosition, size = wx.Size( 629,225 ), style = wx.DEFAULT_FRAME_STYLE|wx.TAB_TRAVERSAL )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		self.m_menubar2 = wx.MenuBar( 0 )
		self.m_menu4 = wx.Menu()
		self.m_menuItem7 = wx.MenuItem( self.m_menu4, wx.ID_ANY, u"导入目标机器信息", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu4.AppendItem( self.m_menuItem7 )
		
		self.m_menubar2.Append( self.m_menu4, u"文件" ) 
		
		self.SetMenuBar( self.m_menubar2 )
		
		bSizer33 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_panel8 = wx.Panel( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer24 = wx.BoxSizer( wx.HORIZONTAL )
		
		sbSizer4 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel8, wx.ID_ANY, u"目标机器信息" ), wx.VERTICAL )
		
		bSizer27 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText20 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"cpu序列号：    ", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText20.Wrap( -1 )
		bSizer27.Add( self.m_staticText20, 0, wx.ALL, 5 )
		
		self.m_textCtrl11 = wx.TextCtrl( self.m_panel8, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.TE_READONLY )
		bSizer27.Add( self.m_textCtrl11, 1, wx.ALL, 5 )
		
		
		sbSizer4.Add( bSizer27, 1, wx.EXPAND, 5 )
		
		bSizer29 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText21 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"硬盘序列号：   ", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText21.Wrap( -1 )
		bSizer29.Add( self.m_staticText21, 0, wx.ALL, 5 )
		
		self.m_textCtrl12 = wx.TextCtrl( self.m_panel8, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.TE_READONLY )
		bSizer29.Add( self.m_textCtrl12, 1, wx.ALL, 5 )
		
		
		sbSizer4.Add( bSizer29, 1, wx.EXPAND, 5 )
		
		bSizer30 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText22 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"bios序列号：    ", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText22.Wrap( -1 )
		bSizer30.Add( self.m_staticText22, 0, wx.ALL, 5 )
		
		self.m_textCtrl13 = wx.TextCtrl( self.m_panel8, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.TE_READONLY )
		bSizer30.Add( self.m_textCtrl13, 1, wx.ALL, 5 )
		
		
		sbSizer4.Add( bSizer30, 1, wx.EXPAND, 5 )
		
		bSizer31 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText23 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"mac地址列表： ", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText23.Wrap( -1 )
		bSizer31.Add( self.m_staticText23, 0, wx.ALL, 5 )
		
		self.m_textCtrl14 = wx.TextCtrl( self.m_panel8, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.TE_READONLY )
		bSizer31.Add( self.m_textCtrl14, 1, wx.ALL, 5 )
		
		
		sbSizer4.Add( bSizer31, 1, wx.EXPAND, 5 )
		
		
		bSizer24.Add( sbSizer4, 2, wx.EXPAND, 5 )
		
		sbSizer6 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel8, wx.ID_ANY, u"授权" ), wx.VERTICAL )
		
		bSizer25 = wx.BoxSizer( wx.VERTICAL )
		
		gSizer2 = wx.GridSizer( 0, 2, 0, 0 )
		
		self.m_staticText24 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"授权起始日期：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText24.Wrap( -1 )
		gSizer2.Add( self.m_staticText24, 0, wx.ALL, 5 )
		
		self.m_datePicker1 = wx.DatePickerCtrl( self.m_panel8, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT )
		gSizer2.Add( self.m_datePicker1, 0, wx.ALL, 5 )
		
		self.m_staticText25 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"授权结束日期：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText25.Wrap( -1 )
		gSizer2.Add( self.m_staticText25, 0, wx.ALL, 5 )
		
		self.m_datePicker2 = wx.DatePickerCtrl( self.m_panel8, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT )
		gSizer2.Add( self.m_datePicker2, 0, wx.ALL, 5 )
		
		self.m_radioBtn1 = wx.RadioButton( self.m_panel8, wx.ID_ANY, u"试用版", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_radioBtn1.SetValue( True ) 
		gSizer2.Add( self.m_radioBtn1, 0, wx.ALL, 5 )
		
		self.m_radioBtn2 = wx.RadioButton( self.m_panel8, wx.ID_ANY, u"注册版", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer2.Add( self.m_radioBtn2, 0, wx.ALL, 5 )
		
		
		bSizer25.Add( gSizer2, 1, wx.EXPAND, 5 )
		
		bSizer32 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_button16 = wx.Button( self.m_panel8, wx.ID_ANY, u"授权", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer32.Add( self.m_button16, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		
		bSizer25.Add( bSizer32, 1, wx.EXPAND, 5 )
		
		
		sbSizer6.Add( bSizer25, 1, wx.EXPAND, 5 )
		
		
		bSizer24.Add( sbSizer6, 1, wx.EXPAND, 5 )
		
		
		self.m_panel8.SetSizer( bSizer24 )
		self.m_panel8.Layout()
		bSizer24.Fit( self.m_panel8 )
		bSizer33.Add( self.m_panel8, 1, wx.EXPAND |wx.ALL, 0 )
		
		
		self.SetSizer( bSizer33 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.Bind( wx.EVT_MENU, self.OnOpenDestComputerInfo, id = self.m_menuItem7.GetId() )
		self.m_button16.Bind( wx.EVT_BUTTON, self.OnAuthorize )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnOpenDestComputerInfo( self, event ):
		event.Skip()
	
	def OnAuthorize( self, event ):
		event.Skip()
	

