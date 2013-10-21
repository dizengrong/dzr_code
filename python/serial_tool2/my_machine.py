#! /usr/bin/env python
# -*- coding: utf8 -*- 

import os, wmi

class Machine(object):
	"""docstring for Machine"""
	def __init__(self):
		super(Machine, self).__init__()
		self.wmi = wmi.WMI ()

	def get_cpu_serial_no(self):
		s = ''
		for cpu in self.wmi.Win32_Processor():
			tmp = ""
			try:
				tmp = cpu.ProcessorId.strip()
			except Exception, e:
				print "get cpu serial number exception: ", e
			s += tmp + "|"
		return s[:-1]

	def get_cpu_info(self):
		dic = {}
		for cpu in self.wmi.Win32_Processor():
			# if cpu.ProcessorId != None:
			# 	dic['cpu.ProcessorId'] = cpu.ProcessorId
			# else:
			# 	dic['cpu.ProcessorId'] = ''

			# if cpu.Name != None:
			# 	dic['cpu.Name'] = cpu.Name
			# else:
			# 	dic['cpu.Name'] = ''

			# if cpu.Version != None:
			# 	dic['cpu.Version'] = cpu.Version
			# else:
			# 	dic['cpu.Version'] = ''

			# if cpu.VoltageCaps != None:
			# 	dic['cpu.VoltageCaps'] = cpu.VoltageCaps
			# else:
			# 	dic['cpu.VoltageCaps'] = ''

			for p in cpu.properties:
				if cpu.__getattr__(p) != None:
					dic['cpu.' + p] = unicode(cpu.__getattr__(p))
				else:
					dic['cpu.' + p] = ''

			return dic

	def get_disk_info(self):
		dic = {}
		for physical_disk in self.wmi.Win32_DiskDrive():
			# if physical_disk.SerialNumber != None:
			# 	dic['physical_disk.SerialNumber'] = physical_disk.SerialNumber
			# else:
			# 	dic['physical_disk.SerialNumber'] = ''

			# if physical_disk.Caption != None:
			# 	dic['physical_disk.Caption'] = physical_disk.Caption
			# else:
			# 	dic['physical_disk.Caption'] = ''

			# if physical_disk.Size != None:
			# 	dic['physical_disk.Size'] = physical_disk.Size
			# else:
			# 	dic['physical_disk.Size'] = ''

			for p in physical_disk.properties:
				# print p
				if physical_disk.__getattr__(p) != None:
					dic['physical_disk.' + p] = unicode(physical_disk.__getattr__(p))
				else:
					dic['physical_disk.' + p] = ''
			
			return dic


	def get_bios_info(self):
		dic = {}
		for bios_id in self.wmi.Win32_BIOS():
			
			# if bios_id.SerialNumber != None:
			# 	dic['bios_id.SerialNumber'] = bios_id.SerialNumber
			# else:
			# 	dic['bios_id.SerialNumber'] = ''

			# if bios_id.Version != None:
			# 	dic['bios_id.Version'] = bios_id.Version
			# else:
			# 	dic['bios_id.Version'] = ''

			# if bios_id.Description != None:
			# 	dic['bios_id.Description'] = bios_id.Description
			# else:
			# 	dic['bios_id.Description'] = ''

			# if bios_id.BIOSVersion != None:
			# 	dic['bios_id.BIOSVersion'] = bios_id.BIOSVersion
			# else:
			# 	dic['bios_id.BIOSVersion'] = ''

			# if bios_id.Caption != None:
			# 	dic['bios_id.Caption'] = bios_id.Caption
			# else:
			# 	dic['bios_id.Caption'] = ''

			for p in bios_id.properties:
				if bios_id.__getattr__(p) != None:
					dic['bios_id.' + p] = unicode(bios_id.__getattr__(p))
				else:
					dic['bios_id.' + p] = ''

			return dic


	def get_mac_info(self):
		dic = {}
		for mac in self.wmi.Win32_NetworkAdapter():
			if mac.AdapterTypeId != None and mac.AdapterTypeId == 0:
				if mac.PNPDeviceID[0:3] == 'PCI':

					# if mac.MACAddress != None:
					# 	dic['mac.MACAddress'] = mac.MACAddress
					# else:
					# 	dic['mac.MACAddress'] = ''

					# if mac.Description != None:
					# 	dic['mac.Description'] = mac.Description
					# else:
					# 	dic['mac.Description'] = ''

					# if mac.InstallDate != None:
					# 	dic['mac.InstallDate'] = mac.InstallDate
					# else:
					# 	dic['mac.InstallDate'] = ''

					# if mac.PhysicalAdapter != None:
					# 	dic['mac.PhysicalAdapter'] = mac.PhysicalAdapter
					# else:
					# 	dic['mac.PhysicalAdapter'] = ''

					# if mac.ProductName != None:
					# 	dic['mac.ProductName'] = mac.ProductName
					# else:
					# 	dic['mac.ProductName'] = ''
					for p in mac.properties:
						if mac.__getattr__(p) != None:
							print unicode(mac.__getattr__(p))
							dic['mac.' + p] = unicode(mac.__getattr__(p))
						else:
							dic['mac.' + p] = ''

					return dic
