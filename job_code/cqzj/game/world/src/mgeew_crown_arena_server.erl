%%% -------------------------------------------------------------------
%%% Author  : ldk
%%% Description :
%%%%%%     战神坛副本（定时开启的副本）
%%% Created : 2012-6-2
%%% -------------------------------------------------------------------
-module(mgeew_crown_arena_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").
-include("crown_arena.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([get_already_rank/0,
%% 		 set_deposit/1,
%% 		 erase_deposit/0,
%% 		 get_deposit/0,
%% 		 erase_deposit_roles/0,
%% 		  set_deposit_roles/1,
%% 		 get_deposit_roles/0,
		 erase_crown_arena_enter/0
		 
		]).

-export([start/0,
         start_link/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).
%%最多多少人参加
-define(MAX_ENTER_NUM,200). 

%%奖励类型
-define(AWARE_EXP,1). %%类型1为：经验
-define(AWARD_MONEY,2). %%2：绑定金
-define(ARARD_GIFT,3). %%3：礼包数量
-define(ARARD_GIFT_EXT,4). %%4：连胜礼包数量

-define(ROLE_CROWN_ARENA_LIFE,0). %%
-define(ROLE_CROWN_ARENA_DEAD,1). %%死亡
-define(ROLE_CROWN_ARENA_QUIT,2). %%退出地图或下线


-define(ROLE_CROWN_INFO_SELF,1). %%个人信息
-define(ROLE_CROWN_INFO_OTHRE,2). %%其他列家信息
-define(ROLE_CROWN_INFO_ALL,3). %%全部信息
-define(ROLE_CROWN_INFO_END,4). %%PK结束个人领奖信息
-define(ROLE_CROWN_INFO_ONLINE,5). %%重新登录时

-define(RANK_INFO_MAX,11). %%反回给前端最大排名信息


-define(STATE_1,1). %%1为：还没开始每一次PK前的等待状态
-define(STATE_2,2). %%2：PK中
-define(STATE_3,3). %%2：战神坛活动结束了
-record(r_crown_arena_time,{open_time=0,next_pk_time=0,state=1}).

%% ====================================================================
%% External functions
%% ====================================================================
start()->
    {ok,_} = supervisor:start_child(mgeew_sup,{?MODULE,
                                               {?MODULE,start_link,[]},
                                               permanent,30000, worker,
                                               [?MODULE]}).

start_link()->
    gen_server:start_link({global,?MODULE}, ?MODULE, [], []).


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
	[Open] = common_config_dyn:find(crown_arena_cull, is_open),
	case Open of
		true ->
			init_crown_arena(),
			AfterSecs = common_time:diff_next_daytime(0, 0),
			erlang:send_after(AfterSecs*1000, self(), open_everyday);
		false ->
			ignore
	end,
	{ok, #state{}}.


init_crown_arena() ->
	[{weekly,Times}] = common_config_dyn:find(crown_arena, open_times),
	WeekDay = common_time:weekday(),
	case lists:keyfind(WeekDay, 1, Times) of
		false ->
			ignore;
		{_,[{StartTime,_EndTime}]} ->
			case StartTime > time() of
				false ->
					ignore;
				true ->
					Now = common_tool:now(),
    				Start = common_tool:datetime_to_seconds({date(),StartTime}),
%% 					send_after(1,self(),gm_open_activity),
                    [{BeforeSeconds,BeforeInterval,BCTimes}] = common_config_dyn:find(crown_arena, fb_open_before_msg_bc),
                    StartBCTime = Start - BeforeSeconds,
                    EndBCTime = StartBCTime + BeforeInterval * (BCTimes - 1),
                    BroadcastTimeList = lists:seq(StartBCTime, EndBCTime, BeforeInterval),
                    lists:foreach(fun(T) ->
                                        case T > Now of
                                            true ->
                                                erlang:send_after((T-Now)*1000, self(), {fb_open_before_broadcast,Start});
                                            _ -> ignore
                                        end
                                  end, BroadcastTimeList),
					erlang:send_after((Start-Now)*1000, self(), gm_open)
			end
	end.

set_role_join_battle_num(RoleID) ->
	RankInfo = get_rank_info(),
	case lists:keyfind(RoleID, #r_crown_role_rank.role_id, RankInfo) of
		false ->
			?ERROR_MSG("-----set_role_join_battle_num error RoleID==~w",[RoleID]);
		RoleRank ->
			#r_crown_role_rank{join_battle_num=JoinBattleNum} = RoleRank,
			put({?MODULE,rank_info},[RoleRank#r_crown_role_rank{join_battle_num=JoinBattleNum+1}|lists:delete(RoleRank, RankInfo)])
	end.

%% get_deposit() ->
%% 	case get({?MODULE,deposit}) of
%% 		undefined ->
%% 			?DEPOSIT_STATUS_0;
%% 		Deposit ->
%% 			Deposit
%% 	end.
%% 
%% set_deposit(Type) ->
%% 	put({?MODULE,deposit},Type).
%% erase_deposit() ->
%% 	erlang:erase({?MODULE,deposit}).
%% 
%% set_deposit_roles(DepositRoles) ->
%% 	put({?MODULE,deposit_roles},DepositRoles).
%% get_deposit_roles() ->
%% 	case get({?MODULE,deposit_roles}) of
%% 		undefined ->
%% 			[];
%% 		DepositRoles ->
%% 			DepositRoles
%% 	end.
%% erase_deposit_roles() ->
%% 	erlang:erase({?MODULE,deposit_roles}).

send_after(Seconds,Pid,Key) ->
	cancel_timerref(Key),
	TimerRef = erlang:send_after(Seconds*1000, Pid, Key),
	put({?MODULE,Key},TimerRef),
	set_all_timerref({Key,TimerRef}).

set_all_timerref({Key,TimerRef}) ->
	case get({?MODULE,all_timerref}) of
		undefined ->
			put({?MODULE,all_timerref},[{Key,TimerRef}]);
		TimerRefs ->
			put({?MODULE,all_timerref},[{Key,TimerRef}|lists:keydelete(Key, 1, TimerRefs)])
	end.

erase_all_timerref() ->
	erlang:erase({?MODULE,all_timerref}).

cancel_all_timerref() ->
	case get({?MODULE,all_timerref}) of
		undefined ->
			ignore;
		TimerRefs ->
			lists:foreach(fun({_,TimerRef}) ->
								  erlang:cancel_timer(TimerRef)
								  end, TimerRefs)
	end.

cancel_timerref(Key) ->
	case get({?MODULE,Key}) of
		undefined ->
			ignore;
		TimerRef ->
			erlang:cancel_timer(TimerRef)
	end.

get_pk_mapprocess() ->
	case get({?MODULE,pk_mapprocess}) of
		undefined ->
			[];
		MapProcessNames ->
			MapProcessNames
	end.

set_pk_mapprocess(MapProcessName) ->
	case get({?MODULE,pk_mapprocess}) of
		undefined ->
			put({?MODULE,pk_mapprocess},[MapProcessName]);
		MapProcessNames ->
			put({?MODULE,pk_mapprocess},[MapProcessName|lists:delete(MapProcessName, MapProcessNames)])
	end.

erase_pk_mapprocess_num() ->
	case get_pk_mapprocess() of
		[] ->
			ignore;
		MapProcessNames ->
			lists:foreach(fun(MapProcessName) ->
								  case global:whereis_name(MapProcessName) of
									  undefined ->
										  ignore;
									  MapPID ->
										  erlang:send(MapPID,{mod,mod_crown_arena_fb,{pk_process_kill,[]}})
								  end
						  end, MapProcessNames)
	end,
	erlang:erase({?MODULE,pk_mapprocess}).

erase_crown_arena_enter() ->
	erlang:erase({?MODULE,crown_arena_time}).
get_crown_arena_enter() ->
	get({?MODULE,crown_arena_time}).
open_crown_arena_enter() ->
	%%多少秒后进入PK
	[AfterPKSeconds] = common_config_dyn:find(crown_arena, open_copy_to_pk),
	put({?MODULE,crown_arena_time},#r_crown_arena_time{open_time=common_tool:now(),next_pk_time=common_tool:now()+AfterPKSeconds,state=?STATE_1}).

check_crown_arena_enter() ->
	case get({?MODULE,crown_arena_time}) of
		undefined ->
			false;
		#r_crown_arena_time{state=?STATE_3} ->
			false;
		_ ->
			true
	end.

set_crown_arena_pk(Num) ->
	[PkNum] = common_config_dyn:find(crown_arena, pk_num),
	case Num < PkNum of
		true ->
			CrownTimes = get({?MODULE,crown_arena_time}),
			[AfterPKSeconds1] = common_config_dyn:find(crown_arena, pk_safe_time),
			[AfterPKSeconds2] = common_config_dyn:find(crown_arena, pk_time),
			[IntevalTime] = common_config_dyn:find(crown_arena, pk_interval_time),
			AfterPKSeconds =AfterPKSeconds1+AfterPKSeconds2+IntevalTime,
			put({?MODULE,crown_arena_time},CrownTimes#r_crown_arena_time{next_pk_time=common_tool:now()+AfterPKSeconds,state=?STATE_2});
		false ->
			ignore
	end.



erase_already_rank() ->
	erlang:erase({?MODULE,already_rank}).
set_already_rank(NewRankList) ->
	put({?MODULE,already_rank},NewRankList).

get_already_rank() ->
	case get({?MODULE,already_rank}) of
		undefined ->
			[];
		RankInfo ->
			RankInfo
	end.


init_rank_info(RoleID,RoleName,JingJie,FightPower,Level,FactionID) ->
	Score = get_role_score(RoleID),
	case get({?MODULE,rank_info}) of
		undefined ->
			put({?MODULE,rank_info},[#r_crown_role_rank{role_id=RoleID,faction_id=FactionID,role_name=RoleName,level=Level,score=Score,jingjie=JingJie,fightpower=FightPower}]);
		[] ->
			put({?MODULE,rank_info},[#r_crown_role_rank{role_id=RoleID,faction_id=FactionID,role_name=RoleName,level=Level,score=Score,jingjie=JingJie,fightpower=FightPower}]);
		RoleRankList ->
			case lists:keyfind(RoleID, #r_role_crown_arena.role_id, RoleRankList) of
				false ->
					put({?MODULE,rank_info},[#r_crown_role_rank{role_id=RoleID,faction_id=FactionID,role_name=RoleName,level=Level,score=Score,jingjie=JingJie,fightpower=FightPower}|RoleRankList]);
				RoleRank->
					put({?MODULE,rank_info},[RoleRank#r_crown_role_rank{role_id=RoleID,faction_id=FactionID,role_name=RoleName,level=Level,score=Score,jingjie=JingJie,fightpower=FightPower}|lists:delete(RoleRank, RoleRankList)])
			end
	end.

get_rank_info() ->
	case get({?MODULE,rank_info}) of
		undefined ->
			[];
		RoleRankList ->
			RoleRankList
	end.

set_role_rank_state(DeadRoleID) ->
	RankInfo = get_rank_info(),
	case lists:keyfind(DeadRoleID, #r_crown_role_rank.role_id, RankInfo) of
		false ->
			?ERROR_MSG("-----set_role_rank_state error RoleID==~w",[DeadRoleID]);
		RoleRank ->
			put({?MODULE,rank_info},[RoleRank#r_crown_role_rank{forwar_state=false}|lists:delete(RoleRank, RankInfo)])
	end.

and_role_rank_score(RoleID) ->
	RankInfo = get_rank_info(),
	case lists:keyfind(RoleID, #r_crown_role_rank.role_id, RankInfo) of
		false ->
			?ERROR_MSG("-----set_role_rank error RoleID==~w",[RoleID]);
		RoleRank ->
			#r_crown_role_rank{forwar_state=ForwarState,link_win=LinkWin,max_link_win=MaxLinkWin,score=Score} = RoleRank,
			NewLinkWin = 
			case ForwarState of
				true ->
					LinkWin + 1;
				false ->
					LinkWin
			end,
			NewMaxLinkWin = 
				case NewLinkWin > MaxLinkWin of
					true ->
						NewLinkWin;
					false ->
						MaxLinkWin
				end,
			put({?MODULE,rank_info},[RoleRank#r_crown_role_rank{forwar_state=true,link_win=NewLinkWin,max_link_win=NewMaxLinkWin,score=Score+1}|lists:delete(RoleRank, RankInfo)])
	end.
	
erase_rank_info() ->
	erlang:erase({?MODULE,rank_info}).


get_role_score(RoleID) ->
	EnterRoles = get_enter_wait_map(),
	case lists:keyfind(RoleID, #r_role_crown_arena.role_id, EnterRoles) of
		false ->
			0;
		#r_role_crown_arena{score=Score} ->
			Score
	end.
set_enter_wait_map(RoleID,_RoleName) ->
	case get({?MODULE,enter_wait_map}) of
		undefined ->
			put({?MODULE,enter_wait_map},[#r_role_crown_arena{role_id=RoleID}]),
			[#r_role_crown_arena{role_id=RoleID}];
		[] ->
			put({?MODULE,enter_wait_map},[#r_role_crown_arena{role_id=RoleID}]),
			[#r_role_crown_arena{role_id=RoleID}];
		RoleEnterList ->
			case lists:keyfind(RoleID, #r_role_crown_arena.role_id, RoleEnterList) of
				false ->
					put({?MODULE,enter_wait_map},[#r_role_crown_arena{role_id=RoleID}|RoleEnterList]),
					[#r_role_crown_arena{role_id=RoleID}|RoleEnterList];
				RoleEnter ->
					NewRoleEnterList = [RoleEnter#r_role_crown_arena{state=?ROLE_CROWN_ARENA_LIFE}|lists:delete(RoleEnter, RoleEnterList)],
					put({?MODULE,enter_wait_map},NewRoleEnterList),
					NewRoleEnterList
			end
	end.
get_enter_wait_map() ->
	case get({?MODULE,enter_wait_map}) of
		undefined ->
			[];
		List ->
			List
	end.

erase_enter_wait_map() ->
	erase({?MODULE,enter_wait_map}).

add_score_and_change_state(DeadRoleID,WinRoleID) ->
	RoleEnterList = get_enter_wait_map(),
	case lists:keyfind(DeadRoleID, #r_role_crown_arena.role_id, RoleEnterList) of
		false ->
			ignore;
		DeadRoleInfo ->
			set_role_rank_state(DeadRoleID),
			put({?MODULE,enter_wait_map},[DeadRoleInfo#r_role_crown_arena{state=?ROLE_CROWN_ARENA_DEAD}|lists:keydelete(DeadRoleID, #r_role_crown_arena.role_id, RoleEnterList)])
	end,
	case lists:keyfind(WinRoleID, #r_role_crown_arena.role_id, RoleEnterList) of
		false ->
			ignore;
		RoleInfo ->
			#r_role_crown_arena{score=Score} = RoleInfo,
			and_role_rank_score(WinRoleID),
			put({?MODULE,enter_wait_map},[RoleInfo#r_role_crown_arena{score=Score+1}|lists:keydelete(WinRoleID, #r_role_crown_arena.role_id, RoleEnterList)])
	end.

role_quit(RoleID) ->
	RoleEnterList = get_enter_wait_map(),
	case lists:keyfind(RoleID, #r_role_crown_arena.role_id, RoleEnterList) of
		false ->
			ignore;
		RoleInfo ->
			put({?MODULE,enter_wait_map},[RoleInfo#r_role_crown_arena{state=?ROLE_CROWN_ARENA_QUIT}|lists:keydelete(RoleID, #r_role_crown_arena.role_id, RoleEnterList)])
	end.

set_pk_num(Num) ->
	put({?MODULE,cur_pk_num},Num).

get_pk_num() ->
	case get({?MODULE,cur_pk_num}) of
		undefined ->
			0;
		Num ->
			Num
	end.

erase_pk_num() ->
	erlang:erase({?MODULE,cur_pk_num}).

erase_all_dict2() ->
	erase_pk_mapprocess_num().
%%清除有顺序关系
erase_all_dict() ->
%% 	%%活动结束
	erase_pk_mapprocess_num(),
	erase_enter_wait_map(),
	erase_crown_arena_enter(),
	%% 	erase_rank_info(),
	%% 	cancel_all_timerref(),
	%% 	erase_already_rank(),
	erase_all_timerref().
%% 	erase_pk_num().
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
	 ?DO_HANDLE_INFO(Info,State),
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

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

do_handle_info({_, _, ?CROWN_ARENA_ENTER, _, _, _, _}=Msg) ->
	do_crown_arena_enter(Msg);

do_handle_info({_, _, ?CROWN_ARENA_INFO, _, _, _, _}=Msg) ->
	do_crown_arena_info(Msg);

do_handle_info({_, _, ?CROWN_ARENA_AWARD, _, _, _, _}=Msg) ->
	do_crown_arena_award(Msg);

%%战神坛淘汰赛
do_handle_info({_, _, ?CROWN_PROMOTE_INFO, _, _, _, _}=Msg) ->
	mod_crown_arena_cull:handle(Msg);
do_handle_info({_, _, ?CROWN_ARENA_WATCH, _, _, _, _}=Msg) ->
	mod_crown_arena_cull:handle(Msg);
do_handle_info({_, _, ?CROWN_CULL_AWARD, _, _, _, _}=Msg) ->
	mod_crown_arena_cull:handle(Msg);

do_handle_info({mod,mod_crown_arena_cull,Msg})->
	mod_crown_arena_cull:handle(Msg);

%%押注
do_handle_info({_, _, ?CROWN_DEPOSIT_INFO, _, _, _, _}=Msg) ->
	mod_crown_arena_deposit:handle(Msg);
do_handle_info({_, _, ?CROWN_DEPOSIT_SEARCH, _, _, _, _}=Msg) ->
	mod_crown_arena_deposit:handle(Msg);
do_handle_info({_, _, ?CROWN_ARENA_DEPOSIT, _, _, _, _}=Msg) ->
	mod_crown_arena_deposit:handle(Msg);
do_handle_info({_, _, ?CROWN_DEPOSIT_LOG, _, _, _, _}=Msg) ->
	mod_crown_arena_deposit:handle(Msg);
do_handle_info({_, _, ?CROWN_DEPOSIT_LOOK, _, _, _, _}=Msg) ->
	mod_crown_arena_deposit:handle(Msg);
do_handle_info({mod,mod_crown_arena_deposit,Msg})->
	mod_crown_arena_deposit:handle(Msg);

do_handle_info(gm_open_activity)->
	%%开启活动，并获取百强榜数据
%% 	set_deposit_roles(DepositRoles),
	common_activity:notfiy_activity_end(?ARENABATTLE_ACTIVITY_ID),
	timer:sleep(3000),
	open_crown_arena_enter(),
	common_activity:notfiy_activity_start({?ARENABATTLE_ACTIVITY_ID, common_tool:now(), common_tool:now()+1, common_tool:now()+80000}),
    ok;

%%GM关闭
do_handle_info(gm_close)->
	common_activity:notfiy_activity_end(?ARENABATTLE_ACTIVITY_ID),
	erase_pk_mapprocess_num(),
	erase_enter_wait_map(),
	erase_already_rank(),
	erase_rank_info(),
	cancel_all_timerref(),
	erlang:send_after(1000, self(), {mod,mod_crown_arena_cull,{cull_kill_all}}),
	timer:sleep(10000),
	common_map:exit(kill);
%% 	erase_pk_num();

%%GM开启
do_handle_info(gm_open)->
	erase_pk_mapprocess_num(),
	erase_enter_wait_map(),
	erase_already_rank(),
	erase_rank_info(),
	cancel_all_timerref(),
	erase_pk_num(),
	mod_crown_arena_cull:erase_all(),
%% 	erase_deposit(),
%% 	erase_deposit_roles(),
	timer:sleep(1000),
	%% 活动开始消息通知
	[AfterPKSeconds1] = common_config_dyn:find(crown_arena, pk_safe_time),
	[AfterPKSeconds2] = common_config_dyn:find(crown_arena, pk_time),
	[AfterPKSeconds3] = common_config_dyn:find(crown_arena, pk_interval_time),
	[AfterPKSeconds4] = common_config_dyn:find(crown_arena, open_copy_to_pk),
	[PkNum] = common_config_dyn:find(crown_arena, pk_num),
	[Time4] = common_config_dyn:find(crown_arena_cull, {open,4}),
	[Time2] = common_config_dyn:find(crown_arena_cull, {open,2}),
	[Time1] = common_config_dyn:find(crown_arena_cull, {open,1}),
	[SafeTime1] = common_config_dyn:find(crown_arena_cull, one_pk_safe_time),
	[SafeTime2] = common_config_dyn:find(crown_arena_cull, other_pk_safe_time),
	[PkTime] = common_config_dyn:find(crown_arena_cull, pk_time),
    ResetTime = SafeTime1*3 + SafeTime2*3*2 + PkTime*3*3,
	%%积分赛时间
	AfterPKSeconds5 =PkNum*(AfterPKSeconds1+AfterPKSeconds2+AfterPKSeconds3)+AfterPKSeconds4,
	%%淘汰赛时间
	AfterPKSeconds6 = Time4+Time2+Time1,
	%%总时间
	AfterPKSeconds = AfterPKSeconds5+AfterPKSeconds6 + ResetTime*3,
    common_activity:notfiy_activity_start({?ARENABATTLE_ACTIVITY_ID, common_tool:now(), common_tool:now()+1, common_tool:now()+AfterPKSeconds}),
	send_after(1,self(),start_crown_arena),
	send_after(AfterPKSeconds5+30,self(),end_crown_arena);
%% 	send_after(AfterPKSeconds5+30,self(),{mod,mod_crown_arena_cull,{update_time_over}});
	%%设置押注标志
%% 	set_deposit(?DEPOSIT_STATUS_10);

do_handle_info({fb_open_before_broadcast, StartTime}) ->
    {_Date,Time} = common_tool:seconds_to_datetime(StartTime),
    StartTimeStr = common_time:time_string(Time),
    PrestartBC = common_misc:format_lang(?_LANG_ARENABATTLE_BC_PRESTART,[StartTimeStr]),
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,PrestartBC),
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT_WORLD,PrestartBC);

do_handle_info({role_quit,RoleID})->
	role_quit(RoleID);

do_handle_info({already_receive,RoleID})->
	do_already_receive(RoleID);

do_handle_info({role_online, RoleID})->
	role_online(RoleID);

%%PK时间到，两个玩家都没死亡，当前血量少的也算死亡
do_handle_info({role_dead,DeadRoleID,WinRoleID})->
	add_score_and_change_state(DeadRoleID,WinRoleID);

%%每天开启
do_handle_info(open_everyday)->
	[Open] = common_config_dyn:find(crown_arena_cull, is_open),
	case Open of
		true ->
			erlang:send_after(86400*1000, self(), open_everyday),
			init_crown_arena();
		false ->
			ignore
	end;

do_handle_info({erase_all_dict})-> 
	erase_all_dict();

do_handle_info({kick_all_role}) ->
	lists:foreach(fun(Num) ->
						  MapProcessName = common_crown_arena:cull_pk_map_process_name(Num),
						  case global:whereis_name(MapProcessName) of
							undefined ->
								ignore;
							MapPID ->
						  		erlang:send(MapPID,{mod,mod_crown_arena_cull_fb,{kick_all_role}})
						  end
						  end, lists:seq(1, 8));

do_handle_info(gm_init)-> 
	do_cmp_score(),
	mod_crown_arena_cull:init(gm_init);

%%统计排名
do_handle_info({cmp_score,Num})->
	do_cmp_score(),
	[PkNum] = common_config_dyn:find(crown_arena, pk_num),
	case Num >= PkNum of
		true ->
			%%发奖励
			crown_arena_reward(),
			%%积分赛结束广播
			catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,?_LANG_ARENABATTLE_CLOSED_FINAL),
			%%触发淘汰赛
			mod_crown_arena_cull:init();
		false ->
			ignroe
	end;	

%%结束一场PK
do_handle_info({pk_finish,Num})->
	%%延迟1秒统计排名，先处理完地图中平局的情况
	send_after(1,self(),{cmp_score,Num}),
	[PkNum] = common_config_dyn:find(crown_arena, pk_num),
	[IntervalTime] = common_config_dyn:find(crown_arena, pk_interval_time),
	case Num > PkNum of
		true ->
			ignore;
		false ->
			send_after(IntervalTime,self(),{open_copy_to_pk,Num+1})
	end;
	
%%通知地图进程PK开始

do_handle_info({open_copy_to_pk,Num})->
	[PkNum] = common_config_dyn:find(crown_arena, pk_num),
	case Num > PkNum of
		true ->
			ignore;
		false ->
			set_pk_num(Num)
	end,
	set_crown_arena_pk(Num),
	do_open_copy_to_pk(Num,PkNum);


do_handle_info({loop_quit_pk_map,MapPID})->
	erlang:send(MapPID,{mod,mod_crown_arena_fb,{quit_pk_map}});
	
%%开启后，通知地图进程相关
do_handle_info(start_crown_arena)->
	MapId = common_crown_arena:wait_map_id(),
	send_msg_to_map(MapId,mod_crown_arena_fb,{start_crown_arena}),
	%% 副本开起过程中广播时间到
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,?_LANG_ARENABATTLE_BC_STARTED),
	open_crown_arena_enter(),
	%%多少秒后进入PK
	[AfterPKSeconds] = common_config_dyn:find(crown_arena, open_copy_to_pk),
	send_after(AfterPKSeconds,self(),{open_copy_to_pk,1});

 do_handle_info({end_crown_arena_wait_map})->
	MapId = common_crown_arena:wait_map_id(),
	send_msg_to_map(MapId,mod_crown_arena_fb,{end_crown_arena});
%%结束报名后（即不能进入等待进图）
do_handle_info(end_crown_arena)->
	erase_all_dict2();
%% 	close_crown_arena_enter();
do_handle_info({create_map,Num})->
	 MapProcessName = common_crown_arena:pk_map_process_name(Num),
	 mod_map_copy:async_create_copy(common_crown_arena:pk_map_id(),MapProcessName,mod_crown_arena_fb,Num);

%%创建PK地图成功 {mod,mgeew_crown_arena_server,{create_map_succ,1}}
do_handle_info({mod,mgeew_crown_arena_server,{create_map_succ,Msg}})->
	#r_crown_arena_time{next_pk_time=_NextPkTime} = get_crown_arena_enter(),
	MapProcessName =
	case Msg of
		{map_create,MapProcess} ->
			MapProcess;
		_ ->
			 common_crown_arena:pk_map_process_name(Msg)
		
	end,
	case global:whereis_name(MapProcessName) of
		undefined ->
			?ERROR_MSG("mgeew_crown_arena_server create_map_fail :~w",[MapProcessName]);
		_MapPID ->
			set_pk_mapprocess(MapProcessName)
	end;


%%每个玩家进入等待地图记录下，以便预先创建多少个PK地图进程
do_handle_info({enter_wait_map,RoleID,RoleName,JingJie,FightPower,Level,FactionID})->
	init_rank_info(RoleID,RoleName,JingJie,FightPower,Level,FactionID),
	EnterTupRoles = set_enter_wait_map(RoleID,RoleName),
	ProcessList = get_pk_mapprocess(),
	case length(EnterTupRoles) rem 2 of
		1 ->
			create_map_process(length(ProcessList)+1);
		0 ->
			ignore
	end;

do_handle_info({one,hook_role_enter_pk_map,RoleID})->
	set_role_join_battle_num(RoleID),
	[AfterPKSeconds1] = common_config_dyn:find(crown_arena, pk_safe_time),
	R2 = #m_crown_update_time_toc{status=?PK_MAP_SAFE_TIME,seconds=AfterPKSeconds1,battle_num=get_pk_num()-1},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2);
	
do_handle_info({two,hook_role_enter_pk_map,[{RoleID1,RoleName1},{RoleID2,RoleName2}]})->
	set_role_join_battle_num(RoleID1),
	set_role_join_battle_num(RoleID2),
	[AfterPKSeconds1] = common_config_dyn:find(crown_arena, pk_safe_time),
	R2 = #m_crown_update_time_toc{right_name=RoleName1,left_name=RoleName2,status=?PK_MAP_SAFE_TIME,seconds=AfterPKSeconds1,battle_num=get_pk_num()-1},
	common_misc:unicast({role, RoleID1}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2),
	common_misc:unicast({role, RoleID2}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2);
%% 	erlang:send_after(AfterPKSeconds1*1000, self(), {hook_role_enter_pk_time,RoleID});

%% do_handle_info({hook_role_enter_pk_time,RoleID})->
%% 	[AfterPKSeconds2] = common_config_dyn:find(crown_arena, pk_time),
%% 	R2 = #m_crown_update_time_toc{status=?PK_MAP_LEAVE_TIME_TYPE,seconds=AfterPKSeconds2,battle_num=get_pk_num()-1},
%% 	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2);
%% 	
do_handle_info({hook_role_enter_wait_map,RoleID})->
	#r_crown_arena_time{next_pk_time=NextPkTime} = get_crown_arena_enter(),
	CurPkNum = get_pk_num(),
	[PkNum] = common_config_dyn:find(crown_arena, pk_num),
	case CurPkNum >= PkNum of
		true ->
			ignore;
		false ->
			R2 = #m_crown_update_time_toc{status=?WAIT_MAP_LEAVE_TIME_TYPE,seconds=NextPkTime-common_tool:now(),battle_num=CurPkNum},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_UPDATE_TIME, R2)
	end,
	%%淘汰赛进入判定倒时
	mod_crown_arena_cull:hook_role_enter_wait_map(RoleID);

do_handle_info(Msg)->
    ?ERROR_MSG("mgeew_crown_arena_server无法识别:~w~n",[Msg]).

do_cmp_score() ->
	RankInfo = get_rank_info(),
	NewRankList = lists:sort(
					fun(RankRecord1,RankRecord2) -> 
							#r_crown_role_rank{score=Score1,level=Level1,fightpower=FightPower1} = RankRecord1,
    						#r_crown_role_rank{score=Score2,level=Level2,fightpower=FightPower2} = RankRecord2,
							cmp([{Score1,Score2},{Level1,Level2},{FightPower1,FightPower2}])
					 end,RankInfo),
	{_,NewRankList2} = lists:foldr(fun(RankRecord,Acc) ->
						{Rank,RankRecords} = Acc,
						{Rank-1,[RankRecord#r_crown_role_rank{rank=Rank}|RankRecords]}
						end, {length(NewRankList),[]}, NewRankList),
	set_already_rank(NewRankList2).
	

do_open_copy_to_pk(Num,PkNum) when Num > PkNum ->
	ignore;
do_open_copy_to_pk(Num,_PkNum) ->
	[AfterPKSeconds1] = common_config_dyn:find(crown_arena, pk_safe_time),
	[AfterPKSeconds2] = common_config_dyn:find(crown_arena, pk_time),
	send_after(AfterPKSeconds1+AfterPKSeconds2,self(),{pk_finish,Num}),
	RoleTwoList = init_pk(Num),
	{_,RoleTwoList2} = init_pk_and_process(RoleTwoList),
	MapId = common_crown_arena:wait_map_id(),
	send_msg_to_map(MapId,mod_crown_arena_fb,{pk,RoleTwoList2}).

do_crown_arena_award({_Unique, _Module, _Method, _DataIn, RoleID, _PID, _Line}=Msg) ->
	try
		draw_award(RoleID,Msg)
	catch
		_ : R ->
			?ERROR_MSG("do_crown_arena_award, r: ~w", [R])
	end.
		
role_online(RoleID) ->
	mod_crown_arena_cull:role_online(RoleID),
	RankInfoList = get_already_rank(),
	CurPkNum = get_pk_num(),
	[PkNum] = common_config_dyn:find(crown_arena, pk_num),
	if 
		CurPkNum >= PkNum ->
			case lists:keyfind(RoleID, #r_crown_role_rank.role_id, RankInfoList) of
				false ->
					ignore;
				#r_crown_role_rank{role_id=RoleID,rank=RankID,level=Level,score=Score,state=State,max_link_win=MaxLinkWin} ->
					case State of
						true ->
							ignore;
						false ->
							[ExpList] = common_config_dyn:find(crown_arena, exp_award),
							[MoneyAwardList] = common_config_dyn:find(crown_arena, money_award),
							{_,Exp} = lists:keyfind(Level, 1, ExpList),
							{_,Money} = lists:keyfind(Level, 1, MoneyAwardList),
							case common_crown_arena:reward_peck_ext(RoleID,Level,MaxLinkWin) of
								[] ->
									Award = [#p_arena_award{type=?AWARE_EXP,value=Exp},
											 #p_arena_award{type=?AWARD_MONEY,value=Money},
											 #p_arena_award{type=?ARARD_GIFT,value=Score}];
								#r_goods_create_info{num=LinkWinNum} ->
									Award = [#p_arena_award{type=?AWARE_EXP,value=Exp},
											 #p_arena_award{type=?AWARD_MONEY,value=Money},
											 #p_arena_award{type=?ARARD_GIFT_EXT,value=LinkWinNum},
											 #p_arena_award{type=?ARARD_GIFT,value=Score}]
							end,
							BattleNum = get_pk_num(),
							R2 = #m_crown_arena_info_toc{type=?ROLE_CROWN_INFO_ONLINE,battle_core=Score,battle_num=BattleNum,
														 battle_win_max=MaxLinkWin,award_state=State,
														 award=Award,rank_id=RankID},
							common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_ARENA_INFO, R2)
					end
			end;
		true ->
			ignore
	end.

do_already_receive(RoleID) ->
	RankInfoList = get_already_rank(),
	case lists:keyfind(RoleID, #r_crown_role_rank.role_id, RankInfoList) of
		false ->
			ignore;
		RankRoleInfo ->
			NewRankRoleInfo = RankRoleInfo#r_crown_role_rank{state=true},
			set_already_rank(lists:keyreplace(RoleID, #r_crown_role_rank.role_id, RankInfoList, NewRankRoleInfo))
	end.

draw_award(RoleID,{Unique, Module, Method, _DataIn, RoleID, PID, _Line} = Msg) ->
	RankInfoList = get_already_rank(),
	case common_tool:now() - common_crown_arena:get_cd_time(RoleID) >= ?AWARD_CD_TIME of
		true ->
			case lists:keyfind(RoleID, #r_crown_role_rank.role_id, RankInfoList) of
				false ->
					R2 = #m_crown_arena_award_toc{},
					?UNICAST_TOC(R2);
				RankRoleInfo ->
					#r_crown_role_rank{state=State} = RankRoleInfo,
					case State of
						true ->
							R2 = #m_crown_arena_award_toc{error_code=?ERR_CROWN_ARENA_YES},
							?UNICAST_TOC(R2);
						false ->
							common_crown_arena:set_cd_time(RoleID,common_tool:now()),
							mgeer_role:send(RankRoleInfo#r_crown_role_rank.role_id, {mod_crown_arena_fb, {crown_award, RankRoleInfo,Msg}})
					end
			end;
		false ->
			ignore
	end.
	
do_crown_arena_info({Unique, Module, Method, DataIn, RoleID, PID, _Line}=_Msg) ->
	#m_crown_arena_info_tos{type=Type} = DataIn,
	RankInfoList = get_already_rank(),
	RankID2 = 
		case lists:keyfind(RoleID, #r_crown_role_rank.role_id, RankInfoList) of
			#r_crown_role_rank{rank=RankID} ->					  
				RankID;
			false ->
				length(RankInfoList)+1
		end,
	ArenaCore= get_arena_score(lists:sublist(RankInfoList, ?RANK_INFO_MAX)),
	BattleNum = get_pk_num(),
	{JoinBattleNum,Score,AwareState,MaxLinkWin,Award} = get_role_award(RoleID,RankInfoList),
	R2 = #m_crown_arena_info_toc{type=Type,join_battle_num=JoinBattleNum,battle_num=BattleNum,battle_core=Score,
								 battle_win_max=MaxLinkWin,award_state=AwareState,
								 award=Award,rank_info=ArenaCore,rank_id=RankID2},
	?UNICAST_TOC(R2).

get_arena_score(RoleCrownInfos) ->
	lists:map(fun(#r_crown_role_rank{role_id=RoleID,role_name=RoleName,score=Score,faction_id=FactionID,level=Level,fightpower=Fightpower}) ->
					  #p_arena_rank_info{role_id=RoleID,faction_id=FactionID,role_name=common_tool:to_list(RoleName),score=Score,level=Level,fight_power=Fightpower}
					  end, RoleCrownInfos).

get_role_award(RoleID,RankInfoList) ->
	case lists:keyfind(RoleID,#r_crown_role_rank.role_id, RankInfoList) of
		false ->
			{0,0,false,0,[]};
		#r_crown_role_rank{level=Level,join_battle_num=JoinBattleNum,score=Score,state=State,max_link_win=MaxLinkWin} ->
			[ExpList] = common_config_dyn:find(crown_arena, exp_award),
			[MoneyAwardList] = common_config_dyn:find(crown_arena, money_award),
			case {lists:keyfind(Level, 1, ExpList),lists:keyfind(Level, 1, MoneyAwardList)} of
				{{_,Exp1},{_,Money1}} -> 
					Exp = common_tool:to_integer(Exp1*(0.5+Score/30)),
					Money = common_tool:to_integer(Money1*(0.5+Score/30)),
					case common_crown_arena:reward_peck_ext(RoleID,Level,MaxLinkWin) of
						[] ->
							{JoinBattleNum,Score,State,MaxLinkWin,[#p_arena_award{type=?AWARE_EXP,value=Exp},
																   #p_arena_award{type=?AWARD_MONEY,value=Money},
																   #p_arena_award{type=?ARARD_GIFT,value=Score}]};
						#r_goods_create_info{num=LinkWinNum} ->
							{JoinBattleNum,Score,State,MaxLinkWin,[#p_arena_award{type=?AWARE_EXP,value=Exp},
																   #p_arena_award{type=?AWARD_MONEY,value=Money},
																   #p_arena_award{type=?ARARD_GIFT_EXT,value=LinkWinNum},
																   #p_arena_award{type=?ARARD_GIFT,value=Score}]}
					end;
				Error ->
					?ERROR_MSG("get_role_award Level==~w,Error==~w",[Level,Error]),
					{0,0,false,0,[]}
			end
	
	end.
		
do_crown_arena_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line}=Msg) ->
	case catch check_crown_arena_enter(RoleID,DataIn) of
        {ok,true}->
			common_misc:send_to_rolemap(RoleID, {mod_crown_arena_fb, Msg});
        {error,ErrCode,Reason}->
            R2 = #m_crown_arena_enter_toc{error_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

check_crown_arena_enter(RoleID,_DataIn) ->
	case check_crown_arena_enter() of
		true ->
			EnterRoles = get_enter_wait_map(),
			case length(EnterRoles) > ?MAX_ENTER_NUM of
				true ->
					case lists:keyfind(RoleID, #r_role_crown_arena.role_id, EnterRoles) of
						false ->
							?THROW_ERR( ?ERR_CROWN_ARENA_MAX_NUM );
						_ ->
							{ok,true}
					end;
				false ->
					{ok,true}
			end;
		false ->
			?THROW_ERR( ?ERR_CROWN_ARENA_NOT_OPEN )
	end.

send_msg_to_map(MapId,ModuleName,Msg) ->
	case global:whereis_name( common_map:get_common_map_name( MapId ) ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,ModuleName,Msg})
    end.

create_map_process(Num) ->
	MapProcessName = common_crown_arena:pk_map_process_name(Num),
	case global:whereis_name(MapProcessName) of
		undefined ->
			mod_map_copy:async_create_copy(common_crown_arena:pk_map_id(),MapProcessName,mgeew_crown_arena_server,Num);
		_MapPID ->
			set_pk_mapprocess(MapProcessName),
			ignore
	end.

init_pk(1) ->
	RoleTupLists = get_enter_roles(),
	NewRankList = lists:sort(
					fun(RankRecord1,RankRecord2) -> 
							#r_role_crown_arena{score=Score1,role_id=RoleID1} = RankRecord1,
    						#r_role_crown_arena{score=Score2,role_id=RoleID2} = RankRecord2,
							cmp([{Score1,Score2},{RoleID1,RoleID2}])
					 end,RoleTupLists),
	calculate_pk_role(1,NewRankList);
init_pk(Num) ->
	RoleTupLists = get_enter_roles(),
	NewRankList = lists:sort(
					fun(RankRecord1,RankRecord2) -> 
							#r_role_crown_arena{score=Score1,role_id=RoleID1} = RankRecord1,
    						#r_role_crown_arena{score=Score2,role_id=RoleID2} = RankRecord2,
							cmp([{Score1,Score2},{RoleID1,RoleID2}])
					 end,RoleTupLists),
	calculate_pk_role(Num,NewRankList).

get_enter_roles() ->
	RoleTupLists = get_enter_wait_map(),
	lists:foldl(fun(RoleTup,Acc) ->
						#r_role_crown_arena{state=State} = RoleTup,
						case State =:= ?ROLE_CROWN_ARENA_QUIT of
							true ->
								Acc;
							false ->
								[RoleTup|Acc]
						end
						end, [], RoleTupLists).

calculate_pk_role(1,RoleTupLists) ->
	calculate_two_pk_role([],RoleTupLists);
calculate_pk_role(_Num,RoleTupLists) ->
	calculate_two_pk_role2([],RoleTupLists).

calculate_two_pk_role(RoleTwo,[]) ->
	RoleTwo;
calculate_two_pk_role(RoleTwo,[RoleTup|[]]) ->
	[{RoleTup,undefined}|RoleTwo];
calculate_two_pk_role(RoleTwo,[RoleTup1,RoleTup2|RoleTupLists]) ->
	calculate_two_pk_role([{RoleTup1,RoleTup2}|RoleTwo],RoleTupLists).
	
calculate_two_pk_role2(RoleTwo,[]) ->
	RoleTwo;
calculate_two_pk_role2(RoleTwo,[RoleTup|[]]) ->
	[{RoleTup,undefined}|RoleTwo];
calculate_two_pk_role2(RoleTwo,[RoleTup1,RoleTup2|RoleTupLists]) ->
	#r_role_crown_arena{score=Score} = RoleTup1,
	case lists:keyfind(Score, #r_role_crown_arena.score, [RoleTup2|RoleTupLists]) of
		false ->
			calculate_two_pk_role2([{RoleTup1,RoleTup2}|RoleTwo],RoleTupLists);
		RoleOtherTup ->
			#r_role_crown_arena{role_id=OtherRole} = RoleOtherTup,
			calculate_two_pk_role2([{RoleTup1,RoleOtherTup}|RoleTwo],lists:keydelete(OtherRole, #r_role_crown_arena.role_id, [RoleTup2|RoleTupLists]))
	end.
	
init_pk_and_process(RoleTwoList) ->
	lists:foldl(fun({RoleTup1,RoleTup2},Acc) ->
						{Num,RoleTups} = Acc,
						ProcessName = common_crown_arena:pk_map_process_name(Num),
						{NewRoleTup1,_RoleList1} = 
						case RoleTup1 =:= undefined of
							true ->
								{RoleTup1,[]};
							false ->
								#r_role_crown_arena{role_id=RoleID1} = RoleTup1,
								{RoleTup1#r_role_crown_arena{pk_map_process=ProcessName},[RoleID1]}						   
						end,
						{NewRoleTup2,_RoleList2} = 
						case RoleTup2 =:= undefined of
							true ->
								{RoleTup2,[]};
							false ->
								#r_role_crown_arena{role_id=RoleID2} = RoleTup2,
								{RoleTup2#r_role_crown_arena{pk_map_process=ProcessName},[RoleID2]}
						end,
						{Num+1,[{NewRoleTup1,NewRoleTup2}|RoleTups]}		
						end, {1,[]}, RoleTwoList).

cmp([]) ->
    true;
cmp([{Element1,Element2}|List]) ->
    case Element1 > Element2 of
        true ->
            true;
        false ->
            case Element1 < Element2 of
                true ->
                    false;
                false ->
                    cmp(List)
            end
    end.

crown_arena_reward() ->
	RankInfoList = get_already_rank(),
	lists:foreach(fun(#r_crown_role_rank{role_id=RoleID,rank=RankID,level=Level,score=Score,state=State,max_link_win=MaxLinkWin}) ->
						  [ExpList] = common_config_dyn:find(crown_arena, exp_award),
						  [MoneyAwardList] = common_config_dyn:find(crown_arena, money_award),
						  {_,Exp1} = lists:keyfind(Level, 1, ExpList),
						  {_,Money1} = lists:keyfind(Level, 1, MoneyAwardList),
						  Exp = common_tool:to_integer(Exp1*(0.5+Score/30)),
							Money = common_tool:to_integer(Money1*(0.5+Score/30)),
						  case common_crown_arena:reward_peck_ext(RoleID,Level,MaxLinkWin) of
							  [] ->
								  Award = [#p_arena_award{type=?AWARE_EXP,value=Exp},
										   #p_arena_award{type=?AWARD_MONEY,value=Money},
										   #p_arena_award{type=?ARARD_GIFT,value=Score}];
							  #r_goods_create_info{num=LinkWinNum} ->
								  Award = [#p_arena_award{type=?AWARE_EXP,value=Exp},
										   #p_arena_award{type=?AWARD_MONEY,value=Money},
										   #p_arena_award{type=?ARARD_GIFT_EXT,value=LinkWinNum},
										   #p_arena_award{type=?ARARD_GIFT,value=Score}]
						  end,
						  
						  BattleNum = get_pk_num(),
						  R2 = #m_crown_arena_info_toc{type=?ROLE_CROWN_INFO_END,battle_num=BattleNum,battle_core=Score,
													   battle_win_max=MaxLinkWin,award_state=State,
													   award=Award,rank_id=RankID},
						  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CROWN, ?CROWN_ARENA_INFO, R2)
				  end, RankInfoList).
 	