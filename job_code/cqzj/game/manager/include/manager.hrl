-define(APP_NAME, 'manager.server').

-define(DEV(Format, Args),
        common_logger:dev(?APP_NAME, ?MODULE, ?LINE, Format, Args)).

-define(DEBUG(Format, Args),
        common_logger:debug_msg(?APP_NAME, ?MODULE,?LINE,Format, Args)).

-define(INFO_MSG(Format, Args),
        common_logger:info_msg( node(), ?MODULE,?LINE,Format, Args)).
			      
-define(WARNING_MSG(Format, Args),
        common_logger:warning_msg( node(), ?MODULE,?LINE,Format, Args)).

			      
-define(ERROR_MSG(Format, Args),
        common_logger:error_msg( node(), ?MODULE,?LINE,Format, Args)).

%%带STACK的ERROR_MSG
-define(ERROR_MSG_STACK(Arg1,Arg2),  %% Args为两个参数
        common_logger:error_msg( node(), ?MODULE,?LINE,"Info:~s, Error: ~w, Stack:~w", [Arg1,Arg2,erlang:get_stacktrace()])).

-define(CRITICAL_MSG(Format, Args),
        common_logger:critical_msg( node(), ?MODULE,?LINE,Format, Args)).

-define(HOOK_CATCH(F), try F() catch E:E2 -> ?ERROR_MSG("~p ~p ~p", [E, E2, erlang:get_stacktrace()]) end).


-define(TCP_OPTS, [
                   binary, 
                   {packet, 2},
                   {reuseaddr, true}, 
                   {nodelay, false},   
                   {delay_send, true}, 
                   {active, false},
                   {exit_on_close, false},
                   {send_timeout, 3000}
                  ]).

-define(CLIENT_PROCESS_EXIT_WAIT, 500).

-define(HEART_BEAT, <<"00">>).
-include("common.hrl").
