%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     玩家属性点更改的hook
%%% @end
%%% Created : 2011-6-18
%%%-------------------------------------------------------------------
-module(hook_attr_point_assign).
-export([
         hook/1
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").


%%%===================================================================
%%% API
%%%===================================================================
hook({_RoleID, _RoleBase, _AddValue})->
    ok.
