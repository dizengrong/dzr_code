-module(mgeec_auth).

-behavior(gen_server).

-include("mgeec.hrl").

-record(state, {}).

-export([start/0, start_link/0, init/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

start() ->
	{ok, _} = supervisor:start_child(
                mgeec_sup, 
                {?MODULE, 
                 {?MODULE, start_link, []}, 
                 transient, 10000, worker, [?MODULE]}).

start_link() ->
    {ok, _Pid} = gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.

handle_info({'EXIT', _Pid, _Reason}, State) ->
    %%?DEBUG("~ts:Pid-->~w Reason-->~w", ["聊天服玩家验证守护进程收到其他进程的退出消息", Pid, Reason]),
    {noreply, State};

handle_info(_Info, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast(_Info, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.
   
handle_call(_Info, _From, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.