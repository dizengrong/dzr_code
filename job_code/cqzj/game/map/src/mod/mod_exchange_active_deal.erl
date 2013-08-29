%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     NPC兑换物品的功能模块
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(mod_exchange_active_deal).

-include("mgeem.hrl").

%% API
-export([ 
         hook_role_notify/2,
         handle/1
         ]).

-export([
         init/2,
         loop/2
        ]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(EXCHANGE_ACTIVE_OPEN_TIMES,exchange_active_open_times).
-define(OPENDAYS(D),{open_days,D}).

-define(ACTION_OPEN,1).
-define(ACTION_CLOSE,2).

%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_EXCHANGE_DEAL_LV_LIMIT,220001).
-define(ERR_EXCHANGE_DEAL_INPUT_INVALID,220002).
-define(ERR_EXCHANGE_DEAL_TIME_INVALID,220003).
-define(ERR_EXCHANGE_DEAL_ITEM_INPUT_NUM_ZERO,220004).
-define(ERR_EXCHANGE_DEAL_ITEM_INPUT_NOT_FOUND,220005).
-define(ERR_EXCHANGE_DEAL_BAG_POS_NOT_ENOUGH,220006).
-define(ERR_EXCHANGE_DEAL_BAG_NUM_NOT_ENOUGH,220007).


handle({_, ?EXCHANGE, ?EXCHANGE_ACTIVE_DEAL,_,_,_,_}=Info) ->
    %% 限时兑换
    do_active_deal(Info);
    
handle(Args) ->
    ?ERROR_MSG("~w, unknow args: ~w", [?MODULE,Args]),
    ok. 

hook_role_notify(RoleID,RoleLv) when RoleLv>=10->
    case common_config:is_debug() of
        true->  %%目的是Debug服可以热更新
            init_active_deal_times();
        _ ->
            ignore
    end,
    case get(?EXCHANGE_ACTIVE_OPEN_TIMES) of
        undefined->
            ignore;
        []->
            ignore;
        ExchangeActiveOpenTimes->
            NowSeconds = common_tool:now(),
            [ do_notify_role_active_deal(RoleID,RoleLv,ActiveId,StartTime,EndTime,NowSeconds) ||{ActiveId,StartTime,EndTime}<-ExchangeActiveOpenTimes ],
            ok
    end;
hook_role_notify(_RoleID,_)->
    ignore.

init(_MapId, _MapName) ->
    init_active_deal_times().

init_active_deal_times()->
    [ActiveList] = common_config_dyn:find(active_deal, active_list),
    
    ActiveOpenTimes = 
        lists:foldl(
          fun(E,AccIn)->
                  case E of
                      {ActiveId,StartTime,EndTime,_,_,_} ->
                          {ok,StartTimeStamp,EndTimeStamp} = get_active_time(StartTime,EndTime),
                          [ {ActiveId,StartTimeStamp,EndTimeStamp}|AccIn];
                      _ ->
                          AccIn
                  end
          end, [], ActiveList),
    put(?EXCHANGE_ACTIVE_OPEN_TIMES,ActiveOpenTimes),
    ok.

get_active_time({?OPENDAYS(StartDiff),StartTime},{?OPENDAYS(EndDiff),EndTime})->
    {OpenDate, _} = common_config:get_open_day(),
    StartDate = common_time:add_days(OpenDate,StartDiff),
    EndDate = common_time:add_days(OpenDate,EndDiff),
    
    StartTimeStamp = common_tool:datetime_to_seconds({StartDate,StartTime}),
    EndTimeStamp = common_tool:datetime_to_seconds({EndDate,EndTime}),
    {ok,StartTimeStamp,EndTimeStamp};
get_active_time(StartTime,EndTime)->
    StartTimeStamp = common_tool:datetime_to_seconds(StartTime),
    EndTimeStamp = common_tool:datetime_to_seconds(EndTime),
    {ok,StartTimeStamp,EndTimeStamp}.

loop(_MapId,NowSeconds) ->
    case get(?EXCHANGE_ACTIVE_OPEN_TIMES) of
        undefined->
            ignore;
        []->
            ignore;
        ExchangeActiveOpenTimes->
            [ do_notify_active_deal(ActiveId,StartTime,EndTime,NowSeconds) ||{ActiveId,StartTime,EndTime}<-ExchangeActiveOpenTimes ],
            ok
    end.

