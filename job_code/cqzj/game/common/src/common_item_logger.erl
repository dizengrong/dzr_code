%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录游戏中的道具使用日志
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(common_item_logger).


%% API
-export([log/3,log/4,log/5]).
-export([log_with_level/4]).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").

%% ====================================================================
%% API Functions
%% ====================================================================


%%% 注意：记录道具日志 ，必须是事务外调用该接口

%% 参数说明
%% @param RoleID::integer() 玩家ID 
%% @param Action::integer() 操作类型， 请参考 log_item_type.hrl中的定义
%% @param ItemTypeId::integer() 道具的类型ID
%% @param Amount::integer() 数量
%% @param EuqipId::integer() 如果是装备，则记录装备的唯一ID，否则为0
%% @param Color::integer() 颜色
%%     array(1=>'白色',2=>'绿色',3=>'蓝色',4=>'紫色',5=>'橙色',6=>'金色',);
%% @param Quality::integer() 品质
%%     array(1=>'普通',2=>'精良',3=>'优质',4=>'无暇',5=>'完美');
%%
%%  参考 map\include\refining.hrl


%% 参数是p_goods
log(RoleID,#p_goods{current_num=Num}=Goods,Action)->
    log(RoleID,Goods,Num,Action);
%% 参数是r_goods_create_info
log(RoleID,#r_goods_create_info{num=Num}=CreateInfo,Action)->
    log(RoleID,CreateInfo,Num,Action);
%% 参数是r_goods_create_info
log(RoleID,RewardProp,Action) when is_record(RewardProp,p_reward_prop)->
    #p_reward_prop{prop_id=PropID,prop_num=PropNum,bind=IsBind} = RewardProp, 
    log(RoleID,PropID,PropNum,IsBind,Action);
log(RoleID,GoodsList,Action) when is_list(GoodsList)->
    [log(RoleID,Goods,Action)||Goods<-GoodsList].


%%@doc 记录道具日志（指定道具的类型ID、数量等信息）
log(RoleID,ItemTypeID,Num,IsBind,Action) when is_integer(ItemTypeID) andalso is_integer(Num)->
    Goods = #r_goods_create_info{type_id=ItemTypeID,color=0,quality=0,bind=IsBind},
    log(RoleID,Goods,Num,Action ).


%% 参数是p_goods
log(RoleID,Goods,Num,Action)when is_record(Goods,p_goods) andalso is_integer(Num)
                                     andalso is_integer(RoleID)->
    {StartTime,EndTime} = get_log_time(),
    RoleLevel = get_role_level(RoleID),
    #p_goods{typeid=ItemTypeID,id=GoodsID,current_colour=Color,quality=Quality,bind=IsBind} = Goods,
    Record = #r_item_log{role_id=RoleID,role_level=RoleLevel,action=Action,item_id=ItemTypeID,amount=Num,equip_id=GoodsID,color=Color,
                         fineness=Quality,start_time=StartTime,end_time=EndTime,bind_type=IsBind},
    log(Record,Goods);
%% 参数是r_goods_create_info
log(RoleID,CreateInfo,Num,Action)when is_record(CreateInfo,r_goods_create_info) andalso is_integer(Num)
                                          andalso is_integer(RoleID)->
    {StartTime,EndTime} = get_log_time(),
    RoleLevel = get_role_level(RoleID),
    #r_goods_create_info{type_id=ItemTypeID,color=Color,quality=Quality,bind=IsBind} = CreateInfo,
    Record = #r_item_log{role_id=RoleID,role_level=RoleLevel,action=Action,item_id=ItemTypeID,amount=Num,equip_id=0,color=Color,
                         fineness=Quality,start_time=StartTime,end_time=EndTime,bind_type=IsBind},
    log(Record,CreateInfo).

%%@doc 记录道具日志（指定玩家等级，主要用于玩家注册成功时）
log_with_level(RoleID,RoleLevel,Goods,Action) when is_record(Goods,p_goods) andalso is_integer(RoleLevel)->
    {StartTime,EndTime} = get_log_time(),
    #p_goods{typeid=ItemTypeID,id=GoodsID,current_num=Num,current_colour=Color,quality=Quality,bind=IsBind} = Goods,
    Record = #r_item_log{role_id=RoleID,role_level=RoleLevel,action=Action,item_id=ItemTypeID,amount=Num,equip_id=GoodsID,color=Color,
                         fineness=Quality,start_time=StartTime,end_time=EndTime,bind_type=IsBind},
    log(Record,Goods).


