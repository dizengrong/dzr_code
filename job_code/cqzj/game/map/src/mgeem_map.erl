%%%----------------------------------------------------------------------
%%% File    : mgeem_virtual_world.erl
%%% Author  : Liangliang
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------
-module(mgeem_map).

-behaviour(gen_server).

-include("mgeem.hrl").

-define(MAP_STATE_KEY, map_state_key).
-define(DEFAULT_MAP_DEBUG_MODE,false).


%% --------------------------------------------------------------------
%% API For Extenal Call
%% --------------------------------------------------------------------
-export([
         start_link/1,
         broad_in_sence/5,
         broad_in_sence_include/5,
         get_9_slice_by_txty/4,
         get_slice_by_txty/4,
         get_all_in_sence_user_by_slice_list/1,
         get_all_in_sence_monster_by_slice_list/1,
         get_all_in_sence_server_npc_by_slice_list/1,
         get_new_around_slice/6,
         get_9_slice_by_actorid_list/2,
         get_all_roleid/0,
         func/2,
         flush_all_role_msg_queue/0,
         broadcast/6,
         broadcast/5,
         broadcast/4,
         update_role_msg_queue/2,
         get_map_type/1,
		     absend/1,
		     call/1,
         send/1,
		     run/1
        ]).

-export([resume/0, resume/1, suspend/0, suspend/1]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% --------------------------------------------------------------------
%% API 子模块专用
%% --------------------------------------------------------------------
-export([
         get_slice_name/2,
         get_slice_trap/1,
         add_slice_trap/3,
         remove_slice_trap/3,
         do_broadcast_insence/5,
         do_broadcast_insence_include/4,
         do_broadcast_insence_include/5,
         get_sxsy_by_txty/2,
         get_slice_dolls/1,
         add_slice_doll/3,
         remove_slice_doll/3,
         get_state/0,
         do_broadcast_insence_by_txty/6,
         broadcast_to_whole_map/3,
         get_mapid/0,
         get_mapname/0,
         get_now/0,
         get_now2/0
        ]).

%% --------------------------------------------------------------------

get_now() ->
    erlang:get(now).

get_now2() ->
    erlang:get(now2).

func(MapName, Fun) ->
    global:send(MapName, {func, Fun}).

absend(Info) ->
	get(map_pid) ! Info.

call(Req) ->
	case get(is_map_process) of
		true ->
			handle_call(Req, undefined, mgeem_map:get_state());
		_ ->
			gen_server:call(get(map_pid), Req)
	end.

send(Info) ->
	case get(is_map_process) of
		true ->
			handle_info(Info, mgeem_map:get_state());
		_ ->  
			get(map_pid) ! Info
	end.

run(Fun) ->
	case get(is_map_process) of
		true ->
			Fun();
		_ ->
			get(map_pid) ! {func, Fun, []}
	end.

-spec(broad_in_sence(MAP::integer() | list(), RoleIdList::list(), Module::integer(), 
                     Method::integer(), DataRecord::tuple()) -> ok).
broad_in_sence(MAP, RoleIdList, Module, Method, DataRecord) 
  when is_list(RoleIdList) andalso is_integer(MAP) ->
    MapName = common_map:get_common_map_name(MAP),
    case global:whereis_name(MapName) of
        undefined ->
            ?ERROR_MSG("map ~w not started !!!", [MAP]);
        PID ->
            PID !  {broadcast_in_sence, RoleIdList, Module, Method, DataRecord}
    end,
    ok;
broad_in_sence(MAP, RoleIdList, Module, Method, DataRecord) 
  when is_list(RoleIdList) andalso is_list(MAP) ->
    case global:whereis_name(MAP) of
        undefined ->
            ?ERROR_MSG("map ~w not started !!!", [MAP]);
        PID ->
            PID ! {broadcast_in_sence, RoleIdList, Module, Method, DataRecord}
    end,
    ok;
broad_in_sence(MAP, RoleIdList, Module, Method, DataRecord) ->
    ?ERROR_MSG("wrong broad_in_sence all ~w ~w ~w ~w ~w", [MAP, RoleIdList, Module, Method, DataRecord]),
    ok.


-spec(broad_in_sence_include(MAP::integer()|list(), RoleIDList::list(), Module::integer(), 
                             Method::integer(), DataRecord::tuple()) -> ok).
broad_in_sence_include(MAP, RoleIDList, Module, Method, DataRecord) 
  when is_list(RoleIDList) andalso is_integer(MAP) ->
    MapName = common_map:get_common_map_name(MAP),
    case global:whereis_name(MapName) of
        undefined ->
            ?ERROR_MSG("map ~w not started !!!", [MAP]);
        _ ->
            global:send(MapName, {broadcast_in_sence_include, RoleIDList, Module, Method, DataRecord})
    end,
    ok;
broad_in_sence_include(MAP, RoleIDList, Module, Method, DataRecord) 
  when is_list(RoleIDList) andalso is_list(MAP) ->
    case global:whereis_name(MAP) of
        undefined ->
            ?ERROR_MSG("map ~w not started !!!", [MAP]);
        _ ->
            global:send(MAP, {broadcast_in_sence_include, RoleIDList, Module, Method, DataRecord})
    end,
    ok;
broad_in_sence_include(MAP, RoleIDList, Module, Method, DataRecord) ->
    ?ERROR_MSG("wrong broad_in_sence all ~w ~w ~w ~w ~w", 
               [MAP, RoleIDList, Module, Method, DataRecord]),
    ok.

broadcast_to_whole_map(Module, Method, Record) ->
    lists:foreach(fun(RoleID) ->
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, Module, Method, Record)
	end, get_all_roleid()).
%%获取当前地图中所有玩家的ID，绝对不要乱用
get_all_roleid() ->
    mod_map_actor:get_in_map_role().

get_map_type(MapID) when is_integer(MapID)->
  mcm:map_type(MapID).

resume() ->
	self() ! resume.

resume(PID) ->
	PID ! resume.

suspend() ->
	self() ! suspend.

suspend(PID) ->
	PID ! suspend.

%% --------------------------------------------------------------------
%% API : start_link
%% --------------------------------------------------------------------

start_link({MapProcessName, MapID}) ->
    case get_map_type(MapID) of 
        ?MAP_TYPE_NORMAL ->
            gen_server:start_link(?MODULE, [MapProcessName, MapID], [{spawn_opt, [{min_heap_size, 10*1024}, {min_bin_vheap_size, 10*1024}]}]);
        _ ->
            gen_server:start_link(?MODULE, [MapProcessName, MapID], [{spawn_opt, [{min_heap_size, 1024}, {min_bin_vheap_size, 1024}]}])
    end.

%% --------------------------------------------------------------------
%% API for state lookup
%% --------------------------------------------------------------------


init([MapProcessName, MAPIdIn]) ->
    MAPID = common_tool:to_integer(MAPIdIn),
    case global:register_name(MapProcessName, erlang:self()) of
        yes ->
            erlang:put(is_map_process, true),
            erlang:process_flag(trap_exit, true),
            init_2(MAPID,MapProcessName);
        _ ->
            {stop, aleady_registered_map_name}
    end.
    
