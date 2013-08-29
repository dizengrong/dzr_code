%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 10 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_pk).

-include("mgeem.hrl").

%% API
-export([
         kill/6,
         kill_faction_ybc/1,
         reduce_pk_point_start/1,
         reduce_pk_point/3,
         login_pk_init/1,
         handle/2
        ]).

-define(PK_STATE_RED, 2).
-define(PK_STATE_YELLOW, 1).
-define(PK_STATE_WHITE, 0).

handle({admin_set_pkpoint, RoleID, PKPoint}, _MapState) ->
    do_admin_set_pkpoint(RoleID, PKPoint);
handle(Info, _MapState) ->
    ?ERROR_MSG("mod_pk, unknow msg: ~w", [Info]).

%% GM命令设置PK值
do_admin_set_pkpoint(RoleID, PKPoint) ->
    case common_transaction:t(
           fun() ->
                   t_admin_set_pkpoint(RoleID, PKPoint)
           end)
    of
        {atomic, {PKPointOld, RoleBase}} ->
            do_pkpoint_change(RoleID, RoleBase, PKPointOld, PKPoint);
        {aborted, Error} ->
            ?ERROR_MSG("do_admin_set_pkpoint, error: ~w", [Error])
    end.

t_admin_set_pkpoint(RoleID, PKPoint) ->
    {ok, #p_role_base{pk_points=PKPointOld}=RoleBase} = mod_map_role:get_role_base(RoleID),
    RoleBase2 = RoleBase#p_role_base{pk_points=PKPoint},
    mod_map_role:set_role_base(RoleID, RoleBase2),
    {PKPointOld, RoleBase2}.

%% RoleID 被杀者, SRoleID 杀人者 
%% 死亡PK值的一些计算
kill(RoleID, FactionID, GrayName, SRoleID, SFactionID, Flag) ->

    %%灰名、两个属于不同国家或者在竞技区不计算PK值
    %% 大明宝藏副本地图不需要计算PK值
    MapId = mgeem_map:get_mapid(),
    case GrayName =:= true 
        orelse FactionID =/= SFactionID
        orelse MapId =:= ?COUNTRY_TREASURE_MAP_ID
        orelse Flag =:= true of
        true ->
            ignore;
        _ ->
            kill2(RoleID, SRoleID)
    end.

kill2(RoleID, SRoleID) ->
    case db:transaction(
           fun() ->
                   t_kill(RoleID, SRoleID)
           end)
    of
        {atomic, {SPKPoint, SPKPoint2, SRoleBase}} ->
            do_pkpoint_change(SRoleID, SRoleBase, SPKPoint, SPKPoint2);

        {aborted, Error} ->
            ?ERROR_MSG("kill2, error: ~w", [Error])
    end.

%% @doc 杀死了本国人的镖车
kill_faction_ybc(RoleID) ->
    case db:transaction(
           fun() ->
                   {ok, #p_role_base{pk_points=OldPK}=RoleBase} = mod_map_role:get_role_base(RoleID),
                   RoleBase2 = RoleBase#p_role_base{pk_points=OldPK + 18},
                   mod_map_role:set_role_base(RoleID, RoleBase2),
                   {OldPK, OldPK + 18, RoleBase2}
           end)
    of
        {atomic, {OldPK, NewPK, RoleBase}} ->
            do_pkpoint_change(RoleID, RoleBase, OldPK, NewPK);

        {aborted, _} ->
            ignore
    end.

%% @doc 启动减PK值计时
reduce_pk_point_start(RoleID) ->
    case mod_map_role:get_role_state(RoleID) of
        {error, _} ->
            ignore;
        {ok, RoleState} ->
            TimerRef = erlang:send_after(?PKPOINT_REDUCE_TIME, self(), {mod_map_role, {reduce_pk_point, RoleID, 1, ?PK_POINT_REDUCE_TYPE_PER_TEN_MIN}}),
            
            RoleState2 = RoleState#r_role_state2{pkpoint_timer_ref=TimerRef},
            mod_map_role:set_role_state(RoleID, RoleState2)
    end.

%% @doc 减PK值
reduce_pk_point(RoleID, Reduce, ReduceType) ->
    case common_transaction:transaction(
           fun() ->
                   t_reduce_pkpoint(RoleID, Reduce)
           end)
    of
		{atomic, role_not_found} ->
			ignore;
        {atomic, {PKPoint, RoleBase}} ->
            mod_map_role:do_update_map_role_info(RoleID, [{#p_map_role.pk_point, PKPoint}]),

            case ReduceType of
                ?PK_POINT_REDUCE_TYPE_NORMAL ->
                    ignore;
                ?PK_POINT_REDUCE_TYPE_PER_TEN_MIN ->
                    case PKPoint =:= 0 of
                        true ->
                            ok;
                        _ ->
                            case mod_map_role:get_role_state(RoleID) of
                                {error, _} ->
                                    ignore;
                                {ok, RoleState} ->
                                    TimerRef = erlang:send_after(?PKPOINT_REDUCE_TIME, self(), {mod_map_role, {reduce_pk_point, RoleID, 1, ?PK_POINT_REDUCE_TYPE_PER_TEN_MIN}}),

                                    RoleState2 = RoleState#r_role_state2{pkpoint_timer_ref=TimerRef},
                                    mod_map_role:set_role_state(RoleID, RoleState2)
                            end
                    end
            end,

            #p_role_base{pk_points = PkPoint,
                         role_name = RoleName,
                         faction_id = FactionID, 
                         family_name = FamilyName
                        } = RoleBase,
            RankSendInfo = {RoleID,RoleName,PkPoint,FactionID,FamilyName},
            common_rank:update_element(ranking_role_pkpoint,RankSendInfo),
            common_rank:update_element(ranking_role_world_pkpoint,RankSendInfo);
        {aborted, R} ->
            ?ERROR_MSG("reduce_pk_point, error: ~w", [R]),
            ok
    end.

%% @doc 登陆时PK点的一些处理
login_pk_init(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        RoleMapInfo ->
            #p_map_role{pk_point=PKPoint} = RoleMapInfo,
            
            case PKPoint > 0 of
                true ->
                    reduce_pk_point_start(RoleID);
                _ ->
                    ignore
            end
	end.

t_reduce_pkpoint(RoleID, Reduce) ->
	case mod_map_role:get_role_base(RoleID) of
		{ok, RoleBase} ->
			PKPoint = RoleBase#p_role_base.pk_points,
			case PKPoint =< 0 of
				true ->
					db:abort(pk_points_min);
				false ->
					case PKPoint - Reduce >= 0 of
						true ->
							PKPoint2 = PKPoint - Reduce;
						_ ->
							PKPoint2 = 0
					end,
					
					RoleBase2 = RoleBase#p_role_base{pk_points=PKPoint2},
					mod_map_role:set_role_base(RoleID, RoleBase2),
					{PKPoint2, RoleBase2}
			end;
		_ ->
			role_not_found
	end.

t_kill(RoleID, SRoleID) ->
    {ok, #p_role_base{pk_points=PKPoint}} = mod_map_role:get_role_base(RoleID),
    {ok, #p_role_base{pk_points=SPKPoint}=SRoleBase} = mod_map_role:get_role_base(SRoleID),
    
    PKState = get_pk_state(PKPoint),
    
    if
        PKState =:= ?PK_STATE_RED ->
            case SPKPoint - 2 >= 0 of
                true ->
                    SPKPoint2 = SPKPoint - 2;
                _ ->
                    SPKPoint2 = 0
            end;
        
        PKState =:= ?PK_STATE_YELLOW ->
            SPKPoint2 = SPKPoint + 3;
        true ->
            SPKPoint2 = SPKPoint + 6
    end,
    
    SRoleBase2 = SRoleBase#p_role_base{pk_points=SPKPoint2},
    mod_map_role:set_role_base(SRoleID, SRoleBase2),
    
    {SPKPoint, SPKPoint2, SRoleBase2}.

get_pk_state(PKPoint) ->
    if
        PKPoint > 19 ->
            ?PK_STATE_RED;
        PKPoint > 0 ->
            ?PK_STATE_YELLOW;
        true ->
            ?PK_STATE_WHITE
    end.

%% @doc PK值变动
do_pkpoint_change(RoleID, RoleBase, PKPoint, PKPoint2) ->
    %%更新杀人者地图信息，
    mod_map_role:do_update_map_role_info(RoleID, [{#p_map_role.pk_point, PKPoint2}]),

    %% 发送到杀人者地图，杀人者跟被杀的人不一定在同一个地图，例如BUFF
    case PKPoint =:= 0 andalso PKPoint2 =/= 0 of
        true ->
            reduce_pk_point_start(RoleID);
        _ ->
            ignore
    end,

    %%发消息给排行榜
    case PKPoint2 > PKPoint andalso PKPoint2 > 18 of
        true ->
            #p_role_base{pk_points = PkPoint,
                         role_name = RoleName,
                         faction_id = FactionID, 
                         family_name = FamilyName
                        } = RoleBase,
            RankSendInfo = {RoleID,RoleName,PkPoint,FactionID,FamilyName},
            common_rank:update_element(ranking_role_pkpoint,RankSendInfo),
            common_rank:update_element(ranking_role_world_pkpoint,RankSendInfo);
        _ ->
            ignore
    end,

    %% 从黄名变成红名，发送一个信件
    case PKPoint < 18 andalso PKPoint2 >= 18 of
        true ->      
            Letter =common_letter:create_temp(?SUSAN_LETTER,[RoleBase#p_role_base.role_name]),
            common_letter:sys2p(RoleID, Letter, "来自监狱-躲猫猫的信件", 14);
        _ ->
            ignore
    end.
