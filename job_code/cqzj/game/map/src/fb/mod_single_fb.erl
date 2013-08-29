-module (mod_single_fb).
-include("mgeem.hrl").
-include("single_fb.hrl").

-export ([handle/1, loop/2, handle_event/2, assert_valid_map_id/1, 
		  get_map_name_to_enter/1, clear_map_enter_tag/1]).
-export ([role_misc_init/2, role_misc_delete/1]).

-define(MOD_UNICAST(RoleID, Method, Msg), common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SINGLE_FB, Method, Msg)).

role_misc_init(RoleID, RSingleFbRec) ->
	case RSingleFbRec of 
		false -> RSingleFbRec1 = #r_single_fb{role_id = RoleID, update_time = common_tool:now()};
		_ 	  -> RSingleFbRec1 = RSingleFbRec
	end,
	set_role_single_fb_rec(RSingleFbRec1).

role_misc_delete(RoleID) ->
	mod_role_tab:erase(RoleID, r_single_fb).
%% ============================================================================
%% ============================================================================
handle({_Unique, _MOUDLE, ?SINGLE_FB_INFO, DataIn, RoleID, _PID, _Line}) ->
	do_fb_info(RoleID, DataIn);
handle({_Unique, _MOUDLE, ?SINGLE_FB_ENTER, DataIn, RoleID, _PID, _Line}) ->
	do_fb_enter(RoleID, DataIn);
handle({_Unique, _MOUDLE, ?SINGLE_FB_QUIT, _DataIn, RoleID, _PID, _Line}) ->
	do_quit(RoleID);

handle({init, MapID, _MapName}) ->
	{FbType, FbId} = cfg_single_fb:fb_key(MapID),
	erlang:put(fb_key, {FbType, FbId}),
	reset_battle_open_time(FbType),
	ok;


handle({init_before_role_enter, RoleID, EnterMapId, EnterPos}) ->
	erlang:put({enter_pos, RoleID}, {EnterMapId, EnterPos}),
	erlang:put({fisrt_enter_this_fb, RoleID}, true),
	erlang:put({in_single_fb_flag, RoleID}, true),
	case is_multi_player_fb(mgeem_map:get_mapid()) of
		false ->
			MonsterIdList = mod_map_monster:get_monster_id_list(), 
			erlang:put(total_monster, length(MonsterIdList)),
			erlang:put(killed_monster_num, 0);
		true -> ignore
	end,
	ok;	

handle({role_enter, RoleID, MapID}) ->
	hook_role_enter(RoleID, MapID);
handle({offline_terminate, RoleID}) ->
	do_offline_terminate(RoleID);
handle({role_quit, RoleID}) ->
	hook_role_quit(RoleID);
handle(_Msg) ->
	ignore.


loop(_MapId, NowSec) ->
	case erlang:get(ready_to_close) of
		undefined -> ignore;
		LeftSeconds -> do_ready_close_broadcast(LeftSeconds)
	end,
	loop_broadcast(NowSec),
	ok.

loop_broadcast(NowSec) ->
	{FbType, FbId} = erlang:get(fb_key), 
	case cfg_single_fb:open_broadcast(FbType) of
		[] -> ignore;
		_  ->
			OpenTimeRec = erlang:get(battle_open_time),
			if 
				OpenTimeRec#battle_open_time.start_time == NowSec ->
					do_open_broadcast(FbType, FbId),
					erlang:put(is_open, true);
				OpenTimeRec#battle_open_time.next_bc_time == NowSec ->
					do_ready_open_broadcast(FbType, FbId, OpenTimeRec),
					NextBcTime = OpenTimeRec#battle_open_time.next_bc_time + 60,
					erlang:put(battle_open_time, OpenTimeRec#battle_open_time{next_bc_time = NextBcTime}); 
				OpenTimeRec#battle_open_time.end_time == NowSec ->
					erlang:put(ready_to_close, 10),
					erlang:put(is_open, false),
					reset_battle_open_time(FbType);
				true -> ok
			end
	end.

do_open_broadcast(FbType, _FbId) ->
	Msg = common_misc:format_lang(<<"~ts已开启，请大家前往参与">>, [cfg_single_fb:fb_name(FbType)]),
	common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg).


