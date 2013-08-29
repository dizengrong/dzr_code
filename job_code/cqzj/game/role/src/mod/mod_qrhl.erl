%%%-------------------------------------------------------------------
%%% @author Li Gengxin <rollbox@gmail.com>
%%% @copyright (C) 2013, Li Gengxin
%%% @doc
%%% 七日好礼模块
%%% @end
%%% Created : 29 Mar 2013 by Li Gengxin <rollbox@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_qrhl).

-include("mgeer.hrl").

%% API
-export([send_event/3, handle/1, handle/2]).

-export([init/2, delete/1]).

-define(QRHL_STATUS_NOT_OPEN, 0).
-define(QRHL_STATUS_DOING, 1).
-define(QRHL_STATUS_DONE, 2).
-define(QRHL_STATUS_TAKE, 3).
-define(QRHL_STATUS_EXPIRED, 4).

-define(OPEN_LEVEL, 15).

-define(ONE_DAY_SECONDS, 86400).

-define(now(), common_tool:now()).

-define(current_stage(Info), Info#r_qrhl.current_stage).

-define(stage_num(), cfg_qrhl:get_stage_num()).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?QRHL, Method, Msg)).

-record(qrhl_conf, {stage, %% 阶段（天数）
                    aim_value}). %% 目标值

-record(r_qrhl, {end_time,
                 stages,
                 current_stage,
                 expired,
                 award}).

-record(r_qrhl_info, {stage,
                      status,
                      end_time,
                      current_value}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
init(RoleID, false) ->
    Now = ?now(),
    StageNum = ?stage_num(),
    Stages = [#r_qrhl_info{stage = Stage,
                           status = ?QRHL_STATUS_NOT_OPEN,
                           end_time = 0,
                           current_value = 0} || Stage <- lists:seq(1, StageNum)],
    TmpInfo =
        #r_qrhl{expired = false,
                end_time = get_stage_end_time(StageNum, Now),
                current_stage = 0,
                award = 0,
                stages = Stages},
    update_info(RoleID, TmpInfo);
init(RoleID, Record) ->
    update_info(RoleID, Record).

delete(RoleID) ->
    erase({dict_qrhl_info, RoleID}).

send_event(RoleID, Event, Value) ->
    Msg =  {mod_qrhl, {Event, Value}},
    mgeer_role:absend(RoleID, Msg).

handle({_Unique, _Module, ?QRHL_INFO, _DataIn, RoleID, _PID, _Line}) ->
    Info = fetch_info(RoleID),
    if Info#r_qrhl.expired =:= true ->
            Msg = #m_qrhl_info_toc{expired = true, stages = []},
            ?MOD_UNICAST(RoleID, ?QRHL_INFO, Msg);
       true -> do_info(RoleID, Info)
    end;
handle({_Unique, _Module, ?QRHL_TAKE, DataIn, RoleID, _PID, _Line}) ->
    Info = fetch_info(RoleID),
    if Info#r_qrhl.expired =:= true -> ignore;
       true -> do_take(RoleID, DataIn, Info)
    end;
handle(Other) ->
    ?ERROR_MSG("Role receive unknow qrhl handle: ~w", [Other]).

handle(RoleID, {set_remain_time, _RoleID, Time}) ->
    set_remain_time(RoleID, Time);
handle(RoleID, Event) ->
    Info = fetch_info(RoleID),
    if Info#r_qrhl.expired =:= true -> ignore;
       true -> do_event(RoleID, Event, Info)
    end.

%%%===================================================================
%%% Internal functions
%%%===================================================================
set_remain_time(RoleID, Time) ->
    Info = fetch_info(RoleID),
    Stage = ?current_stage(Info),
    Now = ?now(),
    NewInfo2 = lists:foldl(fun(ID, InfoAccIn) ->
                TailStageInfo = get_stage_info(ID, InfoAccIn),
                NewTailStageInfo = TailStageInfo#r_qrhl_info{
                    end_time = Now + (ID - Stage) * ?ONE_DAY_SECONDS + Time},
                NewStages = lists:keystore(ID, #r_qrhl_info.stage, InfoAccIn#r_qrhl.stages, NewTailStageInfo),
                InfoAccIn#r_qrhl{stages = NewStages}
          end, Info, lists:seq(Stage,?stage_num())),
    update_info(RoleID, NewInfo2),
    do_info(RoleID, NewInfo2).

