%% Author: ldk
%% Created: 2012-6-4
%% Description: TODO: Add description to common_crown_arena
-module(common_crown_arena).

%%
%% Include files
%%
-include("common.hrl").
-include("crown_arena.hrl").

%%
%% Exported Functions
%%
-export([pk_map_process_name/1,
		 cull_pk_map_process_name/1,
		 quit_pk_map_change_pos/1,
		 get_wait_map_born_points/1,
		 pk_map_id/0,
		 cull_pk_map_id/0,
		 wait_map_process_name/0,
		 reward_peck_ext/3,
		 kick_wait_map_roles/0,
		 wait_map_id/0,
		 set_cd_time/2,
		 set_pk_state/1,
		 get_pk_state/0,
		 get_cd_time/1]).

%%
%% API Functions
%%
%%多少连胜
-define(LINK_WIN_5, 5).
-define(LINK_WIN_10, 10).
-define(LINK_WIN_30, 30).

set_pk_state(State) ->
	put({?MODULE,pk_state},State).
get_pk_state() ->
	case get({?MODULE,pk_state}) of
		undefined ->
			?PK_SAFE_TIME;
		State ->
			State
	end.


set_cd_time(RoleID,Time) ->
	put({?MODULE,cd_time,RoleID},Time).
get_cd_time(RoleID) ->
	case get({?MODULE,cd_time,RoleID}) of
		undefined ->
			common_tool:now() - ?AWARD_CD_TIME;
		Time ->
			Time
	end.


%% 战神坛PK地图进程名
pk_map_process_name(Num) ->
	lists:concat(["mgee_crown_arena_pk_map_",Num]).

%% 战神坛淘汰赛PK地图进程名
cull_pk_map_process_name(Num) ->
	lists:concat(["mgee_crown_cull_pk_map_",Num]).

pk_map_id() ->
	[MapId] = common_config_dyn:find(crown_arena, pk_map_id),
	MapId.
cull_pk_map_id() ->
	[MapId] = common_config_dyn:find(crown_arena_cull, cull_pk_map_id),
	MapId.

wait_map_id() ->
	[MapId] = common_config_dyn:find(crown_arena, wait_map_id),
	MapId.

wait_map_process_name() ->
	[MapId] = common_config_dyn:find(crown_arena, wait_map_id),
	common_map:get_common_map_name( MapId ).

kick_wait_map_roles() ->
	MapId = common_crown_arena:wait_map_id(),
	case global:whereis_name( common_map:get_common_map_name( MapId ) ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,mod_crown_arena_fb,{kick_wait_map_roles,[]}})
    end.
quit_pk_map_change_pos(RoleID)->
	case mod_map_actor:get_actor_mapinfo(RoleID,role) of
		#p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
			{TX,TY} = get_wait_map_born_points(RoleID),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE, RoleID, wait_map_id(), TX, TY);
		#p_map_role{max_hp=MaxHp,max_mp=MaxMp,role_id = RoleID} ->
 			mod_map_role:do_role_add_hp(RoleID, MaxHp, RoleID),
            mod_map_role:do_role_add_mp(RoleID, MaxMp, RoleID),
			{TX,TY} = get_wait_map_born_points(RoleID),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, wait_map_id(), TX, TY);
		_ ->
			ignore
	end.

get_wait_map_born_points(_RoleID) ->
	[FbBornPoints] = common_config_dyn:find(crown_arena,wait_map_born_points),
	common_tool:random_element(FbBornPoints).

reward_peck_ext(_RoleID,Level,MaxLinkWin) when MaxLinkWin >= ?LINK_WIN_30 ->
	[PeckAward30] = common_config_dyn:find(crown_arena, peck_award_30),
	{_,#r_crown_award{type=Type,typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime,num=Num}} = lists:keyfind(Level, 1, PeckAward30),
	#r_goods_create_info{bind=Bind,type=Type, start_time=StartTime,end_time=EndTime,type_id=TypeID,num=Num};
reward_peck_ext(_RoleID,Level,MaxLinkWin) when MaxLinkWin < ?LINK_WIN_30 andalso MaxLinkWin >= ?LINK_WIN_10 ->
	[PeckAward10] = common_config_dyn:find(crown_arena, peck_award_10),
	{_,#r_crown_award{type=Type,typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime,num=Num}} = lists:keyfind(Level, 1, PeckAward10),
	#r_goods_create_info{bind=Bind,type=Type, start_time=StartTime,end_time=EndTime,type_id=TypeID,num=Num};
reward_peck_ext(_RoleID,Level,MaxLinkWin) when MaxLinkWin < ?LINK_WIN_10 andalso MaxLinkWin >= ?LINK_WIN_5 ->
	[PeckAward5] = common_config_dyn:find(crown_arena, peck_award_5),
	{_,#r_crown_award{type=Type,typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime,num=Num}} = lists:keyfind(Level, 1, PeckAward5),
	#r_goods_create_info{bind=Bind,type=Type, start_time=StartTime,end_time=EndTime,type_id=TypeID,num=Num};
reward_peck_ext(_RoleID,_Jingjie,_MaxLinkWin) ->
	[].


%%
%% Local Functions
%%

