%%%-------------------------------------------------------------------
%%% @author Liangliang <Liangliang@gmail.com>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  5 Jun 2010 by Liangliang <Liangliang@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_map_loader).

-include("mgeem.hrl").

%%%===================================================================
%%% Macro
%%%===================================================================


%%%===================================================================
%%% API
%%%===================================================================
-export([
         auto_create_maps/0,
         create_map/1,
         create_family_maps/0
        ]).

%%%===================================================================
%%% API
%%%===================================================================
%%自动载入地图
auto_create_maps() ->
    lists:foreach(fun(Mcm) ->
	  case Mcm:map_type() =:= 0 orelse Mcm:map_id() =:= 10700  of
	      false ->
	          ignore;
	      _ ->
	          case Mcm:map_id() =:= 0 of
	              true ->
	                  ignore;
	              false ->
	                  mgeem_router:create_map_if_not_exist(Mcm:map_id())
	          end
	  end
  	end, mcm:get_all()).

create_map(MapID) ->
    MName = common_map:get_common_map_name(MapID),
    mgeem_router:do_start_map(MapID, MName).

create_family_maps() ->
	FamilyList = db:dirty_match_object(?DB_FAMILY, #p_family_info{enable_map=true, _='_'}),
	lists:foreach(
		fun(#p_family_info{family_id=FamilyID, hour=H, minute=M, level=Level}) ->
                        case FamilyID > 0 andalso Level > 0 of
                            true ->
                                mod_map_copy:create_family_map_copy(FamilyID, common_tool:today(H,M,0));
                            false ->
                                ignore
                        end
		end, FamilyList).
