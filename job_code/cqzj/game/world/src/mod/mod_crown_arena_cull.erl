%% Author: ldk
%% Created: 2012-6-14
%% Description: TODO: Add description to mod_crown_arena_cull
-module(mod_crown_arena_cull).

%%
%% Include files
%%
-include("mgeew.hrl").
-include("crown_arena.hrl").

-define(JOIN_MAX_8,8). %%参加8强赛的人数
-define(BROADCASE_TIME,15). %%淘汰赛前几秒广播
-define(BROADCASE_NOTICE,30). %%淘汰赛每隔秒广播

%%
%% Exported Functions
%%
-export([handle/1,
		 init/0,
		 role_online/1,
		 init/1,
		 erase_all/0,
		 get_pk_roles/1
		]).

-export([check_reset_new_batttle/1,
		 create_map_process/1,
		 get_battle_name/1,
		 get_pk_num/0,
		 get_next_pk_time/1,
		 hook_role_enter_wait_map/1
		]).

set_pk_roles(Num,RoleTups) ->
	put({?MODULE,pk_roles,Num},RoleTups).
get_pk_roles(Num) ->
	case get({?MODULE,pk_roles,Num}) of
		undefined ->
			[];
		RoleTups ->
		  RoleTups
	end.

set_award_state(RoleID,Aware,State) ->
	Award = get_award_state(),
	put({?MODULE,award},[{RoleID,Aware,State}|lists:keydelete(RoleID, 1, Award)]).
get_award_state() ->
	case get({?MODULE,award}) of
		undefined ->
			[];
		[] ->
			[];
		Award ->
			Award
	end.

		
change_pk_roles(PkNum,PkRoles,PkRolesList) ->
	#p_arena_role{right_role_id=RightRoleID} = PkRoles,
	NewPkRolesList = lists:keyreplace(RightRoleID, #p_arena_role.right_role_id, PkRolesList, PkRoles),
	put({?MODULE,pk_roles,PkNum},NewPkRolesList).

set_pk_num(Num) ->
	put({?MODULE,pk_num},Num).
get_pk_num() ->
	case get({?MODULE,pk_num}) of
		undefined ->
			?PK_4;
		Num ->
			Num
	end.

update_time_in_wait_map_fight(Num,Time) ->
	put({?MODULE,wait_map_fight,Num},Time).
get_time_in_wait_map_fight(Num) ->
	get({?MODULE,wait_map_fight,Num}).

set_next_pk_time(Num,Time) ->
 	put({?MODULE,next_pk_time,Num},Time).
get_next_pk_time(Num) ->
 	get({?MODULE,next_pk_time,Num}).
erase_next_pk_time() ->
%% 	erlang:erase({?MODULE,next_pk_time,8}),
	erlang:erase({?MODULE,next_pk_time,4}),
	erlang:erase({?MODULE,next_pk_time,2}),
	erlang:erase({?MODULE,next_pk_time,1}).

erase_all() ->
	erase_next_pk_time(),
%% 	erlang:erase({?MODULE,pk_roles,?PK_8}),
	erlang:erase({?MODULE,pk_roles,?PK_4}),
	erlang:erase({?MODULE,pk_roles,?PK_2}),
	erlang:erase({?MODULE,pk_roles,?PK_1}),
	erlang:erase({?MODULE,pk_num}),
	erlang:erase({?MODULE,award}),
	lists:map(fun(Num) ->
					   MapProcessName = common_crown_arena:cull_pk_map_process_name(Num),
					   case global:whereis_name(MapProcessName) of
							  undefined ->
								  ignore;
							  MapPID ->
								  erlang:send(MapPID,{mod,mod_crown_arena_cull_fb,{kill_process}})
						  end	
					  end, lists:seq(1, 8)).
role_online(RoleID) ->
	case check_can_award(RoleID) of
		{false,_ErCode} ->
			ignore;
		{Exp,Money,Item,Rank} ->
			R2 = #m_crown_award_info_toc{rank=Rank,award=[#p_arena_award{type=1,value=Exp},
														  #p_arena_award{type=2,value=Money},
														  #p_arena_award{type=5,value=Item#r_crown_award.num}
														  ]},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_AWARD_INFO,R2)
	end.
	
hook_role_enter_wait_map(RoleID) ->
	PkNum = mod_crown_arena_cull:get_pk_num(),
	PromoteRoles = get_pk_roles(PkNum),
	case check_in_pk_roles(RoleID,PromoteRoles) of
		{ok,PkRoles} ->
			#p_arena_role{right_role_name=RoleName1,left_role_name=RoleName2} = PkRoles,
			NextTimes = mod_crown_arena_cull:get_next_pk_time(PkNum),
			Now = common_tool:now(),
			case (NextTimes - Now) > 0 of
				true ->
					R3 = #m_crown_update_time_toc{num=PkNum,right_name=RoleName1,left_name=RoleName2,status=?UPDATE_TIME_IN_WAIT_MAP,seconds=NextTimes - Now},
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R3);
				false ->
					case get_time_in_wait_map_fight(PkNum) of
						undefined ->
							ignore;
						WMFTime ->
							case (WMFTime - Now) > 0 of
								true ->
									R4 = #m_crown_update_time_toc{num=PkNum,right_name=RoleName1,left_name=RoleName2,status=?UPDATE_TIME_IN_WAIT_MAP_FIGHT,seconds=WMFTime - Now},
									common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R4);
								_ ->
									ignore
							end
					end
			end;
		_ ->
			NextTimes = mod_crown_arena_cull:get_next_pk_time(PkNum),
			case NextTimes =:= undefined of
				false ->
					Now = common_tool:now(),
					case (NextTimes - Now) > 0 of
						true ->
							R3 = #m_crown_update_time_toc{num=NextTimes,status=?UPDATE_TIME_IN_WAIT_MAP,seconds=NextTimes - Now},
							common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R3);
						false ->
							case get_time_in_wait_map_fight(PkNum) of
								undefined ->
									ignore;
								WMFTime ->
									case (WMFTime - Now) > 0 of
										true ->
											R4 = #m_crown_update_time_toc{num=PkNum,status=?UPDATE_TIME_IN_WAIT_MAP_FIGHT,seconds=WMFTime - Now},
											common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R4);
										_ ->
											ignore
									end
							end
					end;
				_ ->
					ignore
			end
	end.
	

