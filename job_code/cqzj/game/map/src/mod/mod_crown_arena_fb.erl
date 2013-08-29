%% Author: ldk
%% Created: 2012-6-1
%%% @doc
%%%     战神坛副本（定时开启的副本）
%% Description: TODO: Add description to mod_crown_arena_fb
-module(mod_crown_arena_fb).

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
		 is_in_pk_map/0,
		 is_in_fb_map/0,
		 is_can_fight/3,
         clear_map_enter_tag/1]).

-export([
         hook_role_dead/3,
		 hook_role_enter/2,
		 role_offline/1,
		 role_exit/1,
		 hook_role_quit/1,
		 kick_all_role/1
        ]).



%%死了后延迟几秒退出地图
-define(DEAD_QUIP_PK_MAP_SECOND, 2).
%%
%% API Functions
%%
set_pk_timerRef(TimerRef) ->
	put({?MODULE,pk_timerRef},TimerRef).
cancel_pk_timerRef() ->
	case get({?MODULE,pk_timerRef}) of
		undefined ->
			ignore;
		TimerRef ->
			 erlang:cancel_timer(TimerRef)
	end.

set_crown_arena_open(Type) ->
	put({?MODULE,is_open},Type).

set_enter_pk_role(RoleID) ->
	case get({?MODULE,enter_roles}) of
		undefined ->
			put({?MODULE,enter_roles},[RoleID]),
			[];
		[] ->
			put({?MODULE,enter_roles},[RoleID]),
			[];
		RoleList ->
			put({?MODULE,enter_roles},[RoleID|lists:delete(RoleID, RoleList)]),
			RoleList
	end.

delete_enter_pk_role(RoleID) ->
	case get({?MODULE,enter_roles}) of
		undefined ->
			ignore;
		[] ->
		ignore;
		RoleList ->
			put({?MODULE,enter_roles},lists:delete(RoleID, RoleList))
	end.

get_enter_pk_role() ->
	case get({?MODULE,enter_roles}) of
		undefined ->
			[];
		RoleList ->
			RoleList
	end.

erase_enter_pk_role() ->
	erlang:erase({?MODULE,enter_roles}).
erase_role_fight_result() ->
	erlang:erase({?MODULE,fight_result}).

set_role_fight_result(DeadRoleID,WinRoleID) ->
	put({?MODULE,fight_result},{DeadRoleID,WinRoleID}).
get_role_fight_result() ->
	case get({?MODULE,fight_result}) of
		undefined ->
			[];
		Result ->
			Result
	end.

set_role_fight_result(QuitRoleID) ->
	EnterRoles = get_enter_pk_role(),
	case get_role_fight_result() of
		[] ->
			case lists:delete(QuitRoleID, EnterRoles) of
				[] ->
					put({?MODULE,fight_result},{undefined,QuitRoleID});
				[WinRoleID] ->
					put({?MODULE,fight_result},{QuitRoleID,WinRoleID});
				_ ->
					ignore
			end;
		_ ->
			ignore
	end.

set_role_pk_map_process(RoleID,MapProcess) ->
	put({?MODULE,RoleID},MapProcess).
get_role_pk_map_process(RoleID) ->
	get({?MODULE,RoleID}).

is_in_pk_map() ->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case ?PK_MAP_ID =:= MapID of
		true ->
			true;
		false ->
			false
	end.

%%角色离开地图
role_exit(RoleID) ->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case ?PK_MAP_ID =:= MapID of
		true ->
			%%有顺序关系
%% 			set_role_fight_result(RoleID),
			delete_enter_pk_role(RoleID);
		false ->
			ignore
	end.
role_offline(RoleID) ->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case ?PK_MAP_ID =:= MapID of
		true ->
			global:send(mgeew_crown_arena_server, {role_quit,RoleID}),
			%%有顺序关系
			set_role_fight_result(RoleID),
			delete_enter_pk_role(RoleID);
		false ->
			ignore
	end,
	case MapID of
		?WAIT_MAP_ID ->
			global:send(mgeew_crown_arena_server, {role_quit,RoleID});
		_ ->
			ignore
	end.

	

hook_role_quit(RoleID) ->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case ?PK_MAP_ID =:= MapID of
		true ->
			%%有顺序关系
%% 			set_role_fight_result(RoleID),
			delete_enter_pk_role(RoleID);
		false ->
			ignore
	end.
	
