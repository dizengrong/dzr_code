#-*- coding: utf8 -*-

# Requires wxPython. &nbsp;This sample demonstrates:
#
# - single file exe using wxPython as GUI.

from distutils.core import setup
import py2exe
import sys

# If run without args, build executables, in quiet mode.

if len(sys.argv) == 1:
	sys.argv.append("py2exe")
	sys.argv.append("-q")

class Target:
	def __init__(self, **kw):
		self.__dict__.update(kw)
		# for the versioninfo resources
		self.version = "1.0.0"
		self.company_name = "dzR-studio"
		self.copyright = "dzR @2013"
		self.name = "PySerial"

################################################################

# A program using wxPython
# The manifest will be inserted as resource into iTip.exe. &nbsp;<span style="color: #0000ff;">This</span>
# gives the controls the Windows XP appearance (if run on XP <img src="http://www.xsmile.net/wp-includes/images/smilies/icon_wink.gif" alt=";-)" class="wp-smiley"> </span>
#
# Another option would be to store it in a file named
# iTip.exe.manifest, and copy it with the data_files option into
# the dist-dir.
#
manifest_template = '''
	<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
	<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
	<assemblyIdentity
	version="5.0.0.0"
	processorArchitecture="x86"
	name="%(prog)s"
	type="win32"
	/>
	<description>%(prog)s Program</description>
	<dependency>
	<dependentAssembly>
	<assemblyIdentity
	type="win32"
	name="Microsoft.Windows.Common-Controls"
	version="6.0.0.0"
	processorArchitecture="X86"
	publicKeyToken="6595b64144ccf1df"
	language="*"
	/>
	</dependentAssembly>
	</dependency>
	</assembly>

'''

RT_MANIFEST = 24

iTip = Target(
# used for the versioninfo resource
description = "A ENote Application",
# what to build
script = "main.py",

other_resources = [(RT_MANIFEST, 1, manifest_template % dict(prog="iTip"))],
icon_resources = [(1, "my.ico")],
dest_base = "iTip")

################################################################

includes=["encodings","encodings.*"]
setup(
options = {"py2exe": {"compressed": 1,
					  "optimize": 2,
					  # "ascii": 0,
					  "includes":includes,
					  "dll_excludes": ["MSVCP90.dll"],
					  "bundle_files": 1 #所有文件打包成一个exe文件
					  }
		  },
zipfile = None,
description = u"mytty",
name = u"mytty",
windows = [{"script":"main2.py", "icon_resources":[(1, "my.ico")]}],
data_files = [("", [r"PortSetting.xls", r"my.ico"]),
			  ("templates", []),
			  ("config", ["config/sessions", u"config/设备类型配置.txt", u"config/设备发送命令提示.txt", u"config/进线口.txt"]),
			  ("tools", []),
			  ("documents", ["documents/help.chm"])
    	     ]
)

############################################################
