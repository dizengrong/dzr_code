%% Author: ldk
%% Created: 2012-5-17
%% Description: TODO: Add description to mod_egg_shop
-module(mod_egg_shop).

%%
%% Include files
%%
-include("mgeem.hrl").
-include("shop.hrl").
%%
%% Exported Functions
%%
-export([handle/1,
		 hook_vip_up/3,
		 hook_role_online/2,
		 refresh_daily_counter_times/2
		]).

-define(EGG_BUY_INFO_NUM,20).
%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_EGG_SHOP_SYS,1030001).%%系统错误
-define(ERR_EGG_NOT_VIP,1030002).%%不是VIP不能刷新
-define(ERR_EGG_USE_EGG_BAG_FULL,1030003).%%背包空间不足
-define(ERR_EGG_SHOP_BUY,1030004).%%已经购买过这种物品了
-define(ERR_EGG_NOT_THIS_ITEM,1030005).%%商店中不存在这种物品
-define(ERR_EGG_NOT_ENOUGH_REFRESH_MONEY,1030006).%%刷新不够钱
-define(ERR_EGG_NOT_ENOUGH_BUY_MONEY,1030007).%%购买不够钱


-define(SHOP_NUM,6).%%显示几个物品
%%
%% API Functions
%%

refresh_daily_counter_times(RoleID,RemainTimes) when erlang:is_integer(RemainTimes) ->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
	{_,FreeRefresh} = lists:keyfind(VipLevel, 1, FreeRefreshList),
	case get_role_expshop_info(RoleID) of
		{error,_} ->
			mod_daily_counter:set_mission_remain_times(RoleID, ?EGG_REFRESH_SHOP, FreeRefresh, false);
		{_,OpenTime,Shop,ShowNum,BuyItems,Items,FreeRefresh1,RefreshTime} ->
			case is_today(RefreshTime) of
				true ->
					RealRemainTimes = 
						case RemainTimes > 0 of
							true ->
								RemainTimes;
							_ ->
								FreeRefresh1
						end;
				false ->
					RealRemainTimes = 
						case RemainTimes > 0 of
							true ->
								RemainTimes;
							_ ->
								FreeRefresh
						end
			end,
			set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,BuyItems,Items,OpenTime,RealRemainTimes,common_tool:now()),
			mod_daily_counter:set_mission_remain_times(RoleID, ?EGG_REFRESH_SHOP, RealRemainTimes, false)
	end.

hook_vip_up(RoleID,OldLevel, NewLevel) ->
	case get_role_expshop_info(RoleID) of
		{error,_} ->
			ignore;
		{_,OpenTime,Shop,ShowNum,BuyItems,Items,FreeRefresh,RefreshTime} ->
			[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
			{_,OldFreeRefresh} = lists:keyfind(OldLevel, 1, FreeRefreshList),
			{_,NewFreeRefresh} = lists:keyfind(NewLevel, 1, FreeRefreshList),
			FreeRefresh2 = NewFreeRefresh - (OldFreeRefresh - FreeRefresh),
			Items1 = get_discount_items(Items,NewLevel),
			set_role_expshop_info(RoleID,NewLevel,Shop,ShowNum,BuyItems,Items1,OpenTime,FreeRefresh2,RefreshTime)
	end.

hook_role_online(RoleID,_) ->
	case get_role_expshop_info(RoleID) of
		{error,_} ->
			ignore;
		{_,OpenTime,Shop,ShowNum,BuyItems,Items,_,RefreshTime} ->
			case is_today(RefreshTime) of
				true ->
					ignore;
				false ->
					VipLevel = mod_vip:get_role_vip_level(RoleID),
					[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
					{_,FreeRefresh} = lists:keyfind(VipLevel, 1, FreeRefreshList),
					set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,BuyItems,Items,OpenTime,FreeRefresh,common_tool:now())
			end
	end.

handle({_,_,?EGG_OPEN_SHOP,_,_,_,_,_State}=Msg) ->
    do_open_shop(Msg);
handle({_,_,?EGG_SHOP_BUY,_,_,_,_,_State}=Msg) ->
    do_shop_buy(Msg);
handle({_,_,?EGG_REFRESH_SHOP,_,_,_,_,_State}=Msg) ->
    do_refresh_shop(Msg);

handle({reset_freerefresh,RoleID}) ->
	do_reset_freerefresh(RoleID);

handle(Other) ->
    ?ERROR_MSG("~ts:~w",["未知消息", Other]).

t_set_role_egg_shop_info(RoleID, EggShopInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewRoleExtInfo = RoleExtInfo#r_role_map_ext{egg_shop=EggShopInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		_ ->
			?THROW_SYS_ERR()
	end.

set_role_egg_shop_info(RoleID, EggShopInfo) ->
	case common_transaction:t(
		   fun()-> 
				   t_set_role_egg_shop_info(RoleID, EggShopInfo)
		   end
							 ) of
		{atomic, ok} ->
			ok;
		{aborted, Error} -> 
			?ERROR_MSG("~ts:~w", ["设置神密商店时系统错误", Error]),
			{error, fail}
	end.

get_role_egg_shop_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{egg_shop=EggShopInfo}} ->
			EggShopInfo;
		_ ->
			{error, not_found}
	end.

set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,BuyItems,Items,ignore,FreeRefresh,RefreshTime) 
  when is_integer(VipLevel) andalso is_integer(RefreshTime) andalso is_integer(FreeRefresh) 
	andalso is_list(BuyItems) andalso is_list(Items)->
	NewEggShopInfo = #r_egg_shop{role_id=RoleID,open_time=common_tool:now(),free_refresh=FreeRefresh,
								 refresh_time=RefreshTime,vip_level=VipLevel,shop=Shop,show_num=ShowNum,buy_items=BuyItems,items=Items},
	set_role_egg_shop_info(RoleID, NewEggShopInfo);
