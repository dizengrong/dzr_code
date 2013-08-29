%%% -------------------------------------------------------------------
%%% Author  : xierf
%%% Description :镜像副本
%%%
%%% Created : 2012-6-5
%%% -------------------------------------------------------------------
-module(mod_mirror_fb).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").

-define(MIRROR_TEST_MAP_ID, 10326). %%镜像测试地图

-define(DEAD_TYPE_MIRROR_FB, 12). %% 在离线PVP中死亡

-define(from_where,from_where).

%% --------------------------------------------------------------------
%% External exports
-export([handle/2, hook_role_before_quit/2, hook_role_map_enter/2, hook_role_online/2, hook_role_offline/2, loop/2]).
-export([assert_valid_map_id/1, get_map_name_to_enter/1, clear_map_enter_tag/1, is_in_mirror_map/0]).

%% ====================================================================
%% External functions
%% ====================================================================
assert_valid_map_id(_DestMapID) ->
	ok.

get_map_name_to_enter(RoleID) ->
	get({map_pname_to_enter, RoleID}).

clear_map_enter_tag(_RoleID) ->
	ok.

is_in_mirror_map() ->
	?IS_MIRROR_FB(mgeem_map:get_mapid()).

hook_role_map_enter(RoleID,MapID) when ?IS_MIRROR_FB(MapID) ->
	case get(in_match) of
	true ->
		ignore;
	_ ->
		RoleMapInfo1 = mod_map_actor:get_actor_mapinfo(RoleID, role),
		put(nuqi_before_fight, RoleMapInfo1#p_map_role.nuqi),
		RoleMapInfo2 = RoleMapInfo1#p_map_role{nuqi = 0},
		mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo2),
		mod_role2:modify_pk_mode_without_check(RoleID, ?PK_PEACE),
		mod_mirror:handle({prepare, RoleID}, undefined)
	end;

hook_role_map_enter(_RoleID, _MapID) ->
	ignore.

hook_role_before_quit(RoleID, MapID) when ?IS_MIRROR_FB(MapID) ->
	handle({stop, RoleID}, mgeem_map:get_state());

hook_role_before_quit(_RoleID, _MapID) ->
	ignore.

