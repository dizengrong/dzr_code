%%% -------------------------------------------------------------------
%% Author: dizengrong
%% Created: 2012-12-5
%% @doc: 这里实现的是t6项目中求购全局模块
%%% -------------------------------------------------------------------
-module(mod_wantbuy_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").
-include("wantbuy.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([
         start/0,
         start_link/0]).

-export([create_wantbuy/1, cancel_wantbuy/2, max_price_sell/3, keep_over/1]).

-export([get_max_price_wantbuy/1, select_wantbuy_data/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

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

%% 创建一条新的求购记录，失败或是出错时返回false
create_wantbuy(WantBuyRec) ->
	case catch gen_server:call({global, ?MODULE}, {create_wantbuy, WantBuyRec}) of
		{'EXIT', Reason} ->
			?ERROR_MSG("create_wantbuy: ~w failed!!! Reason: ~w", [WantBuyRec, Reason]),
			{error, ?_LANG_SYSTEM_ERROR};
		Ret ->
			Ret
	end.

%% 玩家取消一条求购记录
cancel_wantbuy(RoleId, Id) ->
	case catch gen_server:call({global, ?MODULE}, {cancel_wantbuy, {RoleId, Id}}) of
		{'EXIT', Reason} ->
			?ERROR_MSG("role ~w cancel_wantbuy id ~w failed!!! Reason: ~w", [RoleId, Id, Reason]),
			{error, ?_LANG_SYSTEM_ERROR};
		Ret ->
			Ret
	end.

%% 玩家RoleId要出售物品给收购价格最高的求购
%% 返回: {error, Reason} | {true, 卖出的数量, 可获取的元宝, 原有的求购记录}
max_price_sell(RoleId, ItemTypeId, SellNum) ->
	case catch gen_server:call({global, ?MODULE}, {max_price_sell, {RoleId, ItemTypeId, SellNum}}) of
		{'EXIT', Reason} ->
			?ERROR_MSG("role ~w sell ~w number of item ~w failed!!! Reason: ~w", [RoleId, ItemTypeId, SellNum, Reason]),
			{error, ?_LANG_SYSTEM_ERROR};
		Ret ->
			Ret
	end.

%% 求购保管时间到期
keep_over(WantbuyRec) ->
	case catch gen_server:call({global, ?MODULE}, {keep_over, WantbuyRec}) of
		{'EXIT', Reason} ->
			?ERROR_MSG("keep_over call failed!!! WantbuyRec: ~w, Reason: ~w", [WantbuyRec, Reason]),
			{error, ?_LANG_SYSTEM_ERROR};
		Ret ->
			Ret
	end.
%% ========================================================================
init([]) ->
	global:register_name(?MODULE, self()),
	{ok, #state{}}.

handle_call({Action, Params}, _From, State) ->
    Reply = case Action of
    	create_wantbuy -> create_wantbuy2(Params);
    	cancel_wantbuy -> cancel_wantbuy2(Params);
    	max_price_sell -> max_price_sell2(Params);
    	keep_over -> 	  keep_over2(Params)
    end,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
create_wantbuy2(WantBuyRec) ->
	WantBuyRec1 = WantBuyRec#p_stall_wantbuy{
		id          = 0,
		create_time = common_tool:now()
	},
	insert_wantbuy(WantBuyRec1).


cancel_wantbuy2({RoleId, WantBuyId}) ->
	delete_wantbuy(RoleId, WantBuyId).

max_price_sell2({_RoleId, ItemTypeId, SellNum}) ->	
	case get_max_price_wantbuy(ItemTypeId) of
		[] ->
			{error, <<"已无对应的求购记录，出售失败">>};
		WantbuyRec ->
			Num = WantbuyRec#p_stall_wantbuy.num,
			case SellNum > Num of
				true ->  SellNum1 = Num;
				false -> SellNum1 = SellNum
			end,
			WantbuyRoleId = WantbuyRec#p_stall_wantbuy.role_id,
			WantBuyId     = WantbuyRec#p_stall_wantbuy.id,
			case SellNum1 == Num of
				true ->
					delete_wantbuy(WantbuyRoleId, WantBuyId);
				false ->
					UpdateList = [{num, Num - SellNum1}],
					WhereExpr  = io_lib:format("where id = ~w", [WantBuyId]),
					update_wantbuy(WantbuyRoleId, UpdateList, WhereExpr)
			end,
			{true, SellNum1, SellNum1*WantbuyRec#p_stall_wantbuy.price, WantbuyRec}
	end.

keep_over2(WantbuyRec) ->
	WantBuyId = WantbuyRec#p_stall_wantbuy.id,
	WhereExpr = io_lib:format("where id=~w", [WantBuyId]),
	case select_wantbuy_data(WhereExpr) of
		[] ->
			false;
		_ ->
			delete_wantbuy(WantbuyRec#p_stall_wantbuy.role_id, WantBuyId),
			true
	end.

insert_wantbuy(WantBuyRec) ->
	FieldValues = tl(tuple_to_list(WantBuyRec)),
	Sql         = {esql, {insert, ?WANTBUY_TAB, ?WANTBUY_FIELDS, [FieldValues]}},
	{ok, _}     = mod_mysql:insert(Sql),
	true.

delete_wantbuy(RoleId, WantBuyId) ->
	Sql = mod_mysql:get_esql_delete(?WANTBUY_TAB, 
		io_lib:format("where id = ~w AND role_id = ~w", [WantBuyId, RoleId])),
	{ok, D} = mod_mysql:delete(Sql),
	(D > 0).

update_wantbuy(_WantbuyRoleId, UpdateList, WhereExpr) ->
	Sql     = mod_mysql:get_esql_update(?WANTBUY_TAB, UpdateList, WhereExpr),
	{ok, _} = mod_mysql:update(Sql),
	true.



%% ========================== mysql 处理 =================================	
%% 获取某类型物品的当前求购的最大价格和数量
%% 有的话返回#p_stall_wantbuy{}, 无则返回[]
get_max_price_wantbuy(ItemTypeId) ->
	Sql = io_lib:format("SELECT id, role_id, role_nickname, item_id, MAX(price),"
					    " num, time_type, create_time FROM ~w WHERE item_id = ~w "
					    " AND price=(SELECT MAX(price) FROM ~w) LIMIT 1", 
						[?WANTBUY_TAB, ItemTypeId, ?WANTBUY_TAB]),
	case mod_mysql:select(Sql) of
		{ok, [[]]} ->
			[];
		{ok, Datas} -> 
			hd(sqldata_2_wantbuy(Datas))
	end.

%% 通过where子句来获取求购数据，返回[#p_stall_wantbuy{}]
select_wantbuy_data(WhereExpr) ->
	Sql = mod_mysql:get_esql_select(?WANTBUY_TAB, ?WANTBUY_FIELDS, WhereExpr),
	{ok, Datas} = mod_mysql:select(Sql),
	sqldata_2_wantbuy(Datas).
	
sqldata_2_wantbuy(Datas) ->
	sqldata_2_wantbuy(Datas, []).

sqldata_2_wantbuy([], WantbuyRecs) -> WantbuyRecs;
sqldata_2_wantbuy([Data | Rest], WantbuyRecs) ->
	[Id, RoleId, RoleNickname, ItemId, Price, Num, TimeType, CreateTime] = Data,
	WantbuyRec = #p_stall_wantbuy{
		id            = Id,
		role_id       = RoleId,
		role_nickname = binary_to_list(RoleNickname),
		item_id       = ItemId,
		price         = Price,
		num           = Num,
		time_type     = TimeType,
		create_time   = CreateTime
	},
	sqldata_2_wantbuy(Rest, [WantbuyRec | WantbuyRecs]).