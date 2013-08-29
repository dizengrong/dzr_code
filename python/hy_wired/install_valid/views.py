# -*- coding: utf8 -*-


from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import render_to_response
from django.template import Context
from django.template import RequestContext
from django.template.loader import get_template
from django.core.context_processors import csrf
from django.views.decorators.csrf import csrf_protect
from django.contrib import auth
import xdrlib, sys, xlrd, datetime, copy

from models import *

def hello(request):
    return HttpResponse("Hello world")

@csrf_protect
def login(request):
	if request.method == 'GET':
		return show_login_view(request, False)
		# return render_to_response('/static/login.html')
	elif request.method == 'POST':
		username = request.POST.get('user', '')
		password = request.POST.get('password', '')
		user     = auth.authenticate(username=username, password=password)
		print "user: %s, password: %s" % (username, password)
		if user is not None and user.is_active:
			# Correct password, and the user is marked "active"
			auth.login(request, user)
			# Redirect to a success page.
			return HttpResponseRedirect("/main/")
		else:
			return show_login_view(request, True)

def logout(request):
	auth.logout(request)
	return HttpResponseRedirect("/login/")

def main(request):
	if request.user.is_authenticated():
		t      = get_template('index.html')
		action = request.GET.get('action', '')
		print "action: %s" % (action)
		if action == '':
			return show_default_main_view(request, t)
		elif action == 'msg':
			return show_msg_view(request, t)
		elif action == 'req_valid':
			return show_req_valid_view(request, t)
		elif action == 'check_onu_valid':
			return show_check_valid_view(request, t)
		elif action == 'check_eoc_valid':
			return show_check_valid_view(request, t)
		elif action == 'query':
			return show_query_view(request, t)
	else:
		return HttpResponseRedirect("/main/")


# ============================help function=====================================
def show_login_view(request, is_error):
	t    = get_template('login.html')
	html = t.render(RequestContext(request, {'error': is_error}))
	return HttpResponse(html)

def show_default_main_view(request, t_html):
	action = request.GET.get('action', '')
	dic = {'user': request.user.username, 
		   'action': action,
		   'msg_len': get_message_len(request.user.username)
		  }
	return HttpResponse(t_html.render(RequestContext(request, dic)))
	

def show_msg_view(request, t_html):
	action  = request.GET.get('action', '')
	my_msgs = Message.objects.filter(user = request.user.username).order_by('-report_date').order_by('is_read')
	dic = {'user': request.user.username, 
		   'action': action,
		   'msg_list': my_msgs,
		   'msg_len': get_message_len(request.user.username)
		  }
	
	response = HttpResponse(t_html.render(RequestContext(request, dic)))

	# for msg in my_msgs:
	# 	msg.is_read = True
	# 	msg.save()
	return response


def get_message_len(username):
	return len(Message.objects.filter(user = username, is_read = False))

def query_msg(request):
	msg_id = request.GET['msg_id']
	msg = Message.objects.get(msg_id = msg_id)
	if msg.msg_type == 1:
		if msg.dev_type == 1:
			report_date = msg.report_date.strftime('%Y-%m-%d %H:%M:%S')
			return HttpResponseRedirect('/main?action=check_onu_valid&report_date=%s' % (report_date))
		elif msg.dev_type == 2:
			report_date = msg.report_date.strftime('%Y-%m-%d %H:%M:%S')
			return HttpResponseRedirect('/main?action=check_eoc_valid&report_date=%s' % (report_date))

def delete_msg(request):
	msg_id = request.GET['msg_id']
	msg = Message.objects.get(msg_id = msg_id)
	if msg is not None:
		msg.delete()
	return HttpResponseRedirect("/main?action=msg")
	# t = get_template('index.html')
	# return show_msg_view(request, t_html)


def show_req_valid_view(request, t_html):
	action = request.GET.get('action', '')
	dic = {'user': request.user.username, 
		   'action': action,
		   'msg_len': get_message_len(request.user.username),
		   'valider_list': User.objects.all()
		  }
	return HttpResponse(t_html.render(RequestContext(request, dic)))

