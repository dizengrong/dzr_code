%% Author: xierongfeng
%% Created: 2013-1-20
%% Description:
-module(mod_qq).

%%
%% Include files
%%
-include("mgeer.hrl").

-define(_qq_yvip_open, ?DEFAULT_UNIQUE, ?QQ, ?QQ_YVIP_OPEN, #m_qq_yvip_open_toc).
-define(_qq_yvip_info, ?DEFAULT_UNIQUE, ?QQ, ?QQ_YVIP_INFO, #m_qq_yvip_info_toc).
-define(_common_error, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc).

%%
%% Exported Functions
%%

-export([
	handle/1,
	send_yvip_to_client/2
]).

-export([get_balance_test/0]).

%%
%% API Functions
%%
qq_pay_call_times_check() ->
	Now = common_tool:now(),
	case erlang:get(ignore_qq_pay_call) of
		undefined ->
			case erlang:get(qq_pay_call_times) of
				undefined -> 
					erlang:put(qq_pay_call_times, {common_tool:now(), 1}),
					true;
				{BeginTime, Times} ->
					case Times >= 5 andalso ((common_tool:now() - BeginTime)) / Times =< 2.0 of
						true -> 
							erlang:put(ignore_qq_pay_call, Now + 30),
							erlang:erase(qq_pay_call_times),
							false;
						false ->
							case Times >= 10 of
								true -> erlang:put(qq_pay_call_times, {Now, 1});
								false -> erlang:put(qq_pay_call_times, {Now, Times + 1})
							end,
							true
					end
			end;
		TillTime ->
			case Now > TillTime of
				true -> erlang:erase(ignore_qq_pay_call);
				false -> ignore
			end,
			(Now > TillTime)
	end.
			
get_balance_test() -> 
	case get(balance_test) of
		undefined -> 
			put(balance_test, 10000),
			10000;
		Balance -> 
			put(balance_test, Balance + 10000),
			Balance + 10000
	end.

%%QQ充值页面onclose回调接口
handle({_Unique, ?QQ, ?QQ_PAY, _DataIn, RoleID, _PID, _Line}) ->
	case qq_pay_call_times_check() of
		true ->
			Balance = mod_qq_api:get_balance(RoleID),
			% Balance = get_balance_test(),
			{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			if
				Balance > 0 ->
					mod_role_tab:update_element(RoleID, p_role_attr, [{#p_role_attr.gold, Balance}]),
					ChangeList = [
								  #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=Balance}
								 ];
				
				true ->
					ChangeList = []
			end,
			case (RoleAttr#p_role_attr.gold < Balance) andalso (Balance > 0) of
				true ->
					Balance > RoleAttr#p_role_attr.gold andalso mod_share_invite:first_pay_award(RoleID),
					PayGold = Balance - RoleAttr#p_role_attr.gold,
					?TRY_CATCH( mod_qq_pay:pay(RoleAttr,PayGold,RoleAttr#p_role_attr.is_payed=/=true) ),
					mod_role_tab:update_element(RoleID, p_role_attr, [{#p_role_attr.is_payed, true}]),
					NewChangeList = [#p_role_attr_change{change_type=?ROLE_PAYED_CHANGE, new_value=true}|ChangeList];
				false ->
					NewChangeList = ChangeList
			end,
			NewChangeList =/= [] andalso common_misc:role_attr_change_notify({role, RoleID}, RoleID, NewChangeList);
		false -> 
			?ERROR_LOG("玩家正在刷QQ_PAY接口，role id: ~w", [RoleID])
	end;

handle({_Unique, ?QQ, ?QQ_YVIP_OPEN, DataIn, RoleID, PID, _Line}) ->
	#m_qq_yvip_open_tos{actid = ActID} = DataIn,
	Discountid = cfg_qq:activity_discountid(ActID),
	case mod_qq_api:get_token(RoleID, Discountid) of
		{ok, ["test", _]} ->
			erlang:send_after(500, self(), {mod_yvip_activity, {qq_activity_callback, self(), RoleID, Discountid, "test", 10100001, 1}}),
			mod_yvip_activity:set_yvip_open_cb(RoleID, ActID, "test");
		{ok, [Token, Mid]} ->
			common_misc:unicast2(PID, ?_qq_yvip_open{actid=Discountid, mid=Mid, token=Token}),
			mod_yvip_activity:set_yvip_open_cb(RoleID, ActID, Token);
		{error, Error} ->
			?ERROR_LOG("get_token error: role_id = ~p, actid=~p, error = ~p", [RoleID, ActID, Error]),
			common_misc:unicast2(PID, ?_common_error{error_str = <<"请求失败，请稍候再试">>})
	end;

handle({_Unique, ?QQ, ?QQ_YVIP_XUFEI, _DataIn, _RoleID, _PID, _Line} = Msg) ->
	mod_yvip_activity:handle(Msg);
handle({_Unique, ?QQ, ?QQ_YVIP_PRIVILEGE, _DataIn, _RoleID, _PID, _Line} = Msg) ->
	mod_yvip_activity:handle(Msg);
handle({_Unique, ?QQ, ?QQ_YVIP_ACTIVITY, _DataIn, _RoleID, _PID, _Line} = Msg) ->
	mod_yvip_activity:handle(Msg);
handle({_Unique, ?QQ, ?QQ_YVIP_LOTTERY, _DataIn, _RoleID, _PID, _Line} = Msg) ->
	mod_yvip_activity:handle(Msg);
handle({_Unique, ?QQ, ?QQ_YVIP_INFO, _DataIn, RoleID, _PID, _Line}) ->
	send_yvip_to_client(RoleID, false);
handle({_Unique, ?QQ, ?QQ_YVIP_OPERAT, _DataIn, _RoleID, _PID, _Line} = Msg) ->
	mod_yvip_activity:handle(Msg);
handle({_Unique, ?QQ, ?QQ_SHARE, _DataIn, _RoleID, _PID, _Line} = Msg) ->
    mod_share_invite:handle(Msg);
handle({_Unique, ?QQ, ?QQ_SHARE_FETCH, _DataIn, _RoleID, _PID, _Line} = Msg) ->
    mod_share_invite:handle(Msg);
handle({_Unique, ?QQ, ?QQ_SHARE_INVITE_INFO, _DataIn, _RoleID, _PID, _Line} = Msg) ->
    mod_share_invite:handle(Msg);
handle({_Unique, ?QQ, ?QQ_INVITE, _DataIn, _RoleID, _PID, _Line} = Msg) ->
    mod_share_invite:handle(Msg);
handle({_Unique, ?QQ, ?QQ_INVITE_FETCH, _DataIn, _RoleID, _PID, _Line} = Msg) ->
    mod_share_invite:handle(Msg).


send_yvip_to_client(RoleID, FromCache) ->
	{ok, IsYellowVip, IsYellowYearVip, YellowVipLevel} = case FromCache of
		true  -> mod_qq_cache:get_vip(RoleID);
		false -> mod_qq_api:is_vip(RoleID)
	end,
	case FromCache of
		false -> 
			mod_qq_cache:set_vip(RoleID, IsYellowVip, IsYellowYearVip, YellowVipLevel),
			mod_map_role:update_map_role_info(RoleID, [{#p_map_role.qq_yvip, mod_map_actor:get_map_qq_yvip(RoleID)}]);
		true -> ignore
	end,
	common_misc:unicast({role, RoleID}, ?_qq_yvip_info{
			is_yvip        = IsYellowVip, 
			is_yearly_yvip = IsYellowYearVip,
			level          = YellowVipLevel,
			error_code     = 0}).

%%
%% Local Functions
%%
