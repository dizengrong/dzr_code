from django.conf.urls import patterns, include, url

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
from install_valid.views import *
import hy_wired
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    url(r'^hello/$', hello),
    url(r'^login/$', login),
    url(r'^logout/$', logout),
    url(r'^main/$',  main),
    url(r'^upload/$',  upload),
    url(r'^valid_dev/$',  valid_dev),
    url(r'^query_msg/$',  query_msg),
    url(r'^delete_msg/$',  delete_msg),
    # url(r'^hy_wired/', include('hy_wired.foo.urls')),
    (r'^static/(?P<path>.*)$', 'django.views.static.serve', {'document_root':hy_wired.settings.STATICFILES_DIRS, 'show_indexes': True}),

    # Uncomment the admin/doc line below to enable admin documentation:
    url(r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    url(r'^admin/', include(admin.site.urls)),
)
