%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_common_misc.erl
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_common_misc).

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

t_bag(RoleID)->
    common_misc:get_dirty_bag_goods(RoleID).

t_week()->
    Week = lists:flatten( io_lib:format("_~2..0B", [common_time:week_of_year( {2009,2,1} )]) ) ,
    Y = 2010,
    TabName = lists:concat([t_log_item_,Y,Week]),
    common_tool:to_atom( TabName ).
