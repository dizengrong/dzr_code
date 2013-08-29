%%%-------------------------------------------------------------------
%%% @author  <caochuncheng2002@gmail.com>
%%% @copyright (C) 2011, 
%%% @doc
%%% 藏宝图道具使用处理
%%% @end
%%%-------------------------------------------------------------------
-module(mod_cang_bao_tu_fb).

-include("mgeem.hrl").
-export([
         do_handle_info/1,
         t_do_use_cang_bao_tu/3,
         init/1,
         loop/2,
         get_map_name_to_enter/1,set_map_enter_tag/2,
         clear_map_enter_tag/1,
         assert_valid_map_id/1,
		 hook_gaoji_cang_bao_tu/1
        ]).
-export([hook_role_online/1,
         hook_role_offline/1,
         hook_role_enter_map/2,
         get_collect_broadcast_msg/5]).

-define(reward_type_item, 1). %% 道具奖励
-define(reward_type_silver_bind, 2). %% 铜钱奖励
-define(reward_type_call_one_monster, 3). %% 召唤一只怪物
-define(reward_type_call_multi_monster, 4). %% 召唤怪物 群
-define(reward_type_enter_fb, 5). %% 进入副本


-define(cangbaofb_status_create, 0).
-define(cangbaofb_status_running, 1).
-define(cangbaofb_status_close, 2).

-record(r_map_fb_dict,{status = 0,enter_map_id,enter_tx,enter_ty, role_offline_time = 0}).

do_handle_info({Unique, Module, ?ITEM_CANG_BAO_TU_FB, DataRecord, RoleId, PId}) ->
    do_cang_bao_tu_fb(Unique, Module, ?ITEM_CANG_BAO_TU_FB, DataRecord, RoleId, PId);
do_handle_info({enter_cang_bao_tu_fb,Msg}) ->
    do_enter_cang_bao_tu_fb(Msg);
do_handle_info({create_map_succ,Key}) ->
    do_async_create_map(Key);
do_handle_info({init_fb_base_info,Msg}) ->
    do_init_fb_base_info(Msg);
do_handle_info({fb_process_kill})->
    common_map:exit(mod_cang_bao_tu_fb_map_exit);

do_handle_info(Info) ->
    ?ERROR_MSG("~ts,Info=~w",["藏宝图道具使用处理模块无法处理此消息",Info]),
    error.
