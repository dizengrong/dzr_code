#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os
import shutil

def delFiles(paths):
    li = []
    def VisitDir(arg, dirname, names):
        for filepath in names:
            li.append(os.path.join(dirname, filepath))
    os.path.walk(paths, VisitDir, ())
    li.reverse()
    for l in li:
        if os.path.isfile(l):
            os.remove(l)
        else:
            os.rmdir(l)
    os.rmdir(paths)

ROOT = os.path.dirname(os.path.abspath(__file__))

os.system('python setup.py py2exe')
    

try:
    shutil.rmtree('sbb_dist')
except Exception, e:
    pass

try:
    shutil.move(os.path.join(ROOT, 'dist'), os.path.join(ROOT, 'sbb_dist'))
except:
    print 'move dist failed'

shutil.copytree('C:\Python27\Lib\site-packages\django', 'sbb_dist/django')

shutil.copy('manage.py', 'sbb_dist/manage.py')
shutil.copy('__init__.py', 'sbb_dist/__init__.py')
shutil.copytree('sbbs', 'sbb_dist/sbbs')
shutil.copytree('bbs1', 'sbb_dist/bbs1')
shutil.rmtree('build')