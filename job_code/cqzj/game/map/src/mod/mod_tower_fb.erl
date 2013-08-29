%% Author: Administrator
%% Created: 2012-12-17
%% Description: TODO: Add description to mod_tower_fb
-module(mod_tower_fb).

%%
%% Include files
%%
-include("mgeem.hrl").

-define(NORMAL_ENTER, 0).
-define(EXTRA_ENTER, 1).
-define(default_tower_mapid, 105001).
-define(tower_fb_config, tower_fb).
-define(tower_fb_quit_type_normal, 0).%%过关退出
-define(tower_fb_quit_type_relive, 1).%%超时并且死亡退出
-define(tower_fb_quit_type_timeout, 2).%%超时退出
-define(tower_fb_quit_type_succ, 3).%%胜利退出
-define(tower_fb_quit_type_roleself, 4).%%玩家主动退出
-define(tower_fb_info, tower_fb_info).
-define(max_level, lists:nth(1, common_config_dyn:find(tower_fb, max_level))).%%玄冥塔最高层数
%% 副本完成
-define(fb_quit_status_finish, 0).
%% 副本失败
-define(fb_quit_status_fail, 1).
-define(ERR_NOT_ENOUGH_GOLD_ENTER_TOWER_FB, 128001).%%进入地狱熔炉所需元宝不足
-define(ERR_TODDAY_IS_ALREADY_REWARD, 128002).%%亲，今天已经领取过挑战奖励了，请明天再来
-define(ERR_NOT_ENOUGH_BAG_POSITION, 128003).%%背包空间不足，请稍后再来
-define(ERR_CAN_NOT_ENTER_TOWER_FB, 128004).%%亲，您领取了奖励，明天再来挑战吧
-define(ERR_NOT_ENOUGH_VIP_LEVEL_3, 128005).%%vip3以上才能从失败关卡开始
-define(ERR_THE_CHALLENGE_BARRIER_NOT_OPEN, 128006).%%挑战的关卡暂未开启
-define(ERR_NOT_ENOUGH_ROLE_LEVEL, 128007).%%亲，玄冥塔危险重重，30级以后再来吧
-define(ERR_FB_MAP_CANNOT_ENTER_TOWER_FB, 128008).%%在副本地图中不能进入玄冥塔副本.
-define(ERR_FB_MAP_CANNOT_QUIT_TOWER_FB, 128009).%%只有在玄冥塔副本中才能主动退出.
-define(ERR_FB_MIN_LEVEL_REWARD, 128010).%%通过最低关卡才能领奖
-define(ERR_FB_QUJING_CAN_NOT_ENTER, 128011).%%唐僧取经任务中，不能进入玄冥塔


%%
%% Exported Functions
%%
-export([handle/1,
		 handle/2,
		 init/2,
		 do_terminate/0,
		 hook_role_enter/2,
		 hook_role_quit/1,
		 assert_valid_map_id/1,
		 get_map_name_to_enter/1,
		 get_role_tower_fb_map_name/2,
		 clear_map_enter_tag/1,
		 hook_monster_dead/2,
		 quit_tower_fb/2,
		 hook_role_dead/1,
		 is_tower_fb_map_id/1,
		 get_role_tower_fb_info/1,
		 update_role_tower_info/2,
		 set_role_tower_fb_info/2]).

%%
%% API Functions
%%
handle(Info,_State) ->
	handle(Info).

handle({_, ?TOWER_FB, ?TOWER_FB_ENTER,_,_,_,_}=Info) ->
	%% 进入地狱熔炉
	do_tower_fb_enter(Info);

handle({_, ?TOWER_FB, ?TOWER_FB_QUIT,_,_,_,_}=Info) ->
	%% 退出地狱熔炉
	do_tower_quit(Info);

handle({_, ?TOWER_FB, ?TOWER_FB_INFO,_,_,_,_}=Info) ->
	do_tower_info(Info);

handle({_, ?TOWER_FB, ?TOWER_FB_REWARD,_,_,_,_}=Info) ->
	do_tower_reward(Info);

handle({_, ?TOWER_FB, ?TOWER_FB_CMZ,_,_,_,_}=Info) ->
	do_tower_cmz(Info);

%%mgeem_router异步创建地图后发送的消息，在这里处理
handle({create_map_succ,RoleID}) ->
	do_async_create_map(RoleID);

handle({init_tower_fb_map_info, RoleTowerFbInfo}) ->
	init_tower_fb_map_info(RoleTowerFbInfo);

handle({fb_timeout_kick, RoleID}) ->
	do_fb_timeout_kick(RoleID);

handle({offline_terminate}) ->
	do_offline_terminate();

handle({enter_tower_fb,Unique, Module, Method, DataIn, RoleID, PID}) ->
	enter_tower_fb(Unique, Module, Method, DataIn, RoleID, PID);

handle(Info) ->
	?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE, Info]).

