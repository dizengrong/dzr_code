#!/usr/bin/env python
# -*- coding: utf8 -*-


import wx, os, serial, threading, util, Mytty, session, base64
import xdrlib, sys, xlrd, tenjin, time, datetime, webbrowser, telnetlib
import SaveSessionDialog, OpenSessionDialog, ChangeIpDialog
from tenjin.escaped import *
from tenjin.helpers import to_str
from deviceListCtrl import DeviceListCtrl
from util import PortSetting, Device
from wxTerm import *
from session import *
import my_machine, traceback

# 端口设置字段
ENUM_SETTING_DESC       = 0
ENUM_SETTING_RATE       = 1
ENUM_SETTING_BYTESIZE   = 2
ENUM_SETTING_PARITY     = 3
ENUM_SETTING_STOPBITS   = 4
ENUM_SETTING_DTRCONTROL = 5

engine = tenjin.SafeEngine()
license_mag = None

#各控件说明：
# 	m_listCtrl1: 设备数据
# 	m_choice7: 命令模板选择列表
# 	m_choice8: serial的设置选择列表
# 	m_choice9: 生成清除配置的命令选择列表
# 	m_comboBox1: 端口选择列表
# 	m_statusBar1: status bar
# 	m_auinotebook2: 管理会话tab的控件
# 	m_staticText19: 当前连接信息显示
# 	m_textCtrl6: 模板输出控件
# 	m_textCtrl7: 设置发送模板数据间隔的控件
# 	m_textCtrl12: telnet连接输入ip的控件
# 	m_textCtrl14: telnet连接输入port的控件
# 	m_textCtrl71: 直接发送命令的控件
# 	m_menu2: 外部工具菜单
class MyttyFrame(Mytty.Mytty):
	#会话管理（类变量）
	session_manager = session.SessionManager()

	def __init__(self):
		super(MyttyFrame, self).__init__(None)
		session_manager.InitConfig()

		self.m_choice8.AppendItems(self.InitPortSetting())
		self.m_choice7.AppendItems(self.InitCmdTemplates())

		# 去掉设计界面时测试用的session1和session2
		self.m_auinotebook2.DeletePage(self.m_auinotebook2.GetPageIndex(self.m_panel10))
		self.m_auinotebook2.DeletePage(self.m_auinotebook2.GetPageIndex(self.m_panel11))

		self.m_textCtrl71.Enable(False)

		# 外部工具的菜单链接
		self.InitExtralToolsMenu()

		self.m_listCtrl1.SetMainFrame(self)
		version = u"（版本：%s    剩余使用天数：%d）" % (license_mag.GetVersion(), license_mag.GetLeftDays())
		self.SetLabel(self.GetLabel() + version)

	def InitExtralToolsMenu(self):
		for item in os.listdir("./tools/"):
			if item.endswith(".exe"):
				tool_name = os.path.basename(item)
				menu_item = wx.MenuItem( self.m_menu2, wx.ID_ANY, tool_name, wx.EmptyString, wx.ITEM_NORMAL )
				self.m_menu2.AppendItem( menu_item )
				self.Bind( wx.EVT_MENU, self.OnOpenExtralTool, id = menu_item.GetId() )
				# os.system(os.path.abspath("./tools/") + "/" + item)

	def OnOpenExtralTool( self, event ):
		menu_item = self.GetMenuBar().FindItemById(event.GetId())
		text = menu_item.GetText()
		print "You selected the '%s' menu item" % (text)
		wx.Execute(os.path.abspath("./tools/") + "/" + text.encode('gbk'), flags=wx.EXEC_ASYNC) 

	def OnChangeLocalIp( self, event ):
		dlg = MyChangeIpDialog(self)
		if dlg.ShowModal() == wx.ID_OK:
			pass
		dlg.Destroy()
		
	def OnImportDeviceDatas( self, event ):
		self.m_listCtrl1.OnImportDeviceDatas(event)
	
	def OnSaveSession( self, event ):
		session = self.GetCurActivatedSession()
		if session is None:
			return

		dlg = MySaveSessionDialog(self, session)
		if dlg.ShowModal() == wx.ID_OK:
			save_name = dlg.GetSessionSaveName()
			save_path = dlg.GetLogFileName()
			if session_manager.SaveSession(session, save_name, save_path):
				self.m_auinotebook2.SetPageText(self.m_auinotebook2.GetSelection(), session.GetSessionName())
			else:
				util.ShowMessageDialog(self, u"保存会话失败，已存在同名的会话了", u"信息")
				print u"save session failed!"
		dlg.Destroy()
	
	def OnOpenSession( self, event ):
		dlg = MyOpenSessionDialog(self)
		if dlg.ShowModal() == wx.ID_OK:
			session = dlg.GetSelectedSession()
			if session == None:
				util.ShowMessageDialog(self, u"没有找到保存的会话", u"信息")
				return
			self.OpenSession(session)
		dlg.Destroy()
	
	def OnExit( self, event ):
		self.Close(True)
	
	def OnOpenDoc( self, event ):
		doc = os.path.join(os.path.realpath(os.path.dirname(".")), "documents/index.html")
		webbrowser.open(doc)
	
	def OnAbout( self, event ):
		dlg = wx.MessageDialog(self, u" 版本：设备配置程序 mytty-v2.02 \n 制作：nx工作室 \n 联系方式：\n      联系人：谢志文\n      手机   ：13575121258 \n      邮箱   ：348588919@qq.com", u"关于", wx.OK)
		dlg.ShowModal()
		dlg.Destroy()
	
	def OnConnectionPageChanged( self, event ):
		event.Skip()
	
	def OnOpenSerialPort( self, event ):
		if self.m_comboBox1.GetSelection() == wx.NOT_FOUND:
			self.m_statusBar1.SetStatusText(u"请选择端口")
			return

		if self.m_choice8.GetSelection() == wx.NOT_FOUND:
			self.m_statusBar1.SetStatusText(u"请选择端口设置")
			return

		portstr = self.m_comboBox1.GetStringSelection()
		port_setting = self.setting_list[self.m_choice8.GetSelection()]

		session = SerialSession(portstr, port_setting)
		self.OpenSession(session)

	def OnTestTelnet( self, event ):
		ip = self.m_textCtrl12.GetValue().strip()
		port = int(self.m_textCtrl14.GetValue().strip())
		try:
			telnet = telnetlib.Telnet(ip, port = port, timeout = 3)
			telnet.close()
			msg = u"telnet连接: %s 成功！" % (ip)
		except Exception, e:
			print u"telnet %s failed, exception: %s" % (ip, e)
			msg = u"telnet连接: %s 失败！" % (ip)
		finally:
			dlg = wx.MessageDialog(self, msg, u"信息", wx.OK)
			dlg.ShowModal()
			dlg.Destroy()
	
	def OnOpenTelnet( self, event ):
		session = TelnetSession(self.m_textCtrl12.GetValue().strip(), 
								int(self.m_textCtrl14.GetValue().strip()))
		self.OpenSession(session)

	def OnGenerateClearCmd( self, event ):
		if self.m_choice9.GetSelection() == wx.NOT_FOUND:
			self.m_statusBar1.SetStatusText(u"请选择模板")
			return
		device = self.m_listCtrl1.GetSelectedDevice()
		if device == None:
			self.m_statusBar1.SetStatusText(u"请选择一条设备数据")
			return

		tpl_file = "templates/" + self.m_choice9.GetStringSelection()

		fd = open(tpl_file, 'r')
		self.m_textCtrl6.SetValue(fd.read())

	def OnGenerateTemplate( self, event ):
		if self.m_choice7.GetSelection() == wx.NOT_FOUND:
			self.m_statusBar1.SetStatusText(u"请选择模板")
			return
		device = self.m_listCtrl1.GetSelectedDevice()
		if device == None:
			self.m_statusBar1.SetStatusText(u"请选择一条设备数据")
			return

		tpl_file = "templates/" + self.m_choice7.GetStringSelection()
		tpl_file = tpl_file.encode('gbk')
		# print tpl_file
		dict_data = {"mangr_vlan": device.mangr_vlan,
					 "mangr_ip": device.mangr_ip,
					 "submask_ip": device.submask_ip,
					 "begin_vlan": device.begin_vlan,
					 "end_vlan": device.end_vlan,
					 "gateway_ip": device.gateway_ip
					 }
		content  = engine.render(tpl_file, dict_data)
		self.m_textCtrl6.SetValue(content)
	
	def OnSendTemplate( self, event ):
		tpl_content = self.m_textCtrl6.GetValue()
		if tpl_content == '':
			self.m_statusBar1.SetStatusText(u"还没有生成命令")
			return
		if not self.AssertOpenSession():
			return
		send_interval = self.GetSendInterval()

		cmd_list = tpl_content.split("\n")
		self.StartSendTplCmdThread(cmd_list, send_interval)

	# def OnSendComand( self, event ):
	# 	content = self.m_textCtrl71.GetValue()
	# 	if content != '' and self.AssertOpenSession():
	# 		send_interval = self.GetSendInterval()
	# 		cmd_list = content.split("\n")
	# 		self.StartSendTplCmdThread(cmd_list, send_interval)
	# 	self.m_textCtrl71.Clear()

	def OnSendCmdKeyDown( self, event ):
		event.Skip()
		if event.GetKeyCode() == wx.WXK_RETURN:
			if event.ControlDown():
				content = self.m_textCtrl71.GetValue()
				if content != '' and self.AssertOpenSession():
					send_interval = self.GetSendInterval()
					cmd_list = content.split("\n")
					self.StartSendTplCmdThread(cmd_list, send_interval)
				self.m_textCtrl71.Clear()

	
	def OnSessionPageChanged( self, event ):
		event.Skip()
		tab_title = self.m_auinotebook2.GetPageText(event.GetSelection())
		session = session_manager.GetSessionByName(tab_title)
		if session:
			self.SetConnectionInfo(session)
			self.m_textCtrl71.Enable(True)

	def OnSessionPageClose( self, event ):
		dlg = wx.MessageDialog(self, u"确定要关闭连接？", u"提示", wx.OK|wx.CANCEL)
		if dlg.ShowModal() == wx.ID_OK:
			session = self.GetCurActivatedSession()
			session_manager.RemoveSession(session)
			session.Close()
			event.Skip()
			self.m_textCtrl71.Enable(False)
			self.SetConnectionInfo(None)
		else:
			event.Veto()

	def OnClose( self, event ):
		session = self.GetCurActivatedSession()
		if session:
			dlg = wx.MessageDialog(self, u"确定要关闭全部连接吗？", u"提示", wx.OK|wx.CANCEL)
			if dlg.ShowModal() == wx.ID_OK:
				session_manager.CloseAllSessions()
				event.Skip()
			else:
				event.Veto()
		else:
			event.Skip()


	def OpenSession(self, session):
		if session.Open():
			session_manager.AddSession(session)
			tabPanel = wx.Panel( self.m_auinotebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
			self.m_auinotebook2.AddPage( tabPanel, session.GetSessionName(), True, wx.NullBitmap )
			self.SetConnectionInfo(session)

			tabPanelSizer = wx.BoxSizer( wx.VERTICAL )
			terminate = wxTerm(tabPanel, "", session = session)
			tabPanelSizer.Add( terminate, 1, wx.ALL|wx.EXPAND, 1 )
			tabPanel.SetSizer( tabPanelSizer )
			tabPanel.Layout()
			self.m_textCtrl71.Enable(True)
			print "page index: %d" % (self.m_auinotebook2.GetPageIndex(tabPanel))
		else:
			dlg = wx.MessageDialog(self, u"连接：%s 打开失败" % session.GetSessionInfo(), u"错误", wx.OK)
			dlg.ShowModal()
			dlg.Destroy()

	def StartSendTplCmdThread(self, cmd_list, send_interval):
		self.send_thread = threading.Thread(target=self.SendTplCmdThread, args = (cmd_list, send_interval))
		self.send_thread.setDaemon(1)
		self.send_thread.start()

	def SendTplCmdThread(self, cmd_list, send_interval):
		session = self.GetCurActivatedSession()
		for cmd in cmd_list:
			print "send cmd: %s\n" % (cmd)
			session.Write(cmd + "\n")
			time.sleep(send_interval/1000.0)

			if not session.IsAlive():
				self.m_statusBar1.SetStatusText(u"连接已断开，发送模板数据已终止！")
				break

		self.send_thread = None

	def GetCurActivatedSession(self):
		selected_tab = self.m_auinotebook2.GetSelection()
		if selected_tab >= 0:
			tab_title = self.m_auinotebook2.GetPageText(self.m_auinotebook2.GetSelection())
			session = session_manager.GetSessionByName(tab_title)
			return session
		else:
			return None

	def AssertOpenSession(self):
		selected_tab = self.m_auinotebook2.GetSelection()
		if selected_tab == -1:
			self.m_statusBar1.SetStatusText(u"当前没有连接的会话")
			return False
		return True

	def GetSendInterval(self):
		send_interval = 100
		try:
			send_interval = int(self.m_textCtrl7.GetValue())
		except Exception, e:
			self.m_textCtrl7.SetValue("100")
		return send_interval

	def SetConnectionInfo(self, session):
		if session:
			self.m_staticText19.SetLabel(u"当前连接信息：" + session.GetSessionInfo())
		else:
			self.m_staticText19.SetLabel(u"当前连接信息：")

	def InitPortSetting(self):
		xml_data = xlrd.open_workbook("PortSetting.xls")
		table    = xml_data.sheet_by_index(0)
		desc_list = []
		self.setting_list = []
		for i in range(1, table.nrows):
			desc_list.append(util.to_str(table.cell(i, ENUM_SETTING_DESC).value))

			port_setting = PortSetting(int(table.cell(i, ENUM_SETTING_RATE).value),
									   int(table.cell(i, ENUM_SETTING_BYTESIZE).value),
									   util.to_str(table.cell(i, ENUM_SETTING_PARITY).value),
									   int(table.cell(i, ENUM_SETTING_STOPBITS).value),
									   int(table.cell(i, ENUM_SETTING_DTRCONTROL).value))
			self.setting_list.append(port_setting)
		return desc_list	

	def InitCmdTemplates(self):
		self.cmd_tpl_list = []
		for item in os.listdir("templates/"):
			if item.endswith(".txt"):
				tpl = os.path.basename(item)
				self.cmd_tpl_list.append(tpl)
		return self.cmd_tpl_list


# 控件说明：
# 	m_staticText21: 连接信息显示控件
# 	m_filePicker1: 选择记录日志文件的控件
# 	m_checkBox2: 是否记录日志的checkbox
# 	m_textCtrl15: 保存的session名称控件
class MySaveSessionDialog(SaveSessionDialog.SaveSessionDialog):
	"""docstring for MySaveSessionDialog"""
	def __init__(self, parent, session):
		super(MySaveSessionDialog, self).__init__(parent)
		self.SetConnectionInfo(session)
		self.m_textCtrl15.SetValue(session.GetSessionName())
		self.session = session
		
	def onRecordLog( self, event ):
		self.m_filePicker1.Enable(event.IsChecked())

	def OnSaveSession( self, event ):
		save_name = self.GetSessionSaveName()
		if save_name != self.session.GetSessionName():
			if MyttyFrame.session_manager.IsNameExist(save_name):
				util.ShowMessageDialog(self, u"该会话名已存在！", u"信息")
			else:
				event.Skip()
		else:
			event.Skip()

	def GetSessionSaveName(self):
		return self.m_textCtrl15.GetValue()

	def GetLogFileName(self):
		if self.m_checkBox2.IsChecked():
			return self.m_filePicker1.GetPath()
		else:
			return ""

	def SetConnectionInfo(self, session):
		self.m_staticText21.SetLabel(u"当前连接信息：" + session.GetSessionInfo())


# 控件说明：
# 	m_listCtrl2: 显示已保存的session
class MyOpenSessionDialog(OpenSessionDialog.OpenSessionDialog):
	"""docstring for MyOpenSessionDialog"""
	def __init__(self, parent):
		super(MyOpenSessionDialog, self).__init__(parent)
		self.m_listCtrl2.InsertColumn(0, u'已保存的会话')
		self.m_listCtrl2.SetColumnWidth(0, 260)

		index = 0
		for session in MyttyFrame.session_manager.saved_sessions:
			session_name = session.GetSessionName()
			self.m_listCtrl2.InsertStringItem(index, session_name + " [" + session.GetSessionInfo() + "]")
			self.m_listCtrl2.SetItemData(index, len(session_name))
			index += 1

	def GetSelectedSession(self):
		sel_index = self.m_listCtrl2.GetFirstSelected()
		# print "sel_index: ", sel_index
		if sel_index == -1:
			return None
		session_name = self.m_listCtrl2.GetItemText(sel_index)
		length = self.m_listCtrl2.GetItemData(sel_index)
		session_name = session_name[0:length]
		return MyttyFrame.session_manager.GetSavedSessionByName(session_name)

	def OnItemActivated( self, event ):
		pass

	def OnDeleteSession( self, event ):
		sel_index = self.m_listCtrl2.GetFirstSelected()
		if sel_index == -1:
			return None
		session_name = self.m_listCtrl2.GetItemText(sel_index)
		if MyttyFrame.session_manager.DeleteSavedSessionByName(session_name):
			self.m_listCtrl2.DeleteItem(sel_index)
		else:
			util.ShowMessageDialog(self, u"删除会话记录失败，可能已经不存在那个会话了", u"错误")

		
# 控件说明：
# 	m_choice8: 选择网络连接名称的控件
# 	m_textCtrl12: ip地址控件
# 	m_textCtrl14: 子网掩码控件
# 	m_textCtrl15: 默认网关控件
class MyChangeIpDialog(ChangeIpDialog.ChangeIpDialog):
	"""docstring for MyChangeIpDialog"""
	def __init__(self, parent):
		super(MyChangeIpDialog, self).__init__(parent)
		all_network_connections = util.GetAllNetworkName()

		self.m_choice8.AppendItems(util.GetAllNetworkName())
		
	def OnChangeIpMode1( self, event ):
		# 改为自动获取ip地址
		connection_name = self.m_choice8.GetStringSelection()
		print connection_name
		if connection_name == "":
			return
		cmd = u"netsh interface ip set address name=" + connection_name + u" source=dhcp"  
		print cmd
		util.ShowMessageDialog(self, util.ExecuteCmd(cmd.encode('gbk')), u"执行结果")
		event.Skip()

	def OnChangeIpMode2( self, event ):
		connection_name = self.m_choice8.GetStringSelection()
		if connection_name == "":
			return

		ip      = self.m_textCtrl12.GetValue().strip()
		mask    = self.m_textCtrl14.GetValue().strip()
		gateway = self.m_textCtrl15.GetValue().strip()

		if ip == "" or mask == "" or gateway == "":
			return
		cmd = "netsh interface ip set address name=\"%s\" source=static addr=%s mask=%s gateway=%s 1" % (connection_name, ip, mask, gateway)
		util.ShowMessageDialog(self, util.ExecuteCmd(cmd.encode('gbk')), u"执行结果")
		event.Skip()


class LicenseManager(object):
	"""docstring for LicenseManager"""
	def __init__(self):
		super(LicenseManager, self).__init__()

	def OpenLicense(self, path):
		"""返回0表示合法的license, 1:非法的, 2:系统时间非法, 3:license过期, 4:非授权的目标机器"""
		self.path = path
		try:
			fd = open(self.path, 'r')
			self.license_dic = eval(base64.decodestring(fd.read())[3:])
			for key in self.license_dic.keys():
				self.license_dic[key] = base64.decodestring(self.license_dic[key])
			fd.close()

			if not self.IsDateValid():
				return (2, "")

			if self.IsLicenseExpired():
				return (3, "")

			if not self.IsAuthorizedMachine():
				return (4, "")

			return (0, "")
		except Exception, e:
			print 'open license file failed, exception:', e
			return (1, e)
	
	def IsAuthorizedMachine(self):
		machine = my_machine.Machine()
		cpu  = machine.get_cpu_info()
		disk = machine.get_disk_info()
		bios = machine.get_bios_info()
		mac  = machine.get_mac_info()
		return (self.license_dic['cpu.ProcessorId'] == cpu['cpu.ProcessorId'] and \
				self.license_dic['physical_disk.SerialNumber'] == disk['physical_disk.SerialNumber'] and \
			    self.license_dic['bios_id.SerialNumber'] == bios['bios_id.SerialNumber'] and \
			    self.license_dic['mac.MACAddress'] == mac['mac.MACAddress'])

	def IsDateValid(self):
		if self.license_dic.has_key('using_logs'):
			now = datetime.datetime.today()
			using_logs = self.license_dic['using_logs'].split('#')
			for log in using_logs:
				# print "using log: ", log
				using_time = datetime.datetime.strptime(log, '%Y-%m-%d %H:%M:%S')
				if using_time >= now:
					return False
			return True
		else:
			return True

	def IsLicenseExpired(self):
		now          = datetime.date.today()
		[y1, m1, d1] = self.license_dic['start_date'].split('-')
		[y2, m2, d2] = self.license_dic['end_date'].split('-')
		self.start_date   = datetime.date(int(y1), int(m1), int(d1))
		self.end_date     = datetime.date(int(y2), int(m2), int(d2))
		return not (self.start_date <= now and now <= self.end_date)

	def AddUsingLog(self):
		now = datetime.datetime.today()
		if self.license_dic.has_key('using_logs'):
			using_logs = self.license_dic['using_logs']
			using_logs += '#' + now.strftime('%Y-%m-%d %H:%M:%S')
		else:
			using_logs = now.strftime('%Y-%m-%d %H:%M:%S')
		self.license_dic['using_logs'] = using_logs

		fd          = open(self.path, 'w')
		encrypt_dic = {}
		for key in self.license_dic.keys():
			encrypt_dic[key] = base64.encodestring(self.license_dic[key])

		encrypt_str =  base64.encodestring(u'dzr' + str(encrypt_dic))
		fd.write(encrypt_str)
		fd.flush()
		fd.close()

	def GetLeftDays(self):
		return (self.end_date - datetime.date.today()).days

	def GetVersion(self):
		if self.license_dic['version'] == '1':
			return u'试用版'
		else:
			return u'注册版'

if __name__ == "__main__":
	app = wx.PySimpleApp(0)
	wx.InitAllImageHandlers()
	license_mag = LicenseManager()
	(val, msg) = license_mag.OpenLicense(u'./license.license')
	if val == 1:
		util.ShowMessageDialog(None, u'该软件没有正确的授权，无法使用！%s' % (msg), u'错误')
	elif val == 2:
		util.ShowMessageDialog(None, u'系统时间有问题，请您正确设置时间并合法使用该软件', u'错误')
	elif val == 3:
		util.ShowMessageDialog(None, u'软件使用已到期，要继续使用请联系商家', u'错误')
	elif val == 4:
		util.ShowMessageDialog(None, u'非授权的机器，无法使用该软件，请联系商家购买', u'错误')
	else:
		license_mag.AddUsingLog()
		frame_1 = MyttyFrame()
		app.SetTopWindow(frame_1)
		frame_1.Show()
		app.MainLoop()


	
	