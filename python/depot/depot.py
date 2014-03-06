# -*- coding: utf-8 -*- 

import wx, sqlite3, models
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


# 控件说明：
#	m_grid1：主界面的售出数据表格	
class MyFrame(MainFrame):
	def __init__(self, parent):
		super(MyFrame, self).__init__(parent)
		self.all_sells = {}
		self.all_products = {}
		self.all_buyers = {}
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

		db_cur    = self.db_conn.cursor()
		db_cur.execute(SQL_SELECT_SELLS)
		row_count = 0
		for row in db_cur:
			rec                 = SellRecord()
			rec.uid             = row[0]
			rec.product_class   = row[1]
			rec.product_type    = row[2]
			rec.deal_unit_price = row[3]
			rec.amount          = row[4]
			rec.buyer           = row[5]
			rec.deal_price      = row[6]
			rec.deal_date       = row[7]
			rec.paid            = row[8]
			rec.buyer_name      = row[9]
			
			rec.total_price     = rec.deal_unit_price * rec.amount
			rec.unpaid          = rec.deal_price - rec.paid
			self.all_sells[uid] = rec
			self.m_grid1.AppendRows()

			self.SetSellTableRow(row_count, rec)
			row_count = row_count + 1

		if self.m_grid1.GetNumberRows() == 0:
			self.m_grid1.AppendRows(1, True)
			
	def __init__products(self):
		db_cur    = self.db_conn.cursor()
		db_cur.execute(SQL_ALL_PRODUCT_TYPE)
		for category in models.ALL_PRODUCT_TYPE.values():
			self.all_products[category] = {}
		for row in db_cur:
			rec            = Product()
			rec.category   = row[0]
			rec.type       = row[1]
			rec.length     = row[2]
			rec.width      = row[3]
			rec.height     = row[4]
			rec.per_weight = row[5]
			rec.price      = row[6]
			self.all_products[rec.category][rec.type] = rec

	def __init_buyers(self):
		db_cur    = self.db_conn.cursor()
		db_cur.execute(SQL_ALL_BUYERS)
		for row in db_cur:
			rec            = Buyer()
			rec.uid        = row[0]
			rec.buyer_name = row[1]
			rec.phone1     = row[2]
			rec.phone2     = row[3]
			rec.phone3     = row[4]
			rec.email      = row[5]

			self.all_buyers[rec.buyer_name] = rec

	def OnCellRightClick(self, event):
		menu = wx.Menu() 
		for id, title, action in SELL_TAB_CONTEXT_MENU:
			it = wx.MenuItem(menu, id, title)
			menu.AppendItem(it)
			self.Bind(wx.EVT_MENU, getattr(self, action), it) 
		self.PopupMenu(menu) 
		
		menu.Destroy()

	def OnAddSellRecord(self, event):
		dlg = MyDlgAddSell(self, self.db_conn, self.all_products, self.all_buyers)
		if dlg.ShowModal() == wx.ID_OK:
			rec = dlg.GetSellRecord()
			self.AddSellRecord(rec)
		dlg.Destroy()


	def OnModifySellRecord(self, event):
		print "OnModifySellRecord called! "

	def OnDeleteSellRecord(self, event):
		print "OnDeleteSellRecord called! "

	def SetSellTableRow(self, row_num, sell_rec):
		"""根据sell_rec设置售出表格的第row_num行的数据"""
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_UID, sell_rec.uid)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_PRODUCT_CLASS, sell_rec.product_class)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_PRODUCT_TYPE, sell_rec.product_type)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_BUYER, sell_rec.buyer_name)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_UNIT_PRICE, sell_rec.deal_unit_price)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_AMOUNT, sell_rec.amount)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_TOTAL_PRICE, sell_rec.total_price)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_DEAL_PRICE, sell_rec.deal_price)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_PAID, sell_rec.paid)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_UNPAY, sell_rec.unpaid)
		self.m_grid1.SetCellValue(row_num, ENUM_SELL_DEAL_DATE, sell_rec.deal_date)


app = wx.App(redirect=False)   # Error messages go to popup window
top = MyFrame(None)
top.Show()
app.MainLoop()