init(gm_init) ->
	erase_all(),
	timer:sleep(5000),
	init().

init() ->
	%%判断够不够8人，不够淘汰赛就不开启
	case check_can_open_cull() of
		ok ->
			init_pk_roles(?PK_4),
%% 			DepositRoles = change_role_tupes(RoleIDTupes),
%% 			mgeew_crown_arena_server:set_deposit_roles(DepositRoles),
			set_pk_num(?PK_4),
			create_map_process(?PK_4),
 			timer:sleep(5000),
			start(?PK_4),
%% 			[Time8] = common_config_dyn:find(crown_arena_cull, {open,8}),
			[Time4] = common_config_dyn:find(crown_arena_cull, {open,4}),
			[Time2] = common_config_dyn:find(crown_arena_cull, {open,2}),
			[Time1] = common_config_dyn:find(crown_arena_cull, {open,1}),
			[SafeTime1] = common_config_dyn:find(crown_arena_cull, one_pk_safe_time),
			[SafeTime2] = common_config_dyn:find(crown_arena_cull, other_pk_safe_time),
			[PkTime] = common_config_dyn:find(crown_arena_cull, pk_time),
			ResetTime = SafeTime1*3 + SafeTime2*3*2 + PkTime*3*3,
			AfterPKSeconds6 = Time4+Time2+Time1+ResetTime,
			%%活动结束后把所有玩家T出副本
 			erlang:send_after((Time4+Time2+Time1+SafeTime1 + SafeTime2*2 + PkTime*3+3)*1000, self(), {mod,mod_crown_arena_cull,{update_time_over}}),
			erlang:send_after(AfterPKSeconds6*1000, self(), {erase_all_dict}),
			erlang:send_after((AfterPKSeconds6)*1000, self(), {mod,mod_crown_arena_cull,{cull_kill_all}});
		{false,Num} ->
			Message = common_tool:get_format_lang_resources(?_LANG_ARENABATTLE_CANCEL,[Num]),
    		catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,Message),
			%%60秒后清除积分赛数据
			%%活动结束后把所有玩家T出副本
			erlang:send_after(1000, self(), {mod,mod_crown_arena_cull,{update_time_over}}),
			erlang:send_after(60*1000, self(), {mod,mod_crown_arena_cull,{cull_kill_all}}),
			erlang:send_after(60*1000, self(), {erase_all_dict})
	end.

init_pk_roles(Num) ->
	RoleIDTupes = get_join_roles(Num),
	set_pk_roles(Num,RoleIDTupes),
	RoleIDTupes.

create_map_process(ProcessNum) ->
	lists:foreach(fun(Num) ->
						  MapProcessName = common_crown_arena:cull_pk_map_process_name(Num),
						  case global:whereis_name(MapProcessName) of
							  undefined ->
								  mod_map_copy:async_create_copy(common_crown_arena:cull_pk_map_id(),MapProcessName,mod_crown_arena_cull,{Num});
							  _MapPID ->
								  ignore
						  end				  
				  end, lists:seq(1, ProcessNum)).
	
start(Num) ->
	%%设置押注
%% 	mgeew_crown_arena_server:set_deposit(Num),
	MapId = common_crown_arena:wait_map_id(),
	[OpenTime] = common_config_dyn:find(crown_arena_cull, {open,Num}),
	[SafeTime1] = common_config_dyn:find(crown_arena_cull, one_pk_safe_time),
	[SafeTime2] = common_config_dyn:find(crown_arena_cull, other_pk_safe_time),
	[PkTime] = common_config_dyn:find(crown_arena_cull, pk_time),
	ResetTime = OpenTime + SafeTime1 + SafeTime2*2 + PkTime*3+1,
	%%设置PK开始时间
	set_next_pk_time(Num,common_tool:now() + OpenTime),
	case Num of
		?PK_4 ->
%% 			erlang:send_after(1000, self(), {mod,mod_crown_arena_cull,{advance_notice,Num}}),
			update_time_in_wait_map(OpenTime,Num),
%% 			PkRoles = get_pk_roles(Num),
%% 			lists:foreach(fun(#p_arena_role{right_role_id=RoleID1,right_role_name=RoleName1,left_role_id=RoleID2,left_role_name=RoleName2}) ->
%% 								  UR2 = #m_crown_update_time_toc{right_name=RoleName1,left_name=RoleName2,status=?UPDATE_TIME_IN_WAIT_MAP,seconds=OpenTime,battle_num=3},
%% 								  common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
%% 								  common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2)
%% 						  end, PkRoles),
			send_msg_to_wait_map(MapId,mod_crown_arena_cull_fb,{exp_award_every});
		_ ->
			ignore
	end,
	erlang:send_after(ResetTime*1000, self(), {mod,mod_crown_arena_cull,{reset_battle,Num}}),
	erlang:send_after(OpenTime*1000, self(), {mod,mod_crown_arena_cull,{open,Num}}).

