%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     排行榜奖励
%%% @end
%%%-------------------------------------------------------------------
-module(mod_rankreward_server).
-behaviour(gen_server).


-export([
         start/0,
         start_link/0,
         get_reward_silver/3,
		 send_reward_letter/2,
		 get_reward_prop/3,
		 send_consume_reward_letter/2
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).



%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

-define(DICT_RANKREWARD_LIST, dict_rankreward_list).
-define(SNAPSHOT(Module), {snap_shot,Module}).
-define(FETCH_RANKREWARD_SILVER, fetch_rankreward_silver).
-define(RANKREWARD_FETCHING_TAG,rankreward_fetching_tag).

-define(ERR_RANKREWARD_NO_DATA, 1001).      %%尚没有排行数据
-define(ERR_RANKREWARD_ROLE_NOT_IN_RANK, 1002). %%玩家没有在排行榜中
-define(ERR_RANKREWARD_ROLE_HAS_FETCHED, 1003). %%奖励已经领取
-define(ERR_RANKREWARD_ROLE_IS_FETCHING, 1004). %%正在领取奖励
-define(ERR_RANKREWARD_ADD_MONEY_FAIL, 1101).   %%增加钱币失败




%% ====================================================================
%% API functions
%% ====================================================================



%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, 30000, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, []}.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
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

do_handle_info({snapshot,Module,DataList}) ->
    erlang:put(?SNAPSHOT(Module), DataList),
    ok;
do_handle_info({notice_rankreward,RoleID}) ->
    do_notice_rankreward(RoleID);
do_handle_info({?ADD_ROLE_MONEY_SUCC, RoleID, _RoleAttr, {?FETCH_RANKREWARD_SILVER,RankId,RewardSilver}}) ->
    Now =common_tool:now(),
    case db:dirty_read(?DB_ROLE_RANKREWARD_P, RoleID) of
        [#r_role_rankreward{role_id=RoleID,fetch_list=FetchList}]->
            next;
        _ ->
            FetchList = []
    end,
    
    FetchList2 = lists:keystore(RankId, 1, FetchList, {RankId,Now,RewardSilver}),
    R2db = #r_role_rankreward{role_id=RoleID,fetch_list=FetchList2},
    db:dirty_write(?DB_ROLE_RANKREWARD_P,R2db),
    
    write_rankreward_log(RoleID,RankId,RewardSilver),
    clear_fetch_tag(RoleID,RankId),
    
    R2 = #m_rankreward_fetch_reward_toc{rank_id=RankId,reward_silver=RewardSilver},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?RANKREWARD, ?RANKREWARD_FETCH_REWARD, R2),
    ok;
do_handle_info({?ADD_ROLE_MONEY_FAILED, RoleID, Reason, {?FETCH_RANKREWARD_SILVER,RankId,_RewardSilver}}) ->
    ?ERROR_MSG("Reason=~w",[Reason]),
    clear_fetch_tag(RoleID,RankId),
    
    R2 = #m_rankreward_fetch_reward_toc{rank_id=RankId,error_code=?ERR_RANKREWARD_ADD_MONEY_FAIL},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?RANKREWARD, ?RANKREWARD_FETCH_REWARD, R2),
    ok;


do_handle_info({_Unique, ?RANKREWARD, _Method, _DataIn, _RoleID, _Pid, _Line}=Info) ->
    do_handle_method(Info);
do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

do_handle_method({_, ?RANKREWARD, ?RANKREWARD_FETCH_REWARD, _, _RoleID, _Pid, _Line}=Info) ->
    do_rankreward_fetch(Info);
do_handle_method(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

get_rankreward_list(RankId)->
    case common_config_dyn:find(rank_info, RankId) of
        [[_,ModuleName]]->
            get(?SNAPSHOT( ModuleName ));
        _ ->
            undefined
    end.

%%@interface 通知领取排行榜奖励
do_notice_rankreward(RoleID)->
    [RewardRankList] = common_config_dyn:find(rankreward, reward_rank_list),
    %%支持多个排行榜的数据领取
    [ do_notice_rankreward_2(RoleID,RankId,IsShowData) ||{RankId,IsShowData}<-RewardRankList].

do_notice_rankreward_2(RoleID,RankId,IsShowData)->
    case catch check_rankreward_info(RoleID,RankId) of
        {ok,LastHeroRank}->
            CanFetch = not has_fetch_reward_today(RoleID,RankId),
            case CanFetch of
                true->
                    case IsShowData of
                        true->
                            RewardSilver = get_reward_silver(LastHeroRank),
                            
                            R2 = #m_rankreward_info_toc{rank_id=RankId,show_data=IsShowData,can_fetch=CanFetch,last_rank=LastHeroRank,
                                                        reward_silver=RewardSilver};
                        _ ->
                            R2 = #m_rankreward_info_toc{rank_id=RankId,show_data=IsShowData}
                    end,
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?RANKREWARD, ?RANKREWARD_INFO, R2);
                _ ->
                    ignore
            end;
        _R->
            ignore
    end.

