%%% -------------------------------------------------------------------
%%% Author  : dzr
%%% Description :
%%%
%%% Created : 2011-12-29
%%% -------------------------------------------------------------------
-module(mod_statistics).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").

-define(STATISTICS_INTERVAL, 300*1000).
-define(STATISTICS_INTERVAL1, 60*1000).

%% --------------------------------------------------------------------
%% External exports
-export([start_link/0, stop_statistics/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([online_players/0, now_online_players/0, get_online_players/0]).

-record(state, {line_id = 0}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
	gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

%% just do something befor shuntdown this mod
stop_statistics() ->
	gen_server:call(?MODULE, stop_statistics).

online_players() ->
	gen_server:cast(?MODULE, online_players).

now_online_players() ->
	Pid = erlang:whereis(mod_statistics),
	Pid ! now_online_players.

get_online_players() ->
	ets:info(ets_online, size).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
	process_flag(trap_exit, true),
	?INFO(?MODULE, "init ~w", [?MODULE]),
	
	now_online_players(),
	
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 在进程关闭时将当前在线人数写入数据库
handle_call(stop_statistics, _From, State) ->
	?INFO(?MODULE, "stop statistics"),
	
	OnlinePlayers = ets:info(?ETS_ONLINE, size),
	Now = util:unixtime(),
	Sql = db_sql:make_insert_sql(log_ServerOnlineCount, 
								["time", "OnlineCount"], 
								[Now, OnlinePlayers]),
								
	?INFO(?MODULE, "statistics excute sql [~w].", [Sql]),
	db_sql:execute(?USER_LOG_DB,Sql),
	
    {reply, ok, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 每5分钟将在线人数写入到数据库中
handle_info(now_online_players, State) ->
	OnlinePlayers = ets:info(?ETS_ONLINE, size),
	Now = util:unixtime(),
	Sql = db_sql:make_insert_sql(log_ServerOnlineCount, 
								["time", "OnlineCount"], 
								[Now, OnlinePlayers]),
								
	?INFO(?MODULE, "statistics excute sql [~w].", [Sql]),
	db_sql:execute(?USER_LOG_DB,Sql),
	erlang:send_after(?STATISTICS_INTERVAL1, self(), now_online_players),
	
    {noreply, State};
    
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, _State) ->
	?INFO(?MODULE, "terminate with reason: ~w", [Reason]),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