set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,BuyItems,Items,OpenTime,FreeRefresh,RefreshTime) 
  when is_integer(VipLevel) andalso is_integer(RefreshTime) andalso is_integer(FreeRefresh) 
	andalso is_list(BuyItems) andalso is_list(Items) ->
	NewEggShopInfo = #r_egg_shop{role_id=RoleID,open_time=OpenTime,free_refresh=FreeRefresh,
								 refresh_time=RefreshTime,vip_level=VipLevel,shop=Shop,show_num=ShowNum,buy_items=BuyItems,items=Items},
	set_role_egg_shop_info(RoleID, NewEggShopInfo);
set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,BuyItems,Items,OpenTime,FreeRefresh,RefreshTime) ->
	?ERROR_MSG("set_role_expshop_info,RoleID==~w,VipLevel==~w,Shop==~w,ShowNum==~w,BuyItems==~w,Items==~w,OpenTime==~w,FreeRefresh==~w,RefreshTime==~w",
			   [RoleID,VipLevel,Shop,ShowNum,BuyItems,Items,OpenTime,FreeRefresh,RefreshTime]).

get_role_expshop_info(RoleID) ->
	case get_role_egg_shop_info(RoleID) of
		#r_egg_shop{vip_level=VipLevel,open_time=OpenTime,
					free_refresh=FreeRefresh,refresh_time=RefreshTime,shop=Shop,show_num=ShowNum,buy_items=BuyItems,items=Items} ->
			{VipLevel,OpenTime,Shop,ShowNum,BuyItems,Items,FreeRefresh,RefreshTime};
		_ ->
			{error,not_found}
	
	end.

