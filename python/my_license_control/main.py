#! /usr/bin/env python
# -*- coding: utf8 -*- 

import AuthorizeFrame, wx, base64, os, datetime

def ParseLicenseFile(path):
	fd = open(path, "r")
	dic = eval(base64.decodestring(fd.read()))
	print dic

def ShowMessageDialog(parent, content, title):
    dlg = wx.MessageDialog(parent, content, title, wx.OK)
    dlg.ShowModal()
    dlg.Destroy()

#控件说明：
# 	m_textCtrl11: cpu
# 	m_textCtrl12: disk
# 	m_textCtrl13: bios
# 	m_textCtrl14: mac
# 	m_datePicker1: 起始日期
# 	m_datePicker2: 结束日期
# 	m_radioBtn1: 试用版
# 	m_radioBtn2: 注册版
class MyFrame(AuthorizeFrame.MyLicenseControlFrame):
	"""docstring for MyFrame"""
	def __init__(self):
		super(MyFrame, self).__init__(None)
		self.license_dic = None
		self.m_button16.Enable(False)

	def OnOpenDestComputerInfo( self, event ):
		dlg = wx.FileDialog(self, message=u"选择文件", style=wx.OPEN | wx.CHANGE_DIR)
		if dlg.ShowModal() == wx.ID_OK:
			path = dlg.GetPath()
			print "You chose the following file(s):", path
			try:
				fd = open(path, "r")
				dic = eval(base64.decodestring(fd.read()))
				print dic
				self.m_textCtrl11.SetValue(base64.decodestring(dic['cpu'])[3:])
				self.m_textCtrl12.SetValue(base64.decodestring(dic['disk'])[3:])
				self.m_textCtrl13.SetValue(base64.decodestring(dic['bios'])[3:])
				self.m_textCtrl14.SetValue(base64.decodestring(dic['mac'])[3:])
				self.license_dic = dic
				self.m_button16.Enable(True)
			except Exception, e:
				ShowMessageDialog(self, u'解析目标机器数据出错，可能是数据格式不对！异常信息：' + str(e), u'错误')
			
		dlg.Destroy()

	def OnAuthorize( self, event ):
		try:
			print self.m_datePicker1.GetValue().FormatISODate()
			self.license_dic['start_date'] = base64.encodestring(u'dzr' + self.m_datePicker1.GetValue().FormatISODate())
			self.license_dic['end_date'] = base64.encodestring(u'dzr' + self.m_datePicker2.GetValue().FormatISODate())
			now = datetime.datetime.today()
			self.license_dic['using_logs'] = base64.encodestring(u'dzr' + now.strftime('%Y-%m-%d %H:%M:%S'))
			print "111"
			if self.m_radioBtn1.GetValue():
				self.license_dic['version'] = base64.encodestring(u'dzr1') #试用版
			else:
				self.license_dic['version'] = base64.encodestring(u'dzr2') #注册版

			print self.license_dic
			path        = './license.license'
			fd          = open(path, 'w')
			encrypt_str =  base64.encodestring(str(self.license_dic))
			fd.write(encrypt_str)
			fd.flush()
			fd.close()
			print os.path.abspath(path)
			ShowMessageDialog(self, u"生成license文件成功，保存路径：%s" % (os.path.abspath(path)), u"信息")
		except Exception, e:
			ShowMessageDialog(self, u"生成license文件失败，发送异常：%s" % (e), u"错误")

if __name__ == "__main__":
	app = wx.PySimpleApp(0)
	wx.InitAllImageHandlers()
	frame_1 = MyFrame()
	app.SetTopWindow(frame_1)
	frame_1.Show()
	app.MainLoop()
