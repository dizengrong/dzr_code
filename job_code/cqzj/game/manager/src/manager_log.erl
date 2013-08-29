%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 30 Mar 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(manager_log).

-behaviour(gen_server).

-include("manager.hrl").

%% API
-export([
         start/0, 
         start_link/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
	{ok, _} = supervisor:start_child(
                    manager_sup, 
                    {?MODULE, 
                     {?MODULE, start_link, []}, 
                     transient, 10000, worker, [?MODULE]}).
%%--------------------------------------------------------------------
%% @doc
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.

%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_handle_info({system_log, Time, Format, Args}) ->
    {{Y,Mo,D},{H,Mi,S}} = Time, 
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    Time2 = io_lib:format("~p ~p ==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ===",
		  [AgentName, ServerName, Y, Mo, D, H, Mi, S]),
    L2 = lists:concat(["system_info ", Time2]),
    B = unicode:characters_to_binary(L2),
    LogFiePath = lists:concat(["/data/logs/",AgentName,"_",ServerName,"/cqzj_manager.log"]),
    file:write_file(LogFiePath, B, [append]),
    try 
        io:format("~n", []),
        io:format(Format, Args),
        M = io_lib:format(Format, Args),
        file:write_file(LogFiePath, M, [append])
    catch _:Error ->
            io:format("log error ~p ~p ~p", [Error, Format, Args])
    end,
    ok;
do_handle_info(Info) ->
    erlang:send(erlang:self(), {system_log, erlang:localtime(), "~ts:~w", ["未知的消息", Info]}),
    ok.
