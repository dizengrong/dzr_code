-module(mod_chat_gm).
-include("mgeec.hrl").
-include("office.hrl").
-include("role_misc.hrl").

-define(SPLIT, $=).
-export([cmd/2, do_cmd/2, get_cmd/5, set_role_attr_opt/2, set_role_base_opt/2]).


cmd(_RoleID, []) ->
    "";
cmd(RoleID, CmdMsg) ->
    get_cmd(common_config:is_debug(), RoleID, CmdMsg, false, {"", [], ""}).


get_cmd(false, _RoleID, CmdMsg, _GotFunName, _FunTuple) ->
    {not_gm, CmdMsg};

get_cmd(true, RoleID, CmdMsg, GotFunName, FunTuple) ->
    case string:substr(CmdMsg, 1, 3) of
        "t4_" ->
            Msg = do_get_cmd(true, RoleID, CmdMsg, GotFunName, FunTuple),
            {gm, lists:flatten(lists:concat([Msg, "\n<FONT COLOR='#FF0000'>旧:", CmdMsg, "</FONT>"]))};
        _ ->
            {not_gm, CmdMsg}
    end.

do_get_cmd(true, _RoleID, [], false, _) ->
    lists:concat(["GM命令有误:\ngm命令统一使用t4_开头,使用", lists:flatten([?SPLIT]), "分隔不同参数\n"]);

do_get_cmd(true, RoleID, [], true, {FunStr, Args, TmpArgStr}) ->

   try 
        Fun=erlang:list_to_atom(FunStr),
        TrueArgs = 
            lists:foldl(
              fun(Arg, Result) ->
                      [erlang:list_to_integer(Arg)|Result]
              end, [], [TmpArgStr|Args]),
        apply(?MODULE, do_cmd, [Fun, {[RoleID|TrueArgs]}])
            
   catch
       _:Reason ->
           lists:flatten(lists:concat(["GM命令有误", io_lib:format("~w", [Reason])]))
   end;

do_get_cmd(true, RoleID, [Char|Msg], GotFunName, {FunStr, Args, TmpArgStr}) ->

    case Char of
        ?SPLIT when GotFunName =:= false ->

            TrueFun = lists:flatten([TmpArgStr]),
            TrueFA = {TrueFun, [], ""},
            NewGotFunName=true,

            do_get_cmd(true, RoleID, Msg, NewGotFunName, TrueFA);

        ?SPLIT when TmpArgStr /= "" ->

            TrueFA = {FunStr, [TmpArgStr|Args], ""},
            NewGotFunName=GotFunName,

            do_get_cmd(true, RoleID, Msg, NewGotFunName, TrueFA);

        _ ->

            TrueFA = {FunStr, Args, lists:flatten([TmpArgStr, Char])},
            NewGotFunName=GotFunName,

            do_get_cmd(true, RoleID, Msg, NewGotFunName, TrueFA)
    end.


parse_gm_level(RoleID, GmLevelDataList) ->
    parse_gm_level(RoleID, GmLevelDataList, []).

parse_gm_level(_RoleID, [], Acc) -> Acc;
parse_gm_level(RoleID, [{level, Lv} | Rest], Acc) ->
    Fun = fun() -> mgeer_role:absend(RoleID, {mod_gm, {set_level, RoleID, Lv}}) end,
    parse_gm_level(RoleID, Rest, [Fun | Acc]);

parse_gm_level(RoleID, [{silver, Num} | Rest], Acc) ->
    Fun = fun() -> common_role_money:set(RoleID, [{silver_bind, Num}]) end,
    parse_gm_level(RoleID, Rest, [Fun | Acc]);
parse_gm_level(RoleID, [{gold_any, Num} | Rest], Acc) ->
    Fun = fun() -> common_role_money:set(RoleID, [{gold_bind, Num}]) end,
    parse_gm_level(RoleID, Rest, [Fun | Acc]);
parse_gm_level(RoleID, [{gold_unbind, Num} | Rest], Acc) ->
    Fun = fun() -> common_role_money:set(RoleID, [{gold, Num}]) end,
    parse_gm_level(RoleID, Rest, [Fun | Acc]);
parse_gm_level(RoleID, [{items, Items} | Rest], Acc) ->
    Fun = fun() -> mod_bag:add_items(RoleID, Items, "") end,
    parse_gm_level(RoleID, Rest, [Fun | Acc]);
parse_gm_level(RoleID, [{equip, Equips} | Rest], Acc) ->
    Fun = fun(EquipId) -> 
        {true, [Goods]} = mod_bag:add_items(RoleID, [{EquipId, 1, 3, true}], ""),
        Msg = #m_equip_load_tos{equipid = Goods#p_goods.id},
        GatewayPid = global:whereis_name(common_misc:get_role_line_process_name(RoleID)),
        GatewayPid ! {debug, 0, 8, 802, Msg},
        timer:sleep(500)
    end,
    Fun2 = fun() -> [Fun(E) || E <- Equips] end,
    parse_gm_level(RoleID, Rest, [Fun2 | Acc]);
parse_gm_level(RoleID, [{pet, PetItemIdList} | Rest], Acc) ->
    Fun = fun(PetItemId) -> 
        {true, [Goods]} = mod_bag:add_items(RoleID, [{PetItemId, 1, 1, true}], ""),
        Msg = #m_item_use_tos{itemid = Goods#p_goods.id,usenum = 1, effect_id = 0},
        GatewayPid = global:whereis_name(common_misc:get_role_line_process_name(RoleID)),
        GatewayPid ! {debug, 0, 11, 1102, Msg},
        timer:sleep(500)
    end,
    Fun2 = fun() -> [Fun(PetItemId) || PetItemId <- PetItemIdList] end,
    parse_gm_level(RoleID, Rest, [Fun2 | Acc]);
parse_gm_level(RoleID, [{mission, MissionId} | Rest], Acc) ->
    Fun = fun() -> send_to_role_map_gm(RoleID, {gm_set_mission, RoleID, MissionId}) end,
    parse_gm_level(RoleID, Rest, [Fun | Acc]).

%%如果需要直接在后台的debug模式下运行GM命令，则可以执行：
%%例如mod_chat_gm:do_cmd(m2_baseattr, {[1, 30]}).


