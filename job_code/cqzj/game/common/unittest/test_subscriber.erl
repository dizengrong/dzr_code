%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_subscriber).

-behaviour(gen_server).
-compile(export_all).
-define( INFO(F,D),io:format(F, D) ).

-include("common_server.hrl").
-include("mnesia.hrl").


%% API
-export([start/1, start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


-record(state, {}).

%%
%% test Functions 
%%

%% 对subscribe进行测试——
%% 1）dirty_write,包括本节点(world)，和其他节点(db)的操作
%% 2）transaction 如果失败，是否不会受到事件？
%% 3）transaction 如果成功，是否可以正常收到事件？
%% 4）对cache的合并写进行修改
test_cache(Count)->
    [ do_write_table(Num) ||Num<-lists:seq(1, Count) ],
    ok.

do_write_table(Num)->
    Tab = db_role_faction,
    R2 = #r_role_faction{faction_id=2,number=Num},
    R3 = #r_role_faction{faction_id=3,number=Num},
    R4 = #r_role_faction{faction_id=4,number=Num},
    ok = db:dirty_write(Tab,R2),
    ok = db:dirty_write(Tab,R3),
    ok = db:dirty_write(Tab,R4).

test_d1()->
	db:dirty_delete(db_goods_counter,101).

test_r1()->
	db:dirty_read(db_goods_counter,101).


%%
%% API Functions
%%
subscribe(Tab)->
	gen_server:cast(?MODULE, {subscribe,Tab}),
	?ERROR_MSG("wuzesen subscribe",[]),
	ok.



%%--------------------------------------------------------------------

init([]) ->
	State = #state{},
	{ok, State}.

start(Sup) ->
    {ok, _} = supervisor:start_child(Sup, {?MODULE, 
                                          {?MODULE, start_link, []},
                                          permanent, 300000, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


%%--------------------------------------------------------------------



%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({subscribe,Tab}, State) ->
	?ERROR_MSG("wuzesen do subscribe",[]),
	mnesia:subscribe({table, Tab, detailed}),
	{noreply, State};

handle_cast(Msg, State) ->
	?ERROR_MSG("wuzesen, receive Msg=~p",[Msg]),
	{noreply, State}.

handle_info(Info, State) ->
	?ERROR_MSG("wuzesen, receive Info=~p",[Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================



