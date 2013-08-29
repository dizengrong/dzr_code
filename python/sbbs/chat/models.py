from django.db import models

# Create your models here.
class Msg(models.Model):
	room     = models.IntegerField(verbose_name = "room")
	username = models.CharField("username", max_length=40)
	msg      = models.CharField("message", max_length=10000)
	dateline = models.IntegerField("Time")

class MyLastid(models.Model):
	last_id  = models.IntegerField(verbose_name = "last_id")
	username = models.CharField("username", max_length=40)


def get_last_msg_id():
	obj = Msg.objects.raw("select max(id), id from chat_msg ")[0]
	print obj

	if obj.id == None :
		return 0
	else:
		return obj.id

def get_my_last_msg_id(username):
	obj = MyLastid.objects.filter(username = username)[0]
	return obj.last_id

def set_my_last_msg_id(username, last_id):
	# print last_id
	obj = MyLastid.objects.filter(username = username)
	if len(obj) == 0:
		obj = MyLastid(username = username, last_id = last_id)
		obj.save()
	else:
		obj = obj[0]
		obj.last_id = last_id
		obj.save()
