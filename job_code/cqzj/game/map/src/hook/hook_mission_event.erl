%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     特殊任务事件的hook
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(hook_mission_event).
-export([
         hook_jingjie/2,
         hook_enter_sw_fb/2,
         hook_enter_hero_fb/2,
         hook_special_event/2
        ]).

-export([
         hook_pet_attack_aptitude/2,
         hook_equip_qianghua/3,
		 hook_equip_upgrade/2,
         hook_pet_grow/2,
         hook_pet_levelup/2,
         hook_pet_understand/2,
         hook_vip_up/2,
		 hook_skill_upgrade/2,
		 hook_ybc/2,
         hook_equip_upgrade_color/2,
         hook_nuqi_skill_upgrade/3,
         hook_nuqi_shape_upgrade/2
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mission.hrl").

%% SpecialEventId 请参考mission_event.hrl
%% 对应特殊事件的任务
hook_special_event(RoleID,SpecialEventId)->
	?TRY_CATCH(mod_mission_handler:handle({listener_dispatch, special_event, RoleID, SpecialEventId}) ).

hook_vip_up(RoleID,VipLevel)->
    ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, role_vip_up, RoleID, VipLevel}) ).


%% 对应特殊事件的任务和具体参数值（例如境界升到哪个境界）
hook_jingjie(RoleID,BarrierId)->
    ?TRY_CATCH(mod_mission_handler:handle({listener_dispatch, special_listener_value, RoleID, ?MISSION_LISTENER_TYPE_JINGJIE,BarrierId}) ).

hook_enter_hero_fb(RoleID,BarrierId)->
    ?TRY_CATCH(mod_mission_handler:handle({listener_dispatch, special_listener_value, RoleID, ?MISSION_LISTENER_TYPE_ENTER_HERO_FB,BarrierId}) ).

hook_enter_sw_fb(RoleID,FbType)->
    ?TRY_CATCH(mod_mission_handler:handle({listener_dispatch, special_listener_value, RoleID, ?MISSION_LISTENER_TYPE_ENTER_SW_FB,FbType}) ).

hook_pet_levelup(RoleID,NewLevel)->
    ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_PET_LEVELUP, NewLevel}) ).

hook_pet_grow(RoleID,GrowLevel)->
    ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_PET_GROW, GrowLevel}) ).

hook_pet_understand(RoleID,UnderstandLevel)->
    ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_PET_UNDERSTAND, UnderstandLevel}) ).

hook_pet_attack_aptitude(RoleID,AttackAptitude)->
    ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_PET_ATTACK_APTITUDE, AttackAptitude}) ).

hook_equip_qianghua(RoleID,SlotNum,ReinforceResult)->
	SpecialListenerType = 
		if
			SlotNum =:= ?PUT_MOUNT ->
				?MISSION_LISTENER_TYPE_MOUNT_QIANGHUA;
			SlotNum =:= ?PUT_FASHION ->
				?MISSION_LISTENER_TYPE_FASHION_QIANGHUA;
			true ->
				?MISSION_LISTENER_TYPE_EQUIP_QIANGHUA
		end,
	?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, SpecialListenerType, ReinforceResult}) ).

hook_equip_upgrade(RoleID,SlotNum)->
	?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value, RoleID, ?MISSION_LISTENER_TYPE_EQUIP_UPGRADE, SlotNum}) ).

hook_equip_upgrade_color(RoleID,SlotNum)->
    hook_special_event(RoleID,?MISSON_EVENT_EQUIP_UPGRADE_COLOR),
    ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value, RoleID, ?MISSION_LISTENER_TYPE_EQUIP_SLOTNUM_UPGRADE_COLOR, SlotNum}) ).

hook_skill_upgrade(RoleID,SkillLevel)->
	?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_SKILL_UPGRADE, SkillLevel}) ).

hook_ybc(RoleID,Times)->
	?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_YBC, Times}) ).

hook_nuqi_skill_upgrade(RoleID, SkillID, SkillLevel) ->
    NuqiShapeNum = mod_role_skill:get_nuqi_skill_shape_num(SkillID),
    case NuqiShapeNum > 1 of
        true -> ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_NUQI_SKILL_UPGRADE, 10000}) );
        false -> ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_NUQI_SKILL_UPGRADE, SkillLevel}) )
    end.

hook_nuqi_shape_upgrade(RoleID, SkillID) ->
    NuqiShapeNum = mod_role_skill:get_nuqi_skill_shape_num(SkillID),
    ?TRY_CATCH( mod_mission_handler:handle({listener_dispatch, special_listener_value_up, RoleID, ?MISSION_LISTENER_TYPE_NUQI_SHAPE_UPGRADE, NuqiShapeNum}) ).



