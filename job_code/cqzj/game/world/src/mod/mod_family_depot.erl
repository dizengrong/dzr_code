%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     家族仓库模块
%%%     注意:: 该模块属于mod_family的子模块，只能在mod_family中被调用！
%%% @end
%%% Created : 2011-03-01
%%%-------------------------------------------------------------------
-module(mod_family_depot).
-include("mgeew.hrl").
-include("mgeew_family.hrl").

%% API
-export([do_handle_info/1]).
-export([msg_tag/0]).
-export([delete_depot/1]).

msg_tag()->
    [fmldepot_getout_result].

-define(MAX_GETOUT_TIMES,3).
-define(LOGTYPE_PUTIN,1).
-define(LOGTYPE_GETOUT,2).

%% ====================================================================
%% API functions
%% ====================================================================

%%删除指定家族的家族仓库
delete_depot(FamilyID)->
    TransFun = fun()-> case db:read(?DB_FAMILY_ASSETS,FamilyID) of
                           []->
                               ignore;
                           [#r_family_assets{bag_num=Num}]->
                               lists:foreach(fun(BagID)->
                                                     DepotKey = {FamilyID,BagID},
                                                     db:delete(?DB_FAMILY_DEPOT,DepotKey,write)
                                             end, lists:seq(1, Num)),
                               db:delete(?DB_FAMILY_ASSETS,FamilyID,write)
                       end
               end,
    case db:transaction(TransFun) of
        {atomic,_}->
            ok;
        {aborted,Error}->
            ?ERROR_MSG("delete_depot error,FamilyID=~w,Error=~w,Stack=~w",[FamilyID,Error,erlang:get_stacktrace()]),
            {error,Error}
    end.

%%开通家族仓库的背包
do_handle_info({Unique, ?FMLDEPOT, ?FMLDEPOT_CREATE, Record, RoleID, _PID, Line}) ->
    do_fmldepot_create({Unique, ?FMLDEPOT, ?FMLDEPOT_CREATE, Record, RoleID, _PID, Line});
%%从家族仓库中取出物品
do_handle_info({Unique, ?FMLDEPOT, ?FMLDEPOT_GETOUT, Record, RoleID, _PID, Line}) ->
    do_fmldepot_getout({Unique, ?FMLDEPOT, ?FMLDEPOT_GETOUT, Record, RoleID, _PID, Line});
%%执行领取物品的结果（从Map节点返回）
do_handle_info({fmldepot_getout_result,IsSuccess,Request}) ->
    do_fmldepot_getout_result(IsSuccess,Request);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知信息", Info]).


%% ====================================================================
%% Internal functions
%% ====================================================================

%%@doc 执行领取物品的结果
do_fmldepot_getout_result(true,{RoleID,DepotRemainGoods})->
    RecMember = #m_fmldepot_update_goods_toc{update_type=?LOGTYPE_GETOUT,goods=[DepotRemainGoods]},
    common_family:broadcast_to_all_inmap_member_except(mod_family:get_family_id(), ?FMLDEPOT, ?FMLDEPOT_UPDATE_GOODS, RecMember, RoleID),
    ok;
do_fmldepot_getout_result(false,{RoleID})->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) of
        true->
            ignore;
        _ ->
            add_fmldepot_getout_times_today(RoleID,-1)  %%减少取出物品的次数
    end.


%%@interface 从家族仓库中取出物品
do_fmldepot_getout({Unique, Module, Method, Record, RoleID, _PID, Line})->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) of
        true->
            mgeer_role:absend(RoleID, {mod,mod_map_fmldepot,{map_fmldepot_getout,self(),RoleID,Record}});
        _ ->
            %%判断当天的操作次数
            CurTimes = get_fmldepot_getout_times_today(RoleID),
            if
                CurTimes>=?MAX_GETOUT_TIMES->
                    ?SEND_ERR_TOC(m_fmldepot_getout_toc,<<"族员每天只能从家族仓库取3次物品！">>);
                true ->
                    %%提前修改操作次数
                    add_fmldepot_getout_times_today(RoleID,1),
                    mgeer_role:absend(RoleID, {mod,mod_map_fmldepot,{map_fmldepot_getout,self(),RoleID,Record}})
            end
    end.

