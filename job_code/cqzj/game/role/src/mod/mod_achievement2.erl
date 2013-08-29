%% Author: dizengrong
%% Created: 2013-1-6
%% @doc: 这里实现的是t6项目中的成就模块
%% 实现的思路：这里将成就记录的数据分为了以下几种模型
%% (#p_achieve_data.cur_progress字段记录的是数字总量)
%% mode_1: 每次更新成就时传递的Data参数是增量
%% mode_2: 每次更新成就时传递的Data参数是总量
%% mode_3: 每次更新成就时传递的Data参数是{增量, 相关数据1}，
%% 		   相关数据1要与#achievement_conf.data_1要一样才能增加该成就的进度
-module (mod_achievement2).
-include("mgeer.hrl").
-compile(export_all).

%% export for role_misc callback
-export([init/2, delete/1]).

-export([handle/1, achievement_update_event/3, gm_finish/2, title_add_attr/3,
		 is_title_open/2, change_title/2]).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GOAL2, Method, Msg)).

-record(achievement_conf, {
		% type     = 0,			%% 成就大分类
		% sub_type = 0,			%% 成就小分类
		id       = 0,			%% 成就id
		mode     = 0,			%% 成就数据模型
		amount   = 0,			%% 完成该成就需要的次数
		data_1   = 0 			%% 完成该成就相关数据1
	}).

%% ============================================================================
%% ============================================================================
init(RoleID, AchievementsRec) ->
	case AchievementsRec of
		false ->
			AchievementsRec1 = #r_achievements{};
		_ ->
			AchievementsRec1 = AchievementsRec
	end,
	mod_role_tab:put({?ROLE_ACHIEVEMENTS, RoleID}, AchievementsRec1).

delete(RoleID) ->
	mod_role_tab:erase({?ROLE_ACHIEVEMENTS, RoleID}).

