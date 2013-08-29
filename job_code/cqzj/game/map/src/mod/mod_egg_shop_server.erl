%%% -------------------------------------------------------------------
%%% Author  : ldk
%%% Description :
%%%
%%% Created : 2012-7-10
%%% -------------------------------------------------------------------
-module(mod_egg_shop_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([
         start/0,
         start_link/0]).

-export([]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

-define(SHOP_BUY_MAX_NUM,50).

%% ====================================================================
%% External functions
%% ====================================================================

start() ->
	supervisor:start_child(mgeem_sup, 
									 {?MODULE,
									  {?MODULE, start_link, []},
									  permanent, 30000, worker, [?MODULE]}).
start_link() ->
    gen_server:start_link(?MODULE, [], []).

init([]) ->
	case global:whereis_name(?MODULE) of
		undefined ->
			global:register_name(?MODULE, self()),
			AfterSecs = common_time:diff_next_daytime(0, 0),
			erlang:send_after((AfterSecs+10)*1000, self(), reset_freerefresh_everyday),
			erlang:send_after(300*1000, self(), dump_buy_infos),
			init_data(),
			{ok, #state{}};
		_ ->
			{stop, alread_start}
	end.

init_data() ->
	BuyInfo = mt_mnesia:show_table(?DB_SHOP_BUY_INFO_P),
	set_shop_buy_info(BuyInfo).
	
	
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
	case get_shop_buy_info() of
		undefined ->
			ignore;
		BuyInfos ->
			lists:foreach(fun(BuyInfo) ->
								  db:dirty_write(?DB_SHOP_BUY_INFO_P, BuyInfo)
								  end, BuyInfos)
	end,
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_handle_info(dump_buy_infos)->
	erlang:send_after(300*1000, self(), dump_buy_infos),
	case get_shop_buy_info() of
		undefined ->
			ignore;
		BuyInfos ->
			db:clear_table(?DB_SHOP_BUY_INFO_P),
			lists:foreach(fun(BuyInfo) ->
								  db:dirty_write(?DB_SHOP_BUY_INFO_P, BuyInfo)
								  end, BuyInfos)
	end;
	
do_handle_info(reset_freerefresh_everyday)->
	erlang:send_after(86400*1000, self(), reset_freerefresh_everyday),
	OnlineRoleIDs = common_misc:get_all_online_roleid(),
	lists:foreach(fun(RoleID) ->
						  common_misc:send_to_rolemap(RoleID, {mod_egg_shop, {reset_freerefresh,RoleID}})
						  end, OnlineRoleIDs);

do_handle_info({buy,RoleID,RoleName,TypeID})->
	case get_shop_buy_info() of
		undefined ->
			set_shop_buy_info([#r_shop_buy_info{role_id=RoleID,role_name=RoleName,typeid=TypeID}]);
		BuyInfos ->
			case length(BuyInfos) >= ?SHOP_BUY_MAX_NUM of
				true ->
					set_shop_buy_info([#r_shop_buy_info{role_id=RoleID,role_name=RoleName,typeid=TypeID}|lists:sublist(BuyInfos, ?SHOP_BUY_MAX_NUM - 1)]);
				false ->
					set_shop_buy_info([#r_shop_buy_info{role_id=RoleID,role_name=RoleName,typeid=TypeID}|BuyInfos])
			end
	end;

do_handle_info({buy_infos,RoleID})->
	case get_shop_buy_info() of
		undefined ->
			R2 = #m_egg_shop_buy_info_toc{buy_infos=[]};
		BuyInfos ->
			NewBuyInfos = lists:map(fun(#r_shop_buy_info{role_id=RoleID1,role_name=RoleName1,typeid=TypeID}) ->
											 [#p_item_base_info{itemname=ItemName}] = common_config_dyn:find_item(TypeID),
											#p_egg_shop_buy_info{role_id=RoleID1,role_name=RoleName1,
																 type_id=TypeID,type_name=ItemName}
											end, BuyInfos),
			R2 = #m_egg_shop_buy_info_toc{buy_infos=NewBuyInfos}
	end,
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EGG, ?EGG_SHOP_BUY_INFO, R2);


do_handle_info(Info)->
	?ERROR_MSG("receive unknown message,Info=~w",[Info]),
	ignore.

set_shop_buy_info(BuyInfos) ->
	put({?MODULE, buy_infos},BuyInfos).
	
get_shop_buy_info() ->
	get({?MODULE, buy_infos}).