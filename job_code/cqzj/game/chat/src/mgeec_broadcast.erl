%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-11
%%% -------------------------------------------------------------------
-module(mgeec_broadcast).

-behaviour(gen_server).

-include("mgeec.hrl").
%% --------------------------------------------------------------------
-export([
         start/0,
         add_child_process/1
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================

start() ->
    N = erlang:system_info(schedulers),
    [supervisor:start_child(mgeec_broadcast_sup, [I]) 
     || I <- lists:seq(1,N)].

add_child_process(I) ->
    Name = process_name(I),
    gen_server:start_link({global, Name}, ?MODULE, [], []).

%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%% --------------------------------------------------------------------
handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.

%% --------------------------------------------------------------------
handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~w", [Info]),
    {noreply, State}.

%% --------------------------------------------------------------------
terminate(Reason, State) ->
    ?INFO_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
    ok.

%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
process_name(I) ->
    lists:concat([mgeec_broadcast_, I]).