do_cmd(t4_add_qinmidu, {[RoleID, PetSeqId, AddQinmidu]}) ->
    PetBagRec = common_debug:get_role_process_data(RoleID, {role_pet_bag_info, RoleID}),
    PetIdNameRecs = lists:keysort(#p_pet_id_name.pet_id, PetBagRec#p_role_pet_bag.pets),
    PetIdNameRec = lists:nth(PetSeqId, PetIdNameRecs),
    PetId = PetIdNameRec#p_pet_id_name.pet_id,
    common_debug:call_function(RoleID, mod_pet_task, add_pet_qinmidu, 
                                [RoleID, PetId, AddQinmidu]),
    "GM:增加宠物亲密度";

do_cmd(t4_add_nuqi, {[RoleID, _]}) ->
    common_debug:call_function(RoleID, mod_map_role, add_max_nuqi, [RoleID]),
    "GM:增加角色一个怒气火把";

do_cmd(t4_open_hidden, {[RoleID, BarrierID]}) ->
    Fun = fun() -> mod_hidden_examine_fb:gm_open_hidden_barrier(RoleID, BarrierID) end,
    mgeer_role:call(RoleID, Fun);

do_cmd(t4_clear_hidden, {[RoleID, _]}) ->
    common_debug:call_function(RoleID, mod_hidden_examine_fb, gm_clear_hidden_barrier, 
                                [RoleID]),
    "GM:清除隐藏关卡数据";

do_cmd(t4_set_exp_back, {[RoleID, _]}) ->
    Fun = fun() -> mod_daily_activity:gm_set_exp_back(RoleID) end,
    mgeer_role:call(RoleID, Fun);

do_cmd(t4_set_pet_attr, {[RoleID, Index, Type, Data]}) ->
    Fun = fun() -> mod_map_pet:gm_set_pet_attr(RoleID, Index, Type, Data) end,
    mgeer_role:call(RoleID, Fun);



do_cmd(t4_gm_level, {[RoleID, Id]}) ->
    try
        case cfg_gm:gm_level(Id) of
            [] -> cfg_gm:all_level();
            GmLevelDataList ->
                AllFuns = parse_gm_level(RoleID, GmLevelDataList),
                Fun = fun(F) ->
                    mgeer_role:run(RoleID, F),
                    timer:sleep(500)
                end,
                [Fun(F2) || F2 <- AllFuns],
                mgeer_role:run(RoleID, fun() -> mod_role_attr:reload_role_base(mod_role_attr:recalc(RoleID)) end),
                ok
        end
    catch
        Type:Error ->
            ?ERROR_MSG("Type:~w, error: ~w, stack: ~w", [Type, Error, erlang:get_stacktrace()])
    end;


%%@doc zesen专用
do_cmd(t4_zesen, {[RoleID, ID]}) ->
%% 	%%gm默认一个职业
    case ID of
        1->
            common_role_money:set(RoleID, [{silver_bind, 800000000}]),
            common_role_money:set(RoleID, [{gold, 800000000}]),
            Num = 100000,
            set_role_base_opt(RoleID, [{base_str, Num}, {base_int, Num}, {base_con, Num}, {base_dex, Num}, {base_men, Num}]),
            send_to_role_map_gm(RoleID, {set_level, RoleID, 50}),
            %%赠送的道具
            AwdItemList = [{?TYPE_ITEM,10100001,100},
                           {?TYPE_ITEM,12000001,50},
                           {?TYPE_EQUIP,30112199,1}],
            send_to_role_map_gm(RoleID, {add_item, RoleID, AwdItemList}),
            "GM:还我靓靓拳";
        2->
            send_to_role_map_gm(RoleID, {family_enable_map, RoleID}),
            send_to_role_map_gm(RoleID, {family_add_money, RoleID, 11111111}),
            send_to_role_map_gm(RoleID, {family_add_active_points, RoleID, 11111}),
            do_cmd(t4_family_con, {[RoleID, 11111]}), 
            "GM:还宗族靓靓拳";
        3->
            common_role_money:set(RoleID, [{silver_bind, 800000000}]),
            common_role_money:set(RoleID, [{gold, 800000000}]),
            %%赠送的道具
            AwdItemList = [{?TYPE_ITEM,10100001,100},
                           {?TYPE_ITEM,12000001,50},
                           {?TYPE_EQUIP,30112199,1}],
            send_to_role_map_gm(RoleID, {add_item, RoleID, AwdItemList}),
            "GM:还神马靓靓拳";
        4->
            Num = 10000000,
            set_role_base_opt(RoleID, [{base_str, Num}, {base_int, Num}, {base_con, Num}, {base_dex, Num}, {base_men, Num}]),
            "GM:还属性靓靓拳";
        5->
            common_role_money:set(RoleID, [{silver_bind, 800000000}]),
            common_role_money:set(RoleID, [{gold, 800000000}]),
            set_role_base_opt(RoleID, [{base_str, 1000}, {base_int, 100000}, {base_con, 100000}, {base_dex, 100000}, {base_men, 100000}]),
            send_to_role_map_gm(RoleID, {set_level, RoleID, 50}),
            %%赠送的道具
            AwdItemList = [{?TYPE_ITEM,10100001,100},
                           {?TYPE_ITEM,12000001,50},
                           {?TYPE_EQUIP,30112199,1}],
            send_to_role_map_gm(RoleID, {add_item, RoleID, AwdItemList}),
            "GM:还我靓靓拳";
        _->
            "2B了吧，这个命令已经不能用了吧~"
    end;

do_cmd(t4_reduce_mp, {[RoleID,Num]}) ->
	mgeer_role:absend(RoleID, {mod_nimbus, {reduce_mp,RoleID,Num}}),
	"GM:减少灵气命令";

do_cmd(t4_mp, {[RoleID,Num]}) ->
	mgeer_role:absend(RoleID, {mod_nimbus, {t4_mp,RoleID,Num}}),
	"GM:设置灵气命令";

%%@doc 立即更新排行榜
do_cmd(t4_rank, {[_RoleID,_Num]}) ->
    global:send(mgeew_ranking,update_all_rank),
    "GM:立即更新排行榜";

%%@doc 立即更新排行榜
do_cmd(t4_rankreward, {[_RoleID,_Num]}) ->
    global:send(mgeew_ranking,{snapshot,ranking_fighting_power_yesterday}),
    "GM:立即更新排行奖励";

do_cmd(t4_qrhl_time, {[RoleID, Time]}) ->
    mgeer_role:absend(RoleID, {mod_qrhl, {set_remain_time, RoleID, Time}}),
    "GM:设置七日好礼剩余时间";

do_cmd(t4_addexp, {[RoleID, Exp]}) ->
    mgeer_role:absend(RoleID, {mod_map_role, {add_exp, RoleID, Exp}}),
    "GM:加经验命令";

do_cmd(t4_add_buff, {[RoleID, BuffID]}) ->
	send_to_role_map_gm(RoleID, {t4_add_buff,RoleID,BuffID}),
    "GM:加Buff命令";
do_cmd(t4_super_buff, {[RoleID, AttrId, Value]}) ->
    send_to_role_map_gm(RoleID, {t4_super_buff,RoleID,AttrId,Value}),
    "GM:加超级Buff命令:t4_super_buff=属性(1:生命, 2:攻击力, 3:物理防御, 4:法术防御)=值";
 
 do_cmd(t4_remove_super_buff, {[RoleID, _]}) ->
    send_to_role_map_gm(RoleID, {t4_remove_super_buff,RoleID}),
    "GM:清除超级Buff命令:t4_remove_super_buff=1";

do_cmd(t4_an_score, {[RoleID, Val]}) ->
    common_misc:send_to_rolemap(RoleID, {mod,mod_arena, {gm_set_arena_score, RoleID, Val}}),
    "GM:加擂台积分";
do_cmd(t4_an_partake, {[RoleID, Val]}) ->
    common_misc:send_to_rolemap(RoleID, {mod,mod_arena, {gm_set_arena_partake_times, RoleID, Val}}),
    "GM:加擂台参与次数";
do_cmd(t4_an_conwin, {[RoleID, Val]}) ->
    common_misc:send_to_rolemap(RoleID, {mod,mod_arena, {gm_set_arena_conwin_times, RoleID, Val}}),
    "GM:加擂台连胜次数";
do_cmd(t4_daily_counter, {[RoleID, Val1,Val2]}) ->
    mgeer_role:absend(RoleID, {mod,mod_daily_counter, {gm_set_daily_counter_times, RoleID, Val1,Val2}}),
    "GM:设置活动次数";
do_cmd(t4_daily_counter_conf, {[RoleID, Val1]}) ->
    common_misc:absend(RoleID, {mod,mod_daily_counter, {gm_reload_daily_counter_conf, RoleID, Val1}}),
    "GM:重新加载次数统计的配置";
do_cmd(t4_bc, {[_RoleID, FileID]}) ->
    BroadCastDataDir = lists:concat(["config/broadcast_", FileID,  ".config"]),
    {ok, List} = file:consult(BroadCastDataDir),
    DataRecord = List,
    Unique = ?DEFAULT_UNIQUE,
    Module =  ?BROADCAST,
    Method = ?BROADCAST_ADMIN,
    global:send("mod_broadcast_server", {Unique, Module, Method, DataRecord}),

    "GM:系统广播";

do_cmd(t4_attr, {[_RoleID, _Num]}) ->
    "2B了吧，这个命令已经不能用了吧~";

do_cmd(t4_attr, {[RoleID, Num, Int]}) when is_integer(Int) ->
    set_role_base_opt(RoleID, [{base_str, Num}, {base_int, Num}, {base_con, Num}, {base_dex, Num}, {base_men, Num}]),
    "GM:加攻基本属性";

do_cmd(t4_qiang, {[RoleID, NoDefence,Miss,DoubleAttack,PoisoningResit,DizzyResit]}) when 
        is_integer(NoDefence),is_integer(Miss),is_integer(DoubleAttack),
        is_integer(PoisoningResit),is_integer(DizzyResit)->
    set_role_base_opt(RoleID, [{no_defence, NoDefence}, {miss, Miss}, {double_attack, DoubleAttack},
                               {poisoning_resist,PoisoningResit},{dizzy_resist,DizzyResit}]),
    "GM:设置强哥基本属性";

do_cmd(T4_TESE, {[RoleID, Value]}) when T4_TESE == t4_tese_no_defence;
										T4_TESE == t4_tese_miss;
										T4_TESE == t4_tese_hit_rate;
										T4_TESE == t4_tese_double_attack;
										T4_TESE == t4_tese_block;
										T4_TESE == t4_tese_wreck;
										T4_TESE == t4_tese_tough;
										T4_TESE == t4_tese_vigour;
										T4_TESE == t4_tese_week;
										T4_TESE == t4_tese_molder;
										T4_TESE == t4_tese_hunger;
										T4_TESE == t4_tese_bless;
										T4_TESE == t4_tese_crit;
										T4_TESE == t4_tese_counter;
										T4_TESE == t4_tese_combos;
										T4_TESE == t4_tese_bloodline ->
	"t4_tese_"++TypeStr = atom_to_list(T4_TESE),
	set_role_base_opt(RoleID, [{common_tool:to_atom(TypeStr), Value}]),
	"GM:设置职业特色属性";

do_cmd(t4_grow, {[RoleID, Index, Val]}) when is_integer(Index), is_integer(Val) ->
    set_role_grow(RoleID, Index, Val),
    "GM:设置培养属性；1=加物攻2=加物防3=加斗攻4=加斗防";
    
do_cmd(t4_apoint, {[RoleID, Num]}) ->
    set_role_base_opt(RoleID, [{remain_attr_points, Num}]),
    "GM:加基本属性点";
    
do_cmd(t4_spoint, {[RoleID, Num]}) ->
    set_role_attr_opt(RoleID, [{remain_skill_points, Num}]),
    "GM:加技能属性点";

do_cmd(t4_silver, {[RoleID, Num]}) ->
    common_role_money:set(RoleID, [{silver_bind, Num}]),
    "GM:设置铜钱";
  
do_cmd(t4_bsilver, {[RoleID, Num]}) ->
    common_role_money:set(RoleID, [{silver_bind, Num}]),
    "GM:设置铜钱";

do_cmd(t4_gold, {[RoleID, Num]}) ->
    common_role_money:set(RoleID, [{gold, Num}]),
    "GM:设置元宝";
  
do_cmd(t4_bgold, {[RoleID, Num]}) ->
    common_role_money:set(RoleID, [{gold_bind, Num}]),
    "GM:设置礼券";

do_cmd(t4_activate_rage_slot, {[RoleID, _Num]}) ->
    mgeer_role:call(RoleID, fun() -> mod_rage_practice:gm_activate_slot(RoleID) end),
    "GM:激活怒神修炼的槽位";

do_cmd(t4_miss, {[RoleID, MissID]}) ->
    send_to_role_map_gm(RoleID, {gm_set_mission, RoleID, MissID}),
    "GM:设置完成主线任务成功";

do_cmd(t4_family_add_active_points, {[RoleID, Num]}) ->
    send_to_role_map_gm(RoleID, {family_add_active_points, RoleID, Num}),
    "GM:添加宗族繁荣度成功";

do_cmd(t4_family_enable_map, {[RoleID, _]}) ->
    send_to_role_map_gm(RoleID, {family_enable_map, RoleID}),
    "GM:激活宗族地图成功 ";


do_cmd(t4_family_add_money, {[RoleID, Num]}) ->
    send_to_role_map_gm(RoleID, {family_add_money, RoleID, Num}),
    "GM:添加宗族财富成功";

do_cmd(t4_family_uplevel, {[RoleID, _Num]}) ->
    send_to_role_map_gm(RoleID, {family_uplevel,RoleID}),
    "GM:宗族直接升级";

do_cmd(t4_family_maintain, {[RoleID, _]}) ->
    common_family:info_by_roleid(RoleID, gm_family_maintain),
    "GM:执行宗族地图维护成功";

do_cmd(t4_set_energy, {[RoleID, Num]}) ->
    mgeer_role:absend(RoleID, {mod_map_role, {gm_set_energy, {RoleID, Num}}}),    
    "GM:设置精力值成功";

do_cmd(t4_bag, {[RoleID, _Val]}) ->
     send_to_role_map_gm(RoleID, {t4_clear_bag,RoleID}),
    "GM:清空背包/背包物品";

do_cmd(t4_hero_times, {[RoleID, ModelType]})->
    send_to_role_map_gm(RoleID, {t4_hero_times,RoleID,ModelType}),
    "GM:重置境界副本的次数 ";

do_cmd(t4_hero, {[RoleID, Process, ModelType]})->
    send_to_role_map_gm(RoleID, {gm_set_progress,RoleID,Process, ModelType}),
    "GM:开启英雄副本 ";

do_cmd(t4_zhiye, {[RoleID,Category]})->
  	mgeer_role:absend(RoleID, {mod_role2, {gm_set_category, RoleID, Category}}),
    "GM:设置职业";

do_cmd(t4_tili, {[RoleID,Tili]})->
  	mgeer_role:absend(RoleID, {mod_tili, {set_role_tili, RoleID, Tili}}),
    "GM:设置体力";

do_cmd(t4_daily_mission_times, {[RoleID,FinishTimes]})->
  	mgeer_role:absend(RoleID, {mod_daily_mission, {set_finish_times, RoleID, FinishTimes}}),
    "GM:设置日常循环任务完成次数";

do_cmd(t4_examine_times, {[RoleID, _]})->
    send_to_role_map_gm(RoleID, {t4_examine_times,RoleID}),
    "GM:重置检验副本的次数 ";

do_cmd(t4_examine_reset, {[RoleID, _]})->
    Fun = fun() -> mod_examine_fb:gm_reset_reset_times(RoleID) end,
    mgeer_role:call(RoleID, Fun),
    "GM:重置检验副本的重置次数 ";

do_cmd(t4_clear_box_times, {[RoleID, _]}) ->
    send_to_role_map_gm(RoleID, {t4_clear_box_times,RoleID}),
    "GM:清理钱币开箱子次数成功 ";

do_cmd(t4_ntalk, {[RoleID, NpcId, TalkId]}) when is_integer(RoleID)->
    send_to_role_map_gm(RoleID, {t4_ntalk,RoleID,NpcId,TalkId}),
    "GM:NPC说话 ";

do_cmd(t4_open, {[RoleID, Id]})->
    do_cmd(t4_open_ex, {[RoleID, Id, 3]}); %%3秒后开启

do_cmd(t4_open_ex, {[_RoleID, Id, Second]})->
	NewSecond =
		if Second =:= undefined orelse Second < 0 ->
			   0;
		   true ->
			   Second
		end,
	case Id of
        0-> %%符文争夺战
            ?TRY_CATCH( open_country_treasure() ),
            "GM:开启符文争夺战 ";
		1-> %%上古战场
			send_fb_module_msg(10501 ,mod_nationbattle_fb,{gm_open_battle, NewSecond}),
			"GM:开启上古战场成功 ";
		2->%%战神坛
			Pid = global:whereis_name(mgeew_crown_arena_server),
			Pid ! gm_open,
			"GM:开启战神坛成功 ";
		22->%%GM:开启战神坛淘汰赛 ，方便调试和测试
			Pid = global:whereis_name(mgeew_crown_arena_server),
			Pid ! gm_open_activity,
			timer:sleep(60*1000),
			Pid ! gm_init,
			"GM:开启战神坛淘汰赛 ";
		3->%%王座争霸战
			MapIdList = [11111,12111,13111],
			[ send_fb_module_msg(MapId ,mod_warofking,{gm_open_battle, NewSecond}) ||MapId<-MapIdList],
			"GM:开启王座争霸战成功 ";
		4->%%封魔殿
			send_fb_module_msg(10503 ,mod_bigpve_fb,{gm_open_battle, NewSecond}),
			"GM:开启封魔殿成功 ";
		5->%%怪物攻城战
			MapIdList = [11112,12112,13112],
			[ send_fb_module_msg(MapId ,mod_warofmonster,{gm_open_battle, Second}) ||MapId<-MapIdList],
			"GM:开启怪物攻城战成功 ";
        6-> %%温泉
            send_fb_module_msg(10512 ,mod_spring,{gm_open_spring, NewSecond}),
            "GM:开启温泉成功 "
	end;

do_cmd(t4_close, {[_RoleID, Id]})->
    case Id of
        1-> %%上古战场
            send_fb_module_msg(10501 ,mod_nationbattle_fb,{gm_close_battle}),
            "GM:关闭上古战场成功 ";
        2->%%战神坛
			Pid = global:whereis_name(mgeew_crown_arena_server),
			Pid ! gm_close,
%%             send_fb_module_msg(10502 ,mod_arenabattle_fb,{gm_close_battle}),
            "GM:关闭战神坛成功 ";
        3->%%王座争霸战
            MapIdList = [11111,12111,13111],
            [ send_fb_module_msg(MapId ,mod_warofking,{gm_close_battle}) ||MapId<-MapIdList],
            "GM:关闭王座争霸战成功 ";
        4->%%封魔殿
            send_fb_module_msg(10503 ,mod_bigpve_fb,{gm_close_battle}),
            "GM:关闭封魔殿成功 ";
        5->%%怪物攻城战
            MapIdList = [11112,12112,13112],
            [ send_fb_module_msg(MapId ,mod_warofmonster,{gm_close_battle}) ||MapId<-MapIdList],
            "GM:关闭怪物攻城战成功 ";
        6-> %%温泉
            send_fb_module_msg(10512 ,mod_spring,{gm_close_spring}),
            "GM:关闭温泉成功 "
    end;

do_cmd(t4_swl_reset, {[RoleID, _]}) when is_integer(RoleID)->
    mgeer_role:send(RoleID, {mod_swl_mission, {swl_reset,RoleID}}),
    "GM:重置神王令数据 ";

do_cmd(t4_daily_reward, {[RoleID, _]}) ->
    mgeer_role:send(RoleID, {mod_newcomer, {gm_fetch_reward, RoleID}}),
    "GM:设置可领取每天登录礼券奖励";

%%未处理 不知道可不可用
do_cmd(t4_add_hyd, {[RoleID, FriendName, Friendly]}) ->
    FriendID = (catch common_misc:get_roleid(common_tool:to_list(FriendName))),
    global:send(mod_friend_server, {add_friendly, RoleID, FriendID, Friendly, 3}),
    Pattern = #r_friend{roleid=RoleID, friendid=FriendID, _='_'},
    Friendly0 =
        case catch db:dirty_match_object(?DB_FRIEND, Pattern) of
            {'EXIT', _} ->
                {error, system_error};
            [] ->
                {error, not_friend};
            [FriendInfo] ->
                FriendInfo#r_friend.friendly
        end,
    case Friendly0 of
        {error, system_error} ->
            "GM:系统错误";
        {error, not_friend} ->
            "GM:对方不是您的好友";
        _ ->
            io_lib:format("GM:添加友好度成功，当前友好度：~w", [Friendly0+Friendly])
    end;

do_cmd(t4_chefu, {[RoleID, ID]}) ->
    do_cmd(t4_chefu, {[RoleID, ID, 443]});
do_cmd(t4_chefu, {[RoleID, MapID, Line]}) ->
    % [Config] = common_config_dyn:find(driver,ID),
    
    % {_, ID, TX, TY, MapID,_, _RuleList} = Config,

    [{TX, TY}|_] = mcm:born_tiles(MapID),


    common_misc:send_to_rolemap(RoleID, {mod_map_role, {change_map, RoleID, MapID, TX, TY, ?CHANGE_MAP_TYPE_DRIVER}}),
    MapChangeTocDataRecord = 
        #m_map_change_map_toc{succ=true, 
                              mapid=MapID, 
                              tx=TX, 
                              ty=TY},
    
    common_misc:unicast(Line, 
                        RoleID, 
                        ?DEFAULT_UNIQUE, 
                        ?MAP, 
                        ?MAP_CHANGE_MAP, 
                        MapChangeTocDataRecord),

    "GM:车夫地图传送";
    
