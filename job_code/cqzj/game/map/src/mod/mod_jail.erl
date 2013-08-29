%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 18 Feb 2011 by  <>
%%%-------------------------------------------------------------------
-module(mod_jail). 

-include("mgeem.hrl").

-export([handle/1]).

-export([
         check_in_jail/1
        ]).

handle({Unique, Module, ?JAIL_OUT, DataIn, RoleID, PID, Line, MapState}) ->
    do_out(Unique, Module, ?JAIL_OUT, DataIn, RoleID, PID, Line, MapState);
handle({Unique, Module, ?JAIL_DONATE, DataIn, RoleID, PID, Line, MapState}) ->
    do_donate(Unique, Module, ?JAIL_DONATE, DataIn, RoleID, PID, Line, MapState);
handle({Unique, Module, ?JAIL_OUT_FORCE, DataIn, RoleID, PID, Line, MapState}) ->
    do_out_force(Unique, Module, ?JAIL_OUT_FORCE, DataIn, RoleID, PID, Line, MapState);

handle(Info) ->
    ?ERROR_MSG("mod_jail, unknow info: ~w", [Info]).

%% 请求出狱
do_out(Unique, Module, Method, _DataIn, RoleID, PID, _Line, MapState) ->
    #map_state{mapid=MapID} = MapState,

    case catch check_can_out_jail(RoleID, MapID) of
        ok ->
            common_misc:unicast2(PID, Unique, Module, Method, #m_jail_out_toc{}),

            %% 弹出监狱
            common_jail_out(RoleID, MapID);
        {error, Reason} ->
            do_out_error(Unique, Module, Method, PID, Reason)
    end.

do_out_error(Unique, Module, Method, PID, Reason) ->
    DataRecord = #m_jail_out_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

%% 捐献，元宝兑换PK值
do_donate(Unique, Module, Method, DataIn, RoleID, PID, _Line, _MapState) ->
    #m_jail_donate_tos{gold=DGold} = DataIn,
    DGold2 = abs(DGold),
    
    case common_transaction:transaction(
           fun() ->
                   t_do_donate(RoleID, DGold2)
           end)
    of
        {atomic, {PKPoints, PKPoints2, RestGold, RestGoldBind}} ->
            Reduce = PKPoints - PKPoints2,
            DataRecord = #m_jail_donate_toc{pk_points=PKPoints2, gold=RestGold, gold_bind=RestGoldBind};

        {aborted, Reason} when is_list(Reason) ->
            Reduce = 0,
            DataRecord = #m_jail_donate_toc{succ=false, reason=Reason};

        {aborted, Reason} ->
            ?ERROR_MSG("do_donate, error: ~w", [Reason]),
            Reduce = 0,
            DataRecord = #m_jail_donate_toc{succ=false, reason=?_LANG_JAIL_DONATE_SYSTEM_ERROR}
    end,
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord),
    
    case Reduce of
        0 ->
            ignore;
        _ ->
            mod_pk:reduce_pk_point(RoleID, Reduce, ?PK_POINT_REDUCE_TYPE_NORMAL)
    end.

%% @doc 强行出狱
do_out_force(Unique, Module, Method, _DataIn, RoleID, PID, _Line, MapState) ->
    #map_state{mapid=MapID} = MapState,
    
    case catch check_can_force_out(RoleID, MapID) of
        ok ->
            do_out_force2(Unique, Module, Method, RoleID, PID, MapID);

        {error, Reason} ->
            do_out_force_error(Unique, Module, Method, PID, Reason)
    end.

do_out_force2(Unique, Module, Method, RoleID, PID, MapID) ->
    case common_transaction:transaction(
           fun() ->
                   t_do_out_force(RoleID)
           end)
    of
        {atomic, {Silver, SilverBind}} ->
            DataRecord = #m_jail_out_force_toc{silver=Silver, silver_bind=SilverBind},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord),
            
            common_jail_out(RoleID, MapID);

        {aborted, Reason} when is_binary(Reason); is_list(Reason) ->
            do_out_force_error(Unique, Module, Method, PID, Reason);

        {aborted, Reason} ->
            ?ERROR_MSG("do_out_force2, error: ~w", [Reason]),
            do_out_force_error(Unique, Module, Method, PID, ?_LANG_JAIL_OUT_FORCE_SYSTEM_ERROR)
    end.

do_out_force_error(Unique, Module, Method, PID, Reason) ->
    DataRecord = #m_jail_out_force_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

%% @doc 检测是否可以强行出狱
check_can_force_out(_RoleID, _MapID) ->
    ok.

%% 检查是否可以出狱
check_can_out_jail(RoleID, _MapID) ->
    {ok, #p_role_base{pk_points=PKPoints}} = mod_map_role:get_role_base(RoleID),
    
    [OutPKPoints] = common_config_dyn:find(jail, jail_out_pkpoints),
    case PKPoints >= OutPKPoints of
        true ->
            Reason = lists:flatten(io_lib:format(?_LANG_JAIL_OUT_PK_POINTS_TOO_MUCH, [PKPoints, OutPKPoints])),
            throw({error, Reason});
        _ ->
            ok
    end.

%% @doc 出狱
common_jail_out(RoleID, MapID) ->
    {ok, #p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
    HomeMapID = common_misc:get_home_mapid(FactionID, MapID),
    {_, TX, TY} = common_misc:get_born_info_by_map(HomeMapID),
    %% 转回主城
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, HomeMapID, TX, TY).

t_do_donate(RoleID, DGold) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{pk_points=PKPoints} = RoleBase,
    case PKPoints of
        0 ->
            common_transaction:abort(?_LANG_JAIL_DONATE_PK_POINT_ZERO); 
        _ ->
            ok
    end,
    case DGold > PKPoints of
        true ->
            PKPoints2 = 0;
        _ ->
            PKPoints2 = PKPoints - DGold
    end,

    case common_bag2:t_deduct_money(gold_any, PKPoints-PKPoints2, RoleID, ?CONSUME_TYPE_GOLD_JAIL_DONATE) of
        {ok, RoleAttr}  -> ok;
        {error, Reason} -> RoleAttr = null, common_transaction:abort(Reason)
    end,

    {PKPoints, PKPoints2, RoleAttr#p_role_attr.gold, RoleAttr#p_role_attr.gold_bind}.

t_do_out_force(RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{silver=Silver, silver_bind=SilverBind} = RoleAttr,
    
    [ForceOutFee] = common_config_dyn:find(jail, jail_out_force_fee),
    case Silver+SilverBind < ForceOutFee of
        true ->
            common_transaction:abort(?_LANG_JAIL_OUT_FORCE_NOT_ENOUGH_SILVER);
        _ ->
            ok
    end,
    
    {RestSilver, RestSilverBind} = mod_role2:calc_rest_money(Silver, SilverBind, ForceOutFee),
    RoleAttr2 = RoleAttr#p_role_attr{silver=RestSilver, silver_bind=RestSilverBind},
    mod_map_role:set_role_attr(RoleID, RoleAttr2),

    %% 消费日志
    common_consume_logger:use_silver({RoleID, SilverBind-RestSilverBind, Silver-RestSilver, ?CONSUME_TYPE_SILVER_JAIL_OUT_FORCE,
                                      ""}),
    
    {RestSilver, RestSilverBind}.

check_in_jail(MapID) ->
    [JailMapID] = common_config_dyn:find(jail, jail_map_id),
    JailMapID =:= MapID.