do_notify_role_active_deal(RoleID,RoleLv,ActiveId,StartTime,EndTime,NowSeconds)->
    if
        NowSeconds>=StartTime andalso EndTime>=NowSeconds->
            do_notify_role_active_deal_2(open,RoleID,RoleLv,ActiveId);
        true->
            ignore
    end.

do_notify_role_active_deal_2(open,RoleID,RoleLv,ActiveId)->
    [ActiveList] = common_config_dyn:find(active_deal, active_list),
    {_,_,_,MinLv,MaxLv,_} = lists:keyfind(ActiveId, 1, ActiveList),
    
    if
        RoleLv>=MinLv andalso MaxLv>=MaxLv->
            R2 = #m_exchange_active_notice_toc{active_id=ActiveId,action=?ACTION_OPEN},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_ACTIVE_NOTICE, R2);
        true ->
            ignore
    end.

do_notify_active_deal(ActiveId,StartTime,EndTime,NowSeconds)->
    if
        NowSeconds=:=StartTime->
            do_notify_active_deal_2(open,ActiveId);
        NowSeconds=:=EndTime->
            do_notify_active_deal_2(close,ActiveId);
        true->
            ignore
    end.

do_notify_active_deal_2(open,ActiveId)->
    [ActiveList] = common_config_dyn:find(active_deal, active_list),
    {_,_,_,MinLv,MaxLv,_} = lists:keyfind(ActiveId, 1, ActiveList),
    
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              case mod_map_role:get_role_attr(RoleID) of
                  {ok,#p_role_attr{level=RoleLv}} when RoleLv>=MinLv andalso MaxLv>=MaxLv->
                      R2 = #m_exchange_active_notice_toc{active_id=ActiveId,action=?ACTION_OPEN},
                      common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_ACTIVE_NOTICE, R2);
                  _ ->
                      ignore
              end
      end, RoleIdList);
do_notify_active_deal_2(close,ActiveId)->
    [ActiveList] = common_config_dyn:find(active_deal, active_list),
    {_,_,_,MinLv,MaxLv,_} = lists:keyfind(ActiveId, 1, ActiveList),
    
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              case mod_map_role:get_role_attr(RoleID) of
                  {ok,#p_role_attr{level=RoleLv}} when RoleLv>=MinLv andalso MaxLv>=MaxLv->
                      R2 = #m_exchange_active_notice_toc{active_id=ActiveId,action=?ACTION_CLOSE},
                      common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_ACTIVE_NOTICE, R2);
                  _ ->
                      ignore
              end
      end, RoleIdList).

