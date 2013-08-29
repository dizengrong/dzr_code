-module(manager_client).

-behavior(gen_server).

-include("manager.hrl").

-export([start_link/0, init/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

-record(state, {}).

start_link() ->
    StartResult = gen_server:start_link(?MODULE, [], []),
    %%StartResult = gen_server:start_link({global, PName}, ?MODULE, [], []),
    case StartResult of
        {ok, Pid} ->
            {ok, Pid};
        {error,{already_started, Pid}} ->
            {ok, Pid};
        Other ->
            ?ERROR_MSG("~ts:~w", ["创建管理员进程失败了", Other]),
            throw(Other)
    end.

init([]) ->
    {ok, #state{}}.

handle_info({'EXIT', _, {socket_send_error, Reason}}, State) ->
    ?DEBUG("~ts:~w", ["管理员退出，原因是发包出错", Reason]),
    {stop, normal, State};

handle_info({'EXIT', _Pid, offline}, State) ->
    {stop, normal, State};

handle_info({'EXIT', _PID, normal}, State) ->
    {stop, normal, State};

handle_info(Info, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast({router, RouterData}, State) ->

    ?DEV("~ts:~w", ["执行路由数据", RouterData]),

    NewState = mod_router:router(RouterData, State),

    ?DEV("~ts:~w", ["执行路由后新状态数据", NewState]),
    {noreply, NewState};
    
handle_cast(Info, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.

handle_call(login_again, _From, State) ->
    ?DEV("~ts:~w", ["管理员重复登录", State]),
    {stop, normal, ok, State};
   
handle_call(Info, _From, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.    