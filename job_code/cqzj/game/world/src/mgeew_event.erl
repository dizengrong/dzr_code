%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 全局事件管理
%%%
%%% @end
%%% Created :  7 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeew_event).

-behaviour(gen_server).

-include("mgeew.hrl").

%% API
-export([
         start/0,
         start_link/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE, {?MODULE, start_link, []},
                                                 permanent, 30000, worker, [?MODULE]}).

%%--------------------------------------------------------------------

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).


%%--------------------------------------------------------------------
init([]) ->
    mod_event_warofking:init_config(),
    mod_event_waroffaction:init_config(),
    %% 初始化在开服多少天之后要处理的时间
    init_open_day_delay_event(common_config:is_debug()),
    {ok, #state{}}.


handle_call({Module, Request}, _From, State) ->
    Reply = Module:handle_call(Request),
    {reply, Reply, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================

do_handle_info(set_fcm_open) ->
    common_fcm:set_fcm_flag(true);
do_handle_info({Module, Info}) when is_atom(Module) ->
    Module:handle_info(Info);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知的消息", Info]).

init_open_day_delay_event(IsDebug) when IsDebug =:= false ->
	case common_config_dyn:find_common(auto_open_fcm) of
		[true]->
			{Date, _} = common_config:get_open_day(),
			{NowDate, _} = erlang:localtime(),
			case calendar:date_to_gregorian_days(Date) - calendar:date_to_gregorian_days(NowDate) > 3 of
				true ->
					common_fcm:set_fcm_flag(true);
				false ->
					ThreeDayAfter = calendar:gregorian_days_to_date(calendar:date_to_gregorian_days(Date) + 3),
					Time = calendar:datetime_to_gregorian_seconds({ThreeDayAfter, {0, 0, 0}}) - 
							   calendar:datetime_to_gregorian_seconds({NowDate, {0, 0, 0}}),
					case Time =< 0 of
						true ->
							common_fcm:set_fcm_flag(true);
						false ->
							erlang:send_after(Time * 1000, erlang:self(), set_fcm_open)
					end
			end;
		_ ->
			nil
	end;

init_open_day_delay_event(_IsDebug) ->
	?ERROR_MSG("测试环境下开服日期超过3天，服务启动时不自动开启防沉迷",[]).