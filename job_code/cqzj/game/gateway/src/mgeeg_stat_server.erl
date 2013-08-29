%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mgeeg_stat_server   统计玩家 的方法调用次数
%%% @end
%%% Created : 2010-12-15
%%%-------------------------------------------------------------------
-module(mgeeg_stat_server).
-behaviour(gen_server).
-record(state,{}).


-export([start/0,start_link/0]).
-export([dump_stat_data/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%%定时发消息进行持久化
-define(DUMP_INTERVAL, 10 * 1000).
-define(IS_STAT_OPEN,true).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeeg.hrl").
-include("mm_parse_list.hrl").

%% ====================================================================
%% External functions
%% ====================================================================
start() ->
    {ok, _} = supervisor:start_child(mgeeg_sup, {?MODULE, 
                                                 {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({local,?MODULE},?MODULE, [], []).

init([]) ->
    
	
	State = #state{},
	{ok, State}.

dump_stat_data()->
    gen_server:call(?MODULE, {dump_stat_data}).

%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call({dump_stat_data}, _From, State) ->
    Reply = do_dump_stat_data(),
    {reply, Reply, State};
handle_call(_Request, _From, State) ->
	Reply = ok,
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


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

-define(METHOD_STAT_KEY(K),{stat_key,K}).

do_handle_info({stat_method,Method})->
    case ?IS_STAT_OPEN of
        true->
            case get(?METHOD_STAT_KEY(Method)) of
                undefined->
                    put(?METHOD_STAT_KEY(Method),1);
                N when is_integer(N)->
                    put(?METHOD_STAT_KEY(Method),N+1)
            end;
        _ ->
            ignore
    end;
 

do_handle_info(Info)->
	?ERROR_MSG("receive unknown message,Info=~w",[Info]),
	ignore.

%%@doc 将统计数据，每分钟保存到db中
do_dump_stat_data()->
    try
      DictList = erlang:get(),
      StatList = lists:filter(fun(E)-> 
                                  {K,_V} = E,
                                  case K of
                                      ?METHOD_STAT_KEY(_) -> true;
                                      _ -> false
                                  end
                              end, DictList),
      case StatList of
          []->
              ignore;
          _ ->
              Queues = [ [ Key,get_method_name(Key),Num] || {{_,Key},Num} <-StatList ],
              Queues
              %%do_dump_to_mysql(Queues)
      end
    catch
        _:Reason1->
          ?ERROR_MSG("写在线用户数失败,Reason=~w", [Reason1])
    end.

get_method_name(Key)->
    {Key,Name} = lists:keyfind(Key, 1, ?MM_PARSE_LIST),
    Name.

%% do_dump_to_mysql(Queues)->
%% 	try
%% 		Tab = t_stat_method,
%% 		SQLDel = mod_mysql:get_esql_delete(Tab, [] ),
%% 		{ok,_} = mod_mysql:delete(SQLDel),
%% 		
%% 		%%批量插入的数据，目前最大不能超过3M
%% 		FieldNames = [ id,method,num ],
%% 		BatchFieldValues = Queues,
%%         mod_mysql:batch_insert(Tab,FieldNames,BatchFieldValues,3000)
%% 	catch
%% 		_:Reason->
%% 			?ERROR_MSG("插入玩家统计方法数据出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
%% 	end. 
