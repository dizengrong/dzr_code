# -*- coding: utf8 -*-

from django.db import models
from django import forms
from django.forms import ModelForm, Form

# Create your models here.

class Board(models.Model):
	survey_type = models.IntegerField(primary_key=True, verbose_name = "survey type")
	name        = models.CharField(max_length=50, unique=True)

	def __unicode__(self):
		return '/' + '/ ' + self.name

# Posts
class Post(models.Model):
	board     = models.ForeignKey(Board)

	level     = models.IntegerField(default=0) # depth in the tree
	rank      = models.IntegerField(default=0) # to determine rank within threads
	sticky    = models.BooleanField("Stickied", default=False) # to determine rank within boards
	locked    = models.BooleanField("Locked from replies", default=False) # whether to allow replies
	
	user_name = models.CharField("用户名", max_length=40, default="Anonymous")
	email     = models.EmailField("Email", max_length=256, blank=True)
	post_time = models.DateTimeField("Time", auto_now_add=True)
	subject   = models.CharField("Subject", max_length=40, blank=True)
	comment   = models.TextField("评论")

	def get_replies(self):
	    return self.replies.order_by('-rank', '-post_time')
	    
	def get_tree(self):
	    queue = [] # linear representation of the thread tree of replies
	    idx = 0 # where to insert children into the queue
	    level = 0 # how far to indent children (replies) in the queue

	    # initialize the queue with immediate children
	    for c in Post.objects.filter(reply=self).select_related('reply').order_by('-rank','-post_time').iterator():
	        queue.append((c, idx*INDENT_PIXELS))

	    # Populate the queue with descendants
	    for i in queue:
	        current = i[0] # fetch the current child (reply)
	        idx += 1 # increment the index

	        if Post.objects.filter(reply=current).count() == 0: # if the loop is not going to execute (current has no children)
	            if level > 0:
	                level -= 1 # decrement the level of indentation

	        else: # if the loop will execute (current has children)
	            level += 1 # increment the level of indentation
	            for j in Post.objects.filter(reply=current).select_related('reply').order_by('-rank','-post_time').reverse().iterator(): # sense of the order has to be reversed because the loop inserts in reverse order
	                queue.insert(idx, (j, level*INDENT_PIXELS))

	    return queue
	    
	def count_replies(self):
	    total = Post.objects.filter(reply=self.id).count()
	    for item in Post.objects.filter(reply=self.id).iterator():
	        if item.replies.count():
	            total += item.count_replies()
	    return total

	class Meta:
	    abstract = True


class TextPost(Post):
	reply = models.ForeignKey('self', related_name='replies', default=None, null=True, blank=True) # limit_choices_to={'board':self.board}
	root = models.ForeignKey('self', default=None, null=True, blank=True) # Original Post
	text = models.BooleanField(default=True, editable=False)

	def __get_tree(self, base, queue):
	    for post in TextPost.objects.order_by('-rank','-post_time').filter(reply=self.id).iterator():
	        queue.append((post, (post.level-base)*INDENT_PIXELS))
	        post.__get_tree(base, queue)
	    return queue
	        
	def get_tree(self):
	    return self.__get_tree(self.level, [])
	    
	def count_replies(self):
	    total = TextPost.objects.filter(reply=self.id).count()
	    for item in TextPost.objects.filter(reply=self.id).iterator():
	        if item.replies.count():
	            total += item.count_replies()
	    return total

	def get_highest_ranked_children(self, n=2):
	    return TextPost.objects.filter(reply=self.id).order_by('-rank', '-post_time')[:n]

class TextPostForm(ModelForm):
    # subject = forms.CharField(max_length=40, required=True)
    comment = forms.CharField(label = '评论', widget=forms.Textarea(attrs={'class':'textarea', 'rows':"5"}), max_length=1000000, required=True)
    # comment = forms.CharField(label = '评论', widget=forms.TextInput, max_length=1000000, required=True)
    class Meta:
        model = TextPost
        exclude = ('board', 'poster', 'reply', 'root', 'rank', 'level', 'sticky', 'locked', 'email','subject', 'user_name',)

class TextReplyForm(ModelForm):
    comment = forms.CharField(widget=forms.Textarea, max_length=1000000, required=True)
    class Meta:
        model = TextPost
        exclude = ('board', 'poster', 'reply', 'root', 'rank', 'level', 'sticky', 'locked', 'email', 'subject', 'user_name',)

# answer为：
# 	1: 完全不同意
# 	2: 基本不同意
# 	3: 有点不同意
# 	4: 有点同意同意
# 	5: 基本同意
# 	6: 完全同意
class QuestionSurvey(models.Model):
	user_name   = models.CharField("用户名", max_length=40, default="Anonymous")
	survey_type = models.IntegerField(verbose_name = "survey type")
	question_id = models.IntegerField(verbose_name = "question")
	answer      = models.IntegerField(verbose_name = "answer")

	
class QuestionConf(models.Model):
	def __str__(self):
		return "QuestionConf"

	class Meta:
		db_table = "questions"

	survey_type = models.IntegerField(verbose_name = "survey type")
	question_id = models.IntegerField(verbose_name = "question")
	describe    = models.CharField("describe", max_length=1000)


						
          	    