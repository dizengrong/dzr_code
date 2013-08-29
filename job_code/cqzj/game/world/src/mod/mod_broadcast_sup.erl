%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 消息广播接口监控树
%%% @end
%%% Created : 12 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_sup).

-behaviour(supervisor).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

%% Supervisor callbacks

-export([start_link/0,init/1]).


%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @spec init(Args) -> {ok, {SupFlags, [ChildSpec]}} |
%%                     ignore |
%%                     {error, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
%%    {ok,{{simple_one_for_one,10,10}, 
%%         [{mod_broadcast, 
%%           {mod_broadcast, start_link, []}, 
%%           transient, brutal_kill, worker, [mod_broadcast_general,mod_broadcast_cycle,mod_broadcast_countdown]}
%%         ]}}.
    RestartStrategy = one_for_one,
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

%%    Restart = permanent,
%%    Shutdown = 2000,
%%    Type = worker,

%%    AChild = {'AName', {'AModule', start_link, []},
%%              Restart, Shutdown, Type, ['AModule']},

    {ok, {SupFlags, []}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
