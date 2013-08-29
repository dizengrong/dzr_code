%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     处理赠送模块（例如新手时装的赠送）
%%% @end
%%% Created : 2011-02-22
%%%-------------------------------------------------------------------
-module(mod_present).

-include("mgeem.hrl").

%% API
-export([
         hook_role_online/1,
         handle/1,handle/2
         ]).

-define(PRESENT_ID_FASHION,10001).

%% ERROR_CODE
-define(ERR_PRESENT_REDBAG_NO_ACTIVITY_ACTIVE, 6803001). %% 当前奖励不可领取
-define(ERR_PRESENT_REDBAG_ALREADY_GET, 6803002). %% 今天已经领取了红包
-define(ERR_PRESENT_REDBAG_BAG_NOT_ENOUGH_PLACE, 6803003). %% 背包已满
-define(ERR_PRESENT_REDBAG_BAG_ERROR, 6803004). %% 背包错误
-define(ERR_PRESENT_REDBAG_LEVEL_NOT_MATCH, 6803005). %% 等级不符，无法领取奖励
-define(ERR_PRESENT_REDBAG_JINGJIE_NOT_MATCH, 6803006). %% 境界不符，无法领取奖励

-define(ERR_PRESENT_FETCH_NOT_TODAY, 680001). %% 今日不可以领取此赠送礼包
-define(ERR_PRESENT_TODAY_HAS_FETCHED, 680002). %% 您今日已经领取了此赠送礼包
-define(ERR_PRESENT_TODAY_TIME_IS_OUT, 680003). %% 今日赠送礼包的时间尚未开始
-define(ERR_PRESENT_INVALID_PRESENT_ID, 680004). %% 领取礼包的参数非法
-define(ERR_PRESENT_NO_GIFT, 680005). %% 该赠送礼包没有礼品
-define(ERR_PRESENT_BAG_NOT_ENOUGH_POS, 680006). %% 您的背包已满，赠送礼包失败
-define(ERR_PRESENT_BAG_ERROR, 680007). %% 背包发生错误，赠送礼包失败


%===================================================================
%%% API
%%%===================================================================
%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).


handle({_, ?PRESENT, ?PRESENT_GET,_,_,_,_}=Info) ->
    do_present_get(Info);
handle({_, ?PRESENT, ?PRESENT_REDBAG,_,_,_,_}=Info) ->
    do_present_redbag(Info);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


%%@doc 玩家上线的时候通知领取礼包
hook_role_online(RoleID)->
    case get_role_present_list(RoleID) of
        {ok,PresentInfoList} when length(PresentInfoList)>0 ->
            R2 = #m_present_notify_toc{present_list=PresentInfoList},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PRESENT, ?PRESENT_NOTIFY, R2);
        _Err ->
            ignore
    end.




%% ====================================================================
%% Internal functions
%% ====================================================================
 