hook_role_dead(DeadRoleID, SActorID, _SActorType)->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case ?PK_MAP_ID =:= MapID of
		true ->
			common_crown_arena:set_pk_state(?PK_FIGHT_SPARE_TIME),
			erlang:send_after(?DEAD_QUIP_PK_MAP_SECOND*1000, self(), {mod,mod_crown_arena_fb,{quip_pk_map_delay,[DeadRoleID]}}),
			{CalWinRoleID,_} = cal_dead_win_roles(DeadRoleID,SActorID),
			set_role_fight_result(DeadRoleID,CalWinRoleID),
			common_misc:unicast({role, DeadRoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
			common_misc:unicast({role, CalWinRoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{});
		false ->
			ignore
	end.
hook_role_enter(RoleID,MapID) ->
	case MapID of
		?PK_MAP_ID ->
			set_enter_pk_role(RoleID);
		?WAIT_MAP_ID ->
			global:send(mgeew_crown_arena_server, {hook_role_enter_wait_map,RoleID});
		_ ->
			ignore
	end.

is_can_fight(_ActorID,MapID,State) ->
	case MapID of
		?PK_MAP_ID ->
			case State of
				?PK_FIGHT_TIME ->
					true;
				?PK_SAFE_TIME ->
%% 					?ROLE_CENTER_BROADCAST(get_other_role(ActorID),"安全时间内不能攻击对方"),
					{error, "安全时间内不能攻击对方"};
				?PK_FIGHT_SPARE_TIME ->
%% 					?ROLE_CENTER_BROADCAST(get_other_role(ActorID),"这局已结束，请等待下局再攻击"),
					{error, "这局已结束，请等待下局再攻击"};
				_ ->
					true
			end;
		_ ->
			true 
	end.

cal_dead_win_roles(DeadRoleID,SActorID) ->
	case get_enter_pk_role() of
		[RoleID1,RoleID2] ->
			case DeadRoleID of
				RoleID1 ->
					{RoleID2,DeadRoleID};
				_ ->
					{RoleID1,DeadRoleID}
			end;
		_ ->
			{SActorID,DeadRoleID}
	end.


handle(Info,_State) ->
    handle(Info).

handle({create_map_succ,{RoleID,MapProcess,PointList}}) ->
	case ?WAIT_MAP_ID =:= mgeem_map:get_mapid() of
		true ->
			set_role_pk_map_process(RoleID,MapProcess),
			global:send(mgeew_crown_arena_server, {mod,mgeew_crown_arena_server,{create_map_succ,{map_create,MapProcess}}}),
			case mod_map_actor:get_actor_mapinfo(RoleID,role) of
				#p_map_role{max_hp=MaxHp,max_mp=MaxMp}->
					mod_map_role:do_role_add_hp(RoleID, MaxHp, RoleID),
					mod_map_role:do_role_add_mp(RoleID, MaxMp, RoleID);
				_ ->
					ignore
			end,
			{TX,TY} = get_pk_map_born_points(RoleID,PointList),
			mod_role2:modify_pk_mode_for_role(RoleID,?PK_ALL),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID,?PK_MAP_ID,TX,TY);
		false ->
			nil
	end;
handle({one,pk_time,RoleID}) ->
	[AfterPKSeconds2] = common_config_dyn:find(crown_arena, pk_time),
	R2 = #m_crown_update_time_toc{status=?PK_MAP_LEAVE_TIME_TYPE,seconds=AfterPKSeconds2},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2);

handle({two,pk_time,[{RoleID1,RoleName1},{RoleID2,RoleName2}]}) ->
	[AfterPKSeconds2] = common_config_dyn:find(crown_arena, pk_time),
	%%修改PK模式
%% 	lists:foreach(fun(RoleID) ->
%% 						  case mod_map_actor:get_actor_mapinfo(RoleID, role) of
%% 							  #p_map_role{} ->
%% 								  mod_role2:modify_pk_mode_for_role(RoleID,?PK_ALL);
%% 							  _ ->
%% 								  ignore
%% 						  end,
%% 						  R2 = #m_crown_update_time_toc{status=?PK_MAP_LEAVE_TIME_TYPE,seconds=AfterPKSeconds2},
%% 						  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
%% 				  end, [RoleID1,RoleID2]),
	common_crown_arena:set_pk_state(?PK_FIGHT_TIME),
	%% 	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
						  case mod_map_actor:get_actor_mapinfo(RoleID, role) of
							  #p_map_role{} ->
								  %%修改PK模式
								   mod_role2:modify_pk_mode_for_role(RoleID,?PK_ALL),
								  R2 = #m_crown_update_time_toc{right_name=RoleName1,left_name=RoleName2,status=?PK_MAP_LEAVE_TIME_TYPE,seconds=AfterPKSeconds2},
								  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2);
							  _ ->
								  ignore
						  end
				  end, [RoleID1,RoleID2]);

handle({update_time_over}) ->
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
						   R2 = #m_crown_update_time_toc{status=?UPDATE_TIME_OVER},
							common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
						  end, RoleIdList),
	lists:foreach(fun(Num) ->
						 MapProcessName = common_crown_arena:cull_pk_map_process_name(Num),
						  case global:whereis_name(MapProcessName) of
							undefined ->
								ignore;
							MapPID ->
								erlang:send(MapPID,{mod,mod_crown_arena_cull_fb,{update_time_over}})
							end			   
						  end, lists:seq(1, 4));

handle({battle_result,RoleID}) ->
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{});

