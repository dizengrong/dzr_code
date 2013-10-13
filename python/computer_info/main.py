#! /usr/bin/env python
# -*- coding: utf8 -*- 

import my_machine, GenComputerInfoFrame, wx, csv, base64, os

def generate_computer_info():
	path = u'./computer_info'
	fd          = open(path, "w")
	machine = my_machine.Machine()
	dic         = {}
	dic['cpu']  = base64.encodestring(u'dzr' + machine.get_cpu_serial_no())
	dic['disk'] = base64.encodestring(u'dzr' + machine.get_disk_serial_no())
	dic['bios'] = base64.encodestring(u'dzr' + machine.get_bios_serial_no())
	dic['mac']  = base64.encodestring(u'dzr' + machine.get_mac_address())
	encrypt_str =  base64.encodestring(str(dic))
	print encrypt_str
	fd.write(encrypt_str)
	fd.flush()
	fd.close()
	return os.path.abspath(path)

def get_computer_info():
	fd = open(u"computer_info", "r")
	dic = eval(base64.decodestring(fd.read()))
	print dic
	return dic

def ShowMessageDialog(parent, content, title):
    dlg = wx.MessageDialog(parent, content, title, wx.OK)
    dlg.ShowModal()
    dlg.Destroy()

class MyFrame(GenComputerInfoFrame.GetComputerInfo):
	"""docstring for MyFrame"""
	def __init__(self):
		super(MyFrame, self).__init__(None)

	def OnExit( self, event ):
		self.Close(True)	

	def OnGenerateComputerInfo( self, event ):
		try:
			path = generate_computer_info()
			ShowMessageDialog(self, u"文件保存在：" + path, u"获取成功")
		except Exception, e:
			ShowMessageDialog(self, u"获取失败，发送异常：%s" % (e), u"获取失败")

if __name__ == "__main__":
	app = wx.PySimpleApp(0)
	wx.InitAllImageHandlers()
	frame_1 = MyFrame()
	app.SetTopWindow(frame_1)
	frame_1.Show()
	app.MainLoop()
