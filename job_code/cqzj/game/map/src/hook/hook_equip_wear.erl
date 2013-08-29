%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 穿装备通知
%%%
%%% Created : 2010-9-5
%%% -------------------------------------------------------------------
-module(hook_equip_wear).
-export([
         hook/1
%% 		 hook_achievement2/2
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").

%% --------------------------------------------------------------------
%% Function: hook/1
%% Description: hook检查口
%% Parameter: int() RoleId 角色id
%% Parameter: record() GoodsInfo #p_goods
%% Parameter: record() GoodsBaseInfo #p_item_base_info
%% Returns: ok
%% --------------------------------------------------------------------
%%检查
hook({_RoleID, _GoodsInfo, _GoodsBaseInfo}) ->
    ok;

hook({RoleID, _SlotNum, _GoodsInfo, _EquipBaseInfo, _NewRoleAttr}) ->
	?TRY_CATCH(mod_open_activity:hook_whole_event(RoleID)).

