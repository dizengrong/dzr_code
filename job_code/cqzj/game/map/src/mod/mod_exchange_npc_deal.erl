%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     NPC兑换物品的功能模块
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(mod_exchange_npc_deal).

-include("mgeem.hrl").

%% API
-export([ 
         handle/1,
         get_role_deal_num/2
         ]).

handle({Unique, Module, ?EXCHANGE_NPC_DEAL, DataIn, RoleID, PID, Line}) ->
    do_npc_deal(Unique, Module, ?EXCHANGE_NPC_DEAL, DataIn, RoleID, PID, Line);
handle({Unique, Module, ?EXCHANGE_EQUIP_INFO, DataIn, RoleID, _PID, Line}) ->
    do_equil_info(Unique, Module, ?EXCHANGE_EQUIP_INFO,RoleID, Line,DataIn);
handle(Args) ->
    ?ERROR_MSG("~w, unknow args: ~w", [?MODULE,Args]),
    ok. 

%%@doc 检查玩家兑换的历史次数
get_role_deal_num(RoleID,DealID)->
    Key = {RoleID,DealID},
    case db:dirty_read(?DB_ROLE_NPC_DEAL,Key) of
        []->
            0;
        [#r_role_npc_deal{total_deal_num=TotalDealNum}]->
            TotalDealNum
    end.

%% 获取玩家今天兑换的次数
get_role_today_deal_num(RoleID, DealID) ->
    Key = {RoleID, DealID},
    case db:dirty_read(?DB_ROLE_NPC_DEAL,Key) of
        []->
            0;
        [#r_role_npc_deal{last_deal_time=LastDealTime, today_deal_num=TodayDealNum}]->
            {DealDate, _} = common_tool:seconds_to_datetime(LastDealTime),
            case DealDate =:= erlang:date() of
                true ->
                    TodayDealNum;
                false ->
                    0
            end
    end.

do_equil_info(Unique, Module,Method,RoleID,Line,DataIn)->
    #m_exchange_equip_info_tos{chagetype=TypeID,equiplist=GoodsList} = DataIn,
    Ft = fun(X,Acc) ->
                 case get_newpgoods(X,RoleID) of
                     {ok,NewItem} ->
                         [NewItem|Acc];
                     _ ->
                         Acc                 
                 end
         end,    
    case erlang:length(GoodsList)>0 of
        true ->
            NewGoodsList = lists:foldl(Ft,[],GoodsList),
            R2 = #m_exchange_equip_info_toc{chagetype = TypeID,newgoods= NewGoodsList},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R2);
        false ->
            ignroe
    end.
    
get_newpgoods(#p_equip_item{typeid=TypeID,color=Color,quality=Quality,isbind=Bind,timelimit=EndTime}=_Item,RoleID) ->
    case EndTime =/= 0 of
        true ->
            {NewStartTime,NewEndTime} = {common_tool:now(),common_tool:now()+EndTime+500};
        false ->
            {NewStartTime,NewEndTime} = {0,0}
    end,
    CreateBind = case Bind of
                    1 ->
                        true;
                    _ ->
                        false
                 end,
    CreateInfo = #r_equip_create_info{role_id=RoleID,num=1,typeid = TypeID,bind=CreateBind,start_time = NewStartTime,end_time = NewEndTime,color=Color,quality=Quality,interface_type=mission},
    case mod_equip:creat_equip(CreateInfo) of
    %%case common_bag2:creat_equip_without_expand(CreateInfo) of
        {ok,[EquipGoods|_]} ->
            {ok,EquipGoods#p_goods{id=1,bagid = 0,bagposition = 0}};
        {error,EquipError} ->
            ?ERROR_MSG("查询物品错误~w",[EquipError]),
            {error,ignore}
    end.



%%@doc 实现NPC兑换的功能
do_npc_deal(Unique, Module, Method, DataIn, RoleID, _PID, Line)->
    case catch check_npc_deal_condition(RoleID,DataIn) of
        ok->
            do_npc_deal_1(Unique, Module, Method, DataIn, RoleID, _PID, Line);
        {error,Reason}->
            ?SEND_ERR_TOC(m_exchange_npc_deal_toc,Reason)
    end.

check_npc_deal_condition(_RoleID,DataIn)->
	#m_exchange_npc_deal_tos{deal_id=DealUniqueID} = DataIn,
    #r_npc_deal{limit_deal_maps=MapIdList} = cfg_deal:get(DealUniqueID),
	case MapIdList of
        undefined->
            next;
        []->
            next;
        _ ->
            MapID = mgeem_map:get_mapid(),
            case lists:member(MapID, MapIdList) of
                true->
                    next;
                _ ->
                    throw({error,?_LANG_EXCHANGE_NPC_DEAL_LIMIT_MAP})
            end
    end,
    ok.
    
do_npc_deal_1(Unique, Module, Method, DataIn, RoleID, _PID, Line)->    
    #m_exchange_npc_deal_tos{deal_id=DealUniqueID,deal_amount=Amount} = DataIn,
    #r_npc_deal{deduct_list=DeductList,limit_deal_times=LimitTimes,
            limit_daily_times=LimitDailyTimes}=ExchangeInfo = cfg_deal:get(DealUniqueID),
    case catch check_exchange_num(RoleID,DealUniqueID,LimitTimes,LimitDailyTimes,Amount) of
        ok ->  
            case catch check_deduct_list(RoleID, DealUniqueID, DeductList, Amount) of
                ok ->
                    do_npc_deal_2(Unique, Module, Method,DataIn, RoleID, Line, ExchangeInfo, Amount);
                {error,ErrorMsg} ->
                    ?SEND_ERR_TOC(m_exchange_npc_deal_toc,ErrorMsg)
            end;
        {error,Reason1} ->
            ?SEND_ERR_TOC(m_exchange_npc_deal_toc,Reason1)
    end.

check_deduct_list(RoleID, DealUniqueID, DeductList, Amount) ->
    lists:foldl(
      fun(Elem, Acc) -> 
              case Elem of
                  {item, ItemID, DeductNum} ->
                      check_goods_exchange(RoleID,ItemID,DeductNum,Amount),
                      Acc;
                  {attr, AttrType, DeductNum} ->
                      check_attr_exchange(RoleID,AttrType,DeductNum,Amount),
                      Acc;
				  {more_to_one, MoreToOneList, DeductNum} ->
					  check_more_to_one_exchange(RoleID, MoreToOneList, DeductNum, Amount),
					  Acc;
                  _ ->
                      ?ERROR_MSG("npc兑换配置有误 DealID ~w",[{DealUniqueID, Elem}]),
                      erlang:throw({error, ?_LANG_SYSTEM_ERROR})
              end
      end, ok, DeductList).

check_more_to_one_exchange(RoleID, TypeIDList, DeductNum, Amount) ->
	DeductNumAll = DeductNum * Amount,
	TotalInBag = lists:foldl(fun(TypeID, Sum) ->
									 {ok, Num} = mod_bag:get_goods_num_by_typeid([1], RoleID, TypeID),
									 Sum + Num
							 end,
							 0, TypeIDList),
	case (DeductNumAll =< TotalInBag) of
		false ->
			erlang:throw({error,?_LANG_EXCHANGE_NPC_DEAL_DEDUCT_ITEM_NOT_ENOUGH});
		_ ->
			ok
	end.

check_attr_exchange(RoleID,TypeID,DeductAmount,Amount) when DeductAmount>0, Amount>0 ->
    case TypeID of
        % arena_score ->
        %     ErrReason= ?_LANG_EXCHANGE_NPC_DEAL_NO_ARENA_SCORE,
        %     Value = mod_arena_misc:get_arena_total_score(RoleID);
        % family_conb ->
        %     ErrReason= ?_LANG_EXCHANGE_NPC_DEAL_NO_FML_GONGXIAN,
        %     {ok, #p_role_attr{family_contribute=Value}}  = mod_map_role:get_role_attr(RoleID);
        gongxun ->
            ErrReason= ?_LANG_EXCHANGE_NPC_DEAL_NO_ZHANGONG,
            {ok, #p_role_attr{gongxun=Value}}  = mod_map_role:get_role_attr(RoleID);
        gold_unbind ->
            ErrReason= ?_LANG_EXCHANGE_NPC_DEAL_NO_GOLD_UNBIND,
            {ok, #p_role_attr{gold=Value}}  = mod_map_role:get_role_attr(RoleID);
        silver_any ->
            ErrReason= ?_LANG_EXCHANGE_NPC_DEAL_NO_SILVER,
            {ok, #p_role_attr{silver=Silver, silver_bind=SilverBind}}  = mod_map_role:get_role_attr(RoleID),
            Value = Silver + SilverBind;
        gold_any ->
            ErrReason= ?_LANG_EXCHANGE_NPC_DEAL_NO_GOLD,
            {ok, #p_role_attr{gold_bind=GoldBind}}  = mod_map_role:get_role_attr(RoleID),
            Value = GoldBind;
        exp ->
            ErrReason= ?_LANG_EXCHANGE_NPC_DEAL_NO_EXP,
            {ok, #p_role_attr{exp=Value}}  = mod_map_role:get_role_attr(RoleID);
        prestige ->
            ErrReason = ?_LANG_EXCHANGE_NPC_DEAL_NO_PRESTIGE,
            {ok, #p_role_attr{cur_prestige=Value}} = mod_map_role:get_role_attr(RoleID);
        score_xunbao ->
            ErrReason = ?_LANG_EXCHANGE_NPC_DEAL_NOT_ENOUGH_SCORE,
            ScoreRec = mod_role_tab:get(RoleID, ?ROLE_SCORE),
            Value = ScoreRec#p_score.xunbao;
        score_yueguang ->
            ErrReason = ?_LANG_EXCHANGE_NPC_DEAL_NOT_ENOUGH_SCORE,
            ScoreRec = mod_role_tab:get(RoleID, ?ROLE_SCORE),
            Value = ScoreRec#p_score.yueguang;
        score_jingji ->
            ErrReason = ?_LANG_EXCHANGE_NPC_DEAL_NOT_ENOUGH_SCORE,
            ScoreRec = mod_role_tab:get(RoleID, ?ROLE_SCORE),
            Value = ScoreRec#p_score.jingji;
        score_dadan ->
            ErrReason = ?_LANG_EXCHANGE_NPC_DEAL_NOT_ENOUGH_SCORE,
            ScoreRec = mod_role_tab:get(RoleID, ?ROLE_SCORE),
            Value = ScoreRec#p_score.dadan;
		score_guard ->
			ErrReason = ?_LANG_EXCHANGE_NPC_DEAL_NOT_ENOUGH_SCORE,
			ScoreRec = mod_role_tab:get(RoleID, ?ROLE_SCORE),
			Value = ScoreRec#p_score.guard;
        cmz ->
            ErrReason = ?_LANG_EXCHANGE_NPC_DEAL_NOT_ENOUGH_SCORE,
            {ok, #r_role_tower_fb{
                cmz = Value
            }} = mod_tower_fb:get_role_tower_fb_info(RoleID)
	end,
    
    AllDealNum = (DeductAmount*Amount),
    if
        Value>=AllDealNum->
            ok;
        true->
            erlang:throw({error,ErrReason})
    end.

check_goods_exchange(RoleID,ItemID,DeductAmount,Amount) ->
    DeductAmountAll = DeductAmount*Amount,
    case mod_bag:check_inbag_by_typeid(RoleID,ItemID) of
        {ok,FoundGoodsList} ->
            FoundItemAmount = lists:foldl(
                                fun(E,AccIn)-> 
                                        #p_goods{current_num=Num}=E,
                                        AccIn + Num
                                end, 0, FoundGoodsList),
            case (FoundItemAmount<DeductAmountAll) of
                true->
                    erlang:throw({error,?_LANG_EXCHANGE_NPC_DEAL_DEDUCT_ITEM_NOT_ENOUGH});
                _->
                    ok
            end;
        _ ->
            erlang:throw({error,?_LANG_EXCHANGE_NPC_DEAL_DEDUCT_ITEM_NOT_EXISTS})
    end.    

get_transaction_module(DeductList) ->
    IsUseDBMoudle = 
        lists:any(fun(Elem) ->
                          case Elem of
                              {item, _, _} ->
                                  false;
                              {attr, arena_score, _} ->
                                  true;
                              _ ->
                                  false
                          end
                  end, DeductList),
    if IsUseDBMoudle ->
           db;
       true ->
           common_transaction
    end.

do_npc_deal_2(Unique, Module, Method, DataIn,RoleID, Line, ExchangeInfo,DealNum)->
	#m_exchange_npc_deal_tos{deal_id=DealUniqueID} = DataIn,
    #r_npc_deal{deal_unique_id=DealUniqueID,deduct_list=DeductList,award_list=AwardList,
                limit_deal_times=LimitDealTimes,limit_daily_times=LimitDailyTimes}=ExchangeInfo,
    TransModule = get_transaction_module(DeductList),
    case TransModule:transaction( fun() -> t_do_npc_deal(RoleID,ExchangeInfo,DealNum) end) of
        {atomic, {ok,AddGoodsList,_XfDeductList,FuncList}} ->
            case LimitDealTimes > 0 orelse LimitDailyTimes > 0 of
                true ->
                    update_role_deal_num(RoleID,DealUniqueID,DealNum);
                _ ->
                    ignore
            end,
            %%奖励道具日志
            lists:foreach(
              fun(E)-> 
                      #r_simple_prop{prop_id=PropID,prop_num=PropNum} = E,
                      common_item_logger:log(RoleID, PropID,PropNum,true,?LOG_ITEM_TYPE_GAIN_NPC_EXCHANGE_DEAL)
              end,AwardList),
            %%扣除道具日志
            lists:foreach(
              fun(E) ->
                      case E of
                          {item, ItemID, Num} ->
                              common_item_logger:log(RoleID, ItemID,Num*DealNum,undefined,?LOG_ITEM_TYPE_LOST_NPC_EXCHANGE_DEAL);
                          _ ->
                              ignore
                      end
              end, DeductList),
            
            %%执行事务成功后的方法
            %% 增加的积分兑换功能的积分扣取在FuncList中执行
            case FuncList of
                []->
                    ignore;
                undefined->
                    ignore;
                FuncList ->
                    lists:foreach(fun({func, Func}) -> Func() end, FuncList)
            end,
            %%属性奖励都在事务后处理
            do_award_attr_list(RoleID,AwardList,DealNum),
            notify_role_goods(update,RoleID,AddGoodsList),
            notify_role_tip(RoleID,ExchangeInfo,AddGoodsList,DealNum);
        {aborted, {bag_error,{not_enough_pos,_BagID}}} ->
            ?SEND_ERR_TOC(m_exchange_npc_deal_toc,?_LANG_EXCHANGE_NPC_DEAL_BAG_FULL);
        {aborted, {throw, {bag_error,{not_enough_pos,_BagID}}}} ->
            ?SEND_ERR_TOC(m_exchange_npc_deal_toc,?_LANG_EXCHANGE_NPC_DEAL_BAG_FULL);
        {aborted, {throw, {bag_error, Reason}}} ->
            ?ERROR_MSG("do_npc_deal_2，Reason=~w",[Reason]),
            ?SEND_ERR_TOC(m_exchange_npc_deal_toc,?_LANG_BAG_ERROR);
        {aborted, Error} ->
            ?ERROR_MSG("do_npc_deal_2，Error=~w",[Error]),
            ?SEND_ERR_TOC(m_exchange_npc_deal_toc,?_LANG_SYSTEM_ERROR)
    end.

t_do_npc_deal(RoleID,ExchangeInfo,AwardAmount)->
	#r_npc_deal{deduct_list=DeductList, award_list=AwardList}=ExchangeInfo,
	{AwardItemList, _AwardAttrList} = lists:partition(fun(E) -> erlang:is_record(E, r_simple_prop) end, AwardList),
    {ok,Num} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
    case Num >= length(AwardItemList) of
        true ->  ok;
        false -> erlang:throw({bag_error,{not_enough_pos,1}})
    end,
    {MoreToOneList, OtherList} = 
        lists:partition(fun(Elem) -> case Elem of
                                         {more_to_one, _, _} -> true;
                                         _ -> false
                                     end
                        end, DeductList),
    case MoreToOneList of
        [] ->
            {ok,UpdateGoodsList,DelGoodsList, AttrFuncList, XfDeductList} = t_do_npc_deal1(RoleID,OtherList,AwardAmount,AwardItemList);
        _ ->
            {ok,UpdateGoodsList1,DelGoodsList1, AttrFuncList} = t_do_npc_deal2(RoleID,MoreToOneList,OtherList,AwardAmount,AwardItemList),
            XfDeductList = [],
            UpdateGoodsList = lists:flatten(UpdateGoodsList1),
            DelGoodsList = lists:flatten(DelGoodsList1)
    end,
    GoodsFuncList ={func,
                    fun()->
                            notify_role_goods(update,RoleID,UpdateGoodsList),
                            notify_role_goods(del,RoleID,DelGoodsList)
                    end},
	{ok,AddGoodsList} = t_add_item(RoleID,[],AwardItemList,AwardAmount),
	{ok,AddGoodsList, XfDeductList, [GoodsFuncList | AttrFuncList]}.


t_do_npc_deal1(RoleID,DeductList,AwardAmount,AwardItemList)->
	{AttrDeductList, ItemDeductList,XfDeductList} = 
		lists:foldl(fun(Elem,Acc) ->
							{AttrD,ItemD,TrumpD} = Acc,
							case Elem of
								{attr, _, _} ->
									{[Elem|AttrD],ItemD,TrumpD};
								{item, _, _} ->
									{AttrD,[Elem|ItemD],TrumpD};
								{xf,_} ->
									{AttrD,ItemD,[Elem|TrumpD]}
							end
					end, {[],[],[]}, DeductList),
  {ok,UpdateGoodsList,DelGoodsList} = t_decrease_goods(RoleID, ItemDeductList, AwardAmount),
	{ok,AttrFuncList} = t_decrease_attr(RoleID, AttrDeductList, AwardAmount, [],AwardItemList),
	{ok,UpdateGoodsList,DelGoodsList, AttrFuncList,XfDeductList}.


t_do_npc_deal2(RoleID,DeductList,AttrDeductList,AwardAmount,AwardItemList)->
	[{more_to_one, DelTypeIDList, PropNum}] = DeductList,
	{ok,UpdateGoodsList,DelGoodsList} = t_decrease_more_to_one(RoleID, DelTypeIDList, PropNum*AwardAmount, [], [], AwardItemList),
	{ok,AttrFuncList} = t_decrease_attr(RoleID, AttrDeductList, AwardAmount, [],AwardItemList),
    {ok,UpdateGoodsList,DelGoodsList, AttrFuncList}.

t_decrease_more_to_one(_RoleID, _DecductList, 0, UpGoodsList, DelGoodList,_AwardItemList) ->
	{ok, UpGoodsList, DelGoodList};
t_decrease_more_to_one(RoleID, [TypeID | DecductListT], Amount, UpGoodsList, DelGoodsList, AwardItemList) when Amount > 0->
	{ok, Num} = mod_bag:get_goods_num_by_typeid([1], RoleID, TypeID),
	case Amount > Num of
		true ->
			{ok, UpGoodsList1, DelGoodsList1} = mod_bag:decrease_goods_by_typeid(RoleID, TypeID, Num),
			t_decrease_more_to_one(RoleID, DecductListT, Amount-Num, [UpGoodsList1 | UpGoodsList], [DelGoodsList1 | DelGoodsList],AwardItemList);
		_ ->
			{ok, UpGoodsList2, DelGoodsList2} = mod_bag:decrease_goods_by_typeid(RoleID, TypeID, Amount),
			t_decrease_more_to_one(RoleID, DecductListT, 0, [UpGoodsList2 | UpGoodsList], [DelGoodsList2 | DelGoodsList],AwardItemList)
	end.

%% 兑换成功后，给予属性/积分等的奖励
do_award_attr_list(RoleID,AwardAttrList,Amount) ->
    {ok,#p_role_base{family_id = FamilyId}} =  mod_map_role:get_role_base(RoleID),
    
    case AwardAttrList of
        []->
            ignore;
        _ ->
            lists:foreach(
              fun(E) ->
                      case E of
                          {attr, AwardType, AddMount} ->
                              case AwardType of
                                  exp -> %% 奖励人物经验
                                      ?TRY_CATCH( common_misc:add_exp_unicast(RoleID,AddMount*Amount) );
                                  family_money -> %% 宗族资金
                                      ?TRY_CATCH( common_family:info(FamilyId, {add_money, AddMount*Amount}) );
                                  family_contribution -> %% 宗族贡献度
                                      ?TRY_CATCH( common_family:info(FamilyId, {add_contribution, RoleID, AddMount*Amount}) )
                              end;
                          _ ->
                              ignore
                      end
              end,AwardAttrList)
    end.


%% ====================================================================
%% Internal functions
%% ====================================================================

%%@doc 给予兑换后的道具
t_add_item(_RoleID,GoodsList,[],_AwardAmount)->
    {ok,GoodsList};
t_add_item(RoleID,GoodsList,[H|T],AwardAmount)->
    #r_simple_prop{prop_id=PropId,prop_type=PropType,prop_num=AwdNum,quality=Quality,color=Color, bind=IsBind} = H,
    Num = AwdNum*AwardAmount,
    CreateInfo = #r_goods_create_info{bind=IsBind,type=PropType, type_id=PropId, start_time=0, end_time=0, 
                                      num=Num, color=Color,quality=Quality,
                                      punch_num=0,interface_type=present},
    {ok,NewGoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
    t_add_item(RoleID, lists:concat([NewGoodsList,GoodsList]) ,T,AwardAmount).

%%@doc 扣除玩家的对应积分属性
t_decrease_attr(_, [], _, Acc,_) ->
    {ok, Acc};

t_decrease_attr(RoleID, [{attr, pet_arena_score, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    global:send(mgeew_pet_arena_server, {add_area_score, RoleID, -(SingleDeductNum * Amount)}),
    t_decrease_attr(RoleID, T, Amount, Acc,AwardItemList);

t_decrease_attr(RoleID, [{attr, family_conb, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    #p_map_role{family_id = FamilyId} =  mod_map_actor:get_actor_mapinfo(RoleID,role),
    ?TRY_CATCH( common_family:info(FamilyId, {add_contribution, RoleID, -(SingleDeductNum * Amount)}) ),
    t_decrease_attr(RoleID, T, Amount, Acc, AwardItemList);

t_decrease_attr(RoleID, [{attr, gongxun, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    {ok, #p_role_attr{gongxun=G}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
    NewValue = G - (SingleDeductNum*Amount),
    RoleAttr2 = RoleAttr#p_role_attr{gongxun=NewValue},
    mod_map_role:set_role_attr(RoleID, RoleAttr2),
    Func = {func,
            fun()-> 
                    RR = #m_role2_attr_change_toc{roleid=RoleID,changes=[#p_role_attr_change{change_type=?ROLE_GONGXUN_CHANGE,new_value=NewValue}]},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, RR),  
                    
                    Notice = common_misc:format_lang(?_LANG_EXCHANGE_NPC_DEAL_LOST_ZHANGONG,[SingleDeductNum*Amount]),
                    common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(Notice))
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc], AwardItemList);

t_decrease_attr(RoleID, [{attr, silver_any, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    {ok,NewRoleAttr} = common_bag2:t_deduct_money(silver_any, SingleDeductNum*Amount, RoleID, ?CONSUME_TYPE_SILVER_NPC_EXCHANGE),
    Func = {func,
            fun()-> 
                    common_misc:send_role_silver_change(RoleID, NewRoleAttr)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc], AwardItemList);

t_decrease_attr(RoleID, [{attr, score_xunbao, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    Func = {func,
            fun()-> 
                    mod_score:decrease_score_without_check(RoleID, SingleDeductNum, Amount, ?SCORE_TYPE_XUNBAO,{?SCORE_TYPE_XUNBAO,"寻宝积分兑换"},AwardItemList)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc], AwardItemList);
t_decrease_attr(RoleID, [{attr, score_yueguang, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    Func = {func,
            fun()-> 
                    mod_score:decrease_score_without_check(RoleID, SingleDeductNum, Amount, ?SCORE_TYPE_YUEGUANG,{?SCORE_TYPE_YUEGUANG,"寻宝积分兑换"},AwardItemList)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc], AwardItemList);
t_decrease_attr(RoleID, [{attr, score_jingji, SingleDeductNum} | T], Amount, Acc, AwardItemList) ->
    Func = {func,
            fun()-> 
                    mod_score:decrease_score_without_check(RoleID, SingleDeductNum, Amount, ?SCORE_TYPE_JINGJI,{?SCORE_TYPE_JINGJI,"竞技积分兑换"},AwardItemList)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc], AwardItemList);
t_decrease_attr(RoleID, [{attr, score_dadan, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    Func = {func,
            fun()-> 
                    mod_score:decrease_score_without_check(RoleID, SingleDeductNum, Amount, ?SCORE_TYPE_DADAN,{?SCORE_TYPE_DADAN,"砸蛋积分兑换"},AwardItemList)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc],AwardItemList);


t_decrease_attr(RoleID, [{attr, score_guard, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    Func = {func,
            fun()-> 
                    mod_score:decrease_score_without_check(RoleID, SingleDeductNum, Amount, ?SCORE_TYPE_GUARD,{?SCORE_TYPE_GUARD,"守护圣女积分兑换"},AwardItemList)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc],AwardItemList);


t_decrease_attr(RoleID, [{attr, Type, SingleDeductNum} | T], Amount, Acc,AwardItemList) when Type =:= gold_any orelse Type =:= gold_unbind ->
    {ok,NewRoleAttr} = common_bag2:t_deduct_money(Type, SingleDeductNum*Amount, RoleID, ?CONSUME_TYPE_GOLD_NPC_EXCHANGE),
    Func = {func,
            fun()-> 
                    common_misc:send_role_gold_change(RoleID, NewRoleAttr)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc],AwardItemList);

t_decrease_attr(RoleID, [{attr, exp, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    {ok, #p_role_attr{exp=Exp}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
    NewExp = Exp - (SingleDeductNum * Amount),
    RoleAttr2 = RoleAttr#p_role_attr{exp=NewExp},
    mod_map_role:set_role_attr(RoleID, RoleAttr2),
    Func = {func,
            fun()-> 
                    RR = #m_role2_attr_change_toc{roleid=RoleID,
                                                  changes=[#p_role_attr_change{change_type=?ROLE_EXP_CHANGE,new_value=NewExp}]},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, RR)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc],AwardItemList);

t_decrease_attr(RoleID, [{attr, cmz, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    Func = {func,
            fun()-> 
                {ok, #r_role_tower_fb{
                    cmz = CMZ
                } = RoleTowerFbInfo} = mod_tower_fb:get_role_tower_fb_info(RoleID),
                NewValue = CMZ - (SingleDeductNum*Amount),
                mod_tower_fb:set_role_tower_fb_info(
                    RoleID, 
                    RoleTowerFbInfo#r_role_tower_fb{cmz = NewValue}
                ),
                R2 = #m_tower_fb_cmz_toc{cmz = NewValue},
                common_misc:unicast(0, RoleID, 0, ?TOWER_FB, ?TOWER_FB_CMZ, R2) 
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc],AwardItemList);

t_decrease_attr(RoleID, [{attr, prestige, SingleDeductNum} | T], Amount, Acc,AwardItemList) ->
    case common_bag2:t_deduct_prestige(SingleDeductNum*Amount, RoleID, ?USE_TYPE_PRESTIGE_EXCHANGE) of
        {ok,RoleAttr} ->
            {ok,RoleAttr};
        _ ->
            RoleAttr = null,
            erlang:throw(not_enough_prestige)
    end,
    Func = {func,
            fun()-> 
                    common_misc:send_role_prestige_change(RoleID,RoleAttr)
            end},
    t_decrease_attr(RoleID, T, Amount, [Func | Acc],AwardItemList).

t_decrease_goods(RoleID, ItemDeductList, Amount) ->
    lists:foldl(
      fun({item, ItemID, SingleDeductNum}, {ok, AccUpGoodsList, AccDelGoodsList}) ->
              {ok, UpList, DelList} = mod_bag:decrease_goods_by_typeid(RoleID, ItemID, SingleDeductNum * Amount),
              {ok, lists:append(UpList,AccUpGoodsList), lists:append(DelList,AccDelGoodsList)}
      end, {ok, [], []}, ItemDeductList).

notify_role_goods(_Type,_RoleID,[])->
    ignore;
notify_role_goods(del,RoleID,GoodsList)->
    common_misc:del_goods_notify({role, RoleID}, GoodsList);
notify_role_goods(_,RoleID,GoodsList)->
    common_misc:update_goods_notify({role, RoleID}, GoodsList).

%%发送兑换成功的通知信息
notify_role_tip(RoleID,ExchangeInfo,AddGoodsList,DealNum) ->
    #r_npc_deal{award_list=AwardList}=ExchangeInfo,
    {AwardItemList, AwardAttrList} = lists:partition(fun(E) -> erlang:is_record(E, r_simple_prop) end, AwardList),
    AwardGoodsDesc = 
        case AwardItemList of
            []->
                "";
            _ ->
                notify_role_tip_2(AwardItemList,AddGoodsList,DealNum)
        end,
    AwardOtherDesc = 
        case AwardAttrList of
            []->
                "";
            _ ->
                notify_role_tip_3(AwardAttrList,DealNum)
        end,
    BcMessage = lists:concat([AwardGoodsDesc,AwardOtherDesc]),
    if BcMessage =/= "" ->
            catch common_broadcast:bc_send_msg_role(
              RoleID,?BC_MSG_TYPE_SYSTEM,common_misc:format_lang(?_LANG_EXCHANGE_NPC_DEAL_SUCC_BC,[BcMessage]));
       true ->
            ok
    end.
    
notify_role_tip_2(AwdItemList,AddGoodsList,DealNum)->
    lists:foldl(
      fun(E,AccIn) ->
              #r_simple_prop{prop_id=PropId,prop_num=Num} = E,
              case lists:keyfind(PropId,#p_goods.typeid,AddGoodsList) of
                  false ->
                      AccIn;
                  Goods ->
                      lists:concat([AccIn," ",common_goods:get_notify_goods_name(Goods#p_goods{current_num = Num*DealNum})])
              end
      end,"",AwdItemList).

notify_role_tip_3(AwardAttrList,DealNum)->
    case AwardAttrList of
        []->
            "";
        _ ->
            lists:foldl(
              fun({attr, OtherType, AddOtherMount},AccIn) ->
                      case OtherType of
                          exp -> %% 奖励人物经验
                              lists:concat([AccIn," ",AddOtherMount*DealNum,?_LANG_NPC_DEAL_TIP_EXP]);
                          family_money -> %% 宗族资金
                              lists:concat([AccIn," ",AddOtherMount*DealNum,?_LANG_NPC_DEAL_TIP_FAMILY_MONEY]);
                          family_contribution -> %% 宗族贡献度
                              lists:concat([AccIn," ",AddOtherMount*DealNum,?_LANG_NPC_DEAL_TIP_FAMILY_CONB]);
                          family_active_points -> %% 宗族繁荣度
                              lists:concat([AccIn," ",AddOtherMount*DealNum,?_LANG_NPC_DEAL_TIP_FAMILY_ACTPOINT]);
                          _ ->
                              AccIn
                      end
              end,"",AwardAttrList)
    end.
    
%%更新玩家的指定交易次数
update_role_deal_num(RoleID,DealID,ThisNum) when ThisNum>0->
    Key = {RoleID,DealID},
    Now = common_tool:now(),
    case db:dirty_read(?DB_ROLE_NPC_DEAL,Key) of
        []->
            R2 = #r_role_npc_deal{key=Key,total_deal_num=ThisNum,last_deal_num=ThisNum,last_deal_time=Now,today_deal_num=ThisNum},
            db:dirty_write(?DB_ROLE_NPC_DEAL,R2);
        [#r_role_npc_deal{total_deal_num=TotalNum,today_deal_num=TodayNum,last_deal_time=LastDealTime}=R1]->
            {LastDealDate, _} = common_tool:seconds_to_datetime(LastDealTime),
            case date() of
                LastDealDate ->
                    %% 同一天today_deal_num累计消费数量
                    R2 = R1#r_role_npc_deal{total_deal_num=ThisNum+TotalNum,last_deal_num=ThisNum,last_deal_time=Now,today_deal_num=TodayNum+ThisNum};
                _ ->
                    %% 不是同一天today_deal_num清零开始
                    R2 = R1#r_role_npc_deal{total_deal_num=ThisNum+TotalNum,last_deal_num=ThisNum,last_deal_time=Now,today_deal_num=ThisNum}
            end,
            db:dirty_write(?DB_ROLE_NPC_DEAL,R2)
    end.

%%检查玩家的交易历史次数
check_exchange_num(RoleID,DealID,LimitTimes,LimitDailyTimes,Amount)->
    mod_shop:assert_num(Amount),
    case LimitTimes =:= 0 of
        true ->
            assert_role_daily_limit_num(RoleID, DealID, LimitTimes, LimitDailyTimes, Amount);
        false ->
            case Amount>LimitTimes of
                true ->
                    Reason = common_misc:format_lang(?_LANG_EXCHANGE_NPC_DEAL_LIMIT_NUM,[LimitTimes]),
                    throw({error,Reason});
                false ->
                    assert_role_deal_limit_num(RoleID,DealID,LimitTimes,LimitDailyTimes,Amount)               
            end
    end,
    ok.

assert_role_deal_limit_num(RoleID,DealID,LimitTimes,LimitDailyTimes,Amount)->
    TotalDealNum = get_role_deal_num(RoleID,DealID),
    if
        TotalDealNum=:=0 ->
            ok;
        TotalDealNum+Amount>LimitTimes->
            Reason = common_misc:format_lang(?_LANG_EXCHANGE_NPC_DEAL_LIMIT_NUM,[LimitTimes]),
            throw({error,Reason});
        true->
            ok
    end,
    assert_role_daily_limit_num(RoleID, DealID, LimitTimes, LimitDailyTimes, Amount).

assert_role_daily_limit_num(RoleID, DealID, _, LimitDailyTimes, Amount) ->
    TodayDealNum = get_role_today_deal_num(RoleID, DealID),
    if TodayDealNum =:= 0 ->
           ok;
       TodayDealNum+Amount > LimitDailyTimes ->
           Reason = common_misc:format_lang(?_LANG_EXCHANGE_NPC_DEAL_DAILY_LIMIT_NUM,[LimitDailyTimes]),
           throw({error,Reason});
       true ->
           ok
    end.
