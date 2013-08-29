%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     测试对sql的执行，sql文本必须放在 /data/目录下
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_sql).

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

t_select()->
    do_test_sql( select,"/data/test.sql" ).

t_insert()-> 
    do_test_sql( insert,"/data/test.sql" ).

do_test_sql(Type, FilePath )-> 
    {Time, Result} = timer:tc(?MODULE, test_tc, [Type,FilePath]),
    ?INFO("~nNow=~w,Result=~w",[common_tool:now(),Result]),
    ?INFO("~n do_test_sql cost ~w ms(~w sec)",[Time/1000,Time/1000000]).


test_tc(select,FilePath)->
    {ok,Bin} = file:read_file( FilePath ),
    mod_mysql:select(Bin);
test_tc(insert,FilePath)->
    {ok,Bin} = file:read_file( FilePath ),
    mod_mysql:insert(Bin).


