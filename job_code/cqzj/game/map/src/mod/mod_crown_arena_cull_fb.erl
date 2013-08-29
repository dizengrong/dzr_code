%% Author: ldk
%% Created: 2012-6-14
%% Description: TODO: Add description to mod_crown_arena_cull_fb
-module(mod_crown_arena_cull_fb).

%%
%% Include files
%%
-include("mgeem.hrl").
-include("crown_arena.hrl").

-export([
         handle/1,
         handle/2
        ]).
%%
%% Exported Functions
%%
-export([assert_valid_map_id/1,
         get_map_name_to_enter/1,
         clear_map_enter_tag/1,
		is_can_fight/1]).

-export([
         hook_role_dead/3,
		 hook_role_enter/2,
		 role_offline/1,
		 role_exit/1,
		 hook_role_quit/1
        ]).
-export([
        drop_buff/0,
		erase_buff/0
        ]).

-define(EXP_AWARD_EVERY,10). %%每隔多少秒奖励经验
-define(DROP_BUFF_MAX_NUM,5). %%最多掉几个BUFF


%%--------------------PK地图进程字典--------------------

erase_every_battle(Num,Num1) ->
%% 	erase_role_offline(),
	erase_backup_pk_roles(),
	erase_battle_result(),
	erase_pk_over(Num,Num1).

next_buff_id() ->
    case get(buff_id) of
        undefined ->
            put(buff_id,2),
            1;
        N ->
            put(buff_id,N+1),
            N
    end.

%% set_role_offline(RoleID) ->
%% 	#p_arena_role{right_role_id=RoleRightID1,left_role_id=RoleLeftID2} = get_pk_roles(),
%% 	case lists:member(RoleID, [RoleRightID1,RoleLeftID2]) of
%% 		false ->
%% 			ignore;
%% 		true ->
%% 			OldRoleOffline = get_role_offline(),
%% 			put({?MODULE,role_offline},[RoleID|lists:delete(RoleID, OldRoleOffline)])
%% 	end.
%% get_role_offline() ->
%% 	case get({?MODULE,role_offline}) of
%% 		undefined ->
%% 			[];
%% 		RoleOfflines ->
%% 			RoleOfflines
%% 	end.
%% 
%% erase_role_offline() ->
%% 	erlang:erase({?MODULE,role_offline}).

backup_pk_roles(PkRoles) ->
	put({?MODULE, backup_pk_roles},PkRoles).
get_backup_pk_roles() ->
	get({?MODULE,backup_pk_roles}).
erase_backup_pk_roles() ->
	erlang:erase({?MODULE,backup_pk_roles}).

set_pk_roles(RoleTups) ->
	put({?MODULE,pk_roles},RoleTups).
get_pk_roles() ->
	get({?MODULE,pk_roles}).
set_update_time(Num,Now,OpenTime) ->
	put({?MODULE,update_time,Num},{Now,OpenTime}).
get_update_time(Num) ->
	get({?MODULE,update_time,Num}).

set_battle_result(Num,Num1) ->
	put({?MODULE,pk_result,Num,Num1},true).

get_battle_result(Num,Num1) ->
	get({?MODULE,pk_result,Num,Num1}).

erase_battle_result() ->
	lists:foreach(fun(Num) ->
						  erlang:erase({?MODULE,pk_result,Num,1}),
						  erlang:erase({?MODULE,pk_result,Num,2}),
						  erlang:erase({?MODULE,pk_result,Num,3})
						  end, [8,4,2,1]).

set_pk_over(Num) ->
	put({?MODULE,pk_over,Num},true).
get_pk_over(Num) ->
	get({?MODULE,pk_over,Num}).
erase_pk_over(_Num,_Num1) ->
	erlang:erase({?MODULE,pk_over,8}),
	erlang:erase({?MODULE,pk_over,4}),
	erlang:erase({?MODULE,pk_over,2}),
	erlang:erase({?MODULE,pk_over,1}).

set_use_buff(RoleID,Buff) ->
 	UseBuff = get_use_buff(),
 	put({?MODULE,use_buff},[{RoleID,Buff}|UseBuff]).
	
get_use_buff() ->
	case get({?MODULE,use_buff}) of
		undefined ->
			[];
		[] ->
			[];
		Buffs ->
			Buffs
	end.		