%%@interface 开通家族仓库的背包
do_fmldepot_create({Unique, Module, Method, Record, RoleID, _PID, Line})->
    #m_fmldepot_create_tos{bag_id=BagID} = Record,
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    #m_fmldepot_create_tos{bag_id=BagID} = Record,
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) of
        true->
            #p_family_info{family_id=FamilyID,money=FamilyMoney} = FamilyInfo,
            CurBagNum = get_family_depot_bag_num(FamilyID),
            if
                BagID=:=CurBagNum+1 ->
                    [#r_family_depot_config{need_family_money=DeductMoney}] = common_config_dyn:find(family_depot,BagID),
                    if
                DeductMoney>FamilyMoney ->
                    StrSilver = common_misc:format_silver(DeductMoney),
                    Msg = common_misc:format_lang(<<"家族资金不足，开通第~w个仓库需要家族资金~s！">>,[BagID,StrSilver]),
                    ?SEND_ERR_TOC(m_fmldepot_create_toc,Msg);
                true->
                    do_fmldepot_create_2(Unique, Module, Method, Record, RoleID, Line,FamilyID,DeductMoney)
            end;
                true->
                    ?SEND_ERR_TOC(m_fmldepot_create_toc,<<"家族仓库必须逐次开通">>)
            end;
        _ ->
            ?SEND_ERR_TOC(m_fmldepot_create_toc,<<"需要族长或者副族长开通该仓库之后才能使用！">>)
    end.

do_fmldepot_create_2(Unique, Module, Method, Record, RoleID, Line,FamilyID,DeductMoney)->
    #m_fmldepot_create_tos{bag_id=BagID} = Record,
    R1 = #r_family_assets{family_id=FamilyID,bag_num=BagID},
    db:dirty_write(?DB_FAMILY_ASSETS,R1),

    mod_family:do_add_money(-DeductMoney),

    R2 = #m_fmldepot_create_toc{succ=true,bag_id=BagID,return_self=true},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R2),

    R3 = #m_fmldepot_create_toc{succ=true,bag_id=BagID,return_self=false},
    mod_family:broadcast_to_all_members_except(Module, Method, R3, RoleID),
    ok.

%%@doc 获取家族仓库的背包数目
get_family_depot_bag_num(FamilyID)->
    case db:dirty_read(?DB_FAMILY_ASSETS,FamilyID) of
        []-> 1;
        [#r_family_assets{bag_num=BagNum}]->
            BagNum
    end.


add_fmldepot_getout_times_today(RoleID,PlusTime) when is_integer(PlusTime)->
    Today = date(),
    case db:dirty_read(?DB_ROLE_FAMILY_PARTTAKE,RoleID) of
        []->
            CurTimes = 0,
            R1 = #r_role_family_parttake{role_id=RoleID};
        [#r_role_family_parttake{fmldepot_getout_times=TmpTimes,fmldepot_getout_date=TmpDate} = R1]->
            case TmpDate =:= Today andalso is_integer(TmpTimes) of
                true->
                    CurTimes = TmpTimes;
                _ ->
                    CurTimes = 0
            end
    end,
    NewTime = if 
                  CurTimes+PlusTime<0 ->
                      0;
                  true->
                      CurTimes+PlusTime
              end,
    R2 = R1#r_role_family_parttake{fmldepot_getout_date=Today,fmldepot_getout_times=NewTime},
    db:dirty_write(?DB_ROLE_FAMILY_PARTTAKE,R2).

%%@doc 获取族员当天取出家族物品的次数
get_fmldepot_getout_times_today(RoleID)->
    case db:dirty_read(?DB_ROLE_FAMILY_PARTTAKE,RoleID) of
        []->
            0;
        [#r_role_family_parttake{fmldepot_getout_date=GetoutDate,fmldepot_getout_times=Times}]->
            Today = date(),
            case GetoutDate =:= Today of
                true->  
                    Times;
                _ ->
                    0
            end
    end.