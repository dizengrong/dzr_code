%% Author: dizengrong
%% Created: 2012-12-27
%% @doc: 这里实现的是t6项目中的目标模块
%% 实现思路是：目标id就是玩家等级，record #r_goal记录了玩家目前完成到了哪个目标id了
%% 以及目前领取到了哪个目标的奖励了
%% 在完成的目标id之前的目标都已完成了，之后都没有完成
%% 在领取到了哪个目标id的奖励之前的奖励都已领取完了，之后都没领取

-module (mod_goal2).
-include("mgeer.hrl").

%% 目标完成后的奖励配置
-record(goal_reward_conf, {
		% gold_bind   = 0,	%% 奖励的元宝
		silver = 0,	%% 奖励的银币
		exp    = 0,	%% 奖励的经验
		items  = []	%% [{物品id, 数量, 物品类型(1,2,3), 是否绑定}...]}
	}).

-record(notice_conf, {
	id      = 0, 		%% 预告id
	next_id = 0, 		%% 下一个预告的id
	role_lv = 0, 		%% 该预告需要玩家达到的等级
	award_item 	 		%% 奖励的物品: {物品id, 数量, 物品类型(1,2,3), 是否绑定(true|false)}
	}).

-export([mission_committed/2, role_level_change/2, handle/1]).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GOAL2, Method, Msg)).

%% 提交任务时检测是否完成目标
mission_committed(RoleID, MissionID) ->
	case cfg_goal:get_finished_goal_by_mission(MissionID) of
		[] -> ignore;
		GoalId ->
			{ok, GoalRec} = mod_map_role:get_role_goal(RoleID),
			case GoalRec#r_goal.finished_id >= GoalId of
				true -> ignore; %% 已经完成了
				false ->
					NewGoalRec = GoalRec#r_goal{finished_id = GoalId},
					mod_map_role:set_role_goal(RoleID, NewGoalRec),
					send_goal_info_to_client(RoleID, GoalRec)
			end
	end.

%% 角色升级时检测是否完成目标
role_level_change(RoleID, NewLevel) -> 
	case cfg_goal:get_finished_goal_by_level(NewLevel) of
		[] -> ignore;
		GoalId ->
			{ok, GoalRec} = mod_map_role:get_role_goal(RoleID),
			case GoalRec#r_goal.finished_id >= GoalId of
				true -> ignore; %% 已经完成了
				false ->
					NewGoalRec = GoalRec#r_goal{finished_id = GoalId},
					mod_map_role:set_role_goal(RoleID, NewGoalRec),
					send_goal_info_to_client(RoleID, GoalRec)
			end
	end,
	send_notice_info_to_client(RoleID),
	ok.

handle({_Unique, _Module, ?GOAL2_INFO, _DataIn, RoleID, _PID, _Line}) ->
	{ok, GoalRec} = mod_map_role:get_role_goal(RoleID),
	send_goal_info_to_client(RoleID, GoalRec);
handle({_Unique, _Module, ?GOAL2_FETCH, DataIn, RoleID, _PID, _Line}) ->
	do_fetch_reward(RoleID, DataIn);
handle({_Unique, _Module, ?GOAL2_NOTICE_INFO, _DataIn, RoleID, _PID, _Line}) ->
	send_notice_info_to_client(RoleID);
handle({_Unique, _Module, ?GOAL2_NOTICE_FETCH, _DataIn, RoleID, _PID, _Line}) ->
	do_notice_fetch_reward(RoleID).

send_goal_info_to_client(RoleID, GoalRec) ->
	Msg = #m_goal2_info_toc{
		finished_id = GoalRec#r_goal.finished_id,
		fetched_id  = erlang:max(cfg_goal:get_first_id() - 1, GoalRec#r_goal.fetched_id)
	},
	?MOD_UNICAST(RoleID, ?GOAL2_INFO, Msg).