do_ready_open_broadcast(FbType, _FbId, OpenTimeRec) ->
	Start = common_tool:seconds_to_datetime_string(OpenTimeRec#battle_open_time.start_time),
	End   = common_tool:seconds_to_datetime_string(OpenTimeRec#battle_open_time.end_time),
	Msg   = common_misc:format_lang(<<"~ts将在~s-~s开启">>, [cfg_single_fb:fb_name(FbType), Start, End]),
	common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg).

do_ready_close_broadcast(LeftSeconds) when LeftSeconds =< 0 -> do_close_fb();
do_ready_close_broadcast(LeftSeconds) ->
	if
		LeftSeconds == 10 orelse LeftSeconds == 5 ->
			Msg = common_misc:format_lang(<<"副本将在~p秒后关闭">>, [LeftSeconds]),
			[(catch common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_CENTER, Msg))
				|| RoleID <- mgeem_map:get_all_roleid()];
		true -> ok
	end,
	erlang:put(ready_to_close, LeftSeconds - 1).

do_close_fb() ->
	erlang:put(single_fb_timeout_flag, true),
	[send_role_quit(RoleID) || RoleID <- mgeem_map:get_all_roleid()].

is_in_this_fb(RoleID) -> 
	case erlang:get({in_single_fb_flag, RoleID}) of
		true -> true;
		_ -> false
	end.

assert_valid_map_id(_DestMapID) -> ok.
get_map_name_to_enter(RoleID) -> 
	{DestMapID, _TX, _TY} = get({enter, RoleID}),
	get_map_name_to_enter(RoleID, DestMapID).
get_map_name_to_enter(RoleID, MapId) ->
	case is_multi_player_fb(MapId) of
		true  -> lists:concat(["single_fb_map_", MapId, "_", 0]);
		false -> lists:concat(["single_fb_map_", MapId, "_", RoleID])
	end.
clear_map_enter_tag(_RoleID) -> ok.

%% ============================================================================
%% ============================================================================
%% 这里做的原因是考虑以后的副本有些是通过npc进入的，有些却不是的
get_fb_type(0, FbType) -> FbType;
get_fb_type(NPCId, 0) -> cfg_single_fb:get_fb_type_by_npc(NPCId).

do_fb_info(RoleID, DataIn) ->
	NPCId  = DataIn#m_single_fb_info_tos.npc_id,
	FbId   = DataIn#m_single_fb_info_tos.fb_id,
	FbType = get_fb_type(NPCId, DataIn#m_single_fb_info_tos.fb_type),
	case check_fb_info(RoleID, FbType, FbId, NPCId) of
		true ->
			% case FbType of 需要对不同副本类型做处理的可以在这里加代码
			FbDetailRec      = get_fb_detail_rec(RoleID, FbType),
			EnterTimes       = FbDetailRec#fb_detail.enter_times,
			SingleFBBaseinfo = cfg_single_fb:base_info(FbType, FbId),
			VipLv            = mod_vip:get_role_vip_level(RoleID),
			{FeeType, Fee}   = cfg_single_fb:enter_fee(FbType, FbId, VipLv, EnterTimes + 1),
			Msg = #m_single_fb_info_toc{
				fb_id        = FbId,
				fb_type      = FbType,
				npc_id       = NPCId,
				fb_times     = EnterTimes,
				fb_max_times = SingleFBBaseinfo#single_fb_baseinfo.max_enter_times,
				fee_type     = get_fee_type(FeeType),
				enter_fee    = Fee
			},
			?MOD_UNICAST(RoleID, ?SINGLE_FB_INFO, Msg);
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason)
	end.
