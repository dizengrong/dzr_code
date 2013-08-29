%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 用于缓存在各个server中的日志消息
%%%
%%% @end
%%% Created : 29 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(behavior_cache_server).

-behaviour(gen_server).

-include("mgeeb.hrl").

%% API
-export([
         start/1, 
         start_link/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

-define(DICT_KEY_BEHAVIOR_CACHE, dict_key_behavior_cache).
-define(MSG_FLUSH_BEHAVIOR,flush_behavior).
-define(MSG_FLUSH_BEHAVIOR_FILE,flush_behavior_file).

%%日志最大的缓存数量
-define(BEHAVIOR_MAX_CACHE_NUM, 1).

%%刷新缓存的时间，单位为ms，默认30秒
-define(BEHAVIOR_FLUSH_CACHE_TICKET, 30*1000).

%%%===================================================================
%%% API
%%%===================================================================


%%--------------------------------------------------------------------
start(SupName) ->
    {ok, _} = supervisor:start_child(SupName, {?MODULE, 
                                               {?MODULE, start_link, []},
                                               transient, brutal_kill, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%%%===================================================================


%%--------------------------------------------------------------------
init([]) ->
    init_behavior(),
    erlang:send_after(?BEHAVIOR_FLUSH_CACHE_TICKET,self(), ?MSG_FLUSH_BEHAVIOR),
    erlang:send_after(?BEHAVIOR_FLUSH_CACHE_TICKET,self(), ?MSG_FLUSH_BEHAVIOR_FILE),
    {ok, #state{}}.

%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.


%%--------------------------------------------------------------------
handle_info(?MSG_FLUSH_BEHAVIOR, State) ->
    flush_behavior(),
    erlang:send_after(?BEHAVIOR_FLUSH_CACHE_TICKET, self(),?MSG_FLUSH_BEHAVIOR),
    {noreply, State};
handle_info(?MSG_FLUSH_BEHAVIOR_FILE, State) ->
    flush_behavior_file(),
    erlang:send_after(?BEHAVIOR_FLUSH_CACHE_TICKET, self(),?MSG_FLUSH_BEHAVIOR_FILE),
    {noreply, State};
handle_info({behavior, Info}, State) ->
    do_behavior(Info),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.


%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_behavior({ModuleTuple, MethodTuple, DataRecord}) ->

    {PBModule, _PHPControllerName} = ModuleTuple,
    {PBMethod, _PHPMethodName} = MethodTuple,
    
    case catch encode(DataRecord) of

        {'EXIT', Error} ->

            ?ERROR_MSG("~ts:~w, ~w, ~w -> ~w", 
                       ["编码日志结构体出错", PBModule, PBMethod, DataRecord, Error]
                      );

        DataBin ->
            %% 将DataRecord 转换为DataBin
            Old = get_behavior(),
            New = [{ModuleTuple, MethodTuple, DataBin} | Old],

            case erlang:length(New) > ?BEHAVIOR_MAX_CACHE_NUM of
                true ->
                    update_behavior(New),
                    flush_behavior();
                false ->
                    update_behavior(New)
            end

    end.

encode(DataRecord) ->
    erlang:term_to_binary(DataRecord).

%%获取当前缓存的所有行为日志数据
get_behavior() ->
    get(?DICT_KEY_BEHAVIOR_CACHE).
%%更新缓存的行为日志数据
update_behavior(New) ->
    put(?DICT_KEY_BEHAVIOR_CACHE, New).
%%发送所有的缓存日志，并清空

flush_behavior() ->
    case global:whereis_name(behavior_server) of
        undefined ->
            %%?ERROR_MSG("~w没有正常启动，请确保receiver server可以正常连接",[behavior_server]),
            ok;
        _ ->
            do_flush_behavior(get_behavior())
    end.

flush_behavior_file() ->
    case global:whereis_name(behavior_server) of
        undefined ->
            IsInDebug = common_config:is_debug(),
            if
                IsInDebug =:= false ->
                    [AgentName] = common_config_dyn:find_common(agent_name),
                    [ServerName] = common_config_dyn:find_common(server_name),
                    {{Y, M, D}, {H, I, S}} = calendar:local_time(),
                    File = lists:concat(["/data/logs/",AgentName,"_",ServerName,"/behavior.", Y, M, D, H, I, S, ".log"]),
                    file:write_file(File, erlang:term_to_binary(get_behavior())),
                    clear_behavior();
                true ->
                    ignore
            end,
            ok;
        _ ->
            ignore
    end.

do_flush_behavior(undefined) ->
    ignore;
do_flush_behavior([]) ->
    ignore;
do_flush_behavior(List) ->
    global:send(behavior_server, {behavior_list, List}),
    clear_behavior().
    
%%清空日志
clear_behavior() ->
    put(?DICT_KEY_BEHAVIOR_CACHE, []).
%%初始化日志数据
init_behavior() ->
    put(?DICT_KEY_BEHAVIOR_CACHE, []).