%% 获取一条成就记录
get_achievement(RoleID, AchieveId) ->
	AchievementsRec = mod_role_tab:get({?ROLE_ACHIEVEMENTS, RoleID}),
	case lists:keyfind(AchieveId, #p_achieve_data.id, AchievementsRec#r_achievements.achieve_list) of
		false -> %% fixme:cur_progress的初始化要根据mode来确定的
			AchieveDataRec = #p_achieve_data{id = AchieveId, cur_progress = 0, award_state = 0},
			set_achievement(RoleID, AchieveDataRec),
			AchieveDataRec;
		AchieveDataRec ->
			AchieveDataRec
	end.
%% 更新一条成就记录
set_achievement(RoleID, AchieveDataRec)	->
	AchieveId       = AchieveDataRec#p_achieve_data.id,
	AchievementsRec = mod_role_tab:get({?ROLE_ACHIEVEMENTS, RoleID}),
	AchieveList     = lists:keystore(AchieveId, #p_achieve_data.id, AchievementsRec#r_achievements.achieve_list, AchieveDataRec),
	mod_role_tab:put({?ROLE_ACHIEVEMENTS, RoleID}, AchievementsRec#r_achievements{achieve_list = AchieveList}).
%% ============================================================================
%% ============================================================================

handle({_Unique, _Module, ?ACHIEVEMENT_INFO, DataIn, RoleID, _PID, _Line}) ->
	do_info(RoleID, DataIn);
handle({_Unique, _Module, ?ACHIEVEMENT_AWARD, DataIn, RoleID, _PID, _Line}) ->
	do_get_award(RoleID, DataIn);
handle({check_if_open_new_title, RoleID, AchieveId}) ->
	check_if_open_new_title(RoleID, AchieveId);
%% 检测成就中的家族成就
handle({check_family_achievement, RoleID, FamilyInfo}) ->
	case is_record(FamilyInfo, p_family_info) of
		true ->
			mod_achievement2:achievement_update_event(RoleID, 33005, FamilyInfo#p_family_info.level),
			mod_achievement2:achievement_update_event(RoleID, 44001, FamilyInfo#p_family_info.level);
		false -> ignore
	end.

gm_finish(RoleID, AchieveId) ->
	case catch cfg_achievement:get_conf(AchieveId) of
		{'EXIT', _} -> "没有这个成就";
		_ ->
			AchieveDataRec  = get_achievement(RoleID, AchieveId),
			AchieveDataRec1 = AchieveDataRec#p_achieve_data{
				is_finished = true,
				award_state = get_award_state(true)
			},
			set_achievement(RoleID, AchieveDataRec1),
			Msg = #m_achievement_update_toc{achieve = AchieveDataRec1#p_achieve_data{data = 0}},
			?MOD_UNICAST(RoleID, ?ACHIEVEMENT_UPDATE, Msg),
			"开启一个成就成功"
	end.

%% 称号改变时调用这个
change_title(RoleID, TitleId) ->
	AchievementsRec = mod_role_tab:get({?ROLE_ACHIEVEMENTS, RoleID}),
	AchievementsRec1 = AchievementsRec#r_achievements{title = TitleId},
	mod_role_tab:put({?ROLE_ACHIEVEMENTS, RoleID}, AchievementsRec1).


do_info(RoleID, DataIn) ->
	TypeId          = DataIn#m_achievement_info_tos.type,
	AchievementsRec = mod_role_tab:get({?ROLE_ACHIEVEMENTS, RoleID}),
	Fun = fun(Rec, Acc) ->
		case get_achievement_type(Rec#p_achieve_data.id) == TypeId of
			true  -> [Rec#p_achieve_data{data = 0} | Acc];
			false -> Acc
		end
	end,
	Msg = #m_achievement_info_toc{
		type         = TypeId,
		achieve_list = lists:foldl(Fun, [], AchievementsRec#r_achievements.achieve_list),
		title_datas  = get_opened_titles(AchievementsRec#r_achievements.achieve_list, TypeId)
	},
	?MOD_UNICAST(RoleID, ?ACHIEVEMENT_INFO, Msg).


is_title_open(RoleID, TitleId) when is_integer(RoleID) -> 
	AchievementsRec = mod_role_tab:get({?ROLE_ACHIEVEMENTS, RoleID}),
	is_title_open(AchievementsRec#r_achievements.achieve_list, TitleId);
is_title_open(AchievementList, TitleId) ->
	Fun = fun(AchieveDataRec, Acc) ->
		case (AchieveDataRec#p_achieve_data.id div 1000) == TitleId of
			true ->  Acc + 1; %% 属于同一大小分类
			false -> Acc
		end
	end,
	lists:foldl(Fun, 0, AchievementList) == cfg_achievement:get_same_type_num(TitleId).

title_add_attr(RoleID, RoleBase, SecondAttr) ->
	AchievementsRec = mod_role_tab:get({?ROLE_ACHIEVEMENTS, RoleID}),
	case is_record(AchievementsRec, r_achievements) andalso AchievementsRec#r_achievements.title of
		0 -> SecondAttr;
		false -> SecondAttr;
		TitleId ->
			{MaxLifeScale, AttScale, PDefScale, MDefScale} = cfg_achievement:get_title_effect(TitleId),
			SecondAttr#role_second_level_attr{
				max_hp           = SecondAttr#role_second_level_attr.max_hp + trunc(RoleBase#p_role_base.max_hp * MaxLifeScale),
				max_phy_attack   = SecondAttr#role_second_level_attr.max_phy_attack + trunc(RoleBase#p_role_base.max_phy_attack * AttScale),
				min_phy_attack   = SecondAttr#role_second_level_attr.min_phy_attack + trunc(RoleBase#p_role_base.min_phy_attack * AttScale),
				max_magic_attack = SecondAttr#role_second_level_attr.max_magic_attack + trunc(RoleBase#p_role_base.max_magic_attack * AttScale),
				min_magic_attack = SecondAttr#role_second_level_attr.min_magic_attack + trunc(RoleBase#p_role_base.min_magic_attack * AttScale),
				phy_defence      = SecondAttr#role_second_level_attr.phy_defence + trunc(RoleBase#p_role_base.phy_defence * PDefScale),
				magic_defence    = SecondAttr#role_second_level_attr.magic_defence + trunc(RoleBase#p_role_base.magic_defence * MDefScale)
			}
	end.


do_get_award(RoleID, DataIn) ->
	AchieveId = DataIn#m_achievement_award_tos.achieve_id,
	AchieveDataRec = get_achievement(RoleID, AchieveId),
	Ret = if
		AchieveDataRec#p_achieve_data.is_finished == false -> 
			{error, <<"该成就还没有完成，不能领取奖励">>};
		AchieveDataRec#p_achieve_data.award_state == 2 ->
			{error, <<"奖励已领取过了，不能再领取">>};
		true -> true
	end,
	case Ret of
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			AwardItems = cfg_achievement:get_award(AchieveId),
			case mod_bag:add_items(RoleID, AwardItems, ?LOG_ITEM_TYPE_ACHIEVEMENT_AWARD) of
				{true, _} -> 
					NewAchieveDataRec = AchieveDataRec#p_achieve_data{award_state = 2},
					set_achievement(RoleID, NewAchieveDataRec),
					Msg = #m_achievement_update_toc{achieve = NewAchieveDataRec#p_achieve_data{data = 0}},
					?MOD_UNICAST(RoleID, ?ACHIEVEMENT_UPDATE, Msg);
				{error, Reason2} ->
					common_misc:send_common_error(RoleID, 0, Reason2)
			end
	end.

get_opened_titles(AchievementList, BigType) ->
	Acc0 = [{T0, 0} || T0 <- cfg_achievement:get_all_types()],
	Fun = fun(AchieveDataRec, Acc) ->
		T = AchieveDataRec#p_achieve_data.id div 1000,
		case AchieveDataRec#p_achieve_data.is_finished of
			true -> 
				{_, Num} = case lists:keyfind(T, 1, Acc) of
					false -> ?ERROR_MSG("achieve id: ~w", [AchieveDataRec#p_achieve_data.id]), {0,0};
					R -> R
				end,
				lists:keystore(T, 1, Acc, {T, Num + 1});
			false -> Acc
		end
	end,
	Acc1 = lists:foldl(Fun, Acc0, AchievementList),
	[{Type, N == cfg_achievement:get_same_type_num(Type)} || {Type, N} <- Acc1, Type div 10 == BigType].

%% 当一个成就完成了时，检测是否开启了新的成就称号
check_if_open_new_title(RoleID, AchieveId) ->
	AchievementsRec = mod_role_tab:get({?ROLE_ACHIEVEMENTS, RoleID}),
	TypeId          = AchieveId div 1000,
	case is_title_open(AchievementsRec#r_achievements.achieve_list, TypeId) of
		true ->
			Msg = #m_achievement_title_update_toc{title_id = TypeId},
			?MOD_UNICAST(RoleID, ?ACHIEVEMENT_TITLE_UPDATE, Msg);
		false -> ignore
	end.

%% 成就数据更新通知，由其他模块调用来完成成就
%% 暂时屏蔽成就系统
achievement_update_event(_RoleID, _AchieveId, _Data) ->
	ok.
	% try
	% 	AchieveConf = cfg_achievement:get_conf(AchieveId),
	% 	Ret = case AchieveConf#achievement_conf.mode of
	% 		1 -> update_mode_1_achievement(RoleID, AchieveId, Data);
	% 		2 -> update_mode_2_achievement(RoleID, AchieveId, Data);
	% 		3 -> update_mode_3_achievement(RoleID, AchieveId, Data);
	% 		4 -> update_mode_4_achievement(RoleID, AchieveId, Data)
	% 	end,	
	% 	case Ret of
	% 		ignore -> ignore;
	% 		{ok, NewAchieveDataRec} ->
	% 			%% 异步去检测是否开启了新的成就称号
	% 			case NewAchieveDataRec#p_achieve_data.is_finished of
	% 				true -> 
	% 					Msg = #m_achievement_update_toc{achieve = NewAchieveDataRec#p_achieve_data{data = 0}},
	% 					?MOD_UNICAST(RoleID, ?ACHIEVEMENT_UPDATE, Msg),
	% 					mgeer_role:absend(RoleID, {?MODULE, {check_if_open_new_title, RoleID, AchieveId}});
	% 				false -> ignore
	% 			end
	% 	end
	% catch
	% 	Type:Error ->
	% 		?ERROR_MSG("Call achievement_update_event(~w, ~w, ~w) failed, type: ~w, error: ~w, stack: ~w",
	% 				   [RoleID, AchieveId, Data, Type, Error, erlang:get_stacktrace()])
	% end.

update_mode_1_achievement(RoleID, AchieveId, Data) ->
	AchieveDataRec = get_achievement(RoleID, AchieveId),
	case AchieveDataRec#p_achieve_data.is_finished of
		true -> ignore;
		false ->
			AchieveConf = cfg_achievement:get_conf(AchieveId),
			IsFinished  = (AchieveDataRec#p_achieve_data.cur_progress + Data >= AchieveConf#achievement_conf.amount),
			AchieveDataRec1 = AchieveDataRec#p_achieve_data{
				cur_progress = AchieveDataRec#p_achieve_data.cur_progress + Data,
				is_finished  = IsFinished,
				award_state  = get_award_state(IsFinished)
			},
			set_achievement(RoleID, AchieveDataRec1),
			{ok, AchieveDataRec1}
	end.

update_mode_2_achievement(RoleID, AchieveId, Data) ->
	AchieveDataRec = get_achievement(RoleID, AchieveId),
	case AchieveDataRec#p_achieve_data.is_finished of
		true -> ignore;
		false ->
			AchieveConf = cfg_achievement:get_conf(AchieveId),
			IsFinished  = (Data >= AchieveConf#achievement_conf.amount),
			AchieveDataRec1 = AchieveDataRec#p_achieve_data{
				cur_progress = Data,
				is_finished  = IsFinished,
				award_state  = get_award_state(IsFinished)
			},
			set_achievement(RoleID, AchieveDataRec1),
			{ok, AchieveDataRec1}
	end.

update_mode_3_achievement(RoleID, AchieveId, {AddedAmount, Data1}) ->
	AchieveDataRec = get_achievement(RoleID, AchieveId),
	case AchieveDataRec#p_achieve_data.is_finished of
		true -> ignore;
		false ->
			AchieveConf = cfg_achievement:get_conf(AchieveId),
			case AchieveConf#achievement_conf.data_1 == Data1 of
				true -> 
					IsFinished  = (AchieveDataRec#p_achieve_data.cur_progress + AddedAmount >= AchieveConf#achievement_conf.amount),
					AchieveDataRec1 = AchieveDataRec#p_achieve_data{
						cur_progress = AchieveDataRec#p_achieve_data.cur_progress + AddedAmount,
						is_finished  = IsFinished,
						award_state  = get_award_state(IsFinished)
					},
					set_achievement(RoleID, AchieveDataRec1),
					{ok, AchieveDataRec1};
				false -> ignore
			end
	end.

update_mode_4_achievement(RoleID, AchieveId, Data) ->
	AchieveDataRec = get_achievement(RoleID, AchieveId),
	case AchieveDataRec#p_achieve_data.is_finished of
		true -> ignore;
		false ->
			AchieveConf = cfg_achievement:get_conf(AchieveId),
			DataList = case AchieveDataRec#p_achieve_data.data of
				undefined -> [];
				Val -> Val
			end,
			case lists:member(Data, DataList) of
				false -> 
					IsFinished  = (AchieveDataRec#p_achieve_data.cur_progress + 1 >= AchieveConf#achievement_conf.amount),
					AchieveDataRec1 = AchieveDataRec#p_achieve_data{
						cur_progress = AchieveDataRec#p_achieve_data.cur_progress + 1,
						data         = [Data | DataList],
						is_finished  = IsFinished,
						award_state  = get_award_state(IsFinished)
					},
					set_achievement(RoleID, AchieveDataRec1),
					{ok, AchieveDataRec1};
				true -> ignore
			end
	end.

get_award_state(false) -> 0;
get_award_state(true) -> 1.

%% 根据成就id获取成就大分类id
get_achievement_type(AchieveId) -> AchieveId div 10000.