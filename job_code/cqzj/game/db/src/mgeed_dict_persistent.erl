%%%-------------------------------------------------------------------
%%% @author wuzesen
%%% @doc
%%%     进程字典数据的特殊持久化
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mgeed_dict_persistent).

-behaviour(gen_server).

-include("mgeed.hrl").
%% API
-export([
         start/0,
         start_link/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeed_sup, {?MODULE, 
                                                 {?MODULE, start_link, []},
                                                 transient, 90000000, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).



%%--------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.


%%--------------------------------------------------------------------

handle_call(Call, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Call, State),
    {reply, Reply, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.


%%--------------------------------------------------------------------
handle_info({'EXIT', PID, shutdown}, State) ->
    List = erlang:pid_to_list(PID),
    case string:str(List, "<0.") of
        0 ->
            {noreply, State};
        _ ->
            {stop, normal, State}
    end;
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
%%%===================================================================

do_handle_call(_) ->
    error.


%%db_local_cache_server 发送过来的数据变动信息

do_handle_info({store_queue, L}) ->
    do_store_queue(L);
do_handle_info({clear_table, Tab}) ->
    mnesia:clear_table(Tab);

do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知的消息", Info]).
 


do_store_queue([]) ->
    ok;
do_store_queue([H|T]) ->
    do_mnesia_store(H),
    do_store_queue(T).

%% @spec do_mnesia_subscriber_queue/1
%% @doc 通过Mnesia方式处理 队列,新的方式
do_mnesia_store({write,DbTab, Record}) ->
	mnesia:dirty_write(DbTab, Record);
do_mnesia_store({delete,DbTab, Key}) ->
	mnesia:dirty_delete(DbTab, Key);
do_mnesia_store({delete_object,DbTab, Object}) ->
	mnesia:dirty_delete_object(DbTab, Object).


%% get_whole_table_match_pattern(SourceTable) ->
%%     A = mnesia:table_info(SourceTable, attributes),
%%     RecordName = mnesia:table_info(SourceTable, record_name),
%%     lists:foldl(
%%       fun(_, Acc) ->
%%               erlang:append_element(Acc, '_')
%%       end, {RecordName}, A).
 

