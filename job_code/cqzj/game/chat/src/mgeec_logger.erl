%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录聊天日志
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mgeec_logger).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeec.hrl").

%% API
-export([start/0, start_link/0,tmp_add_ets/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).
-export([log_channel/3, log_pairs/3]).

-export([]).
-record(state, {}).

%% 默认每15秒钟进行数据的缓存
-define(INTERVAL_SAVE_CHAT_LOG, 15*1000).
-define(MSG_DUMP_LOG, dump_chat_log).
-define(SERVER, ?MODULE).
-define(FACTION_ID_LIST, [1,2,3]).

%%%===================================================================
start() ->
    {ok, _Pid} =  supervisor:start_child(mgeec_sup, 
                                         {?MODULE, 
                                          {?MODULE, start_link, []},
                                          permanent, 1000, worker, [?MODULE]
                                         }).

start_link() ->
    StartResult = gen_server:start_link({local, ?MODULE}, ?MODULE, [], []),
    
    {ok, _Pid} =  case StartResult of
                      {ok, ServerPid} ->
                          {ok, ServerPid};
                      {error,{already_started, ServerPid}} ->
                          {ok, ServerPid};
                      Other ->
                          ?ERROR_MSG("~ts:~w", ["创建日志进程失败了", Other]),
                          Other
                  end.


log_channel(ChannelSign, RoleChatInfo, Msg) ->
    #p_chat_role{ rolename=RoleName } = RoleChatInfo,
    case is_world_channel(ChannelSign) of
        true->
            gen_server:cast(?SERVER, {channel_world, ChannelSign, RoleName, Msg});
        false->
            case is_faction_channel(ChannelSign) of
                true->
                    gen_server:cast(?SERVER, {channel_faction, ChannelSign, RoleName, Msg});
                false->
                    case is_level_channel(ChannelSign) of
                        true->
                            gen_server:cast(?SERVER, {channel_level_channel, ChannelSign, RoleName, Msg});
                        false->
                            ignore
                    end
            end
    end.

is_world_channel(ChannelSign)->
    ChannelSign =:= ?CHANNEL_SIGN_WORLD.

is_faction_channel(ChannelSign)->
    string:str(ChannelSign, ?CHANNEL_SIGN_FACTION)>0.

is_level_channel(ChannelSign)->
    string:str(ChannelSign, ?CHANNEL_SIGN_LEVEL_CHANNEL)>0.

log_pairs(_ToRoleID, _RoleChatInfo, _Msg) ->
    %% 不记录私人消息
    ignore.

tmp_add_ets()->
    gen_server:call(mgeec_logger, add_ets).

%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
%%--------------------------------------------------------------------
init([]) ->
    ets:new(?ETS_CHAT_LOG_WORLD, [duplicate_bag, protected, named_table]),
    ets:new(?ETS_CHAT_LOG_COUNTRY, [duplicate_bag, protected, named_table]),
    ets:new(?ETS_CHAT_LOG_LEVEL_CHANNEL, [duplicate_bag, protected, named_table]),
    erlang:send_after(?INTERVAL_SAVE_CHAT_LOG,self(),?MSG_DUMP_LOG),
    {ok, #state{}}.
    
%%--------------------------------------------------------------------
handle_call(add_ets, _, State) ->
    ets:new(?ETS_CHAT_LOG_LEVEL_CHANNEL, [duplicate_bag, protected, named_table]),
    {reply, ok, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.
%%--------------------------------------------------------------------
handle_cast(Msg, State) ->
    do_handle_cast(Msg),
    {noreply, State}.
%%--------------------------------------------------------------------

handle_info(?MSG_DUMP_LOG, State) ->
    %%%%?DEBUG("start to save_chat_log",[]),
    
    do_dump_chat_log(),
    erlang:send_after(?INTERVAL_SAVE_CHAT_LOG,self(),?MSG_DUMP_LOG),
    
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


%% ====================================================================
%% Local Functions
%% ====================================================================

do_handle_cast({channel_world, ChannelSign, RoleName, Msg})->
    
    ets:insert(?ETS_CHAT_LOG_WORLD,{ChannelSign,get_content_binary(RoleName,Msg)});
do_handle_cast({channel_faction, ChannelSign, RoleName, Msg})->

    ets:insert(?ETS_CHAT_LOG_COUNTRY,{ChannelSign,get_content_binary(RoleName,Msg)});

do_handle_cast({channel_level_channel, ChannelSign, RoleName, Msg})->
    ets:insert(?ETS_CHAT_LOG_LEVEL_CHANNEL,{ChannelSign,get_content_binary(RoleName,Msg)});

do_handle_cast(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

get_content_binary(RoleName,Msg)->
    SecNow= common_tool:hour_minute_second_format(),
    list_to_binary(
      lists:concat([ "[", SecNow,"]  ",RoleName,"    ",Msg,"\n" ])
                  ).

%%@doc 存储聊天日志,按天、频道来分目录；按小时来分文件
do_dump_chat_log()->
    try
        do_dump_world_chat_log(),
        do_dump_country_chat_log(),
        do_dump_level_chat_log()
    catch
        _:Reason->
            ?ERROR_MSG("do_dump_chat_log error,Reason=~w,Stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

%%@doc dump世界的聊天日志
do_dump_world_chat_log()->
    ChannelSign = ?CHANNEL_SIGN_WORLD,
    
    case ets:tab2list(?ETS_CHAT_LOG_WORLD) of
        []-> ignore;
        LogList ->
            %%%%?DEBUG("wuzesen,LogList=~w",[LogList]),
            filelib:ensure_dir( get_channel_dir(ChannelSign) ),
            LogFile = get_channel_file(ChannelSign),
            
            BinContent = list_to_binary( [Data|| {_Key,Data}<-LogList ] ),
            ok = file:write_file(LogFile, BinContent, [append]),
            ets:delete_all_objects(?ETS_CHAT_LOG_WORLD)
    end.

%%@doc dump国家的聊天日志
do_dump_country_chat_log()->
    [  do_dump_one_channel_log( ?ETS_CHAT_LOG_COUNTRY,
                                common_misc:chat_get_faction_channel_pname(FactionID) ) || 
         FactionID <- ?FACTION_ID_LIST ].



do_dump_one_channel_log(Tab,ChannelSign)->
    
    case ets:lookup(Tab,ChannelSign) of
        []-> ignore;
        LogList ->
            %%%%?DEBUG("wuzesen,LogList=~w",[LogList]),
            filelib:ensure_dir( get_channel_dir(ChannelSign) ),
           
            LogFile = get_channel_file(ChannelSign),
            BinContent = list_to_binary( [Data|| {_Key,Data}<-LogList ] ),
            ok = file:write_file(LogFile, BinContent, [append]),
            ets:delete(Tab, ChannelSign)
    end.

%%@doc dump等级群组的聊天日志
do_dump_level_chat_log()->
    {level_channel, LevelList} =  mgeec_config:get_config(level_channel),
    %%lists:concat([?CHANNEL_SIGN_LEVEL_CHANNEL, "_", ChannelID, "_", FactionID]),
    lists:foreach(fun(LevelConfig)->
                          {_Start, _End, ChannelID, _ChannelName}=LevelConfig,
                          lists:foreach(fun(FactionID)->
                                                Sign = lists:concat([?CHANNEL_SIGN_LEVEL_CHANNEL, "_", ChannelID, "_", FactionID]),
                                                do_dump_one_level_chat_log(?ETS_CHAT_LOG_LEVEL_CHANNEL,Sign)
                                                end,?FACTION_ID_LIST)
                          end,
                  LevelList).

do_dump_one_level_chat_log(Tab,ChannelSign)->
    case ets:lookup(Tab,ChannelSign) of
        []-> ignore;
        LogList ->
            %%?ERROR_MSG("caisiqiang,LogList=~w~n",[LogList]),
            filelib:ensure_dir( get_channel_dir(ChannelSign) ),
           
            LogFile = get_channel_file(ChannelSign),
            BinContent = list_to_binary( [Data|| {_Key,Data}<-LogList ] ),
            ok = file:write_file(LogFile, BinContent, [append]),
            ets:delete(Tab, ChannelSign)
    end.

%%@doc 获取频道目录名
get_channel_dir(ChannelSign)->
    DateDirName = common_tool:date_format(),
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    lists:concat(["/data/logs/",AgentName,"_", ServerName,"/chat.logs/",DateDirName,"/",ChannelSign,"/"]).

%%@doc 获取频道对应的文件名，每个频道目录目前最多用8个文件
get_channel_file(ChannelSign)->
    {_Date, {H, _I, _S}} = calendar:local_time(),
    FileName = H div 3,
    lists:concat( [get_channel_dir(ChannelSign),FileName,".log"] ).