handle({quip_pk_map_delay,RoleidList}) ->
	lists:foreach(fun(RoleID) ->
						  case mod_map_actor:get_actor_mapinfo(RoleID, role) of
							  #p_map_role{} ->
								  common_crown_arena:quit_pk_map_change_pos(RoleID);
							  _ ->
								  ignore
						  end
				  end, RoleidList);
	
handle({role_win,{[{RoleID1,RoleName1},{RoleID2,RoleName2}]}}) ->
	global:send(mgeew_crown_arena_server, {two,hook_role_enter_pk_map,[{RoleID1,RoleName1},{RoleID2,RoleName2}]}),
	[PkSafeTimes] = common_config_dyn:find(crown_arena, pk_safe_time),
	[PkTimes] = common_config_dyn:find(crown_arena, pk_time),
	AfterPKSeconds = PkSafeTimes+PkTimes,
	erlang:send_after(AfterPKSeconds*1000, self(), {mod,mod_crown_arena_fb,{quit_pk_map,[RoleID1,RoleID2]}}),
	TimerRef = erlang:send_after(PkSafeTimes*1000, self(), {mod,mod_crown_arena_fb,{two,pk_time,[{RoleID1,RoleName1},{RoleID2,RoleName2}]}}),
	set_pk_timerRef(TimerRef),
	RoleIdList = mod_map_actor:get_in_map_role(),
	catch lists:foreach(fun(RoleID) ->
								common_crown_arena:quit_pk_map_change_pos(RoleID)	  
						end, RoleIdList--[RoleID1,RoleID2]),
	common_crown_arena:set_pk_state(?PK_SAFE_TIME);
	

handle({role_win,{RoleID}}) ->
	global:send(mgeew_crown_arena_server, {one,hook_role_enter_pk_map,RoleID}),
	[PkSafeTimes] = common_config_dyn:find(crown_arena, pk_safe_time),
	[PkTimes] = common_config_dyn:find(crown_arena, pk_time),
	AfterPKSeconds = PkSafeTimes+PkTimes,
	erlang:send_after(AfterPKSeconds*1000, self(), {mod,mod_crown_arena_fb,{quit_pk_map,[RoleID]}}),
	TimerRef = erlang:send_after(PkSafeTimes*1000, self(), {mod,mod_crown_arena_fb,{one,pk_time,RoleID}}),
	set_pk_timerRef(TimerRef),
	RoleIdList = mod_map_actor:get_in_map_role(),
	catch lists:foreach(fun(RoleID1) ->
								common_crown_arena:quit_pk_map_change_pos(RoleID1)	  
						end, RoleIdList--[RoleID]),
	
	set_role_fight_result(undefined,RoleID),
	common_crown_arena:set_pk_state(?PK_SAFE_TIME);
	
handle({start_crown_arena}) ->
	set_crown_arena_open(true); 

handle({end_crown_arena}) ->
	set_crown_arena_open(false); 
  
%%每场PK结束发奖励
handle({crown_award_every, RoleID}) ->
	do_crown_award_every(RoleID);
%%结束时奖励
handle({crown_award, RankRoleInfo,Msg}) ->
	do_crown_award(RankRoleInfo,Msg);

%%把全部玩家T出PK地图，并退出process
handle({pk_process_kill,RoleIDList}) ->
	catch kick_all_role(RoleIDList),
	timer:sleep(5000),
	common_map:exit(kill);
%%把全部玩家T出等待地图
handle({kick_wait_map_roles,RoleIDList}) ->
	kick_all_role(RoleIDList);
handle({quit_pk_map,RoleList,MapProcess}) ->
	case global:whereis_name(MapProcess) of
		undefined ->
			ignore;
		MapPID ->
			erlang:send(MapPID,{mod,mod_crown_arena_fb,{quit_pk_map,RoleList}})
	end;
	
%%PK时间完了，把PK地图里的玩家T出到等待地图
handle({quit_pk_map,RoleList}) ->
	try
		do_quit_pk_map(RoleList)       
	catch
		_ : R ->
			RoleIdList = mod_map_actor:get_in_map_role(),
			catch lists:foreach(fun(RoleID) ->
										common_crown_arena:quit_pk_map_change_pos(RoleID)	  
								end, RoleIdList),
			?ERROR_MSG("{quit_pk_map}, r: ~w", [R])
	end;

%%mgeew_crown_arena_server发消息PK开始
handle({pk,RoleTwoList}) ->
	do_enter_pk_map(RoleTwoList);
%%下注
handle({deposit, RoleID,DataIn}) ->
    do_deposit(RoleID,DataIn);

handle({_, ?CROWN, ?CROWN_ARENA_ENTER,_,_,_,_}=Info) ->
    do_crown_arena_enter(Info);

handle({_, ?CROWN, ?CROWN_ARENA_QUIT,_,_,_,_}=Info) ->
    do_crown_arena_quit(Info);

handle({_, ?CROWN, ?ARENA_PICK_BUFF,_,_,_,_}=Info) ->
    mod_crown_arena_cull_fb:handle(Info);
