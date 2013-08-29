%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com(C) 2011, 
%%% @doc
%%% 大明宝藏副本模块
%%% @end
%%% Created : 25 Jan 2011 by  <caochuncheng>
%%%-------------------------------------------------------------------
-module(mod_country_treasure).

-include("mgeem.hrl").
-include("country_treasure.hrl").
%% API
-export([
     %% 地图初始化时，大明宝藏初始化
     init/2,
     %% 地图循环处理函数，即一秒循环
     loop/2
    ]).

-export([
     do_handle_info/1,handle/1,handle/2,
     hook_role_map_enter/2,
     hook_role_quit/1,
     hook_role_before_quit/1,
     hook_role_dead/3,
     get_default_map_id/0,
     add_country_points/2,
     get_collect_broadcast_msg/5,
     get_country_treasure_fb_map_id/0,
     get_relive_home_pos/2,
     get_buff_item/3,
     add_award_items/2
    ]).
-export([
     assert_valid_map_id/1,
     get_map_name_to_enter/1,
     clear_map_enter_tag/1,
     close_buff_item/1
    ]).

-export([is_in_treasure_fb_map_id/1]).

-export([
     init_country_treasure_dict/1,
     put_country_treasure_dict/2,
     get_country_treasure_dict/1,
     put_country_treasure_role_number/2,
     get_country_treasure_role_number/1
    ]).

%% 国家积分
-define(country_points, country_points).
%% 各国ID
-define(faction_hongwu, 1).
-define(faction_yongle, 2).
-define(faction_wanli, 3).
%% 加经验间隔
-define(EXP_ADD_INTERVAL, 10).
-define(INTERVAL_EXP_LIST, interval_exp_list).

-define(COUNTRY_ROLE_INFO, country_role_info).

-record(r_country_role_info, {role_infos=[]}).
%% kill_times: 击杀敌人次数
%% be_killed_times: 被击杀次数
-record(r_role_info, {role_id, kill_times=0, be_killed_times=0, total_kill_times = 0}).

-define(BUFF_KILL_TYPE, 0). 
-define(BUFF_BE_KILLED_TYPE, 1).
-define(ENTER_TYPE_VIP, 2).

-define(ERR_COUNTRY_TREASURE_ENTER_MAX_ROLE_NUM,61007).
-define(ERR_COUNTRY_TREASURE_ENTER_VIP_LIMIT,61008).

-define(ERR_COUNTRY_TREASURE_BUFF_NOT_ENOUGH_BAG_POS, 610001).  %% 背包满了，请整理
-define(ERR_CHANGE_SKIN_MISSION_CAN_NOT_ENTER, 61009).  %%唐僧取经任务中，不能进入副本
-define(CONFIG_NAME,country_treasure).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

%%%===================================================================
%%% API
%%%===================================================================
handle(Info,_State) ->
  handle(Info).

handle(Info) ->
  do_handle_info(Info).

is_in_treasure_fb_map_id(MapId)->
  get_country_treasure_fb_map_id() =:= MapId.

%%@doc 获取默认的大明宝藏的地图ID
get_default_map_id()->
  ?COUNTRY_TREASURE_MAP_ID.

%% 进入明宝藏地图入口NPC所在的地图
get_enter_fb_map_ids() ->
  [10260].

assert_valid_map_id(DestMapID)->
  case DestMapID of
    ?COUNTRY_TREASURE_MAP_ID->
      ok;
    _ ->
      ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
      throw({error,error_map_id,DestMapID})
  end.

%% @doc 获取复活的回城点
get_relive_home_pos(RoleMapInfo, MapID) when is_record(RoleMapInfo,p_map_role)->
  #p_map_role{faction_id=FactionID} = RoleMapInfo,
  {TX, TY} = get_country_treasure_fb_born_points(FactionID),
  {MapID, TX, TY}.


%%地图跳转前，获得这条友进入的竞技场地图名称
get_map_name_to_enter(_RoleID)->
  common_map:get_common_map_name( ?COUNTRY_TREASURE_MAP_ID).

clear_map_enter_tag(_RoleID)->
  ignore.


init_country_treasure_dict(MapId) ->
  NowSeconds = common_tool:now(),
  {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
  TodayWeek = calendar:day_of_the_week(NowDate),
  Record = #r_country_treasure_dict{
                    week = TodayWeek,
                    start_time = 0,
                    end_time = 0,
                    next_bc_start_time = 0,
                    next_bc_end_time = 0,
                    next_bc_process_time = 0,
                    before_interval = 0,
                    close_interval = 0,
                    process_interval = 0,
                    min_role_level = 20},
  erlang:put({?COUNTRY_TREASURE_RECORD_DICT_PREFIX,MapId},Record).
put_country_treasure_dict(MapId,Record) ->
  erlang:put({?COUNTRY_TREASURE_RECORD_DICT_PREFIX,MapId},Record).
get_country_treasure_dict(MapId) ->
  erlang:get({?COUNTRY_TREASURE_RECORD_DICT_PREFIX,MapId}).


put_country_treasure_role_number(MapId,Number) ->
  erlang:put({country_treasure_role_number,MapId},Number).
get_country_treasure_role_number(MapId) ->
  erlang:get({country_treasure_role_number,MapId}).

syn_country_treasure_role_number(Type,Number) ->
  EnterFbMapIdList = get_enter_fb_map_ids(),
  lists:foreach(
    fun(MapId) ->
        MapProcessName = common_map:get_common_map_name(MapId),
        catch global:send(MapProcessName,{mod,?MODULE,{enter_ct_fb_number,Type,MapId,Number}})
    end,EnterFbMapIdList).
%% 地图初始化时，大明宝藏初始化
%% 参数：
%% MapId 地图id
%% MapName 地图进程名称
init(MapId, MapName) ->
  FBMapId = get_country_treasure_fb_map_id(),
  [IsOpenCountryTreasure] = ?find_config(is_open_country_treasure),
  case FBMapId =:= MapId andalso IsOpenCountryTreasure =:= true of
    true ->
      init2(MapId, MapName);
    _ ->
      ignore
  end,
  %% 在三个京城地图初始化大明宝藏当前的人数
  EnterFbMapIdList = get_enter_fb_map_ids(),
  case lists:member(MapId,EnterFbMapIdList) of 
    true ->
      put_country_treasure_role_number(MapId,0);
    false ->
      ignore
  end.

init2(MapId, _MapName) ->
  NowSeconds = common_tool:now(),
  Record = get_country_treasure_dict_record(NowSeconds),
  put_country_treasure_dict(MapId,Record),
  %% 重置积分
  reset_country_points(),
  %% 重置玩家击杀记录
  reset_country_role_info_list().

%% 地图循环处理函数，即一秒循环
%% 参数
%% MapId 地图id
loop(MapId,NowSeconds) ->
  FBMapId = get_country_treasure_fb_map_id(),
  [IsOpenCountryTreasure] = ?find_config(is_open_country_treasure),
  case FBMapId =:= MapId andalso IsOpenCountryTreasure =:= true of
    true ->
      loop2(MapId,NowSeconds);
    _ ->
      ignore
  end.
