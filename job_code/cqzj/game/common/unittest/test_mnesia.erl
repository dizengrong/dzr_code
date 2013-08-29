%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%      test_mnesia
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_mnesia).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

%% @doc 可以实现类似mysql的 limit操作
t_limit(Limit)->
    MaxExpRecordCount = Limit,
    MatchHead = #p_faction{_='_', silver=0},
    Guard = [],
    Result = ['$_'],
    case ets:select(db_faction,[{MatchHead, Guard, Result}],MaxExpRecordCount) of
        '$end_of_table' ->
            %% 当前表没有记录不需要处理
            ?INFO("$end_of_table",[]);
        {ExpRecordList,Continuation} ->
            ?INFO("ExpRecordList=~p,Continuation=~pw",[ExpRecordList,Continuation])
    end.



