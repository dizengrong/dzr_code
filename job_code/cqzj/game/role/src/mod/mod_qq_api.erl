%% Author: xierongfeng
%% Created: 2013-1-20
%% Description:
-module(mod_qq_api).

%%
%% Include files
%%
-include("mgeer.hrl").

-record(goods, {meta="''", url="''", appmode=2, paymode=0}).


%%
%% Exported Functions
%%

-export([
	is_vip/1,
	get_balance/1,
	is_login/1,
 	buy_goods/4,
 	buy_goods/5,
	exchange_goods/5,
	exchange_goods/6,
 	get_token/2,
	get_app_friends/1,
	inform_task_completed/2
]).

%%
%% API Functions
%%

is_vip(RoleID) ->
	case call(RoleID, "is_vip") of
		{ok, [IsYellowVip, IsYellowYearVip, YellowVipLevel]} ->
			YellowVipLevel2 = if
				YellowVipLevel == "";
				YellowVipLevel == undefined ->
					0;
				true ->
					list_to_integer(YellowVipLevel)
			end,
			{ok, IsYellowVip == "1", IsYellowYearVip == "1", YellowVipLevel2};
		_ -> 
			{ok, false, false, 0}
	end.

get_balance(RoleID) ->
	case call(RoleID, "get_balance") of
		{ok, [Balance]} ->
			list_to_integer(Balance);
		Reason -> 
			?ERROR_LOG("~p get_balance, error: ~p", [RoleID,Reason]),
			case catch db:dirty_read(?DB_ROLE_ATTR, RoleID) of
				[#p_role_attr{gold=Gold}] ->
					Gold;
				_ ->
					0
			end
end.

is_login(RoleID) ->
	call(RoleID, "is_login").
		
inform_task_completed(RoleID,TaskID) ->
	call(RoleID, "inform_task_completed", [TaskID]).
		
buy_goods(RoleID, ID, Price, Num, Amt) ->
	buy_goods(RoleID, ID, [{ID,Price,Num}], Amt).
buy_goods(RoleID, ID, Payitems, Amt) ->
	Payitems2 = string:join([
		lists:concat([GoodsID,"*",Price,"*",Num])||{GoodsID,Price,Num}<-Payitems], ";"),
	#goods{meta=Goodsmeta, url=Goodsurl, appmode=Appmode, paymode=Paymode} = cfg_goods:goods(ID),
	call(RoleID, "buy_goods", [Amt, Payitems2, Goodsmeta, Goodsurl, Appmode, Paymode]).


exchange_goods(RoleID,TargetId, ID, Price, Num, Amt) ->
	exchange_goods(RoleID,TargetId,ID, [{ID,Price,Num}], Amt).
exchange_goods(RoleID,TargetId, ID, Payitems, Amt) ->
	{ok, TargetOpenid, _, _,_} = mod_qq_cache:get_params(TargetId),
	Payitems2 = string:join([
		lists:concat([GoodsID,"*",Price,"*",Num])||{GoodsID,Price,Num}<-Payitems], ";"),
	#goods{meta=Goodsmeta, url=Goodsurl} = cfg_goods:goods(ID),
	call(RoleID, "exchange_goods", [Amt, Payitems2, Goodsmeta, Goodsurl,TargetOpenid]).

%% 获取黄钻送礼活动的token, Discountid::string()
get_token(RoleID, Discountid) ->
	call(RoleID, "get_token", [Discountid]).

%% 获取已安装了应用的好友列表
get_app_friends(RoleID) ->
    case call(RoleID, "get_app_friends") of
        {ok, Friendslist} ->
            Friendslist;
        _ -> 
            []
    end.

%%
%% Local Functions
%%

call(RoleID, ApiName) ->
	call(RoleID, ApiName, []).
call(RoleID, ApiName, ApiParams) ->
	{ok, Openid, Openkey, Pf, Pfkey} = mod_qq_cache:get_params(RoleID),
	Cmd = make_cmd(ApiName, RoleID, Openid, Openkey, Pf, Pfkey, ApiParams),
	case os:cmd(Cmd) of
		"ok" ++ Rem ->
			{ok, re:split(Rem, "[|]", [{return, list}])};
		"error" ++ Rem ->
			{error, re:split(Rem, "[|]", [{return, list}])};
		Others ->
			?ERROR_LOG("~p call api ~p, error ~p", [RoleID, ApiName, Others]),
			{error, Others}
	end.

make_cmd(ApiName, RoleID, Openid, Openkey, Pf, Pfkey, ApiParams)->
	[AgentName]  = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
	Params = lists:concat(lists:foldr(fun
		(Param, Acc) -> [" ",Param|Acc]
	end, [], [ApiName, RoleID, Openid, Openkey, Pf, Pfkey|ApiParams])),
	if
		AgentName == "qq"; AgentName == "pengyou" ->
    		["cd /data/cqzj_",AgentName,"_",ServerName,"/web/www/library; php qq_api.php ",Params];
		true ->
			["cd /data/mcqzj/app/web/game.www/library; php qq_api_test.php ",Params]
	end.