%% ====================================================================
%% Local Functions
%% ====================================================================
transform_int(undefined)->
    0;
transform_int(Val)->
    Val.

transform_bool(undefined)->
    0;
transform_bool(true)->
    1;
transform_bool(ture)->
    1;
transform_bool(false)->
    2;
transform_bool(Val) when is_integer(Val)->
    Val.

%%@doc 记录道具日志
%% 参数是r_item_log,(p_goods or r_goods_create_info)
log(Record1,Goods) when is_record(Record1,r_item_log)->
    ?TRY_CATCH( log_2(Record1,Goods) ).
log_2(Record1,Goods) when is_record(Record1,r_item_log)->
    #r_item_log{equip_id=EquipID,color=Color,fineness=Quality,bind_type=BindType,role_id=RoleID} =  Record1,
    Record2 = Record1#r_item_log{equip_id=transform_int(EquipID),  
                                 color=transform_int(Color), 
                                 fineness=transform_int(Quality), 
                                 bind_type=transform_bool(BindType)},
    {RefiningIndex1,Type1}= if is_record(Goods,p_goods) ->
                                   #p_goods{refining_index=RefiningIndex,type=Type}=Goods,
                                   {RefiningIndex,Type};
                               is_record(Goods, r_goods_create_info) ->
                                   #r_goods_create_info{type=Type}=Goods,
                                   {0,Type};
                               true->{0,0}
                            end,
    Color1 = 
    if Color>=?COLOUR_WHITE ->
        case Type1 of
            ?TYPE_ITEM->
                [BaseInfo]=common_config_dyn:find_item(Record1#r_item_log.item_id),
                BaseInfo#p_item_base_info.colour;
            ?TYPE_STONE->
                [BaseInfo]=common_config_dyn:find_stone(Record1#r_item_log.item_id),
                BaseInfo#p_stone_base_info.colour;
            ?TYPE_EQUIP->
                Record2#r_item_log.color
        end;
       true->Record2#r_item_log.color
    end,
    
    
    if (Color1>= ?COLOUR_BLUE orelse RefiningIndex1 >=10) andalso Type1=:=3  ->
           global:send(mgeew_super_item_log_server,{log,Record2#r_item_log{color=Color1},Goods});
       true->
           common_item_log_server:insert_log(Record2#r_item_log{color=Color1})
    end,
    hook_activity_schedule:hook_get_equip(RoleID, {Record2#r_item_log.item_id, Color1}, Record2#r_item_log.action),
    case Type1 of
        ?TYPE_EQUIP ->
            case Record2#r_item_log.color of
                ?COLOUR_ORANGE ->
                    Fun = fun() ->
                        mod_achievement2:achievement_update_event(RoleID, 31006, Record1#r_item_log.item_id),
                        mod_achievement2:achievement_update_event(RoleID, 21005, Record1#r_item_log.item_id),
                        mod_achievement2:achievement_update_event(RoleID, 41003, Record1#r_item_log.item_id)
                    end,
                    mgeer_role:run(RoleID, Fun);
                _ -> ignore
            end;
        _ -> ignore
    end.

get_log_time()->
    %% 失效时间,暂时都不记录
    {common_tool:now(), 0}.


%%@doc 获取玩家等级
get_role_level(RoleID)->
    case (catch mod_map_role:get_role_attr(RoleID)) of
        {ok, #p_role_attr{level=Level}} ->
            Level;
        _ ->
            case common_misc:get_dirty_role_attr(RoleID) of
                {ok, #p_role_attr{level=Level}} ->
                    Level;
                {error,Reason}->
                    ?ERROR_MSG("写道具日志时获取玩家级别失败!RoleID=~wReason=~w,Stack=~w",[RoleID,Reason,erlang:get_stacktrace()]),
                    0
            end
    end.