do_fetch_reward(RoleID, DataIn) ->
	{ok, GoalRec} = mod_map_role:get_role_goal(RoleID),
	FetchGoalId   = DataIn#m_goal2_fetch_tos.goal_id,
	%% 因为fetched_id为目标id，而目标id为
	Ret = case cfg_goal:get_next_id(GoalRec#r_goal.fetched_id) of
		[] 			-> {error, "已无奖励可领取了"};
		FetchGoalId when FetchGoalId =< GoalRec#r_goal.finished_id -> true;
		_ 			-> {error, "亲，请先把前面已完成目标的奖励领取掉吧！"}
	end,
	case Ret of
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			case send_goal_reward(RoleID, FetchGoalId) of
				true ->
					NewGoalRec = GoalRec#r_goal{fetched_id = FetchGoalId},
					mod_map_role:set_role_goal(RoleID, NewGoalRec),
					send_goal_info_to_client(RoleID, NewGoalRec);
				{false, Reason1} ->
					common_misc:send_common_error(RoleID, 0, Reason1)
			end
	end.

send_goal_reward(RoleID, FetchGoalId) ->
	GoalRewardRec  = cfg_goal:get_reward(FetchGoalId),
	Items          = GoalRewardRec#goal_reward_conf.items,
	Silver         = GoalRewardRec#goal_reward_conf.silver,
	Exp            = GoalRewardRec#goal_reward_conf.exp,
	case mod_bag:add_items(RoleID, Items, ?LOG_ITEM_TYPE_GAIN_GOAL) of
		{error, Reason} ->
			{false, Reason};
		{true, _} -> 
			if Silver > 0 -> {ok, _} = common_bag2:add_money(RoleID, silver_bind, Silver, ?GAIN_TYPE_SILVER_FROM_GOAL);
			   true 	  -> ignore
			end, 
			if Exp > 0 -> mod_map_role:do_add_exp(RoleID, Exp);
			   true    -> ignore
			end,
			true
	end.

%% ===================================================================
%% ============================ 预告 =================================

send_notice_info_to_client(RoleID) ->
	{ok, GoalRec} = mod_map_role:get_role_goal(RoleID),
	send_notice_info_to_client(RoleID, GoalRec).
send_notice_info_to_client(RoleID, GoalRec) ->
	case GoalRec#r_goal.cur_notice == cfg_goal:last_notice() of
		true -> 
			Msg = #m_goal2_notice_info_toc{
				next_notice = GoalRec#r_goal.cur_notice, 
				can_fetch   = false};
		false ->
			NextNotice     = erlang:max(cfg_goal:first_notice(), GoalRec#r_goal.cur_notice),
			NoticeConfRec  = cfg_goal:notice(NextNotice),
			{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			CanFetch       = (RoleAttr#p_role_attr.level >= NoticeConfRec#notice_conf.role_lv),
		 	Msg = #m_goal2_notice_info_toc{
				next_notice = NextNotice,
				can_fetch  = CanFetch
			}
	end,
	?MOD_UNICAST(RoleID, ?GOAL2_NOTICE_INFO, Msg).

do_notice_fetch_reward(RoleID) ->
	{ok, GoalRec}  = mod_map_role:get_role_goal(RoleID),
	NextNotice     = erlang:max(cfg_goal:first_notice(), GoalRec#r_goal.cur_notice),
	NoticeConfRec  = cfg_goal:notice(NextNotice),
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	LastNotice     = cfg_goal:last_notice(),
	Ret = if
		RoleAttr#p_role_attr.level < NoticeConfRec#notice_conf.role_lv ->
			{error, "当前角色等级下没有奖励可领取"};
		GoalRec#r_goal.cur_notice == LastNotice ->
			{error, "该功能的奖励已全部领取完毕了"};
		true ->
			Items = [get_notice_reward_by_category(RoleAttr#p_role_attr.category, NoticeConfRec)],
			case mod_bag:add_items(RoleID, Items, ?LOG_ITEM_TYPE_GOAL_NOTICE_AWARD) of 
				{error, Reason} -> {error, Reason};
				_ -> true
			end
	end,
	case Ret of
		{error, Reason1} ->
			common_misc:send_common_error(RoleID, 0, Reason1);
		true ->
			NewGoalRec = GoalRec#r_goal{cur_notice = NoticeConfRec#notice_conf.next_id},
			mod_map_role:set_role_goal(RoleID, NewGoalRec),
			send_notice_info_to_client(RoleID, NewGoalRec)
	end.

get_notice_reward_by_category(Category, NoticeConfRec) ->
	{_, Reward} = lists:keyfind(Category, 1, NoticeConfRec#notice_conf.award_item),
	Reward.


