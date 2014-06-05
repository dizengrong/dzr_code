# -*- coding: utf-8 -*- 
# 售出记录的查询结果面板
from DepotWindows import SearchResutlPanel
import gui_util, db, wx, models, xlwt, os
from common import *
from gui_util import *

from matplotlib.ticker import FuncFormatter
from numpy import arange, sin, pi
import matplotlib, numpy
matplotlib.use('WXAgg')
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
# matplotlib.use('WX')
# from matplotlib.backends.backend_wx import FigureCanvasWx as FigureCanvas
from matplotlib.backends.backend_wx import NavigationToolbar2Wx
from matplotlib.figure import Figure
import matplotlib.pyplot as plt

from pylab import * 
mpl.rcParams['font.sans-serif'] = ['SimHei'] #指定默认字体 
mpl.rcParams['axes.unicode_minus'] = False #解决保存图像是负号'-'显示为方块的问题 

def InitPrices():
	deal_prices = {}
	for category in models.ALL_PRODUCT_TYPE2.keys():
		deal_prices[category] = 0
	return deal_prices

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
			buyer       = search_args
			search_cond = u"从%s到%s之间，与买家%s的所有交易记录" % (begin_date, end_date, buyer)

		self.m_staticText14.SetLabel(search_cond)

		gui_util.InitSellRecordTab(self.m_grid2)
		self.search_type    = search_type
		self.search_args    = search_args
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

		if len(self.search_results) > 0:
			self.m_button9.Enable(True)
			self.m_button10.Enable(True)
		else:
			self.m_button9.Enable(False)
			self.m_button10.Enable(False)

		self.Layout()
		self.Fit()

	def OnExport2Excel(self, event):
		dirname = ''
		dlg = wx.FileDialog(self, "Save file", dirname, "", "Excel Files (*.xls)|*.xls|All Files (*.*)|*.*||", wx.SAVE)
		if dlg.ShowModal() == wx.ID_OK:
			filename = dlg.GetFilename()
			dirname  = dlg.GetDirectory()
			#新建一个excel文件
			fd = xlwt.Workbook() 
			#新建一个sheet
			table = fd.add_sheet(u'报表', cell_overwrite_ok=True)

			table.write(0, ENUM_SELL_UID, u"售出记录uid")
			table.write(0, ENUM_SELL_PRODUCT_CLASS, u"产品分类")
			table.write(0, ENUM_SELL_PRODUCT_TYPE, u"产品型号")
			table.write(0, ENUM_SELL_BUYER, u"买家")
			table.write(0, ENUM_SELL_UNIT_PRICE, u"成交的单价")
			table.write(0, ENUM_SELL_AMOUNT, u"成交数量")
			table.write(0, ENUM_SELL_TOTAL_PRICE, u"计算所得总价")
			table.write(0, ENUM_SELL_DEAL_PRICE, u"实际成交总价")
			table.write(0, ENUM_SELL_PAID, u"已收款")
			table.write(0, ENUM_SELL_UNPAY, u"剩余欠款")
			table.write(0, ENUM_SELL_DEAL_DATE, u"成交日期")
			row = 1
			for sell_rec in self.search_results.values():
				category = models.ALL_PRODUCT_TYPE2[sell_rec.product_class]
				table.write(row, ENUM_SELL_UID, int(sell_rec.uid))
				table.write(row, ENUM_SELL_PRODUCT_CLASS, category)
				table.write(row, ENUM_SELL_PRODUCT_TYPE, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_PRODUCT_TYPE))
				table.write(row, ENUM_SELL_BUYER, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_BUYER))
				table.write(row, ENUM_SELL_UNIT_PRICE, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_UNIT_PRICE))
				table.write(row, ENUM_SELL_AMOUNT, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_AMOUNT))
				table.write(row, ENUM_SELL_TOTAL_PRICE, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_TOTAL_PRICE))
				table.write(row, ENUM_SELL_DEAL_PRICE, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_DEAL_PRICE))
				table.write(row, ENUM_SELL_PAID, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_PAID))
				table.write(row, ENUM_SELL_UNPAY, gui_util.GetSellFieldByCol(sell_rec, ENUM_SELL_UNPAY))
				table.write(row, ENUM_SELL_DEAL_DATE, sell_rec.deal_date)
				row += 1
			#保存文件
			fd.save(os.path.join(dirname, filename))
			
		dlg.Destroy()

	def DoSearch(self, begin_date, end_date, search_type, search_args):
		if search_type == SEARCH_TYPE_TOTAL:
			return db.QuerySellsByDate(begin_date, end_date)
		elif search_type == SEARCH_TYPE_PRODUCT:
			(category, type_list) = search_args
			category2 = models.ALL_PRODUCT_TYPE[category]
			return db.QuerySellsByProductType(begin_date, end_date, category2, type_list)
		elif search_type == SEARCH_TYPE_BUYER:
			buyer = search_args
			return db.QuerySellsWithBuyer(begin_date, end_date, buyer)

	def OnGenerateReport(self, event):
		self.m_notebook2.AddPage( self.m_panel28, u"报表", True )
		panel = self.m_panel28
		panel.SetBackgroundColour(wx.NamedColour("WHITE"))
		
		if self.search_type == SEARCH_TYPE_TOTAL:
			self.DrawTotalReport(panel)
		elif self.search_type == SEARCH_TYPE_PRODUCT:
			self.DrawProductReport(panel)
		elif self.search_type == SEARCH_TYPE_BUYER:
			self.DrawSelleWithBuyer(panel)

		panel.sizer = wx.BoxSizer(wx.VERTICAL)
		panel.sizer.Add(panel.canvas, 1, wx.ALL|wx.EXPAND)
		panel.SetSizer(panel.sizer)
		panel.Layout()

		self.Layout()

	def DrawTotalReport(self, panel):
		deal_prices = InitPrices()
		total       = 0.0
		paid        = 0.0
		for sell_rec in self.search_results.values():
			deal_prices[sell_rec.product_class] += float(sell_rec.deal_price)
			paid  += float(sell_rec.paid)
			total += float(sell_rec.deal_price)
		labels  = []
		sizes   = []
		colors  = []
		explode = []
		for category in deal_prices.keys():
			labels.append(models.ALL_PRODUCT_TYPE2[category])
			sizes.append(deal_prices[category])
			colors.append(models.PRODUCT_COLORS[category])
			explode.append(0.01)
			
		panel.figure = Figure()
		panel.figure.text(0, 0.97, None, text = self.m_staticText14.GetLabel(), color = 'b')
		# 第一块
		panel.axes   = panel.figure.add_subplot(1, 3, 1, axisbg = 'w', alpha=0.3)
		panel.axes.pie(sizes, labels=labels, explode=explode, colors=colors, autopct='%1.1f%%', shadow=True, startangle=90)
		# Set aspect ratio to be equal so that pie is drawn as a circle.
		panel.axes.axis('equal')
		panel.axes.set_title(u'各产品所占比例，总价：%.1f' % (total))
		# 第二块
		panel.axes2   = panel.figure.add_subplot(1, 3, 2, axisbg = 'r')
		panel.axes2.pie([paid, total - paid], labels=[u"已支付", u"未支付"], colors=['g', 'r'], autopct='%1.1f%%', shadow=True, startangle=90)
		# Set aspect ratio to be equal so that pie is drawn as a circle.
		panel.axes2.axis('equal')
		panel.axes2.set_title(u'收款与欠款比例，总价：%.1f' % (total))
		# 第三块
		all_total = db.GetTotalDealPrice()
		panel.axes3   = panel.figure.add_subplot(1, 3, 3, axisbg = 'g')
		panel.axes3.pie([total, all_total - total], labels=[u"查询部分", u"未查询部分"], colors=['g', 'r'], autopct='%1.1f%%', shadow=True, startangle=90)
		# Set aspect ratio to be equal so that pie is drawn as a circle.
		panel.axes3.axis('equal')
		panel.axes3.set_title(u'查询总价占全部交易的比例')


		panel.canvas = FigureCanvas(panel, -1, panel.figure)


	def DrawProductReport(self, panel):
		"""产品相关查询报表"""
		(category, type_list) = self.search_args
		deal_prices = {}
		for t in type_list:
			deal_prices[t] = 0
		for sell_rec in self.search_results.values():
			deal_prices[sell_rec.product_type] = deal_prices[sell_rec.product_type] + float(sell_rec.deal_price)
			
		labels = []
		sizes  = []
		colors = []
		index  = 0
		for product_type in deal_prices.keys():
			labels.append(product_type)
			sizes.append(deal_prices[product_type])
			colors.append(COLOUR_TAB[index])
			if index < len(COLOUR_TAB) - 1:
				index = index + 1

		panel.figure = Figure()
		panel.figure.text(0, 0.97, None, text = self.m_staticText14.GetLabel() + u"总额分布图", color = 'b')
		panel.axes   = panel.figure.add_subplot(111)
		# panel.axes.pie(sizes, labels=labels, colors=colors, autopct='%1.1f%%', shadow=True, startangle=90)
		# panel.axes.axis('equal')
		# x_array =     numpy.arange(start=0, stop = len(deal_prices)/2.0, step=0.5)
		x_array =     numpy.arange(len(deal_prices))
		# money = [1.5e5, 2.5e6, 5.5e6, 2.0e7]

		def millions(money, pos):
			'The two args are the value and tick position'
			return u'￥%0.1f' % (money)
		formatter = FuncFormatter(millions)
		panel.axes.yaxis.set_major_formatter(formatter)
		panel.axes.bar(x_array, sizes, width = 0.5, align = 'center', color = colors)
		panel.axes.set_xticks( x_array)
		panel.axes.set_xticklabels(labels)
		count = 0
		for x_pos in x_array:
			panel.axes.annotate(sizes[count], (x_pos, sizes[count]), va="bottom", ha="center")
			count += 1
		panel.canvas = FigureCanvas(panel, -1, panel.figure)
		# panel.figure.savefig('product_report.png')


	def DrawSelleWithBuyer(self, panel):
		"""与某买家在某段时间内的所有交易记录的报表"""
		panel.figure = Figure()
		panel.figure.text(0, 0.97, None, text = u"暂无", color = 'b')
		panel.canvas = FigureCanvas(panel, -1, panel.figure)
		
