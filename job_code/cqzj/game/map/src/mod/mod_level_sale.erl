%%% @author dizengrong 
%%% @doc
%%%     福利界面的等级优惠抢购sale
%%% @end
%%% Created : 2013-2-25
%%%-------------------------------------------------------------------
-module (mod_level_sale).
-include("mgeem.hrl").

-export([handle/3]).

%% export for role_misc callback
-export([init_sale/2, delete_sale/1]).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, Method, Msg)).

init_sale(RoleID, LevelSaleRec) ->
    case LevelSaleRec of
        false -> 
            LevelSaleRec1 = #r_level_sale{};
        _ -> 
            LevelSaleRec1 = LevelSaleRec
    end,
    mod_role_tab:put({r_level_sale, RoleID}, LevelSaleRec1).

delete_sale(RoleID) ->
    mod_role_tab:erase({r_level_sale, RoleID}).

get_sale_data(RoleID) ->
	mod_role_tab:get({r_level_sale, RoleID}).
set_sale_data(RoleID, LevelSaleRec) ->
    mod_role_tab:put({r_level_sale, RoleID}, LevelSaleRec).


handle(RoleID, Method, DataIn) ->
	case Method of
		?ACTIVITY_LV_SALE_INFO ->
			send_sale_info_to_client(RoleID);
		?ACTIVITY_LV_SALE_BUY ->
			buy_sale_goods(RoleID, DataIn)
	end.

make_p_level_sale_goods(SaleId, Category, IsBuyed) ->
	{OrgPrice, CurPrice, {TypeId, Num, _, IsBind}} = cfg_activity:sale_goods(SaleId, Category),
	#p_level_sale_goods{
		sale_id   = SaleId,
		typeid    = TypeId,
		org_price = OrgPrice,
		cur_price = CurPrice,
		bind      = IsBind,
		num       = Num,
		is_buyed  = IsBuyed
	}.

send_sale_info_to_client(RoleID) ->
	LevelSaleRec   = get_sale_data(RoleID),
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	Category       = RoleAttr#p_role_attr.category,
	Fun = fun({Lv, SaleIdList}, Acc) ->
		case Lv > RoleAttr#p_role_attr.level of
			true -> Acc;
			false ->
				GoodsList = [make_p_level_sale_goods(SaleId, Category, lists:member(SaleId, LevelSaleRec#r_level_sale.buyed_list)) 
					    || SaleId <- SaleIdList],
				[#p_sale_level{level = Lv, goods_list = GoodsList} | Acc]
		end
	end,
	Msg = #m_activity_lv_sale_info_toc{
		sale_data = lists:foldl(Fun, [], cfg_activity:all_sale_level())
	},
	?MOD_UNICAST(RoleID, ?ACTIVITY_LV_SALE_INFO, Msg).

buy_sale_goods(RoleID, DataIn) ->
	{ok, RoleAttr}      = mod_map_role:get_role_attr(RoleID),
	SaleId              = DataIn#m_activity_lv_sale_buy_tos.sale_id,
	{_, CurPrice, {ItemId,ItemNum,_,_} = Item } = cfg_activity:sale_goods(SaleId, RoleAttr#p_role_attr.category),
	{ok, FreeBagNum}    = mod_bag:get_empty_bag_pos_num(RoleID, 1),
	LevelSaleRec        = get_sale_data(RoleID),
	IsBuyed             = lists:member(SaleId, LevelSaleRec#r_level_sale.buyed_list),
	SaleLv              = get_level_by_sale_id(SaleId),
	Ret = if
		RoleAttr#p_role_attr.level < SaleLv -> {error, <<"您等级不足，不能购买">>};
		1 > FreeBagNum -> {error, ?_LANG_SHOP_BAG_NOT_ENOUGH};
		IsBuyed -> {error, <<"您已经购买过了，不能再次购买">>};
		true ->
			case common_transaction:t(
				   fun() -> common_bag2:t_deduct_money(gold_unbind, CurPrice, RoleID,?CONSUME_TYPE_LV_SALE_BUY,ItemId,ItemNum) end
				   ) of
        		{atomic,{ok,RoleAttr2}} ->
        			{true, _} = mod_bag:add_items(RoleID, [Item], ?LOG_ITEM_TYPE_LV_SALE_BUY),
        			LevelSaleRec1 = LevelSaleRec#r_level_sale{
        				buyed_list = [SaleId | LevelSaleRec#r_level_sale.buyed_list]
        			},
					 common_misc:send_role_gold_change(RoleID, RoleAttr2),
        			set_sale_data(RoleID, LevelSaleRec1),
        			true;
        		{atomic, {error, Reason2}} ->
        			{error, Reason2};
        		{abort, Reason0} ->
        			{error, Reason0}
        	end
	end,
    case Ret of
		true ->
			Msg = #m_activity_lv_sale_buy_toc{sale_id = SaleId},
			?MOD_UNICAST(RoleID, ?ACTIVITY_LV_SALE_BUY, Msg);
			% send_sale_info_to_client(RoleID);
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason)
	end.


%% 根据sale id反查对应的等级
get_level_by_sale_id(SaleId) ->
	get_level_by_sale_id(SaleId, cfg_activity:all_sale_level()).

get_level_by_sale_id(SaleId, []) -> throw({mod_level_sale_error, SaleId});
get_level_by_sale_id(SaleId, [{Lv, SaleIdList} | Rest]) ->
	case lists:member(SaleId, SaleIdList) of
		true -> Lv;
		false -> get_level_by_sale_id(SaleId, Rest)
	end.