erase_buff() ->
	UseBuff = get_use_buff(),
	lists:foreach(fun({RoleID,Buff}) ->
						  mod_role_buff:del_buff(RoleID,Buff#p_arena_buff.key_id)			  
				  end, UseBuff),
	erlang:erase({?MODULE,use_buff}),
	DropBuffs = get_drop_buff(),
	#p_arena_role{right_role_id=RoleRightID1,left_role_id=RoleLeftID2} = get_pk_roles(),
	lists:foreach(fun(#p_arena_buff{key_id=KeyBuffID,buff_id=BuffID,tx=Tx,ty=Ty}) ->
						  delete_drop_buff(KeyBuffID),
						  R1 = #m_arena_update_buff_toc{action=2,buff=#p_arena_buff{key_id=KeyBuffID,buff_id=BuffID,tx=Tx,ty=Ty}},
						  lists:foreach(fun(RoleID1) ->
												common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?ARENA_UPDATE_BUFF, R1)
										end, [RoleRightID1,RoleLeftID2])	  
				  end , DropBuffs).

set_drop_buff(Buff) ->
	put({?MODULE,drop_buff},[Buff|get_drop_buff()]).
get_drop_buff() ->
	case get({?MODULE,drop_buff}) of
		undefined ->
			[];
		[] ->
			[];
		Buffs ->
			Buffs
	end.
delete_drop_buff(BuffID) ->
	put({?MODULE,drop_buff},lists:keydelete(BuffID, #p_arena_buff.key_id, get_drop_buff())).

set_pk_num(Num) ->
	put({?MODULE,pk_num},Num).
get_pk_num() ->
	get({?MODULE,pk_num}).



%%--------------------等待地图进程字典--------------------
set_cull_map_name(RoleID,MapProcess) ->
	put({?MODULE,RoleID},MapProcess).
get_cull_map_name(RoleID) ->
	get({?MODULE,RoleID}).



is_can_fight(ActorID) ->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case MapID =:= ?CULL_PK_MAP_ID  orelse MapID =:= ?PK_MAP_ID of
		true ->
			State = common_crown_arena:get_pk_state(),
			case State of
				?PK_FIGHT_TIME ->
					true;
				?PK_SAFE_TIME ->
					case MapID of
						?PK_MAP_ID ->
							mod_crown_arena_fb:is_can_fight(ActorID,MapID,State);
						?CULL_PK_MAP_ID ->
%% 							?ROLE_CENTER_BROADCAST(get_other_role(ActorID),"安全时间内不能攻击对方"),
							{error, "安全时间内不能攻击对方"}
					end;
				?PK_FIGHT_SPARE_TIME ->
					case MapID of
						?PK_MAP_ID ->
							mod_crown_arena_fb:is_can_fight(ActorID,MapID,State);
						?CULL_PK_MAP_ID ->
%% 							?ROLE_CENTER_BROADCAST(get_other_role(ActorID),"这局已结束，请等待下局再攻击"),
							{error, "这局已结束，请等待下局再攻击"}
					end;
				
				_ ->
					true
			end;
		_ ->
			true 
	end.

%% get_other_role(ActorID) ->
%% 	#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = get_pk_roles(),
%% 	case ActorID of
%% 		RoleID1 ->
%% 			RoleID2;
%% 		_ ->
%% 			RoleID1
%% 	end.

%%角色离开地图
role_exit(_RoleID) ->
	ignore.
%% 	#map_state{mapid=MapID} = mgeem_map:get_state(),
%% 	case ?CULL_PK_MAP_ID =:= MapID of
%% 		true ->
%% 			battle_result(RoleID);
%% 		false ->
%% 			ignore
%% 	end.
role_offline(_RoleID) ->
	ignore.
%% 	set_role_offline(RoleID),
%% 	#map_state{mapid=MapID} = mgeem_map:get_state(),
%% 	case ?CULL_PK_MAP_ID =:= MapID of
%% 		true ->
%% 			ignore;
%% 		false ->
%% 			ignore
%% 	end.
%% 	#map_state{mapid=MapID} = mgeem_map:get_state(),
%% 	case ?CULL_PK_MAP_ID =:= MapID of
%% 		true ->
%% 			?ERROR_MSG("44444444444444444444444444RoleID==~w,get_pk_roles()==~w",[RoleID,get_pk_roles()]),
%% 			battle_result(RoleID),
%% 			?ERROR_MSG("44444444444444444444444444RoleID==~w,get_pk_roles()==~w",[RoleID,get_pk_roles()]);
%% 		false ->
%% 			ignore
%% 	end.

hook_role_quit(_RoleID) ->
	ignore.
%% 	#map_state{mapid=MapID} = mgeem_map:get_state(),
%% 	case ?CULL_PK_MAP_ID =:= MapID of
%% 		true ->
%% 			battle_result(RoleID);
%% 		false ->
%% 			ignore
%% 	end.

hook_role_dead(DeadRoleID, _SActorID, _SActorType)->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case MapID of
		?CULL_PK_MAP_ID ->
			common_crown_arena:set_pk_state(?PK_FIGHT_SPARE_TIME),
			PkRoles = #p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2,
									right_win_num=WinNum,battle_num=Num1} = get_pk_roles(),
			{CalWinRoleID,_} = cal_dead_win_roles(DeadRoleID,RoleID1,RoleID2),
			Num = get_pk_num(),
					case get_battle_result(Num,Num1) of
						true ->
							ignore;
						_ ->
							set_battle_result(Num,Num1),
							common_misc:unicast({role, CalWinRoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{}),
							common_misc:unicast({role, DeadRoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
							case get_pk_over(Num) of
								true ->
									cal_dead_result(PkRoles,CalWinRoleID,WinNum,RoleID1,RoleID2,Num1,{pk_over,true});
								_ ->
									cal_dead_result(PkRoles,CalWinRoleID,WinNum,RoleID1,RoleID2,Num1,{pk_over,false})
							end
					end;
		_ ->
			ignore
	end.

hook_role_enter(RoleID,MapID) ->
	case MapID of
		?WAIT_MAP_ID ->
			Num = get_pk_num(),
			case get_update_time(Num) of
				undefined ->
					ignore;
				{Time,Seconds} ->
					case common_tool:now() - Time > Seconds of
						true ->
							ignore;
						false ->
							OpenTime = Seconds - (common_tool:now() - Time),
							R2 = #m_crown_update_time_toc{num=Num,status=?UPDATE_TIME_IN_WAIT_MAP,seconds=OpenTime},
							common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
					end
			end;
		?CULL_PK_MAP_ID ->
			todl;
		_ ->
			ignore
	end.
	
%%
%% API Functions
%%
handle(Info,_State) ->
    handle(Info).


handle({enter_pk}) ->
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
						  MapProcessName = common_crown_arena:cull_pk_map_process_name(1),
						  case global:whereis_name(MapProcessName) of
							  undefined ->
								  ignore;
							  _MapPID ->
								  set_cull_map_name(RoleID,MapProcessName),
								  change_map(RoleID,1)
						  end
				  end, RoleIdList),
	todo; 

handle({kill_process}) ->
	mod_crown_arena_fb:kick_all_role([]),
	timer:sleep(5000),
	common_map:exit(kill); 
handle({kick_all_role}) ->
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
						  common_crown_arena:quit_pk_map_change_pos(RoleID)
						  end, RoleIdList),
	timer:sleep(5000),
	common_map:exit(kill);
	
%%等待地图收到信息
handle({pk,Num,RoleTups}) ->
	enter_cull_pk_map(Num,RoleTups);

handle({exp_award_every,ResetTime}) ->
	case ResetTime > 0 of
		false ->
			ignore;
		true ->
			exp_award_every(),
			erlang:send_after((?EXP_AWARD_EVERY)*1000, self(), {mod,mod_crown_arena_cull_fb,{exp_award_every,ResetTime-(?EXP_AWARD_EVERY)}})
	end;
	
handle({exp_award_every}) ->
	%[OpenTime1] = common_config_dyn:find(crown_arena_cull, {open,8}),
	[OpenTime2] = common_config_dyn:find(crown_arena_cull, {open,4}),
	[OpenTime3] = common_config_dyn:find(crown_arena_cull, {open,2}),
	[OpenTime4] = common_config_dyn:find(crown_arena_cull, {open,1}),
	[SafeTime1] = common_config_dyn:find(crown_arena_cull, one_pk_safe_time),
	[SafeTime2] = common_config_dyn:find(crown_arena_cull, other_pk_safe_time),
	[PkTime] = common_config_dyn:find(crown_arena_cull, pk_time),
	ResetTime = OpenTime2+OpenTime3+OpenTime4+ SafeTime1 + SafeTime2*2 + PkTime*3+2,
	exp_award_every(),
	erlang:send_after((?EXP_AWARD_EVERY)*1000, self(), {mod,mod_crown_arena_cull_fb,{exp_award_every,ResetTime-(?EXP_AWARD_EVERY)}});

%% handle({update_time,Num,OpenTime}) ->
%% 	erlang:send_after(1*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_start_after_three,Num,OpenTime}});
handle({update_time,Num,OpenTime,PkRoles}) ->
	JoinRoles = get_join_role_ids(PkRoles),
	set_update_time(Num,common_tool:now(),OpenTime),
	set_pk_num(Num),
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
			R2 = #m_crown_update_time_toc{num=Num,status=?UPDATE_TIME_IN_WAIT_MAP,seconds=OpenTime},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
						  end, RoleIdList--JoinRoles),
	%%没参加淘汰赛玩家在比赛进行时时间
	erlang:send_after(OpenTime*1000, self(), {mod,mod_crown_arena_cull_fb,{other_role_pk_time,Num,JoinRoles}});