do_info(RoleID, Info) ->
    Stages = generate_stage_p(Info),
    Msg = #m_qrhl_info_toc{expired = false,
                           stages = Stages},
    ?MOD_UNICAST(RoleID, ?QRHL_INFO, Msg).

do_take(RoleID, DataIn, Info) ->
    #m_qrhl_take_tos{stage = Stage} = DataIn,
    StageNum = ?stage_num(),
    if is_integer(Stage)
       andalso
       Stage > 0
       andalso
       Stage =< StageNum ->
            do_take2(RoleID, DataIn, Info);
       true ->
            Reason = <<"系统错误">>,
            do_take_error(RoleID, Reason)
    end.

do_take2(RoleID, DataIn, Info) ->
    if Info#r_qrhl.award =:= 0 ->
            Reason = <<"没有可领取的奖励">>,
            do_take_error(RoleID, Reason);
       true ->
            do_take3(RoleID, DataIn, Info)
    end.

do_take3(RoleID, DataIn, Info) ->
    #m_qrhl_take_tos{stage = Stage} = DataIn,
    StageInfo = get_stage_info(Stage, Info),
    if StageInfo#r_qrhl_info.status /= ?QRHL_STATUS_DONE ->
            Reason = <<"不可以领取此奖励">>,
            do_take_error(RoleID, Reason);
       true ->
            do_take4(RoleID, DataIn, StageInfo, Info)
    end.

do_take4(RoleID, _DataIn, StageInfo, Info) ->
    ItemsTmp1 = cfg_qrhl:get_stage_award(StageInfo#r_qrhl_info.stage),
    #p_role_attr{
        category = RoleCategory
    } = mod_map_role:get_role_attr(RoleID),

    Items = lists:filter(fun(H) ->
        case common_config_dyn:find_equip(H) of
            [EquipBase] -> 
                case mod_role_equip:check_equip_category([], EquipBase, RoleCategory) of
                    true -> true;
                    _ -> false
                end;
            _ -> true
        end
    end, ItemsTmp1),

    case mod_bag:add_items(RoleID, Items, ?LOG_ITEM_TYPE_GAIN_QRHL) of
        {error, Reason} ->
            do_take_error(RoleID, Reason);
        {true, _} -> 
            NewStageInfo = StageInfo#r_qrhl_info{status = ?QRHL_STATUS_TAKE},
            NewInfo = set_stage_info(NewStageInfo, Info),
            NewInfo2 = NewInfo#r_qrhl{award = NewInfo#r_qrhl.award - 1},
            update_info(RoleID, NewInfo2),
            do_info(RoleID, NewInfo2)
    end.

do_take_error(RoleID, Reason) ->
    Msg = #m_qrhl_take_toc{succ = false,
                           reason = Reason},
    ?MOD_UNICAST(RoleID, ?QRHL_TAKE, Msg).

generate_stage_p(Info) ->
    CurrentStage = Info#r_qrhl.current_stage,
    [r_to_p(Stage, Info, CurrentStage) || Stage <- lists:seq(1, ?stage_num())].

r_to_p(Stage, Info, CurrentStage) ->
    %% 未开启的目标减少一天时间来显示到开启倒计时
    ReduceTime = case Stage > CurrentStage of
                    true -> ?ONE_DAY_SECONDS;
                    _ -> 0
                end,
    StageInfo = get_stage_info(Stage, Info),
    #r_qrhl_info{stage = Stage, status = Status, end_time = EndTime, current_value = CurrentValue} = StageInfo,
    #p_qrhl_info{stage = Stage, status = Status, end_time = EndTime - ReduceTime, current_value = CurrentValue}.

