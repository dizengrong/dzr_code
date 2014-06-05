#!/usr/bin/env python
# -*- coding: utf8 -*-

import os, sys, json, subprocess, my_util
import xml.dom.minidom, zipfile

# 如果有pysvn模块就可以使用它来获取svn的文件版本号
# import pysvn

def usage():
	print(
"""
usage: 
		svn_util --ver_list project_path
		svn_util --changed_list all_rev_dir rev_number1 rev_number2
""")

# pysvn有一个小bug，导致project_path参数不能为“.”或“./”
# 最好是给project_path传递svn项目的根目录文件名或者给绝对路径
# 
# def generate_version_list(project_path, svn_username, svn_password):
# 	def get_login(realm, username, may_save):
# 		return True, svn_username, svn_password, True

# 	client = pysvn.Client()
# 	client.callback_get_login = get_login
# 	svn_info = client.info(project_path)
# 	rev_number = svn_info.revision.number
# 	dic = {}
# 	for (entry, v) in client.list(project_path, depth = pysvn.depth.infinity):
# 		if entry.kind == pysvn.node_kind.file:
# 			dic[entry.path] = entry.created_rev.number
# 			print("path: %s, commit_rev: %s" % (entry.path, entry.created_rev.number))
# 	rev_file = '%s.revision' % (rev_number)
# 	open(rev_file, 'w').write(json.dumps(dic))
# 	print(u"The revision of each file has write to file: %s." % (rev_file))

# 获取project_path目录下所有文件的版本号信息，并将数据以json格式写入文件生成在to_dir目录下
# {'file':revision_number}
# 若提供了部署的版本代号，则以版本代号命名文件，否则以当前的svn版本号来命令文件
# 返回: 生成的文件的路径
def generate_version_list(project_path, to_dir = ".", deploy_version=None, ignore_files_in_root_dir=False):
	cmd = "cd " + project_path + "; svn list -R --xml"
	handle = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
	doc = xml.dom.minidom.parseString(handle.communicate()[0])
	dic = {}
	for entry_node in doc.getElementsByTagName("entry"):
		if entry_node.getAttribute("kind") == "file":
			name_node   = entry_node.getElementsByTagName("name")[0]
			commit_node = entry_node.getElementsByTagName("commit")[0]
			f           = name_node.childNodes[0].data
			# 这里是因为客户端发布时需要把版本目录下第一级的文件删掉
			# 这个太特殊了，所以很蛋疼
			if ignore_files_in_root_dir and os.path.dirname(f) == '':
				continue
			dic[f] = commit_node.getAttribute("revision")
	if deploy_version is None:
		rev_file = '%s.revision' % (get_svn_revision(project_path))
	else:
		rev_file = '%s.revision' % (deploy_version)
	rev_file = os.path.join(to_dir, rev_file)
	open(rev_file, 'w').write(json.dumps(dic))
	print(u"版本库所有文件版本号生成成功: %s." % (rev_file))
	return rev_file

# 获取project_path目录的版本库号
def get_svn_revision(svn_path, svn_account="", svn_password=""):
	if svn_account == "":
		cmd = "svn info --xml " + svn_path
	else:
		cmd = "svn info --xml " + svn_path + " --username " + svn_account + " --password " + svn_password
	handle     = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
	doc        = xml.dom.minidom.parseString(handle.communicate()[0])
	entry_node = doc.getElementsByTagName("entry")[0]
	return entry_node.getAttribute("revision")

# 从所有版本库的目录rev_dir中去读取版本号文件rev1.revision和rev2.revision
# 然后生成差异文件列表(差异文件定义为rev2中与rev1中不同的文件)
def generate_changed_files(all_rev_dir, rev1, rev2):
	if os.path.isdir(all_rev_dir) == False:
		print(u"不存在目录: %s，请确保版本库目录存在！" % (to_dir))
		return
	rev1_dir = os.path.join(all_rev_dir, rev1 + ".revision")
	rev2_dir = os.path.join(all_rev_dir, rev2 + ".revision")
	dict1   = json.loads(open(rev1_dir).read())
	dict2   = json.loads(open(rev2_dir).read())
	to_file = os.path.join(all_rev_dir, "%s_to_%s.change_list" % (rev1, rev2))
	fd      = open(to_file, "w")
	rows    = []
	for f, new_rev in dict2.items():
		old_rev = dict1.get(f, "0")
		if new_rev != old_rev:
			fd.write(str((os.path.getsize(os.path.join(all_rev_dir, rev2, f)) + 1023) / 1024) + "\n")
			fd.write(f + "\n")
			rows.append([f, str(old_rev), str(new_rev)])
	fd.close()
	headers = [u"added or updated file", u"old revision", u"new revision"]
	my_util.format_table(headers, rows)
	print(u"\n差异文件列表生成成功: %s" % (to_file))
	zip_changed_files(all_rev_dir, rev1, rev2, [d[0] for d in rows])
	

def zip_changed_files(deploy_dir, old_version, deploy_version, changed_files):
	to_file  = os.path.join(deploy_dir, "%s_to_%s.change_list.zip" % (old_version, deploy_version))
	zip_file = zipfile.ZipFile(to_file, 'w', zipfile.ZIP_DEFLATED) 
	for f in changed_files:
		(old_version, ext) = os.path.splitext(f)
		if ext == ".lua":
			arcname = os.path.basename(f)
		else:
			arcname = f
		zip_file.write(os.path.join(deploy_dir, deploy_version, f), arcname) 
	zip_file.close()
	print(u"\n差异文件的zip包生成成功: %s" % (to_file))

if __name__=='__main__':
	arg_nums = len(sys.argv)
	if sys.argv[1]=='--ver_list' and arg_nums == 3:
		generate_version_list(sys.argv[2])
	elif sys.argv[1]=='--changed_list' and arg_nums == 5:
		generate_changed_files(sys.argv[2], sys.argv[3], sys.argv[4])
	else:
		usage()
