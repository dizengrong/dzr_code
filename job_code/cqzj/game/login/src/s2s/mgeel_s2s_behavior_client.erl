%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     将s2s的数据直接发给 behavior_server（behavior_server本身是没有缓存的），最后再转发给receiver
%%% @end
%%% Created : 2010-11-15
%%%-------------------------------------------------------------------
-module(mgeel_s2s_behavior_client).


%% API
-export([]).
-export([send/3]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeel.hrl").


%% ====================================================================
%% API Functions
%% ====================================================================

%%@doc 将数据发送给behavior_server
send( ModuleTuple, MethodTuple, BinaryList )->
    
    S2S_List = [ {ModuleTuple, MethodTuple, DataBin} || DataBin<-BinaryList ],
    case global:whereis_name(behavior_server) of
        undefined ->
            {error,behavior_server_undefined};
        Pid ->
            ?DEBUG("S2S_List=~w",[S2S_List]),
            erlang:send(Pid, {s2s_list, S2S_List })
    end.