%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  2 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_map).
-include("common.hrl").
-include("common_server.hrl").

%% API
-export([
         get_warofcity_map_name/1,
         get_common_map_name/2,
         get_common_map_name/1,
         get_common_map_slave_name/2,
         get_map_str_name/1,
         get_family_map_name/1,
         get_faction_id_by_map_id/1,
         get_cangbaotu_map_name/2,
         exit/1,exit/2
        ]).

-export([
         get_online_num/0,
         get_map_return_pos_of_jingcheng/1,
         info/2,
         is_doing_ybc/1,
         dynamic_create_monster/2,
         dynamic_delete_monster/2,
         send_to_all_map/1,
         family_info/2,
         get_map_family_id/0,
         set_map_family_id/2
        ]).

-export([
         reset_boss_group/0,
         %%英雄副本排行
         hero_fb_ranking/1]).

-define(dict_event_timer_cd, dict_event_timer_cd).%%控制检查间隔时间
-define(event_timer_cd_time, 5).%%累计被loop5次就计算

exit(Reason)->
    erlang:exit(self(),Reason).
exit(PID,Reason)->
    erlang:exit(PID,Reason).

%%@doc 地图中获取所有在线人数
get_online_num()->
    length(db:dirty_match_object(?DB_USER_ONLINE, #r_role_online{_='_'})).

info(PName, Info) when erlang:is_list(PName) orelse erlang:is_atom(PName) ->
    case global:whereis_name(PName) of
        undefined ->
            ignore;
        PID ->
            PID ! Info
    end.

family_info(FamilyID, Info) ->
    case global:whereis_name(get_family_map_name(FamilyID)) of
        undefined ->
            ignore;
        PID ->
            PID ! {mod_map_family, Info}
    end.

get_family_map_name(FamilyID) when is_integer(FamilyID) ->
    lists:concat(["map_family_", FamilyID]).

%% 拼凑地图争夺战地图进程的名字
get_warofcity_map_name(MapID) when is_integer(MapID) ->
    lists:concat(["map_warofcity_", MapID]).

get_common_map_name(RoleID, MapID) when MapID >= 105001 andalso MapID =< 105081 ->
    mod_tower_fb:get_role_tower_fb_map_name(RoleID, MapID - 105001 + 1);

get_common_map_name(_RoleID, MapID) when is_integer(MapID) ->
    lists:concat([mgee_map_, MapID]).

get_common_map_name(MapID) when is_integer(MapID) ->
    lists:concat([mgee_map_, MapID]).

get_common_map_slave_name(MapID,0) ->
    lists:concat([mgee_map_, MapID]);
get_common_map_slave_name(MapID,SlaveIndex) when is_integer(MapID) ->
    lists:concat([mgee_map_slave_, MapID,"_",SlaveIndex]).
%% 获取藏宝图副本地图进程名
get_cangbaotu_map_name(RoleID,Now) ->
    lists:concat(["mgee_cangbaotu_fb_map_",RoleID,"_",Now]).

%%@doc 获取地图的中文名称，例如 11000->"蚩尤-太平村"
get_map_str_name(MapID) when is_integer(MapID) ->
    [MapNameStr] = common_config_dyn:find(map_info,MapID),
    MapNameStr.

is_doing_ybc(RoleID) ->
    [RoleState] = db:dirty_read(?DB_ROLE_STATE, RoleID),
    RoleYbcState = RoleState#r_role_state.ybc,
    if
        RoleYbcState =:= 3 ->
            true;
        RoleYbcState =:= 2 ->
            true;
        RoleYbcState =:= 1 ->
            true; 
        true ->
            false
    end.
	

dynamic_create_monster(notice, Key) ->
    [Msg] = common_config_dyn:find(dynamic_monster, {notice, Key}),
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
dynamic_create_monster(monster, Key) ->
    [MonsterList] = common_config_dyn:find(dynamic_monster, {monster, Key}),
    lists:foreach(
      fun({MapID, TMonsterList}) ->
              MapProcessName = common_misc:get_map_name(MapID),
              catch global:send(MapProcessName, {mod_map_monster, {dynamic_create_monster2, TMonsterList}})
      end, MonsterList);
dynamic_create_monster(boss_group,Key) when is_integer(Key)->
    [CountryList] = common_config_dyn:find(dynamic_monster,{boss_group,Key}),
    CountryMapIDList = 
        lists:foldl(
          fun({CountryID,MapList},TmpMapIDList)->
                  {MapID,BornNum,MonsterList,_}=lists:nth(mod_refining:get_random_number([Weight||{_MapID,_BornNum,_MonsterList,Weight}<-MapList],0,1), MapList),
                  {ok,NewMonsterList} = random_monster_list(BornNum,MonsterList,[]),
                  MapProcessName = common_misc:get_map_name(MapID),
                  ?TRY_CATCH(global:send(MapProcessName, {mod_map_monster, {dynamic_create_boss_group, NewMonsterList,Key}}),Err),
                  [{CountryID,common_misc:get_born_info_by_map(MapID)}|TmpMapIDList]
          end,[],CountryList),
    [{_NoticeType,Notice}] = common_config_dyn:find(dynamic_monster,{notice_boss_group,Key}),
			lists:foreach(
      fun({CountryID,{MapID,TX,TY}})->
              [MapName] = common_config_dyn:find(map_info,MapID),
              MapIDStr = common_tool:to_list(MapID),
              SplitStr =
                  case Key =:= 5 orelse Key =:= 6 of
                      true -> "0";
                      false -> "#"
                  end,
              NewMapIDStr = lists:concat([string:substr(MapIDStr,1,1),SplitStr,string:substr(MapIDStr,3)]),
              NoticeMsg = common_misc:format_lang(Notice, [lists:concat(["<a href=\"event:gotopt|",NewMapIDStr,
                                                                         "-",TX,"-",TY,"\"><u><FONT COLOR='#3DEA42'>",MapName,
                                                                         "</FONT></u></a>"])]),
              common_broadcast:bc_send_msg_faction(CountryID,
                                                   [?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],
                                                   ?BC_MSG_TYPE_CHAT_COUNTRY,
                                                   NoticeMsg,[])
      end, CountryMapIDList),
    
    activity_boss_attention_notice(Key);

dynamic_create_monster(MapIDList, CreateDataList) ->
    lists:foreach(fun(MapID) ->
        MapProcessName = common_misc:get_map_name(MapID),
        lists:foreach(fun(CreateData) ->
            catch global:send(MapProcessName, {mod_map_monster, {dynamic_create_monster, CreateData}})
        end, CreateDataList)
    end, MapIDList).

dynamic_delete_monster(boss_group,Key) when is_integer(Key)->
    [CountryList] = common_config_dyn:find(dynamic_monster,{boss_group,Key}),
    lists:foreach(
      fun({_CountryID,MapList})->
        lists:foreach(fun({MapID,_,_,_})->
                              MapProcessName = common_misc:get_map_name(MapID),
                              catch global:send(MapProcessName, {mod_map_monster, {dynamic_delete_boss_group, Key}})
                      end,MapList)  
      end,CountryList);
dynamic_delete_monster(MapIDList, MonsterIDList) ->
	lists:foreach(fun(MapID) ->
        MapProcessName = common_misc:get_map_name(MapID),
        lists:foreach(fun(MonsterID) ->
            catch global:send(MapProcessName, {mod_map_monster, {dynamic_delete_monster, MonsterID}})
        end, MonsterIDList)
    end, MapIDList).

%% 重新出生世界BOSS
reset_boss_group()->
     MapProcessName = common_misc:get_map_name(?DEFAULT_MAPID),
     catch global:send(MapProcessName, {mod,mod_activity_boss,{reset_boss_group}}).

hero_fb_ranking(Info)->
     MapProcessName = common_misc:get_map_name(?DEFAULT_MAPID),
     catch global:send(MapProcessName, {mod_hero_fb,{hero_fb_ranking,Info}}).

%% @doc 发消息到所有地图
send_to_all_map(Info) ->
    MapNameList = 
        case catch db:dirty_match_object(?DB_MAP_ONLINE, #r_map_online{_='_'}) of
            {'EXIT', _} -> [];
            []-> [];
            RecList ->
                [R#r_map_online.map_name || R <-RecList]
        end,
    lists:foreach(
      fun(MapProcessName) ->
              case global:whereis_name(MapProcessName) of
                  undefined ->
                      ignore;
                  PID ->
                      PID ! Info
              end
      end,MapNameList).

%%获取宗族地图对应的宗族ID
get_map_family_id() ->
     get(family_map_family_id).


%%设置宗族地图的宗族ID
set_map_family_id(MapName,10300) ->
    [FamilyIDStr] = string:tokens(MapName, "map_family_"),
    {FamilyID,_} = string:to_integer(FamilyIDStr),
    put(family_map_family_id,{FamilyID,MapName});
set_map_family_id(_MapName,_) ->
    ok.

get_faction_id_by_map_id(MapId) ->
    {ok, MapId rem 10000 div 1000}.

random_monster_list(_BornNum,[],NewMonsterList)->
    {ok,NewMonsterList};
random_monster_list(BornNum,MonsterList,NewMonsterList)->
    case BornNum>0 of
        true->
            Num = common_tool:random(1, erlang:length(MonsterList)),
            MonsterInfo = lists:nth(Num, MonsterList),
            random_monster_list(BornNum-1,lists:delete(MonsterInfo, MonsterList),[MonsterInfo|NewMonsterList]);
        false->
            {ok,NewMonsterList}
    end.

get_map_return_pos_of_jingcheng(RoleID)->
    {ok,#p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
    MapID = common_misc:get_jingcheng_mapid(FactionId),
	[{TX, TY}] = mcm:born_tiles(MapID),
    {MapID,TX,TY}.

%% 活动boss关注通知
activity_boss_attention_notice(BossID) ->
	MapProcessName = common_misc:get_map_name(?DEFAULT_MAPID),
	case global:whereis_name(MapProcessName) of
		undefined->
			ignore;
		MapPID->
			MapPID ! {mod,mod_activity_boss,{activity_boss_attention_notice,BossID}}
	end.