update_time_in_wait_map(OpenTime,PkNum) ->
	MapId = common_crown_arena:wait_map_id(),
	%%副本里进入排名赛玩家时间
	PkRoles = get_pk_roles(PkNum),
	lists:foreach(fun(#p_arena_role{right_role_id=RoleID1,right_role_name=RoleName1,left_role_id=RoleID2,left_role_name=RoleName2}) ->
						  UR2 = #m_crown_update_time_toc{num=PkNum,right_name=RoleName1,left_name=RoleName2,status=?UPDATE_TIME_IN_WAIT_MAP,seconds=OpenTime,battle_num=3},
						  common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
						  common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2)
				  end, PkRoles),
	%%副本里其它玩家时间
	send_msg_to_wait_map(MapId,mod_crown_arena_cull_fb,{update_time,PkNum,OpenTime,PkRoles}).


check_can_open_cull() ->
	RankInfoList = mgeew_crown_arena_server:get_already_rank(),
	case length(RankInfoList) >= ?JOIN_MAX_8 of
		true ->
			ok;
		false ->
			{false,length(RankInfoList)}
	end.

get_join_roles(?PK_4) ->
	case mgeew_crown_arena_server:get_already_rank() of
		[] ->
			?ERROR_MSG("~w, rank_info_empoty", [?MODULE]),
			[];
		RankInfoList ->
			RankInfoList2 = lists:sublist(RankInfoList, ?JOIN_MAX_8),
			RoleIDs = lists:map(fun(#r_crown_role_rank{role_id=RoleID}) ->RoleID end, RankInfoList2),
			RoleIDTupes = calculate_pk_role([],RoleIDs),
			lists:map(fun(RoleIDTupe) ->
							  case RoleIDTupe of
								  [RoleID] ->
									  [#p_role_base{sex=Sex}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
									  [#p_role_attr{category=Category}] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
									  #r_crown_role_rank{role_name=RoleName} = lists:keyfind(RoleID, #r_crown_role_rank.role_id, RankInfoList2),
									  #p_arena_role{right_role_id=RoleID,right_role_name=RoleName,
													right_role_sex=Sex,right_role_category=Category};
								  [RoleID1,RoleID2] ->
									  [#p_role_base{sex=Sex1}] = db:dirty_read(?DB_ROLE_BASE, RoleID1),
									  [#p_role_attr{category=Category1}] = db:dirty_read(?DB_ROLE_ATTR, RoleID1),
									  [#p_role_base{sex=Sex2}] = db:dirty_read(?DB_ROLE_BASE, RoleID2),
									  [#p_role_attr{category=Category2}] = db:dirty_read(?DB_ROLE_ATTR, RoleID2),
									  #r_crown_role_rank{role_name=RoleName1} = lists:keyfind(RoleID1, #r_crown_role_rank.role_id, RankInfoList2),
									  #r_crown_role_rank{role_name=RoleName2} = lists:keyfind(RoleID2, #r_crown_role_rank.role_id, RankInfoList2),
									  #p_arena_role{right_role_id=RoleID1,right_role_name=RoleName1,
													right_role_sex=Sex1,right_role_category=Category1,
													left_role_id=RoleID2,left_role_name=RoleName2,
													left_role_sex=Sex2,left_role_category=Category2}
							  end
							  end, RoleIDTupes)
	end;
get_join_roles(_Num) ->
	[].
%%
%% API Functions
%%
handle({broadcase_notice,Num,Time}) ->
	case Time > 5 of
		false ->
			ignore;
		true ->
			BattleName = get_battle_name(Num),
			Message = common_tool:get_format_lang_resources("经过激烈的比赛竞技，~s玩家已经公布，打开战神坛排名赛面板可获得对阵信息！",[BattleName]),
			?WORLD_CENTER_BROADCAST(Message),
			?WORLD_CENTER_BROADCAST(Message),
			?WORLD_CENTER_BROADCAST(Message),
			erlang:send_after((?BROADCASE_NOTICE)*1000, self(), {mod,mod_crown_arena_cull,{broadcase_notice,Num,Time-?BROADCASE_NOTICE}})
	end;
		
	
%%对参加淘汰赛的玩家提前通知
handle({advance_notice,Num}) ->
	RoleList = get_join_roles(Num),
	lists:foreach(fun(#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2}) ->
						  case RoleID1 of
							  0 ->
								  ignore;
							  _ ->
						  	common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_ADVANCE_NOTICE, #m_crown_advance_notice_toc{type=Num,times=?BROADCASE_TIME})
						  end,
						  case RoleID2 of
							  0 ->
								  ignore;
							  _ ->
						  	common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_ADVANCE_NOTICE, #m_crown_advance_notice_toc{type=Num,times=?BROADCASE_TIME})
						  end
						  end, RoleList);

%%8强赛开始和初始化四强赛
handle({open,?PK_8}) ->
	do_start(?PK_8),
	start(?PK_4);

%%4强赛开始和初始化半决赛
handle({open,?PK_4}) ->
	do_start(?PK_4),
	start(?PK_2);

%%半决赛开始和初始化决赛
handle({open,?PK_2}) ->
	do_start(?PK_2),
	start(?PK_1);

%%决赛开始
handle({open,?PK_1}) ->
	do_start(?PK_1);

handle({reset_battle,PkNum}) ->
	NextPkNum = get_next_pk_num(PkNum),
	PkRolesList = get_pk_roles(PkNum),
	NewPkRolesList = reset_pk_roles(PkRolesList),
%% 	DepositRoles = change_role_tupes(NewPkRolesList),
%% 	mgeew_crown_arena_server:set_deposit_roles(DepositRoles),
 	set_pk_roles(PkNum,NewPkRolesList),
	[SafeTime1] = common_config_dyn:find(crown_arena_cull, one_pk_safe_time),
	[SafeTime2] = common_config_dyn:find(crown_arena_cull, other_pk_safe_time),
%% 	[OpenTimes] = common_config_dyn:find(crown_arena_cull, {open,NextPkNum}),
	[PkTime] = common_config_dyn:find(crown_arena_cull, pk_time),
	ResetTime = SafeTime1 + SafeTime2*2 + PkTime*3,
	case NextPkNum of
		?PK_4 ->
			[OpenTime] = common_config_dyn:find(crown_arena_cull, {open,NextPkNum}),
			erlang:send_after((?BROADCASE_NOTICE)*1000, self(), {mod,mod_crown_arena_cull,{broadcase_notice,NextPkNum,OpenTime-ResetTime-?BROADCASE_NOTICE}}),
			reset_new_batttle(?PK_8,?PK_4,[],NewPkRolesList);
		?PK_2 ->
			[OpenTime] = common_config_dyn:find(crown_arena_cull, {open,NextPkNum}),
			erlang:send_after((?BROADCASE_NOTICE)*1000, self(), {mod,mod_crown_arena_cull,{broadcase_notice,NextPkNum,OpenTime-ResetTime-?BROADCASE_NOTICE}}),
			reset_new_batttle(?PK_4,?PK_2,[],{[],[]},NewPkRolesList),
			update_time_in_wait_map(OpenTime-ResetTime,NextPkNum);
		?PK_1 ->
			[OpenTime] = common_config_dyn:find(crown_arena_cull, {open,NextPkNum}),
			erlang:send_after((?BROADCASE_NOTICE)*1000, self(), {mod,mod_crown_arena_cull,{broadcase_notice,NextPkNum,OpenTime-ResetTime-?BROADCASE_NOTICE}}),
			reset_new_batttle(?PK_2,?PK_1,1,[],NewPkRolesList),
			update_time_in_wait_map(OpenTime-ResetTime,NextPkNum);
		_ ->
			ignore
	end;
	
	

handle({already_award,RoleID}) ->
	AwardInfo = get_award_state(),
	{_,Aware,_State} = lists:keyfind(RoleID, 1, AwardInfo),
	set_award_state(RoleID,Aware,true);

handle({update_time_in_wait_map_fight,Num,ResetTime}) ->
	update_time_in_wait_map_fight(Num,common_tool:now()+ResetTime);

handle({update_time_over}) ->
	%%活动结束
	common_activity:notfiy_activity_end({?ARENABATTLE_ACTIVITY_ID, 1}),
	common_activity:notfiy_activity_end({?ARENABATTLE_ACTIVITY_ID, 2}),
	common_activity:notfiy_activity_end({?ARENABATTLE_ACTIVITY_ID, 3}),
	MapId = common_crown_arena:wait_map_id(),
	send_msg_to_wait_map(MapId,mod_crown_arena_fb,{update_time_over});
	
handle({cull_kill_all}) ->	
	%%清理押注
%% 	mgeew_crown_arena_server:erase_deposit(),
%% 	mgeew_crown_arena_server:erase_deposit_roles(),
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,?_LANG_ARENABATTLE_BC_CLOSED_TIME),
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT_WORLD,?_LANG_ARENABATTLE_BC_CLOSED_TIME),
	MapId = common_crown_arena:wait_map_id(),
	send_msg_to_wait_map(MapId,mod_crown_arena_fb,{kick_wait_map_roles,[]}),
	lists:foreach(fun(Num) ->
						  MapProcessName = common_crown_arena:cull_pk_map_process_name(Num),
						  case global:whereis_name(MapProcessName) of
							  undefined ->
								  ignore;
							  MapPID ->
								  erlang:send(MapPID,{mod,mod_crown_arena_cull_fb,{kill_process}})
						  end
				  end, lists:seq(1, 8));
handle({award_after_4,PkRoles}) ->
	award(PkRoles);

%%
handle({battle_result,PkNum,PkRoles}) ->
	PkRolesList = get_pk_roles(PkNum),
	battle_result(PkNum,PkRoles),
	change_pk_roles(PkNum,PkRoles,PkRolesList);

%%两个都不参加，跟据积分赛判断谁赢
handle({need_cacalculate_result,PkNum,PkRoles}) ->
	#p_arena_role{right_role_id=RoleRightID1,left_role_id=RoleLeftID2} = PkRoles,
	RankList = mgeew_crown_arena_server:get_already_rank(),
	#r_crown_role_rank{rank=Rank1} = lists:keyfind(RoleRightID1, #r_crown_role_rank.role_id, RankList),
	#r_crown_role_rank{rank=Rank2} = lists:keyfind(RoleLeftID2, #r_crown_role_rank.role_id, RankList),
	PkRolesList = get_pk_roles(PkNum),
	PkRoles2 = 
	case Rank1 > Rank2 of
		true ->
			PkRoles#p_arena_role{win_role_id=RoleRightID1,right_win_num=3,battle_num=3};
		false ->
			PkRoles#p_arena_role{win_role_id=RoleLeftID2,right_win_num=0,battle_num=3}
	end,
	change_pk_roles(PkNum,PkRoles2,PkRolesList);

handle({Unique, Module, Method = ?CROWN_CULL_AWARD, _DataIn, RoleID, PID, _Line}=Msg) ->
	case common_tool:now() - common_crown_arena:get_cd_time(RoleID) >= ?AWARD_CD_TIME of
		true ->
			case check_can_award(RoleID) of
				{false,_ErCode} ->
					R2 = #m_crown_cull_award_toc{},
					?UNICAST_TOC(R2);
				{Exp,Money,Item,_Rank} ->
                    mgeer_role:send(RoleID, {mod_crown_arena_cull_fb, {crown_award,RoleID,Exp,Money,Item,Msg}})
			end;
		false ->
			ignore
	end;
	
handle({Unique, Module, Method = ?CROWN_PROMOTE_INFO, _DataIn, _RoleID, PID, _Line}) ->
	Type = get_pk_num(),
%% 	PromoteEight = get_pk_roles(?PK_8),
	PromoteFour = get_pk_roles(?PK_4),
	PromoteTwo = get_pk_roles(?PK_2),
	PromoteOne = get_pk_roles(?PK_1),
	R2 = #m_crown_promote_info_toc{type=Type,
								   promote_four=PromoteFour,promote_two=PromoteTwo,promote_one=PromoteOne},
	?UNICAST_TOC(R2);
handle({Unique, Module, Method = ?CROWN_ARENA_WATCH, DataIn, _RoleID, PID, _Line}) ->
	#m_crown_arena_watch_tos{right_role_id=RightRoleID,left_role_id=LeftRoleID} = DataIn,
%% 	PromoteEight = get_pk_roles(?PK_8),
	PromoteFour = get_pk_roles(?PK_4),
	PromoteTwo = get_pk_roles(?PK_2),
	PromoteOne = get_pk_roles(?PK_1),
	AllPkRoles = PromoteOne ++ PromoteTwo ++ PromoteFour ,
	case check_fight_over(RightRoleID,LeftRoleID,AllPkRoles) of
		{ok,PkRoles} ->
			NextTimes = get_next_pk_time(get_pk_num()),
			Now = common_tool:now(),
			Times = 
			case (NextTimes - Now) > 0 of
				true ->
					NextTimes - Now;
				false ->
					0
			end,
			R2 = #m_crown_arena_watch_toc{is_can_watch=true,times=Times,arena_role=PkRoles};
		_ ->
			R2 = #m_crown_arena_watch_toc{}
	end,
	?UNICAST_TOC(R2);
	
	
handle({set_pk_num,NextPkNum}) ->	
	set_pk_num(NextPkNum);
	
handle({create_map_succ,{Num}}) ->
  MapProcessName = common_crown_arena:cull_pk_map_process_name(Num),
	case global:whereis_name(MapProcessName) of
		undefined ->
			?ERROR_MSG("mgeew_crown_arena_cull create_map_fail :~w",[MapProcessName]);
		_MapPID ->
			ignore
	end;
	
handle(Info) ->
	?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


%%
%% Local Functions
%%
check_in_pk_roles(RoleID,PromoteRoles) ->
	catch lists:foldl(fun(PkRoles,Acc) -> 
						#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = PkRoles,
						case RoleID1 =:= RoleID orelse RoleID2 =:= RoleID of
							true ->
								throw({ok,PkRoles});
							false ->
								Acc
						end
						end, false, PromoteRoles).

check_fight_over(RightRoleID,LeftRoleID,AllPkRoles) ->
	catch lists:foldl(fun(PkRoles,Acc) -> 
						#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = PkRoles,
						case RightRoleID =:= RoleID1 andalso LeftRoleID =:= RoleID2 of
							true ->
								throw({ok,PkRoles});
							false ->
								Acc
						end
						end, [], AllPkRoles).
	
	
reset_new_batttle(?PK_2,?PK_1,_OldPkRolesList,TupPkRoleList,[]) ->
	set_pk_roles(?PK_1,TupPkRoleList);
reset_new_batttle(?PK_2,?PK_1,Num,TupPkRoleList,[PkRole1,PkRole2|PkRolesList]) ->
	{{{WinRoleID1,WinRoleName1},{WinRoleID2,WinRoleName2}},
	 {{FailRoleID1,FailRoleName1},{FailRoleID2,FailRoleName2}}}= get_win(PkRole1,PkRole2),
	{RightSex1,RightCategory1} = get_sex_and_category(WinRoleID1),
	{LeftSex1,LeftCategory1} = get_sex_and_category(WinRoleID2),
	{RightSex2,RightCategory2} = get_sex_and_category(FailRoleID1),
	{LeftSex2,LeftCategory2} = get_sex_and_category(FailRoleID2),
	TupPkRole1 = 
	#p_arena_role{right_role_id=WinRoleID1,right_role_name=WinRoleName1,right_pre_win=true,left_pre_win=true,
				  left_role_id=WinRoleID2,left_role_name=WinRoleName2,
				  right_role_sex=RightSex1,right_role_category=RightCategory1,
					left_role_sex=LeftSex1,left_role_category=LeftCategory1,rank=Num},
	TupPkRole2 = 
	#p_arena_role{right_role_id=FailRoleID1,right_role_name=FailRoleName1,right_pre_win=false,left_pre_win=false,
				  left_role_id=FailRoleID2,left_role_name=FailRoleName2,
				  right_role_sex=RightSex2,right_role_category=RightCategory2,
					left_role_sex=LeftSex2,left_role_category=LeftCategory2,rank=Num+2},
	reset_new_batttle(?PK_2,?PK_1,Num+4,lists:append(TupPkRoleList, [TupPkRole1,TupPkRole2]),PkRolesList);


reset_new_batttle(?PK_4,?PK_2,_OldPkRolesList,{TupPkRoleList1,TupPkRoleList2},[]) ->
	set_pk_roles(?PK_2,TupPkRoleList1++TupPkRoleList2);
reset_new_batttle(?PK_4,?PK_2,OldPkRolesList,{[],[]},[PkRole1,PkRole2|PkRolesList]) ->
	{{{WinRoleID1,WinRoleName1},{WinRoleID2,WinRoleName2}},
	 {{FailRoleID1,FailRoleName1},{FailRoleID2,FailRoleName2}}}= get_win(PkRole1,PkRole2),
	{RightSex1,RightCategory1} = get_sex_and_category(WinRoleID1),
	{LeftSex1,LeftCategory1} = get_sex_and_category(WinRoleID2),
	{RightSex2,RightCategory2} = get_sex_and_category(FailRoleID1),
	{LeftSex2,LeftCategory2} = get_sex_and_category(FailRoleID2),
	TupPkRole1 = 
	#p_arena_role{right_role_id=WinRoleID1,right_role_name=WinRoleName1,right_pre_win=true,left_pre_win=true,
				  left_role_id=WinRoleID2,left_role_name=WinRoleName2,
				  right_role_sex=RightSex1,right_role_category=RightCategory1,
					left_role_sex=LeftSex1,left_role_category=LeftCategory1},
	TupPkRole2 = 
	#p_arena_role{right_role_id=FailRoleID1,right_role_name=FailRoleName1,right_pre_win=false,left_pre_win=false,
				  left_role_id=FailRoleID2,left_role_name=FailRoleName2,
				  right_role_sex=RightSex2,right_role_category=RightCategory2,
					left_role_sex=LeftSex2,left_role_category=LeftCategory2,rank=5},
	reset_new_batttle(?PK_4,?PK_2,OldPkRolesList,{[TupPkRole1],[TupPkRole2]},PkRolesList);
