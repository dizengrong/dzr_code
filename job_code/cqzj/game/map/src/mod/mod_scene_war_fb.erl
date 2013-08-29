%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 场景大战副本类型
%%% @end
%%% Created : 31 Mar 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_scene_war_fb).

%% INCLUDE
-include("mgeem.hrl").
-include("scene_war_fb.hrl").

%% 怪物出生点记录
-record(r_vwf_monster_bron,{tx,ty}).

-export([
         handle/1,
         handle/2
        ]).

-export([
         init/2,
         loop/2
        ]).

-export([
         do_handle_info/1,
         do_cancel_role_sw_fb/1,
         is_scene_war_fb_map_id/1,
         is_scene_war_fb_born_monster/1,
         hook_role_pick_dropthing/2,
         do_hook_quit_team/1,
         get_sw_fb_exp_rate/2,
         check_sw_fb_mcm/2,
         check_sw_fb_time_and_fee/2,
         check_sw_fb_role_enter_level_limit/2,
		 get_scene_war_fb_map_process_name/2
        ]).
-export([
         hook_monster_dead/1,
         hook_role_dead/2,
         hook_role_enter_map/2,
         hook_role_offline/1,
         hook_role_online/1,
         
         put_sw_fb_enter_dict/2,
         get_sw_fb_dict/1
        ]).
-export([
         get_relive_home_pos/2,
         assert_valid_map_id/1,
         get_map_name_to_enter/1,set_map_enter_tag/2,
         clear_map_enter_tag/1
        ]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(SW_FB_MAP_NAME_TO_ENTER,sw_fb_map_name_to_enter).



%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_SW_FB_NOT_IN_FB_MAP,10101).
-define(ERR_SW_FB_ROLE_NOT_IN_MAP,10102).
-define(ERR_SW_FB_ROLE_VIP_NOT_AVARIABLE,10103).
-define(ERR_SW_FB_ROLE_FB_NOT_AVARIABLE,10104).
-define(ERR_SW_FB_ROLE_FB_BUFF_DUPLICATE,10105).
-define(ERR_SW_FB_BUY_SILVER_ANY_NOT_ENOUGH,10110).
-define(ERR_SW_FB_BUY_GOLD_ANY_NOT_ENOUGH,10111).


%%%===================================================================
%%% API
%%%===================================================================
handle(Info) ->
    do_handle_info(Info).
handle(Info,_State) ->
    do_handle_info(Info).

%% 场景大战副本入口地图进程字典信息，入口比如是京城
put_sw_fb_enter_dict(MapId,DataRecordList) ->
    put({?SW_FB_ENTER_DICT_PREFIX,MapId},DataRecordList).
get_sw_fb_enter_dict(MapId) ->
    get({?SW_FB_ENTER_DICT_PREFIX,MapId}).

%% 场景大战副本地图进程字典信息
put_sw_fb_dict(MapId,Record) ->
    put({?SW_FB_DICT_PREFIX,MapId},Record).
get_sw_fb_dict(MapId) ->
    get({?SW_FB_DICT_PREFIX,MapId}).

%% @doc 获取复活的回城点
get_relive_home_pos(RoleMapInfo, MapID) when is_record(RoleMapInfo,p_map_role)->
    case common_misc:get_born_info_by_map(MapID) of
        {MapID, TX, TY} ->
            {MapID, TX, TY};
        _ ->
            #p_map_role{faction_id=FactionID} = RoleMapInfo,
            common_misc:get_born_info_by_map( common_misc:get_home_mapid(FactionID, MapID) )
    end.

assert_valid_map_id(DestMapID)->
    case is_scene_war_fb_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.

%% 玩家跳转进入场景大战地图进程字典信息
get_map_name_to_enter(RoleID)->
    CurMapId = mgeem_map:get_mapid(),
    get({?SW_FB_MAP_NAME_TO_ENTER,CurMapId,RoleID}).

clear_map_enter_tag(RoleID)->
    CurMapId = mgeem_map:get_mapid(),
    erlang:erase({?SW_FB_MAP_NAME_TO_ENTER,CurMapId,RoleID}).

set_map_enter_tag(RoleID,FbMapProcessName) ->
    CurMapId = mgeem_map:get_mapid(),
    put({?SW_FB_MAP_NAME_TO_ENTER,CurMapId,RoleID},FbMapProcessName).

    
%% 获取场景大战副本地图进程名称
get_scene_war_fb_map_process_name(FbId,FbSeconds) ->
    lists:concat(["map_scene_war_",FbId,FbSeconds]).

%% 地图初始化时，大明宝藏初始化
%% 参数：
%% MapId 地图id
%% MapName 地图进程名称
init(MapId, _MapName) ->
    %% 场景大战副本地图入口，例如京城
    case get_swfb_npc_record(MapId) of
        false ->
            ignore;
        #r_sw_fb_npc{map_id = MapId} ->
            put_sw_fb_enter_dict(MapId,[])
    end,
    %% 场景大战副本地图
    case get_swfb_mcm_record(MapId) of
        false ->
            ignore;
        #r_sw_fb_mcm{fb_map_id = MapId, max_seconds = MaxSeconds} ->
            StartTime = common_tool:now(),
            Record = #r_sw_fb_dict{start_time = StartTime,
                                   end_time = StartTime + MaxSeconds,
                                   fb_status = ?SCENE_WAR_FB_FB_STATUS_CREATE},
            put_sw_fb_dict(MapId,Record),
            ok
    end.


%%@doc 地图循环处理函数，即一秒循环
loop(MapId,NowSeconds) ->
	case get_sw_fb_dict(MapId) of
		undefined ->
			ignore;
		SwFbDictRecord ->
			if SwFbDictRecord#r_sw_fb_dict.fb_status =:= ?SCENE_WAR_FB_FB_STATUS_CREATE ->
				   if NowSeconds > SwFbDictRecord#r_sw_fb_dict.end_time ->
						  common_map:exit(sw_fb_map_close_1);
					  true ->
						  ignore
				   end;
			   true ->
				   loop2(MapId,SwFbDictRecord,NowSeconds)
			end
	end.
