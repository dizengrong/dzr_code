# -*- coding: utf-8 -*- 
# 与xxx买家的售出记录的对话框界面

import models, wx, db, gui_util
from DepotWindows import DlgHistoryDeals

class MyDlgHistoryDeals(DlgHistoryDeals):
	def __init__(self, buyer_name):
		super(MyDlgHistoryDeals, self).__init__(None)
		self.SetLabel(u"与【%s】的交易历史记录" % buyer_name)
		history_sells = db.GetHistorySellsByBuyerName(buyer_name)
		gui_util.InitSellRecordTab(self.m_grid4)

		row_count = 0
		for sell_uid in sorted(history_sells.keys()):
			rec = history_sells[sell_uid]
			self.m_grid4.AppendRows()
			gui_util.SetSellTableRow(self.m_grid4, row_count, rec)
			row_count = row_count + 1
		self.m_grid4.AppendRows(1, True)
		self.m_grid4.AutoSize()
		self.Fit()
		self.Layout()

		