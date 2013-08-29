%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-11
%%% -------------------------------------------------------------------
-module(mgeem_config).

-behaviour(gen_server).
-include("mgeem.hrl").

-export([
         start/0,
         start_link/0,
         set/2,
         get/1
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

-define(ETS_CONFIG, mgeem_ets_config).

start() ->
    {ok, _} = supervisor:start_child(
                mgeem_sup, 
                {?MODULE, {?MODULE, start_link, []}, transient, 10000, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).


%% ====================================================================

set(Key, Value) ->
    gen_server:call({global, ?MODULE},  {set, Key, Value}).

%% return value or undefined when not found
-spec(get(Key :: term()) -> term() | undefined).
get(Key) ->
    gen_server:call({global, ?MODULE}, {get, Key}).

%% --------------------------------------------------------------------
init([]) ->
    ets:new(?ETS_CONFIG, [protected, named_table, set]),
    {ok, #state{}}.

%% --------------------------------------------------------------------
handle_call({set, Key, Value}, _From, State) ->
    ets:insert(?ETS_CONFIG, {Key, Value}),
    {reply, ok, State};


handle_call({register_line, Line}, _, State) ->
    Line2 = common_tool:to_integer(Line),
    ?DEBUG("new line ~w", [Line2]),
    case ets:lookup(?ETS_CONFIG, lines) of
        [{lines, List}] ->
            ?DEBUG("previous result ~w", [List]),
            case lists:member(Line2, List) of
                true ->
                    ignore;
                false ->
                    ets:insert(?ETS_CONFIG, {lines, lists:append(List, [Line2])})
            end;
        _ ->
            ets:insert(?ETS_CONFIG, {lines, [Line2]})
    end,
    {reply, ok, State};


handle_call({get, Key}, _From, State) ->
    case ets:lookup(?ETS_CONFIG, Key) of
        [{Key, Value}] ->
            Reply = Value;
        _ ->
            Reply = undefined
    end,
    {reply, Reply, State};


handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.

%% --------------------------------------------------------------------
handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~w", [Info]),
    {noreply, State}.

%% --------------------------------------------------------------------
terminate(Reason, State) ->
    ?INFO_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
    ok.

%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