loop2(MapId,SwFbDictRecord,NowSeconds) ->
    %% 检查副本的结束时间
    #r_sw_fb_dict{fb_status = FbStatus,fb_close_flag = FbCloseFlag,
                  fb_offline_role_ids = FbOfflineRoleIdList,
                  fb_id = FbId,fb_seconds = FbSeconds,
                  enter_fb_map_id=EnterFbMapId} = SwFbDictRecord,
    FbOfflineRoleIdList2 = 
        lists:foldl(
          fun({OfflineRoleId,OfflineEndSeconds},AccOfflineRoleIdList) ->
                  if NowSeconds > OfflineEndSeconds ->
                          do_cancel_role_sw_fb(OfflineRoleId),
                          AccOfflineRoleIdList;
                     true ->
                          [{OfflineRoleId,OfflineEndSeconds}|AccOfflineRoleIdList]
                  end
          end,[],FbOfflineRoleIdList),
    case EnterFbMapId of
        undefined ->
            common_map:exit(sw_fb_map_close_2);
        _ ->
            next
    end,
    EnterFbMapProcessName = common_map:get_common_map_name(EnterFbMapId),
    case  (FbOfflineRoleIdList2 =:= [] 
          andalso mod_map_actor:get_in_map_role() =:= []
          andalso FbStatus =:= ?SCENE_WAR_FB_FB_STATUS_RUNNING) of
        true -> %% 可以关闭副本
            put_sw_fb_dict(MapId,SwFbDictRecord#r_sw_fb_dict{fb_offline_role_ids = FbOfflineRoleIdList2,
                                                             fb_close_flag = ?SCENE_WAR_FB_FB_STATUS_CLOSE}),
            catch global:send(EnterFbMapProcessName,{mod_scene_war_fb,{update_enter_sw_fb_info,FbId,FbSeconds,?SCENE_WAR_FB_FB_STATUS_CLOSE}}),
            do_scene_war_fb_close_and_bc(0);
        false ->
            SwFbDictRecord2 = SwFbDictRecord#r_sw_fb_dict{fb_offline_role_ids = FbOfflineRoleIdList2},
            %% 原先判断副本怪物的个数为零则关闭副本  不符合召唤怪物的模式
			%%MonsterIDList = mod_map_monster:get_monster_id_list(),
            if FbCloseFlag =/= ?SCENE_WAR_FB_FB_STATUS_CLOSE 
               andalso FbStatus =/= ?SCENE_WAR_FB_FB_STATUS_CREATE
               andalso SwFbDictRecord2#r_sw_fb_dict.monster_number=<SwFbDictRecord2#r_sw_fb_dict.cur_monster_number ->
                    put_sw_fb_dict(MapId,SwFbDictRecord2#r_sw_fb_dict{fb_close_flag = ?SCENE_WAR_FB_FB_STATUS_CLOSE}),
                    catch global:send(EnterFbMapProcessName,{mod_scene_war_fb,{update_enter_sw_fb_info,FbId,FbSeconds,?SCENE_WAR_FB_FB_STATUS_CLOSE}}),
                    %% 将副本等待关闭的时间也写到进程字典
					%%[CloseSeconds] = common_config_dyn:find(scene_war_fb, scene_war_fb_close_seconds),
                    do_scene_war_fb_close_and_bc(SwFbDictRecord2#r_sw_fb_dict.close_seconds);
               true ->
                    put_sw_fb_dict(MapId,SwFbDictRecord2),
                    ignore
            end
    end.

%% 怪物死亡
%% Rarity 1:普通 2:精英 3:BOSS
hook_monster_dead({TypeId,MonsterName,Rarity,MonsterLevel}) ->

    MapId = mgeem_map:get_mapid(),
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        _SwFbDictRecord ->
            do_monster_dead(TypeId,MonsterName,Rarity, MonsterLevel)
            %% FbMapProcessName = get_scene_war_fb_map_process_name(FbId,FbSeconds),
            %% global:send(FbMapProcessName,{mod_scene_war_fb,{monster_dead,TypeId,MonsterName,Rarity}})
            %% self() ! {mod_scene_war_fb,{monster_dead,TypeId,MonsterName,Rarity}}
    end.
%% 玩家死亡
hook_role_dead(RoleID,MapRoleInfo) ->
    MapId = mgeem_map:get_mapid(),
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        _ ->
            self() ! {mod_scene_war_fb,{role_dead,RoleID,MapRoleInfo}}
    end.
    
%% 玩家进入地图
hook_role_enter_map(RoleID,MapId) ->
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        SwFbDictRecord ->
            #r_sw_fb_dict{fb_status = FbStatus,end_time = EndTime} = SwFbDictRecord,
            if FbStatus =:= ?SCENE_WAR_FB_FB_STATUS_CREATE ->
                    put_sw_fb_dict(MapId,SwFbDictRecord#r_sw_fb_dict{fb_status = ?SCENE_WAR_FB_FB_STATUS_RUNNING});
               true ->
                    next
            end,
            %%完成进入场景副本的任务
            mgeer_role:run(RoleID, fun() -> hook_mission_event:hook_enter_sw_fb(RoleID,MapId) end),
            
            {_NowDate,{H,M,S}} =
                common_tool:seconds_to_datetime(EndTime),
            StrM = if M >= 10 -> common_tool:to_list(M);true -> lists:concat(["0",M]) end,
            StrS = if S >= 10 -> common_tool:to_list(S);true -> lists:concat(["0",S]) end,
            EnterMessage = common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_BROADCAST_ENTER_FB,[H,StrM,StrS]),
            (catch common_broadcast:bc_send_msg_role(RoleID,[?BC_MSG_TYPE_SYSTEM,?BC_MSG_TYPE_CENTER],EnterMessage)),
            ?TRY_CATCH(hook_call_monster(RoleID,MapId,SwFbDictRecord),Err),
            %% 设置副本的超时定时器
            set_fb_timeout_timer(RoleID, MapId)
    end.


%% 是否要通知有怪物
hook_call_monster(RoleID,MapId,SwFbDictRecord)->
    MonsterNum = erlang:length(mod_map_monster:get_monster_id_list()),
    case MonsterNum >0 of
        true->
            DestPassID = SwFbDictRecord#r_sw_fb_dict.cur_monster_key;
        false->
            DestPassID = get_next_pass_id(MapId,SwFbDictRecord#r_sw_fb_dict.cur_monster_key)
    end,
    case SwFbDictRecord#r_sw_fb_dict.born_monster of
        ?SCENE_WAR_FB_BORN_MONSTER_CALL->
            case DestPassID =/= ?FINISH_PASS of
                true->
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SCENE_WAR_FB, ?SCENE_WAR_FB_CALL_MONSTER, 
                                              #m_scene_war_fb_call_monster_toc{op_type=?SCENE_WAR_FB_CALL_MONSTER_TYPE,
                                               pass_id =DestPassID});
                false->
                    ignore
            end;
        _->
            ignore
    end.

%% 玩家下线
hook_role_offline(RoleID) ->
    MapId = mgeem_map:get_mapid(),
    NowSeconds = common_tool:now(),
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        SwFbDictRecord ->
            [SwFbKeepOfflineSeconds] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_keep_offline_seconds),
            #r_sw_fb_dict{fb_offline_role_ids = FbOfflineRoleIdList} = SwFbDictRecord,
            put_sw_fb_dict(MapId,SwFbDictRecord#r_sw_fb_dict{fb_offline_role_ids = [{RoleID,NowSeconds + SwFbKeepOfflineSeconds}|FbOfflineRoleIdList]})
    end.
%% 玩家上线
hook_role_online(RoleID) ->
    MapId = mgeem_map:get_mapid(),
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        SwFbDictRecord ->
            #r_sw_fb_dict{fb_offline_role_ids = FbOfflineRoleIdList, scene_war_fb = SceneWarFbList,
                          cur_monster_number=CurMonsterNum, monster_number=MonsterNum} = SwFbDictRecord,
            case lists:keyfind(RoleID,1,FbOfflineRoleIdList) of
                false ->
                    ignore;
                {RoleID,_} ->
                    FbOfflineRoleIdList2 = lists:keydelete(RoleID,1,FbOfflineRoleIdList),
                    put_sw_fb_dict(MapId,SwFbDictRecord#r_sw_fb_dict{fb_offline_role_ids = FbOfflineRoleIdList2})
            end,
            if CurMonsterNum >= MonsterNum ->
                   %% 特殊情况：玩家在倒数10秒左右提示时下线，因判断玩家下线处理是有延迟的，因此副本只是走帮玩家切换地图的操作，
                   %% 此时FbCloseFlag =:= ?SCENE_WAR_FB_FB_STATUS_CLOSE, 而如果此时玩家上线即不会再踢出副本，即使杀怪数已经超过了规定的数量。
                   %% 现判断玩家上线时副本杀怪数来决定是否让玩家传出副本
                   case lists:keyfind(RoleID,#r_scene_war_fb.role_id,SceneWarFbList) of
                       false ->
                           ignore;
                       SceneWarFbRecord ->
                           #r_scene_war_fb{map_id = DestMapId,pos = DestPos} = SceneWarFbRecord,
                           #p_pos{tx=DestTx,ty = DestTy} = DestPos,
                           mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID,DestMapId,DestTx,DestTy)
                   end;
               true ->
                   ignore
            end
    end.


%% 判断是否是场景大战副本地图
is_scene_war_fb_map_id(MapId) ->
    case common_config_dyn:find(scene_war_fb,sw_fb_mcm) of
        [] ->
            false;
        [SwFbMcmList] ->
            case lists:keyfind(MapId,#r_sw_fb_mcm.fb_map_id,SwFbMcmList) of
                false ->
                    false;
                _ ->
                    true
            end
    end.
%% 场景大战副本是否出生怪物
is_scene_war_fb_born_monster(MapId) ->
    case common_config_dyn:find(?SCENE_WAR_FB_CONFIG, sw_fb_mcm) of
        [] ->
            true;
        [SwFbMcmList] ->
            case lists:keyfind(MapId, #r_sw_fb_mcm.fb_map_id, SwFbMcmList) of
                false->
                    true;
                #r_sw_fb_mcm{born_monster=?SCENE_WAR_FB_BORN_MONSTER_AUTO} ->
					true;
                _ ->
                    false
            end
    end.


%% 进入场景大战副本
do_handle_info({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_ENTER, DataRecord, RoleID, PId, _Line})
  when erlang:is_record(DataRecord,m_scene_war_fb_enter_tos)->
    do_scene_war_fb_enter({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_ENTER, DataRecord, RoleID, PId});
%% 退出场景大战副本
do_handle_info({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_QUIT, DataRecord, RoleID, PId, _Line})
  when erlang:is_record(DataRecord,m_scene_war_fb_quit_tos)->
    do_scene_war_fb_quit({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_QUIT, DataRecord, RoleID, PId});
%% 查询场景大战副本信息
do_handle_info({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_QUERY, DataRecord, RoleID, PId, _Line})
  when erlang:is_record(DataRecord,m_scene_war_fb_query_tos)->
    do_scene_war_fb_query({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_QUERY, DataRecord, RoleID, PId});
%% 玩家召唤怪物
do_handle_info({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_CALL_MONSTER, DataRecord, RoleID, PId, _Line})
  when erlang:is_record(DataRecord,m_scene_war_fb_call_monster_tos)->
    do_scene_war_fb_call_monster({Unique, ?SCENE_WAR_FB, ?SCENE_WAR_FB_CALL_MONSTER, DataRecord, RoleID, PId});

%% global:send(FbMapProcessName, {mod_scene_war_fb,{create_sw_fb_info,SwFbDict}})
%% global:send(FbMapProcessName, {mod_scene_war_fb,{create_sw_fb_info,SceneFbRecord}})
do_handle_info({create_sw_fb_info,DataRecord}) ->
    do_create_sw_fb_info(DataRecord);
%% global:send(FbMapProcessName,{mod_scene_war_fb,{monster_dead,TypeId,MonsterName,Rarity}})
do_handle_info({monster_dead,TypeId,MonsterName,Rarity,MonsterLevel}) ->
    do_monster_dead(TypeId,MonsterName,Rarity,MonsterLevel);
%% self() ! {mod_scene_war_fb,{role_dead,RoleID,MapRoleInfo}}.
do_handle_info({role_dead,RoleID,MapRoleInfo}) ->
    do_role_dead(RoleID,MapRoleInfo);
do_handle_info({init_sw_monster, MonsterKey}) ->
    do_init_sw_monster(MonsterKey);
%% catch global:send(EnterMapProcessName,{mod_scene_war_fb,{diff_map_enter_fb,XXXX}})
do_handle_info({diff_map_enter_fb,{Unique, Module, Method, DataRecord, RoleID, PId},
                RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord}) ->
    do_scene_war_fb_enter3({Unique, Module, Method, DataRecord, RoleID, PId},
                           RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord);
do_handle_info({put_enter_sw_fb_info,RoleID,FbMapId,FbMapProcessName}) ->
    put_enter_sw_fb_info(RoleID,FbMapId,FbMapProcessName);
    
%%{mod_scene_war_fb,{scene_war_fb_close_and_bc,MaxInterval}}
do_handle_info({scene_war_fb_close_and_bc,MaxInterval}) ->
    do_scene_war_fb_close_and_bc(MaxInterval);
%% 玩家通过传送和其它方式离开场景大战副本
%% global:send(FbMapProcessName,{mod_scene_war_fb,{cancel_role_sw_fb,RoleID}})
do_handle_info({cancel_role_sw_fb,RoleID}) ->
    do_cancel_role_sw_fb(RoleID);

%% global:send(EnterFbMapProcessName,{mod_scene_war_fb,{update_enter_sw_fb_info,FbId,FbSeconds,?SCENE_WAR_FB_FB_STATUS_CLOSE}}),
do_handle_info({update_enter_sw_fb_info,FbId,FbSeconds,FbStatus}) ->
    do_update_enter_sw_fb_info({FbId,FbSeconds,FbStatus});

do_handle_info({delete_enter_sw_fb_info,FbId,FbSeconds}) ->
    do_delete_enter_sw_fb_info({FbId,FbSeconds});

%% 创建地图成功
do_handle_info({create_map_succ, Key}) ->
    do_create_fb_succ(Key);

%% 关闭场景大战地图进程
do_handle_info({kill_scene_war_fb_map}) ->
    #map_state{mapid =MapId}= mgeem_map:get_state(),
    #r_sw_fb_dict{fb_id = FbId,fb_seconds = FbSeconds,enter_fb_map_id = EnterFbMapId} = get_sw_fb_dict(MapId),
    EnterFbMapProcessName = common_map:get_common_map_name(EnterFbMapId),
    catch global:send(EnterFbMapProcessName,{mod_scene_war_fb,{delete_enter_sw_fb_info,FbId,FbSeconds}}),
    common_map:exit( scene_war_fb_map_exit );

do_handle_info(Info) ->
    ?ERROR_MSG("~ts,Info=~w",["场景大战模块无法处理此消息",Info]),
    error.

%% 设置超时退出timer
set_fb_timeout_timer(_RoleID, MapId) ->
    case erlang:get(scene_war_fb_timeout_ref) of
        undefined ->ignore;
        Ref -> erlang:cancel_timer(Ref),erlang:erase(scene_war_fb_timeout_ref)
    end,
    %% 副本超时时间为10min
    TimerRef = erlang:send_after(1000*get_fb_lasting_time(MapId), self(), {?MODULE, {scene_war_fb_close_and_bc, 5}}),
    erlang:put(scene_war_fb_timeout_ref, TimerRef).

get_fb_lasting_time(MapId) -> 
    case get_swfb_mcm_record(MapId) of
        false ->
            1800;
        #r_sw_fb_mcm{max_seconds = MaxSeconds} ->
            MaxSeconds
    end.

%% 进入副本
%% DataRecord 结构为 m_scene_war_fb_enter_tos
do_scene_war_fb_enter({Unique, Module, Method, DataRecord, RoleID, PId}) ->
    case catch do_scene_war_fb_enter2(Unique, Module, Method, DataRecord, RoleID, PId) of
        {error,Reason,ReasonCode} ->
            do_scene_war_fb_enter_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode);
        {error,diff_map_enter_fb,RoleID,CurMapId} ->
            ?DEBUG("~ts,DataRecord=~w,RoleID=~w,CurMapId=~w",["玩家在不同NPC的地图传送进来",DataRecord,RoleID,CurMapId]);
        {ok,RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord} ->
            do_scene_war_fb_enter3({Unique, Module, Method, DataRecord, RoleID, PId},
                                  RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord)
    end.

%% 场景副本条件判断
do_scene_war_fb_enter2(Unique, Module, Method, DataRecord, RoleID, PId) ->
    #m_scene_war_fb_enter_tos{npc_id = NpcId, 
                              fb_type = FbType,
                              fb_level = FbLevel,
                              fb_id = FbId,
                              fb_seconds = FbSeconds,
                              fb_fast_enter = FastEnter} = DataRecord,
    CurMapId = mgeem_map:get_mapid(),
	% case common_misc:is_role_on_map(RoleID) andalso common_misc:is_role_on_gateway(RoleID, PId) of
	case common_misc:is_role_on_map(RoleID) of
    	true->
			next;
		_ ->
			erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_ERROR,0})
	end,

  case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
      true ->
          erlang:throw({error,?_LANG_XIANNVSONGTAO_MSG,0});
      false -> ignore
  end,

	%%获取玩家地图信息
	RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID,role),
    %% 请求的副本类型，副本级别是否正确认
    [SwFbNpcList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_npc),
    SwFbNpcRecord = 
        case lists:foldl(
               fun(SwFbNpcRecordT,{AccFbNpcFlag,AccFbNpcRecord}) ->
                       if AccFbNpcFlag =:= false
                          andalso (FastEnter == true orelse NpcId =:= SwFbNpcRecordT#r_sw_fb_npc.npc_id)
                          andalso FbType =:= SwFbNpcRecordT#r_sw_fb_npc.fb_type
                          andalso FbLevel =:= SwFbNpcRecordT#r_sw_fb_npc.fb_level ->
                               {true,SwFbNpcRecordT};
                          true ->
                               {AccFbNpcFlag,AccFbNpcRecord}
                       end                                                         
               end,{false,undefined},SwFbNpcList) of
            {false, _SwFbNpcError} ->
                ?DEBUG("~ts,DataRecord=~w,SwFbNpcList=~w",["场景大战副本参数不合法",DataRecord,SwFbNpcList]),
                erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_ERROR,0});
            {true,SwFbNpcRecordTT} ->
                SwFbNpcRecordTT
        end,
    %% 玩家是否在NPC的附近，是否是本国国民  
    MapFactionId = SwFbNpcRecord#r_sw_fb_npc.map_id rem 10000 div 1000,
    if MapFactionId =/= 0 andalso RoleMapInfo#p_map_role.faction_id =/= MapFactionId ->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_FACTION,0});
       true ->
            next
    end,
    %% 检查是否有此场景大战地图信息
    [SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
    SwFbMcmRecord =
        case lists:foldl(
               fun(SwFbMcmRecordT,{AccSwFbMcmFlag,AccSwFbMcmRecord})->
                       if AccSwFbMcmFlag =:= false 
                          andalso FbType =:= SwFbMcmRecordT#r_sw_fb_mcm.fb_type
                          andalso FbLevel =:= SwFbMcmRecordT#r_sw_fb_mcm.fb_level ->
                               {true,SwFbMcmRecordT};
                          true ->
                               {AccSwFbMcmFlag,AccSwFbMcmRecord}
                       end
               end,{false,undefined},SwFbMcmList) of
            {false,_SwFbMcmError} ->
                ?DEBUG("~ts,DataRecord=~w,SwFbMcmList=~w",["场景大战副本参数不合法",DataRecord,SwFbMcmList]),
                erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_ERROR,0});
            {true,SwFbMcmRecordTT} ->
                SwFbMcmRecordTT
        end,
    %% 检查级别
    if RoleMapInfo#p_map_role.level >= SwFbMcmRecord#r_sw_fb_mcm.min_level 
       andalso SwFbMcmRecord#r_sw_fb_mcm.max_level >= RoleMapInfo#p_map_role.level ->
            next;
       true ->
            erlang:throw({error,common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_LEVEL,[SwFbMcmRecord#r_sw_fb_mcm.min_level, SwFbMcmRecord#r_sw_fb_mcm.max_level]),0})
    end,
	%% 非组队的玩家可通过
    if RoleMapInfo#p_map_role.team_id =/= 0   %% 是否组队
       andalso SwFbNpcRecord#r_sw_fb_npc.map_id =:= CurMapId ->  %% 请求的地图是不是npc所在地图
            case lists:keyfind(RoleMapInfo#p_map_role.team_id,#r_sw_fb_enter_dict.team_id,get_sw_fb_enter_dict(CurMapId)) of   %%找这个用户进入地图的信息
                false ->
                    next;
                SwFbEnterRecord ->
                    if FbId =/= 0 andalso FbSeconds =/= 0 
                       andalso FbId =:= SwFbEnterRecord#r_sw_fb_enter_dict.fb_id
                       andalso FbSeconds =:= SwFbEnterRecord#r_sw_fb_enter_dict.fb_seconds ->
                            case global:whereis_name(get_scene_war_fb_map_process_name(FbId,FbSeconds)) of
                                undefined ->
                                    erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_CLOSE,0});
                                _ ->
                                    next
                            end;
                       true ->
                            erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_CREATE,1})
                    end
            end;
       true ->
            next
    end,
    if RoleMapInfo#p_map_role.team_id =/= 0
       andalso FbId =/= 0 andalso FbSeconds =/= 0 ->
            case global:whereis_name(get_scene_war_fb_map_process_name(FbId,FbSeconds)) of
                undefined ->
                    erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_CLOSE,0});
                _ ->
                    next
            end,
            case (FastEnter == false andalso CurMapId =/= SwFbNpcRecord#r_sw_fb_npc.map_id) of
                true ->
                    catch global:send(common_map:get_common_map_name(SwFbNpcRecord#r_sw_fb_npc.map_id),
                                      {mod_scene_war_fb,{diff_map_enter_fb,
                                                         {Unique, Module, Method, DataRecord, RoleID, PId},
                                                         RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord}}),
                    erlang:throw({error,diff_map_enter_fb,RoleID,CurMapId});
                false ->
                    next
            end,
            next;
       true ->
            next
    end,
    {ok,RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord}.


%%@return #r_sw_fb_npc | false
get_swfb_npc_record(MapId) when is_integer(MapId)->
    [SwFbNpcList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_npc),
    lists:keyfind(MapId,#r_sw_fb_npc.map_id,SwFbNpcList).

%%@return #r_sw_fb_mcm | false
get_swfb_mcm_record(MapId) when is_integer(MapId)->
    [SeFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
    lists:keyfind(MapId,#r_sw_fb_mcm.fb_map_id,SeFbMcmList).

assert_get_actor_mapinfo(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined ->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_ENTER_ERROR,0});
        RoleMapInfo ->
            RoleMapInfo
    end.

do_create_fb_succ(Key) ->
    case erase_async_create_map_info(Key) of
        undefined ->
            ignore;
        {{Unique, Module, Method, DataRecord, RoleID, PId}, RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord, FbSecond} ->
            do_async_scene_war_fb_enter({Unique, Module, Method, DataRecord, RoleID, PId}, RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord, FbSecond)
    end,
    ok.

%% 启动完进程之后，初始化场景副本中的内容
do_async_scene_war_fb_enter({Unique, Module, Method, DataRecord, RoleID, PId}, RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord, FbSecond) ->
    case db:transaction(
           fun() -> 
                   do_t_async_scene_war_fb_enter(RoleID,DataRecord,RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord, FbSecond)
           end) of
        {atomic,{ok,OpType,RoleAttr,TeamRoleIdList,SceneFbRecord,FbTimes,SwFbFeeRecord}} ->
            do_scene_war_fb_enter4({Unique, Module, Method, DataRecord, RoleID, PId},
                                   RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord,OpType,RoleAttr,
                                   TeamRoleIdList,SceneFbRecord,SwFbFeeRecord,FbTimes);
        {atomic, {ok, FbMapProcessName, TeamId, TeamRoleIdList, MemberEnterInfo}} -> %副本进程名，队伍id，队员id列表，进入副本人员信息
            do_scene_war_fb_enter4({Unique, Module, Method, DataRecord, RoleID, PId},
                                   SwFbMcmRecord, FbMapProcessName, TeamId, TeamRoleIdList, MemberEnterInfo);
        {aborted, Error} ->
            case Error of
                {Reason, ReasonCode} ->
                    do_scene_war_fb_enter_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode);
                _ ->
                    ?ERROR_MSG("~ts,RoleID=~w,Error=~w",["进入场景大战副本出错",RoleID,Error]),
                    Reason2 = ?_LANG_SCENE_WAR_FB_ENTER_ERROR,
                    do_scene_war_fb_enter_error({Unique, Module, Method, DataRecord, PId},Reason2,0)
            end
    end.

%% ================== start 不同的组队要求类型判断不同 =================================================================
%% must_team 是否一定要组队，LEVEL_ONE:可以组队，可以不组。允许中途进副本  LEVEL_TWO:可以组队可以不组，不允许中途入副本  ;LEVEL_THREE:必须组队进
do_t_async_scene_war_fb_enter(RoleID, _DataRecord, RoleMapInfo, _SwFbNpcRecord, #r_sw_fb_mcm{must_team=?SCENE_WAR_FB_TEAM_LEVEL_THREE}=SwFbMcmRecord, FbSecond) ->
	%% 玩家组队信息
    RoleTeamInfo = 
        case mod_map_team:get_role_team_info(RoleID) of
            {error, _} ->
                db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MEMBER_NOT_ENOUGH, SwFbMcmRecord#r_sw_fb_mcm.team_member), 0});
            {ok, TRoleTeamInfo} ->
                TRoleTeamInfo
        end,
	%% 玩家组队的人
    TeamRoleIdList = [TeamRoleInfo#p_team_role.role_id || TeamRoleInfo <- RoleTeamInfo#r_role_team.role_list],
    if TeamRoleIdList =:= [] ->
            db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MEMBER_NOT_ENOUGH, SwFbMcmRecord#r_sw_fb_mcm.team_member), 0});
       erlang:length(TeamRoleIdList) < SwFbMcmRecord#r_sw_fb_mcm.team_member ->
            db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MEMBER_NOT_ENOUGH, SwFbMcmRecord#r_sw_fb_mcm.team_member), 0});
       true ->
            next
    end,
	%% 是否队长
    LeaderRoleId = mod_map_team:get_team_leader_role_id(RoleTeamInfo#r_role_team.role_list),
    if LeaderRoleId =/= RoleID ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_NOT_LEADER, 0});
       true ->
            next
    end,
	%%　玩家所在位置
    #p_map_role{pos=#p_pos{tx=TX, ty=TY}} = RoleMapInfo,
    FbId = RoleID,
    FbMapProcessName = get_scene_war_fb_map_process_name(FbId,FbSecond),
    case mod_map_copy:create_copy(SwFbMcmRecord#r_sw_fb_mcm.fb_map_id,FbMapProcessName) of
        ok ->
            next;
        error ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_CREATE_MAP,0})
    end,
    MemberEnterInfo =
        lists:foldl(
          fun(MemberRoleId, TMemberEnterInfo) ->
                  {ok, MemberMapInfo, MemberAttr, MemberSceneFbRecord, MemberSwFbFeeRecord, MemberTimes} =
                      t_check_team_member_can_enter(MemberRoleId, SwFbMcmRecord, FbId, FbSecond, TX, TY),
                  [{MemberRoleId, MemberMapInfo, MemberAttr, MemberSceneFbRecord, MemberSwFbFeeRecord, MemberTimes}|TMemberEnterInfo]
          end, [], TeamRoleIdList),
    {ok, FbMapProcessName, RoleMapInfo#p_map_role.team_id, TeamRoleIdList, MemberEnterInfo};

do_t_async_scene_war_fb_enter(RoleID, DataRecord, RoleMapInfo, _SwFbNpcRecord, #r_sw_fb_mcm{must_team=?SCENE_WAR_FB_TEAM_LEVEL_TWO}=SwFbMcmRecord, FbSecond) ->
       if RoleMapInfo#p_map_role.team_id =/= 0 ->
           do_t_async_scene_war_fb_enter(RoleID, DataRecord, RoleMapInfo, _SwFbNpcRecord, SwFbMcmRecord#r_sw_fb_mcm{must_team=?SCENE_WAR_FB_TEAM_LEVEL_THREE}, FbSecond);
       true->
           do_t_async_scene_war_fb_enter(RoleID,DataRecord,RoleMapInfo,_SwFbNpcRecord,SwFbMcmRecord#r_sw_fb_mcm{must_team=?SCENE_WAR_FB_TEAM_LEVEL_ONE}, FbSecond)
    end;

%%初始化场景信息 鄱阳湖组队类型
do_t_async_scene_war_fb_enter(RoleID,DataRecord,RoleMapInfo,_SwFbNpcRecord,#r_sw_fb_mcm{must_team=?SCENE_WAR_FB_TEAM_LEVEL_ONE}=SwFbMcmRecord, FbSecond) ->
    %% 获取组队信息
    if DataRecord#m_scene_war_fb_enter_tos.fb_id =:= 0 
       andalso RoleMapInfo#p_map_role.team_id =/= 0 ->
           case mod_map_team:get_role_team_info(RoleID) of
               {ok,MapTeamInfo} ->
                   LeaderRoleId = mod_map_team:get_team_leader_role_id(MapTeamInfo#r_role_team.role_list),
                   TeamRoleIdList = [TeamRoleInfo#p_team_role.role_id || TeamRoleInfo <- MapTeamInfo#r_role_team.role_list],
                   case RoleID =:= LeaderRoleId of
                       true ->
                           next;
                       _ ->
                           db:abort({?_LANG_SCENE_WAR_FB_ENTER_NOT_LEADER,0})
                   end;
               _ ->
                   {TeamRoleIdList,_LeaderRoleId} = {[],0},
                   db:abort({?_LANG_SCENE_WAR_FB_ENTER_NOT_LEADER,0})
           end;
       true ->
            {TeamRoleIdList,_LeaderRoleId} = {[],0}
    end,
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    SceneFbRecord = 
        case db:read(?DB_SCENE_WAR_FB,RoleID) of
            [] ->
                undefined;
            [SceneFbRecordT] ->
                SceneFbRecordT
        end,
    #r_sw_fb_mcm{fb_type = FbType} = SwFbMcmRecord,
    Times = get_sw_fb_times(FbType,SceneFbRecord),
    SwFbFeeRecord = 
        case get_sw_fb_fee(FbType,Times + 1) of
            {ok,SwFbFeeRecoedT} ->
                SwFbFeeRecoedT;
            {error,max_times,MaxTimes} ->
                db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MAX_TIME,MaxTimes),0});
            {error,not_found_fee} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_ERROR,0});
            {error,not_found} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_ERROR,0})
        end,
    if SwFbFeeRecord#r_sw_fb_fee.fb_fee =/= 0 -> %% 需要扣费
            _RoleAttr2 = do_t_scene_war_fb_enter_fee(RoleID,RoleAttr,SwFbFeeRecord#r_sw_fb_fee.fb_fee);
       true ->
            _RoleAttr2 = RoleAttr
    end,
    FbId = RoleID,
    FbMapProcessName = get_scene_war_fb_map_process_name(FbId,FbSecond),
    case mod_map_copy:create_copy(SwFbMcmRecord#r_sw_fb_mcm.fb_map_id,FbMapProcessName) of
        ok ->
            next;
        error ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_CREATE_MAP,0})
    end,
    SceneFbRecord2 = get_new_role_sw_fb_record(RoleMapInfo,SwFbMcmRecord,Times,SceneFbRecord,FbId,FbSecond),
    db:write(?DB_SCENE_WAR_FB,SceneFbRecord2,write),
    {ok,?SCENE_WAR_FB_ENTER_FB_TYPE_CREATE,RoleAttr,TeamRoleIdList,SceneFbRecord2,Times + 1,SwFbFeeRecord}.

%% 检查每个队员是否可以进入
t_check_team_member_can_enter(RoleID, SwFbMcmRecord, FbId, FbSecond, LeaderTX, LeaderTY) ->
    RoleMapInfo =
        case mod_map_actor:get_actor_mapinfo(RoleID, role) of
            undefined ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_TOO_FAR, 0});
            TRoleMapInfo ->
                TRoleMapInfo
        end,
    %% 检查级别
    if RoleMapInfo#p_map_role.level >= SwFbMcmRecord#r_sw_fb_mcm.min_level 
       andalso SwFbMcmRecord#r_sw_fb_mcm.max_level >= RoleMapInfo#p_map_role.level ->
            next;
       true ->
            db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MEMBER_LEVEL, 
                                                            [RoleMapInfo#p_map_role.role_name, SwFbMcmRecord#r_sw_fb_mcm.min_level]), 0}) 
    end,
	%% 队员是否在队长附近
    #p_map_role{pos=#p_pos{tx=TX, ty=TY}} = RoleMapInfo,
    if
        erlang:abs(TX-LeaderTX) < ?TEAM_MEMBER_MAX_DIS andalso
        erlang:abs(TY-LeaderTY) < ?TEAM_MEMBER_MAX_DIS ->
            next;
        true ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_TOO_FAR, 0})
    end,
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    SceneFbRecord =
        case db:read(?DB_SCENE_WAR_FB,RoleID) of
            [] ->
                undefined;
            [SceneFbRecordT] ->
                SceneFbRecordT
        end,
    #r_sw_fb_mcm{fb_type=FbType} = SwFbMcmRecord,
    Times = get_sw_fb_times(FbType, SceneFbRecord),
    SwFbFeeRecord = 
        case get_sw_fb_fee(FbType, Times + 1) of
            {ok,SwFbFeeRecoedT} ->
                SwFbFeeRecoedT;
            {error,max_times,MaxTimes} ->
                db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MEMBER_MAX_TIME,[RoleMapInfo#p_map_role.role_name,MaxTimes]), 0});
            {error,not_found_fee} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_ERROR, 0});
            {error,not_found} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_ERROR, 0})
        end,
    RoleAttr2 =
        if SwFbFeeRecord#r_sw_fb_fee.fb_fee =/= 0 -> %% 需要扣费
                do_t_scene_war_fb_enter_fee(RoleID, RoleAttr, SwFbFeeRecord#r_sw_fb_fee.fb_fee, member);
           true ->
                RoleAttr
        end,
    SceneFbRecord2 = get_new_role_sw_fb_record(RoleMapInfo,SwFbMcmRecord,Times,SceneFbRecord,FbId,FbSecond),
    db:write(?DB_SCENE_WAR_FB,SceneFbRecord2,write),
    {ok, RoleMapInfo, RoleAttr2, SceneFbRecord2, SwFbFeeRecord, Times+1}.
%% ================== end ==========================================================================================
%% 初始化进入副本
asyn_enter({Unique, Module, Method, DataRecord, RoleID, PId}, RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord) ->
    FbSecond = common_tool:now(),
    log_async_create_map({RoleID, DataRecord#m_scene_war_fb_enter_tos.fb_type, DataRecord#m_scene_war_fb_enter_tos.fb_level}, 
                         {{Unique, Module, Method, DataRecord, RoleID, PId}, RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord, FbSecond}),
    FbMapProcessName = get_scene_war_fb_map_process_name(RoleID, FbSecond),
    case global:whereis_name(FbMapProcessName) of
        undefined ->
            mod_map_copy:async_create_copy(SwFbMcmRecord#r_sw_fb_mcm.fb_map_id, FbMapProcessName, ?MODULE, 
                                           {RoleID, DataRecord#m_scene_war_fb_enter_tos.fb_type, DataRecord#m_scene_war_fb_enter_tos.fb_level});
        _PID ->            
            do_async_scene_war_fb_enter({Unique, Module, Method, DataRecord, RoleID, PId}, RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord, FbSecond)
    end,
    ok.

log_async_create_map(Key, Info) ->
    erlang:put({mod_scene_war_fb, Key}, Info).
erase_async_create_map_info(Key) ->
    erlang:erase({mod_scene_war_fb, Key}).

%% 进入副本的下一步处理  根据是否存在副本来判断是进入副本还是创建副本
do_scene_war_fb_enter3({Unique, Module, Method, DataRecord, RoleID, PId},
                       RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord) ->
    case DataRecord#m_scene_war_fb_enter_tos.fb_id =/= 0 of
        true ->
            case db:transaction(
                   fun() -> 
						   %% 如果是进入副本走这里
                           do_t_scene_war_fb_enter(RoleID,DataRecord,RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord)
                   end) of
                {atomic,{ok,OpType,RoleAttr,TeamRoleIdList,SceneFbRecord,FbTimes,SwFbFeeRecord}} ->
                    do_scene_war_fb_enter4({Unique, Module, Method, DataRecord, RoleID, PId},
                                           RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord,OpType,RoleAttr,
                                           TeamRoleIdList,SceneFbRecord,SwFbFeeRecord,FbTimes);
                {aborted, Error} ->
                    case Error of
                        {Reason, ReasonCode} ->
                            do_scene_war_fb_enter_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode);
                        _ ->
                            ?ERROR_MSG("~ts,RoleID=~w,Error=~w",["进入场景大战副本出错",RoleID,Error]),
                            Reason2 = ?_LANG_SCENE_WAR_FB_ENTER_ERROR,
                            do_scene_war_fb_enter_error({Unique, Module, Method, DataRecord, PId},Reason2,0)
                    end
            end;
        false ->
            %% 先检查费用，再异步创建地图
            asyn_enter({Unique, Module, Method, DataRecord, RoleID, PId}, RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord)
    end.
%% =====================================初始化场景的东西 ======================================
%% 组队的且同时进入的副本  场景初始化
do_scene_war_fb_enter4({Unique, Module, Method, DataRecord, RoleID, PId},
                       SwFbMcmRecord, FbMapProcessName, TeamId, TeamRoleIdList, MemberEnterInfo) ->
    #m_scene_war_fb_enter_tos{fb_type=FbType, fb_level=FbLevel, npc_id=NpcId} = DataRecord,
    {LeaderSceneFbRecord, LeaderSwFeeRecord, LeaderFbTimes, MapInfoList, SceneFbRecordList} =
        lists:foldl(
          fun({MemberRoleId, MemberMapInfo,  _, MemberSceneFbRecord, MemberSwFbFeeRecord, MemberTimes}, 
              {TLSceneFbRecord, TLFbFeeRecord, TFbTimes, TMapInfoList, TFbRecordList}) ->
                  if MemberRoleId =:= RoleID ->
                          {MemberSceneFbRecord, MemberSwFbFeeRecord, MemberTimes, [MemberMapInfo|TMapInfoList], [MemberSceneFbRecord|TFbRecordList]};
                     true ->
                          {TLSceneFbRecord, TLFbFeeRecord, TFbTimes, [MemberMapInfo|TMapInfoList], [MemberSceneFbRecord|TFbRecordList]}
                  end
          end, {undefined, undefined, undefined, [], []}, MemberEnterInfo),
    #r_scene_war_fb{fb_id=FbId, fb_seconds=FbSeconds, start_time=StartTime} = LeaderSceneFbRecord,
    %% 更新入口地图进程字典信息
    MapId = mgeem_map:get_mapid(),
    SwFbEnterDictList = get_sw_fb_enter_dict(MapId),
    SwFbEnterDictList2 = 
        [#r_sw_fb_enter_dict{fb_id=FbId,
                             fb_seconds=FbSeconds,
                             fb_status=?SCENE_WAR_FB_FB_STATUS_RUNNING,
                             fb_type=FbType,
                             fb_level=FbLevel,
                             team_id=TeamId,
                             team_role_ids=TeamRoleIdList,
                             in_role_ids=TeamRoleIdList}|SwFbEnterDictList],
    put_sw_fb_enter_dict(MapId, SwFbEnterDictList2),
    %% 初始化副本进程字典消息
    [CloseSeconds] = common_config_dyn:find(scene_war_fb, scene_war_fb_close_seconds),
    SwFbDict = #r_sw_fb_dict{fb_id=FbId,
                             fb_seconds=FbSeconds,
                             fb_status=?SCENE_WAR_FB_FB_STATUS_CREATE,
                             fb_type=FbType,
                             fb_level=FbLevel,
                             team_id=TeamId,
                             team_role_ids=TeamRoleIdList,
                             in_role_ids=TeamRoleIdList,
                             start_time=StartTime,
                             end_time=StartTime + SwFbMcmRecord#r_sw_fb_mcm.max_seconds,
                             enter_fb_map_id=MapId,
                             scene_war_fb=SceneFbRecordList,
                             monster_number = SwFbMcmRecord#r_sw_fb_mcm.monster_number,
                             close_seconds = CloseSeconds,
                             born_monster = SwFbMcmRecord#r_sw_fb_mcm.born_monster,
                             born_elite = SwFbMcmRecord#r_sw_fb_mcm.born_elite
							 },
    catch global:send(FbMapProcessName, {mod_scene_war_fb,{create_sw_fb_info,SwFbDict}}),
	%% 创建怪物
	hook_create_monster(FbMapProcessName,SwFbMcmRecord,MapInfoList),
    SendSelf = #m_scene_war_fb_enter_toc{succ = true,
                                         return_self = true,
                                         fb_fee = LeaderSwFeeRecord#r_sw_fb_fee.fb_fee,
                                         fb_type = FbType,
                                         fb_level = FbLevel,
                                         npc_id = NpcId,
                                         fb_id = FbId,
                                         fb_seconds = FbSeconds,
                                         fb_times = LeaderFbTimes},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    case FbType =:= ?SCENE_WAR_FB_TYPE_DXWL of
        true ->
            %% 特殊任务事件
			mgeer_role:send(RoleID, {apply, hook_mission_event, 
				hook_special_event, [RoleID,?MISSON_EVENT_FB_TYPE_5]});
        _ ->
            ignore
    end,
    FbMapId = SwFbMcmRecord#r_sw_fb_mcm.fb_map_id,
    {DestTx,DestTy} = get_sw_fb_map_born_point(FbMapId),
    lists:foreach(
      fun({MemberRoleId, _, MemberAttr, _, MemberSwFbFeeRecord, _MemberTimes}) ->
              catch do_notify_role_fee_change(MemberRoleId, MemberAttr, MemberSwFbFeeRecord),
              case common_config_dyn:find(?SCENE_WAR_FB_CONFIG, {today_activity_id, FbType}) of
                  [] ->
                      ignore;
                  [TodayActivityId] ->
                      hook_activity_task:done_task(MemberRoleId, TodayActivityId)
              end,
              %% 切换地图
              set_map_enter_tag(MemberRoleId,FbMapProcessName),
              mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_SCENE_WAR_FB, MemberRoleId, FbMapId, DestTx, DestTy)
      end, MemberEnterInfo).
                     
