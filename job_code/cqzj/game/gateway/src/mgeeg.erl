%%%----------------------------------------------------------------------
%%% File    : mgeeg.erl
%%% Author  : Liangliang
%%% Purpose : MGEE application
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeeg).

-behaviour(application).
-include("mgeeg.hrl").
-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [mgeeg]).

%% --------------------------------------------------------------------

start() ->
    try
        ok = common_misc:start_applications(?APPS) 
    after
        %%give the error loggers some time to catch up
        timer:sleep(100)
    end.

stop() ->
    common_global:put(mgeeg_stop, true),
    ok = common_misc:stop_applications(?APPS).


%% --------------------------------------------------------------------
start(normal, []) ->
    {ok, SupPid} = mgeeg_sup:start_link(),
	[[{_, Host, Ports}]] = common_config_dyn:find_common(gateway),
    lists:foreach(
      fun ({Msg, Thunk}) ->
              io:format("starting ~-24s ...", [Msg]),
              Thunk(),
              io:format("done~n");
          ({Msg, M, F, A}) ->
              io:format("starting ~-20s ...", [Msg]),
              apply(M, F, A),
              io:format("done~n")
      end, 
      [
       {"MGEE Line Role-Sock Map Server",
        fun () -> 
                mgeeg_role_sock_map:start() 
        end},
	   {"MGEE Net Working",
        fun () ->
	   		mgeeg_networking:start()
		end},
       {"MGEE Line Moniter",
        fun () ->
                mgeeg_stat_server:start(),
				lists:foreach(fun(Port) ->
                	mgeeg_moniter:start(Host, Port, Port)
				end, Ports)
        end},
       {"MGEE Line Unicast Server",
        fun () ->
			lists:foreach(fun(Line) ->
                mgeeg_unicast:start(Line)
			end, Ports)  
        end},
	   {"Global Gateway Server", 
        fun() ->
                global_gateway_server:start()
        end},
       {"TCP listeners",
        fun () ->
			lists:foreach(fun
				(Port) when Port > 0 ->
            		ok = mgeeg_networking:start_tcp_listener(Port, Port, 30);
                (_Port) ->
                    throw(wrong_port)
			end, Ports)
        end}
      ]),
    ?SYSTEM_LOG("~ts~n", ["mgeeg启动成功"]),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_Line) ->
	  ok.