handle({_, ?CROWN, ?CROWN_WATCH_ENTER,_,_,_,_}=Info) ->
    mod_crown_arena_cull_fb:handle(Info);

handle(Info) ->
	?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

do_crown_award_every(RoleID) ->
	case mod_map_role:get_role_attr(RoleID) of
		{ok,#p_role_attr{level=Level}}  ->
			[ExpAward] = common_config_dyn:find(crown_arena, exp_award),
			[ExpEvery] = common_config_dyn:find(crown_arena, exp_every),
			case lists:keyfind(Level, 1, ExpAward) of
				{_,Exp} ->	
					mod_map_role:do_add_exp(RoleID,common_tool:to_integer(Exp/ExpEvery));
				_ ->
					ignore
			end;
		_ ->
			ignore
	end.

do_crown_award(RankRoleInfo,{Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
	#r_crown_role_rank{role_id=RoleID,level=Level,score=Score,max_link_win=MaxLinkWin} = RankRoleInfo,
	Exp = reward_exp(RoleID,Level,Score),  
	{Money,_NewRoleAttr} = reward_money(RoleID,Level,Score),
	{Num1,CreateInfo1} = reward_peck(RoleID,Score),
	CreateInfo2 = common_crown_arena:reward_peck_ext(RoleID,Level,MaxLinkWin),
	TransFun = fun()-> 
					   case CreateInfo1 of
						   [] ->
							   GoodsList1 = [];
						   _ ->
							   {ok,GoodsList1} = mod_bag:create_goods(RoleID,CreateInfo1)
					   end,
					   case CreateInfo2 of
						   [] ->
							   GoodsList2 = [];
						   _ ->
							   {ok,GoodsList2} = mod_bag:create_goods(RoleID,CreateInfo2)
					   end,
					   {ok,NewRoleAttr} = common_bag2:t_gain_money(silver_bind, Money, RoleID, ?GAIN_TYPE_SILVER_CROWN_ARENA),
					   {ok,NewRoleAttr,GoodsList1++GoodsList2}
			   
			   end,
	
	case common_transaction:t( TransFun ) of
		{atomic, {ok,NewRoleAttr,GoodsList}} ->
			mod_map_role:do_add_exp(RoleID,Exp),
			common_misc:send_role_silver_change(RoleID,NewRoleAttr),
			common_misc:update_goods_notify({role,RoleID}, GoodsList),
			global:send(mgeew_crown_arena_server, {already_receive,RoleID}),
			MsgMoney = common_misc:format_lang(?_LANG_CROWN_ARENA_AWARD_MONEY, [ common_misc:format_silver(Money) ]),
			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, MsgMoney),
%% 			MsgMoney = common_tool:get_format_lang_resources(?_LANG_CROWN_ARENA_AWARD_MONEY,[Money]),
%% 			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(MsgMoney)),
			MsgGoods = common_tool:get_format_lang_resources(?_LANG_CROWN_ARENA_AWARD_GOODS,
															 [Num1+(if MaxLinkWin >= 5 -> CreateInfo2#r_goods_create_info.num;
																	   true -> 0 end)]),
			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(MsgGoods)),
			MsgExp = common_tool:get_format_lang_resources(?_LANG_CROWN_ARENA_AWARD_EXP,[Exp]),
			common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(MsgExp)),
			R2 = #m_crown_arena_award_toc{},
			?UNICAST_TOC(R2),
			catch award_logs(RoleID,Money,GoodsList);
		{aborted, {bag_error,Reason}} ->
			?ERROR_MSG("creat_goods, r: Reason=~w", [Reason]),
			R2 = #m_crown_arena_award_toc{error_code=?ERR_CROWN_ARENA_BAG_FULL},
			?UNICAST_TOC(R2);
		{aborted, {error,ErrCode,Reason}} ->
			?ERROR_MSG("creat_goods, r: ErrCode=~w,Reason=~w", [ErrCode,Reason])
	end.
	
award_logs(RoleID,_Money,GoodsList) ->
	GoodsList2 = 
				case GoodsList of
					GoodsList when is_record(GoodsList, p_goods) ->
						[GoodsList];
					GoodsList when is_list(GoodsList) ->
						GoodsList;
					_Other ->
						[]
				end,
			lists:foreach(
			  fun(LogGoods) ->
					   common_item_logger:log(RoleID,LogGoods,1,?LOG_ITEM_TYPE_GET_CROWN_ARENA)
			  end,GoodsList2).
reward_exp(_RoleID,Level,Score) ->
	[ExpAward] = common_config_dyn:find(crown_arena, exp_award),
	{_,Exp} = lists:keyfind(Level, 1, ExpAward),
	common_tool:to_integer(Exp*(0.5+Score/30)).
	