loop2(MapId,NowSeconds) ->
  Record = get_country_treasure_dict(MapId),
  #r_country_treasure_dict{week = Week,kick_role_time = KickRoleTime} = Record,
  %% 当关闭时，有玩家进入副本时，不能正常被踢回京城
  Record2 = 
    if KickRoleTime =/= 0 andalso NowSeconds > (KickRoleTime - 65)  ->
         if KickRoleTime > NowSeconds  ->
            catch kick_all_role_from_fb_map(),
            Record;
          true ->
            catch kick_all_role_from_fb_map(),
            NewRecord = Record#r_country_treasure_dict{kick_role_time = 0},
            put_country_treasure_dict(MapId,NewRecord),
            NewRecord
         end;
       true ->
         Record
    end,
  {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
  TodayWeek = calendar:day_of_the_week(NowDate),
  if Week =:= TodayWeek ->
       loop3(MapId,NowSeconds,Record2);
     true ->
       next
  end,
  %% 加经验循环
  do_add_exp_interval(NowSeconds).
loop3(MapId,NowSeconds,Record) ->
  #r_country_treasure_dict{start_time=StartTime, end_time = EndTime} = Record,
  case {erlang:get(notice_flag), NowSeconds >= StartTime andalso EndTime >= NowSeconds} of
    {undefined, true} ->
      erlang:put(notice_flag, true),
      common_activity:notfiy_activity_start({?ACTIVITY_TASK_COUNTRY_TREASURE, NowSeconds, StartTime, EndTime});
    _ ->
      ignore
  end,
  %% 副本开起提前广播开始消息
  Record2 = do_fb_open_before_broadcast(MapId,NowSeconds,Record),
  %% 副本开启过程中广播处理
  Record3 = do_fb_open_process_broadcast(MapId,NowSeconds,Record2),
  %% 副本开起过程中，需要提前广播副本关闭信息
  Record4 = do_fb_open_close_broadcast(MapId,NowSeconds,Record3),
  put_country_treasure_dict(MapId,Record4),
  
  if EndTime =/= 0
       andalso NowSeconds > EndTime ->
       %% 本次副本结束处理，计算下次开启时间，还有副本结束广播
       NewRecord = get_country_treasure_dict_record(NowSeconds),
       put_country_treasure_dict(MapId,NewRecord#r_country_treasure_dict{kick_role_time = NowSeconds + 80}),
       %% 结束广播以及BUFF加成
       end_broadcast_and_buff(),
       catch kick_all_role_from_fb_map(),
       %% 重置积分
       reset_country_points(),
       %% 重置玩家击杀记录
       reset_country_role_info_list(),
       syn_country_treasure_role_number(reset,0),
       NextStartTime = NewRecord#r_country_treasure_dict.start_time,
       EndMessageF = 
         if NextStartTime > 0 ->
            {{NextY,NextM,NextD},{NextHH,NextMM,_NextSS}} = common_tool:seconds_to_datetime(NextStartTime), 
            NextStartTimeStr = 
              if NextMM < 10 ->
                 lists:flatten(io_lib:format("~w-~w-~w ~w:0~w",[NextY,NextM,NextD,NextHH,NextMM]));
               true ->
                 lists:flatten(io_lib:format("~w-~w-~w ~w:~w",[NextY,NextM,NextD,NextHH,NextMM]))
              end,
            lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_E_CHAT,[NextStartTimeStr]));
          true ->
            ?_LANG_COUNTRY_TREASURE_E_CHAT_F
         end,
       catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,EndMessageF),
       erlang:erase(notice_flag),
       % mod_activity:notice_activity_end(),
       common_activity:notfiy_activity_end(?ACTIVITY_TASK_COUNTRY_TREASURE);
     true ->
       next
  end,    
  ok.


%% 副本开起提前广播开始消息
%% Record 结构为 r_country_treasure_dict
%% 返回 new r_country_treasure_dict
do_fb_open_before_broadcast(_MapId,NowSeconds,Record) ->
  #r_country_treasure_dict{
               start_time = StartTime,
               end_time = EndTime,
               next_bc_start_time = NextBCStartTime,
               before_interval = BeforeInterval} = Record,
  if StartTime =/= 0 
       andalso EndTime =/= 0 
       andalso NextBCStartTime =/= 0
       andalso NowSeconds >= NextBCStartTime 
       andalso NowSeconds < StartTime->
       %% 副本开起提前广播开始消息
       BeforeSeconds = if (StartTime - NowSeconds) < 0 -> 0; true -> (StartTime - NowSeconds) end,
       BeforeMessage = 
         if BeforeSeconds > 0 -> 
            {_Date,{H,M,_S}} = common_tool:seconds_to_datetime(StartTime),
            StartTimeStr = 
              if M < 10 ->
                 lists:flatten(io_lib:format("~w:0~w",[H,M]));
               true ->
                 lists:flatten(io_lib:format("~w:~w",[H,M]))
              end,
            lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_B_CHAT,[StartTimeStr]));
          true ->
            lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_B_CHAT_OK,[]))
         end,
       catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,BeforeMessage),
       Record#r_country_treasure_dict{
                      next_bc_start_time = NowSeconds + BeforeInterval};
     true ->
       Record
  end.
%% 副本开启过程中广播处理
%% Record 结构为 r_country_treasure_dict
%% 返回
do_fb_open_process_broadcast(_MapId,NowSeconds,Record) ->
  #r_country_treasure_dict{
               start_time = StartTime,
               end_time = EndTime,
               next_bc_process_time = NextBCProcessTime,
               process_interval = ProcessInterval} = Record,
  ?DEV("NowSeconds=~w,NextBCProcessTime=~w,tttt=~w",[NowSeconds,NextBCProcessTime,NowSeconds-NextBCProcessTime]),
  if StartTime =/= 0 
       andalso EndTime =/= 0 
       andalso NowSeconds >= StartTime
       andalso EndTime >= NowSeconds 
       andalso NextBCProcessTime =/= 0
       andalso NowSeconds >= NextBCProcessTime ->
       %% 副本开起过程中广播时间到
       ProcessMessage = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_P_CHAT,[])),
       catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,ProcessMessage),
       Record#r_country_treasure_dict{
                      next_bc_process_time = NowSeconds + ProcessInterval};
     true ->
       Record
  end.
%% 副本开起过程中，需要提前广播副本关闭信息
%% Record 结构为 r_country_treasure_dict
do_fb_open_close_broadcast(_MapId,NowSeconds,Record) ->
  #r_country_treasure_dict{
               start_time = StartTime,
               end_time = EndTime,
               next_bc_end_time = NextBCEndTime,
               close_interval = CloseInterval} = Record,
  if StartTime =/= 0 
       andalso EndTime =/= 0 
       andalso NowSeconds >= StartTime
       andalso EndTime >= NowSeconds
       andalso NextBCEndTime =/= 0
       andalso NowSeconds >= NextBCEndTime ->
       %% 副本开起过程中，需要提前广播副本关闭信息
       if (EndTime - NowSeconds) < 0 ->
          next;
        true ->
          {_Date,{H,M,_S}} = common_tool:seconds_to_datetime(EndTime),
          EndTimeStr = 
            if M < 10 ->
               lists:flatten(io_lib:format("~w:0~w",[H,M]));
             true ->
               lists:flatten(io_lib:format("~w:~w",[H,M]))
            end,
          EndMessage = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_E_CENTER,[EndTimeStr])),
          catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,EndMessage)
       end,
       Record#r_country_treasure_dict{
                      next_bc_end_time = NowSeconds + CloseInterval};
     true ->
       Record
  end.


%% 进入大明宝藏副本
do_handle_info({Unique, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ENTER, DataRecord, RoleID, PId, Line})
  when erlang:is_record(DataRecord,m_country_treasure_enter_tos)->
  do_country_treasure_enter({Unique, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ENTER, DataRecord, RoleID, PId, Line});

%% 退出大明宝藏副本
do_handle_info({Unique, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_QUIT, DataRecord, RoleID, PId, Line})
  when erlang:is_record(DataRecord,m_country_treasure_quit_tos)->
  do_country_treasure_quit({Unique, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_QUIT, DataRecord, RoleID, PId, Line});

%% 查询大明宝藏副本信息
do_handle_info({Unique, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_QUERY, DataRecord, RoleID, PId, Line})
  when erlang:is_record(DataRecord,m_country_treasure_query_tos)->
  do_country_treasure_query({Unique, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_QUERY, DataRecord, RoleID, PId, Line});

%% 后台管理手工开起大明宝藏副本
%% IntervalSeconds 多少秒之后开启
do_handle_info({admin_open_fb}) ->
  do_admin_open_fb();
do_handle_info({enter_ct_fb_number,Type,MapId,Number}) ->
  do_enter_ct_fb_number(Type,MapId,Number);

do_handle_info({country_treasure_query,{Unique, Module, Method, DataRecord, RoleID, PId, Line}}) ->
  do_country_treasure_query({Unique, Module, Method, DataRecord, RoleID, PId, Line});

do_handle_info(Info) ->
  ?ERROR_MSG("~ts,Info=~w",["商贸活动模块无法处理此消息",Info]),
  error.


%% 进入大明宝藏副本
%% DataRecord 结构为 m_country_treasure_enter_tos
do_country_treasure_enter({Unique, Module, Method, DataRecord, RoleID, PID, Line}) ->
  case catch check_country_treasure_enter({Unique, Module, Method, DataRecord, RoleID, PID, Line}) of
    {error,ErrCode,Reason}->
      #m_country_treasure_enter_tos{enter_type=EnterType} = DataRecord,
      R2 = #m_country_treasure_enter_toc{error_code=ErrCode,reason=Reason,enter_type=EnterType},
      ?UNICAST_TOC(R2);
    {ok,RoleMapInfo} ->
      do_country_treasure_enter3({Unique, Module, Method, DataRecord, RoleID, PID, Line},RoleMapInfo)
  end.
