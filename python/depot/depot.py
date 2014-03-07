# -*- coding: utf-8 -*- 

import wx, sqlite3, models, db
from DepotWindows import MainFrame
from models import SellRecord, Product, Buyer
from DlgAddSell import MyDlgAddSell

ENUM_SELL_UID           = 0		# 售出的uid
ENUM_SELL_PRODUCT_CLASS = 1		# 产品分类
ENUM_SELL_PRODUCT_TYPE  = 2		# 产品型号
ENUM_SELL_BUYER         = 3		# 买家
ENUM_SELL_UNIT_PRICE    = 4		# 成交的单价
ENUM_SELL_AMOUNT        = 5		# 成交数量
ENUM_SELL_TOTAL_PRICE   = 6		# 计算所得总价
ENUM_SELL_DEAL_PRICE    = 7 	# 实际成交总价
ENUM_SELL_PAID          = 8 	# 已收款
ENUM_SELL_UNPAY         = 9 	# 剩余欠款
ENUM_SELL_DEAL_DATE     = 10 	# 成交日期

MAX_COL = ENUM_SELL_DEAL_DATE + 1	# 售出数据表格的列数

# 售出数据表格的右键菜单
SELL_TAB_CONTEXT_MENU = [(wx.NewId(), u"添加", "OnAddSellRecord"),
						 (wx.NewId(), u"修改", "OnModifySellRecord"),
						 (wx.NewId(), u"删除", "OnDeleteSellRecord"),
						]

# 控件说明：
#	m_grid1：主界面的售出数据表格	
class MyFrame(MainFrame):
	def __init__(self, parent):
		super(MyFrame, self).__init__(parent)
		self.all_sells    = {}
		self.all_products = {}
		self.all_buyers   = {}
		self.__init__sell_table()
		self.__init__products()
		self.__init_buyers()

	def __init__sell_table(self):
		self.m_grid1.AppendCols(MAX_COL, True)

		self.m_grid1.SetColLabelValue(ENUM_SELL_UID, u'交易id')
		self.m_grid1.SetColLabelValue(ENUM_SELL_PRODUCT_CLASS, u'产品分类')
		self.m_grid1.SetColLabelValue(ENUM_SELL_PRODUCT_TYPE, u'产品型号')
		self.m_grid1.SetColLabelValue(ENUM_SELL_BUYER, u'买家')
		self.m_grid1.SetColLabelValue(ENUM_SELL_UNIT_PRICE, u'成交的单价')
		self.m_grid1.SetColLabelValue(ENUM_SELL_AMOUNT, u'成交数量')
		self.m_grid1.SetColLabelValue(ENUM_SELL_TOTAL_PRICE, u'计算所得总价')
		self.m_grid1.SetColLabelValue(ENUM_SELL_DEAL_PRICE, u'实际成交总价')
		self.m_grid1.SetColLabelValue(ENUM_SELL_PAID, u'已收款')
		self.m_grid1.SetColLabelValue(ENUM_SELL_UNPAY, u'剩余欠款')
		self.m_grid1.SetColLabelValue(ENUM_SELL_DEAL_DATE, u'成交日期')

		row_count = 0
		for rec in db.GetAllSellRecords().values():
			self.m_grid1.AppendRows()
			self.SetSellTableRow(row_count, rec)
			row_count = row_count + 1

		# if self.m_grid1.GetNumberRows() == 0:
		self.m_grid1.AppendRows(1, True)
		self.m_grid1.AutoSize()
			
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
		self.PopupMenu(menu) 
		
		menu.Destroy()

	def OnAddSellRecord(self, event):
		dlg = MyDlgAddSell()
		if dlg.ShowModal() == wx.ID_OK:
			rec = dlg.GetSellRecord()
			self.InsertSellRecord(rec)
		dlg.Destroy()

	def InsertSellRecord(self, sell_rec):
		sell_rec = db.InsertSellRecord(sell_rec)
		row      = self.m_grid1.GetNumberRows()
		self.SetSellTableRow(row - 1, sell_rec)
		self.m_grid1.AppendRows()
		self.m_grid1.AutoSize()

	def OnModifySellRecord(self, event):
		print "OnModifySellRecord called! "

	def OnDeleteSellRecord(self, event):
		print "OnDeleteSellRecord called! "

	def SetSellTableRow(self, row_num, sell_rec):
		"""根据sell_rec设置售出表格的第row_num行的数据"""
		category = models.ALL_PRODUCT_TYPE2[sell_rec.product_class]
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_UID, str(sell_rec.uid))
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_PRODUCT_CLASS, category)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_PRODUCT_TYPE, sell_rec.product_type)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_BUYER, sell_rec.buyer_name)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_UNIT_PRICE, sell_rec.deal_unit_price)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_AMOUNT, sell_rec.amount)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_TOTAL_PRICE, sell_rec.total_price)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_DEAL_PRICE, sell_rec.deal_price)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_PAID, sell_rec.paid)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_UNPAY, sell_rec.unpaid)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_DEAL_DATE, sell_rec.deal_date)

		if float(sell_rec.unpaid) >= 0.001:
			self.m_grid1.SetCellTextColour(row_num, ENUM_SELL_UNPAY, wx.RED)


app = wx.App(redirect=False)   # Error messages go to popup window
top = MyFrame(None)
top.Show()
app.MainLoop()