check_fb_info(RoleID, FbType, FbId, NPCId) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	case cfg_single_fb:base_info(FbType, FbId) of
		[] -> {error, <<"请求错误，没有该副本">>};
		SingleFBBaseinfo when RoleAttr#p_role_attr.level >= SingleFBBaseinfo#single_fb_baseinfo.open_level ->
			IsOpen   = is_fb_open(FbType),
			CfgNPCId = SingleFBBaseinfo#single_fb_baseinfo.entry_npc,
			if
				IsOpen == false -> {error, <<"副本暂未到开启时间">>};
				CfgNPCId == 0 -> true;
				CfgNPCId =/= NPCId -> {error, <<"请求副本信息时的npc参数错误">>};
				true -> %% todo: 检测玩家与npc的距离 
					true
			end;
		_ ->
			{error, <<"您的等级不够，副本暂未开启">>}
	end.

do_fb_enter(RoleID, DataIn) ->
	FbType      = DataIn#m_single_fb_enter_tos.fb_type,
	FbId        = DataIn#m_single_fb_enter_tos.fb_id,
	NPCId       = DataIn#m_single_fb_enter_tos.npc_id,
	FbDetailRec = get_fb_detail_rec(RoleID, FbType),
	case check_fb_enter(RoleID, FbType, FbId, NPCId, FbDetailRec) of
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason);
		{true, FeeType, Fee} ->
			case FeeType == free orelse Fee == 0 of
				true -> ok;
				false -> true = common_bag2:use_money(RoleID, FeeType, Fee, get_fee_log_type(FeeType))
			end,
			%% 增加次数
			NewEnterTimes = FbDetailRec#fb_detail.enter_times + 1,
			FbDetailRec1 = FbDetailRec#fb_detail{enter_times = NewEnterTimes},
			set_fb_detail_rec(RoleID, FbDetailRec1),

			SingleFBBaseinfo = cfg_single_fb:base_info(FbType, FbId),
			MapId            = SingleFBBaseinfo#single_fb_baseinfo.map_id,
			MapPID           = get_map_name_to_enter(RoleID, MapId),
			case is_multi_player_fb(MapId) of
				true  -> ignore;
				false -> mod_map_copy:create_copy(MapId, MapPID)
			end,
			EnterPos         = mod_map_actor:get_actor_pos(RoleID, role),
			EnterMapId       = mgeem_map:get_mapid(),
			global:send(MapPID, {?MODULE, {init_before_role_enter, RoleID, EnterMapId, EnterPos}}),
			%% 传送到新地图
			{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
			{TX, TY} = get_dest_born_pos(MapId, RoleBase#p_role_base.faction_id),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapId, TX, TY)
	end.

get_dest_born_pos(MapId, FactionId) ->
	case cfg_single_fb:born_pos(MapId, FactionId) of
		{X, Y} -> {X, Y};
		[] 	   -> {_, X, Y} = common_misc:get_born_info_by_map(MapId)
	end,
	{X, Y}.

check_fb_enter(RoleID, FbType, FbId, _NPCId, FbDetailRec) ->
	EnterTimes       = FbDetailRec#fb_detail.enter_times,
	SingleFBBaseinfo = cfg_single_fb:base_info(FbType, FbId),
	{ok, RoleAttr}   = mod_map_role:get_role_base(RoleID),
	IsOpen           = is_fb_open(FbType),
	if
		IsOpen == false -> {error, <<"副本暂未到开启时间">>};
		EnterTimes >= SingleFBBaseinfo#single_fb_baseinfo.max_enter_times ->
			{error, <<"今天可进入次数已用完，请明天再来">>};
		RoleAttr#p_role_attr.level < SingleFBBaseinfo#single_fb_baseinfo.open_level ->
			{error, <<"您的等级不够，副本暂未开启">>};
		true ->
			case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
                true ->
                	{error, ?_LANG_XIANNVSONGTAO_MSG};
                false -> 
                	VipLv          = mod_vip:get_role_vip_level(RoleID),
                	{FeeType, Fee} = cfg_single_fb:enter_fee(FbType, FbId, VipLv, EnterTimes + 1),
					case FeeType == free orelse Fee == 0 of
						true -> {true, FeeType, Fee};
						_ ->
							case common_bag2:check_money_enough(FeeType, Fee, RoleID) of
								false -> {error, get_fee_type_error(FeeType)};
								true  -> {true, FeeType, Fee}
							end
					end
            end
	end.

do_quit(RoleID) ->
	case is_in_this_fb(RoleID) of
		true ->	
			Msg = #m_single_fb_quit_toc{},
			?MOD_UNICAST(RoleID, ?SINGLE_FB_QUIT, Msg),

			send_role_quit(RoleID),
			mod_map_event:delete_handler({role, RoleID}, ?MODULE);
		false -> ignore
	end.

send_role_quit(RoleID) ->
	{EnterMapId, EnterPos} = erlang:get({enter_pos, RoleID}),
	mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, EnterMapId, EnterPos#p_pos.tx, EnterPos#p_pos.ty).

hook_role_enter(RoleID, MapId) ->
	case is_in_this_fb(RoleID) of
		true ->
			{FbType, FbId} = erlang:get(fb_key), 
			case erlang:get({fisrt_enter_this_fb, RoleID}) of
				true -> %% 第一次进入
					case cfg_single_fb:done_activity(FbType, FbId) of
						[] -> ignore;
						ActivityId -> hook_activity_task:done_task(RoleID, ActivityId)
					end,
					erlang:put({fisrt_enter_this_fb, RoleID}, false),
					mod_map_event:add_handler({role, RoleID}, ?MODULE),
					%% 完成进入场景副本的任务(因为该副本是由场景大战副本的衍生的，所以保留了之前的处理)
					mgeer_role:run(RoleID, fun() -> hook_mission_event:hook_enter_sw_fb(RoleID,MapId) end);
				_ -> ignore
			end,
			case erlang:erase(single_fb_timeout_flag) of
				true  -> send_role_quit(RoleID);
				_ -> ignore
			end;
		false -> ignore
	end.

hook_role_quit(RoleID) ->
	case is_in_this_fb(RoleID) of
		false -> ignore;
		true -> 
			mod_map_event:delete_handler({role, RoleID}, ?MODULE), %% 保险再调用一次
			case is_multi_player_fb(mgeem_map:get_mapid()) of
				false ->
					case mod_map_role:is_role_exit_game(RoleID) of
						true -> %% 玩家下线后副本进程保持9s，与玩家进程一同退出
							erlang:send_after(9*1000, self(), {?MODULE, {offline_terminate, RoleID}});
						_ -> %% 直接关闭副本进程
							common_map:exit(single_fb_role_quit)
					end;
				true -> ignore
			end
	end.

do_offline_terminate(_RoleID) ->
	case mod_map_actor:get_in_map_role() of
        [] -> common_map:exit(single_fb_role_quit);
        _  -> ignore
    end.

handle_event({role, RoleID}, {monster_dead, _MonsterInfo, _MonsterBaseInfo}) ->
	KilledMonsterNum = add_kill_monster_num(),
	TotalMonsterNum = erlang:get(total_monster), 
	%% 广播副本怪物数目
	Msg = common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_BC_MONSTER,[KilledMonsterNum,TotalMonsterNum]),
    (catch common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_CENTER, Msg)),
    %% 如果怪物杀完了，就可以设置退出标识了
    case KilledMonsterNum >= TotalMonsterNum of
    	true  -> erlang:put(ready_to_close, 10);
    	false -> ignore
    end,
	ok;

