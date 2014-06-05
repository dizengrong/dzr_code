# -*- coding: utf8 -*-

import wx
import xdrlib, sys, xlrd, os, util, serialRxEvent
import wx.lib.mixins.listctrl as listmix
from util import PortSetting, Device
import  wx.grid as  gridlib

# 设备数据字段
# ENUM_DEVICE_FLAG    	= 0
ENUM_DEVICE_DEV_TYPE    = 0
ENUM_DEVICE_DEV_ADDR    = 1
ENUM_DEVICE_MANGR_IP    = 2
ENUM_DEVICE_SUBMASK_IP  = 3
ENUM_DEVICE_GATEWAY_IP  = 4
ENUM_DEVICE_MANGR_VLAN  = 5
ENUM_DEVICE_BEGIN_VLAN  = 6
ENUM_DEVICE_END_VLAN    = 7

MAX_COL = ENUM_DEVICE_END_VLAN

def GetDeviceTypeList():
	fd = open(u'config/设备类型配置.txt', 'r')
	str = fd.read().strip().decode('utf8')
	return str.split('\n')

def GetSendPrompt():
	fd = open(u'config/设备发送命令提示.txt', 'r')
	str = fd.read().strip().decode('utf8')
	prompts = str.split('\n')
	dic = {}
	for prompt in prompts:
		tmp = prompt.split('=')
		dic[tmp[0]] = tmp[1]
	return dic
		

