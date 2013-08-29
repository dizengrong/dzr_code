%% Author: dizengrong
%% Created: 2012-12-5
%% @doc: 这里实现的是t6项目中求购个人模块

-module (mod_wantbuy).

-include("mgeem.hrl").
-include("wantbuy.hrl").

-compile(export_all).

-export([handle/3]).

-define(MIN_PRICE, 	 			2).		%% 发布求购的最低单价
-define(MIN_BUY_NUM, 	 		1).		%% 发布求购的最小数量
-define(MAX_BUY_NUM, 	 		99).	%% 发布求购的大数量
-define(SEND_BROADCAST_COST, 	5000).	%% 发布求购广播消耗的银币

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?STALL, Method, Msg)).

-define(_assert(Condition, Reason), 
        case Condition of true -> ok; _ -> throw(Reason) end).

%% ========================== handle 处理 ================================	
handle(Method, DataIn, RoleId) ->
	case Method of
		?STALL_WANTBUY_CREATE ->
			do_create_wantbuy(RoleId, DataIn);
		?STALL_WANTBUY_MY_INFO ->
			do_get_my_wantbuy_info(RoleId, DataIn);
		?STALL_WANTBUY_MAX_PRICE ->
			do_get_max_price(RoleId, DataIn);
		?STALL_WANTBUY_CANCEL ->
			do_cancel(RoleId, DataIn);
		?STALL_WANTBUY_SELL ->	
			do_max_price_sell(RoleId, DataIn);
		?STALL_WANTBUY_SEARCH ->
			do_search(RoleId, DataIn)
	end.
%% ========================== handle 处理 ================================	

%% ========================== loop 处理 ================================	
loop(RoleId) ->
	Counter = get_loop_counter(RoleId),
	case Counter >= 5 of
		true ->
			set_loop_counter(RoleId, 0),
			case loop2(get_wantbuy_info(RoleId), false, common_tool:now()) of
				true ->
					reload_wantbuy_info(RoleId);
				false ->
					ignore
			end;
		false ->
			set_loop_counter(RoleId, Counter + 1)
	end.
