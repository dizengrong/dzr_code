%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     
%%% @end
%%%-------------------------------------------------------------------
-module(hook_pet).

-include("mgeem.hrl").

%% API
-export([
         hook_pet_levelup/3,
		 hook_pet_periodup/2
        ]).

%%%===================================================================
%%% API
%%%===================================================================

%%宠物升级
hook_pet_levelup(RoleID,PetID,_NewLevel) ->
    mod_map_pet:hook_pet_levelup(RoleID, PetID),
    ok.

%%宠物形态升级
hook_pet_periodup(_RoleID,_NewPetInfo) ->
    ok.