def show_check_valid_view(request, t_html):
	action      = request.GET.get('action', '')
	report_date = request.GET.get('report_date', '')
	username    = request.user.username
	dic = {'user': username, 
		   'action': action,
		   'msg_len': get_message_len(username)
		  }
	if action == 'check_onu_valid':
		dic['onu_check_list'] = get_onu_detail_report(username, report_date)
	elif action == 'check_eoc_valid':
		dic['eoc_check_list'] = get_eoc_detail_report(username)
	return HttpResponse(t_html.render(RequestContext(request, dic)))


def get_onu_detail_report(username, report_date):
	if report_date == '':
		return ONUDetailReport.objects.raw(
		('select install_valid_devonu_tmp.dev_id, user, date, addr_1, addr_2, addr_detail, dev_name, mac_addr, port_remark '
				'from install_valid_devonu_tmp, install_valid_devreport '
				'where to_who=\'%s\' and dev_type=1 and is_valid=0 '
				'and install_valid_devonu_tmp.dev_id=install_valid_devreport.dev_id '
				'order by date') % (username))
	else:
		return ONUDetailReport.objects.raw(
		('select install_valid_devonu_tmp.dev_id, user, date, addr_1, addr_2, addr_detail, dev_name, mac_addr, port_remark '
				'from install_valid_devonu_tmp, install_valid_devreport '
				'where to_who=\'%s\' and dev_type=1 and is_valid=0 and install_valid_devreport.date=\'%s\' '
				'and install_valid_devonu_tmp.dev_id=install_valid_devreport.dev_id '
				'order by date') % (username, datetime.datetime.strptime(report_date, '%Y-%m-%d %H:%M:%S')))

def get_eoc_detail_report(username):
	return EOCDetailReport.objects.raw(
		('select install_valid_deveoc_tmp.dev_id, user, date, addr_1, addr_2, addr_detail, '
		 'line_box_type, dev_box_type, install_valid_deveoc_tmp.dev_type, cover_users, '
		 'model, manager_ip, ip_mask, gateway, manager_vlan, port_begin_valn, port_end_valn '
				'from install_valid_deveoc_tmp, install_valid_devreport '
				'where to_who=\'%s\' and install_valid_devreport.dev_type=2 and is_valid=0 '
				'and install_valid_deveoc_tmp.dev_id=install_valid_devreport.dev_id '
				'order by date') % (username))

@csrf_protect
def upload(request):
	if request.method != 'POST':
		msg_dic = {'error_msg':'客户端提交方法错误'}
	elif request.FILES.get('file', '') == '':
		msg_dic = {'error_msg':'请选择要上传的文件'}
	elif request.POST.get('valider', '') == '':
		msg_dic = {'error_msg':'请选择验收者'}
	else:
		msg_dic = handle_upload(request.FILES.get('file', ''), request)
	t = get_template('upload_succ.html')
	return HttpResponse(t.render(RequestContext(request, msg_dic)))


def handle_upload(f, request):
	# to-do: temp文件要唯一
	tmp_file = ('%s_tmp.xlsx') % (request.user.username)
	print tmp_file
	destination = open(tmp_file, 'wb+')
	for chunk in f.chunks():
		destination.write(chunk)
	destination.close()

	xml_data = xlrd.open_workbook(tmp_file)
	(IsOk, data1, data2) = check_upload_data(xml_data)
	if IsOk:
		upload_onu_dev(request, data1)
		upload_eoc_dev(request, data2)
		return {'error_msg':'上传成功'}
	else:
		return {'error_msg':'eoc_check_error', 'type':data1, 'eoc_check_list':[data2]}

def ip_check(ip):
	q = ip.split('.')
	return len(q) == 4 and len(filter(lambda x: x >= 0 and x <= 255, \
	map(int, filter(lambda x: x.isdigit(), q)))) == 4