check_country_treasure_enter({_Unique, _Module, _Method, DataRecord, RoleID, _PId, _Line}) ->
  #m_country_treasure_enter_tos{map_id=MapId,npc_id=NpcId,enter_type=EnterType} = DataRecord,
  case ?find_config(is_open_country_treasure) of
    [true] ->
      next;
    _ ->
      ?THROW_ERR_REASON( ?_LANG_COUNTRY_TREASURE_NOT_OPEN)
  end,
  CurMapId = mgeem_map:get_mapid(),
  if MapId =:= CurMapId ->
       next;
     true ->
       ?THROW_ERR_REASON( ?_LANG_COUNTRY_TREASURE_ENTER_PARAM_ERROR )
  end,
  
  %%唐僧取经任务中，不能进入副本呢
  case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
    true ->
      ?THROW_ERR(?ERR_CHANGE_SKIN_MISSION_CAN_NOT_ENTER);
    false ->
      next
  end,
  
  %% 检查玩家是否在NPC附近
  case check_valid_distance(CurMapId,RoleID,NpcId) of
    true ->
      next;
    false ->
      ?THROW_ERR_REASON( ?_LANG_COUNTRY_TREASURE_NOT_VALID_DISTANCE )
  end,
  RoleMapInfo = 
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
      undefined ->
        ?THROW_ERR_REASON( ?_LANG_COUNTRY_TREASURE_ENTER_PARAM_ERROR );
      RoleMapInfoT ->
        RoleMapInfoT
    end,
  CheckLevel = 
    case ?find_config(enter_fb_role_level) of
      [CheckLevelT] ->
        CheckLevelT;
      _ ->
        20
    end,
  if RoleMapInfo#p_map_role.level >= CheckLevel ->
       next;
     true ->
       Reason = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_ENTER_LEVEL,[common_tool:to_list(CheckLevel)])),
       ?THROW_ERR_REASON( Reason )
  end,
  %% 检查参数Npc是否合法
  case check_valid_npc_id(MapId,NpcId) of
    true ->
      next;
    false ->
      ?DBG(),
      ?THROW_ERR_REASON( ?_LANG_COUNTRY_TREASURE_ENTER_PARAM_ERROR )
  end,
  %% 检查当前是不是合法的时间进入大明宝藏副本
  case check_valid_enter_fb_time() of
    true ->
      next;
    false ->
      ?THROW_ERR_REASON( ?_LANG_COUNTRY_TREASURE_NOT_OPEN_TIME )
  end,
  [{NormalMaxRoleNum,AllMaxRoleNum}] = ?find_config(limit_fb_role_num),
  case get_country_treasure_role_number(MapId) of
    undefined ->
      next;
    CurRoleNum ->
      case check_direct_enter_vip(EnterType,RoleID) of
        true->
          if
            CurRoleNum>=AllMaxRoleNum->
              ?THROW_ERR( ?ERR_COUNTRY_TREASURE_ENTER_MAX_ROLE_NUM );
            true->
              next
          end;
        {false,ErrorCode}->
          ?THROW_ERR( ErrorCode );
        _ ->
          if
            CurRoleNum>=NormalMaxRoleNum->
              ?THROW_ERR( ?ERR_COUNTRY_TREASURE_ENTER_MAX_ROLE_NUM );
            true->
              next
          end
      end
  end,
  {ok,RoleMapInfo}.

%%判断是否为VIP直接进入
check_direct_enter_vip(?ENTER_TYPE_VIP,RoleID)->
  case mod_map_actor:get_actor_mapinfo(RoleID, role) of
    #p_map_role{vip_level=VipLevel} ->
      case ?find_config( direct_enter_vip_level) of
        [EnterVip] when VipLevel>= EnterVip->
          true;
        _ ->
          {false,?ERR_COUNTRY_TREASURE_ENTER_VIP_LIMIT}
      end;
    _ -> false
  end;
check_direct_enter_vip(_,_)->
  false.


do_country_treasure_enter3({Unique, Module, Method, DataRecord, RoleID, PID, Line},
               RoleMapInfo) ->
  [Fee] = ?find_config(enter_fb_fee),
  case catch common_transaction:transaction(
       fun() ->  
           deduct_enter_country_treasure_fee(RoleMapInfo,Fee)  
       end) of
    {atomic, {ok, RoleAttr}} ->
      do_country_treasure_enter4({Unique, Module, Method, DataRecord, RoleID, PID, Line},
                     RoleMapInfo,RoleAttr);
    {aborted, Reason} ->
      Reason2 =
        if erlang:is_binary(Reason) ->
             Reason;
           true ->
            ?DBG(Reason),
             ?_LANG_COUNTRY_TREASURE_ENTER_PARAM_ERROR
        end,
      #m_country_treasure_enter_tos{enter_type=EnterType} = DataRecord,
      R2 = #m_country_treasure_enter_toc{error_code=?ERR_OTHER_ERR,reason=Reason2,enter_type=EnterType},
      ?UNICAST_TOC(R2)
  end.
