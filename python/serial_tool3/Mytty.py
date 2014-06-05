# -*- coding: utf-8 -*- 

###########################################################################
## Python code generated with wxFormBuilder (version Oct  8 2012)
## http://www.wxformbuilder.org/
##
## PLEASE DO "NOT" EDIT THIS FILE!
###########################################################################

import wx
import wx.xrc
import wx.aui
from deviceListCtrl import DeviceListCtrl

###########################################################################
## Class Mytty
###########################################################################

class Mytty ( wx.Frame ):
	
	def __init__( self, parent ):
		wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = u"设备简易配置程序", pos = wx.DefaultPosition, size = wx.Size( 1131,600 ), style = wx.CAPTION|wx.CLOSE_BOX|wx.MAXIMIZE|wx.MAXIMIZE_BOX|wx.MINIMIZE_BOX|wx.SYSTEM_MENU )
		
		self.SetSizeHintsSz( wx.Size( 1131,600 ), wx.DefaultSize )
		
		self.m_menubar1 = wx.MenuBar( 0 )
		self.m_menu3 = wx.Menu()
		self.m_menuItem1 = wx.MenuItem( self.m_menu3, wx.ID_ANY, u"导入设备数据", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu3.AppendItem( self.m_menuItem1 )
		
		self.m_menuItem2 = wx.MenuItem( self.m_menu3, wx.ID_ANY, u"保存当前会话", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu3.AppendItem( self.m_menuItem2 )
		
		self.m_menuItem3 = wx.MenuItem( self.m_menu3, wx.ID_ANY, u"打开会话", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu3.AppendItem( self.m_menuItem3 )
		
		self.m_menuItem4 = wx.MenuItem( self.m_menu3, wx.ID_ANY, u"退出", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu3.AppendItem( self.m_menuItem4 )
		
		self.m_menubar1.Append( self.m_menu3, u"文件" ) 
		
		self.m_menu31 = wx.Menu()
		self.m_menu2 = wx.Menu()
		self.m_menu31.AppendSubMenu( self.m_menu2, u"外部工具" )
		
		self.m_menubar1.Append( self.m_menu31, u"工具" ) 
		
		self.m_menu4 = wx.Menu()
		self.m_menuItem5 = wx.MenuItem( self.m_menu4, wx.ID_ANY, u"文档", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu4.AppendItem( self.m_menuItem5 )
		
		self.m_menuItem6 = wx.MenuItem( self.m_menu4, wx.ID_ANY, u"关于", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu4.AppendItem( self.m_menuItem6 )
		
		self.m_menubar1.Append( self.m_menu4, u"帮助" ) 
		
		self.SetMenuBar( self.m_menubar1 )
		
		self.m_statusBar1 = self.CreateStatusBar( 1, wx.ST_SIZEGRIP, wx.ID_ANY )
		bSizer5 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_notebook2 = wx.Notebook( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_panel6 = wx.Panel( self.m_notebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer11 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText12 = wx.StaticText( self.m_panel6, wx.ID_ANY, u"端口号", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText12.Wrap( -1 )
		bSizer11.Add( self.m_staticText12, 0, wx.ALIGN_CENTER, 2 )
		
		m_comboBox1Choices = [ u"com1", u"com2", u"com3", u"com4", u"com5", u"com6", u"com7", u"com8", u"com9", u"com10" ]
		self.m_comboBox1 = wx.ComboBox( self.m_panel6, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, m_comboBox1Choices, 0 )
		bSizer11.Add( self.m_comboBox1, 0, wx.ALL|wx.EXPAND, 2 )
		
		
		bSizer11.AddSpacer( ( 10, 0), 0, wx.EXPAND, 5 )
		
		self.m_staticText13 = wx.StaticText( self.m_panel6, wx.ID_ANY, u"波特率设置", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText13.Wrap( -1 )
		bSizer11.Add( self.m_staticText13, 0, wx.ALIGN_CENTER, 2 )
		
		m_choice8Choices = []
		self.m_choice8 = wx.Choice( self.m_panel6, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, m_choice8Choices, 0 )
		self.m_choice8.SetSelection( 0 )
		bSizer11.Add( self.m_choice8, 0, wx.ALL|wx.EXPAND, 2 )
		
		
		bSizer11.AddSpacer( ( 10, 0), 0, wx.EXPAND, 5 )
		
		self.m_button6 = wx.Button( self.m_panel6, wx.ID_ANY, u"打开端口", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer11.Add( self.m_button6, 0, wx.ALL|wx.EXPAND, 2 )
		
		
		self.m_panel6.SetSizer( bSizer11 )
		self.m_panel6.Layout()
		bSizer11.Fit( self.m_panel6 )
		self.m_notebook2.AddPage( self.m_panel6, u"串口连接", True )
		self.m_panel7 = wx.Panel( self.m_notebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer13 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText18 = wx.StaticText( self.m_panel7, wx.ID_ANY, u"IP地址", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText18.Wrap( -1 )
		bSizer13.Add( self.m_staticText18, 0, wx.ALIGN_CENTER_HORIZONTAL|wx.ALIGN_CENTER_VERTICAL|wx.ALL, 2 )
		
		self.m_textCtrl12 = wx.TextCtrl( self.m_panel7, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer13.Add( self.m_textCtrl12, 1, wx.ALL|wx.EXPAND|wx.FIXED_MINSIZE, 2 )
		
		self.m_staticText20 = wx.StaticText( self.m_panel7, wx.ID_ANY, u"端口", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText20.Wrap( -1 )
		bSizer13.Add( self.m_staticText20, 0, wx.ALIGN_CENTER|wx.LEFT|wx.RIGHT, 2 )
		
		self.m_textCtrl14 = wx.TextCtrl( self.m_panel7, wx.ID_ANY, u"23", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer13.Add( self.m_textCtrl14, 0, wx.ALL|wx.EXPAND, 2 )
		
		self.m_button111 = wx.Button( self.m_panel7, wx.ID_ANY, u"修改本机ip地址", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer13.Add( self.m_button111, 0, wx.ALL|wx.EXPAND, 2 )
		
		self.m_button11 = wx.Button( self.m_panel7, wx.ID_ANY, u"测试连接", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer13.Add( self.m_button11, 0, wx.ALL|wx.EXPAND, 2 )
		
		self.m_button12 = wx.Button( self.m_panel7, wx.ID_ANY, u"打开连接", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer13.Add( self.m_button12, 0, wx.ALL|wx.EXPAND, 2 )
		
		
		bSizer13.AddSpacer( ( 0, 0), 1, wx.EXPAND, 5 )
		
		
		bSizer13.AddSpacer( ( 0, 0), 1, wx.EXPAND, 5 )
		
		
		bSizer13.AddSpacer( ( 0, 0), 1, wx.EXPAND, 5 )
		
		
		self.m_panel7.SetSizer( bSizer13 )
		self.m_panel7.Layout()
		bSizer13.Fit( self.m_panel7 )
		self.m_notebook2.AddPage( self.m_panel7, u"telnet连接", False )
		
		bSizer5.Add( self.m_notebook2, 0, wx.EXPAND |wx.ALL, 0 )
		
		self.m_panel8 = wx.Panel( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer6 = wx.BoxSizer( wx.HORIZONTAL )
		
		bSizer7 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_listCtrl1 = DeviceListCtrl( self.m_panel8, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LC_HRULES|wx.LC_REPORT|wx.LC_SINGLE_SEL|wx.LC_VRULES )
		bSizer7.Add( self.m_listCtrl1, 1, wx.ALIGN_CENTER|wx.ALL|wx.EXPAND, 0 )
		
		bSizer8 = wx.BoxSizer( wx.HORIZONTAL )
		
		m_choice7Choices = []
		self.m_choice7 = wx.Choice( self.m_panel8, wx.ID_ANY, wx.DefaultPosition, wx.Size( 190,-1 ), m_choice7Choices, 0 )
		self.m_choice7.SetSelection( 0 )
		self.m_choice7.SetMinSize( wx.Size( 190,-1 ) )
		
		bSizer8.Add( self.m_choice7, 1, wx.ALL, 5 )
		
		self.m_button3 = wx.Button( self.m_panel8, wx.ID_ANY, u"生成配置命令", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer8.Add( self.m_button3, 0, wx.ALL, 5 )
		
		self.m_staticline2 = wx.StaticLine( self.m_panel8, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LI_HORIZONTAL|wx.LI_VERTICAL )
		bSizer8.Add( self.m_staticline2, 0, wx.EXPAND |wx.ALL, 5 )
		
		m_choice9Choices = []
		self.m_choice9 = wx.Choice( self.m_panel8, wx.ID_ANY, wx.DefaultPosition, wx.Size( 200,-1 ), m_choice9Choices, 0 )
		self.m_choice9.SetSelection( 0 )
		self.m_choice9.SetMinSize( wx.Size( 200,-1 ) )
		
		bSizer8.Add( self.m_choice9, 1, wx.ALL, 5 )
		
		self.m_button15 = wx.Button( self.m_panel8, wx.ID_ANY, u"生成清除配置命令", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer8.Add( self.m_button15, 0, wx.ALL, 5 )
		
		
		bSizer7.Add( bSizer8, 0, wx.ALIGN_CENTER|wx.ALL|wx.EXPAND, 1 )
		
		self.m_textCtrl6 = wx.TextCtrl( self.m_panel8, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.HSCROLL|wx.TE_DONTWRAP|wx.TE_MULTILINE|wx.TE_READONLY )
		bSizer7.Add( self.m_textCtrl6, 1, wx.ALL|wx.EXPAND, 1 )
		
		bSizer10 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_staticText11 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"发送间隔（毫秒）：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText11.Wrap( -1 )
		bSizer10.Add( self.m_staticText11, 0, wx.ALIGN_CENTER, 1 )
		
		self.m_textCtrl7 = wx.TextCtrl( self.m_panel8, wx.ID_ANY, u"300", wx.DefaultPosition, wx.Size( 50,-1 ), 0 )
		bSizer10.Add( self.m_textCtrl7, 0, wx.ALL|wx.EXPAND, 1 )
		
		self.m_button5 = wx.Button( self.m_panel8, wx.ID_ANY, u"发送", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer10.Add( self.m_button5, 0, wx.ALL|wx.EXPAND, 1 )
		
		self.m_staticText191 = wx.StaticText( self.m_panel8, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText191.Wrap( -1 )
		bSizer10.Add( self.m_staticText191, 1, wx.ALL, 5 )
		
		
		bSizer7.Add( bSizer10, 0, wx.EXPAND, 5 )
		
		
		bSizer6.Add( bSizer7, 1, wx.ALL|wx.EXPAND, 1 )
		
		bSizer14 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_staticText19 = wx.StaticText( self.m_panel8, wx.ID_ANY, u"当前连接信息：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText19.Wrap( -1 )
		bSizer14.Add( self.m_staticText19, 0, wx.ALL, 5 )
		
		self.m_auinotebook2 = wx.aui.AuiNotebook( self.m_panel8, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.aui.AUI_NB_DEFAULT_STYLE|wx.STATIC_BORDER )
		self.m_panel10 = wx.Panel( self.m_auinotebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		self.m_auinotebook2.AddPage( self.m_panel10, u"session1", True, wx.NullBitmap )
		self.m_panel11 = wx.Panel( self.m_auinotebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		self.m_auinotebook2.AddPage( self.m_panel11, u"session2", False, wx.NullBitmap )
		
		bSizer14.Add( self.m_auinotebook2, 5, wx.EXPAND |wx.ALL, 1 )
		
		self.m_textCtrl71 = wx.TextCtrl( self.m_panel8, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.TE_MULTILINE|wx.TE_PROCESS_ENTER|wx.TE_PROCESS_TAB )
		bSizer14.Add( self.m_textCtrl71, 1, wx.ALL|wx.EXPAND, 1 )
		
		
		bSizer6.Add( bSizer14, 1, wx.EXPAND, 5 )
		
		
		self.m_panel8.SetSizer( bSizer6 )
		self.m_panel8.Layout()
		bSizer6.Fit( self.m_panel8 )
		bSizer5.Add( self.m_panel8, 1, wx.EXPAND |wx.ALL, 0 )
		
		
		self.SetSizer( bSizer5 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.Bind( wx.EVT_CLOSE, self.OnClose )
		self.Bind( wx.EVT_MENU, self.OnImportDeviceDatas, id = self.m_menuItem1.GetId() )
		self.Bind( wx.EVT_MENU, self.OnSaveSession, id = self.m_menuItem2.GetId() )
		self.Bind( wx.EVT_MENU, self.OnOpenSession, id = self.m_menuItem3.GetId() )
		self.Bind( wx.EVT_MENU, self.OnExit, id = self.m_menuItem4.GetId() )
		self.Bind( wx.EVT_MENU, self.OnOpenDoc, id = self.m_menuItem5.GetId() )
		self.Bind( wx.EVT_MENU, self.OnAbout, id = self.m_menuItem6.GetId() )
		self.m_notebook2.Bind( wx.EVT_NOTEBOOK_PAGE_CHANGED, self.OnConnectionPageChanged )
		self.m_button6.Bind( wx.EVT_BUTTON, self.OnOpenSerialPort )
		self.m_button111.Bind( wx.EVT_BUTTON, self.OnChangeLocalIp )
		self.m_button11.Bind( wx.EVT_BUTTON, self.OnTestTelnet )
		self.m_button12.Bind( wx.EVT_BUTTON, self.OnOpenTelnet )
		self.m_button3.Bind( wx.EVT_BUTTON, self.OnGenerateTemplate )
		self.m_button15.Bind( wx.EVT_BUTTON, self.OnGenerateClearCmd )
		self.m_button5.Bind( wx.EVT_BUTTON, self.OnSendTemplate )
		self.m_auinotebook2.Bind( wx.aui.EVT_AUINOTEBOOK_PAGE_CHANGED, self.OnSessionPageChanged )
		self.m_auinotebook2.Bind( wx.aui.EVT_AUINOTEBOOK_PAGE_CLOSE, self.OnSessionPageClose )
		self.m_textCtrl71.Bind( wx.EVT_KEY_DOWN, self.OnSendCmdKeyDown )
		self.m_textCtrl71.Bind( wx.EVT_KEY_UP, self.OnSendCmdKeyUp )
		self.m_textCtrl71.Bind( wx.EVT_TEXT_ENTER, self.OnSendComand )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnClose( self, event ):
		event.Skip()
	
	def OnImportDeviceDatas( self, event ):
		event.Skip()
	
	def OnSaveSession( self, event ):
		event.Skip()
	
	def OnOpenSession( self, event ):
		event.Skip()
	
	def OnExit( self, event ):
		event.Skip()
	
	def OnOpenDoc( self, event ):
		event.Skip()
	
	def OnAbout( self, event ):
		event.Skip()
	
	def OnConnectionPageChanged( self, event ):
		event.Skip()
	
	def OnOpenSerialPort( self, event ):
		event.Skip()
	
	def OnChangeLocalIp( self, event ):
		event.Skip()
	
	def OnTestTelnet( self, event ):
		event.Skip()
	
	def OnOpenTelnet( self, event ):
		event.Skip()
	
	def OnGenerateTemplate( self, event ):
		event.Skip()
	
	def OnGenerateClearCmd( self, event ):
		event.Skip()
	
	def OnSendTemplate( self, event ):
		event.Skip()
	
	def OnSessionPageChanged( self, event ):
		event.Skip()
	
	def OnSessionPageClose( self, event ):
		event.Skip()
	
	def OnSendCmdKeyDown( self, event ):
		event.Skip()
	
	def OnSendCmdKeyUp( self, event ):
		event.Skip()
	
	def OnSendComand( self, event ):
		event.Skip()
	

