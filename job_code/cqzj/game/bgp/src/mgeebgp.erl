%%%----------------------------------------------------------------------
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author bisonwu 2010-05-27
%%% @doc mgeebgp application
%%%		bgproxy is short for border gateway proxy
%%% @end
%%%----------------------------------------------------------------------

-module(mgeebgp).

-behaviour(application).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").

%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([
	 start/0,		 
	 start/2,
	 stop/0,
	 stop/1
        ]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(APPS, [sasl, mgeebgp]).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% API Functions
%% --------------------------------------------------------------------

%% @spec start/0
start() ->
	try
        ok = mgeebgp_misc:start_applications(?APPS) 
    after
        %%give the error loggers some time to catch up
        timer:sleep(100)
    end.

%% @spec stop/0
stop() ->
    ok = mgeebgp_misc:stop_applications(?APPS).

%% ====================================================================!
%% External functions 
%% ====================================================================!
%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
start(_Name, []) ->
    {ok, SupPid} = mgeebgp_sup:start_link(),
    Apps = [
            {"INETS", 
             fun() -> 
                     inets:start() 
             end },
            {"Behavior Logger",
             fun() ->
                     bgp_serverlog:start(),
                     error_logger:add_report_handler(bgp_logger_h, ""),
                     {ok, LogLevel} = application:get_env(log_level),
                     common_loglevel:set(LogLevel)
             end},
            {"MGEE BGP Monitor",
             fun () ->
                     mgeebgp_monitor:start()
             end },
            {"MGEE BGP Server",
             fun () ->
                     mgeebgp_server:start()
             end }				
           ],
    lists:foreach(
      fun ({Msg, Thunk}) ->
              io:format("starting ~-30s ...~n", [Msg]),
              Thunk(),
		 	  io:format("starting ~-30s done.~n", [Msg]);
          ({Msg, M, F, A}) ->
              io:format("starting ~-30s ...~n", [Msg]),
              apply(M, F, A),
              io:format("starting ~-30s done.~n", [Msg])
      end,
	  Apps),
	io:format("~nsystem running :)~n~n"),
    {ok, SupPid}.

%% --------------------------------------------------------------------
%% Func: stop/1
%% Returns: any
%% --------------------------------------------------------------------
stop(_State) ->
    ok.


