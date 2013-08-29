# -*- coding: utf8 -*-

# Create your views here.
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import render_to_response
from django.template import Context
from django.template import RequestContext
from django.template.loader import get_template
from django.core.context_processors import csrf
from django.views.decorators.csrf import csrf_protect, csrf_exempt
from django.contrib import auth
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from chat.models import *
import time, datetime
from operator import itemgetter
from django.db import connections

@csrf_protect
@login_required
def index(request, room):
	last_msg_id = get_last_msg_id()
	set_my_last_msg_id(request.user.username, last_msg_id)
	if int(room) == 1:
		tag = 'A'
	else:
		tag = 'B'
	dic = {'user_name':request.user.username, 
		   'announce': '您好，谢谢您选择' + tag + '，请在如下聊天室内讨论你们选择' + tag + '的理由，可以相互讨论，15分钟后页面将自动跳转。', 
		   'room': room,
		   'last_msg_id': last_msg_id}
	# return render_to_response('chat/index.html', dic, RequestContext(request))
	return render_to_response('chat/index.html', dic)


def listen(request, room):
	time.sleep(1)
	# yield "comet" 
	# dic = {'room': room}
	c = {}
	c.update(csrf(request))
	return HttpResponse("newmsg", c)

# @csrf_protect
@login_required
@csrf_exempt  
def postmsg(request, room):
	msg = Msg(room     = room, 
			  username = request.user.username, 
			  msg      = request.POST.get('msg', 'message'),
			  dateline = int(time.time()))
	msg.save()
	return HttpResponse('postmsgok')

@login_required
def getmsg(request, room):
	my_lastid = get_my_last_msg_id(request.user.username)
	msglist = Msg.objects.raw('select * from chat_msg where room=' + str(room) + ' and ' + 'id>' + str(my_lastid))
	if len(list(msglist)) == 0:
		return HttpResponse('')
	li = []
	cur_last_id = my_lastid
	for i, msg in enumerate(msglist):
		msg_dict             = {}
		msg_dict['msg']      = msg.msg
		msg_dict['username'] = msg.username
		msg_dict['dateline'] = time.strftime('%H:%M:%S', time.localtime(msg.dateline))
		li.append(dict(msg_dict))
		print li[i]
		if msg.id > cur_last_id:
			cur_last_id = msg.id

	set_my_last_msg_id(request.user.username, cur_last_id)
	return HttpResponse('msg' + str(li))

