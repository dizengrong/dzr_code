%%%-------------------------------------------------------------------
%%% @author dizengrong
%%% @doc
%%% 	每日活动处理，包括活跃度、活动以及经验找回
%%% @end
%%% Created : 2013-3-15
%%%-------------------------------------------------------------------
-module (mod_daily_activity).

-include("mgeem.hrl").

-export([handle/1, do_finish_task/2, gm_set_exp_back/1]).
%% for role_misc
-export([init/2, delete/1]).
%% for test
-export([get_task_rec/1]).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, Method, Msg)).
-define(DEFAULT_ACTIVITY_TYPE, 		1).
-define(EXP_BACK_NOT_FETCH, 		0).		%% 经验找回未领取
-define(EXP_BACK_FETCHED, 			1).		%% 经验找回已领取


init(RoleID, ActivityTaskRec) ->
	case ActivityTaskRec of 
		false -> ActivityTaskRec1 = #r_activity_task{update_time = common_tool:now()};
		_ 	  -> ActivityTaskRec1 = ActivityTaskRec
	end,
	set_task_rec(RoleID, ActivityTaskRec1).

delete(RoleID) ->
	mod_role_tab:erase(RoleID, r_activity_task).

get_task_rec(RoleID) ->
	ActivityTaskRec = mod_role_tab:get(RoleID, r_activity_task),
	Now             = common_tool:now(),
	DiffDays        = common_tool:diff_days(Now, ActivityTaskRec#r_activity_task.update_time),
	if
		DiffDays == 0 ->
			ActivityTaskRec1 = ActivityTaskRec;
		DiffDays == 1 ->
			ActivityTaskRec1 = ActivityTaskRec#r_activity_task{
				tasks            = [], 
				tasks_history    = build_exp_task_info(RoleID, ActivityTaskRec#r_activity_task.tasks),
				point_list       = [], 
				points           = 0, 
				points_cur_award = 0, 
				update_time      = Now},
			mod_role_tab:put(RoleID, r_activity_task, ActivityTaskRec1);
		true -> %% 相隔天数>=2了
			ActivityTaskRec1 = #r_activity_task{
				tasks_history = build_default_exp_task_info(RoleID), 
				update_time   = Now},
			mod_role_tab:put(RoleID, r_activity_task, ActivityTaskRec1)
	end,
	ActivityTaskRec1.
set_task_rec(RoleID, ActivityTaskRec) ->
	mod_role_tab:put(RoleID, r_activity_task, ActivityTaskRec).

gm_set_exp_back(RoleID) ->
	ActivityTaskRec  = get_task_rec(RoleID),
	ActivityTaskRec1 = ActivityTaskRec#r_activity_task{update_time = 0},
	set_task_rec(RoleID, ActivityTaskRec1).


