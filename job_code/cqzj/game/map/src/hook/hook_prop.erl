%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 得到道具/销毁道具
%%%
%%% Created : 2010-6-28
%%% -------------------------------------------------------------------
-module(hook_prop).
-export([
         hook/2,hook/3
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").


%% --------------------------------------------------------------------
%% Function: hook/1
%% Description: hook检查口
%% Parameter: record() PGoodsRecord #p_goods
%% Parameter: int() NumChange 数量改变 正/负数
%% Returns: ok
%% --------------------------------------------------------------------
%%检查
hook(decreate, PropList) ->
    ?TRY_CATCH( hook_mission(prop_decreate, PropList) );

hook(shop_buy, PropList) ->
    ?TRY_CATCH( hook_mission(prop_shop_buy, PropList) );

hook(create, PropList) ->
    ?TRY_CATCH( hook_mission(prop_create, PropList) ).

hook(open_gift, RoleID, PropList) ->
    ?TRY_CATCH( hook_open_gift(RoleID, PropList) ).

%% ====================================================================
%% 第三方hook代码放置在此
%% ====================================================================

%%玩家打开礼包的处理，某些装备需要自动穿戴
hook_open_gift(RoleID,PropList)->
    case common_config_dyn:find(item_special, auto_load_when_open_gift) of
        [] -> ignore;
        [AutoLoadTypeIdList] ->
            AutoLoadList = lists:foldl(fun
                (E,AccIn)->
                    #p_goods{id=GoodsId, typeid=TypeId} = E,
                    case lists:keyfind(TypeId, 1, AutoLoadTypeIdList) of
                        false->
                            AccIn;
                        {_TypeId,SlotNum}->
                            [{GoodsId,SlotNum}|AccIn]
                    end
            end, [], PropList),
            lists:foreach(fun
                ({GoodsId,SlotNum})->
                    LoadInfo = #m_equip_load_tos{equip_slot_num=SlotNum, equipid=GoodsId},
                    mod_role_equip:handle({?DEFAULT_UNIQUE, ?EQUIP, ?EQUIP_LOAD, 
                                              LoadInfo, RoleID, common_misc:get_role_pid(RoleID), 0})
            end, AutoLoadList),
            ok
    end.

%%触发任务更新
hook_mission(Type, PropList) ->
    case PropList of
        [#p_goods{typeid = PropTypeID, roleid = RoleID,current_num=PropNum}|_T]->
            Msg =  {mod_mission_handler, {listener_dispatch, Type, RoleID, PropTypeID, PropNum}},
            mgeer_role:absend(RoleID, Msg);
        _ ->
            ignore
    end.
