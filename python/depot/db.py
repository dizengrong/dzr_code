# -*- coding: utf-8 -*- 
# 数据操作层

import sqlite3


# 售出数据表格的右键菜单
SELL_TAB_CONTEXT_MENU = [(wx.NewId(), u"添加", "OnAddSellRecord"),
						 (wx.NewId(), u"修改", "OnModifySellRecord"),
						 (wx.NewId(), u"删除", "OnDeleteSellRecord"),
						]

# 查询所有售出记录的sql语句
SQL_SELECT_SELLS = "select sell_record.uid, product_class, product_type, " \
				   "deal_unit_price, amount, buyer, deal_price, deal_date, paid, " \
				   "buyer_name from sell_record, buyer where sell_record.buyer = buyer.uid"
# 查询所有的产品信息
SQL_ALL_PRODUCT_TYPE = "select class, type, length, width, height, per_weight, price from product"
# 查询所有的买家
SQL_ALL_BUYERS = "SELECT uid, buyer_name, phone1, phone2, phone3, email FROM buyer"


db_conn = sqlite3.connect("depot.sqlite")


def GetAllSellRecords():
	db_cur    = db_conn.cursor()
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
		all_sells[uid] = rec
		self.m_grid1.AppendRows()

		self.SetSellTableRow(row_count, rec)
		row_count = row_count + 1