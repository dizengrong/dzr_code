%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_mod_activity
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_mod_person_ybc).

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

test_speed(YbcID,Sp)->
    R2 = #m_ybc_speed_toc{ybc_id=YbcID,move_speed=Sp},
    RoleID = 3,
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?YBC, ?YBC_SPEED, R2).