do_cmd(t4_lv, {[RoleID, Level]}) ->
	%%gm默认一个职业
    [MaxLevel] = common_config_dyn:find(etc, max_level),
    case Level > MaxLevel of
        true ->
            "GM:等级只开放到" ++ erlang:integer_to_list(MaxLevel) ++ "设置无效";
        _ ->
            mgeer_role:absend(RoleID, {mod_gm, {set_level, RoleID, Level}}),
            "GM:设置等级"
    end;


do_cmd(t4_shengwang, {[RoleID, Prestige]}) ->
	mgeer_role:absend(RoleID,{mod_prestige,{admin_set_role_prestige, RoleID, Prestige}}),
	"GM:设置声望";

do_cmd(t4_jungong, {[RoleID, JunGong]}) ->
	mgeer_role:absend(RoleID,{mod_map_role,{gm_set_role_jungong, RoleID, JunGong}}),
	"GM:设置军功";

do_cmd(t4_add_gx, {[RoleID, Add]}) ->
    mgeer_role:absend(RoleID, {mod_map_role, {add_gongxun, RoleID, Add}}),
    "GM:增加战功命令";

do_cmd(t4_add_jifen, {[RoleID, AddJifen]}) ->
	mgeer_role:absend(RoleID,{mod_vip,{add_jifen,RoleID,AddJifen}}),
	"GM:添加积分";

