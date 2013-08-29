%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     钦点美人
%%% @end
%%% Created : 2012-06-09
%%%-------------------------------------------------------------------
-module(mod_horse_racing).

-include("mgeem.hrl").
-include("horse_racing.hrl").

-export([handle/1,
         hook_role_online/1,
         hook_role_offline/1,
         hook_vip_up/2,
         is_role_in_horse_racing/1,
		 refresh_daily_counter_times/2,
         horse_racing_exit/2]).


refresh_daily_counter_times(RoleID,RemainTimes) ->
	?TRY_CATCH(global:send(mgeew_horse_racing, {refresh_daily_counter_times,RoleID,RemainTimes})).

%% 标记玩家是否处于钦点美人的
set_role_in_horse_racing(RoleID, PreviousTitleName) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,ExtInfo} ->
            mod_map_role:set_role_map_ext_info(RoleID, ExtInfo#r_role_map_ext{horse_racing=#r_horse_racing_ext{is_racing=true,
                                                                                                               previous_title=PreviousTitleName}});
        _ ->
            ignore
    end.

clear_role_in_horse_racing(RoleID) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,ExtInfo} ->
            mod_map_role:set_role_map_ext_info(RoleID, ExtInfo#r_role_map_ext{horse_racing=#r_horse_racing_ext{is_racing=false}});
        _ ->
            ignore
    end.

is_role_in_horse_racing(RoleID) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{horse_racing=#r_horse_racing_ext{is_racing=Status}}} ->
            Status;
        _ ->
            false
    end.

horse_racing_exit(RoleID, PID) ->
    case is_role_in_horse_racing(RoleID) of
        true ->
            do_horse_racing_exit({
                ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_EXIT, 
                undefined, RoleID, PID, undefined});
        _ ->
            ignore
    end.

handle({_, ?HORSE_RACING, ?HORSE_RACING_ENTER, _, _, _, _} = Info) ->
    do_horse_racing_enter(Info);

handle({_, ?HORSE_RACING, ?HORSE_RACING_EXIT, _, _, _, _} = Info) ->
    do_horse_racing_exit(Info);

handle({operate, RoleID, OpType, TargetRoleID}) ->
    do_handle_operate(RoleID, OpType, TargetRoleID);

handle({fetch_reward, RoleID, RewardExp, RewardPrestige, Yueli}) ->
    do_handle_fetch_reward(RoleID, RewardExp, RewardPrestige, Yueli);

handle({buy_horse, RoleID, HorseType, OpType}) ->
    do_buy_horse(RoleID, HorseType, OpType);

handle({role_enter, RoleID}) ->
    do_role_enter(RoleID);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

do_horse_racing_enter({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
    case catch check_horse_racing_enter(RoleID) of
        {error, ErrCode, Reason} ->
            ?UNICAST_TOC(#m_horse_racing_enter_toc{err_code=ErrCode, reason=Reason});
        {ok, RoleBase, VipLevel} ->
            #p_role_base{role_name=RoleName, faction_id=FactionID} = RoleBase,
            ?TRY_CATCH(global:send(mgeew_horse_racing, {role_enter, RoleID, {RoleName, FactionID, VipLevel}}))
    end.

do_role_enter(RoleID) ->
    {ok, #p_role_base{cur_title=CurTitle}} = mod_map_role:get_role_base(RoleID),
    set_role_in_horse_racing(RoleID, CurTitle),
    [{TitleName, Color}] = common_config_dyn:find(horse_racing, title),
    common_title_srv:add_title(?TITLE_HORSE_RACING, RoleID, {TitleName, Color}),
    mod_map_role:do_change_titlename_ex(RoleID, ?TITLE_HORSE_RACING, TitleName, Color),
    ok.

check_horse_racing_enter(RoleID) ->
    {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
    [MinLevel] = common_config_dyn:find(horse_racing, min_level),
    if Level >= MinLevel ->
           ok;
       true ->
           ?THROW_ERR(?ERR_HORSE_RACING_NOT_ENOUGH_LEVEL)
    end,
    case mod_map_role:get_role_base(RoleID) of
        {ok, RoleBase} ->
            ok;
        _ ->
            RoleBase = undefined,
            ?THROW_SYS_ERR()
    end,
    VipLevel = mod_vip:get_role_vip_level(RoleID),
    assert_role_state(RoleID, Level),
    {ok, RoleBase, VipLevel}.

assert_role_state(RoleID, Level) ->
    case mod_map_role:is_role_fighting(RoleID) andalso Level >= 40 of
        true ->
            ?THROW_ERR(?ERR_HORSE_RACING_IN_PK_STATE);
        _ ->
            ok
    end,
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    case RoleBase#p_role_base.status of
        ?ROLE_STATE_NORMAL ->%%正常状态
            ok;
        ?ROLE_STATE_STALL_SELF ->
            ?THROW_ERR(?ERR_HORSE_RACING_IN_STALL_STATE);
        ?ROLE_STATE_STALL ->
            ?THROW_ERR(?ERR_HORSE_RACING_IN_STALL_STATE);
        ?ROLE_STATE_COLLECT ->
            ?THROW_ERR(?ERR_HORSE_RACING_IN_COLLECT_STATE);
        ?ROLE_STATE_DEAD ->
            ?THROW_ERR(?ERR_HORSE_RACING_IN_DEAD_STATE);
        _S->
            ok
    end,    
    case mgeem_map:get_map_type(mgeem_map:get_mapid()) of
        ?MAP_TYPE_COPY ->
            ?THROW_ERR(?ERR_HORSE_RACING_IN_FB_MAP);
        _ ->
            ok
    end,
	
	case mod_spring:is_in_spring_map() of
		true ->
			?THROW_ERR(?ERR_HORSE_RACING_NOT_ALLOW_IN_SPRING);
		_ ->
			ignore
	end,
    ok.

do_horse_racing_exit({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
    clear_role_state(RoleID),
    ?UNICAST_TOC(#m_horse_racing_exit_toc{}),
    ?TRY_CATCH(global:send(mgeew_horse_racing, {role_exit, RoleID})).

do_buy_horse(RoleID, HorseType, OpType) ->
    TransFunc = 
        fun() ->
                [#r_horse_config{consume_gold=Gold}] = common_config_dyn:find(horse_racing, {horse, HorseType}),
                case common_bag2:t_deduct_money(gold_unbind, Gold, RoleID, ?CONSUME_TYPE_GOLD_HORSE_RACING_BUY) of
                    {ok, RoleAttr} ->
                        ok;
                    {error, Reason0} ->
                        RoleAttr = null,
                        ?THROW_ERR(?ERR_OTHER_ERR, Reason0)
                end,
                {ok, RoleAttr}
        end,
    case common_transaction:transaction(TransFunc) of
        {aborted, {error,ErrCode,Reason}} ->
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_GET, 
                                #m_horse_racing_get_toc{err_code=ErrCode, reason=Reason, op_type=OpType});
        {aborted, Reason} ->
            ?ERROR_MSG("钦点美人购买纸船系统错误, error: ~w", [Reason]),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_GET, 
                                #m_horse_racing_get_toc{err_code=?ERR_SYS_ERR, op_type=OpType});
        {atomic, {ok, NewRoleAttr}} ->
            common_misc:send_role_gold_change(RoleID, NewRoleAttr),
            case HorseType of
                6 -> %% 最高级的, 完成成就
                    mod_achievement2:achievement_update_event(RoleID, 22003, 1),
                    mod_achievement2:achievement_update_event(RoleID, 34003, 1);
                _ -> ignore
            end,
            ?TRY_CATCH(global:send(mgeew_horse_racing, {get_horse, RoleID, HorseType, OpType}))
     end.

do_handle_operate(RoleID, OpType, TargetRoleID) ->
    TransFunc =
        fun() ->
                [{MoneyType, DeductMoney, _}] = common_config_dyn:find(horse_racing, {operate, OpType}),
                ConsumeLogType =
                    if OpType =:= ?OP_TYPE_SILVER_BLESS ->
                           ?CONSUME_TYPE_SILVER_HORSE_RACING_BLESS;
                       OpType =:= ?OP_TYPE_GOLD_BLESS ->
                           ?CONSUME_TYPE_GOLD_HORSE_RACING_BLESS;
                       OpType =:= ?OP_TYPE_SILVER_PUNISH ->
                           ?CONSUME_TYPE_SILVER_HORSE_RACING_PUNISH;
                       OpType =:= ?OP_TYPE_GOLD_PUNISH ->
                           ?CONSUME_TYPE_GOLD_HORSE_RACING_PUNISH
                    end,
                case common_bag2:t_deduct_money(MoneyType, DeductMoney, RoleID, ConsumeLogType) of
                    {ok, RoleAttr} ->
                        next;
                    {error, _} ->
                        RoleAttr = null,
                        if OpType =:= ?OP_TYPE_GOLD_BLESS orelse OpType =:= ?OP_TYPE_GOLD_PUNISH ->
                               ?THROW_ERR(?ERR_HORSE_RACING_NOT_ENOUGH_GOLD_TO_OPERATE);
                           true ->
                               ?THROW_ERR(?ERR_HORSE_RACING_NOT_ENOUGH_SILVER_TO_OPERATE)
                        end
                end,
                {ok, RoleAttr}
        end,
    case common_transaction:transaction(TransFunc) of
        {aborted, {error,ErrCode,Reason}} ->
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_OPERATE, 
                                #m_horse_racing_operate_toc{err_code=ErrCode, reason=Reason, op_type=OpType}),
            ?TRY_CATCH(global:send(mgeew_horse_racing, {operate_failed, RoleID, OpType, TargetRoleID}));
        {aborted, Reason} ->
            ?ERROR_MSG("钦点美人护体或惩罚系统错误, error: ~w", [Reason]),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_OPERATE, 
                                #m_horse_racing_operate_toc{err_code=?ERR_SYS_ERR, op_type=OpType}),
            ?TRY_CATCH(global:send(mgeew_horse_racing, {operate_failed, RoleID, OpType, TargetRoleID}));
        {atomic, {ok, NewRoleAttr}} ->
            if OpType =:= ?OP_TYPE_GOLD_BLESS orelse OpType =:= ?OP_TYPE_GOLD_PUNISH ->
                   common_misc:send_role_gold_change(RoleID, NewRoleAttr);
               true ->
                   common_misc:send_role_silver_change(RoleID, NewRoleAttr)
            end,
            hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_HORSE_RACE_OPERAT),
            ?TRY_CATCH(global:send(mgeew_horse_racing, {operate_succ, RoleID, OpType, TargetRoleID}))
    end.

do_handle_fetch_reward(RoleID, RewardExp, RewardPrestige, Yueli) ->
    TransFun =
        fun() ->
                {ok,RoleAttr2} = common_bag2:t_gain_prestige(RewardPrestige,RoleID,?GAIN_TYPE_PRESTIGE_HORSE_RACING),
                {ok,RoleAttr3} = common_bag2:t_gain_yueli(Yueli,RoleAttr2,?GAIN_TYPE_YUELI_HORSE),
                {ok, RoleAttr3}
        end,
    case common_transaction:transaction(TransFun) of
        {atomic, {ok, NewRoleAttr}} ->
                    common_misc:send_role_prestige_change(RoleID,NewRoleAttr),
                    mod_map_role:add_exp(RoleID, RewardExp),
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_REWARD_FETCH, 
                                        #m_horse_racing_reward_fetch_toc{exp=RewardExp, presitge=RewardPrestige, silver=0, yueli=Yueli});
                {aborted, Reason} ->
                    ?ERROR_MSG("fetch horse racing reward error,RoleID:~w,Reason:~w",[RoleID, Reason]),
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_REWARD_FETCH, 
                                        #m_horse_racing_reward_fetch_toc{err_code=?ERR_SYS_ERR})
    end.
    

%% 上线删除称号
hook_role_online(_RoleID) -> ok.

%% 下线判断不准确，会导致删除称号失败
hook_role_offline(RoleID) ->
    case is_role_in_horse_racing(RoleID) of
        true ->
            ?TRY_CATCH(global:send(mgeew_horse_racing, {role_exit, RoleID}));
        _ ->
            ignore
    end.

clear_role_state(RoleID) ->
    case is_role_in_horse_racing(RoleID) of
        true ->
            clear_role_in_horse_racing(RoleID);
        _ ->
            ignore
    end.

hook_vip_up(RoleID, VipLevel) ->
    ?TRY_CATCH(global:send(mgeew_horse_racing, {vip_up, RoleID, VipLevel})).
