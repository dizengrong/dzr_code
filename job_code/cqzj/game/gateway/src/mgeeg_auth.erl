%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-11
%%% -------------------------------------------------------------------
-module(mgeeg_auth).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeeg.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start/2, start_link/2, auth/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {socket}).

-define(TIMEOUT, 15000).

%% ====================================================================
%% External functions
%% ====================================================================

start(LoginHost, LoginPort) ->
    {ok, _} = supervisor:start_child(mgeeg_sup, 
                                     {?MODULE, 
                                      {?MODULE, start_link, [LoginHost, LoginPort]},
                                      transient, 10000, worker, [?MODULE]}).

start_link(LoginHost, LoginPort) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [LoginHost, LoginPort], []).

%% ====================================================================
%% Server functions
%% ====================================================================

auth({_AccountName, _Key}) ->
    %%gen_server:call(?MODULE, {auth, AccountName, Key}).
    ok.

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([LoginHost, LoginPort]) ->
    case gen_tcp:connect(LoginHost, LoginPort, [], ?TIMEOUT) of
        {ok, Socket} ->
            {ok, #state{socket=Socket}};
        {error, Reason} ->
            ?ERROR_MSG("cannot connect to the Login Server ~w:~w, Reason:~w", 
                       [LoginHost, LoginPort, Reason]),
            {stop, Reason}
    end.


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

handle_call({auth, AccountName, Key}, _From, {socket=Socket}=State) ->
    case erlang:is_port(Socket) of
        true ->
            L = erlang:byte_size(AccountName),
            L2 = erlang:byte_size(Key),
            Bin = << <<"auth_key">>/binary, L, AccountName/binary, L2, Key/binary>>,
            gen_tcp:send(Socket, Bin),
            case gen_tcp:recv(Socket, 0) of
                {ok, <<"ok">>} ->
                    Reply = ok;
                {ok, Other} ->
                    Reply = {fail, binary_to_list(Other)};
                {error, Reason} ->
                    ?ERROR_MSG("~w", [Reason]),
                    Reply = {error, system_error}
            end;
        false ->
            Reply = {error, system_error}
    end,
    {reply, Reply, State};


handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~w", [Info]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    ?INFO_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
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

