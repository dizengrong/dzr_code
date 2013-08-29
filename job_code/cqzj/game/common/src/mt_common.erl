%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mt_common  提供一些常用的维护脚本
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mt_common).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( PRINTME(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").
-include("common_server.hrl").
%%@doc 任务基础数据
-record(mission_base_info, {
    id,%% 任务ID
    name,%% 任务名
    type=0,%% 类型-1主-2支-3循
    model,%% 模型处理模块
    big_group=0,%% 大组
    small_group=0,%% 小组
    time_limit_type=0,%% 时间限制类型--0无限制--1每天--2每周--3每月
    time_limit=[],%% #mission_time_limit
    pre_mission_id=0, %%前置任务ID
    next_mission_list=[], %%后置任务ID列表
    pre_prop_list=[], %%前置任务道具列表 #pre_mission_prop{}
    gender=0,%% 性别
    faction=0,%国家
    team=0,%% 是否需要组队
    family=0,%% 需要家族
    min_level=0,%% 最低等级限制
    max_level=0,%% 最高等级限制
    vip_level=0,%% 最低VIP级别
    max_do_times=1,%% 最多可以做的次数
    listener_list=[],%% #mission_listener_data 侦听器数据
    max_model_status=0,%% 最大状态的模型值从0开始算
    model_status_data=[],%% #mission_status_data 状态数据
    reward_data%% #mission_reward_data 奖励数据
}).
-record(mission_reward_data, {
    rollback_times=1,%% 执行次数大于该值时奖励回滚为第一次奖励
    prop_reward_formula=1,%% 道具给与方式 1全部给与 2选择 3随机 4转盘
    attr_reward_formula=1,%% 属性给与公式 1普通 x...
    exp=0,%%经验奖励
    silver=0,%%钱币
    silver_bind=0,%%铜钱
    prop_reward,%%道具奖励#p_mission_prop
    tili = 0
}).

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%
  

%%@doc 产生任务列表
-define(FIST_ID_LIST,[4000,4001,4002]).
get_miss_list(Max,FactionID)->
    FirstID = lists:nth(FactionID, ?FIST_ID_LIST),
    Things = lists:map(fun({ID,Name,Model,Exp,Sivler})-> 
                           lists:concat([ID,",",Name,",",Model,",",Exp,",",Sivler,"-></br>\n"])
                       end, get_miss_list(FirstID,Max,FactionID)),
    
    Bytes = list_to_binary( lists:concat(Things) ),
    file:write_file(lists:concat(["/data/miss_list_",FactionID,".txt"]), Bytes).

get_miss_list(ID,Max,FactionID)->
    lists:reverse( get_miss_list(ID,Max,FactionID,25) ).

get_miss_list(ID,Max,FactionID,RoleLevel)->
    RoleLevelKey = common_tool:ceil(RoleLevel/10),
    Key = {RoleLevelKey, FactionID},
    FilterList = mod_mission_data:get_list_by_key(Key),
    get_post_miss_list_2(ID,[],FilterList,Max).

get_post_miss_list_2(ID,List,FilterList,Max) ->
    case length(List)>=Max of
        true->
            List;
        _ ->
            #mission_base_info{next_mission_list=NextList,name=Name,type=Type,model=Model,
                               reward_data=#mission_reward_data{exp=AddExp,silver_bind=SilverBind}} = mod_mission_data:get_base_info(ID),
            List2 = lists:filter(fun(E)->  lists:member(E, FilterList) end, NextList),
            case length(List2) < 2 of
                true->
                    [NextID|_] = List2;
                _ ->
                    [NextID|_] = lists:filter(
                                   %%只获取主线任务
                                   fun(E)-> 
                                       #mission_base_info{type=Type} = mod_mission_data:get_base_info(E),
                                       Type =:= 1
                                   end, List2)
            end,
            
            get_post_miss_list_2(NextID,[{ID,Name,Model,AddExp,SilverBind}|List],FilterList,Max)
    end.


write(Bytes) when is_binary(Bytes)->
    file:write_file("/data/test.txt", Bytes, [write]);
write(Content) ->
    Bytes = common_tool:to_binary(Content),
    file:write_file("/data/test.txt", Bytes, [write]).

%%@doc 将指定模块热更新到所有Node
load_nodes(CodeModule)->
    Args = [CodeModule],
    Nodes = [node()|nodes()],
    [ rpc:call(Nod, c, l, Args) ||Nod<-Nodes ].


%%@doc 将指定模块热更新到Map节点
load_maps(CodeModule)->
    Args = [CodeModule],
    
    Nodes = lists:filter(fun(Nd)-> 
                                 StrNode = common_tool:to_list(Nd),
                                 string:str(StrNode, "map") =:= 1 orelse
                                     string:str(StrNode, "mgeem") =:= 1
                         end, [node()|nodes()]), 
    [ rpc:call(Nod, c, l, Args) ||Nod<-Nodes ].

%%@doc 对所有的Node进行rpc:call 指定的MFA
call_nodes(Module,Method)->
    call_nodes(Module,Method,[]).

call_nodes(Module,Method,Args)->
    Nodes = [node()|nodes()],
    [ rpc:call(Nod, Module, Method, Args) ||Nod<-Nodes ].

%%@doc 对Map节点进行rpc:call 指定的MFA
call_maps(Module,Method)->
    call_maps(Module,Method,[]).

call_maps(Module,Method,Args)->
    Nodes = lists:filter(fun(Nd)-> 
                                 StrNode = common_tool:to_list(Nd),
                                 string:str(StrNode, "map") =:= 1 orelse
                                     string:str(StrNode, "mgeem") =:= 1
                         end, [node()|nodes()]), 
    [ rpc:call(Nod, Module, Method, Args) ||Nod<-Nodes ].

load_config(ConfigFileName) when is_atom(ConfigFileName)->
    call_nodes(common_config_dyn,reload,[ConfigFileName]).


complete_mission(RoleID,MissionID) ->
    mgeer_role:send(RoleID,{mod_mission_handler,{gm_complete_mission,RoleID,MissionID}}).


%%@spec sys_info/0
sys_info()->

    PortsCount   = length( erlang:ports() ),
    ProcCount    = erlang:system_info(process_count),  
    NodesList = [node()|nodes()],
    NodesCount  = length(NodesList),
    MemTotal     = ( erlang:memory(total) div 1024 div 1024 ),
    
    %% eg: acceptors:   10 ports:   20  memory: 5000    processes:  20 nodes: [xx,xx]
    Res = concat(["ports:\t",PortsCount,"\tmemory:\t",MemTotal,"MB\tprocesses:\t",ProcCount,"\tnodescount:\t",NodesCount]),
    ?PRINTME("~s~n",[Res]).

%%@spec msg_info/0
msg_info()->
    msg_info(0).
msg_info(AlertLen)->
    %%增加排序功能
    lists:foreach(fun(P)-> 
                          {_, PLen} = erlang:process_info(P, message_queue_len), 
                          if PLen > AlertLen -> 
                                 ?PRINTME("Process:~p RegName:~p MsgQueue:~p~n",[P, erlang:process_info(P,registered_name), PLen]); 
                             true -> ignore 
                          end 
                  end, erlang:processes()).

%%@spec mnesia_info/0
mnesia_info()->
    ok.

kill_mysql_pool()->
    Processes = erlang:processes(),
    P2List = lists:filter(fun(P)-> 
                                  case erlang:process_info(P, current_function) of
                                      {current_function,{mysql_recv,loop,_}}->
                                          true;
                                      {current_function,{mysql_conn,loop,_}}->
                                          true;
                                      _ -> false
                                  end
                          end, Processes),
    [ erlang:exit(P2, killed) || P2<-P2List ].


%%@spec fun_info/0
fun_info()->
    Processes = erlang:processes(),
    Header = io_lib:format( "Processes's length=~p~n",[ erlang:length( Processes ) ] ) ,
    
    Body = lists:foldl(fun(P,AccIn)->
                               case erlang:process_info(P,current_function) of
                                   undefined -> AccIn;
                                   [] -> AccIn;
                                   {current_function,{gen_server,loop,_}} ->
                                       case erlang:process_info(P,dictionary) of
                                           {dictionary,List} ->
                                               case lists:keyfind('$initial_call', 1, List) of
                                                   {'$initial_call',V}-> 
                                                       StrRes = io_lib:format("~p:gen_server:~p",[P,V]),
                                                       concat([AccIn,"\n",StrRes]);
                                                    _ ->  AccIn
                                               end;
                                           _ -> AccIn
                                       end;
                                   {current_function,{application_master,_,_}} -> AccIn;
                                   Res -> 
                                       StrRes = io_lib:format("~p:~p",[P,Res]),
                                       concat([AccIn,"\n",StrRes])
                               end
                       end ,Header, Processes),
    do_write_log(Body,"./fun_info.log"),
    ok.


%%@doc 获取地图的人数
get_map_online(MapIDList) when is_list(MapIDList)->
    [ get_map_online(MapID)||MapID<-MapIDList ];
get_map_online(MapID) when is_integer(MapID)->
    Pattern = #r_map_online{_='_',map_id=MapID},
    db:dirty_match_object(?DB_MAP_ONLINE,Pattern).

%%
%% Local Functions
%%

do_write_log(Body,Filename)->
    Bytes = common_tool:to_binary(Body),
    file:write_file(Filename, Bytes,[write]).

concat(Things)->
    lists:concat(Things).






