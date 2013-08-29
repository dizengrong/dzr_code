%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description :
%%% 
%%% Created : 2011-03-20
%%% -------------------------------------------------------------------
-module(mgeem_event).
 
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").
%% --------------------------------------------------------------------

-record(state, {}).
-record(event_data, {key, dispatch_time, deal_model, deal_method, params}).

-define(event_list, event_list).
%% External exports
-export([start/0, start_link/0, set_event/4, set_event/5, del_event/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% ====================================================================
%% Server functions
%% ====================================================================
start() ->
    Result = 
        supervisor:start_child(
          mgeem_sup, 
          {?MODULE, 
           {?MODULE, start_link, []}, 
           permanent, 
           brutal_kill, 
           supervisor, [?MODULE]}),
    case Result of
        {ok, _Pid} ->
            ok;
        {error, {already_started, _}} -> 
            ok;
		{error, {{already_started, _}, _}} -> 
            ok;
        {error, Reason} ->
            ?ERROR_MSG("~ts ~w", ["创建活动管理器失败", Reason]),
            {error, Reason}
    end.

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% --------------------------------------------------------------------
%% gen_server 函数块 开始
%% --------------------------------------------------------------------
set_event(Key, DispatchTime, DealModel, DealMethod, Params) ->
    Now = common_tool:now(),
    if
        DispatchTime < Now ->
            ignore;
        true ->
            global:send(?MODULE, {set_event, Key, DispatchTime, DealModel, DealMethod, Params})
    end.

set_event(Key, DispatchTime, DealModel, DealMethod) ->
    global:send(?MODULE, {set_event, Key, DispatchTime, DealModel, DealMethod, null}).

del_event(Key) ->
    global:send(?MODULE, {del_event, Key, null}).
    

init([]) ->
    erlang:process_flag(trap_exit, true),
    erlang:send_after(1000, self(), loop),
    init_event(),
    {ok, #state{}}.

handle_call(_Info, _From, State) ->
    {replay, ok, State}.

handle_info({'EXIT', _From, normal}, State) ->
    {noreply, State};

handle_info({set_event, Key, DispatchTime, DealModel, DealMethod, Params}, State) ->
    List = do_del_event(Key),
    EventData = #event_data{key=Key,
                            dispatch_time=DispatchTime, 
                            deal_model=DealModel, 
                            deal_method=DealMethod,
                            params=Params},
    NewList = [EventData|List],
    put(?event_list, NewList),
    {noreply, State};

handle_info({del_event, Key}, State) ->
    do_del_event(Key),
    {noreply, State};

handle_info(loop, State) ->
    erlang:send_after(1000, self(), loop),
    do_loop(),
    {noreply, State};

handle_info({dispatch_event, EventData}, State) ->
    #event_data{deal_model=Model, 
                deal_method=Method, 
                params=Params} = EventData,
    try
        if
            Params =:= null ->
                Model:Method();
            true ->
                Model:Method(Params)
        end
    catch
        _:Error ->
            ?ERROR_MSG("~ts:~w Error-->", ["派发活动事件失败了", Error,erlang:get_stacktrace()])
    end,
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
do_del_event(Key) ->
    OldList = get_event_list(),
    ListUnique = lists:keydelete(Key, #event_data.key, OldList),
    put(?event_list, ListUnique),
    ListUnique.

get_event_list() ->
    case get(?event_list) of
        undefined ->
            [];
        List ->
            List
    end.

do_loop() ->
    Now = common_tool:now(),
    EventList = get_event_list(),
    lists:foreach(fun(Event) ->
        #event_data{dispatch_time=DispatchTime} = Event,
        if
            Now >= DispatchTime ->
                dispatch_event(Event);
            true ->
                ignore
        end
    end, EventList).

dispatch_event(Event) ->
    do_del_event(Event#event_data.key),
    self() ! {dispatch_event, Event}.

init_event() ->
    mod_ybc_person:init_event().