reward_money(RoleID,Level,Score) ->
	[MoneyAward] = common_config_dyn:find(crown_arena, money_award),
	{_,Money1} = lists:keyfind(Level, 1, MoneyAward),
	Money = common_tool:to_integer(Money1*(0.5+Score/30)),
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
	NewSilverBind = RoleAttr#p_role_attr.silver_bind + Money,
	{Money,RoleAttr#p_role_attr{silver_bind = NewSilverBind}}.

reward_peck(_RoleID,Score) ->
	[PeckAward] = common_config_dyn:find(crown_arena, peck_award),
	#r_crown_award{type=Type,typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime,num=Num} = PeckAward,
	{Num*(erlang:max(Score,1)),#r_goods_create_info{bind=Bind, 
                                      type=Type, 
                                      start_time=StartTime,
                                      end_time=EndTime,
                                      type_id=TypeID,
                                      num=Num*(erlang:max(Score,1))
                                     }}.	

award_every(RoleList) ->
	lists:foreach(fun(RoleID) ->
			common_misc:send_to_rolemap(RoleID, {mod_crown_arena_fb, {crown_award_every, RoleID}})			  
						  end, RoleList).
	
%%正常情况下每张PK地图里最多两个玩家
do_quit_pk_map(RoleList) ->
	common_crown_arena:set_pk_state(?PK_FIGHT_SPARE_TIME),
	case get_role_fight_result() of
		{undefined,WinRoleID} ->
			common_crown_arena:quit_pk_map_change_pos(WinRoleID),
			global:send(mgeew_crown_arena_server, {role_dead,undefined,WinRoleID});
		{DeadRoleID,WinRoleID} ->
			global:send(mgeew_crown_arena_server, {role_dead,DeadRoleID,WinRoleID}),
			lists:foreach(fun(RoleID) ->
								  common_crown_arena:quit_pk_map_change_pos(RoleID)
						  end, [DeadRoleID,WinRoleID]);
		[] ->
			case RoleList of
				[RoleID2,RoleID3] ->
					case {mod_map_actor:get_actor_mapinfo(RoleID2, role),mod_map_actor:get_actor_mapinfo(RoleID3, role)} of
						{#p_map_role{hp=HP2},#p_map_role{hp=HP3}} ->
							if 
								HP2 > HP3 ->
									global:send(mgeew_crown_arena_server, {role_dead,RoleID3,RoleID2}),
									common_misc:unicast({role, RoleID3}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
									common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{});
								HP3 > HP2 ->
									global:send(mgeew_crown_arena_server, {role_dead,RoleID2,RoleID3}),
									common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
									common_misc:unicast({role, RoleID3}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{});
								true ->
									{ok,RoleAttr2} = mod_map_role:get_role_attr(RoleID2),
									{ok,RoleBase2} = mod_map_role:get_role_base(RoleID2),
									{ok,RoleAttr3} = mod_map_role:get_role_attr(RoleID3),
									{ok,RoleBase3} = mod_map_role:get_role_base(RoleID3),
									FightPower2 = common_role:get_fighting_power(RoleBase2, RoleAttr2),
									FightPower3 = common_role:get_fighting_power(RoleBase3, RoleAttr3),
									case FightPower2 >= FightPower3 of
										true ->
											global:send(mgeew_crown_arena_server, {role_dead,RoleID3,RoleID2}),
											common_misc:unicast({role, RoleID3}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
											common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{});
										false ->
											global:send(mgeew_crown_arena_server, {role_dead,RoleID2,RoleID3}),
											common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
											common_misc:unicast({role, RoleID3}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{})
									end
							end,
							erlang:send_after(?DEAD_QUIP_PK_MAP_SECOND*1000, self(), {mod,mod_crown_arena_fb,{quip_pk_map_delay,[RoleID2,RoleID3]}});
						%% 					common_crown_arena:quit_pk_map_change_pos(RoleID2),
						%% 					common_crown_arena:quit_pk_map_change_pos(RoleID3);
						{#p_map_role{hp=_HP2},undefined} ->
							global:send(mgeew_crown_arena_server, {role_dead,RoleID3,RoleID2}),
							common_crown_arena:quit_pk_map_change_pos(RoleID2),
							common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{});
						{undefined,#p_map_role{hp=_HP3}} ->
							global:send(mgeew_crown_arena_server, {role_dead,RoleID2,RoleID3}),
							common_crown_arena:quit_pk_map_change_pos(RoleID3),
							common_misc:unicast({role, RoleID3}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{});
						_ ->
							ignore
					end;
				OtherEnter ->
					lists:foreach(fun(RoleID5) ->
										  common_crown_arena:quit_pk_map_change_pos(RoleID5) 
								  end , OtherEnter),
					?ERROR_MSG("error OtherEnter:~w",[OtherEnter])
			end;
		Other ->
			lists:foreach(fun(RoleID6) ->
								  common_crown_arena:quit_pk_map_change_pos(RoleID6) 
						  end , RoleList),
			?ERROR_MSG("error Other:~w",[Other])
	end,
	RoleIdList = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID8) ->
						  common_crown_arena:quit_pk_map_change_pos(RoleID8) 
				  end , RoleIdList--RoleList),
	%%每场结束奖励
	catch award_every(RoleList),
	%%清理PK地图数据
	erase_enter_pk_role(),
	%% 	erase_kick_roles_state(),
	erase_role_fight_result().