def check_upload_data(xml_data):
	onu_table    = xml_data.sheet_by_name(u'onu')
	onu_dev_list = []
	for i in range(1, onu_table.nrows):
		# 保存等待验收的设备临时数据
		dev = DevONU_TMP(addr_1      = onu_table.cell(i, 0).value,
						 addr_2      = onu_table.cell(i, 1).value,
						 addr_detail = onu_table.cell(i, 2).value,
						 dev_name    = onu_table.cell(i, 3).value,
						 mac_addr    = onu_table.cell(i, 4).value,
						 port_remark = onu_table.cell(i, 5).value)
		onu_dev_list.append(dev)

	eoc_table    = xml_data.sheet_by_name(u'eoc')
	eoc_dev_list = []
	for i in range(1, eoc_table.nrows):
		# 保存等待验收的设备临时数据
		dev = DevEOC_TMP(addr_1          = eoc_table.cell(i, 0).value,
						 addr_2          = eoc_table.cell(i, 1).value,
						 addr_detail     = eoc_table.cell(i, 2).value,
						 line_box_type   = eoc_table.cell(i, 3).value,
						 dev_box_type    = eoc_table.cell(i, 4).value,
						 dev_type        = eoc_table.cell(i, 5).value,
						 cover_users     = eoc_table.cell(i, 6).value,
						 model           = eoc_table.cell(i, 7).value,
						 manager_ip      = eoc_table.cell(i, 8).value,
						 ip_mask         = eoc_table.cell(i, 9).value,
						 gateway         = eoc_table.cell(i, 10).value,
						 manager_vlan    = eoc_table.cell(i, 11).value,
						 port_begin_valn = eoc_table.cell(i, 12).value,
						 port_end_valn   = eoc_table.cell(i, 13).value)
		if dev.manager_vlan != 2:
			return (False, '管理VLAN', dev)
		if ip_check(dev.manager_ip) == False:
			return (False, '管理地址', dev)
		if ip_check(dev.ip_mask) == False:
			return (False, '子网掩码', dev)
		if ip_check(dev.gateway) == False:
			return (False, '默认网关', dev)
		if dev.port_begin_valn < 1000 or dev.port_begin_valn > 3000:
			return (False, '端口开始VLAN', dev)
		if dev.port_end_valn < 1000 or dev.port_end_valn > 3000:
			return (False, '端口结束VLAN', dev)
		eoc_dev_list.append(dev)
	# 检测成功，返回正确的数据
	return (True, onu_dev_list, eoc_dev_list)

def upload_onu_dev(request, onu_dev_list):
	dev_type = 1
	date     = datetime.datetime.now()
	# 循环行列表数据
	for dev in onu_dev_list:
		dev.save()
		dev_id = dev.dev_id
		# 然后保存提交记录
		report = DevReport(	user     = request.user.username, 
							to_who   = request.POST.get('valider', ''),
							dev_id   = dev_id,
							dev_type = dev_type,
							date     = date,
							is_valid = False)
		report.save()
	# 再向验证者发送消息
	if len(onu_dev_list) > 0:
		msg = Message(user        = request.POST.get('valider', ''),
					  msg_type    = 1,
					  from_who    = request.user.username,
					  dev_type    = dev_type,
					  report_date = date,
					  is_read     = False)
		msg.save()

def upload_eoc_dev(request, eoc_dev_list):
	date     = datetime.datetime.now()
	dev_type = 2
	# 循环行列表数据
	for dev in eoc_dev_list:
		dev.save()
		dev_id = dev.dev_id
		# 然后保存提交记录
		report = DevReport(	user     = request.user.username, 
							to_who   = request.POST.get('valider', ''),
							dev_id   = dev_id,
							dev_type = dev_type,
							date     = date,
							is_valid = False)
		report.save()
	# 再向验证者发送消息
	if len(eoc_dev_list):
		msg = Message(user        = request.POST.get('valider', ''),
					  msg_type    = 1,
					  from_who    = request.user.username,
					  dev_type    = dev_type,
					  report_date = date,
					  is_read     = False)
		msg.save()