loop2([], HasOvered, _Now) -> HasOvered;
loop2([WantbuyRec | Rest], HasOvered, Now) ->
	case WantbuyRec#p_stall_wantbuy.time_type of
		?TIME_TYPE_1 -> AddSec = 8*60*60;
		?TIME_TYPE_2 -> AddSec = 24*60*60;
		?TIME_TYPE_3 -> AddSec = 48*60*60
	end,
	case WantbuyRec#p_stall_wantbuy.create_time + AddSec >= Now of
		true -> %% 求购保管时间到期了
			?_assert(WantbuyRec#p_stall_wantbuy.id == 0, "求购数据bug"),
			case mod_wantbuy_server:keep_over(WantbuyRec) of
				false ->
					ignore;
				true ->
					send_keep_over_notify(WantbuyRec)
			end,
			HasOvered1 = true;
		false ->
			HasOvered1 = HasOvered
	end,
	loop2(Rest, HasOvered1, Now).

%% 求购保管时间到期通知，将元宝返还
send_keep_over_notify(WantbuyRec) ->
	TypeId          = WantbuyRec#p_stall_wantbuy.item_id,
	{_ItemType, ItemStr, Name, _IsOverlap} = get_goods_type_name(TypeId),
	{{Y1 ,M1 ,D1},{HH1 ,MM1 ,SS1}} = common_tool:seconds_to_datetime(WantbuyRec#p_stall_wantbuy.create_time),
	{{Y2 ,M2 ,D2},{HH2 ,MM2 ,SS2}} = common_tool:seconds_to_datetime(common_tool:now()),
	Text  = "亲爱的玩家，您之前于" ++ 
			integer_to_list(Y1) ++ "-" ++ integer_to_list(M1) ++ "-" ++ integer_to_list(D1) ++
			" " ++ integer_to_list(HH1) ++ ":" ++ integer_to_list(MM1) ++ 
			":" ++ integer_to_list(SS1) ++ 
			"求购的" ++ ItemStr ++ "：" ++ Name ++ "，数量：" ++ 
			 integer_to_list(WantbuyRec#p_stall_wantbuy.num) ++ "单价：" ++ 
			 integer_to_list(WantbuyRec#p_stall_wantbuy.price) ++ 
			 "已经于" ++ integer_to_list(Y2) ++ "-" ++ integer_to_list(M2) ++ "-" ++ integer_to_list(D2) ++
			" " ++ integer_to_list(HH2) ++ ":" ++ integer_to_list(MM2) ++ 
			":" ++ integer_to_list(SS2) ++ 
			 "过期了，元宝已返回，请注意查收",
	Title = "求购保管时间过期通知",
	common_letter:sys2p(WantbuyRec#p_stall_wantbuy.role_id, Text, Title, [], 14).

get_loop_counter(RoleId) ->
	case erlang:get({want_buy_loop_counter, RoleId}) of
		undefined -> 0;
		N -> N
	end.
set_loop_counter(RoleId, Counter) ->
	erlang:put({want_buy_loop_counter, RoleId}, Counter).
%% ========================== loop 处理 ================================	
%% ========================== STALL_WANTBUY_CREATE 处理 ==================	
do_create_wantbuy(RoleId, DataIn) ->
	case create_wantbuy_common_check(RoleId, DataIn) of
		{error, Reason} ->
			common_misc:send_common_error(RoleId, 0, Reason);
		true ->
			Price           = DataIn#m_stall_wantbuy_create_tos.price,
			Num             = DataIn#m_stall_wantbuy_create_tos.num,
			TimeType        = DataIn#m_stall_wantbuy_create_tos.time_type,
			IsSendBroadcast = DataIn#m_stall_wantbuy_create_tos.send_broadcast,
			TotalCost       = Price * Num,
			create_wantbuy_cost(RoleId, TotalCost, TimeType, IsSendBroadcast),
			{ok, RoleBaseRec} = mod_map_role:get_role_base(RoleId),
			WantBuyRec = #p_stall_wantbuy{
				role_id       = RoleId,
				role_nickname = RoleBaseRec#p_role_base.role_name,
				item_id       = DataIn#m_stall_wantbuy_create_tos.item_id,
				price         = Price,
				num           = Num,
				time_type     = DataIn#m_stall_wantbuy_create_tos.time_type
			},

			case mod_wantbuy_server:create_wantbuy(WantBuyRec) of
				false ->
					return_wantbuy_gold(RoleId, TotalCost),
					Msg = #m_stall_wantbuy_create_toc{succ = false};
				_ ->
					Msg = #m_stall_wantbuy_create_toc{succ = true},
					check_and_do_broadcast(IsSendBroadcast, WantBuyRec),
					reload_wantbuy_info(RoleId)
			end,
			?MOD_UNICAST(RoleId, ?STALL_WANTBUY_CREATE, Msg)
	end.

create_wantbuy_cost(RoleId, GoldCost, TimeType, IsSendBroadcast) ->
	%% 买物品要的元宝
	LogType = ?CONSUME_TYPE_GOLD_WANTBUY_COST,
	true = common_bag2:use_money(RoleId, gold_any, GoldCost, LogType),
	%% 保管费
	LogType2 = ?CONSUME_TYPE_SILVER_WANTBUY_KEEP,
	true = common_bag2:use_money(RoleId, silver_any, cfg_wantbuy:get_keep_cost(TimeType), LogType2),
	%% 广播费
	case IsSendBroadcast of
		true ->
			LogType3 = ?CONSUME_TYPE_SILVER_WANTBUY_BROADCAST,
			true = common_bag2:use_money(RoleId, silver_any, ?SEND_BROADCAST_COST, LogType3);
		false ->
			ignore
	end.

check_and_do_broadcast(IsSendBroadcast, WantBuyRec) ->
	case IsSendBroadcast of
		true ->
			TypeId = WantBuyRec#p_stall_wantbuy.item_id,
			{_ItemType, _ItemStr, Name, _IsOverlap} = get_goods_type_name(TypeId),
			Content = "玩家" ++ WantBuyRec#p_stall_wantbuy.role_nickname ++
					  "以单价" ++ integer_to_list(WantBuyRec#p_stall_wantbuy.price) ++
					  "元宝收购" ++ Name ++ "，大家赶紧来围观啊",
			common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_WORLD, Content);
		false ->
			ignore
	end.

create_wantbuy_common_check(RoleId, DataIn) ->
	Price           = DataIn#m_stall_wantbuy_create_tos.price,
	Num             = DataIn#m_stall_wantbuy_create_tos.num,
	TimeType        = DataIn#m_stall_wantbuy_create_tos.time_type,
	TotalCost       = Price * Num,
	IsSendBroadcast = DataIn#m_stall_wantbuy_create_tos.send_broadcast,
	if
		Price < ?MIN_PRICE ->
			{error, ?_LANG_PARAM_ERROR};
		Num < ?MIN_BUY_NUM orelse Num > ?MAX_BUY_NUM ->
			{error, ?_LANG_PARAM_ERROR};
		true ->
			case common_bag2:check_money_enough(gold_any, TotalCost, RoleId) of
				false ->
					{error, ?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD_ANY};
				true ->
					case IsSendBroadcast of
						true ->
							CostSilver = ?SEND_BROADCAST_COST + cfg_wantbuy:get_keep_cost(TimeType);
						false ->
							CostSilver = cfg_wantbuy:get_keep_cost(TimeType)
					end,
					case common_bag2:check_money_enough(silver_any, CostSilver, RoleId) of
						false ->
							{error, ?_LANG_ROLE_MONEY_NOT_ENOUGH_SILVER_ANY};
						true ->
							true
					end
			end
	end.
%% ========================== STALL_WANTBUY_CREATE 处理 ==================	


%% ========================== STALL_WANTBUY_MY_INFO 处理 ==================	
do_get_my_wantbuy_info(RoleId, _DataIn) -> 
	WantbuyRecs = get_wantbuy_info(RoleId),
	send_self_wantbuy_info_to_client(RoleId, WantbuyRecs).

send_self_wantbuy_info_to_client(RoleId, WantbuyRecs) ->
	Msg = #m_stall_wantbuy_my_info_toc{datas = WantbuyRecs},
	?MOD_UNICAST(RoleId, ?STALL_WANTBUY_MY_INFO, Msg).
%% ========================== STALL_WANTBUY_MY_INFO 处理 ==================	

%% ========================== STALL_WANTBUY_MAX_PRICE 处理 ==================	
do_get_max_price(RoleId, DataIn) ->
	ItemTypeId      = DataIn#m_stall_wantbuy_max_price_tos.item_id,
	case mod_wantbuy_server:get_max_price_wantbuy(ItemTypeId) of
		[] ->
			MaxPrice = 0,
			Num      = 0;
		WantbuyRec ->
			MaxPrice = WantbuyRec#p_stall_wantbuy.price,
			Num      = WantbuyRec#p_stall_wantbuy.num
	end,
	Msg = #m_stall_wantbuy_max_price_toc{
		item_id   = ItemTypeId,
		max_price = MaxPrice,
		num       = Num
	},
	?MOD_UNICAST(RoleId, ?STALL_WANTBUY_MAX_PRICE, Msg).
%% ========================== STALL_WANTBUY_MAX_PRICE 处理 ==================	

%% ========================== STALL_WANTBUY_CANCEL 处理 ==================	
do_cancel(RoleId, DataIn) ->
	Id = DataIn#m_stall_wantbuy_cancel_tos.id,
	case mod_wantbuy_server:cancel_wantbuy(RoleId, Id) of
		false ->
			common_misc:send_common_error(RoleId, 0, <<"您无此求购记录">>);
		_ ->
			reload_wantbuy_info(RoleId)
	end,
	WantbuyRecs = get_wantbuy_info(RoleId),
	send_self_wantbuy_info_to_client(RoleId, WantbuyRecs).
%% ========================== STALL_WANTBUY_CANCEL 处理 ==================	


%% ========================== STALL_WANTBUY_SELL 处理 ====================	
do_max_price_sell(RoleId, DataIn) ->
	ItemTypeId    = DataIn#m_stall_wantbuy_sell_tos.item,
	SellNum       = DataIn#m_stall_wantbuy_sell_tos.num,
	{ok, HaveNum} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleId, ItemTypeId),
	Ret = case HaveNum >= SellNum andalso SellNum >= ?MIN_BUY_NUM andalso SellNum =< ?MAX_BUY_NUM of
		false ->
			{error, ?_LANG_GOODS_NUM_NOT_ENOUGH};
		true ->
			case mod_wantbuy_server:max_price_sell(RoleId, ItemTypeId, SellNum) of
				{error, Reason0} -> 
					{error, Reason0};
				{true, SellNum1, GainGold, OldWantbuyRec} ->
					%% 出售者
					LogType1 = ?LOG_ITEM_TYPE_SELL_LOST,
					ok = mod_bag:use_item(RoleId, ItemTypeId, SellNum1, LogType1),
					LogType2 = ?GAIN_TYPE_GOLD_SELL,
					common_bag2:add_money(RoleId, gold_bind, GainGold, LogType2),
					%% 求购者
					send_item_mail_to_buyer(OldWantbuyRec, SellNum1),
					{true, SellNum1}
			end
	end,
	case Ret of
		{error, Reason} ->
			common_misc:send_common_error(RoleId, 0, Reason);
		{true, SellNum2} ->
			Msg = #m_stall_wantbuy_sell_toc{
				item = ItemTypeId,
				num = SellNum2
			},
			?MOD_UNICAST(RoleId, ?STALL_WANTBUY_SELL, Msg)
	end.

send_item_mail_to_buyer(OldWantbuyRec, GainItemNum) ->
	RoleId = OldWantbuyRec#p_stall_wantbuy.role_id,
	TypeId = OldWantbuyRec#p_stall_wantbuy.item_id,
	{ItemType, ItemStr, Name, IsOverlap} = get_goods_type_name(TypeId),
	Text = "亲爱的玩家，您之前求购的" ++ ItemStr ++ "：" ++ Name ++ ", 数量：" ++
		   integer_to_list(OldWantbuyRec#p_stall_wantbuy.num) ++ "单价：" ++
		   integer_to_list(OldWantbuyRec#p_stall_wantbuy.price) ++ 
		   "，已有玩家卖给您" ++ integer_to_list(GainItemNum) ++ "个了，请注意查收",
	Title = "物品求购所得通知",
	Fun = fun(Num) ->
		CreateInfo = #r_goods_create_info{
			num      = Num,
			type_id  = TypeId,
			type     = ItemType,
			bind     = false,
			bag_id   = 1,
			position = 1
		},
		{ok, [Goods]} = mod_bag:create_p_goods(RoleId, CreateInfo),
		Goods#p_goods{id = 1}
	end,
	case IsOverlap of
		1 ->
			CreateInfoList = [Fun(GainItemNum)];
		_ ->
			CreateInfoList = [Fun(1) || _N <- lists:seq(1, GainItemNum)]
	end,
	common_letter:sys2p(RoleId, Text, Title, CreateInfoList, 14).

get_goods_type_name(TypeId)	->
	ItemType = TypeId div 10000000,
	case ItemType of
		?TYPE_ITEM ->  
			ItemStr = "物品",
			[#p_item_base_info{itemname = Name, is_overlap = IsOverlap}] = common_config_dyn:find(item, TypeId);
		?TYPE_STONE -> 
			ItemStr = "宝石",
			IsOverlap = false,
			[#p_stone_base_info{stonename = Name}] = common_config_dyn:find(stone, TypeId);
		?TYPE_EQUIP -> 
			ItemStr = "装备",
			IsOverlap = false,
			[#p_equip_base_info{equipname = Name}] = common_config_dyn:find(equip, TypeId)
	end,
	{ItemType, ItemStr, binary_to_list(Name), IsOverlap}.
%% ========================== STALL_WANTBUY_SELL 处理 ====================	


%% ========================== STALL_WANTBUY_SEARCH 处理 ====================	
do_search(RoleId, DataIn) ->
	SearchTypeIdList = DataIn#m_stall_wantbuy_search_tos.item_list,
	IdListStr = common_misc:term_to_string(SearchTypeIdList),
	Expr = string:sub_string(IdListStr, 2, length(IdListStr) - 1),
	WhereExpr   = io_lib:format("where item_id in (~s)", [Expr]),
	WantbuyRecs = mod_wantbuy_server:select_wantbuy_data(WhereExpr),
	% Msg         = #m_stall_wantbuy_search_toc{datas = WantbuyRecs},
	Msg         = #m_stall_wantbuy_my_info_toc{datas = WantbuyRecs},
	?MOD_UNICAST(RoleId, ?STALL_WANTBUY_MY_INFO, Msg).
%% ========================== STALL_WANTBUY_SEARCH 处理 ====================	


%% 求购到期时或是创建求购记录失败时返还元宝
return_wantbuy_gold(RoleId, TotalCost) ->
	LogType = ?GAIN_TYPE_GOLD_WANTBUY_RETURN,
	common_bag2:add_money(RoleId, gold_bind, TotalCost, LogType).

%% ========================== 进程字典操作接口 =============================	
get_wantbuy_info(RoleId) ->
	case erlang:get({wantbuy_info, RoleId}) of
		undefined ->
			WantbuyRecs = reload_wantbuy_info(RoleId),
			WantbuyRecs;
		WantbuyRecs ->
			WantbuyRecs
	end.

set_wantbuy_info(RoleId, WantbuyRecs) ->
	erlang:put({wantbuy_info, RoleId}, WantbuyRecs).

reload_wantbuy_info(RoleId) ->
	WantbuyRecs = load_wantbuy_from_db(RoleId),
	set_wantbuy_info(RoleId, WantbuyRecs),
	WantbuyRecs.

load_wantbuy_from_db(RoleId) ->
	WhereExpr = io_lib:format("where role_id = ~w", [RoleId]),
	mod_wantbuy_server:select_wantbuy_data(WhereExpr).