%% 不一定组队的初始化    队长进入也是走这条，队员进入也是走这条...
%% 区别在于进入方式不同...
do_scene_war_fb_enter4({Unique, Module, Method, DataRecord, RoleID, PId},
                       RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord,OpType,RoleAttr,
                       TeamRoleIdList,SceneFbRecord,SwFbFeeRecord,FbTimes) ->
    %% 场景大战副本入口地图进程字典消息
    SwFbEnterDictList = get_sw_fb_enter_dict(mgeem_map:get_mapid()),
    SwFbEnterDictList2 = 
        case OpType of
            ?SCENE_WAR_FB_ENTER_FB_TYPE_CREATE ->
                InRoleIdList = [RoleID],
                [#r_sw_fb_enter_dict{fb_id = SceneFbRecord#r_scene_war_fb.fb_id,
                                    fb_seconds = SceneFbRecord#r_scene_war_fb.fb_seconds,
                                    fb_status = ?SCENE_WAR_FB_FB_STATUS_RUNNING,
                                    fb_type = SceneFbRecord#r_scene_war_fb.fb_type,
                                    fb_level = SceneFbRecord#r_scene_war_fb.fb_level,
                                    team_id = SceneFbRecord#r_scene_war_fb.team_id,
                                    team_role_ids = TeamRoleIdList,
                                    in_role_ids = [RoleID]} | SwFbEnterDictList];
            ?SCENE_WAR_FB_ENTER_FB_TYPE_JOIN ->
                {SwFbEnterDictListT,InRoleIdList} = 
                    lists:foldl(
                      fun(SwFbEnterDictT,{AccSwFbEnterDictList,AccInRoleIdList}) ->
                              if SwFbEnterDictT#r_sw_fb_enter_dict.fb_id =:= SceneFbRecord#r_scene_war_fb.fb_id
                                 andalso SwFbEnterDictT#r_sw_fb_enter_dict.fb_seconds =:= SceneFbRecord#r_scene_war_fb.fb_seconds ->
                                      InRoleIdListT = SwFbEnterDictT#r_sw_fb_enter_dict.in_role_ids,
                                      SwFbEnterDictT2 = SwFbEnterDictT#r_sw_fb_enter_dict{in_role_ids = [RoleID | lists:delete(RoleID,InRoleIdListT)]},
                                      {[SwFbEnterDictT2|AccSwFbEnterDictList],SwFbEnterDictT2#r_sw_fb_enter_dict.in_role_ids};
                                 true ->
                                      {[SwFbEnterDictT|AccSwFbEnterDictList],AccInRoleIdList}
                              end
                      end,{[],[]},SwFbEnterDictList),
                SwFbEnterDictListT
        end,
    put_sw_fb_enter_dict(mgeem_map:get_mapid(),SwFbEnterDictList2),
    do_scene_war_fb_enter5({Unique, Module, Method, DataRecord, RoleID, PId},
                           RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord,OpType,RoleAttr,
                           TeamRoleIdList,SceneFbRecord,SwFbFeeRecord,FbTimes,InRoleIdList).
do_scene_war_fb_enter5({Unique, Module, Method, DataRecord, RoleID, PID},
                       RoleMapInfo,_SwFbNpcRecord,SwFbMcmRecord,OpType,RoleAttr,
                       TeamRoleIdList,SceneFbRecord,SwFbFeeRecord,FbTimes,InRoleIdList) ->
    %% 当前创建的副本地图的进程字典信息
    FbMapProcessName = SceneFbRecord#r_scene_war_fb.fb_map_name,
    [CloseSeconds] = common_config_dyn:find(scene_war_fb, scene_war_fb_close_seconds),
    case OpType of
        ?SCENE_WAR_FB_ENTER_FB_TYPE_CREATE ->
            SwFbDict = #r_sw_fb_dict{
                                     fb_id = SceneFbRecord#r_scene_war_fb.fb_id,
                                     fb_seconds = SceneFbRecord#r_scene_war_fb.fb_seconds,
                                     fb_status = ?SCENE_WAR_FB_FB_STATUS_CREATE,
                                     fb_type = SceneFbRecord#r_scene_war_fb.fb_type,
                                     fb_level = SceneFbRecord#r_scene_war_fb.fb_level,
                                     team_id = SceneFbRecord#r_scene_war_fb.team_id,
                                     team_role_ids = TeamRoleIdList,in_role_ids = [RoleID],
                                     start_time = SceneFbRecord#r_scene_war_fb.start_time,
                                     end_time = SceneFbRecord#r_scene_war_fb.start_time + SwFbMcmRecord#r_sw_fb_mcm.max_seconds,
                                     enter_fb_map_id = mgeem_map:get_mapid(),
                                     scene_war_fb = [SceneFbRecord],
                                     monster_number = SwFbMcmRecord#r_sw_fb_mcm.monster_number,
                                     close_seconds = CloseSeconds,
                                     born_monster = SwFbMcmRecord#r_sw_fb_mcm.born_monster,
                                     born_elite = SwFbMcmRecord#r_sw_fb_mcm.born_elite},
            catch global:send(FbMapProcessName, {mod_scene_war_fb,{create_sw_fb_info,SwFbDict}}),
			hook_create_monster(FbMapProcessName,SwFbMcmRecord,[RoleMapInfo]);
        ?SCENE_WAR_FB_ENTER_FB_TYPE_JOIN ->
            catch global:send(FbMapProcessName, {mod_scene_war_fb,{create_sw_fb_info,SceneFbRecord}})
    end,
    %% 进入场景副本成功请求
    SendSelf = #m_scene_war_fb_enter_toc{succ = true,return_self = true,
                                         fb_fee = SwFbFeeRecord#r_sw_fb_fee.fb_fee,
                                         fb_type = DataRecord#m_scene_war_fb_enter_tos.fb_type,
                                         fb_level = DataRecord#m_scene_war_fb_enter_tos.fb_level,
                                         npc_id = DataRecord#m_scene_war_fb_enter_tos.npc_id,
                                         fb_id = SceneFbRecord#r_scene_war_fb.fb_id,
                                         fb_seconds = SceneFbRecord#r_scene_war_fb.fb_seconds,
                                         fb_times = FbTimes},
    ?UNICAST_TOC(SendSelf),
    
    catch do_notify_role_fee_change(RoleID,RoleAttr,SwFbFeeRecord),
    if OpType =:= ?SCENE_WAR_FB_ENTER_FB_TYPE_CREATE ->
           catch do_notify_team_member(RoleID,Module,Method,DataRecord,SceneFbRecord,SwFbMcmRecord,TeamRoleIdList,InRoleIdList);
       true ->
           next
    end,
    %% 切换地图
    FbMapId = SwFbMcmRecord#r_sw_fb_mcm.fb_map_id,
    %% 记录活动参与次数
    case common_config_dyn:find(?SCENE_WAR_FB_CONFIG, {today_activity_id, SceneFbRecord#r_scene_war_fb.fb_type}) of
        [] ->
            ignore;
        [TodayActivityId] ->
            hook_activity_task:done_task(RoleID, TodayActivityId)
    end,
    case SceneFbRecord#r_scene_war_fb.fb_type =:= ?SCENE_WAR_FB_TYPE_DXWL of
        true ->
            %% 特殊任务事件
			mgeer_role:send(RoleID, {apply, hook_mission_event, 
				hook_special_event, [RoleID, ?MISSON_EVENT_FB_TYPE_5]});
        _ ->
            ignore
    end,
    put_enter_sw_fb_info(RoleID,FbMapId,FbMapProcessName).

%% =============================================================================================
hook_create_monster(FbMapProcessName,SwFbMcmRecord,MapInfoList)->
	case SwFbMcmRecord#r_sw_fb_mcm.born_monster of
		?SCENE_WAR_FB_BORN_MONSTER_AUTO ->
			ignore;
		?SCENE_WAR_FB_BORN_MONSTER_DYNAMIC->
			?TRY_CATCH(global:send(FbMapProcessName, {mod_scene_war_fb, {init_sw_monster,get_team_average_level(MapInfoList,SwFbMcmRecord#r_sw_fb_mcm.fb_type)}}),Err);
		?SCENE_WAR_FB_BORN_MONSTER_CALL->
            ignore
	end.
	
put_enter_sw_fb_info(RoleID,FbMapId,FbMapProcessName) ->
    set_map_enter_tag(RoleID,FbMapProcessName),
    {DestTx,DestTy} = get_sw_fb_map_born_point(FbMapId),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_SCENE_WAR_FB, RoleID, FbMapId, DestTx, DestTy).

%% 场景大战副本费用变化通知
do_notify_role_fee_change(RoleID,RoleAttr,SwFbFeeRecord) ->
    if SwFbFeeRecord#r_sw_fb_fee.fb_fee =/= 0 ->
            UnicastArg = {role, RoleID},
            AttrChangeList = [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value = RoleAttr#p_role_attr.gold},
                              #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value = RoleAttr#p_role_attr.gold_bind}],
            common_misc:role_attr_change_notify(UnicastArg,RoleID,AttrChangeList);
       true ->
            ignore
    end.
%% 队员
do_notify_team_member(RoleID,Module,Method,DataRecord,SceneFbRecord,SwFbMcmRecord,TeamRoleIdList,InRoleIdList) ->
    %% 查询在周周围的队伍，通知其是否一起进入此等级的副本
    #m_scene_war_fb_enter_tos{npc_id = NpcId,fb_type = FbType,fb_level = FbLevel} = DataRecord,
    SendMember = #m_scene_war_fb_enter_toc{succ = true,return_self = false,npc_id = NpcId,
                                           fb_type = FbType,fb_level = FbLevel,
                                           fb_id = SceneFbRecord#r_scene_war_fb.fb_id,
                                           fb_seconds = SceneFbRecord#r_scene_war_fb.fb_seconds},
    TeamRoleIdList2 = lists:delete(RoleID,TeamRoleIdList),
    BcMessage = common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_NOT_VALID_MAP,
                                                      [NpcId,SwFbMcmRecord#r_sw_fb_mcm.fb_name,
                                                       SwFbMcmRecord#r_sw_fb_mcm.fb_level_name]),
    BcTimesMessage = common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_NOT_VALID_MAP_TIMES,
                                                      [SwFbMcmRecord#r_sw_fb_mcm.fb_name,
                                                       SwFbMcmRecord#r_sw_fb_mcm.fb_level_name]),
    if SceneFbRecord#r_scene_war_fb.team_id =/= 0 ->
            lists:foreach(
              fun(MemberRoleId) ->
                      case lists:member(MemberRoleId,InRoleIdList) of
                          true ->
                              next;
                          false ->
                              SceneWarFbRecord = 
                                  case db:dirty_read(?DB_SCENE_WAR_FB,MemberRoleId) of
                                      [] ->
                                          undefined;
                                      [SceneWarFbRecordT] ->
                                          SceneWarFbRecordT
                                  end,
                              FbTimes = get_sw_fb_times(FbType,SceneWarFbRecord),
                              {EnterFee,MaxTimes} = 
                                  case get_sw_fb_fee(FbType,FbTimes + 1) of
                                      {error,max_times,MaxTimesT} ->
                                          {0,MaxTimesT};
                                      {error,_Error} ->
                                          {0,0};
                                      {ok,#r_sw_fb_fee{fb_fee = EnterFeeT}} ->
                                          {EnterFeeT,0}
                                  end,
                              CurFbTimes = if MaxTimes =/= 0 -> MaxTimes; true -> FbTimes + 1 end,
                              %% 先处理只在本地图通知传送进入
                              case mod_map_actor:get_actor_mapinfo(MemberRoleId,role) of
                                  undefined ->
                                      if MaxTimes =/= 0 ->
                                              catch common_broadcast:bc_send_msg_role(MemberRoleId,[?BC_MSG_TYPE_SYSTEM,?BC_MSG_TYPE_CENTER],BcTimesMessage);
                                         true ->
                                              catch common_broadcast:bc_send_msg_role(MemberRoleId,[?BC_MSG_TYPE_SYSTEM,?BC_MSG_TYPE_CENTER],BcMessage)
                                      end;
                                  _ ->
                                      SendMember2 = SendMember#m_scene_war_fb_enter_toc{fb_fee = EnterFee,fb_times = CurFbTimes,fb_max_times = MaxTimes},
                                      catch common_misc:unicast(common_role_line_map:get_role_line(MemberRoleId), 
                                                                MemberRoleId, ?DEFAULT_UNIQUE, Module, Method, SendMember2)
                              end
                      end
              end,TeamRoleIdList2);
       true ->
            next
    end.

do_scene_war_fb_enter_error({Unique, Module, Method, DataRecord, PID},Reason,ReasonCode) ->
    #m_scene_war_fb_enter_tos{npc_id = NpcId,fb_type = FbType,fb_level = FbLevel} = DataRecord,
    SendSelf = #m_scene_war_fb_enter_toc{
      succ = false,
      return_self = true,
      npc_id = NpcId,
      fb_type = FbType,
      fb_level = FbLevel,
      reason = Reason,
      reason_code = ReasonCode},
    ?UNICAST_TOC(SendSelf).

%% 就只有玩家是fb_id=/=0 走这里
do_t_scene_war_fb_enter(RoleID,DataRecord,RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord) ->
    %% 检查是否队长
    if DataRecord#m_scene_war_fb_enter_tos.fb_id =:= 0 
       andalso RoleMapInfo#p_map_role.team_id =/= 0 ->
           case mod_map_team:get_role_team_info(RoleID) of
               {ok,MapTeamInfo} ->
                   case RoleID =:= mod_map_team:get_team_leader_role_id(MapTeamInfo#r_role_team.role_list) of
                       true ->
                           next;
                       _ ->
                           db:abort({?_LANG_SCENE_WAR_FB_ENTER_NOT_LEADER,0})
                   end;
               _ ->
                   db:abort({?_LANG_SCENE_WAR_FB_ENTER_NOT_LEADER,0})
           end;
       true ->
           next
    end,
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    SceneFbRecord = 
        case db:read(?DB_SCENE_WAR_FB,RoleID) of
            [] ->
                undefined;
            [SceneFbRecordT] ->
                SceneFbRecordT
        end,
    #r_sw_fb_mcm{fb_type = FbType} = SwFbMcmRecord,
    Times = get_sw_fb_times(FbType,SceneFbRecord),
    SwFbFeeRecord = 
        case get_sw_fb_fee(FbType,Times + 1) of
            {ok,SwFbFeeRecoedT} ->
                SwFbFeeRecoedT;
            {error,max_times,MaxTimes} ->
                db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MAX_TIME,MaxTimes),0});
            {error,not_found_fee} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_ERROR,0});
            {error,not_found} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_ERROR,0})
        end,
    if SwFbFeeRecord#r_sw_fb_fee.fb_fee =/= 0 -> %% 需要扣费
            RoleAttr2 = do_t_scene_war_fb_enter_fee(RoleID,RoleAttr,SwFbFeeRecord#r_sw_fb_fee.fb_fee);
       true ->
            RoleAttr2 = RoleAttr
    end,
    %% 当进入别人创建的副本时，需要检查副本当前是否允许进入
    do_t_scene_war_fb_enter2(RoleID,DataRecord,RoleMapInfo,SwFbNpcRecord,SwFbMcmRecord,
                             RoleAttr2,SwFbFeeRecord,Times,SceneFbRecord).

do_t_scene_war_fb_enter_fee(RoleID,RoleAttr,Fee) ->
    do_t_scene_war_fb_enter_fee(RoleID, RoleAttr, Fee, self).

do_t_scene_war_fb_enter_fee(_RoleID, RoleAttr, _Fee, _Type) -> RoleAttr.
    % #p_role_attr{role_name=RoleName, gold = Gold,gold_bind = GoldBind} = RoleAttr,
    % if (Gold + GoldBind) < Fee ->
    %         if Type =:= self ->
    %                 db:abort({?_LANG_SCENE_WAR_FB_ENTER_NOT_GOLD,?SCENE_WAR_FB_RETURN_CODE_NOT_GOLD});
    %            true ->
    %                 db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MEMBER_NOT_GOLD, RoleName), 0})
    %         end;
    %    true ->
    %         next
    % end,
    % if GoldBind < Fee ->
    %         NewGold = Gold - (Fee - GoldBind),
    %         if NewGold < 0 ->
    %                 if Type =:= self ->
    %                         db:abort({?_LANG_SCENE_WAR_FB_ENTER_NOT_GOLD,?SCENE_WAR_FB_RETURN_CODE_NOT_GOLD});
    %                    true ->
    %                         db:abort({common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_ENTER_MEMBER_NOT_GOLD, RoleName), 0})
    %                 end;
    %            true ->
    %                 common_consume_logger:use_gold({RoleID, GoldBind, (Fee - GoldBind), ?CONSUME_TYPE_GOLD_SCENE_WAR_FB, ""}),
    %                 RoleAttr2 = RoleAttr#p_role_attr{gold= NewGold,gold_bind=0 },
    %                 mod_map_role:set_role_attr(RoleID,RoleAttr2),
    %                 RoleAttr2
    %         end;
    %    true ->
    %         common_consume_logger:use_gold({RoleID, Fee, 0, ?CONSUME_TYPE_GOLD_SCENE_WAR_FB, ""}),
    %         NewGoldBind = GoldBind - Fee,
    %         RoleAttr2 = RoleAttr#p_role_attr{gold_bind=NewGoldBind},
    %         mod_map_role:set_role_attr(RoleID, RoleAttr2),
    %         RoleAttr2
    % end.

