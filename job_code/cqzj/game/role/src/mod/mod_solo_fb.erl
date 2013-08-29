%% Author: xierongfeng
%% Created: 2012-12-16
%% Description: 单人副本
-module(mod_solo_fb).

%%
%% Include files
%%
-include("mgeer.hrl").

%%
%% Exported Functions
%%
-export([init/2, init/3, clear/0, put_fb_rec/2, del_fb_rec/1]).

%%
%% API Functions
%%
init(MAPID, MapProcessName) ->
	init(MAPID, MapProcessName, #r_solo_fb{}).
init(MAPID, MapProcessName, false) ->
	init(MAPID, MapProcessName, #r_solo_fb{});								   
init(MAPID, MapProcessName, SoloFb) ->
	Mcm = mcm:get_mod(MAPID),
	GridWidth = Mcm:grid_width(),
	GridHeight = Mcm:grid_height(),
	OffsetX = Mcm:offset_x(),
	OffsetY = Mcm:offset_y(),
	%%初始化九宫格的slice
	init_slice_lists(MapProcessName, GridWidth, GridHeight),
	State = #map_state{
        mapid       = MAPID, 
        map_type    = ?MAP_TYPE_COPY, 
        offsetx     = OffsetX, 
        offsety     = OffsetY,  
        map_name    = MapProcessName, 
        grid_width  = GridWidth, 
        grid_height = GridHeight
    },
	put(map_state_key, State),
    mod_map_collect:init(MAPID),
	hook_map:init(MAPID, MapProcessName, SoloFb#r_solo_fb.monsters),
	mod_map_actor:init_in_map_role(),
	catch db:dirty_write(?DB_MAP_ONLINE, #r_map_online{
        map_name = MapProcessName, 
        map_id   = MAPID, 
        online   = 1, 
        node     = node()
    }),
	put(is_map_process, true),
	{ok, State}.

put_fb_rec(_RoleID, _Rec) ->
	ignore.

del_fb_rec(_RoleID) ->
	case mgeem_map:get_state() of
        #map_state{mapid = MapID} when ?IS_SOLO_FB(MapID) ->
			Monsters = lists:foldl(fun(MonsterID, Acc) -> 
                #p_map_monster{
                    typeid = MonsterType,
                    pos    = #p_pos{tx = TX, ty = TY}
                } = mod_map_actor:get_actor_mapinfo(MonsterID, monster),
                [{MonsterType, TX, TY}|Acc]
			end, [], mod_map_monster:get_monster_id_list()),
			#r_solo_fb{monsters = [{MapID, Monsters}]};
		_ ->
			nil
	end.

clear() ->
	lists:foreach(fun
		({{ref, _, _}, _}) ->
            ignore;
		({{ref_collect, _, _}, _}) ->
			 ignore;
        ({{slices, _, _}, _}) ->
            ignore;
        ({{slice_name, _, _}, _}) ->
            ignore;
        ({{slice_role, _}, _}) ->
            ignore;
        ({{slice_monster, _}, _}) ->
            ignore;
        ({{slice_server_npc, _}, _}) ->
            ignore;
        ({{slice_pet, _}, _}) ->
            ignore;
		({{attack_count, _}, _}) ->
			ignore;
		({server_npc_id_list, _}) ->
			ignore;
		({{change_map_quit, _}, _}) ->
			ignore;
		({{last_attack_time, _, _}, _}) ->
			ignore;
		({monster_id_list, _}) ->
			ignore;
		({{monster_state, _}, _}) ->
			ignore;
		({{monster_enemy, _}, _}) ->
			ignore;
		({{map_monsterinfo, _}, _}) ->
			ignore;
		({{dropthing, _}, _}) ->
			ignore;
		({{dropthing_protect_queue, _}, _}) ->
			ignore;
		({{collect, _}, _}) ->
			ignore;
		({collect_point, _}) ->
			ignore;
		({{collection, _}, _}) ->
			ignore;
		({role_drop_goods_id, _}) ->
			ignore;
		({{role_monster_drop, _}, _}) ->
			ignore;
		({max_monster_id, _}) ->
			ignore;
		({mission_collect_roles, _}) ->
			ignore;
	   	({map_pet_info, _}) ->
			 ignore;
        ({Key, Value}) ->
            put(Key, Value)
    end, erase()).

%%
%% Local Functions
%%
init_slice_lists(MapPName, GridWidth,GridHeight) ->
    X = common_tool:ceil(GridWidth/?MAP_SLICE_WIDTH) - 1,
    Y = common_tool:ceil(GridHeight/?MAP_SLICE_HEIGHT) - 1,
    lists:foreach(fun
        (SX) ->
            lists:foreach(fun
                (SY) ->
                    SliceName = concat_slice_name(MapPName, SX, SY),
                    erlang:put({slice_name, SX, SY}, SliceName),
                    erlang:put({slice_role, SliceName}, []),
                    erlang:put({slice_monster, SliceName}, []),
                    erlang:put({slice_server_npc, SliceName}, []),
                    erlang:put({slice_pet, SliceName}, [])
            end, lists:seq(0, Y))
      end, lists:seq(0, X)),
    lists:foreach(fun
        (SX) ->
            lists:foreach(fun
                (SY) ->
                    Slices9 = get_9slices(X, Y, SX, SY),
                    put({slices, SX, SY}, Slices9)
            end, lists:seq(0, Y))
      end, lists:seq(0, X)).

%%拼凑一个slice的名字
concat_slice_name(MAPID, SX, SY) ->
    lists:concat(["pg22_map_slice_", MAPID, "_", SX, "_", SY]).

get_9slices(SliceWidthMaxValue, SliceHeightMaxValue, SX, SY) ->
    if 
        SX > 0 ->
            BeginX = SX - 1;
        true ->
            BeginX = 0
    end,
    if
        SY > 0 ->
            BeginY = SY - 1;
        true ->
            BeginY = 0
    end,
    if 
        SX >= SliceWidthMaxValue ->
            EndX = SliceWidthMaxValue;
        true ->
            EndX = SX + 1
    end,
    if 
        SY >= SliceHeightMaxValue ->
            EndY = SliceHeightMaxValue;
        true ->
            EndY = SY + 1
    end,
    get_9_slice_by_tile_2(BeginX, BeginY, EndX, EndY).
get_9_slice_by_tile_2(BeginX, BeginY, EndX, EndY) ->
    lists:foldl(fun
        (TempSX, Acc) ->
            lists:foldl
                (fun(TempSY, AccSub) ->
                    Temp = get_slice_name(TempSX, TempSY),
                    [Temp|AccSub]
                end, Acc, lists:seq(BeginY, EndY))
      end, [], lists:seq(BeginX, EndX)).

get_slice_name(SX, SY) -> 
    get({slice_name, SX, SY}).
