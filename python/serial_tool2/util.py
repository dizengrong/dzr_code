#! /usr/bin/env python
# -*- coding: utf8 -*- 

import wx, socket, os, sys, subprocess
from netaddr import IPNetwork, IPAddress

def ShowMessageDialog(parent, content, title):
    dlg = wx.MessageDialog(parent, content, title, wx.OK)
    dlg.ShowModal()
    dlg.Destroy()
    
class PortSetting(object):
    def __init__(self, baudRate, byteSize, parity, stopBits, dtrControl):
        self.baudRate   = baudRate      # 波特率
        self.byteSize   = byteSize      # 每个字节有多少位
        self.parity     = parity        # 奇偶校验位
        self.stopBits   = stopBits      # 停止位
        self.dtrControl = dtrControl    # 数据流控制

class Device(object):
    def __init__(self, dev_type, dev_addr, mangr_ip, submask_ip, gateway_ip, mangr_vlan, begin_vlan, end_vlan):
        self.dev_type   = dev_type          # 设备箱类型
        self.dev_addr   = dev_addr          # 设备箱安装地址
        self.mangr_ip   = mangr_ip          # 管理地址
        self.submask_ip = submask_ip        # 子网掩码
        self.gateway_ip = gateway_ip        # 默认网关
        self.mangr_vlan = mangr_vlan        # 管理VLAN
        self.begin_vlan = begin_vlan        # 端口开始VLAN
        self.end_vlan   = end_vlan          # 端口结束VLAN

def to_str(value):
    if isinstance(value, float):
        if int(value) == value: return str(int(value))
        else: return str(value)
    else:
        return unicode(value)


def IsValidIP(ip_str):
    try:
        IPAddress(ip_str)
        if len(ip_str.split('.')) == 4:
            ip = True
        else:
            ip = False
    except Exception, e:
        ip = False
    return ip

# 判断2个v4的ip是否在同一个网段
def IsInSameSubNets(ip1, ip2):
    return True
    # return (IPAddress(ip1) in IPNetwork(ip2 + "/32"))

def PrintStringAsAscii(s):
    import string
    for ch in s:
        if ch in string.printable:
            print ch,
        else:
            print ord(ch), 


def to_str(value):
    if isinstance(value, float):
        if int(value) == value: return str(int(value))
        else: return str(value)
    else:
        return unicode(value)    

def GetAllNetworkName():
    ret = []
    for str in os.popen("netsh interface show int").readlines():
        # str = str.decode('GBK')
        str = str.strip('\n')
        str = str.strip(' ')
        if str == '':
            continue
        str = str[::-1] # 反转字符串
        ret.append(str.split('  ')[0][::-1])
    return ret[2:]

# 执行外部命令，并获取结果
def ExecuteCmd(cmd):
    handle = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    return handle.communicate()[0]

