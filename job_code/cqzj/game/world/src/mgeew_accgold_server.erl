%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录玩家的累计元宝消费
%%% @end
%%% Created : 2011-4-22
%%%-------------------------------------------------------------------
-module(mgeew_accgold_server).
-behaviour(gen_server).


-export([start/0,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([get_activity_accgold_rewards/1]).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").



%% ====================================================================
%% Macro
%% ====================================================================
-define(accgold_logs,accgold_logs).
-define(update_consume_gold,update_consume_gold).
-define(consume_mission_accgold_logs,consume_mission_accgold_logs).

-define(do_minute_check,do_minute_check).
-define(LAST_STAT_REWARD_DATE,last_stat_reward_date).
-define(CONSUME_REM_GOLD,consume_rem_gold).



%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, brutal_kill, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    send_minute_check(),    
    {ok, []}.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(Call, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Call, State),
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

do_handle_call({get_consume_rem_gold, RoleID}) ->
    erlang:get({?CONSUME_REM_GOLD,RoleID});
do_handle_call(_) ->
    error.


%%累计元宝消费的记录
do_handle_info({?accgold_logs,AccGoldList})->
    do_accgold_logs(AccGoldList);
do_handle_info({?consume_mission_accgold_logs,AccConsumeMissionGoldList})->
    do_consume_mission_accgold_logs(AccConsumeMissionGoldList);
do_handle_info({?update_consume_gold,ExchangeLostList,OtherGoldList})->
    update_consume_gold_tag(ExchangeLostList,OtherGoldList);


do_handle_info({gm_stat_rewards})->
   do_stat_rewards();

do_handle_info({get_consume_jifen,Msg})->
   do_send_consume_jifen(Msg);
do_handle_info({?do_minute_check})->
    send_minute_check(),
    case calendar:local_time() of
		{_Date,{0,0,_}} ->
			reset_today_consume();
        {_Date,{1,0,_}} -> %%凌晨1点进行统计计算
            do_stat_rewards();
        _R ->
            ignore
    end;

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

reset_today_consume() ->
	AllRoleGoldList1 = db:dirty_match_object(?DB_ROLE_ACCGOLD, #r_role_accgold{_='_' }),
	lists:foreach(fun(#r_role_accgold{role_id=RoleID}) -> 
						  erlang:put({today_consume,RoleID},0)
				  end, AllRoleGoldList1).
%%每天凌晨执行统计奖励
send_minute_check()->
    erlang:send_after(60 * 1000, erlang:self(), {?do_minute_check}).

%% 返回玩家今日积分
do_send_consume_jifen({_Unique, _Module, _Method, _DataIn,RoleID, _PID}) ->
	TodayUseGold = erlang:get({today_consume,RoleID}),
	case TodayUseGold of
		undefined ->
			ignore;
		_ ->
			NewScore = ranking_consume_today:calc_total_score(TodayUseGold),
			DataRecord = #m_role2_consume_jifen_change_toc{new_jifen = NewScore},
			common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_CONSUME_JIFEN_CHANGE, DataRecord)
			%%common_misc:unicast2(PID, Unique, Module, Method, DataRecord)
	end.
%%@doc 进行统计奖励
%% do_stat_rewards()->
%%     YestodayTime = common_tool:now()-3600*24,
%%     case get_activity_accgold_rewards(YestodayTime) of
%%         {ok,RewardConfList}->
%%             %%所有的元宝累计消费数据
%%             AllRoleGoldList1 = db:dirty_match_object(?DB_ROLE_ACCGOLD, #r_role_accgold{_='_' }),
%%             YestodayDate = common_time:time_to_date( YestodayTime ),
%%             %%昨日的元宝累计消费数据
%%             {ok,YestodayRoleGoldList,UpdateRoleRecList} = get_yestoday_role_gold_list(AllRoleGoldList1,YestodayDate),
%%             case get_reward_role_list(YestodayRoleGoldList,RewardConfList,[]) of
%%                 {ok,RewardRoleList} when length(RewardRoleList)>0->
%%                     %%将记录写到mysql中
%%                     save_to_mysql(RewardRoleList,YestodayDate);
%%                 _R ->
%%                     ignore
%%             end,
%%             Now = common_tool:now(),
%%             clear_old_gold_rec(AllRoleGoldList1,UpdateRoleRecList,Now);
%%         _ ->
%%             ignore
%%     end,
%%     
%%     %%标记最后一次执行奖励方法的日期
%%     put(?LAST_STAT_REWARD_DATE,erlang:date()),
%%     ok.
-define(type_can_reward_status,1).
-define(type_pay,21).
do_stat_rewards() ->
	AllRoleGoldList1 = db:dirty_match_object(?DB_ROLE_ACCGOLD, #r_role_accgold{_='_' }),
	lists:foreach(fun(#r_role_accgold{role_id=RoleID})->
						  case cfg_open_activity:get_max_subid(?type_pay) of
							  MaxSubId when erlang:is_integer(MaxSubId) ->
								  Fun = fun(SubId) ->
												case catch mod_open_activity:get_role_open_info(RoleID,?type_pay,SubId) of
													{ok,PactivityInfo} ->
														case PactivityInfo#p_open_activity_info.status of
															?type_can_reward_status ->
																{_,RewardsList} = cfg_open_activity:get_activity_reward(?type_pay,SubId),
																send_reward_by_letter_list(RoleID,RewardsList),
																mod_open_activity:set_role_open_activity_status(RoleID, ?type_pay, SubId, 0);
															_ ->
																ignore
														end;
													_ ->
														ignore
												end
										end,
								 lists:foreach( Fun, lists:reverse(lists:seq(1, MaxSubId))),
								  mod_open_activity:notify_activity_change(RoleID);
							  _ ->
								  ignore
						  end
				  
				  end, AllRoleGoldList1).

send_reward_by_letter_list(RoleID,RewardsList) ->
	lists:foreach(fun({PropID,PropNum,PropType,IsBind})->
						  RewardProp =#p_reward_prop{prop_id=PropID,prop_type=PropType,prop_num=PropNum,bind=IsBind},
						  send_reward_by_letter(RoleID,RewardProp)
				  end, RewardsList).




%%超过两天以上的消费记录可以删除
%% clear_old_gold_rec([],_,_)->
%%     ignore;
%% clear_old_gold_rec([H|T],UpdateRoleRecList,Now)->
%%     #r_role_accgold{role_id=RoleID,consume_mission_gold=ConsumeMissionGold,last_consume_time=LastConsumeTime} = H,
%%     if
%%         Now>LastConsumeTime*3600*48->
%% 			%%存在消费任务非礼券记录则不删除记录
%% 			case ConsumeMissionGold > 0 of
%% 				true ->
%% 					ignore;
%% 				false ->
%% 					db:dirty_delete(?DB_ROLE_ACCGOLD, RoleID)
%% 			end;
%%         true->
%%             case lists:keyfind(RoleID, #r_role_accgold.role_id, UpdateRoleRecList) of
%%                 false->
%%                     next;
%%                 UpdateRec->
%%                     db:dirty_write(?DB_ROLE_ACCGOLD, UpdateRec)
%%             end
%%     end,
%%     clear_old_gold_rec(T,UpdateRoleRecList,Now).

%%获取可以奖励的玩家列表，并执行奖励
%% get_reward_role_list([],_,AccList)->
%%     {ok,AccList};
%% get_reward_role_list([H|T],RewardConfList,AccList)->
%%     {RoleID,UseGold} = H,
%%     case get_reward_role_list_2(RoleID,UseGold,RewardConfList) of
%%         {ok,RewardProps}->
%%             [ ?TRY_CATCH(send_reward_by_letter(RoleID,RewardProp)) ||RewardProp<-RewardProps ],
%%             get_reward_role_list(T,RewardConfList,[H|AccList]);
%%         _ ->
%%             get_reward_role_list(T,RewardConfList,AccList)
%%     end.
%% 
%% get_reward_role_list_2(_RoleID,_UseGold,[])->
%%     ignore; 
%% get_reward_role_list_2(RoleID,UseGold,[H|T])->
%%     {MinGold,MaxGold,RewardProps} = H,
%%     case UseGold>=MinGold andalso MaxGold>=UseGold of
%%         true->
%%             {ok,RewardProps};
%%         _ -> 
%%             get_reward_role_list_2(RoleID,UseGold,T)
%%     end.

send_reward_by_letter(RoleID,RewardProp)->
    #p_reward_prop{prop_id=PropID,prop_type=PropType,prop_num=PropNum,bind=IsBind,color=Color} = RewardProp,
    GoodsCreateInfo = #r_goods_create_info{
                                           bag_id=1, 
                                           position=1,
                                           bind=IsBind,
                                           type=PropType, 
                                           type_id= PropID, 
                                           start_time=0, 
                                           end_time=0,
                                           color=Color,
                                           num= PropNum},
    case mod_bag:create_p_goods(RoleID,GoodsCreateInfo) of
        {ok,GoodsList} ->
            GoodsList2 = [R#p_goods{id = 1} || R <- GoodsList],
            send_reward_by_letter_2(RoleID,GoodsList2);
        {error,Reason}->
            ?ERROR_MSG("send_reward_by_letter,Reason=~w,RoleID=~w,RewardProp=~w",[Reason,RoleID,RewardProp])
    end.

send_reward_by_letter_2(RoleID,[Goods|_T])->
    Title = ?_LANG_ACCGOLD_LETTER_TITLE,
    Text = common_letter:create_temp(?ACCGOLD_REWARD_LETTER,[]),
    common_letter:sys2p(RoleID,Text,Title,[Goods],14),
    ok.

get_activity_accgold_rewards(YestodayTime)->
    ActList = common_config_dyn:list(activity_accgold),
    get_activity_accgold_rewards_2(ActList,YestodayTime).

get_activity_accgold_rewards_2([],_)->
    false;
get_activity_accgold_rewards_2([H|T],YestodayTime)->
    #r_activity_accgold{start_time={StartDate,_},end_time={EndDate,_},reward_list=RewardList} = H,
    
    StartTimeStamp = common_tool:datetime_to_seconds({StartDate,{0,0,0}}),
    EndTimeStamp = common_tool:datetime_to_seconds({EndDate,{23,59,59}}),
    
    if
        YestodayTime>=StartTimeStamp andalso EndTimeStamp>=YestodayTime ->
            {ok,RewardList};
        true->
            get_activity_accgold_rewards_2(T,YestodayTime)
    end.

%% get_yestoday_role_gold_list(RoleGoldList1,YestodayDate)->
%%     get_yestoday_role_gold_list_2(RoleGoldList1,YestodayDate,[],[]).
%% 
%% get_yestoday_role_gold_list_2([],_,AccInRoleGold,AccInRoleRec)->
%%     {ok,AccInRoleGold,AccInRoleRec};
%% get_yestoday_role_gold_list_2([H|T],TheDate,AccInRoleGold,AccInRoleRec)->
%%     #r_role_accgold{role_id=RoleID,consume_list=ConsumeList1} = H,
%%     case lists:keyfind(TheDate, 1, ConsumeList1) of
%%         false->
%%             get_yestoday_role_gold_list_2(T,TheDate,AccInRoleGold,AccInRoleRec);
%%         {TheDate,UseGold}->
%%             ConsumeList2 = lists:keydelete(TheDate, 1, ConsumeList1),
%%             AccInRoleGold2 = [{RoleID,UseGold}|AccInRoleGold],
%%             AccInRoleRec2 = [H#r_role_accgold{consume_list=ConsumeList2}|AccInRoleRec],
%%             get_yestoday_role_gold_list_2(T,TheDate,AccInRoleGold2,AccInRoleRec2)
%%     end.


%%@doc 更新玩家交易元宝的标记
update_consume_gold_tag(ExchangeLostList,ClearTagList)->
    [ erlang:put({?CONSUME_REM_GOLD,RoleID},{RoleID,RemGold}) ||{RoleID,RemGold}<-ExchangeLostList ],
    [ erlang:erase({?CONSUME_REM_GOLD,RoleID2}) ||RoleID2<-ClearTagList],
    ok.

%%@doc 更新玩家今日的累计元宝消费
do_accgold_logs(AccGoldList)->
	do_accgold_day_logs(AccGoldList),
    RoleUseGoldList = 
        lists:foldl(
          fun({RoleID,UseGold},AccIn)-> 
                  case lists:keyfind(RoleID, 1, AccIn) of
                      false->
                          [{RoleID,UseGold}|AccIn];
                      {RoleID,OldGold}->
                          NewGold = OldGold+UseGold,
                          lists:keystore(RoleID, 1, AccIn, {RoleID,NewGold})
                  end 
          end, [], AccGoldList),
    Today = erlang:date(),
    Now = common_tool:now(),
    [ ?TRY_CATCH( do_role_accgold(RoleUseGold,Today,Now) ) ||RoleUseGold<-RoleUseGoldList ],
    ok.

do_role_accgold({RoleID,UseGold},Today,Now)->
	case db:dirty_read(?DB_ROLE_ACCGOLD, RoleID) of
		[]->
			mod_open_activity:hook_day_accgold_event(RoleID,UseGold),
			mod_open_activity:hook_accgold_event(RoleID,UseGold),
			R2 = #r_role_accgold{role_id=RoleID,consume_list=[{Today,UseGold}],last_consume_time=Now};
		[#r_role_accgold{consume_list=ConsumeListOld}=R1]->
			
			case lists:keyfind(Today, 1, ConsumeListOld) of
				false->
					mod_open_activity:hook_day_accgold_event(RoleID,UseGold),
					ConsumeList2 = [{Today,UseGold}|ConsumeListOld];
				{Today,OldGold} ->
					mod_open_activity:hook_day_accgold_event(RoleID,OldGold+UseGold),
					ConsumeList2 = lists:keystore(Today, 1, ConsumeListOld, {Today,(OldGold+UseGold)})
			end, 
			UseGoldSum = get_use_gold_sum(ConsumeList2),
			mod_open_activity:hook_accgold_event(RoleID,UseGoldSum),
			R2 = R1#r_role_accgold{consume_list=ConsumeList2,last_consume_time=Now}
	end,
	db:dirty_write(?DB_ROLE_ACCGOLD, R2),
	ok.

get_use_gold_sum(ConsumeList2) ->
	lists:foldl(fun({_,Sum},AccIn) -> AccIn+Sum end, 0, ConsumeList2).
	
-define(MISSION_LISTENER_TYPE_CONSUME_UNBIND_GOLD,23). %% 累计消耗多少非礼券
do_consume_mission_accgold_logs(AccConsumeMissionGoldList) ->
	RoleUseGoldList = 
		lists:foldl(
		  fun({RoleID,UseGold,ListenerValue},AccIn)-> 
				  case lists:keyfind(RoleID, 1, AccIn) of
					  false->
						  [{RoleID,UseGold,ListenerValue}|AccIn];
					  {RoleID,OldGold,ListenerValue}->
						  NewGold = OldGold+UseGold,
						  lists:keystore(RoleID, 1, AccIn, {RoleID,NewGold,ListenerValue})
				  end 
		  end, [], AccConsumeMissionGoldList),
	[ ?TRY_CATCH( do_role_consume_mission_accgold(RoleUseGold) ) ||RoleUseGold<-RoleUseGoldList ],
	ok.

do_role_consume_mission_accgold({RoleID,UseGold,ListenerValue})->
	case db:dirty_read(?DB_ROLE_ACCGOLD, RoleID) of
		[]->
			R2 = #r_role_accgold{role_id=RoleID,consume_mission_gold=UseGold};
		[#r_role_accgold{consume_mission_gold=OldConsumeMissionGold}=R1]->
			R2 = R1#r_role_accgold{consume_mission_gold=OldConsumeMissionGold+UseGold}
	end,
	db:dirty_write(?DB_ROLE_ACCGOLD, R2),
	case R2#r_role_accgold.consume_mission_gold >= ListenerValue of
		true ->
			Msg={mod_mission_handler,{listener_dispatch,special_listener_value_up,RoleID,?MISSION_LISTENER_TYPE_CONSUME_UNBIND_GOLD,R2#r_role_accgold.consume_mission_gold}},
			mgeer_role:absend(RoleID,Msg);
		false ->
			ignore
	end,
	ok.


%%@doc 更新玩家今日的累计元宝消费
do_accgold_day_logs(AccGoldList)->
	RoleUseGoldList = accgold_logs(AccGoldList),
	Today = erlang:date(),
	Now = common_tool:now(),
	[ ?TRY_CATCH( do_role_day_accgold(RoleUseGold,Today,Now) ) ||RoleUseGold<-RoleUseGoldList ],
	ok.

accgold_logs(AccGoldList) ->
	lists:foldl(
	  fun({RoleID,UseGold},AccIn)-> 
			  case lists:keyfind(RoleID, 1, AccIn) of
				  false->
					  [{RoleID,UseGold}|AccIn];
				  {RoleID,OldGold}->
					  NewGold = OldGold+UseGold,
					  lists:keystore(RoleID, 1, AccIn, {RoleID,NewGold})
			  end 
	  end, [], AccGoldList).

do_role_day_accgold({RoleID,UseGold},Today,Now)->
	case db:dirty_read(?DB_ROLE_ACCGOLD, RoleID) of
		[]->
			erlang:put({today_consume,RoleID},UseGold),
			consume_rank({RoleID,UseGold},Now);
		[#r_role_accgold{consume_list=ConsumeListOld}]->
			case lists:keyfind(Today, 1, ConsumeListOld) of
				false->
					erlang:put({today_consume,RoleID},UseGold),
					consume_rank({RoleID,UseGold},Now);
				{Today,OldGold} ->
					NewGold = OldGold + UseGold,
					erlang:put({today_consume,RoleID},NewGold),
					consume_rank({RoleID,NewGold},Now)
			end
	end.
consume_rank({RoleId,UseGold},Now)->
	NewScore = ranking_consume_today:calc_total_score(UseGold),
	notify_role_consume_jifen_change(RoleId,NewScore),
	LimitScore = cfg_rank_score:socre_limit(?CONSUME_TODAY_RANK_ID),
	case NewScore >= LimitScore of
		true ->
			common_rank:update_element(ranking_consume_today, {RoleId,NewScore,Now});
		_ ->
			ignore
	end.

notify_role_consume_jifen_change(RoleId,NewScore) ->
	Record = #m_role2_consume_jifen_change_toc{new_jifen = NewScore},
	common_misc:unicast({role, RoleId}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_CONSUME_JIFEN_CHANGE, Record).

%% --------------------------------------------------------------------
%%% 内部二级函数
%% --------------------------------------------------------------------
%% save_to_mysql(RewardRoleList,YestodayDate) when is_list(RewardRoleList)->
%%     try
%%         {Year,Month,Date} = YestodayDate,
%%         ConsumeDate = Year*10000 + Month*100 + Date,
%%         RewardTime = common_tool:now(),
%%         QueuesInsert = [ [RoleID,UseGold,ConsumeDate,RewardTime]||{RoleID,UseGold}<-RewardRoleList ],
%%         %%批量插入
%%         FieldNames = [ role_id, use_gold, consume_date, reward_time ],
%%         
%%         mod_mysql:batch_insert(t_log_role_accgold,FieldNames,QueuesInsert,3000)
%%     catch
%%         _:Reason->
%%             ?ERROR_MSG("持久化元宝累计消费奖励出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
%%     end.
%% 

