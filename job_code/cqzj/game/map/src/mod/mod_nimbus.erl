%% Author: ldk
%% Created: 2012-7-30
%% Description: 灵气值模块
-module(mod_nimbus).

%%
%% Include files
%%
-include("mgeem.hrl"). 

-record(r_nimbus_config, {id,tx, ty,range,num}).

%%
%% Exported Functions
%%
-export([
			check_in_fb/0,
			hook_change_level/1,
			nimbus_up/2,
			pool_add_mp/4,
			handle/1
		]).

-export([
			hook_role_enter/3,
			hook_monster_dead/3
		]).

%%
%% API Functions
%%
handle({t4_mp,RoleID,Value}) ->
    Change = [{#p_map_role.mp, Value}, {#p_map_role.max_mp, Value}],
    mod_map_role:update_map_role_info(RoleID, Change);

handle({reduce_mp,RoleID,ReduceMp}) ->
    mod_map_role:do_role_reduce_mp(RoleID, ReduceMp, RoleID);

handle({skillup,RoleID,Value}) ->
	nimbus_up(RoleID,Value);

handle(Info) ->
	?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

%% 杀死怪物加灵气值
hook_monster_dead(RoleID,MinDropMP,MaxDropMP) ->
	case MaxDropMP < MinDropMP orelse MinDropMP =:= 0 of
		false ->
			AddMP = common_tool:random(MinDropMP,MaxDropMP),
			mod_map_role:do_role_add_mp(RoleID,AddMP,RoleID),
			{ok,AddMP};
		true ->
			ignore
	end.
	
hook_role_enter(RoleID,RoleMapInfo, MapID) when RoleMapInfo#p_map_role.from_mapid =/= 0 ->
	case mgeem_map:get_map_type(MapID) of
		?MAP_TYPE_COPY->
			case mgeem_map:get_map_type(RoleMapInfo#p_map_role.from_mapid) of
				?MAP_TYPE_COPY ->
					set_mp(RoleID,get_mp(RoleID));
				_ ->
					case mod_map_actor:get_actor_mapinfo(RoleID, role) of
						undefined ->
							ignore;
						#p_map_role{mp=Mp} ->
							set_mp(RoleID,Mp)
					end
			end;
		_ ->
			ignore
	end;
hook_role_enter(_RoleID,_RoleMapInfo, _MapID) ->
	ignore.

nimbus_up(RoleID,SkillLevel) ->
	[AddMaxMp] = common_config_dyn:find(nimbus, {nimbus_level,SkillLevel}),
	RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
	#p_map_role{max_mp=MaxHp} = RoleMapInfo,
	AttrChanges = common_role:get_attr_change_list([{max_mp, MaxHp+AddMaxMp}]),
	mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo#p_map_role{max_mp=MaxHp+AddMaxMp}),
	RAttrChanges = #m_role2_attr_change_toc{roleid=RoleID, changes=AttrChanges},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE,RAttrChanges).

hook_change_level(RoleID) ->
	case mod_map_actor:get_actor_mapinfo(RoleID,role) of
		#p_map_role{max_mp=MaxMp}->
			mod_map_role:do_role_add_mp(RoleID, MaxMp, RoleID);
		_ ->
			ignore
	end.

check_in_fb() ->
	#map_state{mapid=MapID} = mgeem_map:get_state(), 
	[PoolMapIDs] = common_config_dyn:find(nimbus, all_map),
	{lists:member(MapID, PoolMapIDs),MapID}.

pool_add_mp(RoleID, MapID,RoleMapInfo2, RecoverMP) ->
	case mod_map_actor:get_actor_txty_by_id(RoleID, role) of
        {X,Y} ->
			[PointConfigs] = common_config_dyn:find(nimbus, {point,MapID}),
			calc_mp(RoleMapInfo2, RecoverMP,PointConfigs,{X,Y},false);
		_ ->
			next
	end.
	
calc_mp(RoleMapInfo, _RecoverMP,_PointConfigs,{_X,_Y},true) ->
	{ok,RoleMapInfo};
calc_mp(_RoleMapInfo, _RecoverMP,[],{_X,_Y},false) ->
	next;
calc_mp(RoleMapInfo, RecoverMP,[PointConfig|PointConfigs],{X,Y},false) ->
	case cal_range(X,Y,PointConfig) of
		{ok,Num,PoolTX,PoolTY} ->
			NewRoleMapInfo = mod_map_role:add_mp(RoleMapInfo#p_map_role.role_id, RoleMapInfo, Num),
			calc_mp(NewRoleMapInfo, RecoverMP,PointConfigs,{PoolTX,PoolTY},true);
		_ ->
			calc_mp(RoleMapInfo, RecoverMP,PointConfigs,{X,Y},false)
	end.
	
cal_range(X,Y,PointConfig) ->
	#r_nimbus_config{tx=TX, ty=TY,range=Range,num=Num} = PointConfig,
	XV = abs(TX-X),
    XY = abs(TY-Y),
	case XV*XV+XY*XY > Range*Range of
        true  ->
			next;
		_ ->
			{ok,Num,TX,TY}
	end.
	
set_mp(RoleID,Mp) ->
	put({?MODULE,RoleID},Mp).
get_mp(RoleID) ->
	get({?MODULE,RoleID}).