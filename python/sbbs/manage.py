#!/usr/bin/env python
import os
import sys
from sbbs import settings

# current = os.getcwd()
# upper   = os.path.normpath(os.path.join(current, '..'))
# sys.path.append(current)
# sys.path.append(upper)
# sys.path.append(os.path.join(current, 'django'))


if __name__ == "__main__":
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "sbbs.settings")

    from django.core.management import execute_from_command_line
    # app_path = os.path.join(os.getcwd(), 'sbbs')
    # if app_path not in sys.path:
    # 	sys.path.append(app_path)
    # print sys.path
    execute_from_command_line(sys.argv)