%% 当进入别人创建的副本时，需要检查副本当前是否允许进入
do_t_scene_war_fb_enter2(RoleID,DataRecord,RoleMapInfo,_SwFbNpcRecord,SwFbMcmRecord,
                         RoleAttr,SwFbFeeRecord,Times,SceneFbRecord) ->
    %% must_team
    case SwFbMcmRecord#r_sw_fb_mcm.must_team of
        ?SCENE_WAR_FB_TEAM_LEVEL_ONE -> 
            next;
        _->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_VALID,0})
    end,
    #m_scene_war_fb_enter_tos{fb_id = FbId,fb_seconds = FbSeconds} = DataRecord,
    case global:whereis_name(get_scene_war_fb_map_process_name(FbId,FbSeconds))of
        undefined ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_CLOSE,0});
        _ ->
            next
    end,
    SwFbEnterList = get_sw_fb_enter_dict(mgeem_map:get_mapid()),
    SwFbEnterDictRecord = 
        case lists:foldl(
               fun(SwFbEnterDictRecordT,{AccSwFbEnterFlag,AccSwFbEnterRecord}) ->
                       if AccSwFbEnterFlag =:= false 
                          andalso FbId =:= SwFbEnterDictRecordT#r_sw_fb_enter_dict.fb_id
                          andalso FbSeconds =:= SwFbEnterDictRecordT#r_sw_fb_enter_dict.fb_seconds
                          andalso RoleMapInfo#p_map_role.team_id =:= SwFbEnterDictRecordT#r_sw_fb_enter_dict.team_id ->
                               case lists:member(RoleID,SwFbEnterDictRecordT#r_sw_fb_enter_dict.team_role_ids) of
                                   true ->
                                       {true,SwFbEnterDictRecordT};
                                   false ->
                                       {false,after_create_fb}
                               end;
                          true ->
                               {AccSwFbEnterFlag,AccSwFbEnterRecord}
                       end
               end,{false,undefined},SwFbEnterList) of
            {true,SwFbEnterDictRecordTT} ->
                SwFbEnterDictRecordTT;
            {false,undefined} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_RECORD,0});
            {false,after_create_fb} ->
                db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_AFTER,0})
        end,
    case lists:member(RoleID,SwFbEnterDictRecord#r_sw_fb_enter_dict.in_role_ids) of
        true -> %% 此玩家已经进入过副本，可能由于掉线或自己主动退出，不可以在进入此副本
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_AGAIN,0});
        false ->
            next
    end,
    NowSeconds = common_tool:now(),
    if NowSeconds > (FbSeconds + SwFbMcmRecord#r_sw_fb_mcm.valid_seconds) ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_VALID,0});
       true ->
            next
    end,
    if SwFbEnterDictRecord#r_sw_fb_enter_dict.fb_status =:= ?SCENE_WAR_FB_FB_STATUS_RUNNING ->
            next;
        SwFbEnterDictRecord#r_sw_fb_enter_dict.fb_status =:= ?SCENE_WAR_FB_FB_STATUS_CLOSE ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_STATUS,0});
       true ->
            db:abort({?_LANG_SCENE_WAR_FB_ENTER_MEMBER_FB_STATUS,0})
    end,
    SceneFbRecord2 = get_new_role_sw_fb_record(RoleMapInfo,SwFbMcmRecord,Times,SceneFbRecord,
                                               SwFbEnterDictRecord#r_sw_fb_enter_dict.fb_id,
                                               SwFbEnterDictRecord#r_sw_fb_enter_dict.fb_seconds),
    db:write(?DB_SCENE_WAR_FB,SceneFbRecord2,write),
    {ok,?SCENE_WAR_FB_ENTER_FB_TYPE_JOIN,RoleAttr,
     SwFbEnterDictRecord#r_sw_fb_enter_dict.team_role_ids,SceneFbRecord2,
     Times + 1,SwFbFeeRecord}.

%% 获得玩家新的副本信息 Times 会加1
%% RoleMapInfo p_map_role
%% SwFbMcmRecord r_sw_fb_mcm
%% SceneFbRecord r_scene_war_fb
get_new_role_sw_fb_record(RoleMapInfo,SwFbMcmRecord,Times,SceneFbRecord,FbId,FbSeconds) ->
    %% 玩家每一次玩场景大战副本
    StartTime = 
        if  RoleMapInfo#p_map_role.role_id =:= FbId ->
                FbSeconds;
            true ->
                common_tool:now()
        end,
    case SceneFbRecord of
        undefined ->
            FbInfoList = [#r_scene_war_fb_info{times = Times + 1,
                                               fb_type = SwFbMcmRecord#r_sw_fb_mcm.fb_type}],
            #r_scene_war_fb{
                           role_id = RoleMapInfo#p_map_role.role_id,
                           role_name = RoleMapInfo#p_map_role.role_name,
                           faction_id = RoleMapInfo#p_map_role.faction_id,
                           level = RoleMapInfo#p_map_role.level,
                           team_id = RoleMapInfo#p_map_role.team_id,
                           status = ?SCENE_WAR_FB_FB_STATUS_CREATE,
                           start_time = StartTime,end_time = 0,
                           map_id = mgeem_map:get_mapid(),
                           pos = RoleMapInfo#p_map_role.pos,
                           fb_type = SwFbMcmRecord#r_sw_fb_mcm.fb_type,
                           fb_level = SwFbMcmRecord#r_sw_fb_mcm.fb_level,
                           fb_map_name = get_scene_war_fb_map_process_name(FbId,FbSeconds),
                           fb_id = FbId,fb_seconds = FbSeconds,fb_info = FbInfoList};
        _ ->
            FbInfoList = get_new_role_sw_fb_info_list(SwFbMcmRecord#r_sw_fb_mcm.fb_type, SceneFbRecord),
            SceneFbRecord#r_scene_war_fb{
              team_id = RoleMapInfo#p_map_role.team_id,
              status = ?SCENE_WAR_FB_FB_STATUS_CREATE,
              level = RoleMapInfo#p_map_role.level,
              start_time = StartTime,end_time = 0,
              map_id = mgeem_map:get_mapid(),
              pos = RoleMapInfo#p_map_role.pos,
              fb_type = SwFbMcmRecord#r_sw_fb_mcm.fb_type,
              fb_level = SwFbMcmRecord#r_sw_fb_mcm.fb_level,
              fb_map_name = get_scene_war_fb_map_process_name(FbId,FbSeconds),
              fb_id = FbId,fb_seconds = FbSeconds,fb_info = FbInfoList}
    end.

%% 退出副本
%% DataRecord 结构为 m_scene_war_fb_quit_tos
do_scene_war_fb_quit({Unique, Module, Method, DataRecord, RoleID, PId}) ->
    case catch do_scene_war_fb_quit2(RoleID, DataRecord) of
        {error, Reason, ReasonCode} ->
            do_scene_war_fb_quit_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode);
        {ok,CurMapId,RoleMapInfo} ->
            do_scene_war_fb_quit3({Unique, Module, Method, DataRecord, RoleID, PId},
                                  CurMapId,RoleMapInfo)
    end.
do_scene_war_fb_quit2(RoleID, DataRecord) ->
    _NpcId = DataRecord#m_scene_war_fb_quit_tos.npc_id,
    CurMapId = mgeem_map:get_mapid(),
    [SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
    case lists:keyfind(CurMapId,#r_sw_fb_mcm.fb_map_id,SwFbMcmList) of
        false ->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_QUIT_ERROR,0});
        _ ->
            next
    end,
    RoleMapInfo = 
        case mod_map_actor:get_actor_mapinfo(RoleID,role) of
            undefined ->
                erlang:throw({error,?_LANG_SCENE_WAR_FB_QUIT_ERROR,0});
            RoleMapInfoT ->
                RoleMapInfoT
        end,
    %% 检查玩家是否在NPC附近
    %% del by caochuncheng 2011-09-28 退出副本不需要判断是否在NPC附近
%%     case catch check_valid_distance(NpcId,RoleMapInfo) of
%%         true ->
%%             next;
%%         _ ->
%%             ?DEBUG("~ts",["玩家不在NPC附近，无法操作"]),
%%             erlang:throw({error,?_LANG_SCENE_WAR_FB_NOT_VALID_DISTANCE,0})
%%     end,
    {ok,CurMapId,RoleMapInfo}.
do_scene_war_fb_quit3({Unique, Module, Method, DataRecord, RoleID, PID},
                      CurMapId,RoleMapInfo) ->
    %% TODO 需要记录玩家的副本日志
    do_role_sw_fb_log([RoleID]),
    SwFbDictRecord = get_sw_fb_dict(CurMapId),
    #r_sw_fb_dict{fb_type = FbType,fb_level = FbLevel,
                  scene_war_fb = SceneWarFbList} = SwFbDictRecord,
    SendSelf = #m_scene_war_fb_quit_toc{
      succ = true,
      npc_id = DataRecord#m_scene_war_fb_quit_tos.npc_id,
      fb_type =FbType,
      fb_level = FbLevel},
    ?UNICAST_TOC(SendSelf),
    
    case lists:keyfind(RoleID,#r_scene_war_fb.role_id,SceneWarFbList) of
        false -> %% 查找不到，直接回京城
            HomeMapId = common_misc:get_home_map_id(RoleMapInfo#p_map_role.faction_id),
            {HomeMapId,HomeTx,HomeTy} = common_misc:get_born_info_by_map(HomeMapId),
            mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, HomeMapId, HomeTx, HomeTy);
        #r_scene_war_fb{map_id = DestMapId,pos = DestPos} ->
            #p_pos{tx=DestTx,ty = DestTy} = DestPos,
            mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID,DestMapId,DestTx,DestTy)
    end.