do_cmd(t4_add_yueli, {[RoleID, AddYueLi]}) ->
	mgeer_role:absend(RoleID,{mod,mod_yueli,{gm_set_yueli,RoleID,AddYueLi}}),
	"GM:添加阅历";


%%切换官职
do_cmd(t4_set_office, {[RoleID, OfficeID]}) ->
    {ok, #p_role_base{faction_id=FactionID}} = common_misc:get_dirty_role_base(RoleID),
    case OfficeID of
        0 ->
            NewOfficeID = 0,
            OfficeName = [],
            GMStr = "GM:已成功切换为平民";
        ?OFFICE_ID_MINISTER ->
            NewOfficeID = OfficeID,
            OfficeName = binary_to_list(?OFFICE_NAME_MINISTER),
            GMStr = "GM:已成功切换为"++binary_to_list(?OFFICE_NAME_MINISTER);
        ?OFFICE_ID_GENERAL ->
            NewOfficeID = OfficeID,
            OfficeName = binary_to_list(?OFFICE_NAME_GENERAL),
            GMStr = "GM:已成功切换为"++binary_to_list(?OFFICE_NAME_GENERAL);
        ?OFFICE_ID_JINYIWEI ->
            NewOfficeID = OfficeID,
            OfficeName = binary_to_list(?OFFICE_NAME_JINYIWEI),
            GMStr = "GM:已成功切换为"++binary_to_list(?OFFICE_NAME_JINYIWEI);
        ?OFFICE_ID_KING ->
            NewOfficeID = OfficeID,
            OfficeName = common_tool:to_list(common_title:get_king_name(FactionID)),
            GMStr = "GM:已成功切换为国王";
        _ ->
            NewOfficeID = 0,
            OfficeName = [],
            GMStr = "失败，没有该官职"
    end,

    global:send(mgeew_office, {gm_set_office, RoleID, NewOfficeID,OfficeName}),
    GMStr;

do_cmd(t4_family_con, {[RoleID, Num]}) ->
    %%必须先脏写数据库
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
    #p_role_attr{family_contribute=OldFmlConb} = RoleAttr,
    #p_role_base{family_id=FamilyID} = RoleBase,
  
    db:dirty_write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{family_contribute=Num}),
    
    common_family:info(FamilyID, {add_contribution, RoleID, (Num-OldFmlConb)}),
    
    set_role_attr_opt(RoleID, [{family_contribute, Num}]),
    "GM:设置宗族贡献度";

