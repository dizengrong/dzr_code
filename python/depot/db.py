# -*- coding: utf-8 -*- 
# 数据操作层

import sqlite3, models, datetime
from models import SellRecord, Product, Buyer

# 查询所有售出记录的sql语句
SQL_SELECT_SELLS = "select sell_record.uid, product_class, product_type, " \
				   "deal_unit_price, amount, buyer, deal_price, deal_date, paid, " \
				   "buyer.buyer_name from sell_record, buyer where sell_record.buyer = buyer.uid "
# 插入售出记录
SQL_INSERT_SELL = "insert into sell_record (product_class, product_type, " \
				  "deal_unit_price, amount, buyer, deal_price, paid, deal_date) VALUES" \
				  "('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')"
# 删除售出记录
SQL_DELETE_SELL = "delete from sell_record where uid = '%s'"
# 更新售出记录
SQL_UPDATE_SELL = "update sell_record set product_class = %s, product_type = '%s', " \
				  "deal_unit_price = %s, amount = %s, buyer = %s, deal_price = %s," \
				  "paid = %s, deal_date = '%s' where uid = %s" \
# 查询与某买家的历史交易
SQL_QUERY_SELLS_BY_NAME = SQL_SELECT_SELLS + " and buyer.buyer_name = '%s' order by sell_record.uid"
# 查询所有的产品信息
SQL_ALL_PRODUCT = "select class, type, length, width, height, per_weight, price from product order by class, type"
# 查询某个分类的产品有哪些型号
SQL_QUERY_PRODUCT_TYPES = "select type from product where class = %s"
# 插入产品数据
SQL_INSERT_PRODUCT = "insert into product (class, type, length, width, height, per_weight, price) VALUES "\
					 "(%s, '%s', %s, %s, %s, %s, %s)"
# 删除产品数据
SQL_DELETE_PRODUCT = "delete from product where class = %s and type = '%s'"
# 更新产品数据
SQL_UPDATE_PRODUCT = "update product set length = %s, width = %s, height = %s, per_weight = %s, price = %s " \
					 "where class = %s and type = '%s'"
# 查询所有的买家
SQL_ALL_BUYERS = "select uid, buyer_name, phone1, phone2, phone3, email from buyer order by uid"
#更新买家数据
SQL_UPDATE_BUYER = "update buyer set buyer_name = '%s', phone1 = '%s', phone2 = '%s', phone3 = '%s', email = '%s' where uid = %s"
# 插入买家信息
SQL_INSERT_BUYER = "insert into buyer (buyer_name, phone1, phone2, phone3, email) VALUES ('%s', '%s', '%s', '%s', '%s')"
# 获取所有售出记录的成交价的总和
SQL_TOTAL_DEAL_PRICE = "select sum(deal_price) as total from sell_record"
# 获取所有售出记录的已支付款的总和
SQL_TOTAL_PAID = "select sum(paid) as total from sell_record"

db_conn = sqlite3.connect("depot.sqlite")


def GetTotalDealPrice():
	"""获取所有售出记录的成交价的总和"""
	db_cur = db_conn.cursor()
	db_cur.execute(SQL_TOTAL_DEAL_PRICE)
	return db_cur.next()[0]

def GetTotalPaid():
	"""获取所有售出记录的已支付款的总和"""
	db_cur = db_conn.cursor()
	db_cur.execute(SQL_TOTAL_PAID)
	return db_cur.next()[0]

def GetAllSellRecords():
	"""获取所有的售出记录"""
	db_cur    = db_conn.cursor()
	db_cur.execute(SQL_SELECT_SELLS)
	all_sells = {}
	for row in db_cur:
		rec = SqlDatas2SellRecord(row)
		all_sells[rec.uid]  = rec

	return all_sells

def GetHistorySellsByBuyerName(buyer_name):
	db_cur = db_conn.cursor()
	sql    = SQL_QUERY_SELLS_BY_NAME % (buyer_name)
	db_cur.execute(sql)
	all_sells = {}
	for row in db_cur:
		rec = SqlDatas2SellRecord(row)
		all_sells[rec.uid]  = rec
	return all_sells

def QuerySellsByDate(begin_date, end_date):
	db_cur = db_conn.cursor()
	sql    = SQL_SELECT_SELLS + " and deal_date between '%s' and '%s'" % (begin_date, end_date)
	db_cur.execute(sql)
	all_sells = {}
	for row in db_cur:
		rec = SqlDatas2SellRecord(row)
		all_sells[rec.uid]  = rec
	return all_sells

def QuerySellsByProductType(begin_date, end_date, category, type_list):
	db_cur = db_conn.cursor()
	tmp = ", ".join(["'" + t + "'" for t in type_list])
	sql    = SQL_SELECT_SELLS + " and deal_date between '%s' and '%s'" % (begin_date, end_date) + \
			 " and product_class = %s and product_type in (%s)" % (category, tmp)
	db_cur.execute(sql)
	all_sells = {}
	for row in db_cur:
		rec = SqlDatas2SellRecord(row)
		all_sells[rec.uid]  = rec
	return all_sells

