%% Author: fangshaokong
%% Created: 2012-2-14
%% Description: 装备发光
-module(mod_equip_shine).
%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([load_equip/3,unload_equip/2]).

%%
%% API Functions
%%

load_equip(SlotNum,RoleAttr,EquipInfo) ->
	#p_role_attr{skin=Skin} = RoleAttr,
	EquipShineValue = role_equip_shine_value(SlotNum,EquipInfo,Skin),
	NewRoleAttr=RoleAttr#p_role_attr{skin=Skin#p_skin{light_code=[EquipShineValue]}},
	NewRoleAttr.

unload_equip(SlotNum,RoleAttr) ->
	#p_role_attr{skin=Skin} = RoleAttr,
	#p_skin{light_code=LightCode} = Skin,
	EquipShineValue = 
		case SlotNum of
			?PUT_ARM -> %% 4：武器
				0;
			_ ->
				case LightCode =:= undefined orelse LightCode =:= [] of
					true ->
						0;
					false ->
						lists:nth(1,LightCode)
				end
		end,
	RoleAttr#p_role_attr{skin=Skin#p_skin{light_code=[EquipShineValue]}}.

%%
%% Local Functions
%%
%% 武器发光值 

role_equip_shine_value(SlotNum,EquipInfo,Skin) ->
	#p_goods{current_colour=Color} = EquipInfo,
	#p_skin{light_code=LightCode} = Skin,
	EquipShineValue = 
		case SlotNum of
			?PUT_ARM -> %% 4：武器
				equip_shine_value(Color);
			_ -> 
				case LightCode =:= undefined orelse LightCode =:= [] of
					true ->
						0;
					false ->
						lists:nth(1,LightCode)
				end
		end,
	EquipShineValue.

equip_shine_value(Color) ->
	case common_config_dyn:find(equip_shine, {equip,Color}) of
		[] -> 0;
		[ShineValue] -> ShineValue
	end.
