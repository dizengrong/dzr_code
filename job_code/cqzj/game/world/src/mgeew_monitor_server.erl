%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mgeew_monitor_server 性能监控服务器
%%% @end
%%% Created : 2010-12-15
%%%-------------------------------------------------------------------
-module(mgeew_monitor_server).
-behaviour(gen_server).
-record(state,{}).


-export([start_link/0]).
-export([send_monitor/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(ETS_MONITOR_DATA,ets_monitor_data).
%%定时发消息进行持久化
-define(DUMP_INTERVAL, 60 * 1000).
-define(DUMP_VERSION_INTERVAL,60*60*1000).
-define(MSG_DUMP_LOG, dump_monitor_data).
-define(LOG_QUEUE, log_queue).


-define(CURRENT_VERSION_INFO,current_version_info).
-define(DUMP_VERSION_DATA, dump_version_data).
-define(VERSION_INFO_DIR,common_config:get_server_dir()++"version_server.txt").
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").


%% ====================================================================
%% API functions
%% ====================================================================

send_monitor(MonitorRec)->
    case global:whereis_name(?MODULE) of
        undefined-> ignore;
        PID ->
            erlang:send(PID, {monitor_data,MonitorRec})
    end.


%% ====================================================================
%% External functions
%% ====================================================================

start_link()  ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) -> 
    ets:new(?ETS_MONITOR_DATA, [named_table, set, protected]),
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG),
    
    erlang:send_after(?DUMP_VERSION_INTERVAL, self(), ?DUMP_VERSION_DATA),
    State = #state{},
    {ok, State}.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% MonitorRec = {Unique,Node,Type,TimeStamp,DataList}
do_handle_info({monitor_data,MonitorRec})->
    ets:insert(?ETS_MONITOR_DATA, MonitorRec);

do_handle_info(?MSG_DUMP_LOG)->
    do_dump_monitor_data(),
    
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);

do_handle_info(?DUMP_VERSION_DATA)->
    catch do_dump_version_data(),
    erlang:send_after(?DUMP_INTERVAL, self(), ?DUMP_VERSION_DATA);

do_handle_info({load_config,ConfigList})->
    if
        is_atom(ConfigList)->
            do_load_config(ConfigList);
        is_list(ConfigList)->
            lists:foreach(fun(E)->
                              do_load_config(E)
                          end, ConfigList);
        true->
            error
    end;

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

do_load_config(ConfigName)->
    Nodes = [node()|nodes()],
    [ rpc:call(Nod, common_config_dyn, reload, [ConfigName]) ||Nod<-Nodes ].

do_dump_monitor_data()->
    %% 将ets数据dump到文件或DB中，
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    MonitorLogDir = lists:concat(["/data/logs/",AgentName, "_" ,ServerName, "/monitor/"]),
    case create_log_dir(MonitorLogDir) of
        ok->
            LogFileName = get_log_file_name(MonitorLogDir),
            
            LogList = ets:tab2list(?ETS_MONITOR_DATA),
            Now = common_tool:time_format(erlang:now()),
            lists:foreach(fun(Log)->
                                  {{Node,Type},TimeStamp,DataList} = Log,
                                  case Type of
                                      monitor_map_msg ->
                                          %%dump to mysql
                                          ValList = [[ TimeStamp,MapName,Node,OnlineNum,MLen ] ||{_PID,MapName,OnlineNum,MLen}<-DataList],
                                          update_queue(?LOG_QUEUE,ValList);
                                      _ -> 
                                          %%dump to file
                                          Format = "~s:{~w,~w},~w\n",
                                          Result =  common_tool:to_binary( io_lib:format( Format,[Now,Node,Type,DataList]) ),
                                          case file:write_file(LogFileName, Result, [append]) of
                                              ok -> ok;
                                              {error,Reason} ->
                                                  ?WARNING_MSG("write the log data for the mcs monitor is fail, ~p\n",[Reason]),
                                                  ignore
                                          end
                                  end
                          
                          end, LogList),
            file:write_file(LogFileName, <<"=====================\n">>, [append]);
        {error,Reason}->
            ?ERROR_MSG("create_log_dir failed!Path=~w,Reason=~w",[MonitorLogDir,Reason])
    end,
    do_dump_to_mysql(),
    ets:delete_all_objects(?ETS_MONITOR_DATA),
    ok.

do_dump_version_data()->
    {ok, Version} =file:read_file(?VERSION_INFO_DIR),
    case check_version(Version) of
        same->
            ignore;
        diff->
            put(?CURRENT_VERSION_INFO,Version),
            do_dump_version_to_mysql()
    end.


%%@doc 将数据更新到log的队列
update_queue(TheKey,ValList)->
    case get(TheKey) of
        undefined ->
            put(TheKey, ValList);
        Queues ->
            put( TheKey,lists:concat([ValList,Queues]) )
    end.

do_dump_to_mysql()->
    case get(?LOG_QUEUE) of
        undefined->ignore;
        []->ignore;
        Queues->
            do_dump_to_mysql(Queues)
    end.

do_dump_to_mysql(Queues)->
    try
        %%批量插入的数据，目前最大不能超过3M
        FieldNames = [ mtime,map_name,node,online_num,msg_len ],
        
        QueuesInsert = lists:reverse(Queues),
        mod_mysql:batch_insert(t_monitor_map_msg,FieldNames,QueuesInsert,3000),
        
        %%插入成功之后，再修改进程字典
        put(?LOG_QUEUE,[])
    catch
        _:Reason->
            ?ERROR_MSG("插入性能监控数据出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.


%% @spec create_log_dir(LogDir)-> ok | {error, Reason}
create_log_dir(LogDir)->
    case filelib:is_dir(LogDir) of
        false ->
            file:make_dir(LogDir);
        true -> 
            ok
    end.

%% @spec get_log_file_name(LogDir,LogMode,Suffix)-> string()
get_log_file_name(LogDir)->
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    FileName = common_tool:date_format(),
    lists:concat([LogDir, "/cqzj_",AgentName,"_",ServerName,"_", FileName, ".log"]).

check_version(Version)->
    case get(?CURRENT_VERSION_INFO) of
        undefined->
            diff;
        OldVersion->
        case Version=:=OldVersion of
            true->same;
            false->diff
        end
    end.    

do_dump_version_to_mysql()->
    case get(?CURRENT_VERSION_INFO) of
        undefined->ignore;
        []->ignore;
        Version ->
            do_dump_version_to_mysql(Version)
    end.
    
do_dump_version_to_mysql(Version)->
    try
        %%批量插入的数据，目前最大不能超过3M
        SQL= mod_mysql:get_esql_insert(t_log_version,
                                   [version,log_time],
                                   [Version,common_tool:now()]
                                  ),
        {ok,_} = mod_mysql:insert(SQL)
        
        %%插入成功之后，再修改进程字典
    catch
        _:Reason->
            ?ERROR_MSG("插入性能监控数据出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

