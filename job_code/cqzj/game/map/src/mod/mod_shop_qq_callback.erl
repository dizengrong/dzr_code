%% Author: xierongfeng
%% Created: 2013-1-26
%% Description:
-module(mod_shop_qq_callback).

%%
%% Include files
%%
-include("mgeem.hrl").

-define(_shop_buy, ?DEFAULT_UNIQUE, ?SHOP, ?SHOP_BUY, #m_shop_buy_toc).

-define(BUY_FROM_STALL, 1).
-define(BUY_FROM_MARKET, 2).
-define(STALL_LOG_CHAT, 0).
-define(STALL_LOG_BUY, 1).
%%
%% Exported Functions
%%
-export([handle/1]).

%%
%% API Functions
%%
handle({qq_buy_goods_callback, From, Token, ItemNum, Amt}) ->
	case erlang:erase({qq_buy_goods, Token}) of
		{ShopID, TypeID} ->
			RoleID = get(role_id),
			case mod_shop:check_shop_buy(RoleID,TypeID,ItemNum,ShopID) of
				{ok,RoleAttr,ShopGoods,BagShop} ->
					case common_transaction:t(fun() ->
							  t_qq_buy_goods(RoleID,ShopID,ItemNum,ShopGoods,RoleAttr,Amt)
					  end) of
						{atomic, {ok,NewRoleAttr,[GoodsBuyInfo|_]=GoodsList}} ->
							mod_shop:update_bag_shop(RoleID,ShopID,TypeID,BagShop,ItemNum),
							hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_SHOP_BUY),
							?TRY_CATCH(common_item_logger:log(
								RoleID,GoodsBuyInfo,ItemNum,?LOG_ITEM_TYPE_SHANG_DIAN_GOU_MAI),Err1),
							?TRY_CATCH(hook_prop:hook(
								shop_buy, [GoodsBuyInfo#p_goods{current_num=ItemNum}]),Err2),
							common_misc:unicast({role, RoleID}, ?_shop_buy{
								succ     = true,
								goods    = GoodsList,
								property = mod_shop:new_property(NewRoleAttr)
							}),
							send(From, ok);
						{aborted, {error,ErrCode,Reason}} ->
							common_misc:unicast({role, RoleID}, ?_shop_buy{
								succ       = false,
								error_code = ErrCode,
								reason     = Reason
							}),
							send(From, error);
						{aborted, Reason} ->
							?ERROR_MSG("do_shop_buy error=~w",[Reason]),
							common_misc:unicast({role, RoleID}, ?_shop_buy{
								succ   = false,
								reason = ?_LANG_SYSTEM_ERROR
							}),
							send(From, error)
					end;
				{error,ErrCode,Reason} ->
					common_misc:unicast({role, RoleID}, ?_shop_buy{
						succ       = false,
						error_code = ErrCode,
						reason     = Reason
					}),
					send(From, error)
			end;
		_ ->
			send(From, error)
	end;
%%线简单的写一下测试一下流程
handle({qq_exchange_goods_callback, From, Token, ItemNum, _Amt}) ->
	case erlang:erase({qq_exchange_goods, Token}) of
		{TargetRoleID,BuyFrom,Detail,Price,PriceType,GoodsDetail,CurNum} ->
			RoleID = get(role_id),
			case db:transaction(fun() ->
											  mod_stall:t_do_qq_exchange_goods(RoleID,TargetRoleID,BuyFrom,Detail,Price,GoodsDetail,CurNum,ItemNum)									  end) of
				{atomic, {NewRoleAttr,NewTargetRoleAttr, GoodsInfo, Number, NewPrice, NewDetail, NewStallGoods}} ->
					%% 更新市场
					case NewStallGoods of
						undefined ->
							mod_stall:delete_stall_prices(GoodsInfo#p_goods.typeid,GoodsInfo#p_goods.current_colour,NewPrice),
							mod_stall_list:stall_list_delete([NewDetail]);
						_ ->
							mod_stall_list:stall_list_update(NewStallGoods)
					end,
					hook_prop:hook(create, [GoodsInfo]),
					%%写购买日志
					Now = common_tool:now(),
					NewLog = #p_stall_log{type=?STALL_LOG_BUY, src_role_id=RoleID, src_role_name=NewRoleAttr#p_role_attr.role_name,
										  goods_info=GoodsInfo, number=Number, price=NewPrice, time=Now, price_type=PriceType},
					mod_stall:do_insert_buy_log(TargetRoleID, NewLog),
					%% 道具消费日志
					case BuyFrom of
						?BUY_FROM_STALL ->
							common_item_logger:log(RoleID,GoodsInfo,Number,?LOG_ITEM_TYPE_BAI_TAN_HUO_DE),
							common_item_logger:log(TargetRoleID,GoodsInfo,Number,?LOG_ITEM_TYPE_BAI_TAN_CHU_SHOU);
						_ ->
							common_item_logger:log(RoleID, GoodsInfo, Number, ?LOG_ITEM_TYPE_MARKET_HUO_DE),
							common_item_logger:log(TargetRoleID, GoodsInfo, Number, ?LOG_ITEM_TYPE_MARKET_CHU_SHOU)
					end,
					{_,GoodsID} = NewDetail#r_stall_goods.id,
					R = #m_stall_buy_toc{num=Number, role_id=TargetRoleID, goods_id=GoodsID},
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?STALL, ?STALL_BUY, R),
					R2 = #m_stall_buy_toc{return_self=false, role_id=RoleID, goods_id=GoodsID, num=Number, role_name=NewRoleAttr#p_role_attr.role_name},
					common_misc:send_role_gold_change(RoleID, NewRoleAttr),
					if NewTargetRoleAttr =/= null -> common_misc:send_role_gold_change(TargetRoleID, NewTargetRoleAttr);true -> ignore end,
					common_misc:unicast({role, TargetRoleID}, ?DEFAULT_UNIQUE,?STALL, ?STALL_BUY, R2),
					common_misc:update_goods_notify({role, RoleID}, GoodsInfo),
					send(From, ok);		
				{aborted, {throw, {bag_error, {not_enough_pos,_BagID}}}} ->
					R = #m_stall_buy_toc{succ=false, reason=?_LANG_STALL_NOT_ENOUGH_BAG_SPACE_2, return_self=true},
					common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE,?STALL, ?STALL_BUY, R),
					send(From, error);
				{aborted, ErrorInfo} ->
					case erlang:is_binary(ErrorInfo) of
						true ->
							Reason = ErrorInfo;
						false ->
							?ERROR_MSG("~ts:~w", ["购买摊位物品出错", ErrorInfo]),
							Reason = ?_LANG_STALL_SYSTEM_ERROR
					end,
					case Reason =:= ?_LANG_STALL_HAS_FINISH of
						false ->
							R = #m_stall_buy_toc{succ=false, reason=Reason, return_self=true};
						true ->
							R = #m_stall_buy_toc{succ=false, reason=Reason, return_self=true, stall_finish=true}
					end,
					common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE,?STALL, ?STALL_BUY, R),
					send(From, error)
			end
	end.