%%
%% Local Functions
%%
%% 进入地狱熔炉
do_tower_fb_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	%%记录进入副本的方式
	#m_tower_fb_enter_tos{enter_type = EnterType, barrier_id = BarrierID} = DataIn,
	case catch check_can_enter_tower_fb(RoleID, EnterType, BarrierID) of
		ok ->
			case EnterType of
				?EXTRA_ENTER ->
					common_misc:send_to_rolemap(RoleID, {mod_tower_fb, {enter_tower_fb, Unique, Module, Method, DataIn, RoleID, PID}});
				_ ->
					enter_tower_fb(Unique, Module, Method, DataIn, RoleID, PID)
			end;
		{error, ErrCode, ErrReason} ->
			ResultRecord = #m_tower_fb_enter_toc{succ = false, err_code = ErrCode, reason = ErrReason},
			common_misc:unicast({role, RoleID}, Unique, Module, Method, ResultRecord)
	end.

enter_tower_fb(Unique, Module, Method, DataIn, RoleID, PID) ->
	#m_tower_fb_enter_tos{barrier_id = BarrierID} = DataIn,
	{ok, RoleTowerFbInfo} = get_role_tower_fb_info(RoleID),
	RoleTowerFbMapName = get_role_tower_fb_map_name(RoleID, BarrierID),
	case  global:whereis_name(RoleTowerFbMapName) of
		undefined ->
			create_tower_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName});
		_ ->
			enter_tower_fb_map(Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName)
	end.

%%检查进入条件是否满足
check_can_enter_tower_fb(RoleID, EnterType, BarrierID) ->
	assert_role_map(),
	assert_role_level(RoleID),
	assert_reward_date(RoleID),
	assert_role_gold(RoleID, EnterType, BarrierID),
	assert_barrier(EnterType, BarrierID),
	assert_qujing(RoleID).

assert_qujing(RoleID) ->
	case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
		true ->%%取经中，不能进入
			?THROW_ERR(?ERR_FB_QUJING_CAN_NOT_ENTER);
		false ->
			ok
	end.

%%玩家所在地图检查
assert_role_map() ->
	MapID = mgeem_map:get_mapid(),
	case common_config_dyn:find(fb_map, MapID) =:= [] orelse is_tower_fb_map_id(MapID) of
		true ->
			ignore;
		false ->
			?THROW_ERR(?ERR_FB_MAP_CANNOT_ENTER_TOWER_FB)
	end.

%%检查等级
assert_role_level(RoleID) ->
	case mod_map_role:get_role_attr(RoleID) of
		{ok, #p_role_attr{level = RoleLevel}} ->
			next;
		_ ->%%会执行到这里的原因可能是因为玩家本来可以进入下一关，但是在等候的30秒过程中下线了
			RoleLevel = 0
	end,
	MinRoleLevel = get_tower_fb_config(min_role_level),
	case RoleLevel < MinRoleLevel of
		true ->
			?THROW_ERR(?ERR_NOT_ENOUGH_ROLE_LEVEL);
		false ->
			ok
	end.

%%判断挑战的关卡是否开启
assert_barrier(EnterType, BarrierID) ->
	case BarrierID - ?max_level > 0 of
		true ->
			?THROW_ERR(?ERR_THE_CHALLENGE_BARRIER_NOT_OPEN);
		false ->
			ok
	end,
	CurMapID = mgeem_map:get_mapid(),
	case is_tower_fb_map_id(CurMapID) of
		false ->
			case EnterType =:= ?NORMAL_ENTER andalso BarrierID =/= 1 of
				true ->
					?THROW_ERR(?ERR_NOT_ENOUGH_VIP_LEVEL_3);
				false ->
					ok
			end;
		true ->
			ok
	end.

%%判断今天是否领取了奖励
assert_reward_date(RoleID) ->
	{ok, #r_role_tower_fb{last_reward_date = LRD}} = get_role_tower_fb_info(RoleID),
	case LRD =:= date() of
		true ->
			?THROW_ERR(?ERR_CAN_NOT_ENTER_TOWER_FB);
		false ->
			ok
	end.

%%检查元宝是否足够
assert_role_gold(RoleID, EnterType, BarrierID) ->
	case EnterType of
		?NORMAL_ENTER ->
			ok;
		?EXTRA_ENTER ->
            NeedGold = get_tower_fb_config({enter, BarrierID}),
            F = fun() ->
            			common_bag2:t_deduct_money(gold_unbind, NeedGold, RoleID, ?CONSUME_TYPE_GOLD_TOWER_FB_ENTER)
            	end,
            case common_transaction:t(F) of
            	{atomic, {ok, RoleAttr}} ->
            		%%由于切换地图，所以，直接通知玩家进程修改玩家属性
            		common_misc:send_role_gold_change(RoleID, RoleAttr),
            		ok;
            	{atomic, {error, _Reason}} ->
            		?THROW_ERR(?ERR_GOLD_NOT_ENOUGH);
            	{aborted, {error, _ErrCode, _Reason}} ->
            		?THROW_ERR(?SYSTEM_ERROR)
            end
	end.

%%创建地狱熔炉地图
create_tower_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName}) ->
	case global:whereis_name(RoleTowerFbMapName) of
		undefined ->
			BarrierMapID = ?default_tower_mapid + BarrierID - 1,
			mod_map_copy:async_create_copy(BarrierMapID, RoleTowerFbMapName, ?MODULE, RoleID),
			log_async_create_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName});
		_PID ->
			enter_tower_fb_map(Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName)
	end.

