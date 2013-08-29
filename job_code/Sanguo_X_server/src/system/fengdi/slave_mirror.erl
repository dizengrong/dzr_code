-module (slave_mirror).

-include("common.hrl").

-export([start_link/0, get_non_slaves/0, lock_player/1, unlock_player/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% internal
-export([get_non_slaves2/2, lock_player2/2, unlock_player2/2]).

-define(MAX_TRAVERSE_TIMES,		2).	%% 最大循环变量次数

-record(state, {
		queue,					%% 当前得到的所有非奴隶的玩家id的队列
		quene_copy,				%% queue字段设置后的最初副本
		traverse_times = 0,		%% 这里实现的是当到达?MAX_TRAVERSE_TIMES次数后会重新设置queue数据
		lock_list = []			%% 锁住的玩家id，他们不能被挑战的
	}).

start_link()->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 随机获取8个不是奴隶的且开启了奴隶功能的玩家id的list
get_non_slaves() ->
	gen_server:call(?MODULE, {request, get_non_slaves2, []}).

%% 请求锁定某个玩家
lock_player(PlayerId) ->
	gen_server:call(?MODULE, {request, lock_player2, [PlayerId]}).	

%% 请求解锁某个已锁定的玩家	
unlock_player(PlayerId) ->
	gen_server:cast(?MODULE, {request, unlock_player2, [PlayerId]}).
%% =================================================================
%% =================================================================
init([]) ->
	erlang:process_flag(trap_exit, true),
	{ok, do_init([])}.
	

do_init(LockList) ->
	SlaveRecs    = fengdi_db:get_all_slave_recs(),
	Pred         = fun(SlaveRec) -> (SlaveRec#slave.slave_owner == 0) end,
	PlayerIdList = [SlaveRec#slave.gd_accountId || SlaveRec <- lists:filter(Pred, SlaveRecs)],
	Q            = queue:from_list(PlayerIdList),
    #state{
			queue      = Q,
			quene_copy = Q,
			lock_list  = LockList}.

handle_cast({request, Action, Args}, State) ->
	NewState = ?MODULE:Action(State, Args),
	{noreply, NewState}.

handle_call({request, Action, Args}, _From, State) ->
	{NewState, Reply} = ?MODULE:Action(State, Args),
	{reply, Reply, NewState}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, State) ->
	?INFO(slave_mirror, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.		

%% ===================================================================
%% ===================================================================

get_non_slaves2(State, []) ->
	{Q, PlayerIdList} = get_max_8_non_slave(State#state.queue),
	State1 = case queue:is_empty(Q) of
		true -> 
			TraverseTimes = State#state.traverse_times + 1,
			case TraverseTimes >= ?MAX_TRAVERSE_TIMES of
				true ->
					do_init(State#state.lock_list);
				false ->
					State#state{
							traverse_times = TraverseTimes, 
							queue          = State#state.quene_copy}
			end;
		false ->
			State#state{
							queue= Q}
	end,

	{State1, PlayerIdList}.

lock_player2(State, [PlayerId]) ->
	LastestSlaveRec = fengdi_db:get_slave_rec(PlayerId),
	IsNonSlave = (LastestSlaveRec#slave.slave_owner == 0),
	IsLocked = lists:member(PlayerId, State#state.lock_list),
	case IsLocked of
		true ->
			?ERR(slave_mirror, "player ~w is already locked", [PlayerId]);
		false ->
			case IsNonSlave of
				true ->
					skip;
				false ->
					?ERR(slave_mirror, "player ~w is slave!", [PlayerId])
			end
	end,
	CanLock = (IsNonSlave andalso (IsLocked == false)),
	case CanLock of
		true ->
			State1 = State#state{lock_list = [PlayerId | State#state.lock_list]};
		false ->
			State1 = State
	end,
	{State1, CanLock}.

unlock_player2(State, [PlayerId]) ->
	case lists:member(PlayerId, State#state.lock_list) of
		false ->
			?ERR(slave_mirror, "player ~w not locked", [PlayerId]),
			State1 = State;
		true ->
			State1 = State#state{lock_list = lists:delete(PlayerId, State#state.lock_list)}
	end,
	State1.


get_max_8_non_slave(Q) ->
	get_max_8_non_slave2(1, queue:out(Q), []).


get_max_8_non_slave2(5 , {_, Q}, PlayerIdList) -> {Q, PlayerIdList};
get_max_8_non_slave2(_Num , {empty, Q}, PlayerIdList) -> {Q, PlayerIdList};
get_max_8_non_slave2(Num , {{value, PlayerId}, Q}, PlayerIdList) ->
	LastestSlaveRec = fengdi_db:get_slave_rec(PlayerId),
	Level = mod_role:get_main_level(PlayerId),
	case LastestSlaveRec#slave.slave_owner > 0 orelse Level < 35 of
		true ->
			get_max_8_non_slave2(Num, queue:out(Q), PlayerIdList);
		false ->
			get_max_8_non_slave2(Num + 1, queue:out(Q), [PlayerId | PlayerIdList])
	end.


