%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     活动-世界BOSS的处理
%%% @end
%%% Created : 2010-12-17
%%%-------------------------------------------------------------------
-module(mod_activity_boss).

-include("mgeem.hrl").
-include("dynamic_monster.hrl").
-include("activity.hrl").

%% API
-export([
         handle/1,
         handle/2
        ]).


-export([
         init/1,
         hook_map_loop/2,
		 hook_monster_dead/1
        ]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(activity_boss_attention,activity_boss_attention).


%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

hook_monster_dead({KillerID,MonsterTypeId, MonsterName,MonsterLevel}) ->
	do_monster_dead_broadcast(KillerID,MonsterTypeId, MonsterName,MonsterLevel).

do_monster_dead_broadcast(KillerID,MonsterTypeId, MonsterName,MonsterLevel) ->
	[MapList] = common_config_dyn:find(dynamic_monster,boss_group_mapid_list),
	MapID = mgeem_map:get_mapid(),
	case lists:member(MapID, MapList) of
		true ->
			case common_config_dyn:find(dynamic_monster, boss_list) of
				[BossList] ->
					case lists:member(MonsterTypeId, BossList) of
						true ->
							{ok,#p_role_base{role_name=KillerName}} = mod_map_role:get_role_base(KillerID),
							Msg = common_misc:format_lang(?_LANG_ACTIVITY_BOSS_DEAD_BROADCAST_MSG, 
														  [KillerName,common_tool:to_list(MonsterName),common_tool:to_list(MonsterLevel)]),
							common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,Msg),
							common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,Msg);
						_ ->
							ignore
					end;
				_ ->
					ignore
			end;
		_ ->
			ignore
	end.

hook_map_loop(?DEFAULT_MAPID,Now)->
    List = get_boss_group_list(),
    [ hook_map_loop_2(BossGroup,Now)||BossGroup<-List ];
hook_map_loop(_MapID,_Now)->
    ignore.

hook_map_loop_2(BossGroup,Now)->
    #r_boss_group_info{id=ID,start_time=StartTime,end_time=EndTime} = BossGroup,
    if
        Now=:=StartTime->
            common_map:dynamic_create_monster(boss_group, ID);
        Now=:=EndTime->
            common_map:dynamic_delete_monster(boss_group,ID),
            reset_boss_group(ID);
        true->
            ignore
    end.

init(?DEFAULT_MAPID)->
    case common_config_dyn:find(boss_group, boss_group) of
        []->
            ignore;
        [BossGroupConfList]->
            BossGrpList = [ init_boss_group(E)||E<-BossGroupConfList ],
            set_boss_group_list(BossGrpList)
    end;
init(_)->
    ignore.

