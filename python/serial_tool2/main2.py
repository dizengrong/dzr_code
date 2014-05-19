#!/usr/bin/env python
# -*- coding: utf8 -*-


import wx, os, serial, threading, util, Mytty, base64, thread, logging, deviceListCtrl
import xdrlib, sys, xlrd, tenjin, time, datetime, webbrowser, telnetlib, zipfile
import SaveSessionDialog, OpenSessionDialog, ChangeIpDialog, SendProgressDialog
from tenjin.escaped import *
from tenjin.helpers import to_str
from deviceListCtrl import *
from util import PortSetting, Device
from wxTerm import *
from session_manager import *
import my_machine, traceback, session_manager
from HtmlMessageDialog import *
import tempfile
from pyterm.Terminal import Terminal

# 端口设置字段
ENUM_SETTING_DESC       = 0
ENUM_SETTING_RATE       = 1
ENUM_SETTING_BYTESIZE   = 2
ENUM_SETTING_PARITY     = 3
ENUM_SETTING_STOPBITS   = 4
ENUM_SETTING_DTRCONTROL = 5

engine = tenjin.SafeEngine()
license_mag = None
logging.basicConfig(filename = os.path.join(os.getcwd(), 'mytty_log.txt'), 
					format = '%(asctime)s - %(levelname)s: %(message)s', level = logging.INFO)


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
# 	m_staticText191: 发送提示
class MyttyFrame(Mytty.Mytty):
	def __init__(self):
		super(MyttyFrame, self).__init__(None)

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

		self.icon = wx.Icon("my.png", wx.BITMAP_TYPE_ICO)
		self.SetIcon(self.icon)
		self.is_clear_cmd = False
		self.init_inline_datas()
		
		try:
			session_manager.session_manag.InitConfig()
		except Exception, e:
			os.system('copy /y config\\sessions config\\sessions.back')
			open('config/sessions', 'w').write('{}')
			util.ShowMessageDialog(None, u'读取会话文件sessions出错，已备份到session.back。错误：%s' % e, u'警告')
			session_manager.session_manag.InitConfig()

		wx.CallAfter(self.m_listCtrl1.ImportDeviceDatas, u'config/设备数据.xls')

	def init_inline_datas(self):
		str = open(u'config/进线口.txt').read().strip().decode('utf8')
		inline_list = str.split('\n')
		self.inline_dic = {}
		for inline in inline_list:
			tmp = inline.split('=')
			self.inline_dic[tmp[0]] = tmp[1]

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
			if session_manager.session_manag.SaveSession(session, save_name, save_path):
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
		doc = os.path.join(os.path.realpath(os.path.dirname(".")), "documents/help.chm")
		webbrowser.open(doc)
	
	def OnAbout( self, event ):
		dlg = wx.MessageDialog(self, u" 版本：设备简易配置程序-v2.3.6 \n\n 联系方式：\n      联系人：谢先生\n      手机   ：13575121258 \n      邮箱   ：348588919@qq.com\n版权所有 2013-2020 nx创意软件工作室\n保留一切权利", u"关于", wx.OK)
		dlg.ShowModal()
		dlg.Destroy()
	
	def OnConnectionPageChanged( self, event ):
		event.Skip()
	
	def OnOpenSerialPort( self, event ):
		if self.m_comboBox1.GetSelection() == wx.NOT_FOUND:
			# self.m_statusBar1.SetStatusText(u"请选择端口")
			util.ShowMessageDialog(self, u"请选择端口", u'提示')
			return

		if self.m_choice8.GetSelection() == wx.NOT_FOUND:
			# self.m_statusBar1.SetStatusText(u"请选择端口设置")
			util.ShowMessageDialog(self, u"请选择端口设置", u'提示')
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
			# self.m_statusBar1.SetStatusText(u"请选择模板")
			util.ShowMessageDialog(self, u"请选择模板", u'提示')
			return
		device = self.m_listCtrl1.GetSelectedDevice()
		if device == None:
			# self.m_statusBar1.SetStatusText(u"请选择一条设备数据")
			util.ShowMessageDialog(self, u"请选择一条设备数据", u'提示')
			return
		content = u'此动作会生成清除设备中所有配置的命令，是否继续？'
		dlg = wx.MessageDialog(self, content, u"提示", wx.OK|wx.CANCEL)
		if dlg.ShowModal() == wx.ID_OK :
			# tpl_file = "templates/" + self.m_choice9.GetStringSelection() + ".tpl"
			tpl_file = os.path.join(self.temp_tpls_dir, self.m_choice9.GetStringSelection() + ".tpl")
			tpl_file = tpl_file.encode('gbk')
			fd = open(tpl_file, 'r')
			self.m_textCtrl6.SetValue(fd.read())
			self.is_clear_cmd = True

	def OnGenerateTemplate( self, event ):
		if self.m_choice7.GetSelection() == wx.NOT_FOUND:
			# self.m_statusBar1.SetStatusText(u"请选择模板")
			util.ShowMessageDialog(self, u"请选择模板", u'提示')
			return
		device = self.m_listCtrl1.GetSelectedDevice()
		if device == None:
			# self.m_statusBar1.SetStatusText(u"请选择一条设备数据")
			util.ShowMessageDialog(self, u"请选择一条设备数据", u'提示')
			return

		if self.m_listCtrl1.GetRowLabelValue(self.m_listCtrl1.GetSelectedRows()[0]) == u'已配置':
			dlg = wx.MessageDialog(self, u'该设备已配置过，是否再次进行操作', u'提示', wx.OK | wx.CANCEL)
			if dlg.ShowModal() != wx.ID_OK:
				return

		content = u"您选择的设备数据如下：\n\t设备类型：       " + device.dev_type + \
										u"\n\t安装地址：       " + device.dev_addr + \
										u"\n\t管理地址：       " + device.mangr_ip + \
										u"\n\t子网掩码：       " + device.submask_ip + \
										u"\n\t默认网关：       " + device.gateway_ip + \
										u"\n\t管理vlan：       " + str(device.mangr_vlan) + \
										u"\n\t端口开始vlan： " + str(device.begin_vlan) + \
										u"\n\t端口结束vlan： " + str(device.end_vlan) + \
										u"\n\t进线口：          " + self.inline_dic.get(device.dev_type, "1") + \
										u"\n是否确定生成命令？"

		dlg = wx.MessageDialog(self, content, u"提示", wx.OK|wx.CANCEL)
		if dlg.ShowModal() == wx.ID_OK :
			# tpl_file = "templates/" + self.m_choice7.GetStringSelection() + ".tpl"
			tpl_file = os.path.join(self.temp_tpls_dir, self.m_choice7.GetStringSelection() + ".tpl")
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
			# util.ExecuteCmd('del .\\templates\\*.cache')
			self.m_textCtrl6.SetValue(content)
			self.is_clear_cmd = False
	
	def OnSendTemplate( self, event ):
		tpl_content = self.m_textCtrl6.GetValue()
		if tpl_content == '':
			# self.m_statusBar1.SetStatusText(u"还没有生成命令")
			util.ShowMessageDialog(self, u"还没有生成命令", u'提示')
			return
		if not self.AssertOpenSession():
			return
		send_interval = self.GetSendInterval()

		cmd_list = tpl_content.split("\n")
		dlg = HtmlMessageDialog(self, u'提示', u'<font color="red"><p>请仔细比对发送提示和窗口输出</p><p>是否确认发送？</p></font>')
		if dlg.ShowModal() == wx.ID_OK:
			self.SendCommand(cmd_list, send_interval)
		
		# self.StartSendTplCmdThread(cmd_list, send_interval)

	def SendCommand(self, cmd_list, send_interval, from_template=True):
		session  = self.GetCurActivatedSession()
		dlg      = MySendProgressDialog(self, cmd_list, send_interval, session, self.is_clear_cmd)
		dlg.ShowModal()
		dlg.Destroy()
		self.m_textCtrl6.SetValue('')
		if from_template:
			row = self.m_listCtrl1.GetSelectedRows()[0]
			max_col = deviceListCtrl.MAX_COL
			for col in xrange(0,max_col + 1):
				self.m_listCtrl1.SetCellTextColour(row, col, wx.Colour(255, 0, 0))
			self.m_listCtrl1.SetRowLabelValue(row, u'已配置')


	def OnSendCmdKeyUp( self, event ):
		event.Skip()
		if event.GetKeyCode() == wx.WXK_RETURN:
			if event.ShiftDown():
				content = self.m_textCtrl71.GetValue()
				if content != '' and self.AssertOpenSession():
					send_interval = self.GetSendInterval()
					cmd_list = content.split("\n")
					self.SendCommand(cmd_list, send_interval, False)
					# self.StartSendTplCmdThread(cmd_list, send_interval)
				self.m_textCtrl71.Clear()

	def OnSessionPageChanged( self, event ):
		event.Skip()
		tab_title = self.m_auinotebook2.GetPageText(event.GetSelection())
		session = session_manager.session_manag.GetSessionByName(tab_title)
		if session:
			self.SetConnectionInfo(session)
			self.m_textCtrl71.Enable(True)

	def OnSessionPageClose( self, event ):
		dlg = wx.MessageDialog(self, u"确定要关闭连接？", u"提示", wx.OK|wx.CANCEL)
		if dlg.ShowModal() == wx.ID_OK:
			session = self.GetCurActivatedSession()
			session_manager.session_manag.RemoveSession(session)
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
				session_manager.session_manag.CloseAllSessions()
				event.Skip()
				util.ExecuteCmd('rd /Q /S ' + self.temp_tpls_dir)
			else:
				event.Veto()
		else:
			util.ExecuteCmd('rd /Q /S ' + self.temp_tpls_dir)
			event.Skip()


	def OpenSession(self, session):
		if session.Open():
			session_manager.session_manag.AddSession(session)
			tabPanel = wx.Panel( self.m_auinotebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
			# tabPanel = Terminal( self.m_auinotebook2, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.TAB_TRAVERSAL )
			self.m_auinotebook2.AddPage( tabPanel, session.GetSessionName(), True, wx.NullBitmap )
			self.SetConnectionInfo(session)

			tabPanelSizer = wx.BoxSizer( wx.VERTICAL )
			self.terminate = wxTerm(tabPanel, "", session = session)
			tabPanelSizer.Add( self.terminate, 1, wx.ALL|wx.EXPAND, 1 )
			tabPanel.SetSizer( tabPanelSizer )
			tabPanel.Layout()
			self.m_textCtrl71.Enable(True)
			util.ShowMessageDialog(self, u"连接成功", u"提示")
			session.Write('\n')
		else:
			util.ShowMessageDialog(self, u"连接：%s 打开失败" % session.GetSessionInfo(), u"错误")

	def StartSendTplCmdThread(self, cmd_list, send_interval):
		self.send_thread = threading.Thread(target=self.SendTplCmdThread, args = (cmd_list, send_interval))
		self.send_thread.setDaemon(1)
		self.send_thread.start()

	def SendTplCmdThread(self, cmd_list, send_interval):
		session = self.GetCurActivatedSession()
		for cmd in cmd_list:
			cmd = cmd + '\n'
			# print "send cmd: [%s]end" % (cmd)
			cmd = cmd.encode('ascii')
			try:
				session.Write(cmd)
			except Exception, e:
				logging.error('send command: (%s) failed, exception: %s', *(cmd, e))
			# event = wx.KeyEvent(eventType=wx.wxEVT_CHAR)
			# for ch in cmd:
			# 	event.m_keyCode = ord(ch)
			# 	# session.term.WriteText(ch)
			# 	session.term.OnTerminalChar(event)
			# 	# wx.PostEvent(self.terminate, event) 
			time.sleep(send_interval/1000.0)

			if not session.IsAlive():
				# self.m_statusBar1.SetStatusText(u"连接已断开，发送模板数据已终止！")
				util.ShowMessageDialog(self, u"连接已断开，发送模板数据已终止！", u'提示')
				break

		self.send_thread = None

	def GetCurActivatedSession(self):
		selected_tab = self.m_auinotebook2.GetSelection()
		if selected_tab >= 0:
			tab_title = self.m_auinotebook2.GetPageText(self.m_auinotebook2.GetSelection())
			session = session_manager.session_manag.GetSessionByName(tab_title)
			return session
		else:
			return None

	def AssertOpenSession(self):
		selected_tab = self.m_auinotebook2.GetSelection()
		if selected_tab == -1:
			self.m_statusBar1.SetStatusText(u"当前没有连接的会话")
			util.ShowMessageDialog(self, u"当前没有连接的会话", u'提示')
			return False
		return True

	def GetSendInterval(self):
		send_interval = 300
		try:
			send_interval = int(self.m_textCtrl7.GetValue())
		except Exception, e:
			self.m_textCtrl7.SetValue("300")
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
		self.tpls_tar = zipfile.ZipFile("templates/templates.zip")
		self.temp_tpls_dir = tempfile.mkdtemp()
		logging.info('unzip templates.zip to directory: %s' % (self.temp_tpls_dir))
		self.tpls_tar.extractall(self.temp_tpls_dir)
		# for item in self.tpls_tar.namelist():
		# 	if item.endswith(".tpl"):
		# 		tpl = os.path.basename(item)
		# 		self.cmd_tpl_list.append(tpl[:-4])
		# return self.cmd_tpl_list
		for item in os.listdir(self.temp_tpls_dir):
			if item.endswith(".tpl"):
				tpl = os.path.basename(item)
				self.cmd_tpl_list.append(tpl[:-4])
		return self.cmd_tpl_list

	def SetSendPrompt(self, prompt):
		print "prompt:", prompt
		self.m_staticText191.SetLabel(u' | 发送提示：' + prompt)

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
			if session_manager.session_manag.IsNameExist(save_name):
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
		for session in session_manager.session_manag.saved_sessions:
			print "open init:", session
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
		return session_manager.session_manag.GetSavedSessionByName(session_name)

	def OnItemActivated( self, event ):
		pass

	def OnDeleteSession( self, event ):
		session = self.GetSelectedSession()
		if session == None:
			return None
		session_name = session.GetSessionName()
		if session_manager.session_manag.DeleteSavedSessionByName(session_name):
			self.m_listCtrl2.DeleteItem(self.m_listCtrl2.GetFirstSelected())
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
		self.m_textCtrl14.SetValue('255.255.255.0')
		self.m_textCtrl15.SetValue('192.168.1.1')
		
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

		if ip == "" or mask == "":
			util.ShowMessageDialog(self, u"ip地址或子网掩码不能为空", u"错误操作")
			return
		if gateway == "":
			cmd = "netsh interface ip set address name=\"%s\" source=static addr=%s mask=%s gateway=none 1" % (connection_name, ip, mask)
		else:
			cmd = "netsh interface ip set address name=\"%s\" source=static addr=%s mask=%s gateway=%s 1" % (connection_name, ip, mask, gateway)
		result = util.ExecuteCmd(cmd.encode('gbk')).strip()
		result_utf8 = result.decode('gbk')
		# print "result: [%s]" % (result)
		if result_utf8 == u'' or result_utf8 == u'\n' or result_utf8 == u'ok' or result_utf8 == u'确定':
			result = u'修改成功'
		util.ShowMessageDialog(self, result, u"执行结果")
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
			# for key in self.license_dic.keys():
			# 	self.license_dic[key] = base64.decodestring(self.license_dic[key])
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
		return (self.license_dic.get('cpu.ProcessorId', 'None') == cpu.get('cpu.ProcessorId', 'None') and \
				self.license_dic.get('physical_disk.SerialNumber', 'None') == disk.get('physical_disk.SerialNumber', 'None') and \
			    self.license_dic.get('bios_id.SerialNumber', 'None') == bios.get('bios_id.SerialNumber', 'None') and \
			    self.license_dic.get('mac.MACAddress', 'None') == mac.get('mac.MACAddress', 'None'))

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
		# encrypt_dic = {}
		# for key in self.license_dic.keys():
		# 	encrypt_dic[key] = base64.encodestring(self.license_dic[key])

		encrypt_str =  base64.encodestring(u'dzr' + str(self.license_dic))
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

class MySendProgressDialog(SendProgressDialog.SendProgressDialog):
	"""docstring for MySendProgressDialog"""
	def __init__(self, parent, cmd_list, send_interval, session, is_clear_cmd):
		super(MySendProgressDialog, self).__init__(parent)
		self.parent        = parent
		self.cmd_list      = cmd_list
		self.session       = session
		self.send_interval = send_interval
		self.is_clear_cmd  = is_clear_cmd
		self.current_count = 0
		self.total_count   = len(self.cmd_list)
		self.m_gauge2.SetRange(self.total_count)
		self.m_staticText21.SetLabel(self.cmd_list[self.current_count])
		self.timer = wx.Timer(self, 1)
		self.Bind(wx.EVT_TIMER, self.OnTimer, self.timer)
		self.timer.Start(self.send_interval)

	def BeginSendProgress(self):
		cmd = self.cmd_list[self.current_count]
		cmd = cmd + '\n'
		cmd = cmd.encode('ascii')
		try:
			self.session.Write(cmd)
		except Exception, e:
			logging.error('send command: (%s) failed, exception: %s', *(cmd, e))

		# time.sleep(self.send_interval)
		self.current_count = self.current_count + 1

		if self.current_count >= self.total_count:
			if self.is_clear_cmd:
				self.m_staticText24.SetLabel(u"清除设备配置完毕，请等待设备重启")
			else:
				self.m_button15.Enable( True )
				self.m_staticText24.SetLabel(u"命令发送完毕，请做好标签拔掉连接线更换配置设备")
		else:
			self.m_staticText21.SetLabel(self.cmd_list[self.current_count])
			if not self.session.IsAlive():
				util.ShowMessageDialog(self, u"连接已断开，发送模板数据已终止！", u"错误")
				self.timer.Stop()
				# self.parent.m_statusBar1.SetStatusText(u"连接已断开，发送模板数据已终止！")

		
			
	def OnTimer(self, event):
		# print("on timer")
		self.BeginSendProgress()
		self.m_gauge2.SetValue(self.current_count + 1)
		if self.current_count >= self.total_count:
			self.timer.Stop()
			if self.is_clear_cmd:
				self.m_gauge2.SetRange(50)
				self.reboot_count = 0
				self.reboot_timer = wx.Timer(self, 1)
				self.Bind(wx.EVT_TIMER, self.OnDeviceRebootTimer, self.reboot_timer)
				self.reboot_timer.Start(1000)

	def OnDeviceRebootTimer(self, event):
		self.reboot_count = self.reboot_count + 1
		self.m_gauge2.SetValue(self.reboot_count)
		if self.reboot_count >= 50:
			self.reboot_timer.Stop()
			self.m_staticText24.SetLabel(u"设备重启完毕！")
			self.m_button15.Enable( True )

		
		

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


	
	