do_country_treasure_enter4({Unique, Module, Method, DataRecord, RoleID, PID, _Line},
               _RoleMapInfo,RoleAttr) ->
  hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_COUNTRY_TREASURE),
  #m_country_treasure_enter_tos{enter_type=EnterType} = DataRecord,
  R2 = #m_country_treasure_enter_toc{enter_type=EnterType},
  ?UNICAST_TOC(R2),
  
  UnicastArg = {role, RoleID},
  AttrChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value = RoleAttr#p_role_attr.silver},
            #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value = RoleAttr#p_role_attr.silver_bind}],
  common_misc:role_attr_change_notify(UnicastArg,RoleID,AttrChangeList),
  syn_country_treasure_role_number(update,1),
  %% 根据玩家的国家信息查找大明宝藏副本的出生点
  {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
  RoleFactionID = RoleBase#p_role_base.faction_id,
  FBMapId = get_country_treasure_fb_map_id(),
  {Tx,Ty} = get_country_treasure_fb_born_points(RoleFactionID),
  mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_COUNTRY_TREASURE, RoleID, FBMapId, Tx, Ty),
  %%===记录玩家进入大明宝藏的日志===
  global:send(mgeew_country_treasure_log_server,{RoleID,RoleAttr#p_role_attr.level}),
  ok.

%% 扣除手续费
deduct_enter_country_treasure_fee(RoleMapInfo,MsgFee) ->
  RoleID = RoleMapInfo#p_map_role.role_id,
  {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
  SilverBind = RoleAttr#p_role_attr.silver_bind,
  Silver = RoleAttr#p_role_attr.silver,
  if (SilverBind + Silver) < MsgFee ->
       db:abort(?_LANG_COUNTRY_TREASURE_ENTER_ENOUGH_MONEY);
     true ->
       next
  end,
  if SilverBind < MsgFee ->
       NewSilver = Silver - (MsgFee - SilverBind),
       if NewSilver < 0 ->
          db:abort(?_LANG_COUNTRY_TREASURE_ENTER_ENOUGH_MONEY);
        true ->
          NewRoleAttr = RoleAttr#p_role_attr{silver_bind=0,silver=NewSilver },
          mod_map_role:set_role_attr(RoleID, NewRoleAttr),
          common_consume_logger:use_silver({RoleID, SilverBind, (MsgFee - SilverBind), ?CONSUME_TYPE_SILVER_COUNTER_TREASURE, ""}),
          {ok, NewRoleAttr}
       end;
     true ->
       NewSilverBind = SilverBind - MsgFee,
       NewRoleAttr = RoleAttr#p_role_attr{silver_bind=NewSilverBind},
       mod_map_role:set_role_attr(RoleID, NewRoleAttr),
       common_consume_logger:use_silver({RoleID, MsgFee, 0, ?CONSUME_TYPE_SILVER_COUNTER_TREASURE, ""}),
       {ok, NewRoleAttr}
  end.
%% 退出大明宝藏副本
%% DataRecord 结构为 m_country_treasure_quit_tos
do_country_treasure_quit({Unique, Module, Method, DataRecord, RoleID, PId, Line}) ->
  case catch do_country_treasure_quit2({Unique, Module, Method, DataRecord, RoleID, PId, Line}) of
    {error,Reason} ->
      do_country_treasure_quit_error({Unique, Module, Method, DataRecord, RoleID, PId, Line},Reason);
    {ok,_RoleMapInfo} ->
      do_country_treasure_quit3({Unique, Module, Method, DataRecord, RoleID, PId, Line})
  end.
do_country_treasure_quit2({_Unique, _Module, _Method, DataRecord, RoleID, _PId, _Line}) ->
  MapId = DataRecord#m_country_treasure_quit_tos.map_id,
  FBMapId = get_country_treasure_fb_map_id(),
  CurMapId = mgeem_map:get_mapid(),
  if MapId =:= CurMapId 
       andalso MapId =:= FBMapId ->
       next;
     true ->
       erlang:throw({error,?_LANG_COUNTRY_TREASURE_QUIT_PARAM_ERROR})
  end,
  RoleMapInfo = 
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
      undefined ->
        erlang:throw({error,?_LANG_COUNTRY_TREASURE_QUIT_PARAM_ERROR});
      RoleMapInfoT ->
        RoleMapInfoT
    end,
  {ok,RoleMapInfo}.

do_country_treasure_quit3({Unique, Module, Method, _DataRecord, RoleID, PId, _Line}) ->
  SendSelf = #m_country_treasure_quit_toc{succ = true},
  common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
  {MapId,Tx,Ty} = common_misc:get_home_born(),
  mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapId, Tx, Ty),
  ok.

do_country_treasure_quit_error({Unique, Module, Method, _DataRecord, _RoleID, PId, _Line},Reason) ->
  SendSelf = #m_country_treasure_quit_toc{succ = false,reason = Reason},
  common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_country_treasure_query({Unique, Module, Method, DataRecord, RoleID, PId, Line}) ->
  if DataRecord#m_country_treasure_query_tos.op_type =:= 1 ->
       FbMapId = get_default_map_id(),
       CurMapId = mgeem_map:get_mapid(),
       if FbMapId =:= CurMapId ->
          do_country_treasure_query2({Unique, Module, Method, DataRecord, RoleID, PId, Line});
        true ->
          case global:whereis_name(common_map:get_common_map_name(FbMapId)) of 
            undefined ->
              SendSelf = #m_country_treasure_query_toc{succ = false,op_type = 1},
              common_misc:unicast2(PId, Unique, Module, Method, SendSelf);
            Pid ->
              Pid ! {mod,?MODULE,{country_treasure_query,{Unique, Module, Method, DataRecord, RoleID, PId, Line}}}
          end
       end;
     true ->
       do_country_treasure_query3({Unique, Module, Method, DataRecord, RoleID, PId, Line})
  end.
do_country_treasure_query2({Unique, Module, Method, _DataRecord, _RoleID, PId, _Line}) ->
  MapId = mgeem_map:get_mapid(),
  DictRecord = get_country_treasure_dict(MapId),
  #r_country_treasure_dict{end_time = EndTime,start_time = StartTime} = DictRecord,
  NowSeconds = common_tool:now(),
  [{NpcId,SeedFee}] = ?find_config(bc_all_role_join),
  SendSelf = 
    if NowSeconds >= StartTime andalso NowSeconds < EndTime ->
         #m_country_treasure_query_toc{succ = true,op_type = 1,fb_start_time = StartTime,
                       fb_end_time = EndTime,npc_id = NpcId, fee = SeedFee};
       true ->
         #m_country_treasure_query_toc{succ = false,op_type = 1}
    end,
  common_misc:unicast2(PId, Unique, Module, Method, SendSelf).
%% 处理玩家传送
do_country_treasure_query3({Unique, Module, Method, DataRecord, RoleID, PId, Line}) ->
  case catch do_country_treasure_query4(RoleID,DataRecord) of
    {error,Reason,ReasonCode} ->
      do_country_treasure_query_error({Unique, Module, Method, DataRecord, RoleID, PId, Line},Reason,ReasonCode);
    {ok,RoleMapInfo} ->
      do_country_treasure_query5({Unique, Module, Method, DataRecord, RoleID, PId, Line},RoleMapInfo)
  end.
do_country_treasure_query4(RoleID,_DataRecord) ->
  RoleMapInfo = 
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
      undefined ->
        erlang:throw({error,?_LANG_COUNTRY_TREASURE_QUERY_ERROR,0});
      RoleMapInfoT ->
        RoleMapInfoT
    end,
  [CheckLevel] = ?find_config(enter_fb_role_level),
  if RoleMapInfo#p_map_role.level >= CheckLevel ->
       next;
     true ->
       Reason = lists:flatten(io_lib:format(?_LANG_COUNTRY_TREASURE_ENTER_LEVEL,[common_tool:to_list(CheckLevel)])),
       erlang:throw({error,Reason,0})
  end,
  case mod_map_role:is_role_fighting(RoleID) of
    true ->
      erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_FIGHTING_STATUS,0});
    false ->
      next
  end,
  if RoleMapInfo#p_map_role.state =:= ?ROLE_STATE_STALL 
                  orelse RoleMapInfo#p_map_role.state =:= ?ROLE_STATE_STALL_AUTO
                                  orelse RoleMapInfo#p_map_role.state =:= ?ROLE_STATE_STALL_SELF ->
       erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_STALL_STATUS,0});
     RoleMapInfo#p_map_role.state =:= ?ROLE_STATE_DEAD ->
       erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_DEAD_STATUS,0});
     RoleMapInfo#p_map_role.state =:= ?ROLE_STATE_FIGHT ->
       erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_FIGHTING_STATUS,0});
     RoleMapInfo#p_map_role.state =:= ?ROLE_STATE_EXCHANGE ->
       erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_EXCHANGE_STATUS,0});
     true ->
       next
  end,
  case mod_horse_racing:is_role_in_horse_racing(RoleID) of
    true ->
      erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_HORSE_RACING_STATUS,0});
    _ ->
      ignore
  end,
  
  %% 商贸状态
  [RoleState] = db:dirty_read(?DB_ROLE_STATE, RoleID),
  if RoleState#r_role_state.trading =:= 1 ->
       erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_TRADING_STATUS,0});
     RoleState#r_role_state.exchange =:= true ->
       erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_EXCHANGE_STATUS,0});
     true ->
       next
  end,
  CurMapId = mgeem_map:get_mapid(),
  case CurMapId rem 10000 div 1000 of
    0 ->
      case CurMapId rem 10000 rem 1000 div 100 of
        2 ->
          next;
        3 ->
          next;
        _ ->
          erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_FB_MAP,0})
      end;
    1 ->
      next;
    2 ->
      next;
    3 ->
      next;
    _ ->
      erlang:throw({error,?_LANG_COUNTRY_TREASURE_IN_SPECIAL_MAP,0})
  end,
  %% 检查当前是不是合法的时间进入大明宝藏副本
  case check_valid_enter_fb_time() of
    true ->
      next;
    false ->
      erlang:throw({error,?_LANG_COUNTRY_TREASURE_NOT_OPEN_TIME,0})
  end,
  {ok,RoleMapInfo}.

do_country_treasure_query5({Unique, Module, Method, DataRecord, RoleID, PId, Line},RoleMapInfo) ->
  [{NpcId,Fee}] = ?find_config(bc_all_role_join),
  NpcId2 = NpcId + RoleMapInfo#p_map_role.faction_id * 1000000,
  case catch common_transaction:transaction(
       fun() ->  
           deduct_enter_country_treasure_fee(RoleMapInfo,Fee)  
       end) of
    {atomic, {ok, RoleAttr}} ->
      do_country_treasure_query6({Unique, Module, Method, DataRecord, RoleID, PId, Line},
                     RoleMapInfo,RoleAttr,NpcId2,Fee);
    {aborted, Reason} ->
      Reason2 =
        if erlang:is_binary(Reason) ->
             Reason;
           true ->
             ?_LANG_COUNTRY_TREASURE_QUERY_ERROR
        end,
      do_country_treasure_query_error({Unique, Module, Method, DataRecord, RoleID, PId, Line},Reason2,0)
  end.
