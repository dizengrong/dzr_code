#!/usr/bin/env python
# -*- coding: utf8 -*-
import util, serial, os, telnetlib, time, json
from util import PortSetting

#使用__metaclass__（元类）的高级python用法
class Singleton(type):
	def __init__(cls, name, bases, dict):
		super(Singleton, cls).__init__(name, bases, dict)
		cls._instance = None
	def __call__(cls, *args, **kw):
		if cls._instance is None:
			cls._instance = super(Singleton, cls).__call__(*args, **kw)
		return cls._instance

class SessionManager(object):
	"""会话管理类，为单例模式"""
	__metaclass__ = Singleton
	def __init__(self):
		super(SessionManager, self).__init__()
		self.sessions = []
		self.saved_sessions = None
		self.session_conf = {}
	def InitConfig(self):
		if self.saved_sessions == None:
			self.saved_sessions = []
			# 读取配置
			# try:
			self.session_conf = json.loads(open("config/sessions").read())
			for session_name in self.session_conf.keys():
				print session_name
				if self.session_conf[session_name]['type'] == 'serial':
					port_setting = PortSetting(int(self.session_conf[session_name]['baudRate']),
											   int(self.session_conf[session_name]["byteSize"]),
											   self.session_conf[session_name]["parity"],
											   int(self.session_conf[session_name]["stopBits"]),
											   int(self.session_conf[session_name]["dtrControl"]))
					session = SerialSession(self.session_conf[session_name]["port"], 
											port_setting, session_name = session_name)
				else:
					session = TelnetSession(self.session_conf[session_name]["ip"], 
											int(self.session_conf[session_name]["port"]), 
											session_name = session_name)
				log_file = self.session_conf[session_name]["logFile"]
				session.SetLogFile(log_file)
				self.saved_sessions.append(session)
			# except Exception, e:
				# print e
				# util.ShowMessageDialog(None, u'读取会话文件出错，会话文件将被还原。错误：%s' % e, u'警告')
			
	# def InitConfig(self):
	# 	if self.saved_sessions == None:
	# 		self.saved_sessions = []

	# 		# 读取配置
	# 		self.session_conf = ConfigParser.ConfigParser()
	# 		self.session_conf.read("config/sessions")
	# 		self.total_session = self.session_conf.get("global", "total_session")
	# 		for session_name in self.total_session.split('||'):
	# 			if session_name == "":
	# 				continue
	# 			if self.session_conf.get(session_name, "type") == "serial":
	# 				portstr = self.session_conf.get(session_name, "port")
	# 				baudRate = int(self.session_conf.get(session_name, "baudRate"))
	# 				byteSize = int(self.session_conf.get(session_name, "byteSize"))
	# 				parity = self.session_conf.get(session_name, "parity")
	# 				stopBits = int(self.session_conf.get(session_name, "stopBits"))
	# 				dtrControl = int(self.session_conf.get(session_name, "dtrControl"))
	# 				port_setting = PortSetting(int(baudRate), int(byteSize), parity, int(stopBits), int(dtrControl))
	# 				session = SerialSession(portstr, port_setting, session_name = session_name)
	# 			else:
	# 				ip = self.session_conf.get(session_name, "ip")
	# 				port = int(self.session_conf.get(session_name, "port"))
	# 				# username = self.session_conf.get(session_name, "username")
	# 				# password = self.session_conf.get(session_name, "password")
	# 				session = TelnetSession(ip, port, session_name = session_name)
	# 			log_file = self.session_conf.get(session_name, "logFile")
	# 			session.SetLogFile(log_file)
	# 			self.saved_sessions.append(session)

	def AddSession(self, session):
		self.sessions.append(session)

	def AddSavedSession(self, session):
		self.saved_sessions.append(session)

	def RemoveSession(self, session):
		self.sessions.remove(session)

	def RemoveSavedSession(self, session):
		try:
			self.saved_sessions.remove(session)
		except Exception, e:
			pass
		

	def CloseAllSessions(self):
		for session in self.sessions:
			session.Close()

	def GetSessionByName(self, session_name):
		for session in self.sessions:
			if session.GetSessionName() == session_name:
				return session
		else:
			return None

	def GetSavedSessionByName(self, session_name):
		for session in self.saved_sessions:
			if session.GetSessionName() == session_name:
				return session
		else:
			return None

	def GetTotalSessionStr(self):
		s = ""
		for session in self.saved_sessions:
			s = s + session.GetSessionName() + "||"
		else:
			if s.endswith("||"):
				s = s[:-2]
		return s

	def DeleteSavedSessionByName(self, session_name):
		print session_name
		for session in self.saved_sessions:
			print "for:", session.GetSessionName()
			if session.GetSessionName() == session_name:
				self.RemoveSavedSession(session)
				# ret_val = self.session_conf.remove_section(session_name)
				del self.session_conf[session_name]
				open('config/sessions', 'w').write(json.dumps(self.session_conf))
				# self.total_session = self.GetTotalSessionStr()
				# self.session_conf.set("global", "total_session", self.total_session)
				# self.session_conf.write(open("config/sessions", "w"))
				return True
		else:
			return False

	def UniqueSessionName(self, session_name):
		"""返回经过唯一化的会话名称"""
		count = 1
		while True:
			for session in self.sessions:
				if session_name == session.GetSessionName():
					if session_name[-3:] == "(" + str(count - 1) + ")":
						session_name = session_name[:-3] + "(" + str(count) + ")" 
					else:
						session_name = session_name + "(" + str(count) + ")" 
					count += 1
					break
			else:
				return session_name

	def IsNameExist(self, name):
		for session in self.sessions:
			if name == session.GetSessionName():
				return True
		else:
			for session in self.saved_sessions:
				if name == session.GetSessionName():
					return True
		return False

	def SaveSession(self, session, save_name, save_path):
		if self.GetSavedSessionByName(save_name):
			return False
		else:
			new_sec_name = save_name
			session_type = session.GetSessionType()
			self.session_conf[new_sec_name] = {}
			self.session_conf[new_sec_name]['type'] = session_type
			self.session_conf[new_sec_name]['logFile'] = save_path.encode('utf8')
			if session_type == "serial":
				self.session_conf[new_sec_name]['port'] = session.port_str	
				self.session_conf[new_sec_name]['baudRate'] = str(session.port_setting.baudRate)	
				self.session_conf[new_sec_name]['byteSize'] = str(session.port_setting.byteSize)	
				self.session_conf[new_sec_name]['parity'] = session.port_setting.parity	
				self.session_conf[new_sec_name]['stopBits'] = str(session.port_setting.stopBits)	
				self.session_conf[new_sec_name]['dtrControl'] = str(session.port_setting.dtrControl)
			else:
				self.session_conf[new_sec_name]['ip'] = session.ip	
				self.session_conf[new_sec_name]['port'] = session.port
			self.AddSavedSession(session)
			open('config/sessions', 'w').write(json.dumps(self.session_conf))
			session.ChangeSessionName(save_name)
			session.SetLogFile(save_path)
			session.StartLog()
			return True
	# def SaveSession(self, session, save_name, save_path):
	# 	if self.GetSavedSessionByName(save_name):
	# 		return False
	# 	else:
	# 		self.DeleteSavedSessionByName(session.GetSessionName())
	# 		self.total_session += "||" + save_name
	# 		new_sec_name = save_name
	# 		session_type = session.GetSessionType()
	# 		self.session_conf.add_section(new_sec_name)
	# 		self.session_conf.set(new_sec_name, "type", session_type)
	# 		self.session_conf.set(new_sec_name, "logFile", save_path.encode('utf8'))
	# 		if session_type == "serial":
	# 			self.session_conf.set(new_sec_name, "port", session.port_str)
	# 			self.session_conf.set(new_sec_name, "baudRate", str(session.port_setting.baudRate))
	# 			self.session_conf.set(new_sec_name, "byteSize", str(session.port_setting.byteSize))
	# 			self.session_conf.set(new_sec_name, "parity", session.port_setting.parity)
	# 			self.session_conf.set(new_sec_name, "stopBits", str(session.port_setting.stopBits))
	# 			self.session_conf.set(new_sec_name, "dtrControl", str(session.port_setting.dtrControl))
	# 		else:
	# 			self.session_conf.set(new_sec_name, "ip", session.ip)
	# 			self.session_conf.set(new_sec_name, "port", session.port)
	# 			# self.session_conf.set(new_sec_name, "username", session.username)
	# 			# self.session_conf.set(new_sec_name, "password", session.password)

	# 		self.AddSavedSession(session)
	# 		self.session_conf.set("global", "total_session", self.total_session)
	# 		self.session_conf.write(open("config/sessions", "w"))
	# 		session.ChangeSessionName(save_name)
	# 		session.SetLogFile(save_path)
	# 		session.StartLog()
	# 		return True

session_manag = SessionManager()

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
			self.session_name = session_manag.UniqueSessionName("serial_" + port_str)

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
			self.session_name = session_manag.UniqueSessionName("telnet_" + ip)
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

										
	