-module (pp_fengdi).

-include("common.hrl").

-export([handle/3]).

%% =========================== 种植 ===========================
handle(22000, PlayerId, PlayerId) ->
	mod_fengdi:client_get_lands(PlayerId);

handle(22000, PlayerId, OtherPlayerId) ->
	mod_fengdi:client_get_lands(PlayerId, OtherPlayerId);

handle(22001, PlayerId, LandId) ->
	mod_fengdi:client_open_land(PlayerId, LandId);

handle(22002, PlayerId, {LandId, SeedType, RoleId}) ->
	mod_fengdi:client_planting(PlayerId, LandId, SeedType, RoleId);

handle(22003, PlayerId, SeedType) ->
	mod_fengdi:client_refresh_seed_quality(PlayerId, SeedType);

handle(22004, PlayerId, LandId) ->
	mod_fengdi:client_get_seed_result(PlayerId, LandId);

handle(22005, PlayerId, LandId) ->
	mod_fengdi:client_clean_planting_cd(PlayerId, LandId);

handle(22006, PlayerId, _) ->
	mod_fengdi:client_get_friends_water_info(PlayerId);

handle(22007, PlayerId, {LandId, FriendId}) ->
	mod_fengdi:watering(PlayerId, FriendId, LandId);

handle(22008, PlayerId, _) ->
    mod_fengdi:client_get_seed_info(PlayerId);    		
%% ============================= end =============================

%% ============================= 奴隶 =============================
handle(22100, PlayerId, PlayerId) ->
	mod_fengdi:client_get_slaves(PlayerId);

handle(22100, _PlayerId, _OtherPlayerId) ->
	%% TO-DO:添加获取其他玩家的奴隶处理，如果需要的话
	?ERR(fengdi, "Not implemented!"),
	ok;

handle(22101, PlayerId, Pos) ->
	mod_fengdi:client_open_cage(PlayerId, Pos);

handle(22102, PlayerId, _) ->
	mod_fengdi:client_refresh_non_slaves(PlayerId);

handle(22103, PlayerId, NonSlaveId) ->
	mod_fengdi:client_battle_non_slave(PlayerId, NonSlaveId);

handle(22104, PlayerId, FriendId) ->
	mod_fengdi:client_battle_for_friend(PlayerId, FriendId);

handle(22105, PlayerId, _) ->
	mod_fengdi:client_battle_for_freedom(PlayerId);

handle(22106, PlayerId, Pos) ->
	mod_fengdi:client_free_slave(PlayerId, Pos);

handle(22107, PlayerId, WorkType) ->
	mod_fengdi:client_slave_work(PlayerId, WorkType);

handle(22108, PlayerId, _) ->
	mod_fengdi:client_clean_work_cd(PlayerId).	


