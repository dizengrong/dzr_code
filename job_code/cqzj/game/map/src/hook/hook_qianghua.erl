%%% @author chenrong
%%% @doc
%%%     时装强化hook
%%% @end
%%% Created : 2012-07-02
%%%-------------------------------------------------------------------
-module(hook_qianghua).
-include("mgeem.hrl").

-export([hook_equip_qianghua/3,
         hook_equip_upgrade/2,
         hook_equip_upgrade_color/2]).

%% 装备强化升星
hook_equip_qianghua(RoleID, EquipInfo, _EquipList) ->
	#p_goods{typeid=TypeID,reinforce_result=ReinforceResult}=EquipInfo,
	[#p_equip_base_info{slot_num=SlotNum}] = common_config_dyn:find_equip(TypeID),
	hook_mission_event:hook_equip_qianghua(RoleID,SlotNum,ReinforceResult),
	?TRY_CATCH(mod_examine_fb:hook_equip_qianghua(RoleID,SlotNum,ReinforceResult)).

%% 装备进阶
hook_equip_upgrade(RoleID, EquipInfo) ->
	#p_goods{typeid=TypeID}=EquipInfo,
	[#p_equip_base_info{slot_num=_SlotNum}] = common_config_dyn:find_equip(TypeID),
	catch mod_role_event:notify(RoleID, {?ROLE_EVENT_EQUIP, EquipInfo}),
	hook_mission_event:hook_equip_upgrade(RoleID,_SlotNum),
	?TRY_CATCH(mod_examine_fb:hook_equip_upgrade(RoleID,EquipInfo)).

%% 装备提色
hook_equip_upgrade_color(RoleID, EquipInfo) ->
	#p_goods{typeid=TypeID}=EquipInfo,
	[#p_equip_base_info{slot_num=SlotNum}] = common_config_dyn:find_equip(TypeID),
	hook_mission_event:hook_equip_upgrade_color(RoleID,SlotNum),
	?TRY_CATCH(mod_examine_fb:hook_equip_upgrade(RoleID,EquipInfo)).