%% @doc 设置活跃度
do_cmd(t4_set_ap, {[RoleID, Num]}) ->
    set_role_attr_opt(RoleID, [{active_points, Num}]),

    "GM:设置活跃度";

%% @doc 获取玩家活跃度
do_cmd(t4_get_ap, {[RoleID, _Num]}) ->
    case get_role_attr_opt(RoleID) of
        {ok,ActivePt} -> 
            lists:flatten(lists:concat(["GM:查询活跃度:" , ActivePt]));
        {error,_Reason}->
            "GM:查询活跃度出错！"
    end;

%% @doc 学习所有技能
do_cmd(t4_skill, {[RoleID, _Num]}) ->
    mgeer_role:absend(RoleID, {mod_skill, {gm_learn_skill, RoleID}}),
    "GM:成功学习所有技能";

do_cmd(t4_life_skill, {[RoleID, _Num]}) ->
    mgeer_role:absend(RoleID, {mod_skill, {gm_learn_life_star_skill, RoleID}}),
    "GM:成功学习本命星技能到最高级，需要重新登录才生效";
    
do_cmd(t4_god, {[RoleID, Level]}) ->
	do_cmd(t4_lv, {[RoleID, Level]}),
	do_cmd(t4_gold, {[RoleID, 5000000]}),
	do_cmd(t4_bgold, {[RoleID, 5000000]}),
	do_cmd(t4_silver, {[RoleID, 5000000]}),
	do_cmd(t4_bsilver, {[RoleID, 5000000]}),
	do_cmd(t4_attr, {[RoleID, 5000000, 123456]});

%% 设置玩家的五行属性
do_cmd(t4_five_ele_attr, {[RoleID, FiveEleAttr]}) ->
    case lists:member(FiveEleAttr,[1,2,3,4,5]) of
        true ->
            catch mgeer_role:absend(RoleID, {mod_role2, {admin_set_role_five_ele_attr, RoleID, FiveEleAttr}}),
            "GM:设置五行属性成功";
        _ ->
            "GM:五行属性的值为1：金，2：木，3：水，4：火，5：土"
    end; 

