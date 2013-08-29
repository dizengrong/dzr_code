%% Author: liuwei
%% Created: 2010-4-12
%% Description: TODO: Add description to mod_item
-module(mod_item).

-include("mgeem.hrl").

-export([handle/1,
		 create_item/1,
		 get_item_baseinfo/1,
		 add_role_drunk_count/1,
		 get_role_drunk_count/1,
		 get_item_effect_fun/1
		]).

-define(SEND_SYMBOL,10100001).
-define(BACK_SYMBOL,10100005).
-define(RANDOM_SYMBOL,10100006).

-define(CAN_OVERLAP,1).
-define(NOT_OVERLAP,2).
-define(USED_ITEM_LIST,used_item_list).
-define(USED_ITEM_LIST_LAST_TIME,used_item_list_last_time).

%% 恢复药物
-define(HUIFU_ITEM,[10200001,10200002,10200003,10200004,10200005,10200006,
		   10200007,10200008,10200009,10200010,11500001,11500002,11500003,
		   11500004,11500005,11700001,11700002,11700003,11700004,11700005]).

handle({Unique, Module, ?ITEM_USE, DataIn, RoleID, PID, _Line, State}) ->
	do_use(Unique, Module, ?ITEM_USE, DataIn, RoleID, PID, State);
handle({Unique, Module, ?ITEM_USE_SPECIAL, DataIn, RoleID, PID, _Line, _State}) ->
    mod_special_item:handle({Unique, Module, ?ITEM_USE_SPECIAL, DataIn, RoleID, PID});
handle({Unique, Module, ?ITEM_CANG_BAO_TU_FB, DataIn, RoleID, PID, _Line, _State}) ->
    mod_cang_bao_tu_fb:do_handle_info({Unique, Module, ?ITEM_CANG_BAO_TU_FB, DataIn, RoleID, PID});
handle({Unique, Module, ?ITEM_SHRINK_BAG, DataIn, RoleID, _PID, Line, _State}) ->
    do_shrink(Unique, Module, ?ITEM_SHRINK_BAG, DataIn, RoleID, Line);
handle({Unqiue, Module, ?ITEM_BATCH_SELL, DataIn, RoleID, PID, _Line, _State}) ->
    do_batch_sell(Unqiue, Module, ?ITEM_BATCH_SELL, DataIn, RoleID, PID);
handle({Unique, Module, ?ITEM_TRACE, DataIn, RoleID, PID, _Line, _State}) ->
    do_trace(Unique, Module, ?ITEM_TRACE, DataIn, RoleID, PID);

%% 背包行扩展
handle({Unique, Module, ?ITEM_EXTEND_BAG_ROW, DataIn, RoleID, PID, _Line, _State}) ->
	mod_bag_extend_row:bag_extend_row({Unique,Module,?ITEM_EXTEND_BAG_ROW,DataIn,RoleID,PID});

handle(Info) ->
    ?ERROR_MSG("~ts: ~s", ["道具模块接收到未知的消息：", Info]).

