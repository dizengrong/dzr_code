%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 定时删除
%%% @end
%%% Created : 14 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_delete).

-behaviour(gen_server).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


-record(state, {interval_time}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link({ProcessName}) ->
    gen_server:start_link({local, list_to_atom(ProcessName)}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    State = init_process(),
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DEBUG("~ts Info=~w",["接收到的消息为：",Info]),
    do_handle_info(Info, State),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% 初始化

init_process() ->
    IntervalTime = get_msg_delete_interval_time(),
    erlang:send_after(IntervalTime, self(), {delete_message}),
    #state{interval_time = IntervalTime}.
    
do_handle_info({delete_message}, State) ->
    #state{interval_time = IntervalTime} = State,
    do_delete_message(),
    erlang:send_after(IntervalTime, self(), {delete_message});

%% 添加外部操作本进程内部执行接口
do_handle_info({func, Fun, Args}, _State) ->
    Ret =(catch apply(Fun,Args)),
    ?ERROR_MSG("~w",[Ret]);

do_handle_info(Info, _State) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息",Info]).

%% 删除已经广播完成的消息
do_delete_message() ->
    Parrten = #r_broadcast_message{msg_type = ?BROADCAST_COUNTDOWN, send_flag = 1, _ = '_'},
    try
        case db:dirty_match_object(?DB_BROADCAST_MESSAGE,Parrten) of
            [] -> 
                ?DEBUG("~ts",["此次删除动作查询不到合法的数据需要删除，操作完成"]);
            RecordList when erlang:is_list(RecordList) ->
                ?DEBUG("~ts,Length=~w",["此次删除操作需要删除的记录条数为：",erlang:length(RecordList)]),
                lists:foreach(fun(Record) ->
                                      db:dirty_delete_object(?DB_BROADCAST_MESSAGE,Record)
                              end,RecordList)
        end
    catch 
        _:Reason ->
            ?ERROR_MSG("~ts Reason=~w.", ["删除已广播完成的消息数据出错",Reason])
    end.


%% 获取删除已经广播完成的消息的时间间隔
get_msg_delete_interval_time() ->
    case common_config_dyn:find(broadcast, msg_delete_interval_time) of
        [IntervalTime] -> IntervalTime;
        _ -> ?DEFAULT_MSG_DELETE_INTERVAL_TIME
    end.