%%获取玩家的地狱熔炉地图名称
get_role_tower_fb_map_name(RoleID, BarrierID) ->
	lists:concat(["tower_fb_map_", BarrierID, "_",RoleID]).

log_async_create_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName}) ->
	erlang:put({tower_fb_roleid, RoleID}, {Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName}).

%%玩家进入地狱熔炉地图
enter_tower_fb_map(_Unique, _Module, _Method, RoleID, _PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName) ->
	CurMapID = mgeem_map:get_mapid(),
	case CurMapID =:= ?default_tower_mapid + BarrierID - 1 of
		true ->%%当前地图正是要进入的地图
			next;
		false ->%%不是当前地图，进入地图，只需要记录进入的关卡，时间和进入前的地图信息
			case is_tower_fb_map_id(CurMapID) of
				true ->%%从地狱熔炉中进入到此地图
					NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{last_challenge_time = now(),
																		 last_challenge_level = BarrierID};
				false ->%%从其他地图进入到地狱熔炉
					case mod_map_actor:get_actor_pos(RoleID, role) of
						undefined ->
							NewRoleTowerFbInfo = RoleTowerFbInfo;
						Pos ->
							NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{enter_pos = Pos, enter_mapid = CurMapID, last_challenge_time = now(),
																				 last_challenge_level = BarrierID}
					end
			end,
			set_role_tower_fb_info(RoleID, NewRoleTowerFbInfo),
		%%	hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_TOWER_FB),
			global:send(RoleTowerFbMapName, {?MODULE, {init_tower_fb_map_info, NewRoleTowerFbInfo}}),
			%% 传送到新地图
			BarrierMapID = ?default_tower_mapid + BarrierID - 1,
			{_, TX, TY} = common_misc:get_born_info_by_map(BarrierMapID),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, BarrierMapID, TX, TY)
	end.

is_tower_fb_map_id(MapID) ->
	MapID >= ?default_tower_mapid andalso MapID < ?default_tower_mapid + 100.




%%退出地狱熔炉副本
do_tower_quit({Unique, Module, Method, DataIn, RoleID, _PID, Line}) ->
	case catch check_can_quit_tower_fb(RoleID) of
		ok ->
			recover_role_state(RoleID, DataIn),
			update_role_tower_info(RoleID),
			quit_tower_map(RoleID, DataIn);
		{error, ErrCode, ErrReason} ->
			DataRecord = #m_tower_fb_quit_toc{succ = false, err_code = ErrCode, reason = ErrReason},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord)
	end.

%%检查是否符合退出条件
check_can_quit_tower_fb(RoleID) ->
	case mod_map_actor:get_actor_mapinfo(RoleID, role) of
		undefined ->
			?THROW_ERR(?SYSTEM_ERROR);
		_ ->
			ok
	end,
	%%预防玩家在玄冥塔副本外退出
	MapID = mgeem_map:get_mapid(),
	BarrierID = MapID - ?default_tower_mapid + 1,
	case BarrierID >= 1 andalso BarrierID =< ?max_level of
		true ->
			ok;
		false ->
			?THROW_ERR(?ERR_FB_MAP_CANNOT_QUIT_TOWER_FB)
	end.

%%退出副本操作
quit_tower_map(RoleID, DataIn) ->
	#m_tower_fb_quit_tos{quit_type = QuitType} = DataIn,
	ResultRecord = #m_tower_fb_quit_toc{quit_type = QuitType},
	{ok, #r_role_tower_fb{enter_pos = EnterPos,enter_mapid = EnterMapID}} = get_role_tower_fb_info(RoleID),
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_QUIT, ResultRecord),
	case is_record(EnterPos, p_pos) andalso erlang:is_integer(EnterMapID) andalso EnterMapID > 0 of
		true->
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, EnterMapID, EnterPos#p_pos.tx, EnterPos#p_pos.ty);
		false->
			{MapID, TX, TY} = common_misc:get_home_born(),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapID, TX, TY)
	end.

%%退出副本后，恢复角色状态
recover_role_state(RoleID, DataIn) ->
	#m_tower_fb_quit_tos{quit_type = QuitType} = DataIn,
	case QuitType of
		%% 在副本超时并死亡退出
		?tower_fb_quit_type_relive ->
			relive_role(RoleID);
		?tower_fb_quit_type_roleself ->
			%%得到玩家状态，如果死亡，则在退出副本时候先复活
			case mod_map_actor:get_actor_mapinfo(RoleID,role) of
				#p_map_role{state = ?ROLE_STATE_DEAD} ->
					relive_role(RoleID);
				_ ->
					next
			end;
		%% 其他退出
		_ ->
			ignore
	end.

%%重新设置玩家的玄冥塔信息
update_role_tower_info(RoleID) ->
	MapID = mgeem_map:get_mapid(),
	BarrierID = MapID - ?default_tower_mapid + 1,
	update_role_tower_info(RoleID, BarrierID).

