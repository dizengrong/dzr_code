%%mail:laojiajie@4399.net
%%2012-9-7

%% 记录模式：
%% mod1: One Status
%% mod2: Times Counter
%% mod3: length([{RoleID,Value}])
%% mod4: Status List
%% mod5: special ID

%% data文件：
%% data_achieve:get_target_1(Type,SubType), 	   	%% 目标：目标数量
%% data_achieve:get_target_1(Type,SubType), 		%% 目标：{目标数量,目标值}
%% data_achieve:get(Type,SubType), 			   		%% cfg数据
%% data_achieve:get_point(Type,SubType),	   		%% 成就点
%% data_achieve:get_award(Type,SubType),	  		%% 奖励
%% data_achieve:get_notify_list(Code),		  		%% 通知列表
%% data_achieve:get_title(Type,SubType),	  	 	%% 称号

-module (mod_achieve).


-behaviour(gen_server).

-include("common.hrl").

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-export([start_link/1]).


-compile(export_all).

-define(CACHE_ACHIEVE_REF, cache_util:get_register_name(achieve)).

-record(state,{
		finish_list = [],
		award_list = []
	}).

-export([get_title/1,get_point/1]).

-export([
		getTotalPoint/1,       	%% 成就总览
		getAchieveTypeInfo/2,  	%% 成就大类信息
		getAwardCanTake/1,	   	%% 可领奖励的成就列表
		takeAward/3				%% 领取某成就的奖励
	]).

-export([
		mainRoleLevelNotify/2, 	%% 主角等级变动
		roleLevelNotify/3,
		goldUse/2,
		employNotify/1,
		intenNotify/3,
		xunxianNotify/2,
		silverNotify/1,
		marstowerNotify/2,
		officialNotify/1,
		qihunNotify/2,
		pinjieNotify/3,
		taskNotify/2,
		gankTaskNotify/2,
		schoolTaskNotify/2,
		friendNotify/1,
		friendSendNotify/2,
		familiarNotify/2,
		yunbiaoNotify/2,
		jiebiaoNotify/2,
		useHornNotify/2,
		gankUpgrateNotify/2,
		fightabilityNotify/2,
		arenaNotify/2
		]).

-export([jewelNotify/1,roleItemNotify/1]).

start_link(AccountID) ->
	gen_server:start_link(?MODULE, [AccountID], []).

%% 用户登录初始化数据
init([AccountID]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
	AllAchieveInfo = cache_getAllAchieve(AccountID),
	FinishList = selectFinishAchieve(AllAchieveInfo),
	AwardList = selectAwardAchieve(AllAchieveInfo),
	NewState = #state{finish_list = FinishList,award_list = AwardList},
    {ok, NewState}.

%% 获取成就称号id
get_title(_AccountID) -> 
	0.

get_point(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.achieve_pid,{get_point,AccountID}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 获取成就总览
getTotalPoint(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{getTotalPoint,AccountID}).

%% 获取某大类成就信息 mod_achieve:getAchieveTypeInfo(600433,1).
getAchieveTypeInfo(AccountID,Type) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{getAchieveTypeInfo,AccountID,Type}).

%% 获取可领奖励的成就信息
getAwardCanTake(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{getAwardCanTake,AccountID}).

%% 获取某成就的奖励
takeAward(AccountID,Type,SubType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{takeAward,{AccountID,Type,SubType}}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 一些可以并为一类的成就  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 主角等级变动
mainRoleLevelNotify(AccountID,Level) ->
	notify1(AccountID,Level,1).

%% 佣兵等级变动
roleLevelNotify(AccountID,RoleID,Level) ->
	notify3(AccountID,RoleID,Level,2).

%% 强化N件装备到M级
intenNotify(AccountID,WorldID,Level) ->
	notify3(AccountID,WorldID,Level,16).

%% 寻仙
xunxianNotify(AccountID,Times) ->
	notify2(AccountID,Times,19).

%% 通关战神塔
marstowerNotify(AccountID,Floor) ->
	notify1(AccountID,Floor,11).

%% 官职
officialNotify(AccountID) ->
	Official = mod_official:get_official_position(AccountID),
	notify1(AccountID,Official,3).

%% 器魂神器
qihunNotify(AccountID,Level) ->
	?INFO(achieve,"qihunNotify, Level = ~w",[Level]),
	notify1(AccountID,Level,4).

%% 器魂品阶
pinjieNotify(AccountID,ID,Level) ->
	notify3(AccountID,ID,Level,20).

%% 主线任务
taskNotify(AccountID,TaskID) ->
	notify5(AccountID,TaskID,5).

%% 好友数量
friendNotify(AccountID) ->
	FullList = mod_relationship:get_all_friend_list(AccountID),
	?INFO(achieve,"friendNum = ~w",[length(FullList)]),
	notify1(AccountID,length(FullList),8).

%% 运镖50,300次
yunbiaoNotify(AccountID,Times) ->
	notify2(AccountID,Times,7).

%% 所在公会升级到某一级
gankUpgrateNotify(AccountID,Level) ->
	notify1(AccountID,Level,10).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 一些比较琐碎的成就  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 使用元宝一次
goldUse(AccountID,Num) ->
	?INFO(achieve,"USE Gold = ~w",[Num]),
	PS = mod_player:get_player_status(AccountID),
	case Num > 0 of
		true ->
			gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,1,3,Num});
		false ->
			void
	end.

