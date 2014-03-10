# -*- coding: utf-8 -*- 
# 管理买家数据的界面

import models, wx, sqlite3, db
from DepotWindows import DlgBuyerManager
from models import Buyer


class MyDlgBuyerManager(DlgBuyerManager):
	def __init__(self):
		super(MyDlgBuyerManager, self).__init__(None)
		self.change_rows = {}
		self.new_buyers  = {}

		self.m_grid5.AppendCols(6, True)
		self.m_grid5.SetColLabelValue(0, u'买家id')
		self.m_grid5.SetColLabelValue(1, u'买家名称（或公司名）')
		self.m_grid5.SetColLabelValue(2, u'联系电话1')
		self.m_grid5.SetColLabelValue(3, u'联系电话2')
		self.m_grid5.SetColLabelValue(4, u'联系电话3')
		self.m_grid5.SetColLabelValue(5, u'邮件')

		self.all_buyers = db.GetAllBuyers()
		row_num = 0
		for rec in self.all_buyers:
			self.m_grid5.AppendRows()
			self.m_grid5.SetCellValue(row_num, 0, rec.uid)
			self.m_grid5.SetCellValue(row_num, 1, rec.buyer_name)
			self.m_grid5.SetCellValue(row_num, 2, rec.phone1)
			self.m_grid5.SetCellValue(row_num, 3, rec.phone2)
			self.m_grid5.SetCellValue(row_num, 4, rec.phone3)
			self.m_grid5.SetCellValue(row_num, 5, rec.email)

			self.m_grid5.SetReadOnly(row_num, 0, True)
			row_num = row_num + 1

		self.AddBlankRow()
		self.m_grid5.AutoSize()
		# 重新自适应布局
		self.Fit() 

	def AddBlankRow(self):
		self.m_grid5.AppendRows()
		row_num = self.m_grid5.GetNumberRows()
		self.m_grid5.SetReadOnly(row_num - 1, 0, True)

	def OnCellChange(self, event):
		row = event.GetRow()
		uid = self.m_grid5.GetCellValue(row, 0)
		if uid == u"": # 增加新的买家
			if not self.new_buyers.has_key(row):
				self.new_buyers[row] = True
				self.AddBlankRow()
		else:
			self.change_rows[str(row)] = True
		
		wx.CallAfter(self.UpdateUI)

	def UpdateUI(self):
		self.m_grid5.AutoSize()
		self.Fit()
		self.Layout()

	def OnOKBtnClick(self, event):
		self.SaveChanges()
		event.Skip()

	def SaveChanges(self):
		for row in self.change_rows.keys():
			row              = int(row)
			buyer            = Buyer()
			buyer.uid        = self.m_grid5.GetCellValue(row, 0)
			buyer.buyer_name = self.m_grid5.GetCellValue(row, 1)
			buyer.phone1     = self.m_grid5.GetCellValue(row, 2)
			buyer.phone2     = self.m_grid5.GetCellValue(row, 3)
			buyer.phone3     = self.m_grid5.GetCellValue(row, 4)
			buyer.email      = self.m_grid5.GetCellValue(row, 5)
			db.UpdateBuyer(buyer)
		for new_row in self.new_buyers.keys():
			buyer            = Buyer()
			buyer.buyer_name = self.m_grid5.GetCellValue(new_row, 1)
			buyer.phone1     = self.m_grid5.GetCellValue(new_row, 2)
			buyer.phone2     = self.m_grid5.GetCellValue(new_row, 3)
			buyer.phone3     = self.m_grid5.GetCellValue(new_row, 4)
			buyer.email      = self.m_grid5.GetCellValue(new_row, 5)
			db.InsertBuyer(buyer)

	def OnCancelBtnClick(self, event):
		if len(self.change_rows) > 0 or len(self.new_buyers) > 0:
			dlg = wx.MessageDialog(self, u"有数据改动了，是否要保存？", u"提示", wx.OK|wx.CANCEL)
			if dlg.ShowModal() == wx.ID_OK :
				self.SaveChanges()
			dlg.Destroy()
		event.Skip()
