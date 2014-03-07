# -*- coding: utf-8 -*- 
# 数据操作层

import sqlite3, models, datetime
from models import SellRecord, Product, Buyer

# 查询所有售出记录的sql语句
SQL_SELECT_SELLS = "select sell_record.uid, product_class, product_type, " \
				   "deal_unit_price, amount, buyer, deal_price, deal_date, paid, " \
				   "buyer_name from sell_record, buyer where sell_record.buyer = buyer.uid order by sell_record.uid"
# 插入售出记录
SQL_INSERT_SELL = "insert into sell_record (product_class, product_type, " \
				  "deal_unit_price, amount, buyer, deal_price, paid, deal_date) VALUES" \
				  "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')"

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
		rec.uid             = str(row[0])
		rec.product_class   = str(row[1])
		rec.product_type    = row[2]
		rec.deal_unit_price = str(row[3])
		rec.amount          = str(row[4])
		rec.buyer           = str(row[5])
		rec.deal_price      = str(row[6])
		rec.deal_date       = row[7] # datetime.datetime.strptime(row[7], "%Y-%m-%d").strftime("%Y-%m-%d")
		rec.paid            = str(row[8])
		rec.buyer_name      = row[9]
		
		rec.total_price     = str(float(rec.deal_unit_price) * float(rec.amount))
		rec.unpaid          = str(float(rec.deal_price) - float(rec.paid))
		all_sells[rec.uid]  = rec

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
		rec.category   = str(row[0])
		rec.type       = row[1]
		rec.length     = str(row[2])
		rec.width      = str(row[3])
		rec.height     = str(row[4])
		rec.per_weight = str(row[5])
		rec.price      = str(row[6])
		all_products[rec.category][rec.type] = rec
	return all_products

def GetAllBuyers():
	"""获取所有的买家数据"""
	db_cur    = db_conn.cursor()
	db_cur.execute(SQL_ALL_BUYERS)
	all_buyers = {}
	for row in db_cur:
		rec            = Buyer()
		rec.uid        = str(row[0])
		rec.buyer_name = row[1]
		rec.phone1     = row[2]
		rec.phone2     = row[3]
		rec.phone3     = row[4]
		rec.email      = row[5]

		all_buyers[rec.buyer_name] = rec
	return all_buyers

def InsertSellRecord(sell_rec):
	db_cur = db_conn.cursor()
	print(type(sell_rec.deal_date))
	sql = SQL_INSERT_SELL % (sell_rec.product_class, 
							 sell_rec.product_type,
							 sell_rec.deal_unit_price,
							 sell_rec.amount,
							 sell_rec.buyer,
							 sell_rec.deal_price,
							 sell_rec.paid,
							 sell_rec.deal_date
							 )
	db_cur.execute(sql)
	db_conn.commit()
	db_cur = db_conn.cursor()
	db_cur.execute("select max(uid) from sell_record")
	sell_rec.uid = db_cur.next()[0]
	return sell_rec
