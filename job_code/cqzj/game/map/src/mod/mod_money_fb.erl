%%%-------------------------------------------------------------------
%%% @author dizengrong
%%% @doc
%%% 	金钱副本
%%% @end
%%% Created : 2013-3-13
%%%-------------------------------------------------------------------
-module (mod_money_fb).

-include("mgeem.hrl").

-export([handle/1, assert_valid_map_id/1, get_map_name_to_enter/1,
		 clear_map_enter_tag/1, handle_event/2, loop/2, lists_zip/3]).

%% for role_misc
-export([init_money_data/2, delete_money_data/1]).

-define(MONEY_FB_MAP_ID, 		10704). 	%% 金钱副本地图的id
-define(THE_FIRST_ROUND, 	 		1).		%% 第一个回合
-define(MAX_LIANZHAN_INTERVAL, 	 	10).	%% 连斩的最大间隔时间(S)

-define(STATE_BEAT_MONSTER, 		 0).	%% 玩家在副本中的状态：打怪
-define(STATE_COLLECT_MONEY, 		 1).	%% 玩家在副本中的状态：捡钱

-define(_slice_enter, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, #m_map_slice_enter_toc).
-define(_remove_grafts, ?DEFAULT_UNIQUE, ?COLLECT, ?COLLECT_REMOVE_GRAFTS, #m_collect_remove_grafts_toc).
-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MONEY_FB, Method, Msg)).

%% 该副本的战报
-record(fb_report, {
	end_time     = 0,			%% 副本结束时间
	total_silver = 0, 			%% 获得的总钱币
	kill_boss    = 0, 			%% 杀死boss的个数
	kill_monster = 0, 			%% 杀死小怪的个数
	lianzhan     = 0, 			%% 当前连斩
	max_lianzhan = 0, 			%% 此次最高连斩
	state        = ?STATE_BEAT_MONSTER 			%% 状态(STATE_BEAT_MONSTER | STATE_BEAT_MONSTER)
	}).

init_money_data(RoleID, MoneyFbRec) ->
	case MoneyFbRec of 
		false -> MoneyFbRec1 = #r_money_fb{update_time = common_tool:now()};
		_ 	  -> MoneyFbRec1 = MoneyFbRec
	end,
	mod_role_tab:put(RoleID, r_money_fb, MoneyFbRec1).

delete_money_data(RoleID) ->
	mod_role_tab:erase(RoleID, r_money_fb).

