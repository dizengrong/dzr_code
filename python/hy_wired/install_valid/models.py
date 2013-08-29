# -*- coding: utf8 -*-

from django.db import models

class User(models.Model):
	"""用户表结构"""
	user     = models.CharField(max_length = 100, primary_key=True)
	password = models.CharField(max_length = 100)
	priv     = models.IntegerField() #特权标志(0:普通, 1:管理员)

class DevONU(models.Model):
	"""ONU设备"""
	dev_id      = models.AutoField(primary_key=True)
	addr_1      = models.CharField(verbose_name = "一级点名称", max_length = 500)
	addr_2      = models.CharField(verbose_name = "二级点名称", max_length = 500)
	addr_detail = models.CharField(verbose_name = "安装详细地址", max_length = 500)
	dev_name    = models.CharField(verbose_name = "设备名称", max_length = 100)
	mac_addr    = models.CharField(verbose_name = "MAC地址", max_length = 100)
	port_remark = models.CharField(verbose_name = "端口备注", max_length = 500)

class DevONU_TMP(models.Model):
	"""等待验收的ONU设备"""
	dev_id      = models.AutoField(primary_key=True)
	addr_1      = models.CharField(verbose_name = "一级点名称", max_length = 500)
	addr_2      = models.CharField(verbose_name = "二级点名称", max_length = 500)
	addr_detail = models.CharField(verbose_name = "安装详细地址", max_length = 500)
	dev_name    = models.CharField(verbose_name = "设备名称", max_length = 100)
	mac_addr    = models.CharField(verbose_name = "MAC地址", max_length = 100)
	port_remark = models.CharField(verbose_name = "端口备注", max_length = 500)

class DevEOC(models.Model):
	"""基带EOC设备"""
	dev_id          = models.AutoField(primary_key=True)
	addr_1          = models.CharField(verbose_name = "一级点名称", max_length = 500)
	addr_2          = models.CharField(verbose_name = "二级点名称", max_length = 500)
	addr_detail     = models.CharField(verbose_name = "安装详细地址", max_length = 500)
	line_box_type   = models.IntegerField(verbose_name = "配线箱类型")
	dev_box_type    = models.CharField(verbose_name = "设备箱类型", max_length = 100)
	dev_type        = models.CharField(verbose_name = "设备类型", max_length = 100)
	cover_users     = models.IntegerField(verbose_name = "覆盖用户数")
	model           = models.IntegerField(verbose_name = "型号")
	manager_ip      = models.IPAddressField(verbose_name = "管理地址")
	ip_mask         = models.IPAddressField(verbose_name = "子网掩码")
	gateway         = models.IPAddressField(verbose_name = "默认网关")
	manager_vlan    = models.IntegerField(verbose_name = "管理VLAN")
	port_begin_valn = models.IntegerField(verbose_name = "端口开始VLAN")
	port_end_valn   = models.IntegerField(verbose_name = "端口结束VLAN")

class DevEOC_TMP(models.Model):
	"""等待验收的基带EOC设备"""
	dev_id          = models.AutoField(primary_key=True)
	addr_1          = models.CharField(verbose_name = "一级点名称", max_length = 500)
	addr_2          = models.CharField(verbose_name = "二级点名称", max_length = 500)
	addr_detail     = models.CharField(verbose_name = "安装详细地址", max_length = 500)
	line_box_type   = models.IntegerField(verbose_name = "配线箱类型")
	dev_box_type    = models.CharField(verbose_name = "设备箱类型", max_length = 100)
	dev_type        = models.CharField(verbose_name = "设备类型", max_length = 100)
	cover_users     = models.IntegerField(verbose_name = "覆盖用户数")
	model           = models.IntegerField(verbose_name = "型号")
	manager_ip      = models.IPAddressField(verbose_name = "管理地址")
	ip_mask         = models.IPAddressField(verbose_name = "子网掩码")
	gateway         = models.IPAddressField(verbose_name = "默认网关")
	manager_vlan    = models.IntegerField(verbose_name = "管理VLAN")
	port_begin_valn = models.IntegerField(verbose_name = "端口开始VLAN")
	port_end_valn   = models.IntegerField(verbose_name = "端口结束VLAN")

class DevReport(models.Model):
	"""设备的提交记录"""
	user       = models.CharField(verbose_name = "提交者", max_length = 100)
	to_who     = models.CharField(verbose_name = "提交给谁验收", max_length = 100)
	dev_id     = models.IntegerField(verbose_name = "对应的设备id")
	dev_type   = models.IntegerField(verbose_name = "设备类型(1:ONU, 2:EOC)")
	date       = models.DateTimeField(verbose_name = "提交日期")
	valid_date = models.DateTimeField(verbose_name = "验收日期", null = True)
	is_valid   = models.BooleanField(verbose_name = "是否验收")

class Message(models.Model):
	"""用户消息"""
	msg_id      = models.AutoField(primary_key=True)
	user        = models.CharField(verbose_name = "谁的消息", max_length = 100)
	msg_type    = models.IntegerField(verbose_name = "消息类型(1:验收请求消息, 2:验收通过消息)")
	from_who    = models.CharField(verbose_name = "来自谁的消息", max_length = 100)
	dev_type    = models.IntegerField(verbose_name = "设备类型(1:ONU, 2:EOC)")
	report_date = models.DateTimeField(verbose_name = "消息产生日期")
	is_read     = models.BooleanField(verbose_name = "是否已读")


class ONUDetailReport(models.Model):
	"""用于查询的辅助类"""
	user     = models.CharField(verbose_name = "提交者", max_length = 100)
	date     = models.DateTimeField(verbose_name = "提交日期")

	dev_id      = models.AutoField(primary_key=True)
	addr_1      = models.CharField(verbose_name = "一级点名称", max_length = 500)
	addr_2      = models.CharField(verbose_name = "二级点名称", max_length = 500)
	addr_detail = models.CharField(verbose_name = "安装详细地址", max_length = 500)
	dev_name    = models.CharField(verbose_name = "设备名称", max_length = 100)
	mac_addr    = models.CharField(verbose_name = "MAC地址", max_length = 100)
	port_remark = models.CharField(verbose_name = "端口备注", max_length = 500)
		
class EOCDetailReport(models.Model):
	"""用于查询的辅助类"""
	user     = models.CharField(verbose_name = "提交者", max_length = 100)
	date     = models.DateTimeField(verbose_name = "提交日期")

	dev_id          = models.AutoField(primary_key=True)
	addr_1          = models.CharField(verbose_name = "一级点名称", max_length = 500)
	addr_2          = models.CharField(verbose_name = "二级点名称", max_length = 500)
	addr_detail     = models.CharField(verbose_name = "安装详细地址", max_length = 500)
	line_box_type   = models.IntegerField(verbose_name = "配线箱类型")
	dev_box_type    = models.CharField(verbose_name = "设备箱类型", max_length = 100)
	dev_type        = models.CharField(verbose_name = "设备类型", max_length = 100)
	cover_users     = models.IntegerField(verbose_name = "覆盖用户数")
	model           = models.IntegerField(verbose_name = "型号")
	manager_ip      = models.IPAddressField(verbose_name = "管理地址")
	ip_mask         = models.IPAddressField(verbose_name = "子网掩码")
	gateway         = models.IPAddressField(verbose_name = "默认网关")
	manager_vlan    = models.IntegerField(verbose_name = "管理VLAN")
	port_begin_valn = models.IntegerField(verbose_name = "端口开始VLAN")
	port_end_valn   = models.IntegerField(verbose_name = "端口结束VLAN")


