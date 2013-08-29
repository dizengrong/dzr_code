%%% -------------------------------------------------------------------
%%% Author  : ldk
%%% Description :
%%%
%%% Created : 2012-7-17
%%% -------------------------------------------------------------------
-module(mod_stall_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").
-include("stall.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([
         start/0,
         start_link/0]).

-export([]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3,fun_stall_db_op/2]).

-export([
	stall_db_read/2, 
	stall_db_match_object/2,
	stall_db_delete/2,
	stall_db_write/2
]).

-record(state, {}).

-define(STALL_GOODS_PRICE_RANGE,stall_goods_price_range).
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
	global:register_name(?MODULE, self()),
	{ok, #state{}}.

%%摆摊地图
init_price_rank(MapID) ->
	StallList = db:dirty_match_object(?DB_STALL_P, #r_stall{mapid=MapID, _='_'}),
	lists:foreach(fun(#r_stall{role_id=RoleID}) ->
						  StallGoodList = db:dirty_match_object(?DB_STALL_GOODS_P, #r_stall_goods{role_id=RoleID, _='_'}),
						  lists:foreach(fun(StallGood) ->
												#r_stall_goods{stall_price=StallPrice, goods_detail=GoodDetail} = StallGood,
												case GoodDetail#p_goods.current_num > 0 of
													true ->
														set_stall_prices(GoodDetail#p_goods.typeid,GoodDetail#p_goods.current_colour,StallPrice);
													_ ->
														ignore
												end
										end, StallGoodList)
				  end, StallList).

handle_call({apply,Fun,Argv,OpType}, _From, State) ->
	Res = mod_stall_server:Fun(Argv, OpType),
	{reply, Res, State};
    % {reply, catch Fun(Argv,OpType), State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%需要返回值
stall_db_read(DB,Key) ->
	?STALL_DB_CALL(?fun_stall_db_op,[DB,Key],?type_db_read).
stall_db_match_object(DB,Match) ->
	?STALL_DB_CALL(?fun_stall_db_op,[DB,Match],?type_db_match_object).
%%无需返回
stall_db_delete(DB,Key) ->
	?STALL_DB_SEND(?fun_stall_db_op,[DB,Key],?type_db_delete).
stall_db_write(DB,Record) ->
	?STALL_DB_SEND(?fun_stall_db_op,[DB,Record],?type_db_write).

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_handle_info({init_price_rank,MapID})->
	init_price_rank(MapID);

do_handle_info({set_stall_prices,TypeID,Color,Price})->
	set_stall_prices(TypeID,Color,Price);

do_handle_info({delete_stall_prices,TypeID,Color,Price})->
	delete_stall_prices(TypeID,Color,Price);	

do_handle_info({{Unique, Module, ?STALL_PRICE_RANGE, DataIn, RoleID, PID,_Line},SysMinPrice})->
	do_price_range(Unique, Module, ?STALL_PRICE_RANGE, DataIn, RoleID, PID,SysMinPrice);

do_handle_info(Info)->
	?ERROR_MSG("receive unknown message,Info=~w",[Info]),
	ignore.

fun_stall_db_op(Argv,OpType) ->
	case OpType of
		?type_db_match_object ->
			[DB,Match] = Argv,
			db:match_object(DB, Match, read);
		?type_db_write ->
			[DB,Record] = Argv,
			db:write(DB,Record, write);
		?type_db_dirty_write ->
			[DB,Record] = Argv,
			db:dirty_write(DB,Record);
		?type_db_dirty_read ->
			[DB,Key] = Argv,
			db:dirty_read(DB,Key);
		?type_db_read ->
			[DB,Key] = Argv,
			db:read(DB,Key);
		?type_db_delete ->
			[DB,Key] = Argv, 
			db:delete(DB,Key, write)
	end.
		
	
do_price_range(Unique, Module, Method, DataIn, _RoleId, PId,SysMinPrice) ->
    #m_stall_price_range_tos{typeid=TypeId, color=Color} = DataIn,
    do_goods_price_range_get({Unique, Module, Method, TypeId, Color, PId,SysMinPrice}).

%% @desc 取价格列表的最高最低价，lists:max(List),min
do_goods_price_range_get({Unique, Module, Method, TypeId, Color, PId,SysMinPrice})	->
	PRList = get_stall_prices(TypeId,Color),
	{GoldH,GoldL} = 
		case PRList of
			[] ->
				{0,0};
			GList ->
				{lists:max(GList), lists:min(GList)}
		end,
	if
		GoldH=:=0 andalso GoldL=:=0	->
			DataRecord = #m_stall_price_range_toc{
												  typeid = TypeId,
												  color = Color,
												  gold_high = SysMinPrice, 
												  gold_low = SysMinPrice,
												  sys_min_price=SysMinPrice
												 },
			common_misc:unicast2(PId, Unique, Module, Method, DataRecord);
		true	->
			DataRecord = #m_stall_price_range_toc{typeid = TypeId,
												  color = Color,
												  gold_high = GoldH, 
												  gold_low = GoldL,
												  sys_min_price=SysMinPrice},
			common_misc:unicast2(PId, Unique, Module, Method, DataRecord)
	end.



get_stall_prices(TypeID,Color) ->
	case get({?STALL_GOODS_PRICE_RANGE,TypeID,Color})  of
		undefined ->
			[];
		Price ->
			Price
	end.

set_stall_prices(TypeID,Color,Price) ->
	case get_stall_prices(TypeID,Color) of
		[] ->
			put({?STALL_GOODS_PRICE_RANGE,TypeID,Color},[Price]);
		PriceList ->
			put({?STALL_GOODS_PRICE_RANGE,TypeID,Color},[Price|PriceList])
	end.

delete_stall_prices(TypeID,Color,Price) ->
	case get_stall_prices(TypeID,Color) of
		[] ->
			ignore;
		PriceList ->
			put({?STALL_GOODS_PRICE_RANGE,TypeID,Color},lists:delete(Price, PriceList))
	end.