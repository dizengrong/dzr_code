%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-4-29
%%% -------------------------------------------------------------------
-module(mgeeg_moniter).

-behaviour(gen_server).
-include("mgeeg.hrl").
-export([
         start/3, 
         start_link/3
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {line}).

start(Host, Port, Line) ->
	ID = common_tool:to_atom(lists:concat([?MODULE,"_",Line])),
    {ok, _} = supervisor:start_child(
                mgeeg_sup, 
                {ID, 
                 {?MODULE, start_link, [Host, Port, Line]}, 
                 transient, 10000, worker, [?MODULE]}).

start_link(Host, Port, Line) ->
    gen_server:start_link(?MODULE, [Host, Port, Line], []).


init([Host, Port, Line]) ->
    register_to_login(Host, Port),
    timer:send_after(100, send_run_queue),
    {ok, #state{line=Line}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%%向login.server发送负载信息
handle_info(send_run_queue, State = #state{line=Line}) ->
    case global:whereis_name(mgeel_line) of
        undefined ->
            ignore;
        _ ->
            global:send(mgeel_line, {run_queue, Line, erlang:length(erlang:processes())})
    end,
    timer:send_after(1000, send_run_queue),
    {noreply, State};
    
handle_info(Info, State) ->
    ?DEBUG("unknow info ~w ~w", [Info, State]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------

register_to_login(Host, Port) ->
    gen_server:call({global, mgeel_line}, {register, Host, Port}).