handle({other_role_pk_time,Num,JoinRoles}) ->
	[SafeTime1] = common_config_dyn:find(crown_arena_cull, one_pk_safe_time),
	[SafeTime2] = common_config_dyn:find(crown_arena_cull, other_pk_safe_time),
	[PkTime] = common_config_dyn:find(crown_arena_cull, pk_time),
	ResetTime = SafeTime1 + SafeTime2*2 + PkTime*3,
	RoleIdList = mod_map_actor:get_in_map_role(),
	global:send(mgeew_crown_arena_server,{mod,mod_crown_arena_cull,
													 {update_time_in_wait_map_fight,Num,ResetTime}}),
	lists:foreach(fun(RoleID) ->
			R2 = #m_crown_update_time_toc{num=Num,status=?UPDATE_TIME_IN_WAIT_MAP_FIGHT,seconds=ResetTime},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
						  end, RoleIdList--JoinRoles);
	
handle({update_time_over}) ->
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
						   R2 = #m_crown_update_time_toc{status=?UPDATE_TIME_OVER},
							common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
						  end, RoleIdList),
	lists:foreach(fun(RoleID) ->
						  common_crown_arena:quit_pk_map_change_pos(RoleID)
						  end, RoleIdList);

handle({crown_award,RoleID,Exp,Money,Item,Msg}) ->
	do_award(RoleID,Exp,Money,Item,Msg);
	
%%掉BUFF
handle({drop_buff}) ->
 	?TRY_CATCH(drop_buff()),
	todo;

