%% Author: xiee
%% Created: 2012-8-24
%% Description: 家族商店
-module(mod_map_fmlshop).

%%
%% Include files
%%
-include("mgeem.hrl").
-include("shop.hrl").

-define(_fmlshop_buy, Unique, ?FMLSHOP, ?FMLSHOP_BUY, #m_fmlshop_buy_toc).
-define(_fmlshop_list, Unique, ?FMLSHOP, ?FMLSHOP_LIST, #m_fmlshop_list_toc).
-define(_fmlshop_error, Unique, ?FMLSHOP, ?FMLSHOP_ERROR, #m_fmlshop_error_toc).

-define(CONTRIBUTE, 5).


%%
%% Exported Functions
%%
-export([handle/1]).

%%
%% API Functions
%%
handle({Unique, _Module, ?FMLSHOP_LIST, _DataIn, _RoleID, PID, _Line}) ->
	common_misc:unicast2(PID, ?_fmlshop_list{items=cfg_family:shop_items()});

handle({Unique, _Module, ?FMLSHOP_BUY, DataIn, RoleID, PID, _Line}) ->
	#m_fmlshop_buy_tos{item_id = ItemID} = DataIn,
	{ok, #p_role_base{family_id = FamilyID}} = mod_map_role:get_role_base(RoleID),
	BuyPrice = get_buy_price(ItemID),
	#p_fmlshop_item{
		buy_type = BuyType
	} = lists:keyfind(ItemID, #p_fmlshop_item.item_id, cfg_family:shop_items()),
	case common_transaction:t(fun
		() ->
			{ok, NewRoleAttr}  = deduct_contribute(RoleID, BuyPrice),

			CrateGoodsInfo     = #r_goods_create_info{
				bind    = true, 
				type    = BuyType, 
				type_id = ItemID, 
				num     = 1
			},
			{ok, NewGoodsList} = mod_bag:create_goods(RoleID, CrateGoodsInfo),
			{ok, NewRoleAttr, NewGoodsList}
	end) of
		{atomic,{ok, NewRoleAttr, NewGoodsList}} ->
			ChangeList = [#p_role_attr_change{
				change_type = ?ROLE_FAMILY_CONTRIBUTE_CHANGE, 
				new_value   = NewRoleAttr#p_role_attr.family_contribute
			}],
			%% 完成成就
			mod_achievement2:achievement_update_event(RoleID, 42003, {1, ItemID}),
			common_misc:update_goods_notify({role, RoleID}, NewGoodsList),
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
			common_family:info(FamilyID, {add_contribution, RoleID, -BuyPrice}),
			common_misc:unicast2(PID, ?_fmlshop_buy{});
		{aborted,{bag_error,_}} ->
			common_misc:unicast2(PID, ?_fmlshop_error{msg = <<"背包已满">>});
		{aborted, Code} when is_integer(Code) -> 
			common_misc:unicast2(PID, ?_fmlshop_error{code = Code});
		{aborted, Msg} -> 
			common_misc:unicast2(PID, ?_fmlshop_error{msg = Msg})
	end.


%%
%% Local Functions
%%
deduct_contribute(RoleID, DeductContribue) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	NewContribue = RoleAttr#p_role_attr.family_contribute-DeductContribue,
	NewContribue >= 0 orelse throw({error, <<"家族贡献点不足">>}),
	{ok, RoleAttr#p_role_attr{family_contribute=NewContribue}}.

get_buy_price(ItemID) ->
	Item = lists:keyfind(ItemID, #p_fmlshop_item.item_id, cfg_family:shop_items()),
	Item#p_fmlshop_item.buy_price.
