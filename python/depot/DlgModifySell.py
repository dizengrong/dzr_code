# -*- coding: utf-8 -*- 
# 修改售出记录的对话框界面

from DepotWindows import DlgModifySell
import models, wx, db
from DlgHistoryDeals import MyDlgHistoryDeals

# 控件说明：
# 	m_staticText42：产品分类
# 	m_staticText49：产品型号
# 	m_staticText50：买家
# 	m_staticText24：计算所得出售总价
# 	m_textCtrl6：出售数量
# 	m_textCtrl8：出售单价
# 	m_textCtrl10：成交总价
# 	m_textCtrl23：新增收款
# 	m_staticText43：已收款
# 	m_staticText44：欠款
# 	m_datePicker3：出售日期
class MyDlgModifySell(DlgModifySell):
	"""docstring for MyDlgModifySell"""
	def __init__(self, sell_rec):
		super(MyDlgModifySell, self).__init__(None)
		self.m_staticText42.SetLabel(models.ALL_PRODUCT_TYPE2[sell_rec.product_class])
		self.m_staticText49.SetLabel(sell_rec.product_type)
		self.m_staticText50.SetLabel(sell_rec.buyer_name)
		self.m_staticText24.SetLabel(sell_rec.total_price)
		self.m_textCtrl6.SetValue(sell_rec.amount)
		self.m_textCtrl8.SetValue(sell_rec.deal_unit_price)
		self.m_textCtrl10.SetValue(sell_rec.deal_price)
		self.m_staticText43.SetLabel(sell_rec.paid)
		self.m_staticText44.SetLabel(sell_rec.unpaid)
		self.m_textCtrl23.SetValue("0")
		date = wx.DateTime()
		date.ParseDate(sell_rec.deal_date)
		self.m_datePicker3.SetValue(date)

		history_sells = db.GetHistorySellsByBuyerName(sell_rec.buyer_name)
		if len(history_sells) > 0:
			self.m_button8.Enable(True)
			self.m_button8.SetLabel(u"点击查看")

		self.sell_rec = sell_rec
	
	def OnOKBtnClick(self, event):
		event.Skip()

	def OnTextChange(self, event):
		key_code = event.GetKeyCode()
		if key_code == wx.WXK_RIGHT or key_code == wx.WXK_LEFT:
			event.Skip()
			return
		if key_code == wx.WXK_BACK or key_code == ord('-') or key_code == ord('.') or chr(key_code).isdigit():
			event.Skip()
			wx.CallAfter(self.UpdateUI)

	def UpdateUI(self):
		amount = self.m_textCtrl6.GetValue()
		if amount == "":
			amount = 0
		unit_price = self.m_textCtrl8.GetValue()
		self.m_staticText24.SetLabel(str(float(unit_price) * float(amount)))

		add_paid   = self.m_textCtrl23.GetValue()
		new_paid   = float(self.sell_rec.paid) + float(add_paid)
		deal_price = self.m_textCtrl10.GetValue()
		unpaid     = float(deal_price) - float(self.sell_rec.paid)
		self.m_staticText43.SetLabel(self.sell_rec.paid + " + " + add_paid + " = " + str(new_paid))
		self.m_staticText44.SetLabel(str(unpaid) + " - " + add_paid + " = " + str(unpaid - float(add_paid)))

	def GetNewSellRecord(self):
		self.sell_rec.amount     = self.m_textCtrl6.GetValue()
		self.sell_rec.deal_price = self.m_textCtrl10.GetValue()
		self.sell_rec.paid       = str(float(self.sell_rec.paid) + float(self.m_textCtrl23.GetValue()))
		self.sell_rec.unpaid     = str(float(self.sell_rec.deal_price) - float(self.sell_rec.paid))
		self.sell_rec.deal_date  = str(self.m_datePicker3.GetValue().Format("%Y-%m-%d"))
		return self.sell_rec

	def OnQueryHistorySells(self, event):
		buyer_name = self.m_staticText50.GetLabel()
		dlg        = MyDlgHistoryDeals(buyer_name)
		dlg.ShowModal()
		dlg.Destroy()