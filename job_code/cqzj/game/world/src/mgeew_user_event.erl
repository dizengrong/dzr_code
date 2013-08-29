%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  7 Jan 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeew_user_event).

-behaviour(gen_server).

-include("mgeew.hrl").

%% API
-export([start/0, start_link/0]).

-export([
         deposit/2,
         record/3
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
deposit(EventType, EventData) ->
    erlang:send(?MODULE, {deposit_event, EventType, EventData}).

record(RoleID, EventType, Data) ->
    erlang:send(?MODULE, {record, RoleID, EventType, Data}).

%%--------------------------------------------------------------------
%% @doc
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent, 30000, worker, 
                                                 [?MODULE]}).


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
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

do_handle_info({deposit_event, EventType, EventData}) ->
    user_event_disposit:handle(EventType, EventData),
    ok;
do_handle_info({record, RoleID, EventType, Data}) ->
    do_record(RoleID, EventType, Data),
    ok;
do_handle_info({?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr, _SuccReturn}) ->
       %% 暂时统一管理，直接通知
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=RoleAttr#p_role_attr.silver},
                     #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=RoleAttr#p_role_attr.silver_bind},
                     #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=RoleAttr#p_role_attr.gold},
                     #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=RoleAttr#p_role_attr.gold_bind}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList),
    ok;
do_handle_info({?ADD_ROLE_MONEY_FAILED, _RoleID, _Reason, _FailedReturn}) ->
    ok;
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]).

do_record(RoleID, EventType, Data) ->
    db:transaction(
      fun() ->
              [#r_user_event_counter{value=ID}] = db:read(?DB_USER_EVENT_COUNTER, 1, write),
              NewID = ID + 1,
              db:write(?DB_USER_EVENT_COUNTER, #r_user_event_counter{id=1, value=NewID}, write),
              db:write(?DB_USER_EVENT, #r_user_event{id=NewID, role_id=RoleID, type=EventType, data=Data}, write)
      end),
    ok.