reset_new_batttle(?PK_4,?PK_2,OldPkRolesList,{TupPkRoleList1,TupPkRoleList2},[PkRole1,PkRole2|PkRolesList]) ->
	{{{WinRoleID1,WinRoleName1},{WinRoleID2,WinRoleName2}},
	 {{FailRoleID1,FailRoleName1},{FailRoleID2,FailRoleName2}}}= get_win(PkRole1,PkRole2),
	{RightSex1,RightCategory1} = get_sex_and_category(WinRoleID1),
	{LeftSex1,LeftCategory1} = get_sex_and_category(WinRoleID2),
	{RightSex2,RightCategory2} = get_sex_and_category(FailRoleID1),
	{LeftSex2,LeftCategory2} = get_sex_and_category(FailRoleID2),
	TupPkRole1 = 
	#p_arena_role{right_role_id=WinRoleID1,right_role_name=WinRoleName1,right_pre_win=true,left_pre_win=true,
				  left_role_id=WinRoleID2,left_role_name=WinRoleName2,
				  right_role_sex=RightSex1,right_role_category=RightCategory1,
					left_role_sex=LeftSex1,left_role_category=LeftCategory1},
	TupPkRole2 = 
	#p_arena_role{right_role_id=FailRoleID1,right_role_name=FailRoleName1,right_pre_win=false,left_pre_win=false,
				  left_role_id=FailRoleID2,left_role_name=FailRoleName2,
				  right_role_sex=RightSex2,right_role_category=RightCategory2,
					left_role_sex=LeftSex2,left_role_category=LeftCategory2,rank=5},
	reset_new_batttle(?PK_4,?PK_2,OldPkRolesList,{lists:append(TupPkRoleList1, [TupPkRole1]),lists:append(TupPkRoleList2, [TupPkRole2])},PkRolesList).


