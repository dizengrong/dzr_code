%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 19 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_rank_service).

%% API
-export([get/3]).

-include("mgeeweb.hrl").

get("all_rank",Req,_) ->
	?DBG(all_rank),
	?TRY_CATCH(global:send(mgeew_ranking,update_all_rank)),
	mgeeweb_tool:return_json_ok(Req);

get(RankName, Req, _) ->
	?DBG(RankName),
	?TRY_CATCH(global:send(mgeew_ranking,{rank,common_tool:to_atom(RankName)})),
	mgeeweb_tool:return_json_ok(Req).