class DeviceListCtrl(gridlib.Grid):
	def __init__(self, parent, Id, pos=wx.DefaultPosition, size=wx.DefaultSize, style=0):
		gridlib.Grid.__init__(self, parent, Id)
		self.CreateGrid(100, MAX_COL + 1)

		# self.SetColLabelValue(ENUM_DEVICE_FLAG, u'')
		# self.SetColMinimalWidth(ENUM_DEVICE_FLAG, 50)

		self.SetColLabelValue(ENUM_DEVICE_DEV_TYPE, u'设备类型')
		self.SetColMinimalWidth(ENUM_DEVICE_DEV_TYPE, 180)

		self.SetColLabelValue(ENUM_DEVICE_DEV_ADDR, u'设备安装地址')
		self.SetColSize(ENUM_DEVICE_DEV_ADDR, 120)

		self.SetColLabelValue(ENUM_DEVICE_MANGR_IP, u'管理地址')
		self.SetColSize(ENUM_DEVICE_MANGR_IP, 120)

		self.SetColLabelValue(ENUM_DEVICE_SUBMASK_IP, u'子网掩码')
		self.SetColSize(ENUM_DEVICE_SUBMASK_IP, 120)

		self.SetColLabelValue(ENUM_DEVICE_GATEWAY_IP, u'默认网关')
		self.SetColSize(ENUM_DEVICE_GATEWAY_IP, 120)

		self.SetColLabelValue(ENUM_DEVICE_MANGR_VLAN, u'管理VLAN')
		self.SetColSize(ENUM_DEVICE_MANGR_VLAN, 120)

		self.SetColLabelValue(ENUM_DEVICE_BEGIN_VLAN, u'端口开始VLAN')
		self.SetColSize(ENUM_DEVICE_BEGIN_VLAN, 120)

		self.SetColLabelValue(ENUM_DEVICE_END_VLAN, u'端口结束VLAN')
		self.SetColSize(ENUM_DEVICE_END_VLAN, 120)

		self.SetRowLabelSize(60)

		self.AutoSizeColumns(setAsMin = False)

		for row in xrange(0,100):
			editor1 = gridlib.GridCellChoiceEditor(GetDeviceTypeList(), allowOthers=True)
			# self.SetCellValue(row, ENUM_DEVICE_DEV_TYPE, 'one')
			self.SetCellEditor(row, ENUM_DEVICE_DEV_TYPE, editor1)

			# editor2 = gridlib.GridCellBoolEditor()
			# self.SetCellEditor(row, ENUM_DEVICE_FLAG, editor2)
			# self.SetCellRenderer(row, ENUM_DEVICE_FLAG, gridlib.GridCellBoolRenderer())

		# for wxMSW
		# self.Bind(wx.EVT_COMMAND_RIGHT_CLICK, self.OnRightClick)
		# for wxGTK
		# self.Bind(wx.EVT_RIGHT_UP, self.OnRightClick)

		self.Bind(wx.grid.EVT_GRID_CELL_CHANGE, self.OnCellDataChange)
		self.Bind(wx.grid.EVT_GRID_RANGE_SELECT, self.OnSelectRangeChange)
		self.Bind(wx.grid.EVT_GRID_SELECT_CELL, self.OnSelectChange)

		# self.SetBackgroundColour('#d9d6c3')
		self.SetDefaultRowSize(20)

		self.send_prompts = GetSendPrompt()

		# add blank rows
		# for index in xrange(0,100):
		# 	self.AddNewRow(index)

	def SetMainFrame(self, main_frame):
		self.main_frame = main_frame

	def GetSelectedDevice(self):
		if len(self.GetSelectedRows()) == 0:
			return None
		else:
			sel_index = self.GetSelectedRows()[0]
			if sel_index == -1:
				return None
			try:
				return Device(self.GetCellValue(sel_index, ENUM_DEVICE_DEV_TYPE),
						  	  self.GetCellValue(sel_index, ENUM_DEVICE_DEV_ADDR),
						  	  self.GetCellValue(sel_index, ENUM_DEVICE_MANGR_IP),
						  	  self.GetCellValue(sel_index, ENUM_DEVICE_SUBMASK_IP),
						  	  self.GetCellValue(sel_index, ENUM_DEVICE_GATEWAY_IP),
						  	  int(self.GetCellValue(sel_index, ENUM_DEVICE_MANGR_VLAN)),
						  	  int(self.GetCellValue(sel_index, ENUM_DEVICE_BEGIN_VLAN)),
						  	  int(self.GetCellValue(sel_index, ENUM_DEVICE_END_VLAN))
						 )
			except Exception, e: # 处理数据错误或空白行的问题
				print 'GetSelectedDevice exception: ', e
				return None

	def FilterTemplateList(self, device_type):
		if device_type == '':
			self.main_frame.m_choice7.Clear()
		else:
			filter_tpls = []
			for cmd_tpl in self.main_frame.cmd_tpl_list:
				if cmd_tpl.decode('gbk').startswith(device_type):
					filter_tpls.append(cmd_tpl)
			self.main_frame.m_choice7.Clear()
			self.main_frame.m_choice7.AppendItems(filter_tpls)
			self.main_frame.m_choice7.Select(0)

		if device_type == '':
			self.main_frame.m_choice9.Clear()
		else:
			filter_tpls = []
			for cmd_tpl in self.main_frame.cmd_tpl_list:
				if cmd_tpl.decode('gbk').startswith(u'清除-' + device_type):
					filter_tpls.append(cmd_tpl)
			self.main_frame.m_choice9.Clear()
			self.main_frame.m_choice9.AppendItems(filter_tpls)
			self.main_frame.m_choice9.Select(0)

	def SetPromptForSend(self, device_type):
		prompt = self.send_prompts.get(device_type, u'暂无发送提示')
		self.main_frame.SetSendPrompt(prompt)

	def OnSelectRangeChange(self, event):
		device_type = self.GetCellValue(event.GetTopRow(), ENUM_DEVICE_DEV_TYPE)
		self.FilterTemplateList(device_type)
		self.SetPromptForSend(device_type)
		self.main_frame.m_textCtrl6.SetValue('')
		event.Skip()

	def OnSelectChange(self, event):
		device_type = self.GetCellValue(event.Row, ENUM_DEVICE_DEV_TYPE)
		self.FilterTemplateList(device_type)
		self.SetPromptForSend(device_type)
		self.main_frame.m_textCtrl6.SetValue('')
		event.Skip()

	def OnCellDataChange(self, event):
		print 'event.Col:', event.Col
		if event.Col == ENUM_DEVICE_DEV_TYPE:
			device_type = self.GetCellValue(event.Row, event.Col)
			print device_type
			self.FilterTemplateList(device_type)
			self.SetPromptForSend(device_type)
		elif event.Col == ENUM_DEVICE_MANGR_IP or event.Col == ENUM_DEVICE_SUBMASK_IP or event.Col == ENUM_DEVICE_GATEWAY_IP:
			if not util.IsValidIP(self.GetCellValue(event.Row, event.Col)):
				util.ShowMessageDialog(self, u"非法的ip地址", u"错误")
				event.Veto()
				return
		event.Skip()
		wx.CallAfter(self.AdjustSizeColumns)
		
	def AdjustSizeColumns(self):
		self.AutoSizeColumns(setAsMin = False)

	def OnImportDeviceDatas(self, e):
		self.dirname = ''
		# self.device_list = []
		dlg = wx.FileDialog(self, "Choose a file", self.dirname, "", "Excel Files (*.xlc;*.xls)|*.xlc; *.xls|All Files (*.*)|*.*||", wx.OPEN)
		if dlg.ShowModal() == wx.ID_OK:
			self.DeleteRows()

			self.filename = dlg.GetFilename()
			self.dirname = dlg.GetDirectory()
			self.ImportDeviceDatas(os.path.join(self.dirname, self.filename))
			
		dlg.Destroy()
		wx.CallAfter(self.AdjustSizeColumns)

	def ImportDeviceDatas(self, filename):
		if not os.path.isfile(filename):
			return
		self.device_list = []
		xml_data  = xlrd.open_workbook(filename)

		table = xml_data.sheet_by_index(0)
		total_cols = table.ncols
		
		# 加载数据
		for i in range(1, table.nrows):
			self.AppendRows()
			for j in range(0, MAX_COL + 1):
				self.SetCellValue(i - 1, j, util.to_str(table.cell(i, j).value))
			# if (i - 1) % 2 == 1:
			# 	self.SetItemTextColour(i - 1, wx.BLUE)

			device = Device(util.to_str(table.cell(i, ENUM_DEVICE_DEV_TYPE).value),
							util.to_str(table.cell(i, ENUM_DEVICE_DEV_ADDR).value),
							util.to_str(table.cell(i, ENUM_DEVICE_MANGR_IP).value),
							util.to_str(table.cell(i, ENUM_DEVICE_SUBMASK_IP).value),
							util.to_str(table.cell(i, ENUM_DEVICE_GATEWAY_IP).value),
							int(table.cell(i, ENUM_DEVICE_MANGR_VLAN).value),
							int(table.cell(i, ENUM_DEVICE_BEGIN_VLAN).value),
							int(table.cell(i, ENUM_DEVICE_END_VLAN).value))
			self.device_list.append(device)
		

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
		self.AddNewRow(self.GetItemCount())

	def AddNewRow(self, index):
		self.InsertStringItem(index, u"")
		for col in xrange(0, MAX_COL):
			self.SetStringItem(index, col, "")
			if col == 1:
				# panel = wx.Panel(self, id = wx.ID_ANY, pos = wx.DefaultPosition, size = wx.Size( 50,60 ), style = wx.TAB_TRAVERSAL )
				# bSizer24 = wx.BoxSizer( wx.VERTICAL )
				# choice = wx.Choice(panel, -1, choices=["one", "two"])

				# bSizer24.Add( choice, 1, wx.ALL, 1 )
				# panel.SetSizer( bSizer24 )
				# panel.Layout()
				panel = wx.Button( self, wx.ID_ANY, u"MyButton", wx.DefaultPosition, wx.DefaultSize, 0 )
				self.SetItemWindow(index, col, panel, expand=True)

	def OnPopupSelect(self, event):
		pass