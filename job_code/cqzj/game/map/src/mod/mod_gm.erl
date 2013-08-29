%% Author: lenovo
%% Created: 2010-12-24
%% Description: TODO: Add description to mod_gm
-module(mod_gm).
-include("../../map/include/mission.hrl").

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([get_pre_id_list/2, handle/2]).

%%
%% API Functions
%%

handle(Info, State) ->
    ?DEBUG("~ts:~w", ["GM消息", Info]),
    do_handle(Info, State).

do_handle({get_role_attr_opt, RoleID, ReceiverPID,ReplyMsgTag}, _State) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{active_points=ActivePt} = RoleAttr,
    ReceiverPID ! {ReplyMsgTag,{ok,ActivePt}};

do_handle({set_role_attr_opt, RoleID, OptionList}, _State) ->
    TransFun = fun()-> 
                       {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
                       NewRoleAttr =
                           lists:foldl(fun({ElementName, Value}, RoleAttrT) ->
                                               internal_set_role_attr(RoleID, RoleAttrT, ElementName, Value)
                                       end, RoleAttr, OptionList),
                       mod_map_role:set_role_attr(RoleID, NewRoleAttr),
                       ok
               end,

    case common_transaction:transaction(TransFun) of
        {atomic, ok}->
            R = #m_role2_attr_change_toc{roleid=RoleID, changes=common_role:get_attr_change_list(OptionList)},
            Info = {role_msg, ?ROLE2, ?ROLE2_ATTR_CHANGE, R},
            common_misc:chat_cast_role_router(RoleID, Info);
        {aborted, Error} ->
            ?ERROR_MSG("Error=~w",[Error]),
            error
    end;

do_handle({set_role_base_opt, RoleID, OptionList}, _State) ->
    TransFun = fun()-> 
                   {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
                   NewRoleBase =
                     lists:foldl(fun({ElementName, Value}, RoleBaseT) ->
                                     internal_set_role_base(RoleID, RoleBaseT, ElementName, Value)
                                 end, RoleBase, OptionList),
                   mod_map_role:set_role_base(RoleID, NewRoleBase),
                   {ok,NewRoleBase}
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,NewRoleBase}}->
            DataRecord = #m_role2_base_reload_toc{role_base=NewRoleBase},
            Info = {role_msg, ?ROLE2, ?ROLE2_BASE_RELOAD, DataRecord},
            common_misc:chat_cast_role_router(RoleID, Info);
        {aborted,Error} ->
            ?ERROR_MSG("Error=~w",[Error]),
            error
    end;
%%GM设置玩家的培养属性，便于测试
do_handle({set_role_grow, RoleID, Index,Val}, _State) ->
    TransFun = fun()-> 
                       t_do_set_role_grow(RoleID,Index,Val)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok, OldRoleGrow, NewRoleGrow}}->
            mod_role_grow:update_role_base(RoleID, OldRoleGrow, NewRoleGrow);
        {aborted,Error} ->
            ?ERROR_MSG("Error=~w",[Error]),
            error
    end;

do_handle({set_role_tower_fb_info, RoleID, Index, Val}, _State) ->
    do_set_role_tower_fb_info(RoleID,Index,Val);

