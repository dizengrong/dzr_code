%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 
%%%     地图hook接口
%%%     处理每个地图进程的init,terminate和循环
%%% @end
%%% Created :  8 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(hook_map).

-include("mgeem.hrl").


%% API
-export([
         loop/1,
         loop_ms/2,
		 init/3,
         init/2,
         terminate/1
        ]).


%%地图每秒钟的循环
loop(MapID) when ?IS_SOLO_FB(MapID) ->
    Now = common_tool:now(),
    FuncList = [
                %%自动回血、怒气
                fun() -> mod_map_actor:auto_recover(MapID, Now)  end,
                %%主要副本地图的循环
                fun() -> 
                    case common_config_dyn:find(fb_map, MapID) of
                        [#r_fb_map{module=ModuleName, is_loop=true}]->
                            ModuleName:loop(MapID, Now);
                        _ ->
                            ignore
                    end 
                end,
                fun() -> mod_map_drop:loop() end,
                fun() -> mod_mirror_fb:loop(Now, MapID) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
    ok;

loop(MapID) ->
    Now = common_tool:now(),
    FuncList = [
                fun() -> mod_map_ybc:loop() end,
                %%自动回血、怒气
                fun() -> mod_map_actor:auto_recover(MapID, Now)  end,
                fun() -> mod_trading:loop(MapID) end,
                %%fun() -> mod_map_bonfire:loop_check() end,
                fun() -> mod_shop:loop() end,
                fun() -> mod_map_team:loop() end,
                fun() -> mod_dynamic_monster:hook_map_loop(Now) end,
				fun() -> mod_activity_boss:hook_map_loop(MapID,Now) end,
                fun() -> mod_stall_list:hook_map_loop(MapID, Now) end,
                %%主要副本地图的循环
                fun() -> case common_config_dyn:find(fb_map,MapID) of
                             [#r_fb_map{module=ModuleName,is_loop=true}]->
                                 ModuleName:loop(MapID, Now) ;
                             _ ->
                                 ignore
                         end end,
                fun() -> mod_cang_bao_tu_fb:loop(MapID,Now) end,
                fun() -> mod_map_drop:loop() end,
                fun() -> mod_activity:loop(MapID, Now) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
    ok.

loop_ms(MapID, NowMsec) when ?IS_SOLO_FB(MapID) ->
    ?TRY_CATCH( mod_map_monster:loop_ms(NowMsec),Err01),
	?TRY_CATCH( mod_mirror_ai:loop_ms(NowMsec, MapID), Err02),
	?TRY_CATCH( mgeem_map:flush_all_role_msg_queue(),Err03),
	ok;

loop_ms(_MapID, NowMsec) ->
    ?TRY_CATCH( mod_map_monster:loop_ms(NowMsec),Err02),
    ?TRY_CATCH( mod_server_npc:loop_ms(NowMsec),Err03),
    ?TRY_CATCH( mod_map_ybc:loop_ms(NowMsec),Err04),
    ?TRY_CATCH( mgeem_map:flush_all_role_msg_queue(),Err05),
    ok.

init(MapID, MapName, Monsters) when ?IS_SOLO_FB(MapID) ->
    ?TRY_CATCH(mod_map_monster:init_monster_id_list(), Err2),
    ?TRY_CATCH(mod_server_npc:init_server_npc_id_list(), Err3),
    ?TRY_CATCH(mod_server_npc:init_server_npc(MapID, MapName), Err4),
	?TRY_CATCH(mod_map_monster:init_map_monster(MapName, MapID, Monsters), Err5),
	FuncList = [
				fun()-> mod_role2:init(MapID) end,
                fun()-> mod_dynamic_monster:hook_map_init(MapID) end
			   ],
	[?HOOK_CATCH(F) || F <- FuncList],
	ok.
    

init(MapID, MapName) ->
    ?TRY_CATCH(mod_map_monster:init_monster_id_list(),Err2),
    ?TRY_CATCH(mod_server_npc:init_server_npc_id_list(),Err3),
    ?TRY_CATCH(mod_server_npc:init_server_npc(MapID, MapName),Err4),
    
    %%宗族副本不自动出生怪物
    IsSceneWarFbBornMonster = mod_scene_war_fb:is_scene_war_fb_born_monster(MapID),
    if MapID =:= 10300 
           orelse MapID =:= 10400
           orelse MapID =:= 10501
           orelse MapID =:= 10600 
           orelse IsSceneWarFbBornMonster =:= false ->
           ignore;
       true ->
           ?TRY_CATCH(mod_map_monster:init_map_monster(MapName, MapID),Err5)
    end,
    ?TRY_CATCH(mod_map_ybc:init(MapID, MapName),Err8),
    ?TRY_CATCH(mod_stall:init(MapID,MapName),Err10),
    ?TRY_CATCH(mod_trading:init(MapID, MapName),Err12),
    %% 通知mgeew_system_buff地图起来了
    case global:whereis_name(mgeew_system_buff) of
        undefined ->
            ignore;
        PID ->
            PID ! {map_init, MapName}
    end,
    FuncList = [
                %%fun()-> mod_map_bonfire:init(MapID) end,
                fun()-> mod_country_treasure:init(MapID, MapName)end,
                fun()-> mod_system_notice:init() end,
                fun()-> mod_scene_war_fb:init(MapID, MapName) end,
                fun()-> mod_stall_list:init(MapID) end,
                fun()-> mod_dynamic_monster:hook_map_init(MapID) end,
				fun()-> mod_activity_boss:init(MapID) end,
                fun()-> mod_role2:init(MapID) end,
                fun()-> mod_nationbattle_fb:init(MapID, MapName) end,
                fun()-> mod_arenabattle_fb:init(MapID, MapName) end,
                fun()-> mod_pve_fb:init(MapID, MapName) end,
                fun()-> mod_cang_bao_tu_fb:init(MapID) end,
                fun()-> mod_exchange_active_deal:init(MapID, MapName) end,
                fun()-> mod_bigpve_fb:init(MapID, MapName) end,
                fun()-> mod_tower_fb:init(MapID, MapName) end,
                fun()-> mod_spring:init(MapID, MapName) end,
                fun()-> mod_mine_fb:init(MapID, MapName) end,
                fun()-> mod_warofking:init(MapID, MapName) end,
                fun()-> mod_warofmonster:init(MapID, MapName) end,
                fun()-> (cfg_map_module:module(MapID)):handle({init, MapID, MapName}) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
	ok.

terminate(MapID) when ?IS_SOLO_FB(MapID) ->
    ok;

terminate(MapID) ->
    FuncList = [
                fun() -> mod_map_ybc:terminate() end,
                fun() -> mod_spring:do_terminate(MapID) end,
                fun() -> mod_tower_fb:do_terminate() end,
                fun() -> mod_stall:do_terminate(MapID) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
    ok.
