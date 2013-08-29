%%%-------------------------------------------------------------------
%%% @author  chenrong
%%% @doc
%%% 财神到
%%% @end
%%% Created : 16 Apr 2012 by  <chenrong>
%%%-------------------------------------------------------------------
-module(mod_caishen).

-include("mgeem.hrl").

-export([handle/1,
		 
         role_online/1,
         renew_role_caishen_info/2,
		 refresh_daily_counter_times/2
		]).

-define(PRODUCE_SILVER, 0).
-define(PRODUCE_SILVER_BIND, 1).
-define(PRODUCE_SILVER_ANY, 2).

-define(FETCH_ONE, 0).
-define(FETCH_MULIT, 1).
-define(FETCH_MULIT_SURE, 2).

-define(ERR_CAISHEN_NOT_ENOUGH_FETCH_NUM, 100101). %% 今天领取财神到的次数已经用完，请明天再继续
-define(ERR_CAISHEN_NOT_ENOUGH_GOLD, 100102). %% 元宝不足，无法领取财神到
-define(ERR_CAISHEN_NOT_FOUND_SILVER, 100103). %% 玩家境界不足，没找到对应的钱币兑换（指玩家没境界，无法领取财神到）
-define(ERR_CAISHEN_NOT_VOUCHER_ENOUTH, 100104).
-define(ERR_CAISHEN_NOT_VIPLEVEL_ENOUTH, 100105).%%vip等级不够无法招财
handle({_, ?CAISHEN, ?CAISHEN_INFO, _, _, _, _} = Info) ->
    do_caishen_info(Info);

handle({_, ?CAISHEN, ?CAISHEN_FETCH, DataIn, RoleID, _, _} = Info) ->
	#m_caishen_fetch_tos{type=Type} = DataIn,
	Ret = case Type of
		?FETCH_MULIT ->
			do_fetch_mulit_info(Info),
			false;
		?FETCH_MULIT_SURE ->
			do_fetch_mulit(Info);
		?FETCH_ONE ->
			do_caishen_fetch(Info);
		_ ->
		?ERROR_MSG("unrecognize m_caishen_fetch_tos,type: ~w", [Type]),
		false
	end,
	case Ret of
		{ok, FetchNum} ->
			mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_11),
			%% 完成活动
			hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_CAI_SHEN),
			%% 完成成就
			mod_achievement2:achievement_update_event(RoleID, 14004, FetchNum),
			mod_achievement2:achievement_update_event(RoleID, 43004, FetchNum);
		_ -> ignore
	end;	

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

