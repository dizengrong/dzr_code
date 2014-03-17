#!/usr/bin/env python
# -*- coding: utf8 -*-

import util, serial, os, telnetlib, time, json
from util import PortSetting


class SessionBase(object):
	"""会话基础类，包含公共的方法与抽象"""
	def __init__(self):
		super(SessionBase, self).__init__()
		self.log_file = None
		self.log_fd = None
		self.session_name = ""

	def Open(self):
		return False

	def Close(self):
		if self.log_fd:
			self.log_fd.close()
		
	def Write(self, data):
		pass

	def Read(self, size):
		pass

	def IsAlive(self):
		False

	def IsOpen(self):
		return self.IsAlive()

	def SetLogFile(self, log_file):
		self.log_file = log_file

	def StartLog(self):
		if not (self.log_file == "" or self.log_file == None):
			try:
				self.log_fd = open(self.log_file, "a+")
			except Exception, e:
				print "start log session in file: %s failed, exception: %s" % (self.log_file, e)

	def Log(self, msg):
		if self.log_fd:
			self.log_fd.write(msg)
			self.log_fd.flush()

	def GetSessionInfo(self):
		pass

	def GetSessionType(self):
		pass

	def GetSessionName(self):
		pass

	def ChangeSessionName(self, new_name):
		self.session_name = new_name


class SerialSession(SessionBase):
	def __init__(self, port_str, setting, session_name = None):
		super(SerialSession, self).__init__()
		self.port_str = port_str
		self.port_setting = setting

		self.handler          = serial.Serial()
		self.handler.port     = port_str
		self.handler.baudrate = self.port_setting.baudRate
		self.handler.bytesize = self.port_setting.byteSize
		self.handler.stopbits = self.port_setting.stopBits
		self.handler.parity   = self.port_setting.parity
		self.handler.rtscts   = self.port_setting.dtrControl
		self.handler.setTimeout(0.1)
		if session_name is not None:
			self.session_name = session_name
		else:
			self.session_name = session_manager.UniqueSessionName("serial_" + port_str)

	def Open(self):
		try:
			self.handler.open()
			self.StartLog()
			return True
		except Exception, e:
			print u"Open serial port %s failed, exception: %s" % (self.port_str, e)
			return False

	def Close(self):
		super(SerialSession, self).Close()
		self.handler.close()

	def Write(self, data):
		self.handler.write(data)

	def Read(self, size):
		if self.IsAlive():
			return self.handler.read(size)
		else:
			return ""

	def IsAlive(self):
		return self.handler.isOpen()

	def GetSessionInfo(self):
		return "serial %s %d %d %d %s" % (self.port_str, self.handler.baudrate, self.handler.bytesize, self.handler.stopbits, self.handler.parity)
	
	def GetSessionType(self):
		return "serial" 

	def GetSessionName(self):
		return self.session_name

# 香港公共图书馆的telnet		
# telnet://202.85.101.136:8603

class TelnetSession(SessionBase):
	def __init__(self, ip, port = 23, session_name = None, username = '', password = ''):
		super(TelnetSession, self).__init__()
		self.ip = ip
		self.port = port
		self.username = username
		self.password = password
		
		if session_name is not None:
			self.session_name = session_name
		else:
			self.session_name = session_manager.UniqueSessionName("telnet_" + ip)
		print self.session_name

	def Open(self):
		try:
			self.handler = telnetlib.Telnet(self.ip, port = self.port, timeout = 3)
			if self.username != '':
				self.handler.read_until('login: ', timeout = 2)
				self.handler.write(self.username + '\n')

				self.handler.read_until('password: ', timeout = 2)
				self.handler.write(self.username + '\n')

			self.StartLog()
			return True
		except Exception, e:
			print u"telnet %s failed, exception: %s" % (self.ip, e)
			return False

	def Close(self):
		super(TelnetSession, self).Close()
		self.handler.close()

	def Read(self, size):
		if self.IsAlive():
			time.sleep(0.03)
			return self.handler.read_some()
		else:
			return ""

	def Write(self, data):
		self.handler.write(data)

	def IsAlive(self):
		return True

	def GetSessionInfo(self):
		return "telnet %s:%d" % (self.ip, self.port)
	
	def GetSessionType(self):
		return "telnet" 

	def GetSessionName(self):
		return self.session_name

										