do_country_treasure_query6({Unique, Module, Method, DataRecord, RoleID, PId, _Line},
               _RoleMapInfo,RoleAttr,_NpcId,Fee) ->
  SendSelf = #m_country_treasure_query_toc{
                       succ = true,
                       op_type = DataRecord#m_country_treasure_query_tos.op_type,
                       fee = Fee
                      },
  common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
  UnicastArg = {role, RoleID},
  AttrChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value = RoleAttr#p_role_attr.silver},
            #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value = RoleAttr#p_role_attr.silver_bind}],
  common_misc:role_attr_change_notify(UnicastArg,RoleID,AttrChangeList),
  {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
  RoleFactionID = RoleBase#p_role_base.faction_id,
  {DestTx,DestTy} = get_country_treasure_fb_born_points(RoleFactionID),
  DestMapId = get_default_map_id(),
  mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_COUNTRY_TREASURE, RoleID, DestMapId, DestTx, DestTy),
  global:send(mgeew_country_treasure_log_server,{RoleID,RoleAttr#p_role_attr.level}),
  ok.
do_country_treasure_query_error({Unique, Module, Method, DataRecord, _RoleID, PId, _Line},Reason,ReasonCode) ->
  SendSelf = #m_country_treasure_query_toc{
                       succ = false,
                       op_type = DataRecord#m_country_treasure_query_tos.op_type,
                       reason = Reason,
                       reason_code = ReasonCode},
  common_misc:unicast2(PId, Unique, Module, Method, SendSelf).
%% 后台管理手工开起大明宝藏副本
%% 同时将关闭开服延迟开启的设置
%% IntervalSeconds 多少秒之后开启
do_admin_open_fb() ->
  MapId = mgeem_map:get_mapid(),
  NowSeconds = common_tool:now(),
  Record = get_country_treasure_dict_record(NowSeconds),
  put_country_treasure_dict(MapId,Record).

do_enter_ct_fb_number(Type,MapId,Number) ->
  EnterFbMapIdList = get_enter_fb_map_ids(),
  case lists:member(MapId,EnterFbMapIdList) of
    true ->
      OldNumber = get_country_treasure_role_number(MapId),
      case Type of
        reset ->
          put_country_treasure_role_number(MapId,0);
        update ->
          NewNumber = if (OldNumber + Number) < 0 -> 0;true -> OldNumber + Number end,
          put_country_treasure_role_number(MapId,NewNumber)
      end;
    false ->
      ignore
  end.

%% 获取大明宝藏副本地图
get_country_treasure_fb_map_id() ->
  [Value] = ?find_config(fb_map_id),
  Value.

%% 获取玩家的信息查找大明宝藏副本地图的出生点
%% 返回 {tx,ty}
get_country_treasure_fb_born_points(FactionID) ->
  case ?find_config(fb_born_points) of
    [DataList] ->
      case lists:keyfind(FactionID,#r_country_treasure_born.map_id,DataList) of
        false ->
          {90,90};
        #r_country_treasure_born{born_points = PointList} ->
          Length = erlang:length(PointList),
          RandomNumber = common_tool:random(1,Length),
          lists:nth(RandomNumber,PointList)
      end;
    _ ->
      {90,90}
  end.
%% 检查参数Npc是否合法
%% 返回 true or false
check_valid_npc_id(MapId,NpcId) ->
  case ?find_config(fb_born_points) of
    [DataList] ->
      case lists:keyfind(MapId,#r_country_treasure_born.map_id,DataList) of
        false ->
          false;
        Record ->
          if Record#r_country_treasure_born.map_id =:= MapId
                              andalso Record#r_country_treasure_born.npc_id =:= NpcId ->
               true;
             true ->
               false
          end
      end;
    _ ->
      false
  end.

%% 根据副本时间和当前时间计算相应的广播时间
%% 返回 {NextBCStartTime,NextBCEndTime,NextBCProcessTime}
get_next_bc_times(NowSeconds,StartTime,EndTime) ->
  [{BeforeSeconds,BeforeInterval}] =  ?find_config(fb_open_before_msg_bc),
  [{CloseSeconds,CloseInterval}] =  ?find_config(fb_open_close_msg_bc),
  [{ProcessInterval}] =  ?find_config(fb_open_process_msg_bc),
  NextBCStartTime = 
    if NowSeconds >= StartTime ->
         0;
       true ->
         if (StartTime - NowSeconds) >= BeforeSeconds ->
            StartTime - BeforeSeconds;
          true ->
            NowSeconds
         end
    end,
  NextBCEndTime = 
    if NowSeconds >= EndTime ->
         0;
       true ->
         if (EndTime - NowSeconds) >= CloseSeconds ->
            EndTime - CloseSeconds;
          true ->
            NowSeconds
         end
    end,
  NextBCProcessTime =
    if NowSeconds > StartTime 
         andalso EndTime > NowSeconds ->
         NowSeconds;
       true ->
         if StartTime =/= 0 ->
            StartTime;
          true ->
            0
         end
    end,
  {NextBCStartTime,NextBCEndTime,NextBCProcessTime,
   BeforeInterval,CloseInterval,ProcessInterval}.

%% 获取大明宝藏开启结束相关进程字典信息
%% 返回 r_country_treasure_dict
get_country_treasure_dict_record(NowSeconds) ->
  %% 根据当前时间获取开始下次大明宝藏副本的时间
  %% 返回 {ok,Week,StartTime,EndTime} or {error,not_found)
  case get_next_time_open_country_treasure(7,NowSeconds) of
    {error,not_found} ->
      #r_country_treasure_dict{
                   week = 0,
                   start_time = 0,
                   end_time = 0,
                   next_bc_start_time = 0,
                   next_bc_end_time = 0,
                   next_bc_process_time = 0,
                   before_interval = 0,
                   close_interval = 0,
                   process_interval = 0,
                   min_role_level = 20};
    {ok,Week,StartTime,EndTime} ->
      {NextBCStartTime,NextBCEndTime,NextBCProcessTime,
       BeforeInterval,CloseInterval,ProcessInterval} =
        get_next_bc_times(NowSeconds,StartTime,EndTime),
      [MinRoleLevel] = ?find_config(enter_fb_role_level),
      #r_country_treasure_dict{
                   week = Week,
                   start_time = StartTime,
                   end_time = EndTime,
                   next_bc_start_time = NextBCStartTime,
                   next_bc_end_time = NextBCEndTime,
                   next_bc_process_time = NextBCProcessTime,
                   before_interval = BeforeInterval,
                   close_interval = CloseInterval,
                   process_interval = ProcessInterval,
                   min_role_level = MinRoleLevel}
  end.


%% 根据当前时间获取开始下次大明宝藏副本的时间
%% NextDays 查询范围，下几天的开始时间，
%% NowSeconds 当前时间秒数 
%% 返回 {ok,Week,StartTime,EndTime} or {error,not_found)
get_next_time_open_country_treasure(NextDays,NowSeconds) ->
  {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
  {Week,OpenTimeList} = get_country_treasure_open_times(NowSeconds),
  case get_next_time_open_country_treasure1(NowDate,NowSeconds,OpenTimeList) of
    {false,_,_} ->
      if NextDays < 0 ->
           {error,not_found};
         true ->
           NextSeconds = common_tool:datetime_to_seconds({NowDate,{0,0,0}}) + 24 * 60 * 60,
           get_next_time_open_country_treasure(NextDays -1,NextSeconds)
      end;
    {true,StartTime,EndTime} ->
      {ok,Week,StartTime,EndTime}
  end.
get_next_time_open_country_treasure1(NowDate,NowSeconds,OpenTimeList) ->
  [IsActiveOpenDay] = ?find_config( open_day_flag),
  IsOpenFirstDay = is_open_first_day(NowDate), %% NowDate是否为开服第一天
  OpenDaySeconds = common_tool:datetime_to_seconds(common_config:get_open_day()),
  {ExtraOpenMinSeconds, ExtraOpenMaxSeconds} = get_open_day_extra_range(),
  [DelaySeconds] = ?find_config( open_day_delay_second),
  lists:foldl(
    fun({StartTime,EndTime},Acc) ->
        {Flag,_AccS,_AccE} = Acc,
        case Flag of
          true ->
            Acc;
          false ->
            StartSeconds = common_tool:datetime_to_seconds({NowDate,StartTime}),
            EndSeconds = common_tool:datetime_to_seconds({NowDate,EndTime}),
            LastSeconds = EndSeconds - StartSeconds,
            {Status, StartTimeAcc, EndTimeAcc} = 
              if IsActiveOpenDay andalso IsOpenFirstDay 
                 andalso OpenDaySeconds >= ExtraOpenMinSeconds andalso ExtraOpenMaxSeconds > OpenDaySeconds ->
                 OpenDayStartSeconds = OpenDaySeconds + DelaySeconds,
                 OpenDayEndSeconds = OpenDaySeconds + DelaySeconds + LastSeconds,
                 if NowSeconds >= OpenDayStartSeconds andalso NowSeconds < OpenDayEndSeconds ->
                    {true, OpenDayStartSeconds, OpenDayEndSeconds};
                  NowSeconds >= OpenDayEndSeconds ->
                    Acc;
                  OpenDayStartSeconds >= NowSeconds ->
                    {true, OpenDayStartSeconds, OpenDayEndSeconds};
                  true ->
                    Acc
                 end;
               true ->
                 Acc
              end,
            
            case Status of
              true ->
                {Status, StartTimeAcc, EndTimeAcc};
              _ ->
                if NowSeconds >= StartSeconds andalso NowSeconds < EndSeconds ->
                   {true,StartSeconds,EndSeconds};
                 NowSeconds >= EndSeconds ->
                   Acc;
                 StartSeconds >=  NowSeconds ->
                   {true,StartSeconds,EndSeconds};
                 true ->
                   Acc
                end
            end
        
        end
    end,{false,0,0},OpenTimeList).

%% 当前是否为开服第一天
is_open_first_day(NowDate) ->
  {OpenDate, _OpenTime} = common_config:get_open_day(),
  OpenDate =:= NowDate.

%% 开服的第一天可延长的时间段
get_open_day_extra_range() ->
  {OpenDate, _OpenTime} = common_config:get_open_day(),
  [{ExtraOpenMinTime, ExtraOpenMaxTime}] = ?find_config( open_day_delay_time),
  ExtraOpenMinSeconds = common_tool:datetime_to_seconds({OpenDate, ExtraOpenMinTime}),
  ExtraOpenMaxSeconds = common_tool:datetime_to_seconds({OpenDate, ExtraOpenMaxTime}),
  {ExtraOpenMinSeconds, ExtraOpenMaxSeconds}.

%% 获取今天大明宝藏副本开启起的时间配置
%% 返回 {Week,[]},or {Week,[{StartTime,EndTime},...]}
get_country_treasure_open_times(NowSeconds) ->
  {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
  TodayWeek = calendar:day_of_the_week(NowDate),
  case ?find_config(open_times) of
    [DataList] ->
      case lists:keyfind(TodayWeek,1,DataList) of
        false ->
          {TodayWeek,[]};
        {TodayWeek,TimeList} ->
          {TodayWeek,TimeList}
      end;
    _ ->
      {TodayWeek,[]}
  end.

%% 检查当前是不是合法的时间进入大明宝藏副本
%% 返回 true or false
check_valid_enter_fb_time() ->
  case ?find_config(open_times) of
    [DataList] ->
      check_valid_enter_fb_time2(DataList);
    _ ->
      false
  end.
check_valid_enter_fb_time2(DataList) ->
  NowSeconds = common_tool:now(),
  {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
  TodayWeek = calendar:day_of_the_week(NowDate),
  case lists:keyfind(TodayWeek,1,DataList) of
    false ->
      false;
    {TodayWeek,TimeList} ->
      check_valid_enter_fb_time3(NowSeconds,NowDate,TodayWeek,TimeList)
  end.
check_valid_enter_fb_time3(NowSeconds,NowDate,_TodayWeek,TimeList) ->
  [IsActiveOpenDay] = ?find_config( open_day_flag),
  IsOpenFirstDay = is_open_first_day(NowDate), %% NowDate是否为开服第一天
  OpenDaySeconds = common_tool:datetime_to_seconds(common_config:get_open_day()),
  {ExtraOpenMinSeconds, ExtraOpenMaxSeconds} = get_open_day_extra_range(),
  [DelaySeconds] = ?find_config( open_day_delay_second),
  lists:foldl(
    fun({{SH,SM,SS},{EH,EM,ES}},Acc) ->
        case Acc of
          true ->
            Acc;
          false ->
            StartSeconds = common_tool:datetime_to_seconds({NowDate,{SH,SM,SS}}),
            EndSeconds = common_tool:datetime_to_seconds({NowDate,{EH,EM,ES}}),
            LastSeconds = EndSeconds - StartSeconds,
            Status = 
              if IsActiveOpenDay andalso IsOpenFirstDay 
                 andalso OpenDaySeconds >= ExtraOpenMinSeconds andalso ExtraOpenMaxSeconds > OpenDaySeconds ->
                 OpenDayStartSeconds = OpenDaySeconds + DelaySeconds,
                 OpenDayEndSeconds = OpenDaySeconds + DelaySeconds + LastSeconds,
                 if NowSeconds >= OpenDayStartSeconds andalso OpenDayEndSeconds >= NowSeconds ->
                    true;
                  true ->
                    Acc
                 end;
               true ->
                 Acc
              end,
            
            case Status of
              true ->
                Status;
              false ->
                %% 属于开服第一天延迟开放时间段
                if IsActiveOpenDay andalso IsOpenFirstDay 
                   andalso OpenDaySeconds >= ExtraOpenMinSeconds 
                   andalso ExtraOpenMaxSeconds > OpenDaySeconds 
                   andalso StartSeconds >= ExtraOpenMinSeconds + DelaySeconds 
                   andalso ExtraOpenMaxSeconds + DelaySeconds + LastSeconds >= EndSeconds ->
                   Acc;
                 NowSeconds >= StartSeconds andalso EndSeconds >= NowSeconds ->
                   true;
                 true ->
                   Acc
                end
            end
        
        end
    end,false,TimeList).


%% 检查玩家是否在有效的距离内
%% 参数
%% RoleID 玩家 id
%% NpcId 商贸商店NPC ID
%% 返回 true or false
check_valid_distance(10260,_RoleID,_NpcId) -> true;
check_valid_distance(MapID,RoleID,NpcId) ->
  {NpcId, Tx, Ty} = lists:keyfind(NpcId, 1, mcm:npc_tiles(MapID)),
  {MaxTx,MaxTy} = get_npc_valid_distance(),
  case mod_map_actor:get_actor_pos(RoleID, role) of
    undefined ->
      false;
    Pos ->
      #p_pos{tx=InTx, ty=InTy} = Pos,
      TxDiff = erlang:abs(InTx - Tx),
      TyDiff = erlang:abs(InTy - Ty),
      if TxDiff < MaxTx  andalso TyDiff < MaxTy ->
           true;
         true ->
           false
      end
  end. 
%% 商贸活动玩家与NPC的有效距离 {tx,ty}
get_npc_valid_distance() ->
  case ?find_config(npc_valid_distance) of
    [Value] ->
      Value;
    _ ->
      {10,10}
  end.

%% 副本结束，将还在地图的所有人踢出副本地图
kick_all_role_from_fb_map() ->
  RoleIDList = mod_map_actor:get_in_map_role(),
  lists:foreach(
    fun(RoleID) ->
        %% 退出大明宝藏地图时，需要取消采集状态
        catch mod_role_busy:stop(RoleID),
          ?DBG(RoleID),
        common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?COUNTRY_TREASURE,?COUNTRY_TREASURE_QUIT,#m_country_treasure_quit_toc{}),
        {MapId,Tx,Ty} = common_misc:get_home_born(),
        mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapId, Tx, Ty)
    end,RoleIDList).
  % earse_interval_exp_list().

%% 玩家进入大明宝藏地图需要处理的
hook_role_map_enter(RoleID,MapId) ->
  if 
    MapId =:= ?COUNTRY_TREASURE_MAP_ID ->
      case check_valid_enter_fb_time() of
        true ->
          mod_role2:do_pk_mode_modify_for_10500(RoleID,?PK_FACTION),
          % %% 插入加经验列表
          % insert_interval_exp_list(RoleID),
          
          common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ENTER, #m_country_treasure_enter_toc{}),
          
          %% 推积分
          DataRecord = get_country_points_record(),
          common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_POINTS, DataRecord),
          
          notify_country_role_info(RoleID);
        false ->%%时间不对，踢回主城
          {MapID, TX, TY} = common_misc:get_home_born(),
          mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapID, TX, TY)
      end;
    true ->
      mgeer_role:run(RoleID, fun() ->mod_country_treasure:close_buff_item(RoleID) end)
  end.

hook_role_quit(_RoleID) ->
  MapId = mgeem_map:get_mapid(),
  FBMapId = get_default_map_id(),
  if FBMapId =:= MapId ->
       syn_country_treasure_role_number(update,-1);
       %% 移出加经验列表
       % delete_interval_exp_list(RoleID);
     true ->
       ignore
  end.

hook_role_before_quit(RoleID)->
  MapId = mgeem_map:get_mapid(),
  FBMapId = get_default_map_id(),
  if FBMapId =:= MapId ->
       mgeer_role:run(RoleID, fun() ->
                      mod_country_treasure:close_buff_item(RoleID) 
              end);
     true ->
       ignore
  end.
close_buff_item(RoleID) ->
  [BuffItemList] = ?find_config(buff_item_list),
  F = fun(TypeID) ->
        TransFun = fun()-> 
                   [BuffList] = ?find_config(can_use_buff_list),
                   mod_role_buff:del_buff(RoleID, BuffList),
                   mod_bag:delete_goods_by_typeid(RoleID,TypeID)
               end,
        case common_transaction:t( TransFun ) of
          {atomic, {ok,DeleteList}} ->
            ?TRY_CATCH( common_misc:del_goods_notify({role,RoleID},DeleteList), Err1);
          {aborted, Reason} ->
            ?ERROR_MSG("clear_country_treasure_item error:~w",[Reason])
        end
    end,
  lists:foreach(F, BuffItemList).


%% @doc 重置积分
reset_country_points() ->
  [DefaultPoints] = ?find_config( default_country_points),
  %% 依次为仙界、妖界、魔界
  put(?country_points, [DefaultPoints, DefaultPoints, DefaultPoints]).

%% @doc 增加国家积分，返回其它两个国家减少积分
add_country_points(FactionID, AddPoints) ->
  [HongWu, YongLe, WanLi] = get(?country_points),
  
  if
    FactionID =:= ?faction_hongwu ->
      YongLe2 = num_reduce(YongLe, AddPoints),
      WanLi2 = num_reduce(WanLi, AddPoints),
      AddPoints2 = YongLe + WanLi - YongLe2 - WanLi2,
      HongWu2 = HongWu + AddPoints2,
      put(?country_points, [HongWu2, YongLe2, WanLi2]),
      {{?faction_yongle, YongLe-YongLe2}, {?faction_wanli, WanLi-WanLi2}};
    
    FactionID =:= ?faction_yongle ->
      HongWu2 = num_reduce(HongWu, AddPoints),
      WanLi2 = num_reduce(WanLi, AddPoints),
      AddPoints2 = HongWu + WanLi - HongWu2 - WanLi2,
      YongLe2 = YongLe + AddPoints2,
      put(?country_points, [HongWu2, YongLe2, WanLi2]),
      {{?faction_hongwu, HongWu-HongWu2}, {?faction_wanli, WanLi-WanLi2}};
    
    true ->
      HongWu2 = num_reduce(HongWu, AddPoints),
      YongLe2 = num_reduce(YongLe, AddPoints),
      AddPoints2 = HongWu + YongLe - HongWu2 - YongLe2,
      WanLi2 = WanLi + AddPoints2,
      put(?country_points, [HongWu2, YongLe2, WanLi2]),
      {{?faction_hongwu, HongWu-HongWu2}, {?faction_yongle, YongLe-YongLe2}}
  end.

%% @doc 减
num_reduce(Num, Reduce) ->
  case Num - Reduce >= 0 of 
    true ->
      Num - Reduce;
    _ ->
      0
  end.

%% @doc 采集HOOK
get_collect_broadcast_msg(RoleName, FactionID, FactionName, Addr, GoodsName) ->
  [DefaultAdd] = ?find_config( default_points_add),
  %% 增加国家积分
  {{ReduceF1, ReduceP1}, {ReduceF2, ReduceP2}} = add_country_points(FactionID, DefaultAdd),
  %% 地图广播积分变动
  broadcast_points_change(),
  %% 获取广播内容
  Msg = io_lib:format(?_LANG_COLLECT_CHAT_BROADCAST_2_10500, [FactionName, RoleName, Addr, GoodsName]),
  
  if
    ReduceP1 =/= 0 andalso ReduceP2 =/= 0 ->
      MsgTail = io_lib:format(?_LANG_COLLECT_CENTER_BROADCAST_2_10500_TAIL_1, 
                  [get_faction_name(ReduceF1), get_faction_name(ReduceF2), FactionName]);
    
    ReduceP1 =/= 0 orelse ReduceP2 =/= 0 ->
      case ReduceP1 of
        0 ->
          ReduceFaction = ReduceP1;
        _ ->
          ReduceFaction = ReduceP2 
      end,
      
      MsgTail = io_lib:format(?_LANG_COLLECT_CENTER_BROADCAST_2_10500_TAIL_2, 
                  [get_faction_name(ReduceFaction), FactionName]);
    
    true ->
      MsgTail = io_lib:format(?_LANG_COLLECT_CENTER_BROADCAST_2_10500_TAIL_3,
                  [get_faction_name(ReduceF1), get_faction_name(ReduceF2), FactionName])
  end,
  
  lists:flatten(lists:append(Msg, MsgTail)).

%% @doc 获取国家名称
get_faction_name(FactionID) ->
  case FactionID of
    ?faction_hongwu ->
      ?_LANG_COLLECT_HONGWU_COLOR;
    ?faction_yongle ->
      ?_LANG_COLLECT_YONGLE_COLOR;
    _ ->
      ?_LANG_COLLECT_WANLI_COLOR
  end.

%% @doc 获取积分
get_country_points_record() ->
  {_, AllPoints} =
    lists:foldl(
      fun(Points, {FactionID, Acc}) ->
          {FactionID+1, [#p_country_points{faction_id=FactionID,
                           points=Points}|Acc]}
      end, {1, []}, get(?country_points)),              
  
  #m_country_treasure_points_toc{points=AllPoints}.