reset_new_batttle(?PK_8,?PK_4,TupPkRoleList,[]) ->
	set_pk_roles(?PK_4,TupPkRoleList);
reset_new_batttle(?PK_8,?PK_4,TupPkRoleList,[PkRole1,PkRole2|PkRolesList]) ->
	#p_arena_role{right_role_id=RightRoleID1,right_role_name=RightRoleName1,
				  left_role_id=_LeftRoleID1,left_role_name=LeftRoleName1,win_role_id=WinRole1} = PkRole1,
	#p_arena_role{right_role_id=RightRoleID2,right_role_name=RightRoleName2,
				  left_role_id=_LeftRoleID2,left_role_name=LeftRoleName2,win_role_id=WinRole2} = PkRole2,
	
	{WinRoleName1,_}= get_win_name(WinRole1,RightRoleID1,RightRoleName1,LeftRoleName1),
	{WinRoleName2,_} = get_win_name(WinRole2,RightRoleID2,RightRoleName2,LeftRoleName2),
	{RightSex,RightCategory} = get_sex_and_category(WinRole1),
	{LeftSex,LeftCategory} = get_sex_and_category(WinRole2),
	TupPkRole = 
	#p_arena_role{right_role_id=WinRole1,right_role_name=WinRoleName1,right_pre_win=true,left_pre_win=true,
				  left_role_id=WinRole2,left_role_name=WinRoleName2,
				  right_role_sex=RightSex,right_role_category=RightCategory,
					left_role_sex=LeftSex,left_role_category=LeftCategory},
	reset_new_batttle(?PK_8,?PK_4,lists:append(TupPkRoleList, [TupPkRole]),PkRolesList).