refresh_daily_counter_times(RoleID,RemainTimes) when erlang:is_integer(RemainTimes)->
	case get_caishen_info(RoleID) of
		{ok,#r_role_caishen{acc_fetch_num=AccFetchNum}=NewCaishenInfo} ->
			if
				RemainTimes > 0 ->
					update_role_caishen_info(RoleID, NewCaishenInfo#r_role_caishen{acc_fetch_num = RemainTimes}),
					RealRemainTimes = RemainTimes;
				true ->
					RealRemainTimes = AccFetchNum
			end,
			mod_daily_counter:set_mission_remain_times(RoleID, 1002, RealRemainTimes,false);
		_ ->
			ignore
	end.
	
do_fetch_mulit({Unique, Module, Method, _DataIn, RoleID, _PID, Line}=Info) ->
	case catch fetch_mulit_caishen_info(RoleID) of
		{ok,item_enought,CaishenInfo,GoodsNums,Level} ->
			Ret = do_only_de_item(Info,CaishenInfo,GoodsNums,Level),
			mod_role_event:notify(RoleID, {?ROLE_EVENT_ZHAO_CAI, GoodsNums}),
			refresh_fetch_num(RoleID);
		{ok,_CaishenInfo,0,0,_,_} ->
			Record = #m_caishen_fetch_toc{err_code=?ERR_CAISHEN_NOT_ENOUGH_GOLD},
			Ret = false,	
			common_misc:unicast(Line, RoleID, Unique, Module, Method, Record);
		{ok,CaishenInfo,GoodsNums,NeedAllGold,FetchNum,Level} ->
			Ret = do_fetch_mulit2(Info,CaishenInfo,GoodsNums,NeedAllGold,FetchNum,Level),
			mod_role_event:notify(RoleID, {?ROLE_EVENT_ZHAO_CAI, FetchNum}),
			refresh_fetch_num(RoleID);
		{error, ErrCode, Reason} ->
            Record = #m_caishen_fetch_toc{err_code=ErrCode, reason=Reason},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, Record),
			Ret = false
    end,
    Ret.

do_fetch_mulit2({Unique, Module, Method, DataIn, RoleID, PID, Line},CaishenInfo,GoodsNums,NeedAllGold,FetchNum,Level) ->
	#m_caishen_fetch_tos{type=Type} = DataIn,
	case common_transaction:transaction(
		   fun() -> 
				   case mod_map_role:get_role_map_ext_info(RoleID) of
					   {ok,RoleExtInfo} ->
						   #r_role_caishen{today_fetch_num=TodayFetchNum, acc_fetch_num=AccFetchNum} = CaishenInfo,
						   [ItemTypeID] = common_config_dyn:find(caishen, caishen_item),
						   {ok,UpdateGoodsList,DelGoodsList} = mod_bag:decrease_goods_by_typeid(RoleID,ItemTypeID,GoodsNums),
						   common_bag2:check_money_enough_and_throw(gold_unbind,NeedAllGold,RoleID),
						   [SilverList] = common_config_dyn:find(caishen, silver),
						   {ok, RoleAttr} = common_bag2:t_deduct_money(gold_unbind, NeedAllGold, RoleID, ?CONSUME_TYPE_GOLD_CAISHEN_FETCH_SILVER),
						   {_,Silver} = lists:keyfind(RoleAttr#p_role_attr.level, 1, SilverList),
						   SilverAward = get_silver(FetchNum,Level),
						   NewRoleAttr = t_award_silver(RoleAttr, SilverAward, ignore, TodayFetchNum + FetchNum),
						   mod_map_role:set_role_attr(RoleID, NewRoleAttr),
						   NewCaishenInfo = CaishenInfo#r_role_caishen{today_fetch_num=TodayFetchNum+FetchNum, 
																	   acc_fetch_num=erlang:max(0, AccFetchNum-FetchNum),
																	   last_fetch_time=common_tool:now()},
						   mod_map_role:t_set_role_map_ext_info(RoleID, RoleExtInfo#r_role_map_ext{caishen=NewCaishenInfo}),
						   {ok, NewCaishenInfo, NewRoleAttr, Silver, SilverAward,{UpdateGoodsList++DelGoodsList}};
					   _ ->
						   {error, not_found}
				   end
		   end
									   ) of
		{aborted, {error, ErrorCode, ErrorReason}} ->
			common_misc:send_common_error(RoleID, ErrorCode, ErrorReason);
		{aborted, Error} ->
			?ERROR_MSG("~ts: role_id: ~w, error : ~w", ["领取财神到经验系统错误", RoleID, Error]),
			ErrRecord = #m_caishen_fetch_toc{type=Type,err_code=?ERR_SYS_ERR},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
		{atomic, {ok, NewCaishenInfo, NewRoleAttr, Silver,SilverAward ,{GoodsList}}} ->
			%%道具日志
			lists:foreach(fun(Good) ->
								  common_item_logger:log(RoleID,Good,1,?LOG_ITEM_TYPE_CAISHEN)
								  end, GoodsList),
			common_misc:update_goods_notify(PID, GoodsList),
			notify_money_change(RoleID, NewRoleAttr),
			NextGoldNeed = get_deduct_gold(NewCaishenInfo#r_role_caishen.today_fetch_num + 1),
			DataRecord = #m_caishen_fetch_toc{type=Type,
											  next_silver=Silver,
											  next_fetch_gold=NextGoldNeed,
											   use_goods_num=GoodsNums,
											  get_silver=SilverAward,
											  use_gold=NeedAllGold,
											  can_fetch_num=NewCaishenInfo#r_role_caishen.acc_fetch_num},
			hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_CAISHEN),
			common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord),
			{ok, FetchNum}
	end.

do_only_de_item({Unique, Module, Method, DataIn, RoleID, PID, Line},CaishenInfo,Num,Level) ->
	#m_caishen_fetch_tos{type=Type} = DataIn,
	case common_transaction:transaction(
		   fun() -> 
				   case mod_map_role:get_role_map_ext_info(RoleID) of
					   {ok,RoleExtInfo} ->
						   {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
						   #r_role_caishen{today_fetch_num=TodayFetchNum, acc_fetch_num=AccFetchNum} = CaishenInfo,
						   [ItemTypeID] = common_config_dyn:find(caishen, caishen_item),
						   {ok,UpdateGoodsList,DelGoodsList} = mod_bag:decrease_goods_by_typeid(RoleID,ItemTypeID,Num),
						 	[SilverList] = common_config_dyn:find(caishen, silver),
						   {_,Silver} = lists:keyfind(RoleAttr#p_role_attr.level, 1, SilverList),
						   SilverAward = get_silver(Num,Level),
						   NewRoleAttr = t_award_silver(RoleAttr, SilverAward, ignore, TodayFetchNum + Num),
						   mod_map_role:set_role_attr(RoleID, NewRoleAttr),
						   NewCaishenInfo = CaishenInfo#r_role_caishen{today_fetch_num=TodayFetchNum+Num, 
																	   acc_fetch_num=AccFetchNum-Num,
																	   last_fetch_time=common_tool:now()},
						   mod_map_role:t_set_role_map_ext_info(RoleID, RoleExtInfo#r_role_map_ext{caishen=NewCaishenInfo}),
						   {ok, NewCaishenInfo, NewRoleAttr, Silver, SilverAward,{UpdateGoodsList++DelGoodsList}};
					   _ ->
						   {error, not_found}
				   end
		   end
									   ) of
		{aborted, Error} ->
			?ERROR_MSG("~ts: role_id: ~w, error : ~w", ["领取财神到经验系统错误", RoleID, Error]),
			ErrRecord = #m_caishen_fetch_toc{type=Type,err_code=?ERR_SYS_ERR},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
		{atomic, {ok, NewCaishenInfo, NewRoleAttr, Silver, SilverAward,{GoodsList}}} ->
			%%道具日志
			lists:foreach(fun(Good) ->
								  common_item_logger:log(RoleID,Good,1,?LOG_ITEM_TYPE_CAISHEN)
								  end, GoodsList),
			common_misc:update_goods_notify(PID, GoodsList),
			notify_money_change(RoleID, NewRoleAttr),
			NextGoldNeed = get_deduct_gold(NewCaishenInfo#r_role_caishen.today_fetch_num + 1),
			DataRecord = #m_caishen_fetch_toc{type=Type,
											  next_silver=Silver,
											  use_goods_num=Num,
											  get_silver=SilverAward,
											  use_gold=0,
											  next_fetch_gold=NextGoldNeed,
											  can_fetch_num=NewCaishenInfo#r_role_caishen.acc_fetch_num},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord),
			{ok, Num}
	end.
	

do_fetch_mulit_info({Unique, Module, _Method, _DataIn, RoleID, _PID, Line}) ->
	case catch fetch_mulit_caishen_info(RoleID) of
		{ok,item_enought,_CaishenInfo,GoodsNums,Level} ->
			GetSilver = get_silver(GoodsNums,Level),
			Record = #m_caishen_fetch_mulit_toc{need_goods_num=GoodsNums,get_silver=GetSilver};
		{ok,_CaishenInfo,0,0,_,_} ->
			Record = #m_caishen_fetch_mulit_toc{err_code=?ERR_CAISHEN_NOT_ENOUGH_GOLD};
		{ok,_CaishenInfo,GoodsNums,NeedAllGold,FetchNum,Level} ->
			GetSilver = get_silver(FetchNum,Level),
			Record = #m_caishen_fetch_mulit_toc{need_gold=NeedAllGold ,need_goods_num=GoodsNums,get_silver=GetSilver};
		{error, ErrCode, Reason} ->
            Record = #m_caishen_fetch_mulit_toc{err_code=ErrCode, reason=Reason}
    end,
	common_misc:unicast(Line, RoleID, Unique, Module, ?CAISHEN_FETCH_MULIT, Record).
		
get_silver(Num,Level) ->
	[SilverList] = common_config_dyn:find(caishen, silver),
	{_,Silver} = lists:keyfind(Level, 1, SilverList),
	[SilverMulti] = common_config_dyn:find(caishen, fetch_multi),
	SilverAward = common_tool:floor(Silver * SilverMulti),
	SilverAward*Num.
	
	
fetch_mulit_caishen_info(RoleID) ->
	case renew_role_caishen_info(RoleID, false) of
		ok ->
			next;
		_ ->
			?THROW_SYS_ERR()
	end,
	case mod_map_role:get_role_attr(RoleID) of
		{ok, RoleAttr} ->
			RoleAttr;
		_ ->
			RoleAttr=null,
			?THROW_SYS_ERR()
	end,
	CaishenInfo = 
		case get_caishen_info(RoleID) of
			{ok, CaishenInfoT} ->
				if CaishenInfoT#r_role_caishen.acc_fetch_num =< 0 ->
					   ?THROW_ERR(?ERR_CAISHEN_NOT_ENOUGH_FETCH_NUM);
				   true ->
					   CaishenInfoT
				end;
			_ ->
				?THROW_SYS_ERR()
		end,
	[ItemTypeID] = common_config_dyn:find(caishen, caishen_item),
	[MultiMaxConfig] = common_config_dyn:find(caishen, caishen_multi_max),
	MultiMax = 
	case MultiMaxConfig > CaishenInfo#r_role_caishen.acc_fetch_num of
		true ->
			CaishenInfo#r_role_caishen.acc_fetch_num;
		_ ->
			MultiMaxConfig
	end,
	{ok, GoodsNums} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ItemTypeID),
	case GoodsNums >= MultiMax of
		true ->
			throw({ok,item_enought,CaishenInfo,MultiMax,RoleAttr#p_role_attr.level});
		false ->
			next
	end,
	NeedAllGold = 
		lists:foldl(fun(Num,Acc) ->
							GoldNeed = get_deduct_gold(CaishenInfo#r_role_caishen.today_fetch_num + Num),
							if RoleAttr#p_role_attr.gold + RoleAttr#p_role_attr.gold_bind >= GoldNeed+Acc ->
								   GoldNeed+Acc;
							   true ->
								   throw({ok,CaishenInfo,GoodsNums,Acc,GoodsNums+Num-1,RoleAttr#p_role_attr.level})
							end
					end, 0, lists:seq(1, MultiMax-GoodsNums)),
	{ok,CaishenInfo,GoodsNums,NeedAllGold,MultiMax,RoleAttr#p_role_attr.level}.


%% 查询天焚炼气塔的信息
do_caishen_info({Unique, Module, Method, _DataIn, RoleID, _PID, Line}) ->
    case catch check_caishen_info(RoleID) of
        {ok, CaishenInfo, Exp, Gold} ->
            #r_role_caishen{acc_fetch_num=AccNum} = CaishenInfo,
            DataRecord = #m_caishen_info_toc{next_silver=Exp, next_fetch_gold=Gold, can_fetch_num=AccNum},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord);
        {error, ErrCode, Reason} ->
            ErrRecord = #m_caishen_info_toc{err_code=ErrCode, reason=Reason},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord)
    end.

check_caishen_info(RoleID) ->
    case renew_role_caishen_info(RoleID, false) of
        ok ->
            next;
        _ ->
            ?THROW_SYS_ERR()
    end,
    
    case get_caishen_info(RoleID) of
        {ok, CaishenInfo} ->
            case mod_map_role:get_role_attr(RoleID) of
                {ok, #p_role_attr{level=Level}} ->
                    case common_config_dyn:find(caishen, silver) of
                        [SilverList] ->
							{_,Silver} = lists:keyfind(Level, 1, SilverList),
                            Gold = get_deduct_gold(CaishenInfo#r_role_caishen.today_fetch_num + 1),
                            {ok, CaishenInfo, Silver, Gold};
                        _ ->
                            ?THROW_ERR(?ERR_CAISHEN_NOT_FOUND_SILVER)
                    end;
                _ ->
                    ?THROW_SYS_ERR()
            end;
        _ ->
            ?THROW_SYS_ERR()
    end.

do_caishen_fetch({Unique, Module, Method, DataIn, RoleID, _PID, Line}) ->
    case catch check_do_caishen_fetch(RoleID) of
         {ok, CaishenInfo} ->
            Ret = do_caishen_fetch_2({Unique, Module, Method, DataIn, RoleID, _PID, Line}, {money,CaishenInfo}),
			mod_role_event:notify(RoleID, {?ROLE_EVENT_ZHAO_CAI, 1}),
			refresh_fetch_num(RoleID);
		{item,ItemTypeID,CaishenInfo} ->
			Ret = do_caishen_fetch_2({Unique, Module, Method, DataIn, RoleID, _PID, Line}, {item,ItemTypeID,CaishenInfo}),
			mod_role_event:notify(RoleID, {?ROLE_EVENT_ZHAO_CAI, 1}),
			refresh_fetch_num(RoleID);
        {error, ErrCode, Reason} ->
            ErrRecord = #m_caishen_fetch_toc{err_code=ErrCode, reason=Reason},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord),
            Ret = false
    end,
    Ret.

check_do_caishen_fetch(RoleID) ->
	case renew_role_caishen_info(RoleID, false) of
		ok ->
			next;
		_ ->
			?THROW_SYS_ERR()
	end,
	
	case get_vip_force_fetch_times(RoleID) of
		{ok,VipTimes} when VipTimes > 0 ->
			ignore;
		_ ->
			?THROW_ERR(?ERR_CAISHEN_NOT_VIPLEVEL_ENOUTH)
	end,	
	
	CaishenInfo = 
		case get_caishen_info(RoleID) of
			{ok, CaishenInfoT} ->
				if CaishenInfoT#r_role_caishen.acc_fetch_num =< 0 ->
					   ?THROW_ERR(?ERR_CAISHEN_NOT_ENOUGH_FETCH_NUM);
				   true ->
					   CaishenInfoT
				end;
			_ ->
				?THROW_SYS_ERR()
		end,
	
	[ItemTypeID] = common_config_dyn:find(caishen, caishen_item),
	case mod_bag:check_inbag_by_typeid(RoleID, ItemTypeID) of
		{ok, _} ->
			throw({item,ItemTypeID,CaishenInfo});
		false ->
			next
	end,
	case mod_map_role:get_role_attr(RoleID) of
		{ok, RoleAttr} ->
			GoldNeed = get_deduct_gold(CaishenInfo#r_role_caishen.today_fetch_num + 1),
			if RoleAttr#p_role_attr.gold + RoleAttr#p_role_attr.gold_bind >= GoldNeed ->
				   next;
			   true ->
				   ?THROW_ERR(?ERR_CAISHEN_NOT_ENOUGH_GOLD)
			end;
		_ ->
			?THROW_SYS_ERR()
	end,
	{ok, CaishenInfo}.

get_vip_force_fetch_times(RoleID) ->
	RoleVipLevel = mod_vip:get_role_vip_level(RoleID),
	[ForceTimes] = common_config_dyn:find(caishen, {fetch_num, RoleVipLevel}),
	{ok,ForceTimes}.



do_caishen_fetch_2({Unique, Module, Method, _DataIn, RoleID, PID, Line}, {item,ItemTypeID,CaishenInfo}) ->
	case common_transaction:transaction(
		   fun() -> 
				   case mod_map_role:get_role_map_ext_info(RoleID) of
					   {ok,RoleExtInfo} ->
						   {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
						   #r_role_caishen{today_fetch_num=TodayFetchNum, acc_fetch_num=AccFetchNum} = CaishenInfo,
						   {ok,UpdateGoodsList,DelGoodsList} = mod_bag:decrease_goods_by_typeid(RoleID,ItemTypeID,1),
						   [SilverList] = common_config_dyn:find(caishen, silver),
						   {_,Silver} = lists:keyfind(RoleAttr#p_role_attr.level, 1, SilverList),
						   [SilverMulti] = common_config_dyn:find(caishen, fetch_multi),
						   SilverAward = common_tool:floor(Silver * SilverMulti),
						   NewRoleAttr = t_award_silver(RoleAttr, SilverAward, ignore, TodayFetchNum + 1),
						   mod_map_role:set_role_attr(RoleID, NewRoleAttr),
						   NewCaishenInfo = CaishenInfo#r_role_caishen{today_fetch_num=TodayFetchNum+1, 
																	   acc_fetch_num=AccFetchNum-1,
																	   last_fetch_time=common_tool:now()},
						   mod_map_role:t_set_role_map_ext_info(RoleID, RoleExtInfo#r_role_map_ext{caishen=NewCaishenInfo}),
						   {ok, NewCaishenInfo, NewRoleAttr, Silver, {UpdateGoodsList++DelGoodsList}};
					   _ ->
						   {error, not_found}
				   end
		   end
									   ) of
		{aborted, Error} ->
			?ERROR_MSG("~ts: role_id: ~w, error : ~w", ["领取财神到经验系统错误", RoleID, Error]),
			ErrRecord = #m_caishen_fetch_toc{err_code=?ERR_SYS_ERR},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
		{atomic, {ok, NewCaishenInfo, NewRoleAttr, Silver, {GoodsList}}} ->
			%%道具日志
			lists:foreach(fun(Good) ->
								  common_item_logger:log(RoleID,Good,1,?LOG_ITEM_TYPE_CAISHEN)
								  end, GoodsList),
			common_misc:update_goods_notify(PID, GoodsList),
			notify_money_change(RoleID, NewRoleAttr),
			NextGoldNeed = get_deduct_gold(NewCaishenInfo#r_role_caishen.today_fetch_num + 1),
			DataRecord = #m_caishen_fetch_toc{next_silver=Silver,
											  next_fetch_gold=NextGoldNeed,
											  can_fetch_num=NewCaishenInfo#r_role_caishen.acc_fetch_num},
			hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_CAISHEN),
			common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord),
			{ok, 1}
	end;
do_caishen_fetch_2({Unique, Module, Method, _DataIn, RoleID, _PID, Line}, {money,CaishenInfo}) ->
	case common_transaction:transaction(
		   fun() -> 
				   case mod_map_role:get_role_map_ext_info(RoleID) of
					   {ok,RoleExtInfo} ->
						   % {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
						   #r_role_caishen{today_fetch_num=TodayFetchNum, acc_fetch_num=AccFetchNum} = CaishenInfo,
						   %% 扣除元宝
						   GoldNeed = get_deduct_gold(TodayFetchNum + 1),
						   % {IsConsumeBindGold, RoleAttr2} = t_deduct_gold(RoleAttr, GoldNeed),
						   case common_bag2:t_deduct_money(gold_unbind, GoldNeed, RoleID, ?CONSUME_TYPE_GOLD_CAISHEN_FETCH_SILVER) of
							   {ok,  RoleAttr} ->
								   [SilverList] = common_config_dyn:find(caishen, silver),
								   {_,Silver} = lists:keyfind(RoleAttr#p_role_attr.level, 1, SilverList),
								   [SilverMulti] = common_config_dyn:find(caishen, fetch_multi),
								   SilverAward = common_tool:floor(Silver * SilverMulti),
								   NewRoleAttr = t_award_silver(RoleAttr, SilverAward, true, TodayFetchNum + 1),
								   mod_map_role:set_role_attr(RoleID, NewRoleAttr),
								   NewCaishenInfo = CaishenInfo#r_role_caishen{today_fetch_num=TodayFetchNum+1, 
																			   acc_fetch_num=AccFetchNum-1,
																			   last_fetch_time=common_tool:now()},
								   mod_map_role:t_set_role_map_ext_info(RoleID, RoleExtInfo#r_role_map_ext{caishen=NewCaishenInfo}),
								   {ok, NewCaishenInfo, NewRoleAttr, Silver, GoldNeed};
							   {error,_} ->
								   ?THROW_ERR(?ERR_CAISHEN_NOT_VOUCHER_ENOUTH)
						   end;
					   _ ->
						   {error, not_found}
				   end
		   end
									   ) of
		{aborted, {error,ErrorCode,Reason}}->
			ErrRecord = #m_caishen_fetch_toc{err_code=ErrorCode,reason=Reason},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);			
		{aborted, Error} ->
			?ERROR_MSG("~ts: role_id: ~w, error : ~w", ["领取财神到经验系统错误", RoleID, Error]),
			ErrRecord = #m_caishen_fetch_toc{err_code=?ERR_SYS_ERR},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
		{atomic, {ok, NewCaishenInfo, NewRoleAttr, Silver, DeductGold}} ->
			notify_money_change(RoleID, NewRoleAttr),
			NextGoldNeed = get_deduct_gold(NewCaishenInfo#r_role_caishen.today_fetch_num + 1),
			DataRecord = #m_caishen_fetch_toc{next_silver=Silver,
											  next_fetch_gold=NextGoldNeed,
											  can_fetch_num=NewCaishenInfo#r_role_caishen.acc_fetch_num,
											  use_gold=DeductGold},
			mod_daily_counter:set_mission_remain_times(RoleID, 1002, NewCaishenInfo#r_role_caishen.acc_fetch_num,true),
			hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_CAISHEN),
			common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord),
			{ok, 1}
	end.

% t_deduct_gold(RoleAttr,NeedGold) ->
%     #p_role_attr{role_id=RoleID, gold_bind = BindGold, gold = Gold} = RoleAttr,
%     IsConsumeBindGold = 
%     case BindGold >= NeedGold of
%         true ->
%             common_consume_logger:use_gold({RoleID, NeedGold, 0, ?CONSUME_TYPE_GOLD_CAISHEN_FETCH_SILVER,""}),
%             NewRoleAttr = RoleAttr#p_role_attr{gold_bind=BindGold-NeedGold},
%             true;
%         false ->
%             common_consume_logger:use_gold({RoleID, BindGold, NeedGold-BindGold, ?CONSUME_TYPE_GOLD_CAISHEN_FETCH_SILVER, ""}),
%             NewRoleAttr = RoleAttr#p_role_attr{gold_bind=0, gold=Gold+BindGold-NeedGold},
%             false
%     end,
%     {IsConsumeBindGold, NewRoleAttr}.

t_award_silver(RoleAttr, SilverAward, IsConsumeBindGold, FetchTimes) ->
    #p_role_attr{role_id=RoleID, silver_bind=SilverBind, silver=Silver} = RoleAttr,
    [BindFetchTimes] = common_config_dyn:find(caishen, bind_fetch_times),
    case FetchTimes =< BindFetchTimes of
        true ->
            NewRoleAttr = RoleAttr#p_role_attr{silver_bind=SilverBind+SilverAward},
            common_consume_logger:gain_silver({RoleID, SilverAward, 0, ?GAIN_TYPE_SILVER_CAISHEN,""});
        false ->
            case {common_config_dyn:find(caishen, caishen_bind), IsConsumeBindGold} of
                {[?PRODUCE_SILVER], _} ->
                    NewRoleAttr = RoleAttr#p_role_attr{silver=Silver+SilverAward},
                    common_consume_logger:gain_silver({RoleID, 0, SilverAward, ?GAIN_TYPE_SILVER_CAISHEN,""});
                {[?PRODUCE_SILVER_BIND], _} ->
                    NewRoleAttr = RoleAttr#p_role_attr{silver_bind=SilverBind+SilverAward},
                    common_consume_logger:gain_silver({RoleID, SilverAward, 0, ?GAIN_TYPE_SILVER_CAISHEN,""});
                {[?PRODUCE_SILVER_ANY], ignore} ->
					NewRoleAttr = RoleAttr#p_role_attr{silver=Silver+SilverAward},
                    common_consume_logger:gain_silver({RoleID, 0, SilverAward, ?GAIN_TYPE_SILVER_CAISHEN,""});
				{[?PRODUCE_SILVER_ANY], true} ->
                    NewRoleAttr = RoleAttr#p_role_attr{silver_bind=SilverBind+SilverAward},
                    common_consume_logger:gain_silver({RoleID, SilverAward, 0, ?GAIN_TYPE_SILVER_CAISHEN,""});
                {[?PRODUCE_SILVER_ANY], false} ->
                    NewRoleAttr = RoleAttr#p_role_attr{silver=Silver+SilverAward},
                    common_consume_logger:gain_silver({RoleID, 0, SilverAward, ?GAIN_TYPE_SILVER_CAISHEN,""})
            end
    end,
    NewRoleAttr.
            

notify_money_change(RoleID,NewRoleAttr) ->
    ChangeList = [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
                  #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind},
                  #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=NewRoleAttr#p_role_attr.silver},
                  #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.silver_bind}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList).

%% 玩家上线时 更新玩家的累积可领取次数
role_online(RoleID) ->
	renew_role_caishen_info(RoleID, false).
refresh_fetch_num(RoleID) ->
	case get_caishen_info(RoleID) of 
		{ok, #r_role_caishen{acc_fetch_num=AccNum}} ->
			mod_daily_counter:set_mission_remain_times(RoleID, 1002, AccNum,true),
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CAISHEN, ?CAISHEN_FETCH_NUM, #m_caishen_fetch_num_toc{can_fetch_num=AccNum});
		_ ->
			ignore
	end.
renew_role_caishen_info(RoleID, IsVipLevelUpgrade) ->
	case get_caishen_info(RoleID) of 
		{ok, CaishenInfo} ->
			VipLevel = mod_vip:get_role_vip_level(RoleID),
			[FetchNum] = common_config_dyn:find(caishen, {fetch_num, VipLevel}),
			%% 跨周时清除玩家的累积次数，以周一为开始
			{LastResetDate, _} = common_tool:seconds_to_datetime(CaishenInfo#r_role_caishen.last_reset_time),
			{Status, NewCaishenInfo} = 
				case common_time:is_in_same_week(date(), LastResetDate) of
					false -> 
						DateDif = 
							case LastResetDate of
								{1970,1,1} ->
									1;
								_ ->
									calendar:day_of_the_week(date())
							end,
						{true, CaishenInfo#r_role_caishen{acc_fetch_num=FetchNum * DateDif, today_fetch_num=0, 
														  last_reset_time=common_tool:now()}};
					true ->  
						%% 跨天时，累积之间未使用的次数
						LastResetDiffDays = erlang:max(0, common_time:diff_date(date(), LastResetDate)),
						CaishenInfo1 = CaishenInfo#r_role_caishen{acc_fetch_num=CaishenInfo#r_role_caishen.acc_fetch_num + FetchNum * LastResetDiffDays},
						case {LastResetDiffDays > 0, IsVipLevelUpgrade} of
							{true, _} ->
								{true, CaishenInfo1#r_role_caishen{today_fetch_num=0, last_reset_time=common_tool:now()}};
							{false, true} ->
								%% 同一天内，vip等级提升时
								{true, CaishenInfo1#r_role_caishen{acc_fetch_num=CaishenInfo#r_role_caishen.acc_fetch_num + FetchNum, last_reset_time=common_tool:now()}};
							{false, false} ->
								{false, CaishenInfo1}
						end
				end,
			if Status =:= true ->
				   mod_daily_counter:set_mission_remain_times(RoleID, 1002, NewCaishenInfo#r_role_caishen.acc_fetch_num,true),
				   update_role_caishen_info(RoleID, NewCaishenInfo);
			   true ->
				   ignore
			end,
			ok;
		_ ->
			?ERROR_MSG("~ts:~w", ["获取玩家的财神到信息出错", not_found]),
			ignore
	end.

update_role_caishen_info(RoleID, NewCaishenInfo) ->
    case common_transaction:transaction(
           fun() -> 
                   case mod_map_role:get_role_map_ext_info(RoleID) of
                       {ok,RoleExtInfo} ->
                           NewRoleExtInfo = RoleExtInfo#r_role_map_ext{caishen=NewCaishenInfo},
                           mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
                           ok;
                       _ ->
                           {error ,not_found} 
                   end
           end
    ) of
        {atomic, ok} ->
            ok;
        {aborted, Error} -> 
            ?ERROR_MSG("~ts:~w", ["更新财神到系统错误", Error]),
            {error, fail}
    end.

get_caishen_info(RoleID) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,RoleExtInfo} ->
            #r_role_map_ext{caishen=CaishenRecord} = RoleExtInfo,
            {ok, CaishenRecord};
        _ ->
            {error, not_found_caishen}
    end.

get_deduct_gold(FetchNum) ->
    [HighNum] = common_config_dyn:find(caishen, fetch_threshold),
    Num = 
        case FetchNum > HighNum of
            true ->
                HighNum;
            _ ->
                FetchNum
        end,
    [Gold] = common_config_dyn:find(caishen, {caishen_gold, Num}),
    Gold.
