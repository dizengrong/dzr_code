%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-17
%%% -------------------------------------------------------------------
-module(mgeel_s2s).

-behaviour(gen_server).
-include("mgeel.hrl").

%% --------------------------------------------------------------------
-export([start/1, start_link/1]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(TCP_OPTS, [
                   binary, 
                   {packet, 4}, 
                   {reuseaddr, true}, 
                   {nodelay, true}, 
                   {active, false},
                   {exit_on_close, false}
                  ]).

-record(state,{socket,pid}).

%% --------------------------------------------------------------------


start(Port) ->
    {ok, _} = supervisor:start_child(mgeel_sup, {mgeel_s2s,
                                                 {mgeel_s2s, start_link, [Port]},
                                                 transient, brutal_kill, worker, 
                                                 [mgeel_s2s]}).

start_link(Port) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Port], []).


%% --------------------------------------------------------------------
init([Port]) ->
    case gen_tcp:listen(Port, ?TCP_OPTS) of
        {ok, ListenSocket} ->
            self() ! {event, start_s2s_client},
            %%self() ! {event, start},
            {ok, #state{socket=ListenSocket}};
        {error, Reason} ->
            {stop, Reason}
    end.


%% --------------------------------------------------------------------
handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.

handle_info({event, start_s2s_client}, State) ->
    case mgeel_s2s_client:start() of
        {ok, CPid} ->
            {noreply,State#state{pid=CPid}};
        _ ->
            {noreply,State}
    end;

%% 暂时废弃的代码
handle_info({event, start}, State) ->
    self() ! {event, start},
    case gen_tcp:accept(State#state.socket) of
        {ok, ClientSock} ->
            case mgeel_s2s_client:start(ClientSock) of
                {ok, CPid} ->
                    ?DEBUG("Pid:~w~n",[CPid]),
                    gen_tcp:controlling_process(ClientSock,CPid),
                    CPid ! {event, run},
                    {noreply,State#state{pid=CPid}};
                _ ->
                    gen_tcp:close(ClientSock),
                    {noreply,State}
            end;
        {error, Reason} ->
            ?ERROR_MSG("unable to accept s2s:~w", [Reason]),
            {noreply,State}
    end;

handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~w", [Info]),
    {noreply, State}.

terminate(Reason, State) ->
    ?INFO_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

