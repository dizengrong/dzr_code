%% Author: xierongfeng
%% Created: 2013-1-20
%% Description:
-module(mod_qq_helper).

%%
%% Include files
%%
-include("mgeer.hrl").

%%
%% Exported Functions
%%

-export([
	wait_buy_goods_callback/2,
	get_buy_goods_token/3,
	get_buy_goods_token/6,
	check_buy_goods/3,
	wait_exchange_goods_callback/2,
	get_exchange_goods_token/4,
	get_exchange_goods_token/7
]).

-define(_qq_buy, ?DEFAULT_UNIQUE, ?QQ, ?QQ_BUY, #m_qq_buy_toc).
%%-define(_qq_exchange, ?DEFAULT_UNIQUE, ?QQ, ?QQ_EXCHANGE, #m_qq_exchange_toc).
%%
%% API Functions
%%
wait_buy_goods_callback(Timeout, Token1) ->
	mgeem_map:flush_all_role_msg_queue(),
	receive
		{qq_buy_goods_callback, From, Token2, _ItemNum, Amt} ->
			case Token1 =/= Token2 of
				true ->
					send(From, not_found),
					{false, <<"Token不存在">>};
				_ ->
					send(From, ok),
					{true, Amt}
			end;
		{'DOWN', MonitorRef, Type, Object, Info} ->
			mgeer_role:handle_info({'DOWN', MonitorRef, Type, Object, Info}, undefined),
			{false, <<"Token不存在">>}
	after
		Timeout -> {false, <<"请求超时">>}
	end.

get_buy_goods_token(RoleID, UseGold, Disturb) ->
	get_buy_goods_token(RoleID, 0, UseGold, 1, UseGold, Disturb).	
get_buy_goods_token(RoleID, ID, Price, Num, Amt, Disturb) ->
	{ok, RoleBase}  = mod_map_role:get_role_base(RoleID),
	case cfg_cheat:is_cheater(RoleBase#p_role_base.account_name) of
		true ->
			Token = "test",
			Amt2 = after_discount(RoleID, Amt),
			% Amt2 = case mod_qq_cache:get_vip(get(role_id)) of
			% 	{ok, true, _, _} ->
			% 		common_tool:floor(Amt*0.8);
			% 	_ ->
			% 		Amt
			% end,
			erlang:send(self(), {qq_buy_goods_callback, undefined, Token, Num, Amt2}),
			Token;
		false ->
			Amt2 = after_discount(RoleID, Amt),
			Amt3 = case Amt of 
				{CostPrice, Num} ->
					common_tool:floor(CostPrice*Num);
				CostPrice ->
					CostPrice
			end,
			case mod_qq_api:buy_goods(RoleID, ID, Price, Num, Amt3) of
				{ok, [Token = "test", _]} ->
					% Amt2 = case mod_qq_cache:get_vip(get(role_id)) of
					% 	{ok, true, _, _} ->
					% 		common_tool:floor(Amt*0.8);
					% 	_ ->
					% 		Amt
					% end,
					erlang:send(self(), {qq_buy_goods_callback, undefined, Token, Num, Amt2}),
					Token;
				{ok, [Token, Url]} ->
					common_misc:unicast({role, RoleID}, ?_qq_buy{url=Url, disturb=Disturb}),
					Token;
				{error, Error} ->
					?ERROR_LOG("buy_goods error: role_id = ~p, error = ~w", [RoleID, Error]),
					?THROW_ERR(?ERR_OTHER_ERR, <<"请求失败，请稍候再试">>)
			end
	end.

%% UseGoldData: {Price, Num} | CostGold
check_buy_goods(RoleID, RoleGold, UseGoldData) ->
	UseGold2 = after_discount(RoleID, UseGoldData),
	if
		UseGold2 =< 0 ->
			{error, ?_LANG_BOX_OPEN_WRONG_CONFIG};
		RoleGold < UseGold2 ->

			{error, ?_LANG_NOT_ENOUGH_GOLD};
		true ->
			ok
	end.

after_discount(RoleID, {CostPrice, Num}) ->
	case mod_qq_cache:get_vip(RoleID) of
		{ok, true, _, _} -> common_tool:floor(CostPrice*0.8) * Num;
		_ -> CostPrice * Num
	end;
after_discount(RoleID, UseGold) ->
	case mod_qq_cache:get_vip(RoleID) of
		{ok, true, _, _} -> common_tool:floor(UseGold*0.8);
		_ -> UseGold
	end.

wait_exchange_goods_callback(Timeout, Token1) ->
	mgeem_map:flush_all_role_msg_queue(),
	receive
		{qq_exchange_goods_callback, From, Token2, _ItemNum, Amt} ->
			case Token1 =/= Token2 of
				true ->
					send(From, not_found),
					{false, <<"Token不存在">>};
				_ ->
					send(From, ok),
					{true, Amt}
			end;
		{'DOWN', MonitorRef, Type, Object, Info} ->
			mgeer_role:handle_info({'DOWN', MonitorRef, Type, Object, Info}, undefined),
			{false, <<"Token不存在">>}
	after
		Timeout -> {false, <<"请求超时">>}
	end.

get_exchange_goods_token(RoleID, TargetId,UseGold, Disturb) ->
	get_exchange_goods_token(RoleID,TargetId, 0, UseGold, 1, UseGold, Disturb).	
get_exchange_goods_token(RoleID,TargetId, ID, Price, Num, Amt, Disturb) ->
	{ok, RoleBase}  = mod_map_role:get_role_base(RoleID),
	case cfg_cheat:is_cheater(RoleBase#p_role_base.account_name) of
		true ->
			Token = "test",
			erlang:send(self(), {qq_exchange_goods_callback, undefined, Token, Num, Amt}),
			Token;
		false ->
			case mod_qq_api:exchange_goods(RoleID,TargetId, ID, Price, Num, Amt) of
				{ok, [Token = "test", _]} ->
					erlang:send_after(2500, self(), {qq_exchange_goods_callback, undefined, Token, Num, Amt}),
					Token;
				{ok, [Token, Url]} ->
					?ERROR_LOG("exchange_goods success: role_id = ~p, Token = ~p,Url = ~p ~n", [RoleID, Token,Url]),
					common_misc:unicast({role, RoleID}, ?_qq_buy{url=Url, disturb=Disturb}),
					Token;
				{error, Error} ->
					?ERROR_LOG("buy_goods error: role_id = ~p, error = ~p", [RoleID, Error]),
					?THROW_ERR(?ERR_OTHER_ERR, <<"请求失败，请稍候再试">>)
			end
	end.


%%
%% Local Functions
%%
send(undefined, _Info) ->
	ignore;
send(PID, Info) ->
	PID ! Info.