%%PK地图收到信息
%%pk安全时间
handle({pk_safe_time,{Num,Num1},RoleList}) ->
	erlang:send_after(1*1000, self(), {mod,mod_crown_arena_cull_fb,{drop_buff}}),
	erlang:send_after(5*1000, self(), {mod,mod_crown_arena_cull_fb,{drop_buff}}),
	erlang:send_after(10*1000, self(), {mod,mod_crown_arena_cull_fb,{drop_buff}}),
	erlang:send_after(15*1000, self(), {mod,mod_crown_arena_cull_fb,{drop_buff}}),
	erlang:send_after(20*1000, self(), {mod,mod_crown_arena_cull_fb,{drop_buff}}),
	case RoleList of
		{right_win,_,RoleRightID1,RoleTup} ->
			loop(Num,Num1,RoleTup),
			set_pk_num(Num),
			set_pk_over(Num),
			case Num of
				?PK_3 ->
					mod_role2:modify_pk_mode_for_role(RoleRightID1,?PK_PEACE);
				?PK_2 ->
					mod_role2:modify_pk_mode_for_role(RoleRightID1,?PK_PEACE);
				_ ->
					common_misc:unicast({role, RoleRightID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{})
			end,
			set_pk_roles(RoleTup#p_arena_role{right_win_num=?PK_3,win_role_id=RoleRightID1,battle_num=?PK_3});
		{left_win,_,RoleLeftID2,RoleTup} ->
			loop(Num,Num1,RoleTup),
			set_pk_num(Num),
			set_pk_over(Num),
			case Num of
				?PK_3 ->
					mod_role2:modify_pk_mode_for_role(RoleLeftID2,?PK_PEACE);
				?PK_2 ->
					mod_role2:modify_pk_mode_for_role(RoleLeftID2,?PK_PEACE);
				_ ->
					common_misc:unicast({role, RoleLeftID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{})
			end,
			set_pk_roles(RoleTup#p_arena_role{right_win_num=0,win_role_id=RoleLeftID2,battle_num=?PK_3});
		_ ->
			loop(Num,Num1,RoleList),
			case Num1 of
				?PK_1 ->
					set_pk_num(Num),
					set_pk_roles(RoleList#p_arena_role{battle_num=Num1});
				_ ->
					RoleList2 = #p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = get_pk_roles(),
					%%修改PK模式
					lists:foreach(fun(RoleID) ->
										  case mod_map_actor:get_actor_mapinfo(RoleID,role) of
											  #p_map_role{} ->
												  mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE);
											  _ ->
												  ignore
										  end
								  end, [RoleID1,RoleID2]),
					[OtherSafeTimes] = common_config_dyn:find(crown_arena_cull,other_pk_safe_time),
					update_time(Num,?UPDATE_TIME_IN_PK_MAP_SAFE,OtherSafeTimes,Num1),
					same_map_change(RoleList2#p_arena_role.right_role_id,1),
					same_map_change(RoleList2#p_arena_role.left_role_id,2),
					set_pk_roles(RoleList2#p_arena_role{battle_num=Num1})
			end
	end,
	common_crown_arena:set_pk_state(?PK_SAFE_TIME);

%%PK时间
handle({pk_start,{Num,Num1},_RoleList}) ->
	#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = get_pk_roles(),
	%%修改PK模式
	lists:foreach(fun(RoleID) ->
						  case mod_map_actor:get_actor_mapinfo(RoleID,role) of
							  #p_map_role{} ->
								  mod_role2:modify_pk_mode_for_role(RoleID,?PK_ALL);
							  _ ->
								  ignore
						  end
				  end, [RoleID1,RoleID2]),
	[PkTimes] = common_config_dyn:find(crown_arena_cull,pk_time),
	update_time(Num,?UPDATE_TIME_IN_PK_MAP_FIGHT,PkTimes,Num1),
	common_crown_arena:set_pk_state(?PK_FIGHT_TIME);



handle({pk_over,{Num,Num1},_RoleList}) ->
	%%先清掉上盘BUFF
	erase_buff(),
	case {get_pk_over(Num),get_battle_result(Num,Num1)} of
		{true,undefined} ->
			ignore;
		{undefined,true} ->
			ignore;
		{true,true} ->
			ignore;
		_ ->
			cal_battle_result(Num1)
	end,
	do_pk_over({Num,Num1});

	
handle({_, ?CROWN, ?ARENA_PICK_BUFF,_,_,_,_}=Info) ->
    do_pick_buff(Info);

handle({_, ?CROWN, ?CROWN_ARENA_QUIT,_,_,_,_}=Info) ->
    do_quit_pk_map(Info);
handle({_, ?CROWN, ?CROWN_WATCH_ENTER,_,_,_,_}=Info) ->
    do_watch_enter(Info);
handle(Info) ->
	?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

cal_battle_result(Num) ->
	PkRoles = #p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2,
							right_win_num=WinNum} = get_pk_roles(),
	case { mod_map_actor:get_actor_mapinfo(RoleID1, role),mod_map_actor:get_actor_mapinfo(RoleID2, role)} of
		{#p_map_role{hp=HP1},#p_map_role{hp=HP2}} ->
			case HP1 >= HP2 of
				true ->
					case Num of
						?PK_3 ->
							WinRoleID = case WinNum+1 > 1 of true -> RoleID1;false ->RoleID2  end,
							set_pk_roles(PkRoles#p_arena_role{win_role_id=WinRoleID,right_win_num=erlang:min(WinNum+1, ?PK_3)});
						_ ->
							
							common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{}),
							common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
							set_pk_roles(PkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3)})
					end;
				_ ->
					case Num of
						?PK_3 ->
							WinRoleID = case WinNum > 1 of true -> RoleID1;false ->RoleID2  end,
							set_pk_roles(PkRoles#p_arena_role{win_role_id=WinRoleID});
						_ ->
							common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{}),
							common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false})
					end
			end;
		{undefined,#p_map_role{}} ->
			case Num of
				?PK_3 ->
					WinRoleID = case WinNum > 1 of true -> RoleID1;false ->RoleID2  end,
					set_pk_roles(PkRoles#p_arena_role{win_role_id=WinRoleID});
				_ ->
					common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{})
			end;
		{#p_map_role{},undefined} ->
			case Num of
				?PK_3 ->
					WinRoleID = case WinNum > 1 of true -> RoleID1;false ->RoleID2  end,
					set_pk_roles(PkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3),win_role_id=WinRoleID});
				_ ->
					set_pk_roles(PkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3)}),
					common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{})
			end;
		{undefined,undefined} ->
			ignore
	end.

assert_valid_map_id(DestMapID)->
	case ?CULL_PK_MAP_ID =:= DestMapID of
		true->
			ok;
		_ ->
			?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
			throw({error,error_map_id,DestMapID})
	end.

get_map_name_to_enter(RoleID)->
	{DestMapID, _TX, _TY} = get({enter, RoleID}),
	case ?CULL_PK_MAP_ID =:= DestMapID of
		true ->
    		get_cull_map_name(RoleID);
		false ->
			process
	end.
clear_map_enter_tag(_RoleId)->
    ignore.

%%
%% Local Functions
%%

do_award(RoleID,Exp,Money,Item,{Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
	CreateInfo = gen_create_goods(Item),
	TransFun = fun()-> 
						{ok,GoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
					   {ok,RoleAttr2} = common_bag2:t_gain_money(silver_bind, Money, RoleID, ?GAIN_TYPE_SILVER_CROWN_ARENA),
					   {ok,RoleAttr2,GoodsList}
			   end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,NewRoleAttr,GoodsList1}} ->
			global:send(mgeew_crown_arena_server,
													{mod,mod_crown_arena_cull,
													 {already_award,RoleID}}),
			?UNICAST_TOC(#m_crown_cull_award_toc{}),
			mod_map_role:do_add_exp(RoleID,Exp),
			common_misc:update_goods_notify({role,RoleID}, GoodsList1),
			common_misc:send_role_silver_change(RoleID,NewRoleAttr),
			MsgGoods = common_tool:get_format_lang_resources(?_LANG_CROWN_ARENA_AWARD_GOODS,
															 [Item#r_crown_award.num]),
			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(MsgGoods)),
			MsgMoney = common_misc:format_lang(?_LANG_CROWN_ARENA_AWARD_MONEY, [ common_misc:format_silver(Money) ]),
			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, MsgMoney),
%% 			MsgMoney = common_tool:get_format_lang_resources(?_LANG_CROWN_ARENA_AWARD_MONEY,[Money]),
%% 			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(MsgMoney)),
			MsgExp = common_tool:get_format_lang_resources(?_LANG_CROWN_ARENA_AWARD_EXP,[Exp]),
			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(MsgExp)),
			lists:foreach(
			  fun(LogGoods) ->
					   common_item_logger:log(RoleID,LogGoods,1,?LOG_ITEM_TYPE_GET_CROWN_ARENA)
			  end,GoodsList1);
		{aborted, {bag_error,Reason}} ->
			?ERROR_MSG("creat_goods, r: Reason=~w", [Reason]),
			R2 = #m_crown_cull_award_toc{error_code=?ERR_CROWN_ARENA_BAG_FULL},
			?UNICAST_TOC(R2);
		{aborted, {error,ErrCode,Reason}} ->
			?ERROR_MSG("do_award creat_goods, r: ErrCode=~w,Reason=~w", [ErrCode,Reason])
	end.

