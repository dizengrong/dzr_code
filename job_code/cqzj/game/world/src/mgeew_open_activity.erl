%%% @author fsk 
%%% @doc
%%%     开服活动
%%% @end
%%% Created : 2012-10-16
%%%-------------------------------------------------------------------
-module(mgeew_open_activity).

-behaviour(gen_server).
-include("mgeew.hrl").

-export([start/0,
         start_link/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([do_stats/0]).
-record(state,{}).
-define(STATUS_NOT_REWARD,0).
-define(STATUS_CAN_REWARD,1).
-define(STATUS_HAS_REWARD,2).

%% 开服活动类型

%% 等级之王大冲刺
-define(OPEN_ACTIVITY_TYPE_2,2).
%% 异兽提升奖励不停
-define(OPEN_ACTIVITY_TYPE_3,3).
%% 兵器淬炼赛
-define(OPEN_ACTIVITY_TYPE_4,4).
%% 境界提升大比拼
-define(OPEN_ACTIVITY_TYPE_5,5).
%% 战斗力之王大比拼
-define(OPEN_ACTIVITY_TYPE_6,6).
%% 家族三分天下
-define(OPEN_ACTIVITY_TYPE_7,7).

-define(CONFIG_NAME,open_activity).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

-define(open_activity_rank, open_activity_rank). 
-define(reward_tag, reward_tag). 

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent,10000, worker,
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    %% 当游戏启动完毕后，再开始真正的初始化
    erlang:process_flag(trap_exit, true),
	[StatsTime] = ?find_config(open_activity_stats_time),
 	DiffSeconds = common_tool:datetime_to_seconds({erlang:date(),StatsTime})-common_tool:now(),
	NewDiffSeconds = 
		case DiffSeconds >= 0 of
			true -> DiffSeconds;
			false -> DiffSeconds + 86400
		end,
	erlang:send_after(NewDiffSeconds*1000,self(),{stats}),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_handle_info({info,Unique,Module,Method,Type,RoleID,PID})->
	case is_open_activity() of
		true ->
			{OpenDays,RankListConf} = open_activity_type_conf(Type),
			RankList = 
				case get_open_activity_rank(Type) of
					[] -> [];
					ActivityRankList ->
						[begin
							 RankStatus = 
								 case RoleID =/= RankRoleID of
									 true -> ?STATUS_NOT_REWARD;
									 false -> Status
								 end,
							 {_,RewardList} = lists:keyfind(Rank, 1, RankListConf),
							 #p_open_activity{rank=Rank,role_id=RankRoleID,role_name=RankRoleName,status=RankStatus,reward_list=RewardList}
						 end||#r_open_activity_rank{role_id=RankRoleID,rank=Rank,role_name=RankRoleName,status=Status}<-ActivityRankList]
				end,
			R2 = #m_activity_open_activity_info_toc{type=Type,rank_list=RankList,open_days=OpenDays};
		false ->
			R2 = #m_activity_open_activity_info_toc{err_code=?ERR_OTHER_ERR,reason="该功能暂未开放"}
	end,
	?UNICAST_TOC(R2);

do_handle_info({reward,Unique,Module,Method,Type,RoleID,PID})->
	case catch check_reward(RoleID,Type) of
		{ok,Rank,RewardList} ->
			set_reward_tag(RoleID,Type,Rank,RewardList),
			mgeer_role:absend(RoleID, {mod,mod_activity, {open_activity_reward,RoleID,Type,RewardList}});
		{error,ErrCode,ErrReason}->
			R2 = #m_activity_open_activity_reward_toc{type=Type,err_code=ErrCode,reason=ErrReason},
			?UNICAST_TOC(R2)
	end;

do_handle_info({open_activity_reward_result,RoleID,Type,ErrCode,Reason})->
	case ErrCode of
		?ERR_OK ->
			case get_open_activity_rank(Type) of
				[] ->
					?ERROR_MSG("open_activity_reward_result ERROR=~w",[{RoleID,Type}]);
				ActivityRankList ->
					case lists:keyfind(RoleID,#r_open_activity_rank.role_id,ActivityRankList) of
						false ->
							?ERROR_MSG("open_activity_reward_result ERROR=~w",[{RoleID,Type}]);
						ActivityRank ->
							NewActivityRankList = lists:keystore(RoleID,#r_open_activity_rank.role_id,ActivityRankList,ActivityRank#r_open_activity_rank{status=?STATUS_HAS_REWARD}),
							set_open_activity_rank(Type,NewActivityRankList),
							db:dirty_write(?DB_OPEN_ACTIVITY_P,#r_open_activity{type=Type,rank_list=NewActivityRankList})
					end
			end;
		_ ->
			ignore
	end,
	clear_reward_tag(RoleID,Type),
	R2 = #m_activity_open_activity_reward_toc{err_code=ErrCode,reason=Reason,type=Type},
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?ACTIVITY,?ACTIVITY_OPEN_ACTIVITY_REWARD,R2);

do_handle_info({stats})->
	do_stats();

do_handle_info({stats_open_activity_data,RoleLevelRankData,TypeList})->
	stats_open_activity_data(TypeList,RoleLevelRankData);

do_handle_info({erase_open_activity_rank,TypeList})->
	?ERROR_MSG("erase_open_activity_rank",[]),
	[erase({?open_activity_rank,Type})||Type<-TypeList];

do_handle_info(Info) ->
    ?ERROR_MSG("定时活动进程无法处理此消息 Info=~w",[Info]),
    ok.

do_stats() ->
	List = [?OPEN_ACTIVITY_TYPE_2,?OPEN_ACTIVITY_TYPE_3,?OPEN_ACTIVITY_TYPE_4,
			?OPEN_ACTIVITY_TYPE_5,?OPEN_ACTIVITY_TYPE_6,?OPEN_ACTIVITY_TYPE_7],
	global:send(mgeew_ranking,{stats_open_activity_data,List}),
	erlang:send_after(86400*1000,self(),{stats}).

check_reward(RoleID,Type) ->
	case is_open_activity() of
		true ->
			next;
		false ->
			?THROW_ERR_REASON("该功能暂未开放")
	end,
	case get_open_activity_rank(Type) of
		[] ->
			ActivityRankList = null,
			?THROW_ERR_REASON("不能领取奖励");
		ActivityRankList ->
			next
	end,
	%%检查是否正在领取当中
	case get_reward_tag(RoleID,Type) of
		undefined->
			next;
		_ ->
			?THROW_ERR_REASON("不要重复操作")
	end,
	case lists:keyfind(RoleID, #r_open_activity_rank.role_id, ActivityRankList) of
		false ->
			?THROW_ERR_REASON("不能领取奖励");
		#r_open_activity_rank{rank=Rank,status=Status} ->
			case Status =:= ?STATUS_CAN_REWARD of
				true ->
					case open_activity_type_conf(Type) of
						undefined ->
							?THROW_ERR_REASON("不能领取奖励");
						{_,RankListConf} ->
							{_,RewardList} = lists:keyfind(Rank, 1, RankListConf),
							{ok,Rank,RewardList}
					end;
				false ->
					?THROW_ERR_REASON("已经领取奖励")
			end
	end.

get_reward_tag(RoleID,Type)->
    get({?reward_tag,Type,RoleID}).

clear_reward_tag(RoleID,Type)->
    erase({?reward_tag,Type,RoleID}).

set_reward_tag(RoleID,Type,Rank,RewardList)->
    put({?reward_tag,Type,RoleID},{Type,Rank,RoleID,RewardList}),
    ok.

open_activity_type_conf(Type) ->
	[OpenActivityList] = ?find_config(open_activity),
	
	case lists:keyfind(Type, 1, OpenActivityList) of
		false -> undefined;
		{_,OpenActivityConf} ->
%% 			?DBG(Type),
%% 			?DBG(OpenActivityConf),
			OpenedDays = common_config:get_opened_days(),
%% 			?DBG(OpenedDays),
			case catch lists:filter(fun({ValidDay,_}) ->
											ValidDay =< OpenedDays
									end, OpenActivityConf) of
				TmpList when TmpList =/= [] ->
%% 					?DBG(lists:last(TmpList)),
					lists:last(TmpList);
				_ ->
					lists:last(OpenActivityConf)
			end
	
	end.

is_open_activity() ->
	[IsOpen] = ?find_config(enable_open_activity),
	IsOpen.

%% 开服活动信息
get_open_activity_rank(Type) ->
	case get({?open_activity_rank,Type}) of
		undefined ->
			ActivityRankList=
				case db:dirty_read(?DB_OPEN_ACTIVITY_P,Type) of
					[] -> [];
					[#r_open_activity{rank_list=RankList}] ->
						RankList
				end,
			put({?open_activity_rank,Type},ActivityRankList);
		ActivityRankList ->
			next
	end,
	ActivityRankList.
set_open_activity_rank(Type,ActivityRankList) ->
	put({?open_activity_rank,Type},ActivityRankList).

stats_open_activity_data(TypeList,RoleLevelRankData) when is_list(TypeList) ->
	lists:foreach(fun(Type) ->
						  {OpenDays,RankListConf} = open_activity_type_conf(Type),
						  OpenedDay = common_config:get_opened_days(),
						  case OpenDays =:= OpenedDay orelse common_config:is_debug() of
							  true ->
								  RankNum = length(RankListConf),
								  case stats_open_activity_data(Type,RoleLevelRankData,RankNum) of
									  {ok,ActivityRankList} ->
										  set_open_activity_rank(Type,ActivityRankList),
										  db:dirty_write(?DB_OPEN_ACTIVITY_P,#r_open_activity{type=Type,rank_list=ActivityRankList});
									  _ ->
										  ignore
								  end;
							  false -> 
								  ignore
						  end
				  end, TypeList).

%% 等级之王大冲刺
stats_open_activity_data(?OPEN_ACTIVITY_TYPE_2,RoleLevelRankData,RankNum) ->
	List = lists:sort(fun(E1,E2) -> not ranking_role_level:cmp(E1,E2) end,RoleLevelRankData),
	List2 = lists:sublist(List,RankNum),
	{_,ActivityRankList} = 
		lists:foldr(fun(#p_role_level_rank{role_id=RoleID,role_name=RoleName},{AccRankNum,Acc}) ->
							{AccRankNum-1,[#r_open_activity_rank{rank=AccRankNum-1,role_id=RoleID,role_name=RoleName,status=?STATUS_CAN_REWARD}|Acc]}
					end, {erlang:min(RankNum,length(List2))+1,[]} , List2),
	{ok,ActivityRankList};
%% 异兽提升奖励不停
stats_open_activity_data(?OPEN_ACTIVITY_TYPE_3,RoleLevelRankData,RankNum) ->
	RankPetList = lists:flatten(
					[begin
						 mnesia:dirty_match_object(?DB_PET_P,#p_pet{_='_',role_id=RoleID})
					 end||#p_role_level_rank{role_id=RoleID}<-RoleLevelRankData]
							   ),
	RolePetRankList = 
		[begin
			 #p_pet{role_id=RoleID,role_name=RoleName} = PetInfo,
			 PetRank = #p_role_pet_rank{role_id=RoleID,role_name=RoleName},
			 ranking_role_pet:get_pet_rank(PetInfo, PetRank)
		 end||PetInfo<-RankPetList],
	List = lists:sort(fun(E1,E2) -> not ranking_role_pet:cmp(E1,E2) end,RolePetRankList),
	List2 = lists:sublist(List,RankNum),
	{_,ActivityRankList} = 
		lists:foldr(fun(#p_role_pet_rank{role_id=RoleID,role_name=RoleName},{AccRankNum,Acc}) ->
							{AccRankNum-1,[#r_open_activity_rank{rank=AccRankNum-1,role_id=RoleID,role_name=RoleName,status=?STATUS_CAN_REWARD}|Acc]}
					end, {erlang:min(RankNum,length(List2))+1,[]} , List2),
	{ok,ActivityRankList};

%% 兵器淬炼赛
stats_open_activity_data(?OPEN_ACTIVITY_TYPE_4,RoleLevelRankData,RankNum) ->
	RankFightingPowerList = lists:flatten(
							  [begin
								   case common_misc:get_dirty_role_attr(RoleID) of
									   {ok,#p_role_attr{category=Category,equips=Equips,role_name=RoleName,role_id=RoleID}} ->
										   case lists:keyfind(?PUT_ARM,#p_goods.loadposition,Equips) of
											   false -> 
												   {RoleID,RoleName,0};
											   PGoods ->
												   {RoleID,RoleName,common_role:get_equip_fighting_power(Category,PGoods)}
										   end;
									   _ -> {0,0,0}
								   end
							   end||#p_role_level_rank{role_id=RoleID}<-RoleLevelRankData]
										 ),
	List = lists:sort(fun({_,_,FightingPower1},{_,_,FightingPower2}) -> 
							  not mgeew_ranking:cmp([{FightingPower1,FightingPower2}])
					  end,RankFightingPowerList),
	List2 = lists:sublist(List,RankNum),
	{_,ActivityRankList} = 
		lists:foldr(fun({RoleID,RoleName,_},{AccRankNum,Acc}) ->
							{AccRankNum-1,[#r_open_activity_rank{rank=AccRankNum-1,role_id=RoleID,role_name=RoleName,status=?STATUS_CAN_REWARD}|Acc]}
					end, {erlang:min(RankNum,length(List2))+1,[]} , List2),
	{ok,ActivityRankList};

%% 境界提升大比拼
%% TODO 可考虑用排行榜的数据
stats_open_activity_data(?OPEN_ACTIVITY_TYPE_5,RoleLevelRankData,RankNum) ->
	RankJingjieList = lists:flatten(
						[begin
							 case common_misc:get_dirty_role_attr(RoleID) of
								 {ok,#p_role_attr{jingjie=Jingjie,role_name=RoleName,role_id=RoleID}} ->
									 {RoleID,RoleName,Jingjie};
								 _ -> {0,0,0}
							 end
						 end||#p_role_level_rank{role_id=RoleID}<-RoleLevelRankData]
								   ),
	List = lists:sort(fun({_,_,Jingjie1},{_,_,Jingjie2}) -> 
							  not mgeew_ranking:cmp([{Jingjie1,Jingjie2}])
					  end,RankJingjieList),
	List2 = lists:sublist(List,RankNum),
	{_,ActivityRankList} = 
		lists:foldr(fun({RoleID,RoleName,_},{AccRankNum,Acc}) ->
							{AccRankNum-1,[#r_open_activity_rank{rank=AccRankNum-1,role_id=RoleID,role_name=RoleName,status=?STATUS_CAN_REWARD}|Acc]}
					end, {erlang:min(RankNum,length(List2))+1,[]} , List2),
	{ok,ActivityRankList};

%% 战斗力之王大比拼
stats_open_activity_data(?OPEN_ACTIVITY_TYPE_6,RoleLevelRankData,RankNum) ->
	RankFightingPowerList = lists:flatten(
							  [begin
								   case common_misc:get_dirty_role_attr(RoleID) of
									   {ok,#p_role_attr{role_name=RoleName,role_id=RoleID}=RoleAttr} ->
										   case common_misc:get_dirty_role_base(RoleID) of
											   {ok,RoleBase} ->
											   		OldBuffs = RoleBase#p_role_base.buffs,
											   		RoleBase2 = lists:foldl(fun
														(BuffID, RoleBaseAcc) ->
															case lists:keyfind(BuffID, #p_actor_buf.buff_id, OldBuffs) of
																OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
																	mod_role_buff:calc(RoleBaseAcc, '-', OldActorBuff);
																_ ->
																	RoleBaseAcc
															end
													end, RoleBase, cfg_zhanli:exclude_buffs()),
												   {RoleID,RoleName,common_role:get_fighting_power(RoleBase2,RoleAttr)};
											   _ ->
												   {0,0,0}
										   end;
									   _ -> {0,0,0}
								   end
							   end||#p_role_level_rank{role_id=RoleID}<-RoleLevelRankData]
										 ),
	List = lists:sort(fun({_,_,FightingPower1},{_,_,FightingPower2}) -> 
							  not mgeew_ranking:cmp([{FightingPower1,FightingPower2}])
					  end,RankFightingPowerList),
	List2 = lists:sublist(List,RankNum),
	{_,ActivityRankList} = 
		lists:foldr(fun({RoleID,RoleName,_},{AccRankNum,Acc}) ->
							{AccRankNum-1,[#r_open_activity_rank{rank=AccRankNum-1,role_id=RoleID,role_name=RoleName,status=?STATUS_CAN_REWARD}|Acc]}
					end, {erlang:min(RankNum,length(List2))+1,[]} , List2),
	{ok,ActivityRankList};

%% 家族三分天下
stats_open_activity_data(?OPEN_ACTIVITY_TYPE_7,_RoleLevelRankData,RankNum) ->
	Sql = io_lib:format(lists:concat(["select owner_role_id,owner_role_name from t_family_summary order by level desc, active_points desc, cur_members desc, family_id asc limit ",RankNum]),[]),
	NewActivityRankList =
		case mod_mysql:select(Sql) of
			{ok, List} ->
				List2 = lists:sublist(List,RankNum),
				{_,ActivityRankList} = 
					lists:foldr(fun([RoleID,RoleName],{AccRankNum,Acc}) ->
										{AccRankNum-1,[#r_open_activity_rank{rank=AccRankNum-1,role_id=RoleID,role_name=RoleName,status=?STATUS_CAN_REWARD}|Acc]}
								end, {erlang:min(RankNum,length(List2))+1,[]} , List2),
				ActivityRankList;
			_ -> []
		end,
	{ok,NewActivityRankList};

stats_open_activity_data(Type,_RoleLevelRankData,_RankNum) ->
	?ERROR_MSG("stats_data Type=~w not_found",[Type]).

