///////////////////////////////////////////////////////////////////////////
// C++ code generated with wxFormBuilder (version Nov  6 2013)
// http://www.wxformbuilder.org/
//
// PLEASE DO "NOT" EDIT THIS FILE!
///////////////////////////////////////////////////////////////////////////

#ifndef __NONAME_H__
#define __NONAME_H__

#include <wx/artprov.h>
#include <wx/xrc/xmlres.h>
#include <wx/string.h>
#include <wx/bitmap.h>
#include <wx/image.h>
#include <wx/icon.h>
#include <wx/menu.h>
#include <wx/gdicmn.h>
#include <wx/font.h>
#include <wx/colour.h>
#include <wx/settings.h>
#include <wx/stattext.h>
#include <wx/datectrl.h>
#include <wx/dateevt.h>
#include <wx/sizer.h>
#include <wx/statbox.h>
#include <wx/checkbox.h>
#include <wx/button.h>
#include <wx/panel.h>
#include <wx/grid.h>
#include <wx/scrolwin.h>
#include <wx/aui/auibook.h>
#include <wx/splitter.h>
#include <wx/statusbr.h>
#include <wx/frame.h>
#include <wx/treectrl.h>
#include <wx/choice.h>
#include <wx/textctrl.h>
#include <wx/dialog.h>

///////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
/// Class MainFrame
///////////////////////////////////////////////////////////////////////////////
class MainFrame : public wxFrame 
{
	private:
	
	protected:
		wxMenuBar* m_menubar1;
		wxMenu* m_menu2;
		wxMenu* m_menu5;
		wxMenu* m_menu3;
		wxSplitterWindow* m_splitter1;
		wxPanel* m_panel2;
		wxStaticText* m_staticText1;
		wxStaticText* m_staticText3;
		wxDatePickerCtrl* m_datePicker1;
		wxStaticText* m_staticText4;
		wxDatePickerCtrl* m_datePicker2;
		wxCheckBox* m_checkBox2;
		wxCheckBox* m_checkBox3;
		wxCheckBox* m_checkBox4;
		wxButton* m_button2;
		wxPanel* m_panel3;
		wxAuiNotebook* m_auinotebook1;
		wxPanel* m_panel5;
		wxGrid* m_grid1;
		wxPanel* m_panel6;
		wxPanel* m_panel9;
		wxStaticText* m_staticText14;
		wxGrid* m_grid2;
		wxStaticText* m_staticText11;
		wxButton* m_button9;
		wxButton* m_button10;
		wxScrolledWindow* m_scrolledWindow1;
		wxStatusBar* m_statusBar1;
		
		// Virtual event handlers, overide them in your derived class
		virtual void OnExit( wxCommandEvent& event ) { event.Skip(); }
		virtual void OnAddProductBaseInfo( wxCommandEvent& event ) { event.Skip(); }
		virtual void OnAbout( wxCommandEvent& event ) { event.Skip(); }
		virtual void OnSearch( wxCommandEvent& event ) { event.Skip(); }
		virtual void OnCellRightClick( wxGridEvent& event ) { event.Skip(); }
		
	
	public:
		
		MainFrame( wxWindow* parent, wxWindowID id = wxID_ANY, const wxString& title = wxT("库存管理系统"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxSize( 819,479 ), long style = wxDEFAULT_FRAME_STYLE|wxTAB_TRAVERSAL );
		
		~MainFrame();
		
		void m_splitter1OnIdle( wxIdleEvent& )
		{
			m_splitter1->SetSashPosition( 189 );
			m_splitter1->Disconnect( wxEVT_IDLE, wxIdleEventHandler( MainFrame::m_splitter1OnIdle ), NULL, this );
		}
	
};

///////////////////////////////////////////////////////////////////////////////
/// Class DlgAddProductType
///////////////////////////////////////////////////////////////////////////////
class DlgAddProductType : public wxDialog 
{
	private:
	
	protected:
		wxTreeCtrl* m_treeCtrl3;
		wxStaticText* m_staticText5;
		wxChoice* m_choice1;
		wxStaticText* m_staticText6;
		wxTextCtrl* m_textCtrl1;
		wxStaticText* m_staticText7;
		wxTextCtrl* m_textCtrl2;
		wxStaticText* m_staticText8;
		wxTextCtrl* m_textCtrl3;
		wxStaticText* m_staticText9;
		wxTextCtrl* m_textCtrl4;
		wxStaticText* m_staticText10;
		wxTextCtrl* m_textCtrl5;
		wxStaticText* m_staticText52;
		wxTextCtrl* m_textCtrl24;
		wxButton* m_button7;
		wxButton* m_button8;
	
	public:
		
		DlgAddProductType( wxWindow* parent, wxWindowID id = wxID_ANY, const wxString& title = wxT("添加产品型号"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxSize( 367,533 ), long style = wxDEFAULT_DIALOG_STYLE ); 
		~DlgAddProductType();
	
};

///////////////////////////////////////////////////////////////////////////////
/// Class DlgAddSell
///////////////////////////////////////////////////////////////////////////////
class DlgAddSell : public wxDialog 
{
	private:
	
