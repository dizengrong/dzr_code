-module (slave_timer).

-include ("common.hrl").

-behaviour(gen_timer). 

-export([add_timer/3, cancle_timer/1, start_link/0]).

%% gen_timer call back
-export([timeout_action/1]).

start_link() -> 
	gen_timer:start_link(?MODULE, ?MODULE).

%% 奴隶过期时间的timer Key为：{slave_expire, SlaveId}
%% Data为：{slave_expire, SlaveOwnerId, Pos, SlaveId}
add_timer(Timeout, Key, Data) ->
	gen_timer:add_timer(?MODULE, Timeout, Key, Data).

cancle_timer(Key) ->
	gen_timer:cancle_timer(?MODULE, Key).


timeout_action({slave_expire, SlaveOwnerId, Pos, SlaveId}) ->
	case fengdi_db:get_slave_by_cage(SlaveOwnerId, Pos) of
		?CAGE_NOT_OPEN ->
			?ERR(slave_timer, "Error, player ~w's cage ~w not even opened", [SlaveOwnerId, Pos]);
		?CAGE_OPENED ->
			?ERR(slave_timer, "player ~w's cage ~w is already free", [SlaveOwnerId, Pos]);
		SlaveId ->
			fengdi_db:reset_cage(SlaveOwnerId, Pos),
			fengdi_db:free_slave(SlaveId);
		ExpectedSlaveId ->
			?ERR(slave_timer, "slave id ~w is not the expected one: ~w", [SlaveId, ExpectedSlaveId])
	end.
			%% TO-DO: send mail to SlaveOwner



