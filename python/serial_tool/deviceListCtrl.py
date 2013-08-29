# -*- coding: utf8 -*-

import wx
import xdrlib, sys, xlrd, os, util, serialRxEvent
import wx.lib.mixins.listctrl as listmix
from util import PortSetting, Device

# 设备数据字段
ENUM_DEVICE_DEV_TYPE    = 0
ENUM_DEVICE_MANGR_IP    = 1
ENUM_DEVICE_SUBMASK_IP  = 2
ENUM_DEVICE_GATEWAY_IP  = 3
ENUM_DEVICE_MANGR_VLAN  = 4
ENUM_DEVICE_BEGIN_VLAN  = 5
ENUM_DEVICE_END_VLAN    = 6

MAX_COL = ENUM_DEVICE_END_VLAN

class DeviceListCtrl(wx.ListCtrl, listmix.TextEditMixin):
	def __init__(self, parent, Id, pos=wx.DefaultPosition, size=wx.DefaultSize, style=0):
		wx.ListCtrl.__init__(self, parent, Id, pos, size, style)
		listmix.TextEditMixin.__init__(self)

		self.InsertColumn(ENUM_DEVICE_DEV_TYPE, u'设备安装地址')
		self.SetColumnWidth(ENUM_DEVICE_DEV_TYPE, 120)

		self.InsertColumn(ENUM_DEVICE_MANGR_IP, u'管理地址')
		self.SetColumnWidth(ENUM_DEVICE_MANGR_IP, 120)

		self.InsertColumn(ENUM_DEVICE_SUBMASK_IP, u'子网掩码')
		self.SetColumnWidth(ENUM_DEVICE_SUBMASK_IP, 120)

		self.InsertColumn(ENUM_DEVICE_GATEWAY_IP, u'默认网关')
		self.SetColumnWidth(ENUM_DEVICE_GATEWAY_IP, 120)

		self.InsertColumn(ENUM_DEVICE_MANGR_VLAN, u'管理VLAN')
		self.SetColumnWidth(ENUM_DEVICE_MANGR_VLAN, 120)

		self.InsertColumn(ENUM_DEVICE_BEGIN_VLAN, u'端口开始VLAN')
		self.SetColumnWidth(ENUM_DEVICE_BEGIN_VLAN, 120)

		self.InsertColumn(ENUM_DEVICE_END_VLAN, u'端口结束VLAN')
		self.SetColumnWidth(ENUM_DEVICE_END_VLAN, 120)

		# for wxMSW
		self.Bind(wx.EVT_COMMAND_RIGHT_CLICK, self.OnRightClick)
		# for wxGTK
		self.Bind(wx.EVT_RIGHT_UP, self.OnRightClick)

	def SetMainFrame(self, main_frame):
		self.main_frame = main_frame

	def OpenEditor(self, col, row):
		self.tmp_old_data = self.GetItem(row, col).GetText()
		print "want to edit: %s" % (self.tmp_old_data)
		listmix.TextEditMixin.OpenEditor(self, col, row)

	def CloseEditor(self, evt=None):
		listmix.TextEditMixin.CloseEditor(self, evt)
		if evt is not None and evt.GetEventType() == wx.wxEVT_KILL_FOCUS:
			return
		item    = self.GetItem(self.curRow, self.curCol)
		newname = item.GetText()

		if self.tmp_old_data == newname:
			return

		if self.curCol in [ENUM_DEVICE_MANGR_IP, ENUM_DEVICE_SUBMASK_IP, ENUM_DEVICE_GATEWAY_IP]:
			if not util.IsValidIP(newname):
				util.SendToTerm(self.main_frame.output, self.main_frame.GetId(), u"输入的ip: " + newname + u"非法\n", serialRxEvent.FROM_TYPE_SYS)
				self.SetStringItem(self.curRow, self.curCol, self.tmp_old_data)
				return

		ip_str1 = self.GetItem(self.curRow, ENUM_DEVICE_MANGR_IP).GetText()
		ip_str2 = self.GetItem(self.curRow, ENUM_DEVICE_GATEWAY_IP).GetText()
		if util.IsValidIP(ip_str1) and util.IsValidIP(ip_str2):
			if not util.IsInSameSubNets(ip_str1, ip_str2):
				util.SendToTerm(self.main_frame.output, self.main_frame.GetId(), u"管理地址与默认网关不在同一网关\n", serialRxEvent.FROM_TYPE_SYS)
				self.SetStringItem(self.curRow, self.curCol, self.tmp_old_data)
				return

		if self.tmp_old_data != newname:
			self.SetItemTextColour(self.curRow, wx.RED)

	def GetSelectedDevice(self):
		sel_index = self.GetFirstSelected()
		if sel_index == -1:
			return None
		return Device(self.GetItem(self.curRow, ENUM_DEVICE_DEV_TYPE).GetText(),
					  self.GetItem(self.curRow, ENUM_DEVICE_MANGR_IP).GetText(),
					  self.GetItem(self.curRow, ENUM_DEVICE_SUBMASK_IP).GetText(),
					  self.GetItem(self.curRow, ENUM_DEVICE_GATEWAY_IP).GetText(),
					  int(self.GetItem(self.curRow, ENUM_DEVICE_MANGR_VLAN).GetText()),
					  int(self.GetItem(self.curRow, ENUM_DEVICE_BEGIN_VLAN).GetText()),
					  int(self.GetItem(self.curRow, ENUM_DEVICE_END_VLAN).GetText())
					 )
		

	def OnImportDeviceDatas(self, e):
		self.DeleteAllItems()
		self.DeleteAllColumns()
		self.dirname = ''
		self.device_list = []
		dlg = wx.FileDialog(self, "Choose a file", self.dirname, "", "Excel Files (*.xlc;*.xls)|*.xlc; *.xls|All Files (*.*)|*.*||", wx.OPEN)
		if dlg.ShowModal() == wx.ID_OK:
			self.filename = dlg.GetFilename()
			self.dirname = dlg.GetDirectory()
			xml_data  = xlrd.open_workbook(os.path.join(self.dirname, self.filename))

			table = xml_data.sheet_by_index(0)
			total_cols = table.ncols
			# 设置列名
			for i in range(0, total_cols):
				self.InsertColumn(i, util.to_str(table.cell(0, i).value))
				self.SetColumnWidth(i, 120)
			# 加载数据
			for i in range(1, table.nrows):
				self.InsertStringItem(i-1,u"")
				for j in range(0, total_cols):
					self.SetStringItem(i - 1, j, util.to_str(table.cell(i, j).value))
				if (i - 1) % 2 == 1:
					self.SetItemTextColour(i - 1, wx.BLUE)

				device = Device(util.to_str(table.cell(i, ENUM_DEVICE_DEV_TYPE).value),
								util.to_str(table.cell(i, ENUM_DEVICE_MANGR_IP).value),
								util.to_str(table.cell(i, ENUM_DEVICE_SUBMASK_IP).value),
								util.to_str(table.cell(i, ENUM_DEVICE_GATEWAY_IP).value),
								int(table.cell(i, ENUM_DEVICE_MANGR_VLAN).value),
								int(table.cell(i, ENUM_DEVICE_BEGIN_VLAN).value),
								int(table.cell(i, ENUM_DEVICE_END_VLAN).value))
				self.device_list.append(device)
			self.Select(0)
		dlg.Destroy()

	def OnRightClick(self, event):
		# only do this part the first time so the events are only bound once
		if not hasattr(self, "popupID1"):
			self.popupID1 = wx.NewId()
			self.popupID2 = wx.NewId()

			self.Bind(wx.EVT_MENU, self.OnPopupAddRow, id=self.popupID1)
			self.Bind(wx.EVT_MENU, self.OnPopupSelect, id=self.popupID2)

		# make a menu
		menu = wx.Menu()
		# add some items
		menu.Append(self.popupID1, u"添加空白行")
		menu.Append(self.popupID2, u"选中")
		# Popup the menu.  If an item is selected then its handler
		# will be called before PopupMenu returns.
		self.PopupMenu(menu)
		menu.Destroy()

	def OnPopupAddRow(self, event):
		Index = self.GetItemCount()
		self.InsertStringItem(Index, u"")
		for col in xrange(0, MAX_COL):
			self.SetStringItem(Index, col, "")

	def OnPopupSelect(self, event):
		pass