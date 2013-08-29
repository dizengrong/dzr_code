%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @doc  处理角色相关的行为日志
%%%
%%% @end
%%% Created : 30 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_role).

-behaviour(gen_server).

-include("mgeerec.hrl").

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%===================================================================


%%--------------------------------------------------------------------
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
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.


%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.


%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


%%这里我们可以缓存同类请求，这样PHP在收到数据之后会容易产生合并的sql语句，暂时不做优化
do_handle_info({Module, Method, Data, _ProcessName, AgentID, _AgentName, GameID}) ->
    mgeerec_http:post(AgentID, GameID, Module, Method, Data),
    ok;
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]).

    
