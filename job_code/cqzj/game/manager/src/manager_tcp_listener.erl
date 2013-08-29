-module(manager_tcp_listener).

-include("manager.hrl").

-behavior(gen_server).

-export([start_link/0, init/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

start_link() ->
    {ok, _Pid} = 
        gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    [ManagerPort] = common_config_dyn:find_common(manager_port),
    AcceptorNum = 10,
    {ok, Socket} = gen_tcp:listen(ManagerPort, ?TCP_OPTS),
    lists:foreach(
      fun(true) ->
              supervisor:start_child(manager_tcp_acceptor_sup, [Socket])
      end, lists:duplicate(AcceptorNum, true)),
    {ok, #state{}}.

handle_info(Info, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast(Info, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.
   
handle_call(Info, _From, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
    



    