do_active_deal({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_exchange_active_deal_tos{active_id=ActiveId,is_deal_all=IsDealAll} = DataIn,
    case catch check_do_active_deal(RoleID,DataIn) of
        {ok,true,ActiveDealItemList}->
            R2 = do_active_deal_one_2(RoleID,DataIn,ActiveDealItemList);
        {ok,false,ActiveDealItemList}->
            R2 = do_active_deal_one_2(RoleID,DataIn,ActiveDealItemList);
        {error,ErrCode,Reason}->
            R2 = #m_exchange_active_deal_toc{err_code=ErrCode,reason=Reason,active_id=ActiveId,is_deal_all=IsDealAll}
    end,
    ?UNICAST_TOC(R2).

assert_role_level(RoleLv,MinLv,MaxLv)->
    if
        RoleLv>=MinLv andalso MaxLv>=RoleLv ->
            next;
        true->
            ?THROW_ERR( ?ERR_EXCHANGE_DEAL_LV_LIMIT )
    end.

check_do_active_deal(RoleID,DataIn)->
    #m_exchange_active_deal_tos{active_id=ActiveId,is_deal_all=IsDealAll,item_type_id=ItemTypeId,deal_amount=DealAmount} = DataIn,
    [ActiveList] = common_config_dyn:find(active_deal, active_list),
    case lists:keyfind(ActiveId, 1, ActiveList) of
        {ActiveId,StartTime,EndTime,MinLv,MaxLv,ActiveDealItemList}->
            next;
        _ ->
            ActiveId=StartTime=EndTime=MinLv=MaxLv=ActiveDealItemList = null,
            ?THROW_ERR( ?ERR_EXCHANGE_DEAL_INPUT_INVALID )
    end,
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{level=RoleLv} = RoleAttr,
    assert_role_level(RoleLv,MinLv,MaxLv),
    
    case common_activity:check_activity_time(true,StartTime,EndTime) of
        {true,_}->
            next;
        _ ->
            ?THROW_ERR( ?ERR_EXCHANGE_DEAL_TIME_INVALID )
    end,
    case IsDealAll of
        true-> 
            next;
        _ ->
            if
                ItemTypeId =:=0 orelse DealAmount=:=0 ->
                    ?THROW_ERR( ?ERR_EXCHANGE_DEAL_ITEM_INPUT_NUM_ZERO );
                true->
                    case lists:keyfind(ItemTypeId, #r_active_deal.deduct_item_id, ActiveDealItemList) of
                        fasle->
                            ?THROW_ERR( ?ERR_EXCHANGE_DEAL_ITEM_INPUT_NOT_FOUND );
                        _ ->
                            next
                    end
            end
    end,
    {ok,IsDealAll,ActiveDealItemList}.

do_active_deal_one_2(RoleID,DataIn,ActiveDealItemList)->
    #m_exchange_active_deal_tos{active_id=ActiveId,is_deal_all=IsDealAll,item_type_id=ItemTypeId,deal_amount=DealAmount} = DataIn,
    #r_active_deal{deduct_item_id=DeductItemId,deduct_item_num=DeductItemNum,is_bind=IsBind,
                   award_prop_list=AwardPropListTmp} = lists:keyfind(ItemTypeId, #r_active_deal.deduct_item_id, ActiveDealItemList),

    %%先计算总共的奖励列表
    AwardAllPropList = [ E#p_reward_prop{prop_num=Num*DealAmount} ||#p_reward_prop{prop_num=Num}=E<- AwardPropListTmp ],
    
    TransFun = fun()-> 
                       DeductAllNum = DealAmount*DeductItemNum,
                       {ok, UpList, DelList} = t_decrease_goods(RoleID, DeductItemId, IsBind, DeductAllNum),
                       
                       AddGoodsList = lists:foldl(
                                        fun(E,AccIn)->
                                                {ok, AddList1} = common_bag2:t_reward_prop(RoleID, E, mission),
                                                lists:merge(AddList1, AccIn)
                                        end, [], AwardAllPropList),
                       {ok,UpList,DelList,AddGoodsList}
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,UpList,DelList,AddGoodsList} } ->
            lists:foreach(
              fun(E)-> 
                      #p_reward_prop{prop_id=PropTypeId,prop_num=PropNum} = E,
                      common_item_logger:log(RoleID, PropTypeId,PropNum,undefined,?LOG_ITEM_TYPE_EXCHANGE_ACTIVE_DEAL)
              end,AwardAllPropList),
            
            case DelList of
                []-> ignore;
                _ ->
                    common_misc:del_goods_notify({role, RoleID}, DelList)
            end,
            case UpList of
                []-> ignore;
                _ ->
                    common_misc:update_goods_notify({role, RoleID}, UpList)
            end,
            case AddGoodsList of
                []-> ignore;
                _ ->
                    common_misc:update_goods_notify({role, RoleID}, AddGoodsList)
            end,
            
            R2 = #m_exchange_active_deal_toc{active_id=ActiveId,is_deal_all=IsDealAll,item_type_id=ItemTypeId,deal_amount=DealAmount,
                                             new_props=AwardAllPropList};
        {atomic,{error,ErrCode,Reason} } ->
            R2 = #m_exchange_active_deal_toc{err_code=ErrCode,reason=Reason,active_id=ActiveId,is_deal_all=IsDealAll};
        {aborted, AbortErr}->
            {error,ErrCode,Reason} = parse_aborted_err(AbortErr,?ERR_OTHER_ERR),
            R2 = #m_exchange_active_deal_toc{err_code=ErrCode,reason=Reason,active_id=ActiveId,is_deal_all=IsDealAll}
    end,
    R2.


%%扣除道具
t_decrease_goods(RoleID, DeductItemId, IsBind, Num) when Num>0->
    mod_bag:decrease_goods_by_typeid(RoleID, [1, 2, 3], DeductItemId, Num, IsBind).

%%解析错误码
parse_aborted_err(AbortErr,BagNotEnoughPosError) when is_integer(BagNotEnoughPosError)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {bag_error,{not_enough_pos,_BagID}}->
            {error,?ERR_EXCHANGE_DEAL_BAG_POS_NOT_ENOUGH,undefined};
        {bag_error,num_not_enough}->
            {error,?ERR_EXCHANGE_DEAL_BAG_NUM_NOT_ENOUGH,undefined};
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.