def valid_dev(request):
	t = get_template('valid_succ.html')
	try:
		checked_list = request.POST.getlist('_selected_action')
		if checked_list == []:
			msg_dic = {'has_error':True, 'msg':'无数据可验收，请选择验收通过的数据'}
			return HttpResponse(t.render(RequestContext(request, msg_dic)))

		dev_type   = request.GET['dev_type']
		valid_date = datetime.datetime.now()
		if dev_type == 'check_onu_valid':
			valid_onu_dev(checked_list, valid_date)
		elif dev_type == 'check_eoc_valid':
			valid_eoc_dev(checked_list, valid_date)

		msg_dic = {'has_error':False, 'msg':'验收成功'}
		return HttpResponse(t.render(RequestContext(request, msg_dic)))
	except Exception, e:
		msg_dic = {'has_error':True, 'msg':'验收时发生异常', 'exception':e}
		return HttpResponse(t.render(RequestContext(request, msg_dic)))

def valid_onu_dev(checked_list, valid_date):
	dev_type        = 1
	report_msg_list = {}
	for report_dev_id in checked_list:
		dev_tmp    = DevONU_TMP.objects.get(dev_id = report_dev_id)
		dev = DevONU(addr_1      = dev_tmp.addr_1,
					 addr_2      = dev_tmp.addr_2,
					 addr_detail = dev_tmp.addr_detail,
					 dev_name    = dev_tmp.dev_name,
					 mac_addr    = dev_tmp.mac_addr,
					 port_remark = dev_tmp.port_remark)
		dev.save()
		new_dev_id = dev.dev_id
		dev_tmp.delete()
		# 修改提交记录
		report            = DevReport.objects.filter(dev_id = report_dev_id, dev_type = dev_type)[0]
		report.dev_id     = new_dev_id
		report.valid_date = valid_date
		report.is_valid   = True
		report.save()
		report_msg_list[report.user] = report.to_who
	# 发消息给提交者
	for u in report_msg_list.keys():
		msg = Message(user        = u,
					  msg_type    = 2,
					  from_who    = report_msg_list[u],
					  dev_type    = dev_type,
					  report_date = datetime.datetime.now(),
					  is_read     = False)
		msg.save()

def valid_eoc_dev(checked_list, valid_date):
	dev_type = 2
	report_msg_list = {}
	for report_dev_id in checked_list:
		dev_tmp    = DevEOC_TMP.objects.get(dev_id = report_dev_id)
		dev = DevEOC(addr_1          = dev_tmp.addr_1,
					 addr_2          = dev_tmp.addr_2,
					 addr_detail     = dev_tmp.addr_detail,
					 line_box_type   = dev_tmp.line_box_type,
					 dev_box_type    = dev_tmp.dev_box_type,
					 dev_type        = dev_tmp.dev_type,
					 cover_users     = dev_tmp.cover_users,
					 model           = dev_tmp.model,
					 manager_ip      = dev_tmp.manager_ip,
					 ip_mask         = dev_tmp.ip_mask,
					 gateway         = dev_tmp.gateway,
					 manager_vlan    = dev_tmp.manager_vlan,
					 port_begin_valn = dev_tmp.port_begin_valn,
					 port_end_valn   = dev_tmp.port_end_valn)
		# 保存验收成功的数据到正式的表中
		dev.save()
		new_dev_id = dev.dev_id
		# 删除临时表的数据
		dev_tmp.delete()
		# 修改提交记录
		report            = DevReport.objects.filter(dev_id = report_dev_id, dev_type = dev_type)[0]
		report.dev_id     = new_dev_id
		report.valid_date = valid_date
		report.is_valid   = True
		report.save()
		report_msg_list[report.user] = report.to_who
	# 发消息给提交者
	for u in report_msg_list.keys():
		msg = Message(user        = u,
					  msg_type    = 2,
					  from_who    = report_msg_list[u],
					  dev_type    = dev_type,
					  report_date = datetime.datetime.now(),
					  is_read     = False)
		msg.save()
