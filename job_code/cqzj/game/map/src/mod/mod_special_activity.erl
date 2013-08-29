%% Author: ming
%% Created: 2011-7-26
%% Description: TODO: Add description to mod_special_activity
-module(mod_special_activity).
-include("mgeem.hrl").
-include("activity.hrl").
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handle/1]).

%% ==========================================================================
%% API Functions
%% =========================================================================


handle({Unique, Module, ?SPECIAL_ACTIVITY_STAT, DataIn, RoleID, PID,Line})->
    do_stat_activity({Unique, Module, ?SPECIAL_ACTIVITY_STAT, DataIn, RoleID, PID,Line});

  %% 活动编辑器活动
handle({get_prize,Msg})->
    get_prize(Msg);
handle(Args) ->
    ?ERROR_MSG("~w, unknow args: ~w", [?MODULE,Args]),
    ok. 
%% =======================================================================
%% Local Functions
%% =======================================================================
do_stat_activity({Unique, Module, ?SPECIAL_ACTIVITY_STAT, DataIn, RoleID, _PID,Line})->
    #m_special_activity_stat_tos{activity_key=ActivityKey,goods_id=GoodsID}=DataIn,
    case catch do_check_goods(ActivityKey,GoodsID,RoleID) of
        {ok,Info}->
            return_handle_result({stat_other,{ActivityKey,{RoleID,Info}}});
        {error,Reason}->
            DataRecord = #m_special_activity_stat_toc{succ=false, reason=Reason},
            common_misc:unicast(Line, RoleID, Unique, Module, ?SPECIAL_ACTIVITY_STAT, DataRecord)
    end.

do_check_goods(ActivityKey,GoodsID,RoleID)->
    {ok,Config}=common_activity:get_config(ActivityKey,other_activity),
    {ok,_,_} = common_activity:check_config_time(other_activity,activity,Config),
    get_stat_info(ActivityKey,GoodsID,RoleID).

get_stat_info(?OTHER_EQUIP_REINFORCE_KEY,EquipID,RoleID)->
    get_equip(RoleID,EquipID);
get_stat_info(?OTHER_EQUIP_STONE_KEY,EquipID,RoleID)->
    get_equip(RoleID,EquipID);
get_stat_info(?OTHER_EQUIP_SCORE_KEY,EquipID,RoleID)->
    get_equip(RoleID,EquipID);
get_stat_info(?OTHER_EQUIP_HOLE_KEY,EquipID,RoleID)->
    get_equip(RoleID,EquipID);
get_stat_info(?OTHER_PET_UNDERSTANDING_KEY,EquipID,RoleID)->
    get_pet(RoleID,EquipID);
get_stat_info(?OTHER_PET_SKILL_COUNT_KEY,EquipID,RoleID)->
    get_pet(RoleID,EquipID);
get_stat_info(?OTHER_PET_APTITUDE_KEY,EquipID,RoleID)->
    get_pet(RoleID,EquipID);
get_stat_info(?OTHER_ROLE_LEVEL_KEY,_EquipID,RoleID)->
    get_level(RoleID).

get_equip(RoleID,EquipID)->
    case mod_bag:get_goods_by_id(RoleID, EquipID) of
        {ok, _GoodsInfo} ->{ok, _GoodsInfo};
        {error, _} ->
            case mod_goods:get_equip_by_id(RoleID, EquipID) of
                {ok, _GoodsInfo}->{ok,_GoodsInfo};
                _->{error,"找不到该物品"}
            end
    end.


get_pet(_RoleID,_PetID)->
    ignore.

get_level(_RoleID)->
    ignore.
%% ==========活动编辑器编辑的活动===============
get_prize({ActivityKey,ConditionID,RoleID,GoodsList})->
    case db:transaction(
           fun()->
                   {ok,GoodsList1} = mod_bag:create_goods_by_p_goods(RoleID,GoodsList),
                   GoodsList1
           end) 
        of
        {atomic,NewGoodsList}->
            %% 写道具使用记录
            lists:foreach(
              fun(Goods) ->
                      #p_goods{roleid=RoleID,current_num=Num}=Goods,
                      common_item_logger:log(RoleID,Goods,Num,?LOG_ITEM_TYPE_SPECIAL_ACTIVITY_HUO_DE)
              end,GoodsList),
             %% 通知前端
            %%R = #m_special_activity_get_prize_toc{succ=true},
            %%common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SPECIAL_ACTIVITY,?SPECIAL_ACTIVITY_GET_PRIZE,R),
            common_misc:new_goods_notify({role,RoleID},NewGoodsList),
            %% 通知世界节点
            return_handle_result({map_get_prize,{succ,RoleID,ActivityKey,ConditionID}});
        {aborted,Error}->
            case Error of
                {bag_error,{not_enough_pos,_BagID}}->
                    Reason = "背包空间不足";
                _ -> 
                    Reason = "系统错误"
            end,
            ?ERROR_MSG("获取物品错误:~w~n",[Error]),
            R=#m_special_activity_get_prize_toc{succ=false,reason=Reason},
            common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SPECIAL_ACTIVITY,?SPECIAL_ACTIVITY_GET_PRIZE,R),
            return_handle_result({map_get_prize,{fail,RoleID,ActivityKey,ConditionID}})
    end.

%%@doc 通知地图结果
return_handle_result(Info)->
    case global:whereis_name(mgeew_activity_server) of
        undefined->
            %%==================找不到  悲剧了
            ?ERROR_MSG("mgeew_activity_server server down Info:~w~n",[Info]);
        Pid->
            erlang:send(Pid,Info)
    end.
