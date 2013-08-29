%%%----------------------------------------------------------------------
%%% File    : mgeeg_line_router.erl
%%% Author  : Liangliang
%%% Created : 2010-03-25
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------
-module(mgeeg_router).

-include("mgeeg.hrl").

-export([router/1, router2/1, reload_router_map/1]).

-define(_include(Met1), Method =:= Met1).
-define(_include(Met1, Met2), (Method =:= Met1 orelse Method =:= Met2)).
-define(_include(Met1, Met2, Met3), (Method =:= Met1 orelse Method =:= Met2 orelse Method =:= Met3)).
-define(_include(Met1, Met2, Met3, Met4), (Method =:= Met1 orelse Method =:= Met2 orelse Method =:= Met3 orelse Method =:= Met4)).
-define(_include(Met1, Met2, Met3, Met4, Met5), (Method =:= Met1 orelse Method =:= Met2 orelse Method =:= Met3 orelse Method =:= Met4 orelse Method =:= Met5)).

-define(_exclude(Met1), Method =/= Met1).
-define(_exclude(Met1, Met2), (Method =/= Met1 andalso Method =/= Met2)).
-define(_exclude(Met1, Met2, Met3), (Method =/= Met1 andalso Method =/= Met2 andalso Method =/= Met3)).
-define(_exclude(Met1, Met2, Met3, Met4), (Method =/= Met1 andalso Method =/= Met2 andalso Method =/= Met3 andalso Method =/= Met4)).

%% --------------------------------------------------------------------

router({Unique, Module, Method, DataRecord, RoleID, PID, Line}) ->
    catch common_role_tracer:trace(RoleID,Module,Method,DataRecord),
    case common_config:chk_module_method_open(Module, Method) of
        true ->
            %%catch common_stat:stat_method(Module,Method),
            router2({Unique, Module, Method, DataRecord, RoleID, PID, Line});
        {false, Reason} ->
            R = #m_system_message_toc{message=Reason},
            Socket = erlang:get(socket),
            case catch mgeeg_packet:packet_encode(?DEFAULT_UNIQUE, ?SYSTEM, ?SYSTEM_MESSAGE, R) of
                {'EXIT', Error} ->
                    ?ERROR_MSG("~ts:~w ~w", ["编码数据包出错", Error, {?SYSTEM, ?SYSTEM_MESSAGE, R}]);
                Bin ->
                    case erlang:is_port(Socket) of
                        true ->
                            erlang:port_command(Socket, Bin, [force]);
                        false ->
                            ignore
                    end
            end
    end.

router2({Unique, Module, Method, DataRecord, _RoleID, _Pid, _Line}) 
  when Module =:= ?SYSTEM andalso Method =:= ?SYSTEM_HEARTBEAT ->
    #m_system_heartbeat_tos{time=Time} = DataRecord,
    R = #m_system_heartbeat_toc{time=Time, server_time=common_tool:now()},
    Socket = erlang:get(socket),
    case catch  mgeeg_packet:packet_encode(Unique, Module, Method, R) of
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w ~w", ["编码数据包出错", Error, {Module, Method, R}]);
        Bin ->
            case erlang:is_port(Socket) of
                true ->
                    erlang:port_command(Socket, Bin, [force]);
                false ->
                    ignore
            end
    end;

