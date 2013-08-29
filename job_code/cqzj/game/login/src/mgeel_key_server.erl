%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-17
%%% -------------------------------------------------------------------
-module(mgeel_key_server).

-behaviour(gen_server).

-include("mgeel.hrl").

-define(ETS_KEY, ets_key).

-define(ETS_LINE_INFO, ets_line_info).

-export([
         start/0, 
         start_link/0,
         gen_key/2
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

gen_key(Account, RoleID) ->
    gen_server:call({global, ?MODULE}, {gen_key, Account, RoleID}).


start() ->
    {ok, _} = supervisor:start_child(mgeel_sup, {mgeel_key_server,
                                                 {mgeel_key_server, start_link, []},
                                                 transient, brutal_kill, worker, 
                                                 [mgeel_key_server]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).


%% --------------------------------------------------------------------
init([]) ->
    ets:new(?ETS_KEY, [public, set, named_table]),
    {ok, MD5Key} = application:get_env(md5key),
    {ok, MD5Key}.


%% --------------------------------------------------------------------

handle_call(get_one_gateway, _From, State) ->
    #p_line_info{ip=Host, port=Port}  = mgeel_line:get_line(),
    {reply, {Host, Port}, State};

handle_call({gen_key, Account, RoleID}, _From, State) ->
    [{Now, Key}, {Now2, Key2}] = gen_key(Account, RoleID, State),
    ets:insert(?ETS_KEY, {Key, Account, RoleID, Now}),
    ets:insert(?ETS_KEY, {Key2, Account, RoleID, Now2}),
    {reply, [{Now, Key}, {Now2, Key2}], State};


handle_call({get_all_lines_and_key, AccountName, RoleID}, _, State) ->
    case mgeel_line:get_line() of
        undefined ->
            {reply, starting, State};
        #p_line_info{ip=Host, port=Port} ->
            {Now, Key} = gen_key(AccountName, RoleID, common_tool:now(), State),
            ets:insert(?ETS_KEY, {Key, AccountName, RoleID, Now}),
            {reply, {Host, Port, Key}, State}
    end;

%% Type:: line | chat
handle_call({auth_key, Account, RoleID, Key}, _From, State) ->
    case Key =:= common_config:get_super_key() of
        true ->
            ?ERROR_MSG("try to login with super key,Account=~w,RoleID=~w,Key=~w",[Account,RoleID,Key]),
            Reply = ok;
        false ->
			case common_config:is_debug() of
				true ->
					Reply = ok;
				false ->
					case ets:lookup(?ETS_KEY, Key) of
						[{Key, Account, RoleID, Time}] ->
							case common_tool:now() - Time < 600 of
								true ->
									Reply = ok;
								false ->
									?DEBUG("~ts", ["key过期了"]),
									Reply = {error, ?_LANG_KEY_TIME_LIMIT}
							end;
						Other ->
							?ERROR_MSG("~ts: ~w =/= ~w", ["key验证失败", [{Key, Account, RoleID}], Other]),
							Reply = {error, ?_LANG_KEY_NOT_VALID}
					end
			end
    end,
    ets:delete(?ETS_KEY, Key),
    {reply, Reply, State};


handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.


handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~w", [Info]),
    {noreply, State}.


terminate(Reason, State) ->
    ?INFO_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------

gen_key(Account, RoleID, MD5Key) ->
    Now = common_tool:now(),
    [
     {Now, common_tool:md5(lists:concat(["mgeel_key", Now, common_tool:to_list(Account), RoleID, MD5Key]))},
     {Now + 1,  common_tool:md5(lists:concat(["mgeel_key", Now + 1, common_tool:to_list(Account), RoleID, MD5Key]))}
     ].

gen_key(Account, RoleID, Now, MD5Key) ->
    {Now, common_tool:md5(lists:concat(["mgeel_key", Now, common_tool:to_list(Account), RoleID, MD5Key]))}.
    