gen_create_goods(Item) ->
	#r_crown_award{type=Type,typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime,num=Num} = Item,
	#r_goods_create_info{bind=Bind, 
                                      type=Type, 
                                      start_time=StartTime,
                                      end_time=EndTime,
                                      type_id=TypeID,
                                      num=Num
                                     }.	
need_cal_battle_result(RoleID) ->
	#p_arena_role{right_role_id=RoleRightID1,left_role_id=RoleLeftID2} = get_pk_roles(),
	Enemy = 
	case RoleID of
		RoleRightID1 ->
			RoleLeftID2;
		_ ->
			RoleRightID1
	end,
	case mod_map_actor:get_actor_mapinfo(Enemy,role) of
		#p_map_role{}->
			RoleID;
		_ ->
			Enemy
	end.
	
battle_result(RoleID) ->
	PkRoles = #p_arena_role{battle_num=Num1} = get_pk_roles(),
	Num = get_pk_num(),
	backup_pk_roles(PkRoles),
	case {get_pk_over(Num),get_battle_result(Num,Num1)} of
		{true,_} ->
			ignore;
		{undefined,true} ->
			cal_battle_result(PkRoles,Num,RoleID,true);
		_ ->
			cal_battle_result(PkRoles,Num,RoleID,false)
	end,
	set_pk_over(Num).

