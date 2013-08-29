%%%-----------------------------------
%%% @Module  : mod_player_sup
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.04.15
%%% @Description: the supervision tree
%%%-----------------------------------
-module(mod_player_sup).
-behaviour(supervisor).

-include("common.hrl").


-export([start_link/0, init/1, stop/1]).

start_link() ->
	supervisor:start_link(?MODULE, []).
	
init([]) -> 
	{
	 ok, 
	 {{one_for_one, 3, 10}, []}
	}. 

stop(ReaderPid) ->
	ReaderPid ! {stop_reader}.
	% erlang:exit(ReaderPid, normal).