get_role_money_fb_rec(RoleID) ->
	MoneyFbRec = mod_role_tab:get(RoleID, r_money_fb),
	Now = common_tool:now(),
	case common_tool:check_if_same_day(MoneyFbRec#r_money_fb.update_time, Now) of
		true -> 
			MoneyFbRec1 = MoneyFbRec;
		false -> 
			MoneyFbRec1 = MoneyFbRec#r_money_fb{enter_times = 0, update_time = Now},
			mod_role_tab:put(RoleID, r_money_fb, MoneyFbRec1)
	end,
	MoneyFbRec1.

assert_valid_map_id(_DestMapID) -> ok.
get_map_name_to_enter(RoleID) -> get_this_map_process_name(RoleID).
clear_map_enter_tag(_RoleID) -> ok.


handle({_Unique, ?MONEY_FB, ?MONEY_FB_ENTER, _DataIn, RoleID, _PID, _Line}) ->
	do_enter(RoleID);
handle({_Unique, ?MONEY_FB, ?MONEY_FB_QUIT, _DataIn, RoleID, _PID, _Line}) ->
	do_quit(RoleID);
handle({_Unique, ?MONEY_FB, ?MONEY_FB_START_SILVER, _DataIn, RoleID, _PID, _Line}) ->
	do_start_gen_gold(RoleID);
handle({init_fb_map_info, RoleID, EnterMapId, EnterPos}) ->
	set_role_in_this_map_flag(RoleID),
	set_return_pos(RoleID, EnterMapId, EnterPos),
	erlang:put(money_fb_fisrt_enter, true),
	ok;
handle({init, _MapID, _MapName}) -> %% 地图创建初始化
	erlang:put(money_fb_fisrt_enter, true),
	ignore;
handle({role_enter, RoleID, MapID}) ->
	hook_role_enter(RoleID, MapID);
handle({role_quit, RoleID}) ->
	hook_role_quit(RoleID);
handle({delete_all_monster, RoleID}) ->
	AllMonsters = mod_map_monster:get_monster_id_list(),
	common_misc:unicast({role, RoleID}, ?_slice_enter{del_monsters = AllMonsters});
handle({RoleID, collect_timer}) ->
	collect_timeout(RoleID, mgeem_map:get_mapid());
handle({RoleID, self_loop}) -> 
	self_one_second_loop(RoleID);
handle({RoleID, fb_timeout}) -> 
	erlang:put(ready_to_close, 5),
	Pid = global:whereis_name(get_this_map_process_name(RoleID)),
	erlang:send_after(5*1000, Pid, {?MODULE, {RoleID, fb_ready_to_close}});
handle({RoleID, fb_ready_to_close}) ->
	LeftTime = erlang:get(ready_to_close),
	case LeftTime > 0 of 
		true ->
			common_misc:send_common_error(RoleID, 0, lists:flatten(io_lib:format(<<"副本将在~w秒后关闭">>, [LeftTime]))),
			erlang:put(ready_to_close, LeftTime - 1),
			Pid = global:whereis_name(get_this_map_process_name(RoleID)),
			erlang:send_after(LeftTime*1000, Pid, {?MODULE, {RoleID, fb_ready_to_close}});
		false ->
			case is_role_in_this_map(RoleID, ?MONEY_FB_MAP_ID) of
				true  -> do_quit(RoleID);
				false -> ignore %% 当玩家退出副本时，，副本就会去关闭的
			end
	end;
handle(_) -> ignore.

%% 每秒循环, 主要用来检测连斩超时的
loop(_MapID, _Now) ->
	case erlang:get(map_owner) of
		undefined -> ignore;
		RoleID    -> self_one_second_loop(RoleID)
	end.
self_one_second_loop(RoleID) ->
	ReportRec = get_report_data(RoleID),
	case is_lianzhan_timeout() of
		true ->
			case ReportRec#fb_report.lianzhan of
				0 -> ignore;
				_ ->
					ReportRec1 = ReportRec#fb_report{lianzhan = 0},
					set_report_data(RoleID, ReportRec1),
					send_report_to_client(RoleID, ReportRec1)
			end;
		false -> ok
	end,
	case ReportRec#fb_report.state of
		?STATE_COLLECT_MONEY -> clear_reborn_monster_list();
		_ -> reborn_monster(RoleID)
	end,
	ok.
	

%% 玩家是否在该地图中
is_role_in_this_map(RoleID, MapID) ->	
	case get_role_in_this_map_flag(RoleID) == true andalso MapID == ?MONEY_FB_MAP_ID of 
		true -> true;
		_    -> false
	end.

get_this_map_process_name(RoleID) ->
	lists:concat([?MONEY_FB_MAP_ID, RoleID]).

do_enter(RoleID) ->
	MoneyFbRec    = get_role_money_fb_rec(RoleID),
	MaxEnterTimes = cfg_money_fb:daily_max_enter_times(),
	Ret = case MoneyFbRec#r_money_fb.enter_times >= MaxEnterTimes of 
		true  -> {error, <<"今天可进入次数已用完，请明天再来">>};
		false -> 
			{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			OpenLv = cfg_money_fb:open_level(),
			case OpenLv > RoleAttr#p_role_attr.level of
				true -> {error, common_misc:format_lang("~w级开放进入权限", [OpenLv])};
				false -> 
		            case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
		                true ->
		                {error, ?_LANG_XIANNVSONGTAO_MSG};
		                false -> true
		            end
			end
	end,

	case Ret of 
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			MapPID     = get_this_map_process_name(RoleID),
			mod_map_copy:create_copy(?MONEY_FB_MAP_ID, MapPID),
			EnterPos   = mod_map_actor:get_actor_pos(RoleID, role),
			EnterMapId = mgeem_map:get_mapid(),
			global:send(MapPID, {?MODULE, {init_fb_map_info, RoleID, EnterMapId, EnterPos}}),
			%% 传送到新地图
			{_, TX, TY} = common_misc:get_born_info_by_map(?MONEY_FB_MAP_ID),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, ?MONEY_FB_MAP_ID, TX, TY)
	end.

do_quit(RoleID) ->
	case is_role_in_this_map(RoleID, mgeem_map:get_mapid()) of
		true ->
			Msg = #m_money_fb_quit_toc{},
			?MOD_UNICAST(RoleID, ?MONEY_FB_QUIT, Msg),

			{EnterMapId, EnterPos} = get_return_pos(RoleID),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, EnterMapId, EnterPos#p_pos.tx, EnterPos#p_pos.ty),
			%% 清理数据
			erase_role_in_this_map_flag(RoleID),
			erase_return_pos(RoleID),
			erase_role_in_this_map_flag(RoleID),
			cancel_collect_timer(),
			erase(map_owner),
			mod_map_event:delete_handler({role, RoleID}, ?MODULE),
			remove_attack_buf(RoleID),
			ok;
		false -> 
			?ERROR_MSG("role ~w not in money fb, not send quit msg", [RoleID])
	end.

hook_role_enter(RoleID, MapID) ->
	case is_role_in_this_map(RoleID, MapID) of 
		true -> %% 初始化回合数据
			case erlang:get(money_fb_fisrt_enter) of
				true ->
					erlang:put(money_fb_fisrt_enter, false),
					Msg = #m_money_fb_enter_toc{},
					?MOD_UNICAST(RoleID, ?MONEY_FB_ENTER, Msg),

					put(map_owner, RoleID),
					mod_map_event:add_handler({role, RoleID}, ?MODULE),

					LastTime  = cfg_money_fb:fb_last_time(),
					ReportRec = #fb_report{
						end_time = LastTime + common_tool:now()
					},
					set_report_data(RoleID, ReportRec),
					send_report_to_client(RoleID, ReportRec),
					set_round_data(?THE_FIRST_ROUND),
					call_monster(?THE_FIRST_ROUND, get_this_map_process_name(RoleID)),
					set_fb_timeout(RoleID, LastTime),
					add_enter_times(RoleID),
					%% 完成活动
					hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_MONEY_FB),
					ok;
				false ->
					ReportRec = get_report_data(RoleID),
					send_report_to_client(RoleID, ReportRec)
			end;
		false -> 
			ignore
	end.

