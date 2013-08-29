%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_hook_register
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_hook_register).

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

test_gift(RoleID)->
    RoleInfo = #p_role{base=#p_role_base{role_id=RoleID}},
    hook_register_ok:hook([RoleInfo]).