    %%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     将mnesia的P表中的数据立即更新到mysql中
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mt_fixmysql).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common_server.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

dump_all_tables() ->
	dump_tables(mysql_persistent_config:tables()).

%%@doc 获取跟mysql连接的进程，进程个数是PoolSize*2
get_mysql_process()->
    lists:filter(fun(P)-> 
                         case erlang:process_info(P, current_function) of
                             {current_function,{mysql_recv,loop,_}}->
                                 true;
                             {current_function,{mysql_conn,loop,_}}->
                                 true;
                             _ -> false
                         end
                 end, erlang:processes()).
    

%%@doc 杀掉本节点的mysql的连接池，目前mysql_dispatcher也会exit
kill_mysql_pool()->
    _ProcDispatcher = erlang:whereis(mysql_dispatcher),
    KillProcList = get_mysql_process(),
    [ begin
          case P2 of
              undefined-> not_exists;
              _ ->
                  erlang:exit(P2, killed)
          end
      end|| P2<- KillProcList ].

%%@doc 重新初始化本节点mysql的连接池
reset_mysql_pool(PoolSize)->
    KillResult = kill_mysql_pool(),
    %%先等待判断mysql_dispatcher是否死亡
    timer:sleep(3*1000),
    case erlang:whereis(mysql_dispatcher) of
        undefined->
            {StartAssistResult,CallResult} = start_mysql_via_assist_server(PoolSize),
            {via_assist_server,length(KillResult),KillResult,StartAssistResult,CallResult};
        _ ->
            StartResult = mod_mysql_assist_server:add_connection(PoolSize),
            {via_mysql_dispatcher_add_connection,length(KillResult),KillResult,StartResult}
    end.
    

start_mysql_via_assist_server(PoolSize)->
    case erlang:whereis(mod_mysql_assist_server) of
        undefined->
            StartAssistResult = mod_mysql_assist_server:start();
        _ ->
            StartAssistResult=ignore
    end,
    CallResult = mod_mysql_assist_server:start_mysql_pool(PoolSize),
    {StartAssistResult,CallResult}.
    



%% @spec dump_tables( TabList::list() ) 
%%      TabList -> [Tab],Tab-> atom()
%% @doc 将Mnesia的P表中的数据dump到MySQL数据库中，更新前先删除目标表
dump_tables(DbTable) when is_atom(DbTable)->
   dump_tables([DbTable]);
dump_tables(TabList)->
    ?INFO("TabList=~p~n",[TabList]),
    [ do_dump_table(Tab) || Tab<- TabList ],
    ok.

do_dump_table(DbTable,MysqlTab)->
	DumpTimeOut = 600*1000, %%10分钟
    ?INFO("deleting mysql table=~p~n",[DbTable]),
    SqlDelete = mod_mysql:get_esql_delete(DbTable, [] ),
    mod_mysql:update(SqlDelete,60*1000), %%1分钟
    
    ?INFO("dumping DbTable=~p~n",[DbTable]),
    Records = get_table_records(DbTable),
    case Records of
        []->
            ignore;
        _->
            RList = mysql_persistent_handler:dirty_write_batch(MysqlTab, Records,1000,DumpTimeOut),
            print_result(RList)
    end.

do_dump_table(DbTable)->
    DumpTimeOut = 600*1000, %%10分钟
    ?INFO("deleting mysql table=~p~n",[DbTable]),
    SqlDelete = mod_mysql:get_esql_delete(DbTable, [] ),
    mod_mysql:update(SqlDelete,60*1000), %%1分钟
    
    ?INFO("dumping DbTable=~p~n",[DbTable]),
    Records = get_table_records(DbTable),
    case Records of
        []->
            ignore;
        _->
            RList = mysql_persistent_handler:dirty_write_batch(DbTable, Records,1000,DumpTimeOut),
            print_result(RList)
    end.


print_result(RList) when is_list(RList)->
    {Effected2,NotEffected2} = lists:foldl(fun(E,{Effected,NotEffected})-> 
                                                   case E of
                                                       {ok,N} when is_integer(N)->
                                                           {Effected+N,NotEffected};
                                                       _ ->
                                                           {Effected,NotEffected+1}
                                                   end
                                           end,{0,0}, RList),
    ?INFO("effected =~p~n",[Effected2]),
    ?INFO("not effected =~p~n=============~n",[NotEffected2]);
print_result(Result) ->
    ?INFO("Result =~p~n==========~n",[Result]).


get_whole_table_match_pattern(SourceTable) ->
    A = mnesia:table_info(SourceTable, attributes),
    RecordName = mnesia:table_info(SourceTable, record_name),
    lists:foldl(
      fun(_, Acc) ->
              erlang:append_element(Acc, '_')
      end, {RecordName}, A).


%% @doc 获取指定的mnesia的P表的所用记录
get_table_records(SourceTable)->
    Pattern = get_whole_table_match_pattern(SourceTable),
    Res = mnesia:dirty_match_object(SourceTable, Pattern),
    Res.


