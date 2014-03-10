# -*- coding: utf-8 -*- 
# 数据模型class

# 所有的产品class
ALL_PRODUCT_TYPE  = {u"木板":'1', u"白膜":'2', u"蜂窝纸":'3'}
ALL_PRODUCT_TYPE2 = {'1':u"木板", '2':u"白膜", '3':u"蜂窝纸"}
ALL_PRODUCT_PRICE = {'1':0, '2':0, '3':0}
PRODUCT_COLORS    = {'1':'yellowgreen', '2':'gold', '3':'lightskyblue'}


class SellRecord(object):
	"""售出记录类"""
	def __init__(self):
		super(SellRecord, self).__init__()
		self.uid             = None 	# 交易号
		self.product_class   = None 	# 产品分类
		self.product_type    = None 	# 产品型号
		self.deal_unit_price = None 	# 成交的单价
		self.amount          = None 	# 成交数量
		self.buyer           = None 	# 买家uid
		self.buyer_name      = None 	# 买家名称
		self.total_price     = None 	# 计算所得总价
		self.deal_price      = None 	# 实际成交总价
		self.deal_date       = None 	# 成交日期
		self.paid            = None 	# 已收款
		self.unpaid          = None 	# 剩余欠款

class Product(object):
	"""产品原型数据类"""
	def __init__(self):
		super(Product, self).__init__()
		self.category   = None
		self.type       = None
		self.length     = None
		self.width      = None
		self.height     = None
		self.per_weight = None
		self.price      = None
		
class Buyer(object):
	"""买家数据类"""
	def __init__(self):
		super(Buyer, self).__init__()
		self.uid        = None
		self.buyer_name = None
		self.phone1     = None
		self.phone2     = None
		self.phone3     = None
		self.email      = None

