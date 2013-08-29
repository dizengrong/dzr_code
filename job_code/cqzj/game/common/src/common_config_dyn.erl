%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     common_config 的动态加载实现版本，之后可以取缔common_config
%%%     目前只支持key-value或者record（首字段为key）的配置文件
%%% @end
%%% Created : 2010-12-2
%%%-------------------------------------------------------------------
-module(common_config_dyn).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").

%% API
-export([init_basic/0]).
-export([reload_all/0,reload/1]).
-export([list_item/0,list_equip/0,list_stone/0,list_driver/0]).
-export([find_item/1,find_equip/1,find_stone/1]).
-export([find_mm_map/1,find_common/1,find_manage_mm_map/1]).
-export([init/1,list/1]).

-export([find/2]).
-export([list_by_module/1]).
-export([gen_all_beam/0]).

-export([load_gen_src/2,load_gen_src/3]).

-define(DEFINE_CONFIG_MODULE(Name,FilePath,FileType),{ Name, get_config_dir() ++ FilePath, FileType }).

-define(DEFINE_SETTING_MODULE(Name,FilePath,FileType),{ Name,get_setting_dir() ++ FilePath, FileType }).

%% 支持4种文件类型：record_consult,key_value_consult,key_value_list,record_list,

-define(BASIC_CONFIG_FILE_LIST,[    %%配置模块名称,路径,类型
									?DEFINE_SETTING_MODULE(common,"common.config",key_value_consult),
									?DEFINE_CONFIG_MODULE(mm_map,"mm_map.config",key_value_list),
									?DEFINE_CONFIG_MODULE(module_method_close,  "module_method_close.config",key_value_consult),
									?DEFINE_CONFIG_MODULE(stat, "stat.config", key_value_consult)
							   ]).

