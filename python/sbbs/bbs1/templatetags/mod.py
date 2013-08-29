from django import  template
register=template.Library()
def mod(value):
    return value % 11 
register.filter('mod',mod)
