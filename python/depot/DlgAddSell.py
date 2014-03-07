# -*- coding: utf-8 -*- 
# 添加售出记录的对话框界面

from DepotWindows import DlgAddSell
import models, wx, sqlite3, db
from models import SellRecord
from DlgBuyerManager import MyDlgBuyerManager

# 控件说明：
#	m_choice8：界面的产品分类选择框	
#	m_choice2：界面的产品型号选择框	
#	m_choice3：界面的买家选择框	
#	m_textCtrl6：界面的出售数量控件	
#	m_textCtrl8：界面的出售单价控件	
# 	m_staticText24：界面的出售总价label
# 	m_textCtrl10：界面的成交总价控件
# 	m_textCtrl11：界面的已收款控件
# 	m_staticText39：界面的欠款label
# 	m_datePicker3：界面的出售日期控件
class MyDlgAddSell(DlgAddSell):
	def __init__(self):
		super(MyDlgAddSell, self).__init__(None)
		self.all_products = db.GetAllProducts()
		self.m_choice8.AppendItems(models.ALL_PRODUCT_TYPE.keys())
		self.m_staticText24.SetLabel("")
		self.all_buyers = db.GetAllBuyers()
		self.m_choice3.AppendItems(self.all_buyers.keys())

	def OnProductClassChoice(self, event):
		category_str = self.m_choice8.GetStringSelection()
		category_int = models.ALL_PRODUCT_TYPE[category_str]
		self.m_choice2.Clear()
		self.m_choice2.AppendItems(self.all_products[category_int].keys())

	def OnMangerBuyers(self, event):
		dlg = MyDlgBuyerManager()
		if dlg.ShowModal() == wx.ID_OK:
			rec = dlg.GetSellRecord()
			self.InsertSellRecord(rec)
		dlg.Destroy()

	def OnSellNumTextChange(self, event):
		self.OnTextChange(event)

	def OnUnitPriceTextChange(self, event):
		self.OnTextChange(event)

	def OnDealPriceTextChange(self, event):
		self.OnTextChange(event)

	def OnPaidTextChange(self, event):
		self.OnTextChange(event)

	def OnTextChange(self, event):
		key_code = event.GetKeyCode()
		char = chr(key_code)
		if key_code == wx.WXK_BACK or chr(key_code).isdigit():
			event.Skip()
			wx.CallAfter(self.UpdateUI)

	def UpdateUI(self):
		amount     = self.m_textCtrl6.GetValue()
		unit_price = self.m_textCtrl8.GetValue()
		if amount != "" and unit_price != "":
			self.m_staticText24.SetLabel(str(float(unit_price) * float(amount)))

		paid       = self.m_textCtrl11.GetValue()
		deal_price = self.m_textCtrl10.GetValue()
		if paid != "" and deal_price != "":
			self.m_staticText39.SetLabel(str(float(deal_price) - float(paid)))

	def OnOkBtnClick(self, event):
		if self.m_choice2.GetSelection() == wx.NOT_FOUND or \
		   self.m_choice8.GetSelection() == wx.NOT_FOUND or \
		   self.m_choice3.GetSelection() == wx.NOT_FOUND or \
		   self.m_textCtrl8.GetValue() == "" or \
		   self.m_textCtrl6.GetValue() == "" or \
		   self.m_textCtrl10.GetValue() == "" or \
		   self.m_textCtrl11.GetValue() == "" :
			return
		event.Skip()

	def GetSellRecord(self):
		category_str        = self.m_choice8.GetStringSelection()
		category_int        = models.ALL_PRODUCT_TYPE[category_str]
		rec                 = SellRecord()
		rec.product_class   = category_int
		rec.product_type    = self.m_choice2.GetStringSelection()
		rec.deal_unit_price = self.m_textCtrl8.GetValue()
		rec.amount          = self.m_textCtrl6.GetValue()
		rec.deal_price      = self.m_textCtrl10.GetValue()
		rec.deal_date       = str(self.m_datePicker3.GetValue().Format("%Y-%m-%d"))
		rec.paid            = self.m_textCtrl11.GetValue()
		rec.buyer_name      = self.m_choice3.GetStringSelection()
		
		buyer               = self.all_buyers[rec.buyer_name]
		rec.buyer           = buyer.uid
		
		rec.total_price     = str(float(rec.deal_unit_price) * float(rec.amount))
		rec.unpaid          = str(float(rec.deal_price) - float(rec.paid))
		return rec