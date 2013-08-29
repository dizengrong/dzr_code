%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description :
%%% 
%%% Created : 2010-09-01
%%% -------------------------------------------------------------------
-module(mgeem_mission).
 
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mission.hrl").
%% --------------------------------------------------------------------

-record(state, {}).

%% External exports
-export([start/0, start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([]).
%% ====================================================================
%% Server functions
%% ====================================================================
start() ->
    {ok, _} = 
        supervisor:start_child(
          mgeem_sup, 
          {?MODULE, 
           {?MODULE, start_link, []}, 
           permanent, 
           brutal_kill, 
           supervisor, [?MODULE]}),
    ok.

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% --------------------------------------------------------------------
%% gen_server 函数块 开始
%% --------------------------------------------------------------------

init([]) ->
    erlang:process_flag(trap_exit, true),
%%     mod_mission_data:code_build_mission_bin(),
    {ok, #state{}}.

handle_call(_Info, _From, State) ->
    {replay, ok, State}.

handle_info({'EXIT', _From, normal}, State) ->
    {noreply, State};

handle_info(Info, State) ->
    ?ERROR_MSG("~ts:~w", ["收到未知消息", Info]),
    {noreply, State}.

handle_cast(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%% gen_server 函数块 结束
%% --------------------------------------------------------------------