handle_event(_Who, _Args) -> ignore.

%% 增加一个杀死的怪物数量，并返回当前已杀死的怪物数
add_kill_monster_num() ->
	Num = 1 + get_killed_monster_num(),
	erlang:put(killed_monster_num, Num),
	Num.
get_killed_monster_num() ->
	case erlang:get(killed_monster_num) of
		undefined -> 
			erlang:put(killed_monster_num, 0),
			0;
		Num -> Num
	end.
	
%% ============================================================================
%% ============================================================================
get_role_single_fb_rec(RoleID) ->
	RSingleFbRec = mod_role_tab:get(RoleID, r_single_fb),
	Now          = common_tool:now(),
	case common_tool:check_if_same_day(RSingleFbRec#r_single_fb.update_time, Now) of
		true -> 
			RSingleFbRec1 = RSingleFbRec;
		false -> 
			FbDatas       = other_day_reset(RSingleFbRec#r_single_fb.fb_datas),
			RSingleFbRec1 = RSingleFbRec#r_single_fb{update_time = Now, fb_datas = FbDatas},
			set_role_single_fb_rec(RSingleFbRec1)
	end,
	RSingleFbRec1.

set_role_single_fb_rec(RSingleFbRec) ->
	mod_role_tab:put(RSingleFbRec#r_single_fb.role_id, r_single_fb, RSingleFbRec).

other_day_reset(AllFbDetailRecList) ->
	other_day_reset(AllFbDetailRecList, []).

%% 需要对个别的副本类型的数据做一些其他的重置的可以在这里添加匹配代码
other_day_reset([], Acc) -> Acc;
other_day_reset([FbDetailRec | Rest], Acc) ->
	other_day_reset(Rest, [FbDetailRec#fb_detail{enter_times = 0} | Acc]).

get_fb_detail_rec(RoleID, FbType) ->
	RSingleFbRec = get_role_single_fb_rec(RoleID),
	case lists:keyfind(FbType, #fb_detail.fb_type, RSingleFbRec#r_single_fb.fb_datas) of
		false ->
			FbDetailRec = build_default_fd_detail_rec(FbType),
			set_fb_detail_rec(RSingleFbRec, FbDetailRec);
		FbDetailRec -> FbDetailRec
	end,
	FbDetailRec.

set_fb_detail_rec(RoleID, NewFbDetailRec) when is_integer(RoleID) ->
	RSingleFbRec = get_role_single_fb_rec(RoleID),
	set_fb_detail_rec(RSingleFbRec, NewFbDetailRec);
set_fb_detail_rec(RSingleFbRec, NewFbDetailRec) ->
	FbDatas = lists:keystore(NewFbDetailRec#fb_detail.fb_type, #fb_detail.fb_type, 
				   RSingleFbRec#r_single_fb.fb_datas, NewFbDetailRec),
	RSingleFbRec1 = RSingleFbRec#r_single_fb{fb_datas = FbDatas},
	set_role_single_fb_rec(RSingleFbRec1).

%% 构造初始的默认fb_detail记录
%% 需要对不同的副本类型做一些特别的初始化可以在这里添加匹配代码
build_default_fd_detail_rec(FbType) -> #fb_detail{fb_type = FbType}.

get_fee_type(gold_any) 	  -> 1;
get_fee_type(gold_unbind) -> 2;
get_fee_type(silver) 	  -> 3;
get_fee_type(free) 		  -> 4.

get_fee_type_error(gold_any)    -> ?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD_BIND;
get_fee_type_error(gold_unbind) -> ?_LANG_NOT_ENOUGH_GOLD;
get_fee_type_error(silver)      -> ?_LANG_NOT_ENOUGH_SILVER.

get_fee_log_type(gold_any) 		-> ?CONSUME_TYPE_GOLD_ENTER_FB;
get_fee_log_type(gold_unbind) 	-> ?CONSUME_TYPE_GOLD_ENTER_FB;
get_fee_log_type(silver) 		-> ?CONSUME_TYPE_SILVER_ENTER_FB.


is_multi_player_fb(MapId) ->
	lists:member(MapId, cfg_single_fb:multi_player_fb_maps()). 


reset_battle_open_time(FbType) ->
	case cfg_single_fb:open_broadcast(FbType) of
		[] -> ignore;
		DailyOpenTimes ->
			NowSec = common_tool:now(),
			{ok,Date,StartSec,EndSec} = common_fb:get_next_fb_open_time_daily(NowSec, DailyOpenTimes),
			BattleOpenTime = #battle_open_time{
				date         = Date,
				start_time   = StartSec,
				end_time     = EndSec,
				next_bc_time = StartSec - 5*60
			},
			erlang:put(battle_open_time, BattleOpenTime)
	end.

is_fb_open(FbType) ->
	case cfg_single_fb:open_broadcast(FbType) of
		[] -> true;
		DailyOpenTimes ->
			NowSec = common_tool:now(),
			{ok,_Date,StartSec,EndSec} = common_fb:get_next_fb_open_time_daily(NowSec, DailyOpenTimes),
			(StartSec =< NowSec andalso NowSec < EndSec)
	end.