%% 玩家使用藏宝图处理
t_do_use_cang_bao_tu(RoleId,ItemGoods,TransModule) ->
    RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleId,role),
    case erlang:length(ItemGoods#p_goods.use_pos) =/= 3 of
        true ->
            TransModule:abort(?_LANG_ITEM_CANG_BAO_TU_NOT_POS_INFO);
        _ ->
            next
    end,
    CurMapId = mgeem_map:get_mapid(),
    [UseMapId,UseTx, UseTy] = ItemGoods#p_goods.use_pos,
    case CurMapId =:= UseMapId 
        andalso erlang:abs((RoleMapInfo#p_map_role.pos)#p_pos.tx - UseTx) =< 4
        andalso erlang:abs((RoleMapInfo#p_map_role.pos)#p_pos.ty - UseTy) =< 4 of 
        true ->
            next;
        _ ->
            [PMapName] = common_config_dyn:find(map_info,UseMapId),
            TransModule:abort(common_tool:get_format_lang_resources(?_LANG_ITEM_CANG_BAO_TU_NOT_IN_POS, [PMapName,UseTx,UseTy]))
    end,
    case get_reward_result(ItemGoods) of
        {error,no_reward} ->
            RewardType = 0,
            ItemRewardResult = undefined,
            PromptMsg = ?_LANG_ITEM_CANG_BAO_TU_REWARD_NO,
            Fun = undefined,
            NewRoleAttr = undefined;
        {error,Reason} ->
            ?ERROR_MSG("~ts,Reason=~w",["使用藏宝图出错",Reason]),
            RewardType = 0,
            ItemRewardResult = undefined,
            PromptMsg = "",
            Fun = undefined,
            NewRoleAttr = undefined,
            TransModule:abort(?_LANG_ITEM_CANG_BAO_TU_ERROR);
        {ok,RewardType,ItemRewardInfo} ->
            case t_give_reward(RoleId,RewardType,ItemRewardInfo,ItemGoods#p_goods.use_pos,TransModule) of
                {ok,RewardType,ItemRewardResult,PromptMsg,Fun} ->
                    NewRoleAttr = undefined,
                    ignore;
                {ok,RewardType,ItemRewardResult,PromptMsg,Fun,NewRoleAttr} ->
                    ignore
            end
                
    end,
    {ok,RewardType,ItemRewardResult,PromptMsg,Fun,NewRoleAttr}.
%% 给玩家道具使用奖励
%% ItemRewardInfo={weight,is_broadcast,r_goods_create_special}
t_give_reward(RoleId,?reward_type_item,ItemRewardInfo,_UsePos,TransModule) ->
    {_,IsBroadcast,CreateGoodsSpecialRecord} = ItemRewardInfo,
    case mod_refining_tool:get_p_goods_by_special(RoleId, CreateGoodsSpecialRecord) of
        {ok,PGoodsList} ->
            %% 以后扩展一下当背包满足时，需要特殊处理
            GoodsList = 
                case catch mod_bag:create_goods_by_p_goods(RoleId,PGoodsList) of
                    {bag_error,not_enough_pos} ->
                        TransModule:abort(?_LANG_ITEM_CANG_BAO_TU_CREATE_ITEM_NOT_ENOUGH_POS);
                    {bag_error,Reason} ->
                        erlang:throw({bag_error,Reason});
                    {ok,GoodsListT} ->
                        GoodsListT
                end,
            [HItemGoods|_TItemGoods] = GoodsList,
            GiveRewardGoodsName = common_goods:get_notify_goods_name(HItemGoods#p_goods{current_num=CreateGoodsSpecialRecord#r_goods_create_special.item_num}),
            {ok,RoleBase} = mod_map_role:get_role_base(RoleId),
            Fun = 
                {func,fun() -> 
                              catch common_item_logger:log(RoleId,HItemGoods,CreateGoodsSpecialRecord#r_goods_create_special.item_num,
                                                           ?LOG_ITEM_TYPE_CANG_BAO_TU),
                              catch common_misc:update_goods_notify({role, RoleId},GoodsList),
                              case IsBroadcast =:= 1 of
                                  true ->
                                      BcMsg = common_tool:get_format_lang_resources(?_LANG_ITEM_CANG_BAO_TU_REWARD_ITEM_BC, [RoleBase#p_role_base.role_name,GiveRewardGoodsName]),
                                      common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER],?BC_MSG_SUB_TYPE,BcMsg);
                                  _ ->
                                      ignore
                              end,
                              ok
                 end},
            PromptMsg = common_tool:get_format_lang_resources(?_LANG_ITEM_CANG_BAO_TU_REWARD_ITEM, [GiveRewardGoodsName]),
            {ok,?reward_type_item,GoodsList,PromptMsg,Fun};
        Reason ->
			?ERROR_MSG("t_give_reward error:~w",[Reason]),
            TransModule:abort(?_LANG_ITEM_CANG_BAO_TU_CREATE_ITEM)
    end;
%% 铜钱奖励
%% ItemRewardInfo={weight,is_broadcast,silver_bind}
t_give_reward(RoleId,?reward_type_silver_bind,ItemRewardInfo,_UsePos,_TransModule) ->
    {_,IsBroadcast,SilverBind} = ItemRewardInfo,
    common_consume_logger:gain_silver({RoleId, SilverBind, 0, ?GAIN_TYPE_SILVER_USE_CANG_BAO_TU, ""}),
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleId),
    {ok,RoleBase} = mod_map_role:get_role_base(RoleId),
    NewSilverBind = RoleAttr#p_role_attr.silver_bind + SilverBind,
    mod_map_role:set_role_attr(RoleId, RoleAttr#p_role_attr{silver_bind = NewSilverBind}),
	Fun = 
		{func,fun() -> 
					  ChangeAttList = [#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=NewSilverBind}],
					  common_misc:role_attr_change_notify({role, RoleId}, RoleId, ChangeAttList),
					  case IsBroadcast =:= 1 of
						  true ->
							  BcMsg = common_misc:format_lang(?_LANG_ITEM_CANG_BAO_TU_REWARD_SILVER_BIND_BC, [common_tool:to_list(RoleBase#p_role_base.role_name),common_tool:silver_to_string(SilverBind)]),
							  common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER],?BC_MSG_SUB_TYPE,BcMsg);
						  _ ->
							  ignore
					  end,
					  ok
		 end},
	PromptMsg = common_misc:format_lang(?_LANG_ITEM_CANG_BAO_TU_REWARD_SILVER_BIND, [common_tool:silver_to_string(SilverBind)]),
    {ok,?reward_type_silver_bind,NewSilverBind,PromptMsg,Fun,RoleAttr#p_role_attr{silver_bind = NewSilverBind}};
t_give_reward(_RoleId,?reward_type_call_one_monster,MonsterTypeId,UsePos,_TransModule) ->
    [_UseMapId,UseTx,UseTy] = UsePos,
    #map_state{mapid = CurMapId, map_name= MapProcessName} = mgeem_map:get_state(),
    Fun = 
        {func,fun() -> 
                      PMonsterInfo=#p_monster{reborn_pos=#p_pos{tx=UseTx, ty=UseTy, dir=common_tool:random(0, 7)},
                                              monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
                                              typeid=MonsterTypeId,
                                              mapid=CurMapId},
                      mod_map_monster:init([PMonsterInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, CurMapId, MapProcessName, undefined, ?FIRST_BORN_STATE, null])
         end},
    [#p_monster_base_info{monstername = MonsterName}] = cfg_monster:find(MonsterTypeId),
    PromptMsg = common_tool:get_format_lang_resources(?_LANG_ITEM_CANG_BAO_TU_REWARD_ONE_MONSTER, [MonsterName]),
    {ok,?reward_type_call_one_monster,undefined,PromptMsg,Fun};
t_give_reward(RoleId,?reward_type_call_multi_monster,ItemRewardInfo,_UsePos,_TransModule) ->
    #map_state{mapid = CurMapId, map_name= MapProcessName} = mgeem_map:get_state(),
    {MonsterTypeId,MonsterPosList} = ItemRewardInfo,
    {ok,RoleBase} = mod_map_role:get_role_base(RoleId),
    Fun = 
        {func,fun() -> 
                      lists:foreach(
                        fun({Tx,Ty}) -> 
                                PMonsterInfo=#p_monster{reborn_pos=#p_pos{tx=Tx, ty=Ty, dir=common_tool:random(0, 7)},
                                                        monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
                                                        typeid=MonsterTypeId,
                                                        mapid=CurMapId},
                                mod_map_monster:init([PMonsterInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, CurMapId, MapProcessName, undefined, ?FIRST_BORN_STATE, null])
                        end,MonsterPosList),
                      [#p_monster_base_info{monstername = MonsterName}] = cfg_monster:find(MonsterTypeId),
                      [MapName] = common_config_dyn:find(map_info,CurMapId),
                      BcMsg = common_tool:get_format_lang_resources(?_LANG_ITEM_CANG_BAO_TU_REWARD_MULTI_MONSTER_BC, [RoleBase#p_role_base.role_name,MapName,MonsterName]),
                      common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER],?BC_MSG_SUB_TYPE,BcMsg),
                      common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_WORLD,BcMsg),
                      ok
         end},
    [#p_monster_base_info{monstername = MonsterName}] = cfg_monster:find(MonsterTypeId),
    PromptMsg = common_tool:get_format_lang_resources(?_LANG_ITEM_CANG_BAO_TU_REWARD_MULTI_MONSTER, [MonsterName]),
    {ok,?reward_type_call_multi_monster,undefined,PromptMsg,Fun};
t_give_reward(RoleId,?reward_type_enter_fb,_,_UsePos,_TransModule) ->
	#map_state{map_name= MapProcessName} = mgeem_map:get_state(),
	Fun = 
		{func,fun() -> 
					  ?TRY_CATCH(global:send(MapProcessName,{mod_cang_bao_tu_fb,{enter_cang_bao_tu_fb,RoleId}}),EnterHuanBaoTuFbError),
					  ok
		 end},
	PromptMsg = ?_LANG_ITEM_CANG_BAO_TU_REWARD_ENTER_FB,
	{ok,?reward_type_enter_fb,undefined,PromptMsg,Fun}.


%% 玩家使用藏宝图获得的奖励
get_reward_result(ItemGoods) ->
    [UseMapId,_UseTx,_UseTy] = ItemGoods#p_goods.use_pos,
    #p_goods{typeid = ItemTypeId} = ItemGoods,
    case common_config_dyn:find(cang_bao_tu_fb, {use_item_reward,ItemTypeId}) of
        [UseItemRewardList] when erlang:length(UseItemRewardList) > 0 ->
            Index = mod_refining:get_random_number([Weight || {Weight,_} <- UseItemRewardList],0,1),
            {_,RewardType} = lists:nth(Index,UseItemRewardList),
            get_reward_result2(ItemTypeId,UseMapId,RewardType);
        _ ->
            {error,no_reward}
    end.
%% 道具奖励
get_reward_result2(ItemTypeId,_UseMapId,?reward_type_item) ->
    case common_config_dyn:find(cang_bao_tu_fb, {use_item_reward,ItemTypeId,?reward_type_item}) of
        [ItemRewardList] when erlang:length(ItemRewardList) > 0 ->
            Index = mod_refining:get_random_number([Weight || {Weight,_,_} <- ItemRewardList],0,1),
            ItemRewardRecord = lists:nth(Index, ItemRewardList),
            {ok,?reward_type_item,ItemRewardRecord};
        _ ->
            {error,reward_type_item}
    end;
%% 铜钱奖励
get_reward_result2(ItemTypeId,_UseMapId,?reward_type_silver_bind) ->
    case common_config_dyn:find(cang_bao_tu_fb, {use_item_reward,ItemTypeId,?reward_type_silver_bind}) of
        [ItemRewardList] when erlang:length(ItemRewardList) > 0 ->
            Index = mod_refining:get_random_number([Weight || {Weight,_,_} <- ItemRewardList],0,1),
            ItemRewardRecord = lists:nth(Index, ItemRewardList),
            {ok,?reward_type_silver_bind,ItemRewardRecord};
        _ ->
            {error,reward_type_bind}
    end;
%% 召唤一只怪物
get_reward_result2(ItemTypeId,UseMapId,?reward_type_call_one_monster) ->
    case common_config_dyn:find(cang_bao_tu_fb, {use_item_reward,ItemTypeId,?reward_type_call_one_monster}) of
        [ItemRewardList] when erlang:length(ItemRewardList) > 0 ->
            case lists:keyfind(UseMapId,1,ItemRewardList) of
                false ->
                    {error,reward_type_call_one_monster_map_id};
                {UseMapId,MonsterList} ->
                    Index = mod_refining:get_random_number([Weight || {Weight,_} <- MonsterList],0,1),
                    {_,MonsterTypeId} = lists:nth(Index, MonsterList),
                    {ok,?reward_type_call_one_monster,MonsterTypeId}
            end;
        _ ->
            {error,reward_type_call_one_monster}
    end;
%% 召唤怪物 群
get_reward_result2(ItemTypeId,UseMapId,?reward_type_call_multi_monster) ->
    case common_config_dyn:find(cang_bao_tu_fb, {use_item_reward,ItemTypeId,?reward_type_call_multi_monster}) of
        [ItemRewardList] when erlang:length(ItemRewardList) > 0 ->
            case lists:keyfind(UseMapId,1,ItemRewardList) of
                false ->
                    {error,reward_type_call_multi_monster_map_id};
                {UseMapId,MonsterNumber,MonsterInfoList,MonsterPosList} ->
                    IndexA = mod_refining:get_random_number([WeightA || {WeightA,_} <- MonsterInfoList],0,1),
                    {_,MonsterTypeId} = lists:nth(IndexA, MonsterInfoList),
                    MonsterPosLength = erlang:length(MonsterPosList),
                    NewMonsterPosList = 
                        lists:foldl(
                          fun(_NumberIndex,AccNewMonsterPosList) -> 
                                  [lists:nth(common_tool:random(1, MonsterPosLength), MonsterPosList)|AccNewMonsterPosList]
                          end, [], lists:seq(1, MonsterNumber)),
                    {ok,?reward_type_call_multi_monster,{MonsterTypeId,NewMonsterPosList}}
            end;
        _ ->
            {error,reward_type_call_multi_monster}
    end;
%% 进入副本
get_reward_result2(_ItemTypeId,_UseMapId,?reward_type_enter_fb) ->
    {ok,?reward_type_enter_fb,undefined};
get_reward_result2(ItemTypeId,UseMapId,RewardType) ->
    ?ERROR_MSG("~ts,ItemTypeId=~w,RewardType=~w",["使用藏宝图出错",ItemTypeId,UseMapId,RewardType]),
    {error,reward_type}.

init(MapId) ->
    case common_config_dyn:find(cang_bao_tu_fb,cang_bao_tu_fb_map_id) of
        [MapId] ->
            put_cangbaotu_fb_dict(MapId,#r_map_fb_dict{enter_map_id = 0,enter_tx = 0,enter_ty = 0});
        _ ->
            ok
    end.
loop(MapId,Now) ->
    case common_config_dyn:find(cang_bao_tu_fb,cang_bao_tu_fb_map_id) of
        [MapId] ->
            case get_cangbaotu_fb_dict(MapId) of
                FBMapInfo when erlang:is_record(FBMapInfo,r_map_fb_dict) ->
                    loop2(MapId,Now,FBMapInfo);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.
loop2(_MapId,_NowSeconds,FBMapInfo) ->
    RoleIDList = mod_map_actor:get_in_map_role(),
    case FBMapInfo#r_map_fb_dict.status =:= ?cangbaofb_status_close 
         andalso RoleIDList =:= [] of
        true ->
            common_map:exit(cang_bao_tu_fb_close);
        _ ->
            next
    end,
    case FBMapInfo#r_map_fb_dict.status =:= ?cangbaofb_status_running 
         andalso FBMapInfo#r_map_fb_dict.role_offline_time =:= 0
         andalso RoleIDList =:= [] of
        true ->
            erlang:send_after(10000, self(), {mod_cang_bao_tu_fb,{fb_process_kill}});
        _ ->
            next
    end,
    ok.
%% 上线清除离线数据 
hook_role_online(_RoleID)->
    MapID = mgeem_map:get_mapid(),
    case get_cangbaotu_fb_dict(MapID) of
        FBMapInfo when erlang:is_record(FBMapInfo,r_map_fb_dict) ->
            put_cangbaotu_fb_dict(MapID,FBMapInfo#r_map_fb_dict{role_offline_time = 0});
        _->
            ignore
    end.

%% 记录离线玩家信息
hook_role_offline(_RoleID)->
    MapID = mgeem_map:get_mapid(),
    case get_cangbaotu_fb_dict(MapID) of
        FBMapInfo when erlang:is_record(FBMapInfo,r_map_fb_dict) ->
            put_cangbaotu_fb_dict(MapID,FBMapInfo#r_map_fb_dict{role_offline_time = common_tool:now()});
        _->
            ignore
    end.
%% 玩家首次进入地图
hook_role_enter_map(_RoleID,MapID) ->
    case get_cangbaotu_fb_dict(MapID) of
        FBMapInfo when erlang:is_record(FBMapInfo,r_map_fb_dict) ->
            case FBMapInfo#r_map_fb_dict.status =:= ?cangbaofb_status_create of
                true ->
                    put_cangbaotu_fb_dict(MapID,FBMapInfo#r_map_fb_dict{status = ?cangbaofb_status_running});
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

put_cangbaotu_fb_dict(MapId,Record) ->
    erlang:put({cangbaotu_fb_dict,MapId},Record).
get_cangbaotu_fb_dict(MapId) ->
    erlang:get({cangbaotu_fb_dict,MapId}).


do_enter_cang_bao_tu_fb(RoleId) ->
    case catch do_enter_cang_bao_tu_fb2(RoleId) of
        {error,Reason,ReasonCode} ->
            ?DEBUG("~ts,Reason=~w,ReasonCode=~w",["玩家使用藏宝图进入宝藏副本出错",Reason,ReasonCode]);
        {ok,FbMapId,FbMapProcessName,Now} ->
            do_enter_cang_bao_tu_fb3(RoleId,FbMapId,FbMapProcessName,Now) 
    end.
do_enter_cang_bao_tu_fb2(RoleId) ->
    FbMapId = 
        case common_config_dyn:find(cang_bao_tu_fb, cang_bao_tu_fb_map_id) of
            [FbMapIdT] ->
                FbMapIdT;
            _ ->
                erlang:throw({error,"",0})
        end,
    case mod_map_actor:get_actor_mapinfo(RoleId, role) of
        undefined ->
            erlang:throw({error,"",0});
        _ ->
            next
    end,
    Now = mgeem_map:get_now(),
    FbMapProcessName = common_map:get_cangbaotu_map_name(RoleId,mgeem_map:get_now()),
    case global:whereis_name(FbMapProcessName) of
        undefined ->
            next;
        _ ->
            erlang:throw({error,"",0})
    end,
    {ok,FbMapId,FbMapProcessName,Now}.
    
do_enter_cang_bao_tu_fb3(RoleId,FbMapId,FbMapProcessName,Now) ->
    case global:whereis_name(FbMapProcessName) of
        undefined ->
            mod_map_copy:async_create_copy(FbMapId, FbMapProcessName, ?MODULE, {RoleId,FbMapId,Now}),
            log_async_create_map({RoleId,FbMapId,Now},{RoleId,FbMapId,FbMapProcessName,Now});
        _PID->
            ignore
    end.

set_map_enter_tag(RoleID,FbMapProcessName)->
    MapID =mgeem_map:get_mapid(),
    erlang:put({cangbaotu_fb_map_processname,MapID,RoleID}, FbMapProcessName).

get_map_name_to_enter(RoleID)->
    MapID =mgeem_map:get_mapid(),
    erlang:get({cangbaotu_fb_map_processname,MapID,RoleID}).

clear_map_enter_tag(RoleID)->
    MapID =mgeem_map:get_mapid(),
    erlang:erase({cangbaotu_fb_map_processname,MapID,RoleID}).

assert_valid_map_id(MapID)->
    case common_config_dyn:find(cang_bao_tu_fb, cang_bao_tu_fb_map_id) of
        [MapID] ->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[MapID]),
            throw({error,error_map_id,MapID})
    end.

log_async_create_map(Key,Value)->
    erlang:put({mod_cangbaotu_fb,Key},Value).
get_async_create_map_info(Key)->
    erlang:get({mod_cangbaotu_fb,Key}).
erase_async_create_map(Key)->
    erlang:erase(Key).

do_async_create_map(Key)->
    case get_async_create_map_info(Key) of
        undefined->
            ignore;
        {RoleId,FbMapId,FbMapProcessName,Now}->
            erase_async_create_map(Key),
            do_enter_cang_bao_tu_fb4(RoleId,FbMapId,FbMapProcessName,Now)
    end.
do_enter_cang_bao_tu_fb4(RoleId,FbMapId,FbMapProcessName,_Now) ->
    {_, Tx, Ty} = common_misc:get_born_info_by_map(FbMapId),
    CurMapId = mgeem_map:get_mapid(),
    #p_map_role{level = Level,pos = #p_pos{tx = CurTx,ty = CurTy}} = mod_map_actor:get_actor_mapinfo(RoleId, role),
    set_map_enter_tag(RoleId,FbMapProcessName),
    ?TRY_CATCH(global:send(FbMapProcessName,{mod_cang_bao_tu_fb,{init_fb_base_info,{Level,CurMapId,CurTx,CurTy}}}),FbBaseInfoError),
    %% 跳转地图
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleId, FbMapId, Tx, Ty),
    ok.
do_init_fb_base_info({Level,CurMapId,CurTx,CurTy}) ->
    #map_state{mapid = MapId, map_name = MapProcessName} = mgeem_map:get_state(),
    CangBaoTuFbDict = get_cangbaotu_fb_dict(MapId),
    put_cangbaotu_fb_dict(MapId,CangBaoTuFbDict#r_map_fb_dict{enter_map_id = CurMapId,enter_tx = CurTx,enter_ty = CurTy}),
    MonsterIdList = 
        case common_config_dyn:find(cang_bao_tu_fb, {cang_bao_tu_fb_monster,Level}) of
            [MonsterIdListA]  ->
                MonsterIdListA;
            _ ->
                case common_config_dyn:find(cang_bao_tu_fb, {cang_bao_tu_fb_monster,0}) of
                    [MonsterIdListB] ->
                        MonsterIdListB;
                    _ ->
                        []
                end
        end,
    [MonsterPosList] = common_config_dyn:find(cang_bao_tu_fb,cang_bao_tu_fb_monster_born_point),
	lists:foldl(
	  fun({Tx,Ty},AccIndex) -> 
			  PMonsterInfo=#p_monster{reborn_pos=#p_pos{tx=Tx, ty=Ty, dir=common_tool:random(0, 7)},
									  monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
									  typeid=lists:nth(AccIndex, MonsterIdList),
									  mapid=MapId},
			  mod_map_monster:init([PMonsterInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, MapId, MapProcessName, undefined, ?FIRST_BORN_STATE, null]),
			  AccIndex + 1
	  end,1,MonsterPosList).

do_cang_bao_tu_fb(Unique, Module, Method, DataRecord, RoleId, PId) ->
    case catch do_cang_bao_tu_fb2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_cang_bao_tu_fb_error(Unique, Module, Method, DataRecord, RoleId, PId, Reason,ReasonCode);
        {ok,RoleMapInfo,EnterMapId,EnterTx,EnterTy} ->
            do_cang_bao_tu_fb3(Unique, Module, Method, DataRecord, RoleId, PId,
                               RoleMapInfo,EnterMapId,EnterTx,EnterTy)
    end.
do_cang_bao_tu_fb2(RoleId,DataRecord) ->
    case DataRecord#m_item_cang_bao_tu_fb_tos.op_type =:= 2 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_ITEM_CANG_BAO_TU_QUIT_FB_ERROR,0})
    end,
    RoleMapInfo =
        case mod_map_actor:get_actor_mapinfo(RoleId, role) of
            undefined ->
                erlang:throw({error,?_LANG_ITEM_CANG_BAO_TU_QUIT_FB_ERROR,0});
            RoleMapInfoT ->
                RoleMapInfoT
        end,
    CurMapId = mgeem_map:get_mapid(),
    case get_cangbaotu_fb_dict(CurMapId) of
        undefined ->
            EnterMapId = common_misc:get_home_map_id(RoleMapInfo#p_map_role.faction_id),
            {EnterMapId,EnterTx,EnterTy} = common_misc:get_born_info_by_map(EnterMapId);
        #r_map_fb_dict{enter_map_id = EnterMapId,enter_tx = EnterTx,enter_ty = EnterTy} ->
            next
    end,
    {ok,RoleMapInfo,EnterMapId,EnterTx,EnterTy}.
do_cang_bao_tu_fb3(Unique, Module, Method, DataRecord, RoleId, PId,
                   _RoleMapInfo,EnterMapId,EnterTx,EnterTy) ->
    SendSelf = #m_item_cang_bao_tu_fb_toc{op_type = DataRecord#m_item_cang_bao_tu_fb_tos.op_type,
                                          succ = true},
    ?DEBUG("~ts,SendSelf=~w",["藏宝图使用模块返回",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ?TRY_CATCH(mod_role_busy:stop(RoleId),StopCollectError),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleId,EnterMapId,EnterTx,EnterTy),
    ok.
do_cang_bao_tu_fb_error(Unique, Module, Method, DataRecord, _RoleId, PId, Reason,ReasonCode) ->
    SendSelf = #m_item_cang_bao_tu_fb_toc{op_type = DataRecord#m_item_cang_bao_tu_fb_tos.op_type,
                                          succ = false,reason = Reason, reason_code = ReasonCode},
    ?DEBUG("~ts,SendSelf=~w",["藏宝图使用模块返回",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

%% @doc 采集HOOK
get_collect_broadcast_msg(RoleName, _FactionID, _FactionName, Addr, GoodsName) ->
    common_tool:get_format_lang_resources(?_LANG_COLLECT_CHAT_BROADCAST_2_10505, [RoleName, Addr, GoodsName]).
  
%% 高级藏宝图碎片合成高级藏宝图的位置
hook_gaoji_cang_bao_tu(#r_goods_create_info{type_id=TypeID,use_pos=UsePosList}=GoodsCreateInfo) when erlang:is_record(GoodsCreateInfo, r_goods_create_info) ->
	NewUsePosList = 
		case UsePosList =:= [] orelse UsePosList =:= undefined of
			true ->
				case common_config_dyn:find(cang_bao_tu_fb,{gaoji_cang_bao_tu_pos,TypeID}) of
					[DropItemUsePosList] ->
						OpenedDays = common_config:get_opened_days(),
						lists:foldl(
						  fun({MinOpenedDays,MaxOpenedDays,SubDropItemUsePosList},AccNewUsePosList) -> 
								  case AccNewUsePosList =:= [] 
										   andalso OpenedDays >= MinOpenedDays 
										   andalso (MaxOpenedDays =:= 0 orelse MaxOpenedDays >= OpenedDays) of
									  true ->
										  {DropItemUseMapId,DropItemUseTx,DropItemUseTy} = lists:nth(common_tool:random(1, erlang:length(SubDropItemUsePosList)), SubDropItemUsePosList),
										  [DropItemUseMapId,DropItemUseTx,DropItemUseTy];
									  _ ->
										  AccNewUsePosList
								  end
						  end, [], DropItemUsePosList);
					_ ->
						[]
				end;
			_ ->
				UsePosList
		end,
	GoodsCreateInfo#r_goods_create_info{use_pos=NewUsePosList};
hook_gaoji_cang_bao_tu(GoodsCreateInfo) ->
	GoodsCreateInfo.