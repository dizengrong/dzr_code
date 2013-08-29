%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :ldk
%%%
%%% Created : 2012-4-23
%%% -------------------------------------------------------------------
-module(mgeew_special_activity).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

-define(FLOWERS_ACTIVITY,1).
-define(RMB_ACTIVITY,2).
-define(OPENDAYS(D),{open_days,D}).


%% --------------------------------------------------------------------
%% External exports
-export([start/0,reward_5_6/0,reward_date/0,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

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
	erlang:process_flag(trap_exit, true),
	%%AfterSecs:每天十二点前400秒时间
	%%AfterSecs = 86000 - (calendar:time_to_seconds(erlang:time())),
    Now = common_tool:now(),
    ActivityTime = common_tool:datetime_to_seconds( {common_time:add_days(date(),1),{01,00,00}} ),
    %%活动1：累计充值和累计送花活动
	erlang:send_after((ActivityTime-Now)*1000, self(), activity_1),
	%%活动2：极致精英礼包：
	%%需求：开服日起14天后（满336小时）系统自动以信件附件方式为百强榜上达到声名鹊起及以上境界的排名前100位的玩家发放【极致精英礼包】
	catch init_activity(activity_2),
	%%活动3：	各级家族礼包
	%%需求：开服日起7天后（满168小时），系统自动以信件附件方式为家族排行榜上达到前10名的家族的每个族员发放各级家族礼包
	catch init_activity(activity_3),
	%%活动4：	神兵排行礼包：
	%%需求：开服日起7天后（满168小时）系统自动以信件附件方式为神兵总分榜上排名前10名的玩家发放神兵排行礼包，排名不同所获得的礼包个数也不同
	catch init_activity(activity_4),
    {ok, #state{}}.

reward_5_6() ->
	?ERROR_MSG("reward_5_6",[]),
   Date = common_time:add_days(date(),-1),
    %% Date =date(),
    Key1 = get_db_key(Date,?FLOWERS_ACTIVITY),
    Key2 = get_db_key(Date,?RMB_ACTIVITY),
    {FlowersInfo,RmbInfo} = get_yesterdate_activity_reward2(Date),
    lists:foreach(fun({DbKey,Key,Info}) ->
                          reward_activity_1(DbKey,Key,Info)
                          end, [{Key1,?FLOWERS_ACTIVITY,FlowersInfo},{Key2,?RMB_ACTIVITY,RmbInfo}]).             

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
do_handle_info( {Type,RoleID, FlowersNum})->
	%%单笔冲值奖励
	reward_rmb_one_cost({Type,RoleID, FlowersNum}),
    case check_in_activity(Type) of
        true ->
            Key = get_db_key(date(),Type),
            case db:dirty_read(?DB_SPECIAL_REWARD_P,Key) of
                [] ->
                   db:dirty_write(?DB_SPECIAL_REWARD_P,#r_special_reward{date_type=Key,value=[{RoleID, FlowersNum}]});
                [#r_special_reward{value=Value}] ->
            case lists:keyfind(RoleID, 1,Value) of
                false ->
            		db:dirty_write(?DB_SPECIAL_REWARD_P,#r_special_reward{date_type=Key,value=[{RoleID, FlowersNum}|Value]});
                {_,Num} ->
                    db:dirty_write(?DB_SPECIAL_REWARD_P,#r_special_reward{date_type=Key,value=[{RoleID, Num+FlowersNum}|lists:keydelete(RoleID, 1, Value)]})
            end
            end;
        false ->
            ignore
    end;

do_handle_info(reward_5_6)->
	reward_5_6();
do_handle_info(reward_date)->
	reward_date();

do_handle_info(reward_all)->
	reward_activity_3(),
	reward_activity_4();
%%活动1：累计充值和累计送花活动	
do_handle_info(activity_1)->
     erlang:send_after(86400*1000, self(), activity_1),
   Date = common_time:add_days(date(),-1),
    %% Date =date(),
    Key1 = get_db_key(Date,?FLOWERS_ACTIVITY),
    Key2 = get_db_key(Date,?RMB_ACTIVITY),
    {FlowersInfo,RmbInfo} = get_yesterdate_activity_reward(Date),
    lists:foreach(fun({DbKey,Key,Info}) ->
                          reward_activity_1(DbKey,Key,Info)
                          end, [{Key1,?FLOWERS_ACTIVITY,FlowersInfo},{Key2,?RMB_ACTIVITY,RmbInfo}]);                   

%%活动3：	各级家族礼包
%%需求：开服日起7天后（满168小时），系统自动以信件附件方式为家族排行榜上达到前10名的家族的每个族员发放各级家族礼包
do_handle_info({activity_3,Day})->
	erlang:send_after(86400*1000, self(), {activity_3,Day}),
	OpenDay = common_config:get_opened_days(),
	case OpenDay =:= Day of
		false ->
			ignore;
		true ->
			reward_activity_3()
	end;
%%活动4：	神兵排行礼包：
%%需求：开服日起7天后（满168小时）系统自动以信件附件方式为神兵总分榜上排名前10名的玩家发放神兵排行礼包，排名不同所获得的礼包个数也不同
do_handle_info({activity_4,Day})->
	erlang:send_after(86400*1000, self(), {activity_4,Day}),
	OpenDay = common_config:get_opened_days(),
	case OpenDay =:= Day of
		false ->
			ignore;
		true ->
			reward_activity_4()
	end;

do_handle_info(Msg)->
    ?ERROR_MSG("mgeew_special_activity无法识别:~w~n",[Msg]).

reward_activity_1(DbKey,Key,Info) ->
    case Info =:= [] of
        true ->
            ignore;
        false ->
    case db:dirty_read(?DB_SPECIAL_REWARD_P,DbKey) of
                [] ->
                   ignore;
                [#r_special_reward{value=Value1}] ->
                   RoleList = get_reward_roles(Value1,Info),
                    lists:foreach(fun({RoleID,RewardNum}) ->
								{{_StartDate,_StartTime},{_EndDate,_EndTime},_Num,Rewards} = lists:keyfind(RewardNum, 3, Info),
                                GiftGoods =  get_goods(RoleID,Rewards),
                                 common_letter:sys2p(RoleID,?_LANG_ACTIVITY_LETTER_REWARD_TEXT(Key),?_LANG_ACTIVITY_LETTER_REWARD_TITLE(Key),GiftGoods,14)
                                          end, RoleList)
    end
    end.

reward_activity_3() ->
	FamilyRank = gen_server:call({global, mgeew_ranking}, {ranking_family_active}, 30000),
	FamilyRank2 = lists:sublist(FamilyRank, 10),
	reward_family_1(FamilyRank2),
	reward_family_2to5(FamilyRank2),
	reward_family_6to10(FamilyRank2).

reward_activity_4() ->
	EquipRank = gen_server:call({global, mgeew_ranking}, {ranking_equip_refining}, 30000),
	EquipRank2 = lists:sublist(EquipRank, 10),
	reward_equip_1(EquipRank2),
	reward_equip_2to5(EquipRank2),
	reward_equip_6to10(EquipRank2).

reward_equip_1(EquipRank2) when length(EquipRank2) >= 1 ->
	common_reward_equip(lists:sublist(EquipRank2, 1),[{11400113,true,5}]);
reward_equip_1(_EquipRank2) ->
	ignore.
reward_equip_2to5(EquipRank2) when length(EquipRank2) >= 2 ->
	common_reward_equip(lists:sublist(EquipRank2, 2,5),[{11400113,true,3}]);
reward_equip_2to5(_EquipRank2) ->
	ignore.
reward_equip_6to10(EquipRank2) when length(EquipRank2) >= 6 ->
	common_reward_equip(lists:sublist(EquipRank2, 6,10),[{11400113,true,1}]);
reward_equip_6to10(_EquipRank2) ->
	ignore.


reward_family_1(FamilyRank2) when length(FamilyRank2) >= 1 ->
	common_reward_family(lists:sublist(FamilyRank2, 1),[{11400109,true,1}]);
reward_family_1(_FamilyRank2) ->
	ignore.
reward_family_2to5(FamilyRank2) when length(FamilyRank2) >= 2 ->
	common_reward_family(lists:sublist(FamilyRank2, 2,5),[{11400110,true,1}]);
reward_family_2to5(_FamilyRank2) ->
	ignore.
reward_family_6to10(FamilyRank2) when length(FamilyRank2) >= 6 ->
	common_reward_family(lists:sublist(FamilyRank2, 6,10),[{11400111,true,1}]);
reward_family_6to10(_FamilyRank2) ->
	ignore.

common_reward_family(FamilyRank2,Reward) ->
	lists:foldl(fun(#p_family_active_rank{family_id=FamilyID},_Acc) ->
						 [#p_family_info{family_name=_Family_name,members=Members}] = db:dirty_read(?DB_FAMILY, FamilyID),
						 lists:foreach(fun(#p_family_member_info{role_id=RoleID}) ->
                                GiftGoods =  get_goods(RoleID,Reward),
								%%Text = common_misc:format_lang(?_LANG_SPECIAL_ACTIVITY3,[common_tool:to_list(Family_name)]),
                                 %%?ERROR_MSG("7777777Text==~w",[Text])
								common_letter:sys2p(RoleID,?_LANG_SPECIAL_ACTIVITY3,"活动奖励",GiftGoods,14)
                                          end, Members)
						end, [], FamilyRank2).

common_reward_equip(EquipRank2,[{_,_,Num}]=Reward) ->
	lists:foreach(fun(#p_equip_rank{role_id=RoleID}) ->
                                GiftGoods =  get_goods(RoleID,Reward),
								Text = common_misc:format_lang(?_LANG_SPECIAL_ACTIVITY4,[Num]),
                                 common_letter:sys2p(RoleID,Text,"活动奖励",GiftGoods,14)
                                          end, EquipRank2).

get_goods(RoleID,Rewards) ->
    lists:map(fun({TypeID,Bind,Num}) ->
                    CreateItem = #r_item_create_info{role_id=RoleID,num=Num,typeid=TypeID,bind=Bind,bag_id=1,bagposition=1},
    				 {ok,[GiftGoods]} = common_bag2:create_item(CreateItem),
    				 GiftGoods#p_goods{id=1}    
                      end, Rewards).

get_reward_roles(Value1,Info) ->
		Nums = 
		lists:map(fun(X) ->
							{{_StartDate,_StartTime},{_EndDate,_EndTime},Num,_Rewards} = X,
							Num
						end, Info),
    lists:foldr(fun({RoleID,Value},Acc) ->
												SortNum = lists:sort([Value|Nums]),
												ReverseNum = lists:reverse(SortNum),
												{_,Lists2} = lists:splitwith(fun(A) -> A =/=Value end, ReverseNum),
												case length(Lists2) =< 1 of 
														true ->
																Acc;
														false ->
																[_N1,N2|_] = Lists2,
																[{RoleID,N2}|Acc]
                        end
                        end, [], Value1).

get_yesterdate_activity_reward(Date) ->
   {ok,Flowers_gift} = common_activity:get_config(flowers_gift,activity_gift_by_letter),
   {ok,Rmb_gift} = common_activity:get_config(rmb_gift,activity_gift_by_letter),
   NewFlowersInfo = 
    lists:foldr(fun(Activity,Acc) ->
                         {{StartDate,_StartTime},{EndDate,_EndTime},_Num,_Rewards} = Activity,
                        case Date >= StartDate andalso Date =< EndDate of
                            true ->
                                [Activity|Acc];
							false ->
								Acc
                         end
                        end, [], Flowers_gift),
    NewRmbInfo = 
    lists:foldr(fun(Activity,Acc) ->
                         {{StartDate,_StartTime},{EndDate,_EndTime},_Num,_Rewards} = Activity,
                        case Date >= StartDate andalso Date =< EndDate of
                            true ->
                                [Activity|Acc];
							false ->
								Acc
                         end
                        end, [], Rmb_gift),
   {NewFlowersInfo,NewRmbInfo}.
get_yesterdate_activity_reward2(Date) ->
   {ok,Flowers_gift} = common_activity:get_config(flowers_gift,activity_gift_by_letter),
   {ok,Rmb_gift} = common_activity:get_config(rmb_gift,activity_gift_by_letter),
   NewFlowersInfo = 
    lists:foldr(fun(Activity,Acc) ->
                         {{StartDate,_StartTime},{_EndDate,_EndTime},_Num,_Rewards} = Activity,
                        case Date >= StartDate of
                            true ->
                                [Activity|Acc];
							false ->
								Acc
                         end
                        end, [], Flowers_gift),
    NewRmbInfo = 
    lists:foldr(fun(Activity,Acc) ->
                         {{StartDate,_StartTime},{_EndDate,_EndTime},_Num,_Rewards} = Activity,
                        case Date >= StartDate of
                            true ->
                                [Activity|Acc];
							false ->
								Acc
                         end
                        end, [], Rmb_gift),
   {NewFlowersInfo,NewRmbInfo}.
   
check_in_activity(Type) ->
    {ok,ActivityList} =
    case Type of
        ?FLOWERS_ACTIVITY ->
    		common_activity:get_config(flowers_gift,activity_gift_by_letter);
        ?RMB_ACTIVITY ->
            common_activity:get_config(rmb_gift,activity_gift_by_letter);
       _->
            {ok,[]}
    end,
    SecondTime = common_tool:datetime_to_seconds({date(),time()}),
	 lists:foldr(fun(Acticity,Acc) ->
                         if 
                             Acc =:= true ->
                                 true;
                             true ->
                        {{StartDate,StartTime},{EndDate,EndTime},_Num,_Rewards} = Acticity,
                        SecondTime1 = common_tool:datetime_to_seconds({get_date(StartDate),StartTime}),
                        SecondTime2 = common_tool:datetime_to_seconds({get_date(EndDate),EndTime}),
                        case SecondTime >= SecondTime1 andalso SecondTime =< SecondTime2 of
                            true ->
                                true;
                            false ->
                                Acc
                        end
                         end
                        end, false, ActivityList).
 

get_date(Date) ->
	case Date of
		{open_days,D} ->
			{OpenDate, _} = common_config:get_open_day(),
    		common_time:add_days(OpenDate,D);
		_ ->
			Date
	end.

get_db_key({Y,M,D},Type) ->
    lists:concat([common_tool:to_list(Y),"-",common_tool:to_list(M),"-",common_tool:to_list(D),"-",common_tool:to_list(Type)]).

init_activity(Activity) ->
	{ok,ActivityTime} = common_activity:get_config(Activity,activity_gift_by_letter),
	[{Day,_Time}] = ActivityTime,
	 {open_days,D} = Day,
	case get_after_second(ActivityTime) of
		ignore ->
			ignore;
		Second ->
			erlang:send_after(Second*1000, self(), {Activity,D})
	end.
get_after_second([{Day,Time}]) ->
	SecondTime = common_tool:datetime_to_seconds({date(),time()}),
	{OpenDate, _} = common_config:get_open_day(),
	{open_days,D} = Day,
	AwardSecondTime = common_tool:datetime_to_seconds({common_time:add_days(OpenDate,D-1),Time}),
	case AwardSecondTime >= SecondTime of
		true ->
			AwardSecondTime - SecondTime;
		false ->
			OpenDay = common_config:get_opened_days(),
			case OpenDay < Day of
				false ->
					ignore;
				true ->
					SecondTime2 = common_tool:datetime_to_seconds(common_time:add_days(date(),1),Time),
					SecondTime2 - SecondTime
			end
	end;
get_after_second(_) ->
	ignore.
	
reward_rmb_one_cost({Type,RoleID, Cost}) when Type =:= ?RMB_ACTIVITY -> 
	Item = get_reward_item(Cost),
	if 
		Item =:= 0 ->
			ignore;
		true ->
			{_,_,Num} = Item,
			GiftGoods =  get_goods(RoleID,[Item]),
			Text = common_misc:format_lang(?_LANG_SPECIAL_ACTIVITY_COST,[Num]),
            common_letter:sys2p(RoleID,Text,"单次充值奖励",GiftGoods,14)
	end;
reward_rmb_one_cost(_) ->
	ignore.

get_reward_item(Cost) ->
	{ok,RmbCostOne} = common_activity:get_config(rmb_cost_one,activity_gift_by_letter),
	catch lists:foldl(fun(RmbCost,Acc) ->
						{{StartDate,StartTime},{EndDate,EndTime},Min,Max,Item} = RmbCost,
						SecondTime = common_tool:datetime_to_seconds({date(),time()}),
						SecondTime1 = common_tool:datetime_to_seconds({get_date(StartDate),StartTime}),
                        SecondTime2 = common_tool:datetime_to_seconds({get_date(EndDate),EndTime}),
						case Cost >= Min andalso Cost < Max andalso SecondTime >= SecondTime1 andalso SecondTime =< SecondTime2 of
							true ->
								throw(Item);
							false ->
								Acc
						end
						end, 0, RmbCostOne).

reward_date() ->
	Key = ?RMB_ACTIVITY,
	reward_date2(Key) .
reward_date2(Key) ->
	MatchHead = #r_pay_log{
							  year='$1',
							  month='$2',
							  day='$3',
							  _='_'},
	Guard = [{'=:=','$1',2012},{'=:=','$2',5},{'=:=','$3',30}],
	Value1 = 
		case db:dirty_select(db_pay_log_p,[{MatchHead,Guard,['$_']}]) of
			[] ->
				[];
			Data ->
				lists:foldl(fun(#r_pay_log{role_id=RoleID,pay_gold=PayGold},Acc) ->
									case lists:keyfind(RoleID, 1, Acc) of
										false ->
											[{RoleID,PayGold}|Acc];
										{_,Gold} ->
											[{RoleID,Gold+PayGold}|lists:keydelete(RoleID, 1, Acc)]
									end
							end, [], Data)
		end,
	Date = common_time:add_days(date(),-1),
	{_FlowersInfo,RmbInfo} = get_yesterdate_activity_reward2(Date),
	RoleList = get_reward_roles(Value1,RmbInfo),
	lists:foreach(fun({RoleID,RewardNum}) ->
						  {{_StartDate,_StartTime},{_EndDate,_EndTime},_Num,Rewards} = lists:keyfind(RewardNum, 3, RmbInfo),
						  GiftGoods =  get_goods(RoleID,Rewards),
						  common_letter:sys2p(RoleID,?_LANG_ACTIVITY_LETTER_REWARD_TEXT(Key),?_LANG_ACTIVITY_LETTER_REWARD_TITLE(Key),GiftGoods,14)
				  end, RoleList).