cal_battle_result(PkRoles,_Num,RoleID,true) ->
	#p_arena_role{right_role_id=RoleID1,left_role_id=LeftRoleID,
				  right_win_num=WinNum,battle_num=Num1} = PkRoles,
	case Num1 of
		?PK_1 ->
			case RoleID of
				RoleID1 ->
					WinRoleID = LeftRoleID,
					WinNum2 = erlang:min(WinNum, ?PK_3);
				_ ->
					WinRoleID = RoleID1,
					WinNum2 = erlang:min(WinNum+2, ?PK_3)
			end,
			set_pk_roles(PkRoles#p_arena_role{win_role_id=WinRoleID,right_win_num=WinNum2,battle_num=?PK_3});
		?PK_2 ->
			case RoleID of
				RoleID1 ->
					WinRoleID = case WinNum > 1 of true -> RoleID1;false -> LeftRoleID end,
					WinNum2 = erlang:min(WinNum, ?PK_3);
				_ ->
					WinRoleID = case WinNum > 1 of true -> RoleID1;false -> LeftRoleID end,
					WinNum2 = erlang:min(WinNum+1, ?PK_3)
			end,
			set_pk_roles(PkRoles#p_arena_role{win_role_id=WinRoleID,right_win_num=WinNum2,battle_num=?PK_3});
		?PK_3 ->
			ignore
	end;

cal_battle_result(PkRoles,_Num,RoleID,false) ->
	#p_arena_role{right_role_id=RoleID1,left_role_id=LeftRoleID,
				  right_win_num=WinNum,battle_num=Num1} = PkRoles,
	case Num1 of
		?PK_1 ->
			case RoleID of
				RoleID1 ->
					WinRoleID = LeftRoleID,
					WinNum2 = 0;
				_ ->
					WinRoleID = RoleID1,
					WinNum2 = ?PK_3
			end;
		?PK_2 ->
			case RoleID of
				RoleID1 ->
					WinRoleID = LeftRoleID,
					WinNum2 = erlang:min(WinNum, ?PK_3);
				_ ->
					WinRoleID = RoleID1,
					WinNum2 = erlang:min(WinNum+2, ?PK_3)
			end;
		?PK_3 ->
			case RoleID of
				RoleID1 ->
					WinRoleID = case WinNum > 1 of true -> RoleID1;false -> LeftRoleID end,
					WinNum2 = erlang:min(WinNum, ?PK_3);
				_ ->
					WinRoleID = case WinNum >= 1 of true -> RoleID1;false -> LeftRoleID end,
					WinNum2 = erlang:min(WinNum+1, ?PK_3)
			end
	end,
	set_pk_roles(PkRoles#p_arena_role{win_role_id=WinRoleID,right_win_num=WinNum2,battle_num=?PK_3}).
	

do_pk_over({Num,?PK_3}) ->
	PkRoles = #p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = get_pk_roles(),
	catch common_crown_arena:quit_pk_map_change_pos(RoleID1),
	catch common_crown_arena:quit_pk_map_change_pos(RoleID2),
	global:send(mgeew_crown_arena_server,
				{mod,mod_crown_arena_cull,
				 {battle_result,Num,PkRoles}});
do_pk_over(_) ->
	ignore.

do_quit_pk_map({Unique, Module, Method, DataIn, RoleID, PID, _Line}=Msg) ->
	#m_crown_arena_quit_tos{type=QuitType} = DataIn,
	case QuitType of
		?QUIT_TYPE_CULL_PK_MAP_IGNORE ->
			#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = get_pk_roles(),
			case lists:member(RoleID, [RoleID1,RoleID2]) of
				true ->
					Enemy = need_cal_battle_result(RoleID),
					battle_result(Enemy);
				false ->
					do_quit_pk_map2(Msg)
			end,
			do_quit_pk_map2(Msg);
		?QUIT_TYPE_CULL_PK_MAP ->
			#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2} = get_pk_roles(),
			case lists:member(RoleID, [RoleID1,RoleID2]) of
				true ->
					R2 = #m_crown_arena_quit_toc{error_code=?ERR_CROWN_ARENA_QUIT_IGNORE,type=QuitType},
					?UNICAST_TOC(R2);
				false ->
					do_quit_pk_map2(Msg)
			end
	end.
			
do_quit_pk_map2({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_crown_arena_quit_tos{type=QuitType} = DataIn,	
	R2 = #m_crown_arena_quit_toc{type=QuitType},
	?UNICAST_TOC(R2),
	common_crown_arena:quit_pk_map_change_pos(RoleID).

do_watch_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_crown_watch_enter_tos{right_role_id=RightRoleID,left_role_id=LeftRoleID} = DataIn,
	case check_can_enter(RoleID,RightRoleID,LeftRoleID) of
		true ->
			R2 = #m_crown_watch_enter_toc{},
			[FbBornPoints] = common_config_dyn:find(crown_arena_cull,cull_other_people_points),
			{TX, TY} = common_tool:random_element(FbBornPoints),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, ?CULL_PK_MAP_ID, TX, TY);
		{false,ErrCode} ->
			R2 = #m_crown_watch_enter_toc{error_code=ErrCode}
	end,
	?UNICAST_TOC(R2).
	
do_pick_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_arena_pick_buff_tos{key_id=KeyBuffID,buff_id=ToBuffID} = DataIn,
	case check_can_pick(KeyBuffID,ToBuffID) of
		{ok,#p_arena_buff{key_id=KeyBuffID,buff_id=BuffID,tx=Tx,ty=Ty}} ->
			use_buff(RoleID,#p_arena_buff{key_id=KeyBuffID,buff_id=BuffID,tx=Tx,ty=Ty}),
			R2 = #m_arena_pick_buff_toc{key_id=KeyBuffID,buff_id=BuffID},
			?UNICAST_TOC(R2);
		{error,ErrorCode} ->
			R2 = #m_arena_pick_buff_toc{buff_id=ToBuffID,error_code=ErrorCode},
			?UNICAST_TOC(R2)
	end,
	delete_drop_buff(KeyBuffID),
	#p_arena_role{right_role_id=RoleRightID1,left_role_id=RoleLeftID2} = get_pk_roles(),
	R1 = #m_arena_update_buff_toc{action=2,buff=#p_arena_buff{key_id=KeyBuffID,buff_id=ToBuffID}},
	lists:foreach(fun(RoleID1) ->
								  common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?ARENA_UPDATE_BUFF, R1)
						  end, [RoleRightID1,RoleLeftID2]).

check_can_enter(RoleID,RightRoleID,LeftRoleID) ->
	MapPocess1 = get_cull_map_name(RightRoleID),
	MapPocess2 = get_cull_map_name(LeftRoleID),
	case RoleID =:= RightRoleID orelse RoleID =:= LeftRoleID of
		true ->
			{false,?ERR_CROWN_ARENA_ENTER_SELF_BATTLE};
		false ->
			case MapPocess1 =:= MapPocess2 of
				true ->
					set_cull_map_name(RoleID,MapPocess1),
					true;
				false ->
					{false,?ERR_CROWN_WATCH_ENTER_OVER}
			end
	end.

use_buff(RoleID,Buff) ->
	set_use_buff(RoleID,Buff),
	mod_role_buff:add_buff(RoleID,Buff#p_arena_buff.buff_id).

check_can_pick(KeyBuffID,_BuffID) ->
	case get_drop_buff() of
		[] ->
			{error,?ERR_CROWN_ARENA_NOT_BUFF};
		Buffs ->
			case lists:keyfind(KeyBuffID, #p_arena_buff.key_id, Buffs) of
				false ->
					{error,?ERR_CROWN_ARENA_NOT_BUFF};
				Buff ->
					{ok,Buff}
			end
	end.

drop_buff() ->
	case common_config_dyn:find(crown_arena_cull,buffs) of
        [Buffs] ->
            case Buffs of
                [] ->
                    ignore;
                _  ->
                    [BuffDropPoints] = common_config_dyn:find(crown_arena_cull,buff_drop_points),
                    {Tx,Ty} = common_tool:random_element(BuffDropPoints),
                    BuffID = calculate_buff(Buffs),
                    KeyBuffID = next_buff_id(),
                    set_drop_buff(#p_arena_buff{key_id=KeyBuffID,buff_id=BuffID,tx=Tx,ty=Ty}),
                    #p_arena_role{right_role_id=RoleRightID1,left_role_id=RoleLeftID2} = get_pk_roles(),
                    %%  RoleIdList = mod_map_actor:get_in_map_role(),
                    R2 = #m_arena_update_buff_toc{action=1,buff=#p_arena_buff{key_id=KeyBuffID,buff_id=BuffID,tx=Tx,ty=Ty}},
                    lists:foreach(fun(RoleID) ->
                                          case mod_map_actor:get_actor_mapinfo(RoleID,role) of
                                              #p_map_role{}->
                                                  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?ARENA_UPDATE_BUFF, R2);
                                              _ ->
                                                  ignore
                                          end
                                  end, [RoleRightID1,RoleLeftID2])
                end;
        _ ->
            ?ERROR_MSG("crown_arena_cull.config buffs配置错误",[])
        end.

calculate_buff(Buffs) ->
	AllRate =
	lists:foldl(fun({_,Rate},Acc) ->
						Rate+Acc
						end, 0, Buffs),	
	Rate = random:uniform(AllRate),
	catch lists:foldl(fun({BuffID,Weight} ,Acc) ->
						case Rate > Weight + Acc of
							true ->
								Weight + Acc;
							false ->
								throw(BuffID)
						end
						end, 0, Buffs).

enter_cull_pk_map(Num,RoleTups) ->
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foldl(fun(RoleTup,Acc) ->
						#p_arena_role{right_role_id=RoleRightID1,right_role_name=RoleName1,
									  left_role_id=RoleLeftID2,left_role_name=RoleName2} = RoleTup,
						MapProcessName = common_crown_arena:cull_pk_map_process_name(Acc),
						case global:whereis_name(MapProcessName) of
							undefined ->
								ignore;
							MapPID ->
								[OneSafeTimes] = common_config_dyn:find(crown_arena_cull,one_pk_safe_time),
								case {lists:member(RoleRightID1, RoleIdList),lists:member(RoleLeftID2, RoleIdList)} of
									{true,true} ->
										set_cull_map_name(RoleRightID1,MapProcessName),
										set_cull_map_name(RoleLeftID2,MapProcessName),
										%%修改PK模式
										mod_role2:modify_pk_mode_for_role(RoleRightID1,?PK_PEACE),
										mod_role2:modify_pk_mode_for_role(RoleLeftID2,?PK_PEACE),
										change_map(RoleRightID1,1),
										change_map(RoleLeftID2,2),
										lists:foreach(fun(URoleID) ->
															  UR2 = #m_crown_update_time_toc{num=Num,right_name=RoleName1,left_name=RoleName2,status=?UPDATE_TIME_IN_PK_MAP_SAFE,seconds=OneSafeTimes,battle_num=0},
															  common_misc:unicast({role, URoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2)
													  end, [RoleRightID1,RoleLeftID2]),
										erlang:send(MapPID,{mod,mod_crown_arena_cull_fb,{pk_safe_time,{Num,1},RoleTup}});
									{true,false} ->
										set_cull_map_name(RoleRightID1,MapProcessName),
										set_cull_map_name(RoleLeftID2,MapProcessName),
										mod_role2:modify_pk_mode_for_role(RoleRightID1,?PK_PEACE),
										change_map(RoleRightID1,1),
										UR2 = #m_crown_update_time_toc{num=Num,right_name=RoleName1,left_name=RoleName2,status=?UPDATE_TIME_IN_PK_MAP_SAFE,seconds=OneSafeTimes,battle_num=0},
										common_misc:unicast({role, RoleRightID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
										erlang:send(MapPID,{mod,mod_crown_arena_cull_fb,{pk_safe_time,{Num,1},{right_win,Num,RoleRightID1,RoleTup}}});
									{false,true} ->
										set_cull_map_name(RoleLeftID2,MapProcessName),
										set_cull_map_name(RoleLeftID2,MapProcessName),
										mod_role2:modify_pk_mode_for_role(RoleLeftID2,?PK_PEACE),
										change_map(RoleLeftID2,2),
										UR2 = #m_crown_update_time_toc{num=Num,right_name=RoleName1,left_name=RoleName2,status=?UPDATE_TIME_IN_PK_MAP_SAFE,seconds=OneSafeTimes,battle_num=0},
										common_misc:unicast({role, RoleLeftID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, UR2),
										erlang:send(MapPID,{mod,mod_crown_arena_cull_fb,{pk_safe_time,{Num,1},{left_win,Num,RoleLeftID2,RoleTup}}});
									{false,false} ->
										global:send(mgeew_crown_arena_server,
													{mod,mod_crown_arena_cull,
													 {need_cacalculate_result,Num,RoleTup}})
								end
						end,
						Acc+1
				end, 1, RoleTups).

change_map(RoleID,Point) ->
	{TX,TY} = get_cull_map_born_points(RoleID,Point),
	case ?WAIT_MAP_ID =:= mgeem_map:get_mapid() of
		true ->
			case mod_map_actor:get_actor_mapinfo(RoleID,role) of
				#p_map_role{state=State,max_hp=MaxHp,max_mp=MaxMp}->
					mod_map_role:do_role_add_hp(RoleID, MaxHp, RoleID),
					mod_map_role:do_role_add_mp(RoleID, MaxMp, RoleID),
					%%修改PK模式
					mod_role2:modify_pk_mode_for_role(RoleID,?PK_ALL),
					case State =:= ?ROLE_STATE_DEAD of
						true ->
							mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_SILVER),
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE,RoleID,?CULL_PK_MAP_ID,TX,TY);
						false ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID,?CULL_PK_MAP_ID,TX,TY)
					end;
				_ ->
					ignore
			end;
		false ->
			nil
	end.

same_map_change(RoleID,Point) ->
	MapState = mgeem_map:get_state(),
	{TX,TY} = get_cull_map_born_points(RoleID,Point),
	case mod_map_actor:get_actor_mapinfo(RoleID,role) of
		#p_map_role{state=State,max_hp=MaxHp,max_mp=MaxMp}->
			mod_map_role:do_role_add_hp(RoleID, MaxHp, RoleID),
			mod_map_role:do_role_add_mp(RoleID, MaxMp, RoleID),
			%%修改PK模式
			mod_role2:modify_pk_mode_for_role(RoleID,?PK_ALL),
			case State =:= ?ROLE_STATE_DEAD of
				true ->
					mod_map_actor:same_map_change_pos(RoleID, role, TX, TY, ?CHANGE_MAP_TYPE_RELIVE, MapState);
				false ->
					mod_map_actor:same_map_change_pos(RoleID, role, TX, TY, ?CHANGE_POS_TYPE_NORMAL, MapState)
			end;
		_ ->
			ignore
	end.
	
	
get_cull_map_born_points(_RoleID,Point) ->
	[FbBornPoints] = common_config_dyn:find(crown_arena_cull,cull_map_born_points),
	lists:nth(Point, FbBornPoints).


get_safe_time(Num1) ->
	case Num1 of
		?PK_1 ->
			[SafeTimes] = common_config_dyn:find(crown_arena_cull,one_pk_safe_time),
			SafeTimes;
		_ ->
			[SafeTimes] = common_config_dyn:find(crown_arena_cull,other_pk_safe_time),
			SafeTimes
	end.


update_time(Num,State,Time,BattleNum) ->
	RoleIdList = mod_map_actor:get_in_map_role(),
	#p_arena_role{right_role_name=RoleName1,
							left_role_name=RoleName2
									} = get_pk_roles(),
	lists:foreach(fun(RoleID) ->
						  R2 = #m_crown_update_time_toc{num=Num,right_name=RoleName1,left_name=RoleName2,status=State,seconds=Time,battle_num=BattleNum-1},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
						  end, RoleIdList).
%% 	lists:foreach(fun(RoleID) ->
%% 	R2 = #m_crown_update_time_toc{status=State,seconds=Time,battle_num=BattleNum-1},
%% 	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
%% 						  end, RoleIdList--[RoleID1,RoleID2]).

exp_award_every() ->
	[ExpList] = common_config_dyn:find(crown_arena_cull,exp_award_every),
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
						  {ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
						  {_,Exp} = lists:keyfind(Level, 1, ExpList),
						  mod_map_role:do_add_exp(RoleID,Exp)
						  end, RoleIdList).

cal_dead_win_roles(DeadRoleID,RightRoleID,LeftRoleID) ->
	case DeadRoleID of
		RightRoleID ->
			{LeftRoleID,RightRoleID};
		_ ->
			{RightRoleID,LeftRoleID}
	end.

cal_dead_result(_PkRoles,CalWinRoleID,WinNum,RoleID1,RoleID2,Num1,{pk_over,true}) ->
	BackPkRoles = get_backup_pk_roles(),
	case Num1 of
		?PK_3 ->
			case CalWinRoleID of
				RoleID1 ->
					WinRoleID = case WinNum+1 > 1 of true -> RoleID1;false ->RoleID2  end,
					backup_pk_roles(BackPkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3),win_role_id=WinRoleID}),
					set_pk_roles(BackPkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3),win_role_id=WinRoleID});
				_ ->
					WinRoleID = case WinNum > 1 of true -> RoleID1;false ->RoleID2  end,
					backup_pk_roles(BackPkRoles#p_arena_role{win_role_id=WinRoleID}),
					set_pk_roles(BackPkRoles#p_arena_role{win_role_id=WinRoleID})
			end;
		_ ->
			case CalWinRoleID of
				RoleID1 ->
					backup_pk_roles(BackPkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3)}),
					set_pk_roles(BackPkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3)});
				_ ->
					ignore
			end
	end;