hook_role_online(RoleID, MapID) when ?IS_MIRROR_FB(MapID) ->
	case mod_mirror:mirrors() of
	[] ->
		case erase({?from_where, RoleID}) of
		{FromMapID, FromMapName,#p_pos{tx=TX, ty=TY}} ->
			case common_config_dyn:find(fb_map,FromMapID) of
			[#r_fb_map{is_simple_enter=true,module=FbModule}]->
				FbModule:set_map_enter_tag(RoleID,FromMapName);
			_ ->
				ignore
			end,
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, FromMapID, TX, TY);
		_ ->
			do_return_home_map(RoleID,MapID)
		end;
	_ ->
		ignore
	end;

hook_role_online(_RoleID, _MapID) ->
	ignore.

hook_role_offline(RoleID, MapID) when ?IS_MIRROR_FB(MapID) ->
	case mod_mirror:mirrors() of
		[] ->
			handle({stop, RoleID}, mgeem_map:get_state());
		_ ->
			ignore
	end;

hook_role_offline(_RoleID, _MapID) ->
	ignore.

loop(_NowSec, MapID) when ?IS_MIRROR_FB(MapID) ->
	case get(match_timer) of
		undefined ->
			ignore;
		{Secs, RoleID, MirrorID} when Secs =< 0 ->
			handle({timeout, RoleID, MirrorID}, mgeem_map:get_state());
		{Secs, RoleID, MirrorID} ->
			put(match_timer, {Secs-1, RoleID, MirrorID})
	end;
loop(_, _) ->
	ignore.

%% --------------------------------------------------------------------
%% Function: handle/2
%% --------------------------------------------------------------------
handle({change_map, RoleID, FbMapID, FbMapPID, FbMapPName, MirrorTab, ExtInfo}, 
	   #map_state{mapid=FromMapID, map_name=FromMapName}) ->
	put({map_pname_to_enter, RoleID}, FbMapPName),
	FromMapData = {FromMapID, FromMapName, mod_map_actor:get_actor_pos(RoleID, role)},
	FbMapPID ! {mod, ?MODULE, {init, RoleID, MirrorTab, FromMapData, FbMapID, ExtInfo}},
	{_, TX, TY} = common_misc:get_born_info_by_map(FbMapID),
	mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, FbMapID, TX, TY);

handle({stop, RoleID}, MapState = #map_state{mapid=MapID}) ->
	[MirrorMaps] = common_config_dyn:find(mirror_fb,mirror_map),
	case lists:keyfind(MapID, 1, MirrorMaps) of
		{MapID,Module}->
			?TRY_CATCH( Module:mirror_fb_stop(RoleID) );
		false->
			ignore
	end,
	mod_mirror:handle(unsummon, MapState);

handle({init, RoleID, MirrorTab, FromMapData, FbMapID, ExtInfo}, _MapState) ->
	[#p_role_base{role_id = MirrorID}] = ets:lookup(MirrorTab, p_role_base),
	put({?from_where, RoleID}, FromMapData),
	put(match_timer, {40, RoleID, MirrorID}),
	put({t_mirror, MirrorID}, MirrorTab),
	[put(K, V)||{K, V} <- ExtInfo],
	{ok, NewMapState} = mod_solo_fb:init(FbMapID, mgeer_role:proc_name(RoleID)),
	mod_mirror:handle({summon, MirrorTab}, NewMapState),
	erlang:send_after(1500, self(), {mod, ?MODULE, {countdown, RoleID, 3}});

handle({countdown, RoleID, Secs}, _MapState) ->
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, 
		?MIRROR_FIGHT, ?MIRROR_FIGHT_COUNTDOWN, #m_mirror_fight_countdown_toc{secs=Secs}),
	erlang:send_after(Secs*1000, self(), {mod, ?MODULE, {fight, RoleID}});

handle({fight, RoleID}, MapState) ->
	put(in_match, true),
	{_, RoleID, MirrorRoleID} = get(match_timer),
	put(match_timer, {30, RoleID, MirrorRoleID}),
	mod_role2:modify_pk_mode_without_check(RoleID, ?PK_ALL),
	mod_role2:modify_pk_mode_without_check(MirrorRoleID, ?PK_ALL),
	mod_mirror:handle({activate, RoleID}, MapState);

handle({timeout, RoleID, MirrorRoleID}, MapState) ->
	erase(in_match) == true andalso begin
		case mod_map_actor:get_actor_mapinfo(RoleID, role) of
			undefined ->
				handle({after_fight, RoleID, MirrorRoleID, false}, MapState);
			#p_map_role{hp=RoHP, max_hp=RoMaxHP} ->
				catch mod_role2:modify_pk_mode_without_check(RoleID, ?PK_PEACE),
				case mod_map_actor:get_actor_mapinfo(MirrorRoleID, role) of
					#p_map_role{hp=MiHP, max_hp=MiMaxHP} ->
						IsRoleWin = RoHP/RoMaxHP > MiHP/MiMaxHP,
						handle({after_fight, RoleID, MirrorRoleID, IsRoleWin}, MapState);
					_ ->
						handle({after_fight, RoleID, MirrorRoleID, false}, MapState)
				end
		end
	end;

handle({role_dead, RoleID, RoleMapInfo, KillerID, KillerType, KillerName}, MapState) ->
	KillerRoleID = role_id(KillerType, KillerID),
	case RoleMapInfo#p_map_role.is_mirror of
		true ->
			MirrorID = RoleID, PlayerID = KillerRoleID;
		false ->
			PlayerID = RoleID, MirrorID = KillerRoleID
	end,
	erase(in_match) == true andalso begin
		case RoleMapInfo#p_map_role.is_mirror of
			true ->
				Record = #m_role2_dead_other_toc{roleid=MirrorID},
				common_misc:unicast({role, PlayerID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_DEAD_OTHER, Record);
			false ->
				Record = #m_role2_dead_toc{killer=KillerName, dead_type=?DEAD_TYPE_MIRROR_FB},
				common_misc:unicast({role, PlayerID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_DEAD, Record)
		end,
		case mod_map_actor:get_actor_mapinfo(PlayerID, role) of
			undefined ->
				ignore;
			_ ->
				catch mod_role2:modify_pk_mode_without_check(PlayerID, ?PK_PEACE)
		end,
		handle({after_fight, PlayerID, MirrorID, PlayerID == KillerRoleID}, MapState)
	end;

handle({after_fight, RoleID, MirrorID, IsRoleWin}, MapState) ->
	mod_mirror:handle(inactivate, MapState),
	case erase(match_timer) of
		{_Time, RoleID, _MirrorID} ->
			#map_state{mapid=MapID} = MapState,
			[MirrorMaps] = common_config_dyn:find(mirror_fb, mirror_map),
			MirrorTab = erase({t_mirror, MirrorID}),
			case lists:keyfind(MapID, 1, MirrorMaps) of
				{MapID,Module}->
					?TRY_CATCH( Module:after_fight(RoleID, abs(MirrorID), MirrorTab, IsRoleWin) );
				false->
					ignore
			end,
			erlang:send_after(3000, self(), {mod, ?MODULE, {terminate, RoleID}});
		_ ->
			handle({terminate, RoleID}, MapState)
	end;

handle(terminate, MapState) ->
	handle({terminate, get(role_id)}, MapState);

handle({terminate, RoleID}, MapState) when ?IS_MIRROR_FB(MapState#map_state.mapid) ->
	do_quit(RoleID, MapState);

handle({_Unique, _Module, ?MIRROR_FIGHT_QUIT, _DataIn, RoleID, _PID, _Line}, 
	   MapState) when ?IS_MIRROR_FB(MapState#map_state.mapid) ->
	case get(match_timer) of
		{_Time, RoleID, MirrorID} ->
			handle({after_fight, RoleID, MirrorID, false}, MapState);
		_ ->
			ignore
	end;

handle(_Msg, _MapState) ->
	ignore.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%回到主城王城
do_return_home_map(RoleID,MapId)->
	{ok, #p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
	HomeMapID = common_misc:get_home_mapid(FactionID, MapId),
	{_, TX, TY} = common_misc:get_born_info_by_map(HomeMapID),
	mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, HomeMapID, TX, TY).

role_id(role, RoleID) -> 
	RoleID;
role_id(pet, PetID) -> 
	#p_map_pet{role_id=RoleID} = mod_map_actor:get_actor_mapinfo(PetID, pet),
	RoleID.

do_quit(RoleID, MapState) ->
	case mod_map_actor:get_actor_mapinfo(RoleID, role) of
		undefined ->
			handle({stop, RoleID}, MapState);
		RoleMapInfo = #p_map_role{max_hp = MaxHP, max_mp = MaxMP} ->
			NuqiBeforeFight = case erase(nuqi_before_fight) of
				Num when is_integer(Num) -> Num;
				_ -> 0
			end,		
			mod_map_role:send_role_hmn_change(RoleID, 
				RoleMapInfo#p_map_role{nuqi = NuqiBeforeFight, hp=MaxHP, mp=MaxMP}),
			case erase({?from_where, RoleID}) of
				{FromMapID, FromMapName, #p_pos{tx = TX, ty = TY}} ->
					case common_config_dyn:find(fb_map, FromMapID) of
						[#r_fb_map{is_simple_enter = true, module = FbModule}]->
							FbModule:set_map_enter_tag(RoleID, FromMapName);
						_ ->
							ignore
					end,
					mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, FromMapID, TX, TY);
				_ ->
					do_return_home_map(RoleID, MapState#map_state.mapid)
			end
	end,
	catch mod_mirror:handle(unsummon, MapState).