do_enter_pk_map(RoleTwoList) ->
	change_map(RoleTwoList).
	
change_map([]) ->
	ignore;
change_map([{RoleTup1,RoleTup2}|RoleTwoList]) ->
	change_map2({RoleTup1,RoleTup2}),
	change_map(RoleTwoList).

change_map2({RoleTup1,undefined}) ->
	#r_role_crown_arena{role_id=RoleID} = RoleTup1,
	erlang:send_after(3*1000, self(), {mod,mod_crown_arena_fb,{battle_result,RoleID}}),
	change_map3(RoleTup1);
change_map2({undefined,RoleTup2}) ->
	#r_role_crown_arena{role_id=RoleID} = RoleTup2,
	erlang:send_after(3*1000, self(), {mod,mod_crown_arena_fb,{battle_result,RoleID}}),
	change_map3(RoleTup2);
change_map2({RoleTup1,RoleTup2}) ->
	change_map3({RoleTup1,RoleTup2}).

change_map3(#r_role_crown_arena{role_id=RoleID,pk_map_process=MapProcess}) ->
	set_role_pk_map_process(RoleID,MapProcess),
	case global:whereis_name(MapProcess) of
		undefined ->
			mod_map_copy:async_create_copy(common_crown_arena:pk_map_id(),MapProcess,mod_crown_arena_fb,{RoleID,MapProcess,[]});
		MapPID ->
			{TX,TY} = get_pk_map_born_points(RoleID,[]),
			case mod_map_actor:get_actor_mapinfo(RoleID,role) of
				#p_map_role{max_hp=MaxHp,max_mp=MaxMp}->
					mod_map_role:do_role_add_hp(RoleID, MaxHp, RoleID),
					mod_map_role:do_role_add_mp(RoleID, MaxMp, RoleID),
					%%修改PK模式
					mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE),
					mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID,?PK_MAP_ID,TX,TY),
					erlang:send(MapPID,{mod,mod_crown_arena_fb,{role_win,{RoleID}}});
				_ ->
					ignore
			end
	end;
change_map3({RoleTup1,RoleTup2}) ->
	#r_role_crown_arena{role_id=RoleID1,pk_map_process=MapProcess1} = RoleTup1,
	#r_role_crown_arena{role_id=RoleID2,pk_map_process=MapProcess2} = RoleTup2,
	set_role_pk_map_process(RoleID1,MapProcess1),
	set_role_pk_map_process(RoleID2,MapProcess2),
	case global:whereis_name(MapProcess1) of
		undefined ->
			mod_map_copy:async_create_copy(common_crown_arena:pk_map_id(),MapProcess1,mod_crown_arena_fb,{RoleTup1,RoleTup2});
		MapPID -> 
			{TX1,TY1} = get_pk_map_born_points(RoleID1,[]),
			{TX2,TY2} = get_pk_map_born_points(RoleID2,[{TX1,TY1}]),
%% 			[PkSafeTimes] = common_config_dyn:find(crown_arena, pk_safe_time),
%% 			[PkTimes] = common_config_dyn:find(crown_arena, pk_time),
%% 			AfterPKSeconds = PkSafeTimes+PkTimes,
			case {mod_map_actor:get_actor_mapinfo(RoleID1,role),mod_map_actor:get_actor_mapinfo(RoleID2,role)} of
				{#p_map_role{role_name=RoleName1,state=State1,max_hp=MaxHp1,max_mp=MaxMp1},#p_map_role{role_name=RoleName2,state=State2,max_hp=MaxHp2,max_mp=MaxMp2}} ->
					mod_map_role:do_role_add_hp(RoleID1, MaxHp1, RoleID1),
					mod_map_role:do_role_add_mp(RoleID1, MaxMp1, RoleID1),
					%%修改PK模式
					mod_role2:modify_pk_mode_for_role(RoleID1,?PK_PEACE),
					case State1 =:= ?ROLE_STATE_DEAD of
						true ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE,RoleID1,?PK_MAP_ID,TX1,TY1);
						false ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID1,?PK_MAP_ID,TX1,TY1)
					end,
					mod_map_role:do_role_add_hp(RoleID2, MaxHp2, RoleID2),
					mod_map_role:do_role_add_mp(RoleID2, MaxMp2, RoleID2),
					%%修改PK模式
					mod_role2:modify_pk_mode_for_role(RoleID2,?PK_PEACE),
					case State2 =:= ?ROLE_STATE_DEAD of
						true ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE,RoleID2,?PK_MAP_ID,TX2,TY2);
						false ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID2,?PK_MAP_ID,TX2,TY2)
					end,
					erlang:send(MapPID,{mod,mod_crown_arena_fb,{role_win,{[{RoleID1,RoleName1},{RoleID2,RoleName2}]}}});
