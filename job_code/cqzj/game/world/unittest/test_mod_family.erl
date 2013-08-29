%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_mgeew_pay_server
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_mod_family).

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
test_callmember(RoleID,FamilyID)->
    DataIn = #m_family_callmember_tos{message="hello"},
    Info = {0,?FAMILY,?FAMILY_CALLMEMBER,DataIn,RoleID,pid,1},
    router_to_family_process(FamilyID, Info).

router_to_family_process(FamilyID, Info) ->
    Process = common_misc:make_family_process_name(FamilyID),
    case global:whereis_name(Process) of
        undefined ->
            error;
        _ ->
            global:send(Process, Info)
    end.