%% 构建默认的昨日经验活动列表
build_default_exp_task_info(RoleID) ->
	{ok, #p_role_attr{level=RoleLv}}  = mod_map_role:get_role_attr(RoleID),
	Fun = fun({ActivityID, _, _}, Acc) ->
		#r_activity_today{need_level=NeedLevel} = cfg_activity:activity(ActivityID),
		case RoleLv >= NeedLevel of 
			true -> [{ActivityID, 0, ?EXP_BACK_NOT_FETCH} | Acc];
			false -> Acc
		end
	end,
	lists:foldl(Fun, [], cfg_activity:exp_activity()).

build_exp_task_info(RoleID, Tasks) ->
	{ok, #p_role_attr{level=RoleLv}}  = mod_map_role:get_role_attr(RoleID),
	Fun = fun({ActivityID, _, _}, Acc) ->
		ActivityConf = cfg_activity:activity(ActivityID),
		DoneTimes    = get_done_times(ActivityID, Tasks),
		case DoneTimes >= ActivityConf#r_activity_today.total_times 
			 orelse ActivityConf#r_activity_today.need_level > RoleLv of
			true  -> Acc;
			false -> [{ActivityID, DoneTimes, ?EXP_BACK_NOT_FETCH} | Acc]
		end
	end,
	lists:foldl(Fun, [], cfg_activity:exp_activity()).




handle({?ACTIVITY_TODAY, DataIn, RoleID}) ->
	do_today(RoleID, DataIn);
handle({?ACTIVITY_BENEFIT_LIST, _DataIn, RoleID}) ->
	do_get_point_list(RoleID);
handle({?ACTIVITY_BENEFIT_REWARD, DataIn, RoleID}) ->
	do_benefit_reward(RoleID, DataIn);
handle({?ACTIVITY_BENEFIT_BUY, DataIn, RoleID}) ->
	do_buy_benefit(RoleID, DataIn);
handle({?ACTIVITY_EXP_BACK_INFO, _DataIn, RoleID}) ->
	do_exp_back_info(RoleID);
handle({?ACTIVITY_EXP_BACK_FETCH, DataIn, RoleID}) ->
	do_exp_back_fetch(RoleID, DataIn);
handle({?ACTIVITY_EXP_BACK_AUTO_FETCH, DataIn, RoleID}) ->
	do_exp_back_auto_fetch(RoleID, DataIn).


do_today(RoleID, #m_activity_today_tos{type=TypeIn}) ->
	{ok, #p_role_attr{level=Level}}  = mod_map_role:get_role_attr(RoleID),
    {ok, #p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),

    %% 获取玩家的符合条件的活动列表
    ActivityTodayList = cfg_activity:show_activity(),
    FilterFun = fun(ActivityID) ->
    	#r_activity_today{need_level=NeedLevel,types=Types} = cfg_activity:activity(ActivityID),
    	lists:member(TypeIn, Types) andalso Level>=NeedLevel
    end,
	MatchedList     = lists:filter(FilterFun, ActivityTodayList),
	ActivityTaskRec = get_task_rec(RoleID),
	ResList         = [update_activity_status(RoleID, ActivityID, FamilyID, ActivityTaskRec#r_activity_task.tasks) || ActivityID <- MatchedList],
	Msg             = #m_activity_today_toc{succ = true, activity_list = ResList},
    ?MOD_UNICAST(RoleID, ?ACTIVITY_TODAY, Msg).

update_activity_status(_RoleID, ActivityID, FamilyID, DoneTasks) ->
	#r_activity_today{
		order_id    = OrderID,
		need_family = IsNeedFamily,
		total_times = TotalTimes} = cfg_activity:activity(ActivityID),
    CheckFamiliy = ( IsNeedFamily=/=true orelse FamilyID>0 ),
    if
        CheckFamiliy->
			Status    = 1,
			DoneTimes = get_done_times(ActivityID, DoneTasks);
        true->
			Status    = 0,
			DoneTimes = 0
    end,
    
    #p_activity_info{
		id          = ActivityID,
		order_id    = OrderID,
		type        = ?DEFAULT_ACTIVITY_TYPE,
		status      = Status,
		done_times  = DoneTimes,
		total_times = TotalTimes}.

do_get_point_list(RoleID) ->
	ActivityTaskRec = get_task_rec(RoleID),
	Point           = ActivityTaskRec#r_activity_task.points,
	PointAwardId    = cfg_activity:get_reward_id_by_activity_point(Point),
	CurAward = ActivityTaskRec#r_activity_task.points_cur_award,
	Fun1 = fun(AwardId) ->
		if
			PointAwardId >= AwardId andalso AwardId > CurAward -> AwardState = 1;
			PointAwardId >= AwardId andalso AwardId =< CurAward -> AwardState = 2;
			true -> AwardState = 0
		end,
		{AwardId, AwardState}
	end,
	Fun2 = fun(ActivityID) ->
		DoneTimes    = get_done_times(ActivityID, ActivityTaskRec#r_activity_task.point_list),
		ActivityConf = cfg_activity:activity(ActivityID),
		{ActivityID, ActivityConf#r_activity_today.total_times - DoneTimes}
	end,

	Msg = #m_activity_benefit_list_toc{
		act_task_list = [Fun2(Id1) || Id1 <- cfg_activity:activity_in_points()],
		reward_list   = [Fun1(Id2) || Id2 <- cfg_activity:activity_point_reward_list()],
		point         = Point
	},
    ?MOD_UNICAST(RoleID, ?ACTIVITY_BENEFIT_LIST, Msg).

do_benefit_reward(RoleID, #m_activity_benefit_reward_tos{reward_id = RewardId}) ->
    {ok, #p_role_attr{level=RoleLevel}}  = mod_map_role:get_role_attr(RoleID),
	ActivityTaskRec = get_task_rec(RoleID),
	PointAwardId    = cfg_activity:get_reward_id_by_activity_point(ActivityTaskRec#r_activity_task.points),
	Ret = if
		ActivityTaskRec#r_activity_task.points_cur_award >= PointAwardId ->
			{error, <<"当前无奖励可领取">>};
		ActivityTaskRec#r_activity_task.points_cur_award + 1 =/= RewardId -> 
			{error, <<"请先领取前面的宝箱奖励">>};
		true ->
			ItemInfoList = cfg_activity:get_activity_point_reward(RewardId, RoleLevel),
			case mod_bag:add_items(RoleID, ItemInfoList, ?LOG_ITEM_TYPE_ACTIVITY_POINT_AWARD) of 
				{error, Reason} -> {error, Reason};
				{true, _} -> true
			end
	end,
	case Ret of 
		{error, Reason1} ->
			common_misc:send_common_error(RoleID, 0, Reason1);
		true ->
			ActivityTaskRec1 = ActivityTaskRec#r_activity_task{points_cur_award = RewardId},
			set_task_rec(RoleID, ActivityTaskRec1),
			do_get_point_list(RoleID)
	end.

do_buy_benefit(RoleID, #m_activity_benefit_buy_tos{act_task_id=0}) ->
    {ok, #p_role_attr{level=RoleLevel}}  = mod_map_role:get_role_attr(RoleID),
	ActivityTaskRec = get_task_rec(RoleID),
	Fun = fun(ActivityID, {CostGold, TotalPoint, NewActivityTaskRec, Items}) ->
		DoneTimes       = get_done_times(ActivityID, NewActivityTaskRec#r_activity_task.point_list),
		ActivityConf    = cfg_activity:activity(ActivityID),
		MaxTimes        = ActivityConf#r_activity_today.total_times,
		case DoneTimes < ActivityConf#r_activity_today.total_times of
			true ->
				CostGold1   = CostGold + 3*(MaxTimes - DoneTimes),
				TotalPoint1 = TotalPoint + ActivityConf#r_activity_today.add_ap,
				NewActivityTaskRec1 = NewActivityTaskRec#r_activity_task{
					points          = NewActivityTaskRec#r_activity_task.points + ActivityConf#r_activity_today.add_ap,
					point_buy_times = NewActivityTaskRec#r_activity_task.point_buy_times + 1,
					point_list      = set_done_times(ActivityID, MaxTimes, NewActivityTaskRec#r_activity_task.point_list)
				},
				Items1 = cfg_activity:finish_activity_times_reward(ActivityID, RoleLevel) ++ Items,
				{CostGold1, TotalPoint1, NewActivityTaskRec1, Items1};
			false ->
				{CostGold, TotalPoint, NewActivityTaskRec, Items}
		end
	end,
	{CostGold2, TotalPoint2, NewActivityTaskRec2, Items2} = lists:foldl(Fun, {0, 0, ActivityTaskRec, []}, cfg_activity:activity_in_points()),
	Ret = case common_bag2:use_money(RoleID, gold_unbind, CostGold2, ?CONSUME_TYPE_GOLD_ACTIVITY_BENEFIT_BUY) of
		{error, Reason} -> {error, Reason};
		true ->
			set_task_rec(RoleID, NewActivityTaskRec2),
			add_actpoint_to_role(RoleID, TotalPoint2),
			send_activity_point_finish_reward_help(RoleID, Items2),
			true
	end,
	case Ret of 
		{error, Reason1} -> common_misc:send_common_error(RoleID, 0, Reason1);
		true -> do_get_point_list(RoleID)
	end;
do_buy_benefit(RoleID, #m_activity_benefit_buy_tos{act_task_id=ActivityID}) ->
	ActivityTaskRec = get_task_rec(RoleID),
	DoneTimes       = get_done_times(ActivityID, ActivityTaskRec#r_activity_task.point_list),
	ActivityConf    = cfg_activity:activity(ActivityID),
	MaxTimes        = ActivityConf#r_activity_today.total_times,
	Ret = case lists:member(ActivityID, cfg_activity:activity_in_points())
		andalso DoneTimes < ActivityConf#r_activity_today.total_times of 
		true ->
			Cost = 3*(MaxTimes - DoneTimes),
			case common_bag2:use_money(RoleID, gold_unbind, Cost, ?CONSUME_TYPE_GOLD_ACTIVITY_BENEFIT_BUY) of
				{error, Reason} -> {error, Reason};
				true ->
					ActivityTaskRec1 = ActivityTaskRec#r_activity_task{
						points          = ActivityTaskRec#r_activity_task.points + ActivityConf#r_activity_today.add_ap,
						point_buy_times = ActivityTaskRec#r_activity_task.point_buy_times + 1,
						point_list      = set_done_times(ActivityID, MaxTimes, ActivityTaskRec#r_activity_task.point_list)
					},
					set_task_rec(RoleID, ActivityTaskRec1),
					add_actpoint_to_role(RoleID, ActivityConf#r_activity_today.add_ap),
					send_activity_point_finish_reward(RoleID, ActivityID),
					true
			end;
		false -> {error, <<"该活动没有参与活动度积分">>}
	end,
	case Ret of 
		{error, Reason1} -> common_misc:send_common_error(RoleID, 0, Reason1);
		true -> do_get_point_list(RoleID)
	end.

do_exp_back_info(RoleID) ->
	{ok, #p_role_attr{level=RoleLevel}}  = mod_map_role:get_role_attr(RoleID),
	ActivityTaskRec = get_task_rec(RoleID),
	Fun = fun({ActivityID, DoneTimes, Status}) ->
		ActivityConf = cfg_activity:activity(ActivityID),
		Exp      = cfg_activity:get_exp(ActivityID, RoleLevel),
		TotalExp = (ActivityConf#r_activity_today.total_times - DoneTimes) * Exp,
		#p_exp_back_info{
			id          = ActivityID,
			name        = ActivityConf#r_activity_today.name,
			done_times  = DoneTimes,
			status      = Status,
			total_times = ActivityConf#r_activity_today.total_times,
			exp         = TotalExp}
	end,
	Msg = #m_activity_exp_back_info_toc{
		task_infos = [Fun(Data) || Data <- ActivityTaskRec#r_activity_task.tasks_history]
	},
    ?MOD_UNICAST(RoleID, ?ACTIVITY_EXP_BACK_INFO, Msg).

do_exp_back_fetch(RoleID, #m_activity_exp_back_fetch_tos{id=ActivityID,type=Type}) ->
	ActivityTaskRec = get_task_rec(RoleID),
	case lists:keyfind(ActivityID, 1, ActivityTaskRec#r_activity_task.tasks_history) of
		false -> 
			{error, <<"该活动没有参与经验找回">>};
		{_, _, FetchState} when FetchState == ?EXP_BACK_FETCHED ->
			{error, <<"该经验已经找回过了">>};
		{_, DoneTimes, _} ->
			ActivityConf    = cfg_activity:activity(ActivityID),
			%% 记住通过get_task_rec/1方法得到的tasks_history中的经验找回活动
			%% 如果次数已经完成了的话，这里是不会出现的，因此UnFinishTimes一定大于0
			UnFinishTimes = ActivityConf#r_activity_today.total_times - DoneTimes,
			{MoneyType, Cost, Percentage} = cfg_activity:exp_cost(Type),
			if
		        MoneyType =:= silver_any ->  LogType = ?CONSUME_TYPE_SILVER_FETCH_EXP_BACK;
		        true -> LogType = ?CONSUME_TYPE_GOLD_FETCH_EXP_BACK
		    end,
			case common_bag2:use_money(RoleID, MoneyType, Cost, LogType) of
				{error, Reason} ->
					common_misc:send_common_error(RoleID, 0, Reason);
				true ->
    				{ok, #p_role_attr{level=RoleLevel}}  = mod_map_role:get_role_attr(RoleID),
					TotalExp = UnFinishTimes * cfg_activity:get_exp(ActivityID, RoleLevel),
					mod_map_role:add_exp(RoleID, (TotalExp*Percentage) div 100),
					ActivityTaskRec1 = ActivityTaskRec#r_activity_task{
						tasks_history = lists:keystore(ActivityID, 1, ActivityTaskRec#r_activity_task.tasks_history, {ActivityID, DoneTimes, ?EXP_BACK_FETCHED})
					},
					set_task_rec(RoleID, ActivityTaskRec1),
					do_exp_back_info(RoleID)
			end
	end.

do_exp_back_auto_fetch(RoleID, #m_activity_exp_back_auto_fetch_tos{type = Type}) ->
	{ok, #p_role_attr{level=RoleLv}}  = mod_map_role:get_role_attr(RoleID),
	ActivityTaskRec = get_task_rec(RoleID),
	{MoneyType, Cost, Percentage} = cfg_activity:exp_cost(Type),
	Fun = fun({ActivityID, DoneTimes, State}, {TotalExp, TotalCost}) ->
		case State == ?EXP_BACK_FETCHED of
			true -> {TotalExp, TotalCost};
			false ->
				ActivityConf  = cfg_activity:activity(ActivityID),
				UnFinishTimes = ActivityConf#r_activity_today.total_times - DoneTimes,
				TotalExp1     = TotalExp + (UnFinishTimes * cfg_activity:get_exp(ActivityID, RoleLv))*Percentage,
				TotalCost1    = TotalCost + Cost,
				{TotalExp1, TotalCost1}
		end
	end,
	{TotalExp2, TotalCost2} = lists:foldl(Fun, {0, 0}, ActivityTaskRec#r_activity_task.tasks_history),
	if
        MoneyType =:= silver_any ->  LogType = ?CONSUME_TYPE_SILVER_FETCH_EXP_BACK;
        true -> LogType = ?CONSUME_TYPE_GOLD_FETCH_EXP_BACK
    end,
    case TotalCost2 == 0 of 
    	true ->
			common_misc:send_common_error(RoleID, 0, <<"经验都已找回，无需再次找回">>);
    	false ->
			case common_bag2:use_money(RoleID, MoneyType, TotalCost2, LogType) of
				{error, Reason} ->
					common_misc:send_common_error(RoleID, 0, Reason);
				true ->
					mod_map_role:add_exp(RoleID, TotalExp2 div 100),
					set_all_exp_fetched(ActivityTaskRec#r_activity_task.tasks_history),
					ActivityTaskRec1 = ActivityTaskRec#r_activity_task{
						tasks_history = set_all_exp_fetched(ActivityTaskRec#r_activity_task.tasks_history)
					},
					set_task_rec(RoleID, ActivityTaskRec1),
					do_exp_back_info(RoleID)
			end
	end.

set_all_exp_fetched(TasksHistory) ->
	set_all_exp_fetched(TasksHistory, []).
set_all_exp_fetched([], NewTasksHistory) -> NewTasksHistory;
set_all_exp_fetched([{ActivityID, DoneTimes, _} | Rest], NewTasksHistory) ->
	set_all_exp_fetched(Rest, [{ActivityID, DoneTimes, ?EXP_BACK_FETCHED} | NewTasksHistory]).

%% 玩家完成活动任务,只是增加勋章，设置完成次数
do_finish_task(RoleID, ActivityID)->
	ActivityTaskRec = get_task_rec(RoleID),
	DoneTimes1      = get_done_times(ActivityID, ActivityTaskRec#r_activity_task.point_list),
	DoneTimes2      = get_done_times(ActivityID, ActivityTaskRec#r_activity_task.tasks),
	ActivityConf    = cfg_activity:activity(ActivityID),
	MaxTimes        = ActivityConf#r_activity_today.total_times,
	case DoneTimes2 >= MaxTimes of 
		true -> ignore;
		false ->
			case DoneTimes2 + 1 >= MaxTimes of %% 完成了所有次数才加活跃度分数的
				true  -> 
                    do_exp_back_info(RoleID),
					send_activity_point_finish_reward(RoleID, ActivityID),
					AddPoint = ActivityConf#r_activity_today.add_ap;
				false -> AddPoint = 0
			end,
			case DoneTimes1 >= MaxTimes of 
				true  -> PointList = ActivityTaskRec#r_activity_task.point_list;
				false -> PointList = set_done_times(ActivityID, DoneTimes2 + 1, ActivityTaskRec#r_activity_task.point_list)
			end,
			ActivityTaskRec1 = ActivityTaskRec#r_activity_task{
				tasks      = set_done_times(ActivityID, DoneTimes2 + 1, ActivityTaskRec#r_activity_task.tasks),
				point_list = PointList,
				points     = ActivityTaskRec#r_activity_task.points + AddPoint
			},
			set_task_rec(RoleID, ActivityTaskRec1),
			add_actpoint_to_role(RoleID, AddPoint),
			case DoneTimes1 < MaxTimes orelse
				 ActivityTaskRec#r_activity_task.points =/= ActivityTaskRec1#r_activity_task.points of 
				true  -> do_get_point_list(RoleID);
				false -> ignore
			end,
			send_role_activity_update_info(RoleID, ActivityID, ActivityTaskRec1#r_activity_task.tasks)
	end.

send_activity_point_finish_reward(RoleID, ActivityID) ->
    {ok, #p_role_attr{level=RoleLevel}}  = mod_map_role:get_role_attr(RoleID),
    Items = cfg_activity:finish_activity_times_reward(ActivityID, RoleLevel),
    send_activity_point_finish_reward_help(RoleID, Items).
send_activity_point_finish_reward_help(_RoleID, []) -> ignore;
send_activity_point_finish_reward_help(RoleID, Items) ->
    case mod_bag:add_items(RoleID, Items, ?LOG_ITEM_TYPE_ACTIVITY_POINT_TIMES_AWARD) of 
		{error, _Reason} -> 
			Text  = "亲爱的玩家，由于之前您活跃度次数完成发放的奖励未能成功领取，"
					"所以系统以邮件的形式发给您了。",
			Title = "活跃度次数完成奖励",
			CreateInfoList = common_misc:get_items_create_info(RoleID, Items),
			GoodsList      = common_misc:get_mail_items_create_info(RoleID, CreateInfoList),
			common_letter:sys2p(RoleID, Text, Title, GoodsList, 14);
		{true, _} -> true
	end.


	

%% 推送玩家的单个活动状态信息
send_role_activity_update_info(RoleID, ActivityID, ActTaskList) ->
    {ok, #p_role_base{family_id = FamilyID}} = mod_map_role:get_role_base(RoleID),
	ActInfo = update_activity_status(RoleID, ActivityID, FamilyID, ActTaskList),
    mod_share_invite:cast_share_invite_info(RoleID, ActivityID),
	Msg     = #m_activity_today_update_toc{info = ActInfo},
    common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_TODAY_UPDATE, Msg).

%% ==================================================================
%% 由于活跃度分数在人物信息数据中存在，因此用该方法来增加玩家的活跃度
add_actpoint_to_role(_RoleID, 0) -> ignore;
add_actpoint_to_role(RoleID, AddActivePt) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    RoleAttr2 = RoleAttr#p_role_attr{
    	active_points = RoleAttr#p_role_attr.active_points + AddActivePt
    },
	mod_map_role:set_role_attr_no_t(RoleID, RoleAttr2),
	ChangeAttList = [#p_role_attr_change{change_type=?ROLE_ACTIVE_POINTS_CHANGE,new_value=RoleAttr2#p_role_attr.active_points}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).
%% ==================================================================


%% ==================================================================
%% 获取活动的完成次数, DoneTasks: [{活动id, 完成次数}]
get_done_times(ActivityID, DoneTasks) ->
	case lists:keyfind(ActivityID, 1, DoneTasks) of 
		false -> DoneTimes = 0;
		{_, DoneTimes} -> ok
	end,
	DoneTimes.
set_done_times(ActivityID, DoneTimes, DoneTasks) ->
	lists:keystore(ActivityID, 1, DoneTasks, {ActivityID, DoneTimes}).
%% ==================================================================


