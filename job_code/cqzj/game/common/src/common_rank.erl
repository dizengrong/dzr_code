%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     排行榜的一些公共方法
%%% @end
%%% Created : 23 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(common_rank).

-export([
         update_element/2
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").
 




%% ====================================================================
%% API functions
%% ====================================================================
update_element(Module,Info) when is_atom(Module)->
    ?TRY_CATCH( global:send(mgeew_ranking, {ranking_element_update, Module, Info}) ),
    ok.


%%%===================================================================
%%% Internal functions
%%%===================================================================
