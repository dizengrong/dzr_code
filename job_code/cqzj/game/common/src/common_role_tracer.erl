%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(common_role_tracer).

%%
%% Include files
%%
 
-include("mm_define.hrl").

%%
%% Exported Functions
%%
-export([
         online/2,
         offline/2,
         trace/4
        ]).

%%
%% API Functions
%%

trace(RoleID,Module,Method,DataRecord)->
    case cfg_trace:is_trace(RoleID) of
        true ->
            trace_2(RoleID, Module,Method,DataRecord);
        _ -> ignore
    end.

trace_2(_RoleID,?SYSTEM,_,_Rec)->
    ignore;
trace_2(_RoleID,?MONSTER,_,_Rec)->
    ignore;
trace_2(_RoleID,?MOVE,_Method,_Rec)->
    ignore;

trace_2(RoleID,Mod,Method,Rec)->
    Format = "[~w]-[~w] RoleID=~w,Rec=~w\n",
    Args = [Mod,Method,RoleID,Rec],
    LoggerMsg = {role_tracer, Format, Args },
    catch gen_event:notify(error_logger, LoggerMsg).

online(RoleID,Detail)->
    do_online(online,RoleID,Detail).

offline(RoleID,Detail)->
    do_online(offline,RoleID,Detail).


do_online(Type,RoleID,Detail)->
    case cfg_trace:is_trace(RoleID) of
        true ->
            do_online_2(Type,RoleID,Detail);
        _ -> ignore
    end.
    
do_online_2(online,RoleID,IP)->
    Format = "online RoleID=~w,IP=~w\n",
    Args = [RoleID,IP],
    LoggerMsg = {role_tracer, Format, Args },
    catch gen_event:notify(error_logger, LoggerMsg);
do_online_2(offline,RoleID,Reason)->
    Format = "offline RoleID=~w,Reason=~w\n",
    Args = [RoleID,Reason],
    LoggerMsg = {role_tracer, Format, Args },
    catch gen_event:notify(error_logger, LoggerMsg).
    


    