-define(ROOT_CONFIG_FILE_LIST,[    %%配置模块名称,路径,类型
								   ?DEFINE_CONFIG_MODULE(item_special,  "map/item_special.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(item_change_skin,  "map/item_change_skin.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(item,  "map/item.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(stone,  "map/stone.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(equip,  "map/equip.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(born,"born.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(buff_type,"buff_type.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(buffs,"buffs.config",record_list),
								   ?DEFINE_CONFIG_MODULE(driver,"driver.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(ybc_person_cost,"ybc_person_cost.config", record_consult),
								   %%?DEFINE_CONFIG_MODULE(level_channel,"level_channel.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(map_info,"map_info.config",key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(effects,"effects.config",record_list),
								   ?DEFINE_CONFIG_MODULE(level,"level.config",record_list),
								   ?DEFINE_CONFIG_MODULE(activate_code,"activate_code.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(logs,"logs.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(etc, "etc.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(activity_define,  "activity_define.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(collect_activity,  "activity/collect_activity.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(open_activity,  "activity/open_activity.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(merge,"merge.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(activity_accgold,  "activity/activity_accgold.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(activity_schedule,  "map/activity_schedule.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(boss_group,  "map/boss_group.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(extend_bag,  "map/extend_bag.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(gift,  "map/gift.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(bighpmp,  "map/big_hp_mp.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(level_hp_mp,  "map/level_hp_mp.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(rankreward,  "map/rankreward.config",key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(broadcast,  "map/broadcast.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(compose,  "map/compose.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(equip_bind,  "map/equip_bind.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(equip_build,  "map/equip_build.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(equip_change,  "map/equip_change.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(equip_whole_attr,  "map/equip_whole_attr.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(equip_shine,  "map/equip_shine.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(treasbox,  "map/treasbox.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(treasbox_3day,  "map/treasbox_3day.config",key_value_consult),
								   %%?DEFINE_CONFIG_MODULE(equip_link,  "map/equip_link.config",record_consult),
								   %%?DEFINE_CONFIG_MODULE(letter,  "map/letter.config",key_value_list),
								   %%?DEFINE_CONFIG_MODULE(punch,  "map/punch.config",record_consult),
								   %%?DEFINE_CONFIG_MODULE(receiver_letter,  "map/receiver_letter.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(refining,  "map/refining.config",key_value_list),
								   %%?DEFINE_CONFIG_MODULE(send_letter,  "map/send_letter.config",record_consult),
								   
								   ?DEFINE_CONFIG_MODULE(educate,  "map/educate.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(rank_info,  "map/ranking/rank_info.config",key_value_consult),
								   
								   %%?DEFINE_CONFIG_MODULE(broadcast_admin,  "map/broadcast_admin_data.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(broadcast_loop,  "map/broadcast_loop.config",record_consult),
								   
								   ?DEFINE_CONFIG_MODULE(item_cd,  "map/item_cd.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(team,  "map/team.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(team_recruitment,  "map/team_recruitment.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family,  "map/family.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(family_boss,  "map/family_boss.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_level_reduce,  "map/family_level_reduce.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(family_depot,  "map/family_depot.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(family_buff,  "map/family_buff.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_base_info,  "map/family_base_info.config",key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(family_plant,  "map/family_plant.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(plant_farm,  "map/plant_farm.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(plant_skill,  "map/plant_skill.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(friend,  "map/friend.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(mission_etc,  "mission/mission_etc.config",key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(monster_etc, "monster/monster_etc.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(boss_ai,  "monster/boss_ai.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(monster_drop_broadcast,  "monster/monster_drop_broadcast.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(server_npc,  "monster/server_npc.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(server_npc_born,  "monster/server_npc_born.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(waroffaction_guarder,  "monster/waroffaction_guarder.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(waroffaction_etc, "monster/waroffaction_etc.config", key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(pet_grow,  "pet/pet_grow.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(pet_etc,  "pet/pet_etc.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(pet_training,"pet/pet_training.config",key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(shop_price_time,  "map/shop_price_time.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(shop_test,  "map/shop_test.config",record_consult),
								   
								   ?DEFINE_CONFIG_MODULE(skill,"map/skill.config",record_list),
								   ?DEFINE_CONFIG_MODULE(skill_level,"map/skill_level.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(jingjie_skill,"map/jingjie_skill.config",key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(active_deal,  "map/active_deal.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(money,  "map/money.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(map_level_limit,  "map/map_level_limit.config",key_value_list),
								   ?DEFINE_CONFIG_MODULE(fb_map,  "map/fb_map.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(fb_npc,  "map/fb_npc.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(trading,  "map/trading.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(role_on_zazen,  "map/role_on_zazen.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(country_treasure,  "map/country_treasure.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(educate_fb,  "map/educate_fb.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(scene_war_fb,  "map/scene_war_fb.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(pve_fb,  "map/pve_fb.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(item_gift,  "map/item_gift.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(dynamic_monster, "monster/dynamic_monster.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(prestige_exchange,  "map/prestige_exchange.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(role_grow,  "map/role_grow.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(big_jingjie,  "map/big_jingjie.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(egg_shop,  "map/egg_shop.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(guide,  "map/guide.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(crown_arena,  "map/crown_arena.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(crown_arena_cull,  "map/crown_arena_cull.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(monster_dead_drop,  "map/monster_dead_drop.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(monster_change,  "monster/monster_change.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(cang_bao_tu_fb,  "map/cang_bao_tu_fb.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(bag_shop, "map/bag_shop.config",record_consult),
								   
								   ?DEFINE_CONFIG_MODULE(fb_manual_monster,  "monster/fb_manual_monster.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(item_effect, "map/item_effect.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(activity_mission, "map/activity_mission.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(drop_goods_notify,  "map/drop_goods_notify.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(monster_born_and_dead_broadcast, "map/monster_born_and_dead_broadcast.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(flowers, "map/flowers.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(level_gift, "map/level_gift.config",key_value_consult),
								   %%?DEFINE_CONFIG_MODULE(time_gift, "map/time_gift.config",key_value_consult),
								   %%?DEFINE_CONFIG_MODULE(spy, "map/spy.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(jail, "map/jail.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(office, "map/office.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(activity_gift_by_letter, "activity/activity_gift_by_letter.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(present, "map/present.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(present_redbag, "map/present_redbag.config",key_value_consult),
								   % ?DEFINE_CONFIG_MODULE(activity_reward, "map/activity_reward.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(activity_notice, "map/activity_notice.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_skill, "map/family_skill.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_skill_limit, "map/family_skill_limit.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(server_npc_born_num, "monster/server_npc_born_num.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(mine_fb, "map/mine_fb.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(mission_fb, "map/mission_fb.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(arena, "map/arena.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(nationbattle, "map/nationbattle.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(arenabattle, "map/arenabattle.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(warofking, "map/warofking.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(warofmonster, "map/warofmonster.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(guide_tip, "map/guide_tip.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(vip, "map/vip.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(mission_auto, "mission/mission_auto.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(mission_collect_points, "mission/mission_collect_points.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(bonfire, "map/bonfire.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(drunk_buff_value, "map/drunk_buff_value.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(shuaqi_fb, "map/shuaqi_fb.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(rank_activity,"activity/rank_activity.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(personybc, "map/personybc.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_party, "map/family_party.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_welfare, "map/family_welfare.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_ybc, "map/family_ybc.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(monster_drop_times, "map/monster_drop_times.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(server_pos, "map/server_pos.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(monster_addition, "monster/monster_addition.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(monster_born_condition, "monster/monster_born_condition.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(stall_list,"map/stall_list.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(spend_activity, "activity/spend_activity.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(ranking_activity, "activity/ranking_activity.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(other_activity, "activity/other_activity.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(lianqi, "map/lianqi.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(caishen, "map/caishen.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(bigpve, "map/bigpve.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(shenqi, "map/shenqi.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(horse_racing, "map/horse_racing.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(extend_bag_row, "map/extend_bag_row.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(mirror_fb,"map/mirror_fb.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(chlg_match, "map/chlg_match.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(stall, "map/stall.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(nimbus,  "map/nimbus.config",key_value_consult),
								   ?DEFINE_CONFIG_MODULE(equip_renewal, "map/equip_renewal.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(tili, "map/tili.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(random_mission_level, "map/random_mission_level.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(random_mission_task, "map/random_mission_task.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(random_mission_grid, "map/random_mission_grid.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(item_use_limit, "map/item_use_limit.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(family_shop,  "map/family_shop.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(access_guide,  "map/access_guide.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(daily_mission,  "map/daily_mission.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(guard_fb,  "map/guard_fb.config", key_value_consult),
								   
								   ?DEFINE_CONFIG_MODULE(family_ybc_money, "family_ybc_money.config",record_consult),
								   ?DEFINE_CONFIG_MODULE(activity_pay_first, "activity/activity_pay_first.config", record_consult),
								   ?DEFINE_CONFIG_MODULE(faction_war, "map/faction_war.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(receiver_server, "receiver/receiver_server.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(swl_mission,  "map/swl_mission.config", key_value_consult),
								   ?DEFINE_CONFIG_MODULE(daily_pay_reward, "map/daily_pay_reward.config", key_value_consult),
                                   ?DEFINE_CONFIG_MODULE(spring,  "map/spring.config", key_value_consult),
                                   ?DEFINE_CONFIG_MODULE(tower_fb, "map/tower_fb.config", key_value_consult)
							  ]).


-define(FOREACH(Fun,List),lists:foreach(fun(E)-> Fun(E)end, List)).

%% ====================================================================
%% API Functions
%% ====================================================================
init_basic()->
    ?FOREACH(catch_do_load_config,?BASIC_CONFIG_FILE_LIST),
    ok.


%%@result   ok | {error,not_found}
init(ConfigName) when is_atom(ConfigName)->
    reload(ConfigName).

reload_all()->
    AllFileList = lists:concat( [?ROOT_CONFIG_FILE_LIST,?BASIC_CONFIG_FILE_LIST]),
    ?FOREACH(catch_do_load_config,AllFileList),
    ok.

%%@spec reload(ConfigName::atom())
%%@result   ok | {error,not_found}
reload(ConfigName) when is_atom(ConfigName)->
    AllFileList = lists:concat( [?ROOT_CONFIG_FILE_LIST,?BASIC_CONFIG_FILE_LIST]),
    case lists:keyfind(ConfigName, 1, AllFileList) of
        false->
            {error,not_found};
        ConfRec->
            reload2(ConfRec),
            ok
    end.
reload2({AtomName,FilePath,FileType}) ->
    reload2({AtomName,FilePath,FileType,set});
     
reload2({AtomName,FilePath,_,_}=ConfRec) ->
    try
        {ok, Code} = do_load_config(ConfRec),
		ConfigModuleName = codegen_name(AtomName),
        file:write_file(lists:concat([get_server_dir(),"ebin/config/", ConfigModuleName, ".beam"]), Code, [write, binary])
    catch
        Err:Reason->
            ?ERROR_MSG("Reason=~w,AtomName=~w,FilePath=~p",[Reason,AtomName,FilePath]),
            throw({Err,Reason})
    end.
%%@doc 获取指定配置的配置项列表
list_item()->
    list_by_module( item_config_codegen).
list_equip()->
    list_by_module( equip_config_codegen).
list_stone()->
    list_by_module( stone_config_codegen).
list_driver()->
    list_by_module( driver_config_codegen).

%% 常用的几个配置读取接口
%%@result   [] | [Result]
find_item(Key)->
    find_by_module(item_config_codegen,Key).
find_equip(Key)->
    find_by_module(equip_config_codegen,Key).
find_stone(Key)->
    find_by_module(stone_config_codegen,Key).
find_mm_map(Key)->
    find_by_module(mm_map_config_codegen,Key).
find_common(Key)->
    find_by_module(common_config_codegen,Key).
find_manage_mm_map(Key) ->
    find_by_module(manmage_mm_map_config_codegen,Key).
%%@spec list/1
%%@doc 为了尽量少改动，接口符合ets:lookup方法的返回值规范，
%%@result   [] | [Result]
list(ConfigName)->
    case do_list(ConfigName) of
        undefined-> [];
        not_implement -> [];
        Val -> Val
    end.

%%@spec find/2
%%@doc 为了尽量少改动，接口符合ets:lookup方法的返回值规范，
%%@result   [] | [Result]
find(ConfigName,Key)->
    case do_find(ConfigName,Key) of
        undefined-> [];
        not_implement -> [];
        Val -> [Val]
    end.

%%@spec list_by_module/1
%%@result   [] | [Result]
list_by_module(ModuleName) when is_atom(ModuleName)->
    case ModuleName:list() of
        undefined-> [];
        not_implement -> [];
        Val -> Val
    end.

%%@spec find_by_module/2
%%@doc  为了尽量少改动，接口符合ets:lookup方法的返回值规范，
%%      如果你的configName是属于频繁调用的，可以在此指定 codegen的模块名
%%@result   [] | [Result]
find_by_module(ModuleName,Key) when is_atom(ModuleName)->
    case ModuleName:find_by_key(Key) of
        undefined-> [];
        not_implement -> [];
        Val -> [Val]
    end.


%%@spec do_list/1
do_list(ConfigName) ->
    ModuleName = common_tool:list_to_atom( codegen_name(ConfigName) ),
    ModuleName:list().

%%@spec do_find/2
do_find(ConfigName,Key) ->
    ModuleName = common_tool:list_to_atom( codegen_name(ConfigName) ),
    ModuleName:find_by_key(Key).

%%@spec load_gen_src/2
%%@doc ConfigName配置名，类型为atom(),KeyValues类型为[{key,Value}|...]
load_gen_src(ConfigName,KeyValues) when is_atom(ConfigName) ->
    load_gen_src(ConfigName,KeyValues,[]).

%%@spec load_gen_src/3
%%@doc ConfigName配置名，类型为atom(),KeyValues类型为[{key,Value}|...]
load_gen_src(ConfigName,KeyValues,ValList) when is_atom(ConfigName) ->
    do_load_gen_src(ConfigName,set,KeyValues,ValList).

%% ====================================================================
%% Local Functions
%% ====================================================================

codegen_name(Name)->
    lists:concat([Name,"_config_codegen"]).

get_server_dir() ->
    {ok, [[ServerDir]]} = init:get_argument(server_dir),
    ServerDir.

get_config_dir() ->
    {ok, [[ServerDir]]} = init:get_argument(server_dir),
    ServerDir ++ "config/".

get_setting_dir() ->
    {ok, [[ServerDir]]} = init:get_argument(server_dir),
    ServerDir ++ "setting/".


catch_do_load_config({AtomName,FilePath,FileType}) ->
        catch_do_load_config({AtomName,FilePath,FileType,set});
     
catch_do_load_config({AtomName,FilePath,_,_}=ConfRec) ->
             try
                 do_load_config(ConfRec)
             catch
                 Err:Reason->
                     ?ERROR_MSG("Reason=~w,AtomName=~w,FilePath=~p",[Reason,AtomName,FilePath]),
                     throw({Err,Reason})
             end.

gen_all_beam() ->
    BasicConfigFileList = lists:keydelete(common, 1, ?BASIC_CONFIG_FILE_LIST),
    AllFileList = lists:concat( [?ROOT_CONFIG_FILE_LIST,
                                 BasicConfigFileList]),
    lists:foreach(
      fun({AtomName, FilePath, Type}) ->
              io:format("~p~n", [AtomName]),
              gen_all_beam2(AtomName, FilePath, Type, set);
         ({AtomName, FilePath, Type, KeyType}) ->
              io:format("~p~n", [AtomName]),
              gen_all_beam2(AtomName, FilePath, Type, KeyType)
      end, AllFileList),
    ok.

gen_all_beam2(AtomName, FilePath, Type, KeyType) ->
    case AtomName =:= common of
        true ->
            ignore;
        false ->
            try
				ConfigModuleName = codegen_name(AtomName),
                gen_src_file(ConfigModuleName, FilePath, Type, KeyType)
            catch
               Err:Reason->
                   erlang:throw({Err,FilePath,Reason})
            end
    end.

gen_src_file(ConfigModuleName, FilePath, Type, KeyType) ->
    if 
        Type =:= record_consult ->
            {ok,RecList} = file:consult(FilePath),
            KeyValues = [ begin
                              Key = element(2,Rec), {Key,Rec}
                          end || Rec<- RecList ],
            ValList = RecList;
        Type =:= record_list ->
            {ok,[RecList]} = file:consult(FilePath),
            KeyValues = [ begin
                              Key = element(2,Rec), {Key,Rec}
                          end || Rec<- RecList ],
            ValList = RecList;
        Type =:= key_value_consult ->
            {ok,RecList} = file:consult(FilePath),
            KeyValues = RecList,
            ValList = RecList;
        true ->
            {ok,[RecList]} = file:consult(FilePath),
            KeyValues = RecList,
            ValList = RecList
    end,
    Src = common_config_code:gen_src(ConfigModuleName,KeyType,KeyValues,ValList),
    file:write_file(lists:concat(["../config/src/", ConfigModuleName, ".erl"]), Src, [write, binary, {encoding, utf8}]),
    ok.

do_load_config({AtomName,FilePath,record_consult, Type}) ->
    {ok,RecList} = file:consult(FilePath),
    KeyValues = [ begin
                      Key = element(2,Rec), {Key,Rec}
                  end || Rec<- RecList ],
    ValList = RecList,
    do_load_gen_src(AtomName,Type,KeyValues,ValList);

do_load_config({AtomName,FilePath,record_list, Type}) ->
    {ok,[RecList]} = file:consult(FilePath),
    KeyValues = [ begin
                      Key = element(2,Rec), {Key,Rec}
                  end || Rec<- RecList ],
    ValList = RecList,
    do_load_gen_src(AtomName,Type,KeyValues,ValList);

do_load_config({AtomName,FilePath,key_value_consult, Type})->
    {ok,RecList} = file:consult(FilePath),
    KeyValues = RecList,
    ValList = RecList,
    do_load_gen_src(AtomName,Type,KeyValues,ValList);

do_load_config({AtomName,FilePath,key_value_list, Type})->
    {ok,[RecList]} = file:consult(FilePath),
    KeyValues = RecList,
    ValList = RecList,
    do_load_gen_src(AtomName,Type,KeyValues,ValList).

%%@doc 生成源代码，执行编译并load
do_load_gen_src(AtomName,Type,KeyValues,ValList) when is_atom(AtomName)->
	ConfigModuleName = codegen_name(AtomName),
    try
        Src = common_config_code:gen_src(ConfigModuleName,Type,KeyValues,ValList),
        {Mod, Code} = dynamic_compile:from_string( Src ),
        code:load_binary(Mod, ConfigModuleName ++ ".erl", Code),
        {ok, Code}
    catch
        Type:Reason -> 
            Trace = erlang:get_stacktrace(), string:substr(erlang:get_stacktrace(), 1,200),
            ?CRITICAL_MSG("Error compiling ~p: Type=~w,Reason=~w,Trace=~w,~n", [ConfigModuleName, Type, Reason,Trace ])
    end.