get_win(PkRole1,PkRole2) ->
	#p_arena_role{right_role_id=RightRoleID1,right_role_name=RightRoleName1,
				  left_role_id=LeftRoleID1,left_role_name=LeftRoleName1,win_role_id=WinRole1} = PkRole1,
	#p_arena_role{right_role_id=RightRoleID2,right_role_name=RightRoleName2,
				  left_role_id=LeftRoleID2,left_role_name=LeftRoleName2,win_role_id=WinRole2} = PkRole2,
	{WinRoleName1,FailRoleName1} = get_win_name(WinRole1,RightRoleID1,RightRoleName1,LeftRoleName1),
	{WinRoleName2,FailRoleName2} = get_win_name(WinRole2,RightRoleID2,RightRoleName2,LeftRoleName2),
	{WinRoleID1,FailRoleID1} = get_win_roleid(WinRoleName1,[{RightRoleName1,RightRoleID1},{LeftRoleName1,LeftRoleID1}]),
	{WinRoleID2,FailRoleID2} = get_win_roleid(WinRoleName2,[{RightRoleName2,RightRoleID2},{LeftRoleName2,LeftRoleID2}]),
	{{{WinRoleID1,WinRoleName1},{WinRoleID2,WinRoleName2}},{{FailRoleID1,FailRoleName1},{FailRoleID2,FailRoleName2}}}.
	
	
