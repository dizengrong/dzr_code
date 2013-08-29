%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% Created : 30 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------


-define(DEBUG(Format, Args),
    mgeerec_logger:debug_msg(?MODULE,?LINE,Format, Args)).

-define(INFO_MSG(Format, Args),
    mgeerec_logger:info_msg(?MODULE,?LINE,Format, Args)).
			      
-define(WARNING_MSG(Format, Args),
    mgeerec_logger:warning_msg(?MODULE,?LINE,Format, Args)).
			      
-define(ERROR_MSG(Format, Args),
    mgeerec_logger:error_msg(?MODULE,?LINE,Format, Args)).

-define(CRITICAL_MSG(Format, Args),
    mgeerec_logger:critical_msg(?MODULE,?LINE,Format, Args)).

-define(ETS_MM_MAP, ets_mm_map).

-define(DO_HANDLE_INFO(Info,State),  
        try do_handle_info(Info) catch _:Reason -> ?ERROR_MSG("Info:~w,State=~w, Reason: ~w, strace:~w", [Info,State, Reason, erlang:get_stacktrace()]) end).

-define(DO_HANDLE_INFO_STATE(Info, State), 
        try do_handle_info(Info, State) catch _:Reason -> ?ERROR_MSG("Info:~w,State=~w, Reason: ~w, strace:~w", [Info,State, Reason, erlang:get_stacktrace()]) end).
