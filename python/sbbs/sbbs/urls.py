from django.conf.urls import patterns, include, url
from django.conf import settings
from bbs1.views import *

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    url(r'^accounts/login/$', 'bbs1.views.login', name='login'),
    url(r'^accounts/logout/$', 'bbs1.views.logout', name='logout'),
    url(r'^survey_statics/$', 'bbs1.views.survey_statics', name='survey_statics'),
    url(r'^$', index),
    url(r'^index/$', 'bbs1.views.index', name='index'),
    url(r'^index/(?P<survey_type>\d+)$', 'bbs1.views.survey', name='survey'),
    url(r'^index/(?P<survey_type>\d+)/post$', 'bbs1.views.post', name='post'),
    url(r'^index/(?P<survey_type>\d+)/submit_survey$', 'bbs1.views.submit_survey', name='submit_survey'),
    # url(r'^sbbs/', include('sbbs.foo.urls')),

    # chat
    url(r'^chat/(?P<room>\d+)/$', 'chat.views.index', name='chat_index'),
    url(r'^chat/(?P<room>\d+)/ajax/listen/\d+/$', 'chat.views.listen'),
    url(r'^chat/(?P<room>\d+)/ajax/getmsg/\d+/$', 'chat.views.getmsg'),
    # url(r'^chat/(?P<room>\d+)/ajax/postmsg/$', 'chat.views.postmsg'),
    url(r'^chat/(?P<room>\d+)/ajax/postmsg/$', 'chat.views.postmsg', name='postmsg'),


    # Uncomment the admin/doc line below to enable admin documentation:
    url(r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    url(r'^admin/', include(admin.site.urls)),
    url(r'^static/(?P<path>.*)$', 'django.views.static.serve',{'document_root': settings.MEDIA_ROOT },name="media")
)