get_win_roleid(WinRoleName,TupLists) ->
	{_,WinRoleID} = lists:keyfind(WinRoleName, 1, TupLists),
	[{_,FailRoleID}] = lists:keydelete(WinRoleName, 1, TupLists),
	{WinRoleID,FailRoleID}.
	
get_win_name(WinRole,RightRoleID,RightRoleName,LeftRoleName) ->
	case WinRole of
		RightRoleID ->
			{RightRoleName,LeftRoleName};
		_ ->
			{LeftRoleName,RightRoleName}
	end.

reset_pk_roles(PkRolesList) ->
	lists:map(fun(PkRoles) ->
					  #p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2,
							win_role_id=WinRoleID,right_win_num=WinNum} = PkRoles,
					  case WinRoleID of
						  0 ->
								WinRoleID2 = case WinNum > 1 of true -> RoleID1;false ->RoleID2  end,
								PkRoles#p_arena_role{win_role_id=WinRoleID2};
						  _ ->
							 WinRoleID2 = case WinNum > 1 of true -> RoleID1;false ->RoleID2  end,
							PkRoles#p_arena_role{win_role_id=WinRoleID2}
					  end
					  end, PkRolesList).

check_reset_new_batttle(PkNum) ->
	PkRolesList = get_pk_roles(PkNum),
	WinNum = 
	lists:foldl(fun(#p_arena_role{win_role_id=WinRoleID} ,Acc) ->
						case WinRoleID > 0 of
							true ->
								Acc+1;
							false ->
								Acc
						end
						end, 0, PkRolesList),
	case {WinNum,PkNum} of
		{?PK_8,?PK_8} ->
			NextPkNum = get_next_pk_num(PkNum),
			{ok,NextPkNum,undefined,PkRolesList};
		{?PK_8 div 2,_} ->
			NextPkNum = get_next_pk_num(PkNum),
			PkNum2 = get_forward_pk_num(PkNum),
			OldPkRolesList = get_pk_roles(PkNum2),
			{ok,NextPkNum,OldPkRolesList,PkRolesList};
		_ ->
			false
	end.
get_forward_pk_num(PkNum) ->
	if 
		PkNum =:= ?PK_8 ->
			undefined;
		PkNum =:= ?PK_4 ->
			?PK_8;
		PkNum =:= ?PK_2 ->
			?PK_4;
		PkNum =:= ?PK_1 ->
			?PK_2;
		true ->
			undefined
	end.
get_next_pk_num(PkNum) ->
	if 
		PkNum =:= ?PK_8 ->
			?PK_4;
		PkNum =:= ?PK_4 ->
			?PK_2;
		PkNum =:= ?PK_2 ->
			?PK_1;
		PkNum =:= ?PK_1 ->
			undefined;
		true ->
			undefined
	end.
		
do_start(Num) ->
	NextPkNum = get_next_pk_num(Num),
	[SafeTimes1] = common_config_dyn:find(crown_arena_cull,one_pk_safe_time),
	[SafeTimes2] = common_config_dyn:find(crown_arena_cull,other_pk_safe_time),
	[PkTimes] = common_config_dyn:find(crown_arena_cull,pk_time),
	AfterPKSeconds = SafeTimes1 + SafeTimes2*2 + PkTimes*3,
	erlang:send_after(AfterPKSeconds*1000, self(), {mod,mod_crown_arena_cull,{set_pk_num,NextPkNum}}),
	RoleIDTupes = get_pk_roles(Num),
	MapId = common_crown_arena:wait_map_id(),
	send_msg_to_wait_map(MapId,mod_crown_arena_cull_fb,{pk,Num,RoleIDTupes}).


calculate_pk_role(RoleIDTupes,[]) ->
	RoleIDTupes;
calculate_pk_role(RoleIDTupes,[RoleID|[]]) ->
	[[RoleID]|RoleIDTupes];
calculate_pk_role(RoleIDTupes,[RoleID1|RoleIDs]) ->
	RanDom = random:uniform(length(RoleIDs)),
	RoleID2 = lists:nth(RanDom, RoleIDs),
	calculate_pk_role([[RoleID1,RoleID2]|RoleIDTupes],lists:delete(RoleID2, RoleIDs)).
	
send_msg_to_wait_map(MapId,ModuleName,Msg) ->
	case global:whereis_name( common_map:get_common_map_name( MapId ) ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,ModuleName,Msg})
    end.	

