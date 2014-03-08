# -*- coding: utf-8 -*- 

###########################################################################
## Python code generated with wxFormBuilder (version Nov  6 2013)
## http://www.wxformbuilder.org/
##
## PLEASE DO "NOT" EDIT THIS FILE!
###########################################################################

import wx
import wx.xrc
import wx.aui
import wx.grid

###########################################################################
## Class MainFrame
###########################################################################

class MainFrame ( wx.Frame ):
	
	def __init__( self, parent ):
		wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = u"库存管理系统", pos = wx.DefaultPosition, size = wx.Size( 819,479 ), style = wx.DEFAULT_FRAME_STYLE|wx.TAB_TRAVERSAL )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		self.m_menubar1 = wx.MenuBar( 0 )
		self.m_menu2 = wx.Menu()
		self.m_menuItem1 = wx.MenuItem( self.m_menu2, wx.ID_ANY, u"退出", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu2.AppendItem( self.m_menuItem1 )
		
		self.m_menubar1.Append( self.m_menu2, u"文件" ) 
		
		self.m_menu5 = wx.Menu()
		self.m_menuItem3 = wx.MenuItem( self.m_menu5, wx.ID_ANY, u"添加产品型号", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu5.AppendItem( self.m_menuItem3 )
		
		self.m_menubar1.Append( self.m_menu5, u"管理" ) 
		
		self.m_menu3 = wx.Menu()
		self.m_menuItem2 = wx.MenuItem( self.m_menu3, wx.ID_ANY, u"关于", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu3.AppendItem( self.m_menuItem2 )
		
		self.m_menubar1.Append( self.m_menu3, u"帮助" ) 
		
		self.SetMenuBar( self.m_menubar1 )
		
		bSizer1 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_splitter1 = wx.SplitterWindow( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.SP_3D|wx.SP_3DBORDER|wx.SP_3DSASH )
		self.m_splitter1.Bind( wx.EVT_IDLE, self.m_splitter1OnIdle )
		
		self.m_panel2 = wx.Panel( self.m_splitter1, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer4 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_staticText1 = wx.StaticText( self.m_panel2, wx.ID_ANY, u"查询", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText1.Wrap( -1 )
		self.m_staticText1.SetFont( wx.Font( 9, 74, 90, 92, False, wx.EmptyString ) )
		self.m_staticText1.SetBackgroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_ACTIVECAPTION ) )
		
		bSizer4.Add( self.m_staticText1, 0, wx.ALL|wx.EXPAND, 0 )
		
		sbSizer1 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel2, wx.ID_ANY, u"时间条件" ), wx.VERTICAL )
		
		fgSizer1 = wx.FlexGridSizer( 0, 2, 0, 0 )
		fgSizer1.SetFlexibleDirection( wx.BOTH )
		fgSizer1.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText3 = wx.StaticText( self.m_panel2, wx.ID_ANY, u"开始：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText3.Wrap( -1 )
		fgSizer1.Add( self.m_staticText3, 0, wx.ALL, 5 )
		
		self.m_datePicker1 = wx.DatePickerCtrl( self.m_panel2, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer1.Add( self.m_datePicker1, 0, wx.ALL, 5 )
		
		self.m_staticText4 = wx.StaticText( self.m_panel2, wx.ID_ANY, u"结束：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText4.Wrap( -1 )
		fgSizer1.Add( self.m_staticText4, 0, wx.ALL, 5 )
		
		self.m_datePicker2 = wx.DatePickerCtrl( self.m_panel2, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer1.Add( self.m_datePicker2, 0, wx.ALL, 5 )
		
		
		sbSizer1.Add( fgSizer1, 1, wx.EXPAND, 5 )
		
		
		bSizer4.Add( sbSizer1, 0, wx.EXPAND, 5 )
		
		sbSizer2 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel2, wx.ID_ANY, u"产品分类条件" ), wx.VERTICAL )
		
		self.m_checkBox2 = wx.CheckBox( self.m_panel2, wx.ID_ANY, u"分类1", wx.DefaultPosition, wx.DefaultSize, 0 )
		sbSizer2.Add( self.m_checkBox2, 0, wx.ALL, 5 )
		
		self.m_checkBox3 = wx.CheckBox( self.m_panel2, wx.ID_ANY, u"分类2", wx.DefaultPosition, wx.DefaultSize, 0 )
		sbSizer2.Add( self.m_checkBox3, 0, wx.ALL, 5 )
		
		self.m_checkBox4 = wx.CheckBox( self.m_panel2, wx.ID_ANY, u"分类3", wx.DefaultPosition, wx.DefaultSize, 0 )
		sbSizer2.Add( self.m_checkBox4, 0, wx.ALL, 5 )
		
		
		bSizer4.Add( sbSizer2, 0, wx.EXPAND, 5 )
		
		self.m_button2 = wx.Button( self.m_panel2, wx.ID_ANY, u"查询", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer4.Add( self.m_button2, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		
		self.m_panel2.SetSizer( bSizer4 )
		self.m_panel2.Layout()
		bSizer4.Fit( self.m_panel2 )
		self.m_panel3 = wx.Panel( self.m_splitter1, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		self.m_panel3.SetFont( wx.Font( 9, 74, 90, 92, False, wx.EmptyString ) )
		
		bSizer3 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_auinotebook1 = wx.aui.AuiNotebook( self.m_panel3, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.aui.AUI_NB_CLOSE_ON_ALL_TABS|wx.aui.AUI_NB_DEFAULT_STYLE )
		self.m_panel5 = wx.Panel( self.m_auinotebook1, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer41 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_grid1 = wx.grid.Grid( self.m_panel5, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, 0 )
		
		# Grid
		self.m_grid1.CreateGrid( 0, 0 )
		self.m_grid1.EnableEditing( False )
		self.m_grid1.EnableGridLines( True )
		self.m_grid1.EnableDragGridSize( False )
		self.m_grid1.SetMargins( 0, 0 )
		
		# Columns
		self.m_grid1.EnableDragColMove( False )
		self.m_grid1.EnableDragColSize( True )
		self.m_grid1.SetColLabelSize( 30 )
		self.m_grid1.SetColLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Rows
		self.m_grid1.AutoSizeRows()
		self.m_grid1.EnableDragRowSize( True )
		self.m_grid1.SetRowLabelSize( 40 )
		self.m_grid1.SetRowLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Label Appearance
		
		# Cell Defaults
		self.m_grid1.SetDefaultCellAlignment( wx.ALIGN_LEFT, wx.ALIGN_TOP )
		bSizer41.Add( self.m_grid1, 1, wx.ALL|wx.EXPAND, 0 )
		
		
		self.m_panel5.SetSizer( bSizer41 )
		self.m_panel5.Layout()
		bSizer41.Fit( self.m_panel5 )
		self.m_auinotebook1.AddPage( self.m_panel5, u"数据", True, wx.NullBitmap )
		self.m_panel6 = wx.Panel( self.m_auinotebook1, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		self.m_auinotebook1.AddPage( self.m_panel6, u"报表", False, wx.NullBitmap )
		self.m_panel9 = wx.Panel( self.m_auinotebook1, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer8 = wx.BoxSizer( wx.HORIZONTAL )
		
		bSizer10 = wx.BoxSizer( wx.VERTICAL )
		
		sbSizer7 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel9, wx.ID_ANY, u"过滤条件" ), wx.VERTICAL )
		
		self.m_staticText14 = wx.StaticText( self.m_panel9, wx.ID_ANY, u"这里填写查询的过滤条件", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText14.Wrap( -1 )
		sbSizer7.Add( self.m_staticText14, 0, wx.ALL, 5 )
		
		
		bSizer10.Add( sbSizer7, 0, wx.EXPAND, 5 )
		
		sbSizer6 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel9, wx.ID_ANY, u"查询结果" ), wx.VERTICAL )
		
		self.m_grid2 = wx.grid.Grid( self.m_panel9, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, 0 )
		
		# Grid
		self.m_grid2.CreateGrid( 5, 5 )
		self.m_grid2.EnableEditing( True )
		self.m_grid2.EnableGridLines( True )
		self.m_grid2.EnableDragGridSize( False )
		self.m_grid2.SetMargins( 0, 0 )
		
		# Columns
		self.m_grid2.EnableDragColMove( False )
		self.m_grid2.EnableDragColSize( True )
		self.m_grid2.SetColLabelSize( 30 )
		self.m_grid2.SetColLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Rows
		self.m_grid2.EnableDragRowSize( True )
		self.m_grid2.SetRowLabelSize( 80 )
		self.m_grid2.SetRowLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Label Appearance
		
		# Cell Defaults
		self.m_grid2.SetDefaultCellAlignment( wx.ALIGN_LEFT, wx.ALIGN_TOP )
		sbSizer6.Add( self.m_grid2, 0, wx.ALL, 5 )
		
		self.m_staticText11 = wx.StaticText( self.m_panel9, wx.ID_ANY, u"汇总信息：xxxx", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText11.Wrap( -1 )
		sbSizer6.Add( self.m_staticText11, 0, wx.ALL, 5 )
		
		bSizer11 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_button9 = wx.Button( self.m_panel9, wx.ID_ANY, u"生成报表", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer11.Add( self.m_button9, 0, wx.ALL, 5 )
		
		self.m_button10 = wx.Button( self.m_panel9, wx.ID_ANY, u"导出到Excel", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer11.Add( self.m_button10, 0, wx.ALL, 5 )
		
		
		sbSizer6.Add( bSizer11, 1, wx.EXPAND, 5 )
		
		
		bSizer10.Add( sbSizer6, 0, wx.EXPAND, 5 )
		
		
		bSizer8.Add( bSizer10, 0, wx.EXPAND, 5 )
		
		self.m_scrolledWindow1 = wx.ScrolledWindow( self.m_panel9, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.HSCROLL|wx.VSCROLL )
		self.m_scrolledWindow1.SetScrollRate( 5, 5 )
		self.m_scrolledWindow1.SetBackgroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_3DDKSHADOW ) )
		
		bSizer8.Add( self.m_scrolledWindow1, 1, wx.EXPAND |wx.ALL, 5 )
		
		
		self.m_panel9.SetSizer( bSizer8 )
		self.m_panel9.Layout()
		bSizer8.Fit( self.m_panel9 )
		self.m_auinotebook1.AddPage( self.m_panel9, u"查询1", False, wx.NullBitmap )
		
		bSizer3.Add( self.m_auinotebook1, 1, wx.EXPAND |wx.ALL, 0 )
		
		
		self.m_panel3.SetSizer( bSizer3 )
		self.m_panel3.Layout()
		bSizer3.Fit( self.m_panel3 )
		self.m_splitter1.SplitVertically( self.m_panel2, self.m_panel3, 189 )
		bSizer1.Add( self.m_splitter1, 1, wx.EXPAND, 5 )
		
		
		self.SetSizer( bSizer1 )
		self.Layout()
		self.m_statusBar1 = self.CreateStatusBar( 1, wx.ST_SIZEGRIP, wx.ID_ANY )
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.Bind( wx.EVT_MENU, self.OnExit, id = self.m_menuItem1.GetId() )
		self.Bind( wx.EVT_MENU, self.OnAddProductBaseInfo, id = self.m_menuItem3.GetId() )
		self.Bind( wx.EVT_MENU, self.OnAbout, id = self.m_menuItem2.GetId() )
		self.m_button2.Bind( wx.EVT_BUTTON, self.OnSearch )
		self.m_grid1.Bind( wx.grid.EVT_GRID_CELL_RIGHT_CLICK, self.OnCellRightClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnExit( self, event ):
		event.Skip()
	
	def OnAddProductBaseInfo( self, event ):
		event.Skip()
	
	def OnAbout( self, event ):
		event.Skip()
	
	def OnSearch( self, event ):
		event.Skip()
	
	def OnCellRightClick( self, event ):
		event.Skip()
	
	def m_splitter1OnIdle( self, event ):
		self.m_splitter1.SetSashPosition( 189 )
		self.m_splitter1.Unbind( wx.EVT_IDLE )
	

###########################################################################
## Class DlgAddProductType
###########################################################################

class DlgAddProductType ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"添加产品型号", pos = wx.DefaultPosition, size = wx.Size( 367,533 ), style = wx.DEFAULT_DIALOG_STYLE )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer5 = wx.BoxSizer( wx.VERTICAL )
		
		sbSizer4 = wx.StaticBoxSizer( wx.StaticBox( self, wx.ID_ANY, u"现有型号：" ), wx.VERTICAL )
		
		self.m_treeCtrl3 = wx.TreeCtrl( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TR_DEFAULT_STYLE )
		sbSizer4.Add( self.m_treeCtrl3, 1, wx.ALL|wx.EXPAND, 0 )
		
		
		bSizer5.Add( sbSizer4, 1, wx.ALL|wx.EXPAND, 0 )
		
		sbSizer5 = wx.StaticBoxSizer( wx.StaticBox( self, wx.ID_ANY, u"添加型号：" ), wx.VERTICAL )
		
		fgSizer2 = wx.FlexGridSizer( 0, 2, 0, 0 )
		fgSizer2.SetFlexibleDirection( wx.BOTH )
		fgSizer2.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText5 = wx.StaticText( self, wx.ID_ANY, u"产品分类：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText5.Wrap( -1 )
		fgSizer2.Add( self.m_staticText5, 0, wx.ALL, 5 )
		
		m_choice1Choices = []
		self.m_choice1 = wx.Choice( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, m_choice1Choices, 0 )
		self.m_choice1.SetSelection( 0 )
		fgSizer2.Add( self.m_choice1, 0, wx.ALL|wx.EXPAND, 5 )
		
		self.m_staticText6 = wx.StaticText( self, wx.ID_ANY, u"产品型号：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText6.Wrap( -1 )
		fgSizer2.Add( self.m_staticText6, 0, wx.ALL, 5 )
		
		self.m_textCtrl1 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer2.Add( self.m_textCtrl1, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		sbSizer5.Add( fgSizer2, 0, wx.EXPAND, 5 )
		
		sbSizer3 = wx.StaticBoxSizer( wx.StaticBox( self, wx.ID_ANY, u"型号属性" ), wx.VERTICAL )
		
		fgSizer4 = wx.FlexGridSizer( 2, 2, 0, 0 )
		fgSizer4.SetFlexibleDirection( wx.BOTH )
		fgSizer4.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText7 = wx.StaticText( self, wx.ID_ANY, u"长(mm)：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText7.Wrap( -1 )
		fgSizer4.Add( self.m_staticText7, 0, wx.ALL, 5 )
		
		self.m_textCtrl2 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl2, 0, wx.ALL|wx.EXPAND, 5 )
		
		self.m_staticText8 = wx.StaticText( self, wx.ID_ANY, u"宽(mm)：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText8.Wrap( -1 )
		fgSizer4.Add( self.m_staticText8, 0, wx.ALL, 5 )
		
		self.m_textCtrl3 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl3, 0, wx.ALL|wx.EXPAND, 5 )
		
		self.m_staticText9 = wx.StaticText( self, wx.ID_ANY, u"高(mm)：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText9.Wrap( -1 )
		fgSizer4.Add( self.m_staticText9, 0, wx.ALL, 5 )
		
		self.m_textCtrl4 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl4, 0, wx.ALL|wx.EXPAND, 5 )
		
		self.m_staticText10 = wx.StaticText( self, wx.ID_ANY, u"每立方米重量kg/m³:", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText10.Wrap( -1 )
		fgSizer4.Add( self.m_staticText10, 0, wx.ALL, 5 )
		
		self.m_textCtrl5 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl5, 0, wx.ALL|wx.EXPAND, 5 )
		
		self.m_staticText52 = wx.StaticText( self, wx.ID_ANY, u"单价：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText52.Wrap( -1 )
		fgSizer4.Add( self.m_staticText52, 0, wx.ALL, 5 )
		
		self.m_textCtrl24 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl24, 0, wx.ALL, 5 )
		
		
		sbSizer3.Add( fgSizer4, 0, wx.EXPAND, 5 )
		
		
		sbSizer5.Add( sbSizer3, 0, wx.EXPAND, 5 )
		
		bSizer7 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_button7 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer7.Add( self.m_button7, 1, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		self.m_button8 = wx.Button( self, wx.ID_CANCEL, u"取消", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer7.Add( self.m_button8, 1, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		
		sbSizer5.Add( bSizer7, 0, wx.EXPAND, 5 )
		
		
		bSizer5.Add( sbSizer5, 0, wx.ALL|wx.EXPAND, 0 )
		
		
		self.SetSizer( bSizer5 )
		self.Layout()
		
		self.Centre( wx.BOTH )
	
	def __del__( self ):
		pass
	

###########################################################################
## Class DlgAddSell
###########################################################################

class DlgAddSell ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"添加售出记录", pos = wx.DefaultPosition, size = wx.Size( 382,429 ), style = wx.DEFAULT_DIALOG_STYLE|wx.RESIZE_BORDER )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer10 = wx.BoxSizer( wx.VERTICAL )
		
		fgSizer4 = wx.FlexGridSizer( 2, 2, 0, 0 )
		fgSizer4.SetFlexibleDirection( wx.BOTH )
		fgSizer4.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText53 = wx.StaticText( self, wx.ID_ANY, u"产品分类：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText53.Wrap( -1 )
		fgSizer4.Add( self.m_staticText53, 0, wx.ALL, 5 )
		
		m_choice8Choices = []
		self.m_choice8 = wx.Choice( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, m_choice8Choices, 0 )
		self.m_choice8.SetSelection( 0 )
		fgSizer4.Add( self.m_choice8, 0, wx.ALL, 5 )
		
		self.m_staticText12 = wx.StaticText( self, wx.ID_ANY, u"产品型号：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText12.Wrap( -1 )
		fgSizer4.Add( self.m_staticText12, 0, wx.ALL, 5 )
		
		m_choice2Choices = []
		self.m_choice2 = wx.Choice( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, m_choice2Choices, 0 )
		self.m_choice2.SetSelection( 0 )
		fgSizer4.Add( self.m_choice2, 0, wx.ALL, 5 )
		
		self.m_staticText16 = wx.StaticText( self, wx.ID_ANY, u"买家：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText16.Wrap( -1 )
		fgSizer4.Add( self.m_staticText16, 0, wx.ALL, 5 )
		
		bSizer13 = wx.BoxSizer( wx.HORIZONTAL )
		
		m_choice3Choices = []
		self.m_choice3 = wx.Choice( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, m_choice3Choices, 0 )
		self.m_choice3.SetSelection( 0 )
		bSizer13.Add( self.m_choice3, 0, wx.ALL, 5 )
		
		self.m_button6 = wx.Button( self, wx.ID_ANY, u"管理买方数据", wx.DefaultPosition, wx.DefaultSize, wx.BU_EXACTFIT|wx.NO_BORDER )
		bSizer13.Add( self.m_button6, 0, wx.ALL, 5 )
		
		
		fgSizer4.Add( bSizer13, 1, wx.EXPAND, 5 )
		
		self.m_staticText21 = wx.StaticText( self, wx.ID_ANY, u"历史交易：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText21.Wrap( -1 )
		fgSizer4.Add( self.m_staticText21, 0, wx.ALL, 5 )
		
		self.m_button8 = wx.Button( self, wx.ID_ANY, u"没有历史交易", wx.DefaultPosition, wx.DefaultSize, wx.NO_BORDER )
		self.m_button8.Enable( False )
		
		fgSizer4.Add( self.m_button8, 0, wx.ALL, 5 )
		
		self.m_staticText13 = wx.StaticText( self, wx.ID_ANY, u"出售数量：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText13.Wrap( -1 )
		fgSizer4.Add( self.m_staticText13, 0, wx.ALL, 5 )
		
		self.m_textCtrl6 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl6, 0, wx.ALL, 5 )
		
		self.m_staticText14 = wx.StaticText( self, wx.ID_ANY, u"出售单价：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText14.Wrap( -1 )
		fgSizer4.Add( self.m_staticText14, 0, wx.ALL, 5 )
		
		self.m_textCtrl8 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl8, 0, wx.ALL, 5 )
		
		self.m_staticText19 = wx.StaticText( self, wx.ID_ANY, u"出售总价：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText19.Wrap( -1 )
		fgSizer4.Add( self.m_staticText19, 0, wx.ALL, 5 )
		
		self.m_staticText24 = wx.StaticText( self, wx.ID_ANY, u"数量*单价", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText24.Wrap( -1 )
		self.m_staticText24.SetForegroundColour( wx.Colour( 255, 0, 0 ) )
		
		fgSizer4.Add( self.m_staticText24, 0, wx.ALL, 5 )
		
		self.m_staticText23 = wx.StaticText( self, wx.ID_ANY, u"成交总价：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText23.Wrap( -1 )
		fgSizer4.Add( self.m_staticText23, 0, wx.ALL, 5 )
		
		self.m_textCtrl10 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl10, 0, wx.ALL, 5 )
		
		self.m_staticText25 = wx.StaticText( self, wx.ID_ANY, u"已收款：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText25.Wrap( -1 )
		fgSizer4.Add( self.m_staticText25, 0, wx.ALL, 5 )
		
		self.m_textCtrl11 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl11, 0, wx.ALL, 5 )
		
		self.m_staticText26 = wx.StaticText( self, wx.ID_ANY, u"欠款：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText26.Wrap( -1 )
		fgSizer4.Add( self.m_staticText26, 0, wx.ALL, 5 )
		
		self.m_staticText39 = wx.StaticText( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText39.Wrap( -1 )
		self.m_staticText39.SetForegroundColour( wx.Colour( 255, 0, 0 ) )
		
		fgSizer4.Add( self.m_staticText39, 0, wx.ALL, 5 )
		
		self.m_staticText15 = wx.StaticText( self, wx.ID_ANY, u"出售日期：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText15.Wrap( -1 )
		fgSizer4.Add( self.m_staticText15, 0, wx.ALL, 5 )
		
		self.m_datePicker3 = wx.DatePickerCtrl( self, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer4.Add( self.m_datePicker3, 0, wx.ALL, 5 )
		
		
		bSizer10.Add( fgSizer4, 0, wx.EXPAND, 5 )
		
		bSizer12 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_button9 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer12.Add( self.m_button9, 1, wx.ALL, 5 )
		
		self.m_button10 = wx.Button( self, wx.ID_CANCEL, u"取消", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer12.Add( self.m_button10, 1, wx.ALL, 5 )
		
		
		bSizer10.Add( bSizer12, 0, wx.EXPAND, 5 )
		
		
		self.SetSizer( bSizer10 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.m_choice8.Bind( wx.EVT_CHOICE, self.OnProductClassChoice )
		self.m_button6.Bind( wx.EVT_BUTTON, self.OnMangerBuyers )
		self.m_textCtrl6.Bind( wx.EVT_CHAR, self.OnSellNumTextChange )
		self.m_textCtrl8.Bind( wx.EVT_CHAR, self.OnUnitPriceTextChange )
		self.m_textCtrl10.Bind( wx.EVT_CHAR, self.OnDealPriceTextChange )
		self.m_textCtrl11.Bind( wx.EVT_CHAR, self.OnPaidTextChange )
		self.m_button9.Bind( wx.EVT_BUTTON, self.OnOkBtnClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnProductClassChoice( self, event ):
		event.Skip()
	
	def OnMangerBuyers( self, event ):
		event.Skip()
	
	def OnSellNumTextChange( self, event ):
		event.Skip()
	
	def OnUnitPriceTextChange( self, event ):
		event.Skip()
	
	def OnDealPriceTextChange( self, event ):
		event.Skip()
	
	def OnPaidTextChange( self, event ):
		event.Skip()
	
	def OnOkBtnClick( self, event ):
		event.Skip()
	

###########################################################################
## Class DlgModifySell
###########################################################################

class DlgModifySell ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"修改售出记录", pos = wx.DefaultPosition, size = wx.Size( 382,411 ), style = wx.DEFAULT_DIALOG_STYLE|wx.RESIZE_BORDER )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer10 = wx.BoxSizer( wx.VERTICAL )
		
		fgSizer4 = wx.FlexGridSizer( 2, 2, 0, 0 )
		fgSizer4.SetFlexibleDirection( wx.BOTH )
		fgSizer4.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText41 = wx.StaticText( self, wx.ID_ANY, u"产品分类：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText41.Wrap( -1 )
		fgSizer4.Add( self.m_staticText41, 0, wx.ALL, 5 )
		
		self.m_staticText42 = wx.StaticText( self, wx.ID_ANY, u"MyLabel", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText42.Wrap( -1 )
		fgSizer4.Add( self.m_staticText42, 0, wx.ALL, 5 )
		
		self.m_staticText12 = wx.StaticText( self, wx.ID_ANY, u"产品型号：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText12.Wrap( -1 )
		fgSizer4.Add( self.m_staticText12, 0, wx.ALL, 5 )
		
		self.m_staticText49 = wx.StaticText( self, wx.ID_ANY, u"MyLabel", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText49.Wrap( -1 )
		fgSizer4.Add( self.m_staticText49, 0, wx.ALL, 5 )
		
		self.m_staticText16 = wx.StaticText( self, wx.ID_ANY, u"买家：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText16.Wrap( -1 )
		fgSizer4.Add( self.m_staticText16, 0, wx.ALL, 5 )
		
		self.m_staticText50 = wx.StaticText( self, wx.ID_ANY, u"MyLabel", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText50.Wrap( -1 )
		fgSizer4.Add( self.m_staticText50, 0, wx.ALL, 5 )
		
		self.m_staticText21 = wx.StaticText( self, wx.ID_ANY, u"历史交易：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText21.Wrap( -1 )
		fgSizer4.Add( self.m_staticText21, 0, wx.ALL, 5 )
		
		self.m_button8 = wx.Button( self, wx.ID_ANY, u"没有历史交易", wx.DefaultPosition, wx.DefaultSize, wx.NO_BORDER )
		self.m_button8.Enable( False )
		
		fgSizer4.Add( self.m_button8, 0, wx.ALL, 5 )
		
		self.m_staticText13 = wx.StaticText( self, wx.ID_ANY, u"出售数量：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText13.Wrap( -1 )
		fgSizer4.Add( self.m_staticText13, 0, wx.ALL, 5 )
		
		self.m_textCtrl6 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_textCtrl6.SetBackgroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_WINDOW ) )
		
		fgSizer4.Add( self.m_textCtrl6, 0, wx.ALL, 5 )
		
		self.m_staticText14 = wx.StaticText( self, wx.ID_ANY, u"出售单价：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText14.Wrap( -1 )
		fgSizer4.Add( self.m_staticText14, 0, wx.ALL, 5 )
		
		self.m_textCtrl8 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, wx.TE_READONLY|wx.NO_BORDER )
		self.m_textCtrl8.SetBackgroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_APPWORKSPACE ) )
		
		fgSizer4.Add( self.m_textCtrl8, 0, wx.ALL, 5 )
		
		self.m_staticText19 = wx.StaticText( self, wx.ID_ANY, u"出售总价：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText19.Wrap( -1 )
		fgSizer4.Add( self.m_staticText19, 0, wx.ALL, 5 )
		
		self.m_staticText24 = wx.StaticText( self, wx.ID_ANY, u"数量*单价", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText24.Wrap( -1 )
		self.m_staticText24.SetForegroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_BACKGROUND ) )
		
		fgSizer4.Add( self.m_staticText24, 0, wx.ALL, 5 )
		
		self.m_staticText23 = wx.StaticText( self, wx.ID_ANY, u"成交总价：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText23.Wrap( -1 )
		fgSizer4.Add( self.m_staticText23, 0, wx.ALL, 5 )
		
		self.m_textCtrl10 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl10, 0, wx.ALL, 5 )
		
		self.m_staticText51 = wx.StaticText( self, wx.ID_ANY, u"新增收款：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText51.Wrap( -1 )
		self.m_staticText51.SetToolTipString( u"如果为负数，表示要减少已收款！" )
		
		fgSizer4.Add( self.m_staticText51, 0, wx.ALL, 5 )
		
		self.m_textCtrl23 = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		fgSizer4.Add( self.m_textCtrl23, 0, wx.ALL, 5 )
		
		self.m_staticText25 = wx.StaticText( self, wx.ID_ANY, u"已收款：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText25.Wrap( -1 )
		fgSizer4.Add( self.m_staticText25, 0, wx.ALL, 5 )
		
		self.m_staticText43 = wx.StaticText( self, wx.ID_ANY, u"MyLabel", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText43.Wrap( -1 )
		self.m_staticText43.SetForegroundColour( wx.Colour( 255, 0, 0 ) )
		
		fgSizer4.Add( self.m_staticText43, 0, wx.ALL, 5 )
		
		self.m_staticText26 = wx.StaticText( self, wx.ID_ANY, u"欠款：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText26.Wrap( -1 )
		fgSizer4.Add( self.m_staticText26, 0, wx.ALL, 5 )
		
		self.m_staticText44 = wx.StaticText( self, wx.ID_ANY, u"MyLabel", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText44.Wrap( -1 )
		self.m_staticText44.SetForegroundColour( wx.Colour( 255, 0, 0 ) )
		
		fgSizer4.Add( self.m_staticText44, 0, wx.ALL, 5 )
		
		self.m_staticText15 = wx.StaticText( self, wx.ID_ANY, u"出售日期：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText15.Wrap( -1 )
		fgSizer4.Add( self.m_staticText15, 0, wx.ALL, 5 )
		
		self.m_datePicker3 = wx.DatePickerCtrl( self, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer4.Add( self.m_datePicker3, 0, wx.ALL, 5 )
		
		
		bSizer10.Add( fgSizer4, 0, wx.EXPAND, 5 )
		
		bSizer12 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_button9 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer12.Add( self.m_button9, 1, wx.ALL, 5 )
		
		self.m_button10 = wx.Button( self, wx.ID_CANCEL, u"取消", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer12.Add( self.m_button10, 1, wx.ALL, 5 )
		
		
		bSizer10.Add( bSizer12, 0, wx.EXPAND, 5 )
		
		
		self.SetSizer( bSizer10 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.m_textCtrl6.Bind( wx.EVT_CHAR, self.OnTextChange )
		self.m_textCtrl10.Bind( wx.EVT_CHAR, self.OnTextChange )
		self.m_textCtrl23.Bind( wx.EVT_CHAR, self.OnTextChange )
		self.m_button9.Bind( wx.EVT_BUTTON, self.OnOKBtnClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnTextChange( self, event ):
		event.Skip()
	
	
	
	def OnOKBtnClick( self, event ):
		event.Skip()
	

###########################################################################
## Class DlgBuyerManager
###########################################################################

class DlgBuyerManager ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"买家信息管理", pos = wx.DefaultPosition, size = wx.Size( 518,392 ), style = wx.DEFAULT_DIALOG_STYLE|wx.RESIZE_BORDER )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer20 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_grid5 = wx.grid.Grid( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, 0 )
		
		# Grid
		self.m_grid5.CreateGrid( 0, 0 )
		self.m_grid5.EnableEditing( True )
		self.m_grid5.EnableGridLines( True )
		self.m_grid5.EnableDragGridSize( False )
		self.m_grid5.SetMargins( 0, 0 )
		
		# Columns
		self.m_grid5.EnableDragColMove( False )
		self.m_grid5.EnableDragColSize( True )
		self.m_grid5.SetColLabelSize( 30 )
		self.m_grid5.SetColLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Rows
		self.m_grid5.EnableDragRowSize( True )
		self.m_grid5.SetRowLabelSize( 80 )
		self.m_grid5.SetRowLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Label Appearance
		
		# Cell Defaults
		self.m_grid5.SetDefaultCellAlignment( wx.ALIGN_LEFT, wx.ALIGN_TOP )
		bSizer20.Add( self.m_grid5, 0, wx.ALL, 5 )
		
		bSizer17 = wx.BoxSizer( wx.HORIZONTAL )
		
		gSizer1 = wx.GridSizer( 0, 2, 0, 0 )
		
		self.m_button15 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer1.Add( self.m_button15, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		self.m_button16 = wx.Button( self, wx.ID_CANCEL, u"取消", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer1.Add( self.m_button16, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		
		bSizer17.Add( gSizer1, 1, wx.EXPAND, 5 )
		
		
		bSizer20.Add( bSizer17, 0, wx.EXPAND, 5 )
		
		self.m_staticText40 = wx.StaticText( self, wx.ID_ANY, u"注意：表格可以直接编辑，点击确定按钮将会保存您的修改，点击取消按钮则放弃更改！", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText40.Wrap( -1 )
		self.m_staticText40.SetForegroundColour( wx.Colour( 255, 0, 0 ) )
		
		bSizer20.Add( self.m_staticText40, 0, wx.ALL, 5 )
		
		
		self.SetSizer( bSizer20 )
		self.Layout()
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.m_grid5.Bind( wx.grid.EVT_GRID_CELL_CHANGE, self.OnCellChange )
		self.m_button15.Bind( wx.EVT_BUTTON, self.OnOKBtnClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnCellChange( self, event ):
		event.Skip()
	
	def OnOKBtnClick( self, event ):
		event.Skip()
	

###########################################################################
## Class DlgHistoryDeals
###########################################################################

class DlgHistoryDeals ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"与买家XXX历史交易", pos = wx.DefaultPosition, size = wx.Size( 506,231 ), style = wx.DEFAULT_DIALOG_STYLE|wx.RESIZE_BORDER )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer21 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_grid4 = wx.grid.Grid( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, 0 )
		
		# Grid
		self.m_grid4.CreateGrid( 5, 5 )
		self.m_grid4.EnableEditing( True )
		self.m_grid4.EnableGridLines( True )
		self.m_grid4.EnableDragGridSize( False )
		self.m_grid4.SetMargins( 0, 0 )
		
		# Columns
		self.m_grid4.EnableDragColMove( False )
		self.m_grid4.EnableDragColSize( True )
		self.m_grid4.SetColLabelSize( 30 )
		self.m_grid4.SetColLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Rows
		self.m_grid4.EnableDragRowSize( True )
		self.m_grid4.SetRowLabelSize( 80 )
		self.m_grid4.SetRowLabelAlignment( wx.ALIGN_CENTRE, wx.ALIGN_CENTRE )
		
		# Label Appearance
		
		# Cell Defaults
		self.m_grid4.SetDefaultCellAlignment( wx.ALIGN_LEFT, wx.ALIGN_TOP )
		bSizer21.Add( self.m_grid4, 0, wx.ALL, 5 )
		
		
		self.SetSizer( bSizer21 )
		self.Layout()
		
		self.Centre( wx.BOTH )
	
	def __del__( self ):
		pass
	