%% 招募任意两个武将
employNotify(AccountID) ->
	EmployList = mod_role:get_employed_id_list2(AccountID, []),
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,1,4,length(EmployList)-1}).

%% 拥有一亿银币
silverNotify(AccountID) ->
	Balance = mod_economy:get(AccountID),
	Silver = Balance#economy.gd_silver,
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,8,3,Silver}).

%% 参加师门任务50,200次
schoolTaskNotify(AccountID,Num) ->
	notify2(AccountID,Num,6).

%% 帮派任务
gankTaskNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,3,11,Num}).

%% 送祝福50次
friendSendNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,4,3,Num}).

%% 亲密度达2000
familiarNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,4,6,Num}).

%% 劫镖300次
jiebiaoNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,8,8,Num}).

%% 神器
shenqiStageNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,8,7,Num}).

%% 小喇叭
useHornNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,1,2,Num}).

%% 加入一个帮会
joinGankNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,1,8,Num}).

%% 战斗力到10W
fightabilityNotify(AccountID,Num)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,8,5,Num}).

%% 参加一次竞技场
arenaNotify(AccountID,Num) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,1,9,Num}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  一些比较坑爹的成就  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 宝石成就
jewelNotify(AccountID) ->
	ItemList = cache_items:getItemsByType(AccountID, 3),
	Fun = fun(Item,SumList) ->
		SumList ++ Item#item.gd_InlayInfo
	end,
	SumList = lists:foldl(Fun,[],ItemList),
	Fun1 = fun({_pos,CfgID},LevelList) ->
		CfgItem = data_items:get(CfgID),
		LevelList ++ [CfgItem#cfg_item.cfg_RoleLevel]
	end,
	LevelList = lists:foldl(Fun1,[],SumList),
	?INFO(achieve,"Jewel LevelList = ~w",[LevelList]),
	notify4(AccountID,LevelList,18).

%% 装备成就
roleItemNotify(AccountID) ->
	RoleIDList = mod_role:get_employed_id_list(AccountID),
	F = fun(RoleID,AccountID1) ->
		ItemList = cache_items:getItemsByRole(AccountID1, RoleID),
		F2 = fun(Item,QualityList) ->
			case Item#item.gd_BagPos =< 6 of
				true ->
					Level = Item#item.gd_Quality,
					QualityList++[Level];
				false ->
					QualityList
			end
			end,
		lists:foldl(F2,[],ItemList)
		end,
	QualityListList = [F(RoleID,AccountID)|| RoleID <- RoleIDList],
	F3 = fun (QualityList) ->
		length(lists:filter(fun(Quality) -> Quality >= 4 end,QualityList))
		end,
	F4 = fun (QualityList) ->
		length(lists:filter(fun(Quality) -> Quality >= 5 end,QualityList))
		end,
	List1 = lists:sort(lists:map(F3,QualityListList)++[0,0]),
	List2 = lists:sort(lists:map(F4,QualityListList)++[0,0]),
	Num1 = lists:last(List1),
	Num2 = lists:last(List2) + lists:last(List2 -- [lists:last(List2)]),
	AllRoleItemList = cache_items:getItemsByType(AccountID, 3),
	F5 = fun (Item,Num3) ->
		case (Item#item.gd_IntensifyLevel div 5) >= 15 andalso Item#item.gd_Quality >= 5 of
			true ->
				Num3 +1;
			false ->
				Num3
		end
		end,
	Num3 = lists:foldl(F5,0,AllRoleItemList),
	?INFO(achieve,"Num1 =~w,Num2 = ~w,Num3 = ~w",[Num1,Num2,Num3]),
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,7,4,Num1}),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,7,5,Num2}),
	gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,8,4,Num3}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 通知类型1：
