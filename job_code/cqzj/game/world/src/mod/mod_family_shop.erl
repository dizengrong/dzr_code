%% Author: xiee
%% Created: 2012-8-24
%% Description: 家族商店
-module(mod_family_shop).

-define(UNICAST(Rec), common_misc:unicast2(PID, Unique, Module, Method, Rec)).
-define(UNICAST(Method, Rec), common_misc:unicast2(PID, Unique, Module, Method, Rec)).
-define(UNICAST(Module, Method, Rec), common_misc:unicast2(PID, Unique, Module, Method, Rec)).
-define(UNICAST_ERROR(Msg), common_misc:unicast2(PID, Unique, ?FMLSHOP, ?FMLSHOP_ERROR, #m_fmlshop_error_toc{msg = Msg})).
-define(UNICAST_CODE(Msg), common_misc:unicast2(PID, Unique, ?FMLSHOP, ?FMLSHOP_ERROR, #m_fmlshop_error_toc{code = Msg})).


%%
%% Include files
%%
-include("mgeew.hrl").
-include("mgeew_family.hrl").

%%
%% Exported Functions
%%
-export([handle/1, delete/1]).

%%
%% API Functions
%%
handle({Unique, _Module, ?FMLSHOP_ADD, DataIn, RoleID, PID, _Line}) ->
	#m_fmlshop_add_tos{item_id=ItemID} = DataIn,
	AllShopItems = common_config_dyn:list(family_shop),
	State = mod_family:get_state(),
	FamilyInfo = State#family_state.family_info,
	case FamilyInfo#p_family_info.owner_role_id of
	RoleID ->
		case lists:keyfind(ItemID, #p_fmlshop_item.item_id, AllShopItems) of
		false ->
			?UNICAST_ERROR(<<"参数非法">>);
		#p_fmlshop_item{add_price=AddPrice} ->
			FamilyID = FamilyInfo#p_family_info.family_id,
			BuyableItems = get_buyable_items(FamilyID),
			case lists:member(ItemID, BuyableItems) of
			true ->
				?UNICAST_ERROR(<<"该道具已被激活">>);
			false ->
				OldMoney = FamilyInfo#p_family_info.money,
				case OldMoney >= AddPrice of
				true ->
					NewMoney = OldMoney - AddPrice,
					mod_family:update_state(State#family_state{family_info=FamilyInfo#p_family_info{money=NewMoney}}),
					set_buyable_items(FamilyID, [ItemID|BuyableItems]),
					mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_MONEY, #m_family_money_toc{new_money=NewMoney}),
					mod_family:broadcast_to_all_members(?FMLSHOP, ?FMLSHOP_ADD, #m_fmlshop_add_toc{item_id=ItemID});
				false ->
					?UNICAST_ERROR(<<"家族资金不足">>)
				end
			end
		end;
	_ ->
		?UNICAST_ERROR(<<"只有族长才能进行该操作">>)
	end.
	
delete(FamilyID) ->
	db:dirty_delete(?DB_FAMILY_SHOP, FamilyID).
%%
%% Local Functions
%%
get_buyable_items(FamilyID) ->
	case db:dirty_read(?DB_FAMILY_SHOP, FamilyID) of
	[] ->
		[];
	[#r_family_shop{items=Items}] ->
		Items
	end.

set_buyable_items(FamilyID, BuyableItems) ->
	db:dirty_write(?DB_FAMILY_SHOP, #r_family_shop{family_id=FamilyID, items=BuyableItems}).