%%
%% Local Functions
%%
t_qq_buy_goods(RoleID,ShopID,ItemNum,ShopGoods,RoleAttr,Amt) ->
	Bind = case ShopGoods of
			   #r_shop_goods{id = GoodsID} when GoodsID == 10100007;
											    GoodsID == 10100086;
											    GoodsID == 10100029 ->
					true;
			   #r_shop_goods{bind = 2}	-> 
				   true;
			   #r_shop_goods{bind = 3}	-> 
				   false;
			   #r_shop_goods{price_bind=2}	-> 
				   true;
			   _ ->
				   false
		   end,
	{ok, GoodsList} = mod_shop:creat_goods(ItemNum,ShopGoods,RoleID,Bind,ShopID),
	NewRoleAttr = RoleAttr#p_role_attr{gold=RoleAttr#p_role_attr.gold-Amt},
	common_consume_logger:use_gold({NewRoleAttr#p_role_attr.role_id,0,Amt,?CONSUME_TYPE_GOLD_BUY_ITEM_FROM_SHOP,[],ShopGoods#r_shop_goods.id,ItemNum}),
	mod_map_role:set_role_attr(RoleID, NewRoleAttr),
	{ok, NewRoleAttr, GoodsList}.

send(undefined, _) ->
	ignore;
send(PID, Info) ->
	PID ! Info.
