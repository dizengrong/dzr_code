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
		self.__init__products()
		self.__init_buyers()
		self.temp = self.m_listbook2.GetChildren()[0] 
		self.temp.SetSingleStyle(wx.LC_SMALL_ICON | wx.LC_ALIGN_LEFT) 

	def __init__sell_table(self):
		gui_util.InitSellRecordTab(self.m_grid1)
		self.ReloadSellTab()
			
	def __init__products(self):
		pass

	def __init_buyers(self):
		pass

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
		dlg = MyDlgAddSell()
		if dlg.ShowModal() == wx.ID_OK:
			rec = dlg.GetSellRecord()
			db.InsertSellRecord(rec)
			wx.CallAfter(self.ReloadSellTab)
		dlg.Destroy()

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
		# self.m_grid1.ClearGrid()
		rows = self.m_grid1.GetNumberRows()
		if rows > 0:
			self.m_grid1.DeleteRows(numRows = rows)
		self.all_sells = db.GetAllSellRecords()
		row_count = 0
		for sell_uid in sorted(self.all_sells.keys()):
			rec = self.all_sells[sell_uid]
			self.m_grid1.AppendRows()
			gui_util.SetSellTableRow(self.m_grid1, row_count, rec)
			row_count = row_count + 1
		self.m_grid1.AppendRows(1, True)
		self.m_grid1.AutoSize()
		self.m_panel5.Layout()

	

	def OnManagerBuyers(sell_rec, event):
		dlg = MyDlgBuyerManager()
		if dlg.ShowModal() == wx.ID_OK:
			pass
			# self.all_buyers = db.GetAllBuyers()
		dlg.Destroy()

	def OnAddProductBaseInfo(self, event):
		dlg = MyDlgManagerProduct()
		if dlg.ShowModal() == wx.ID_OK:
			pass
			# self.all_buyers = db.GetAllBuyers()
		dlg.Destroy()

	def OnExit(self, event):
		self.Close(True)

	def OnSearch( self, event ):
		btn_id = event.GetId()
		if btn_id == self.m_button2.GetId():
			begin = self.m_datePicker1.GetValue().Format("%Y-%m-%d")
			end   = self.m_datePicker2.GetValue().Format("%Y-%m-%d")
			panel = MySearchResutlPanel(self.m_auinotebook1, begin, end, SEARCH_TYPE_TOTAL)
			self.m_auinotebook1.AddPage(panel, u"查询结果", True, wx.NullBitmap )
			panel.Layout()
			# self.SearchTotalSell(begin, end)
		elif btn_id == self.m_button21.GetId():
			pass
		elif btn_id == self.m_button22.GetId():
			pass

app = wx.App(redirect=False)   # Error messages go to popup window
top = MyFrame(None)
top.Show()
app.MainLoop()