cal_dead_result(PkRoles,CalWinRoleID,WinNum,RoleID1,RoleID2,Num1,{pk_over,false}) ->
	case Num1 of
		?PK_3 ->
			case CalWinRoleID of
				RoleID1 ->
					WinRoleID = case WinNum+1 > 1 of true -> RoleID1;false ->RoleID2  end,
					set_pk_roles(PkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3),win_role_id=WinRoleID});
				_ ->
					WinRoleID = case WinNum > 1 of true -> RoleID1;false ->RoleID2  end,
					set_pk_roles(PkRoles#p_arena_role{win_role_id=WinRoleID})
			end;
		_ ->
			case CalWinRoleID of
				RoleID1 ->
					set_pk_roles(PkRoles#p_arena_role{right_win_num=erlang:min(WinNum+1, ?PK_3)});
				_ ->
					ignore
			end
	end.
get_join_role_ids(PkRoles) ->
	lists:foldl(fun(#p_arena_role{right_role_id=RoleID1,left_role_id=RoleID2},Acc) ->
						[RoleID1,RoleID2|Acc]
						end, [], PkRoles).


loop(Num,Num1,RoleList)	->
	case Num1 of
		?PK_1 ->
			%%先把上一次的战斗清掉
			erase_every_battle(Num,Num1),
			SafeTimes1 = get_safe_time(1),
			SafeTimes2 = get_safe_time(2),
			SafeTimes3 = get_safe_time(3),
			[PkTimes] = common_config_dyn:find(crown_arena_cull,pk_time),
			%%每场PK开始
			erlang:send_after(SafeTimes1*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_start,{Num,1},RoleList}}),
			erlang:send_after((SafeTimes1+SafeTimes2+PkTimes)*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_start,{Num,2},RoleList}}),
			erlang:send_after((SafeTimes1+SafeTimes2+SafeTimes3+PkTimes*2)*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_start,{Num,3},RoleList}}),
			%%每场安全时间开始
			erlang:send_after((SafeTimes1+PkTimes)*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_safe_time,{Num,2},RoleList}}),
			erlang:send_after((SafeTimes1+SafeTimes2+PkTimes*2)*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_safe_time,{Num,3},RoleList}}),
			%%每盘PK结束
			erlang:send_after((SafeTimes1+PkTimes)*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_over,{Num,1},RoleList}}),
			erlang:send_after((SafeTimes1+SafeTimes2+PkTimes*2)*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_over,{Num,2},RoleList}}),
			erlang:send_after((SafeTimes1+SafeTimes2+SafeTimes3+PkTimes*3)*1000, self(), {mod,mod_crown_arena_cull_fb,{pk_over,{Num,3},RoleList}}),
			todl;
		_ ->
			ignore
	end.