%% 批量卖出物品
do_batch_sell(Unique, Module, Method, DataIn, RoleID, PID) ->
    ItemList = DataIn#m_item_batch_sell_tos.id_list,
    case erlang:length(ItemList) > 0 of
        true ->
            case common_transaction:t(fun() -> t_do_batch_sell(ItemList, RoleID) end) of
                {atomic, {NewRoleAttr, Silver, BindSilver}} ->
                    ChangeList = [
                                  #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=NewRoleAttr#p_role_attr.silver},
                                  #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.silver_bind}],
                    common_misc:role_attr_change_notify({pid, PID}, RoleID, ChangeList),
                    common_misc:unicast2(PID, Unique, Module, Method, #m_item_batch_sell_toc{silver=Silver, bind_silver=BindSilver}),
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            do_batch_sell_error(Unique, Module, Method, Error, PID);
                        false ->
                            ?ERROR_MSG("~ts:~w", ["处理批量卖出时发生系统错误", Error]),
                            do_batch_sell_error(Unique, Module, Method, ?_LANG_ITEM_SYSTEM_ERROR_WHEN_BATCH_SELL, PID)
                    end
            end,
            ok;
        false ->
            do_batch_sell_error(Unique, Module, Method, ?_LANG_ITEM_LIST_IS_EMPTY_WHEN_BATCH_SELL, PID)
    end.

t_do_batch_sell(ItemList, RoleID) ->
    {S, BS} = lists:foldl(
                fun(GoodsID, {Silver, BindSilver}) ->
                        case mod_bag:get_goods_by_id(RoleID,GoodsID) of
                            {error, goods_not_found} ->
                                erlang:throw({error, ?_LANG_ITEM_GOODS_NOT_EXIST});
                            {ok, GoodsInfo} ->
                                case GoodsInfo#p_goods.sell_type =:= 0 of
                                    true ->
                                        erlang:throw({error, ?_LANG_ITEM_CANNT_SELL});
                                    false ->
                                        case GoodsInfo#p_goods.type of
                                            ?TYPE_EQUIP ->
                                                Add = goods_sell_price(GoodsInfo),
                                                case GoodsInfo#p_goods.bind of
                                                    true ->
                                                        {Silver, BindSilver + GoodsInfo#p_goods.current_num * Add};
                                                    false ->
                                                        {Silver + GoodsInfo#p_goods.current_num * Add, BindSilver}
                                                end;
                                            _ ->
                                                case GoodsInfo#p_goods.bind of
                                                    true ->
                                                        {Silver, BindSilver + GoodsInfo#p_goods.current_num * GoodsInfo#p_goods.sell_price};
                                                    false ->
                                                        {Silver + GoodsInfo#p_goods.current_num * GoodsInfo#p_goods.sell_price, BindSilver}
                                                end
                                        end
                                end
                        end
                end, {0, 0}, ItemList),       
    mod_bag:delete_goods(RoleID, ItemList),
    {ok, #p_role_attr{silver=OldS, silver_bind=OldSB} = RoleAttr} = mod_map_role:get_role_attr(RoleID),
    NewAttr = RoleAttr#p_role_attr{silver=OldS + S, silver_bind=OldSB + BS},
    mod_map_role:set_role_attr(RoleID, NewAttr),
    {NewAttr, S, BS}.

goods_sell_price(Goods) ->
    #p_goods{sell_price=SellPrice,
             current_endurance=CE,
             endurance=ES,
             refining_index=RI}=Goods,  
    common_tool:ceil(SellPrice*RI*CE/ES/10).
              

do_batch_sell_error(Unique, Module, Method, Reason, PID) ->
    common_misc:unicast2(PID, Unique, Module, Method, #m_item_batch_sell_toc{succ=false, reason=Reason}).
    

%%道具使用流程
do_use(Unique, Module, Method, DataIn, RoleId, PId, MapState) ->
    case catch check_can_use_item(RoleId, MapState#map_state.mapid, DataIn) of
        {ok, ItemBaseInfo, ItemGoods, TransModule} ->
            do_use2(Unique, Module, Method, DataIn, RoleId, PId, MapState, ItemBaseInfo, ItemGoods, TransModule);
        {aborted, Reason, ReasonCode} ->
            do_use_error(Unique,Module,Method,PId,Reason, ReasonCode);
        {error, Reason} when is_binary(Reason) ->
            do_use_error(Unique, Module, Method, PId, Reason, 0);
        {error, Reason} ->
            ?ERROR_MSG("use item error, roleId=~w,reason=~w,DataIn=~w", [RoleId,Reason,DataIn]),
            do_use_error(Unique, Module, Method, PId, ?_LANG_SYSTEM_ERROR, 0)
    end.

do_use2(Unique, Module, Method, DataIn, RoleID, PId, MapState, ItemBaseInfo, ItemGoods, TransModule) ->
    #m_item_use_tos{usenum=UseNum, effect_id=EffectID} = DataIn,
    case TransModule:transaction(
           fun() ->
                   {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
				   mod_item_use_limit:assert_item_use_limit(RoleID,RoleAttr#p_role_attr.level,UseNum,ItemBaseInfo),
                   {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
                   %%使用道具的功能
                   #r_item_effect_result{item_info=NewItemInfo, role_base=NewRoleBase, role_attr=NewRoleAttr,
                                         msg_list=MsgList, prompt_list=PromptList} 
                       = apply_item_effect(ItemGoods, ItemBaseInfo, RoleBase, RoleAttr, EffectID, UseNum, MapState, TransModule),
                   %%更新玩家信息
                   mod_role_attr:reload_role_base(NewRoleBase),
                   mod_map_role:set_role_attr(RoleID, NewRoleAttr), 
                   DataToc = #m_item_use_toc{succ = true,itemid = ItemGoods#p_goods.id, reason_code = 0,
                                             rest = NewItemInfo#p_goods.current_num,reason=PromptList},
                   {NewItemInfo,MsgList, DataToc}
           end)
        of
        {aborted, {bag_error,{not_enough_pos,_BagID}}} ->
            do_use_error(Unique,Module,Method, PId,?_LANG_GOODS_BAG_NOT_ENOUGH, 0);
        {aborted, {error,ErrorCode,Reason}} ->
            do_use_error(Unique,Module,Method,PId,Reason,ErrorCode);
        {aborted, Reason, ReasonCode} ->
            do_use_error(Unique,Module,Method,PId,Reason, ReasonCode);
        {aborted, Reason} when erlang:is_binary(Reason) ->
            do_use_error(Unique, Module, Method, PId, Reason, 0);
        {aborted, Reason} ->
            do_use_error(Unique,Module,Method,PId,Reason, 0);
        {atomic, {NewItemInfo,MsgList,Data}} ->
            %%事务成功后把事务中要发送到客户的信息发送，发送的顺序按添加的顺序发送
            send_use_item_msg(MsgList),
            %%更新道具使用cd时间
 			common_item_logger:log(RoleID,ItemGoods,ItemGoods#p_goods.current_num-NewItemInfo#p_goods.current_num,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
            updata_use_cd_time(ItemBaseInfo,RoleID),
            common_misc:unicast2(PId, Unique, Module, Method, Data)
    end.
                   	
%%使用道具时的错误处理
do_use_error(Unique, Module, Method, PId, Reason, ReasonCode) ->
    DataRecord = #m_item_use_toc{succ=false, reason=[Reason],reason_code = ReasonCode},
    common_misc:unicast2(PId, Unique, Module, Method, DataRecord).

%% @doc 判断某个数是否是正整数
assert_positive_int(Value, Reason) ->
    if
        is_integer(Value) andalso Value>0 andalso Value<?MAX_USE_NUM ->
            next;
        true->
            erlang:throw({error, Reason})
    end.

check_can_use_item(RoleId, MapID, DataIn) ->
	case cfg_item_helper:can_use_item(MapID) of
		false ->
			{error, <<"不能在这里使用道具">>};
		_ ->
		    #m_item_use_tos{itemid=ItemId, usenum=UseNum} = DataIn,
		    assert_positive_int(UseNum, ?_LANG_ITEM_USE_ILLEGAL_NUM),
		    {ItemInfo, ItemBaseInfo} =
		        case get_item_info(RoleId, ItemId) of
		            {ok, TInfo, TBaseInfo} ->
		                {TInfo, TBaseInfo};
		            {error, Reason} ->
		                erlang:throw({error, Reason})
		        end,
            {ok, RoleBase} = mod_map_role:get_role_base(RoleId),
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleId),
		    check_if_can_use(RoleId, RoleBase, RoleAttr, ItemInfo, ItemBaseInfo, UseNum),
		    TransModule =
		        case get_transaction_module(ItemBaseInfo#p_item_base_info.effects, common_transaction) of
		            {error, R} ->
						?ERROR_MSG("check_can_use_item error:~w",[R]),
		                erlang:throw({error, ?_LANG_SYSTEM_ERROR});
		            TModule ->
		                TModule
		        end,
		    {ok, ItemBaseInfo, ItemInfo, TransModule}
	end.


%%获取道具的物品信息和基础属性
%%返回结果{ok,道具物品信息,道具基础信息} | {error,Reason}
get_item_info(RoleID,ItemID) ->
    case mod_bag:check_inbag(RoleID,ItemID) of
         {ok,ItemInfo} ->
            case get_item_baseinfo(ItemInfo#p_goods.typeid) of
                {ok, ItemBaseInfo} ->
                    {ok, ItemInfo,ItemBaseInfo};
                _ ->
                    {error,?_LANG_ITEM_NO_TYPE_GOODS}
            end;
        false->
            {error,?_LANG_ITEM_NO_TYPE_GOODS};
        {error,Reason} ->
            {error,Reason}
    end.

%%在事务外，检查能检查的道具使用条件
check_if_can_use(RoleID, RoleBase, RoleAttr, ItemInfo, ItemBaseInfo, UsedNum) ->
    check_if_is_item(ItemInfo),
    check_in_use_time(ItemInfo),
    check_item_num(ItemInfo, UsedNum),
    check_item_use_interval(RoleID, ItemBaseInfo#p_item_base_info.cd_type),
    check_role_state(ItemInfo#p_goods.typeid,RoleBase),
    check_role_buff(RoleBase),
    check_item_use_requirement(ItemBaseInfo, RoleAttr).

%%检查是否是道具
check_if_is_item(ItemInfo) ->
    case ItemInfo#p_goods.type of
        ?TYPE_ITEM ->
            ok;
        _ ->
            throw({error,?_LANG_ITEM_NOT_CAN_USE})
    end.

%%检查道具是否到了可以使用的时间，或者过期了
check_in_use_time(ItemInfo) ->
    #p_goods{start_time = StartTime,
             end_time = EndTime} = ItemInfo,
    Now = common_tool:now(),         
    if StartTime =:= 0  orelse 
       StartTime =< Now ->
            next;
       true ->
            throw({error,?_LANG_GOODS_USE_TIME_NOT_ARRIVE})
    end,
    if EndTime =:= 0  orelse 
       EndTime >= Now ->
            ok;
       true ->
            throw({error,?_LANG_GOODS_USE_TIME_PASSED})
    end.

%%检查道具的个数是否够使用的个数
check_item_num(ItemInfo,UsedNum) ->
    case ItemInfo#p_goods.current_num >= UsedNum of
        true ->
            ok;
        false ->
            throw({error,?_LANG_GOODS_NUM_NOT_ENOUGH})
    end.

%%减少道具使用的cd时间
check_item_use_interval(RoleID,CDType) ->
    case get({effect_last_use_time, RoleID}) of
        undefined ->
            ok;
        TimeList ->
            case lists:keyfind(CDType, 1, TimeList) of
                {_, LastUseTime} ->
                    Now = common_tool:now2(),
                    case common_config_dyn:find(item_cd,CDType) of
                        [CDTime]->
                            next;
                        _ ->
                            CDTime = 0
                    end,
                    case Now - LastUseTime > CDTime - 100 of
                        true ->
                            ok;
                        _ ->
                            throw({error,?_LANG_ITEM_USE_TOO_FAST})
                    end;
                _ ->
                    ok
            end
    end.

%%在事务中检查玩家道具使用时的状态
check_role_state(TypeID,#p_role_base{status=RoleState}) ->
	if RoleState =:= ?ROLE_STATE_DEAD ->
		   erlang:throw({error, ?_LANG_ITEM_ROLE_DEAD});
	   true ->
		   %% 战神坛场上禁止使用恢复药物
		   case mod_crown_arena_fb:is_in_fb_map() =:= true
					andalso lists:member(TypeID, ?HUIFU_ITEM) =:= true of
			   true ->
				   erlang:throw({error, ?_LANG_ITEM_IN_ARENA_FIGHT});
			   false ->
				   ok
		   end
	end.

check_role_buff(#p_role_base{buffs=Buffs}) ->
	lists:foreach(
	  fun(Buff) ->
			  case mod_skill_manager:get_buff_func_by_type(Buff#p_actor_buf.buff_type) of
				  %%麻痹
				  {ok, paralysis} ->
					  erlang:throw({error, ?_LANG_ITEM_ROLE_IN_PARALYSIS});
				  {ok, dizzy} -> %%晕迷
					  erlang:throw({error, ?_LANG_ITEM_ROLE_IN_DIZZY});
				  _ ->
					  ok
			  end
	  end, Buffs).

%%在事务中检查道具的使用需求
check_item_use_requirement(ItemBaseInfo, #p_role_attr{role_id=RoleID,level=Level}) ->
    #p_item_base_info{requirement=Req}=ItemBaseInfo,
	#p_use_requirement{min_level=MinLevel,max_level=MaxLevel,vip_level_limit=VipLevelLimit} = Req,
	case Level >= MinLevel andalso Level =< MaxLevel of
		true ->
			RoleVipLevel = mod_vip:get_role_vip_level(RoleID),
			case RoleVipLevel >= VipLevelLimit of
				true ->
					ok;
				false ->
					erlang:throw({error, ?_LANG_ITEM_VIP_LEVEL_DO_NOT_MEET})
			end;
		false ->
			erlang:throw({error, ?_LANG_ITEM_LEVEL_DO_NOT_MEET})
	end.
%%@return #r_item_effect_result()
get_item_effect_result({ItemInfo,RoleBase,RoleAttr,AccMsgList,AccPromptList})->
    #r_item_effect_result{item_info=ItemInfo,role_base=RoleBase,role_attr=RoleAttr,
                          msg_list=AccMsgList,prompt_list=AccPromptList};
get_item_effect_result(Rec) when is_record(Rec,r_item_effect_result)->
    Rec.

get_transaction_module([], Module) ->
	Module;
get_transaction_module([{p_item_effect, FunId, _}|TEffects], Module) ->
	case common_config_dyn:find(item_effect, FunId) of
		[] ->
			{error, not_found};
		[{_, _}] ->
			get_transaction_module(TEffects, Module);
		[{_, _, M}] ->
			if M =:= db ->
				   db;
			   true ->
				   get_transaction_module(TEffects, Module)
			end
	end;
get_transaction_module(undefined, _Module) ->
	{error, ?_LANG_ITEM_NOT_CAN_USE}.


%%使用道具功能
apply_item_effect(ItemInfo, ItemBaseInfo, RoleBase, RoleAttr, EffectID, UseNum, State, TransModule) ->
    Acc0 = get_item_effect_result({ItemInfo, RoleBase, RoleAttr, [], []}),
    lists:foldl(
      fun({p_item_effect,FunID,Params},Acc)->
              #r_item_effect_result{item_info=AccItemInfo,role_base=AccRoleBase,role_attr=AccRoleAttr,
                                    msg_list=AccMsgList,prompt_list=AccPromptList} = Acc,
              case common_config_dyn:find(item_effect, FunID) of
                  [] ->
                      ?ERROR_MSG("~ts:~p, ~ts:~p",["玩家发送了一个不存在的item effect id", FunID, "角色ID", RoleBase#p_role_base.role_id]),
                      TransModule:abort(?_LANG_SYSTEM_ERROR);
                  [{M,F}] ->
                      Rt = M:F(AccItemInfo,ItemBaseInfo,AccRoleBase,AccRoleAttr,AccMsgList,AccPromptList,Params,EffectID,UseNum,State, TransModule),
                      get_item_effect_result(Rt);
                  [{M,F,_}] ->
                      Rt = M:F(AccItemInfo,ItemBaseInfo,AccRoleBase,AccRoleAttr,AccMsgList,AccPromptList,Params,EffectID,UseNum,State, TransModule),
                      get_item_effect_result(Rt)
              end
      end, Acc0, ItemBaseInfo#p_item_base_info.effects).

%%@doc 依放入的顺序发送在事务中带出来的消息  
%%  同时执行指定的func函数
send_use_item_msg(TocMsgList) ->
	lists:foreach(
	  fun({RoleID, Module, Method, Data}) ->
			  common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE, Module, Method, Data);
		 ({func,Fun})->
			  Fun();
		 (_Other)->
			  ignore
	  end,lists:reverse(TocMsgList)).

%%更新道具使用的cd时间
updata_use_cd_time(ItemBase,RoleID) ->
    CDType = ItemBase#p_item_base_info.cd_type,
    case get({effect_last_use_time, RoleID}) of
        undefined ->
            put({effect_last_use_time, RoleID}, [{CDType, common_tool:now2()}]);
        TimeList ->
            case lists:keyfind(CDType, 1, TimeList) of
                false ->
                    put({effect_last_use_time, RoleID}, [{CDType, common_tool:now2()}|TimeList]);
                _ ->
                    put({effect_last_use_time, RoleID}, [{CDType, common_tool:now2()}|lists:keydelete(CDType, 1, TimeList)])
            end
    end.

%% 扩展背包
do_shrink(Unique, Module, Method, DataIn, RoleID, Line) ->
    case catch do_shrink2(RoleID,DataIn) of
        {error,Reason} ->
            do_shrink_error(RoleID, Unique, Module, Method, Line, Reason);
        {ok} ->
            do_shrink2(Unique, Module, Method, DataIn, RoleID, Line)
    end.
do_shrink2(_RoleID,DataIn) ->
    case DataIn#m_item_shrink_bag_tos.bagid > 1 andalso DataIn#m_item_shrink_bag_tos.bagid < 5 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_ITEM_ERROR_SHRINK_BAGID})
    end,
    {ok}.
do_shrink2(Unique, Module, Method, DataIn, RoleID, Line) ->
    case db:transaction(
           fun() ->
                   do_t_shrink(RoleID,DataIn)
           end)
    of
        {aborted, Reason} ->
            ?DEV("~ts:~w",["收起扩展背包失败了", Reason]),
            do_shrink_error(RoleID, Unique, Module, Method, Line, Reason);
        {atomic, {ok,Goods,MainRows,MainClowns,MainGridNumber}}->
            ?DEV("goods:~w~n",[Goods]),
            Data = #m_item_shrink_bag_toc{
              succ=true,
              item=Goods,
              bagid=DataIn#m_item_shrink_bag_tos.bagid,
              rows = MainRows,
              columns = MainClowns,
              grid_number = MainGridNumber
             },
            common_misc:unicast(Line, RoleID, Unique, Module, Method, Data)
    end.

do_shrink_error(RoleID, Unique, Module, Method, Line, Reason)
  when is_binary(Reason) ->
    R = #m_item_shrink_bag_toc{succ=false,reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R);
do_shrink_error(RoleID, Unique, Module, Method, Line, _) ->
    R = #m_item_shrink_bag_toc{succ=false,reason=?_LANG_SYSTEM_ERROR},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_t_shrink(RoleID,DataIn) ->
    #m_item_shrink_bag_tos{bagid=BagID, bag=Bag, position=Pos} = DataIn,
    [BagBasicInfo]= db:read(?DB_ROLE_BAG_BASIC_P,RoleID),
    #r_role_bag_basic{bag_basic_list=BagBasicList} = BagBasicInfo,
    DelBagBasicInfo = 
        case lists:keyfind(BagID,1,BagBasicList) of
            false ->
                db:abort(?_LANG_ITEM_ERROR_SHRINK_NOT_BAGID);
            DelBagBasicInfoT ->
                DelBagBasicInfoT
        end,
    BagBasicList2 = lists:keydelete(BagID,1,BagBasicList),
    MainBagID = 1,
    BagBasicList3 = lists:keydelete(MainBagID,1,BagBasicList2),
    %% 判断当前是否有物品占用扩展背包的格子
    {BagID,DelBagTypeID,DelOutUseTime,_DelRows,_DelClowns,DelGridNumber} = DelBagBasicInfo,
    {MainBagID,MainBagTypeID,MainOutUseTime,_MainRows,MainClowns,MainGridNumber} = mod_bag:get_bag_info_by_id(RoleID,MainBagID),
    case Pos > (MainGridNumber - DelGridNumber) of
        true ->
            db:abort(?_LANG_ITEM_ERROR_SHRINK_BAG_ITEM_POS);
        _ ->
            next
    end,
    case (MainGridNumber - DelGridNumber) rem MainClowns of
        0 ->
            MainRows2 = (MainGridNumber - DelGridNumber) div MainClowns;
        _ ->
            MainRows2 = (MainGridNumber - DelGridNumber) div MainClowns + 1
    end,
    MainGoodsList = mod_refining_bag:get_goods_by_bag_id(RoleID,1),
    case lists:foldl(
           fun(MainGoods,AccFlag) ->
                   case MainGoods#p_goods.bagposition > (MainGridNumber - DelGridNumber) of
                       true ->
                           false;
                       _ ->
                           AccFlag
                   end
           end,true,MainGoodsList) of
        true ->
            next;
        _ ->
            db:abort(?_LANG_ITEM_ERROR_GOODS_IN_SHRINK)
    end,
    mod_bag:delete_bag(RoleID,MainBagID,MainRows2,MainClowns,MainGridNumber - DelGridNumber),
    NewBagBasicInfo = BagBasicInfo#r_role_bag_basic{
                        bag_basic_list=[{MainBagID,MainBagTypeID,MainOutUseTime,MainRows2,MainClowns,MainGridNumber - DelGridNumber}
                                        |BagBasicList3]},
    db:write(?DB_ROLE_BAG_BASIC_P,NewBagBasicInfo,write),
    StartTime = 
        if DelOutUseTime =:=0 -> 
                0;  %%若设为0且end_time!=0，在create的时候会让start_time=now, end_time=end_time+start_time
           true->
                1
        end,
    CreateInfo = #r_goods_create_info{
      type=?TYPE_ITEM,
      type_id=DelBagTypeID,
      num=1,
      bind=true,
      bag_id = Bag,
      position = Pos,
      start_time = StartTime,   
      end_time= DelOutUseTime},
    {ok,[Goods]} = mod_bag:create_goods(RoleID,CreateInfo),
    {ok,Goods,MainRows2,MainClowns,MainGridNumber - DelGridNumber}.

%% @doc 追踪符
do_trace(Unique, Module, Method, DataIn, RoleID, PID) ->
    #m_item_trace_tos{target_name=TargetName, goods_id=GoodsID} = DataIn,
    %% 是否能够使用
    case check_can_use_trace_rune(RoleID, GoodsID) of
        {ok, GoodsInfo} ->
            TargetID = common_misc:get_roleid(TargetName),
            %% 是否在线
            case common_misc:is_role_online(TargetID) of
                false ->
                    do_trace_error(Unique, Module, Method, PID, ?_LANG_ITEM_TRACE_ROLE_NOT_FOUND);
                _ ->
                    do_trace2(Unique, Module, Method, RoleID, TargetID, TargetName, GoodsInfo, PID)
            end;
        {error, Reason} ->
            do_trace_error(Unique, Module, Method, PID, Reason)
    end.

do_trace2(Unique, Module, Method, RoleID, TargetID, TargetName, GoodsInfo, PID) ->
    %% 暂时用脏读
    {ok, #p_role_pos{map_process_name=TargetMapPName, map_id=MapID, pos=#p_pos{tx=TX, ty=TY}}} = common_misc:get_dirty_role_pos(TargetID),
    %% 减的数量写死是1
    Fun = fun() -> mod_bag:decrease_goods(RoleID, [{GoodsInfo, 1}]) end,
    case common_transaction:transaction(Fun) of
        {atomic, {ok, [undefined]}} ->
            GoodsInfo2 = GoodsInfo#p_goods{current_num=0},
            do_trace3(Unique, Module, Method, TargetID, TargetName, TargetMapPName, MapID, TX, TY, GoodsInfo2, PID);
        {atomic, {ok, [GoodsInfo2]}} ->
            do_trace3(Unique, Module, Method, TargetID, TargetName, TargetMapPName, MapID, TX, TY, GoodsInfo2, PID);
        {aborted, Reason} ->
            ?ERROR_MSG("~ts: ~w", ["追踪符使用出错：", Reason]),
            do_trace_error(Unique, Module, Method, PID, ?_LANG_ITEM_TRACE_SYSTEM_ERROR)
    end.

do_trace3(Unique, Module, Method, TargetID, TargetName, TargetMapPName, MapID, TX, TY, GoodsInfo2, PID) ->
    %% 回复客户端
    #p_goods{id=GoodsID, current_num=Num} = GoodsInfo2,
    case global:whereis_name(TargetMapPName) of
        undefined ->
            DataRecord = #m_item_trace_toc{goods_id=GoodsID, goods_num=Num, target_name=TargetName,
                                           target_mapid=MapID, target_tx=TX, target_ty=TY},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord);
        MapPID ->
            MapPID ! {mod_map_role, {trace_role, Unique, Module, Method, PID, {TargetID, TargetName, GoodsID, Num}}}
    end.

do_trace_error(Unique, Module, Method, PID, Reason) ->
    DataRecord = #m_item_trace_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

%% @doc 是否能使用追踪符
check_can_use_trace_rune(RoleID, GoodsID) ->
    case mod_bag:get_goods_by_id(RoleID, GoodsID) of
        {ok, GoodsInfo} ->
            %% todo: 判断是否是追踪符
            {ok, GoodsInfo};
        _ ->
            {error, ?_LANG_ITEM_TRACE_GOODS_NOT_FOUND}
    end.                     

%%创建物品
create_item(CreateInfo)when is_record(CreateInfo,r_item_create_info) ->
    common_bag2:create_item(CreateInfo).


%%获取道具的基础属性
get_item_baseinfo(TypeID) ->
    case common_config_dyn:find_item(TypeID) of
        [] ->
            error;
        [BaseInfo] -> 
            {ok,BaseInfo}
    end.

add_role_drunk_count(RoleID) ->
    ToDay = erlang:date(),
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{energy_drug_usage=Usage} = ExtInfo} ->
            #r_role_energy_drug_usage{drunk_count=OCount, last_drunk_date=Day} = Usage,
            if Day =/= ToDay ->
                   NewUsage = Usage#r_role_energy_drug_usage{drunk_count=1, last_drunk_date=ToDay},
                   mod_map_role:t_set_role_map_ext_info(RoleID, ExtInfo#r_role_map_ext{energy_drug_usage=NewUsage});
               Day =:= ToDay andalso OCount > 4 ->
                    db:abort(?_LANG_ITEM_USE_WINE_TO_MAX);
               true ->
                   NewUsage = Usage#r_role_energy_drug_usage{drunk_count=1+OCount, last_drunk_date=ToDay},
                   mod_map_role:t_set_role_map_ext_info(RoleID, ExtInfo#r_role_map_ext{energy_drug_usage=NewUsage})
            end;
        _ ->
            db:abort(?_LANG_SYSTEM_ERROR)
    end.

get_role_drunk_count(RoleID) ->
    ToDay = common_tool:today(0,0,0),
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{energy_drug_usage=Usage}} ->
            #r_role_energy_drug_usage{drunk_count=OCount, last_drunk_date=Day} = Usage,
            if Day =/= ToDay ->
                   0;
               true ->
                   OCount
            end;
        _ ->
            0
    end.

%% 获得道具的fun名称
get_item_effect_fun(TypeID) ->
	[ItemBaseInfo] = common_config_dyn:find_item(TypeID),
	#p_item_base_info{effects=Effects}=ItemBaseInfo,
	case Effects of
		[#p_item_effect{funid=FunID}|_] ->
			case common_config_dyn:find(item_effect,FunID) of
				[{_,FunName}] ->
					FunName;
				_ ->
					undefined
			end;
		_ ->
			undefined
	end.
