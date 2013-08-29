%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 玩家装备附带BUFF
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------
-module(mod_equip_buff).

-export ([calc/5, calc/3]).

-include("mgeer.hrl").

calc(RoleBase, Op1, Equip1, Op2, Equip2) ->
	calc(calc(RoleBase, Op1, Equip1), Op2, Equip2).

calc(RoleBase, '+', Equip) ->
	mod_role_buff:add_buff2(RoleBase, equip_buffs(Equip));
calc(RoleBase, '-', Equip) ->
	mod_role_buff:del_buff2(RoleBase, equip_buffs(Equip)).

equip_buffs(#p_goods{typeid = EquipTypeID}) ->
	cfg_equip_helper:buffs(EquipTypeID);
equip_buffs(_) -> [].