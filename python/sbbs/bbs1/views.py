# -*- coding: utf8 -*-

# Create your views here.
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import render_to_response
from django.template import Context
from django.template import RequestContext
from django.template.loader import get_template
from django.core.context_processors import csrf
from django.views.decorators.csrf import csrf_protect
from django.contrib import auth
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from bbs1.models import *
from operator import itemgetter

TxtPostForm = TextPostForm()

@csrf_protect
def login(request):
	if request.method == 'GET':
		return show_login_view(request, False)
	elif request.method == 'POST':
		username = request.POST.get('user', '')
		password = request.POST.get('user', '')
		user = auth.authenticate(username=username, password=password)
		if user is None:
			user = User.objects.create_user(username=username, password=password)
			user.save()
			user = auth.authenticate(username=username, password=password)
		if user is not None and user.is_active:
			# Correct password, and the user is marked "active"
			auth.login(request, user)
			# Redirect to a success page.
			return HttpResponseRedirect("/index")
		else:
			return show_login_view(request, True)

@login_required
def logout(request):
	auth.logout(request)
	return show_login_view(request, False)

def show_login_view(request, is_error):
	t    = get_template('login.html')
	html = t.render(RequestContext(request, {'error': is_error}))
	return HttpResponse(html)

@login_required
def index(request):
	dic = {'user_name':request.user.username}
	return render_to_response('index.html', dic)

@csrf_protect
@login_required
def survey(request, survey_type):
	survey_name = 'survey' + str(survey_type)
	(new_board, is_created)   = Board.objects.get_or_create(survey_type = int(survey_type), name = survey_name)
	posts       = TextPost.objects.filter(board = survey_type)
	form        = TxtPostForm
	questions = QuestionConf.objects.using('cfg_db').filter(survey_type = survey_type)
	dic         = {'borad':new_board, 'posts':posts, 
				   'form':form, 'type':survey_type, 
				   'user_name':request.user.username,
				   'only_show_self_comment': (int(survey_type)==1),
				   'is_participated': is_participated(request.user.username, survey_type),
				   'questions': questions}
	return render_to_response(survey_name + '.html', dic, RequestContext(request))

@login_required
def post(request, survey_type):
	if request.method == 'POST':
		return _txtpost(request, survey_type)
		

def _txtpost(request, survey_type):
	borad = Board.objects.get(survey_type = survey_type)
	form = TextPostForm(request.POST)
	tempPost       = form.save(commit=False)
	if form.is_valid():
		tempPost           = form.save(commit=False) # get the Post object
		tempPost.board     = borad # set the board this post belongs to
		tempPost.user_name = request.user.username
		tempPost.reply     = None
		tempPost.save()
        return HttpResponseRedirect(request.META.get('HTTP_REFERER'))


@login_required
def submit_survey(request, survey_type):
	questions = QuestionConf.objects.using('cfg_db').filter(survey_type = survey_type)
	for cfg_q in questions:
		qs = QuestionSurvey(user_name   = request.user.username, 
					   		survey_type = int(survey_type), 
					   		question_id = cfg_q.question_id, 
					   		answer      = int(request.POST.get('answer' + str(cfg_q.question_id), '6')))
		qs.save()
	if int(survey_type) == 100:
		answer = int(request.POST.get('answer1', '6'))
		if answer > 3:
			return HttpResponseRedirect('/chat/2/') # 选择B类的
		else:
			return HttpResponseRedirect('/chat/1/') # 选择A类的
	else:
		return render_to_response("thank_you.html")

@login_required
def survey_statics(request):
	board_dict = {}
	for board in Board.objects.all():
		statics_dict = {}
		questions = QuestionSurvey.objects.filter(survey_type = board.survey_type)
		for question in questions:
			if str(question.question_id) not in statics_dict:
				static = Statics()
			else:
				static = statics_dict[str(question.question_id)]
			if question.answer == 1:
				static.answer1 = static.answer1 + 1
			elif question.answer == 2:
				static.answer2 = static.answer2 + 1
			elif question.answer == 3:
				static.answer3 = static.answer3 + 1
			elif question.answer == 4:
				static.answer4 = static.answer4 + 1
			elif question.answer == 5:
				static.answer5 = static.answer5 + 1
			elif question.answer == 6:
				static.answer6 = static.answer6 + 1
			statics_dict[str(question.question_id)] = static
		statics_dict = sorted(statics_dict.iteritems(), key=itemgetter(0))
		board_dict[str(board.survey_type)] = statics_dict
	dic = {'board_dict': board_dict, 'user_name':request.user.username}
	return render_to_response('survey_statics.html', dic, RequestContext(request))


class Statics(object):
	# question_id = 0
	answer1     = 0
	answer2     = 0
	answer3     = 0
	answer4     = 0
	answer5     = 0
	answer6     = 0


def is_participated(user_name, survey_type):
	return len(QuestionSurvey.objects.filter(user_name = user_name, survey_type = survey_type)) > 0