%% @doc 广播积分变动
broadcast_points_change() ->
  DataRecord = get_country_points_record(),
  
  lists:foreach(
    fun(RoleID) ->
        common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_POINTS, DataRecord)
    end, mod_map_actor:get_in_map_role()). 

%% @doc 计算排名
country_points_rank() ->
  PointsList = get(?country_points),
  {_, PointsList2} = 
    lists:foldl(
      fun(Points, {FactionID, Acc}) ->
          {FactionID+1, [{FactionID, Points}|Acc]}
      end, {1, []}, PointsList),
  PointsList3 = lists:reverse(lists:keysort(2, PointsList2)),
  [{_, Max}|_] = PointsList3,
  
  {_, RankList, WinList, _} =
    lists:foldl(
      fun({FactionID, Points}, {RankID, Acc, Acc2, LastPoints}) ->
          case Points =:= LastPoints of
            true ->
              case RankID of
                1 ->
                  {RankID, [{FactionID, RankID}|Acc], [FactionID|Acc2], Points};
                _ ->
                  {RankID, [{FactionID, RankID}|Acc], Acc2, Points}
              end;
            _ ->
              {RankID+1, [{FactionID, RankID+1}|Acc], Acc2, Points}
          end
      end, {1, [], [], Max}, PointsList3),
  
  {RankList, WinList}.

