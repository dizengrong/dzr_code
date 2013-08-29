-module (mod_horse).

-include("common.hrl").

-export([client_get_horse_info/1, client_feed_horse/2, client_buy_horse_equip/2,
		 client_change_show_state/2]).

-export([start_link/1, get_added_attri/1]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3,
		 client_get_horse_info2/2, client_feed_horse2/2, client_buy_horse_equip2/2,
		 client_change_show_state2/2]).

-record(state, {player_id = 0}).

start_link({PlayerId})->
	gen_server:start_link(?MODULE, {PlayerId}, []).

%% 获取坐骑给主将的属性加成 
-spec get_added_attri(player_id()) -> #role_update_attri{}.
get_added_attri(PlayerId) ->
	HorseRec  = get_horse_rec(PlayerId),
	data_horse:get_added_attri(data_horse:get_level(HorseRec#horse.gd_exp)).

%% 客户端请求坐骑的详细数据
client_get_horse_info(PlayerId) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.horse_pid, 
					{request, client_get_horse_info2, [PlayerId]}).

%% 客户端请求喂养坐骑
client_feed_horse(PlayerId, FeedType) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.horse_pid, 
					{request, client_feed_horse2, [PlayerId, FeedType]}).

%% 客户端请求购买或穿戴坐骑时装
client_buy_horse_equip(PlayerId, HorseEquipId) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.horse_pid, 
					{request, client_buy_horse_equip2, [PlayerId, HorseEquipId]}).

%% 客户端请求改变坐骑显示状态
client_change_show_state(PlayerId, IsShow) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.horse_pid, 
					{request, client_change_show_state2, [PlayerId, IsShow]}).

	