hook_role_quit(RoleID) ->
	CurMapId = mgeem_map:get_mapid(),
	case is_role_in_this_map(RoleID, CurMapId) of
		true -> %% 之前退出失败，或是玩家在副本中下线
			do_quit(RoleID);
		false -> ignore
	end,
	case CurMapId == ?MONEY_FB_MAP_ID of
		true  -> common_map:exit(money_fb_quit);
		false -> ignore
	end.

lists_zip(Fun, List1, List2) ->
	lists_zip(Fun, List1, List2, []).

lists_zip(_Fun, [], [], ResultList) -> ResultList;
lists_zip(_Fun, [], _, ResultList) -> ResultList;
lists_zip(_Fun, _, [], ResultList) -> ResultList;
lists_zip(Fun, [E1 | Rest1], [E2 | Rest2], ResultList) ->
	lists_zip(Fun, Rest1, Rest2, [Fun(E1, E2) | ResultList]).

call_monster(Round, MapPID) ->
	Fun = fun({X, Y}, Id) -> {Id, X, Y} end,
	Monsters = lists_zip(Fun, cfg_money_fb:monster_reborn_pos(), cfg_money_fb:round_monsters(Round)),
	global:send(MapPID, {mod_map_monster, {dynamic_create_monster2, Monsters}}),
	ok.

