# -*- coding: utf-8 -*- 
# 数据操作层

import sqlite3, models
from models import SellRecord, Product, Buyer


# 售出数据表格的右键菜单
SELL_TAB_CONTEXT_MENU = [(wx.NewId(), u"添加", "OnAddSellRecord"),
						 (wx.NewId(), u"修改", "OnModifySellRecord"),
						 (wx.NewId(), u"删除", "OnDeleteSellRecord"),
						]

# 查询所有售出记录的sql语句
SQL_SELECT_SELLS = "select sell_record.uid, product_class, product_type, " \
				   "deal_unit_price, amount, buyer, deal_price, deal_date, paid, " \
				   "buyer_name from sell_record, buyer where sell_record.buyer = buyer.uid"
# 插入售出记录
SQL_INSERT_SELL = "insert into sell_record (product_class, product_type, " \
				  "deal_unit_price, amount, buyer, deal_price, deal_date, paid, buyer_name) VALUES" \
				  "(%d, %d, %f, %d, %d, %f, %s, %f, %s)"

# 查询所有的产品信息
SQL_ALL_PRODUCT_TYPE = "select class, type, length, width, height, per_weight, price from product"
# 查询所有的买家
SQL_ALL_BUYERS = "SELECT uid, buyer_name, phone1, phone2, phone3, email FROM buyer"


db_conn = sqlite3.connect("depot.sqlite")


def GetAllSellRecords():
	"""获取所有的售出记录"""
	db_cur    = db_conn.cursor()
	db_cur.execute(SQL_SELECT_SELLS)
	all_sells = {}
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
		all_sells[uid]      = rec

	return all_sells

def GetAllProducts():
	"""获取所有的产品数据"""
	db_cur    = db_conn.cursor()
	db_cur.execute(SQL_ALL_PRODUCT_TYPE)
	all_products = {}
	for category in models.ALL_PRODUCT_TYPE.values():
		all_products[category] = {}
	for row in db_cur:
		rec            = Product()
		rec.category   = row[0]
		rec.type       = row[1]
		rec.length     = row[2]
		rec.width      = row[3]
		rec.height     = row[4]
		rec.per_weight = row[5]
		rec.price      = row[6]
		all_products[rec.category][rec.type] = rec
	return all_products


def GetAllBuyers():
	"""获取所有的买家数据"""
	db_cur    = db_conn.cursor()
	db_cur.execute(SQL_ALL_BUYERS)
	all_buyers = {}
	for row in db_cur:
		rec            = Buyer()
		rec.uid        = row[0]
		rec.buyer_name = row[1]
		rec.phone1     = row[2]
		rec.phone2     = row[3]
		rec.phone3     = row[4]
		rec.email      = row[5]

		all_buyers[rec.buyer_name] = rec
	return all_buyers

def InsertSellRecord(sell_rec):