update_role_tower_info(RoleID, BarrierID) ->
	{ok, RoleTowerFbInfo} = get_role_tower_fb_info(RoleID),
	%%首先判断玩家此次挑战是否为今天第一次挑战，如果是，则吧此次挑战累积积分添加到reward_list，如果不是，则吧此次挑战累积积分覆盖掉reward_list的头元素
	#r_role_tower_fb{last_challenge_date = LCD, reward_list = RewardList, score_list = ScoreList, best_score = BestScore,
					 best_level = BestLevel, challenge_time_list = CTL} = RoleTowerFbInfo,
	TotalScore = cacl_total_score(ScoreList, BarrierID, quit),
	case LCD =:= date() of
		true ->
			%%除去奖励列表是空的情况
			case RewardList of
				[] ->
					TodayBestScore = 0,
					T = [];
				_ ->
					[TodayBestScore | T] = RewardList
			end,
			case TotalScore >= TodayBestScore of
				true ->%%这一次挑战是整天最好的
					NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{reward_list = [TotalScore | T], last_challenge_date = date()};
				false ->%%这一次挑战不是整天最好的
					NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{last_challenge_date = date()}
			end;
		false ->
			NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{reward_list = [TotalScore | RewardList], last_challenge_date = date()}
	end,
	%%判断是否是最好成绩,如果是，更新最好成绩
	case BestScore < TotalScore of
		true ->
			NewRoleTowerFbInfo1 = NewRoleTowerFbInfo#r_role_tower_fb{best_score = TotalScore};
		false ->
			NewRoleTowerFbInfo1 = NewRoleTowerFbInfo
	end,
	%%替换个人最好关卡	
	case length(ScoreList) < BestLevel of
		true ->
			NewRoleTowerFbInfo2 = NewRoleTowerFbInfo1;
		false ->
			NewBestLevel = length(ScoreList),
			NewRoleTowerFbInfo2 = NewRoleTowerFbInfo1#r_role_tower_fb{best_level = NewBestLevel},
			case length(CTL) < NewBestLevel orelse NewBestLevel =:= 0 of
				true ->
					?ERROR_MSG("tower fb error, ~w, ~w, ~w, ~w", [CTL, NewBestLevel, ScoreList, RoleID]);
				false ->
					%%发送消息，申请替换最好成绩
					global:send(mod_tower_fb_manager, {replace, NewBestLevel, lists:nth(NewBestLevel, CTL), RoleID})
			end
	end,
	set_role_tower_fb_info(RoleID, NewRoleTowerFbInfo2).

%%计算玩家退出时的，这一次挑战的得分
cacl_total_score(ScoreList, BarrierID, quit) ->
	%%本次挑战得分计算方法：1、得到次关卡之前的关卡得分总和，2、判断本关是否通关，如果通关，本次挑战得分为，之前关卡的得分总和+本关得分，否则为，之前关卡得分总和
	case BarrierID > (length(ScoreList) + 1) of
		true ->
			H = ScoreList,
			T = [];
		false ->
			{H, T} = lists:split(BarrierID - 1, ScoreList)
	end,
	Length = length(mod_map_monster:get_monster_id_list()) - 1,
	case Length =< 0 of
		true ->%%当前关卡通关了
			case T of
				[] ->
					TH = 0;
				_ ->
					[TH | _] = T
			end,
			lists:sum(H) + TH;
		false ->%%当前关卡没有通关
			lists:sum(H)
	end.

%%计算玩家达到指定关卡时的积分
cacl_total_score(ScoreList, BarrierID) ->
	%%本次挑战得分计算方法：1、得到次关卡之前的关卡得分总和，2、判断本关是否通关，如果通关，本次挑战得分为，之前关卡的得分总和+本关得分，否则为，之前关卡得分总和
	case length(ScoreList) < BarrierID -1 of
		true ->%%好吧，兼容一下
			lists:sum(ScoreList);
		false ->
			{H, _T} = lists:split(BarrierID - 1, ScoreList),
			lists:sum(H)
	end.

%%复活角色
relive_role(RoleID) ->
	mod_role2:do_relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_FREE, mgeem_map:get_state()).



%%地狱熔炉信息接口
do_tower_info({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
	{ok, #r_role_tower_fb{best_score = BS, reward_list = RewardList, last_challenge_date = LCD,
						  best_level = BestLevel, last_challenge_level = LCL, time_list = TL,
						  last_reward_date = LRD, challenge_time_list = CTL, cmz = CMZ}} = get_role_tower_fb_info(RoleID),
	%%根据当前积分列表，计算玩家当前的奖励物品列表
	F = fun(Score, AccIn) ->
				case Score =:= 0 of
					true ->
						AccIn;
					false ->
						RewardPropList = get_tower_fb_config({reward, (Score div 1001 + 1) * 1000}),
						lists:append(RewardPropList, AccIn)
				end
		end,
	PropList = lists:foldl(F, [], RewardList),
	%%整理道具列表
	NewPropList = merge_reward_props(PropList),
	%%返回今天是否有领过奖励0-没有领过奖励，1-已经领过奖励
	case LRD =:= date() of
		true ->
			ChallengeState = 1;
		false ->
			ChallengeState = 0
	end,
	%%找出上次挑战时间和最好挑战纪录
	case CTL =/= [] andalso LCL - 1 =< length(CTL) andalso LCL - 1 > 0 of
		true ->
			BestTime = lists:nth(erlang:min(BestLevel, length(CTL)), CTL),%%暂时防御
			LastChallengeTime = lists:nth(LCL - 1, TL);
		false ->
			case BestLevel =< length(CTL) andalso BestLevel =/= 0 of
				true ->
					BestTime = lists:nth(BestLevel, CTL);
				false ->
					BestTime = 0
			end,
			LastChallengeTime = 0
	end,
	%%去除是0的情况
	case LCL =:= 0 of
		true ->
			NewLCL = 0;
		false ->
			NewLCL = LCL -1
	end,
	%%今天没有挑战，除魔值显示0
	case LCD =:= date() of
		true ->
			NewBS = BS;
		false ->
			NewBS = 0
	end,
	ResultRec = #m_tower_fb_info_toc{best_level = BestLevel, best_score = NewBS, best_time = BestTime,
									 reward_list = NewPropList, challenge_state = ChallengeState, last_challenge_level = NewLCL,
									 last_challenge_time = LastChallengeTime, cmz = CMZ},
	?UNICAST_TOC(ResultRec).