do_cmd(t4_set_cj, {[RoleID, Num]}) ->
    {ok, #p_role_pos{map_id=MapID}} = common_misc:get_dirty_role_pos(RoleID),
    case MapID =:= 10300 of
        true ->
            common_misc:send_to_rolemap(RoleID, {mod_family_collect, {gm_set_family_collect_score, RoleID, Num}}),
            "GM:宗族采集积分设置成功";
        _ ->
            "GM:这个命令暂时只能在宗族地图使用呀"
    end;

do_cmd(t4_set_pk, {[RoleID, Num]}) ->
    case mgeer_role:absend(RoleID, {mod_pk, {admin_set_pkpoint, RoleID, Num}}) of
        ignore ->
            "GM: 设置PK值失败，系统错误";
        _ ->
            "GM: 设置PK值成功"
    end;

do_cmd(t4_add_score, {[RoleID, AddScore, ScoreType]}) ->
	Str = case ScoreType of
			  ?SCORE_TYPE_XUNBAO -> "寻宝积分";
			  ?SCORE_TYPE_YUEGUANG -> "月光积分";
			  ?SCORE_TYPE_JINGJI -> "竞技积分";
			  ?SCORE_TYPE_DADAN -> "宠物砸蛋积分";
			  ?SCORE_TYPE_GUARD -> "守护圣殿积分"
		  end,	
	case catch mgeer_role:call(RoleID, fun() -> mod_score:gain_score_notify(RoleID, AddScore, ScoreType,{ScoreType,"GM命令获得" ++ Str}) end) of
		{'EXIT', _} ->
			"GM: 命令使用出错, t4_add_score=增加数量=积分类型(1:寻宝积分,2:月光积分,3:竞技积分,4:宠物砸蛋积分,5:守护圣殿积分)";
		_ ->
			
			"GM: 增加" ++ Str ++ "成功"
	end;

do_cmd(t4_add_item, {[RoleID, ItemTypeId, Num]}) ->
    ?DBG(),
    Type = ItemTypeId div 10000000,
    ?DBG(Type),
    case catch mgeer_role:call(RoleID, fun() -> mod_bag:add_items(RoleID, [{ItemTypeId,Num,Type,true}], "") end) of
        {'EXIT', _} ->
            "GM: 命令使用出错, t4_add_item=物品id=数量";
        _ ->
            ?DBG(),
            [ItemBaseInfo] = common_config_dyn:find(item, ItemTypeId),
            "GM: 增加" ++ binary_to_list(ItemBaseInfo#p_item_base_info.itemname) ++ "成功"
    end;

%% 设置玩家的创建时间
do_cmd(t4_goalday, {[RoleID, Days]}) ->
    mgeer_role:absend(RoleID, {mod_goal, {set_role_days, RoleID, Days}}),
    "修改目标时间";

%% 设置玩家的境界
do_cmd(t4_jingjie, {[RoleID, Jingjie]}) ->
    mgeer_role:absend(RoleID, {mod_role_jingjie, {set_jingjie, RoleID, Jingjie}}),
    "设置境界成功";

%% 设置封神关卡
do_cmd(t4_examine_fb, {[RoleID|FBList]}) ->
	lists:foreach(fun(FB) ->
						  common_misc:send_to_rolemap(RoleID, {mod_examine_fb, {gm_open, RoleID, FB}})
						  end, FBList),
    
    "开启封神关卡成功";

do_cmd(t4_ybc, {[RoleID, Val1,Val2,Val3,Val4]}) when 
        is_integer(Val1),is_integer(Val2),is_integer(Val3),is_integer(Val3) ->
	{ok,#p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
	common_misc:send_to_rolemap_mod(RoleID,mod_ybc_person,{gm_start_faction_ybc,FactionID,Val1,Val2,Val3,Val4}),
    "GM:設置國運開始時間結束時間";

%% 设置玩家的爵位
do_cmd(t4_juewei, {[RoleID, Juewei]}) ->
    mgeer_role:absend(RoleID, {mod_role_jingjie, {set_juewei, RoleID, Juewei}}),
    "设置爵位成功";

%% 完成一个成就    
do_cmd(t4_finish_achieve, {[RoleID, AchieveId]}) ->
    mgeer_role:call(RoleID, fun() -> mod_achievement2:gm_finish(RoleID, AchieveId) end);

%% 重置魔尊洞窟挑战次数
do_cmd(t4_guard_fb, {[RoleID, _]}) ->
    mgeer_role:absend(RoleID, {mod_guard_fb, {gm_reset_enter_times,RoleID}}),
    "重置魔尊洞窟挑战次数成功";

%% 开启全民运镖成功
do_cmd(t4_open_factionche, {[_RoleID, FactionId, Hour, Minute]}) ->
	MapId = 10260,
    MapName = common_misc:get_common_map_name(MapId),
    case global:whereis_name(MapName) of 
        undefind ->
            ignore;
        _ ->
            global:send(MapName,{mod_ybc_person,{admin_start_faction_ybc,FactionId,Hour,Minute}})
    end,
    "开启全民运镖成功";

do_cmd(t4_open_act, {[_RoleID, ActName]}) ->
	ActivityID =
		case ActName of
			1 ->
				?ACTIVITY_SCHEDULE_SILVER;
			2 ->
				?ACTIVITY_SCHEDULE_EXP;
			4 ->
				?ACTIVITY_SCHEDULE_EQUIP;
			5 ->
				?ACTIVITY_SCHEDULE_BOSS;
			6 ->
				?ACTIVITY_SCHEDULE_TRDING;
			_ ->
				0
		end,
    if ActivityID > 0 ->
           global:send(mgeew_activity_schedule, {admin_query,{open_activity, ActivityID}}),
           "开启定时活动成功";
       true ->
           "开启定时活动失败"
    end;

do_cmd(t4_cmonster, {[RoleID, MonsterTypeID, Num]})->
    common_debug:call_function(RoleID, mod_gm, handle, [{call_monster,RoleID,MonsterTypeID,Num}, null]),
    "GM:手工召唤怪物，怪物类型=怪物数量";


do_cmd(t4_mirror, {[RoleID, MirrorID]}) when is_integer(MirrorID), MirrorID > 0 ->
    common_misc:send_to_rolemap_mod(RoleID, mod_mirror_fb, {test, RoleID, MirrorID}),
    "挑战玩家镜像";

do_cmd(t4_signin, {[RoleID, Day]}) ->
    mgeer_role:absend(RoleID, {mod_role_signin, signin, RoleID, Day}),
     "修改每日签到天数成功";

do_cmd(t4_clear_signin, {[RoleID, _]}) ->
    mgeer_role:absend(RoleID, {mod_role_signin, clear_signin, RoleID}),
    "清楚签到数据成功";

do_cmd(t4_clear_timegift, {[RoleID, _]}) ->
    mgeer_role:absend(RoleID, {mod_time_gift, clear_timegift, RoleID}),
    "清楚时间礼包成功";

do_cmd(t4_timegift, {[RoleID, _]}) ->
    mgeer_role:absend(RoleID, {mod_time_gift, time_gift, RoleID}),
    "签到时间礼包成功";

do_cmd(t4_smiss, {[RoleID, _]}) ->
    MissID = 1011701,
    do_cmd(t4_miss, {[RoleID, 1011701]}), 
    do_cmd(t4_chefu, {[RoleID, 10250]}),
    send_to_role_map_gm(RoleID, {gm_set_mission, RoleID, MissID}),
    "GM:设置跳过新手任务";

do_cmd(t4_zhabao, {[_RoleID, 1]}) ->
    common_misc:send_to_map(10513, {apply, mod_bomb_fb, open_by_gm, []}),
    "GM:开启炸宝玩法";

do_cmd(t4_zhabao, {[_RoleID, 0]}) ->
    common_misc:send_to_map(10513, {apply, mod_bomb_fb, close_by_gm, []}),
    "GM:关闭炸宝玩法";

do_cmd(t4_invite, {[RoleID, Type]}) ->
    mod_share_invite:gm_set_invite_info(RoleID, Type),
    "GM:设置可领取邀请界面奖励";

do_cmd(t4_new_open_act, {[_RoleID, _Num]}) ->
    mgeew_open_activity:do_stats(),
	"GM:刷新开服活动榜单记录";

do_cmd(t4_xiaofei_ranking, {[_RoleID, _Num]}) ->
    global:send(mgeew_ranking,{reset}),
	"GM:刷新消費排行榜";

do_cmd(t4_xiaofei_reward, {[_RoleID, _Num]}) ->
    global:send(mgeew_ranking,{reward}),
	"GM:消费排行奖励";

do_cmd(t4_tower_fb, {[RoleID, Index, Val]}) when is_integer(Index) ->
    set_role_tower_fb_info(RoleID, Index, Val),
    "GM:设置玄冥塔副本信息；1=领奖日期，2=挑战日期，3=最高关卡";

do_cmd(t4_recalc, {[RoleID, _]}) ->
    mgeer_role:run(RoleID, fun
        () ->
            mod_role_attr:reload_role_base(mod_role_attr:recalc(RoleID))
    end),
    "GM:重新计算人物属性";

do_cmd(t4_get_fuwen, {[RoleID, TypeId, Level]}) ->
    mgeer_role:run(RoleID, fun
        () ->
            mod_rune_altar:gm_get_rune(RoleID, TypeId, Level)
    end),
    "GM:获取符文";

do_cmd(t4_clear_fuwen, {[RoleID, _]}) ->
    mgeer_role:run(RoleID, fun
        () ->
            mod_rune_altar:gm_clear_bag(RoleID)
    end),
    "GM:清空符文";    

do_cmd(t4_huoling, {[RoleID, _]}) ->
    mod_nuqi_huoling:handle({huoling, RoleID}),
    "GM:设置异火元素成功";

do_cmd(t4_hexie, _) ->
    HelpList = 
        [
         "<B>GM命令帮助菜单:</B>\n",
         lists:concat(["使用:<B><FONT COLOR='#FF0000'>", lists:flatten([?SPLIT]), "</FONT></B>分隔不同参数\n"]),
         help_format("加经验", "t4_addexp", ["经验值"]),
         help_format("创建怪物", "t4_cmonster", ["手工召唤怪物，怪物类型=怪物数量"]),
         help_format("载入系统广播", "t4_bc", ["文件ID"]),
         help_format("修改基础攻击等属性", "t4_attr", ["数值"]),
         help_format("修改基本属性点数", "t4_apoint", ["数值"]),
         help_format("修改技能属性点数", "t4_spoint", ["数值"]),
         help_format("修改钱币", "t4_silver", ["数值"]),
         help_format("修改铜钱", "t4_bsilver", ["数值"]),
         help_format("修改元宝", "t4_gold", ["数值"]),
         help_format("修改礼券", "t4_bgold", ["数值"]),
         help_format("修改宗族繁荣度", "t4_family_add_active_points", ["数值"]),
         help_format("激活宗族地图", "t4_family_enable_map", ["1"]),
         help_format("维护宗族地图", "t4_family_maintain", ["1"]),
         help_format("修改宗族资金", "t4_family_add_money", ["数值"]),
         help_format("宗族直接升级", "t4_family_uplevel", ["1"]),
         help_format("添加好友度，姓名暂时只支持数字", "t4_add_hyd", ["好友姓名", "数值"]),
         help_format("增加师德值","t4_add_morals",["师德值"]),
         help_format("车夫地图传送","t4_chefu",["传送地点ID，与车夫配置相同", "分线ID"]),				
         help_format("设置等级", "t4_lv", ["等级"]),
         help_format("增加功勋", "t4_add_gx", ["数值"]),
         help_format("设置宗族贡献度", "t4_family_con", ["数值"]),
         help_format("设置称号", "t4_set_office", ["数值"]),
         help_format("设置活跃度", "t4_set_ap", ["数值"]),
         help_format("查询活跃度", "t4_get_ap", ["1"]),
         help_format("上帝命令(加很多东西)", "t4_god", ["等级"]),
         help_format("学习所有技能", "t4_skill", ["1"]),
         help_format("学习本命星技能到最高级", "t4_life_skill", ["1"]),
         help_format("设置精力值", "t4_set_energy", ["数值"]),
         help_format("设置完成主线任务成功", "t4_miss", ["数值"]),
         help_format("设置宗族采集积分", "t4_set_cj", ["数值"]),
         help_format("设置PK值", "t4_set_pk", ["数值"]),
         help_format("加擂台积分", "t4_an_score", ["数值"]),
         help_format("加擂台参与次数", "t4_an_partake", ["数值"]),
         help_format("加擂台连胜次数", "t4_an_conwin", ["数值"]),
         help_format("加斗兽场连胜次数", "t4_pet_arena_winnum", ["数值"]),
         help_format("加斗兽场积分", "t4_pet_arena_score", ["数值"]),
         help_format("预订婚宴", "t4_hl_book", ["N分钟后", "婚宴等级"]),
         help_format("增加夫妻情深值", "t4_add_qsz", ["数值"]),
         help_format("设置初出茅庐境界", "t4_jingjie", ["境界代码，如101"]),
         help_format("开户封神关卡", "t4_examine_fb", ["关卡ID，如101"]),
		 help_format("立即更新排行榜", "t4_rank", ["数值"]),
         help_format("立即更新排行奖励", "t4_rankreward", ["数值"]),
         help_format("设置玩家可进行的目标天数", "t4_goalday", ["第几天"]),
         help_format("开启上古战场", "t4_open", ["1"]),
         help_format("开启上古战场", "t4_open_ex=1=10", [" 10指10秒后开放"]),
         help_format("关闭上古战场", "t4_close", ["1"]),
         help_format("开启战神坛", "t4_open", ["2"]),
         help_format("开启战神坛", "t4_open_ex=2=10", [" 10指10秒后开放"]),
         help_format("关闭战神坛", "t4_close", ["2"]),
         help_format("添加buff", "t4_add_buff", [""]),
		 help_format("添加积分值", "t4_add_jifen", ["数值"]),
		 help_format("设置声望值", "t4_shengwang", ["数值"]),
         help_format("重置境界副本的次数", "t4_hero_times=1", [""]),
		 help_format("GM:开启英雄副本 ", "t4_hero", ["数值"]),
		 help_format("设置军功值", "t4_jungong", ["数值"]),
         help_format("重置检验副本的次数", "t4_examine_times=1", [""]),
         help_format("开启全民运镖", "t4_open_factionche=1=11=20", [" 1指势力，即是蚩尤在11点20分开启全民运镖"]),
         help_format("设置培养属性", "t4_grow=1=1000", [" 1指培养类型（1=加物攻2=加物防3=加斗攻4=加斗防），1000是设置的培养值"]),
         help_format("设置强哥基本属性", "t4_qiang=100=200=300=400=500", ["100=破甲(晕抗),200=闪避,300=重击,400=毒抗,500=晕抗(破甲)"]),
         help_format("开启定时活动30分钟", "t4_open_act=活动名", ["1=富甲天下,2=经验多多,3=法宝之王,4=神兵之主,5=毁灭之王"]),
         help_format("创建神器", "t4_shenqi=神器ID=目标神器ID", [""]),
         help_format("设置职业", "t4_zhiye=职业ID", ["1=锤2=刀3=剑4=杖"]),
         help_format("设置体力", "t4_tili=体力", ["数值"]),
		 help_format("设置灵气", "t4_mp=灵气值", ["数值"]),
		 help_format("减少灵气", "t4_reduce_mp=灵气值", ["数值"]),
		 help_format("设置日常循环任务完成次数", "t4_daily_mission_times=完成次数", ["数值"]),
		 help_format("重置魔尊洞窟挑战次数成功", "t4_guard_fb=1", ["数值"]),
         help_format("设置法宝积分", "t4_drop_num=1", ["数值"]),
         help_format("增加宠物亲密度", "t4_add_qinmidu", ["数值"]),
         help_format("增加角色一个怒气火把", "t4_add_nuqi=1", []),
         help_format("开启一个隐藏关卡", "t4_open_hidden", ["隐藏关卡Id"]),
		 help_format("清除隐藏关卡数据", "t4_clear_hidden=1", [""]),
		 help_format("重置神王令数据", "t4_swl_reset", ["重置神王令数据"]),
         help_format("重置法宝数据", "t4_mount_clear", ["重置法宝数据"]),
		 help_format("设置可领取每天登录礼券奖励", "t4_daily_reward", ["设置可领取每天登录礼券奖励"]),
		 help_format("开启炸宝玩法", "t4_zhabao=1", ["开启炸宝玩法"]),
         help_format("关闭炸宝玩法", "t4_zhabao=0", ["关闭炸宝玩法"]),
         help_format("设置可领取邀请界面奖励", "t4_invite", [" 1：指第几行的奖励"]),
         help_format("GM:设置七日好礼剩余时间", "t4_qrhl_time", [" 1：指剩余时间设为1秒"]),
		 help_format("GM:刷新开服活动榜单记录", "t4_new_open_act", ["刷新开服活动榜单记录"]),
         help_format("GM:重新计算人物属性", "t4_recalc=1", ["重新计算人物属性"]),
		 help_format("GM:刷新消費排行榜", "t4_xiaofei_ranking=1", ["刷新消費排行榜"]),
		 help_format("GM:消费排行奖励", "t4_xiaofei_reward=1", ["消费排行奖励"]),
         help_format("设置玄冥塔信息", "t4_tower_fb=1=20121212", ["(1=领奖日期，2=挑战日期，3=最高关卡)"]),
         ""
        ],
    lists:flatten(lists:concat(HelpList));

do_cmd(_, _) ->
    "失败了,没找到该命令".
    

help_format(FunTitle, FunName, Args) ->
    
    SplitStr = lists:flatten([?SPLIT]),
    Result = 
        lists:foldl(
          fun(Item, Result) ->
                  lists:concat([Result, SplitStr, Item])
          end, 
          ["<B>", 
           FunTitle, 
           ":</B>\n<FONT COLOR='#FF0000'>", 
           FunName
          ], 
          Args),

    lists:flatten(lists:concat([Result, "</FONT>\n"])).

%%获取角色ATTR
get_role_attr_opt(RoleID)->
    Info = {get_role_attr_opt, RoleID, self(),reply_get_role_attr_opt},
    mgeer_role:absend(RoleID, {mod_gm, Info}),
    receive_async_msg(reply_get_role_attr_opt).

%%接收其他进程发来的异步信息
receive_async_msg(ReplyTag)->
    receive 
        {ReplyTag,ReturnVal} ->
            ReturnVal
        after 5000 ->
            ?ERROR_MSG("time out  %%%%%%%%%",[]),
            {error,timeout}
    end.

    
%%设置角色培养属性
set_role_grow(RoleID, Index, Val)->
    send_to_role_map_gm(RoleID, {set_role_grow, RoleID, Index,Val}).

set_role_tower_fb_info(RoleID, Index, Val) ->
    send_to_role_map_gm(RoleID, {set_role_tower_fb_info, RoleID, Index, Val}).

%%设置角色ATTR
set_role_attr_opt(RoleID, OptionList) ->
    send_to_role_map_gm(RoleID, {set_role_attr_opt, RoleID, OptionList}).
set_role_base_opt(RoleID, OptionList) ->
    send_to_role_map_gm(RoleID, {set_role_base_opt, RoleID, OptionList}).
send_to_role_map_gm(RoleID, Info) ->
    mgeer_role:absend(RoleID, {mod_gm, Info}).


%%将模块消息发送给战场副本
send_fb_module_msg(MapId,ModuleName,Msg) when is_integer(MapId), is_atom(ModuleName)->
    case global:whereis_name( common_map:get_common_map_name( MapId ) ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,ModuleName,Msg})
    end.

open_country_treasure()->
    NStartSeconds = common_tool:now()+3,
    case common_event:get_country_treasure_config(start,NStartSeconds,30) of
        {ok,ModuleName,ModuleDataList} ->
            % Nodes = nodes(),
            % Args = [ModuleName,ModuleDataList,ModuleDataList],
            common_config_dyn:load_gen_src(ModuleName,ModuleDataList,ModuleDataList),
            % [ rpc:call(Nod, common_config_dyn, load_gen_src, Args) ||Nod<-Nodes ],
            catch global:send(common_map:get_common_map_name(?COUNTRY_TREASURE_MAP_ID),{mod,mod_country_treasure,{admin_open_fb}});
        R ->
            ?DBG(R),
            error
    end.
