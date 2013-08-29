%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mission 内部的事务
%%% @end
%%% Created : 2011-4-10
%%%-------------------------------------------------------------------
-module(common_mission).

%% API
-export([
         on_transaction_begin/0,
         on_transaction_rollback/0,
         on_transaction_commit/0,
         is_in_transaction/0
        ]).

-include("common.hrl").




is_in_transaction()->
    %%单进程，同一时间只有一次事务
    erlang:get(?MAP_MISSION_TRANSACTION_FLAG) =:= true.

%%%===================================================================
%%% Internal functions
%%%===================================================================
on_transaction_begin() ->
    erlang:put(?MISSION_ROLE_IDLIST_IN_TRANSACTION, []),
    case erlang:get(?MAP_MISSION_TRANSACTION_FLAG) of
        undefined ->
            erlang:put(?MAP_MISSION_TRANSACTION_FLAG, true),
            ok;
        _ ->
            %% 禁止嵌套事务
            erlang:throw({nesting_transaction, ?MODULE})
    end,
    ok.


on_transaction_rollback() ->
    lists:foreach(
      fun(RoleID) ->
              erlang:erase( ?MISSION_DATA_DICT_KEY_COPY(RoleID) )
      end, erlang:get(?MISSION_ROLE_IDLIST_IN_TRANSACTION)),
    
    erlang:erase(?MAP_MISSION_TRANSACTION_FLAG),
    erlang:put(?MISSION_ROLE_IDLIST_IN_TRANSACTION, []).


on_transaction_commit() ->
    lists:foreach(
      fun(RoleID) ->
              case erlang:get(?MISSION_DATA_DICT_KEY_COPY(RoleID) ) of
                  undefined ->
                      ignore;
                  MissionData ->
                      erlang:put(?MISSION_DATA_DICT_KEY(RoleID), MissionData ),
                      erlang:erase( ?MISSION_DATA_DICT_KEY_COPY(RoleID) )
              end
      end, erlang:get(?MISSION_ROLE_IDLIST_IN_TRANSACTION)),
    
    erlang:erase(?MAP_MISSION_TRANSACTION_FLAG),
    erlang:put(?MISSION_ROLE_IDLIST_IN_TRANSACTION, []).


 

    

