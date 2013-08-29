%% Author: dzr
%% Created: 2011-9-20
%% Description: TODO: Add description to mydbg_gui
-module(mydbg_gui).

%%=============================================================================
%% Include files
%%=============================================================================
-include_lib("wx/include/wx.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([start/0]).

-export([create_window/0]).

-define(START_TRACE,  100).
-define(ADD_MODULE, 101).
-define(STOP_TRACE, 102).
-define(PRINT_TRACE, 103).
-define(CLEAR_TRACE, 104).
-define(MOD_LISTBOX, 105).

-record(win_info, {main_frame,
				   print_win,
				   msg_label,
				   mod_list}).
%%=============================================================================
%% API Functions
%%=============================================================================
start() ->
	spawn_link(?MODULE, create_window, []).

create_window() ->
	wx:new(),
	Frame = wxFrame:new(wx:null(), -1, "mydebug", [{size, {600,800}}]),
    wxFrame:connect(Frame, close_window),
	
	MainSz = wxBoxSizer:new(?wxHORIZONTAL),
    LeftSz = wxBoxSizer:new(?wxVERTICAL),

    Panel = wxPanel:new(Frame),
	
	%% add left protocal box
    ModListBox = wxListBox:new(Panel, ?MOD_LISTBOX, [{size, {120, 200}}]),
         
    wxSizer:add(LeftSz,ModListBox,[{border, 3}]),
	
	SBox = wxStaticBox:new(Panel, ?wxID_ANY, ""),
	
    SBS  = wxStaticBoxSizer:new(SBox, ?wxVERTICAL),
	
	StartBtn = wxButton:new(Panel, ?START_TRACE, [{label,"start trace"}]),
    wxButton:connect(StartBtn, command_button_clicked),
    AddTraceBtn = wxButton:new(Panel, ?ADD_MODULE, [{label,"add module"}]),
    wxButton:connect(AddTraceBtn, command_button_clicked),
    StopBtn = wxButton:new(Panel, ?STOP_TRACE, [{label,"stop trace"}]),
    wxButton:connect(StopBtn, command_button_clicked),
    PrintBtn  = wxButton:new(Panel, ?PRINT_TRACE, [{label, "print trace"}]),
    wxButton:connect(PrintBtn, command_button_clicked),
	ClearBtn  = wxButton:new(Panel, ?CLEAR_TRACE, [{label, "clear trace"}]),
    wxButton:connect(ClearBtn, command_button_clicked),
	StateText = wxStaticText:new(Panel, ?wxID_ANY, "message:\n"), 
	
	wxSizer:addSpacer(LeftSz,2),
    SF = wxSizerFlags:new(),
    wxSizerFlags:proportion(SF,1),
    wxSizer:add(SBS, StartBtn, [{flag, ?wxEXPAND}]), 
    wxSizer:addSpacer(LeftSz,3),
    wxSizer:add(SBS, AddTraceBtn,[{flag, ?wxEXPAND}]),
    wxSizer:addSpacer(LeftSz,3),   
    wxSizer:add(SBS, StopBtn, [{flag, ?wxEXPAND}]),
    wxSizer:addSpacer(LeftSz,3),   
    wxSizer:add(SBS, PrintBtn, [{flag, ?wxEXPAND}]),
    wxSizer:addSpacer(LeftSz,3),
	wxSizer:add(SBS, ClearBtn, [{flag, ?wxEXPAND}]),
	wxSizer:addSpacer(LeftSz,3),
	wxSizer:add(SBS, StateText, [{flag, ?wxEXPAND}]),
    wxSizer:addSpacer(MainSz,3),
	wxSizer:add(LeftSz,SBS, [{flag,?wxEXPAND}]),
	wxSizer:add(MainSz, LeftSz, [{border, 3}, {flag,?wxALL bor ?wxEXPAND}]),
	

	PrintTextCtrl = wxTextCtrl:new(Panel, ?wxID_ANY, [{value, "trace message will show here\n"}, 
													  {style, ?wxTE_MULTILINE},
													  {size, {670, 400}}]),
	wxTextCtrl:setEditable(PrintTextCtrl, false),
	wxSizer:add(MainSz, PrintTextCtrl, wxSizerFlags:proportion(wxSizerFlags:expand(SF),1)),
    wxWindow:setSizer(Panel,MainSz),
    wxSizer:fit(MainSz, Frame),
    wxSizer:setSizeHints(MainSz,Frame),
    wxWindow:show(Frame),
	
	WinInfo = #win_info{main_frame = Frame, 
			  print_win = PrintTextCtrl, 
			  msg_label = StateText,
			  mod_list = ModListBox},
	loop(WinInfo),
	wx:destroy().

%%=============================================================================
%% Local Functions
%%=============================================================================

loop(WinInfo) ->
	receive
		#wx{event = #wxClose{type = close_window}} ->
			wxWindow:destroy(WinInfo#win_info.main_frame);
		#wx{id = ?START_TRACE, event = #wxCommand{type = command_button_clicked}} ->
			mydebug:start(),
			wxStaticText:setLabel(WinInfo#win_info.msg_label, "message:\n    trace started"),
			loop(WinInfo);
		#wx{id = ?ADD_MODULE, event = #wxCommand{type = command_button_clicked}} ->
			Prompt = "add module to trace",
			MD = wxTextEntryDialog:new(WinInfo#win_info.main_frame, 
									   Prompt, 
									   [{caption, "add module"}]),
			case wxTextEntryDialog:showModal(MD) of
				?wxID_OK ->
					Mod = wxTextEntryDialog:getValue(MD),
					mydebug:trc(list_to_atom(Mod)),
					wxListBox:append(WinInfo#win_info.mod_list, Mod),
					wxStaticText:setLabel(WinInfo#win_info.msg_label, "message:\n    add " ++ Mod);
				_ ->
					ok
			end,
			wxDialog:destroy(MD),
			loop(WinInfo);
		#wx{id = ?STOP_TRACE, event = #wxCommand{type = command_button_clicked}} ->
			mydebug:stop(),
			wxStaticText:setLabel(WinInfo#win_info.msg_label, "message:\n    trace stopped"),
			loop(WinInfo);
		#wx{id = ?PRINT_TRACE, event = #wxCommand{type = command_button_clicked}} ->
			TraceFile = atom_to_list(node()) ++ "-debug_log",
			FormatFile = "trace_tmp",
			mydebug:format(TraceFile, FormatFile),
			{ok, Fd} = file:open(FormatFile, [read]),
			wxTextCtrl:appendText(WinInfo#win_info.print_win, 
								  "\n=========================== new trace ======================\n\n"),
			print_trace_msg(Fd, WinInfo#win_info.print_win),
			file:close(Fd),
			loop(WinInfo);
		#wx{id = ?CLEAR_TRACE, event = #wxCommand{type = command_button_clicked}} ->
			wxTextCtrl:clear(WinInfo#win_info.print_win),
			wxListBox:clear(WinInfo#win_info.mod_list),
			wxStaticText:setLabel(WinInfo#win_info.msg_label, "message:\n    clear"),
			loop(WinInfo)
	end.
	
print_trace_msg(Fd, PrintTextCtrl) ->
	case file:read_line(Fd) of
		{ok, Data} ->
			wxTextCtrl:appendText(PrintTextCtrl, Data),
			print_trace_msg(Fd, PrintTextCtrl);
		eof ->
			ok
	end.
	
	