%% @doc 结束广播
get_fb_end_broadcast(WinList) ->
  Msg = 
    case WinList of
      [F1] ->
        io_lib:format(?_LANG_COUNTRY_TREASURE_QUIT_BROADCAST_1, [get_faction_name(F1), get_faction_name(F1)]);
      
      [F1, F2] ->
        io_lib:format(?_LANG_COUNTRY_TREASURE_QUIT_BROADCAST_2, [get_faction_name(F1), get_faction_name(F2),
                                     get_faction_name(F1), get_faction_name(F2)]);
      
      _ ->
        ?_LANG_COUNTRY_TREASURE_QUIT_BROADCAST_3
    end,
  
  lists:flatten(Msg).

%% @doc 结束广播
end_broadcast_and_buff() ->
  {RankList, WinList} = country_points_rank(),
  
  lists:foreach(
    fun(RoleID) ->
        case mod_map_actor:get_actor_mapinfo(RoleID, role) of
          undefined ->
            ignore;
          
          #p_map_role{faction_id=FID} ->
            {_FID, RankID} = lists:keyfind(FID, 1, RankList),
            [AwardItems] = ?find_config(erlang:list_to_atom("faction_award_" ++ erlang:integer_to_list(RankID))),
            send_award(RoleID, AwardItems)
            % if
            %   RankID =:= 1 ->
            %     [AwardItems] = ?find_config( faction_1_award),
            %     send_award(RoleID, AwardItems);
            %   RankID =:= 2 ->
            %     [BuffList] = ?find_config( faction_second_buff),
            %     Random = random:uniform(length(BuffList)),
            %     AddBuff = lists:nth(Random, BuffList),
            %     add_buff(RoleID, [AddBuff]);
            %   true ->
            %     ignore
            % end
        end
    end, mod_map_actor:get_in_map_role()),
  
  Msg = get_fb_end_broadcast(WinList),
  common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg).

send_award(RoleID, AwardItems) ->
  Fun = fun() ->mod_country_treasure:add_award_items(RoleID, AwardItems) end,
  mgeer_role:absend(RoleID, {apply,Fun}),
  ok.

add_award_items(RoleID, AwardItems) ->
  case mod_bag:add_items(RoleID, AwardItems, ?LOG_ITEM_TYPE_COUNTRY_TREASURE_RANK_AWARD) of
    {true, _GoodsList} -> ok;
    {error, _Reason} ->
      CreateInfoList = common_misc:get_items_create_info(RoleID, AwardItems),
      GoodsList      = common_misc:get_mail_items_create_info(RoleID, CreateInfoList),
      Text           = "符文争夺战的排名奖励",
      Title          = "符文争夺战的排名奖励",
      common_letter:sys2p(RoleID, Text, Title, GoodsList, 14)
  end.

% %% @doc 加BUFF
% add_buff(RoleID, BuffIDList) ->
%   AddBuffs =
%     lists:map(
%       fun(ID) ->
%           {ok, BuffDetail} = common_skill:get_buf_detail(ID),
%           BuffDetail
%       end, BuffIDList),
  
%   mod_role_buff:add_buff(RoleID, RoleID, role, AddBuffs).

%% @doc 获取每次间隔加的经验
get_interval_exp_add(_FactionID, Level) ->
  case ?find_config({fb_add_exp, Level}) of
    [] ->
      100;
    [Exp] ->
      Exp
  end.

do_add_exp_interval(Now) ->
  case erlang:get(last_add_exp_time) of
    undefined ->
      erlang:put(last_add_exp_time, Now);
    LastAddExpTime when Now >= LastAddExpTime + 10 ->
      erlang:put(last_add_exp_time, Now),
      Fun = fun(RoleID) ->
        case mod_map_actor:get_actor_mapinfo(RoleID, role) of 
          undefined -> ignore;
          #p_map_role{faction_id=FactionID, level=Level} ->
            ExpAdd = get_interval_exp_add(FactionID, Level),
            mod_map_role:do_add_exp(RoleID, ExpAdd)
        end
      end,
      [Fun(R) || R <- mgeem_map:get_all_roleid()];
    _ -> ignore
  end.


% %% @doc 插入加经验列表
% insert_interval_exp_list(RoleID) ->
%   List = get_interval_exp_list(RoleID),
%   set_interval_exp_list(RoleID, [RoleID|lists:delete(RoleID, List)]).