set_fb_timeout(RoleID, LastTime) ->
	Pid = global:whereis_name(get_this_map_process_name(RoleID)),
	TimerRef = erlang:send_after(LastTime*1000, Pid, {?MODULE, {RoleID, fb_timeout}}),
	erlang:put(fb_timeout_timer, TimerRef).

set_collect_timer(RoleID) ->
	Pid = global:whereis_name(get_this_map_process_name(RoleID)),
	TimerRef = erlang:send_after(cfg_money_fb:collect_gold_time()*1000, Pid, {?MODULE, {RoleID, collect_timer}}),
	erlang:put(collect_timer, TimerRef).
cancel_collect_timer() ->
	TimerRef = erlang:erase(collect_timer),
	case TimerRef of
		undefined -> ignore;
		_ -> erlang:cancel_timer(TimerRef)
	end.

%% 客户端一定要请求开始产生钱币，服务端才会有下一步的动作的
do_start_gen_gold(RoleID) ->
	case get_gold_award() of
		undefined -> ?ERROR_MSG("Role ~w has no gold award", [RoleID]);
		_Num -> 
			erase_gold_award(),
			% new_collect(Num),
			set_collect_timer(RoleID)
	end.

%% 采集金币结束后，开始下一回合
collect_timeout(RoleID, MapID) ->
	clear_money_pos(erlang:get(all_money_pos)),
	change_state(RoleID, ?STATE_BEAT_MONSTER),

	AllCollections = [begin erase({collect, PointId}), PointId end || {PointId, _, _} <- mcm:collection_tiles(MapID)],
	common_misc:unicast({role, RoleID}, ?_slice_enter{del_grafts = AllCollections}),
	
	set_round_data(1 + get_round_data()),
	call_monster(get_round_data(), get_this_map_process_name(RoleID)),
	ok.

clear_money_pos(undefined) -> ok;
clear_money_pos([]) -> ok;
clear_money_pos([Key | Rest]) ->
	erlang:erase(Key),
	clear_money_pos(Rest).


