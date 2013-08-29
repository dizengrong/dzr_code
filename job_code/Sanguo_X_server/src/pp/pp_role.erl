%% Author: dzr
%% Created: 2011-8-13
%% Description: 
-module(pp_role).

%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%
-export([handle/3]).

%%=============================================================================
%% API Functions
%%=============================================================================

handle(15000, PlayerId, _) ->
	mod_role:client_get_employed_list(PlayerId);

handle(15010, PlayerId, _) ->
	%% TO-DO: 佣兵装备请求
	EquipmentList = mod_items:getAllRoleItems(PlayerId),
	{ok, Packet} = pt_15:write(15010, EquipmentList),
	lib_send:send_by_id(PlayerId, Packet);

handle(15020, PlayerId, {RoleId, IsBattle}) ->
	mod_role:client_change_battle_state(PlayerId, {RoleId, IsBattle});

handle(15100, PlayerId, _) ->
	mod_role:client_get_employable_list(PlayerId);

handle(15101, PlayerId, _) ->
	mod_role:client_get_fired_list(PlayerId);

handle(15102, PlayerId, {RoleId, Action}) ->
	case Action of
		0 ->
			mod_role:client_fire(PlayerId, RoleId);
		1 ->
			mod_role:client_employ(PlayerId, RoleId)
	end;	

handle(15200, PlayerId, {RoleId, AttriId, IsProtected, AutoUseCard}) ->
	mod_role:client_up_talent(PlayerId, RoleId, AttriId, IsProtected, AutoUseCard);

handle(15201, PlayerId, {RoleId, ReservedList}) ->
	mod_role:client_refresh_skill(PlayerId, RoleId, ReservedList);

handle(15202, PlayerId, {ARoleId, BRoleId, PreservedSkillList}) ->
	mod_role:client_A_to_B(PlayerId, ARoleId, BRoleId, PreservedSkillList);

handle(15210, PlayerId, {RoleId, AutoUseCard}) ->
	mod_role:client_foster(PlayerId, RoleId, AutoUseCard);

handle(15300, PlayerId, _) ->
	mod_role:client_get_junwei(PlayerId);

handle(15301, PlayerId, _) ->
	mod_role:client_get_zhaoshu_flag(PlayerId);

handle(15302, PlayerId, _) ->
	mod_role:client_get_free_zhaoshu(PlayerId);

handle(15303, PlayerId, ZhaoshuType) ->
	mod_role:client_buy_zhaoshu(PlayerId, ZhaoshuType);

handle(15400, PlayerId, ID) ->
	{ok,BinData} = pt_15:write(15400,ID),
	lib_send:send(PlayerId,BinData);

handle(15401,PlayerId,{ID,RoleId}) ->
	RoleRec = role_base:get_employed_role_rec(ID,RoleId),
	ItemList = cache_items:getItemsByRole(ID, RoleId),
	{ok,BinData} = pt_15:write(15401,{RoleRec,ItemList}),
	lib_send:send(PlayerId,BinData);

handle(15501,PlayerId,{RoleId,SkillId,ItemID,Num}) ->
	mod_role:client_up_skill(PlayerId,RoleId,SkillId,ItemID,Num);

handle(Cmd, _PlayerId, _) ->
	?ERR(to_do, "protocal ~w not implemented", [Cmd]),
	ignore_this_protocal.