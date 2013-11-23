# -*- coding: utf-8 -*- 

###########################################################################
## Python code generated with wxFormBuilder (version Oct  8 2012)
## http://www.wxformbuilder.org/
##
## PLEASE DO "NOT" EDIT THIS FILE!
###########################################################################

import wx
import wx.xrc
import wx.html

###########################################################################
## Class HtmlMessageDialog
###########################################################################

class HtmlMessageDialog ( wx.Dialog ):
    
    def __init__( self, parent, title, content ):
        wx.Dialog.__init__ ( self, parent, id = wx.ID_ANY, title = title, pos = wx.DefaultPosition, size = wx.Size( 271,141 ), style = wx.DEFAULT_DIALOG_STYLE )
        
        self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )
        
        bSizer27 = wx.BoxSizer( wx.VERTICAL )
        
        self.m_htmlWin1 = wx.html.HtmlWindow( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.html.HW_SCROLLBAR_AUTO )
        
        

        bSizer27.Add( self.m_htmlWin1, 3, wx.ALL|wx.EXPAND, 5 )
        
        bSizer28 = wx.BoxSizer( wx.HORIZONTAL )
        
        self.m_button17 = wx.Button( self, wx.ID_OK, u"确定", wx.DefaultPosition, wx.DefaultSize, 0 )
        bSizer28.Add( self.m_button17, 1, wx.ALL, 5 )
        
        self.m_button18 = wx.Button( self, wx.ID_CANCEL, u"取消", wx.DefaultPosition, wx.DefaultSize, 0 )
        bSizer28.Add( self.m_button18, 1, wx.ALL, 5 )
        
        
        bSizer27.Add( bSizer28, 1, wx.EXPAND, 5 )
        
        
        self.SetSizer( bSizer27 )
        self.Layout()
        
        self.m_htmlWin1.SetPage(content)
        irep = self.m_htmlWin1.GetInternalRepresentation()
        self.m_htmlWin1.SetSize((irep.GetWidth()+25, irep.GetHeight()))
        (width, height) = self.m_htmlWin1.GetSize()
        self.SetClientSize((width, height*2))
        self.CentreOnParent(wx.BOTH)

        self.Centre( wx.BOTH )
    
    def __del__( self ):
        pass
    