init({PlayerId})->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, PlayerId),
    {ok, #state{player_id = PlayerId}}.

handle_cast({request, Action, Args}, State) ->
	NewState = ?MODULE:Action(State, Args),
	{noreply, NewState}.

handle_call({request, Action, Args}, _From, State) ->
	{NewState, Reply} = ?MODULE:Action(State, Args),
	{reply, Reply, NewState}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, State) ->
	?INFO(horse, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.	


%% ============================================================================
%% ============================ 2 方法 ^_^ ====================================
client_get_horse_info2(_State, [PlayerId]) ->
	HorseRec = get_horse_rec(PlayerId),
	FeedTimes = mod_counter:get_counter(PlayerId, ?COUNTER_HORSE_FEED),

	{ok, Packet1} = pt_25:write(25100, HorseRec),
	{ok, Packet2} = pt_25:write(25102, FeedTimes),
	lib_send:send_by_id(PlayerId, <<Packet1/binary, Packet2/binary>>).

 
client_feed_horse2(_State, [PlayerId, FeedType]) ->
	HorseRec  = get_horse_rec(PlayerId),
	OldLevel  = data_horse:get_level(HorseRec#horse.gd_exp),
	FeedTimes = mod_counter:get_counter(PlayerId, ?COUNTER_HORSE_FEED),
	Result = case (HorseRec#horse.gd_horse /= 0) andalso 
				  (FeedTimes < data_system:get(3)) andalso 
				  (OldLevel < data_horse:get_max_level()) of
		true ->
			{CostSliver, CostBingGold} = data_horse:get_feed_cost(FeedType),
			SliverCheck = mod_economy:check_silver(PlayerId, CostSliver),
			GoldCheck = mod_economy:check_bind_gold(PlayerId, CostBingGold),
			case SliverCheck andalso GoldCheck of
				true ->
					mod_economy:use_silver(PlayerId, CostSliver, ?SILVER_FEED_HORSE),
					mod_economy:use_bind_gold(PlayerId, CostBingGold, ?GOLD_FEED_HORSE),
					mod_counter:add_counter(PlayerId, ?COUNTER_HORSE_FEED),

					TotalExp = HorseRec#horse.gd_exp + data_horse:get_feed_exp(FeedType),
					update_exp(PlayerId, TotalExp),
					%% 如果等级改变了需要通知角色模块
					NewLevel = data_horse:get_level(TotalExp),
					case NewLevel > OldLevel of
						true ->
							mod_role:main_role_update_attri_notify(PlayerId);
						false ->
							ok
					end,
					{true, HorseRec#horse{gd_exp = TotalExp}};
				false ->
					if 
						SliverCheck == false -> ?ERR_NOT_ENOUGH_SILVER;
						true -> ?ERR_NOT_ENOUGH_GOLD
					end
			end;
		false ->
			?ERR(horse, "cannot feed horse, since your horse "
						"reach max level or has no feed time left"),
			?ERR_UNKNOWN
	end,
	case Result of
		{true, NewHorseRec} ->
			{ok, Packet1} = pt_25:write(25100, NewHorseRec),
			{ok, Packet2} = pt_25:write(25102, FeedTimes + 1),
			Packet = <<Packet1/binary, Packet2/binary>>;
		ErrCode1 ->
			{ok, Packet} = pt_err:write(10999, {25, ErrCode1})
	end,
	lib_send:send_by_id(PlayerId, Packet).


client_buy_horse_equip2(_State, [PlayerId, HorseEquipId]) ->
	HorseRec = get_horse_rec(PlayerId),
	Ret = case lists:member(HorseEquipId, HorseRec#horse.gd_equipList) of
		true -> %% 已经购买过了
			?INFO(horse, "player horse equip changed to ~w", [HorseEquipId]),
			update_current_equip(PlayerId, HorseEquipId),
			{true, HorseRec#horse{gd_curHorseEquip = HorseEquipId}};
		false -> %% 需要先购买
			GoldCost = data_horse:get_equip_cost(HorseEquipId),
			case mod_economy:check_and_use_bind_gold(PlayerId, GoldCost, ?GOLD_HORSE_EQUIP_COST) of
				true ->
					update_current_equip(PlayerId, HorseEquipId),
					update_equip_list(PlayerId, [HorseEquipId | HorseRec#horse.gd_equipList]),

					scene:update_horse_data(PlayerId, HorseEquipId),
					{true, HorseRec#horse{gd_curHorseEquip = HorseEquipId}};
				false ->
					{false, ?ERR_NOT_ENOUGH_GOLD}
			end
	end,

	case Ret of
		{false, ErrCode} ->
			{ok, Packet} = pt_err:write(10999, {25, ErrCode});
		{true, NewHorseRec} ->
			{ok, Packet} = pt_25:write(25100, NewHorseRec)
	end,
	lib_send:send_by_id(PlayerId, Packet).

client_change_show_state2(_State, [PlayerId, IsShow]) ->
	HorseRec = get_horse_rec(PlayerId),
	Check = (HorseRec#horse.gd_horse /= 0) andalso 
			(((IsShow == 1) andalso (HorseRec#horse.gd_isShow == 0)) orelse
			 ((IsShow == 0) andalso (HorseRec#horse.gd_isShow == 1))),
	case Check of
		true ->
			mod_role:main_role_update_attri_notify(PlayerId),
			case IsShow of
				1 -> Data = HorseRec#horse.gd_curHorseEquip;
				0 -> Data = 0
			end,
			scene:update_horse_data(PlayerId, Data);
		false ->
			?ERR(horse, "Client wrong request")
	end.




 %% ===========================================================================
 %% ============================ db 数据操作 ==================================
 %% ===========================================================================
 -define(HORSE_CACHE_REF, cache_util:get_register_name(horse)).

get_horse_rec(PlayerId) ->
 	case gen_cache:lookup(?HORSE_CACHE_REF, PlayerId) of
		[] ->
			Rec = #horse{gd_accountId = PlayerId},
			gen_cache:insert(?HORSE_CACHE_REF, Rec),
			Rec;
		[Rec | _] ->
			Rec
	end.


update_exp(PlayerId, TotalExp) ->
	gen_cache:update_element(?HORSE_CACHE_REF, PlayerId, [{#horse.gd_exp, TotalExp}]).	

update_current_equip(PlayerId, NewEquipId) ->
	gen_cache:update_element(?HORSE_CACHE_REF, PlayerId, [{#horse.gd_curHorseEquip, NewEquipId}]).

update_equip_list(PlayerId, NewEquipList) ->
	gen_cache:update_element(?HORSE_CACHE_REF, PlayerId, [{#horse.gd_equipList, NewEquipList}]).



