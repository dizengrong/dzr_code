#!/usr/bin/env python
# -*- coding: utf8 -*-

import os, sys, svn_util, traceback, my_util


def usage():
	print(
"""
usage: 
		部署: client_deploy.py --deploy svn_url to_dir deploy_version svn_account svn_password
		参数说明:
			svn_url: 为版本库的url
			to_dir: 为签出到哪个目录下
			deploy_version: 本次发布的版本代号
			svn_account: svn账号名
			svn_password: svn密码
		输出:
			若成功，则签出的版本库将放到目录:to_dir/deploy_version/

		删除部署: client_deploy.py --delete_deploy deploy_dir deploy_version
		参数说明:
			deploy_dir: 为版本库的url
			deploy_version: 发布的版本代号

""")


def deploy(svn_url, to_dir, deploy_version, svn_account, svn_password):
	if os.path.isdir(to_dir) == False:
		print(u"不存在目录: %s，请确保目录存在！" % (to_dir))
		return
	try:
		revision = svn_util.get_svn_revision(svn_url, svn_account, svn_password)
		to_dir2  = os.path.join(to_dir, deploy_version)
		if os.path.isdir(to_dir2) == True:
			print(u"已存在版本库目录：%s，将不重新生成版本库" % (to_dir2))
			return
		cmd = "svn checkout " + svn_url + " " + to_dir2 + " --username " + svn_account + " --password " + svn_password
		os.system(cmd)
		print(u"发布客户端成功，版本号: %s，生成到目录：%s" % (revision, to_dir2))
		svn_util.generate_version_list(to_dir2, to_dir, deploy_version)
		lastest_ver_file = os.path.join(to_dir, "lastest_version_no")
		open(lastest_ver_file, "w").write(deploy_version)
		print(u"更新%s成功！" % (lastest_ver_file))
	except Exception, e:
		print(u"发布失败，错误: %s" % (e))

def delete_deploy(deploy_dir, deploy_version):
	if os.path.isdir(deploy_dir) == False:
		print(u"不存在目录: %s，请确保目录存在！" % (deploy_dir))
		return
	version_dir  = os.path.join(deploy_dir, deploy_version)
	if os.path.isdir(version_dir) == False:
		print(u"不存在版本库目录：%s，将不做任何动作" % (version_dir))
		return
	del_files = []
	for f in os.listdir(deploy_dir):
		if f.startswith(deploy_version):
			del_files.append(os.path.join(deploy_dir, f))
		elif f.find("_to_" + deploy_version) != -1:
			del_files.append(os.path.join(deploy_dir, f))

	my_util.format_table(["file or directory to be delete"], [[f] for f in del_files])
	answer = raw_input("delete these files? (y/n):") 
	if answer == "y":
		os.system("rm -vrf %s" % (" ".join(del_files)))
	else:
		print(u"版本删除已终止")


if __name__=='__main__':
	arg_nums = len(sys.argv)
	if sys.argv[1]=='--deploy' and arg_nums == 7:
		deploy(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
	elif sys.argv[1]=='--delete_deploy' and arg_nums == 4:
		delete_deploy(sys.argv[2], sys.argv[3])
	else:
		usage()