%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 27 Aug 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeem_clear).

%% API
-export([stop/0]).

-include("mgeem.hrl").

stop() ->
    %% 地图是simple_one_for_one，在init:stop情况下可能无法执行完terminate
    A = lists:foldl(
          fun(NameT, AL) ->
                  Name = common_tool:to_list(NameT),
                  case string:str(Name, "mgee_map") =:= 1 orelse
                      string:str(Name, "map_") =:= 1 orelse
                      string:str(Name, "mgee_mission_fb_map_") =:= 1 
                  of 
                      true ->
                          [Name | AL];
                      false ->
                          AL
                  end
          end,[], global:registered_names()),
    lists:foreach(
      fun(MapName) ->
              case global:whereis_name(MapName) of
                  undefined ->
                      ignore;
                  PID ->
                      erlang:monitor(process, PID),
                      erlang:exit(PID, normal),
                      receive
                          {'DOWN', _Ref, process, PID, _Info} ->
                              ok
                      end
              end
      end, A),       
    ok.