%%
%% Local Functions
%%
do_reset_freerefresh(RoleID) ->
	EggShop = get_role_egg_shop_info(RoleID),
	case EggShop of
		#r_egg_shop{} ->
			VipLevel = mod_vip:get_role_vip_level(RoleID),
			[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
			{_,FreeRefresh} = lists:keyfind(VipLevel, 1, FreeRefreshList),
			mod_daily_counter:set_mission_remain_times(RoleID, ?EGG_REFRESH_SHOP, FreeRefresh, true),
			set_role_egg_shop_info(RoleID, EggShop#r_egg_shop{free_refresh=FreeRefresh,refresh_time=common_tool:now()});
		_ ->
			ignore
	end.

do_open_shop({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State}=Msg) ->
	#m_egg_open_shop_tos{is_open=IsOpen} = DataIn,
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	Now = common_tool:now(),
	try
		case get_role_expshop_info(RoleID) of
			{error,_}  ->
				open_first(Msg,VipLevel,Level,Now,IsOpen);
			{_,OpenTime,_,_,BuyItems,Items,FreeRefresh,RefreshTime} ->
				[AuthRefresh] = common_config_dyn:find(egg_shop,refresh_seconds),
				[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
				{_,FreeRefresh1} = lists:keyfind(VipLevel, 1, FreeRefreshList),
				case common_tool:now() - OpenTime > AuthRefresh of
					false ->
						R2 = get_open_shop_record(next,{FreeRefresh,VipLevel,BuyItems,Items,AuthRefresh - (common_tool:now() - OpenTime),FreeRefresh1});
					true ->
						[ShopTypeList] = common_config_dyn:find(egg_shop,shop_type),
						{ShopType,ShopItemList} = get_shop_items(VipLevel,Level,ShopTypeList),
						Goods1 = item_calculate_weight(?SHOP_NUM,ShopItemList,[]),
						Goods = get_discount_items(Goods1,VipLevel),
						set_role_expshop_info(RoleID,VipLevel,ShopType,?SHOP_NUM,[],Goods,Now,FreeRefresh,RefreshTime),
						R2 = get_open_shop_record(first,{FreeRefresh,VipLevel,Goods,AuthRefresh,FreeRefresh1})
				end,
				?UNICAST_TOC(R2#m_egg_open_shop_toc{is_open=IsOpen})
		end
	catch
		_ : R ->
			?ERROR_MSG("do_open_shop, error: ~w", [R]),
			set_role_egg_shop_info(RoleID, undefined),
			open_first(Msg,VipLevel,Level,Now,IsOpen)
	end,
	global:send(mod_egg_shop_server,{buy_infos,RoleID}).

open_first({Unique, Module, Method, _DataIn, RoleID, PID, _Line, _State},VipLevel,Level,Now,IsOpen) ->
	[ShopTypeList] = common_config_dyn:find(egg_shop,shop_type),
	[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
	[AuthRefresh] = common_config_dyn:find(egg_shop,refresh_seconds),
	{ShopType,ShopItemList} = get_shop_items(VipLevel,Level,ShopTypeList),
	{_,FreeRefresh} = lists:keyfind(VipLevel, 1, FreeRefreshList),
	Goods1 = item_calculate_weight(?SHOP_NUM,ShopItemList,[]),
	Goods = get_discount_items(Goods1,VipLevel),
	set_role_expshop_info(RoleID,VipLevel,ShopType,?SHOP_NUM,[],Goods,Now,FreeRefresh,Now),
	R2 = get_open_shop_record(first,{FreeRefresh,VipLevel,Goods,AuthRefresh,FreeRefresh}),
	?UNICAST_TOC(R2#m_egg_open_shop_toc{is_open=IsOpen}).

do_shop_buy({Unique,Module, Method, DataIn, RoleID, PID, _Line, _State}) -> 
	{ok,#p_role_attr{role_name=RoleName,gold_bind=GoldBind,gold=Gold}} = mod_map_role:get_role_attr(RoleID),
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	case catch check_can_buy(RoleID,GoldBind,Gold,DataIn,VipLevel) of
		{error,ErrCode} ->
			R2 = #m_egg_shop_buy_toc{err_code=ErrCode},
			?UNICAST_TOC(R2);
		{fail,_Reason} ->
			ignore;
		{ok,BuyItem,DiscountPrice,OpenTime,Shop,ShowNum,BuyItems,Items,FreeRefresh,RefreshTime} ->
			case BuyItem#r_egg_shop_goods.money_bind of
				true ->
					GoldType = gold_any;
				false ->
					GoldType = gold_unbind
			end,
			TransFunc = 
				fun() ->
						CreateInfo = #r_goods_create_info{
							bind       =BuyItem#r_egg_shop_goods.bind, 
							type       =BuyItem#r_egg_shop_goods.type, 
							start_time =BuyItem#r_egg_shop_goods.start_time,
							end_time   =BuyItem#r_egg_shop_goods.end_time,
							type_id    =BuyItem#r_egg_shop_goods.typeid,
							num        =BuyItem#r_egg_shop_goods.num
                        },
						{ok,GoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
						NewBuyItems    = [BuyItem|BuyItems],
						NewItems       = lists:delete(BuyItem, Items),
						case common_bag2:t_deduct_money(GoldType,DiscountPrice,RoleID,?CONSUME_TYPE_GOLD_EGG_SHOP_USE) of
							{ok,RoleAttr2}->
								{ok,RoleAttr2,GoodsList,NewBuyItems,NewItems};
							{error,Reason0}->
								?THROW_ERR(?ERR_OTHER_ERR, Reason0)
						end
				end,
			case common_transaction:transaction(TransFunc) of
				{aborted, {error,ErrCode,Reason}} ->
					R2 = #m_egg_shop_buy_toc{err_code=ErrCode, reason = Reason},
					?UNICAST_TOC(R2);
				{atomic, {ok,NewRoleAttr,GoodsList,NewBuyItems,NewItems}} ->
					global:send(mod_egg_shop_server,{buy,RoleID,RoleName,BuyItem#r_egg_shop_goods.typeid}),
					common_misc:update_goods_notify(PID, GoodsList),
					common_misc:send_role_gold_change(RoleID, NewRoleAttr),
					set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,NewBuyItems,NewItems,OpenTime,FreeRefresh,RefreshTime),
					R2 = #m_egg_shop_buy_toc{items=[#p_egg_shop_item{typeid=BuyItem#r_egg_shop_goods.typeid,
																	 org_price=BuyItem#r_egg_shop_goods.org_price,
																	 cur_price=BuyItem#r_egg_shop_goods.cur_price,
																	 num=BuyItem#r_egg_shop_goods.num,
																	 bind=BuyItem#r_egg_shop_goods.bind,buy=false,
																	 discount=BuyItem#r_egg_shop_goods.discount,
																	 is_max_discount=BuyItem#r_egg_shop_goods.is_max_discount}]},
					?UNICAST_TOC(R2);
				{aborted, Reason} ->
					?ERROR_MSG("神秘商店刷新系统错误, error: ~w", [Reason])
			end
	
	end.	
%%这里面的#r_egg_shop_goods.cur_price是黄钻价
get_discount_price(RoleID,BuyItem) ->
	case catch mod_qq_cache:get_vip(RoleID) of
		{ok,true,_,_} ->
			if
				BuyItem#r_egg_shop_goods.discount > 0 ->
					common_tool:floor(BuyItem#r_egg_shop_goods.cur_price*BuyItem#r_egg_shop_goods.discount/10);
				true ->
					BuyItem#r_egg_shop_goods.cur_price
			end;
		{ok,false,_,_} ->
			if
				BuyItem#r_egg_shop_goods.discount > 0 ->
					common_tool:floor(BuyItem#r_egg_shop_goods.org_price*BuyItem#r_egg_shop_goods.discount/10);
				true ->
					BuyItem#r_egg_shop_goods.org_price
			end;
		Reason ->
			?ERROR_MSG("ERR:Get Discount Price Error ~p ~n",[Reason]),
			BuyItem#r_egg_shop_goods.org_price
	end.
	
do_refresh_shop({Unique, Module, Method, _DataIn, RoleID, PID, _Line, _State}=Msg) ->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	case get_role_expshop_info(RoleID) of
		{error,_} ->
			R2 = #m_egg_refresh_shop_toc{err_code=?ERR_EGG_SHOP_SYS},
			?UNICAST_TOC(R2);
		{_,_,_,ShowNum,_BuyItems,_Items,FreeRefresh,RefreshTime} ->
			[ShopTypeList] = common_config_dyn:find(egg_shop,shop_type),
			{ShopType,_ShopItemList} = get_shop_items(VipLevel,Level,ShopTypeList),
			case FreeRefresh > 0 of
				false ->
					case check_can_refresh(VipLevel) of
						ok ->
							do_refresh_not_free(Msg,{ShopType,ShowNum,VipLevel,RefreshTime});
						{error,ErrorCode} ->
							R2 = #m_egg_refresh_shop_toc{err_code=ErrorCode},
							?UNICAST_TOC(R2)
					end;
				true ->
					do_refresh_free(Msg,{ShopType,ShowNum,VipLevel,FreeRefresh,RefreshTime})
			end
	end.

do_refresh_free({Unique, Module, Method, _DataIn, RoleID, PID, _Line, _State},{Shop,ShowNum,VipLevel,FreeRefresh,RefreshTime}) ->
	[ShopItemList] = common_config_dyn:find(egg_shop,Shop),
	[RefreshGoldList] = common_config_dyn:find(egg_shop,refresh_gold),
	[AuthRefresh] = common_config_dyn:find(egg_shop,refresh_seconds),
	[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
	{_,FreeRefresh1} = lists:keyfind(VipLevel, 1, FreeRefreshList),
	{_,RefreshGold} = lists:keyfind(VipLevel, 1, RefreshGoldList),
	Goods1 = item_calculate_weight(ShowNum,ShopItemList,[]),
	Goods = get_discount_items(Goods1,VipLevel),
	set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,[],Goods,common_tool:now(),FreeRefresh-1,RefreshTime),
	mod_daily_counter:set_mission_remain_times(RoleID, ?EGG_REFRESH_SHOP, FreeRefresh-1, true),
	R2 = get_refresh_shop_record({Goods,RefreshGold,FreeRefresh-1,VipLevel,AuthRefresh,FreeRefresh1}),
	?UNICAST_TOC(R2).

do_refresh_not_free({Unique, Module, Method, _DataIn, RoleID, PID, _Line, _State},{Shop,ShowNum,VipLevel,RefreshTime}) ->
	[RefreshGoldList] = common_config_dyn:find(egg_shop,refresh_gold),
	{_,RefreshGold} = lists:keyfind(VipLevel, 1, RefreshGoldList),
	TransFunc = 
		fun() ->
				case common_bag2:t_deduct_money(gold_unbind,RefreshGold,RoleID,?CONSUME_TYPE_GOLD_EGG_SHOP_USE) of
					{ok,RoleAttr2}->
						{ok,RoleAttr2};
					{error,Reason0}->
						?THROW_ERR(?ERR_OTHER_ERR, Reason0)
				end
		end,
	case common_transaction:transaction(TransFunc) of
		{aborted, {error,ErrCode,Reason}} ->
			R2 = #m_egg_refresh_shop_toc{err_code=ErrCode, reason = Reason},
			?UNICAST_TOC(R2);
		{atomic, {ok,NewRoleAttr}} ->
			common_misc:send_role_gold_change(RoleID, NewRoleAttr),
			[AuthRefresh] = common_config_dyn:find(egg_shop,refresh_seconds),
			[ShopItemList] = common_config_dyn:find(egg_shop,Shop),
			[FreeRefreshList] = common_config_dyn:find(egg_shop,free_refresh),
			{_,FreeRefresh1} = lists:keyfind(VipLevel, 1, FreeRefreshList),
			Goods1 = item_calculate_weight(ShowNum,ShopItemList,[]),
			Goods = get_discount_items(Goods1,VipLevel),
			set_role_expshop_info(RoleID,VipLevel,Shop,ShowNum,[],Goods,common_tool:now(),0,RefreshTime),
			%% 完成成就
			mod_achievement2:achievement_update_event(RoleID, 33004, 1),
			mod_achievement2:achievement_update_event(RoleID, 34006, 1),
			mod_achievement2:achievement_update_event(RoleID, 42002, 1),
			R2 = get_refresh_shop_record({Goods,RefreshGold,0,VipLevel,AuthRefresh,FreeRefresh1}),
			?UNICAST_TOC(R2);
		{aborted, Reason} ->
			?ERROR_MSG("神秘商店刷新系统错误, error: ~w", [Reason])
	end.

get_max_discount(BaseRateList) ->
	SortBaseRateList = lists:keysort(1, BaseRateList),
	lists:last(SortBaseRateList).

get_discount_items(Goods,VipLevel)->
	[BaseRateList] = common_config_dyn:find(egg_shop, shop_refresh_rate),
	{Discount,Rate} = get_max_discount(BaseRateList),
	[VipAddRateList] = common_config_dyn:find(egg_shop, shop_refresh_vip_rate),
	case lists:keyfind(VipLevel, 1, VipAddRateList) of
		{_,VipRate} when VipRate > 0 ->
			lists:map(fun(R)->
							  NewBaseRateList = lists:keystore(Discount, 1, BaseRateList, {Discount,Rate+VipRate}),
							  {NewDiscount,_} = common_tool:random_from_tuple_weights(NewBaseRateList, 2),
							  IsMaxDiscount = Discount=:= NewDiscount,
							  R#r_egg_shop_goods{discount=NewDiscount,is_max_discount=IsMaxDiscount}
					  end, Goods);
		_ ->
			Goods
	end.

check_can_refresh(VipLevel) ->
	case VipLevel > 0 of
		true ->
			ok;
		false ->
			{error,?ERR_EGG_NOT_VIP}
	end.

check_can_buy(RoleID,GoldBind,Gold,DataIn,_VipLevel) ->
	#m_egg_shop_buy_tos{typeid=TypeID,num=Num,bind=Bind,cur_price=CurPrice,money_bind=MoneyBind} = DataIn,
	
	
	if
		is_integer(Num) andalso Num>0 andalso Num<?MAX_USE_NUM ->
			ok;
		true->
			throw({error,?ERR_EGG_SHOP_SYS})
	end,
	case get_role_expshop_info(RoleID) of
		{error,_} ->
			throw({error,?ERR_EGG_SHOP_SYS});
		{_,OpenTime,Shop,ShowNum,BuyItems,Items,FreeRefresh,RefreshTime}  ->
			case check_in_items(TypeID,Num,Bind,MoneyBind,CurPrice,BuyItems) of
				[] ->
					next;
				_BuyItem ->
					throw({error,?ERR_EGG_SHOP_BUY})
			end,
			
			case check_in_items(TypeID,Num,Bind,MoneyBind,CurPrice,Items) of
				[] ->
					throw({error,?ERR_EGG_NOT_THIS_ITEM});
				BuyItem ->
					{ok,DiscountPrice} = check_money_enough(RoleID,MoneyBind,GoldBind,Gold,BuyItem),
					{ok,BuyItem,DiscountPrice,OpenTime,Shop,ShowNum,BuyItems,Items,FreeRefresh,RefreshTime}
					% creat_goods(BuyItem,RoleID,{DiscountPrice,Shop,ShowNum,BuyItems,Items,FreeRefresh,RefreshTime})
			end
	end.

check_money_enough(RoleID,MoneyBind,GoldBind,Gold,BuyItem)->
	CurPrice1 = get_discount_price(RoleID,BuyItem),
	case MoneyBind of
		true ->
			case GoldBind+Gold >= CurPrice1 of
				true ->
					{ok,CurPrice1};
				false ->
					throw({error,?ERR_EGG_NOT_ENOUGH_BUY_MONEY})
			end;
		_ ->
			case Gold >= CurPrice1 of
				true ->
					{ok,CurPrice1};
				false ->
					throw({error,?ERR_EGG_NOT_ENOUGH_BUY_MONEY})
			end
	end.

check_in_items(TypeID,Num,Bind,MoneyBind,CurPrice,Items) ->
	catch lists:foldl(fun(Item,Acc) ->
						#r_egg_shop_goods{typeid=TypeID1,bind=Bind1,num=Num1,money_bind=MoneyBind1,cur_price=CurPrice1} = Item,
						case TypeID =:= TypeID1 andalso Bind =:= Bind1 andalso Num =:= Num1 
							andalso MoneyBind =:= MoneyBind1 andalso CurPrice =:= CurPrice1 of
							true ->
								throw(Item);
							false ->
								Acc
						end
						end, [], Items).
	
get_refresh_shop_record({Goods,RefreshGold,FreeRefresh,VipLevel,AuthRefresh,MaxFreeRefresh}) ->
	Items = 
	lists:map(fun(#r_egg_shop_goods{typeid=TypeID,bind=Bind,money_bind=MoneyBind,num=Num,org_price=OrgPrice,cur_price=CurPrige,discount=Discount,is_max_discount=IsMaxDiscount}) ->
					  #p_egg_shop_item{typeid=TypeID,org_price=OrgPrice,money_bind=MoneyBind,
									   cur_price=CurPrige,num=Num,bind=Bind,
									   discount=Discount,is_max_discount=IsMaxDiscount,buy=true}
					  end, Goods),
	#m_egg_refresh_shop_toc{items=Items,refresh_money=RefreshGold,max_free_refresh=MaxFreeRefresh,
							seconds=AuthRefresh,free_refresh=FreeRefresh,vip_level=VipLevel}.

get_open_shop_record(first,{RreeRefresh,VipLevel,Goods,Seconds,MaxRreeRefresh}) ->
	[RefreshGoldList] = common_config_dyn:find(egg_shop,refresh_gold),
	{_,RefreshGold} = lists:keyfind(VipLevel, 1, RefreshGoldList),
	Items = 
	lists:map(fun(#r_egg_shop_goods{typeid=TypeID,bind=Bind,num=Num,org_price=OrgPrice,
									cur_price=CurPrige,money_bind=MoneyBind,
									discount=Discount,is_max_discount=IsMaxDiscount}) ->
					  #p_egg_shop_item{typeid=TypeID,org_price=OrgPrice,
									   cur_price=CurPrige,num=Num,bind=Bind,buy=true,
									   money_bind=MoneyBind,discount=Discount,is_max_discount=IsMaxDiscount}
					  end, Goods),
	#m_egg_open_shop_toc{vip_level=VipLevel,items=Items,seconds=Seconds,
						 refresh_money=RefreshGold,free_refresh=RreeRefresh,max_free_refresh=MaxRreeRefresh};
get_open_shop_record(next,{RreeRefresh,VipLevel,BuyItems,OtherItems,Seconds,MaxRreeRefresh}) ->
	[RefreshGoldList] = common_config_dyn:find(egg_shop,refresh_gold),
	{_,RefreshGold} = lists:keyfind(VipLevel, 1, RefreshGoldList),
	Items = 
	lists:map(fun(#r_egg_shop_goods{typeid=TypeID,bind=Bind,num=Num,org_price=OrgPrice,
									cur_price=CurPrige,money_bind=MoneyBind,
									discount=Discount,is_max_discount=IsMaxDiscount}=Item) ->
					  Buy = 
					  case lists:member(Item, BuyItems) of
						  false ->
							  true;
						  _ ->
							  false
					  end,
					  #p_egg_shop_item{typeid=TypeID,org_price=OrgPrice,
									   cur_price=CurPrige,num=Num,bind=Bind,
									   buy=Buy,money_bind=MoneyBind,
									   discount=Discount,is_max_discount=IsMaxDiscount}
					  end, BuyItems ++ OtherItems),
	#m_egg_open_shop_toc{vip_level=VipLevel,items=Items,seconds=Seconds,
						 refresh_money=RefreshGold,free_refresh=RreeRefresh,max_free_refresh=MaxRreeRefresh}.

item_calculate_weight(0,_ShopList,ReturnGoods) ->
	ReturnGoods;
item_calculate_weight(ShowNum,ShopList,[]) ->
	Goods = item_calculate_return_one(ShopList),
	item_calculate_weight(ShowNum-1,ShopList--[Goods],[Goods]);
item_calculate_weight(ShowNum,ShopList,ReturnGoods) ->
	Goods = item_calculate_return_one(ShopList),
	case check_goods_in_list(Goods,ReturnGoods) of
		[] ->
			item_calculate_weight(ShowNum-1,ShopList--[Goods],[Goods|ReturnGoods]);
		_ ->
			item_calculate_weight(ShowNum,ShopList,ReturnGoods)
	end.

check_goods_in_list(Good,ReturnGoods) ->
	lists:foldl(fun(Item,Acc) ->
						case Item =:= Good of
							true ->
								[Good|Acc];
							false ->
								Acc
						end
						end, [], ReturnGoods).

item_calculate_return_one(ShopList) ->
	AllWeight = 
	lists:foldl(fun(#r_egg_shop_goods{rate=Weight},Acc) ->
						Acc + Weight
						end, 0, ShopList),
	{A1,A2,A3} = erlang:now(),
	random:seed(A1, A2, A3),	
	Rate = random:uniform(AllWeight),
	catch lists:foldl(fun(#r_egg_shop_goods{rate=Weight} = Goods ,Acc) ->
						case Rate > Weight + Acc of
							true ->
								Weight + Acc;
							false ->
								throw(Goods)
						end
						end, 0, ShopList).


is_today(Time) ->
	{Date,_} = common_tool:seconds_to_datetime(Time),
	Date =:= erlang:date().

get_shop_items(VipLevel,Level,[{MinVIP,MaxVip,LevelShopList}|_ShopTypeList]) when VipLevel >= MinVIP andalso VipLevel =< MaxVip ->
	get_shop_items_by_level(Level,LevelShopList);
get_shop_items(VipLevel,Level,[{_MinVIP,_MaxVip,_LevelShopList}|ShopTypeList]) ->
	get_shop_items(VipLevel,Level,ShopTypeList).
	
get_shop_items_by_level(Level,[{MinLevel,MaxLevel,ShopType}|_LevelShopList]) when Level >= MinLevel andalso Level =< MaxLevel ->
	[ShopItemList] = common_config_dyn:find(egg_shop,ShopType),
	{ShopType,ShopItemList};
get_shop_items_by_level(Level,[{_MinLevel,_MaxLevel,_ShopType}|LevelShopList]) ->
	get_shop_items_by_level(Level,LevelShopList).
	