def QuerySellsWithBuyer(begin_date, end_date, buyer_name):
	"""查询与某买家在某段时间内的所有交易记录"""
	db_cur = db_conn.cursor()
	sql    = SQL_SELECT_SELLS + " and buyer_name = '%s' " % buyer_name + \
			 " and deal_date between '%s' and '%s'" % (begin_date, end_date)
	db_cur.execute(sql)
	all_sells = {}
	for row in db_cur:
		rec = SqlDatas2SellRecord(row)
		all_sells[rec.uid]  = rec
	return all_sells

def SqlDatas2SellRecord(datas):
	rec                 = SellRecord()
	rec.uid             = str(datas[0])
	rec.product_class   = str(datas[1])
	rec.product_type    = datas[2]
	rec.deal_unit_price = str(datas[3])
	rec.amount          = str(datas[4])
	rec.buyer           = str(datas[5])
	rec.deal_price      = str(datas[6])
	rec.deal_date       = datas[7] # datetime.datetime.strptime(datas[7], "%Y-%m-%d").strftime("%Y-%m-%d")
	rec.paid            = str(datas[8])
	rec.buyer_name      = datas[9]

	rec.total_price     = str(float(rec.deal_unit_price) * float(rec.amount))
	rec.unpaid          = str(float(rec.deal_price) - float(rec.paid))
	return rec

def GetAllProducts():
	"""获取所有的产品数据"""
	db_cur    = db_conn.cursor()
	db_cur.execute(SQL_ALL_PRODUCT)
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
	all_buyers = []
	for row in db_cur:
		rec            = Buyer()
		rec.uid        = str(row[0])
		rec.buyer_name = row[1]
		rec.phone1     = row[2]
		rec.phone2     = row[3]
		rec.phone3     = row[4]
		rec.email      = row[5]

		all_buyers.append(rec)
	return all_buyers

def GetBuyer(buyer_name, all_buyers):
	for buyer in all_buyers:
		if buyer.buyer_name == buyer_name:
			return buyer
	return None

def InsertSellRecord(sell_rec):
	db_cur = db_conn.cursor()
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

def DeleteSellRecord(sell_uid):
	db_cur = db_conn.cursor()
	sql    = SQL_DELETE_SELL % (sell_uid)
	db_cur.execute(sql)
	db_conn.commit()

def UpdateSellRecord(sell_rec):
	db_cur = db_conn.cursor()
	sql    = SQL_UPDATE_SELL % (sell_rec.product_class, 
								sell_rec.product_type, 
								sell_rec.deal_unit_price,
								sell_rec.amount,
								sell_rec.buyer,
								sell_rec.deal_price,
								sell_rec.paid,
								sell_rec.deal_date,
								sell_rec.uid)
	db_cur.execute(sql)
	db_conn.commit()



def UpdateBuyer(buyer_rec):
	db_cur = db_conn.cursor()
	sql    = SQL_UPDATE_BUYER % (buyer_rec.buyer_name, 
								 buyer_rec.phone1, 
								 buyer_rec.phone2,
								 buyer_rec.phone3,
								 buyer_rec.email,
								 buyer_rec.uid)
	db_cur.execute(sql)
	db_conn.commit()

def InsertBuyer(buyer_rec):
	db_cur = db_conn.cursor()
	sql    = SQL_INSERT_BUYER % (buyer_rec.buyer_name, 
								 buyer_rec.phone1, 
								 buyer_rec.phone2,
								 buyer_rec.phone3,
								 buyer_rec.email)
	db_cur.execute(sql)
	db_conn.commit()	

def InsertProduct(product_rec):
	db_cur = db_conn.cursor()
	sql    = SQL_INSERT_PRODUCT % (product_rec.category, 
								   product_rec.type, 
								   product_rec.length,
								   product_rec.width,
								   product_rec.height,
								   product_rec.per_weight,
								   product_rec.price)
	db_cur.execute(sql)
	db_conn.commit()

def DeleteProduct(product_rec):
	db_cur = db_conn.cursor()
	sql    = SQL_DELETE_PRODUCT % (product_rec.category, product_rec.type)
	db_cur.execute(sql)
	db_conn.commit()

def UpdateProduct(product_rec):
	db_cur = db_conn.cursor()
	sql    = SQL_UPDATE_PRODUCT % (product_rec.length,
								   product_rec.width,
								   product_rec.height,
								   product_rec.per_weight,
								   product_rec.price,
								   product_rec.category, 
								   product_rec.type)
	db_cur.execute(sql)
	db_conn.commit()

def QueryProductType(product_class):
	db_cur = db_conn.cursor()
	sql    = SQL_QUERY_PRODUCT_TYPES % (product_class)
	db_cur.execute(sql)
	types = []
	for row in db_cur:
		types.append(row)
	return types