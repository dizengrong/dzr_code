-module(mod_economy).

%% 说明：
%% 0.尽量使用check_and_use_xxx方法
%% 1.要加/减一个经济数据时，可以使用 add_xxx/use_xxx 方法
%% 2.要减多个经济数据时，就使用 use/2,add/2
%% 3.要减经济数据时，要先判断，可以再减钱（我们支持减到负数的）
-export([use/3,add/3,get/1,init/1, get_economy_status/1,
		 add_silver/3, add_gold/3, add_bind_gold/3, add_practice/3,
		 add_popularity/3,
		 use_gold/3, use_bind_gold/3, use_practice/3, use_popularity/3,
		 use_silver/3,
		 check_silver/2, check_gold/2, check_bind_gold/2, 
		 check_practice/2, check_popularity/2, check/2,
		 check_and_use_silver/3, check_and_use_gold/3,
		 check_and_use_bind_gold/3, check_and_use_practice/3,
		 check_and_use_popularity/3, check_and_use/3]).

-include("common.hrl").

-define(ECONOMY_CACHE_REF, cache_util:get_register_name(economy)).

-spec init(Id::integer())->ok.
init(Id)->
	init_economy_status(Id).


-spec get(Id::integer())->{ok,Economy::#economy{}}|none.
get(Id)->
	global:set_lock({economy,Id}),
	Reply = case get_economy_status(Id) of 
		[Balance]->
			Balance;
		[]->
			?ERR(economy,"should not happen, id ~w without data",[Id]),
			none
	end,
	global:del_lock({economy,Id}),
	Reply.

%% ===========================================================
%% 下面的check_xxx方法的参数Amount为使用的数量，都是返回：true|falase
check_silver(PlayerId, Amount) ->
	check(PlayerId, #economy{gd_silver = Amount}).

check_gold(PlayerId, Amount) ->
	check(PlayerId, #economy{gd_gold = Amount}).

check_bind_gold(PlayerId, Amount) ->
	check(PlayerId, #economy{gd_bind_gold = Amount}).
		
check_practice(PlayerId, Amount) ->
	check(PlayerId, #economy{gd_practice = Amount}).

check_popularity(PlayerId, Amount) ->
	check(PlayerId, #economy{gd_popularity = Amount}).

%% 这个方法的UseEconomyRec为economy记录
check(PlayerId, UseEconomyRec) ->
	global:set_lock({economy, PlayerId}),
	[Balance] =  get_economy_status(PlayerId),
	Ret = check_enough(Balance, UseEconomyRec),
	global:del_lock({economy, PlayerId}),
	
	Ret.
%% ================================================================
%% ================================================================


%% ================================================================
%% ===================== use_xxx ==================================
use_silver(PlayerId, Amount, LogType) ->
	use(PlayerId, #economy{gd_silver = Amount}, LogType),
	ok.
%% 只消耗金币时调用这个
use_gold(PlayerId, Amount, LogType) ->
	use(PlayerId, #economy{gd_gold = Amount}, LogType),
	ok.
%% 优先消耗绑定金币时调用这个
use_bind_gold(PlayerId, Amount, LogType) ->
	use(PlayerId, #economy{gd_bind_gold = Amount}, LogType),
	ok.

use_practice(PlayerId, Amount, LogType) ->
	use(PlayerId, #economy{gd_practice = Amount}, LogType),
	ok.

use_popularity(PlayerId, Amount, LogType) ->
	use(PlayerId, #economy{gd_popularity = Amount}, LogType),
	ok.

-spec use(Id::integer(), Use_amount::#economy{}, integer())-> true.
use(Id, Use_amount, LogType)->
	global:set_lock({economy,Id}),
	[OldEconomyRec] = get_economy_status(Id),
	NewEconomyRec = use_amount(OldEconomyRec, Use_amount),
	update_economy_status(Id, NewEconomyRec),
	global:del_lock({economy,Id}),

	mod_user_log:log_user(economy, Id, [OldEconomyRec, NewEconomyRec, LogType]),
	notify_economy_changed(Id, NewEconomyRec),

	true.
%% ================================================================
%% ================================================================


%% ================================================================
%% =================== check_and_use_xxx ==========================
%% 下面的方法如果钱够的话就使用并返回true，否则返回false
check_and_use_silver(PlayerId, Amount, LogType) ->
	check_and_use(PlayerId, #economy{gd_silver = Amount}, LogType).
%% 只消耗金币时调用这个
check_and_use_gold(PlayerId, Amount, LogType) ->
	check_and_use(PlayerId, #economy{gd_gold = Amount}, LogType).
%% 优先消耗绑定金币时调用这个
check_and_use_bind_gold(PlayerId, Amount, LogType) ->
	check_and_use(PlayerId, #economy{gd_bind_gold = Amount}, LogType).

check_and_use_practice(PlayerId, Amount, LogType) ->
	check_and_use(PlayerId, #economy{gd_practice = Amount}, LogType).

check_and_use_popularity(PlayerId, Amount, LogType) ->
	check_and_use(PlayerId, #economy{gd_popularity = Amount}, LogType).

check_and_use(PlayerId, UseAmount, LogType) ->
	global:set_lock({economy, PlayerId}),
	[OldEconomyRec] = get_economy_status(PlayerId),
	case check_enough(OldEconomyRec, UseAmount) of 
		true->
			NewEconomyRec = use_amount(OldEconomyRec, UseAmount),
			update_economy_status(PlayerId, NewEconomyRec),
			Ret = true;
		false->
			NewEconomyRec = none,
			Ret = false
	end,
	global:del_lock({economy, PlayerId}),

	case Ret of
		true ->
			mod_user_log:log_user(economy, PlayerId, [OldEconomyRec, NewEconomyRec, LogType]),
			notify_economy_changed(PlayerId, NewEconomyRec);
		false -> ok
	end,

	Ret.
%% ================================================================
%% ================================================================


%% ================================================================
%% ======================== add_xxx ===============================
add_silver(PlayerId, Amount, LogType) ->
	%% TO-DO: 添加对押镖银币类型的判断
	%% 并调用：mod_fengdi:gain_taxes/2 给他的奴隶主加税金
	add(PlayerId, #economy{gd_silver = Amount}, LogType),
	%% 成就通知
	mod_achieve:silverNotify(PlayerId),
	ok.

add_gold(PlayerId, Amount, LogType) ->
	add(PlayerId, #economy{gd_gold = Amount}, LogType),
	ok.

add_bind_gold(PlayerId, Amount, LogType) ->
	add(PlayerId, #economy{gd_bind_gold = Amount}, LogType),
	ok.		

add_practice(PlayerId, Amount, LogType) ->
	add(PlayerId, #economy{gd_practice = Amount}, LogType),
	ok.

add_popularity(PlayerId, Amount, LogType) ->
	add(PlayerId, #economy{gd_popularity = Amount}, LogType),
	mod_achieve:officialNotify(PlayerId),
	ok.

-spec add(Id::integer(),Add_amount::#economy{}, integer())-> #economy{}.
add(Id, Add_amount, LogType)->
	global:set_lock({economy, Id}),
	
	[OldEconomyRec] = get_economy_status(Id),
	NewEconomyRec = add_up(OldEconomyRec, Add_amount),
	update_economy_status(Id, NewEconomyRec),

	global:del_lock({economy, Id}),

	mod_user_log:log_user(economy, Id, [OldEconomyRec, NewEconomyRec, LogType]),
	notify_economy_changed(Id, NewEconomyRec),

	NewEconomyRec.
%% ================================================================
%% ================================================================



%%local functions
-spec check_enough(Balance::#economy{},Balanceunt::#economy{})->true|false.
check_enough(Balance,Use_amount)->
	if
		(Balance#economy.gd_gold >= Use_amount#economy.gd_gold) andalso %% 只消耗金币的判断
		(Balance#economy.gd_bind_gold+Balance#economy.gd_gold >= Use_amount#economy.gd_gold + Use_amount#economy.gd_bind_gold) andalso
		(Balance#economy.gd_silver >= Use_amount#economy.gd_silver) andalso
		(Balance#economy.gd_practice >= Use_amount#economy.gd_practice) andalso 
		(Balance#economy.gd_popularity >= Use_amount#economy.gd_popularity) ->
			 true;
		true->
			false
	end.

-spec use_amount(Balance::#economy{},Use_amount::#economy{})->New_balance::#economy{}.
use_amount(Balance,Use_amount)->
	if 
		Use_amount#economy.gd_bind_gold == 0 ->
			New_bind_gold = Balance#economy.gd_bind_gold,
			New_gold = Balance#economy.gd_gold - Use_amount#economy.gd_gold;
		Use_amount#economy.gd_bind_gold >= Balance#economy.gd_bind_gold->
			New_bind_gold = 0,
			New_gold = Balance#economy.gd_bind_gold + Balance#economy.gd_gold - 
				(Use_amount#economy.gd_bind_gold + Use_amount#economy.gd_gold);
		true->
			?INFO(economy,"~w", [Balance]),
			?INFO(economy,"~w", [Use_amount]),
			New_bind_gold = Balance#economy.gd_bind_gold - Use_amount#economy.gd_bind_gold,
			New_gold = Balance#economy.gd_gold - Use_amount#economy.gd_gold
	end,
	mod_achieve:goldUse(Balance#economy.gd_accountId,(Use_amount#economy.gd_bind_gold + Use_amount#economy.gd_gold)),
	Balance#economy{
		gd_bind_gold  = New_bind_gold,
		gd_gold       = New_gold,
		gd_silver     = Balance#economy.gd_silver - Use_amount#economy.gd_silver,
		gd_practice   = Balance#economy.gd_practice - Use_amount#economy.gd_practice,
		gd_popularity = Balance#economy.gd_popularity - Use_amount#economy.gd_popularity
	}. 
			 
add_up(Balance,Add_amount)->
	Balance#economy{
		gd_bind_gold       = Balance#economy.gd_bind_gold + Add_amount#economy.gd_bind_gold,
		gd_gold            = Balance#economy.gd_gold + Add_amount#economy.gd_gold,
		gd_silver          = Balance#economy.gd_silver + Add_amount#economy.gd_silver,
		gd_practice        = Balance#economy.gd_practice + Add_amount#economy.gd_practice,
		gd_popularity      = Balance#economy.gd_popularity + Add_amount#economy.gd_popularity,
		gd_totalPopularity = Balance#economy.gd_totalPopularity + Add_amount#economy.gd_popularity
	}.


get_economy_status(Id)->
	gen_cache:lookup(?ECONOMY_CACHE_REF, Id).
	
	
update_economy_status(_Id,Balance)->
	gen_cache:update_record(?ECONOMY_CACHE_REF, Balance).
	
init_economy_status(Id)->
	gen_cache:insert(?ECONOMY_CACHE_REF, #economy{gd_accountId = Id}).

notify_economy_changed(PlayerId, EconomyRec) ->
	{ok, Packet} = pt_25:write(25000, EconomyRec),
	lib_send:send_by_id(PlayerId, Packet).