notify1(AccountID,Num,Code)->
	PS = mod_player:get_player_status(AccountID),
	NotifyList = data_achieve:get_notify_list(Code),
	?INFO(achieve,"NotifyList = ~w",[NotifyList]),
	Fun = fun({Type,SubType}) ->
		gen_server:cast(PS#player_status.achieve_pid,{1,AccountID,Type,SubType,Num})
	end,
	lists:map(Fun,NotifyList).

%% 通知类型2:
notify2(AccountID,Num,Code) ->
	PS = mod_player:get_player_status(AccountID),
	NotifyList = data_achieve:get_notify_list(Code),
	Fun = fun({Type,SubType}) ->
		gen_server:cast(PS#player_status.achieve_pid,{2,AccountID,Type,SubType,Num})
	end,
	lists:map(Fun,NotifyList).

%% 通知类型3：
notify3(AccountID,UniqueID,Num,Code) ->
	PS = mod_player:get_player_status(AccountID),
	NotifyList = data_achieve:get_notify_list(Code),
	Fun = fun({Type,SubType}) ->
		gen_server:cast(PS#player_status.achieve_pid,{3,AccountID,Type,SubType,UniqueID,Num})
	end,
	lists:map(Fun,NotifyList).

%% 通知类型4：
notify4(AccountID,List,Code) ->
	PS = mod_player:get_player_status(AccountID),
	NotifyList = data_achieve:get_notify_list(Code),
	Fun = fun({Type,SubType}) ->
		gen_server:cast(PS#player_status.achieve_pid,{4,AccountID,Type,SubType,List})
	end,
	lists:map(Fun,NotifyList).

%% 通知类型5：
notify5(AccountID,UniqueID,Code) ->
	PS = mod_player:get_player_status(AccountID),
	NotifyList = data_achieve:get_notify_list(Code),
	Fun = fun({Type,SubType}) ->
		gen_server:cast(PS#player_status.achieve_pid,{5,AccountID,Type,SubType,UniqueID})
	end,
	lists:map(Fun,NotifyList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											handler														   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 获取总览 29000
handle_cast({getTotalPoint,AccountID},State) ->
	FinishList = State#state.finish_list,
	Fun = fun({Type,SubType},{SumPoint,TypePoint}) -> 
		case Type of
			1->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point1 = TypePoint#type_point.point1+PointAdd}};
			2->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point2 = TypePoint#type_point.point2+PointAdd}};
			3->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point3 = TypePoint#type_point.point3+PointAdd}};
			4->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point4 = TypePoint#type_point.point4+PointAdd}};
			5->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point5 = TypePoint#type_point.point5+PointAdd}};
			6->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point6 = TypePoint#type_point.point6+PointAdd}};
			7->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point7 = TypePoint#type_point.point7+PointAdd}};
			8->
				PointAdd = data_achieve:get_point(Type,SubType),
				{SumPoint+PointAdd,TypePoint#type_point{point8 = TypePoint#type_point.point8+PointAdd}};
			_Else ->
				{SumPoint,TypePoint}
			end
		end,
		{SumPoint,TypePoint} = lists:foldl(Fun,{0, #type_point{}},FinishList),
		?INFO(achieve,"SumPoint =~w,FinishNum = ~w,TypePoint = ~w",[SumPoint,length(FinishList),TypePoint]),
		{ok,BinData} = pt_29:write(29000,{SumPoint,length(FinishList),TypePoint}),
		lib_send:send(AccountID,BinData),
		{noreply,State};

%% 获取某大类成就信息 29001
handle_cast({getAchieveTypeInfo,AccountID,Type},State) ->
	case cache_getAchieve_Type(AccountID,Type) of
		[] ->
			?INFO(achieve,"HAVE A look"),
			InfoList = [];
		AchieveRecList ->
			Fun = fun(AchieveRec) ->
				{_AccountID,_Type,SubType} = AchieveRec#achieve.key,
				{SubType,AchieveRec#achieve.gd_Progress}
			end,
			InfoList = lists:map(Fun,AchieveRecList)
	end,
	?INFO(achieve,"achieve Type = ~w,InfoList = ~w",[Type,InfoList]),
	{ok,BinData} = pt_29:write(29001,{Type,InfoList}),
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 可领奖成就获取 29003
handle_cast({getAwardCanTake,AccountID},State) ->
	case State#state.award_list of
		AwardList ->
			?INFO(achieve,"AwardList = ~w",[AwardList]),
			{ok,BinData} = pt_29:write(29003,AwardList),
			lib_send:send(AccountID,BinData)
	end,
	{noreply,State};

%% 领取某个成就的奖励 29004
handle_cast({takeAward,{AccountID,Type,SubType}},State) ->
	case lists:member({Type,SubType},State#state.award_list) of
		true ->
			{Silver,BindGold,ItemList,JunGong} = data_achieve:get_award(Type,SubType),
			case mod_items:getBagNullNum(AccountID) >  length(ItemList) of
				true ->
					case length(ItemList)>0 of
						true ->
							mod_items:createItems(AccountID, ItemList, ?ITEM_FROM_ACHIEVE);
						false ->
							void
					end,
					mod_economy:add_bind_gold(AccountID,BindGold,?GOLD_ACHIEVE),
					mod_economy:add_popularity(AccountID,JunGong,?POPULARITY_FROM_ACHIEVE),
					mod_economy:add_silver(AccountID,Silver,?SILVER_FROM_ACHIEVE),
					AchieveRec = cache_getAchieve(AccountID,Type,SubType),
					NewAchieveRec = AchieveRec#achieve{gd_IsAward = 0},
					cache_update(NewAchieveRec),
					NewAwardList = State#state.award_list -- [{Type,SubType}],
					NewState = State#state{award_list = NewAwardList},
					{ok,BinData} = pt_29:write(29004,{Type,SubType}),
					lib_send:send(AccountID,BinData);
				false ->
					mod_err:send_err(AccountID,29,?ERR_ITEM_BAG_NOT_ENOUGH),
					NewState = State
			end;
		false ->
			mod_err:send_err(AccountID,29,?ERR_ACHIEVE_AWARD_ERR),
			NewState = State
	end,
	{noreply,NewState};


%% 触发成就模式一
handle_cast({1,AccountID,Type,SubType,Num},State) ->
	case lists:member({Type,SubType},State#state.finish_list) of
		true ->
			NewState = State;
		false ->
			AchieveRec = cache_getAchieve(AccountID,Type,SubType),
			case Num > AchieveRec#achieve.gd_Progress of
				false ->
					NewState = State;
				true ->
					Target = data_achieve:get_target_1(Type,SubType),
					case Num < Target of
						true ->
							NewAchieveRec = AchieveRec#achieve{gd_Progress = Num},
							NewState = State;
						false ->
							NewAchieveRec = AchieveRec#achieve{gd_Progress = Target,gd_IsFinish = 1,gd_IsAward =1},
							{ok,BinData} = pt_29:write(29002,{Type,SubType}),
							lib_send:send(AccountID,BinData),
							add_point_to_rank(AccountID,Type,SubType),
							NewState = State#state{finish_list = State#state.finish_list ++ [{Type,SubType}],
												award_list = State#state.award_list ++ [{Type,SubType}]}
					end,
					cache_update(NewAchieveRec)
			end
	end,
	{noreply,NewState};

%% 触发成就模式二
handle_cast({2,AccountID,Type,SubType,Num},State) ->
	case lists:member({Type,SubType},State#state.finish_list) of
		true ->
			?INFO(achieve,"MODE2,FinishList =~w",[State#state.finish_list]),
			NewState = State;
		false ->
			?INFO(achieve,"MODE2,Type=~w,SubType=~w,Num=~w",[Type,SubType,Num]),
			AchieveRec = cache_getAchieve(AccountID,Type,SubType),
			Target = data_achieve:get_target_2(Type,SubType),
			case AchieveRec#achieve.gd_Progress+Num < Target of
				true ->
					NewState = State,
					NewAchieveRec = AchieveRec#achieve{gd_Progress = AchieveRec#achieve.gd_Progress+Num};
				false ->
					NewState = State#state{finish_list = State#state.finish_list ++ [{Type,SubType}],
										award_list = State#state.award_list ++ [{Type,SubType}]},
					NewAchieveRec = AchieveRec#achieve{gd_Progress = Target,gd_IsFinish = 1,gd_IsAward =1},
					{ok,BinData} = pt_29:write(29002,{Type,SubType}),
					lib_send:send(AccountID,BinData),
					add_point_to_rank(AccountID,Type,SubType)
			end,
			cache_update(NewAchieveRec)
	end,
	{noreply,NewState};


%% 触发成就模式三
handle_cast({3,AccountID,Type,SubType,UniqueID,Num},State)->
	case lists:member({Type,SubType},State#state.finish_list) of
		true ->
			NewState = State;
		false ->
			AchieveRec = cache_getAchieve(AccountID,Type,SubType),
			case lists:keyfind(UniqueID,1,AchieveRec#achieve.gd_Data) of
				{_ID,_OldNum} ->
					NewState = State;
				false ->
					{TargetNum,Target} = data_achieve:get_target_3(Type,SubType),
					case Num < Target of
						true ->
							NewState = State;
						false ->
							NewData = AchieveRec#achieve.gd_Data ++ [{UniqueID,Num}],
							case length(NewData) < TargetNum of
								true ->
									NewState = State,
									NewAchieveRec = AchieveRec#achieve{gd_Progress = length(NewData),gd_Data = NewData};
								false ->
									NewState = State#state{finish_list = State#state.finish_list ++ [{Type,SubType}],
												award_list = State#state.award_list ++ [{Type,SubType}]},
									NewAchieveRec = AchieveRec#achieve{gd_Progress = TargetNum,gd_IsFinish = 1,
																	gd_IsAward = 1,gd_Data = NewData},
									{ok,BinData} = pt_29:write(29002,{Type,SubType}),
									lib_send:send(AccountID,BinData),
									add_point_to_rank(AccountID,Type,SubType)
							end,
							cache_update(NewAchieveRec)
					end
			end
	end,
	{noreply,NewState};

%% 触发成就模式四
handle_cast({4,AccountID,Type,SubType,List},State) ->
	case lists:member({Type,SubType},State#state.finish_list) of
		true ->
			NewState = State;
		false ->
			AchieveRec = cache_getAchieve(AccountID,Type,SubType),
			{TargetNum,Target} = data_achieve:get_target_4(Type,SubType),
			Fun = fun(A,Num) ->
				case A >= Target of
					true ->
						Num + 1;
					false ->
						Num
				end
			end,
			Num = lists:foldl(Fun,0,List),
			case Num =< AchieveRec#achieve.gd_Progress of
				true ->
					NewState = State;
				false ->
					case Num < TargetNum of
						true ->
							NewState = State,
							NewAchieveRec = AchieveRec#achieve{gd_Progress = Num};
						false ->
							NewState = State#state{finish_list = State#state.finish_list ++ [{Type,SubType}],
												award_list = State#state.award_list ++ [{Type,SubType}]},
							NewAchieveRec = AchieveRec#achieve{gd_Progress = TargetNum,gd_IsFinish = 1,
																	gd_IsAward = 1},
							{ok,BinData} = pt_29:write(29002,{Type,SubType}),
							lib_send:send(AccountID,BinData),
							add_point_to_rank(AccountID,Type,SubType)
					end,
					cache_update(NewAchieveRec)
			end
	end,
	{noreply,NewState};

%% 触发成就模式五
handle_cast({5,AccountID,Type,SubType,UniqueID},State) ->
	case lists:member({Type,SubType},State#state.finish_list) of
		true ->
			NewState = State;
		false ->
			Target = data_achieve:get_target_5(Type,SubType),
			case UniqueID =:= Target of
				false ->
					NewState = State;
				true ->
				AchieveRec = cache_getAchieve(AccountID,Type,SubType),
					NewState = State#state{finish_list = State#state.finish_list ++ [{Type,SubType}],
												award_list = State#state.award_list ++ [{Type,SubType}]},
							NewAchieveRec = AchieveRec#achieve{gd_Progress = 1,gd_IsFinish = 1,
																	gd_IsAward = 1},
							{ok,BinData} = pt_29:write(29002,{Type,SubType}),
							lib_send:send(AccountID,BinData),
							add_point_to_rank(AccountID,Type,SubType),
							cache_update(NewAchieveRec)
			end
	end,
	{noreply,NewState};



handle_cast(_Request, State) ->
    {noreply,State}.

handle_call({get_point,_AccountID},_From,State) ->
	FinishList = State#state.finish_list,
	Fun = fun({Type,SubType},SumPoint) -> 
		case Type of
			1->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			2->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			3->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			4->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			5->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			6->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			7->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			8->
				PointAdd = data_achieve:get_point(Type,SubType),
				SumPoint+PointAdd;
			_Else ->
				SumPoint
			end
		end,
		Reply = lists:foldl(Fun,0,FinishList),
		{reply,Reply,State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											Local Function												   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 筛选已经完成的成就,结果为[{1,2},{1,4}...]
selectFinishAchieve(AchieveInfoList) ->
	Fun = fun(AchieveInfo,List) ->
		case AchieveInfo#achieve.gd_IsFinish =:= 1 of
			true ->
				{_AccountID,Type,SubType} = AchieveInfo#achieve.key,
				List++[{Type, SubType}];
			false ->
				List
		end
	end,
	lists:foldl(Fun,[],AchieveInfoList).

%% 筛选可领奖励的成就
selectAwardAchieve(AchieveInfoList) ->
	Fun = fun(AchieveInfo,List) ->
		case AchieveInfo#achieve.gd_IsAward =:= 1 of
			true ->
				{_AccountID,Type,SubType} = AchieveInfo#achieve.key,
				List++[{Type, SubType}];
			false ->
				List
		end
	end,
	lists:foldl(Fun,[],AchieveInfoList).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%												gen_cache												   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cache_getAllAchieve(AccountID) ->
	gen_cache:lookup(?CACHE_ACHIEVE_REF,AccountID).

cache_getAchieve(AccountID,Type,SubType) ->
	case gen_cache:lookup(?CACHE_ACHIEVE_REF,{AccountID,Type,SubType}) of
		[AchieveRec] ->
			AchieveRec;
		[] ->
			AchieveRec = #achieve{
							key = {AccountID,Type,SubType},
							gd_IsFinish   		= 0,			%% 是否完成
							gd_IsAward 	 		= 0,			%% 是否有奖励
							gd_Progress  		= 0,	    	%% 进度
							gd_Data 	 		= []    		%% 数据记录
			},
			gen_cache:insert(?CACHE_ACHIEVE_REF,AchieveRec)
	end,
	AchieveRec.

cache_update(AchieveRec) ->
	gen_cache:update_record(?CACHE_ACHIEVE_REF,AchieveRec).

cache_getAchieve_Type(AccountID,Type) ->
	AchieveRecList = gen_cache:lookup(?CACHE_ACHIEVE_REF,AccountID),
	Fun = fun(AchieveRec)->
		{_AccountID,Type1,_SecondType} = AchieveRec#achieve.key,
		Type1 =:= Type
	end,
	lists:filter(Fun,AchieveRecList).

add_point_to_rank(_AccountID,_Type,_SubType)->
	ok.