%%@interface 获取赠送礼包
do_present_get({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_do_present_get(DataIn,RoleID) of
        {ok,PresentInfo}->
            do_present_get_2(Unique, Module, Method, RoleID, PID ,PresentInfo);
        {error,ErrCode,Reason}->
            R2 = #m_present_get_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

do_present_get_2(Unique, Module, Method, RoleID, PID ,PresentInfo)->
    #p_present_info{present_id=PresentId,prop_list=PropList} = PresentInfo,
    Today = erlang:date(),
    TransFun = fun()-> 
                       %%标志今日已领取该赠品
                       {ok,#r_role_map_ext{role_present=RolePresentInfo}=ExtInfo} = 
                           mod_map_role:get_role_map_ext_info(RoleID),
                       #r_role_present{present_list=OldPresentList} = RolePresentInfo,
                       case OldPresentList of
                           undefined->
                               NewPresentList = [{PresentId,Today}];
                           _ ->
                               NewPresentList = lists:keystore(PresentId, 1, OldPresentList, {PresentId,Today})
                       end,
                       RolePresentInfo2 = RolePresentInfo#r_role_present{role_id=RoleID,present_list=NewPresentList},
                       ExtInfo2 = ExtInfo#r_role_map_ext{role_present=RolePresentInfo2},
                       mod_map_role:t_set_role_map_ext_info(RoleID, ExtInfo2),
                       
                       common_bag2:t_reward_prop(RoleID, PropList)
               end,
    case common_transaction:t( TransFun ) of
        {atomic, {ok,AddGoodsList}} ->
            %%记录日志
            [ common_item_logger:log(RoleID, Prop, ?LOG_ITEM_TYPE_GET_SPEC_PRESENT) ||Prop<-PropList ],  
            common_misc:update_goods_notify({role,RoleID}, AddGoodsList),
            
            R2 = #m_present_get_toc{present_id=PresentId,present_info=PresentInfo},
            ?UNICAST_TOC(R2);
        {aborted, Error} ->
            {error,ErrCode,Reason} = parse_aborted_err(RoleID,Error),
            R2 = #m_present_get_toc{present_id=PresentId,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

check_do_present_get(DataIn,RoleID)->
    #m_present_get_tos{present_id=PresentId} = DataIn,
    Now = common_tool:now(),
    Today = erlang:date(),
    
    case get_role_present_info(RoleID) of
        {ok,RolePresentInfo}->
            next;
        _ -> 
            RolePresentInfo = null,
            ?THROW_SYS_ERR()
    end,
    case common_config_dyn:find(present,present_list) of
        [PresentList] ->
            case lists:keyfind(PresentId, 1, PresentList) of
                {PresentId,FetchDate,StartTime,EndTime} ->
                    if
                        FetchDate=:=Today ->
                            next;
                        true->
                            ?THROW_ERR( ?ERR_PRESENT_FETCH_NOT_TODAY )
                    end,
                    StartTimeStamp = common_tool:datetime_to_seconds({Today,StartTime}),
                    EndTimeStamp = common_tool:datetime_to_seconds({Today,EndTime}),
                    
                    case Now>=StartTimeStamp andalso EndTimeStamp>= Now of
                        true-> 
                            #r_role_present{present_list=FetchPresntList} = RolePresentInfo,
                            if
                                FetchPresntList=:=undefined->
                                    next;
                                true->
                                    case lists:keyfind(PresentId, 1, FetchPresntList) of
                                        {PresentId,Today}->   %%今天已经领取过不能再领
                                            ?THROW_ERR( ?ERR_PRESENT_TODAY_HAS_FETCHED );
                                        {PresentId,_}->       %%上周领取的可以再领
                                            next;
                                        false->               %%尚未领取
                                            next
                                    end
                            end;
                        _ -> ?THROW_ERR( ?ERR_PRESENT_TODAY_TIME_IS_OUT )
                    end;
                _ ->
                    ?THROW_ERR( ?ERR_PRESENT_INVALID_PRESENT_ID )
            end;
        _ -> 
            ?THROW_ERR( ?ERR_PRESENT_INVALID_PRESENT_ID )
    end,
    case mod_map_role:get_role_attr(RoleID) of
        {ok,#p_role_attr{level=Level}}->
            next;
        _ ->
            Level = null,
            ?THROW_SYS_ERR()
    end,
    case common_config_dyn:find(present,{present_gift,PresentId}) of
        [ConfGiftList] ->
            case get_level_present_gift(Level,ConfGiftList) of
                {ok,#r_present_gift{gift_list=PropList}}->
                    PresentInfo = #p_present_info{present_id=PresentId,prop_list=PropList},
                    {ok,PresentInfo};
                _ ->
                    ?THROW_ERR( ?ERR_PRESENT_NO_GIFT )
            end;
        _ -> 
            ?THROW_ERR( ?ERR_PRESENT_NO_GIFT )
    end.

%%@doc 获取玩家的礼品数据信息
get_role_present_info(RoleID)->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{role_present=RolePresentInfo}} when is_record(RolePresentInfo,r_role_present)->
            {ok,RolePresentInfo};
        _ ->
            {error,not_found}
    end.

%%@doc 获取可以领取的礼品列表
%%@return {ok,PresentInfoList} | {error,not_found}
get_role_present_list(RoleID)->
    case get_present_id_list(RoleID) of
        []->
            {error,not_found};
        PresentIdList when length(PresentIdList)>0->
            case mod_map_role:get_role_attr(RoleID) of
                {ok,#p_role_attr{level=Level}}->
                    get_role_present_list_2(PresentIdList,Level,[]);
                _ ->
                    {error,not_found}
            end
    end.


%%@return {ok,PresentInfoList}
get_role_present_list_2([],_,AccList)->
    {ok,AccList};
get_role_present_list_2([PresentId|T],Level,AccList)->
    PresentGiftKey = {present_gift,PresentId},
    case common_config_dyn:find(present,PresentGiftKey) of
        [ConfGiftList] ->
            case get_level_present_gift(Level,ConfGiftList) of
                {ok,#r_present_gift{gift_list=PropList}}->
                    PresentInfo = #p_present_info{present_id=PresentId,prop_list=PropList},
                    get_role_present_list_2(T,Level,[PresentInfo|AccList]);
                _ ->
                    get_role_present_list_2(T,Level,AccList)
            end;
        _ -> 
            get_role_present_list_2(T,Level,AccList)
    end.

%%获取匹配境界的礼包
get_level_present_gift(_,[])->
    {error,not_found};
get_level_present_gift(Level,[H|T])->
    #r_present_gift{min_level=MinLevel,max_level=MaxLevel} = H,
    case Level>=MinLevel andalso MaxLevel>= Level of
        true-> {ok,H};
        _ ->
            get_level_present_gift(Level,T)
    end.

get_present_id_list(RoleID)->
    case get_role_present_info(RoleID) of
        {ok,RolePresentInfo}->
            case common_config_dyn:find(present,present_list) of
                [PresentList] ->
                    get_present_id_list_2(RolePresentInfo,PresentList);
                _ -> []
            end;
        _ -> []
    end.

get_present_id_list_2(RolePresentInfo,PresentList)->
    Now = common_tool:now(),
    Today = erlang:date(),
    lists:foldl(
      fun(E,AccIn)-> 
              {PresentId,FetchDate,StartTime,EndTime} = E,
              case FetchDate of
                  Today->
                      StartTimeStamp = common_tool:datetime_to_seconds({Today,StartTime}),
                      EndTimeStamp = common_tool:datetime_to_seconds({Today,EndTime}),
                      case Now>=StartTimeStamp andalso EndTimeStamp>= Now of
                          true-> 
                              #r_role_present{present_list=FetchPresntList} = RolePresentInfo,
                              if
                                  FetchPresntList=:=undefined->
                                      [PresentId|AccIn];
                                  true->
                                      case lists:keyfind(PresentId, 1, FetchPresntList) of
                                          {PresentId,Today}->   %%今天已经领取过不能再领
                                              AccIn;
                                          {PresentId,_}->       %%上周领取的可以再领
                                              [PresentId|AccIn];
                                          false->               %%尚未领取
                                              [PresentId|AccIn]
                                      end
                              end;
                          _ -> 
                               AccIn
                      end;
                  _ -> AccIn
              end
      end, [], PresentList).


%%@interface 领取红包
do_present_redbag({Unique, Module, Method, _DataIn, RoleID, PID, Line})->
    case catch check_present_redbag(RoleID) of
        {error,ErrCode,Reason}->
            R2 = #m_present_redbag_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2);
        {ok, ActivityID, RewardItemList} ->
            do_send_redbag(Line, RoleID, Unique, Module, Method, PID, ActivityID, RewardItemList)
    end,
    ok.

check_present_redbag(RoleID) ->
    ActivityID = get_current_active_redbag_activity_id(),
    case db:dirty_read(?DB_ROLE_PRESENT_REDBAG,{RoleID, ActivityID}) of
        [] ->
            ok;
        [#r_role_present_redbag{last_time=LastTime}] ->
            case date() =:= common_time:time_to_date(LastTime) of
                true ->
                   ?THROW_ERR(?ERR_PRESENT_REDBAG_ALREADY_GET);
                false ->
                    next
            end
    end,
    
    Rewards = 
        case common_config_dyn:find(present_redbag, ActivityID) of
            [] ->
                ?THROW_SYS_ERR();
            [RewardsT] ->
                RewardsT
        end,
    RewardItemList = check_redbag_condition(RoleID, Rewards),
    {ok, ActivityID, RewardItemList}.

get_current_active_redbag_activity_id() ->
    RedBagList = 
        case common_config_dyn:find(present_redbag, redbag_list) of
            [] ->
                ?THROW_SYS_ERR();
            [Config] ->
                Config
        end,
    Now = common_tool:now(),
    ActivityID = 
        lists:foldl(
          fun({ActivityID, StartDateTime, EndDateTime}, Acc) ->
                  StartTimeStamp = common_tool:datetime_to_seconds(StartDateTime),
                  EndTimeStamp = common_tool:datetime_to_seconds(EndDateTime),
                  if Now >= StartTimeStamp andalso EndTimeStamp >= Now ->
                         ActivityID;
                     true ->
                         Acc
                  end
          end, undefined, RedBagList),
    if ActivityID =:= undefined ->
           ?THROW_ERR(?ERR_PRESENT_REDBAG_NO_ACTIVITY_ACTIVE);
       true ->
           ok
    end,
    ActivityID.

check_redbag_condition(RoleID, {NeedCondition, RewardItemList}) ->
    {ok, #p_role_attr{level=Level, jingjie=Jingjie}} = mod_map_role:get_role_attr(RoleID),
    case NeedCondition of
        level ->
            case get_redbag_reward_items(Level, RewardItemList) of
                [] ->
                    ?THROW_ERR(?ERR_PRESENT_REDBAG_LEVEL_NOT_MATCH);
                Rewards ->
                    Rewards
            end;
        jingjie ->
            case get_redbag_reward_items(Jingjie, RewardItemList) of
                [] ->
                    ?THROW_ERR(?ERR_PRESENT_REDBAG_JINGJIE_NOT_MATCH);
                Rewards ->
                    Rewards
            end;
        _ ->
            ?THROW_SYS_ERR()
    end.

get_redbag_reward_items(RoleValue, Rewards) ->
    lists:foldl(
      fun({Min, Max, RewardItemList}, Acc) -> 
              if RoleValue >= Min andalso Max >= RoleValue ->
                     RewardItemList;
                 true ->
                     Acc
              end
      end, [], Rewards).

do_send_redbag(_Line, RoleID, Unique, Module, Method, PID, ActivityId, RewardItemList) ->
    case db:transaction( 
           fun() ->
                   db:write(?DB_ROLE_PRESENT_REDBAG, #r_role_present_redbag{role_activity_key={RoleID, ActivityId}, last_time=common_tool:now()}, write),
                   common_bag2:t_reward_prop(RoleID, RewardItemList, present)
           end) of
        {atomic, {ok, AddGoodsList}} ->
            lists:foreach(
              fun(RewardItem) ->
                      #p_reward_prop{prop_id=ItemTypeID, bind=IsBind, prop_num=Num} = RewardItem,
                      common_item_logger:log(RoleID, ItemTypeID, Num, IsBind, ?LOG_ITEM_TYPE_GAIN_REWARD_ITEM_FROM_REDBAG)
              end, RewardItemList),
            common_misc:update_goods_notify({role, RoleID}, AddGoodsList),
            ?UNICAST_TOC(#m_present_redbag_toc{});
        {aborted, {throw, {bag_error,{not_enough_pos,_BagID}}}} ->
            R2 = #m_present_redbag_toc{err_code=?ERR_PRESENT_REDBAG_BAG_NOT_ENOUGH_PLACE},
            ?UNICAST_TOC(R2);
        {aborted, {throw, {bag_error, Reason}}} ->
            ?ERROR_MSG("春节红包赠送错误，{bag_error, Reason=~w}",[Reason]),
            R2 = #m_present_redbag_toc{err_code=?ERR_PRESENT_REDBAG_BAG_ERROR},
            ?UNICAST_TOC(R2);
        {aborted, Error} ->
            ?ERROR_MSG("春节红包赠送错误，Error=~w",[Error]),
            R2 = #m_present_redbag_toc{err_code=?ERR_SYS_ERR},
            ?UNICAST_TOC(R2)
    end.
  


%%解析错误码
parse_aborted_err(RoleID,AbortErr)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {bag_error,{not_enough_pos,_BagID}}->
            {error,?ERR_PRESENT_BAG_NOT_ENOUGH_POS,undefined};
        {bag_error,BagError}->
            ?ERROR_MSG_STACK( "RoleID=~w,BagError=~w",[BagError] ),
            {error,?ERR_PRESENT_BAG_ERROR,undefined};
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        _ ->
            ?ERROR_MSG("RoleID=~w, aborted,AbortErr=~w,stack=~w",[RoleID,AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.