%%地狱熔炉领取奖励接口
do_tower_reward({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
	{ok, #r_role_tower_fb{reward_list = RewardList, last_challenge_date = LCD, last_challenge_level = LCL, cmz = CMZ}
							 = RoleTowerFbInfo} = get_role_tower_fb_info(RoleID),
	case catch check_can_reward(RoleID, RewardList) of
		{error, ErrCode, Reason} ->
			?UNICAST_TOC(#m_tower_fb_reward_toc{succ = false, err_code = ErrCode, reason = Reason});
		{error, Error} when is_binary(Error) ->
			?UNICAST_TOC(#m_tower_fb_reward_toc{succ = false, err_code = 2, reason = Error});
		_ ->
			MinRewardLevel = get_tower_fb_config(min_reward_level),
			case LCL < MinRewardLevel of
				true ->
					?UNICAST_TOC(#m_tower_fb_reward_toc{succ = false, err_code = ?ERR_FB_MIN_LEVEL_REWARD});
				false ->
					%%根据历史积分，获得奖励道具列表
					F = fun(Score, AccIn) ->
								case Score =:= 0 of
									true ->
										AccIn;
									false ->
										RewardPropList = get_tower_fb_config({reward, (Score div 1001 + 1) * 1000}),
										lists:append(RewardPropList, AccIn)
								end
						end,
					PropList = lists:foldl(F, [], RewardList),
					%%整理道具列表
					NewPropList = merge_reward_props(PropList),
					%%将奖励道具发送到玩家的背包中
					G = fun() ->
								common_bag2:t_reward_prop(RoleID, NewPropList)
						end,
					case common_transaction:t(G) of
						{atomic, {ok, NewGoodsList}} ->
						%	hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_TOWER_FB),
							%%通知物品改变
							common_misc:update_goods_notify({role, RoleID}, NewGoodsList),
							%%道具获得日志
							K = fun(Reward) ->
										TypeID = Reward#p_reward_prop.prop_id,
										Num = Reward#p_reward_prop.prop_num,
										?TRY_CATCH(common_item_logger:log(RoleID, TypeID, Num, undefined, ?LOG_ITEM_TYPE_TOWER_REWARD))
								end,
							lists:foreach(K, NewPropList),
							%%改变领奖日期，领奖时间为上一次挑战日期，因为领奖是领取累积到上一次挑战日期的奖励之和
							NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{reward_list = [], last_reward_date = LCD, cmz = CMZ + lists:sum(RewardList)},
							set_role_tower_fb_info(RoleID, NewRoleTowerFbInfo),
							?UNICAST_TOC(#m_tower_fb_reward_toc{succ = true}),
							do_tower_info({Unique, Module, ?TOWER_FB_INFO, _DataIn, RoleID, PID, _Line});
						{aborted, {error, ErrCode, ErrReason}} ->
							?UNICAST_TOC(#m_tower_fb_reward_toc{succ = false, err_code = ErrCode, reason = ErrReason});
						{aborted, {bag_error, {not_enough_pos, _}}} ->
							?UNICAST_TOC(#m_tower_fb_reward_toc{succ = false, err_code = ?ERR_NOT_ENOUGH_BAG_POSITION})
					end
			end
	end.

check_can_reward(_RoleID, RewardList) ->
	case RewardList =:= [] of
		true ->%%没有奖励，返回错误
			?THROW_ERR(?ERR_TODDAY_IS_ALREADY_REWARD);
		false ->
			next
	end.
	%%判断是否在主线任务1026129中
%%	mod_mission_misc:is_doing_tower_fb_mission(RoleID).


%%异步创建地图
do_async_create_map(RoleID) ->
	case get_async_create_map_info(RoleID) of
		undefined ->
			ignore;
		{Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName} ->
			enter_tower_fb_map(Unique, Module, Method, RoleID, PID, RoleTowerFbInfo, BarrierID, RoleTowerFbMapName)
	end.

get_async_create_map_info(RoleID) ->
	erlang:erase({tower_fb_roleid, RoleID}).




do_fb_timeout_kick(RoleID) ->
	%%到了副本上限时间，如果怪已经全部打完，说明玩家已经通关，则不做处理，否则，说明玩家没有过关，直接踢出
	Length = length(mod_map_monster:get_monster_id_list()) - 1,
	case Length < 0 of
		true ->
			ignore;
		false ->
			case mod_map_actor:get_actor_mapinfo(RoleID, role) of
				#p_map_role{state = ?ROLE_STATE_DEAD} ->
					DataIn = #m_tower_fb_quit_tos{quit_type = ?tower_fb_quit_type_relive};
				_ ->
					DataIn = #m_tower_fb_quit_tos{quit_type = ?tower_fb_quit_type_timeout}
			end,
			Line = common_misc:get_role_line_by_id(RoleID),
			do_tower_quit({?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_QUIT, DataIn, RoleID, self(), Line})
	end.

hook_role_dead([RoleID, _SActorID, _SActorType]) ->
	case is_tower_fb_map_id(mgeem_map:get_mapid()) of
		true ->
			%%死亡，默认为失败，这里调用超时退出的方法
			erlang:send_after(2 * 1000, self(), {?MODULE, {fb_timeout_kick, RoleID}});
		false ->
			ignore
	end.

%%hook_map_monster回调函数
hook_monster_dead(RoleID, MapID) ->
	case erlang:get(?tower_fb_info) of
		undefined ->
			ignore;
		_ ->
			BarrierID = MapID - ?default_tower_mapid + 1,
			check_is_all_monster_dead(RoleID, BarrierID)
	end.

%%检测怪物是否全部杀死，如果是，进入下一关，否则，忽略
check_is_all_monster_dead(RoleID, BarrierID) ->
	Length = length(mod_map_monster:get_monster_id_list()) - 1,
	case Length =< 0 of
		true ->
			%%记录下这一关的挑战时间和累加积分
			role_challenge_win(RoleID, BarrierID),
			ok;
		false ->
			ignore
	end.

%%玩家在当前关卡获胜
role_challenge_win(RoleID, BarrierID) ->
	{ok, #p_role_attr{role_name=_RoleName,level = _RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	{ok, #r_role_tower_fb{last_challenge_time = LCT, score_list = ScoreList, challenge_time_list = CTL, last_challenge_level = LCL, time_list = TL} = 
							 RoleTowerFbInfo} = get_role_tower_fb_info(RoleID),
	DiffTime = common_misc:diff_time(now(), LCT),
	global:send(mod_tower_fb_manager, {replace, {BarrierID, DiffTime, RoleID}}),
	%%根据barrierid更新玩家的积分列表，首先获取barrierid之前的积分列表，然后把当前关卡最新积分添加进去
	NewScore = calc_score(BarrierID, DiffTime),
	{NewScoreList, NewCTL, NewTL} = replace_challenge_list(BarrierID, ScoreList, NewScore, CTL, DiffTime, TL),
	case lists:sum(NewScoreList) < 0 of
		true ->%%有一次发现程序会执行到这里，为什么，抓个数据分析一下先
			?ERROR_MSG("tower fb score error, RoleID:~w, NewScoreList:~w, NewCTL:~w, BarrierID:~w, ScoreList:~w, NewScore:~w,
						CTL:~w, DiffTime:~w", [RoleID, NewScoreList, NewCTL, BarrierID, ScoreList, NewScore, CTL, DiffTime]);
		false ->
			ignore
	end,
	NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{score_list = NewScoreList, challenge_time_list = NewCTL, last_challenge_level = LCL + 1, time_list = NewTL},
	set_role_tower_fb_info(RoleID, NewRoleTowerFbInfo),
	%%如果不是最高关卡，发送消息进入下一关，否则，退出
	case BarrierID =:= ?max_level of
		true ->
			%%把玩家达到最后一层的数据记录下来
			DataIn = #m_tower_fb_quit_tos{quit_type = ?tower_fb_quit_type_succ},
			Line = common_misc:get_role_line_by_id(RoleID),
			%%因为显示的原因，这里延迟一秒退出
			timer:apply_after(1000, mod_tower_fb, update_role_tower_info, [RoleID, BarrierID]),
			erlang:send_after(1000, self(), {?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_QUIT, DataIn, RoleID, self(), Line});
		false ->
			Line = common_misc:get_role_line_by_id(RoleID),
			%%因为前端显示原因，延迟2秒弹出显示框
			NextSeconds = get_tower_fb_config({next_seconds, BarrierID}),
			ResultRecord = #m_tower_fb_quit_toc{quit_type = ?tower_fb_quit_type_normal, barrier_id = BarrierID, next_seconds = NextSeconds},
			timer:apply_after(1000, mod_tower_fb, update_role_tower_info, [RoleID, BarrierID]),
			timer:apply_after(2000, common_misc, unicast, [{role, RoleID}, ?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_QUIT, ResultRecord]),
			%%30秒之后，进入下一关卡
			DataIn = #m_tower_fb_enter_tos{enter_type = ?NORMAL_ENTER, barrier_id = BarrierID + 1},
			erlang:send_after((NextSeconds + 2) * 1000, self(), {?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_ENTER, DataIn, RoleID, self(), Line})
	end.
%%  mod_role_activity:hook_value_change(RoleID, BarrierID, ?role_activity_9),
%%	mgeew_open_activity:hook_open_activity_change(?OPEN_ACTIVITY_TYPE_11, RoleID, RoleName, BarrierID).

%%初始化副本信息
init_tower_fb_map_info(RoleTowerFbInfo) ->
	erlang:put(?tower_fb_info, RoleTowerFbInfo).

%%更新挑战纪录列表
replace_challenge_list(BarrierID, ScoreList, NewScore, CTL, DiffTime, TL) ->
	case BarrierID > length(ScoreList) of
		true ->%%当前关卡是玩家第一次挑战
			NewScoreList = ScoreList ++ [NewScore],
			NewTL = TL ++ [DiffTime],
			NewCTL = CTL ++ [DiffTime];
		false ->
			%%替换积分列表ScoreList
			NewScoreList = replace_list_element(BarrierID, ScoreList, NewScore),
			%%替换时间列表TL
			NewTL = replace_list_element(BarrierID, TL, DiffTime),
			%%替换挑战时间列表CTL
			case DiffTime < lists:nth(BarrierID, CTL) of
				true ->%%此次的挑战比最好的成绩还要好
					NewCTL = replace_list_element(BarrierID, CTL, DiffTime);
				false ->%%此次成绩比最好成绩要差，不改变最好成绩列表
					NewCTL = CTL
			end
	end,
	{NewScoreList, NewCTL, NewTL}.

replace_list_element(Nth, List, NewE) ->
	{H, T} = lists:split(Nth - 1, List),
	%%去除空列表的情况
	case T of
		[] ->
			T11 = [];
		[_ | T11] ->
			next
	end,
	H ++ [NewE] ++ T11.

%%计算积分
calc_score(BarrierID, DiffTime) ->
	{_, CalcTime} = get_tower_fb_config({timeout, BarrierID}),
	case CalcTime < DiffTime of
		true ->
			erlang:max(1000 - 6 * (DiffTime - CalcTime), 0);
		false ->
			1000
	end.

%%hook_map，初始化地图的回调函数
init(_MapID, _MapName) ->
	ok.

%%hook_map，terminate地图的回调函数
do_terminate() ->
	ok.

%%hook_map_role调用
hook_role_enter(RoleID, MapID) ->
	case erlang:get(?tower_fb_info) of
		undefined ->
			ignore;
		_ ->
			Length = length(mod_map_monster:get_monster_id_list()) - 1,
			case Length =< 0 of
				true ->
					BarrierID = MapID - ?default_tower_mapid + 1,
					Line = common_misc:get_role_line_by_id(RoleID),
					DataIn = #m_tower_fb_enter_tos{enter_type = ?NORMAL_ENTER, barrier_id = BarrierID + 1},
					erlang:send_after(30 * 1000, self(), {?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_ENTER, DataIn, RoleID, self(), Line});
				false ->
					BarrierID = MapID - ?default_tower_mapid + 1,
					{MaxTime, _} = get_tower_fb_config({timeout, BarrierID}),
					BarrierRewardList = get_tower_fb_config({reward, 1000 * BarrierID}),
					case BarrierID >= ?max_level of
						false ->
							NextBarrierRewardList = get_tower_fb_config({reward, 1000 * (BarrierID + 1)});
						_ ->
							NextBarrierRewardList = []
					end,
					{ok, #r_role_tower_fb{score_list = ScoreList}} = get_role_tower_fb_info(RoleID),
					CurrentScore = cacl_total_score(ScoreList, BarrierID),
					case CurrentScore =:= 0 of
						true ->
							TotalRewardList = [];
						false ->
							TotalRewardList = get_tower_fb_config({reward, (CurrentScore div 1001 + 1) * 1000})
					end,
					DataRecord = #m_tower_fb_enter_toc{max_time = MaxTime, current_score = CurrentScore, level_reward = BarrierRewardList,
													   next_level_reward = NextBarrierRewardList, current_level = BarrierID,
													   total_reward = TotalRewardList},
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_ENTER, DataRecord),
					global:send(mod_tower_fb_manager, {level_best, BarrierID, RoleID}),
					erlang:send_after(MaxTime * 1000, self(), {?MODULE, {fb_timeout_kick, RoleID}})
			end
	end.

%% @doc 角色退出地图hook，hook_map_role调用
hook_role_quit(RoleID) ->
	case erlang:get(?tower_fb_info) of
		undefined ->
			{error, not_found};
		RoleTowerFbMapInfo ->
			hook_role_quit2(RoleID, RoleTowerFbMapInfo)
	end.

hook_role_quit2(RoleID, RoleTowerFbMapInfo) ->
	#map_state{mapid = MapID, map_name = MapName} = mgeem_map:get_state(),
	case mod_map_actor:is_change_map_quit(RoleID) of
		{true, MapID} ->
			catch do_tower_fb_log(RoleTowerFbMapInfo),
			%% 删除所有怪物
			mod_map_monster:delete_all_monster(),
			%% 重新出生怪物
			mod_map_monster:init_monster_id_list(),
			mod_map_monster:init_map_monster(MapName, MapID);
		_ ->
			hook_role_quit3(RoleID, RoleTowerFbMapInfo)
	end.

hook_role_quit3(RoleID, TowerFbMapInfo) ->
	case mod_map_role:is_role_exit_game(RoleID) of
		true ->
			%% 玩家在副本中退出地图，地图进程会保持一段时间
			ProtectTime = get_tower_fb_config(offline_protect_time),
			erlang:send_after(ProtectTime * 1000, self(), {?MODULE, {offline_terminate}});
		_ ->
			common_map:exit(tower_fb_role_quit),
			catch do_tower_fb_log(TowerFbMapInfo)
	end.

%% @doc 下线保护时间到，如果角色不在副本中杀掉副本地图进程
do_offline_terminate() ->
	case erlang:get(?tower_fb_info) of
		#r_role_tower_fb{} = TowerFbMapInfo ->
			case mod_map_actor:get_in_map_role() of
				[] ->
					common_map:exit( examine_fb_role_quit ),
					catch do_tower_fb_log(TowerFbMapInfo);
				_ ->
					ignore
			end;
		_ ->
			common_map:exit( examine_fb_role_quit )
	end.


%%mgeem_map回调函数
assert_valid_map_id(DestMapID) ->
	is_tower_fb_map_id(DestMapID).

%%mgeem_map回调函数
get_map_name_to_enter(RoleID) ->
	{DestMapID, _TX, _TY} = get({enter, RoleID}),
	get_role_tower_fb_map_name(RoleID, DestMapID - ?default_tower_mapid + 1).

%%mgeem_map回调函数
clear_map_enter_tag(_RoleID) ->
	ignore.




%%获取配置文件中的信息
get_tower_fb_config(Key) ->
	[Val] = common_config_dyn:find(?tower_fb_config, Key),
	Val.

%%从进程字典中获取玩家的地狱熔炉信息
get_role_tower_fb_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok, #r_role_map_ext{role_tower_fb_info = RoleTowerFbInfo}} ->
			{ok, RoleTowerFbInfo};
		_ ->
			{error, not_found}
	end.

%%向进程字典中设置玩家的地狱熔炉信息
set_role_tower_fb_info(RoleID, NewRoleTowerFbInfo) ->
	F = fun() ->
			{ok, RoleExt} = mod_map_role:get_role_map_ext_info(RoleID),
			NewRoleExt = RoleExt#r_role_map_ext{role_tower_fb_info = NewRoleTowerFbInfo},
			mod_map_role:set_role_map_ext_info(RoleID, NewRoleExt)
		end,
	mgeer_role:run(RoleID, F).

quit_tower_fb(RoleID, NowMapID) ->
	case is_tower_fb_map_id(NowMapID) of
		true ->
			BarrierID = NowMapID - ?default_tower_mapid + 1,
			Line = common_misc:get_role_line_by_id(RoleID),
			MapName = get_role_tower_fb_map_name(RoleID, BarrierID),
			case global:whereis_name(MapName) of
				undefined ->
					ignore;
				PID ->
					PID ! {?DEFAULT_UNIQUE, ?TOWER_FB, ?TOWER_FB_QUIT, #m_tower_fb_quit_tos{quit_type = 4}, RoleID, self(), Line}
			end;
		false ->
			ignore
	end.

do_tower_fb_log(TowerFbMapInfo) ->
	#r_role_tower_fb{role_id = RoleID, last_challenge_level = LCL, last_challenge_time = LCT} = TowerFbMapInfo,
	RemainMonster = erlang:length(mod_map_monster:get_monster_id_list()),
	case RemainMonster =:= 0 of
		true ->
			Status = ?fb_quit_status_finish;
		_ ->
			Status = ?fb_quit_status_fail
	end,
	{ok, #p_role_base{role_name = RoleName, faction_id = FactionID}} = common_misc:get_dirty_role_base(RoleID),
	{A, B, _} = LCT,
	EnterTime2 = A * 1000000 + B,
	StopTime = common_tool:now(),
	PersonalFBLog = #r_tower_fb_log{role_id=RoleID,
									role_name=RoleName,
									faction_id=FactionID,
									fb_id=LCL,
									start_time=EnterTime2,
									end_time=StopTime,
									status=Status},
	common_general_log_server:log_tower_fb(PersonalFBLog).

do_tower_cmz({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
	{ok, #r_role_tower_fb{cmz = CMZ}} = get_role_tower_fb_info(RoleID),
	?UNICAST_TOC(#m_tower_fb_cmz_toc{cmz = CMZ}).


merge_reward_props(GoodsList) ->
    lists:foldl(fun(#p_goods{typeid=TypeID,type=Type,current_num=Num}=PGoods,Acc) ->
                            case Type of
                                ?TYPE_ITEM ->
                                    case lists:keyfind(TypeID, #p_goods.typeid, Acc) of
                                        false -> [PGoods | Acc];
                                        #p_goods{current_num=Num1}=PGoods1 ->
                                            lists:keyreplace(TypeID,#p_goods.typeid,Acc,PGoods1#p_goods{current_num=Num1+Num})
                                    end;
                                _ -> [PGoods | Acc]
                            end;
                       (#p_reward_prop{prop_id=TypeID,prop_type=Type,prop_num=Num}=PGoods,Acc) ->
                            case Type of
                                ?TYPE_ITEM ->
                                    case lists:keyfind(TypeID, #p_reward_prop.prop_id, Acc) of
                                        false -> [PGoods | Acc];
                                        #p_reward_prop{prop_num=Num1}=PGoods1 ->
                                            lists:keyreplace(TypeID,#p_reward_prop.prop_id,Acc,PGoods1#p_reward_prop{prop_num=Num1+Num})
                                    end;
                                _ -> [PGoods | Acc]
                            end
                    end, [], GoodsList).