% delete_interval_exp_list(RoleID) ->
%   List = get_interval_exp_list(RoleID),
%   set_interval_exp_list(RoleID, lists:delete(RoleID, List)).

% get_interval_exp_list(RoleID) ->
%   Key = RoleID rem ?EXP_ADD_INTERVAL,
%   case get({?INTERVAL_EXP_LIST, Key}) of
%     undefined ->
%       put({?INTERVAL_EXP_LIST, Key}, []),
%       [];
%     List ->
%       List
%   end.

% earse_interval_exp_list() ->
%   lists:foreach(fun(Key)->
%               erlang:put({?INTERVAL_EXP_LIST, Key}, [])
%           end, lists:seq(0, ?EXP_ADD_INTERVAL-1)).


% set_interval_exp_list(RoleID, List) ->
%   Key = RoleID rem ?EXP_ADD_INTERVAL,
%   put({?INTERVAL_EXP_LIST, Key}, List).


reset_country_role_info_list()->
  erlang:put(?COUNTRY_ROLE_INFO, #r_country_role_info{}).

get_country_role_info_list() ->
  case erlang:get(?COUNTRY_ROLE_INFO) of
    undefined ->
      #r_country_role_info{};
    RoleInfoList ->
      RoleInfoList
  end.

get_country_role_info(RoleID) ->
  case get_country_role_info_list() of
    #r_country_role_info{role_infos=RoleInfoList} ->
      case lists:keyfind(RoleID, #r_role_info.role_id, RoleInfoList) of
        false ->
          #r_role_info{role_id=RoleID};
        RoleInfo ->
          RoleInfo
      end;
    _ ->
      #r_role_info{role_id=RoleID}
  end.

set_country_role_info(RoleID, RoleInfo) ->
  case get_country_role_info_list() of
    #r_country_role_info{role_infos=RoleInfoList}=CountryRoleInfo ->
      NewRoleInfoList = lists:keystore(RoleID, #r_role_info.role_id, RoleInfoList, RoleInfo),
      erlang:put(?COUNTRY_ROLE_INFO, CountryRoleInfo#r_country_role_info{role_infos=NewRoleInfoList});
    _ ->
      erlang:put(?COUNTRY_ROLE_INFO, #r_country_role_info{role_infos=[RoleInfo]})
  end.

hook_role_dead(DeadRoleID, SActorID, SActorType)->
  MapState = mgeem_map:get_state(),
  FBMapId = get_country_treasure_fb_map_id(),
  if MapState#map_state.mapid =:= FBMapId ->
       hook_role_dead_2(DeadRoleID, SActorID, SActorType);
     true ->
       ignore
  end.

hook_role_dead_2(DeadRoleID, SActorID, SActorType) when SActorType =:= role ->
  case {mod_map_actor:get_actor_mapinfo(DeadRoleID,role), mod_map_actor:get_actor_mapinfo(SActorID,role)} of
    {#p_map_role{faction_id=DeadRoleFaction}, #p_map_role{faction_id=AttackRoleFaction}} when DeadRoleFaction =/= AttackRoleFaction ->
      DeadRoleInfo = get_country_role_info(DeadRoleID),
      AttackRoleInfo = get_country_role_info(SActorID),
      NewDeadRoleInfo = DeadRoleInfo#r_role_info{be_killed_times=DeadRoleInfo#r_role_info.be_killed_times + 1},
      NewAttackRoleInfo = AttackRoleInfo#r_role_info{kill_times=AttackRoleInfo#r_role_info.kill_times + 1, total_kill_times = AttackRoleInfo#r_role_info.total_kill_times + 1},
      trigger_role_get_buff_item(role_dead, NewDeadRoleInfo),
      trigger_role_get_buff_item(role_attack, NewAttackRoleInfo),
      ok;
    _ ->
      ignore
  end;
hook_role_dead_2(_DeadRoleID, _SActorID, _SActorType) ->
  ignore.

trigger_role_get_buff_item(role_dead, DeadRoleInfo) ->
  [BeKilledTimeRate] = ?find_config( be_killed_times_rate),
  roll_to_get_buff_item(role_dead, DeadRoleInfo, DeadRoleInfo#r_role_info.be_killed_times, BeKilledTimeRate),
  ok;
trigger_role_get_buff_item(role_attack, AttackRoleInfo) ->
  [KillTimeRate] = ?find_config( kill_times_rate),
  roll_to_get_buff_item(role_attack, AttackRoleInfo, AttackRoleInfo#r_role_info.kill_times, KillTimeRate),
  ok.

roll_to_get_buff_item(Type, RoleInfo, Times, RateList) ->
  Rate = 
    lists:foldl(fun({Count, TRate}, Acc) ->
              if Times >= Count ->
                   TRate;
                 true ->
                   Acc
              end
          end, 0, RateList),
  
  RandomRate = common_tool:random(1, 100),
  if Rate >= RandomRate ->
       BuffRandomList = get_buff_random_list(Type),
       {BuffItemID,_} = common_tool:random_from_tuple_weights(BuffRandomList, 2),
       NewRoleInfo = 
         case Type of
           role_dead ->
             RoleInfo#r_role_info{be_killed_times=0};
           role_attack ->
             RoleInfo#r_role_info{kill_times=0}
         end,
       case notify_role_get_buff_item(NewRoleInfo#r_role_info.role_id, BuffItemID, Type) of
         ok ->
           set_country_role_info(NewRoleInfo#r_role_info.role_id, NewRoleInfo),
           notify_country_role_info(NewRoleInfo);
         {error, not_enough_pos} ->
           set_country_role_info(RoleInfo#r_role_info.role_id, RoleInfo),
           notify_country_role_info(RoleInfo);
         _Error ->
           ignore
       end,
       ok;
     true ->
       set_country_role_info(RoleInfo#r_role_info.role_id, RoleInfo),
       notify_country_role_info(RoleInfo),
       ignore
  end.

get_buff_random_list(Type) ->
  [BuffRandomList] = 
    case Type of
      role_dead ->
        ?find_config( be_killed_buff_rate);
      role_attack ->
        ?find_config( kill_buff_rate)
    end,
  BuffRandomList.
notify_role_get_buff_item(RoleID, BuffItemID, Type) ->
  Fun = fun() ->mod_country_treasure:get_buff_item(RoleID, BuffItemID, Type) end,
  mgeer_role:absend(RoleID, {apply,Fun}),
  ok.

get_buff_item(RoleID, BuffItemID, Type) ->
  case common_transaction:transaction(
       fun() ->
           CreateInfo = #r_goods_create_info{bind=true, type=?TYPE_ITEM, type_id=BuffItemID, num=1},
           mod_bag:create_goods(RoleID, CreateInfo)
       end) of
    {atomic, {ok, [BuffGoods]}} ->
      catch common_item_logger:log(RoleID,BuffGoods,1,?LOG_ITEM_TYPE_COUNTRY_TREASURE_FIGHT),
      common_misc:update_goods_notify({role,RoleID}, [BuffGoods]),
      case Type of
        role_dead ->
          KillType = ?BUFF_BE_KILLED_TYPE;
        role_attack ->
          KillType = ?BUFF_KILL_TYPE
      end,
      common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ROLE_BUFF, 
                #m_country_treasure_role_buff_toc{buff_item=BuffGoods,type=KillType}),
      ok;
    {aborted, Error} ->
      case Error of
        {bag_error, {not_enough_pos,_BagID}} ->
          common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ROLE_BUFF, 
                    #m_country_treasure_role_buff_toc{err_code=?ERR_COUNTRY_TREASURE_BUFF_NOT_ENOUGH_BAG_POS}),
          {error, not_enough_pos};
        _ ->
          ?ERROR_MSG("~ts:~w", ["玩家获得符文争夺战的BUFF符时系统错误", Error]),
          common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ROLE_BUFF, 
                    #m_country_treasure_role_buff_toc{err_code=?ERR_SYS_ERR}),
          {error, Error}
      end
  end.

notify_country_role_info(RoleID) when erlang:is_integer(RoleID) ->
  #r_role_info{role_id=RoleID, kill_times=KillTime, be_killed_times=BeKillTime, total_kill_times=TotalKillTimes} = get_country_role_info(RoleID),
  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ROLE_INFO, 
            #m_country_treasure_role_info_toc{kill_times=KillTime, be_kill_times=BeKillTime, total_kill_times = TotalKillTimes});
notify_country_role_info(RoleInfo) when erlang:is_record(RoleInfo, r_role_info) ->
  #r_role_info{role_id=RoleID, kill_times=KillTime, be_killed_times=BeKillTime, total_kill_times=TotalKillTimes} = RoleInfo,
  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COUNTRY_TREASURE, ?COUNTRY_TREASURE_ROLE_INFO, 
            #m_country_treasure_role_info_toc{kill_times=KillTime, be_kill_times=BeKillTime, total_kill_times = TotalKillTimes}).