	protected:
		wxStaticText* m_staticText53;
		wxChoice* m_choice8;
		wxStaticText* m_staticText12;
		wxChoice* m_choice2;
		wxStaticText* m_staticText16;
		wxChoice* m_choice3;
		wxButton* m_button6;
		wxStaticText* m_staticText21;
		wxButton* m_button8;
		wxStaticText* m_staticText13;
		wxTextCtrl* m_textCtrl6;
		wxStaticText* m_staticText14;
		wxTextCtrl* m_textCtrl8;
		wxStaticText* m_staticText19;
		wxStaticText* m_staticText24;
		wxStaticText* m_staticText23;
		wxTextCtrl* m_textCtrl10;
		wxStaticText* m_staticText25;
		wxTextCtrl* m_textCtrl11;
		wxStaticText* m_staticText26;
		wxStaticText* m_staticText39;
		wxStaticText* m_staticText15;
		wxDatePickerCtrl* m_datePicker3;
		wxButton* m_button9;
		wxButton* m_button10;
		
		// Virtual event handlers, overide them in your derived class
		virtual void OnProductClassChoice( wxCommandEvent& event ) { event.Skip(); }
		virtual void OnMangerBuyers( wxCommandEvent& event ) { event.Skip(); }
		virtual void OnSellNumTextChange( wxKeyEvent& event ) { event.Skip(); }
		virtual void OnUnitPriceTextChange( wxKeyEvent& event ) { event.Skip(); }
		virtual void OnDealPriceTextChange( wxKeyEvent& event ) { event.Skip(); }
		virtual void OnPaidTextChange( wxKeyEvent& event ) { event.Skip(); }
		virtual void OnOkBtnClick( wxCommandEvent& event ) { event.Skip(); }
		
	
	public:
		
		DlgAddSell( wxWindow* parent, wxWindowID id = wxID_ANY, const wxString& title = wxT("添加售出记录"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxSize( 382,429 ), long style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER ); 
		~DlgAddSell();
	
};

///////////////////////////////////////////////////////////////////////////////
/// Class DlgModifySell
///////////////////////////////////////////////////////////////////////////////
class DlgModifySell : public wxDialog 
{
	private:
	
	protected:
		wxStaticText* m_staticText12;
		wxStaticText* m_staticText49;
		wxStaticText* m_staticText16;
		wxStaticText* m_staticText50;
		wxStaticText* m_staticText21;
		wxButton* m_button8;
		wxStaticText* m_staticText13;
		wxTextCtrl* m_textCtrl6;
		wxStaticText* m_staticText14;
		wxTextCtrl* m_textCtrl8;
		wxStaticText* m_staticText19;
		wxStaticText* m_staticText24;
		wxStaticText* m_staticText23;
		wxTextCtrl* m_textCtrl10;
		wxStaticText* m_staticText51;
		wxTextCtrl* m_textCtrl23;
		wxStaticText* m_staticText25;
		wxTextCtrl* m_textCtrl11;
		wxStaticText* m_staticText26;
		wxTextCtrl* m_textCtrl12;
		wxStaticText* m_staticText15;
		wxDatePickerCtrl* m_datePicker3;
		wxButton* m_button9;
		wxButton* m_button10;
	
	public:
		
		DlgModifySell( wxWindow* parent, wxWindowID id = wxID_ANY, const wxString& title = wxT("修改售出记录"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxSize( 382,411 ), long style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER ); 
		~DlgModifySell();
	
};

///////////////////////////////////////////////////////////////////////////////
/// Class DlgBuyerManager
///////////////////////////////////////////////////////////////////////////////
class DlgBuyerManager : public wxDialog 
{
	private:
	
	protected:
		wxGrid* m_grid3;
		wxButton* m_button15;
		wxButton* m_button16;
		wxStaticText* m_staticText40;
		
		// Virtual event handlers, overide them in your derived class
		virtual void OnCellChange( wxGridEvent& event ) { event.Skip(); }
		virtual void OnOKBtnClick( wxCommandEvent& event ) { event.Skip(); }
		
	
	public:
		
		DlgBuyerManager( wxWindow* parent, wxWindowID id = wxID_ANY, const wxString& title = wxT("买家信息管理"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxSize( 518,392 ), long style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER ); 
		~DlgBuyerManager();
	
};

///////////////////////////////////////////////////////////////////////////////
/// Class DlgHistoryDeals
///////////////////////////////////////////////////////////////////////////////
class DlgHistoryDeals : public wxDialog 
{
	private:
	
	protected:
		wxGrid* m_grid4;
	
	public:
		
		DlgHistoryDeals( wxWindow* parent, wxWindowID id = wxID_ANY, const wxString& title = wxT("与买家XXX历史交易"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxSize( 506,231 ), long style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER ); 
		~DlgHistoryDeals();
	
};

#endif //__NONAME_H__
