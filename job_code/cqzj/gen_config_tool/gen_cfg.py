# -*- coding: utf-8 -*- 

import tenjin, re, copy
from tenjin.helpers import *
from tenjin.escaped import *
import xdrlib, sys, xlrd, datetime, ConfigParser
from xml.dom import minidom
from tenjin.escaped import as_escaped

def get_attrvalue(node, attrname):
	return node.getAttribute(attrname) if node else ''

def get_nodevalue(node, index = 0):
	return node.childNodes[index].nodeValue if node else ''

def get_xmlnode(node, name):
	return node.getElementsByTagName(name) if node else []


def format(value):
    if isinstance(value, float):
        if int(value) == value: return int(value)
        else: return value
    elif isinstance(value, str):
        return as_escaped(value)
    else:
    	try:
    		return as_escaped(value)
    	except Exception, e:
    		return value

## create engine object
engine    = tenjin.SafeEngine()

doc       = minidom.parse('cfg.xml')
root      = doc.documentElement


path_cfg  = ConfigParser.ConfigParser()
path_cfg.read('path.ini')
dest_dir  = path_cfg.get('path','dest_dir')
excel_dir = path_cfg.get('path','excel_dir')

for node in get_xmlnode(root, 'file'):
	dict = {}
	tpl  = get_attrvalue(node, 'tpl')
	for node2 in get_xmlnode(root, 'dict'):
		xml_data  = xlrd.open_workbook(excel_dir + get_attrvalue(node2, 'excle_file'))
		table     = xml_data.sheet_by_name(get_attrvalue(node2, 'sheet'))
		key       = get_attrvalue(node2, 'name')
		col_start = int(get_attrvalue(node2, 'col_start'))
		col_end   = int(get_attrvalue(node2, 'col_end'))
		dict[key] = []
		for i in range(1, table.nrows):
			tmp = []
			for j in xrange(col_start - 1, col_end):
				tmp.append(format(table.cell(i, j).value))
			dict[key].append(tmp)

		sort_col  = get_attrvalue(node2, 'sort_col')
		if sort_col is '':
			pass
		else:
			sort_col = int(sort_col) - 1
			dict[key].sort(cmp=lambda x,y: cmp(x[sort_col], y[sort_col]), reverse = True)
	## render template with dict data
	content  = engine.render(tpl, dict)
	cfg_file = dest_dir + tpl.split('.')[0] + ".erl"
	dest     = open(cfg_file, "w")
	content  = content.replace("\r\n", "\n")
	dest.write(content)
	dest.close()
	del dict
	print "generate file: %s" % (cfg_file)


	