router2({_Unique, Module, Method, DataRecord, _RoleID, _PID, _Line})
  when Module =:= ?SYSTEM andalso Method =:= ?SYSTEM_SET_FCM ->
    #m_system_set_fcm_tos{name=Realname, card=Card} = DataRecord,
    case common_config:get_agent_name() of
        "4399" ->
            Url = lists:concat([common_config:get_fcm_validation_url(), "?account=",
                                mochiweb_util:quote_plus(erlang:get(account_name)), "&truename=", mochiweb_util:quote_plus(Realname), "&card=",
                                Card, "&sign=", common_tool:md5(lists:concat([Realname, 
                                                                              common_tool:to_list(erlang:get(account_name)), 
                                                                              common_config:get_fcm_validation_key(),
                                                                              Card]))]),
            ok;
        "2918" ->
            %% 做了urlencode
            MD5 = common_tool:md5(lists:concat([mochiweb_util:quote_plus(Realname), mochiweb_util:quote_plus(erlang:get(account_name)),
                                                common_config:get_fcm_validation_key(), Card])),
            Param = mochiweb_util:urlencode([{"account", erlang:get(account_name)}, {"truename", Realname}, {"card", Card}]),
            Url = lists:concat([common_config:get_fcm_validation_url(), "?", Param, "&sign=", MD5]);
        "96pk" ->
            %% 做了urlencode
            MD5 = common_tool:md5(lists:concat([mochiweb_util:quote_plus(Realname), 
                                                mochiweb_util:quote_plus(erlang:get(account_name)),
                                                common_config:get_fcm_validation_key(), Card])),
            Param = mochiweb_util:urlencode([{"account", erlang:get(account_name)}, {"truename", Realname}, {"card", Card}]),
            Url = lists:concat([common_config:get_fcm_validation_url(), Param, "&sign=", MD5]);
        "pptv" ->
            MD5 = common_tool:md5(lists:concat([mochiweb_util:quote_plus(Realname), 
                                                mochiweb_util:quote_plus(erlang:get(account_name)),
                                                common_config:get_fcm_validation_key(), Card])),
            [ServerID] = common_config_dyn:find(common, server_id),
            Param = mochiweb_util:urlencode([{"gid", "mccq"}, {"account", erlang:get(account_name)}, {"truename", Realname}, {"card", Card},{"server_id",ServerID}]),
            Url = lists:concat([common_config:get_fcm_validation_url(), "?", Param, "&sign=", MD5]);
        _ ->
            MD5 = common_tool:md5(lists:concat([mochiweb_util:quote_plus(Realname), mochiweb_util:quote_plus(erlang:get(account_name)),
                                                common_config:get_fcm_validation_key(), Card])),
            [ServerID] = common_config_dyn:find(common, server_id),
            Param = mochiweb_util:urlencode([{"account", erlang:get(account_name)}, {"truename", Realname}, {"card", Card},{"server_id",ServerID}]),
            Url = lists:concat([common_config:get_fcm_validation_url(), "?", Param, "&sign=", MD5])
    end,
    %% 向平台发起请求，异步请求
    httpc:request(get, {Url, []},
                  [], [{sync, false}]),
    ok;
    
router2({Unique, Module, Method, DataIn, RoleID, PID, Line}) when Method =:= ?STALL_CHAT ->
    #m_stall_chat_tos{target_role_id=TargetRoleID} = DataIn, 
    case common_misc:get_stall_map_pid(TargetRoleID) of
        {ok, MapPID} ->
            MapPID ! {Unique, Module, Method, DataIn, RoleID, PID, Line};
        _ ->
            DataRecord = #m_stall_chat_toc{succ=false, reason=?_LANG_STALL_TARGET_ROLE_NOT_STALLING},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord)
    end;

router2({Unique, Module, Method, DataIn, RoleID, PID, Line}) when Method =:= ?STALL_LIST ->
    case global:whereis_name("mgee_map_10700") of
        undefined ->
            DataRecord = #m_stall_list_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord);
        MapPID ->
            MapPID ! {Unique, Module, Method, DataIn, RoleID, PID, Line}
    end;

router2({Unique, Module, Method, DataIn, RoleID, PID, _Line}) when Method =:= ?ROLE2_RENAME ->
    %% 交给mgeel_account_server处理
    catch global:send(mgeel_account_server, {Unique, Module, Method, DataIn, RoleID, PID});

