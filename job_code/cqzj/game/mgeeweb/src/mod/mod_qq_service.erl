-module(mod_qq_service).

-export([get/3]).

-include("mgeeweb.hrl").

%%初始化QQ信息
get("/init_qq_info"++ _, Req, _) ->
	Get          = Req:parse_qs(),
	RoleID       = get_param_int("role_id", Get),
	{_, Openid}  = lists:keyfind("openid", 1, Get),
	{_, Openkey} = lists:keyfind("openkey", 1, Get),
	{_, Pf}      = lists:keyfind("pf", 1, Get),
	{_, Pfkey}   = lists:keyfind("pfkey", 1, Get),
	mod_qq_cache:set_roleid(Openid, RoleID),
	mod_qq_cache:set_params(RoleID, Openid, Openkey, Pf, Pfkey),
	IsYellowVip     = get_param_int("is_yellow_vip", Get),
	IsYellowYearVip = get_param_int("is_yellow_year_vip", Get),
	YellowVipLevel  = get_param_int("yellow_vip_level", Get),
	mod_qq_cache:set_vip(RoleID, IsYellowVip == 1, IsYellowYearVip == 1, YellowVipLevel),
	mgeeweb_tool:return_json_ok(Req);

%%回调发货
get("/pay"++_, Req, _DocRoot) ->
	Get = Req:parse_qs(),
	{_, Openid} = lists:keyfind("openid", 1, Get),
	{_, Token}  = lists:keyfind("token", 1, Get),
	ItemNum     = get_param_int("itemnumber", Get),
	Amt         = get_param_int("amt", Get),
	PayamtCoins = get_param_int("payamt_coins", Get),
	RoleID 		= mod_qq_cache:get_roleid(Openid),
	case global:whereis_name(mgeer_role:proc_name(RoleID)) of
		undefined ->
			mgeeweb_tool:return_json([{result, error}], Req);
		Pid ->
			Amt2 = max(round(Amt*10), round(PayamtCoins)),
			Pid ! {qq_buy_goods_callback, self(), Token, ItemNum, Amt2},
			receive
				Result ->
					mgeeweb_tool:return_json([{result, Result}], Req)
			end
	end;


get("/exchange"++_, Req, _DocRoot) ->
	Get = Req:parse_qs(),
	?ERROR_MSG("Exchange Get:~p~n",[Get]),
	{_, Openid} = lists:keyfind("openid", 1, Get),
	{_, SellerOpenid} = lists:keyfind("seller_openid", 1, Get),
	{_, Token}  = lists:keyfind("token", 1, Get),
	{_, _TypeId}  = lists:keyfind("typeid", 1, Get),
	ItemNum     = get_param_int("itemnumber", Get),
	UniAppAmt = get_param_int("uni_appamt", Get),
	RoleID 		= mod_qq_cache:get_roleid(Openid),
	_SellerRoleid 		= mod_qq_cache:get_roleid(SellerOpenid),
	case global:whereis_name(mgeer_role:proc_name(RoleID)) of
		undefined ->
			mgeeweb_tool:return_json([{result, error}], Req);
		Pid ->
			Pid ! {qq_exchange_goods_callback, self(), Token, ItemNum, UniAppAmt},
			receive
				Result ->
					mgeeweb_tool:return_json([{result, Result}], Req)
			end
	end;

get("/activity"++_, Req, _DocRoot) ->
	Get = Req:parse_qs(),
	{_, Openid}     = lists:keyfind("openid", 1, Get),
	{_, Discountid} = lists:keyfind("discountid", 1, Get),
	{_, Token}      = lists:keyfind("token", 1, Get),
	ItemType   		= get_param_int("itemtypeid", Get),
	ItemNum         = get_param_int("itemnumber", Get),
	RoleID          = mod_qq_cache:get_roleid(Openid),
	case global:whereis_name(mgeer_role:proc_name(RoleID)) of
		undefined ->
			mgeeweb_tool:return_json([{result, error}], Req);
		Pid ->
			Pid ! {mod_yvip_activity, {qq_activity_callback, self(), RoleID, Discountid, Token, ItemType, ItemNum}},
			receive
				Result ->
					mgeeweb_tool:return_json([{result, Result}], Req)
			end
	end;
	
get(_, _, _) ->
	ignore.

get_param_int(Key, List) ->
	{_, Val} = lists:keyfind(Key, 1, List),
	case Val of
		"" ->
			0;
		_ ->
			list_to_integer(Val)
	end.