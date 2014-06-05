#!/usr/bin/env python
# -*- coding: utf8 -*-

def format_table(headers, rows):
	cols = len(headers)
	col_max_lens = [0] * cols
	def find_max_len():
		col_num = 0
		for item in headers:
			length = len(item)
			if length > col_max_lens[col_num]:
				col_max_lens[col_num] = length
			col_num = col_num + 1
		for row in rows:
			col_num = 0
			for item in row:
				length = len(item)
				if length > col_max_lens[col_num]:
					col_max_lens[col_num] = length
				col_num = col_num + 1
		
	find_max_len()
	print_tab_header(headers, col_max_lens)
	for row in rows:
		print_tab_row(row, col_max_lens)
	print_tab_delimiter("-", col_max_lens)

def print_tab_row(row, col_max_lens, is_center = False):
	cols = len(col_max_lens)
	for i in xrange(0, cols):
		if is_center:
			print(u"| %s" % (u"{0:^%s}" % (col_max_lens[i] + 1)).format(row[i])),
		else:
			print(u"| %s" % (u"{0:<%s}" % (col_max_lens[i] + 1)).format(row[i])),
	print("|")

def print_tab_header(headers, col_max_lens):
	print_tab_delimiter("-", col_max_lens)
	cols = len(col_max_lens)
	print_tab_row(headers, col_max_lens, True)
	print_tab_delimiter("-", col_max_lens)


def print_tab_delimiter(delimiter, col_max_lens):
	cols = len(col_max_lens)
	for i in xrange(0, cols):
		print("+"),
		print(u"%s" % (u"{0:%s^%s}" % (delimiter, col_max_lens[i] + 1)).format("")),
	print("+")