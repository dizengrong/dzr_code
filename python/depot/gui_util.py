# -*- coding: utf-8 -*- 
import models, wx

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


def InitSellRecordTab(grid):
	grid.AppendCols(ENUM_SELL_DEAL_DATE + 1, True)

	grid.SetColLabelValue(ENUM_SELL_UID, u'交易id')
	grid.SetColLabelValue(ENUM_SELL_PRODUCT_CLASS, u'产品分类')
	grid.SetColLabelValue(ENUM_SELL_PRODUCT_TYPE, u'产品型号')
	grid.SetColLabelValue(ENUM_SELL_BUYER, u'买家')
	grid.SetColLabelValue(ENUM_SELL_UNIT_PRICE, u'成交的单价')
	grid.SetColLabelValue(ENUM_SELL_AMOUNT, u'成交数量')
	grid.SetColLabelValue(ENUM_SELL_TOTAL_PRICE, u'计算所得总价')
	grid.SetColLabelValue(ENUM_SELL_DEAL_PRICE, u'实际成交总价')
	grid.SetColLabelValue(ENUM_SELL_PAID, u'已收款')
	grid.SetColLabelValue(ENUM_SELL_UNPAY, u'剩余欠款')
	grid.SetColLabelValue(ENUM_SELL_DEAL_DATE, u'成交日期')

def SetSellTableRow(grid, row_num, sell_rec):
		"""根据sell_rec设置售出表格的第row_num行的数据"""
		category = models.ALL_PRODUCT_TYPE2[sell_rec.product_class]
		grid.SetCellValue(row_num, ENUM_SELL_UID, str(sell_rec.uid))
		grid.SetCellValue(row_num, ENUM_SELL_PRODUCT_CLASS, category)
		grid.SetCellValue(row_num, ENUM_SELL_PRODUCT_TYPE, sell_rec.product_type)
		grid.SetCellValue(row_num, ENUM_SELL_BUYER, sell_rec.buyer_name)
		grid.SetCellValue(row_num, ENUM_SELL_UNIT_PRICE, sell_rec.deal_unit_price)
		grid.SetCellValue(row_num, ENUM_SELL_AMOUNT, sell_rec.amount)
		grid.SetCellValue(row_num, ENUM_SELL_TOTAL_PRICE, sell_rec.total_price)
		grid.SetCellValue(row_num, ENUM_SELL_DEAL_PRICE, sell_rec.deal_price)
		grid.SetCellValue(row_num, ENUM_SELL_PAID, sell_rec.paid)
		grid.SetCellValue(row_num, ENUM_SELL_UNPAY, sell_rec.unpaid)
		grid.SetCellValue(row_num, ENUM_SELL_DEAL_DATE, sell_rec.deal_date)

		if float(sell_rec.unpaid) >= 0.001:
			grid.SetCellTextColour(row_num, ENUM_SELL_UNPAY, wx.RED)
