%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2010-3-26
%%% -------------------------------------------------------------------
-module(mgeeg_role_sock_map).

-behaviour(gen_server).

-export([start/0,start_link/0]).


-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
start() -> 
    {ok, _} = supervisor:start_child(mgeeg_sup, 
                                     {mgeeg_role_sock_map,
                                      {mgeeg_role_sock_map, start_link, []},
                                      permanent, 1000, worker, 
                                      [mgeeg_role_sock_map]}).


start_link()->
    gen_server:start_link({local,?MODULE},?MODULE,[],[]).


%% --------------------------------------------------------------------
init([]) ->
    ets:new(mgeeg_role_sock_map, [set,protected,named_table]),
    {ok, #state{}}.

%% --------------------------------------------------------------------

handle_call(shutdown, _, State) ->
    do_shutdown(),
    {reply, ok, State};

handle_call(_, _, State) ->
    {reply, ok, State }.

%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
handle_info({role, Role, Pid, Sock}, State) ->
    case ets:info(mgeeg_role_sock_map) of
        undefined ->
            ets:new(mgeeg_role_sock_map, [set,protected,named_table]);
        _ ->
            nil
    end,
    ets:insert(mgeeg_role_sock_map, {Role,Sock}),	
    ets:insert(mgeeg_role_sock_map, {Pid,Sock}),
    {noreply, State};


handle_info({erase,Role,Pid}, State) ->
    case ets:info(mgeeg_role_sock_map) of
        undefined ->
            ets:new(mgeeg_role_sock_map, [set,protected,named_table]);
        _ ->
            ets:delete(mgeeg_role_sock_map, Role),
            ets:delete(mgeeg_role_sock_map, Pid)
    end,
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------

do_shutdown() ->
    List = ets:tab2list(mgeeg_role_sock_map),
    lists:foreach(
      fun({P, _}) ->
              case erlang:is_pid(P) of
                  true ->
                      gen_server:call(P, shutdown);
                  false ->
                      ignore
              end
      end, List).
                      
