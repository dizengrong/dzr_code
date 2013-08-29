%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created :  3 Jan 2011 by  <>
%%%-------------------------------------------------------------------
-module(mgeew_money_event_server).

-include("mgeew.hrl").

-behaviour(gen_server).

%% API
-export([start/0, start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 
-define(MONEY_EVENT_STATE_REQUEST, 1).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, 
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    case db:dirty_read(?DB_MONEY_EVENT_COUNTER, 1) of
        [] ->
            db:dirty_write(?DB_MONEY_EVENT_COUNTER, #r_money_event_counter{id=1, event_id=1});
        _ ->
            ignore
    end,

    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    do_handle_info(Info),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_handle_info({record_event, EventID, RoleID, EventInfo, MoneyChange}) ->
    do_record_event(EventID, RoleID, EventInfo, MoneyChange);
do_handle_info({erase_event, EventID}) ->
    do_erase_event(EventID);
do_handle_info({update_event_state, EventID, NewState}) ->
    do_update_event_state(EventID, NewState);
do_handle_info(Info) ->
    ?ERROR_MSG("mgeew_event_server, info: ~w", [Info]).

do_record_event(EventID, RoleID, EventInfo, MoneyChange) ->
    Event = #r_money_event{event_id=EventID, role_id=RoleID, event_info=EventInfo, money_change=MoneyChange, state=?MONEY_EVENT_STATE_REQUEST},
    db:dirty_write(?DB_MONEY_EVENT, Event).

do_erase_event(EventID) ->
    db:dirty_delete(?DB_MONEY_EVENT, EventID).

do_update_event_state(EventID, NewState) ->
    case db:dirty_read(?DB_MONEY_EVENT, EventID) of
        [EventInfo] ->
            db:dirty_write(?DB_MONEY_EVENT, EventInfo#r_money_event{state=NewState});
        _ ->
            ignore
    end.
