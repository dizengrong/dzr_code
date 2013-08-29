-module(mod_shop).

-include("mgeem.hrl").
-include("shop.hrl").
-include("activity.hrl").

-export([
			init/0,
			handle/1,
			handle/2,
			loop/0,
			is_bag_shop/1,
			bag_shop_conf/2
		]).

-export([
			get_goods_price/1,
			get_goods_price/2,
			get_goods_price_in_all_shop/1,
			update_bag_shop/5,
			check_shop_buy/4,
			creat_goods/5,
			new_property/1,
			assert_num/1
		]).

%% 固定时间刷新商店
loop() ->
	%% 固定由蚩尤-涿鹿来刷新促销商店
	case mgeem_map:get_mapid() =:= 10260 of
		true ->
		    {_, {H, M, _}} = erlang:localtime(),
			{Hour2, Min2, _} = ?BAG_SHOP_REFRESH_TIME,
			case Hour2 =:= H andalso M =:= Min2 of
				true ->
					check_is_init_bag_shop();
				false ->
					ignore
			end;
		false ->
			ignore
	end.

handle({_,_,?SHOP_BUY,_,_,_,_,_}=Msg) ->
	do_shop_buy(Msg);
handle({_,_,?SHOP_SHOPS,_,_,_,_,_}=Msg) ->
	do_shop_shops(Msg);
handle({_,_,?SHOP_ALL_GOODS,_,_,_,_,_}=Msg) ->
	do_shop_all_goods(Msg);
handle({_,_,?SHOP_SEARCH,_,_,_,_,_}=Msg) ->
	do_shop_search(Msg);
handle({_,_,?SHOP_NPC,_,_,_,_,_}=Msg) ->
	do_shop_npc(Msg);
handle({_,_,?SHOP_SALE,_,_,_,_,_}=Msg) ->
	do_shop_sale(Msg);
handle({_,_,?SHOP_ITEM,_,_,_,_,_}=Msg) ->
	do_shop_item(Msg);
handle({_,_,?SHOP_BUY_BACK,_,_,_,_,_}=Msg) ->
	do_shop_buy_back(Msg);
handle(Other) ->
	?ERROR_MSG("~ts:~w",["未知消息", Other]).

handle(force_reload_bag_shop,_State) ->
    force_reload_bag_shop().
	
%% return {MoneyType,Price} | error
%% MoneyType = silver_unbind | silver_any | gold_unbind | gold_any
get_goods_price_in_all_shop(GoodsID) ->
	get_goods_price_in_all_shop2(?ALL_SHOP_IDS,GoodsID).
get_goods_price_in_all_shop2([],_GoodsID) ->
	error;
get_goods_price_in_all_shop2([ShopID|T],GoodsID) ->
	case get_goods_price(ShopID, GoodsID) of
		error ->
			get_goods_price_in_all_shop2(T,GoodsID);
		Found ->
			Found
	end.

%% @doc 获取道具价格(不打折,默认在快速购买商店70023里获取)
%% return error | {MoneyType,Price}
%% MoneyType = silver_unbind | silver_any | gold_unbind | gold_any
get_goods_price(GoodsID) ->
	get_goods_price(?QUICK_BUY_SHOP_ID,GoodsID).
