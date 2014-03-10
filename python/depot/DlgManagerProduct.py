# -*- coding: utf-8 -*- 
# 管理产品数据的界面

import db, models, wx
from DepotWindows import DlgManagerProduct  
import  wx.grid as gridlib
from models import Product

class MyDlgManagerProduct(DlgManagerProduct):
	def __init__(self):
		super(MyDlgManagerProduct, self).__init__(None)
		
		self.new_products = {}
		self.change_rows  = {}
		self.m_grid5.AppendCols(7, True)
		self.m_grid5.SetColLabelValue(0, u'产品分类')
		self.m_grid5.SetColLabelValue(1, u'产品型号')
		self.m_grid5.SetColLabelValue(2, u'长（毫米）')
		self.m_grid5.SetColLabelValue(3, u'宽（毫米）')
		self.m_grid5.SetColLabelValue(4, u'高（毫米）')
		self.m_grid5.SetColLabelValue(5, u'每立方米重量kg/m³')
		self.m_grid5.SetColLabelValue(6, u'单价')

		self.all_products = db.GetAllProducts()
		row_num = 0
		for category in sorted(self.all_products.keys()):
			for product_type in sorted(self.all_products[category].keys()):
				self.m_grid5.AppendRows()
				rec = self.all_products[category][product_type]
				self.m_grid5.SetCellValue(row_num, 0, models.ALL_PRODUCT_TYPE2[rec.category])
				self.m_grid5.SetCellValue(row_num, 1, rec.type)
				self.m_grid5.SetCellValue(row_num, 2, rec.length)
				self.m_grid5.SetCellValue(row_num, 3, rec.width)
				self.m_grid5.SetCellValue(row_num, 4, rec.height)
				self.m_grid5.SetCellValue(row_num, 5, rec.per_weight)
				self.m_grid5.SetCellValue(row_num, 6, rec.price)

				self.m_grid5.SetReadOnly(row_num, 0, True)
				self.m_grid5.SetReadOnly(row_num, 1, True)
				self.m_grid5.SetCellBackgroundColour(row_num, 0, wx.CYAN)
				self.m_grid5.SetCellBackgroundColour(row_num, 1, wx.CYAN)
				
				row_num = row_num + 1

		for x in xrange(1,11):
			self.AddBlankRow()
		self.m_grid5.AutoSize()
		# 重新自适应布局
		self.Fit() 


	def AddBlankRow(self):
		self.m_grid5.AppendRows()
		row_num = self.m_grid5.GetNumberRows()
		# self.m_grid5.SetReadOnly(row_num - 1, 0, True)
		# self.m_grid5.SetReadOnly(row_num - 1, 1, True)
		editor1 = gridlib.GridCellChoiceEditor(models.ALL_PRODUCT_TYPE.keys(), allowOthers=False)
		self.m_grid5.SetCellEditor(row_num - 1, 0, editor1)

	def OnCellChange(self, event):
		row = event.GetRow()
		col = event.GetCol()
		category = self.m_grid5.GetCellValue(row, 0)
		if col == 0: # 增加新的产品
			if not self.new_products.has_key(row):
				self.new_products[row] = True
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
			row                = int(row)
			product            = Product()
			product.category   = models.ALL_PRODUCT_TYPE[self.m_grid5.GetCellValue(row, 0)]
			product.type       = self.m_grid5.GetCellValue(row, 1)
			product.length     = self.m_grid5.GetCellValue(row, 2)
			product.width      = self.m_grid5.GetCellValue(row, 3)
			product.height     = self.m_grid5.GetCellValue(row, 4)
			product.per_weight = self.m_grid5.GetCellValue(row, 5)
			product.price      = self.m_grid5.GetCellValue(row, 6)
			db.UpdateProduct(product)
		for new_row in self.new_products.keys():
			product            = Product()
			product.category   = models.ALL_PRODUCT_TYPE[self.m_grid5.GetCellValue(row, 0)]
			product.type       = self.m_grid5.GetCellValue(new_row, 1)
			product.length     = self.m_grid5.GetCellValue(new_row, 2)
			product.width      = self.m_grid5.GetCellValue(new_row, 3)
			product.height     = self.m_grid5.GetCellValue(new_row, 4)
			product.per_weight = self.m_grid5.GetCellValue(new_row, 5)
			product.price      = self.m_grid5.GetCellValue(new_row, 6)
			db.InsertProduct(product)

	def OnCancelBtnClick(self, event):
		if len(self.change_rows) > 0 or len(self.new_products) > 0:
			dlg = wx.MessageDialog(self, u"有数据改动了，是否要保存？", u"提示", wx.OK|wx.CANCEL)
			if dlg.ShowModal() == wx.ID_OK :
				self.SaveChanges()
			dlg.Destroy()
		event.Skip()