%%退出场景大战副本返回结果
do_scene_war_fb_quit_error({Unique, Module, Method, DataRecord, PID},Reason,ReasonCode) ->
    SendSelf = #m_scene_war_fb_quit_toc{
      npc_id = DataRecord#m_scene_war_fb_quit_tos.npc_id,
      succ = false,
      reason = Reason,
      reason_code = ReasonCode},
    ?UNICAST_TOC(SendSelf).

%% 玩家召唤怪物  
do_scene_war_fb_call_monster({Unique, Module, Method, DataRecord, RoleID, PId})->
	case catch check_can_call_monster(RoleID,DataRecord) of
		{ok,MonsterKey} ->
            do_init_sw_monster(MonsterKey);
		{error, Reason, ReasonCode}->
			do_scene_war_fb_call_monster_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode)
	end.
%% 是否可以召唤怪物检查
check_can_call_monster(RoleID,DataRecord)->
    #m_scene_war_fb_call_monster_tos{npc_id=NpcID,
                                     pass_id =DestPassID}=DataRecord,
    [SwFbMcmConfig] =common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
    CurMapId = mgeem_map:get_mapid(),
    SwFbMcm =
    case lists:keyfind(CurMapId, #r_sw_fb_mcm.fb_map_id, SwFbMcmConfig) of
        false->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_NOT_CALL_MONSTER_TYPE});
        _SwFbMcm->
            _SwFbMcm
    end,
    
    RoleMapInfo = 
        case mod_map_actor:get_actor_mapinfo(RoleID,role) of
            undefined ->
                erlang:throw({error,?_LANG_SCENE_WAR_FB_QUERY_ERROR,0});
            RoleMapInfoT ->
                RoleMapInfoT
        end,
    %% 检查玩家是否在NPC附近
    case check_valid_distance(CurMapId,NpcID,RoleMapInfo) of
        true ->
            next;
        false ->
            ?DEBUG("~ts",["玩家不在NPC附近，无法操作"]),
            erlang:throw({error,?_LANG_SCENE_WAR_FB_NOT_VALID_DISTANCE,0})
    end,
    
    %% 地图是否能召唤怪物
    SwFbDictRecord = get_sw_fb_dict(CurMapId),
    case SwFbMcm#r_sw_fb_mcm.fb_type =:=SwFbDictRecord#r_sw_fb_dict.fb_type 
        andalso SwFbMcm#r_sw_fb_mcm.fb_level =:=SwFbDictRecord#r_sw_fb_dict.fb_level
        andalso SwFbDictRecord#r_sw_fb_dict.born_monster =:=?SCENE_WAR_FB_BORN_MONSTER_CALL of
        true->
            next;
        false->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_QUERY_ERROR,0})
    end,
    %% 地图是否没有怪
    MonsterNum = erlang:length(mod_map_monster:get_monster_id_list()),
    case MonsterNum >0 of
        true->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_MONSTER_NOT_CLEAR,0});
        false->
            next
    end,

    %% 请求的关卡是否有效
    SwFbCallMonsterList=
        case common_config_dyn:find(?SCENE_WAR_FB_CONFIG, {sw_fb_call_monster,CurMapId}) of
            []->
                erlang:throw({error,?_LANG_SCENE_WAR_FB_NOT_CALL_MONSTER_TYPE,0});
            [_SwFbCallMonsterList]->
                _SwFbCallMonsterList
        end,
    %% 是否是下关的关卡
    case lists:keyfind(SwFbDictRecord#r_sw_fb_dict.cur_monster_key,#r_sw_fb_call_monster.pass_id,SwFbCallMonsterList) of
        false->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_NOT_CALL_MONSTER_TYPE,0});
        #r_sw_fb_call_monster{next_pass_id = NextPassID}->
            if NextPassID =:=DestPassID ->
                   {ok,DestPassID};
               true->
                   erlang:throw({error,?_LANG_SCENE_WAR_FB_NOT_REACH_PASS,0})
            end
    end.

do_scene_war_fb_call_monster_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode)->
	SendSelf = 
		#m_scene_war_fb_call_monster_toc{
										 succ = false,
										 npc_id = DataRecord#m_scene_war_fb_call_monster_tos.npc_id,
										 reason = Reason,
										 reason_code = ReasonCode},
	common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

%% 查询玩家副本信息
%% DataRecord 结构为 m_scene_war_fb_query_tos
do_scene_war_fb_query({Unique, Module, Method, DataRecord, RoleID, PId}) ->
    case catch check_do_scene_war_fb_query(RoleID, DataRecord) of 
        {error, Reason, ReasonCode} ->
            do_scene_war_fb_query_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode);
        {ok,RoleMapInfo,SwFbNpcList} ->
            do_scene_war_fb_query3({Unique, Module, Method, DataRecord, RoleID, PId},
                                   RoleMapInfo,SwFbNpcList)
    end.
check_do_scene_war_fb_query(RoleID, DataRecord) ->
    NpcId= DataRecord#m_scene_war_fb_query_tos.npc_id,
    [SwFbNpcList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_npc),
    CurMapId = mgeem_map:get_mapid(),
    SwFbNpcList2 = [SwFbNpcRecord || SwFbNpcRecord <- SwFbNpcList, 
                                     SwFbNpcRecord#r_sw_fb_npc.npc_id =:= NpcId,
                                     SwFbNpcRecord#r_sw_fb_npc.map_id =:= CurMapId],
    if SwFbNpcList2 =:= [] ->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_QUERY_ERROR,0});
       true ->
            next
    end,
    RoleMapInfo = assert_get_actor_mapinfo(RoleID),
    assert_valid_distance(CurMapId,NpcId,RoleMapInfo),
    
    {ok,RoleMapInfo,SwFbNpcList2}.

