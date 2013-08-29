-module(pp_scene).

-include ("common.hrl").

-export([handle/3]).


%% when a player first enter the scene
handle(11001, PlayerId, SceneId) ->
	scene:player_enter(PlayerId, SceneId),
	?INFO(scene,"also need to update 11405 for monster lists");
	%% scene:update_monsters(PlayerId);

%% notice that the parameter PosList is list of {X, Y}
handle(11000, PlayerId, PosList) ->
	scene:player_move(PlayerId, PosList);

handle(11003, PlayerId, Pos) ->
	?INFO(pp_scene, "Pos = ~w", [Pos]),
	scene:move_check(PlayerId, Pos);

%% 处理户端请求根地图跳转
handle(11004, PlayerId, NewSceneId) ->
	scene:scene_jump(PlayerId, NewSceneId);

handle(11005, PlayerId, SceneId) ->
	scene:go_back(PlayerId, SceneId);	

%% 客户端请求重定位
handle(11008, PlayerId, _) ->
	{SceneId, _, _} = scene:get_position(PlayerId),
	{DefaultX, DefaultY} = data_scene:get_default_xy(SceneId),
	scene:reset_location(PlayerId, DefaultX, DefaultY);

handle(11012, PlayerId, _Code) ->
	scene:get_access_scene(PlayerId);

%% 小飞鞋..
handle(11016, PlayerId, {SceneId, X, Y}) ->	
	scene:fly(PlayerId, SceneId, X, Y);

%% 打野外怪
handle(11404, Player_id, {Scene_id,Monster_id}) ->
	mod_monster:fight_monster(Player_id, Scene_id,Monster_id);


handle(Cmd, _PlayerId, _Code) ->
	?ERR(scene, "scene cmd:~w not implemented", [Cmd]).