get_sex_and_category(RoleID) ->
	 [#p_role_base{sex=Sex}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
	[#p_role_attr{category=Category}] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
	 {Sex,Category}.

battle_result(PkNum,PkRoles) ->
	R2 = #m_crown_cull_over_toc{battle_num=PkNum,arena_role=PkRoles},
	common_misc:unicast({role, PkRoles#p_arena_role.right_role_id}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_CULL_OVER, R2),
	common_misc:unicast({role,  PkRoles#p_arena_role.left_role_id}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_CULL_OVER, R2),
	case PkNum of
		?PK_1 ->
			%%最后一场玩家主动复活
			UR2 = #m_crown_update_time_toc{num=PkNum,status=?UPDATE_TIME_IN_WAIT_MAP,seconds=2,battle_num=3},
			common_misc:unicast({role, PkRoles#p_arena_role.right_role_id}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
			common_misc:unicast({role, PkRoles#p_arena_role.left_role_id}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
			erlang:send_after(4*1000, self(), {mod,mod_crown_arena_cull,{award_after_4,PkRoles}});
		_ ->
%% 			NexPkNum = get_next_pk_num(PkNum),
%% 			[OpenTime] = common_config_dyn:find(crown_arena_cull, {open,NexPkNum}),
%% 			[SafeTime1] = common_config_dyn:find(crown_arena_cull, one_pk_safe_time),
%% 			[SafeTime2] = common_config_dyn:find(crown_arena_cull, other_pk_safe_time),
%% 			[PkTime] = common_config_dyn:find(crown_arena_cull, pk_time),
%% 			ResetTime = SafeTime1 + SafeTime2*2 + PkTime*3,
%% 			UR2 = #m_crown_update_time_toc{status=?UPDATE_TIME_IN_WAIT_MAP,seconds=OpenTime-ResetTime,battle_num=3},
%% 			common_misc:unicast({role, PkRoles#p_arena_role.right_role_id}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
%% 			common_misc:unicast({role, PkRoles#p_arena_role.left_role_id}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
			ignore
	end.
	
award(PkRoles) ->
	[AwardExpBase] = common_config_dyn:find(crown_arena_cull, award_exp_base),
	[AwardMoneyBase] = common_config_dyn:find(crown_arena_cull, award_money_base),
	[AwardItemBase] = common_config_dyn:find(crown_arena_cull, award_item_base),
	[ExpAwardList] = common_config_dyn:find(crown_arena_cull, exp_award),
	[MoneyAwardList] = common_config_dyn:find(crown_arena_cull, money_award),
	[ItemAward] = common_config_dyn:find(crown_arena_cull, item_award),
						 #p_arena_role{right_role_id=RightRoleID,left_role_id=LeftRoleID,win_role_id=WinRoleID,rank=Rank} = PkRoles, 
						 {{RoleID1,Rank1},{RoleID2,Rank2}} =
						 case WinRoleID of
							 RightRoleID ->
								 {{RightRoleID,Rank},{LeftRoleID,Rank+1}};
							 _ ->
								 {{LeftRoleID,Rank},{RightRoleID,Rank+1}}
						 end,
                        case Rank =:= 1 of
                            true ->
                                {ok,#p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(WinRoleID),
                                BroadcastMsg = common_misc:format_lang(?_LANG_ARENABATTLE_CHAMPION, [RoleName]),
                                catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT_WORLD, BroadcastMsg),
                                catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD, BroadcastMsg);
                            _ ->
                                ignore
                        end,
						 {_,ExpBase1} = lists:keyfind(Rank1, 1, AwardExpBase),
						  {_,ExpBase2} = lists:keyfind(Rank2, 1, AwardExpBase),
						 {_,MoneyBase1} = lists:keyfind(Rank1, 1, AwardMoneyBase),
						  {_,MoneyBase2} = lists:keyfind(Rank2, 1, AwardMoneyBase),
						 {_,ItemBase1} = lists:keyfind(Rank1, 1, AwardItemBase),
						  {_,ItemBase2} = lists:keyfind(Rank2, 1, AwardItemBase),
						  [#p_role_attr{level=Level1}] = db:dirty_read(?DB_ROLE_ATTR, RoleID1),
						  [#p_role_attr{level=Level2}] = db:dirty_read(?DB_ROLE_ATTR, RoleID2),
						 {_,Exp1} = lists:keyfind(Level1, 1, ExpAwardList),
						  {_,Exp2} = lists:keyfind(Level2, 1, ExpAwardList),
						 {_,Money1} = lists:keyfind(Level1, 1, MoneyAwardList),
						  {_,Money2} = lists:keyfind(Level2, 1, MoneyAwardList),
						 set_award_state(RoleID1,{common_tool:to_integer(Exp1*ExpBase1),common_tool:to_integer(Money1*MoneyBase1),ItemAward#r_crown_award{num=ItemBase1},Rank1},false),
						 set_award_state(RoleID2,{common_tool:to_integer(Exp2*ExpBase2),common_tool:to_integer(Money2*MoneyBase2),ItemAward#r_crown_award{num=ItemBase2},Rank2},false),
						 R1 = #m_crown_award_info_toc{rank=Rank1,award=[#p_arena_award{type=1,value=common_tool:to_integer(Exp1*ExpBase1)},
																		#p_arena_award{type=2,value=common_tool:to_integer(Money1*MoneyBase1)},
																		#p_arena_award{type=5,value=ItemBase1}]},
						 R2 = #m_crown_award_info_toc{rank=Rank2,award=[#p_arena_award{type=1,value=common_tool:to_integer(Exp2*ExpBase2)},
																		#p_arena_award{type=2,value=common_tool:to_integer(Money2*MoneyBase2)},
																		#p_arena_award{type=5,value=ItemBase2}]},
						 common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_AWARD_INFO,R1),
						common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_AWARD_INFO, R2).

check_can_award(RoleID) ->
	AwardState = get_award_state(),
	case lists:keyfind(RoleID, 1, AwardState) of
		{RoleID,Aware,false} ->
			Aware;
		_ ->
			{false,?ERR_CROWN_AWARD_ALREADY}
	end.
		
		
get_battle_name(Num) ->
	case Num of
		?PK_8 ->
			"8强";
		?PK_4 ->
			"第一轮比赛";
		?PK_2 ->
			"第二轮比赛";
		?PK_1 ->
			"第三轮比赛"
	end.
			
%% change_role_tupes(RoleIDTupes) ->
%% 	lists:foldl(fun(#p_arena_role{right_role_id=RoleID1,right_role_name=RoleName1,left_role_id=RoleID2,left_role_name=RoleName2},Acc) ->
%% 						 [#p_bet_role{role_id=RoleID1,role_name=RoleName1},
%% 						 #p_bet_role{role_id=RoleID2,role_name=RoleName2}|Acc]
%% 						end, [], RoleIDTupes).
%% 

