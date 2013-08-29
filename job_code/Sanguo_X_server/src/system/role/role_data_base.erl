-module(role_data_base).

-include("common.hrl").

-export ([get_employable_list/1, add_employable/2, remove_a_employable_role/2]).

-compile(export_all).

get_employable_list(PlayerId) ->
	RoleDataRec = role_db:get_role_data(PlayerId),
	RoleDataRec#role_data.gd_EmployableList.

add_employable(PlayerId, RoleIdList) ->
	AllIdList = role_base:get_all_role_id_list(PlayerId),
	EmployableList = role_data_base:get_employable_list(PlayerId),
	RoleIdSet  = sets:from_list(lists:append(AllIdList, EmployableList)),
	Fun = fun(RoleId) -> (not sets:is_element(RoleId, RoleIdSet)) end,

	RoleIdList1 = lists:filter(Fun, RoleIdList),
	case RoleIdList1 of
		[] -> ok;
		_ ->
			NewEmployableList = sets:to_list(
				sets:from_list(lists:append(EmployableList, RoleIdList1))),
			role_db:update_role_data_fields(PlayerId, PlayerId, 
						[{#role_data.gd_EmployableList, NewEmployableList}])

	end,
	RoleIdList1.

%% 移除一个可招募的角色id
remove_a_employable_role(PlayerId, RoleId) ->
	EmployableList = get_employable_list(PlayerId),
	EmployableList1 = lists:delete(RoleId, EmployableList),
	role_db:update_role_data_fields(PlayerId, PlayerId, 
			[{#role_data.gd_EmployableList, EmployableList1}]).

%% 检测君威是否够，返回: true|false
check_junwei(PlayerId, Amount) ->
	(Amount =< role_db:get_junwei(PlayerId)).

%% 使用君威
use_junwei(PlayerId, Amount) ->
	OldAmount = role_db:get_junwei(PlayerId),
	role_db:set_junwei(PlayerId, OldAmount - Amount).

%% 打开使用诏书，使用成功则返回{true, 现有的总君威}
%% 参数：IsFree为true|false,表示是否免费打开诏书
open_zhaoshu(PlayerId, ZhaoshuType, IsFree) ->
	case IsFree of
		true -> 
			TJunWei = do_open_zhaoshu(PlayerId, ZhaoshuType),
			{true, TJunWei};
		false ->
			GoldCost = data_zhaoshu:get_open_cost(ZhaoshuType),
			case mod_economy:check_and_use_bind_gold(PlayerId, GoldCost, ?GOLD_BUY_ZHAOSHU) of
				true -> 
					TJunWei = do_open_zhaoshu(PlayerId, ZhaoshuType),
					{true, TJunWei};
				false -> {false, ?ERR_NOT_ENOUGH_GOLD}
			end
	end.

do_open_zhaoshu(PlayerId, ZhaoshuType) ->
	N = util:rand(1, 100),
	AddedJunwei = data_zhaoshu:get_rand_junwei(ZhaoshuType, N),
	Total = role_db:get_junwei(PlayerId) + AddedJunwei,
	role_db:set_junwei(PlayerId, Total),

	Total.
