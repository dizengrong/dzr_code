%% Author: chixiaosheng
%% Created: 2011-4-5
%% Description: 神兵图鉴兑换模型，判断是否集齐图鉴（一）（二）（三）
-module(mission_model_11, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  

%%
%% Exported Functions
%%
-export([
         auth_accept/1,
         auth_show/1,
         do/2,
         cancel/2,
         listener_trigger/3,
         init_pinfo/1]).

-define(ITEM_ID_LIST,[10900070,10900071,10900072]).

%%
%% API Functions
%%
%%@doc 验证是否可接
auth_accept(_PInfo) -> 
    mod_mission_auth:auth_accept(RoleID, MissionBaseInfo).

%%@doc 验证是否可以出现在任务列表
auth_show(_PInfo) -> 
    mod_mission_auth:auth_show(RoleID, MissionBaseInfo).

-define(RETURN_ABORT_RESULT(R2),
        mod_mission_unicast:r_unicast(RoleID),
        mod_mission_misc:r_trans_func(RoleID),
        {aborted,R2}
       ).

%%@doc 执行任务 接-做-交
do(PInfo, RequestRecord) ->
    TransFun = fun() ->
                       assert_deduct_items(),
                       mission_model_common:common_do(RoleID, MissionID,MissionBaseInfo,RequestRecord, PInfo)
               end,
    case common_transaction:transaction(TransFun) of
        {atomic,Result}->
            mod_mission_unicast:c_unicast(RoleID),
            mod_mission_misc:c_trans_func(RoleID),
            {atomic, Result};
        {aborted,{throw,{bag_error,{not_enough_pos,_BagID}}=R2}}->
            ?RETURN_ABORT_RESULT(R2);
        {aborted,{bag_error,{not_enough_pos,_BagID}}=R3}->
            ?RETURN_ABORT_RESULT(R3);
        {aborted,{man, _ReasonCode, _ReasonCodeData}=R4}->
            ?RETURN_ABORT_RESULT(R4);
        {aborted,Result}->
            ?ERROR_MSG("transaction aborted,Result=~w,PInfo=~w,MissionBaseInfo=~w",[Result,PInfo,MissionBaseInfo]),
            ?RETURN_ABORT_RESULT(Result)
    end.

%%确定背包中存在 神兵图鉴三个道具
assert_deduct_items()->
    {UpdateList,DeleteList} = 
        lists:foldl(fun(ItemTypeID,{UpListAcc,DelListAcc}=AccIn)-> 
                            case mod_bag:check_inbag_by_typeid(RoleID,ItemTypeID) of
                                {ok,_}->
                                    {ok,UpList,DelList} = mod_bag:decrease_goods_by_typeid(RoleID,ItemTypeID,1),
                                    { lists:merge(UpList,UpListAcc),lists:merge(DelList,DelListAcc)};
                                _R ->
                                    throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_DEL_PROP, [ItemTypeID]}),
                                    AccIn
                            end
                    end, {[],[]}, ?ITEM_ID_LIST),
    Func ={func,fun()-> 
                        common_misc:del_goods_notify({role, RoleID}, DeleteList),
                        common_misc:update_goods_notify({role, RoleID}, UpdateList)
           end},
    mod_mission_misc:push_trans_func(RoleID,Func),
    ok.



%%@doc 取消任务
cancel(PInfo, RequestRecord) ->
    TransFun = fun() ->
                       mission_model_common:common_cancel(RoleID, MissionID, MissionBaseInfo,RequestRecord, PInfo)
               end,
    ?DO_TRANS_FUN( TransFun ).

%%@doc 侦听器触发
listener_trigger(_ListenerData, _PInfo,_TriggerParam) -> ok.

%%@doc 初始化任务pinfo
%%@return #p_mission_info{} | false
init_pinfo(OldPInfo) -> 
    NewPInfo = mission_model_common:init_pinfo(RoleID, OldPInfo, MissionBaseInfo),
    CurrentStatus = NewPInfo#p_mission_info.current_model_status,
    if
        CurrentStatus =/= ?MISSION_MODEL_STATUS_FIRST ->
            NewPInfo;
        true ->
            case auth_show(NewPInfo) of
                true->
                    NewPInfo;
                _ ->
                    false
           end
    end.