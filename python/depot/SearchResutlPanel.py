# -*- coding: utf-8 -*- 
# 售出记录的查询结果面板
from DepotWindows import SearchResutlPanel
import gui_util, db, wx, models
from common import *

from numpy import arange, sin, pi
import matplotlib
matplotlib.use('WXAgg')
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
from matplotlib.backends.backend_wx import NavigationToolbar2Wx
from matplotlib.figure import Figure
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties

# font = FontProperties(fname=r"c:\\windows\\fonts\\simsun.ttc", size=14) 

class MySearchResutlPanel(SearchResutlPanel):
	def __init__(self, parent, begin_date, end_date, search_type, search_args = None):
		super(MySearchResutlPanel, self).__init__(parent)
		# page0: 为查询结果
		# page1: 为报表
		self.m_notebook2.RemovePage(1) # 先隐藏报表panel
		
		if search_type == SEARCH_TYPE_TOTAL:
			search_cond = u"从%s到%s之间的所有交易记录" % (begin_date, end_date)
		elif search_type == SEARCH_TYPE_PRODUCT:
			(category, type_list) = search_args
			search_cond = u"从%s到%s之间，产品%s中型号为%s的所有交易记录" % \
							(begin_date, end_date, category, u"、".join(type_list))
		elif search_type == SEARCH_TYPE_BUYER:
			search_cond = u"todo"
		else:
			search_cond = "todo"
		self.m_staticText14.SetLabel(search_cond)

		gui_util.InitSellRecordTab(self.m_grid2)
		self.search_results = self.DoSearch(begin_date, end_date, search_type, search_args)

		row_count = 0
		for sell_uid in sorted(self.search_results.keys()):
			rec = self.search_results[sell_uid]
			self.m_grid2.AppendRows()
			gui_util.SetSellTableRow(self.m_grid2, row_count, rec)
			row_count = row_count + 1
		self.m_grid2.AppendRows(1, True)
		self.m_grid2.AutoSize()

		total        = 0
		total_paid   = 0
		total_unpaid = 0
		for sell_rec in self.search_results.values():
			total        = total + float(sell_rec.deal_price)
			total_paid   = total_paid + float(sell_rec.paid)
			total_unpaid = total_unpaid + float(sell_rec.unpaid)
		msg = u"汇总信息：\n\t一共%d条记录，总交易额为：%.1f，总收款：%.1f，总欠款：%.1f" % \
				(len(self.search_results), total, total_paid, total_unpaid)
		self.m_staticText11.SetLabel(msg)

		self.Layout()
		# self.Fit()

	def DoSearch(self, begin_date, end_date, search_type, search_args):
		if search_type == SEARCH_TYPE_TOTAL:
			return db.QuerySellsByDate(begin_date, end_date)

	def OnGenerateReport(self, event):
		m_panel28 = wx.Panel( self.m_notebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
		self.m_notebook2.AddPage( m_panel28, u"报表", True )

		panel        = m_panel28
		panel.SetBackgroundColour(wx.NamedColour("WHITE"))
		
		panel.figure = Figure()
		panel.axes   = panel.figure.add_subplot(111)
		
		deal_prices = {}
		for category in models.ALL_PRODUCT_TYPE2.keys():
			deal_prices[category] = 0
		for sell_rec in self.search_results.values():
			deal_prices[sell_rec.product_class] = deal_prices[sell_rec.product_class] + float(sell_rec.deal_price)
		self.labels = []
		self.sizes  = []
		self.colors = []
		for category in deal_prices.keys():
			self.labels.append(models.ALL_PRODUCT_TYPE2[category])
			self.sizes.append(deal_prices[category])
			self.colors.append(models.PRODUCT_COLORS[category])
		# explode      = (0, 0, 0, 0) # only "explode" the 2nd slice (i.e. 'Hogs')
		panel.axes.pie(self.sizes, labels=self.labels, colors=self.colors, 
					   autopct='%1.1f%%', shadow=True, startangle=90)
		# Set aspect ratio to be equal so that pie is drawn as a circle.
		panel.axes.axis('equal')
		panel.canvas = FigureCanvas(panel, -1, panel.figure)

		panel.sizer = wx.BoxSizer(wx.VERTICAL)
		panel.sizer.Add(panel.canvas, 1, wx.ALL|wx.EXPAND)
		panel.SetSizer(panel.sizer)
		panel.Layout()

		self.Layout()