do_event(RoleID, {Key, Value} = Event, Info) ->
    Stage =
        case Key of
            shengji -> 1;
            skill -> 2;
            fashion -> 3;
            jingjie -> 4;
            baoshi -> 5;
            pet -> 6;
            zizhi -> 7
        end,
    NewInfo =
        if Key =:= shengji ->
                level_up(RoleID, Value, Info);
           true ->
                Info
        end,
    StageInfo = get_stage_info(Stage, NewInfo),
    #qrhl_conf{aim_value = AimValue} = cfg_qrhl:get_stage_info(Stage),
    if StageInfo#r_qrhl_info.current_value =:= AimValue ->
            ignore;
       true ->
            NewValue =
                case Stage of
                    7 ->
                        Value;
                    _ ->
                        max(Value, StageInfo#r_qrhl_info.current_value)
                end,
            NewValue2 =
                if NewValue > AimValue -> AimValue;
                   true -> NewValue
                end,
            do_event3(RoleID, Event, NewValue2, StageInfo, NewInfo)
    end.
    
do_event3(RoleID, _Event, NewValue, StageInfo, Info) ->
    Stage = StageInfo#r_qrhl_info.stage,
    TmpStageInfo = StageInfo#r_qrhl_info{current_value = NewValue},
    NewInfo = set_stage_info(TmpStageInfo, Info),
    NewInfo2 =
        if StageInfo#r_qrhl_info.status =:= ?QRHL_STATUS_DOING ->
                check_done(?now(), Stage, ?stage_num(), NewInfo);
           true -> NewInfo
        end,
    update_info(RoleID, NewInfo2),
    if NewInfo2#r_qrhl.current_stage =:= 0 -> ignore;
       true -> do_info(RoleID, NewInfo2)
    end.

get_stage_info(Stage, Info) ->
    case lists:keyfind(Stage, #r_qrhl_info.stage, Info#r_qrhl.stages) of
        false ->
            undefined;
        StageInfo ->
            StageInfo
    end.

set_stage_info(StageInfo, Info) ->
    NewStages = lists:keystore(StageInfo#r_qrhl_info.stage, #r_qrhl_info.stage, Info#r_qrhl.stages, StageInfo),
    Info#r_qrhl{stages = NewStages}.

fetch_info(RoleID) ->
    Info = get({dict_qrhl_info, RoleID}),
    if Info#r_qrhl.current_stage =:= 0 -> Info;
       true -> fix_info(RoleID, Info)
    end.

update_info(RoleID, NewInfo) ->
    put({dict_qrhl_info, RoleID}, NewInfo).

get_stage_end_time(Stage, StartTime) ->
    Time = ?ONE_DAY_SECONDS, %% 24小时
    StartTime + (Time * Stage).

fix_info(RoleID, Info) ->
    NewInfo = check_done(?now(), ?current_stage(Info), ?stage_num(), Info),
    update_info(RoleID, NewInfo),
    NewInfo.

check_done(Now, CurrentStage, StageNum, Info) when CurrentStage =:= StageNum ->
    StageConf = cfg_qrhl:get_stage_info(CurrentStage),
    StageInfo = get_stage_info(CurrentStage, Info),
    NewInfo2 =
        case is_expired(Now, StageInfo) of
            true ->
                %% 如果当前是进行 并且数量满了
                NewInfo3 =
                    if StageInfo#r_qrhl_info.status =:= ?QRHL_STATUS_DOING
                       andalso
                       StageInfo#r_qrhl_info.current_value >= StageConf#qrhl_conf.aim_value ->
                            NewStageInfo = StageInfo#r_qrhl_info{status = ?QRHL_STATUS_DONE},
                            NewInfo = Info#r_qrhl{award = Info#r_qrhl.award + 1},
                            set_stage_info(NewStageInfo, NewInfo);
                       StageInfo#r_qrhl_info.status =:= ?QRHL_STATUS_DONE
                       orelse
                       StageInfo#r_qrhl_info.status =:= ?QRHL_STATUS_TAKE ->
                            Info;
                       true ->
                            NewStageInfo = StageInfo#r_qrhl_info{status = ?QRHL_STATUS_EXPIRED,
                                                                 end_time = 0},
                            set_stage_info(NewStageInfo, Info)
                    end,
                if NewInfo3#r_qrhl.award =:= 0 ->
                        NewInfo3#r_qrhl{expired = true};
                   true ->
                        NewInfo3
                end;
            false ->
                if StageInfo#r_qrhl_info.status =:= ?QRHL_STATUS_DOING
                   andalso
                   StageInfo#r_qrhl_info.current_value >= StageConf#qrhl_conf.aim_value ->
                        NewStageInfo = StageInfo#r_qrhl_info{status = ?QRHL_STATUS_DONE},
                        NewInfo = Info#r_qrhl{award = Info#r_qrhl.award + 1},
                        set_stage_info(NewStageInfo, NewInfo);
                   true ->
                        Info
                end
        end,
    NewInfo2#r_qrhl{current_stage = CurrentStage};
check_done(Now, CurrentStage, StageNum, Info) ->
    StageConf = cfg_qrhl:get_stage_info(CurrentStage),
    StageInfo = get_stage_info(CurrentStage, Info),
    NextStage = CurrentStage + 1,
    NewInfo3 =
        if StageInfo#r_qrhl_info.status =:= ?QRHL_STATUS_DOING
           andalso
           StageInfo#r_qrhl_info.current_value >= StageConf#qrhl_conf.aim_value ->
                NewStageInfo = StageInfo#r_qrhl_info{status = ?QRHL_STATUS_DONE},
                NewInfo = Info#r_qrhl{award = Info#r_qrhl.award + 1},
                set_stage_info(NewStageInfo, NewInfo);
           true ->
                Info
        end,
    case is_expired(Now, StageInfo) of
        false ->
            NewInfo3#r_qrhl{current_stage = CurrentStage};
        true ->
            NewStageInfo5 =
                if StageInfo#r_qrhl_info.status =:= ?QRHL_STATUS_DOING ->
                        StageInfo#r_qrhl_info{status = ?QRHL_STATUS_EXPIRED,
                                              end_time = 0};
                   true ->
                        StageInfo#r_qrhl_info{end_time = 0}
                end,
            NextStageInfo = get_stage_info(NextStage, Info),
            %% 下一个的过期时间 当前过期时间加间隔
            NewNextStageInfo = NextStageInfo#r_qrhl_info{status = ?QRHL_STATUS_DOING},
            Info5 = set_stage_info(NewStageInfo5, Info),
            Info6 = set_stage_info(NewNextStageInfo, Info5),
            check_done(Now, NextStage, StageNum, Info6)
    end.

is_expired(Now, StageInfo) ->
    Now >= StageInfo#r_qrhl_info.end_time.

level_up(RoleID, Value, Info) ->
    if Value >= ?OPEN_LEVEL ->
            if Info#r_qrhl.current_stage =:= 0 ->
                    StageInfo = get_stage_info(1, Info),
                    NewStageInfo = StageInfo#r_qrhl_info{status = ?QRHL_STATUS_DOING,
                                                         end_time = ?now() + ?ONE_DAY_SECONDS},
                    NewInfo = set_stage_info(NewStageInfo, Info),
                    NewInfo2 = lists:foldl(fun(ID, InfoAccIn) ->
                                TailStageInfo = get_stage_info(ID, InfoAccIn),
                                NewTailStageInfo = TailStageInfo#r_qrhl_info{
                                        end_time = ?now() + ID * ?ONE_DAY_SECONDS},
                                NewStages = lists:keystore(ID, #r_qrhl_info.stage, InfoAccIn#r_qrhl.stages, NewTailStageInfo),
                                InfoAccIn#r_qrhl{stages = NewStages}
                          end, NewInfo, lists:seq(2,?stage_num())),
                    update_info(RoleID, NewInfo2),
                    NewInfo2;
               true ->
                    Info
            end;
       true ->
            Info
    end.
