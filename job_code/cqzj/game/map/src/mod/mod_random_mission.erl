%% Author: xiee
%% Created: 2012-9-6
%% Description: 遗迹探险
-module(mod_random_mission).
%%
%% Include files
%%
-include("mgeem.hrl").
-define(TASK_START, 1).
-define(TASK_DONE,  2).
-define(DEFAULT_CHANCES, 15).

-define(TASK_FB, [1,2]).%%副本任务类型

-define(_if(If, Val1, Val2), if If -> Val1; true -> Val2 end).
-define(_trans(Fun), common_transaction:t(fun()-> Fun end)).
-define(_catch(Code), case catch Code of ok -> ok; Error -> throw(Error) end).

-define(UNICAST(Rec), common_misc:unicast2(PID, Unique, Module, Method, Rec)).
-define(UNICAST(Method, Rec), common_misc:unicast2(PID, Unique, Module, Method, Rec)).
-define(UNICAST(Module, Method, Rec), common_misc:unicast2(PID, Unique, Module, Method, Rec)).
-define(UNICAST_ERR_CODE(Code), common_misc:unicast2(PID, Unique, ?RANDOM_MISSION, ?RANDOM_MISSION_ERROR, #m_random_mission_error_toc{code = Code})).
-define(UNICAST_ERR_MSG(Msg), common_misc:unicast2(PID, Unique, ?RANDOM_MISSION, ?RANDOM_MISSION_ERROR, #m_random_mission_error_toc{msg = Msg})).

-define(OPERATE_ROLL,		1).
-define(OPERATE_COMPLETE,	2).
-define(OPERATE_GIVEUP,		3).
-define(OPERATE_IMMEDIATE,	4).
-define(OPERATE_CHEAT,		5).

-define(PRESENT_GOLD_BIND,	2).
-define(PRESENT_SILVER_BIND,4).
-define(PRESENT_EXP,		5).
-define(PRESENT_PRESTIGE,	6).

-define(LEVEL_UP_MSG(RoleName, Level), 
	"天降奇运，【"++common_tool:to_list(RoleName)++"】成功通关【遗迹探险】第"++common_tool:to_list(Level)++"关，获得了大量珍贵道具，众人膜拜！").

-define(ERR_RAND_MISSION_NOT_IN_SPRING,10001).
-record(random_mission_level, {id, rewards}).
-record(random_mission_grid, {id, type, args}).
-record(random_mission_task, {id, type, times, rewards}).

%%
%% Exported Functions
%%
-export([init/2, delete/1, handle_event/2, handle/1, add_chance/2,refresh_daily_counter_times/2]).
%%
%% API Functions
%%

refresh_daily_counter_times(RoleID,RemainTimes1) when erlang:is_integer(RemainTimes1)->
	case  get_mission(RoleID) of
		#r_random_mission{chances = RemainTimes} = Mission ->
			if
				RemainTimes1 > 0 ->
					set_mission(RoleID,Mission#r_random_mission{chances=RemainTimes1}),
					IsNotyfy = true,
					RemainTimes2 = RemainTimes1;
				true ->
					IsNotyfy = false,
					RemainTimes2 = RemainTimes
			end,
			mod_daily_counter:set_mission_remain_times(RoleID, 1013, RemainTimes2,IsNotyfy);
		_ ->
			ignore
	end.
	
init(RoleID, Rec) when is_record(Rec, r_random_mission) ->
	mod_role_tab:put({random_mission, RoleID}, Rec);
init(_RoleID, _Rec) ->
	ignore.

delete(RoleID) ->
	mod_role_tab:get({random_mission, RoleID}).

handle_event(RoleID, Type) ->
	case get_mission(RoleID) of
	Mission when is_record(Mission, r_random_mission),
				 Mission#r_random_mission.task_status == ?TASK_START ->
		case common_config_dyn:find(random_mission_task, Mission#r_random_mission.task_id) of
			[#random_mission_task{type=Type, times=Times}] ->
				NewProgress = Mission#r_random_mission.task_progress+1,
				NewStatus   = ?_if(NewProgress >= Times, ?TASK_DONE, ?TASK_START),
				NewMission  = Mission#r_random_mission{task_progress=NewProgress, task_status=NewStatus},
				set_mission(RoleID, NewMission);
			_ ->
				ignore
		end;
	_ ->
		ignore
	end.

handle(Info) ->
	?_catch(handle_info(Info)).

handle_info({Unique, Module, Method=?RANDOM_MISSION_OPEN, _DataIn, RoleID, PID, _Line}) ->
	
	case mod_spring:is_in_spring_map() of
		true ->
			?UNICAST(#m_random_mission_open_toc{err_code = ?ERR_RAND_MISSION_NOT_IN_SPRING});
		_ ->
			#r_random_mission{
				level       = Level, 
				grid_id     = GridID,
				task_id     = TaskID, 
				task_status = TaskStatus, 
				chances     = Chances
			} = get_mission(RoleID),
			{ok, #p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
			BigJingjie = big_level(RoleLevel),
			[#random_mission_level{rewards=Rewards1}] = common_config_dyn:find(random_mission_level, {1, BigJingjie}),
			[#random_mission_level{rewards=Rewards2}] = common_config_dyn:find(random_mission_level, {2, BigJingjie}),
			[#random_mission_level{rewards=Rewards3}] = common_config_dyn:find(random_mission_level, {3, BigJingjie}),
			[#random_mission_level{rewards=Rewards4}] = common_config_dyn:find(random_mission_level, {4, BigJingjie}),
			[#random_mission_level{rewards=Rewards5}] = common_config_dyn:find(random_mission_level, {5, BigJingjie}),
			[#random_mission_level{rewards=Rewards6}] = common_config_dyn:find(random_mission_level, {6, BigJingjie}),
			Toc = #m_random_mission_open_toc{
				level       = Level, 
				grid_id     = GridID, 
				chances     = Chances,
				lv1_rewards = Rewards1,
				lv2_rewards = Rewards2,
				lv3_rewards = Rewards3,
				lv4_rewards = Rewards4,
				lv5_rewards = Rewards5,
				lv6_rewards = Rewards6
			},
			if
			TaskID > 0 ->
				case common_config_dyn:find(random_mission_task, TaskID) of
				[] ->
					?UNICAST(Toc);
				[#random_mission_task{type=TaskType,times=TaskTimes,rewards=TaskRewards}] ->
					?UNICAST(Toc#m_random_mission_open_toc{
						task_type    = TaskType, 
						task_times   = TaskTimes, 
						task_status  = TaskStatus, 
						task_rewards = TaskRewards
					})
				end;
			true ->
				?UNICAST(Toc)
			end
	end,
	ok;

handle_info({Unique, Module, Method=?RANDOM_MISSION_ROLL, DataIn, RoleID, PID, _Line}) ->
	#m_random_mission_roll_tos{num=DiceNum} = DataIn,
	Mission = get_mission(RoleID),
	#r_random_mission{level=Level, task_status=TaskStatus, chances=Chances} = Mission, 
	if
	Level >= 6 ->
		?UNICAST_ERR_MSG(<<"已经过了第6关">>);
	Chances =< 0 ->
		?UNICAST_ERR_MSG(<<"今天已经没有机会了">>);
	TaskStatus == ?TASK_DONE ->
		?UNICAST_ERR_MSG(<<"请先领取奖励">>);
	TaskStatus == ?TASK_START ->
		?UNICAST_ERR_MSG(<<"任务进行中">>);
	true ->
		{ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
		Steps = [random:uniform(6)||_<-lists:seq(1, DiceNum)],
		{NewMission, Arrows} = roll(RoleID, lists:sum(Steps), Mission, []),
		set_mission(RoleID, NewMission),
		hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_RANDOM_MISSION),
		if
		DiceNum == 2; DiceNum ==3 ->
			case ?_trans(common_bag2:t_deduct_money(gold_any, 10*(DiceNum-1), RoleID, ?CONSUME_TYPE_GOLD_RANDOM_MISSION_ROLL)) of
				{_, {ok,NewRoleAttr}}->
					ChangeList = [
						#p_role_attr_change{
							change_type = ?ROLE_GOLD_CHANGE, 
							new_value   = NewRoleAttr#p_role_attr.gold
						},
						#p_role_attr_change{
							change_type = ?ROLE_GOLD_BIND_CHANGE, 
							new_value   = NewRoleAttr#p_role_attr.gold_bind
						}
					],
					common_misc:role_attr_change_notify({pid, PID}, RoleID, ChangeList);
				{_, {error,gold_any}} ->
					?UNICAST_ERR_CODE(?ERR_GOLD_NOT_ENOUGH),
					throw(ok);
				{_, {error, Reason}} ->
					?UNICAST_ERR_MSG(Reason),
					throw(ok)
			end;
		DiceNum == 1 ->
			ignore
		end,
		case common_config_dyn:find(random_mission_task, NewMission#r_random_mission.task_id) of
			[] ->
				?UNICAST(#m_random_mission_roll_toc{
					steps   = Steps,
					level   = NewMission#r_random_mission.level,
					grid_id = NewMission#r_random_mission.grid_id,
					chances = NewMission#r_random_mission.chances,
					arrows  = lists:sort(Arrows)
				});
			[#random_mission_task{type=TaskType,times=TaskTimes,rewards=Rewards}] ->
				?UNICAST(#m_random_mission_roll_toc{
					steps        = Steps,
					level        = NewMission#r_random_mission.level,
					grid_id      = NewMission#r_random_mission.grid_id,
					task_type    = TaskType,
					task_times   = TaskTimes,
					task_rewards = Rewards,
					chances      = NewMission#r_random_mission.chances,
					arrows       = lists:sort(Arrows)
				})
		end,
		Log = #r_random_mission_log{
			role_id      = RoleID,
			role_name    = RoleName,
			operate_id   = ?OPERATE_ROLL,
			operate_time = common_tool:now()
		},

		hook_mission_event:hook_special_event(RoleID,?MISSION_EVENT_RANDOM_MISSION_ROLL),
		common_general_log_server:log_random_mission(Log)
	end,
	ok;

handle_info({Unique, Module, Method=?RANDOM_MISSION_COMPLETE, _DataIn, RoleID, PID, _Line}) ->
	Mission = get_mission(RoleID),
	#r_random_mission{grid_id=GridID, task_id=TaskID, task_status=TaskStatus} = Mission,
	if
		TaskID =< 0 ->
			?UNICAST_ERR_MSG(<<"未接受任何任务">>);
		TaskStatus /= ?TASK_DONE ->
			?UNICAST_ERR_MSG(<<"任务未完成">>);
		true ->
			[#random_mission_grid{type=1}] = common_config_dyn:find(random_mission_grid, GridID),
			[#random_mission_task{type=TaskType,rewards=Rewards}] = common_config_dyn:find(random_mission_task, TaskID),
			present(mission_complete, RoleID, Rewards),
			set_mission(RoleID, Mission#r_random_mission{task_id=0,task_progress=0,task_status=0}),
			?UNICAST(#m_random_mission_complete_toc{}),
			{ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
			Log = #r_random_mission_log{
				role_id      = RoleID,
				role_name    = RoleName,
				task_id      = TaskID,
				task_type    = TaskType,
				operate_id   = ?OPERATE_COMPLETE,
				operate_time = common_tool:now()
			},
			common_general_log_server:log_random_mission(Log)
	end,
	ok;

handle_info({Unique, Module, Method=?RANDOM_MISSION_GIVEUP, _DataIn, RoleID, PID, _Line}) ->
	Mission = get_mission(RoleID),
	#r_random_mission{grid_id=GridID, task_id=TaskID} = Mission,
	set_mission(RoleID, Mission#r_random_mission{task_id=0,task_status=0,task_progress=0}),
	?UNICAST(#m_random_mission_giveup_toc{}),
	[#random_mission_grid{type=1}] = common_config_dyn:find(random_mission_grid, GridID),
	[#random_mission_task{type=TaskType}] = common_config_dyn:find(random_mission_task, TaskID),
	{ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
	Log = #r_random_mission_log{
		role_id      = RoleID,
		role_name    = RoleName,
		task_id      = TaskID,
		task_type    = TaskType,
		operate_id   = ?OPERATE_GIVEUP,
		operate_time = common_tool:now()
	}, 
	common_general_log_server:log_random_mission(Log),
	ok;

handle_info({Unique, Module, Method=?RANDOM_MISSION_IMMEDIATE, _DataIn, RoleID, PID, _Line}) ->
	Mission = get_mission(RoleID),
	#r_random_mission{grid_id=GridID, task_id=TaskID, task_status=?TASK_START} = Mission,
	[#random_mission_grid{type=1}] = common_config_dyn:find(random_mission_grid, GridID),
	[#random_mission_task{type=TaskType, rewards=Rewards}] = common_config_dyn:find(random_mission_task, TaskID),

	case ?_trans(common_bag2:t_deduct_money(gold_any, 2, RoleID, ?CONSUME_TYPE_GOLD_RANDOM_MISSION_IMMEDIATE)) of
		{_,{ok,NewRoleAttr}}->
			ChangeList = [
				#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
				#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind}],
			common_misc:role_attr_change_notify({pid, PID}, RoleID, ChangeList);
		{_, {error,gold_any}} ->
			?UNICAST_ERR_CODE(?ERR_GOLD_NOT_ENOUGH),
			throw(ok);
		{_, {error, Reason}} ->
			?UNICAST_ERR_MSG(Reason),
			throw(ok)
	end,
	
	present(mission_complete, RoleID, Rewards),
	set_mission(RoleID, Mission#r_random_mission{task_id=0,task_status=0,task_progress=0}),
	{ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
	Log = #r_random_mission_log{
		role_id      = RoleID,role_name=RoleName,
		task_id      = TaskID,
		task_type    = TaskType,
		operate_id   = ?OPERATE_IMMEDIATE,
		operate_time = common_tool:now()
	},
	
	?UNICAST(#m_random_mission_immediate_toc{}),
	common_general_log_server:log_random_mission(Log),
	ok;

handle_info({Unique, Module, ?RANDOM_MISSION_CHEAT, DataIn, RoleID, PID, _Line}) ->
	#m_random_mission_cheat_tos{step=Step, num=DiceNum} = DataIn,
	Mission = get_mission(RoleID),
	#r_random_mission{level=Level, task_status=TaskStatus, chances=Chances} = Mission, 
	if
	Level >= 6 ->
		?UNICAST_ERR_MSG(<<"已经过了第6关">>);
	Chances =< 0 ->
		?UNICAST_ERR_MSG(<<"今天已经没有机会了">>);
	TaskStatus == ?TASK_DONE ->
		?UNICAST_ERR_MSG(<<"请先领取奖励">>);
	TaskStatus == ?TASK_START ->
		?UNICAST_ERR_MSG(<<"任务进行中">>);
	Step < 1; Step > 6; DiceNum < 1; DiceNum > 3 ->
		?UNICAST_ERR_MSG(<<"参数非法">>);
	true ->
		{ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
		{NewMission, Arrows} = roll(RoleID, lists:sum([Step||_<-lists:seq(1, DiceNum)]), Mission, []),
		case ?_trans(common_bag2:t_deduct_money(gold_any, 20+10*(DiceNum-1), RoleID, ?CONSUME_TYPE_GOLD_RANDOM_MISSION_CHEAT)) of
			{_, {ok,NewRoleAttr}}->
				ChangeList = [
					#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
					#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind}],
				common_misc:role_attr_change_notify({pid, PID}, RoleID, ChangeList);
			{_, {error,gold_any}} ->
				?UNICAST_ERR_CODE(?ERR_GOLD_NOT_ENOUGH),
				throw(ok);
			{_, {error, Reason}} ->
				?UNICAST_ERR_MSG(Reason),
				throw(ok)
		end,
		set_mission(RoleID, NewMission),
		case common_config_dyn:find(random_mission_task, NewMission#r_random_mission.task_id) of
			[] ->
				?UNICAST(?RANDOM_MISSION_ROLL, #m_random_mission_roll_toc{
					steps   = [Step||_<-lists:seq(1, DiceNum)],
					level   = NewMission#r_random_mission.level,
					grid_id = NewMission#r_random_mission.grid_id,
					chances = NewMission#r_random_mission.chances,
					arrows  = Arrows
				}); 
			[#random_mission_task{type=TaskType,times=TaskTimes,rewards=Rewards}] ->
				?UNICAST(?RANDOM_MISSION_ROLL, #m_random_mission_roll_toc{
					steps        = [Step||_<-lists:seq(1, DiceNum)],
					level        = NewMission#r_random_mission.level,
					grid_id      = NewMission#r_random_mission.grid_id,
					chances      = NewMission#r_random_mission.chances,
					task_type    = TaskType,
					task_times   = TaskTimes,
					task_rewards = Rewards,
					arrows       = Arrows
				})
		end,
		Log = #r_random_mission_log{
			role_id      = RoleID,
			role_name    = RoleName,
			operate_id   = ?OPERATE_CHEAT,
			operate_time = common_tool:now()
		},
		common_general_log_server:log_random_mission(Log)
	end,
	ok.

%%
%% Local Functions
%%
get_mission(RoleID) when is_integer(RoleID) ->
	case mod_role_tab:get({random_mission, RoleID}) of
		undefined ->
			#r_random_mission{};
		Mission ->
			NowSecs = common_tool:now(),
			IsToday = common_time:is_today(Mission#r_random_mission.time),
			#r_random_mission{
				level       = ?_if(IsToday, Mission#r_random_mission.level, 0),
				grid_id     = ?_if(IsToday, Mission#r_random_mission.grid_id, 1),
				task_id     = ?_if(IsToday, Mission#r_random_mission.task_id, 0),
				task_status = ?_if(IsToday, Mission#r_random_mission.task_status, 0),
				chances     = ?_if(IsToday, Mission#r_random_mission.chances, ?DEFAULT_CHANCES),
				time        = ?_if(IsToday, Mission#r_random_mission.time, NowSecs)
			}
	end.

set_mission(RoleID, Mission) ->
	mod_role_tab:put({random_mission, RoleID}, Mission).

%% 增加掷骰子的次数
add_chance(RoleID, Times) ->
	Mission  = get_mission(RoleID),
	Chances1 = Mission#r_random_mission.chances + Times,
	Mission1 = Mission#r_random_mission{chances = Chances1},
	set_mission(RoleID, Mission1),
	mod_daily_counter:set_mission_remain_times(RoleID, 1013, Chances1,true),
	Msg = #m_random_mission_chance_change_toc{chances = Chances1},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?RANDOM_MISSION, ?RANDOM_MISSION_CHANCE_CHANGE, Msg).

roll(RoleID, Step, Mission = #r_random_mission{level=Level, grid_id=GridID, chances=Chances}, Arrows) ->
	Now = common_tool:now(),
	NewLevel = ?_if(Step+GridID>20, Level+1, Level),
	NewGridID = ?_if(Step+GridID>20, Step+GridID-20, Step+GridID),
	{ok, #p_role_attr{role_name=RoleName, level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	if
	NewLevel > Level ->
		[#random_mission_level{rewards=Rewards}] = common_config_dyn:find(random_mission_level, {NewLevel, big_level(RoleLevel)}),
		present(levelup, RoleID, Rewards),
		if
		NewLevel >= 4 ->
			common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_WORLD, ?LEVEL_UP_MSG(RoleName, NewLevel));
		true ->
			ignore
		end;
	true ->
		ignore
	end,
	[#random_mission_grid{type=Type, args=Args}] = common_config_dyn:find(random_mission_grid, NewGridID),
	case Type of
	1 -> %%任务 
		{_, TaskIDs} = lists:keyfind(big_level(RoleLevel), 1, Args),
		{TaskID, _} = common_tool:list_random(TaskIDs),
		NewMission = Mission#r_random_mission{level=NewLevel, grid_id=NewGridID,
											  task_id=TaskID, task_status=?TASK_START, task_progress=0,
											  chances=Chances-1, time=Now},
		mod_daily_counter:set_mission_remain_times(RoleID, 1013, Chances-1,true),
		{NewMission, lists:sort(Arrows)};
	2 -> %%礼包
		{_, Gifts} = lists:keyfind(big_level(RoleLevel), 1, Args),
		Raffle = raffle(random:uniform(lists:sum([W||{_,_,W}<-Gifts])), 0, Gifts),
		present(gift, RoleID, [Raffle]),
		NewMission = Mission#r_random_mission{level=NewLevel, grid_id=NewGridID,
											  task_id=0, task_status=0, task_progress=0,
											  chances=Chances-1, time=Now},
		mod_daily_counter:set_mission_remain_times(RoleID, 1013, Chances-1,true),
		{NewMission, lists:sort(Arrows)};
	3 -> %%前进
		Step2 = case Args of
			[Step3] ->
				Step3;
			[] ->
				case random:uniform(5) of 4 -> 5; 5 -> 6; Others -> Others end
		end,
		roll(RoleID, Step2, Mission#r_random_mission{level=NewLevel, grid_id=NewGridID}, lists:sort([NewGridID|Arrows]));
	4 -> %%增加次数
		[AddChances] = Args,
		NewMission = Mission#r_random_mission{level=NewLevel, grid_id=NewGridID,
											  task_id=0, task_status=0, task_progress=0,
											  chances=Chances+AddChances-1, time=Now},
		mod_daily_counter:set_mission_remain_times(RoleID, 1013, Chances+AddChances-1,true),
		{NewMission, lists:sort(Arrows)};
	_ ->
		NewMission = Mission#r_random_mission{level=NewLevel, grid_id=NewGridID,
											  task_id=0, task_status=0, task_progress=0,
											  chances=Chances-1, time=Now},
		mod_daily_counter:set_mission_remain_times(RoleID, 1013, Chances-1,true),
		{NewMission, lists:sort(Arrows)}						
	end.

present(Reason, RoleID, Rewards) ->
	present(exp, Reason, RoleID, lists:keyfind(?PRESENT_EXP, 1, Rewards)),
	present(gold_bind, Reason, RoleID, lists:keyfind(?PRESENT_GOLD_BIND, 1, Rewards)),
	present(silver_bind, Reason, RoleID, lists:keyfind(?PRESENT_SILVER_BIND, 1, Rewards)),
	present(prestige, Reason, RoleID, lists:keyfind(?PRESENT_PRESTIGE, 1, Rewards)),
	present(goods, Reason, RoleID, [#r_goods_create_info{
		bind    = true, 
		type    = ?TYPE_ITEM, 
		type_id = TypeID, 
		num     = Num
	}||{TypeID, Num}<-Rewards, TypeID > 10]).

present(exp, _Reason, RoleID, {_, Value}) ->
	mod_map_role:do_add_exp(RoleID, Value);

present(goods, Reason, RoleID, CreateInfos) when length(CreateInfos) > 0 ->
	ReasonInt = case Reason of levelup -> 1; gift -> 2; mission_complete -> 3; _ -> 0 end,
	case mod_bag:get_empty_bag_pos_num(RoleID, 1) of
		{ok,Num} when Num >= length(CreateInfos) ->
			case ?_trans(mod_bag:create_goods(RoleID, CreateInfos)) of
				{_,{ok, UpdateList}} ->
					R = #m_random_mission_present_toc{type=1, reason=ReasonInt, rewards=UpdateList},
					common_item_logger:log(RoleID, CreateInfos, ?LOG_ITEM_TYPE_RADMON_MISSION_REWARD);
				{_,Error} ->
					R = [],
					?ERROR_LOG("create goods error: ~p", [Error])
			end;
		_ ->
			GoodsList2 = lists:concat([case mod_bag:create_p_goods(RoleID, CreateInfo) of
		    	{ok, GoodsList} ->
			   		[R#p_goods{id = 1} || R <- GoodsList];
		   		_ ->
			   		[]
		   	end||CreateInfo<-CreateInfos]),
			common_letter:sys2p(RoleID,"恭喜你获得遗迹探险奖励道具：","遗迹探险奖励",GoodsList2,14),
			R = #m_random_mission_present_toc{type=2, reason=ReasonInt, rewards=GoodsList2}
	end,
	common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?RANDOM_MISSION, ?RANDOM_MISSION_PRESENT, R);

present(_Type, _Reason, _RoleID, _Value) ->
	ignore.

big_level(Level) ->
	if
	Level >= 160 -> 160;
	Level >= 150 -> 150;
	Level >= 140 -> 140;
	Level >= 130 -> 130;
	Level >= 120 -> 120;
	Level >= 110 -> 110;
	Level >= 100 -> 100;
	Level >= 90 -> 90;
	Level >= 80 -> 80;
	Level >= 70 -> 70;
	Level >= 60 -> 60;
	Level >= 50 -> 50;
	Level >= 40 -> 40;
	Level >= 30 -> 30;
	Level >= 20 -> 20;
	Level >= 10 -> 10;
	true -> 10
	end.

raffle(Random, WeightSum, [{ID, Num, Weight}|Gifts]) ->
	if
	Random =< WeightSum + Weight ->
		{ID, Num};
	true ->
		raffle(Random, WeightSum + Weight, Gifts)
	end.

