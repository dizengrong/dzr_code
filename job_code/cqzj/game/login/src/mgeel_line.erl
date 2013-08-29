%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-18
%%% -------------------------------------------------------------------
-module(mgeel_line).

-behaviour(gen_server).
-include("mgeel.hrl").


-define(ETS_LINE_INFO, ets_line_info).
-define(ETS_LINE_CONFIG, ets_line_config).

%% --------------------------------------------------------------------
-export([
         start/0, 
         start_link/0,
         get_line/0,
         get_module_info/0
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% --------------------------------------------------------------------

start() ->
    {ok, _} = supervisor:start_child(mgeel_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, 
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% --------------------------------------------------------------------


get_80_line() ->
    Lines = ets:tab2list(?ETS_LINE_INFO),
    Lines2 = lists:filter(
               fun({_, #p_line_info{port=Port}, _, _, Alive}) ->
                       Port =:= 80 andalso Alive
               end, Lines),
    case erlang:length(Lines2) > 0 of
        true ->
            R = erlang:hd(Lines2),
            {_, #p_line_info{port=Port, ip=IP}, _, _, _} = R,
            {IP, Port};
        false ->
            []
    end.

%%获得一条分线给客户端，通常是负载最低的
get_line() ->
    Lines = ets:tab2list(?ETS_LINE_INFO),
    Lines2 = lists:filter(
               fun({_, _, _, _, Alive}) ->
                       Alive =:= true
               end, Lines),
    %%找出负载最小的一个分线
    LinesSort = lists:sort(
                  fun({_, _, RA, _, _}, {_, _, RB, _, _}) ->
                          RA < RB
                  end, Lines2),

    %%取负载最小的5个分线的随机数
    RandomLineBase = case length(LinesSort) > 5 of
                         true->
                             5;
                         _->
                             length(LinesSort)
                     end,
    case RandomLineBase =:= 0 of
        true ->
            undefined;
        false ->            
            Random = common_tool:random(1, RandomLineBase),
            {_, Line, _, _, _} = lists:nth(Random, LinesSort),
            Line
    end.


get_module_info() ->
    I1 = ets:info(?ETS_LINE_INFO),
    ?DEBUG("~ts:~w ~n", ["分线信息", I1]),
    ok.

%% --------------------------------------------------------------------
init([]) ->
    %% 数据结构: {line, #p_line_info{guid,ip,port,line}, run_queue, last_active_time}
    %% run_queue越大代表负载越高
    ets:new(?ETS_LINE_INFO, [protected, named_table, set]),
    timer:send_after(5000, check_line_active),
    {ok, #state{}}.


%% --------------------------------------------------------------------

%%处理分线注册，如果在配置表里面没有对应的分线，则本次注册失败
handle_call({register, Host, Port}, _From, State) ->
    Reply = register_line(Host, Port),
    {reply, Reply, State};

handle_call(get_all_line, _, State) ->
    All = ets:tab2list(?ETS_LINE_INFO),
    Lines = lists:foldl(
              fun({Line, _, _, _, Flag}, Acc) ->
                      case Flag of 
                          true ->
                              [Line | Acc];
                          false ->
                              Acc
                      end
              end, [], All),
    {reply, Lines, State};

handle_call(get_80_line, _, State) ->
    Reply = get_80_line(),
    {reply, {ok, Reply}, State};

handle_call(get_one_line_and_key, _, State) ->
    Reply = get_line(),
    
    {reply, Reply, State};


handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~w from ~w", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~w", [Msg]),
    {noreply, State}.


%%更新每个分线的runqueue
handle_info({run_queue, Line, RunQueue}, State) ->
    do_run_queue(Line, RunQueue),
    {noreply, State};


%%定时检查分线是否还活着
handle_info(check_line_active, State) ->
    do_check_line_active(),
    {noreply, State};


handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~w", [Info]),
    {noreply, State}.


terminate(Reason, State) ->
    ?INFO_MSG("~w terminate : ~w, ~w", [self(), Reason, State]),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------

%%注册分线
register_line(Host, Port) ->
    ?DEBUG("~ts:~w ~w", ["分线注册", Host, Port]),
    IntPort = common_tool:to_integer(Port),
    Guid = common_tool:to_list(Port),
    LineConfig = #p_line_info{guid=Guid, ip=Host, port=IntPort, line=Guid},
    ets:insert(?ETS_LINE_INFO, {Port, LineConfig, 0, now(), true}).


%%更新每条分线的runqueue
do_run_queue(Line, RunQueue) ->
    [{Line, LineInfo, OldRunQueue, _, _}] = ets:lookup(?ETS_LINE_INFO, Line),
    ets:insert(?ETS_LINE_INFO, {Line, LineInfo, RunQueue + OldRunQueue, erlang:now(), true}).
    

%%检查分线是否活着，否的话需要移除
do_check_line_active() ->
    Lines = ets:tab2list(?ETS_LINE_INFO),
    lists:foreach(
      fun({Line, LineInfo, RunQueue, LastActiveTime, Active}) ->
              case timer:now_diff(now(), LastActiveTime) > 3000000 of
                  true ->
                      ?DEBUG("~ts", ["注销了一条分线"]),
                      case Active =:= true of
                          true ->
                              ets:insert(?ETS_LINE_INFO, {Line, LineInfo, RunQueue, LastActiveTime, false});
                          false ->
                              ignore
                      end;
                  false ->
                      ok
              end
      end, Lines),
    timer:send_after(1000, check_line_active).