%% 					erlang:send_after(AfterPKSeconds*1000, self(), {mod,mod_crown_arena_fb,{quit_pk_map,[RoleID1,RoleID2],MapProcess1}});
				{#p_map_role{state=State1,max_hp=MaxHp1,max_mp=MaxMp1},undefined} ->
					mod_map_role:do_role_add_hp(RoleID1, MaxHp1, RoleID1),
					mod_map_role:do_role_add_mp(RoleID1, MaxMp1, RoleID1),
					%%修改PK模式
					mod_role2:modify_pk_mode_for_role(RoleID1,?PK_PEACE),
					case State1 =:= ?ROLE_STATE_DEAD of
						true ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE,RoleID1,?PK_MAP_ID,TX1,TY1);
						false ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID1,?PK_MAP_ID,TX1,TY1)
					end,
					erlang:send(MapPID,{mod,mod_crown_arena_fb,{role_win,{RoleID1}}});
				{undefined,#p_map_role{state=State2,max_hp=MaxHp2,max_mp=MaxMp2}} ->
					mod_map_role:do_role_add_hp(RoleID2, MaxHp2, RoleID2),
					mod_map_role:do_role_add_mp(RoleID2, MaxMp2, RoleID2),
					%%修改PK模式
					mod_role2:modify_pk_mode_for_role(RoleID2,?PK_PEACE),
					case State2 =:= ?ROLE_STATE_DEAD of
						true ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE,RoleID2,?PK_MAP_ID,TX2,TY2);
						false ->
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID2,?PK_MAP_ID,TX2,TY2)
					end,
					erlang:send(MapPID,{mod,mod_crown_arena_fb,{role_win,{RoleID2}}});
				_ ->
					ignore
			end
	end.

do_crown_arena_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line}=Info) ->
	#m_crown_arena_quit_tos{type=QuitType} = DataIn,
    case catch check_crown_arena_quit(RoleID,DataIn) of
        ok->
            case QuitType of
                ?QUIT_TYPE_WAIT_MAP ->
					global:send(mgeew_crown_arena_server, {role_quit,RoleID}),
                    do_quit_wait_map_normal(RoleID),
					R2 = #m_crown_arena_quit_toc{type=QuitType},
					?UNICAST_TOC(R2);
                ?QUIT_TYPE_PK_MAP ->
					cancel_pk_timerRef(),
                    do_quit_pk_map_normal(RoleID),
					R2 = #m_crown_arena_quit_toc{type=QuitType},
					?UNICAST_TOC(R2);
				?QUIT_TYPE_CULL_PK_MAP ->
					mod_crown_arena_cull_fb:handle(Info);
				?QUIT_TYPE_CULL_PK_MAP_IGNORE ->
					mod_crown_arena_cull_fb:handle(Info)
            end;
        {error,ErrCode,Reason}->
            R2 = #m_crown_arena_quit_toc{type=QuitType,error_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
    end.

do_quit_wait_map_normal(RoleID) ->
	%%修改PK模式
	mod_role2:modify_pk_mode_for_role(RoleID,?PK_FACTION),
	{DestMapId,TX,TY} = common_map:get_map_return_pos_of_jingcheng(RoleID),
     mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY).

