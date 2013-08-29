# mysetup.py
from distutils.core import setup
import py2exe


setup(
    windows=[
        {"script":"server1f1w.py","icon_resources":[(1,"images\\1f1w.ico")]},
        {"script":"start1f1w.py","icon_resources":[(1,"images\\1f1w.ico")]}],
    data_files = [
        ("",[r"config.ini",r"l_alive.log",r"l_stdout.log",r"l_stop.log",r"MSVCP71.DLL"]),
        ("resources",[r"resources\Dialog_hasrun.xrc",r"resources\Frame.xrc"]),
        ("images",[r"images\1f1w.ico"]),
    ],
    options={
        "py2exe":
            {
                "dll_excludes" : ["POWRPROF.dll"],
                "includes" : [
                    "bsddb",
                    "PIL",
                    "Image",
                    "ImageDraw",
                    "web",
                    "web.*",
                    "web.contrib",
                    "web.contrib.*",
                    "csv",
                    "mako",
                    "mako.*",
                    "email.*",
                    "xml.dom.minidom",
                    "xml.dom.minidom.*",
                    "sqlite3",
                ],
            },
    },
    )