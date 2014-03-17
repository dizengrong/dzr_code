# -*- coding: utf-8 -*- 

import wx, sqlite3, models, db
from DepotWindows import MainFrame
from models import SellRecord, Product, Buyer
from DlgAddSell import MyDlgAddSell
from DlgModifySell import MyDlgModifySell
from DlgBuyerManager import MyDlgBuyerManager
from DlgManagerProduct import MyDlgManagerProduct
from SearchResutlPanel import MySearchResutlPanel
from gui_util import *
from common import *
import gui_util


MAX_COL = ENUM_SELL_DEAL_DATE + 1	# 售出数据表格的列数

# 售出数据表格的右键菜单
SELL_TAB_CONTEXT_MENU = [(wx.NewId(), u"添加", "OnAddSellRecord"),
						 (wx.NewId(), u"修改", "OnModifySellRecord"),
						 (wx.NewId(), u"删除", "OnDeleteSellRecord"),
						]

# 控件说明：
#	m_grid1：主界面的售出数据表格
# 	m_auinotebook1：数据和查询结果的notebook	
class MyFrame(MainFrame):
	def __init__(self, parent):
		super(MyFrame, self).__init__(parent)
		self.all_sells    = {}
		self.all_products = {}
		self.all_buyers   = {}
		self.__init__sell_table()
		self.__init_product_query_panel()
		self.__init_buyer_query_panel()
		self.temp = self.m_listbook2.GetChildren()[0] 
		self.temp.SetSingleStyle(wx.LC_SMALL_ICON | wx.LC_ALIGN_LEFT) 

		self.last_clicked_col_label = -1
		# trap the column label's paint event:
		# columnLabelWindow = self.m_grid1.GetGridColLabelWindow()
		# wx.EVT_PAINT(columnLabelWindow, self.OnGridColumnHeaderPaint)
		# self.m_grid1.sortedColumn = -1

	def OnGridColumnHeaderPaint(self, evt):
		w = self.m_grid1.GetGridColLabelWindow()
		dc = wx.PaintDC(w)
		clientRect = w.GetClientRect()
		font = dc.GetFont()

		# For each column, draw it's rectangle, it's column name,
		# and it's sort indicator, if appropriate:
		#totColSize = 0
		totColSize = -self.m_grid1.GetViewStart()[0]*self.m_grid1.GetScrollPixelsPerUnit()[0] # Thanks Roger Binns
		for col in range(self.m_grid1.GetNumberCols()):
			dc.SetBrush(wx.Brush("WHEAT", wx.TRANSPARENT))
			dc.SetTextForeground(wx.BLACK)
			colSize = self.m_grid1.GetColSize(col)
			rect = (totColSize,0,colSize,32)
			dc.DrawRectangle(rect[0] - (col<>0 and 1 or 0), rect[1],
							 rect[2] + (col<>0 and 1 or 0), rect[3])
			totColSize += colSize

			if col == self.m_grid1.sortedColumn:
				font.SetWeight(wx.BOLD)
				# draw a triangle, pointed up or down, at the
				# top left of the column.
				left = rect[0] + 3
				top = rect[1] + 3

				dc.SetBrush(wxBrush("WHEAT", wxSOLID))
				if self.m_grid1.sortedColumnDescending:
					dc.DrawPolygon([(left,top), (left+6,top), (left+3,top+4)])
				else:
					dc.DrawPolygon([(left+3,top), (left+6, top+4), (left, top+4)])
			else:
				font.SetWeight(wx.NORMAL)

			dc.SetFont(font)
			dc.DrawLabel("%s" % self.m_grid1.GetColLabelValue(col),
					 rect, wx.ALIGN_CENTER | wx.ALIGN_TOP)

	def __init__sell_table(self):
		gui_util.InitSellRecordTab(self.m_grid1)
		self.ReloadSellTab()
			
	def __init__products(self):
		self.all_products = db.GetAllProducts()

	def __init_buyers(self):
		self.all_buyers = db.GetAllBuyers()

	def __init_buyer_query_panel(self):
		self.__init_buyers()
		wind       = self.m_scrolledWindow23
		wind.DestroyChildren()
		sizer      = wind.GetSizer()
		buyer_list = []
		for buyer in self.all_buyers:
			buyer_list.append(buyer.buyer_name)
		self.buyer_radio_box = wx.RadioBox( self.m_scrolledWindow23, wx.ID_ANY, u"买家", wx.DefaultPosition, wx.DefaultSize, buyer_list, len(buyer_list), wx.RA_SPECIFY_ROWS )
		self.buyer_radio_box.SetSelection( 0 )
		sizer.Add( self.buyer_radio_box, 1, wx.ALL|wx.EXPAND, 5 )
		sizer.Layout()

	def __init_product_query_panel(self):
		# m_scrolledWindow2:产品白膜
		# m_scrolledWindow21:产品蜂窝纸
		# m_scrolledWindow22:产品木板
		self.__init__products()
		self.winds = {u"木板":self.m_scrolledWindow22, 
					  u"白膜":self.m_scrolledWindow2, 
					  u"蜂窝纸":self.m_scrolledWindow21}
		for category in models.ALL_PRODUCT_TYPE2.keys():
			wind = self.winds[models.ALL_PRODUCT_TYPE2[category]]
			wind.DestroyChildren()
			sizer = wind.GetSizer()
			for t in self.all_products[category].keys():
				m_checkBox = wx.CheckBox(wind, wx.ID_ANY, u"%s" % t, wx.DefaultPosition, wx.DefaultSize, 0)
				sizer.Add(m_checkBox, 0, wx.ALL, 5)
			sizer.Layout()

	def OnCheckBoxSelectAll1(self, event):
		"""注意这个处理的鼠标左键点击checkbox的事件，该死的EVT_CHECKBOX事件居然没触发！！！"""
		print("bbbb")
		event.Skip()
		wx.CallAfter(self.DoTriggerAllProductTypes, event)

	def OnCheckBoxSelectAllProductTypes(self, event):
		checkbox_id = event.GetId()
		if checkbox_id == self.m_checkBox5.GetId(): # 白膜
			wind = self.winds[u"白膜"]
		elif checkbox_id == self.m_checkBox51.GetId(): # 蜂窝纸
			wind = self.winds[u"蜂窝纸"]
		elif checkbox_id == self.m_checkBox52.GetId(): # 木板
			wind = self.winds[u"木板"]
		is_checked = event.IsChecked()

		for child in wind.GetChildren():
			if is_checked:
				child.SetValue(True)
			else:
				child.SetValue(False)

	def OnCheckBoxSelectAllBuyers(self):
		wind = self.m_scrolledWindow23
		is_checked = event.IsChecked()
		for child in wind.GetChildren():
			if is_checked:
				child.SetValue(True)
			else:
				child.SetValue(False)

	def OnGridLabelLeftClick(self, event):
		def sort(col, reverse = False):
			sells = self.all_sells.values()
			sells = sorted(sells, key = lambda e:gui_util.GetSellFieldByCol(e, col), reverse = reverse)
			self.ReloadSellTabHelp(sells)

		row, col = event.GetRow(), event.GetCol()
		if row == -1: 
			if self.last_clicked_col_label == -1:
				colname = self.m_grid1.GetColLabelValue(col)
				self.m_grid1.SetColLabelValue(col, u"%s↑" % (colname))
				sort(col, False)
			else:
				if self.last_clicked_col_label == col:
					colname = self.m_grid1.GetColLabelValue(col)
					if colname[-1:] == u"↓":
						new_colname = u"%s↑" % (colname[:-1])
						reverse = False
					else:
						new_colname = u"%s↓" % (colname[:-1])
						reverse = True
					self.m_grid1.SetColLabelValue(col, new_colname)
					sort(col, reverse)
				else:# 点击了新的一列
					colname = self.m_grid1.GetColLabelValue(self.last_clicked_col_label)
					self.m_grid1.SetColLabelValue(self.last_clicked_col_label, colname[:-1])

					colname = self.m_grid1.GetColLabelValue(col)
					self.m_grid1.SetColLabelValue(col, u"%s↑" % (colname))
					sort(col, False)
			self.last_clicked_col_label = col
					

	def OnCellRightClick(self, event):
		menu = wx.Menu() 
		for id, title, action in SELL_TAB_CONTEXT_MENU:
			it = wx.MenuItem(menu, id, title)
			menu.AppendItem(it)
			self.Bind(wx.EVT_MENU, getattr(self, action), it) 
		self.sell_tab_clicked_row = event.GetRow()
		self.PopupMenu(menu) 
		
		menu.Destroy()
		self.sell_tab_clicked_row = None


	def OnAddSellRecord(self, event):
		dlg = MyDlgAddSell(self.all_buyers)
		if dlg.ShowModal() == wx.ID_OK:
			rec = dlg.GetSellRecord()
			db.InsertSellRecord(rec)
			wx.CallAfter(self.ReloadSellTab)
		dlg.Destroy()
		wx.CallAfter(self.__init_buyer_query_panel)

	def InsertSellRecord(self, sell_rec):
		sell_rec = db.InsertSellRecord(sell_rec)
		row      = self.m_grid1.GetNumberRows()
		gui_util.SetSellTableRow(self.m_grid1, row - 1, sell_rec)
		self.m_grid1.AppendRows()
		self.m_grid1.AutoSize()

	def OnModifySellRecord(self, event):
		row = self.sell_tab_clicked_row
		if row == None:
			return
		sell_uid = self.m_grid1.GetCellValue(row, ENUM_SELL_UID)
		sell_rec = self.all_sells[sell_uid]
		dlg = MyDlgModifySell(sell_rec)
		if dlg.ShowModal() == wx.ID_OK:
			rec = dlg.GetNewSellRecord()
			db.UpdateSellRecord(rec)
			wx.CallAfter(self.ReloadSellTab)
		dlg.Destroy()


	def OnDeleteSellRecord(self, event):
		row = self.sell_tab_clicked_row
		if row == None:
			return
		sell_uid = self.m_grid1.GetCellValue(row, ENUM_SELL_UID)
		dlg      = wx.MessageDialog(self, u"您确定要删除交易号为%s的交易记录？" % (sell_uid), u"删除交易记录", wx.OK|wx.CANCEL)
		if dlg.ShowModal() == wx.ID_OK :
			db.DeleteSellRecord(sell_uid)
			wx.CallAfter(self.ReloadSellTab)
		dlg.Destroy()

	def ReloadSellTab(self):
		"""重新加载售出记录数据"""
		self.all_sells = db.GetAllSellRecords()
		self.ReloadSellTabHelp(self.all_sells.values())

	def ReloadSellTabHelp(self, sells):
		rows = self.m_grid1.GetNumberRows()
		if rows > 0:
			self.m_grid1.DeleteRows(numRows = rows)
		row_count = 0
		for rec in sells:
			self.m_grid1.AppendRows()
			gui_util.SetSellTableRow(self.m_grid1, row_count, rec)
			row_count = row_count + 1
		self.m_grid1.AppendRows(1, True)
		self.m_grid1.AutoSize()
		self.m_panel5.Layout()

	def OnManagerBuyers(self, event):
		dlg = MyDlgBuyerManager()
		if dlg.ShowModal() == wx.ID_OK:
			self.__init_buyer_query_panel()
		dlg.Destroy()

	def OnAddProductBaseInfo(self, event):
		dlg = MyDlgManagerProduct()
		if dlg.ShowModal() == wx.ID_OK:
			self.__init_product_query_panel()
		dlg.Destroy()

	def OnExit(self, event):
		self.Close(True)

	def OnSearch( self, event ):
		btn_id = event.GetId()
		if btn_id == self.m_button2.GetId(): # 销售总额查询
			begin = self.m_datePicker1.GetValue().Format("%Y-%m-%d")
			end   = self.m_datePicker2.GetValue().Format("%Y-%m-%d")
			panel = MySearchResutlPanel(self.m_auinotebook1, begin, end, SEARCH_TYPE_TOTAL)
		elif btn_id == self.m_button21.GetId(): # 产品相关查询
			begin        = self.m_datePicker11.GetValue().Format("%Y-%m-%d")
			end          = self.m_datePicker21.GetValue().Format("%Y-%m-%d")
			category_str = self.m_choicebook2.GetPageText(self.m_choicebook2.GetSelection())
			wind         = self.winds[category_str]
			type_list    = []
			for child in wind.GetChildren():
				if child.IsChecked():
					label = child.GetLabel()
					if label != u"全部选中":
						type_list.append(label)
			panel = MySearchResutlPanel(self.m_auinotebook1, begin, end, SEARCH_TYPE_PRODUCT, (category_str, type_list))
		elif btn_id == self.m_button22.GetId(): # 买家相关查询
			begin      = self.m_datePicker111.GetValue().Format("%Y-%m-%d")
			end        = self.m_datePicker211.GetValue().Format("%Y-%m-%d")
			wind       = self.m_scrolledWindow23
			buyer_name = self.buyer_radio_box.GetStringSelection()
			panel      = MySearchResutlPanel(self.m_auinotebook1, begin, end, SEARCH_TYPE_BUYER, buyer_name)
		self.m_auinotebook1.AddPage(panel, u"查询结果", True, wx.NullBitmap )
		panel.Layout()

	def OnNoteBookClose(self, event):
		PageId = event.GetSelection()
		if PageId == 0 or PageId == 1:
			event.Veto()

	def OnChoiceCategoryChanged(self, event):
		pass

	def OnCheckBoxSelectAll(self, event):
		pass

app = wx.App(redirect=False)   # Error messages go to popup window
top = MyFrame(None)
top.Show()
app.MainLoop()