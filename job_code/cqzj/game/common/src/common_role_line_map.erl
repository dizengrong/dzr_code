%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 12 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_role_line_map).

-include("common.hrl").

-include("common_server.hrl").

-behaviour(gen_server).

%% API
-export([
         start/1,
         start_link/0,
         get_role_line/1,
         get_lines/0
        ]).
-export([stat_lines/0]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 
-define(ETS_LINES, ets_lines).

-define(GET_LINES_TICKET, 1000).

-record(state, {}).

start(ParentSup) ->
    {ok, _} = supervisor:start_child(ParentSup,
                                     {?MODULE,
                                      {?MODULE, start_link, []},
                                      transient, brutal_kill, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%获得玩家的分线
get_role_line(RoleID) ->
    case ets:lookup(?ETS_ROLE_LINE_MAP, RoleID) of
        [{RoleID, Line}] ->
            Line;
        _Other ->
            false
    end.

%%获得当前已知的所有分线
get_lines() ->
    [{lines, Lines}] = ets:lookup(?ETS_LINES, lines),
    Lines.

%%统计各个分线的人数，必须在world节点运行
stat_lines()->
    ets:foldl(fun(E,AccIn)-> 
                  {_RoleID, Line} = E,
                  case lists:keyfind(Line, 1, AccIn) of
                      false->
                          [{Line,1}|AccIn];
                      {Line,Sum1}->
                          lists:keystore(Line, 1, AccIn, {Line,Sum1+1})
                  end
              end, [], ?ETS_ROLE_LINE_MAP).

%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    ets:new(?ETS_ROLE_LINE_MAP, [protected, named_table, set]),
    ets:new(?ETS_LINES, [protected, named_table, set]),
    ets:insert(?ETS_LINES, {lines, []}),
    erlang:send_after(?GET_LINES_TICKET, self(), loop),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(Reason, _State) ->
    ?ERROR_MSG("~ts:~w", ["玩家分线存储进程down了", Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_handle_info(loop) ->
    case global:whereis_name(mgeel_line) of
        undefined ->
            ignore;
        _ ->
            Lines = gen_server:call({global, mgeel_line}, get_all_line),
            ets:insert(?ETS_LINES, {lines, Lines})
    end,
    erlang:send_after(?GET_LINES_TICKET, self(), loop);

do_handle_info({set, RoleID, Line}) ->
    ?DEBUG("~ts ~w ~w", ["注册玩家分线", RoleID, Line]),
    ets:insert(?ETS_ROLE_LINE_MAP, {RoleID, Line});
%%删除分线
do_handle_info({remove_line, Line}) ->
    ets:delete(?ETS_LINES, Line);
do_handle_info({remove, RoleID}) ->
    ?DEBUG("~ts ~w", ["删除玩家分线", RoleID]),
    ets:delete(?ETS_ROLE_LINE_MAP, RoleID).
