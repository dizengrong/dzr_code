#! /usr/bin/env python
# -*- coding: utf8 -*- 

import os, wmi

class Machine(object):
	"""docstring for Machine"""
	def __init__(self):
		super(Machine, self).__init__()
		self.wmi = wmi.WMI ()
		
	def get_cpu_info(self):
		fd = os.popen("wmic cpu list /format:csv")
		count = 0
		col = []
		row = []
		for i in csv.reader(fd):
			if count == 0:
				count += 1
				continue
			if count == 1:
				col = i
			if count == 2:
				row = i
			count += 1
		length = len(col)
		for i in xrange(0, length):
			describe = col[i].upper()
			if describe == 'PROCESSORID' or \
				describe == 'NAME' or \
				describe == 'VOLTAGECAPS':
				dic[describe] = row[i]
		return dic

	def get_cpu_serial_no(self):
		s = ''
		for cpu in self.wmi.Win32_Processor():
			s += cpu.ProcessorId.strip() + "|"
		return s[:-1]

	def get_disk_serial_no(self):
		s = ''
		for physical_disk in self.wmi.Win32_DiskDrive():
			s += physical_disk.SerialNumber.strip() + "|"
		return s[:-1]


	def get_bios_serial_no(self):
		for bios_id in self.wmi.Win32_BIOS():
			return bios_id.SerialNumber.strip()

	def get_mac_address(self):
		s = ''
		for mac in self.wmi.Win32_NetworkAdapter():
			if mac.AdapterTypeId != None and mac.AdapterTypeId == 0:
				if mac.PNPDeviceID[0:3] == 'PCI':
					s += mac.MACAddress + '|'
		return s[:-1]