init_2(MAPID,MapProcessName)->
    Mcm        = mcm:get_mod(MAPID),
    GridWidth  = Mcm:grid_width(),
    GridHeight = Mcm:grid_height(),
    OffsetX    = Mcm:offset_x(),
    OffsetY    = Mcm:offset_y(),
    MapType    = Mcm:map_type(),
    %%读取地图数据
    random:seed(now()),
    %%初始化九宫格的slice
    init_slice_lists(MapProcessName, GridWidth,GridHeight),
    State = #map_state{
      mapid       = MAPID, 
      map_type    = MapType, 
      offsetx     = OffsetX, 
      offsety     = OffsetY,  
      map_name    = MapProcessName, 
      grid_width  = GridWidth, 
      grid_height = GridHeight
    },
    init_state(State),
    erlang:self() ! loop,
    erlang:self() ! loop_ms,
    mod_map_collect:init(MAPID),
    hook_map:init(MAPID, MapProcessName),
    mod_map_actor:init_in_map_role(),
    common_map:set_map_family_id(MapProcessName,MAPID),
    db:dirty_write(?DB_MAP_ONLINE, #r_map_online{
        map_name = MapProcessName, 
        map_id   = MAPID, 
        online   = 0, 
        node     = node()
    }),
    {ok, State}.


%% --------------------------------------------------------------------

handle_call(Request, _From, State) ->
  try
      Reply = do_handle_call(Request, State),
      {reply, Reply, State}
  catch
        T:R ->
          ?ERROR_MSG("module: ~w, line: ~w, Request:~w, type: ~w, reason: ~w,stactraceo: ~w",
                               [?MODULE, ?LINE, Request, T, R,erlang:get_stacktrace()]),
          {reply, exception_hanppened, State}
  end.

handle_cast({map_chat, Content}, State) ->
    catch lists:foreach(fun
		(RoleID) -> 
		 	case get({roleid_to_pid, RoleID}) of
				undefined ->
					ignore;
				Pid ->
					Pid ! {map_chat, Content} 
			end 
	end, get_all_roleid()),
    {noreply, State};
handle_cast(Msg, State) ->
    ?ERROR_MSG("unexpected msg ~w ~w", [Msg, State]),
    {noreply, State}.

handle_info({'EXIT', PID, Reason}, State) ->
    MapID = get_mapid(),
	case get_map_type(MapID) of 
		?MAP_TYPE_COPY->
            ignore;
        _ ->
            %%这里是为了记录副本地图挂掉的原因
            ?ERROR_MSG("严重！！ map exit: MapID=~w,Reason=~w,PID=~w,State=~w", [MapID,Reason,PID,State])
    end,
    {stop, normal, State};

handle_info(Info, State) ->
    try 
        do_handle_info(Info, State) 
    catch
        T:R ->
            case Info of
                {_Unique, _Module, _Method, DataRecord, RoleID, _Pid, _Line}->
                    ?ERROR_MSG("module: ~w, line: ~w, Info:~w, type: ~w, reason: ~w,DataRecord=~w,RoleID=~w,stactraceo: ~w",
                               [?MODULE, ?LINE, Info, T, R,DataRecord,RoleID,erlang:get_stacktrace()]);
                _ ->
                    ?ERROR_MSG("module: ~w, line: ~w, Info:~w, type: ~w, reason: ~w,stactraceo: ~w",
                               [?MODULE, ?LINE, Info, T, R,erlang:get_stacktrace()])
            end
    end,
    {noreply, State}.