get_goods_price(ShopID,GoodsID) ->
	case common_config_dyn:find(shop_shops, ShopID) of
		[Shop] ->
			case lists:keyfind(GoodsID, #r_shop_goods.id, Shop#r_shop_shops.goods) of
				false ->
					error;
				ShopGoods ->
					get_goods_price2(ShopGoods)
			end;
		_ ->
			?ERROR_MSG("get_goods_price error,ShopID=~w,GoodsID=~w",[ShopID,GoodsID]),
			error
	end.
get_goods_price2(ShopGoods) ->
	#r_shop_goods{price_bind=PriceBind, price=[ShopPrice],discount_type=DiscountType} = ShopGoods,
	#p_shop_price{currency=[ShopCurrency]} = ShopPrice,
	#p_shop_currency{id=ID, amount=Price} = ShopCurrency,
	CostPrice = 
		if
			DiscountType =:= 0 ->
				Price;
			DiscountType =:= 1 ->
				Price;
			true -> 
				DiscountType
		end,

	%% PriceBind 检查货币绑定类型 3 要求不绑定 其他(1,2)可以用非绑定
	%% ID 货币类型 1 银两 2元宝
	if ID =:= 1 ->
		   if
			   PriceBind =:= 3 ->
				   {silver_unbind,CostPrice};
			   true ->
				   {silver_any,CostPrice}
		   end;
	   true ->
		   if
			   PriceBind =:= 3 ->
				   {gold_unbind,CostPrice};
			   true ->
				   {gold_any,CostPrice}
		   end
	end.

%%@interface 获取某件物品的商品价格信息
do_shop_item({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State})->
	#m_shop_item_tos{shop_id=ShopID,item_type_id=ItemTypeID} = DataIn,
	case common_config_dyn:find(shop_shops, ShopID) of
		[R] -> 
			case lists:keyfind(ItemTypeID, #r_shop_goods.id,  R#r_shop_shops.goods) of
				false ->
					?SEND_ERR_TOC(m_shop_item_toc,?_LANG_SHOP_CANNT_FIND_THIS_GOODS,PID);
				Goods ->
					ShopGoods = get_shop_all_goods(RoleID,ShopID,Goods),
					R2 = #m_shop_item_toc{succ=true,shop_id=ShopID,goods=ShopGoods},
					?UNICAST_TOC(R2)
			end;
		_  ->
			?SEND_ERR_TOC(m_shop_item_toc,?_LANG_SHOP_CANNT_FIND_THIS_SHOP,PID)
	end.
%%购买商品----------------------------------------------------------------------------
do_shop_buy({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State}) ->
	#m_shop_buy_tos{goods_id=TypeID, goods_num=Num, shop_id=ShopID} = DataIn,
	case catch check_shop_buy(RoleID,TypeID,Num,ShopID) of
		{ok,RoleAttr,ShopGoods,BagShop} ->
			case common_transaction:t(
				   fun() ->
						   t_shop_buy(RoleID,DataIn,RoleAttr,ShopGoods)
				   end) of
				{atomic, {qq_buy_goods, Token}} ->
					erlang:put({qq_buy_goods, Token}, {ShopID, TypeID});
				{atomic, {ok,NewRoleAttr,[GoodsBuyInfo|_]=GoodsList}} ->
					update_bag_shop(RoleID,ShopID,TypeID,BagShop,Num),
					%% 特殊任务事件
					hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_SHOP_BUY),
					?TRY_CATCH(common_item_logger:log(RoleID,GoodsBuyInfo,Num,?LOG_ITEM_TYPE_SHANG_DIAN_GOU_MAI),Err2),
					?TRY_CATCH(hook_prop:hook(shop_buy, [GoodsBuyInfo#p_goods{current_num=Num}]),Err3),
					?UNICAST_TOC(#m_shop_buy_toc{succ=true,goods=GoodsList,property=new_property(NewRoleAttr)});
				{aborted, {error,ErrCode,Reason}} ->
					?UNICAST_TOC(#m_shop_buy_toc{succ=false,error_code=ErrCode,reason=Reason});
				{aborted, Reason} ->
					?ERROR_MSG("do_shop_buy error=~w",[Reason]),
					?UNICAST_TOC(#m_shop_buy_toc{succ=false,reason=?_LANG_SYSTEM_ERROR})
			end;
		{error,ErrCode,Reason} ->
			?UNICAST_TOC(#m_shop_buy_toc{succ=false,error_code=ErrCode,reason=Reason})
	end.

%% 是否可以购买道具
check_shop_buy(RoleID,TypeID,Num,ShopID) ->
	assert_num(Num),
	ShopGoods = assert_in_shop(ShopID,TypeID),
	assert_vip_shop(RoleID,ShopGoods),
	{ok,RoleAttr} = assert_role_level(RoleID, ShopGoods),
	BagShop = assert_bag_shop(RoleID,ShopID,ShopGoods,Num),
    %% 在富甲天下期间不能购买兑换银票
    case lists:member(ShopGoods#r_shop_goods.id, [10100008,10100009,10100010,10100011,10100012]) of
        true ->
            case common_misc:get_event_state(schedule_activity) of
                {ok, #r_event_state{data=#r_schedule_data{activity_id=?ACTIVITY_SCHEDULE_SILVER, start_time=StartTime, end_time=EndTime}}} ->
                    Now = common_tool:now(),
                    if Now >= StartTime andalso EndTime >= Now ->
						   ?THROW_ERR_REASON(?_LANG_SHOP_CAN_BUY_IN_ACTIVITY_SCHEDULE_SILVER);
                       true ->
                           ok
                    end;
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
	{ok,RoleAttr,ShopGoods,BagShop}.
t_shop_buy(RoleID,DataIn,RoleAttr,ShopGoods)->
	#m_shop_buy_tos{price_id=PriceID,shop_id=ShopID,goods_id=TypeID,goods_num=Num}=DataIn,
	case lists:keyfind(PriceID,#p_shop_price.id,ShopGoods#r_shop_goods.price) of
		false -> ?THROW_SYS_ERR();
		ShopPrice ->
			%% PriceBind 检查货币绑定类型 3 要求不绑定 其他(1,2)可以用非绑定
			%% ItemBind 1根据货币 2强制绑定 3强制不绑定
			%% CurrencyList 一个商品可以用不同货币来出售
			%% DiscountType 折扣类型 0不打折 1VIP折扣 其他值表示折扣价格
			%% ID 货币类型 1 银两 2元宝
			%% Price 价格
			#r_shop_goods{bind=ItemBind,price_bind=PriceBind,discount_type=DiscountType} = ShopGoods,
			#p_shop_price{currency=Currency} = ShopPrice,
			case Currency of
				[] -> CostPrice = ID = 0;
				[#p_shop_currency{id=ID,amount=Price}|_] ->
					CostPrice = 
						if
							DiscountType =:= 0 ->
								Price;
							DiscountType =:= 1 ->
								common_tool:floor(Price * (mod_vip:get_vip_shop_discount(RoleAttr#p_role_attr.role_id) / 100));
							true -> 
								DiscountType
						end
			end,
			{ok, Num2} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
			NeedBagNum = case ShopGoods#r_shop_goods.type of
				?TYPE_EQUIP ->
					Num;
				_ ->
					Num div 90 + if Num rem 90 > 0 -> 1; true -> 0 end
			end,
			NeedBagNum =< Num2 orelse ?THROW_ERR_REASON(?_LANG_SHOP_BAG_NOT_ENOUGH),
			case money_type(ID,PriceBind) of
				{gold_unbind, _} when CostPrice == 0 ->
					{ok,GoodsList} = creat_goods(Num,ShopGoods,RoleID,_Bind=true,ShopID),
					{ok,RoleAttr,GoodsList};
				{gold_unbind, _} when CostPrice > 0 ->
					% Amt  = CostPrice*Num,
					case mod_qq_helper:check_buy_goods(RoleID, RoleAttr#p_role_attr.gold, {CostPrice, Num}) of
						ok ->
							Token = mod_qq_helper:get_buy_goods_token(RoleID, TypeID, CostPrice, Num, {CostPrice, Num}, false),
							{qq_buy_goods, Token};
						{error, Reason} ->
							?THROW_ERR_REASON(Reason)
					end;
				_ ->
					calc_shop_buy(RoleID,RoleAttr,ID,CostPrice,Num,ItemBind,PriceBind,ShopGoods,ShopID)
			end
	end.

%% return {ok,RoleAttr,GoodsList}
calc_shop_buy(RoleID,RoleAttr,ID,CostPrice,Num,ItemBind,PriceBind,ShopGoods,ShopID) ->
	#p_role_attr{silver_bind=OldSilverBind,gold_bind=OldGoldBind} = RoleAttr,
	{MoneyType,ConsumeLogType} = money_type(ID,PriceBind),
	case common_bag2:t_deduct_money(MoneyType,CostPrice*Num,RoleID,ConsumeLogType,ShopGoods#r_shop_goods.id,Num) of
		{ok,NewRoleAttr} ->
			next;
		{error,gold_any} ->
			NewRoleAttr = null,
			?THROW_ERR(?ERR_GOLD_NOT_ENOUGH);
		{error,silver_unbind} ->
			NewRoleAttr = null,
			?THROW_ERR(?ERR_SILVER_NOT_ENOUGH);
		{error,silver_any} ->
			NewRoleAttr = null,
			?THROW_ERR(?ERR_SILVER_NOT_ENOUGH);
		{error, Reason} ->
			NewRoleAttr = null,
			?THROW_ERR(?ERR_OTHER_ERR, Reason)
	end,
	#p_role_attr{silver_bind=SilverBind,gold_bind=GoldBind} = NewRoleAttr,
	GoodsID = ShopGoods#r_shop_goods.id,
	{ok,GoodsList} = 
		case ItemBind of
			1 -> %%根据货币
				case CostPrice =:= 0 of
					true ->
						creat_goods(Num,ShopGoods,RoleID,_Bind=true,ShopID);
					false ->
						case PriceBind of
							3 -> %%一定不绑定
								creat_goods(Num,ShopGoods,RoleID,false,ShopID);
							_ -> %%可以用绑定
								BuyBindNum = 
									case MoneyType of
										silver_any ->
											common_tool:ceil((OldSilverBind-SilverBind) / CostPrice);
										_ ->
											common_tool:ceil((OldGoldBind-GoldBind) / CostPrice)
									end,
								{ok,GoodsList1} = creat_goods(BuyBindNum,ShopGoods,RoleID,true,ShopID),
								{ok,GoodsList2} = creat_goods(Num-BuyBindNum,ShopGoods,RoleID,false,ShopID),
								{ok,lists:append([GoodsList1,GoodsList2])}
						end
				end;
			2 -> %%强制绑定 
				creat_goods(Num,ShopGoods,RoleID,_Bind=true,ShopID);
			3 when GoodsID == 10100007;
				   GoodsID == 10100086;
				   GoodsID == 10100029 ->
				creat_goods(Num,ShopGoods,RoleID,_Bind=true,ShopID);
			3 -> %%强制不绑定
				creat_goods(Num,ShopGoods,RoleID,_Bind=false,ShopID)
		end,
	{ok,NewRoleAttr,GoodsList}.

money_type(ID,PriceBind) ->
	if
		ID =:= 1 -> 
			{case PriceBind of
				 3 ->
					 silver_unbind;
				 _ ->
					 silver_any
			 end,?CONSUME_TYPE_SILVER_BUY_ITEM_FROM_SHOP};
		true -> 
			{case PriceBind of
				 3 ->
					 gold_unbind;
				 _ ->
					 gold_any
			 end,?CONSUME_TYPE_GOLD_BUY_ITEM_FROM_SHOP}
	end.

update_bag_shop(RoleID,ShopID,ItemID,#r_bag_shop{}=BagShop, Num) ->
    db:dirty_write(?DB_BAG_SHOP,BagShop),
	add_role_bag_shop(RoleID, ShopID, ItemID, Num);
update_bag_shop(_,_,_,_,_) ->
    ignore.

%% 数量判断
assert_num(Num) ->
	if
		is_integer(Num) andalso Num>0 andalso Num=<?MAX_USE_NUM ->
			next;
		true->
			?THROW_ERR_REASON(?_LANG_SHOP_NUMBER_MUST_MORE_THAN_ZERO)
	end.

%% 物品是否在商店中
assert_in_shop(ShopID,TypeID) ->
	case common_config_dyn:find(shop_shops, ShopID) of
		[ShopShops] ->
			case lists:keyfind(TypeID, #r_shop_goods.id, ShopShops#r_shop_shops.goods) of
				false ->
					?THROW_ERR_REASON(?_LANG_SHOP_NOT_THIS_GOODS);
				ShopGoods ->
					ShopGoods
			end;
		_ ->
			?THROW_ERR_REASON(?_LANG_SHOP_DOES_NOT_EXIST)
	end.
%% vip权限判断
assert_vip_shop(RoleID,ShopGoods) ->
	#r_shop_goods{modify=Modify} = ShopGoods,
	case Modify of
		<<"VIP">> ->
			case mod_vip:is_role_vip(RoleID) of
				true ->
					ok;
				_ ->
					?THROW_ERR_REASON(?_LANG_SHOP_BUY_ONLY_VIP)
			end;
		_ ->
			ok
	end.
%% 等级判断
assert_role_level(RoleID,ShopGoods) ->
	{ok,#p_role_attr{level=Level}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
	#r_shop_goods{role_grade=[MinLevel,MaxLevel]} = ShopGoods,
	case Level >= MinLevel andalso Level =< MaxLevel of
		true -> next;
		false -> ?THROW_ERR_REASON(?_LANG_LEVEL_NOT_ENOUGH)
	end,
	{ok,RoleAttr}.
%% 是否限量购买
assert_bag_shop(RoleID,ShopID,ShopGoods,Num) ->
	case db:dirty_read(?DB_BAG_SHOP,ShopID) of
        [] -> 
        	undefined;
        [BagShop] ->
            case lists:keytake(ShopGoods#r_shop_goods.id,#r_shop_goods.id,BagShop#r_bag_shop.shop_items) of
                false ->
					?THROW_ERR_REASON(?_LANG_SHOP_AGAIN_OPEN_SHOP);
                {value, Item, NewItems} ->
                    {ok,NewItem}=check_role_bag_shop_buy_num(RoleID, ShopID, Item, Num),
					BagShop#r_bag_shop{shop_items=[NewItem|NewItems]}
            end
    end.

creat_goods(N,#r_shop_goods{time=[StartTime,EndTime],type=Type,id=ID,num=Num},RoleID,Bind,ShopID) when is_integer(N),N>0 ->
	%%如果商店ID是70024(特殊的快速购买-强化),需要自动加上强化等级，读取qianghua.config里的give_qianghua_level_equip_list,interface_type=give_qianghua_level
	InterfaceType =
		case ShopID of
			70024 -> give_qianghua_level;
			_ -> buy
		end,
	CreateInfo = #r_goods_create_info{bind=Bind,type=Type,start_time=StartTime,end_time=EndTime,
									  type_id=ID,num=N * Num,interface_type=InterfaceType},
	case catch mod_bag:create_goods(RoleID, CreateInfo) of
		{bag_error,{not_enough_pos,_BagID}} ->
			?THROW_ERR_REASON(?_LANG_SHOP_BAG_NOT_ENOUGH);
		{bag_error,goods_not_found} ->
			?THROW_ERR_REASON(?_LANG_SHOP_NOT_THIS_GOODS);
		{ok,GoodsList} ->
			{ok,GoodsList}
	end;
creat_goods(0,_ShopGoods,_RoleID,_Bind,_ShopID) ->
    {ok,[]}.

%%获取所有的商店列表------------------------------------------------------------------------
do_shop_shops({Unique, Module, Method, _DataIn, _RoleID, PID, _Line,_State}) ->
	R2 = case common_config_dyn:find(shop_npcs,shops) of
			 [Record] ->
				 Shops = [branch_shop(ShopInfo) || ShopInfo <- Record#r_shop_npc.shops],
				 #m_shop_shops_toc{shops = Shops};
			 [] ->
				 #m_shop_shops_toc{shops=[]}
		 end,
	?UNICAST_TOC(R2).

branch_shop(#p_shop_info{branch_shop=CShopIDs} = ShopInfo) ->
	ShopInfo#p_shop_info{branch_shop = 
							 lists:reverse(lists:foldl(
											 fun(ShopID, Acc) ->
													 case common_config_dyn:find(shop_shops, ShopID) of
														 [] -> Acc;
														 [#r_shop_shops{name=Name}] ->
															 [#p_shop_info{id=ShopID,name=Name,branch_shop=[]}|Acc]
													 end
											 end,[],CShopIDs))}.


%%获取指定商店的商品列表------------------------------------------------------------------------
do_shop_all_goods({Unique, Module, Method, DataIn, RoleID, PID, _Line,_State}) ->
	#m_shop_all_goods_tos{npc_id=NPCID,shop_id=ShopID}=DataIn,
	R = #m_shop_all_goods_toc{npc_id=NPCID,shop_id=ShopID,all_goods=[],recommend=0},
	R2 = 
		case common_config_dyn:find(shop_npcs, convert_npc_id(NPCID)) of
			[] -> R;
			_ ->
				case is_bag_shop(ShopID) of
					true ->
						case db:dirty_read(?DB_BAG_SHOP, ShopID) of
							[] ->
								R;
							[BagShop] ->
								case common_config_dyn:find(shop_shops, ShopID) of
									[ShopShops] ->
										BagShopItems = lists:foldl(fun(H, Acc) ->
											#r_bag_shop_item{item_id = ItemId} = H, 
											case lists:keyfind(ItemId, #r_shop_goods.id, ShopShops#r_shop_shops.goods) of
												false ->
													Acc;
												ShopItem ->
													[ShopItem|Acc]
											end
										end, [], BagShop#r_bag_shop.shop_items),
										AllGoods = get_shop_all_goods(RoleID,ShopID,BagShopItems),
										#m_shop_all_goods_toc{npc_id=NPCID,shop_id=ShopID,all_goods=lists:reverse(AllGoods),recommend=get_bag_shop_recommend(ShopID)};
									_ -> R
								end
						end;
					_ ->
						case common_config_dyn:find(shop_shops, ShopID) of
							[ShopShops] ->
								AllGoods = get_shop_all_goods(RoleID,ShopID,ShopShops#r_shop_shops.goods),
								#m_shop_all_goods_toc{npc_id=NPCID,shop_id=ShopID,all_goods=lists:reverse(AllGoods),recommend=get_bag_shop_recommend(ShopID)};
							_ -> R
						end							
				end					
		end,
	?UNICAST_TOC(R2).

%%搜索指定的商品----------------------------------------------------------------------
do_shop_search({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_shop_search_tos{search_goods_id=GoodsIDList, npc_id=NPCID} = DataIn,
    R = case common_config_dyn:find(shop_npcs, convert_npc_id(NPCID)) of
            [Re] ->
                do_search2(Re#r_shop_npc.shops,RoleID,GoodsIDList,[], 1);
            [] ->
                #m_shop_search_toc{search_all_goods = [],npc_id=NPCID} 
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_search2([],_, _GoodsIDList,GoodsList, _Seat) ->
    #m_shop_search_toc{search_all_goods = GoodsList};
do_search2([Shop|T],RoleID,GoodsIDList,GoodsList, Seat) when is_integer(Shop) ->
    case common_config_dyn:find(shop_shops, Shop) of
        [R] ->
            {NewGoodsList, NewSeat} = 
                get_search_goods(GoodsIDList, RoleID, GoodsList, R#r_shop_shops.id,R#r_shop_shops.goods, Seat),
            do_search2(T,RoleID, GoodsIDList, NewGoodsList, NewSeat);
        [] ->
            do_search2(T,RoleID, GoodsIDList, GoodsList, Seat)
    end;
do_search2([Shop|T],RoleID,GoodsIDList,GoodsList, Seat) ->	   
    case Shop#p_shop_info.branch_shop of
        [] ->
            do_search2([Shop#p_shop_info.id|T],RoleID,GoodsIDList,GoodsList, Seat);
        BShops ->
            do_search2(lists:append(BShops,T),RoleID,GoodsIDList,GoodsList, Seat)
    end.

get_search_goods([], _, GoodsList, _, _, Seat) ->
    {GoodsList, Seat};
get_search_goods([H|T], RoleID, GoodsList,ShopID, RGoodsList, Seat) ->
    case lists:keyfind(H, 2, RGoodsList) of
        false ->
            get_search_goods(T,RoleID,GoodsList,ShopID,RGoodsList,Seat);
        Goods ->
            NewGoods = Goods#r_shop_goods{seat = Seat},
            case catch get_shop_all_goods(RoleID,ShopID,NewGoods) of
                undefined -> get_search_goods(T, RoleID, GoodsList,ShopID,RGoodsList,Seat);
                PGoods when is_record(PGoods,p_shop_goods_info) -> get_search_goods(T,RoleID, [PGoods|GoodsList],ShopID,RGoodsList,Seat+1);
				_ -> get_search_goods(T, RoleID, GoodsList,ShopID,RGoodsList,Seat)
            end
    end.

%%获取npc商店的信息------------------------------------------------------------------
do_shop_npc({Unique, Module, Method, DataIn, _RoleID, PID, _Line,_State}) ->
    #m_shop_npc_tos{npc_id = NPCID} = DataIn,
    R2 = case common_config_dyn:find(shop_npcs, NPCID) of
            [ShopNpc] ->
                #m_shop_npc_toc{npc_id=NPCID,shops = ShopNpc#r_shop_npc.shops};
            _ ->
                #m_shop_npc_toc{npc_id=NPCID,shops=[]}
        end,
	?UNICAST_TOC(R2).

%%把物品卖给npc商店------------------------------------------------------------------
do_shop_sale({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State}) ->
    #m_shop_sale_tos{goods = SaleList} = DataIn,
    case db:transaction(fun() -> t_shop_sale(SaleList, RoleID) end) of
        {atomic,{NewRoleAttr,GoodsList,GoodsBuyBackList, Addtion}} ->
            Property = new_property(NewRoleAttr),
			lists:foreach(
			  fun(Goods) ->
					  common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_CHU_SHOU_XI_TONG)
			  end,GoodsList),
            R2 = #m_shop_sale_toc{succ=true, property=Property,ids=[SaleGoods#p_shop_sale_goods.id||SaleGoods<-SaleList]},
			?UNICAST_TOC(R2),
			?ROLE_CENTER_BROADCAST(RoleID, common_misc:format_lang(?_LANG_SHOP_SELL_RETRUN, [Addtion])),
            hook_buy_back_sale(RoleID,GoodsBuyBackList);
        {aborted, Reason} ->
			?SEND_ERR_TOC(m_shop_sale_toc,Reason,PID)
    end.

get_goods_sale_price(Goods) ->
    #p_goods{sell_price=SellPrice,
             level=Level,
             current_endurance=CE,
             endurance=ES,
             refining_index=RI,
             current_colour=Colour}=Goods,  
    common_tool:ceil((SellPrice*math:pow(1.22,RI)*math:pow(Level/5,1.5)+math:pow(Colour-1,4)*10)*CE/ES).

t_shop_sale(SellList, RoleID) -> 
	{AddSilver,AddBindSilver,NewGoodsBuyBackList} = 
		lists:foldl(
		  fun(#p_shop_sale_goods{id = Id, type_id = TypeID}, {Silver, BindSilver,GoodsBuyBackList}) ->
				  case mod_bag:get_goods_by_id(RoleID, Id) of
					  {ok, Goods} ->
						  #p_goods{bind=Bind, type=Type, sell_type=SellType, current_num=Num} = Goods,
						  case SellType of
							  ?UNAVAI ->
								  db:abort(?_LANG_SHOP_GOODS_CANT_SELL);
							  _ ->
								  ok
						  end,
						  case Type =:= ?TYPE_EQUIP of
							  true ->
								  NewPrice = get_goods_sale_price(Goods),
								  case Bind of
									  true ->
										  {Silver, BindSilver + NewPrice*Num,[Goods|GoodsBuyBackList]};
									  false ->
										  {Silver + NewPrice*Num, BindSilver,[Goods|GoodsBuyBackList]}
								  end;
							  false  ->
								  [#p_item_base_info{buy_price = SellPrice}] = common_config_dyn:find_item(TypeID),
								  NewPrice = SellPrice, 
								  case Bind of
									  true ->
										  {Silver, BindSilver + NewPrice*Num,[Goods|GoodsBuyBackList]};
									  false ->
										  {Silver + NewPrice*Num, BindSilver,[Goods|GoodsBuyBackList]}
								  end
						  end;
					  {error, Reason} ->
						  db:abort(Reason)
				  end
		  end, {0, 0,[]}, SellList),
	GoodsIDList = [GID || #p_shop_sale_goods{id=GID} <- SellList],
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
	%{ok,RoleAttr2} = common_bag2:t_gain_money(silver_unbind, AddSilver, RoleAttr, ?GAIN_TYPE_SILVER_SALE_ITEM_FROM_SHOP),
	%{ok,NewRoleAttr} = common_bag2:t_gain_money(silver_bind, AddBindSilver, RoleAttr2, ?GAIN_TYPE_SILVER_SALE_ITEM_FROM_SHOP),
	{ok, NewRoleAttr} = common_bag2:t_gain_money(silver_bind, AddSilver + AddBindSilver, RoleAttr, ?GAIN_TYPE_SILVER_SALE_ITEM_FROM_SHOP),
	mod_map_role:set_role_attr(RoleID, NewRoleAttr),    
	{ok, GoodsList} = mod_bag:delete_goods(RoleID, GoodsIDList),
	{NewRoleAttr, GoodsList, NewGoodsBuyBackList, AddSilver + AddBindSilver}.

%%---------------------------------------------------------------------------------
get_shop_transform_fun(ShopID,IsPayed)->
	fun(#r_shop_goods{id=ID,price=[ShopPrice],bind=BindTmp,type=Type,discount_type=DiscountType,
					  seat=Seat,time=Time,role_grade=RoleGrade,modify=Modify,price_bind=PriceBind}=ShopGoods) ->
			{Num,LimitBuyNum} = bag_shop_num(ShopID,ShopGoods,IsPayed),    
			Bind =
				case BindTmp of
					2 -> true;
					_ -> false
				end,
			{Property,Colour} = 
				case Type of
					?TYPE_ITEM ->
						get_item_pro_colour(ID);
					?TYPE_STONE ->
						get_stone_pro_colour(ID);
					?TYPE_EQUIP ->
						get_equip_pro_colour(ID)
				end,
			#p_shop_price{currency=Currency} = ShopPrice,
			NewShopPrice = 
				case Currency of
					[] -> ShopPrice#p_shop_price{currency=[{p_shop_currency,2,0}]};
					_ -> ShopPrice
				end,
			#p_shop_goods_info{
								  goods_id=ID,seat_id=Seat,packe_num=Num,time=Time,
								  role_grade=RoleGrade,goods_bind=Bind,goods_modify=Modify,
								  price=[NewShopPrice],type=Type,colour=Colour,property=Property,
								  discount_type=DiscountType,shop_id=ShopID,price_bind=PriceBind,
								  limit_buy_num=LimitBuyNum
							  }
	end.
    
%% 限量抢购是否需要充值才显示判断
assert_pay_bag_shop(NeedPayed,IsPayed) ->
	case NeedPayed =:= true andalso IsPayed =/= true of
		true ->
			throw(need_payed);
		false ->
			next
	end.

%%获取商店中的商品列表
get_shop_all_goods(RoleID,ShopID,ShopGoods) when is_record(ShopGoods,r_shop_goods) -> 
	{ok,#p_role_attr{is_payed=IsPayed}} = mod_map_role:get_role_attr(RoleID),
	F = get_shop_transform_fun(ShopID,IsPayed),
	F(ShopGoods);
get_shop_all_goods(RoleID,ShopID,ShopGoodsList) when is_list(ShopGoodsList) -> 
	{ok,#p_role_attr{is_payed=IsPayed}} = mod_map_role:get_role_attr(RoleID),
	F = get_shop_transform_fun(ShopID,IsPayed),
	lists:foldl(fun(G,Acc) -> 
						case catch F(G) of
							R when is_record(R,p_shop_goods_info) ->
								[R|Acc];
							_Reason ->
								Acc
						end
				end, [], ShopGoodsList).

%%构造玩家的财产列表
new_property(NewRoleAttr) ->
	[    
		NewRoleAttr#p_role_attr.silver, 
		NewRoleAttr#p_role_attr.silver_bind,
		NewRoleAttr#p_role_attr.gold,
		NewRoleAttr#p_role_attr.gold_bind
	].

get_item_pro_colour(TypeID) ->
    [BaseInfo] = common_config_dyn:find_item(TypeID),
    {undefined,BaseInfo#p_item_base_info.colour}.   

get_stone_pro_colour(TypeID) ->
    [BaseInfo] = common_config_dyn:find_stone(TypeID),
    {BaseInfo#p_stone_base_info.level_prop,BaseInfo#p_stone_base_info.colour}.

get_equip_pro_colour(TypeID) ->
    [BaseInfo] = common_config_dyn:find_equip(TypeID),
    {BaseInfo#p_equip_base_info.property,BaseInfo#p_equip_base_info.colour}.


convert_npc_id(0) -> shops;
convert_npc_id(ShopID) -> ShopID.

%%==========================================
init() ->
    {ok,RecNpcList1} = 
        file:consult(common_config:get_map_config_file_path(shop_npcs)),
    {ok,RecShopsList1} = 
        file:consult(common_config:get_map_config_file_path(shop_shops)),
    {RecNpcList2,RecShopsList2} =
        case common_config:is_debug() of
            true ->
                {case lists:keyfind(shops,2,RecNpcList1) of
                     false ->
                         RecNpcList1;
                     #r_shop_npc{shops = Shops} = ShopInfo ->
                         [ShopInfo#r_shop_npc{shops=lists:reverse([{p_shop_info,?FREE_SHOP,"免费商店",[?FREE_SHOP]}|lists:reverse(Shops)])}|
                          lists:keydelete(shops,2,RecNpcList1)]
                 end,
                 [init_test_data(?FREE_SHOP)|RecShopsList1]};
            false ->
                {RecNpcList1,RecShopsList1}
        end,
    NpcKeyValues = 
        [ begin
              Key = element(2,Rec), {Key,Rec}
          end || Rec <- RecNpcList2 ],
    check_shop_item(RecShopsList2),
    ShopsKeyValues =
        [ begin
              Key = element(2,Rec), {Key,Rec}
          end || Rec <- RecShopsList2 ],
    common_config_dyn:load_gen_src(shop_npcs,NpcKeyValues),
    common_config_dyn:load_gen_src(shop_shops,ShopsKeyValues),
    check_is_init_bag_shop().

check_shop_item([]) ->
	ok;
check_shop_item([#r_shop_shops{goods=GoodsList}|T]) ->
	lists:foreach(
	  fun(#r_shop_goods{id=TypeID,type=Type}) ->
			  case Type of
				  ?TYPE_EQUIP ->
					  case common_config_dyn:find_equip(TypeID) of
						  [_] ->
							  ignore;
						  _ ->
							  ?ERROR_MSG("商店配置装备ID=~w没找到",[TypeID])
					  end;
				  ?TYPE_STONE ->
					  case common_config_dyn:find_stone(TypeID) of
						  [_] ->
							  ignore;
						  _ ->
							  ?ERROR_MSG("商店配置宝石ID=~w没找到",[TypeID])
					  end;
				  ?TYPE_ITEM ->
					  case common_config_dyn:find_item(TypeID) of
						  [_] ->
							  ignore;
						  _ ->
							  ?ERROR_MSG("商店配置道具ID=~w没找到",[TypeID])
					  end
			  end
	  end,GoodsList),
	check_shop_item(T).

init_test_data(ShopID) ->
    StoneList = common_config_dyn:list_stone(),
    ItemList = common_config_dyn:list_item(),
    EquipList = common_config_dyn:list_equip(),
    {List1,S1} = 
        lists:foldl(
          fun(Goods1,{Acc1,Seat1}) ->
                  G1 = #r_shop_goods{
                    id = Goods1#p_stone_base_info.typeid, 
                    num = 1, 
                    bind = 3, 
                    modify = "",
                    price_bind = 1, 
                    price = [{p_shop_price,1,[{p_shop_currency, 1, 0}]}], 
                    time = [0,0],
                    role_grade = [0,400],
                    type = 2,
                    seat = Seat1,
                    discount_type = 0},
                  {[G1|Acc1],Seat1+1}
          end,{[],1},StoneList),
    {List2,S2} =
        lists:foldl(
          fun(Goods2,{Acc2,Seat2}) ->
                  try
                  G2 = #r_shop_goods{
                    id = Goods2#p_item_base_info.typeid, 
                    num = 1, 
                    bind = 3, 
					
                    modify = "",
                    price_bind = 1, 
                    price =  [{p_shop_price,1,[{p_shop_currency, 1, 0}]}], 
                    time = [0,0],
                    role_grade = [0,400],
                    type = 1,
                    seat= Seat2,
                    discount_type = 0},
                  {[G2|Acc2],Seat2+1}
                  catch
                    _:Reason->
                        ?ERROR_MSG("config err,Goods2=~w,Reason=~w",[Goods2,Reason])
                  end
          end,{List1,S1},ItemList),
    {List3,_} =
        lists:foldl(
          fun(Goods3,{Acc3,Seat3}) ->
                  G3 = #r_shop_goods{
                    id = Goods3#p_equip_base_info.typeid, 
                    num = 1, 
                    bind = 3, 
                    modify = "",
                    price_bind = 1, 
                    price = [{p_shop_price,1,[{p_shop_currency, 1, 0}]}], 
                    time = [0,0],
                    role_grade = [0, 400],
                    type = 3,
                    seat = Seat3,
                    discount_type = 0},
                  {[G3|Acc3],Seat3+1}
          end,{List2,S2},EquipList),
    #r_shop_shops{id=ShopID,name="免费商店",branchs=[],goods=lists:reverse(List3),time=[0,9999999999]}.

%% 强制重新加载限量商店
force_reload_bag_shop() ->
	erlang:erase(init_bag_shop_time),
	check_is_init_bag_shop().

%%----------- 买回物品 ----------------------

%% 卖出物品写入可买回物品列表
hook_buy_back_sale(RoleID,GoodsList)->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{error,not_found}->
			?ERROR_MSG("数据丢失，严重！",[]);
		{ok,ExpInfo}->
			NewGoodsList = GoodsList++ExpInfo#r_role_map_ext.buy_back_goods,
			NewGoodsList1 = 
				case length(NewGoodsList)=< ?BUY_BACK_NUM of
					true->
						NewGoodsList;
					false->
						{List1,_List2}=lists:split(?BUY_BACK_NUM, NewGoodsList),
						List1
				end,
			mod_map_role:set_role_map_ext_info(RoleID,ExpInfo#r_role_map_ext{buy_back_goods=NewGoodsList1}),
			case length(GoodsList)>1 of
				true->
					DataRecord = #m_shop_buy_back_toc{op_type=?GET_LIST,goods=NewGoodsList1},
					common:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SHOP, ?SHOP_BUY_BACK, DataRecord);
				false->
					ignore
			end
	end.

%% 玩家买回物品请求 包括1.获取可买回物品列表 2.买回某物品
do_shop_buy_back({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State}) -> 
    #m_shop_buy_back_tos{op_type=OpType} = DataIn,
    case OpType of
        ?GET_LIST->
            do_get_buy_back_list({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State});
        ?BUY_BACK->
            do_buy_back_goods({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State})
            
    end.

%% 获取玩家可买回物品列表
do_get_buy_back_list({Unique, Module, Method, _DataIn, RoleID, PID, _Line, _State})->
	{ok,GoodsList} = 
		case mod_map_role:get_role_map_ext_info(RoleID) of
			{ok,ExpInfo} when is_record(ExpInfo,r_role_map_ext)->
				{ok,ExpInfo#r_role_map_ext.buy_back_goods};
			_->
				{ok,[]}
		end,
	R2 = #m_shop_buy_back_toc{op_type=?GET_LIST, goods=GoodsList},
	?UNICAST_TOC(R2).

%% 买回物品
do_buy_back_goods({Unique, Module, Method, DataIn, RoleID, PID, Line, _State})->
    GoodsID =DataIn#m_shop_buy_back_tos.goods_id,
    case check_buy_back_goods(GoodsID,RoleID) of
        {error,Reason}->
            do_buy_back_goods_error({Unique, Module, Method, DataIn, RoleID, PID},{error,Reason});
        {ok,GoodsInfo}->
           case common_transaction:transaction(fun()-> t_buy_back_goods(RoleID,GoodsInfo) end) of
               {atomic,{ok,NewRoleAttr,NewGoodsList}}->
                   common_misc:new_goods_notify({line, Line, RoleID},NewGoodsList),
                   R2 = #m_shop_buy_back_toc{op_type=?BUY_BACK,goods_id=GoodsID},
				   ?UNICAST_TOC(R2),
				   common_misc:send_role_silver_change(RoleID, NewRoleAttr);
               {aborted,Msg}->
                   do_buy_back_goods_error({Unique, Module, Method, DataIn, RoleID, PID},Msg)
           end
    end.
     
%% 检查买回物品
check_buy_back_goods(GoodsID,RoleID)-> 
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {error,not_found}->
            {error,?_LANG_SHOP_BUY_BACK_SYSTEM_ERROR};
         {ok,ExpInfo}->
            case lists:keyfind(GoodsID, 2, ExpInfo#r_role_map_ext.buy_back_goods) of
                GoodsInfo when erlang:is_record(GoodsInfo, p_goods)->
                    {ok,GoodsInfo};
                _Msg->{error,?_LANG_SHOP_BUY_BACK_NO_SUCH_GOODS}
            end
    end.
    
t_buy_back_goods(RoleID,GoodsInfo)->
	#p_goods{bind=_Bind,sell_price=SellPrice,type=Type,current_num=Num}=GoodsInfo,
	NewSellPrize = 
		case Type of
			?TYPE_EQUIP->get_goods_sale_price(GoodsInfo)*Num;
			_->SellPrice*Num
		end,
	%% 绑定的物品可以用不绑定银买，不绑物品必须用不绑银买，绑定属性不变
	MoneyType = silver_any,
%% 		case Bind of
%% 			true->  silver_any;
%% 			false-> silver_unbind
%% 		end,
	case common_bag2:t_deduct_money(MoneyType, NewSellPrize, RoleID, ?CONSUME_TYPE_SILVER_BUY_BACK) of
		{ok,NewRoleAttr} ->
			next;
		{error, Reason} ->
			NewRoleAttr = null,
			common_transaction:abort({error,Reason});
		_ ->
			NewRoleAttr = null,
			common_transaction:abort({error,?_LANG_SHOP_BUY_BACK_NOT_ENOUGH_SILVER})
	end,
	{ok,ExpInfo}=mod_map_role:get_role_map_ext_info(RoleID),
	NewGoodsInfo=lists:delete(GoodsInfo, ExpInfo#r_role_map_ext.buy_back_goods),
	mod_map_role:t_set_role_map_ext_info(RoleID, ExpInfo#r_role_map_ext{buy_back_goods=NewGoodsInfo}),
	{ok,GoodsList2} = mod_bag:create_goods_by_p_goods(RoleID,GoodsInfo),
	{ok,NewRoleAttr,GoodsList2}.

do_buy_back_goods_error({Unique, Module, Method, DataRecord, _RoleId, PID},Error)->
	Reason = 
		case Error of
			Error when erlang:is_binary(Error) -> Error;
			{error,_Reason}->_Reason;
			{bag_error,{not_enough_pos,_BagID}} -> ?_LANG_SHOP_BUY_BACK_NOT_ENOUTH_POS;
			_ ->?_LANG_SHOP_BUY_BACK_SYSTEM_ERROR
		end,
	R2 = #m_shop_buy_back_toc{op_type=DataRecord#m_shop_buy_back_tos.op_type,succ=false,reason=Reason},
	?UNICAST_TOC(R2).

is_bag_shop(ShopID) ->
	List = common_config_dyn:list(bag_shop),
	lists:keyfind(ShopID,#r_bag_shop_config.shop_id,List) =/= false.  

check_is_init_bag_shop() ->
	{H, M, S} = ?BAG_SHOP_REFRESH_TIME,
	NewInitTime = common_tool:today(H, M, S),
	case get(init_bag_shop_time) of
		Tm when Tm =:= NewInitTime ->
			ignore;
		_Other ->
			OpenDay = common_config:get_opened_days(),
			case common_config_dyn:find(shop_npcs, ?BAG_SHOP_NPC_ID) of
				[Record] ->
					db:clear_table(?DB_BAG_SHOP),
					[case bag_shop_conf(R#p_shop_info.id,OpenDay) of
						 {_RecommendType,Items,RandomNum} -> 
							 NewItems = get_init_bag_shop_item(RandomNum,Items),
							 db:dirty_write(?DB_BAG_SHOP,#r_bag_shop{shop_id=R#p_shop_info.id,shop_items=NewItems});
						 [] -> ignore
					 end || R <- Record#r_shop_npc.shops],
					put(init_bag_shop_time, NewInitTime);
				_Other ->
					ignore
			end
	end.

%% return {RecommendType,Items,RandomNum} | []
bag_shop_conf(ShopID,OpenDay) ->
	case common_config_dyn:find(bag_shop,ShopID) of
		[#r_bag_shop_config{shop_items=ShopItems,random_num=RandomNum}] -> 
			case lists:keyfind(OpenDay, 1, ShopItems) of
				false ->
					Key = OpenDay rem erlang:length(ShopItems) + 1,
					case lists:keyfind(Key, 1, ShopItems) of
						false ->
							{_,{RecommendType,Items}} = lists:nth(1, ShopItems);
						{_,{RecommendType,Items}} ->
							next
					end;
				{_,{RecommendType,Items}} ->
					next
			end,
			{RecommendType,Items,RandomNum};
		_ ->
			[]
	end.

%% 获得限量抢购的推荐类型
get_bag_shop_recommend(ShopID) ->
	{H, M, S} = ?BAG_SHOP_REFRESH_TIME,
	OpenDay = common_config:get_opened_days(),
	NewOpenDay = 
		case common_tool:now() > common_tool:today(H, M, S) of
			false ->
				%% 当天上午取前一天的
				erlang:max(OpenDay - 1,1);
			true ->
				OpenDay
		end,
	case bag_shop_conf(ShopID,NewOpenDay) of
		[] -> 0;
		{RecommendType,_Items,_RandomNum} ->
			RecommendType
	end.
							 
get_init_bag_shop_item(RNum,Items) ->
	%%先取一定会出现的道具
	HitItems = [Item||#r_bag_shop_item{weight=Weight}=Item<-Items,Weight=:=1],
	HitLen = erlang:length(HitItems),
	HitItems2 =
		case HitLen >= RNum of
			true ->
				lists:sublist(HitItems,RNum);
			false ->
				HitItems
		end,
	{_,NewItems} = lists:foldl(
					 fun (_,{[], AccItems}) ->
							  {[], AccItems};
						(_,{Counts,AccItems}) ->
							 Item = lists:nth(common_tool:random(1,length(Counts)),Counts),
							 {lists:keydelete(Item#r_bag_shop_item.item_id,#r_bag_shop_item.item_id,Counts),[Item|AccItems]}
					 end,{Items--HitItems2,[]},lists:seq(1,RNum-erlang:length(HitItems2))),
	NewItems++HitItems2.
    
%% return {Num,LimitBuyNum}
bag_shop_num(ShopID, ShopGoods, IsPayed) ->
    case db:dirty_read(?DB_BAG_SHOP,ShopID) of
        [#r_bag_shop{shop_items=Items}] ->
            case lists:keyfind(ShopGoods#r_shop_goods.id,#r_bag_shop_item.item_id,Items) of
                false -> {ShopGoods#r_shop_goods.num,0};
                #r_bag_shop_item{num=Num,limit_num=LimitBuyNum,need_payed=NeedPayed} ->
					assert_pay_bag_shop(NeedPayed,IsPayed),
					{Num,LimitBuyNum}
            end;
        _ ->
			{ShopGoods#r_shop_goods.num,0}
    end.

check_role_bag_shop_buy_num(RoleID, ShopID,#r_bag_shop_item{item_id=ItemID,num=Num1,limit_num=LNum}=Item, Num2) ->
	[#r_shop_shops{name=Name}] = common_config_dyn:find(shop_shops,ShopID),
	case Num1 < Num2 of
		true ->
			?THROW_ERR_REASON(?_LANG_SHOP_NUM_NOT_ENOUGH);
		false when LNum > 0 -> 
			if Num2 > LNum ->
				   ?THROW_ERR_REASON(common_misc:format_lang(?_LANG_SHOP_NOT_CAN_OVER_LIMIT, [Name,LNum]));
			   true ->
				   TodayHasBuyNum = get_role_today_bag_shop(RoleID,ShopID,ItemID),
				   case TodayHasBuyNum + Num2 > LNum of
					   true ->
						   ?THROW_ERR_REASON(?_LANG_SHOP_TODAY_ALREADY_BUYING);
					   false ->
						   {ok, Item#r_bag_shop_item{num=Num1-Num2}}
				   end
			end;
		false ->
			{ok, Item#r_bag_shop_item{num=Num1-Num2}}
	end.

%% 获取玩家今天限量抢购的购买个数
get_role_today_bag_shop(RoleID,ShopID,ItemID) ->
	case get_role_bag_shop_info(RoleID) of
		{ok, #r_role_bag_shop{buy_list=BuyList}} ->
			case lists:keyfind({ShopID,ItemID}, 1, BuyList) of
				false ->
					0;
				{{_ShopID,_ItemID},OldNum,LastBuyTime} ->
					case common_time:is_today(LastBuyTime) of
						true -> OldNum;
						false -> 0
					end
			end;
		false ->
			?ERROR_MSG("get_role_today_bag_shop error:RoleID=~w,ShopID=~w,ItemID=~w",[RoleID,ShopID,ItemID]),
			0
	end.

%% 更新玩家限量抢购的购买个数
add_role_bag_shop(RoleID,ShopID,ItemID,Num) ->
	case get_role_bag_shop_info(RoleID) of
		{ok, #r_role_bag_shop{buy_list=BuyList}=RoleBagShopInfo} ->
			Now = common_tool:now(),
			NewBuyList = 
				case lists:keyfind({ShopID,ItemID}, 1, BuyList) of
					false ->
						[{{ShopID,ItemID},Num,Now}|BuyList];
					{{_ShopID,_ItemID},OldNum,LastBuyTime} ->
						NewNum = 
							case common_time:is_today(LastBuyTime) of
								true -> OldNum+Num;
								false -> Num
							end,
						lists:keyreplace({ShopID,ItemID},1,BuyList,{{ShopID,ItemID},NewNum,Now})
				end,
			set_role_bag_shop_info(RoleID, RoleBagShopInfo#r_role_bag_shop{buy_list=NewBuyList});
		false ->
			?ERROR_MSG("add_role_bag_shop error:RoleID=~w,ShopID=~w,ItemID=~w,Num=~w",[RoleID,ShopID,ItemID,Num])
	end.

set_role_bag_shop_info(RoleID, RoleBagShopInfo) ->
	case common_transaction:t(
		   fun()-> 
				   t_set_role_bag_shop_info(RoleID, RoleBagShopInfo)
		   end
							 ) of
		{atomic, ok} ->
			ok;
		{aborted, Error} -> 
			?ERROR_MSG("~ts:~w", ["设置限量抢购数据时系统错误", Error]),
			{error, fail}
	end.

t_set_role_bag_shop_info(RoleID, RoleBagShopInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewRoleExtInfo = RoleExtInfo#r_role_map_ext{bag_shop=RoleBagShopInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		_ ->
			?THROW_SYS_ERR()
	end.

get_role_bag_shop_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{bag_shop=RoleBagShopInfo}} ->
			{ok, RoleBagShopInfo};
		_ ->
			{error, not_found}
	end.
    