send_report_to_client(RoleID, ReportRec) ->
	{NextMaxLianzhan, NextAddAttack} = cfg_money_fb:next_lianzhan(ReportRec#fb_report.max_lianzhan),
	Msg = #m_money_fb_report_toc{
		end_time          = ReportRec#fb_report.end_time,
		total_silver      = ReportRec#fb_report.total_silver,
		kill_boss         = ReportRec#fb_report.kill_boss,
		kill_monster      = ReportRec#fb_report.kill_monster,
		lianzhan          = ReportRec#fb_report.lianzhan,
		max_lianzhan      = ReportRec#fb_report.max_lianzhan,
		add_attack        = cfg_money_fb:lianzhan_add_attack(ReportRec#fb_report.max_lianzhan),
		next_max_lianzhan = NextMaxLianzhan, 
		next_add_attack   = NextAddAttack,
		state             = ReportRec#fb_report.state
	},
	?MOD_UNICAST(RoleID, ?MONEY_FB_REPORT, Msg).

add_enter_times(RoleID) ->
	MoneyFbRec  = get_role_money_fb_rec(RoleID),
	MoneyFbRec1 = MoneyFbRec#r_money_fb{enter_times = MoneyFbRec#r_money_fb.enter_times + 1},
	mod_role_tab:put(RoleID, r_money_fb, MoneyFbRec1),
	ok.

% move_for_silver(_RoleID, TX, TY) ->
% 	case erase({money, TX, TY}) of
% 		PointID when is_integer(PointID) ->
% 			catch mod_map_collect:remove_grafts(?MONEY_FB_MAP_ID, PointID),
% 			cfg_money_fb:round_silver(get_round_data());
% 		_ -> 0
% 	end.

%%%-------------------------------------------------------------------
% handle_event({role, RoleID}, {role_pos_change, TX, TY, _DIR}) ->
% 	ReportRec  = get_report_data(RoleID),
% 	case ReportRec#fb_report.state of
% 		?STATE_COLLECT_MONEY ->
% 			AddSilver1  = move_for_silver(RoleID, TX, TY),
% 			AddSilver2  = move_for_silver(RoleID, TX + 1, TY),
% 			AddSilver3  = move_for_silver(RoleID, TX - 1, TY),
% 			AddSilver4  = move_for_silver(RoleID, TX, TY + 1),
% 			AddSilver5  = move_for_silver(RoleID, TX, TY - 1),
% 			AddSilver6  = move_for_silver(RoleID, TX - 1, TY - 1),
% 			AddSilver7  = move_for_silver(RoleID, TX + 1, TY + 1),
% 			TotalSilver = AddSilver1 + AddSilver2 + AddSilver3 + AddSilver4 + AddSilver5 + AddSilver6 + AddSilver7,
% 			add_silver(RoleID, TotalSilver),
% 			ok;
% 		_ -> ignore
% 	end;

handle_event({role, RoleID}, {monster_dead, _MonsterInfo, MonsterBaseInfo}) ->
	ReportRec  = get_report_data(RoleID),
	case ReportRec#fb_report.state of
		?STATE_COLLECT_MONEY -> ignore;
		_ ->
			IsBoss = (MonsterBaseInfo#p_monster_base_info.rarity == ?BOSS),
			case IsBoss of 
				true -> %% boss死了就把小怪全部删除
					kill_boss(RoleID),
					global:send(get_this_map_process_name(RoleID), {mod_map_monster, {delete_all_monster}}),
					notify_start_money_award(RoleID);
				_ -> 
					%% 小怪会在死后重生
					add_monster_to_reborn_list(MonsterBaseInfo#p_monster_base_info.typeid),
					add_lianzhan(RoleID)
			end,
			case IsBoss of 
				false -> set_next_lianzhan_end_time(?MAX_LIANZHAN_INTERVAL + common_tool:now());
				true  -> set_next_lianzhan_end_time(?MAX_LIANZHAN_INTERVAL + common_tool:now() + cfg_money_fb:collect_gold_time())
			end
	end,
	ok;

handle_event(_Who, _Args) ->
	ignore.

reborn_monster(_RoleID) ->
	case get_reborn_monster_list() of
		[] -> ignore;
		ReadyRebornList ->
			RebornPosList  = cfg_money_fb:monster_reborn_pos(),
			PosListLen = length(RebornPosList),
			Fun = fun({MonsterTypeId, LeftSecond}, {RebornList, ReadyList}) ->
				case LeftSecond > 0 of
					true  -> {RebornList, [{MonsterTypeId, LeftSecond - 1} | ReadyList]};
					false -> 
						{Tx, Ty} = lists:nth(common_tool:random(1, PosListLen), RebornPosList),
						{[{MonsterTypeId, Tx, Ty} | RebornList], ReadyList}
				end
			end,
			{RebornList1, ReadyList1} = lists:foldl(Fun, {[], []}, ReadyRebornList),
			erlang:put(monster_reborn_list, ReadyList1),
			mod_map_monster:handle({dynamic_create_monster2, RebornList1}, mgeem_map:get_state())
	end.

add_monster_to_reborn_list(MonsterTypeId) ->
	RebornList1 = case erlang:get(monster_reborn_list) of
		undefined  -> [{MonsterTypeId, cfg_money_fb:monster_reborn_delay_time()}];
		RebornList -> [{MonsterTypeId, cfg_money_fb:monster_reborn_delay_time()} | RebornList]
	end,
	erlang:put(monster_reborn_list, RebornList1).
get_reborn_monster_list() ->
	case erlang:get(monster_reborn_list) of
		undefined  -> [];
		RebornList -> RebornList
	end.
clear_reborn_monster_list() ->
	erlang:erase(monster_reborn_list).

% new_collect(Count) ->
% 	#map_state{mapid=MapID} = mgeem_map:get_state(),
% 	CollectionTiles = random(mcm:collection_tiles(MapID), [], [], Count),

% 	Fun = fun({PointID, X, Y}) ->
% 		put({money, X, Y}, PointID),
% 		mod_map_collect:new_collect(MapID, PointID, X, Y),
% 		{money, X, Y}
% 	end,
% 	AllMoneyPosList = [Fun(Data) || Data <- CollectionTiles],
% 	erlang:put(all_money_pos, AllMoneyPosList),

% 	RoleID = get(map_owner),
% 	#p_pos{tx = TX, ty = TY} = mod_map_actor:get_actor_pos(RoleID, role),
% 	OffsetX   = mcm:offset_x(MapID),
% 	OffsetY   = mcm:offset_y(MapID), 
% 	AllSlices = mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY),
% 	Collects  = mod_map_collect:get_collect_by_slice_list(AllSlices),
% 	common_misc:unicast({role, RoleID}, ?_slice_enter{grafts = Collects}).

% random(_Collections, Satisfying, _NotSatisfying, 0) ->
% 	Satisfying;
% random([], Satisfying, NotSatisfying, Count) ->
% 	Satisfying ++ lists:sublist(NotSatisfying, Count);
% random([Collection|T], Satisfying, NotSatisfying, Count) ->
% 	case random:uniform(2) of
% 		R when R < 2 ->
% 			random(T, [Collection|Satisfying], NotSatisfying, Count-1);
% 		_ ->
% 			random(T, Satisfying, [Collection|NotSatisfying], Count)
% 	end.

% add_silver(RoleID, AddSilver) ->
% 	case AddSilver > 0 of
% 		true ->
% 			ReportRec  = get_report_data(RoleID),
% 			ReportRec1 = ReportRec#fb_report{total_silver = ReportRec#fb_report.total_silver + AddSilver},
% 			set_report_data(RoleID, ReportRec1),
% 			send_report_to_client(RoleID, ReportRec1),
% 			common_bag2:add_money(RoleID, silver_bind, AddSilver, ?CONSUME_TYPE_SILVER_MONEY_FB),
% 			ok;
% 		false -> ignore
% 	end.

add_lianzhan(RoleID) ->
	ReportRec  = get_report_data(RoleID),
	case is_lianzhan_timeout() of
		false ->
			ReportRec1 = ReportRec#fb_report{
				lianzhan     = ReportRec#fb_report.lianzhan + 1,
				kill_monster = ReportRec#fb_report.kill_monster + 1
			},
			case ReportRec1#fb_report.lianzhan > ReportRec#fb_report.max_lianzhan of
				true  -> ReportRec2 = ReportRec1#fb_report{max_lianzhan = ReportRec1#fb_report.lianzhan};
				false -> ReportRec2 = ReportRec1
			end;
		true ->
			ReportRec2 = ReportRec#fb_report{lianzhan = 1}
	end,
	add_attack_buf(RoleID, ReportRec2#fb_report.max_lianzhan),
	set_report_data(RoleID, ReportRec2),
	send_report_to_client(RoleID, ReportRec2),
	case cfg_money_fb:can_add_nuqi(ReportRec2#fb_report.lianzhan) of
		false -> ignore;
		AddNuqi -> 
			mod_map_role:add_nuqi(RoleID, AddNuqi),
            common_misc:send_common_error(RoleID, 0, 
            	common_misc:format_lang(<<"恭喜玩家当前连斩数达到~w，系统赠送怒气~w">>, 
            								[ReportRec2#fb_report.lianzhan, AddNuqi]))
	end,
	ok.

add_attack_buf(RoleID, NewMaxLianzhan) ->
	case cfg_money_fb:lianzhan_buf(NewMaxLianzhan) of
		0 -> ignore;
		BufId ->
			OldBufId = erlang:get(attack_buf),
			case OldBufId == BufId of
				true  -> ignore;
				false ->
					erlang:put(attack_buf, BufId),
					remove_attack_buf(RoleID, OldBufId),
					mod_role_buff:add_buff(RoleID, [BufId]),
					ok
			end
	end.

remove_attack_buf(RoleID) ->
	remove_attack_buf(RoleID, erlang:get(attack_buf)).
remove_attack_buf(RoleID, BufId) when is_integer(BufId)  ->
	[#p_buf{buff_type = BuffType}] = common_config_dyn:find(buffs,BufId),
	mgeer_role:send(RoleID, {mod_map_role, {remove_buff, RoleID, RoleID, role, BuffType}});
remove_attack_buf(_RoleID, _BufId)  -> ignore.


is_lianzhan_timeout() ->
	(get_next_lianzhan_end_time() < common_tool:now()).
set_next_lianzhan_end_time(NextTime) ->
	erlang:put(next_lianzhan_end_time, NextTime).
get_next_lianzhan_end_time() ->
	erlang:get(next_lianzhan_end_time).


kill_boss(RoleID) ->
	GainMoney = cfg_money_fb:kill_boss_silver(get_round_data()),
	common_bag2:add_money(RoleID, silver_bind, GainMoney, ?CONSUME_TYPE_SILVER_MONEY_FB),
	ReportRec = get_report_data(RoleID),
	ReportRec1 = ReportRec#fb_report{
		kill_boss    = ReportRec#fb_report.kill_boss + 1,
		total_silver = ReportRec#fb_report.total_silver + GainMoney
	},
	set_report_data(RoleID, ReportRec1),
	send_report_to_client(RoleID, ReportRec1),
	ok.

notify_start_money_award(RoleID) ->
	Num        = common_tool:random(50, 99),
	set_gold_award(Num),
	% Msg        = #m_money_fb_start_silver_toc{num = Num},
	% ?MOD_UNICAST(RoleID, ?MONEY_FB_START_SILVER, Msg),

	change_state(RoleID, ?STATE_COLLECT_MONEY),

	GatewayPid = global:whereis_name(common_misc:get_role_line_process_name(RoleID)),
	% GatewayPid ! {debug, ?DEFAULT_UNIQUE, ?MONEY_FB, ?MONEY_FB_START_SILVER, #m_money_fb_start_silver_tos{}},
	GatewayPid ! {router_to_map, {?DEFAULT_UNIQUE, ?MONEY_FB, ?MONEY_FB_START_SILVER, #m_money_fb_start_silver_tos{}, RoleID, null, 0}},
	% common_misc:send_to_map(RoleID, {?DEFAULT_UNIQUE, ?MONEY_FB, ?MONEY_FB_START_SILVER, #m_money_fb_start_silver_tos{}, RoleID, null, 0}),
	ok.

change_state(RoleID, State) ->
	ReportRec  = get_report_data(RoleID),
	ReportRec1 = ReportRec#fb_report{state = State},
	set_report_data(RoleID, ReportRec1),
	send_report_to_client(RoleID, ReportRec1).

%% =========================================================================
%% =========================================================================
%% 设置玩家处于这个副本的标识
set_role_in_this_map_flag(RoleID) ->
	mod_role_tab:put(RoleID, role_in_money_fb_flag, true).
erase_role_in_this_map_flag(RoleID) ->
	mod_role_tab:erase(RoleID, role_in_money_fb_flag).
get_role_in_this_map_flag(RoleID) ->
	mod_role_tab:get(RoleID, role_in_money_fb_flag).
%% 设置玩家进入该副本前的位置，以便退出时获取
set_return_pos(RoleID, EnterMapId, EnterPos) ->
	mod_role_tab:put(RoleID, money_fb_return_pos, {EnterMapId, EnterPos}).
get_return_pos(RoleID) ->
	mod_role_tab:get(RoleID, money_fb_return_pos).
erase_return_pos(RoleID) ->
	mod_role_tab:erase(RoleID, money_fb_return_pos).
%% 设置摇奖开出了多少个金币
set_gold_award(Num) ->
	erlang:put(gold_award, Num).
get_gold_award() ->
	erlang:get(gold_award).
erase_gold_award() ->
	erlang:erase(gold_award). 
%% 设置目前是第几回合的怪了
set_round_data(Round) -> erlang:put(round_data, Round).
%% 获取目前已
get_round_data() -> erlang:get(round_data).
%% 设置战报数据
set_report_data(_RoleID, ReportRec) ->
	erlang:put(money_fb_report, ReportRec).
get_report_data(_RoleID) ->
	erlang:get(money_fb_report).
%% =========================================================================
%% =========================================================================