do_quit_pk_map_normal(RoleID) ->
	case get_enter_pk_role() of
	[RoleID1,RoleID2] ->
		case get_role_fight_result() of
			{_,_} ->
			  ignore;
			[] ->
			[WinRoleID] = lists:delete(RoleID, [RoleID1,RoleID2]),
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{is_win=false}),
			common_misc:unicast({role, WinRoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_BATTLE_RESULT, #m_crown_battle_result_toc{})
		end;
		_ ->
			ignore
	end,
	set_role_fight_result(RoleID),
	{Tx,Ty} = common_crown_arena:get_wait_map_born_points(RoleID),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, ?WAIT_MAP_ID, Tx, Ty).	

	
check_crown_arena_quit(_RoleID,DataIn) ->
	#m_crown_arena_quit_tos{type=QuitType} = DataIn,
    case is_in_fb_map(QuitType) of
        true->
            next;
        _->
            ?THROW_ERR( ?ERR_CROWN_ARENA_NOT_IN_FB )
    end,
    ok.
is_in_fb_map(QuitType) ->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case QuitType of
		?QUIT_TYPE_WAIT_MAP ->
			MapID =:= ?WAIT_MAP_ID;
		?QUIT_TYPE_PK_MAP ->
			MapID =:= ?PK_MAP_ID;
		_ ->
			MapID =:= ?CULL_PK_MAP_ID 
	end.
is_in_fb_map() ->
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	MapID =:= ?WAIT_MAP_ID orelse MapID =:= ?PK_MAP_ID orelse MapID =:= ?CULL_PK_MAP_ID.

do_deposit(RoleID,DataIn) ->
	#m_crown_arena_deposit_tos{deposit_money=Silver} = DataIn,
	TransFun =
		fun() ->
				case common_bag2:t_deduct_money(silver_any, Silver, RoleID, ?CONSUME_TYPE_SILVER_CROWN_DIPOSIT) of
					{ok,RoleAttr2}-> next;
					{error, Reason}->
						RoleAttr2 = null,
						?THROW_ERR(?ERR_OTHER_ERR, Reason)
				end,
				{ok, RoleAttr2}
		end,
	case common_transaction:transaction(TransFun) of
		{atomic, {ok, RoleAttr2}} ->
			global:send(mgeew_crown_arena_server,
													{mod,mod_crown_arena_deposit,
													 {deposit,RoleID,DataIn}}),
			common_misc:send_role_silver_change(RoleID, RoleAttr2),
			R2 = #m_crown_arena_deposit_toc{},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_ARENA_DEPOSIT, R2);
		{aborted, {error,ErrCode,Reason}} ->
			R2 = #m_crown_arena_deposit_toc{error_code=ErrCode, reason = Reason},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_ARENA_DEPOSIT, R2);
		{aborted, Reason} ->
			?ERROR_MSG(" jingjie skill armor do_start_silver_training, error: ~w", [Reason])
	end.

									 
do_crown_arena_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	case catch check_crown_arena_enter(RoleID,DataIn) of
        {ok,FactionId}->
            do_crown_arena_enter_2(RoleID,FactionId);
        {error,ErrCode,Reason}->
            R2 = #m_crown_arena_enter_toc{error_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

do_crown_arena_enter_2(RoleID,_FactionId) ->
	{ok,#p_role_base{role_name=RoleName,faction_id=FactionID}=RoleBase} = mod_map_role:get_role_base(RoleID),
	{ok,#p_role_attr{level=Level,jingjie=JingJie}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
	FightPower = common_role:get_fighting_power(RoleBase, RoleAttr),
	global:send(mgeew_crown_arena_server, {enter_wait_map,RoleID,RoleName,JingJie,FightPower,Level,FactionID}),
    hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_ARENABATTLE),
	%%地图跳转
    {Tx,Ty} = common_crown_arena:get_wait_map_born_points(RoleID),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, ?WAIT_MAP_ID, Tx, Ty).
	
	
check_crown_arena_enter(RoleID,_DataIn) ->
 	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
  	{ok,#p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
    assert_role_level(RoleAttr),
 	#map_state{mapid=MapID,map_type=MapType} = mgeem_map:get_state(),
    IsInWarofkingFb = mod_warofking:is_fb_map_id(MapID),
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_CROWN_ARENA_ENTER_FB_LIMIT );
        IsInWarofkingFb->
            ?THROW_ERR(?ERR_CROWN_ARENA_ENTER_FB_LIMIT);
        true->
            next
    end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
	    true ->
	        ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
	    false -> ignore
	end,
	{ok,FactionId}.

get_pk_map_born_points(_RoleID,PointList) ->
	[FbBornPoints] = common_config_dyn:find(crown_arena,pk_map_born_points),
	common_tool:random_element(FbBornPoints--PointList).

assert_role_level(RoleAttr)->
    #p_role_attr{level=RoleLevel} = RoleAttr,
    [MinRoleLevel] = common_config_dyn:find(crown_arena,enter_map_min_level),
    if
        MinRoleLevel>RoleLevel->
            ?THROW_ERR( ?ERR_CROWN_ARENA_ENTER_LV_LIMIT );
        true->
            next
    end,
    ok.

assert_valid_map_id(DestMapID)->
	case ?WAIT_MAP_ID =:= DestMapID orelse ?PK_MAP_ID =:= DestMapID of
		true->
			ok;
		_ ->
			?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
			throw({error,error_map_id,DestMapID})
	end.

get_map_name_to_enter(RoleID)->
	{DestMapID, _TX, _TY} = get({enter, RoleID}),
	case ?WAIT_MAP_ID =:= DestMapID of
		true ->
    		common_crown_arena:wait_map_process_name();
		false ->
			case ?PK_MAP_ID =:= DestMapID of
				true ->
					get_role_pk_map_process(RoleID);
				false ->
					process
			end
	end.

clear_map_enter_tag(_RoleId)->
    ignore.

kick_all_role(RoleIDList) ->
	EnterRoleIDs = get_enter_pk_role(),
	RoleIdList1 = mod_map_actor:get_in_map_role(),
	lists:foreach(fun(RoleID) ->
						  mod_role2:modify_pk_mode_for_role(RoleID,?PK_FACTION),
						  case common_map:get_map_return_pos_of_jingcheng(RoleID) of
							  {DestMapId,TX,TY} -> 
								  case mod_map_actor:get_actor_mapinfo(RoleID,role) of
									  #p_map_role{state=State}->%%死亡状态
										  %%修改PK模式
											mod_role2:modify_pk_mode_for_role(RoleID,?PK_FACTION),
										  case State =:= ?ROLE_STATE_DEAD of
											  true ->
												  mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE, RoleID, DestMapId, TX, TY);
											  false ->
												  mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY)
										  end;
									  _ ->
										  ignore
								  end;
							  _ ->
								  ignore
						  end
				  end, RoleIdList1++EnterRoleIDs++RoleIDList).