do_scene_war_fb_query3({Unique, Module, Method, DataRecord, RoleID, PID},
                       RoleMapInfo,SwFbNpcList) ->
    CurMapId = mgeem_map:get_mapid(),
    [SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
    SwFbEnterDictRecordList = 
        if RoleMapInfo#p_map_role.team_id =/= 0 -> %% 需要处理队伍情况
                CurTeamIdList = common_misc:team_get_team_member(RoleID),
                CurTeamIdList2 = lists:delete(RoleID,CurTeamIdList),
                case get_sw_fb_enter_dict(CurMapId) of
                    undefined ->
                        [];
                    [] ->
                        [];
                    SwFbEnterList ->
                        %% 这里需要处理队伍变化的情况
                        case lists:keyfind(RoleMapInfo#p_map_role.team_id,#r_sw_fb_enter_dict.team_id,SwFbEnterList) of
                            false ->
                                lists:foldl(
                                  fun(SwFbEnterRecordTT,AccSwFbEnterListT) ->
                                          case check_member_create_fb(SwFbEnterRecordTT,CurTeamIdList2,SwFbMcmList) of
                                              true ->
                                                  [SwFbEnterRecordTT | AccSwFbEnterListT];
                                              false ->
                                                  AccSwFbEnterListT
                                          end
                                  end,[],SwFbEnterList);
                            SwFbEnterRecordT ->
                                [SwFbEnterRecordT]
                        end
                end;
           true ->
                []
        end,
    SceneWarFbRecord = 
        case db:dirty_read(?DB_SCENE_WAR_FB,RoleID) of
            [] ->
                undefined;
            [SceneWarFbRecordT] ->
                SceneWarFbRecordT
        end,
    FbLinkList = get_p_scene_war_fb_link(SwFbEnterDictRecordList,SceneWarFbRecord,SwFbNpcList),
    SendSelf = #m_scene_war_fb_query_toc{
      succ = true,
      op_type = DataRecord#m_scene_war_fb_query_tos.op_type,
      npc_id = DataRecord#m_scene_war_fb_query_tos.npc_id,
      fb_links = FbLinkList},

    ?UNICAST_TOC(SendSelf).

%% 判断此队员的是否在此副本中
%% 返回 true or false
check_member_create_fb(SwFbEnterRecord,TeamMemberIdList,SwFbMcmList) ->
    #r_sw_fb_enter_dict{team_role_ids = FbTeamRoleIdList} = SwFbEnterRecord,
    lists:foldl(
      fun(MemberRoleId,AccFlag) ->
              case (AccFlag =:= false andalso lists:member(MemberRoleId,FbTeamRoleIdList) =:= true) of
                  true ->
                      case mod_map_role:get_role_pos_detail(MemberRoleId) of
                          {ok,#p_role_pos{map_id = MemberCurMapId}} ->
                              case lists:keyfind(MemberCurMapId,#r_sw_fb_mcm.fb_map_id,SwFbMcmList) of
                                  false ->
                                      false;
                                  _ ->
                                      true
                              end;
                          _ ->
                              false
                      end;
                  false ->
                      AccFlag
              end
      end,false,TeamMemberIdList).

%% 获取当前玩家打开的NPC面版的连接
%% 返回 [] or  [p_scene_war_fb_link,...]
get_p_scene_war_fb_link(SwFbEnterDictRecordList,SceneWarFbRecord,SwFbNpcList) ->
    SwFbNpcList2 = 
        case SwFbEnterDictRecordList of
            [] ->
                SwFbNpcList;
            _ ->
                SwFbNpcListT = 
                    lists:foldl(
                      fun(SwFbNpcRecordT,AccSwFbNpcRecordT) ->
                              case lists:foldl(
                                     fun(SwFbEnterDictRecord,AccSwFbEnterDictRecordFlag) ->
                                             if AccSwFbEnterDictRecordFlag =:= false 
                                                andalso SwFbNpcRecordT#r_sw_fb_npc.fb_type =:= SwFbEnterDictRecord#r_sw_fb_enter_dict.fb_type
                                                andalso SwFbNpcRecordT#r_sw_fb_npc.fb_level =:= SwFbEnterDictRecord#r_sw_fb_enter_dict.fb_level ->
                                                     true;
                                                true ->
                                                     AccSwFbEnterDictRecordFlag
                                             end
                                     end,false,SwFbEnterDictRecordList) of
                                  true ->
                                      [SwFbNpcRecordT|AccSwFbNpcRecordT];
                                  false ->
                                      AccSwFbNpcRecordT
                              end
                      end,[],SwFbNpcList),
                if SwFbNpcListT =/= [] ->
                        SwFbNpcListT;
                   true ->
                        SwFbNpcList
                end
        end,
    lists:map(
      fun(#r_sw_fb_npc{fb_type = FbType,fb_level = FbLevel}) ->
              FbTimes = get_sw_fb_times(FbType,SceneWarFbRecord),
              {EnterFee,MaxTimes} = 
                  case get_sw_fb_fee(FbType,FbTimes + 1) of
                      {error,max_times,MaxTimesT} ->
                          {0,MaxTimesT};
                      {error,_Error} ->
                          {0,get_sw_fb_max_times(FbType)};
                      {ok,#r_sw_fb_fee{fb_fee = EnterFeeT}} ->
                          {EnterFeeT,get_sw_fb_max_times(FbType)}
                  end,
              CurFbTimes =  FbTimes + 1,
              {_,FbId,FbSeconds} = 
                  lists:foldl(
                    fun(SwFbEnterDictRecordT,{AccFlag,AccFbId,AccFbSeconds}) ->
                            if AccFlag =:= false 
                               andalso FbType =:= SwFbEnterDictRecordT#r_sw_fb_enter_dict.fb_type
                               andalso FbLevel =:= SwFbEnterDictRecordT#r_sw_fb_enter_dict.fb_level ->
                                    {true,SwFbEnterDictRecordT#r_sw_fb_enter_dict.fb_id,SwFbEnterDictRecordT#r_sw_fb_enter_dict.fb_seconds};
                               true ->
                                    {AccFlag,AccFbId,AccFbSeconds}
                            end
                    end,{false,0,0},SwFbEnterDictRecordList),
              #p_scene_war_fb_link{fb_type = FbType,fb_level = FbLevel,
                                   fb_id = FbId,fb_seconds = FbSeconds,
                                   enter_fee = EnterFee,fb_times = CurFbTimes,fb_max_times = MaxTimes}
      end,SwFbNpcList2).
do_scene_war_fb_query_error({Unique, Module, Method, DataRecord, PId},Reason,ReasonCode) ->
    SendSelf = #m_scene_war_fb_query_toc{
      succ = false,
      op_type = DataRecord#m_scene_war_fb_query_tos.op_type,
      npc_id = DataRecord#m_scene_war_fb_query_tos.npc_id,
      reason = Reason,
      reason_code = ReasonCode},
    ?DEBUG("~ts,SendSelf=~w",["查询场景大战副本返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

%% 进入场景大战副本
%% 创建副本时 在副本中的进程字典中写入数据
do_create_sw_fb_info(DataRecord) when erlang:is_record(DataRecord,r_sw_fb_dict)->
        %%MonsterIdList = mod_map_monster:get_monster_id_list(),
        put_sw_fb_dict(mgeem_map:get_mapid(),DataRecord);
%% 进入副本更改数据
do_create_sw_fb_info(DataRecord) when erlang:is_record(DataRecord,r_scene_war_fb)->
    MapId = mgeem_map:get_mapid(),
    SwFbDictRecord = get_sw_fb_dict(MapId),
    SceneWarFbList =  SwFbDictRecord#r_sw_fb_dict.scene_war_fb,
    SceneWarFbList2 = 
        case lists:keyfind(DataRecord#r_scene_war_fb.role_id,#r_scene_war_fb.role_id,SceneWarFbList) of
            false ->
                [DataRecord|SceneWarFbList];
            _ ->
                SceneWarFbListT = lists:keydelete(DataRecord#r_scene_war_fb.role_id,#r_scene_war_fb.role_id,SceneWarFbList),
                [DataRecord|SceneWarFbListT]
        end,
    InRoleIdList = SwFbDictRecord#r_sw_fb_dict.in_role_ids,
    put_sw_fb_dict(MapId,SwFbDictRecord#r_sw_fb_dict{
                           scene_war_fb = SceneWarFbList2,
                           in_role_ids = [DataRecord#r_scene_war_fb.role_id|InRoleIdList]}).

%% 场景大战副本怪物死亡  此时此刻..怪物的id还没被干掉
do_monster_dead(TypeId,MonsterName,Rarity, MonsterLevel) ->
    MapId = mgeem_map:get_mapid(),
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        SwFbDictRecord ->
            do_monster_dead2(TypeId,MonsterName,Rarity,MonsterLevel,MapId,SwFbDictRecord)
    end.
do_monster_dead2(TypeId,_MonsterName,_Rarity,_MonsterLevel,MapId,SwFbDictRecord) ->
    %% 广播副本怪物数目 TODO
    SwFbDictRecord = get_sw_fb_dict(MapId),
    MonsterSumNumber = SwFbDictRecord#r_sw_fb_dict.monster_number,
    CurMonsterNumber = SwFbDictRecord#r_sw_fb_dict.cur_monster_number + 1,
    NewSwFbDictRecord = SwFbDictRecord#r_sw_fb_dict{cur_monster_number = CurMonsterNumber},
    put_sw_fb_dict(MapId,NewSwFbDictRecord),
    RoleIdList = mod_map_actor:get_in_map_role(),
    
    CenterMessage = common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_BC_MONSTER,[CurMonsterNumber,MonsterSumNumber]),
    (catch common_broadcast:bc_send_msg_role(RoleIdList,?BC_MSG_TYPE_CENTER,CenterMessage)),
    
    %% 场景大战副本特殊怪物死亡时，需要自动给每一个人发放奖励
    #r_sw_fb_dict{fb_type = FbType,fb_level = FbLevel} = SwFbDictRecord,
    [SwFbMonsterList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_monster),
    case lists:foldl(
           fun(SwFbMonsterRecordT,{AccMonsterFlag,AccSwFbMonsterRecord}) ->
                   if AccMonsterFlag =:= false
                      andalso FbType =:= SwFbMonsterRecordT#r_sw_fb_monster.fb_type
                      andalso FbLevel =:= SwFbMonsterRecordT#r_sw_fb_monster.fb_level
                      andalso TypeId =:= SwFbMonsterRecordT#r_sw_fb_monster.monster_type_id ->
                           {true,SwFbMonsterRecordT};
                      true ->
                           {AccMonsterFlag,AccSwFbMonsterRecord}
                   end
           end,{false,undefined},SwFbMonsterList) of
        {false,_SwFbMonsterError} ->
            ignore;
        {true,SwFbMonsterRecord} ->
            if SwFbMonsterRecord#r_sw_fb_monster.award_items =/= [] ->
                    do_monster_dead_fb_item(RoleIdList,SwFbMonsterRecord);
               true ->
                    ?ERROR_MSG("~ts,SwFbMonsterRecord=~w",["场景大战副本中特殊怪物死亡配置没有奖励",SwFbMonsterRecord])
            end
    end,              
    
    %% 某一个怪物死亡需要给当前副本地图奖励腰牌 TODO
    if MonsterSumNumber =:= CurMonsterNumber -> %% 副本结束
            %% 更新此副本入口的状态信息，其它队伍不可以在此之后进入副本
            #r_sw_fb_dict{fb_id = FbId,fb_seconds = FbSeconds,
                          enter_fb_map_id=EnterFbMapId} = SwFbDictRecord,
            EnterFbMapProcessName = common_map:get_common_map_name(EnterFbMapId),
            catch global:send(EnterFbMapProcessName,{mod_scene_war_fb,{update_enter_sw_fb_info,FbId,FbSeconds,?SCENE_WAR_FB_FB_STATUS_CLOSE}}),
            %% 此处，策划不需要直接踢人出副本，只需记录日志即可
            do_role_sw_fb_log(RoleIdList),
            %%do_scene_war_fb_close_and_bc(),
            ok;
       true ->
            next
    end,
    %% 是否再创建精英怪
    MonsterNum = erlang:length(mod_map_monster:get_monster_id_list()),
    %% 如果当前怪物挂光了..
    if MonsterNum - 1 =:= 0 ->
           if SwFbDictRecord#r_sw_fb_dict.monster_type=:=?NORMAL    %%是否要召唤elite类型怪物
                  andalso SwFbDictRecord#r_sw_fb_dict.born_elite=:=?SW_FB_BORN_ELITE_NORMAL_DEAD  ->
                  RoleIDList = mod_map_actor:get_in_map_role(),
                  (catch common_broadcast:bc_send_msg_role(RoleIDList,?BC_MSG_TYPE_CENTER,?_LANG_VIE_WORLD_BOSS_BRON)),
                  do_init_sw_monster2(SwFbDictRecord#r_sw_fb_dict.cur_monster_key, ?ELITE),
                  put_sw_fb_dict(MapId,NewSwFbDictRecord#r_sw_fb_dict{monster_type = ?ELITE});
              true->
                  case SwFbDictRecord#r_sw_fb_dict.born_monster of   %%是否要提示召唤怪物
                      ?SCENE_WAR_FB_BORN_MONSTER_CALL->
                          DestPassID = get_next_pass_id(MapId,SwFbDictRecord#r_sw_fb_dict.cur_monster_key),
                          %%通知前端 
                          RoleIDList = mod_map_actor:get_in_map_role(),
                          mgeem_map:broadcast(RoleIDList, ?SCENE_WAR_FB, ?SCENE_WAR_FB_CALL_MONSTER, 
                                              #m_scene_war_fb_call_monster_toc{op_type=?SCENE_WAR_FB_CALL_MONSTER_TYPE,
                                               pass_id = DestPassID});
                      _->
                          ignore
                  end
           end;
       true->
           ignore
    end.

get_next_pass_id(MapId,PassID)->
    case common_config_dyn:find(?SCENE_WAR_FB_CONFIG,{sw_fb_call_monster,MapId}) of
        []->0;
        [SwFbMonsterConfig]->
            case lists:keyfind(PassID, #r_sw_fb_call_monster.pass_id, SwFbMonsterConfig) of
                false->
                    0;
                #r_sw_fb_call_monster{next_pass_id=NextPassID}->
                    NextPassID
            end
    end.


%% self() ! {mod_scene_war_fb,{role_dead,RoleID,MapRoleInfo}}.
do_role_dead(RoleID,MapRoleInfo) ->
    MapId = mgeem_map:get_mapid(),
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        SwFbDictRecord ->
            do_role_dead2(RoleID,MapRoleInfo,MapId,SwFbDictRecord)
    end.
do_role_dead2(RoleID,_MapRoleInfo,MapId,SwFbDictRecord) ->
    #r_sw_fb_dict{role_dead_times = RoleDeadTimesList} = SwFbDictRecord,
    RoleDeadTimesList2 = 
        case lists:keyfind(RoleID,1,RoleDeadTimesList) of
            false ->
                [{RoleID,1}|RoleDeadTimesList];
            {RoleID,DeadTimes} ->
                RoleDeadTimesListT = lists:keydelete(RoleID,1,RoleDeadTimesList),
                [{RoleID,DeadTimes + 1}|RoleDeadTimesListT]
        end,
    put_sw_fb_dict(MapId,SwFbDictRecord#r_sw_fb_dict{role_dead_times = RoleDeadTimesList2}),
    ok.
%% 初始化场景副本怪物
%% MonsterKey 怪物出生的依据   例如动态出生怪物的等级 当前第几批怪物
do_init_sw_monster(MonsterKey) ->
    do_init_sw_monster2(MonsterKey, ?NORMAL),
    MapID = mgeem_map:get_mapid(),
    case get_sw_fb_dict(MapID) of
        undefined ->
            ignore;
        SwFbDictRecord ->
			%%判断是否要出生精英怪
			[SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
			case lists:keyfind(MapID, #r_sw_fb_mcm.fb_map_id, SwFbMcmList) of
				false->
					MonsterType = ?NORMAL;
				SwFbMcm->
					case SwFbMcm#r_sw_fb_mcm.born_elite of
						?SW_FB_BORN_ELITE_TOGETHER->
                            MonsterType = ?ELITE,
							do_init_sw_monster2(MonsterKey,?ELITE);
						_->MonsterType = ?NORMAL
					end
			end,
            put_sw_fb_dict(MapID, SwFbDictRecord#r_sw_fb_dict{cur_monster_key=MonsterKey,monster_type=MonsterType})
    end.


do_init_sw_monster2(MonsterKey, MonsterType) ->
    #map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
    MonsterList = get_sw_monster(MapID, MonsterKey, MonsterType),
    mod_map_monster:init_call_fb_monster(MapProcessName, MapID, MonsterList).
%%     mod_map_monster:init_sw_fb_monster(MapProcessName, MapID, MonsterList, MonsterType, MonsterKey).

%% 更新场景大战副本入口信息
do_update_enter_sw_fb_info({FbId,FbSeconds,FbStatus}) ->
    ?DEBUG("~ts,FbId=~w,FbSeconds=~w,FbStatus=~w",["此副本的状态需要修改",FbId,FbSeconds,FbStatus]),
    MapId = mgeem_map:get_mapid(),  
    EnterSwFbDictList = get_sw_fb_enter_dict(MapId),
    EnterSwFbDictList2 = 
        lists:foldl(
          fun(EnterSwFbDict,AccEnterSwFbDictList) ->
                  if FbId =:= EnterSwFbDict#r_sw_fb_enter_dict.fb_id
                     andalso FbSeconds =:= EnterSwFbDict#r_sw_fb_enter_dict.fb_seconds ->
                          if FbStatus =:= ?SCENE_WAR_FB_FB_STATUS_CLOSE ->
                                  AccEnterSwFbDictList;
                             true ->
                                  [EnterSwFbDict#r_sw_fb_enter_dict{fb_status = FbStatus}|AccEnterSwFbDictList]
                          end;
                     true ->
                          [EnterSwFbDict|AccEnterSwFbDictList]
                  end
          end,[],EnterSwFbDictList),
    put_sw_fb_enter_dict(MapId,EnterSwFbDictList2).
%% 
do_delete_enter_sw_fb_info({FbId,FbSeconds}) ->
    ?DEBUG("~ts,FbId=~w,FbSeconds=~w",["此副本已经完成，不可以再进入",FbId,FbSeconds]),
    MapId = mgeem_map:get_mapid(),
    EnterSwFbDictList = get_sw_fb_enter_dict(MapId),
    EnterSwFbDictList2 = 
        lists:foldl(
          fun(EnterSwFbDict,AccEnterSwFbDictList) ->
                  if FbId =:= EnterSwFbDict#r_sw_fb_enter_dict.fb_id
                     andalso FbSeconds =:= EnterSwFbDict#r_sw_fb_enter_dict.fb_seconds ->
                          AccEnterSwFbDictList;
                     true ->
                          [EnterSwFbDict|AccEnterSwFbDictList]
                  end
          end,[],EnterSwFbDictList),
    put_sw_fb_enter_dict(MapId,EnterSwFbDictList2).

%% 场景大战副本广播
do_scene_war_fb_close_and_bc(MaxInterval) ->
    if MaxInterval =:= 0 ->
            do_scene_war_fb_close();
       true ->
            case get_sw_fb_dict(mgeem_map:get_mapid()) of
                undefined ->
                    ignore;
                #r_sw_fb_dict{fb_type=FbType} ->
                    case common_config_dyn:find(?SCENE_WAR_FB_CONFIG, {quit_npc_name, FbType}) of
                        [] ->
                            ?ERROR_MSG("scene_war_fb config error, FbType: ~w", [FbType]),
                            QuitNpcName = <<"副本出口">>;
                        [QuitNpcName] -> ok
                    end,
                    Message = lists:flatten(io_lib:format(?_LANG_SCENE_WAR_FB_BROADCAST_CLOSE_FB,[common_tool:to_list(MaxInterval), QuitNpcName])),
                    RoleIdList = mod_map_actor:get_in_map_role(),
                    (catch common_broadcast:bc_send_msg_role(RoleIdList,?BC_MSG_TYPE_CENTER,Message)),
                    if MaxInterval - 5 >= 5 ->
                            erlang:send_after(5000,self(),{mod_scene_war_fb,{scene_war_fb_close_and_bc,MaxInterval - 5}});
                       true ->
                            erlang:send_after(MaxInterval * 1000,self(),{mod_scene_war_fb,{scene_war_fb_close_and_bc, 0}})
                    end
            end
    end.
%% 玩家通过传送和其它方式离开场景大战副本
%% global:send(FbMapProcessName,{mod_scene_war_fb,{cancel_role_sw_fb,RoleID}})
do_cancel_role_sw_fb(RoleID) ->
    MapId = mgeem_map:get_mapid(),
    case get_sw_fb_dict(MapId) of
        undefined ->
            ignore;
        _ ->
            do_role_sw_fb_log([RoleID])
    end.

%% 场景大战副本关闭操作
do_scene_war_fb_close() ->
    RoleIdList = mod_map_actor:get_in_map_role(),
    if erlang:length(RoleIdList) > 0 ->
            do_scene_war_fb_close2(RoleIdList);
       true ->
            %% 发送消息关闭地图
            self() ! {mod_scene_war_fb,{kill_scene_war_fb_map}}
    end.
do_scene_war_fb_close2(RoleIdList) ->
    %% 记录日志，踢人下线
    do_role_sw_fb_log(RoleIdList),
    MapId = mgeem_map:get_mapid(),
    #r_sw_fb_dict{scene_war_fb = SceneWarFbList} = get_sw_fb_dict(MapId),
    lists:foreach(
      fun(RoleID) ->
              SceneWarFbRecord = lists:keyfind(RoleID,#r_scene_war_fb.role_id,SceneWarFbList),
              #r_scene_war_fb{map_id = DestMapId,pos = DestPos} = SceneWarFbRecord,
              #p_pos{tx=DestTx,ty = DestTy} = DestPos,
              mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID,DestMapId,DestTx,DestTy)
      end,RoleIdList),
    ok.

do_role_sw_fb_log(RoleIdList) ->
    MapId = mgeem_map:get_mapid(),
    #r_sw_fb_dict{log_role_ids = LogRoleIdList} = SwFbDictRecord = get_sw_fb_dict(MapId),
    RoleIdList2 = 
        lists:foldl(
          fun(RoleID,AccRoleIdList) ->
                  case lists:member(RoleID,LogRoleIdList) of
                      true ->
                          AccRoleIdList;
                      false ->
                          [RoleID|AccRoleIdList]
                  end
          end,[],RoleIdList),
    if RoleIdList2 =:= [] ->
            ignore;
       true ->
            do_role_sw_fb_log2(MapId,RoleIdList2,SwFbDictRecord)
    end.
do_role_sw_fb_log2(MapId,RoleIdList,SwFbDictRecord) ->
    #r_sw_fb_dict{fb_id = FbId,
                  fb_seconds = FbSeconds,
                  scene_war_fb = SceneWarFbList,
                  monster_number = MonsterNumber,
                  team_role_ids = TeamRoleIdList,
                  in_role_ids = InRoleIdList,
                  role_dead_times = RoleIdDeadTimesList,
                  collect_log_flag = CollectLogFlag,
                  collect_info = CollectInfoList,
                  log_role_ids = LogRoleIdList} = SwFbDictRecord,
    EndTime = common_tool:now(),
    MonsterIdList = mod_map_monster:get_monster_id_list(),
    CurMonsterNumber = erlang:length(MonsterIdList),
    InRoleNames = 
        lists:foldl(
          fun(TeamRoleId,AccInRoleNames) ->
                  [#p_role_attr{role_name = InRoleName}] = db:dirty_read(?DB_ROLE_ATTR,TeamRoleId),
                  if AccInRoleNames =:= "" ->
                          lists:append([AccInRoleNames,common_tool:to_list(InRoleName)]);
                     true ->
                          lists:append([AccInRoleNames,",",common_tool:to_list(InRoleName)])
                  end
          end,"",TeamRoleIdList),
    SceneWarFbList2 = 
        lists:foldl(
          fun(SceneWarFbRecord,AccSceneWarFbList) ->
                  SceneWarFbRecord2 = 
                      case lists:member(SceneWarFbRecord#r_scene_war_fb.role_id,RoleIdList) of
                          false ->
                              SceneWarFbRecord;
                          true ->
                              SceneWarFbRecordT = SceneWarFbRecord#r_scene_war_fb{end_time = EndTime,status = ?SCENE_WAR_FB_FB_STATUS_COMPLETE},
                              db:dirty_write(?DB_SCENE_WAR_FB,SceneWarFbRecordT),
                              SceneWarFbRecordT
                      end,
                  SceneWarFbLogRecord = get_role_sw_fb_log_record(SceneWarFbRecord2),
                  DeadTimes = 
                      case lists:keyfind(SceneWarFbRecord#r_scene_war_fb.role_id,1,RoleIdDeadTimesList) of
                          false ->
                              0;
                          {_,DeadTimesT} ->
                              DeadTimesT
                      end,
                  SceneWarFbLogRecord2 = SceneWarFbLogRecord#r_scene_war_fb_log{
                                           dead_times = DeadTimes,
                                           in_number =  erlang:length(TeamRoleIdList),
                                           out_number =  erlang:length(InRoleIdList),
                                           in_role_ids = lists:flatten(io_lib:format("~w", [TeamRoleIdList])),
                                           in_role_names = InRoleNames,
                                           out_role_ids = lists:flatten(io_lib:format("~w", [InRoleIdList])),
                                           monster_born_number = MonsterNumber,
                                           monster_dead_number = (MonsterNumber - CurMonsterNumber)},
                  catch common_general_log_server:log_scene_war_fb(SceneWarFbLogRecord2),
                  [SceneWarFbRecord2|AccSceneWarFbList]
          end,[],SceneWarFbList),
    LogRoleIdList2 = lists:append([RoleIdList,LogRoleIdList]),
    %% 采集物日志
    if CollectInfoList =/= [] andalso CollectLogFlag =:= 0 ->
            %% 需要记录日志
            CollectLogFlag2 = 1,
            SwFbCollectLogList = 
                lists:foldl(
                  fun(#p_map_collect{typeid = CollectTypeId},AccSwFbCollectLogList) ->
                          case lists:keyfind(CollectTypeId,#r_scene_war_fb_log_collect.collect_id,AccSwFbCollectLogList) of
                              false ->
                                  [#r_scene_war_fb_log_collect{
                                      fb_id=FbId, fb_seconds=FbSeconds,
                                      collect_id = CollectTypeId,collect_number = 1}|AccSwFbCollectLogList];
                              #r_scene_war_fb_log_collect{collect_number = CollectNumber} ->
                                  AccSwFbCollectLogList2 = lists:keydelete(CollectTypeId,#r_scene_war_fb_log_collect.collect_id,AccSwFbCollectLogList),
                                  [#r_scene_war_fb_log_collect{
                                      fb_id=FbId, fb_seconds=FbSeconds,
                                      collect_id = CollectTypeId,collect_number = (CollectNumber + 1)}|AccSwFbCollectLogList2]
                          end
                  end,[],CollectInfoList),
            lists:foreach(
              fun(SwFbCollectLog) -> 
                      catch common_general_log_server:log_scene_war_fb(SwFbCollectLog)
              end,SwFbCollectLogList);
       true ->
            CollectLogFlag2 = 1
    end,
    SwFbDictRecord2 = SwFbDictRecord#r_sw_fb_dict{
                        scene_war_fb = SceneWarFbList2,
                        log_role_ids = LogRoleIdList2,
                        collect_log_flag = CollectLogFlag2},
    put_sw_fb_dict(MapId,SwFbDictRecord2),
    ok.
%% 根据玩家场景大战记录，获取场景大战日志记录基本数据
get_role_sw_fb_log_record(SceneWarFbRecord) ->
    FbInfoList = SceneWarFbRecord#r_scene_war_fb.fb_info,
    Times = case lists:keyfind(SceneWarFbRecord#r_scene_war_fb.fb_type,#r_scene_war_fb_info.fb_type,FbInfoList) of
                false ->
                    0;
                #r_scene_war_fb_info{times = TimesT} ->
                    TimesT
            end,
    #r_scene_war_fb_log{
              role_id = SceneWarFbRecord#r_scene_war_fb.role_id,
              role_name = SceneWarFbRecord#r_scene_war_fb.role_name,
              faction_id = SceneWarFbRecord#r_scene_war_fb.faction_id,
              level = SceneWarFbRecord#r_scene_war_fb.level,
              team_id = SceneWarFbRecord#r_scene_war_fb.team_id,
              status = SceneWarFbRecord#r_scene_war_fb.status,
              times = Times,
              start_time = SceneWarFbRecord#r_scene_war_fb.start_time,
              end_time = SceneWarFbRecord#r_scene_war_fb.end_time,
              fb_id = SceneWarFbRecord#r_scene_war_fb.fb_id,
              fb_seconds = SceneWarFbRecord#r_scene_war_fb.fb_seconds,
              fb_type = SceneWarFbRecord#r_scene_war_fb.fb_type,
              fb_level = SceneWarFbRecord#r_scene_war_fb.fb_level
             }.

%% @doc 获取玩家场景副本新的挑战次数列表
get_new_role_sw_fb_info_list(FbType, SceneFbRecord) ->
    #r_scene_war_fb{fb_info=FbInfoList, start_time=StartTime} = SceneFbRecord,
    NowDate = erlang:date(),
    TodaySeconds = common_tool:datetime_to_seconds({NowDate, {0, 0, 0}}),
    FbInfoList2 =
        case StartTime > TodaySeconds of
            true ->
                FbInfoList;
            _ ->
                lists:map(fun(FbInfo) -> FbInfo#r_scene_war_fb_info{times=0} end, FbInfoList)
        end,
    case lists:keyfind(FbType, #r_scene_war_fb_info.fb_type, FbInfoList2) of
        false ->
            [#r_scene_war_fb_info{fb_type=FbType, times=1}|FbInfoList2];
        #r_scene_war_fb_info{times=T} ->
            [#r_scene_war_fb_info{fb_type=FbType, times=T+1}|lists:keydelete(FbType, #r_scene_war_fb_info.fb_type, FbInfoList2)]
    end.

%% 获取玩家某类场景大战副本的次数
get_sw_fb_times(_FbType,undefined) ->
    0;
get_sw_fb_times(FbType,SceneFbRecord) ->
    #r_scene_war_fb{fb_info = FbInfoList, start_time = StartTime} = SceneFbRecord,
    NowSeconds = common_tool:now(),
    {NowDate,_NowTime} =
        common_tool:seconds_to_datetime(NowSeconds),
    TodaySeconds = common_tool:datetime_to_seconds({NowDate,{0,0,0}}),
    case lists:keyfind(FbType,#r_scene_war_fb_info.fb_type,FbInfoList) of
        false ->
            0;
        #r_scene_war_fb_info{times = Times} ->
            if StartTime > TodaySeconds ->
                    Times;
               true ->
                    0
            end
    end.

%% 获取进入场景大战副本的费用，元宝
%% FbType 副本类型
%% Times 当前玩家副本次数
%% 返回 {ok,r_sw_fb_fee} or  {error, Reason}
get_sw_fb_fee(FbType,Times) ->
    [SwFbFeeList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_fee),
    SwFbFeeList2 = [R || R <- SwFbFeeList, R#r_sw_fb_fee.fb_type =:= FbType],
    if SwFbFeeList2 =:= [] ->
            {error,not_found};
       true ->
            SwFbFeeList3 =lists:sort(fun(RA,RB) -> RA#r_sw_fb_fee.max_times < RB#r_sw_fb_fee.max_times end,SwFbFeeList2),
            MaxSwFbRecord = lists:nth(erlang:length(SwFbFeeList3),SwFbFeeList3),
            if Times > MaxSwFbRecord#r_sw_fb_fee.max_times ->
                    {error, max_times,MaxSwFbRecord#r_sw_fb_fee.max_times};
               true ->
                    case lists:foldl(
                           fun(SwFbFeeRecordT,{AccSwFbFeeFlag,AccSwFbFeeRecord}) ->
                                   if AccSwFbFeeFlag =:= false 
                                      andalso FbType =:= SwFbFeeRecordT#r_sw_fb_fee.fb_type
                                      andalso Times >= SwFbFeeRecordT#r_sw_fb_fee.min_times
                                      andalso SwFbFeeRecordT#r_sw_fb_fee.max_times >= Times ->
                                           {true,SwFbFeeRecordT};
                                      true ->
                                           {AccSwFbFeeFlag,AccSwFbFeeRecord}
                                   end
                           end,{false,undefined},SwFbFeeList2) of
                        {false,_ErrorSwFbFee} ->
                            {error,not_found_fee};
                        {true,SwFbFeeRecord} ->
                            {ok,SwFbFeeRecord}
                    end
            end
    end.   
get_sw_fb_max_times(FbType) ->                               
    [SwFbFeeList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_fee),
    SwFbFeeList2 = [R || R <- SwFbFeeList, R#r_sw_fb_fee.fb_type =:= FbType],
    if SwFbFeeList2 =:= [] ->
            0;
       true ->
            SwFbFeeList3 =lists:sort(fun(RA,RB) -> RA#r_sw_fb_fee.max_times < RB#r_sw_fb_fee.max_times end,SwFbFeeList2),
            MaxSwFbRecord = lists:nth(erlang:length(SwFbFeeList3),SwFbFeeList3),
            MaxSwFbRecord#r_sw_fb_fee.max_times
    end.


%% 检查玩家是否在NPC附近
assert_valid_distance(CurMapId,NpcId,RoleMapInfo)->
    case check_valid_distance(CurMapId,NpcId,RoleMapInfo) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_SCENE_WAR_FB_NOT_VALID_DISTANCE,0})
    end.

%% 检查玩家是否在有效的距离内
%%@return true | false
check_valid_distance(MapID, NpcId,RoleMapInfo) when is_record(RoleMapInfo,p_map_role) ->
    #p_map_role{pos = #p_pos{tx = InTx,ty = InTy}} = RoleMapInfo,
    
    {NpcId, Tx, Ty} = lists:keyfind(NpcId, 1, mcm:npc_tiles(MapID)),
    [{MaxTx,MaxTy}] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,npc_valid_distance),
    TxDiff = erlang:abs(InTx - Tx),
    TyDiff = erlang:abs(InTy - Ty),
    if TxDiff < MaxTx andalso TyDiff < MaxTy ->
            true;
       true ->
            false
    end.

%% 获取地图出生点
get_sw_fb_map_born_point(MapId) ->
    case mcm:born_tiles(MapId) of
        [] ->
            {0,0};
        [{Tx, Ty}|_] ->
            {Tx,Ty}
    end.

%% 场景大战副本特殊怪物死亡时，需要自动给每一个人发放奖励
do_monster_dead_fb_item(RoleIdList,SwFbMonsterRecord) ->
    ?DEBUG("~ts,RoleIdList=~w",["打死精英怪时给奖励道具获得地图所有用户",RoleIdList]),
    #r_sw_fb_monster{award_items = AwardItemList} = SwFbMonsterRecord,
    WeightList = [Weight || #r_sw_fb_monster_item{weight = Weight} <- AwardItemList],
    lists:foreach(
      fun(RoleID) ->
            case mod_refining:get_random_number(WeightList,0,-1) of
                -1 ->
                    ?ERROR_MSG("ErrorCode=~ts,Description=~ts,RoleID=~w",["场景大战副本内玩家根据概率计算无法获得副本道具",RoleID]);
                HitIndex ->
                    AwardItemRecord = lists:nth(HitIndex,AwardItemList),
                    do_monster_dead_fb_item2(RoleID,AwardItemRecord)
            end  
      end,RoleIdList),
    ok.
do_monster_dead_fb_item2(_RoleID, #r_sw_fb_monster_item{item_id=0}) ->
    ignore;
do_monster_dead_fb_item2(RoleID,AwardItemRecord) ->
    #r_sw_fb_monster_item{item_id = ItemId,item_type = ItemType,
                          item_number = ItemNumber,item_bind = ItemBind,
                          color = ColorList,quality = QualityList} = AwardItemRecord,
    Bind = if ItemBind =:= 0 ->
                   false;
              ItemBind =:= 100 ->
                   true;
              true ->
                   RandomNumber = random:uniform(100),
                   if ItemBind >= RandomNumber ->
                           true;
                      true ->
                           false
                   end
           end,
    CreateInfo =
        if ItemType =:= ?TYPE_EQUIP ->
                Color = mod_refining:get_random_number(ColorList,0,1),
                Quality = mod_refining:get_random_number(QualityList,0,1),
                #r_goods_create_info{type=ItemType,
                                     type_id=ItemId,
                                     num=ItemNumber,
                                     bind=Bind,
                                     color = Color,
                                     quality = Quality,         
                                     interface_type=scene_war_fb};
           true ->
                #r_goods_create_info{
             type=ItemType,
             type_id=ItemId,
             num=ItemNumber,
             bind=Bind}
        end,
    case db:transaction(
           fun() ->
                   {ok,GoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
                   {ok,GoodsList}
           end) of
        {atomic,{ok,GoodsList}} ->
            Line = common_role_line_map:get_role_line(RoleID),
            UnicastArg = {line, Line, RoleID},
            if GoodsList =/= [] ->
                    [HGoods|_T] = GoodsList,
                    catch common_item_logger:log(RoleID,HGoods#p_goods{current_num = ItemNumber},?LOG_ITEM_TYPE_SCENE_WAR_FB_AWARD),
                    catch common_misc:update_goods_notify(UnicastArg,GoodsList),
                    NGoodsName = common_goods:get_notify_goods_name(HGoods#p_goods{current_num = ItemNumber}),
                    catch common_broadcast:bc_send_msg_role(RoleID,?BC_MSG_TYPE_SYSTEM,
                                                            common_tool:get_format_lang_resources(?_LANG_SCENE_WAR_FB_BC_MONSTER_GOODS,[NGoodsName])),
                    ok;
               true ->
                    next
            end,
            ok;
        {aborted, Reason} ->
            case Reason of 
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    {FBType, FbName} = 
                        case get_sw_fb_dict(mgeem_map:get_mapid()) of
                            undefined ->
                                {?SCENE_WAR_FB_TYPE_PYH, ""};
                            #r_sw_fb_dict{fb_type = FbType,fb_level = FbLevel} ->
                                [SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
                                lists:foldl(
                                  fun(#r_sw_fb_mcm{fb_type = FbTypeA,fb_level = FbLevelA,fb_name = FbNameA},{AccFbType, AccFbName}) ->
                                          case (AccFbName =:= "" andalso FbType =:= FbTypeA andalso FbLevelA =:= FbLevel) of
                                              true ->
                                                  {FbType, common_tool:to_list(FbNameA)};
                                              false ->
                                                  {AccFbType, AccFbName}
                                          end
                                  end,{?SCENE_WAR_FB_TYPE_PYH,""},SwFbMcmList)
                        end,
                    [{Title, NpcName}] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG, {fb_goods_letter, FBType}),
                    LetterText = common_letter:create_temp(?SCENE_WAR_FB_GOODS_LETTER_2, [FbName, NpcName]),
                    (catch common_letter:sys2p(RoleID,LetterText,Title,CreateInfo,14));
                _ ->
                    ?ERROR_MSG("~ts,Reason=~w",["玩家被系统踢出师门同心副本时删除副本道具出错",Reason])
            end
    end.
%%add by caochuncheng 2011-04-21 添加场景大战拾取物品世界通知
hook_role_pick_dropthing(RoleID,Goods) ->
    SwFbDictRecord = get_sw_fb_dict(mgeem_map:get_mapid()),
    #r_sw_fb_dict{fb_type = FbType,fb_level = FbLevel, enter_fb_map_id = EnterFbMapId} = SwFbDictRecord,
    [SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
    [SwFbNpcList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_npc),
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{role_name=RoleName, faction_id=FactionID, sex=Sex} = RoleBase,
    FactionName = 
        if FactionID =:= 1 ->
                common_tool:to_list(?_LANG_COLOR_FACTION_1);
           FactionID =:= 2 ->
                common_tool:to_list(?_LANG_COLOR_FACTION_2);
           FactionID =:= 3 ->
                common_tool:to_list(?_LANG_COLOR_FACTION_3);
           true ->
                ""
        end,
    FbName = 
        lists:foldl(
          fun(#r_sw_fb_mcm{fb_type = FbTypeA,fb_level = FbLevelA,fb_name = FbNameA},AccFbName) ->
                  case (AccFbName =:= "" andalso FbType =:= FbTypeA andalso FbLevelA =:= FbLevel) of
                      true ->
                          common_tool:to_list(FbNameA);
                      false ->
                          AccFbName
                  end
          end,"",SwFbMcmList),
    NpcId = 
        lists:foldl(
          fun(SwFbNpcRecord,AccNpcId) ->
                  if AccNpcId =:= 0
                     andalso SwFbNpcRecord#r_sw_fb_npc.fb_type =:= FbType
                     andalso SwFbNpcRecord#r_sw_fb_npc.fb_level =:= FbLevel
                     andalso SwFbNpcRecord#r_sw_fb_npc.map_id =:= EnterFbMapId ->
                          SwFbNpcRecord#r_sw_fb_npc.npc_id;
                     true ->
                          AccNpcId
                  end
          end,0,SwFbNpcList),
    NpcId2 = NpcId - FactionID * 1000000,
    GoodsName = common_goods:get_notify_goods_name(Goods),
    BcMessage = common_tool:get_format_lang_resources(
                  ?_LANG_SCENE_WAR_FB_BROADCAST_PICK_GOODS,
                  [common_misc:get_role_name_color(RoleName,FactionID),FbName,NpcId2]),
    BcCenterMessage = common_tool:get_format_lang_resources(
                        ?_LANG_SCENE_WAR_FB_BROADCAST_PICK_GOODS_CENTER,
                        [FactionName, RoleName,FbName,GoodsName]),
%%     case  FbType of
%%        ?SCENE_WAR_FB_TYPE_PYEH ->
%%            Banlevel = 34;
%%        _ ->
           Banlevel = 15,
%%     end,           
    catch common_broadcast:bc_send_msg_faction_include_goods(FactionID, [?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD,Banlevel, BcMessage,
                                                             RoleID, RoleName, Sex, [Goods]),
    catch common_broadcast:bc_send_msg_faction(FactionID, ?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,BcCenterMessage).
%% @doc 获取队伍平均等级
get_team_average_level(MapInfoList,FbType) ->
	{SumLW,SumW} = 
		lists:foldl(
		  fun(MapInfo,Acc) ->
				  {AccLW,AccW} = Acc,
				  RoleLevel = MapInfo#p_map_role.level,
				  Weight = get_vwf_role_weight(RoleLevel,FbType),
				  AccLW2 = AccLW + RoleLevel *  Weight,
				  AccW2 = AccW + Weight,
				  {AccLW2,AccW2}
		  end,{0,0},MapInfoList),
	Level = common_tool:ceil(SumLW div SumW div 5)*5,
    if Level < 30 ->
           30;
       true->
           Level
    end.
    
%% 	[WeightList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,{sw_role_level_weight,FbType}),
%%     {_,AvgLevel} =
%% 	lists:foldl(
%% 	  fun(Record,{_IfDone,_AvgLevel}) ->
%% 			  if _IfDone =:= false 
%% 					 andalso Level=<Record#r_sw_role_level_weight.max_level->
%% 					 {true,Record#r_sw_role_level_weight.min_level};
%% 				 true->
%% 					 {_IfDone,_AvgLevel}
%% 			  end
%% 	  end,{false,0},WeightList),
%%     AvgLevel.

%% 获取级别权重记录
get_vwf_role_weight(RoleLevel,FbType) ->
    case common_config_dyn:find(?SCENE_WAR_FB_CONFIG,{sw_role_level_weight,FbType}) of
        [ WeightList ] ->
            lists:foldl(
              fun(Record,Acc) ->
                      MinLevel = Record#r_sw_role_level_weight.min_level,
                      MaxLevel = Record#r_sw_role_level_weight.max_level,
                      if RoleLevel >= MinLevel 
                         andalso RoleLevel =< MaxLevel ->
                              Record#r_sw_role_level_weight.weight;
                         true ->
                              Acc
                      end
              end,1,WeightList);
        _ ->
            1
    end.

get_sw_monster(MapId, MonsterKey,MonsterType) ->
    case common_config_dyn:find(fb_manual_monster, {monster_list, MapId, MonsterKey, MonsterType}) of
        []->
            MonsterList=[];
        [MonsterList]->
            next
    end,
    lists:foldl(
      fun(MonsterTypeId, AccMonsterList) ->
              [BornPointList] = common_config_dyn:find(fb_manual_monster, {monster_born_list, MonsterTypeId}),
              lists:foldl(
                fun(MonsterBornRecord, TMonsterList) ->
                        #r_vwf_monster_bron{tx=TX, ty=TY} = MonsterBornRecord,
                        Pos = #p_pos{tx=TX, ty=TY, dir=1},
                        [#p_monster{reborn_pos=Pos,
                                    monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
                                    typeid=MonsterTypeId,
                                    mapid=MapId}|TMonsterList]
                end, AccMonsterList, BornPointList)
      end, [], MonsterList).

%% %%玩家退出队伍时搞的
do_hook_quit_team(RoleID) ->
    case get_sw_fb_dict(mgeem_map:get_mapid()) of
        undefined->
            ignore;
        SwFbDictRecord->
            [SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
            {_Flag,MustTeam} =
                lists:foldl(
                  fun(SwFbMcmConfig,{AccFlag,IfMustTeam}) ->
                          if AccFlag =:= false 
                                 andalso SwFbMcmConfig#r_sw_fb_mcm.fb_type =:= SwFbDictRecord#r_sw_fb_dict.fb_type
                                 andalso SwFbMcmConfig#r_sw_fb_mcm.fb_level =:= SwFbDictRecord#r_sw_fb_dict.fb_level ->
                                 {true,SwFbMcmConfig#r_sw_fb_mcm.must_team};
                             true ->
                                 {AccFlag,IfMustTeam}
                          end
                  end,{false,false},SwFbMcmList),
            case MustTeam of
                ?SCENE_WAR_FB_TEAM_LEVEL_ONE ->
                    ignore;
                _->
                    %%玩家退出副本
                    do_cancel_role_sw_fb(RoleID),
                    RoleMapInfo = 
                        case mod_map_actor:get_actor_mapinfo(RoleID,role) of
                            undefined ->
                                erlang:throw({error,?_LANG_SCENE_WAR_FB_QUIT_ERROR,0});
                            RoleMapInfoT ->
                                RoleMapInfoT
                        end,
                    case lists:keyfind(RoleID,#r_scene_war_fb.role_id,SwFbDictRecord#r_sw_fb_dict.scene_war_fb) of
                        false -> %% 查找不到，直接回京城
                            HomeMapId = common_misc:get_home_map_id(RoleMapInfo#p_map_role.faction_id),
                            {HomeMapId,HomeTx,HomeTy} = common_misc:get_born_info_by_map(HomeMapId),
                            mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, HomeMapId, HomeTx, HomeTy);
                        #r_scene_war_fb{map_id = DestMapId,pos = DestPos} ->
                            #p_pos{tx=DestTx,ty = DestTy} = DestPos,
                            mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID,DestMapId,DestTx,DestTy)
                    end
            end
    end.

get_sw_fb_exp_rate(MemberCount,MapId) ->
    case get_sw_fb_dict(MapId) of
        undefined ->
            100;
        #r_sw_fb_dict{fb_type=FbType} ->
            case common_config_dyn:find(?SCENE_WAR_FB_CONFIG, {sw_fb_exp, FbType}) of
                [] ->
                    100;
                [FbList] ->
                    get_sw_fb_exp_rate2(MemberCount, FbList)
            end
    end.

get_sw_fb_exp_rate2(_RoleNum, []) ->
    100;
get_sw_fb_exp_rate2(RoleNum, [SwFbExpRecord|TFbList]) ->
    if RoleNum >= SwFbExpRecord#r_sw_fb_exp.min_num andalso
       RoleNum =< SwFbExpRecord#r_sw_fb_exp.max_num ->
            SwFbExpRecord#r_sw_fb_exp.exp_rate;
       true ->
            get_sw_fb_exp_rate2(RoleNum, TFbList)
    end.

%% 检查副本配置
check_sw_fb_mcm(FbType, FbLevel) ->
    [SwFbMcmList] = common_config_dyn:find(?SCENE_WAR_FB_CONFIG,sw_fb_mcm),
    case lists:foldl(
           fun(SwFbMcmRecordT,{AccSwFbMcmFlag,AccSwFbMcmRecord})->
                   if AccSwFbMcmFlag =:= false 
                        andalso FbType =:= SwFbMcmRecordT#r_sw_fb_mcm.fb_type
                        andalso FbLevel =:= SwFbMcmRecordT#r_sw_fb_mcm.fb_level ->
                          {true,SwFbMcmRecordT};
                      true ->
                          {AccSwFbMcmFlag,AccSwFbMcmRecord}
                   end
                          end,{false,undefined},SwFbMcmList) of
        {false,_SwFbMcmError} ->
                erlang:throw({error, fb_not_found});
        {true,SwFbMcmRecordTT} ->
            SwFbMcmRecordTT
        end.

%% 检查玩家进入等级限制
check_sw_fb_role_enter_level_limit(RoleLevel, SwFbMcmRecord) ->
    if RoleLevel < SwFbMcmRecord#r_sw_fb_mcm.min_level ->
           erlang:throw({error, lower_than_min_level});
       RoleLevel > SwFbMcmRecord#r_sw_fb_mcm.max_level ->
           erlang:throw({error, higher_than_max_level});
       true ->
           ok
    end.

%% 检查玩家完成的次数以及费用是否足够
check_sw_fb_time_and_fee(RoleID, SwFbMcmRecord) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    SceneFbRecord = 
        case db:transaction(
           fun() -> 
                   case db:read(?DB_SCENE_WAR_FB,RoleID) of
                       [] ->
                           undefined;
                       [SceneFbRecordT] ->
                           SceneFbRecordT
                   end
           end) of
            {atomic, SceneFbRecordT} ->
                SceneFbRecordT;
            {aborted, DBError} ->
                erlang:throw(DBError)
        end,
    #r_sw_fb_mcm{fb_type = FbType} = SwFbMcmRecord,
    Times = get_sw_fb_times(FbType,SceneFbRecord),
    SwFbFeeRecord = 
        case get_sw_fb_fee(FbType,Times + 1) of
            {ok,SwFbFeeRecoedT} ->
                SwFbFeeRecoedT;
            Error ->
                erlang:throw(Error)
        end,
    if SwFbFeeRecord#r_sw_fb_fee.fb_fee =/= 0 -> %% 需要扣费
           #p_role_attr{gold = Gold,gold_bind = GoldBind} = RoleAttr,
           if (Gold + GoldBind) < SwFbFeeRecord#r_sw_fb_fee.fb_fee ->
                  erlang:throw({error, not_enough_gold});
              true ->
                  ok
           end;
       true ->
           ok
    end.

%% 
%% %% return ingore|tuple():r_sw_fb_mcm
%% get_sw_fb_mcm(FbType,FbLevel)->
%% 	case common_config_dyn:find(?SCENE_WAR_FB_CONFIG, sw_fb_mcm) of
%% 		[]->false;
%% 		[SwFbMcmList]->
%% 			get_sw_fb_mcm(SwFbMcmList,FbType,FbLevel)
%% 	end.
%% 
%% get_sw_fb_mcm([#r_sw_fb_mcm{fb_type=FbType,fb_level=FbLevel}=H|_RestList],FbType,FbLevel)->
%% 	H;
%% get_sw_fb_mcm([_H|RestList],FbType,FbLevel)->
%% 	get_sw_fb_mcm(RestList,FbType,FbLevel);
%% get_sw_fb_mcm([],_,_)->
%% 	false.
