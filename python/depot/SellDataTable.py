# -*- coding: utf-8 -*- 

import wx.grid, wx

class SellDataTable(wx.grid.PyGridTableBase):
	def __init__(self):
		super(SellDataTable, self).__init__()

		self.colLabels = [u'交易id', u'产品分类', u'产品型号', u'买家', u'成交的单价', 
						  u'成交数量', u'计算所得总价', u'实际成交总价', u'已收款', u'剩余欠款', u'成交日期']

		# self.dataTypes = [wxGRID_VALUE_NUMBER,
		# 				  wxGRID_VALUE_STRING,
		# 				  wxGRID_VALUE_CHOICE + ':only in a million years!,wish list,minor,normal,major,critical',
		# 				  wxGRID_VALUE_NUMBER + ':1,5',
		# 				  wxGRID_VALUE_CHOICE + ':all,MSW,GTK,other',
		# 				  wxGRID_VALUE_BOOL,
		# 				  wxGRID_VALUE_BOOL,
		# 				  wxGRID_VALUE_BOOL,
		# 				  wxGRID_VALUE_FLOAT + ':6,2',
		# 				  ]
		self.data = []


	#--------------------------------------------------
	# required methods for the wxPyGridTableBase interface

	def GetNumberRows(self):
		return len(self.data) + 1

	def GetNumberCols(self):
		return len(self.colLabels)

	def IsEmptyCell(self, row, col):
		try:
			return not self.data[row][col]
		except IndexError:
			return True

	# Get/Set values in the table.  The Python version of these
	# methods can handle any data-type, (as long as the Editor and
	# Renderer understands the type too,) not just strings as in the
	# C++ version.
	def GetValue(self, row, col):
		try:
			return self.data[row][col]
		except IndexError:
			return ''

	def SetValue(self, row, col, value):
		try:
			self.data[row][col] = value
		except IndexError:
			# add a new row
			self.data.append([''] * self.GetNumberCols())
			self.SetValue(row, col, value)

			# tell the grid we've added a row
			msg = wxGridTableMessage(self,                             # The table
									 wxGRIDTABLE_NOTIFY_ROWS_APPENDED, # what we did to it
									 1)                                # how many

			self.GetView().ProcessTableMessage(msg)