router2({Unique, Module, Method, DataRecord, RoleID, Pid, Line}) when 
  Module =:= ?DEPOT;
  Module =:= ?GOODS;
  Module =:= ?ITEM;
  Module =:= ?MISSION;
  Module =:= ?GOAL2;
  Module =:= ?SCORE;
  Module =:= ?EQUIP;
  Module =:= ?SKILL;
  Module =:= ?VIP;
  Module =:= ?RANDOM_MISSION;
  Module =:= ?WORSHIP;
  Module =:= ?FASHION andalso ?_exclude(?FASHION_PUTON);
  Module =:= ?ROLE2 andalso ?_exclude(?ROLE2_ZAZEN, ?ROLE2_PKMODEMODIFY);
  Module =:= ?SYSTEM andalso Method =/= ?SYSTEM_PK_NOT_AGREE;
  Module =:= ?SHORTCUT;
  Module =:= ?TITLE;
  Module =:= ?TREASBOX;
  Module =:= ?SIGNIN;
  Module =:= ?LEVEL_GIFT;
  Module =:= ?SHOP;
  Module =:= ?REFINING;
  Module =:= ?PET andalso ?_exclude(?PET_SUMMON, ?PET_CALL_BACK, ?PET_HIDDEN);
  Module =:= ?CAISHEN;
  Module =:= ?LIANQI;
  Module =:= ?MAP andalso Method =:= ?MAP_TRANSFER;
  Module =:= ?ACCUMULATE_EXP;
  Module =:= ?FAMILY_IDOL;
  Module =:= ?FAMILY andalso Method =:= ?FAMILY_DONATE;
  Module =:= ?HORSE_RACING andalso ?_include(?HORSE_RACING_ENTER, ?HORSE_RACING_EXIT);
  Module =:= ?FMLDEPOT andalso ?_include(?FMLDEPOT_LIST_GOODS, ?FMLDEPOT_PUTIN, ?FMLDEPOT_LIST_LOG);
  Module =:= ?FMLSHOP andalso ?_include(?FMLSHOP_LIST, ?FMLSHOP_BUY);
  Module =:= ?FLOWERS;
  Module =:= ?ACHIEVEMENT;
  Module =:= ?QRHL;
  Module =:= ?GIFT;
  Module =:= ?JINGJIE;
  Module =:= ?JUEWEI;
  Module =:= ?PRESTIGE;
  Module =:= ?NEWCOMER;
  Module =:= ?PRESENT;
  Module =:= ?SHENQI;
  Module =:= ?EQUIP_BUILD;
  Module =:= ?RANKING andalso Method =:= ?RANKING_EQUIP_JOIN_RANK;
  Module =:= ?BROADCAST andalso Method =:= ?BROADCAST_LABA;
  Module =:= ?ACCESS_GUIDE;
  Module =:= ?WAROFMONSTER andalso ?_include(?WAROFMONSTER_GROW_GUARD, ?WAROFMONSTER_SUMMON_GUARD, ?WAROFMONSTER_BUY_BUFF);
  Module =:= ?STALL;
  Module =:= ?GEMS;
  Module =:= ?EGG;
  Module =:= ?PVE_FB andalso Method =:= ?PVE_FB_BUY_BUFF;
  Module =:= ?EXCHANGE;
  Module =:= ?DRIVER andalso Method =:= ?DRIVER_GO;
  Module =:= ?BIGPVE andalso Method =:= ?BIGPVE_BUY_BUFF;
  Module =:= ?ACTIVITY andalso ?_include (?ACTIVITY_BENEFIT_REWARD, ?ACTIVITY_BENEFIT_BUY,?ACTIVITY_DAILY_PAY_REWARD, ?ACTIVITY_EXP_BACK_FETCH, ?ACTIVITY_GETGIFT);
  Module =:= ?ACTIVITY andalso ?_include(?ACTIVITY_DINGZI_BUY,?ACTIVITY_OPEN_ACTIVITY_REWARD,?ACTIVITY_DINGZI_INFO, ?ACTIVITY_LV_SALE_INFO, ?ACTIVITY_LV_SALE_BUY);
  Module =:= ?TRADING andalso ?_include(?TRADING_GET, ?TRADING_RETURN);
  Module =:= ?EXAMINE_FB andalso ?_include(?EXAMINE_FB_SELECT_REWARD, ?EXAMINE_FB_SWEEP, ?EXAMINE_FB_ONE_KEY_SWEEP, ?EXAMINE_FB_HIDDEN_ENTER, ?EXAMINE_FB_RESET);
  Module =:= ?EXAMINE_FB andalso Method =:= ?EXAMINE_FB_FULL_STAR_AWARD;
  Module =:= ?HERO_FB andalso ?_include(?HERO_FB_SELECT_REWARD, ?HERO_FB_SWEEP, ?HERO_FB_ONE_KEY_SWEEP);
  Module =:= ?RNKM andalso ?_include(?RNKM_ADD_CHANCE, ?RNKM_GET_BONUS, ?RNKM_MIRROR_ATTR, ?RNKM_REFRESH_CD);
  Module =:= ?CLGM andalso ?_include(?CLGM_ROTATE, ?CLGM_STORM, ?CLGM_GET_BONUS, ?CLGM_MIRROR_ATTR);
  Module =:= ?TOWER_FB andalso (Method =:= ?TOWER_FB_REWARD orelse (Method =:= ?TOWER_FB_ENTER andalso DataRecord#m_tower_fb_enter_tos.enter_type==1));
  Module =:= ?GUARD_FB andalso Method =/= ?GUARD_FB_ENTER;
  Module =:= ?MISSION_FB andalso ?_include(?MISSION_FB_ENTER, ?MISSION_FB_PROP);
  Module =:= ?SPRING andalso ?_include(?SPRING_BUY_BUFF, ?SPRING_UPDATE);
  Module =:= ?SWL_MISSION;
  Module =:= ?PERSONYBC;
  Module =:= ?PVE_FB;
  Module =:= ?JAIL andalso Method =:= ?JAIL_DONATE;
  Module =:= ?ARENA andalso Method =:= ?ARENA_CHALLENGE;
  Module =:= ?WAROFKING andalso Method =:= ?WAROFKING_BUY_BUFF;
  Module =:= ?QQ;
  Module =:= ?DAILY_COUNTER;
  Module =:= ?OPEN_ACTIVITY;
  Module =:= ?NATIONBATTLE andalso (Method =:= ?NATIONBATTLE_FETCH_REWARD orelse Method =:= ?NATIONBATTLE_TRANSFER);
  Module =:= ?BOMB_FB andalso ?_include(?BOMB_FB_PLANT);
  Module =:= ?HUOLING;
  Module =:= ?RUNE_ALTAR;
  Module =:= ?RAGE_PRACTICE;
  Module =:= ?CD;
  Module =:= ?CONSUME_TASK ->
	case erlang:get(role_pid) of
		undefined ->
			exit(self(), role_process_not_found);
		PID ->
			PID ! {Unique, Module, Method, DataRecord, RoleID, Pid, Line}
	end;

router2({Unique, Module, Method, DataRecord, RoleID, Pid, Line}) when 
    Module =:= ?MAP orelse
	Module =:= ?PET orelse
    Module =:= ?ROLE2 orelse
    Module =:= ?STONE orelse
    Module =:= ?MOVE  orelse
    Module =:= ?FIGHT orelse
    Module =:= ?COLLECT orelse
    Module =:= ?WAROFCITY orelse
    Module =:= ?DRIVER orelse
    Module =:= ?TRADING orelse
    Module =:= ?TEAM orelse
    Module =:= ?WAROFFACTION orelse
    Module =:= ?COUNTRY_TREASURE orelse
    Module =:= ?SPY orelse
    Module =:= ?JAIL orelse
    Module =:= ?SPRING orelse
    Module =:= ?EDUCATE_FB orelse
    Module =:= ?PERSONAL_FB orelse
    Module =:= ?HERO_FB orelse
    Module =:= ?SINGLE_FB orelse
    Module =:= ?MISSION_FB orelse
    Module =:= ?SCENE_WAR_FB orelse
    Module =:= ?WAROFKING orelse
    (Module =:= ?MINE_FB andalso Method=/= ?MINE_FB_LIST)  orelse
    Module =:= ?GUARD_FB orelse
    Module =:= ?BUBBLE orelse
    (Module =:= ?CROWN andalso (
        Method=:= ?CROWN_ARENA_QUIT orelse Method=:= ?ARENA_PICK_BUFF orelse Method=:= ?CROWN_WATCH_ENTER
      )
    ) orelse 
    (Module =:= ?ARENA andalso (
        Method=:=?ARENA_QUIT orelse Method=:=?ARENA_ASSIST orelse Method=:=?ARENA_READY_ANSWER
	  )
    ) orelse
    (Module =:= ?PLANT andalso Method =/= ?PLANT_ASSART ) orelse
    Module =:= ?BONFIRE orelse
    Module =:= ?FAMILY_COLLECT  orelse
    Module =:= ?ACTIVITY orelse
    (Module =:= ?SPECIAL_ACTIVITY andalso Method=:=?SPECIAL_ACTIVITY_STAT) orelse
    Module =:= ?NATIONBATTLE orelse
    Module =:= ?ARENABATTLE orelse
    Module =:= ?FB_NPC orelse
    Module =:= ?EXAMINE_FB orelse
    Method =:= ?FRIEND_VISIT orelse
    Module =:= ?MONEY_FB orelse
    Method =:= ?FRIEND_SEND_VISITED_LIST orelse
    (Module =:= ?FRIEND andalso Method =:= ?FRIEND_RECOMMEND) orelse
    %Method =:= ?STALL_EMPLOY orelse
    %Method =:= ?STALL_FINISH orelse
    Module =:= ?SYSTEM orelse
    Module =:= ?MIRROR_FIGHT orelse
    Module =:= ?BOMB_FB orelse
    Module =:= ?FASHION orelse
    Module =:= ?BIGPVE orelse 
    Module =:= ?TOWER_FB orelse
    Module =:= ?MOUNT ->
   case erlang:get(map_pid) of
        undefined ->
             exit(self(), role_map_process_not_found);
        PID ->
            PID ! {Unique, Module, Method, DataRecord, RoleID, Pid, Line}
    end;


router2({Unique, Module, Method, DataRecord, RoleID, PID, Line})
  when Module =:= ?FAMILY 
		   orelse (Module =:= ?FMLSKILL)
		   orelse (Module =:= ?FMLDEPOT)
		   orelse (Module =:= ?PLANT andalso Method =:= ?PLANT_ASSART ) 
		   orelse Module =:= ?FAMILY_WELFARE
		   orelse Method =:= ?FMLSHOP_ADD ->
    case global:whereis_name(mod_family_manager) of
        undefined ->
            ignore;
        GPID ->
            GPID ! {Unique, Module, Method, DataRecord, RoleID, PID, Line}
    end;

router2({Unique, Module, Method, DataRecord, RoleID, PID, Line}) when Module =:= ?HORSE_RACING  ->
    ?TRY_CATCH( global:send(mgeew_horse_racing, {Unique, Module, Method, DataRecord, RoleID, PID, Line}) );

router2({Unique, Module, Method, DataRecord, RoleID, PID, Line}) 
  when Module =:= ?OFFICE  ->
    catch global:send(mgeew_office, {Unique, Module, Method, DataRecord, RoleID, PID, Line});

router2({Unique, Module, Method, DataRecord, RoleID, Pid, Line}) ->
    do_router({Unique, Module, Method, DataRecord, RoleID, Pid, Line}).

do_router({Unique, Module, Method, DataRecord, RoleID, Pid, Line}) ->
    Info = {Unique, Module, Method, DataRecord, RoleID, Pid, Line},
    case Module of
        ?MAP ->
            global:send(mgeem_router, Info);
        ?ARENA ->
            global:send(mod_arena_manager, Info);
        ?MINE_FB ->
            global:send(mod_mine_fb_manager, Info);
        ?BROADCAST ->
            global:send("mod_broadcast_server", Info);
        ?FRIEND ->
            global:send(mod_friend_server, Info);
        ?GM ->
            global:send(mgeel_s2s_client, Info);
        ?STAT ->
            global:send(mgeel_stat_server, Info);
        ?RANKING ->
            global:send(mgeew_ranking, Info);
        ?RANKREWARD ->
            global:send(mod_rankreward_server, Info);
        ?LETTER ->
            global:send(mgeew_letter_server, Info);
        ?SPECIAL_ACTIVITY->
            global:send(mgeew_activity_server,Info);
		?CROWN->
            global:send(mgeew_crown_arena_server,Info);
        ?FACTION ->
            global:send(mgeew_faction, Info);
		?RNKM ->
			global:send(mod_mirror_rnkm, Info);
		?CLGM ->
			global:send(mod_mirror_clgm, Info);
        ?TOWER_FB_MANAGER ->
            global:send(mod_tower_fb_manager, Info);
        _ ->
            ?DEBUG("undefined module ~w", [Module]), 
            ok
    end.

%% use this method to update the moudle method map data.
reload_router_map(Filename) ->
    {ok, _Map} = file:consult(Filename),
    ok.