%%设置家族繁荣度
do_handle({family_add_active_points, RoleID, Value}, _State) ->
    {ok, #p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),
    common_family:info(FamilyID,{gm_add_active_points, Value});


%%进入家族地图
do_handle({family_enable_map, RoleID}, _State) ->
    {ok, #p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),
    common_family:info(FamilyID,{gm_enable_map, RoleID});

%%增加宗族资金
do_handle({family_add_money, RoleID, Value}, _State) ->
    {ok, #p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),
    common_family:info(FamilyID,{gm_add_money, Value});

%%直接宗族升级
do_handle({family_uplevel,RoleID}, _State) ->
    {ok, #p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),
    common_family:info(FamilyID,{gm_uplevel,RoleID});

%%设置完成任务
do_handle({gm_set_mission, RoleID, MissID}, _State) ->
    gm_set_mission(RoleID,MissID);

%%设置等级
do_handle({set_level, RoleID, Level}, _State) ->
    case common_config_dyn:find(level, Level + 1) of
        [#p_level_exp{exp = NextLevelExp}] ->
            {ok, OldAttr} = mod_map_role:get_role_attr(RoleID),
            {ok, OldRoleBase} = mod_map_role:get_role_base(RoleID),
            OldExp = OldAttr#p_role_attr.exp,
            OldLevel = OldAttr#p_role_attr.level,
            _Increment = NextLevelExp - OldExp,
            mgeer_role:send(RoleID, {mod_map_role, 
                {gm_level_up, OldAttr, OldRoleBase, OldLevel, Level, 0}
            });
        _ ->
            ignore
    end;

%%设置初出茅庐境界
do_handle({t4_clear_bag,RoleID}, _State) ->
    TransFun = fun()-> 
                       {ok,AllGoodsList} = mod_bag:get_bag_goods_list(RoleID),
                       GoodsIDList = [Id||#p_goods{id=Id}<-AllGoodsList],
                       mod_bag:delete_goods(RoleID, GoodsIDList),
                       {ok,AllGoodsList}
               end,
    case common_transaction:t( TransFun ) of
        {atomic, {ok,AllGoodsList}} ->
            common_misc:del_goods_notify({role, RoleID}, AllGoodsList);
        {aborted, Error} ->
            ?ERROR_MSG("set_jingjie_info, error: ~w", [Error]),
            error
    end;

%%重新清零境界副本的次数
do_handle({t4_hero_times,RoleID,ModelType}, _State) ->
    mod_hero_fb:gm_reset_barrier_fight_times(RoleID,ModelType),
    ok;

%%重新清零境界副本的次数
do_handle({gm_set_progress,RoleID,Process,ModelType}, _State) ->
    mod_hero_fb:gm_set_progress(RoleID,Process,ModelType),
    ok;

%%重新清零英雄副本的次数
do_handle({t4_examine_times,RoleID}, _State) ->
    mod_examine_fb:gm_reset_barrier_fight_times(RoleID),
    ok;

%%清理钱币开箱子次数
do_handle({t4_clear_box_times,RoleID}, _State) ->
	mod_treasbox:handle({clear_remain_silver_box_times,RoleID}),
    ok;

%% 加Buff
do_handle({t4_add_buff,RoleID,BuffID}, _State) ->
	mod_role_buff:add_buff(RoleID, BuffID),
    ok;

%%测试NPC说话
do_handle({t4_ntalk,RoleID,NpcId,TalkId}, _State) ->
    R2 = #m_fb_npc_talk_toc{npc_id=NpcId,talk_id=TalkId},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FB_NPC, ?FB_NPC_TALK, R2),
    ok;

%%GM赠送道具
do_handle({add_item, RoleID, AwdItemList}, _State) ->
    case common_transaction:t( 
           fun() ->  t_add_item(RoleID,[],AwdItemList) 
           end)of
        {atomic, {ok,AddGoodsList}} ->
            lists:foreach(fun(AwdItem)-> 
                                  {_Type,ItemTypeID,Num} = AwdItem,   
                                  common_item_logger:log(RoleID, ItemTypeID,Num,true,?LOG_ITEM_TYPE_GET_SYSTEM)
                          end,AwdItemList),
            common_misc:update_goods_notify({role, RoleID}, AddGoodsList);
        {aborted, {bag_error,{not_enough_pos,_BagID}}} ->
            ?ERROR_MSG("GM赠送道具,背包空间已满，请整理背包！,RoleID=~w",[RoleID]);
        {aborted, {throw, {bag_error, Reason}}} ->
            ?ERROR_MSG("GM赠送道具出错，Reason=~w",[Reason]);
        {aborted, Error} ->
            ?ERROR_MSG("GM赠送道具出错，Reason=~w",[Error])
    end;

do_handle({t4_super_buff,RoleID,AttrId,Value}, _State) ->
    case AttrId of
        1 -> %% 生命
            Buff = #p_buf{buff_id = -AttrId, last_type = 2, absolute_or_rate = 0, value = Value, is_debuff = false, buff_type = 127};
        2 -> %% 攻击力
            Buff = #p_buf{buff_id = -AttrId, last_type = 2, absolute_or_rate = 0, value = Value, is_debuff = false, buff_type = 62};
        3 -> %% 物理防御
            Buff = #p_buf{buff_id = -AttrId, last_type = 2, absolute_or_rate = 0, value = Value, is_debuff = false, buff_type = 126};
        4 -> %% 法术防御
            Buff = #p_buf{buff_id = -AttrId, last_type = 2, absolute_or_rate = 0, value = Value, is_debuff = false, buff_type = 128}
    end,
    mod_role_buff:del_buff(RoleID, Buff#p_buf.buff_id),
    mod_role_buff:add_buff(RoleID, Buff);

do_handle({t4_remove_super_buff,RoleID}, _State) ->
    mod_role_buff:del_buff(RoleID, [-1,-2,-3,-4]);
    

%% 召唤怪物
do_handle({call_monster,RoleID,MonsterTypeID,Num}, _State) ->
	#map_state{mapid=_MapID, map_name=MapProcessName} = mgeem_map:get_state(),
	{ok, #p_pos{tx=TX, ty=TY}} = mod_map_role:get_role_pos(RoleID),
	lists:foreach(fun(_I) -> 
        global:send(MapProcessName, {mod_map_monster, {dynamic_create_monster2, [{MonsterTypeID, TX + 2, TY + 2}]}})
						  % MonsterList = [#p_monster{reborn_pos=#p_pos{tx=TX + 2, ty=TY + 2},
								% 					monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
								% 					typeid=MonsterTypeID,
								% 					mapid=MapID}],
						  % mod_map_monster:init_call_fb_monster(MapProcessName,MapID,MonsterList)
        end, lists:seq(1,Num));

do_handle(Info, _State) ->
    ?ERROR_MSG("~ts:~w", ["GM命令地图辅助接口匹配到错误数据", Info]).

%%Local Functions

%%@doc 给予道具
t_add_item(_RoleID,GoodsList,[])->
    {ok,GoodsList};
t_add_item(RoleID,GoodsList,[AwdItem|T])->
    ?INFO_MSG("AwdItem:~w~n",[AwdItem]),
    {Type,ItemTypeID,Num} = AwdItem,
    CreateInfo = #r_goods_create_info{bind=true,type=Type, type_id=ItemTypeID, start_time=0, end_time=0, 
                                      num=Num, color=?COLOUR_WHITE,quality=?QUALITY_GENERAL,
                                      punch_num=0,interface_type=present},
    {ok,NewGoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
    t_add_item(RoleID, lists:concat([NewGoodsList,GoodsList]) ,T).

internal_set_role_base(RoleID, RoleBase, ElementName, Value) ->
    List = record_info(fields, p_role_base),
    {ResultBool, TrueIndex} = internal_get_record_element_index(List, ElementName),
    if
        ResultBool =:= true ->
            NewRoleBase = erlang:setelement(TrueIndex, RoleBase, Value),
            mod_map_role:set_role_base(RoleID, NewRoleBase),
            NewRoleBase;
        true ->
            RoleBase
    end.

internal_set_role_attr(RoleID, RoleAttr, ElementName, Value) ->
    List = record_info(fields, p_role_attr),
    {ResultBool, TrueIndex} = internal_get_record_element_index(List, ElementName),
    if
        ResultBool =:= true ->
            NewRoleAttr = erlang:setelement(TrueIndex, RoleAttr, Value),
            mod_map_role:set_role_attr(RoleID, NewRoleAttr),
            NewRoleAttr;
        true ->
            RoleAttr
    end.

internal_get_record_element_index(ElementList, ElementName) ->
    lists:foldl(
        fun(E, {Bool, Index}) ->
            Index2 = Index+1,
            if
                E =:= ElementName ->
                    {true, Index2};
                Bool =:= true ->
                    {Bool, Index};
                true ->
                    {false, Index2}
             end
         end, {false, 1}, ElementList).

%% ====================================================================
%% Internal functions
%% ====================================================================

gm_set_mission(RoleID,MissionID) when is_integer(RoleID), is_integer(MissionID)->
    MissionBaseInfo = mod_mission_data:get_base_info(MissionID),
    #mission_base_info{min_level=MinLevel} = MissionBaseInfo,
    
    LocalNow = calendar:local_time(),
    MissionIDList = get_pre_id_list(MissionID,[]),
    #mission_data{counter_list=CounterListTmp} = mod_mission_data:get_mission_data(RoleID),
    DoneMissList = [ ID ||#mission_counter{id=ID}<-CounterListTmp],
    ExpSum = lists:foldl(fun(E,Acc)-> 
                             case lists:member(E, DoneMissList) of
                                 true->
                                     Acc;
                                 _ ->
                                     #mission_base_info{reward_data=RewardData} = mod_mission_data:get_base_info(E),
                                     #mission_reward_data{exp=Exp} = RewardData,
                                     Exp+Acc
                             end
                         end, 0, MissionIDList),
    CounterList = lists:map(fun(ID)->
                                #mission_counter{key={0, ID}, 
                                                 id=ID,big_group=0,last_clear_counter_time=LocalNow, 
                                                 commit_times=1,  succ_times=1}
                            end, MissionIDList),
    NewPInfo = get_new_pinfo(MissionBaseInfo),
    MissionData2 = #mission_data{last_store_time=common_tool:now(),
                                 data_version=common_tool:now(),
                                 mission_list=[NewPInfo],
                                 counter_list=CounterList},
    db:dirty_write(?DB_MISSION_DATA_P,#r_db_mission_data{role_id=RoleID ,mission_data=MissionData2}),
    mod_mission_data:init_role_data(RoleID, MissionData2),
    mgeer_role:absend(RoleID, {mod_map_role, {add_exp, RoleID, ExpSum}}),
    mgeer_role:absend(RoleID, {mod_gm, {set_level, RoleID, MinLevel}}),
    ok.

get_new_pinfo(MissionBaseInfo)->
    #p_mission_info{id=MissionBaseInfo#mission_base_info.id,
                                       model=MissionBaseInfo#mission_base_info.model,
                                       type=MissionBaseInfo#mission_base_info.type,
                                       current_status=1,
                                       pre_status=1,
                                       current_model_status=0,
                                       pre_model_status=0,
                                       commit_times=0,
                                       succ_times=0,
                                       accept_time=0,
                                       status_change_time=0,
                                       listener_list=[],
                                       int_list_1=[],
                                       int_list_2=[],
                                       int_list_3=[],
                                       int_list_4=[]}.

get_pre_id_list(0,Acc)->
    Acc;
get_pre_id_list(ID,Acc)->
    #mission_base_info{pre_mission_id=PreID} = mod_mission_data:get_base_info(ID),
    case PreID of
        0->
            Acc;
        _ ->
            get_pre_id_list(PreID,[PreID|Acc])
    end.


%%GM设置玩家的培养属性，便于测试
t_do_set_role_grow(RoleID,Index,Value) when Index>0 andalso Index<5->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{role_grow=RoleGrow}=RoleMapExt} ->
            #r_role_grow{sum_grow_val=SumGrowVal}=RoleGrow,
            case SumGrowVal of
                undefined->
                    SumGrowVal2 = #r_grow_add_val{};
                _ ->
                    SumGrowVal2 = SumGrowVal
            end,
            case Index of
                1-> ElementName=phy_attack;
                2-> ElementName=phy_defence;
                3-> ElementName=mgc_attack;
                4-> ElementName=mgc_defence
            end,
            List = record_info(fields, r_grow_add_val),
            {ResultBool, TrueIndex} = internal_get_record_element_index(List, ElementName),
            if
                ResultBool =:= true ->
                    NewSumGrowVal = erlang:setelement(TrueIndex, SumGrowVal2, Value),
                    RoleGrow2 = RoleGrow#r_role_grow{sum_grow_val=NewSumGrowVal,
                                                     last_save_time=common_tool:now()},
                    RoleMapExt2 = RoleMapExt#r_role_map_ext{role_grow=RoleGrow2},
                    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2),
                    {ok, RoleGrow, RoleGrow2};
                true ->
                    {error,index_not_found}
            end;
        _ ->
            {error,role_not_found}
    end.

do_set_role_tower_fb_info(RoleID,Index,Value) when Index>0 andalso Index<5 ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok, #r_role_map_ext{role_tower_fb_info = RoleTowerFbInfo} = RoleExt} ->
            case Index of
                1 ->%%改变领奖日期
                    RewardDate = {Value div 10000, (Value rem 10000) div 100, Value rem 100},
                    NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{last_reward_date = RewardDate};
                2 ->%%改变挑战日期
                    LCD = {Value div 10000, (Value rem 10000) div 100, Value rem 100},
                    NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{last_challenge_date = LCD};
                3 ->%%改变最高关卡
                    BestLevel = Value,
                    NewRoleTowerFbInfo = RoleTowerFbInfo#r_role_tower_fb{best_level = BestLevel, score_list = lists:duplicate(BestLevel, 1000)};
                _ ->
                    NewRoleTowerFbInfo = RoleTowerFbInfo
            end,
            NewRoleExt = RoleExt#r_role_map_ext{role_tower_fb_info = NewRoleTowerFbInfo},
            mod_map_role:set_role_map_ext_info(RoleID, NewRoleExt);
        _ ->
            {error, not_found}
    end.