check_rankreward_info(RoleID,RankId)->
    case get_rankreward_list(RankId) of
        undefined->
            {error,no_rankreward_list};
        RankList->
            %%#p_jingjie_rank_yesterday.role_id
            %%#p_role_fighting_power_rank_yesterday.role_id
            case lists:keyfind(RoleID, 2, RankList) of
                false->
                    {error,not_found};
                LastHeroRank ->
                    {ok,LastHeroRank}
            end
    end.

%%@interface 领奖
do_rankreward_fetch({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_rankreward_fetch_reward_tos{rank_id=RankId} = DataIn,
    case catch check_rankreward_fetch(RoleID,RankId) of
        {ok,LastHeroRank}->
            RewardSilver = get_reward_silver(LastHeroRank),
            %%在地图中进行处理
            AddMoneyList = [{silver_bind, RewardSilver,?GAIN_TYPE_SILVER_RANKREWARD_FETCH,""}],
            ReturnMsg = {?FETCH_RANKREWARD_SILVER,RankId,RewardSilver},
            common_role_money:add(RoleID, AddMoneyList,ReturnMsg,ReturnMsg,true),
            set_fetch_tag(RoleID,RankId,LastHeroRank),
            ok;
        {error,ErrCode,ErrReason}->
            R2 = #m_rankreward_fetch_reward_toc{error_code=ErrCode,reason=ErrReason},
            ?UNICAST_TOC(R2)
    end.

%%记录排行奖励的日志
write_rankreward_log(RoleID,RankId,RewardSilver)->
    case get_fetch_tag(RoleID,RankId) of
        {#p_jingjie_rank_yesterday{ranking=Ranking,jingjie=Jingjie},_Time}->
            Now = common_tool:now(),
            RoleName = common_misc:get_dirty_rolename(RoleID),
            Log = #r_rankreward_log{role_id=RoleID,rank_id=RankId,role_name=RoleName,ranking=Ranking,jingjie=Jingjie,
                                    reward_silver=RewardSilver,log_time=Now},
            common_general_log_server:log_rankreward(Log);
        {#p_role_fighting_power_rank_yesterday{ranking=Ranking,jingjie=Jingjie},_Time}->
            Now = common_tool:now(),
            RoleName = common_misc:get_dirty_rolename(RoleID),
            Log = #r_rankreward_log{role_id=RoleID,rank_id=RankId,role_name=RoleName,ranking=Ranking,jingjie=Jingjie,
                                    reward_silver=RewardSilver,log_time=Now},
            common_general_log_server:log_rankreward(Log);
        _ ->
            ignore
    end.

get_fetch_tag(RoleID,RankId)->
    get({?RANKREWARD_FETCHING_TAG,RankId,RoleID}).


clear_fetch_tag(RoleID,RankId)->
    erase({?RANKREWARD_FETCHING_TAG,RankId,RoleID}).

set_fetch_tag(RoleID,RankId,LastHeroRank)->
    Now = common_tool:now(),
    put({?RANKREWARD_FETCHING_TAG,RankId,RoleID},{LastHeroRank,Now}),
    ok.

%%根据排名获取奖励钱币数目
get_reward_silver(#p_role_fighting_power_rank_yesterday{ranking=Ranking,level=Level})->
    RankId = ranking_fighting_power_yesterday:get_rank_id(),
    get_reward_silver(RankId,Level,Ranking).

get_reward_silver(RankId,Level,Ranking)->
	[BasicTitleRewardList] = common_config_dyn:find(rankreward,{basic_reward,RankId}),
	[RankRatioList] = common_config_dyn:find(rankreward,rank_ratio),
	case lists:keyfind(Level div 10, 1, BasicTitleRewardList) of
		false ->
			BasicTitleReward = 0;
		{_,BasicTitleReward} ->
			todo
	end,
	MatchRatio = get_match_ratio(Ranking,RankRatioList),
	BasicTitleReward*MatchRatio div 10000.

check_rankreward_fetch(RoleID,RankId)->
    case get_rankreward_list(RankId) of
        undefined->
            ?THROW_ERR( ?ERR_RANKREWARD_NO_DATA );
        RankList->
            %%#p_jingjie_rank_yesterday.role_id
            %%#p_role_fighting_power_rank_yesterday.role_id
            case lists:keyfind(RoleID, 2, RankList) of
                false->
                    ?THROW_ERR( ?ERR_RANKREWARD_ROLE_NOT_IN_RANK );
                LastHeroRank ->
                    assert_reward_not_fetched(RoleID,RankId),
                    {ok,LastHeroRank}
            end
    end.
assert_reward_not_fetched(RoleID,RankId)->
    case has_fetch_reward_today(RoleID,RankId) of
        true->
            ?THROW_ERR( ?ERR_RANKREWARD_ROLE_HAS_FETCHED );
        _ ->
            %%检查是否正在领取当中
            case get_fetch_tag(RoleID,RankId) of
                undefined->
                    next;
                {_,LastTime}->
                    Now = common_tool:now(),
                    case Now>(LastTime+30) of %%30秒后还没有加钱成功，则允许重新领取一次
                        true->
                            next;
                        _ ->
                            ?THROW_ERR( ?ERR_RANKREWARD_ROLE_IS_FETCHING )
                    end
            end
    end.

%%检查当日是否已领取
has_fetch_reward_today(RoleID,RankId)->
    case db:dirty_read(?DB_ROLE_RANKREWARD_P,RoleID) of
        []->
            false;
        [#r_role_rankreward{fetch_list=FetchList}]->
            case lists:keyfind(RankId, 1, FetchList) of
                {RankId,LastFetchTime,_}->
                    next;
                _ ->
                    LastFetchTime = 0
            end,
            case LastFetchTime=:=0 orelse LastFetchTime=:=undefined of
                true->
                    false;
                _ ->
                    {Date,_} = common_tool:seconds_to_datetime(LastFetchTime),
                    Date =:= date()
            end
    end.
    

get_match_ratio(_Ranking,[])->
    [DefaultRatio] = common_config_dyn:find(rankreward,default_ratio),
    DefaultRatio;
get_match_ratio(Ranking,[H|T])->
    {MinRank,MaxRank,RatioVal} = H,
    case Ranking>=MinRank andalso MaxRank>=Ranking of
        true->
            RatioVal;
        _ ->
            get_match_ratio(Ranking,T)
    end.
get_reward_prop(RankId,Level,Ranking) ->
	[BasicTitleRewardList] = common_config_dyn:find(rankreward,{basic_reward,RankId}),
	[RankRatioList] = common_config_dyn:find(rankreward,{rank_ratio,RankId}),
	case lists:keyfind(Level div 10, 1, BasicTitleRewardList) of
		false ->
			BasicTitleReward = 0,
			RewardProp = [];
		{_,BasicTitleReward,RewardProp} ->
			next
	end,
	{RatioVal,RatioItem} = get_match_ratio(Ranking,RankRatioList),
	NewSilver = BasicTitleReward*RatioVal div 10000,
	NewRewardProp = [Reward#p_reward_prop{prop_num=RatioItem*Num}|| #p_reward_prop{prop_num=Num}=Reward <-RewardProp],
	{NewSilver,NewRewardProp}.


send_reward_letter(RankID,RoleRankList) ->
	MaxRankLevel = ranking_role_level_all:get_rank_max_level(),
	lists:foreach(fun(RoleRank) ->
						  {RoleID,Ranking,RoleName} = get_ranking_info(RankID,RoleRank),
						  {Silver,RewardList} = mod_rankreward_server:get_reward_prop(RankID,MaxRankLevel,Ranking),
						  case Silver > 0 of
							  true ->
								  NewRewardList = [#p_reward_prop{prop_id=10100137,prop_type=true,prop_num=1,bind=true,color=1}|RewardList];
							  false ->
								  NewRewardList = RewardList
						  end,
						  case RewardList of
							  [] ->
								  Name = "";
							  [#p_reward_prop{prop_id=TypeID,prop_type=PropType}] ->
								  case PropType of
									  ?TYPE_EQUIP ->
										  [#p_equip_base_info{equipname=Name}] = common_config_dyn:find_equip(TypeID);
									  _ ->
										  [#p_item_base_info{itemname=Name}] =  cfg_item:find(TypeID)
								  end
						  
						  end,
						  {Title,Content} = create_letter_content(RankID,Ranking,RoleName,Silver,Name),
						  send_letter(RoleID,NewRewardList,Title,Content,Silver)
				  end, RoleRankList),
	?ERROR_MSG("Send ~p reward success! ",[RankID]).

create_letter_content(RankID,Ranking,RoleName,_Silver,_ItemName) ->
	case RankID of
		?CONSUME_TODAY_RANK_ID ->
			Title = <<"每日消费排行榜奖励">>,
			Content = common_misc:format_lang(?_LANG_RANKING_CONSUME_TODAY_LETTER_CONTENT, [RoleName, Ranking])
	end,
	{Title,Content}.


get_consume_reward_prop(RankId,Level,Ranking) ->
	case Ranking of
		1 ->
			[RankInfo] = db:dirty_match_object(?DB_ROLE_CONSUME_TODAY_RANK_P,#p_role_consume_today_rank{ranking=Ranking,_='_'}),
			Jifen = RankInfo#p_role_consume_today_rank.score,
			RewardList = cfg_rank_reward:rank(RankId,Ranking,Jifen);
		_ ->
			RewardList = cfg_rank_reward:rank(RankId,Ranking,0)
	end,
	case get_level_reward_list(Level,RewardList) of
		[] ->
			{0,[]};
		{Silver,RewardProp} ->
			NewRewardProp = [Reward#p_reward_prop{prop_num=Num}|| #p_reward_prop{prop_num=Num}=Reward <-RewardProp],
			{Silver,NewRewardProp}
	end.

get_level_reward_list(_Level,[]) ->
	[];
get_level_reward_list(Level,[H|T]) ->
	{{MinLevel,MaxLevel},Silver,RewardList} = H,
	case (Level>=MinLevel andalso Level=<MaxLevel) of
		true ->
			{Silver,RewardList};
		_ ->
			get_level_reward_list(Level,T)
	end.

send_consume_reward_letter(RankID,RoleRankList) ->
	lists:foreach(fun(RoleRank) ->
						  {RoleID,Ranking,RoleName} = get_ranking_info(RankID,RoleRank),
						  case common_misc:get_dirty_role_attr(RoleID) of
							  {ok, #p_role_attr{level = Level}} ->
								  Level;
							  _ ->
								  Level = 20
						  end,
						  {Silver,RewardList} = get_consume_reward_prop(RankID,Level,Ranking),
						  case Silver > 0 of
							  true ->
								  NewRewardList = [#p_reward_prop{prop_id=10100137,prop_type=true,prop_num=1,bind=true,color=1}|RewardList];
							  false ->
								  NewRewardList = RewardList
						  end,
						  {Title,Content} = create_letter_content(RankID,Ranking,RoleName,Silver,""),
						  send_letter(RoleID,NewRewardList,Title,Content,Silver)
				  end, RoleRankList),
	?ERROR_MSG("Send ~p reward success! ",[RankID]).


send_letter(RoleID,RewardGoodList,LetterTitle,Content,Silver) ->
	NewRewardItemList = 
		lists:foldl(fun(#p_reward_prop{prop_id=PropID,prop_num=PropNum,prop_type=PropType,bind=IsBind},AccIn) ->
							{ok,GoodList} = 
								case PropType of
									?TYPE_EQUIP ->
										CreateEquip = #r_equip_create_info{role_id=RoleID,num=PropNum,typeid=PropID,bind=IsBind,bag_id=1,bagposition=1},
										common_bag2:creat_equip_without_expand(CreateEquip);
									_ ->
										CreateItem = #r_item_create_info{role_id=RoleID,num=PropNum,typeid=PropID,bind=IsBind,bag_id=1,bagposition=1},
										common_bag2:create_item(CreateItem)
								end,
						  case PropID =:= 10100137 of
							  true ->
								  NewGoodList = [Goods#p_goods{id=1,quality=Silver}||Goods<-GoodList];
							  false ->
								  NewGoodList = [Goods#p_goods{id=1}||Goods<-GoodList]
						  end,
						  lists:append(NewGoodList, AccIn)
				  end, [], RewardGoodList),

	common_letter:sys2p(RoleID,Content,LetterTitle,NewRewardItemList,14).

 
get_ranking_info(RankID,RoleRank) ->
	case RankID of
		?CONSUME_TODAY_RANK_ID ->
			#p_role_consume_today_rank{role_id=RoleID,ranking=Ranking,score=RoleName} = RoleRank
	end,
	{RoleID,Ranking,RoleName}.
    
 


