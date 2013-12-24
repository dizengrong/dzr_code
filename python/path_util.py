# -*- coding: utf8 -*-

import os, sys


def usage():
	print("usage: path_util --gen_path root_path cur_path file_ext")

# root_path:上一层目录
# cur_path: root_path里面的子目录，作为当前目录来计算域root_path的距离
# file_ext: 需要的文件的扩展名
def gen_path_files(root_path, cur_path, file_ext):
	all_file = []
	path_distance = cal_path_len(root_path, cur_path)
	gen_path_files_help(root_path, cur_path, file_ext, get_distance_str(path_distance), all_file)
	fd = open("all_file", "w")
	for f in all_file:
		print(f)
		fd.write(os.path.normpath(f) + "\n")

def get_distance_str(path_distance):
	i = 0
	str = ""
	while i < path_distance:
		str = str + "../"
		i = i +1
	return str

def gen_path_files_help(root_path, cur_path, file_ext, path_prefix, all_file):
	for f in os.listdir(root_path):
		path = os.path.join(root_path, f)
		if (os.path.isfile(path) and f.endswith(file_ext)):
			all_file.append(os.path.join(path_prefix, f))
		if os.path.isdir(path):
			gen_path_files_help(path, cur_path, file_ext, os.path.join(path_prefix, f), all_file)

# path1 is the parent dir of path2
def cal_path_len(path1, path2):
	path1 = os.path.normpath(path1)
	path2 = os.path.normpath(path2)
	return cal_path_len2(path1, path2, 0)

def cal_path_len2(path1, path2, len):
	if path2 == path1:
		return len
	if path2.startswith(path1):
		return cal_path_len2(path1, os.path.dirname(path2), len + 1)
	else:
		return len

if __name__=='__main__':
	arg_nums = len(sys.argv)
	if arg_nums == 5 and sys.argv[1]=='--gen_path':
		gen_path_files(sys.argv[2], sys.argv[3], sys.argv[4])
	elif arg_nums == 4 and sys.argv[1]=='--path_distance':
		print cal_path_len(sys.argv[2], sys.argv[3])
	else:
		usage()

