%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 20 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_transaction).

%% API
-export([
         transaction/1,
         commit/0,
         rollback/0,
         abort/1,
         t/1
        ]).

-include("common.hrl").
-include("common_server.hrl").

t(F) ->
    common_transaction:transaction(F).

transaction(F) ->
    try
        common_bag2:on_transaction_begin(),
        common_role:on_transaction_begin(),
        common_mission:on_transaction_begin(),
        common_consume_logger:on_transaction_begin(),
        common_prestige_logger:on_transaction_begin(),
        common_yueli_logger:on_transaction_begin(),
		common_pet:on_transaction_begin(),
		
        Result = F(),
        commit(),
        {atomic, Result}
    catch ErrorType:Error ->
              rollback(),
              case ErrorType of
                  throw ->
                      case Error of
                          {error, ErrorInfo} ->
                              {aborted, ErrorInfo};
                          _ ->
                              {aborted, Error}
                      end;
                  exit ->
                      case Error of
                          {aborted, _} ->
                              Error;
                          _ ->
                              {aborted, Error}
                      end;
                  _ ->
                      {aborted, {ErrorType, Error, erlang:get_stacktrace()}}
              end
    end.


commit() ->
    common_bag2:on_transaction_commit(),
    common_role:on_transaction_commit(),
    common_mission:on_transaction_commit(),
    common_consume_logger:on_transaction_commit(),
    common_prestige_logger:on_transaction_commit(),
    common_yueli_logger:on_transaction_commit(),
    common_pet:on_transaction_commit(),
    ok.


rollback() ->
    common_bag2:on_transaction_rollback(),
    common_role:on_transaction_rollback(),
    common_mission:on_transaction_rollback(),
    common_consume_logger:on_transaction_rollback(),
    common_prestige_logger:on_transaction_rollback(),
    common_yueli_logger:on_transaction_rollback(),
    common_pet:on_transaction_rollback(),
    ok.

abort(Error) ->
    erlang:throw(Error).

    

