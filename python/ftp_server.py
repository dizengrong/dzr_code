#!/usr/bin/env python
# -*- coding: utf8 -*-
# 文档参考: https://code.google.com/p/pyftpdlib/wiki/Tutorial

from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer

def main():
	authorizer = DummyAuthorizer()
	authorizer.add_user("dzR", "111111", "/data/dpcq/web/static/", perm='elradfmw')
	# authorizer.add_anonymous("E:\\my_code\\dzr_code\\python")

	handler = FTPHandler
	handler.authorizer    = authorizer
	# 设置被动模式下的数据端口范围
	# 然后要确保服务器的这些端口是能访问的
	handler.passive_ports = range(60000, 60001)
	server = FTPServer(("172.22.0.11", 21), handler)
	server.serve_forever()


if __name__ == '__main__':
    main()