# -*- coding: utf8 -*-

class MyDbRouter(object):
    """ 一个控制 myapp 应用中模型的
    所有数据库操作的路由 """

    def db_for_read(self, model, **hints):
        "myapp 应用中模型的操作指向 'other'"
        print model
        print type(model)
        if str(model.__class__) == 'bbs1.models.QuestionConf':
            return 'question_db'
        return None

    def db_for_write(self, model, **hints):
        "myapp 应用中模型的操作指向 'other'"
        if str(model.__class__) == 'bbs1.models.QuestionConf':
            return 'question_db'
        return None

    def allow_relation(self, obj1, obj2, **hints):
        " 如果包含 myapp 应用中的模型则允许所有关系 "
        # if obj1._meta.app_label == 'myapp' or obj2._meta.app_label == 'myapp':
        #     return True
        return None

    def allow_syncdb(self, db, model):
        " 确保 myapp 应用只存在于 'other' 数据库 "
        # print str(model.__class__)
        print str(model)
        if str(model) == '<class \'bbs1.models.QuestionConf\'>':
            return False
        # elif model._meta.app_label == 'myapp':
        #     return False
        return None