%%根据配置初始化每个世界BOSS
%%@return #r_boss_group_info{}
init_boss_group(#r_boss_group_conf{type=Type}=BossGroupConf) when Type=:=daily->
    %%每天都出生的怪物
    #r_boss_group_conf{id=ID,time_params=TimeParams} = BossGroupConf,
    Today = date(),
    TimeSecsList = [ {common_tool:datetime_to_seconds({Today,StartTimeParam}),
                      common_tool:datetime_to_seconds({Today,EndTimeParam})}
                     ||{StartTimeParam,EndTimeParam}<-TimeParams ],
    Now = common_tool:now(),
    [CountryList] = common_config_dyn:find(dynamic_monster,{boss_group,ID}),
    BornMapList = [ {CountryID,common_misc:get_born_info_by_map(MapID)}||{CountryID,[{MapID,_BornNum,_MonsterList,_}|_T]}<-CountryList],
    case get_next_match_time(Now,TimeSecsList) of
        {ok,{StartTime,EndTime}}->
            NextDate = Today;
        _ ->
            [{StartTimeParam,EndTimeParam}|_T] = TimeParams,
            {NextDate,_} = common_tool:seconds_to_datetime(Now+3600*24), %% tomorrow
            StartTime = common_tool:datetime_to_seconds({NextDate,StartTimeParam}),
            EndTime = common_tool:datetime_to_seconds({NextDate,EndTimeParam})
    end,
    #r_boss_group_info{id=ID,date=NextDate,start_time=StartTime,end_time=EndTime,born_map_list=BornMapList}.

get_next_match_time(_Now,[])->
    {error,not_match_time};  %%全部过期
get_next_match_time(Now,[H|T])->
    {StartTimeSec,EndTimeSec} = H,
    if
        Now>=StartTimeSec andalso EndTimeSec>Now-> %%进行中
            {ok,H};
        StartTimeSec>Now->  %%今天的下一个开始时间
            {ok,H};
        true->
            get_next_match_time(Now,T)
    end.

%%怪物死亡后重新设置该BOSS的信息
reset_boss_group(ID) when is_integer(ID)->
    case common_config_dyn:find(boss_group, boss_group) of
        []->
            ignore;
        [BossGroupConfList]->
            List = get_boss_group_list(),
            case lists:keyfind(ID, #r_boss_group_conf.id, BossGroupConfList) of
                false->
                    BossGrpList2 = lists:keydelete(ID, #r_boss_group_info.id, List);
                BossGroupConf ->
                    NewBossGrp = init_boss_group(BossGroupConf),
                    BossGrpList2 = lists:keystore(ID, #r_boss_group_info.id, List, NewBossGrp)
            end,
            set_boss_group_list(BossGrpList2)
    end.


handle({Unique, Module, ?ACTIVITY_BOSS_GROUP, DataIn, RoleID, PID, Line}) ->
    do_boss_group(Unique,Module,?ACTIVITY_BOSS_GROUP,DataIn,RoleID,PID,Line);
handle({handle,FactionID,MapPID,Request})->
    do_handle_boss_group(FactionID,MapPID,Request);
handle({activity_boss_attention_notice,BossID})->
    do_activity_boss_attention_notice(BossID);
handle({reset_boss_group})->
    init(?DEFAULT_MAPID);
handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


%% boss群请求,现在玩家所在进程获取国家信息，然后路由到监狱
do_boss_group(Unique,Module,Method,DataIn,RoleID,PID,Line)->
    {ok,#p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
    MapProcessName = common_misc:get_map_name(?DEFAULT_MAPID),
    case global:whereis_name(MapProcessName) of
        undefined->
            R2 = #m_activity_boss_group_toc{succ=false, reason=?_LANG_BOSS_GROUP_BUSY},
            ?UNICAST_TOC(R2);
        MapPID->
            MapPID ! {mod,?MODULE,{handle,FactionID,self(),{Unique, Module, Method, DataIn, RoleID, PID, Line}}}
    end.


%% 监狱处理消息
do_handle_boss_group(FactionID,MapPID,{Unique,Module,Method,DataIn,RoleID,PID,Line})->
    TodayBossList = get_today_boss_group_list(),
    case DataIn#m_activity_boss_group_tos.op_type of
        ?BOSS_GROUP_GET_LIST->
            do_boss_group_get_list({Unique,Module,Method,DataIn,RoleID,PID,Line},TodayBossList,FactionID);
        ?BOSS_GROUP_GET_DETAIL->
            do_boss_group_get_detail({Unique,Module,Method,DataIn,RoleID,PID,Line},TodayBossList,FactionID);
        ?BOSS_GROUP_TRANSFER->
            do_boss_group_transfer({Unique,Module,Method,DataIn,RoleID,PID,Line},MapPID,TodayBossList,FactionID);
        ?BOSS_GROUP_ATTENTION->
            do_boss_group_attention({Unique,Module,Method,DataIn,RoleID,PID,Line},MapPID,TodayBossList);
        ?BOSS_GROUP_DELETE_ATTENTION->
            do_boss_group_attention({Unique,Module,Method,DataIn,RoleID,PID,Line},MapPID,TodayBossList)
    end.


get_role_attention_boss_list(RoleID,ViewList) when is_integer(RoleID)->
    lists:foldl(
      fun(#r_boss_group_info{id=ID},AccIn)-> 
              case get_activity_boss_attention(ID) of
                  undefined ->
                      AccIn;
                  RoleIDList ->
                      case lists:member(RoleID, RoleIDList) of
                          true ->
                              [ID|AccIn];
                          false ->
                              AccIn
                      end
              end
      end, [], ViewList). 


%% 获取列表
do_boss_group_get_list({Unique,Module,Method,DataIn,RoleID,PID,_Line},ViewList,FactionID)->
    #m_activity_boss_group_tos{op_type=OpType} = DataIn,
    AttentionBoss = get_role_attention_boss_list(RoleID,ViewList),
    BossGroupList = [begin
                         {MapID,TX,TY} = get_map_born_info(FactionID,BornMapList),
                         #p_boss_group{boss_id=BossID,
                                       start_time=StartTime,
                                       end_time = EndTime,
                                       map_id=MapID,
                                       tx=TX,
                                       ty=TY}
                     end
                     ||#r_boss_group_info{id=BossID,start_time=StartTime,end_time=EndTime,born_map_list=BornMapList}<-ViewList ],
	R2 = #m_activity_boss_group_toc{op_type= OpType,
                                    boss_group_list = BossGroupList,
                                    attention_boss = AttentionBoss
                                   },
    ?UNICAST_TOC(R2).


%% 获取boss详情
do_boss_group_get_detail({Unique,Module,Method,DataIn,_RoleID,PID,_Line},ViewList,FactionID)->
    #m_activity_boss_group_tos{boss_id=BossID,op_type=OpType} = DataIn, 
    case lists:keyfind(BossID, #r_boss_group_info.id, ViewList) of
        false->
            R2 = #m_activity_boss_group_toc{op_type=OpType,
                                            boss_id=BossID,
                                            succ=false,
                                            reason=?_LANG_BOSS_GROUP_CLOSE};
        #r_boss_group_info{id=BossID,born_map_list=BornMapList}->
            {MapID,TX,TY} =get_map_born_info(FactionID,BornMapList),
            R2 = #m_activity_boss_group_toc{op_type=OpType,
                                            boss_id=BossID,
                                            map_id=MapID,
                                            tx=TX,
                                            ty=TY}
    end,
    ?UNICAST_TOC(R2).

%% 传送
do_boss_group_transfer({Unique,Module,Method,DataIn,RoleID,PID,Line},_MapPID,ViewList,FactionID)->
    #m_activity_boss_group_tos{boss_id=BossID,op_type=OpType} = DataIn, 
    case lists:keyfind(BossID, #r_boss_group_info.id, ViewList) of
        false->
            R2= #m_activity_boss_group_toc{op_type=OpType,
                                           boss_id=BossID,
                                           succ=false,
                                           reason=?_LANG_BOSS_GROUP_CLOSE},
            ?UNICAST_TOC(R2);
        #r_boss_group_info{id=BossID,born_map_list=BornMapList}->
            {DestMapID,TX,TY} =get_map_born_info(FactionID,BornMapList),
            DestDataIn=#m_map_transfer_tos{mapid=DestMapID, tx=TX, ty=TY, change_type=0},
			mgeer_role:absend(RoleID,{Unique, ?MAP, ?MAP_TRANSFER, DestDataIn, RoleID, PID, Line})
    end.

%% 关注/取消关注
do_boss_group_attention({Unique,Module,Method,DataIn,RoleID,PID,_Line},_MapPID,ViewList)->
    #m_activity_boss_group_tos{boss_id=BossID,op_type=OpType} = DataIn, 
    case lists:keyfind(BossID, #r_boss_group_info.id, ViewList) of
        false->
            ignore;
        #r_boss_group_info{id=BossID}->
            case OpType of
                ?BOSS_GROUP_ATTENTION ->
                    set_activity_boss_attention(RoleID,BossID);
                ?BOSS_GROUP_DELETE_ATTENTION ->
                    del_activity_boss_attention(RoleID,BossID)
            end,
            R2=#m_activity_boss_group_toc{op_type=OpType,boss_id=BossID},
            ?UNICAST_TOC(R2)
    end.


%% 活动Boss关注 
do_activity_boss_attention_notice(BossID) ->
    case get_activity_boss_attention(BossID) of
        undefined ->
            ingore;
        RoleIDList ->
            DataRecord = #m_activity_boss_group_toc{op_type=?BOSS_GROUP_ATTENTION_NOTICE,boss_id=BossID},
			lists:foreach(fun(RoleID) ->
								  common_misc:unicast2_direct({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_BOSS_GROUP, DataRecord)
								  end, RoleIDList)
    end.

get_activity_boss_attention(BossID) ->
    erlang:get({?activity_boss_attention,BossID}).

set_activity_boss_attention(RoleID,BossID) ->
    case get_activity_boss_attention(BossID) of
        undefined ->
            erlang:put({?activity_boss_attention,BossID},[RoleID]);
        AttentionList ->
            erlang:put({?activity_boss_attention,BossID},[RoleID|lists:delete(RoleID,AttentionList)])
    end.

del_activity_boss_attention(RoleID,BossID) ->
    case get_activity_boss_attention(BossID) of
        undefined ->
            ignore;
        AttentionList ->
            erlang:put({?activity_boss_attention,BossID},lists:delete(RoleID,AttentionList))
    end.


%%怪物的出生位置
get_map_born_info(_FactionID,[{0,{Map,TX,TY}}])->
    {Map,TX,TY};
get_map_born_info(_FactionID,[{Map,TX,TY}])->
    {Map,TX,TY};
get_map_born_info(FactionID,BornMapList) when is_list(BornMapList)->
    case lists:keyfind(FactionID, 1, BornMapList) of
        false->
            {0,0,0};
        {FactionID,{Map,TX,TY}}->{Map,TX,TY}
    end;
get_map_born_info(_,_)->
    {0,0,0}.


set_boss_group_list(List)->
    erlang:put(?BOSS_GROUP_LIST,List).

get_boss_group_list()->
    case erlang:get(?BOSS_GROUP_LIST) of
        undefined->
            [];
        L->L
    end.

%%获取今日可见的世界BOSS的列表（即每种怪物的最近出现时间）
get_today_boss_group_list()->
    List = get_boss_group_list(),
    Today = date(),
    [ R ||#r_boss_group_info{date=Date}=R<-List, Date=:=Today ].

