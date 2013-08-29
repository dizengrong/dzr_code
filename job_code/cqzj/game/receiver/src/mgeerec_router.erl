%%%----------------------------------------------------------------------
%%% File    : mgeerec_router.erl
%%% Author  : Liangliang
%%% Created : 2010-06-30
%%% Description: 路由请求
%%%----------------------------------------------------------------------
-module(mgeerec_router).

-include("mgeerec.hrl").

-export([
         router/1
        ]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

%% @doc 非HTTP-Post方式的Module
-define(UN_HTTP_POST_MODULE_LIST,[?B_CONSUME,?B_GM,?B_PAY]).


router({ParentPID, BehaviorList, AgentID, GameID}) ->
    do_router({ParentPID, BehaviorList, AgentID, GameID}).


%% --------------------------------------------------------------------

%%暂时先实现为直接请求PHP页面
do_router({_ParentPID, BehaviorList, AgentID, GameID}) ->
    ?DEBUG("BehaviorList=~p",[BehaviorList]),
    
	%% 处理UnPostList
	UnPostList = lists:filter(fun({ModuleTuple1, _, _})->
									  is_unpost_module(ModuleTuple1)
							  end, BehaviorList),
	do_unpost_modulelist(AgentID, GameID, UnPostList),
	
	%% 处理PostList
	PostList=
		lists:foldl(
		  fun({ModuleTuple, MethodTuple, DataBinary}, Result) ->
				  
				  case is_unpost_module(ModuleTuple) of
					  true-> Result;
					  false->
						  ?DEBUG("~ts:~w ~ts:~w", ["整理发送到HTTP的数据, 模块", ModuleTuple, "方法", MethodTuple]),
						  case lists:keyfind({ModuleTuple, MethodTuple}, 1, Result) of
							  false ->
								  [{{ModuleTuple, MethodTuple}, [DataBinary]}|Result];
							  {_, List} ->
								  [{{ModuleTuple, MethodTuple}, [DataBinary|List]}|Result]
						  end
				  end
		  end, [], BehaviorList),
	
	do_post_modulelist(AgentID, GameID, PostList).


%% @doc 判断是否为非HTTP-Post方式的Module
is_unpost_module(ModuleTuple)->
    lists:member(ModuleTuple, ?UN_HTTP_POST_MODULE_LIST).

%% @doc 处理HTTP Post方式的Module
do_post_modulelist(AgentID, GameID, PostList)->
	lists:foreach(
	  fun({{ModuleTuple, MethodTuple}, BinList}) ->
			  mgeerec_http:post(AgentID, GameID, ModuleTuple, MethodTuple, BinList),
			  timer:sleep(100)%%避免频繁请求php
	  end, PostList).

%% @doc 处理其他方式的Module
do_unpost_modulelist(AgentID, GameID, UnPostList)->
    [ do_unpost_module(AgentID, GameID, Req)  || Req <- UnPostList  ].

do_unpost_module( AgentID, GameID, {_ModuleTuple, MethodTuple, DataBinary} )->
    ?DEBUG("MethodTuple=~p",[MethodTuple]),
    try
        case MethodTuple of
            ?B_CONSUME_GOLD->
                Record = mgeerec_packet:decode(DataBinary),
                mod_consume_receiver:write_gold_log(AgentID, GameID, Record);
            
            ?B_PAY_LOG ->
                Record = mgeerec_packet:decode(DataBinary),
                mod_pay_receiver:write_pay_log(AgentID, GameID, Record);
            
            ?B_GM_COMPLAINT->
                Record = binary_to_term(DataBinary),
                mod_gm_receiver:write_complaint_log(AgentID, GameID, Record);
            
            ?B_GM_EVALUATE->
                Record = binary_to_term(DataBinary),
                mod_gm_receiver:write_evaluate_log(AgentID, GameID, Record);
            
            ?B_GM_NOTIFY_REPLY->
                Record = binary_to_term(DataBinary),
                mod_gm_receiver:write_notice_reply_log(AgentID, GameID, Record)
        end
    catch
        _:Reason->
            ?ERROR_MSG("~ts,MethodTuple=~w,Reason=~w,Stacktrace=~w", ["执行do_unpost_module出错", MethodTuple,Reason,erlang:get_stacktrace()])
    end.
    





