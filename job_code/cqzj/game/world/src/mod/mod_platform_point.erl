%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     平台点数赠送礼券的接口
%%% @end
%%% Created : 2011-03-01
%%%-------------------------------------------------------------------
-module(mod_platform_point).
-include("mgeew.hrl").

-export([
         send_succ_letter/3,
         give_bind_gold/6
        ]).

-define(ADD_GOLD_BY_PLATFORM_POINT,add_gold_by_platform_point).


give_bind_gold(GiveID, AccountName, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour})->
    ?ERROR_MSG("收到平台赠送礼券请求,GiveID=~p,AccountName=~ts,Params=~w", [GiveID, AccountName, {GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour}}]),
    
    BinAccountName = common_tool:to_binary(AccountName),
    TransFun = fun() -> 
                       t_give_bind_gold( GiveID, BinAccountName, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour} ) 
               end,
    case db:transaction( TransFun ) of
        {atomic, ok} ->
            ok;
        {aborted, Reason} ->
            case erlang:is_binary(Reason) of
                true ->
                    ?ERROR_MSG("~ts:~w", ["平台赠送礼券", common_tool:to_list(Reason)]);
                false ->
                    ?ERROR_MSG("~ts:~w", ["平台赠送礼券", Reason])
            end,
            case Reason of
                ?_LANG_PAY_DUPLICATED ->
                    used;
                ?_LANG_PAY_ACCOUNT_NOT_FOUND->
                    not_found;
                _ ->
                    error
            end
    end.
t_give_bind_gold( GiveID, AccountName, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour} )->
    %%判断是否该订单已经处理过
    case db:match_object(?DB_PLATFORM_POINT_LOG, #r_platform_point_log{give_id=GiveID, _='_'}, write) of
        [] ->
            case db:match_object(?DB_ROLE_BASE_P, #p_role_base{account_name=AccountName, _='_'}, write) of
                [] ->
                    db:abort(?_LANG_PAY_ACCOUNT_NOT_FOUND);
                RoleBaseList ->
                    case RoleBaseList of
                        [RoleBase] ->  next;
                        _ -> {ok,RoleBase} = get_main_role_base(RoleBaseList)
                    end,
                    t_give_bind_gold_2(GiveID, AccountName, RoleBase, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour})
            end;
        _ ->
            db:abort(?_LANG_PAY_DUPLICATED)
    end.


t_give_bind_gold_2(GiveID, AccountName, RoleBase, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour})->
    #p_role_base{role_id=RoleID, role_name=RoleName} = RoleBase,
    [#p_role_attr{gold_bind=OldBindGold,level=RoleLevel}=RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID),
    RLog = #r_platform_point_log{give_id=GiveID, role_id=RoleID, role_name=RoleName, account_name=AccountName, give_time=GiveTime,
                                give_bind_gold=BindGold, active_point=ActivePoint, year=Year, month=Month, day=Day, hour=Hour, role_level=RoleLevel},
    
    db:write(?DB_PLATFORM_POINT_LOG, RLog, write),
    case is_role_online(RoleID) of
        true ->
            ?ERROR_MSG("玩家离线平台赠送礼券：~w",[{GiveID, RoleID, BindGold, OldBindGold, {Year, Month, Day, Hour}}]),
            t_do_add_gold_offline(RoleAttr, OldBindGold,BindGold ),
            common_consume_logger:gain_gold({RoleID, BindGold, 0, ?GAIN_TYPE_GOLD_FROM_PLATFORM_POINT, ""}),
            send_succ_letter(RoleID,RoleName,BindGold);
        false ->
            ?ERROR_MSG("玩家在线平台赠送礼券：~w",[{GiveID, RoleID, BindGold, OldBindGold, {Year, Month, Day, Hour}}]),
            db:write(?DB_ROLE_ATTR, RoleAttr, write),
            t_do_add_gold_online(GiveID, RoleID, BindGold)
    end,    
    ok.

is_role_online(RoleID)->
    db:read(?DB_USER_ONLINE, RoleID, read) =:= [] orelse common_misc:is_role_online2(RoleID) =:= false.
 

send_succ_letter(RoleID,RoleName,BindGold) ->
    Content = common_letter:create_temp(?PLATFORM_POINT_GIVE_GOLD_SUCCESS_LETTER, [RoleName, BindGold]),
    common_letter:sys2p(RoleID,Content,?_LANG_LEETER_PLATFORM_POINT_SUCCESS,14),
    ok.



%% 在线更新元宝
t_do_add_gold_online(GiveID, RoleID, BindGold)->
    AddMoneyList = [{gold_bind, BindGold,?GAIN_TYPE_GOLD_FROM_PLATFORM_POINT,""}],
    %%同时发送钱币/元宝更新的通知
    common_role_money:add(RoleID, AddMoneyList,{?ADD_GOLD_BY_PLATFORM_POINT,GiveID,BindGold},
                          {?ADD_GOLD_BY_PLATFORM_POINT,GiveID,BindGold}, true).

%% 离线更新元宝
t_do_add_gold_offline(RoleAttr,OldBindGold,BindGold)->
    NewRoleAttr = RoleAttr#p_role_attr{gold_bind=OldBindGold + BindGold},
    db:write(?DB_ROLE_ATTR, NewRoleAttr, write).



%%@doc 获取多个角色中的主角色
get_main_role_base(RoleBaseList) when is_list(RoleBaseList)->
    NewRoleBaseList = [ {RoleID,CreateTime,RoleBase}||#p_role_base{role_id=RoleID,create_time=CreateTime}=RoleBase<-RoleBaseList ],
    RoleLvList = lists:foldl(
                   fun(E,AccIn)->
                           {RoleID,CreateTime,RoleBase} = E,
                           case db:dirty_read(?DB_ROLE_ATTR,RoleID) of
                               [#p_role_attr{level=Level}] ->
                                   [{RoleID,Level,CreateTime,RoleBase}|AccIn];
                               _ ->
                                   AccIn
                           end
                   end, [], NewRoleBaseList),
    [H|T] = RoleLvList,
    get_main_role_base_2(H,T).

get_main_role_base_2(E,[])->
    {_RoleID,_v,_CreateTime,RoleBase} = E,
    {ok,RoleBase};
get_main_role_base_2(E,[H|T])->
    {_,LvE,CreateTimeE,_} = E,
    {_,LvH,CreateTimeH,_} = H,
    if
        LvE>LvH->
            get_main_role_base_2(E,T);
        LvH>LvE->
            get_main_role_base_2(H,T);
        true->
            if
                CreateTimeE>CreateTimeH->
                    get_main_role_base_2(E,T);
                true->
                    get_main_role_base_2(H,T)
            end
    end.   

