%% Author: dizengrong
%% Created: 2012-11-12
%% @doc: 离线事件处理，在玩家登录之后会发送事件通知，
%% 		 需要对事件进行处理的在这里添加代码

-module (mod_offline_event).
-include("mgeer.hrl").

-export([dispatch_event/1, get_db_data/1, add_event/3, handle/1]).

%% 初始化离线事件	
handle({dispatch_offline_event, RoleID}) ->
	dispatch_event(get_db_data(RoleID)).

%% 分发离线事件
dispatch_event(OfflineEventRec) ->
	try 
		RoleId = OfflineEventRec#r_offline_event.role_id,
		Events = OfflineEventRec#r_offline_event.events,
		do_dispatch(RoleId, Events),
		%% 分发后离线事件被删掉
		set_db_data(OfflineEventRec#r_offline_event{events = []})
	catch
		Type:Error ->
			?ERROR_MSG("Call dispatch_event(~w) failed, type: ~w, error: ~w, stack: ~w",
					   [OfflineEventRec, Type, Error, erlang:get_stacktrace()])
	end.
	

do_dispatch(_RoleId, []) -> ok;	
do_dispatch(RoleId, [{?OFFLINE_EVENT_TYPE_JOIN_FAMILY, Data} | Rest]) -> 
	mod_achievement2:achievement_update_event(RoleId, 41004, Data),
	do_dispatch(RoleId, Rest);
do_dispatch(RoleId, [{?OFFLINE_EVENT_TYPE_MINE_END, HarvestSilver} | Rest]) -> 
	common_bag2:add_money(RoleId, silver_bind, HarvestSilver, ?GAIN_TYPE_SILVER_MINE_FB_HARVEST),
	{ok, RoleMapExtRec} = mod_map_role:get_role_map_ext_info(RoleId),
	RoleMineFbInfo      = RoleMapExtRec#r_role_map_ext.role_mine_fb,
	RoleMineFbInfo1     = RoleMineFbInfo#r_role_mine_fb{place_id=0},
	RoleMapExtRec1      = RoleMapExtRec#r_role_map_ext{role_mine_fb = RoleMineFbInfo1},
	mod_map_role:set_role_map_ext_info(RoleId, RoleMapExtRec1),

	R2 = #m_mine_fb_dig_toc{dig_type=2,return_self=true,role_id=RoleId,harvest_silver=HarvestSilver},
	common_misc:unicast({role, RoleId}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_DIG, R2),

	do_dispatch(RoleId, Rest);
do_dispatch(RoleId, [{?OFFLINE_EVENT_TYPE_WIN_COUNT, WinCount} | Rest]) ->	
	mod_achievement2:achievement_update_event(RoleId, 42006, WinCount),
	mod_achievement2:achievement_update_event(RoleId, 43001, WinCount),
	mod_achievement2:achievement_update_event(RoleId, 44003, WinCount),
	do_dispatch(RoleId, Rest).

%% 添加离线事件
add_event(RoleId, EventType, EventData) ->
	try
		do_add_event(RoleId, EventType, EventData)
	catch
		Type:Error ->
			?ERROR_MSG("Call do_add_event(~w, ~w, ~w) failed, type: ~w, error: ~w, stack: ~w",
					   [RoleId, EventType, EventData, Type, Error, erlang:get_stacktrace()])
	end.

do_add_event(RoleId, EventType = ?OFFLINE_EVENT_TYPE_WIN_COUNT, WinCount) ->
	OfflineEventRec = get_db_data(RoleId),
	Ret = case lists:keyfind(EventType, 1, OfflineEventRec#r_offline_event.events) of
		false -> {EventType, WinCount};
		{_, OldWinCount} ->
			case WinCount > OldWinCount of
				true ->  {EventType, WinCount};
				false -> ignore
			end
	end,
	case Ret of
		ignore -> ignore;
		Event ->
			Events = lists:keystore(EventType, 1, OfflineEventRec#r_offline_event.events, Event),
			set_db_data(OfflineEventRec#r_offline_event{events = Events})
	end;
do_add_event(RoleId, EventType = ?OFFLINE_EVENT_TYPE_JOIN_FAMILY, Data) ->
	OfflineEventRec = get_db_data(RoleId),
	Ret = case lists:keyfind(EventType, 1, OfflineEventRec#r_offline_event.events) of
		false -> {EventType, Data};
		{_, _} ->
			ignore
	end,
	case Ret of
		ignore -> ignore;
		Event ->
			Events = lists:keystore(EventType, 1, OfflineEventRec#r_offline_event.events, Event),
			set_db_data(OfflineEventRec#r_offline_event{events = Events})
	end;
%% 不需要特殊处理的，默认覆盖原有的事件	
do_add_event(RoleId, EventType, EventData) ->
	OfflineEventRec = get_db_data(RoleId),
	Event           = {EventType, EventData},
	Events          = lists:keystore(EventType, 1, OfflineEventRec#r_offline_event.events, Event),
	set_db_data(OfflineEventRec#r_offline_event{events = Events}).


%% ==============================数据操作=====================================
get_db_data(RoleId) ->
	case db:dirty_read(?DB_OFFLINE_EVENT_P, RoleId) of
        [] -> Rec = #r_offline_event{role_id = RoleId};
        [Rec] -> ok
    end,
    Rec.

set_db_data(OfflineEventRec) ->
	db:dirty_write(?DB_OFFLINE_EVENT_P, OfflineEventRec).