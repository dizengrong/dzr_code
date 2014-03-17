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
		wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = u"库存管理系统", pos = wx.DefaultPosition, size = wx.Size( 819,479 ), style = wx.DEFAULT_FRAME_STYLE|wx.MAXIMIZE|wx.TAB_TRAVERSAL )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		self.m_menubar1 = wx.MenuBar( 0 )
		self.m_menu2 = wx.Menu()
		self.m_menuItem1 = wx.MenuItem( self.m_menu2, wx.ID_ANY, u"退出", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu2.AppendItem( self.m_menuItem1 )
		
		self.m_menubar1.Append( self.m_menu2, u"文件" ) 
		
		self.m_menu5 = wx.Menu()
		self.m_menuItem3 = wx.MenuItem( self.m_menu5, wx.ID_ANY, u"管理产品型号", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu5.AppendItem( self.m_menuItem3 )
		
		self.m_menuItem4 = wx.MenuItem( self.m_menu5, wx.ID_ANY, u"管理买家数据", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu5.AppendItem( self.m_menuItem4 )
		
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
		
		self.m_listbook2 = wx.Listbook( self.m_panel2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LB_DEFAULT )
		self.m_panel20 = wx.Panel( self.m_listbook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer27 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_staticText49 = wx.StaticText( self.m_panel20, wx.ID_ANY, u"说明：查询一段时间内的销售总额明细", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText49.Wrap( -1 )
		self.m_staticText49.SetForegroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_HIGHLIGHT ) )
		
		bSizer27.Add( self.m_staticText49, 0, wx.ALL, 5 )
		
		sbSizer1 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel20, wx.ID_ANY, u"时间条件" ), wx.VERTICAL )
		
		fgSizer1 = wx.FlexGridSizer( 0, 2, 0, 0 )
		fgSizer1.SetFlexibleDirection( wx.BOTH )
		fgSizer1.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText3 = wx.StaticText( self.m_panel20, wx.ID_ANY, u"开始：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText3.Wrap( -1 )
		fgSizer1.Add( self.m_staticText3, 0, wx.ALL, 5 )
		
		self.m_datePicker1 = wx.DatePickerCtrl( self.m_panel20, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer1.Add( self.m_datePicker1, 0, wx.ALL, 5 )
		
		self.m_staticText4 = wx.StaticText( self.m_panel20, wx.ID_ANY, u"结束：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText4.Wrap( -1 )
		fgSizer1.Add( self.m_staticText4, 0, wx.ALL, 5 )
		
		self.m_datePicker2 = wx.DatePickerCtrl( self.m_panel20, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer1.Add( self.m_datePicker2, 0, wx.ALL, 5 )
		
		
		sbSizer1.Add( fgSizer1, 1, wx.EXPAND, 5 )
		
		
		bSizer27.Add( sbSizer1, 0, wx.EXPAND, 5 )
		
		self.m_button2 = wx.Button( self.m_panel20, wx.ID_ANY, u"查询", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer27.Add( self.m_button2, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		
		self.m_panel20.SetSizer( bSizer27 )
		self.m_panel20.Layout()
		bSizer27.Fit( self.m_panel20 )
		self.m_listbook2.AddPage( self.m_panel20, u"销售总额查询", True )
		self.m_panel21 = wx.Panel( self.m_listbook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer28 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_staticText50 = wx.StaticText( self.m_panel21, wx.ID_ANY, u"说明：查询某产品的销售明细", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText50.Wrap( -1 )
		self.m_staticText50.SetForegroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_HIGHLIGHT ) )
		
		bSizer28.Add( self.m_staticText50, 0, wx.ALL, 5 )
		
		self.m_button21 = wx.Button( self.m_panel21, wx.ID_ANY, u"查询", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer28.Add( self.m_button21, 0, wx.ALL, 5 )
		
		sbSizer11 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel21, wx.ID_ANY, u"时间条件" ), wx.VERTICAL )
		
		fgSizer11 = wx.FlexGridSizer( 0, 2, 0, 0 )
		fgSizer11.SetFlexibleDirection( wx.BOTH )
		fgSizer11.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText31 = wx.StaticText( self.m_panel21, wx.ID_ANY, u"开始：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText31.Wrap( -1 )
		fgSizer11.Add( self.m_staticText31, 0, wx.ALL, 5 )
		
		self.m_datePicker11 = wx.DatePickerCtrl( self.m_panel21, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer11.Add( self.m_datePicker11, 0, wx.ALL, 5 )
		
		self.m_staticText41 = wx.StaticText( self.m_panel21, wx.ID_ANY, u"结束：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText41.Wrap( -1 )
		fgSizer11.Add( self.m_staticText41, 0, wx.ALL, 5 )
		
		self.m_datePicker21 = wx.DatePickerCtrl( self.m_panel21, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer11.Add( self.m_datePicker21, 0, wx.ALL, 5 )
		
		
		sbSizer11.Add( fgSizer11, 1, wx.EXPAND, 5 )
		
		
		bSizer28.Add( sbSizer11, 0, wx.EXPAND, 5 )
		
		self.m_choicebook2 = wx.Choicebook( self.m_panel21, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.CHB_DEFAULT )
		self.m_panel24 = wx.Panel( self.m_choicebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer30 = wx.BoxSizer( wx.VERTICAL )
		
		bSizer33 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_checkBox5 = wx.CheckBox( self.m_panel24, wx.ID_ANY, u"全部选中", wx.DefaultPosition, wx.DefaultSize, wx.CHK_2STATE )
		bSizer33.Add( self.m_checkBox5, 0, wx.ALL, 5 )
		
		
		bSizer30.Add( bSizer33, 0, wx.EXPAND, 5 )
		
		self.m_scrolledWindow2 = wx.ScrolledWindow( self.m_panel24, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.HSCROLL|wx.VSCROLL )
		self.m_scrolledWindow2.SetScrollRate( 5, 5 )
		fgSizer7 = wx.FlexGridSizer( 0, 1, 0, 0 )
		fgSizer7.SetFlexibleDirection( wx.BOTH )
		fgSizer7.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		
		self.m_scrolledWindow2.SetSizer( fgSizer7 )
		self.m_scrolledWindow2.Layout()
		fgSizer7.Fit( self.m_scrolledWindow2 )
		bSizer30.Add( self.m_scrolledWindow2, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		self.m_panel24.SetSizer( bSizer30 )
		self.m_panel24.Layout()
		bSizer30.Fit( self.m_panel24 )
		self.m_choicebook2.AddPage( self.m_panel24, u"白膜", False )
		self.m_panel25 = wx.Panel( self.m_choicebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer301 = wx.BoxSizer( wx.VERTICAL )
		
		bSizer331 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_checkBox51 = wx.CheckBox( self.m_panel25, wx.ID_ANY, u"全部选中", wx.DefaultPosition, wx.DefaultSize, wx.CHK_2STATE )
		bSizer331.Add( self.m_checkBox51, 0, wx.ALL, 5 )
		
		
		bSizer301.Add( bSizer331, 0, wx.EXPAND, 5 )
		
		self.m_scrolledWindow21 = wx.ScrolledWindow( self.m_panel25, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.HSCROLL|wx.VSCROLL )
		self.m_scrolledWindow21.SetScrollRate( 5, 5 )
		fgSizer71 = wx.FlexGridSizer( 0, 1, 0, 0 )
		fgSizer71.SetFlexibleDirection( wx.BOTH )
		fgSizer71.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		
		self.m_scrolledWindow21.SetSizer( fgSizer71 )
		self.m_scrolledWindow21.Layout()
		fgSizer71.Fit( self.m_scrolledWindow21 )
		bSizer301.Add( self.m_scrolledWindow21, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		self.m_panel25.SetSizer( bSizer301 )
		self.m_panel25.Layout()
		bSizer301.Fit( self.m_panel25 )
		self.m_choicebook2.AddPage( self.m_panel25, u"蜂窝纸", False )
		self.m_panel26 = wx.Panel( self.m_choicebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer302 = wx.BoxSizer( wx.VERTICAL )
		
		bSizer332 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_checkBox52 = wx.CheckBox( self.m_panel26, wx.ID_ANY, u"全部选中", wx.DefaultPosition, wx.DefaultSize, wx.CHK_2STATE )
		bSizer332.Add( self.m_checkBox52, 0, wx.ALL, 5 )
		
		
		bSizer302.Add( bSizer332, 0, wx.EXPAND, 5 )
		
		self.m_scrolledWindow22 = wx.ScrolledWindow( self.m_panel26, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.HSCROLL|wx.VSCROLL )
		self.m_scrolledWindow22.SetScrollRate( 5, 5 )
		fgSizer72 = wx.FlexGridSizer( 0, 1, 0, 0 )
		fgSizer72.SetFlexibleDirection( wx.BOTH )
		fgSizer72.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		
		self.m_scrolledWindow22.SetSizer( fgSizer72 )
		self.m_scrolledWindow22.Layout()
		fgSizer72.Fit( self.m_scrolledWindow22 )
		bSizer302.Add( self.m_scrolledWindow22, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		self.m_panel26.SetSizer( bSizer302 )
		self.m_panel26.Layout()
		bSizer302.Fit( self.m_panel26 )
		self.m_choicebook2.AddPage( self.m_panel26, u"木板", False )
		bSizer28.Add( self.m_choicebook2, 1, wx.EXPAND |wx.ALL, 5 )
		
		
		self.m_panel21.SetSizer( bSizer28 )
		self.m_panel21.Layout()
		bSizer28.Fit( self.m_panel21 )
		self.m_listbook2.AddPage( self.m_panel21, u"产品相关查询", False )
		self.m_panel22 = wx.Panel( self.m_listbook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer29 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_staticText51 = wx.StaticText( self.m_panel22, wx.ID_ANY, u"说明：查询与某买家的交易明细", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText51.Wrap( 0 )
		self.m_staticText51.SetForegroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_HIGHLIGHT ) )
		
		bSizer29.Add( self.m_staticText51, 0, wx.ALL, 5 )
		
		fgSizer6 = wx.FlexGridSizer( 0, 1, 0, 0 )
		fgSizer6.SetFlexibleDirection( wx.BOTH )
		fgSizer6.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		
		bSizer29.Add( fgSizer6, 0, wx.EXPAND, 5 )
		
		self.m_button22 = wx.Button( self.m_panel22, wx.ID_ANY, u"查询", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer29.Add( self.m_button22, 0, wx.ALL, 5 )
		
		sbSizer111 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel22, wx.ID_ANY, u"时间条件" ), wx.VERTICAL )
		
		fgSizer111 = wx.FlexGridSizer( 0, 2, 0, 0 )
		fgSizer111.SetFlexibleDirection( wx.BOTH )
		fgSizer111.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		self.m_staticText311 = wx.StaticText( self.m_panel22, wx.ID_ANY, u"开始：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText311.Wrap( -1 )
		fgSizer111.Add( self.m_staticText311, 0, wx.ALL, 5 )
		
		self.m_datePicker111 = wx.DatePickerCtrl( self.m_panel22, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer111.Add( self.m_datePicker111, 0, wx.ALL, 5 )
		
		self.m_staticText411 = wx.StaticText( self.m_panel22, wx.ID_ANY, u"结束：", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText411.Wrap( -1 )
		fgSizer111.Add( self.m_staticText411, 0, wx.ALL, 5 )
		
		self.m_datePicker211 = wx.DatePickerCtrl( self.m_panel22, wx.ID_ANY, wx.DefaultDateTime, wx.DefaultPosition, wx.DefaultSize, wx.DP_DEFAULT|wx.DP_DROPDOWN )
		fgSizer111.Add( self.m_datePicker211, 0, wx.ALL, 5 )
		
		
		sbSizer111.Add( fgSizer111, 1, wx.EXPAND, 5 )
		
		
		bSizer29.Add( sbSizer111, 0, wx.EXPAND, 5 )
		
		bSizer303 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_scrolledWindow23 = wx.ScrolledWindow( self.m_panel22, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.HSCROLL|wx.VSCROLL )
		self.m_scrolledWindow23.SetScrollRate( 5, 5 )
		fgSizer73 = wx.FlexGridSizer( 0, 1, 0, 0 )
		fgSizer73.SetFlexibleDirection( wx.BOTH )
		fgSizer73.SetNonFlexibleGrowMode( wx.FLEX_GROWMODE_SPECIFIED )
		
		m_radioBox1Choices = [ u"买家1" ]
		self.m_radioBox1 = wx.RadioBox( self.m_scrolledWindow23, wx.ID_ANY, u"买家", wx.DefaultPosition, wx.DefaultSize, m_radioBox1Choices, 100, wx.RA_SPECIFY_ROWS )
		self.m_radioBox1.SetSelection( 0 )
		fgSizer73.Add( self.m_radioBox1, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		self.m_scrolledWindow23.SetSizer( fgSizer73 )
		self.m_scrolledWindow23.Layout()
		fgSizer73.Fit( self.m_scrolledWindow23 )
		bSizer303.Add( self.m_scrolledWindow23, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		bSizer29.Add( bSizer303, 1, wx.EXPAND, 5 )
		
		
		self.m_panel22.SetSizer( bSizer29 )
		self.m_panel22.Layout()
		bSizer29.Fit( self.m_panel22 )
		self.m_listbook2.AddPage( self.m_panel22, u"买家相关查询", False )
		
		bSizer4.Add( self.m_listbook2, 1, wx.ALL|wx.EXPAND, 5 )
		
		
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
		self.m_grid1.SetGridLineColour( wx.Colour( 128, 128, 0 ) )
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
		self.m_auinotebook1.AddPage( self.m_panel5, u"数据", False, wx.NullBitmap )
		self.m_panel6 = wx.Panel( self.m_auinotebook1, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		self.m_auinotebook1.AddPage( self.m_panel6, u"报表", False, wx.NullBitmap )
		
		bSizer3.Add( self.m_auinotebook1, 1, wx.EXPAND |wx.ALL, 0 )
		
		
		self.m_panel3.SetSizer( bSizer3 )
		self.m_panel3.Layout()
		bSizer3.Fit( self.m_panel3 )
		self.m_splitter1.SplitVertically( self.m_panel2, self.m_panel3, 332 )
		bSizer1.Add( self.m_splitter1, 1, wx.EXPAND, 5 )
		
		
		self.SetSizer( bSizer1 )
		self.Layout()
		self.m_statusBar1 = self.CreateStatusBar( 1, wx.ST_SIZEGRIP, wx.ID_ANY )
		
		self.Centre( wx.BOTH )
		
		# Connect Events
		self.Bind( wx.EVT_MENU, self.OnExit, id = self.m_menuItem1.GetId() )
		self.Bind( wx.EVT_MENU, self.OnAddProductBaseInfo, id = self.m_menuItem3.GetId() )
		self.Bind( wx.EVT_MENU, self.OnManagerBuyers, id = self.m_menuItem4.GetId() )
		self.Bind( wx.EVT_MENU, self.OnAbout, id = self.m_menuItem2.GetId() )
		self.m_button2.Bind( wx.EVT_BUTTON, self.OnSearch )
		self.m_button21.Bind( wx.EVT_BUTTON, self.OnSearch )
		self.m_choicebook2.Bind( wx.EVT_CHOICEBOOK_PAGE_CHANGED, self.OnChoiceCategoryChanged )
		self.m_checkBox5.Bind( wx.EVT_CHECKBOX, self.OnCheckBoxSelectAllProductTypes )
		self.m_checkBox51.Bind( wx.EVT_CHECKBOX, self.OnCheckBoxSelectAllProductTypes )
		self.m_checkBox52.Bind( wx.EVT_CHECKBOX, self.OnCheckBoxSelectAllProductTypes )
		self.m_button22.Bind( wx.EVT_BUTTON, self.OnSearch )
		self.m_auinotebook1.Bind( wx.aui.EVT_AUINOTEBOOK_PAGE_CLOSE, self.OnNoteBookClose )
		self.m_grid1.Bind( wx.grid.EVT_GRID_CELL_RIGHT_CLICK, self.OnCellRightClick )
		self.m_grid1.Bind( wx.grid.EVT_GRID_LABEL_LEFT_CLICK, self.OnGridLabelLeftClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnExit( self, event ):
		event.Skip()
	
	def OnAddProductBaseInfo( self, event ):
		event.Skip()
	
	def OnManagerBuyers( self, event ):
		event.Skip()
	
	def OnAbout( self, event ):
		event.Skip()
	
	def OnSearch( self, event ):
		event.Skip()
	
	
	def OnChoiceCategoryChanged( self, event ):
		event.Skip()
	
	def OnCheckBoxSelectAllProductTypes( self, event ):
		event.Skip()
	
	
	
	
	def OnNoteBookClose( self, event ):
		event.Skip()
	
	def OnCellRightClick( self, event ):
		event.Skip()
	
	def OnGridLabelLeftClick( self, event ):
		event.Skip()
	
	def m_splitter1OnIdle( self, event ):
		self.m_splitter1.SetSashPosition( 332 )
		self.m_splitter1.Unbind( wx.EVT_IDLE )
	

###########################################################################
## Class SearchResutlPanel
###########################################################################

class SearchResutlPanel ( wx.Panel ):
	
	def __init__( self, parent ):
		wx.Panel.__init__ ( self, parent, id = wx.ID_ANY, pos = wx.DefaultPosition, size = wx.Size( 563,330 ), style = wx.TAB_TRAVERSAL )
		
		bSizer51 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_notebook2 = wx.Notebook( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.NB_FIXEDWIDTH )
		self.m_panel27 = wx.Panel( self.m_notebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		bSizer10 = wx.BoxSizer( wx.VERTICAL )
		
		sbSizer7 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel27, wx.ID_ANY, u"过滤条件" ), wx.VERTICAL )
		
		self.m_staticText14 = wx.StaticText( self.m_panel27, wx.ID_ANY, u"这里填写查询的过滤条件", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText14.Wrap( -1 )
		self.m_staticText14.SetForegroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_HIGHLIGHT ) )
		
		sbSizer7.Add( self.m_staticText14, 0, wx.ALL, 5 )
		
		
		bSizer10.Add( sbSizer7, 0, wx.ALL|wx.EXPAND, 5 )
		
		sbSizer6 = wx.StaticBoxSizer( wx.StaticBox( self.m_panel27, wx.ID_ANY, u"查询结果" ), wx.VERTICAL )
		
		self.m_staticText11 = wx.StaticText( self.m_panel27, wx.ID_ANY, u"汇总信息：xxxx", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText11.Wrap( -1 )
		self.m_staticText11.SetForegroundColour( wx.SystemSettings.GetColour( wx.SYS_COLOUR_HIGHLIGHT ) )
		
		sbSizer6.Add( self.m_staticText11, 0, wx.ALL|wx.EXPAND, 5 )
		
		bSizer11 = wx.BoxSizer( wx.HORIZONTAL )
		
		self.m_button9 = wx.Button( self.m_panel27, wx.ID_ANY, u"生成报表", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer11.Add( self.m_button9, 0, wx.ALL, 5 )
		
		self.m_button10 = wx.Button( self.m_panel27, wx.ID_ANY, u"导出到Excel", wx.DefaultPosition, wx.DefaultSize, 0 )
		bSizer11.Add( self.m_button10, 0, wx.ALL, 5 )
		
		
		sbSizer6.Add( bSizer11, 0, wx.ALL|wx.EXPAND, 5 )
		
		self.m_grid2 = wx.grid.Grid( self.m_panel27, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, 0 )
		
		# Grid
		self.m_grid2.CreateGrid( 0, 0 )
		self.m_grid2.EnableEditing( False )
		self.m_grid2.EnableGridLines( True )
		self.m_grid2.SetGridLineColour( wx.Colour( 128, 128, 0 ) )
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
		sbSizer6.Add( self.m_grid2, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		bSizer10.Add( sbSizer6, 1, wx.ALL|wx.EXPAND, 5 )
		
		
		self.m_panel27.SetSizer( bSizer10 )
		self.m_panel27.Layout()
		bSizer10.Fit( self.m_panel27 )
		self.m_notebook2.AddPage( self.m_panel27, u"查询结果", True )
		self.m_panel28 = wx.Panel( self.m_notebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		self.m_notebook2.AddPage( self.m_panel28, u"报表", False )
		
		bSizer51.Add( self.m_notebook2, 1, wx.EXPAND |wx.ALL, 5 )
		
		
		self.SetSizer( bSizer51 )
		self.Layout()
		
		# Connect Events
		self.m_button9.Bind( wx.EVT_BUTTON, self.OnGenerateReport )
		self.m_button10.Bind( wx.EVT_BUTTON, self.OnExport2Excel )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnGenerateReport( self, event ):
		event.Skip()
	
	def OnExport2Excel( self, event ):
		event.Skip()
	

###########################################################################
## Class DlgManagerProduct2
###########################################################################

class DlgManagerProduct2 ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"产品管理", pos = wx.DefaultPosition, size = wx.Size( 367,533 ), style = wx.DEFAULT_DIALOG_STYLE )
		
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
		self.m_choice3.Bind( wx.EVT_CHOICE, self.OnSelectBuyer )
		self.m_button6.Bind( wx.EVT_BUTTON, self.OnMangerBuyers )
		self.m_button8.Bind( wx.EVT_BUTTON, self.OnQueryHistorySells )
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
	
	def OnSelectBuyer( self, event ):
		event.Skip()
	
	def OnMangerBuyers( self, event ):
		event.Skip()
	
	def OnQueryHistorySells( self, event ):
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
		self.m_button8.Bind( wx.EVT_BUTTON, self.OnQueryHistorySells )
		self.m_textCtrl6.Bind( wx.EVT_CHAR, self.OnTextChange )
		self.m_textCtrl10.Bind( wx.EVT_CHAR, self.OnTextChange )
		self.m_textCtrl23.Bind( wx.EVT_CHAR, self.OnTextChange )
		self.m_button9.Bind( wx.EVT_BUTTON, self.OnOKBtnClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnQueryHistorySells( self, event ):
		event.Skip()
	
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
		self.m_grid5.SetGridLineColour( wx.Colour( 128, 128, 0 ) )
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
		self.m_button16.Bind( wx.EVT_BUTTON, self.OnCancelBtnClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnCellChange( self, event ):
		event.Skip()
	
	def OnOKBtnClick( self, event ):
		event.Skip()
	
	def OnCancelBtnClick( self, event ):
		event.Skip()
	

###########################################################################
## Class DlgManagerProduct
###########################################################################

class DlgManagerProduct ( wx.Dialog ):
	
	def __init__( self, parent ):
		wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = u"产品管理", pos = wx.DefaultPosition, size = wx.Size( 518,392 ), style = wx.CLOSE_BOX|wx.DEFAULT_DIALOG_STYLE|wx.MAXIMIZE_BOX|wx.MINIMIZE_BOX|wx.RESIZE_BORDER )
		
		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
		
		bSizer20 = wx.BoxSizer( wx.VERTICAL )
		
		self.m_grid5 = wx.grid.Grid( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, 0 )
		
		# Grid
		self.m_grid5.CreateGrid( 0, 0 )
		self.m_grid5.EnableEditing( True )
		self.m_grid5.EnableGridLines( True )
		self.m_grid5.SetGridLineColour( wx.Colour( 128, 128, 0 ) )
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
		bSizer20.Add( self.m_grid5, 1, wx.ALL|wx.EXPAND, 5 )
		
		bSizer17 = wx.BoxSizer( wx.HORIZONTAL )
		
		gSizer1 = wx.GridSizer( 0, 2, 0, 0 )
		
		self.m_button15 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer1.Add( self.m_button15, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		self.m_button16 = wx.Button( self, wx.ID_CANCEL, u"取消", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer1.Add( self.m_button16, 0, wx.ALIGN_CENTER|wx.ALL, 5 )
		
		
		bSizer17.Add( gSizer1, 0, wx.EXPAND, 5 )
		
		
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
		self.m_button16.Bind( wx.EVT_BUTTON, self.OnCancelBtnClick )
	
	def __del__( self ):
		pass
	
	
	# Virtual event handlers, overide them in your derived class
	def OnCellChange( self, event ):
		event.Skip()
	
	def OnOKBtnClick( self, event ):
		event.Skip()
	
	def OnCancelBtnClick( self, event ):
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
		self.m_grid4.CreateGrid( 0, 0 )
		self.m_grid4.EnableEditing( False )
		self.m_grid4.EnableGridLines( True )
		self.m_grid4.SetGridLineColour( wx.Colour( 128, 128, 0 ) )
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
	

