%%%-------------------------------------------------------------------
%%% @author Liangliang <Liangliang@gmail.com>
%%% Created : 14 Oct 2011 by Liangliang <Liangliang@gmail.com>
%%%-------------------------------------------------------------------
-module(global_gateway_server).

-behaviour(gen_server).

-include("mgeeg.hrl").

%% API
-export([start/0,start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(role_data_write_done,role_data_write_done).
-define(ROLE_LOGIN_AGAIN_KEY(),{role_login_again,RoleID}).


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    case global:whereis_name(?MODULE) of
        undefined ->
            {ok, _} = supervisor:start_child(mgeeg_sup, {?MODULE, {?MODULE, start_link, []},
                                                         permanent, 10000, worker, [?MODULE]});
        _ ->
            ignore
    end.

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
    {ok, #state{}}.

%%--------------------------------------------------------------------
handle_call(Request, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Request, State),
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
do_handle_call({check_role_login_flag, RoleID, GatewayPID}) ->
	Today = date(),
	case get( ?ROLE_LOGIN_AGAIN_KEY() ) of
		{Today,Cnt} when Cnt>30->
			?DBG("too_many_relogin,brushgold,RoleID=~w,Cnt=~w ",[RoleID,Cnt]),
			{error,too_many_relogin};
		_ ->
			check_role_login_flag_2(RoleID,GatewayPID)
	end.

check_role_login_flag_2(RoleID,_GatewayPID)->
	case erlang:get({?role_data_write_done, RoleID}) of
		undefined ->
			ok;
		_ ->
			{ok,writing}
	end.


%% 通知 玩家的信息已经持久化完成了 
do_handle_info({notify_role_write_done, RoleID}) ->
    erlang:erase({?role_data_write_done, RoleID}),
    ok;
%% 记录玩家重登的次数
do_handle_info({log_login_again, RoleID}) ->
	do_log_login_again(RoleID);
do_handle_info({clear_login, RoleID}) ->
    erase( ?ROLE_LOGIN_AGAIN_KEY() );
do_handle_info({check_if_role_write_doing, RoleID}) ->
    Now = common_tool:now(),
    case erlang:get({?role_data_write_done, RoleID}) of
        undefined -> ignore;
        {last_time,LastTime} when Now<(LastTime+299)-> ignore;
        _ ->
			check_role_brushgold(RoleID),
            ?ERROR_MSG("ERR~ts:~p", ["接收玩家写入数据完成标志超时", RoleID]),
            erlang:erase({?role_data_write_done, RoleID})
    end; 

do_handle_info({set_writing_flag, RoleID}) ->
	Now = common_tool:now(),
    erlang:send_after(300 * 1000, erlang:self(), {check_if_role_write_doing, RoleID}),
    erlang:put({?role_data_write_done, RoleID}, {last_time, Now});

%% do_handle_info({'DOWN', _MonitorRef, process, PID, _Info}) ->
%% 	RoleID = erlang:erase(PID),
%% 
%% 	Now = common_tool:now(),
%%     erlang:send_after(300 * 1000, erlang:self(), {check_if_role_write_doing, RoleID}),
%%     erlang:put({?role_data_write_done, RoleID}, {last_time,Now});

%% do_handle_info({new_client, RoleID, PID}) ->
%%     erlang:monitor(process, PID),
%% 	
%%     erlang:put(PID, RoleID);
do_handle_info(Info) ->
    ?ERROR_MSG("ERR~ts:~w", ["未知的消息", Info]),
    ok.


check_role_brushgold(RoleID)->
	case get( ?ROLE_LOGIN_AGAIN_KEY() ) of
        {_,Cnt} when Cnt>5->
            ?DBG("brushgold,RoleID=~w,Cnt=~w ",[RoleID,Cnt]);
        _ ->
			ignore
    end.

do_log_login_again(RoleID)->
	Today = date(),
    case get( ?ROLE_LOGIN_AGAIN_KEY() ) of
        {Today,Cnt}->
            ?DBG("log_login_again,RoleID=~w,Cnt=~w",[RoleID,Cnt]);
        _ ->
			Cnt = 0
    end,
	put( ?ROLE_LOGIN_AGAIN_KEY(),{Today,Cnt+1} ),
	ok.