%% loop_drop_buff(Num1) ->
%% 	SafeTimes = 
%% 	case Num1 of 
%% 		?PK_1 ->
%% 			[OneSafeTimes] = common_config_dyn:find(crown_arena_cull,one_pk_safe_time),
%% 			OneSafeTimes;
%% 		_ ->
%% 			[OtherSafeTimes] = common_config_dyn:find(crown_arena_cull,other_pk_safe_time),
%% 			OtherSafeTimes
%% 	end,
%% 	DropSeconds = get_drop_buff_num(?DROP_BUFF_MAX_NUM,SafeTimes),
%% 	lists:foreach(fun(Second) ->
%% 						  erlang:send_after(Second*1000, self(), {mod,mod_crown_arena_cull_fb,{drop_buff}})
%% 						  end, DropSeconds).
%% 	
%% 	
%% get_drop_buff_num(Num,SafeTimes) ->
%% 	case SafeTimes =< Num of
%% 		true ->
%% 			lists:append(lists:seq(1, Num-SafeTimes), lists:seq(1, SafeTimes));
%% 		false ->
%% 			lists:foldl(fun(_,Acc) ->
%% 								Random = random:uniform(SafeTimes),
%% 								[Random|Acc]
%% 								end, [], lists:seq(1, Num))
%% 	end.

	