terminate(Reason, State) ->
    hook_map:terminate(State#map_state.mapid),
    %%从DB_MAP_ONLINE中删除
    MapName = State#map_state.map_name, 
    catch db:dirty_delete(?DB_MAP_ONLINE,MapName),
    case Reason of
        normal ->
            ignore;
		shutdown ->
			ignore;
        false ->
            ?ERROR_MSG("map terminate : ~w , state: ~w", [Reason, State])
    end,
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------


%% 踢摊位下线
do_handle_call({kick_role_stall, RoleID}, _State) ->
    catch mod_stall:handle({kick_role_stall, RoleID});
do_handle_call({get, Key}, _State) ->
	erlang:get(Key);
do_handle_call({put, Key, Data}, _State) ->
    erlang:put(Key, Data);
do_handle_call({debug_call_function, Mod, Func, Args} , _State) ->
  erlang:apply(Mod, Func, Args);
do_handle_call({Mod, Msg}, State) ->
	Mod:handle(Msg, State);
do_handle_call({apply, M, F, A}, _State) ->
	apply(M, F, A);
do_handle_call(_Request, _State) ->
    {error, unknow_call}.

%% ---------------- Macro -------------------------------------
%% 调用handle/2 的缩写
-define(MODULE_HANDLE_TWO(Module,HandleModule),
    do_handle_info({Unique, Module, Method, DataIn, RoleID, PID, Line}, State) ->
    HandleModule:handle({Unique, Module, Method, DataIn, RoleID, PID, Line}, State)).
%% 调用handle/1 的缩写
-define(MODULE_HANDLE_ONE(Module,HandleModule),
    do_handle_info({Unique, Module, Method, DataIn, RoleID, PID, Line}, _State) ->
    HandleModule:handle({Unique, Module, Method, DataIn, RoleID, PID, Line})).
%% 调用handle/1 同时带上State参数的缩写
-define(MODULE_HANDLE_ONE_STATE(Module,HandleModule),
		do_handle_info({Unique, Module, Method, DataIn, RoleID, PID, Line}, State) ->
		HandleModule:handle({Unique, Module, Method, DataIn, RoleID, PID, Line, State})).

%%地图每帧的循环
do_handle_info(loop_ms, State) -> 
    %%modified by zesen,修改为200ms
    erlang:send_after(200, self(), loop_ms),
    NowMsec = common_tool:now2(),
    erlang:put(now2, NowMsec),    
    hook_map:loop_ms(State#map_state.mapid, NowMsec),
    {noreply, State};
%%地图每秒大循环
do_handle_info(loop, State) ->
    erlang:send_after(1000, self(), loop), 
    erlang:put(now, common_tool:now()),
    MapID = State#map_state.mapid,
    hook_map:loop(MapID),
    {noreply, State};

do_handle_info({apply, Mod, Fun, Args}, _State) ->
    apply(Mod, Fun, Args);
%%对指定的模块发送消息，通用，建议使用
do_handle_info({mod,Module,Msg}, State) ->
    Module:handle(Msg,State);
%%对在线玩家发送指定的消息
do_handle_info({unicast,RoleID,Module,Method,Record}, _State) 
  when is_integer(RoleID),is_integer(Module),is_integer(Method) ->
    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,Module,Method,Record);
do_handle_info({broadcast_insence, ActorList, Module, Method, Toc}, State) ->
   do_broadcast_insence(ActorList, Module, Method, Toc, State);
do_handle_info({mod_map_actor,Msg}, State) ->
    mod_map_actor:handle(Msg,State);
do_handle_info({mod_map_monster,Msg}, State) ->
    mod_map_monster:handle(Msg,State);
%%怪物，角色和其他精灵共有的信息
do_handle_info({mod_map_role,Msg}, State) ->
    mod_map_role:handle(Msg,State);
do_handle_info({mod_stall, Msg}, _State) ->
    mod_stall:handle(Msg);
do_handle_info({mod_stall_list, Msg}, _State) ->
    mod_stall_list:handle(Msg);
do_handle_info({mod_system_notice, Msg}, _State) ->
    mod_system_notice:handle(Msg);
do_handle_info({mod_exchange, Msg}, State) ->
    mod_exchange:handle(Msg,State);
do_handle_info({mod_team_exp, Msg}, _State) ->
    mod_team_exp:handle(Msg);
do_handle_info({mod_goods, Msg}, _State) ->
    mod_goods:handle(Msg);
do_handle_info({mod_map_drop,Msg}, State) ->
    mod_map_drop:handle(Msg,State);
do_handle_info({mod_accumulate_exp, Msg}, _State) ->
    mod_accumulate_exp:handle(Msg);
do_handle_info({mod_fight,Msg}, State) ->
    mof_fight_handler:handle(Msg,State);
do_handle_info({mod_map_family,Msg}, State) ->
    mod_map_family:handle(Msg,State);
do_handle_info({mod_bigpve_fb, Msg}, State) ->
    mod_bigpve_fb:handle(Msg, State);
do_handle_info({mod_spring, Msg}, State) ->
    mod_spring:handle(Msg,State);
do_handle_info({mod_map_ybc,Msg}, State) ->
    mod_map_ybc:handle(Msg,State);
do_handle_info({mod_ybc_family, Msg}, State) ->
    mod_ybc_family:handle(Msg, State);
do_handle_info({mod_map_admin,Msg}, State) ->
    mod_map_admin:handle(Msg,State);
do_handle_info({mod_waroffaction, Msg}, State) ->
    mod_waroffaction:handle(Msg, State);
do_handle_info({mod_map_collect,Msg},State) ->
    mod_map_collect:handle({Msg,State});
do_handle_info({mod_server_npc, Msg}, State) ->
    mod_server_npc:handle(Msg, State);
%% 境界副本
do_handle_info({mod_hero_fb, Msg}, _State) ->
    mod_hero_fb:handle(Msg);
%% 检验副本
do_handle_info({mod_examine_fb, Msg}, _State) ->
    mod_examine_fb:handle(Msg);

%% 玄冥塔
do_handle_info({mod_tower_fb, Msg}, _State) ->
    mod_tower_fb:handle(Msg);

do_handle_info({mod_bomb_fb, Msg}, _State) ->
    mod_bomb_fb:handle(Msg);

do_handle_info({mod_activity, Msg}, _State) ->
    mod_activity:handle(Msg);

%% 组队前端请求消息处理
%%推荐队友。。悲剧的放到这里
do_handle_info({Unique, ?TEAM, ?TEAM_MEMBER_RECOMMEND, _DataRecord, RoleID, _PID, Line}, _State) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            do_team_recommend_error(Unique, ?TEAM, ?TEAM_MEMBER_RECOMMEND, RoleID, ?_LANG_SYSTEM_ERROR, Line);
        RoleMapInfo ->
            #p_map_role{faction_id=FactionID} = RoleMapInfo,
            do_team_recommend(Unique, ?TEAM, ?TEAM_MEMBER_RECOMMEND, RoleID, FactionID, Line, get_all_roleid(), [], 0)
    end;

do_handle_info({Unique, ?TEAM, Method, DataIn, RoleID, Pid, _Line}, _State) ->
    mod_map_team:do_handle_info({Unique, ?TEAM, Method, DataIn, RoleID, Pid});

%% 组队服务端各节点通信消息处理
do_handle_info({mod_map_team, Msg}, _State) ->
    mod_map_team:do_handle_info(Msg);

do_handle_info({mod_special_activity,Msg},_State) ->
    mod_special_activity:handle(Msg);

do_handle_info({mod_crown_arena_fb, Msg}, _State) ->
    mod_crown_arena_fb:handle(Msg);
do_handle_info({mod_crown_arena_cull_fb, Msg}, _State) ->
    mod_crown_arena_cull_fb:handle(Msg);

%%客户端发来的消息以及剩余的直接在map模块中处理的消息
do_handle_info({Unique, ?BUBBLE, ?BUBBLE_SEND, DataRecord, RoleID, _Pid, Line}, State) ->
    ReturnDataRecord = #m_bubble_send_toc{succ=true},
    common_misc:unicast(Line, RoleID, Unique, ?BUBBLE, ?BUBBLE_SEND, ReturnDataRecord),
    mod_map_role:handle({bubble_msg, RoleID, Line, DataRecord}, State);
%%掉落物处理
do_handle_info({Unique, ?MAP, ?MAP_DROPTHING_PICK, DataIn, RoleID, Pid, _Line}, State) ->
    mod_map_drop:handle({Unique, ?MAP, ?MAP_DROPTHING_PICK, DataIn, RoleID, Pid}, State);
%%处理获取目标地图信息请求
do_handle_info({Unique, ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, DataIn, RoleID, _PID, _Line}, State) ->
    mod_map_actor:handle({Unique, ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, DataIn, RoleID}, State);

?MODULE_HANDLE_TWO(?FIGHT,mof_fight_handler);
?MODULE_HANDLE_TWO(?MOVE,mod_move);
?MODULE_HANDLE_TWO(?WAROFFACTION,mod_waroffaction);
?MODULE_HANDLE_TWO(?FAMILY_COLLECT,mod_family_collect);
?MODULE_HANDLE_TWO(?RNKM, mod_mirror_rnkm);
?MODULE_HANDLE_TWO(?CLGM, mod_mirror_clgm);
?MODULE_HANDLE_TWO(?MIRROR_FIGHT, mod_mirror_fb);
?MODULE_HANDLE_TWO(?PET, mod_map_pet);

?MODULE_HANDLE_ONE(?WAROFCITY,mod_warofcity);
?MODULE_HANDLE_ONE(?EXCHANGE,mod_exchange);
?MODULE_HANDLE_ONE(?ACTIVITY,mod_activity);
?MODULE_HANDLE_ONE(?TRADING,mod_trading);
?MODULE_HANDLE_ONE(?COUNTRY_TREASURE,mod_country_treasure);
?MODULE_HANDLE_ONE(?EDUCATE_FB,mod_educate_fb);
?MODULE_HANDLE_ONE(?SCENE_WAR_FB,mod_scene_war_fb);
?MODULE_HANDLE_ONE(?MISSION_FB,mod_mission_fb);
?MODULE_HANDLE_ONE(?ARENA,mod_arena);
?MODULE_HANDLE_ONE(?NATIONBATTLE,mod_nationbattle_fb);
?MODULE_HANDLE_ONE(?ARENABATTLE,mod_arenabattle_fb);
?MODULE_HANDLE_ONE(?CROWN,mod_crown_arena_fb);
?MODULE_HANDLE_ONE(?FB_NPC,mod_fb_npc);
?MODULE_HANDLE_ONE(?WAROFKING,mod_warofking);
?MODULE_HANDLE_ONE(?WAROFMONSTER,mod_warofmonster);
?MODULE_HANDLE_ONE(?BIGPVE,mod_bigpve_fb);
?MODULE_HANDLE_ONE(?EXAMINE_FB,mod_examine_fb);
?MODULE_HANDLE_ONE(?GUARD_FB,mod_guard_fb);
?MODULE_HANDLE_ONE(?FRIEND,mod_friend);
?MODULE_HANDLE_ONE(?MINE_FB,mod_mine_fb);
?MODULE_HANDLE_ONE(?STALL, mod_stall);
?MODULE_HANDLE_ONE(?SYSTEM, mod_system);
?MODULE_HANDLE_ONE(?MONEY_FB, mod_money_fb);
?MODULE_HANDLE_ONE(?SINGLE_FB, mod_single_fb);
?MODULE_HANDLE_ONE(?BOMB_FB, mod_bomb_fb);
?MODULE_HANDLE_ONE(?FASHION, mod_role_fashion);
?MODULE_HANDLE_ONE(?MOUNT, mod_role_mount);
?MODULE_HANDLE_ONE(?TOWER_FB,mod_tower_fb);

%% 活动
?MODULE_HANDLE_ONE(?SPECIAL_ACTIVITY,	mod_special_activity);
?MODULE_HANDLE_ONE_STATE(?ROLE2, 		mod_role2);


%% 第一次进入地图
do_handle_info({first_enter, Info}, State) ->
    mod_map_actor:handle({first_enter, Info}, State);

do_handle_info({Unique, ?MAP, ?MAP_ENTER, DataIn, RoleID, PID, Line}, State) ->
    do_map_enter(Unique, ?MAP, ?MAP_ENTER, DataIn, RoleID, PID, Line, State);

do_handle_info({Unique, ?MAP, ?MAP_CHANGE_MAP, DataIn, RoleID, PID, _Line}, _State) ->
    do_change_map(Unique, ?MAP, ?MAP_CHANGE_MAP, DataIn, RoleID, PID);

do_handle_info({Unique, ?DRIVER, Method, DataIn, RoleID, PID, _Line}, _State) ->
	mod_driver:handle({Unique,?DRIVER,Method,DataIn,RoleID,PID});

do_handle_info({mod_role2, Msg}, _MapState) ->
    mod_role2:handle(Msg);

%% 采集
?MODULE_HANDLE_ONE_STATE(?COLLECT,mod_map_collect);
%% 监狱
?MODULE_HANDLE_ONE_STATE(?JAIL,mod_jail);
%% 英雄副本
?MODULE_HANDLE_ONE_STATE(?HERO_FB,mod_hero_fb);
%% %% 篝火
%% ?MODULE_HANDLE_ONE_STATE(?BONFIRE,mod_map_bonfire);
%% 温泉
?MODULE_HANDLE_ONE_STATE(?SPRING,mod_spring);

%%处理管理后台开启国运
do_handle_info({mod_ybc_person,Msg},_State) ->
    mod_ybc_person:handle(Msg);
do_handle_info({mod_mission_fb, Msg}, _State) ->
    mod_mission_fb:handle(Msg);
do_handle_info({mod_arena, Msg}, _State) ->
    mod_arena:handle(Msg);
do_handle_info({mod_money_fb, Msg}, _State) ->
    mod_money_fb:handle(Msg);
do_handle_info({mod_single_fb, Msg}, _State) ->
    mod_single_fb:handle(Msg);

%% 天工炉炼制模块处理，主要用于内部消息处理
do_handle_info({mod_refining_forging,Msg},_State) ->
    mod_refining_forging:do_handle_info(Msg);

%% 商贸活动
do_handle_info({mod_trading,Msg},_State) ->
    mod_trading:do_handle_info(Msg);

%% 师门同心副本
do_handle_info({mod_educate_fb,Msg},_State) ->
    mod_educate_fb:do_handle_info(Msg);

%% 场景大战副本
do_handle_info({mod_scene_war_fb,Msg},_State) ->
    mod_scene_war_fb:do_handle_info(Msg);

%% 礼包模块
do_handle_info({mod_gift,Msg},_State) ->
    mod_gift:do_handle_info(Msg);

%% %%篝火
%% do_handle_info({mod_map_bonfire,Msg}, _State) ->
%%     mod_map_bonfire:handle(Msg);

%% 藏宝图模块
do_handle_info({mod_cang_bao_tu_fb,Msg}, _State) ->
    mod_cang_bao_tu_fb:do_handle_info(Msg);

%%调用任务handler
do_handle_info({mod_mission_handler, Msg},_State) ->
    mod_mission_handler:handle(Msg);

%%slice内广播
do_handle_info({broadcast_in_sence, RoleIDList, Module, Method, DataRecord}, State) 
  when is_list(RoleIDList) ->
    %%转换格式，这个接口本身只提供给role用
    ActorList = lists:foldl(fun(ID, Acc0) -> [{role, ID} | Acc0] end, [], RoleIDList),
    do_broadcast_insence(ActorList, Module, Method, DataRecord, State);
%%可视范围广播 
do_handle_info({broadcast_in_sence_include, RoleIDList, Module, Method, DataRecord}, State) ->
	ActorList = lists:foldl(fun(ID, Acc0) -> [{role, ID} | Acc0] end, [], RoleIDList),
    do_broadcast_insence_include(ActorList, Module, Method, DataRecord, State);

do_handle_info({enter_family_map, Unique, RoleID, FamilyID, Line, BonfireBurnTime}, _State) ->
    
    IsDoingYbc = common_map:is_doing_ybc(RoleID),
    Module = ?MAP,Method = ?MAP_CHANGE_MAP,
    if
        IsDoingYbc =:= true ->
            ?SEND_ERR_TOC(m_map_change_map_toc,?_LANG_FAMILY_DOING_YBC_CAN_NOT_CHANGE);
        true ->
            MapName = common_map:get_family_map_name(FamilyID),
            case global:whereis_name(MapName) of
                undefined ->
                    ?SEND_ERR_TOC(m_map_change_map_toc,?_LANG_FAMILY_MAP_NOT_STARTED),
                    mod_map_copy:create_family_map_copy(FamilyID, BonfireBurnTime);
                _ ->
                    MapID = 10300,
					mod_map_event:notify({role, RoleID}, change_map),
                    {MapID, TX, TY} = common_misc:get_born_info_by_map(MapID),
                    R = #m_map_change_map_toc{mapid=MapID, tx=TX, ty=TY},
                    common_misc:unicast(Line, RoleID, Unique, ?MAP, ?MAP_CHANGE_MAP, R)
            end
    end;

do_handle_info({func, Fun, Args}, _State) ->
    apply(Fun, Args),
    ok;

do_handle_info({'DOWN', _, _, PID, _}, _State) ->
    RoleID = erlang:erase({pid_to_roleid, PID}),
    erlang:erase({roleid_to_pid, RoleID}),
    erlang:erase({role_msg_queue, PID}),
    ok;

do_handle_info({timeout, TimerRef, {buff_timeout, monster, MonsterID, BuffID}}, State) ->
  mod_monster_buff:handle({buff_timeout, TimerRef, MonsterID, BuffID}, State);

do_handle_info({timeout, TimerRef, {buff_timeout, server_npc, ServerNpcID, BuffID}}, State) ->
  mod_server_npc_buff:handle({buff_timeout, TimerRef, ServerNpcID, BuffID}, State);

do_handle_info(Info, _State) ->
    ?ERROR_MSG("receive unknow msg: ~w", [Info]),  
    ok.

get_slice_name(SX, SY) -> 
    get({slice_name, SX, SY}).


%%根据txty获得sxsy
get_sxsy_by_txty(TX, TY) ->
    State = get_state(),
    #map_state{offsetx=OffsetX, offsety=OffsetY} = State,
    {PX, PY} = common_misc:get_iso_index_mid_vertex(TX, 0, TY),
    PXC = PX + OffsetX,
    PYC = PY + OffsetY,
    SX = common_tool:floor(PXC/?MAP_SLICE_WIDTH),
    SY = common_tool:floor(PYC/?MAP_SLICE_HEIGHT),
    {SX, SY}.
    

%%根据SXSY获得摊位列表
get_slice_dolls(SliceName) ->
    get({slice_dolls, SliceName}).
add_slice_doll(TX, TY, Stall) ->
    {SX, SY} = get_sxsy_by_txty(TX, TY),
    SliceName = get_slice_name(SX, SY),
    Old = get_slice_dolls(SliceName),
    case lists:member(Stall, Old) of
        true ->
            ignore;
        false ->
            put({slice_dolls, SliceName}, [Stall | Old])
    end.
remove_slice_doll(TX, TY, Stall) ->
    {SX, SY} = get_sxsy_by_txty(TX, TY),
    case get_slice_name(SX, SY) of
        undefined ->
            ignore;
        SliceName ->
            Old = get_slice_dolls(SliceName),
            put({slice_dolls, SliceName}, lists:delete(Stall, Old))
    end.

%%根据SXSY获取陷阱列表
get_slice_trap(SliceName) ->
    get({slice_trap, SliceName}).

add_slice_trap(TX, TY, MapTrap) ->
    {SX, SY} = get_sxsy_by_txty(TX, TY),
    SliceName = get_slice_name(SX, SY),
    TrapList = get_slice_trap(SliceName),

    case lists:member(MapTrap, TrapList) of
        true ->
            ignore;
        _ ->
            put({slice_trap, SliceName}, [MapTrap|TrapList])
    end,
    
    MapTrapList = get(map_trap_list),
    case lists:member(MapTrap, MapTrapList) of
        true ->
            ignore;
        _ ->
            put(map_trap_list, [MapTrap|MapTrapList])
    end.

remove_slice_trap(TX, TY, TrapID) ->
    {SX, SY} = get_sxsy_by_txty(TX, TY),
    SliceName = get_slice_name(SX, SY),
    TrapList = get_slice_trap(SliceName),
    MapTrapList = get(map_trap_list),
    
    put({slice_trap, SliceName}, lists:keydelete(TrapID, #p_map_trap.trap_id, TrapList)),
    put(map_trap_list, lists:keydelete(TrapID, #p_map_trap.trap_id, MapTrapList)).

%%拼凑一个slice的名字
concat_slice_name(MAPID, SX, SY) ->
    lists:concat(["pg22_map_slice_", MAPID, "_", SX, "_", SY]).


%%初始化每个slice对应的九宫格，避免之后的重复计算 
init_slice_lists(MapPName, GridWidth,GridHeight) ->
    X = common_tool:ceil(GridWidth/?MAP_SLICE_WIDTH) - 1,
    Y = common_tool:ceil(GridHeight/?MAP_SLICE_HEIGHT) - 1,
    %%为每个slice创建一个pg2，同初始化2每2个slice中的摊位信息为[]
    lists:foreach(
      fun(SX) ->
              lists:foreach(
                fun(SY) ->
                        SliceName = concat_slice_name(MapPName, SX, SY),
                        erlang:put({slice_name, SX, SY}, SliceName),
                        erlang:put({slice_dolls, SliceName}, []),
                        erlang:put({slice_ybc, SliceName}, []),
                        erlang:put({slice_role, SliceName}, []),
                        erlang:put({slice_monster, SliceName}, []),
                        erlang:put({slice_server_npc, SliceName}, []),
                        erlang:put({slice_pet, SliceName}, [])
                end, lists:seq(0, Y))
      end, lists:seq(0, X)),
    lists:foreach(
      fun(SX) ->
              lists:foreach(
                fun(SY) ->
                        Slices9 = get_9slices(X, Y, SX, SY),
                        put({slices, SX, SY}, Slices9)
                end, lists:seq(0, Y))
      end, lists:seq(0, X)).


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
    lists:foldl(
      fun(TempSX, Acc) ->
              lists:foldl(
                fun(TempSY, AccSub) ->
                        Temp = get_slice_name(TempSX, TempSY),
                        [Temp|AccSub]
                end,
                Acc,
                lists:seq(BeginY, EndY)
               )
      end, [], lists:seq(BeginX, EndX)).


%%@doc 获得所有在slice list中的玩家
get_all_in_sence_user_by_slice_list(SliceList) ->
    lists:foldl(
      fun(SliceName, Acc) ->
			lists:merge(mod_map_actor:slice_get_roles(SliceName), Acc)
      end, [], SliceList).

%%@doc 获得所有在Slice list中的怪物
get_all_in_sence_monster_by_slice_list(SliceList)->
    lists:foldl(
      fun(SliceName, Acc) ->
            lists:merge(mod_map_actor:slice_get_monsters(SliceName), Acc)
      end, [], SliceList).

%%@doc 获得所有在Slice list中的ServerNpc
get_all_in_sence_server_npc_by_slice_list(SliceList)->
    lists:foldl(
      fun(SliceName, Acc) ->
            lists:merge(mod_map_actor:slice_get_server_npc(SliceName), Acc)
      end, [], SliceList).


%%slice变化时获得新的slice
get_new_around_slice(NewTX, NewTY, OldTX, OldTY, OffsetX, OffsetY) ->
    case get_9_slice_by_txty(NewTX, NewTY, OffsetX, OffsetY) of
        undefined ->
            [];
        TNew ->
            TOld = get_9_slice_by_txty(OldTX, OldTY, OffsetX, OffsetY),
            lists:filter(
              fun(T) -> 
                      case lists:member(T, TOld) of
                          true ->
                              false;
                          false ->
                              true
                      end
              end, TNew)
    end.


%%在actor列表可视范围内广播消息,不包括列表中actor
do_broadcast_insence(ActorList, Module, Method, DataRecord, State) when is_list(ActorList) ->
    AllSlice = get_9_slice_by_actorid_list(ActorList, State),
    AllInSenceRole = get_all_in_sence_user_by_slice_list(AllSlice),
    %% remove them self
    AllInSenceRole2 = 
        lists:foldl(
          fun({Type, RoleID}, Acc) ->
                  case Type of
                      role ->
                          lists:delete(RoleID, Acc);
                      _ ->
                          Acc
                  end
          end, AllInSenceRole, ActorList),
    broadcast(AllInSenceRole2, ?DEFAULT_UNIQUE, Module, Method, DataRecord);
do_broadcast_insence(ActorList, Module, Method, DataRecord, _) ->
    ?ERROR_MSG("do_broadcast_insence wrong args ~w ~w ~w ~w", 
               [ActorList, Module, Method, DataRecord]),
    ok.

%%用于特殊情况，托管摆摊时角色不在线
do_broadcast_insence_by_txty(TX, TY, Module, Method, DataRecord, State) ->
    OffsetX = State#map_state.offsetx,
    OffsetY = State#map_state.offsety,
    case get_9_slice_by_txty(TX, TY, OffsetX, OffsetY) of
        undefined ->
            ignore;
        Slices ->
            AllInSenceRole = get_all_in_sence_user_by_slice_list(Slices),
            broadcast(AllInSenceRole, ?DEFAULT_UNIQUE, Module, Method, DataRecord)
    end.

do_broadcast_insence_include(ActorList, Module, Method, DataRecord)->
    State = mgeem_map:get_state(),
    do_broadcast_insence_include(ActorList, Module, Method, DataRecord, State).

%%广播在actor列表中的所有actor的可视范围内的玩家，包括这些actor自己
do_broadcast_insence_include(ActorList, Module, Method, DataRecord, State) when is_list(ActorList) ->
    %% 获取列表中所有玩家所在九宫格
    AllSlice = get_9_slice_by_actorid_list(ActorList, State),
    %% 所有所有的视野范围内玩家
    AllInSenceRole = get_all_in_sence_user_by_slice_list(AllSlice),
    broadcast(AllInSenceRole, ?DEFAULT_UNIQUE, Module, Method, DataRecord);
do_broadcast_insence_include(ActorList, Module, Method, DataRecord, _) ->
    ?ERROR_MSG("do_broadcast_insence_include ~ts: ~w ~w ~w ~w", ["出错", ActorList, Module, Method, DataRecord]).

update_role_msg_queue(PID, Binary) ->
    erlang:put({role_msg_queue, PID}, [Binary | erlang:get({role_msg_queue, PID})]).

broadcast(RoleIDList, _Module, _Method, _DataRecord)
  when erlang:length(RoleIDList) =:= 0 ->
    ignore;
broadcast(RoleIDList, Module, Method, DataRecord)
  when is_list(RoleIDList) andalso is_integer(Module) andalso is_integer(Method) ->
	Binary = mgeeg_packet:packet_encode(?DEFAULT_UNIQUE, Module, Method, DataRecord),
	lists:foreach(
	  fun(RoleID) ->
			  case get({roleid_to_pid,RoleID}) of
			  undefined ->
				  ignore;
			  mirror ->
				  ignore;
			  {PID, in_role_process} ->
				  PID ! {binary, Binary};
			  PID ->
				  update_role_msg_queue(PID, Binary)
			  end
	  end, RoleIDList),
	ok.

broadcast(RoleIDList, RoleIDList2, _Unique, Module, Method, DataRecord) ->
    broadcast(RoleIDList, Module, Method, DataRecord),
    broadcast(RoleIDList2, Module, Method, DataRecord),
    ok.

broadcast(RoleIDList, _Unique, Module, Method, DataRecord)
  when is_list(RoleIDList) andalso is_integer(Module) andalso is_integer(Method) ->
    broadcast(RoleIDList, Module, Method, DataRecord),
    ok.

flush_all_role_msg_queue() ->
	lists:foreach(
	  fun(RoleID) ->
			  case get({roleid_to_pid,RoleID}) of
			  undefined ->
				  ignore;
			  mirror ->
				  ignore;
			  PID ->                      
				  case erlang:get({role_msg_queue, PID}) of
					  List when is_list(List), List =/= []->                              
						  PID ! {binaries, lists:reverse(List)},
						  erlang:put({role_msg_queue, PID}, []);
					  _ ->
						  ignore
				  end
			  end
	  end, mgeem_map:get_all_roleid()).  


%%根据格子或者像素位置获得所在的slice名称
get_slice_by_txty(TX, TY, OffsetX, OffsetY) ->
    {PX, PY} = common_misc:get_iso_index_mid_vertex(TX, 0, TY),
    PXC = PX + OffsetX,
    PYC = PY + OffsetY,
    get_slice_by_pxpy(PXC, PYC).
get_slice_by_pxpy(PX, PY) ->
    SX = common_tool:floor(PX/?MAP_SLICE_WIDTH),
    SY = common_tool:floor(PY/?MAP_SLICE_HEIGHT),
    get_slice_name(SX, SY).


%%根据格子所在位置获得九宫格slice
get_9_slice_by_txty(TX, TY, OffsetX, OffsetY) ->
    {PX, PY} = common_misc:get_iso_index_mid_vertex(TX, 0, TY),
    PXC = PX + OffsetX,
    PYC = PY + OffsetY,
    SX = common_tool:floor(PXC/?MAP_SLICE_WIDTH),
    SY = common_tool:floor(PYC/?MAP_SLICE_HEIGHT),
    get({slices, SX, SY}).


%%获得actorid列表中actor所在的所有slice
%% 形式为 [{role, 1}, {monster, 2}, {pet, 2}]
%%actor包括role pet monster
get_9_slice_by_actorid_list(ActorIdList, State) ->
    OffsetX = State#map_state.offsetx,
    OffsetY = State#map_state.offsety,
    lists:foldl(
      fun({ActorType, ActorID}, Acc) ->
              case mod_map_actor:get_actor_txty_by_id(ActorID, ActorType) of
                  {TX, TY} ->
                      case mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY) of
                          undefined ->
                              Acc;
                          Slices ->
                              common_tool:combine_lists(Acc, Slices)
                      end;
                  undefined ->
                      Acc
              end
      end, [], ActorIdList).


%%方便获得state
get_state() ->
    get(?MAP_STATE_KEY).
init_state(State) ->
    put(?MAP_STATE_KEY, State).

get_mapid() ->
    State = get_state(),
    State#map_state.mapid.

get_mapname() ->
    State = get_state(),
    State#map_state.map_name.

do_map_enter(Unique, Module, Method, DataIn, RoleID, PID, Line, State) ->
    %%找不到地角色的地图信息的话直接踢掉。。。
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            mgeem_router:kick_role(RoleID, Line, cant_find_mapinfo);
        RoleMapInfo ->
            MapID = State#map_state.mapid,
            #m_map_enter_tos{map_id=DestMapID} = DataIn,
            %%[{_, Type}], Type =:= 0 -> 普通的地图跳转; Type =:= 1 -> 副本地图
            case get_map_type(DestMapID) of
                ?MAP_TYPE_NORMAL->
                    do_map_enter_normal(Unique, Module, Method, RoleID, PID, RoleMapInfo, MapID, DestMapID, Line, State);
                ?MAP_TYPE_COPY->
                    do_map_enter_copy(Unique, Module, Method, RoleID, PID, RoleMapInfo, MapID, DestMapID, Line, State);
                _ ->
                    %% 地图ID错误
                    mgeem_router:kick_role(RoleID, Line, wrong_map_id)
            end
    end.

do_map_enter_normal(Unique, Module, Method, RoleID, PID, RoleMapInfo, MapID, DestMapID, Line, State) ->
    #p_pos{tx=TX, ty=TY} = RoleMapInfo#p_map_role.pos,
    %%是否可以跳转，站在跳转点上，或者使用了某些特定的方法，如回城卷才能完成跳转，否则踢掉
    case if_can_jump(MapID, DestMapID, TX, TY) of
        {true, IndexTX, IndexTY} ->
            {IndexTX2, IndexTY2} = get_jump_point(MapID, DestMapID, IndexTX, IndexTY),
            do_map_enter_normal2(Unique, Module, Method, RoleID, PID, RoleMapInfo, IndexTX2, IndexTY2,
                                 MapID, DestMapID, Line, State);
        _ ->
            case get({enter, RoleID}) of
                {DestMapID, DestTX, DestTY} ->
                    erase({enter, RoleID}),
                    ChangeMapType = get({change_map_type, RoleID}),

                    if ChangeMapType =:= ?CHANGE_MAP_TYPE_DRIVER ->
                            {DestTX2, DestTY2} = get_jump_point(MapID, DestMapID, DestTX, DestTY);
                       true ->
                            {DestTX2, DestTY2} = {DestTX, DestTY}
                    end,
                    do_map_enter_normal2(Unique, Module, Method, RoleID, PID, RoleMapInfo, DestTX2, DestTY2,
                                         MapID, DestMapID, Line, State);
                _ ->
                    DataRecord = #m_map_enter_toc{succ=false, reason=?_LANG_MAP_ENTER_NOT_IN_JUMP_POINT},
                    ?UNICAST_TOC( DataRecord )
            end
    end.

do_map_enter_normal2(Unique, _Module, _Method, RoleID, PID, RoleMapInfo, DestTX, DestTY,
                     MapID, DestMapID, Line, MapState) ->
    DestMapPName = common_map:get_common_map_name(DestMapID),
    case global:whereis_name(DestMapPName) of
        undefined ->
            ?ERROR_MSG("跳转地图，目标地图地程（~w）不存在！！！", [DestMapID]),
            %% 跳回原点
            do_dest_map_not_exist(Unique, PID, RoleID, RoleMapInfo, MapID);
        MPID ->
            common_map_enter(PID, RoleMapInfo, DestMapID, MPID, DestMapPName, DestTX, DestTY, Unique, Line, MapState)
    end.

-define(IF_THEN_ELSE(Condition,DoTrue,DoFalse),
        case Condition of
            true->
                DoTrue;
            _ ->
                DoFalse
        end
       ).

%%进入副本地图。。10300是宗族副本
do_map_enter_copy(Unique, Module, Method, RoleID, PID, RoleMapInfo, MapID, DestMapID, Line, State) ->
    case common_config_dyn:find(fb_map, DestMapID) of
        [#r_fb_map{is_simple_enter=true,module=FbModule}]->
            do_map_enter_simple_fb(Unique, RoleID, PID, RoleMapInfo, Line, State,FbModule);
        _ ->
            case DestMapID of
                10300 ->    %%宗族地图
                    do_map_enter_family(Unique, RoleID, PID, RoleMapInfo, DestMapID, Line, State);
                10700 ->    %%监狱
                    do_map_enter_normal(Unique, Module, Method, RoleID, PID, RoleMapInfo, MapID, DestMapID, Line, State);
                _ ->
                    ?ERROR_MSG("DestMapID=~w is not expected,RoleID=~w,MapID=~w",[DestMapID,RoleID,MapID]),
                    ignore
            end
    end.

%%比较简单通用的副本地图跳转
do_map_enter_simple_fb(Unique, RoleID, PID, RoleMapInfo, Line, State,FbModule) when is_atom(FbModule)->
	case get({enter, RoleID}) of
        {DestMapID, TX, TY} ->
            FbModule:assert_valid_map_id(DestMapID),
            MapProcessName = FbModule:get_map_name_to_enter(RoleID),
            FbModule:clear_map_enter_tag(RoleID),
            case global:whereis_name(MapProcessName) of
                undefined ->
                    ?ERROR_MSG("跳转副本地图，目标地图进程不存在！！！DestMapID=~w,MapProcessName=~w", [DestMapID,MapProcessName]),
                    %% 跳回原点
                    do_dest_map_not_exist(Unique, PID, RoleID, RoleMapInfo, get_mapid());
                MapPID ->
                    common_map_enter(PID, RoleMapInfo, DestMapID, MapPID, MapProcessName, TX, TY, Unique, Line, State)
            end;
        _ ->
            ?ERROR_MSG("do_map_enter_simple_fb err,RoleID=~w",[RoleID]),
            ok
            %%mgeem_router:kick_role(RoleID, Line, hack_attemp)
    end.
    
do_map_enter_family(Unique, RoleID, PID, RoleMapInfo, DestMapID, Line, State)->
    FamilyID = RoleMapInfo#p_map_role.family_id,
    MapProcessName = common_map:get_family_map_name(FamilyID),
    case global:whereis_name(MapProcessName) of
        undefined ->
            mod_map_copy:create_family_map_copy(FamilyID),
            ?ERROR_MSG("跳转地图，目标地图地程（宗族地图）不存在！！！", []),
            %% 跳回原点
            do_dest_map_not_exist(Unique, PID, RoleID, RoleMapInfo, get_mapid());
        MapPID ->
            FamilyMapID = DestMapID,
            case get({enter, RoleID}) of
                undefined ->
					[{TX, TY}|_] = mcm:born_tiles(FamilyMapID);
                {_, TX, TY} ->
                    ok
            end,
            common_map_enter(PID, RoleMapInfo, FamilyMapID, MapPID, MapProcessName, TX, TY, Unique, Line, State)
    end. 

common_map_enter(RolePID, RoleMapInfo1, DestMapID, DestMapPID, DestMapPName, TX, TY, Unique, Line, State) ->
  #p_map_role{role_id=RoleID} = RoleMapInfo1,
  catch hook_map_role:before_role_quit(RoleID, State#map_state.mapid, DestMapID),
  RoleMapInfo2 = mod_map_actor:get_actor_mapinfo(RoleID, role),
  PetTransfer  = mod_map_pet:get_pet_transfer_info(RoleID),
  %%先退出原来的地图
  ChangeMapType = erase({change_map_type, RoleID}),
  erlang:erase({enter, RoleID}),
  %% 取出要传输的数据
  Pos = #p_pos{tx = TX, ty = TY, dir = 4},
  LastSkillTime        = mof_fight_time:get_last_skill_time(role, RoleID),
  {ok,RoleState}       = mod_map_role:get_role_state(RoleID),
  {ok,GrayTime,PKTime} = mod_map_role:clear_role_timer(RoleState),
  mod_map_actor:do_change_map_quit(role, ChangeMapType, RoleID, DestMapPName, DestMapID, Pos, State),
  
  NewState = case ChangeMapType of
      ?CHANGE_MAP_TYPE_RELIVE ->
          ?ROLE_STATE_NORMAL;
      _ ->
          RoleMapInfo2#p_map_role.state
  end,

  RoleMapInfo3 = case PetTransfer of
    [{{map_pet_info,PetID}, _}] ->
        PetInfo = mod_map_pet:get_pet_info(RoleID,PetID),
        PetTypeID = PetInfo#p_pet.type_id,
        RoleMapInfo2#p_map_role{
          state               = NewState, 
          from_mapid          = get_mapid(), 
          pos                 = Pos, 
          last_walk_path      = undefined,
          summoned_pet_id     = PetID,
          summoned_pet_typeid = PetTypeID
        };
    [] ->
        RoleMapInfo2#p_map_role{
          state               = NewState, 
          from_mapid          = get_mapid(), 
          pos                 = Pos, 
          last_walk_path      = undefined
        }
  end,

  MapDataTransfer1 = [
    {role_map_info,   RoleMapInfo3}, 
    {last_skill_time, LastSkillTime},
    {gray_time,       GrayTime},
    {pk_time,         PKTime},
    {role_state,      RoleState}
  |PetTransfer] ,
  MapDataTransfer2 = case erase({apply_after_enter_map, RoleID}) of
      undefined -> MapDataTransfer1;
      MFA       -> [{apply_after_enter_map, MFA}|MapDataTransfer1]
  end,
  DestMapPID ! {mod_map_actor, {enter, Unique, RolePID, RoleID, MapDataTransfer2, Line}}.

if_can_jump(_MapID, 10123, _X, _Y) ->
    [{X, Y}] = mcm:born_tiles(10123),
    {true, X, Y};
if_can_jump(MapID, DestMapID, TX, TY) ->
    lists:foldl(
      fun({DestMapID2, X, Y, IndexTX, IndexTY}, Acc) ->
              if DestMapID == DestMapID2 andalso abs(X-TX) =< 5 andalso abs(Y-TY) =< 5 ->
                      {true, IndexTX, IndexTY};
                 true ->
                      Acc
              end
      end, false, mcm:jump_tiles(MapID)).

%%客户端普通地图跳转流程: change_map_tos(服务端做些验证，现在暂时没有) -> change_map_toc -> map_enter_tos -> map_enter_toc
do_change_map(Unique, Module, Method, DataIn, RoleID, PID) ->
    #m_map_change_map_tos{mapid=DestMapID, tx=TX, ty=TY} = DataIn,
    case catch check_can_change_map(RoleID, DestMapID) of
        ok ->
			mod_map_event:notify({role, RoleID}, change_map),
            put({change_map_type, RoleID}, ?CHANGE_MAP_TYPE_NORMAL),
            DataRecord = #m_map_change_map_toc{mapid=DestMapID, tx=TX, ty=TY};
        {error, Reason} ->
            DataRecord = #m_map_change_map_toc{succ=false, reason=Reason};
        R ->
            ?ERROR_MSG("do_change_map, error: ~w", [R]),
            DataRecord = #m_map_change_map_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
    end,
    ?UNICAST_TOC( DataRecord ).

check_can_change_map(RoleID, DestMapID) ->
    case get({change_map_type, RoleID}) of
        undefined ->
            ok;
        _ ->
            throw({error, ?_LANG_MAP_TRANSFER_TRANSFERING})
    end,
    case common_config_dyn:find(map_level_limit, DestMapID) of
        [Level] -> ok;
        [] -> 
            ?ERROR_MSG("map_level_limit没有配~w的最低进入等级, 默认进入等级为0", [DestMapID]),
            Level = 0
    end,
    RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
    #p_map_role{level=RoleLevel, faction_id=FactionID} = RoleMapInfo,
    %% 等级判断
    case RoleLevel >= Level of
        true ->
            ok;
        _ ->
            throw({error, list_to_binary(io_lib:format(?_LANG_MAP_TRANSFER_LEVEL_LIMIT, [Level]))})
    end,
    MapID = get_mapid(),
    case MapID =:= DestMapID of
        true ->
            throw({error, ?_LANG_MAP_TRANSFER_DEST_MAP_ALREADY});
        _ ->
            ok
    end,
    {ok, MapFactionID} = common_map:get_faction_id_by_map_id(MapID),
    [SafeMapList] = common_config_dyn:find(etc, safe_map),
    IsSafeMap = lists:member(DestMapID, SafeMapList),
    %% 不能进入外国的安全地图
    case IsSafeMap andalso MapFactionID =/= FactionID of
        true ->
            throw({error, ?_LANG_MAP_TRANSFER_OTHER_FACTION_SAFE_MAP});
        _ ->
            ok
    end,
    case mod_ybc_person:faction_ybc_status(MapFactionID) of
        {activing, {PastTime, _}} ->
            if
                %%国运前10分钟T人
                PastTime =< 600 andalso MapFactionID =/= FactionID ->
                    HomeMapID = common_misc:get_home_mapid(FactionID, MapID),
                    {_, TX, TY} = common_misc:get_born_info_by_map(HomeMapID),
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RETURN_HOME, RoleID, HomeMapID, TX, TY),
                    common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_SYSTEM], ?_LANG_PERSON_YBC_CLEAR_OTHER_FACTION_ROLE),
                    throw({error, ?_LANG_DRIVER_MAP_FACTION_DOING_PERSONYBC_FACTION});
                true ->
                    ok
            end;
        _ ->
            ok
    end.

do_team_recommend(Unique, Module, Method, RoleID, _FactionID, Line, [], InfoList, _Counter) ->
    do_team_recommend2(Unique, Module, Method, RoleID, Line, InfoList);
do_team_recommend(Unique, Module, Method, RoleID, _FactionID, Line, _TargetIDList, InfoList, 5) ->
    do_team_recommend2(Unique, Module, Method, RoleID, Line, InfoList);
do_team_recommend(Unique, Module, Method, RoleID, FactionID, Line, [TargetID|T], InfoList, Counter) ->
    case mod_map_actor:get_actor_mapinfo(TargetID, role) of
        undefined ->
            do_team_recommend(Unique, Module, Method, RoleID, FactionID, Line, T, InfoList, Counter);
        TRoleMapInfo ->
            #p_map_role{role_name=_TRoleName, faction_id=TFactionID, level=TLevel, team_id=TTeamID} = TRoleMapInfo,

            case TLevel >= 18 andalso TTeamID =:= 0 andalso FactionID =:= TFactionID andalso TargetID =/= RoleID of
                true ->
                    ok;%%TODO 任务重构备忘修改
                _ ->
                    do_team_recommend(Unique, Module, Method, RoleID, FactionID, Line, T, InfoList, Counter)
            end
    end.

do_team_recommend2(Unique, Module, Method, RoleID, Line, InfoList) ->
    DataRecord = #m_team_member_recommend_toc{member_info=InfoList},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).

do_team_recommend_error(Unique, Module, Method, RoleID, Reason, Line) ->
    DataRecord = #m_team_member_recommend_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).

%% @doc 获取跳转点，国战期间一些地图随机取一个跳转点
get_jump_point(_FromMapID, _MapID, TX, TY) ->
    {TX, TY}.

%% @doc 目标地图进程不存在，跳回原点    
do_dest_map_not_exist(Unique, PID, RoleID, RoleMapInfo, MapID) ->
    #p_map_role{pos=#p_pos{tx=DestTX2, ty=DestTY2}} = RoleMapInfo,
    DataRecord = #m_map_enter_toc{succ=false},
    common_misc:unicast2(PID, Unique, ?MAP, ?MAP_ENTER, DataRecord),
    PID ! {sure_enter_map_need_change_pos, erlang:self()},
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RETURN_HOME, RoleID, MapID, DestTX2, DestTY2).
