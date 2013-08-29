%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created : 17 Dec 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_role2).

%% Include File
-include("mgeem.hrl").
-include("office.hrl").

%% API Func
-export([
         handle/1,
		 handle/2
        ]).

-export([
         do_relive/6,
         do_pk_mode_modify_for_10500/2,
         modify_pk_mode_for_role/2,
		 modify_pk_mode_without_check/2,
         calc_rest_money/3,
         online_broadcast/6,
         init/1,
		 hook_role_dead/1,
		 relive/5
        ]).

-export([p_other_role_info/2]).

-define(SEXMAN, 1).
-define(SEXWOMAN, 2).

-define(DICT_KEY_TIMEREF, time_ref).
-define(PLAIN_RELIVE_INTERVAL, 120).
-define(MAX_PK_MODE, 5).
-define(DEFAULT_ROLE2_FIVE_ELE_ATTR_MIN_LEVEL, 16).

-define(MANWATCHMAN, "<font color=\"#00ff00\">[~s]</font> 挑衅地看着你").
-define(MANWATCHWOMAN, "<font color=\"#00ff00\">[~s]</font> 色迷迷地看着你").
-define(WOMANWATCHMAN, "<font color=\"#00ff00\">[~s]</font> 痴痴地看着你").
-define(WOMANWATCHWOMAN, "<font color=\"#00ff00\">[~s]</font> 鬼鬼祟祟地打量着你").


%% 更换发型价格（文）
-define(HAIR_CUT_PRICE, 10000).
%% 变性价格（元宝）
-define(SEX_CHANGE_PRICE, 50).
%% 更换头像价格（文）
-define(CHANGE_HEAD_PRICE, 10000).

%% 离开新手村事件ID
-define(EVENT_LEVEL_XSC_ID, 1).

%% 发型卡typeid
-define(hair_card_typeid, 10100024).
%% 头像卡typeid
-define(head_card_typeid, 10100023).

relive(Unique, Module, Method, RoleID, ReliveType) ->
	mgeer_role:send(RoleID, {apply, ?MODULE, do_relive, 
		[Unique, Module, Method, RoleID, ReliveType, mgeem_map:get_state()]}).

%% API Func
handle(Info,_State) ->
	handle(Info).
handle(Info) ->
    do_handle(Info).

%% Internal Func
do_handle({Unique, Module, ?ROLE2_HEAD, DataIn, RoleID, PID, _Line, MapState}) ->
    do_head(Unique, Module, ?ROLE2_HEAD, DataIn, RoleID, PID, MapState);
do_handle({Unique, Module, ?ROLE2_SEX, DataIn, RoleID, PID, Line, MapState}) ->
    do_sex(Unique, Module, ?ROLE2_SEX, DataIn, RoleID, PID, MapState, Line);
do_handle({Unique, Module, ?ROLE2_RELIVE, DataIn, RoleID, _PID, Line, MapState}) ->
    do_relive(Unique, Module, ?ROLE2_RELIVE, RoleID, DataIn, Line, MapState);
do_handle({Unique, Module, ?ROLE2_PKMODEMODIFY, DataIn, RoleID, _PID, Line, _MapState}) ->
    do_pk_mode_modify(Unique, Module, ?ROLE2_PKMODEMODIFY, RoleID, DataIn, Line);
do_handle({Unique, Module, ?ROLE2_ZAZEN, DataIn, RoleID, _PID, Line, _MapState}) ->
    do_zazen(Unique, Module, ?ROLE2_ZAZEN, RoleID, DataIn, Line);
do_handle({Unique, Module, ?ROLE2_ZAZEN_BUY_BUFF, DataIn, RoleID, _PID, Line, _MapState}) ->
    do_zazen_buy_buff(Unique, Module, ?ROLE2_ZAZEN_BUY_BUFF, RoleID, DataIn, Line);
do_handle({Unique, Module, ?ROLE2_FIVE_ELE_ATTR, DataIn, RoleID, _PID, Line, _MapState}) ->
    do_five_ele_attr(Unique, Module, ?ROLE2_FIVE_ELE_ATTR, DataIn, RoleID, Line);
do_handle({Unique, Module, ?ROLE2_LEVELUP, DataIn, RoleID, _PID, Line, _MapState}) ->
    do_levelup(Unique, Module, ?ROLE2_LEVELUP, DataIn, RoleID, Line);
do_handle({Unique, Module, ?ROLE2_SHOW_CLOTH, DataIn, RoleID, _PID, Line, _MapState}) ->
    do_show_cloth(Unique, Module, ?ROLE2_SHOW_CLOTH, DataIn, RoleID, Line);
do_handle({Unique, Module, ?ROLE2_PKPOINT_LEFT, _DataIn, RoleID, _PID, Line, _MapState}) ->
    do_pkpoint_left(Unique, Module, ?ROLE2_PKPOINT_LEFT, RoleID, Line);
do_handle({Unique, Module, ?ROLE2_GETROLEATTR, DataIn, RoleID, PID, Line, _MapState}) ->
    do_get_roleattr(Unique, Module, ?ROLE2_GETROLEATTR, RoleID, DataIn, PID, Line);
do_handle({Unique, Module, ?ROLE2_UNBUND_CHANGE, DataIn, RoleID, _PID, _Line, _MapState}) ->
    do_unbund_change(Unique, Module, ?ROLE2_UNBUND_CHANGE, RoleID, DataIn);
do_handle({Unique, Module, ?ROLE2_EVENT, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_event(Unique, Module, ?ROLE2_EVENT, DataIn, RoleID, PID);
do_handle({Unique, Module, ?ROLE2_REMOVE_SKIN_BUFF, _DataIn, RoleID, PID, _Line, _MapState}) ->
    do_remove_skin_buff(Unique, Module, ?ROLE2_REMOVE_SKIN_BUFF, RoleID, PID);
do_handle({Unique, Module, ?ROLE2_ADD_ENERGY, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_add_energy(Unique, Module, ?ROLE2_ADD_ENERGY, DataIn, RoleID, PID);
do_handle({Unique, Module, ?ROLE2_CONSUME_JIFEN_CHANGE, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_role2_consume_jifen_change({Unique, Module, ?ROLE2_CONSUME_JIFEN_CHANGE, DataIn, RoleID, PID});

%% 人物培养
do_handle({_, ?ROLE2, ?ROLE2_GROW_REFRESH, _, _, _PID, _Line, _MapState}=Info) ->
    mod_role_grow:handle(Info);
do_handle({_, ?ROLE2, ?ROLE2_GROW_SAVE, _, _, _PID, _Line, _MapState}=Info) ->
    mod_role_grow:handle(Info);
do_handle({_, ?ROLE2, ?ROLE2_GROW_SHOW, _, _, _PID, _Line, _MapState}=Info) ->
    mod_role_grow:handle(Info);
          
%% 玩家改名
do_handle({Unique, Module, ?ROLE2_RENAME, NewRoleName, RoleID, PID}) ->
    do_rename(Unique, Module, ?ROLE2_RENAME, NewRoleName, RoleID, PID);
do_handle({Unique, Module, ?FACTION_CHANGE, FactionID, ToStrength, RoleID, PID}) ->
    do_change_faction(Unique, Module, ?FACTION_CHANGE, FactionID, ToStrength, RoleID, PID);

%% 选择职业
do_handle({Unique, Module, ?ROLE2_CHOOSE_CATEGORY, DataIn, RoleID, PID, _Line, MapState}) ->
	#m_role2_choose_category_tos{category=Category} = DataIn,
	do_choose_category(Unique,Module,?ROLE2_CHOOSE_CATEGORY,Category,RoleID,PID,MapState);

%% 购买体力
do_handle({Unique, Module, ?ROLE2_BUY_TILI, _DataIn, RoleID, PID, _Line, _MapState}) ->
	mod_tili:buy_tili({Unique,Module,?ROLE2_BUY_TILI,RoleID,PID});

%% 日常循环任务
do_handle({Unique, Module, ?ROLE2_DAILY_MISSION_INFO, _DataIn, RoleID, PID, _Line, _MapState}) ->
	mod_daily_mission:daily_mission_info({Unique,Module,?ROLE2_DAILY_MISSION_INFO,RoleID,PID});
do_handle({Unique, Module, ?ROLE2_DAILY_MISSION_REFRESH, DataIn, RoleID, PID, _Line, _MapState}) ->
	#m_role2_daily_mission_refresh_tos{op_type=OpType} = DataIn,
	mod_daily_mission:daily_mission_refresh({Unique,Module,?ROLE2_DAILY_MISSION_REFRESH,RoleID,OpType,PID});
do_handle({Unique, Module, ?ROLE2_DAILY_MISSION_FINISH, DataIn, RoleID, PID, _Line, _MapState}) ->
	#m_role2_daily_mission_finish_tos{op_type=OpType} = DataIn,
	mod_daily_mission:daily_mission_finish({Unique,Module,?ROLE2_DAILY_MISSION_FINISH,RoleID,OpType,PID});

%% 在线挂机模块处理
%% do_handle({Unique, Module, ?ROLE2_ON_HOOK_BEGIN, DataIn, RoleID, PID, Line, _MapState}) ->
%%     mod_role_on_hook:do_handle_info({Unique, Module, ?ROLE2_ON_HOOK_BEGIN, DataIn, RoleID, PID,Line});
%% do_handle({Unique, Module, ?ROLE2_ON_HOOK_END, DataIn, RoleID, PID, Line, _MapState}) ->
%%     mod_role_on_hook:do_handle_info({Unique, Module, ?ROLE2_ON_HOOK_END, DataIn, RoleID, PID,Line});
%% do_handle({Unique, Module, ?ROLE2_ON_HOOK_STATUS, DataIn, RoleID, PID, Line, _MapState}) ->
%%     mod_role_on_hook:do_handle_info({Unique, Module, ?ROLE2_ON_HOOK_STATUS, DataIn, RoleID, PID,Line});

%% 查询当前国家在线玩家榜数据
do_handle({Unique, Module, ?ROLE2_QUERY_FACTION_ONLINE_RANK, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_query_faction_online_rank(Unique, Module, ?ROLE2_QUERY_FACTION_ONLINE_RANK, DataIn, RoleID, PID);
do_handle({admin_query_faction_online_rank,Msg}) ->
    do_admin_query_faction_online_rank(Msg);
do_handle({admin_join_faction_online_rank,Msg}) ->
    do_admin_join_faction_online_rank(Msg);
do_handle({admin_quit_faction_online_rank,Msg}) ->
    do_admin_quit_faction_online_rank(Msg);
do_handle({admin_uplevel_faction_online_rank,Msg}) ->
    do_admin_uplevel_faction_online_rank(Msg);

%% GM命令设置玩家五行属性
do_handle({admin_set_role_five_ele_attr, RoleID, FiveEleAttr}) ->
    do_admin_set_role_five_ele_attr(RoleID,FiveEleAttr);

do_handle({gm_set_category, RoleID, Category}) ->
	case common_transaction:t(fun() -> t_choose_category(RoleID,Category) end) of
		{atomic, {ok,Head,_FactionID}} ->
			Change = [{#p_map_role.category,Category}],
			mod_map_role:update_map_role_info(RoleID, Change),
			R2 = #m_role2_choose_category_toc{category=Category,head=Head},
			common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_CHOOSE_CATEGORY, R2);
		_ ->
			ignore
	end;

do_handle(Info) ->
    ?ERROR_MSG("mod_role2, unknow info: ~w", [Info]).

%% 地图进程创建初始化
init(MapId) ->
    [DoFactionOnlineRoleRankMapId] = common_config_dyn:find(etc,do_faction_online_role_rank_map_id),
    case DoFactionOnlineRoleRankMapId =:= MapId of
        true ->
            init_faction_online_role_rank(DoFactionOnlineRoleRankMapId,1),
            init_faction_online_role_rank(DoFactionOnlineRoleRankMapId,2),
            init_faction_online_role_rank(DoFactionOnlineRoleRankMapId,3);
        _ ->
            ignore
    end,
    ok.

do_role2_consume_jifen_change(Msg)->
	case global:whereis_name( mgeew_accgold_server ) of
        undefined->
            {error,undefined};
        PID ->
			?DBG(PID),
            PID ! {get_consume_jifen,Msg}
    end.


%% 玩家改名
do_rename(Unique, Module, Method, NewRoleName, RoleID, PID) ->
    case db:transaction(fun() -> t_rename(RoleID, NewRoleName) end) of
        {atomic, FamilyID} ->
            common_role:do_update_family_member_name(FamilyID, RoleID, NewRoleName),
            common_misc:send_to_rolemap(RoleID, {mod_map_role, {rename_notify, RoleID, NewRoleName}}),
            ?ERROR_MSG("~ts,Self=~w",["玩家改名返回结果",#m_role2_rename_toc{}]),
            ?UNICAST_TOC( #m_role2_rename_toc{}),
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    do_rename_error(Unique, Module, Method, Error, PID);
                false ->
                    ?ERROR_MSG("~ts:~w", ["玩家改名时发生系统错误", Error]),
                    do_rename_error(Unique, Module, Method, ?_LANG_ROLE2_SYSTEM_ERROR_WHEN_RENAME, PID)
            end,
            ok
    end.

do_rename_error(Unique, Module, Method, Reason, PID) ->
    R = #m_role2_rename_toc{succ=false, reason=Reason},
    ?ERROR_MSG("~ts,Self=~w",["玩家改名返回结果",R]),
    ?UNICAST_TOC( R).


t_rename(RoleID, NewRoleName) ->    
    {ok, #p_role_attr{role_name=RoleName} = Attr} = mod_map_role:get_role_attr(RoleID),   
    FamilyID = common_role:t_rename(RoleID, NewRoleName),
    [PostFix] = common_config_dyn:find(merge, rename_postfix),
    ?ERROR_MSG("~ts ~ts ~p", [common_tool:to_list(RoleName), PostFix, string:str(common_tool:to_list(RoleName), PostFix)]),
    {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
    case string:str(common_tool:to_list(RoleName), PostFix) > 0 of
        true ->
            %% 玩家名字中包含合服改名的特殊字符，允许改名，并且免费
            mod_map_role:set_role_attr(RoleID, Attr#p_role_attr{role_name=NewRoleName}),
            mod_map_role:set_role_base(RoleID, RoleBase#p_role_base{role_name = NewRoleName}),
            ok;
        false ->
            [ReduceGold] = common_config_dyn:find(etc, rename_gold),  
            case common_bag2:t_deduct_money(gold_any, ReduceGold, RoleID, ?CONSUME_TYPE_GOLD_RENAME) of
                {ok, RoleAttr2} -> ok;
                {error, Reason} ->
                    RoleAttr2 = Attr,
                    db:abort(Reason)
            end,
            mod_map_role:set_role_attr(RoleID, RoleAttr2#p_role_attr{role_name=NewRoleName}),
            mod_map_role:set_role_base(RoleID, RoleBase#p_role_base{role_name = NewRoleName})
    end,
    FamilyID.

do_change_faction(Unique, Module, Method, FactionID, ToStrength, RoleID, PID) ->
    case db:transaction(fun() -> t_change_faction(RoleID, FactionID, ToStrength) end) of
        {atomic, {RoleAttr2, OldFactionID}} ->
            common_misc:send_role_gold_change(RoleID, RoleAttr2),
            %% 移民后刷新玩家任务列表
            mod_mission_handler:reload_pinfo_list(RoleID),
            RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
            mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo#p_map_role{faction_id=FactionID}),
            RRoleMap = #m_map_update_actor_mapinfo_toc{actor_id=RoleID, actor_type=?TYPE_ROLE, 
                                                       role_info=RoleMapInfo#p_map_role{faction_id=FactionID}},
            mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, RRoleMap, mgeem_map:get_state()),
            ?UNICAST_TOC( #m_faction_change_toc{} ),
            %% 发消息通知玩家切换到对应国家的京城
            hook_map_role:change_faction(RoleID, RoleAttr2#p_role_attr.role_name, OldFactionID, FactionID),
            ok;
        {aborted, Error} ->            
            case erlang:is_binary(Error) of
                true ->
                    R = #m_faction_change_toc{succ=false, reason=Error},
                    ?UNICAST_TOC( R);
                false ->
                    ?ERROR_MSG("~ts:~p", ["处理移民出错", Error])
            end,
            ok
    end,
    ok.

t_change_faction(RoleID, FactionID, ToStrength) ->
    case lists:member(FactionID, ?FACTIONID_LIST) of
        true ->
            ok;
        false ->
            db:abort(?_LANG_ROLE2_CHANGE_FACTION_PARAM_ERROR)
    end,
    {ok, #p_role_base{faction_id=CurFactionID, family_id=FamilyID, team_id=TeamId} = RoleBase} = mod_map_role:get_role_base(RoleID),
    {ok, #p_role_attr{office_id=OfficeID} = RoleAttr} = mod_map_role:get_role_attr(RoleID),
    if TeamId =:= 0 orelse TeamId =:= undefined ->
            ok;
       true ->
            db:abort(?_LANG_ROLE2_CHANGE_FACTION_HAS_TEAM)
    end,
    case CurFactionID =:= FactionID of
        true ->
            db:abort(?_LANG_ROLE2_CANNT_CHANGE_SAME_FACTION);
        false ->
            ok
    end,
    case FamilyID > 0 of
        true ->
            db:abort(?_LANG_ROLE2_CHANGE_FACTION_CANNT_HAS_FAMILY);
        false ->
            ok
    end,
    %% 判断官职 
    case OfficeID > 0 of
        true ->
            db:abort(?_LANG_ROLE2_CHAGNE_FACTION_CANNT_HAS_OFFICE);
        false ->
            ok
    end,
    mod_map_role:set_role_base(RoleID, RoleBase#p_role_base{faction_id=FactionID}),
    %% 强国、弱国都可以移民，但是代价不同
    [{CommonReduceGold, StrengthReduceGold}] = common_config_dyn:find(etc, change_faction_gold),    
    case ToStrength of
        true ->
            ReduceGold = StrengthReduceGold;
        false ->
            ReduceGold = CommonReduceGold
    end,
    case common_bag2:t_deduct_money(gold_unbind, ReduceGold, RoleID, ?CONSUME_TYPE_GOLD_CHANGE_FACTION) of
        {ok, RoleAttr2} -> ok;
        {error, Reason} ->
             RoleAttr2 = RoleAttr,
            db:abort(Reason)
    end,
    {RoleAttr2, CurFactionID}.


%% @doc 重置精力值
do_add_energy(Unique, Module, Method, DataIn, RoleID, PID) ->
    #m_role2_add_energy_tos{gold_exchange=GoldExchange} = DataIn,
    case catch check_can_add_energy(RoleID, GoldExchange) of
        {ok, GoldExchange2, RoleFight} ->
            do_add_energy2(Unique, Module, Method, RoleID, PID, GoldExchange2, RoleFight);
        {error, Reason} ->
            do_add_energy_error(Unique, Module, Method, PID, Reason)
    end.


do_add_energy2(Unique, Module, Method, RoleID, PID, GoldExchange, RoleFight) ->
    case common_transaction:t(
           fun() ->
                   case common_bag2:t_deduct_money(gold_any, GoldExchange, RoleID, no_log) of
                    {ok, RoleAttr2} -> 
                        {RoleAttr2#p_role_attr.gold, RoleAttr2#p_role_attr.gold_bind};
                    {error, Reason} ->
                        ?THROW_ERR_REASON(Reason)
                   end
           end)
    of
        {atomic, {Gold2, GoldBind2}} ->
            #p_role_fight{energy=Energy, energy_remain=EnergyRemain} = RoleFight,
            [Gold2Energy] = common_config_dyn:find(etc, gold2energy),
            EnergyAdd = GoldExchange * Gold2Energy,

            case EnergyRemain - EnergyAdd < 0 of
                true ->
                    EnergyRemain2 = 0,
                    Energy2 = Energy + EnergyRemain;
                _ ->
                    EnergyRemain2 = EnergyRemain - EnergyAdd,
                    Energy2 = Energy + EnergyAdd
            end,
   
            RoleFight2 = RoleFight#p_role_fight{energy=Energy2, energy_remain=EnergyRemain2},
            mod_map_role:set_role_fight(RoleID, RoleFight2),

            DataRecord = #m_role2_add_energy_toc{gold=Gold2,
                                                 gold_bind=GoldBind2,
                                                 energy=Energy2,
                                                 energy_remain=EnergyRemain2},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord);
        {aborted,{error,_ErrCode,Reason}} ->
            do_add_energy_error(Unique, Module, Method, PID, Reason);
        {aborted, Error} ->
            ?ERROR_MSG("do_add_energy, error: ~w", [Error]),
            do_add_energy_error(Unique, Module, Method, PID, ?_LANG_ROLE2_ADD_ENERGY_SYSTEM_ERROR)
    end.

do_add_energy_error(Unique, Module, Method, PID, Reason) ->
    DataRecord = #m_role2_add_energy_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

%% @doc 精力值补充相关判断
check_can_add_energy(RoleID, GoldExchange) ->
    case GoldExchange =< 0 of
        true ->
            erlang:throw({error, ?_LANG_ROLE2_ADD_ENERGY_ILLEGAL_INPUT});
        _ ->
            ok
    end,
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{gold=Gold, gold_bind=GoldBind} = RoleAttr,
    case GoldExchange > GoldBind + Gold of
        true ->
            erlang:throw({error, ?_LANG_ROLE2_ADD_ENERGY_NOT_ENOUGH_GOLD});
        _ ->
            ok
    end,
    %% 剩余精力值兑换元宝
    {ok, RoleFight} = mod_map_role:get_role_fight(RoleID),
    #p_role_fight{energy_remain=EnergyRemain} = RoleFight,
    case EnergyRemain =< 0 of
        true ->
            erlang:throw({error, ?_LANG_ROLE2_ADD_ENERGY_ENERGY_REMAIN_NOT_ENOUGH});
        _ ->
            ok
    end,
    %% 兑换的精力值不超过剩余精力值
    [Gold2Energy] = common_config_dyn:find(etc, gold2energy),
    EnergyAdd = GoldExchange * Gold2Energy,
    case EnergyAdd > EnergyRemain of
        true ->
            GoldExchange2 = common_tool:ceil(erlang:round(EnergyRemain)/Gold2Energy);
        _ ->
            GoldExchange2 = GoldExchange
    end,
    {ok, GoldExchange2, RoleFight}.

%% 移除变身价格，5两
-define(remove_skin_buff_price, 500).

%% @doc 移除变身状态
do_remove_skin_buff(Unique, Module, Method, RoleID, PID) ->
    case common_transaction:transaction(
           fun() ->
                   t_do_remove_skin_buff(RoleID)
           end)
    of
        {atomic, {Silver, SilverBind}} ->
            %% 移除BUFF
            mod_role_buff:del_buff_by_type(RoleID, ?SKIN_BUFF_TYPE),
            %% 通知钱币变动
            SilverChange = #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=Silver},
            SilverBindChange = #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=SilverBind},
            DataRecord2 = #m_role2_attr_change_toc{roleid=RoleID, changes=[SilverChange, SilverBindChange]},
            common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord2),

            DataRecord = #m_role2_remove_skin_buff_toc{};
        {aborted, Reason} when is_binary(Reason) ->
            DataRecord = #m_role2_remove_skin_buff_toc{succ=false, reason=Reason};
        {aborted, Reason} ->
            ?ERROR_MSG("do_remove_skin_buff, error: ~w", [Reason]),
            DataRecord = #m_role2_remove_skin_buff_toc{succ=false, reason=?_LANG_ROLE2_REMOVE_SKIN_BUFF_ERROR}
    end,

    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

t_do_remove_skin_buff(RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{silver=Silver, silver_bind=SilverBind} = RoleAttr,
    
    case Silver+SilverBind >= ?remove_skin_buff_price of
        true ->
            ok;
        _ ->
            common_transaction:abort(?_LANG_ROLE2_REMOVE_SKIN_BUFF_NOT_ENOUGH_SILVER)
    end,

    {RestSilver, RestSilverBind} = calc_rest_money(Silver, SilverBind, ?remove_skin_buff_price),
    RoleAttr2 = RoleAttr#p_role_attr{silver=RestSilver, silver_bind=RestSilverBind},
    mod_map_role:set_role_attr(RoleID, RoleAttr2),

    %% 消费日志
    common_consume_logger:use_silver({RoleID, SilverBind-RestSilverBind, Silver-RestSilver, ?CONSUME_TYPE_SILVER_CHANGE_SKIN,
                                      ""}),
    
    {RestSilver, RestSilverBind}.

%% @doc 头像
do_head(Unique, Module, Method, DataIn, RoleID, PID, _MapState) ->
    #m_role2_head_tos{head_id=HeadID} = DataIn,
    %% 检测头像ID是否合法
    case check_head_id_illegal(HeadID) of
        ok ->
            do_head2(Unique, Module, Method, HeadID, RoleID, PID);
        {error, Reason} ->
            do_head_error(Unique, Module, Method, RoleID, Reason, PID)
    end.

do_head2(Unique, Module, Method, HeadID, RoleID, PID) ->
    case common_transaction:transaction(
           fun() ->
                   t_do_head(RoleID, HeadID)
           end)
    of
        {atomic, {ok, reduce_money, Silver, SilverBind, Skin}} ->
            DataRecord = #m_role2_head_toc{head_id=HeadID},
            ?UNICAST_TOC( DataRecord),
            %% 通知钱币变动
            common_misc:send_role_silver_change(RoleID,{Silver,SilverBind}),
            %% 广播皮肤变动
            mod_map_role:update_map_role_info(RoleID, [{#p_map_role.skin, Skin}]),
            %% 世界广播
            broadcast_head_change(RoleID),
            ok;
        {atomic, {ok, reduce_card, ChangeList, DelList, Skin}} ->
            %% 返回结果
            DataRecord = #m_role2_head_toc{head_id=HeadID},
            ?UNICAST_TOC( DataRecord),
            %% 通知物品变动
            case ChangeList of
                []->
                    [Goods] = DelList,
                    item_used_log([Goods#p_goods{current_num=1}]),
                    common_misc:del_goods_notify({role, RoleID}, DelList);
                _->
                    [Goods] = ChangeList,
                    item_used_log([Goods#p_goods{current_num=1}]),
                    common_misc:update_goods_notify({role, RoleID}, Goods)
            end,
            %% 广播皮肤变动
            mod_map_role:update_map_role_info(RoleID, [{#p_map_role.skin, Skin}]),
            %% 世界广播
            broadcast_head_change(RoleID),
            ok;
        {aborted, Reason} when is_binary(Reason) ->
            do_head_error(Unique, Module, Method, RoleID, Reason, PID);
        {aborted, Reason} ->
            ?ERROR_MSG("do_head, error: ~w", [Reason]),
            do_head_error(Unique, Module, Method, RoleID, ?_LANG_ROLE2_HEAD_SYSTEM_ERROR, PID)
    end.

do_head_error(Unique, Module, Method, _RoleID, Reason, PID) ->
    DataRecord = #m_role2_head_toc{succ=false, reason=Reason},
    ?UNICAST_TOC( DataRecord).

t_do_head(RoleID, HeadID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{skin=Skin, silver=Silver, silver_bind=SilverBind} = RoleAttr,
    %% 先减头像卡
    {ReduceType, ReturnA, ReturnB} =
        case catch mod_bag:decrease_goods_by_typeid(RoleID, ?head_card_typeid, 1) of
            {ok, UpdateList, DelList} ->
                Skin2 = Skin#p_skin{skinid=HeadID},
                RoleAttr2 = RoleAttr#p_role_attr{skin=Skin2},
                mod_map_role:set_role_attr(RoleID, RoleAttr2),
                {reduce_card, UpdateList, DelList};

            _ ->
                case Silver + SilverBind < ?CHANGE_HEAD_PRICE of
                    true ->
                        common_transaction:abort(?_LANG_ROLE2_HEAD_NOT_ENOUGH_SILVER);
                    _ ->
                        ok
                end,

                {Silver2 , SilverBind2} = calc_rest_money(Silver, SilverBind, ?CHANGE_HEAD_PRICE),

                Skin2 = Skin#p_skin{skinid=HeadID},
                RoleAttr2 = RoleAttr#p_role_attr{skin=Skin2, silver=Silver2, silver_bind=SilverBind2},
                mod_map_role:set_role_attr(RoleID, RoleAttr2),

                %% 消费日志
                common_consume_logger:use_silver({RoleID, SilverBind-SilverBind2, Silver-Silver2, ?CONSUME_TYPE_SILVER_CHANGE_HEAD,
                                                  ""}),

                {reduce_money, Silver2, SilverBind2}
        end,

    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    mod_map_role:set_role_base(RoleID, RoleBase#p_role_base{head=HeadID}),

    {ok, ReduceType, ReturnA, ReturnB, Skin2}.

do_sex(Unique, Module, Method, _DataIn, RoleID, PID, _MapState, _Line) ->
    case common_transaction:transaction(
           fun() ->
                   t_do_sex(RoleID)
           end)
    of
        {atomic, {ok, Sex2, Skin2, Gold, GoldBind,RoleAttr,RoleBase}} ->
            mod_map_role:update_map_role_info(RoleID, [{#p_map_role.skin, Skin2}]),
            AttrChanges = common_role:get_attr_change_list([{gold, Gold}, {charm, 0}, {gold_bind, GoldBind}]),
            RAttrChanges = #m_role2_attr_change_toc{roleid=RoleID, changes=AttrChanges},
            common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, RAttrChanges),
            %%把送花得分清零
            db:dirty_write(?DB_ROLE_GIVE_FLOWERS,#r_give_flowers{role_id=RoleID,score=0}),
            hook_map_role:sex_change(RoleID, Sex2),
                    catch global:send(mgeew_ranking,{ranking_element_update,ranking_give_flowers,{RoleBase,RoleAttr,0}}),
                    catch global:send(mgeew_ranking,{ranking_element_update,ranking_give_flowers_today,{RoleBase,RoleAttr,0}}),
                    catch global:send(mgeew_ranking,{ranking_element_update,ranking_rece_flowers,{RoleBase,RoleAttr}}),
                    catch global:send(mgeew_ranking,{ranking_element_update,ranking_rece_flowers_today,{RoleBase,RoleAttr,0}}),
            %% 变性成功
            ?UNICAST_TOC( #m_role2_sex_toc{sex=Sex2}),
            %% 成功变性广播
            common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER, ?BC_MSG_SUB_TYPE, ?_LANG_ROLE2_SEX_BROADCAST_MSG),
            ok;
        {aborted, Reason} when is_binary(Reason); is_list(Reason) ->
            do_sex_error(Unique, Module, Method, RoleID, Reason, PID);
        {aborted, Reason} ->
            ?ERROR_MSG("do_sex, error: ~w", [Reason]),
            do_sex_error(Unique, Module, Method, RoleID, ?_LANG_SYSTEM_ERROR, PID)
    end.

do_sex_error(Unique, Module, Method, _RoleID, Reason, PID) ->
    DataRecord = #m_role2_sex_toc{succ=false, reason=Reason},
    ?UNICAST_TOC( DataRecord).

t_do_sex(RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),    
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{sex=Sex} = RoleBase,
    Sex2 = if Sex =:= 1 -> 2; true -> 1 end,
    #p_role_attr{skin=Skin} = RoleAttr,
    {ok, SkinID, _HairType} = get_new_skin_and_hair(Sex2),
    Skin2 = Skin#p_skin{skinid=SkinID},
    RoleAttr3 = RoleAttr#p_role_attr{skin=Skin2,charm=0},
    mod_map_role:set_role_attr(RoleID, RoleAttr3),

    case common_bag2:t_deduct_money(gold_any, ?SEX_CHANGE_PRICE, RoleID, ?CONSUME_TYPE_GOLD_SEX_CHANGE) of
        {ok, NewRoleAttr} -> ok;
        {error, Reason} ->
            NewRoleAttr = RoleAttr3,
            common_transaction:abort(Reason)
    end,

    RoleBase3 = RoleBase#p_role_base{sex=Sex2, head=SkinID},
    mod_map_role:set_role_base(RoleID, RoleBase3),
   {ok, Sex2, Skin2, NewRoleAttr#p_role_attr.gold, NewRoleAttr#p_role_attr.gold_bind,RoleAttr,RoleBase}.

calc_rest_money(Money, MoneyBind, MoneyNeed) ->
    case MoneyBind - MoneyNeed >= 0 of
        true ->
            {erlang:trunc(Money), erlang:trunc(MoneyBind-MoneyNeed)};
        _ ->
            {erlang:trunc(Money-(MoneyNeed-MoneyBind)), 0}
    end.

%% 国王
-define(role_type_king, 1).
%% 战斗力排行第一
-define(fighting_power_rank, 2).

%% @doc 上线广播
online_broadcast(RoleID, RoleName, _PID, OfficeID, FactionID, Level) ->
	%% 30级以上才广播
	case Level >= 30 of
		true ->
			case common_role:get_fighting_power_rank(RoleID) of
				#p_role_fighting_power_rank{ranking=Ranking} when Ranking =:= 1 ->
					DataRecord = #m_role2_online_broadcast_toc{role_type=?fighting_power_rank, 
															   role_name=RoleName,
															   faction_id = FactionID},
					common_misc:chat_broadcast_to_world(?ROLE2, ?ROLE2_ONLINE_BROADCAST, DataRecord);
				_ ->
					if
						OfficeID =:= ?OFFICE_ID_KING ->
							DataRecord = #m_role2_online_broadcast_toc{role_type=?role_type_king, 
																	   role_name=RoleName,
																	   faction_id = FactionID},
							common_misc:chat_broadcast_to_faction(FactionID, ?ROLE2, ?ROLE2_ONLINE_BROADCAST, DataRecord);
						true ->
							ignore
					end
			end;
		false ->
			ignore
	end.

%% @doc 变性后随机生成头像及头发ID
get_new_skin_and_hair(Sex) ->
    Random = common_tool:random(6, 9),
    {ok, 2*Random+Sex, (Random rem 3) + 1}.

%% @doc 复活
do_relive(Unique, Module, Method, RoleID, ReliveType, MapState) -> 
	mod_role_buff:del_buff_by_type(RoleID, [0]),
    case common_transaction:transaction(fun() -> t_do_relive(RoleID, ReliveType, MapState) end) of
        {atomic, {HP, MP, RoleAttr2}} ->
            %%取消自动复活定时
            case erase({auto_relive_timer_ref, RoleID}) of
                undefined ->
                    ok;
                TimerRef ->
                    erlang:cancel_timer(TimerRef)
            end,
            if is_tuple(ReliveType) ->
                    ReliveType2 = ?RELIVE_TYPE_ORIGINAL_FREE;
               true ->
                    ReliveType2 = ReliveType
            end,
            case cfg_relive:relive_buff(MapState#map_state.mapid, ReliveType) of
                Buffs when is_list(Buffs) ->
                    mod_role_buff:add_buff(RoleID, Buffs);
                _ ->
                    ignore
            end,
            mgeem_map:send({mod_map_role, {relive, RoleID, ReliveType2, {HP, MP}, Unique}}),
			case mod_ybc_person:check_in_ybcing(RoleID, role) of
				true ->
					mod_ybc_person:set_ybc_speed(RoleID);
				false ->
					ignore
			end,
            case is_record(RoleAttr2,p_role_attr) of
                true->
                    common_misc:send_role_silver_change(RoleID, RoleAttr2),
                    common_misc:send_role_gold_change(RoleID, RoleAttr2);
                _ ->
                    ignore
            end;
        {aborted, R} when is_binary(R) ->
            do_relive_error(Unique, Module, Method, RoleID, R);

        {aborted, R} ->
            ?ERROR_MSG("do_relive, error: ~w", [R]),
            do_relive_error(Unique, Module, Method, RoleID, ?_LANG_SYSTEM_ERROR)
    end.

%%复活
do_relive(Unique, Module, Method, RoleID, DataIn, _Line, MapState) ->
    ReliveType = DataIn#m_role2_relive_tos.type,
    do_relive(Unique, Module, Method, RoleID, ReliveType, MapState).

do_relive_error(Unique, Module, Method, RoleID, Reason) ->
    Record = #m_role2_relive_toc{succ=false, reason=Reason},
    common_misc:unicast({role, RoleID}, Unique, Module, Method, Record).

t_do_relive(RoleID, ReliveType, _MapState) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    RoleBase2 = RoleBase#p_role_base{status=?ROLE_STATE_NORMAL},
    DeadTime = get({role_dead_time, RoleID}),
    Result = case ReliveType of
        ?RELIVE_TYPE_ORIGINAL_FREE ->
            t_do_relive_original_free(RoleID, RoleBase2, DeadTime);
        ?RELIVE_TYPE_ORIGINAL_SILVER ->
            t_do_relive_original_silver(RoleID, RoleBase2);
        ?RELIVE_TYPE_ORIGINAL_GOLD->
            t_do_relive_original_gold(RoleID, RoleBase2);
        
        ?RELIVE_TYPE_HOME_FREE_FULL ->
            t_do_relive_home_free_full(RoleID, RoleBase2);
        ?RELIVE_TYPE_HOME_SILVER->
            t_do_relive_home_silver(RoleID, RoleBase2);
        ?RELIVE_TYPE_HOME_FREE_HALF->
            t_do_relive_home_free_half(RoleID, RoleBase2);
        
        {?RELIVE_TYPE_SKILL, ResumRate} ->
            t_do_relive_skill(RoleID, RoleBase2, ResumRate);
        _ ->
            common_transaction:abort(?_LANG_ROLE2_RELIVE_BAD_TYPE)
    end,
    mod_map_role:set_role_base(RoleID,RoleBase2),
    erase({role_dead_time, RoleID}),
	Result.

t_do_relive_original_free(_RoleID, RoleBase, DeadTime) ->
    case DeadTime =:= undefined orelse common_tool:now()-DeadTime >= ?PLAIN_RELIVE_INTERVAL of
        true ->
            #p_role_base{max_hp=MaxHP, max_mp=MaxMP} = RoleBase,
            {common_tool:ceil(MaxHP*0.2), common_tool:ceil(MaxMP), undefined};
        _ ->
            common_transaction:abort(?_LANG_ROLE2_RELIVE_ILLEGAL_INTERVAL)
    end.

t_do_relive_skill(_RoleID, RoleBase, ResumRate) ->
    #p_role_base{max_hp=MaxHP, max_mp=MaxMP} = RoleBase,
    {common_tool:ceil(MaxHP*ResumRate/10000), common_tool:ceil(MaxMP*ResumRate/10000), undefined}.

%%扣银子，原地复活
t_do_relive_original_silver(RoleID, RoleBase) ->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{equips=Equips, level=Level} = RoleAttr,
    #p_role_base{faction_id=FactionID, max_hp=MaxHP, max_mp=MaxMP} = RoleBase, 
    SilverNeed = mod_map_role:get_relive_silver(FactionID, Level, Equips, mgeem_map:get_state()),
	case common_bag2:t_deduct_money(silver_any, SilverNeed, RoleID, ?CONSUME_TYPE_SILVER_RELIVE) of
        {ok,RoleAttr2}->
            mod_map_role:set_role_attr(RoleID,RoleAttr2);
        {error, Reason} ->
            RoleAttr2 = null,
            common_transaction:abort(Reason)
    end,
    {MaxHP, MaxMP, RoleAttr2}.


%%回城复活(满血收费)
t_do_relive_home_silver(RoleID, RoleBase)->
    #p_role_base{max_hp=MaxHP, max_mp=MaxMP} = RoleBase,
    
    SilverNeed = 300,   %%目前定价300铜
    case common_bag2:t_deduct_money(silver_any, SilverNeed, RoleID, ?CONSUME_TYPE_SILVER_RELIVE) of
        {ok,RoleAttr2}->
            mod_map_role:set_role_attr(RoleID,RoleAttr2);
        % {error,_MoneyType}->
        %     RoleAttr2 = null,
        %     common_transaction:abort(?_LANG_NOT_ENOUGH_SILVER);
        {error, Reason} ->
            RoleAttr2 = null,
            common_transaction:abort(Reason)
    end,
    {MaxHP, MaxMP, RoleAttr2}.


%%回城复活(满血免费)
t_do_relive_home_free_full(_RoleID, RoleBase) ->
    #p_role_base{max_hp=MaxHP, max_mp=MaxMP} = RoleBase,
    {MaxHP, MaxMP, undefined}.

%%回城复活(半血免费)
t_do_relive_home_free_half(_RoleID, RoleBase)->
    #p_role_base{max_hp=MaxHP, max_mp=MaxMP} = RoleBase,
    {common_tool:ceil(MaxHP*0.5), common_tool:ceil(MaxMP), undefined}.

%%扣元宝，原地复活
t_do_relive_original_gold(RoleID, RoleBase)->
    #p_role_base{max_hp=MaxHP, max_mp=MaxMP} = RoleBase, 
    MapId1 = mgeem_map:get_mapid(),
    
    %%玄冥塔统一按照第一关收费
    case MapId1 >=105001 andalso MapId1 =< 105081 of
        true ->
            MapId = 105001;
        false ->
            MapId = MapId1
    end,
    case cfg_relive:original_gold(MapId) of
        undefined ->
            {MaxHP, MaxMP, undefined};
        {DeductType,DeductGold} when DeductType=:=gold_any orelse DeductType=:=gold_unbind ->
            case common_bag2:t_deduct_money(DeductType, DeductGold, RoleID, ?CONSUME_TYPE_GOLD_RELIVE) of
                {ok,RoleAttr2}->
                    mod_map_role:set_role_attr(RoleID,RoleAttr2),
                    {MaxHP, MaxMP, RoleAttr2};
                % {error,_MoneyType}->
                %     common_transaction:abort(?_LANG_NOT_ENOUGH_GOLD);
                {error, Reason} ->
                    common_transaction:abort(Reason)
            end;
        false->
            common_transaction:abort(?_LANG_SYSTEM_ERROR)
    end.

%%@doc 修改玩家的PK模式
modify_pk_mode_for_role(RoleID,PKMode) ->
    DataIn = #m_role2_pkmodemodify_tos{pk_mode=PKMode},
    Line = common_misc:get_role_line_by_id(RoleID),
    do_pk_mode_modify(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_PKMODEMODIFY, RoleID, DataIn, Line).

modify_pk_mode_without_check(RoleID, PKMode) ->
	DataIn = #m_role2_pkmodemodify_tos{pk_mode=PKMode},
    Line = common_misc:get_role_line_by_id(RoleID),
    do_pk_mode_modify_without_check(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_PKMODEMODIFY, RoleID, DataIn, Line).


%% 进入大明宝藏地图自动设置玩家PK模式
do_pk_mode_modify_for_10500(RoleID,PKMode) ->
    DataIn = #m_role2_pkmodemodify_tos{pk_mode=PKMode},
    Line = common_misc:get_role_line_by_id(RoleID),
    do_pk_mode_modify(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_PKMODEMODIFY, RoleID, DataIn, Line).

%%@doc 检查PK模式
check_pk_mode_modify(PKMode)->
    if
        PKMode > ?MAX_PK_MODE->
            throw({error,?_LANG_PK_MODE_NOT_EXIST});
        true->
            next
    end,
    case mod_nationbattle_fb:is_in_fb_map() andalso PKMode=/= ?PK_FACTION of
        true->
            throw({error,?_LANG_NATIONBATTLE_PK_MODE_LIMIT});
        _ ->
            next
    end,
    case mod_warofking:is_in_fb_map() andalso PKMode=/= ?PK_FAMILY of
        true->
            throw({error,?_LANG_WAROFKING_PK_MODE_LIMIT});
        _ ->
            next
	end,
    case mod_warofmonster:is_in_fb_map() andalso PKMode=/= ?PK_PEACE of
        true->
            throw({error,?_LANG_WAROFMONSTER_PK_MODE_LIMIT});
        _ ->
            next
    end,
    case mod_mine_fb:is_in_fb_map() andalso PKMode=/= ?PK_PEACE of
        true->
            throw({error,?_LANG_MINE_FB_PK_MODE_LIMIT});
        _ ->
            next
    end,
	case mod_bigpve_fb:is_role_in_map() andalso PKMode=/= ?PK_PEACE of
		true->
			throw({error,?_LANG_BIGPVE_PK_MODE_LIMIT});
		_ ->
			next
	end,
	case mod_guard_fb:is_in_fb_map() andalso PKMode=/= ?PK_PEACE of
		true->
			throw({error,?_LANG_BIGPVE_PK_MODE_LIMIT});
		_ ->
			next
	end,
    case mod_spring:is_in_spring_map() andalso PKMode=/= ?PK_PEACE of
        true->
            throw({error,<<"温泉中只能使用和平模式">>});
        _ ->
            next
    end,
	case mod_crown_arena_fb:is_in_pk_map() andalso PKMode=/= ?PK_ALL of
		true->
			throw({error,?_LANG_CROWN_ARENA_PK_MODE_LIMIT});
		_ ->
			next
	end,
	case mod_mirror_fb:is_in_mirror_map() of
	true->
		throw({error,?_LANG_MIRROR_FIGHT_PK_MODE_LIMIT});
	_ ->
		next
	end,
    ok.

%% 修改PK模式
do_pk_mode_modify(Unique, Module, Method, RoleID, DataIn, Line) ->
    #m_role2_pkmodemodify_tos{pk_mode=PKMode} = DataIn,
    case catch check_pk_mode_modify(PKMode) of
        ok->
            case common_transaction:transaction(fun() -> t_do_modify_pk_mode(RoleID, PKMode) end) of
                {atomic, _} ->
                    mof_common:erase_role_fight_attr(RoleID),
                    global:send(mgeel_stat_server,{pk_mode_modify,RoleID,PKMode}),
                    mod_map_pet:hook_role_pk_mode_change(RoleID,PKMode),
                    R = #m_role2_pkmodemodify_toc{succ=true,pk_mode = PKMode};
                {aborted, Error} ->
                    ?ERROR_MSG("do_pk_mode_modify, error: ~w", [Error]),
                    R = #m_role2_pkmodemodify_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
            end;
        {error,Reason}->
            R = #m_role2_pkmodemodify_toc{succ=false, reason=Reason}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_pk_mode_modify_without_check(Unique, Module, Method, RoleID, DataIn, Line) ->
	#m_role2_pkmodemodify_tos{pk_mode=PKMode} = DataIn,
	case common_transaction:transaction(fun() -> t_do_modify_pk_mode(RoleID, PKMode) end) of
	{atomic, _} ->
		global:send(mgeel_stat_server,{pk_mode_modify,RoleID,PKMode}),
		mod_map_pet:hook_role_pk_mode_change(RoleID,PKMode),
        mof_common:erase_role_fight_attr(RoleID),
		R = #m_role2_pkmodemodify_toc{succ=true,pk_mode = PKMode};
	{aborted, Error} ->
		?ERROR_MSG("do_pk_mode_modify, error: ~w", [Error]),
		R = #m_role2_pkmodemodify_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
	end,
	common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

t_do_modify_pk_mode(RoleID, PKMode) ->
    {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
    case RoleBase#p_role_base.pk_mode =:= PKMode of
        true ->
            ok;
        false ->
            NewRoleBase = RoleBase#p_role_base{pk_mode=PKMode},
            mod_map_role:set_role_base(RoleID,NewRoleBase)
    end.

%% 计数器类别定义
-define(COUNTER_ZAZEN_BUY_BUFF,     1).     %% 打坐购买buff的次数

do_zazen_buy_buff(Unique, Module, Method, RoleID, DataIn, Line) ->
    MaxTimes = cfg_zazen:max_buy_buff_times(),
    case mod_counter:get_counter(RoleID, ?COUNTER_ZAZEN_BUY_BUFF) >= MaxTimes of
        true -> common_misc:send_common_error(RoleID, 0, <<"今天购买次数已满，请明天再来">>);
        false ->
            BuffId = DataIn#m_role2_zazen_buy_buff_tos.buff_id,
            case mod_role_buff:has_any_buff(RoleID, cfg_zazen:all_buff()) of
                {true, _} -> common_misc:send_common_error(RoleID, 0, <<"不能同时领取多个的buff效果">>);
                false ->
                    Cost    = cfg_zazen:buff_price(BuffId),
                    LogType = ?CONSUME_TYPE_GOLD_BUY_ZAZEN_BUFF,
                    case common_bag2:use_money(RoleID, gold_unbind, Cost, LogType) of
                        {error, Reason} ->
                            common_misc:send_common_error(RoleID, 0, Reason);
                        _ ->
                            mod_role_buff:add_buff(RoleID, BuffId),
                            Times = mod_counter:add_counter(RoleID, ?COUNTER_ZAZEN_BUY_BUFF),
                            Msg = #m_role2_zazen_buy_buff_toc{buff_id = BuffId},
                            Msg2 = common_misc:format_lang(<<"您今天已购买了~p次打坐多倍经验buff，还可以购买~p次">>, [Times, MaxTimes-Times]),
                            common_misc:unicast(Line, RoleID, Unique, Module, Method, Msg),
                            common_misc:send_common_error(RoleID, 0, Msg2),
                            hook_activity_task:done_task(RoleID, 50028),
                            ok
                    end
            end
    end.
%% @doc 打坐
do_zazen(Unique, Module, Method, RoleID, DataIn, Line) ->
    #m_role2_zazen_tos{status=ToState} = DataIn,
    check_position() orelse
        case common_transaction:transaction(
               fun() ->
                       t_do_zazen(RoleID, ToState)
               end)
        of
            {atomic, {ok, RoleState}} ->
                mod_role_mount:do_mount_down(RoleID),
                mod_map_role:do_update_map_role_info(RoleID, [{#p_map_role.state, RoleState}]),
                case ToState of 
                    true->
                        mod_role_on_zazen:init_zazen_total_exp(RoleID),
                        ReturnSelf = #m_role2_zazen_toc{status=ToState};
                    false->
                        SumExp = mod_role_on_zazen:del_zazen_total_exp(RoleID),
                        ReturnSelf = #m_role2_zazen_toc{status=ToState,sum_exp=SumExp}
                end,
                common_misc:unicast(Line, RoleID, Unique, Module, Method, ReturnSelf),
                ToOther = #m_role2_zazen_toc{roleid=RoleID, return_self=false, status=ToState},
                mgeem_map:send({broadcast_insence, [{role, RoleID}], Module, Method, ToOther});
            {aborted, Reason}  when is_binary(Reason) ->
                do_zazen_error(Unique, Module, Method, RoleID, Reason, Line);
            {aborted, Reason} ->
                ?ERROR_MSG("do_zazen, error: ~w", [Reason]),
                do_zazen_error(Unique, Module, Method, RoleID, ?_LANG_SYSTEM_ERROR, Line)
        end.

t_do_zazen(RoleID, ToState) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{status=RoleState} = RoleBase,
    if
        RoleState =:= ?ROLE_STATE_NORMAL andalso ToState =:= true -> 
            mod_map_role:set_role_base(RoleID, RoleBase#p_role_base{status=?ROLE_STATE_ZAZEN}),
            {ok, ?ROLE_STATE_ZAZEN};
        RoleState =:= ?ROLE_STATE_ZAZEN andalso ToState =:= false ->
            mod_map_role:set_role_base(RoleID, RoleBase#p_role_base{status=?ROLE_STATE_NORMAL}),
            {ok, ?ROLE_STATE_NORMAL};
        true ->
            common_transaction:abort(?_LANG_ROLE2_WRONG_STATUS)
    end.

do_zazen_error(Unique, Module, Method, RoleID, Reason, Line) ->
    DataRecord = #m_role2_zazen_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).


%% 角色设置五行属性消息接口
%% 角色设置五行属性，即获取五行属性消息处理
do_five_ele_attr(Unique, Module, Method, DataRecord, RoleId, Line) ->
    Type = DataRecord#m_role2_five_ele_attr_tos.type,
    if Type =:= 0 ->
            %% 免费获取五行属性
            do_five_ele_attr2(Unique, Module, Method, DataRecord, RoleId, Line);
       Type =:= 1 ->
            %% 有偿获取五行属性
            do_five_ele_attr3(Unique, Module, Method, DataRecord, RoleId, Line);
       true ->
            Reason = ?_LANG_ROLE2_FIVE_ELE_ATTR_TYPE,
            do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line)
    end.
do_five_ele_attr2(Unique, Module, Method, DataRecord, RoleId, Line) ->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleId),
    Level = RoleAttr#p_role_attr.level,
    if Level < ?DEFAULT_ROLE2_FIVE_ELE_ATTR_MIN_LEVEL ->
            Reason = ?_LANG_ROLE2_FIVE_ELE_ATTR_LEVEL,
            do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line);
       true ->
            do_five_ele_attr2_1(Unique, Module, Method, DataRecord, RoleId, Line, RoleAttr)
    end.
do_five_ele_attr2_1(Unique, Module, Method, DataRecord, RoleId, Line, RoleAttr) ->
    if RoleAttr#p_role_attr.five_ele_attr =/= 0 ->
            Reason = ?_LANG_ROLE2_FIVE_ELE_ATTR_FEE,
            do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line);
       true ->
            do_five_ele_attr2_2(Unique, Module, Method, DataRecord, RoleId, Line)
    end.
do_five_ele_attr2_2(Unique, Module, Method, DataRecord, RoleId, Line) ->
    Type = DataRecord#m_role2_five_ele_attr_tos.type,
    FiveEleAttr = random:uniform(5),
    case catch do_transaction_five_ele(RoleId,FiveEleAttr,Type,0) of
        {error,Reason} ->
            do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line);
        {ok,NewAttr} ->
            do_five_ele_attr_succ(Unique, Module, Method, DataRecord, RoleId, Line, NewAttr)
    end.

do_five_ele_attr3(Unique, Module, Method, DataRecord, RoleId, Line) ->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleId),
    Level = RoleAttr#p_role_attr.level,
    if Level < ?DEFAULT_ROLE2_FIVE_ELE_ATTR_MIN_LEVEL ->
            Reason = ?_LANG_ROLE2_FIVE_ELE_ATTR_LEVEL,
            do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line);
       true ->
            do_five_ele_attr4(Unique, Module, Method, DataRecord, RoleId, Line, RoleAttr)
    end.
do_five_ele_attr4(Unique, Module, Method, DataRecord, RoleId, Line, RoleAttr) ->
    FiveEleAttr = RoleAttr#p_role_attr.five_ele_attr,
    if FiveEleAttr =:= 0 ->
            Reason = ?_LANG_ROLE2_FIVE_ELE_ATTR_RE_GET,
            do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line);
       true ->
            do_five_ele_attr5(Unique, Module, Method, DataRecord, RoleId, Line)
    end.

do_five_ele_attr5(Unique, Module, Method, DataRecord, RoleId, Line) ->
    Type = DataRecord#m_role2_five_ele_attr_tos.type,
    FiveEleAttr = random:uniform(5),
    case catch do_transaction_five_ele(RoleId,FiveEleAttr,Type,1000) of
        {error,Reason} ->
            do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line);
        {ok,NewAttr} ->
            do_five_ele_attr_succ(Unique, Module, Method, DataRecord, RoleId, Line, NewAttr)
    end.

do_five_ele_attr_succ(Unique, Module, Method, _DataRecord, RoleId, Line, RoleAttr) ->
    Level = RoleAttr#p_role_attr.level,
    FiveEleAttr = RoleAttr#p_role_attr.five_ele_attr,
    FiveEleAttrLevel = if Level >= 0 andalso Level =< 19 ->
                               0;
                          Level >= 20 andalso Level =< 49 ->
                               1;
                          Level >= 50 andalso Level =< 99 ->
                               2;
                          Level >= 100 andalso Level =< 160 ->
                               3;
                          true ->
                               0
                       end,
    SendSelf = #m_role2_five_ele_attr_toc{succ = true, five_ele_attr_level=FiveEleAttrLevel,
                                          five_ele_attr=FiveEleAttr},
    common_misc:unicast(Line, RoleId, Unique, Module, Method, SendSelf),
    AttrChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value = RoleAttr#p_role_attr.silver},
                      #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value = RoleAttr#p_role_attr.silver_bind}],
    common_misc:role_attr_change_notify({line, Line, RoleId},RoleId,AttrChangeList).

do_five_ele_attr_error(Unique, Module, Method, Reason, RoleId, Line) ->
    SendSelf = #m_role2_five_ele_attr_toc{succ = false,reason = Reason,
                                          five_ele_attr_level=0,five_ele_attr=0},
    common_misc:unicast(Line, RoleId, Unique, Module, Method, SendSelf).

do_transaction_five_ele(RoleId,FiveEleAttr,Type,Fee) ->
    case common_transaction:transaction(
           fun() ->
                   do_transaction_five_ele2(RoleId,FiveEleAttr,Type,Fee)
           end) of
        {atomic, {ok,RAttr}} ->     
            {ok, RAttr};
        {aborted, Error} ->
            ?ERROR_MSG("~ts,RoleId=~w,Error=~w",["事务修改角色五行属性失败",RoleId,Error]),
            case erlang:is_binary(Error) of 
                true ->
                    erlang:throw({error,Error});
                _ ->
                    erlang:throw({error,?_LANG_ROLE2_FIVE_ELE_ATTR_ERROR})
            end
    end.
do_transaction_five_ele2(RoleId,FiveEleAttr,Type,Fee) ->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleId),  
    RoleAttr2= 
        if Type =:= 1 ->
                SilverBind = RoleAttr#p_role_attr.silver_bind,
                Silver = RoleAttr#p_role_attr.silver,
                if (SilverBind + Silver) < Fee ->
                        db:abort(?_LANG_ROLE2_FIVE_ELE_ATTR_NOT_FEE);
                   true ->
                        next
                end,
                if SilverBind < Fee ->
                        NewSilver = Silver - (Fee - SilverBind),
                        if NewSilver < 0 ->
                                ?ERROR_MSG("~ts",["角色不够钱币重洗五行属性"]),
                                db:abort(?_LANG_ROLE2_FIVE_ELE_ATTR_NOT_FEE);
                           true ->
                                %%consume log
                                common_consume_logger:use_silver({RoleId,SilverBind,(Fee - SilverBind),
                                                                  ?CONSUME_TYPE_SILVER_FIVE_ELE_REFRESH,
                                                                  ""}),
                                RoleAttr#p_role_attr{silver_bind=0,silver=NewSilver}
                        end;
                   true ->
                        NewSilverBind = SilverBind - Fee,
                        common_consume_logger:use_silver({RoleId,Fee,0,
                                                          ?CONSUME_TYPE_SILVER_FIVE_ELE_REFRESH,
                                                          ""}),
                        RoleAttr#p_role_attr{silver_bind=NewSilverBind}
                end;
           true ->
                RoleAttr
        end,
    RoleAttr3 = RoleAttr2#p_role_attr{five_ele_attr = FiveEleAttr},
    mod_map_role:set_role_attr(RoleId,RoleAttr3),
    {ok,RoleAttr3}.

do_levelup(Unique, Module, Method, _DataIn, RoleID, Line) ->
    case common_transaction:transaction(
           fun() ->
                   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   {ok,RoleBase} = mod_map_role:get_role_base(RoleID),

                   #p_role_attr{exp=Exp, level=Level, next_level_exp=NextLevelExp} = RoleAttr, 
                   %%暂时只开放到100级
                   [MaxLevel] = common_config_dyn:find(etc, max_level),
                   case Level >= MaxLevel of
                       true ->
                           common_transaction:abort(level_full);
                       false ->
                           ok
                   end,
                           
                   case Exp >= NextLevelExp of
                       true ->
                           mod_map_role:t_level_up(RoleAttr, RoleBase, Level, Level+1, Exp-NextLevelExp);
                       false ->
                           common_transaction:abort(exp_not_enough)
                   end
           end) of
        {atomic, {level_up, Level, RoleAttr2, RoleBase2}} ->
            mod_map_role:do_after_level_up(Level, RoleAttr2, RoleBase2, 0, Unique, true);
        {atomic, {error, skill_not_satify}} ->
            DataRecord = #m_role2_levelup_toc{err_code=2,reason = <<"怒气技能形态不满足">>},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord);
        {aborted, Error} when erlang:is_binary(Error) orelse erlang:is_list(Error)->
			DataRecord = #m_role2_levelup_toc{err_code=1,reason=Error},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord);
		{aborted, Error} ->
			?ERROR_MSG("do_levelup error:~s",[Error])
    end. 	

%%是否显示衣服
do_show_cloth(Unique, Module, Method, DataIn, RoleID, Line) ->
    ShowCloth = DataIn#m_role2_show_cloth_tos.show_cloth,

    case common_transaction:transaction(
           fun() ->
                   t_do_show_cloth(RoleID, ShowCloth)
           end)
    of
        {atomic, _} ->
            DataRecord = #m_role2_show_cloth_toc{show_cloth=ShowCloth},

            %%更新角色地图信息
            mod_map_role:update_map_role_info(RoleID, [{#p_map_role.show_cloth, ShowCloth}]);
        {aborted, _R} ->
            DataRecord = #m_role2_show_cloth_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
    end,

    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).

t_do_show_cloth(RoleID, ShowCloth) ->
    {ok,RoleAttr}= mod_map_role:get_role_attr(RoleID),
    mod_map_role:set_role_attr(RoleID,RoleAttr#p_role_attr{show_cloth=ShowCloth}).

do_pkpoint_left(Unique, Module, Method, RoleID, Line) ->
    case mod_map_role:get_role_state(RoleID) of
        {error, _} ->
            TimeLeft = 0;
        {ok, #r_role_state2{pkpoint_timer_ref=TimerRef}} ->
            case TimerRef of
                undefined ->
                    TimeLeft = 0;
                _ ->
                    case erlang:read_timer(TimerRef) of
                        false ->
                            TimeLeft = 0;
                        T ->
                            TimeLeft = T
                    end
            end
    end,

    Record = #m_role2_pkpoint_left_toc{time_left=common_tool:ceil(TimeLeft/(1000*60))},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Record).

do_get_roleattr(Unique, Module, Method, RoleID, DataRecord, PID, Line) ->
    #m_role2_getroleattr_tos{
        role_id     = TargetRoleID,
        is_check    = IsCheck,
        can_worship = CanWorship
    } = DataRecord,
    try
        %% 这里要用脏读，否则查看不了下线玩家的信息
        case mod_map_role:get_role_base(TargetRoleID) of
            {ok, RoleBase} ->
                ok;
            _ ->
                {ok, RoleBase} = common_misc:get_dirty_role_base(TargetRoleID)
        end,
        case mod_map_role:get_role_attr(TargetRoleID) of
            {ok, RoleAttr} ->
                ok;
            _ ->
                {ok, RoleAttr} = common_misc:get_dirty_role_attr(TargetRoleID)
        end,
        {ok, RoleExt} = common_misc:get_dirty_role_ext(abs(TargetRoleID)),
        case mod_map_role:get_role_fight(TargetRoleID) of
            {ok, RoleFight} ->
                ok;
            _ ->
                {ok, RoleFight} = common_misc:get_dirty_role_fight(TargetRoleID)
        end,
        [#r_sys_config{sys_config=SysConfig}] = db:dirty_read(?DB_SYSTEM_CONFIG, abs(TargetRoleID)),
        ByFind = SysConfig#p_sys_config.by_find,
        VipLevel = mod_vip:get_dirty_role_vip_level(TargetRoleID),
        case mod_map_pet:get_summoned_pet_info(TargetRoleID) of
            undefined ->
                PetID = 0;
            {PetID, _} ->
                ok
        end,
        case db:dirty_read(?DB_ROLE_LEVEL_RANK, abs(TargetRoleID)) of
            [] ->
                LevelRank = 0;
            [#p_role_level_rank{ranking=LevelRank}] ->
                ok
        end,
		RoleInfo1 = p_other_role_info(RoleBase, RoleAttr),
		RoleInfo2 = RoleInfo1#p_other_role_info{level_rank=LevelRank,
												vip_level=VipLevel,
												birthday=RoleExt#p_role_ext.birthday,
												province=RoleExt#p_role_ext.province,
												city=RoleExt#p_role_ext.city,
												pet_id=PetID,
												cur_energy=RoleFight#p_role_fight.energy,
												max_energy=RoleFight#p_role_fight.energy_remain},
        case ByFind andalso IsCheck of 
            true ->
                {ok, SRoleBase} = mod_map_role:get_role_base(RoleID),
                #p_role_base{sex=SSex, role_name=SRoleName} = SRoleBase,
                DSex = RoleBase#p_role_base.sex,
                Notice = get_target_notice(SSex, SRoleName, DSex),
                common_broadcast:bc_send_msg_role(TargetRoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(Notice));
            _ ->
                ok
        end,
        case CanWorship of
            true ->
				{ok, _, CanWorship2, RemTimes} = mod_role_worship:get_worship_info(RoleID, TargetRoleID),
				{ok, WorshipCount, DisdainCount} = mod_role_worship:count(TargetRoleID),
  				Record = #m_role2_getroleattr_toc{
                    role_info    = RoleInfo2,
                    worship_info = #p_worship_info{
						can_worship   = CanWorship2,
						rem_times     = RemTimes,
                        worship_count = WorshipCount, 
                        disdain_count = DisdainCount
                    }
                },
				common_misc:unicast2(PID, Unique, Module, Method, Record);
            false ->
                Record = #m_role2_getroleattr_toc{role_info=RoleInfo2},
				common_misc:unicast(Line, RoleID, Unique, Module, Method, Record)
        end
    catch
        _ : R ->
            ?ERROR_MSG("do_get_roleattr, r: ~w", [R]),
            Record2 = #m_role2_getroleattr_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
			common_misc:unicast(Line, RoleID, Unique, Module, Method, Record2)
    end.

p_other_role_info(RoleBase, RoleAttr) ->
    RateAttrs = case RoleBase#p_role_base.rate_attrs of
        undefined -> #p_rate_attrs{};
        Others    -> Others
    end,
	#p_other_role_info{
        role_id          = RoleBase#p_role_base.role_id,
        role_name        = RoleBase#p_role_base.role_name,
        faction_id       = RoleBase#p_role_base.faction_id,
        family_name      = RoleBase#p_role_base.family_name,
        five_ele_attr    = RoleAttr#p_role_attr.five_ele_attr,
        office_name      = RoleAttr#p_role_attr.office_name,
        sex              = RoleBase#p_role_base.sex,
        charm            = RoleAttr#p_role_attr.charm,
        category         = RoleAttr#p_role_attr.category,
        level            = RoleAttr#p_role_attr.level,
        equips           = RoleAttr#p_role_attr.equips,
        gongxun          = RoleAttr#p_role_attr.gongxun,
        pk_point         = RoleBase#p_role_base.pk_points,
        str              = RoleBase#p_role_base.str,
        int2             = RoleBase#p_role_base.int2,
        con              = RoleBase#p_role_base.con,
        dex              = RoleBase#p_role_base.dex,
        men              = RoleBase#p_role_base.men,
        max_phy_attack   = trunc(RoleBase#p_role_base.max_phy_attack*(1+RateAttrs#p_rate_attrs.physic_att_rate/10000)),
        min_phy_attack   = trunc(RoleBase#p_role_base.min_phy_attack*(1+RateAttrs#p_rate_attrs.physic_att_rate/10000)),
        max_magic_attack = trunc(RoleBase#p_role_base.max_magic_attack*(1+RateAttrs#p_rate_attrs.magic_att_rate/10000)),
        min_magic_attack = trunc(RoleBase#p_role_base.min_magic_attack*(1+RateAttrs#p_rate_attrs.magic_att_rate/10000)),
        double_attack    = RoleBase#p_role_base.double_attack,
        phy_defence      = trunc(RoleBase#p_role_base.phy_defence*(1+RateAttrs#p_rate_attrs.physic_def_rate/10000)),
        magic_defence    = trunc(RoleBase#p_role_base.magic_defence*(1+RateAttrs#p_rate_attrs.magic_def_rate/10000)),
        luck             = RoleBase#p_role_base.luck,
        miss             = RoleBase#p_role_base.miss,
        no_defence       = RoleBase#p_role_base.no_defence,
        hit_rate         = RoleBase#p_role_base.hit_rate,
        sum_prestige     = RoleAttr#p_role_attr.sum_prestige,
        cur_prestige     = RoleAttr#p_role_attr.cur_prestige,
        cur_title        = RoleBase#p_role_base.cur_title,
        pk_title         = RoleBase#p_role_base.pk_title,
        max_hp           = trunc(RoleBase#p_role_base.max_hp*(1+RateAttrs#p_rate_attrs.blood_rate/10000)),
        max_mp           = trunc(RoleBase#p_role_base.max_mp*(1+RateAttrs#p_rate_attrs.magic_rate/10000)),
        skin             = RoleAttr#p_role_attr.skin,
        medals           = RoleAttr#p_role_attr.medals,
        fighting_power   = common_role:get_fighting_power(RoleBase, RoleAttr),
        jingjie          = RoleAttr#p_role_attr.jingjie,
        poisoning_resist = RoleBase#p_role_base.poisoning_resist,
        dizzy_resist     = RoleBase#p_role_base.dizzy_resist,
        phy_hurt_rate    = RoleBase#p_role_base.phy_hurt_rate,
        magic_hurt_rate  = RoleBase#p_role_base.magic_hurt_rate,
        hurt             = RoleBase#p_role_base.hurt,
        phy_anti         = RoleBase#p_role_base.phy_anti,
        magic_anti       = RoleBase#p_role_base.magic_anti,
        block            = RoleBase#p_role_base.block,
        wreck            = RoleBase#p_role_base.wreck,
        tough            = RoleBase#p_role_base.tough,
        vigour           = RoleBase#p_role_base.vigour,
        week             = RoleBase#p_role_base.week,
        molder           = RoleBase#p_role_base.molder,
        hunger           = RoleBase#p_role_base.hunger,
        bless            = RoleBase#p_role_base.bless,
        crit             = RoleBase#p_role_base.crit,
        bloodline        = RoleBase#p_role_base.bloodline,
        juewei           = RoleAttr#p_role_attr.juewei,
        yueli            = RoleAttr#p_role_attr.yueli
	}.

do_unbund_change(_Unique, _Module, _Method, RoleID, DataIn) ->
    #m_role2_unbund_change_tos{unbund=Unbund} = DataIn,
    case common_transaction:transaction(
           fun() ->
                   {ok,Attr}= mod_map_role:get_role_attr(RoleID),
                   mod_map_role:set_role_attr(RoleID,Attr#p_role_attr{unbund=Unbund})
           end)
    of
        {aborted, Reason} ->
            ?ERROR_MSG("~ts:~w~n",["更新角色是否不使用绑定货币失败",Reason]);
        {atomic, _} ->
            ok
    end.

%% @doc 纪录角色某些事件
do_event(Unique, Module, Method, DataIn, RoleID, PID) ->
    #m_role2_event_tos{event_id=EventID} = DataIn,

    case db:transaction(
           fun() ->
                   [RoleExt] = db:read(?DB_ROLE_EXT, RoleID, write),

                   RoleExt2 = 
                       case EventID of
                           ?EVENT_LEVEL_XSC_ID ->
                               RoleExt#p_role_ext{ever_leave_xsc=true};
                           _ ->
                               db:abort(?_LANG_ROLE2_EVENT_ID_NOT_EXIST)
                       end,
                   db:write(?DB_ROLE_EXT, RoleExt2, write)
           end)
    of
        {atomic, _} ->
            DataRecord = #m_role2_event_toc{event_id=EventID};
        {aborted, Reason} when is_binary(Reason) ->
            DataRecord = #m_role2_event_toc{event_id=EventID, reason=Reason};
        {aborted, Reason} ->
            ?ERROR_MSG("do_event, error: ~w", [Reason]),
            DataRecord = #m_role2_event_toc{event_id=EventID, reason=?_LANG_ROLE2_EVENT_SYSTEM_ERROR}
    end,
    
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

get_target_notice(SSex, SRoleName, DSex) ->
    if
        SSex =:= ?SEXMAN andalso DSex =:= ?SEXMAN ->
            io_lib:format(?MANWATCHMAN, [SRoleName]);
        SSex =:= ?SEXMAN andalso DSex =:= ?SEXWOMAN ->
            io_lib:format(?MANWATCHWOMAN, [SRoleName]);
        DSex =:= ?SEXMAN ->
            io_lib:format(?WOMANWATCHMAN, [SRoleName]);
        true ->
            io_lib:format(?WOMANWATCHWOMAN, [SRoleName])
    end.

%% @doc 头像ID是否合法
check_head_id_illegal(_HeadID) ->
    ok.

%% @doc 世界广播换头像
broadcast_head_change(RoleID) ->
    {ok, #p_role_base{sex=Sex, role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
    case Sex of
        ?SEXMAN ->
            Msg = io_lib:format(?_LANG_ROLE2_HEAD_BROADCAST_MSG_MALE, [RoleName]);
        _ ->
            Msg = io_lib:format(?_LANG_ROLE2_HEAD_BROADCAST_MSG_FEMALE, [RoleName])
    end,
    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER, ?BC_MSG_SUB_TYPE, lists:flatten(Msg)).

%% @doc 道具使用日志
item_used_log(GoodsList) ->
    lists:foreach(
      fun(Goods) ->
              #p_goods{roleid=RoleID}=Goods,
              common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU)
      end,GoodsList).

%% GM命令设置玩家五行属性
do_admin_set_role_five_ele_attr(RoleId,FiveEleAttr) ->
    case lists:member(FiveEleAttr,[1,2,3,4,5]) of
        true ->
            case mod_map_role:get_role_attr(RoleId) of
                {ok,RoleAttr} ->
                    common_transaction:transaction(
                      fun() ->
                              mod_map_role:set_role_attr(RoleId,RoleAttr#p_role_attr{five_ele_attr=FiveEleAttr})
                      end);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
%% 当前国家在线玩家榜数据进程字典操作
init_faction_online_role_rank(MapId,FactionId) ->
    erlang:put({faction_online_role_rank,MapId,FactionId},[]).

get_faction_online_role_rank(MapId,FactionId) ->
    erlang:get({faction_online_role_rank,MapId,FactionId}).
    
set_faction_online_role_rank(MapId,FactionId,RoleRankList) ->
    erlang:put({faction_online_role_rank,MapId,FactionId},RoleRankList).

do_admin_join_faction_online_rank({RoleId,RoleName,FactionId,RoleLevel,DoMapId}) ->
    NewRoleRank = #p_faction_online_rank{
      faction_id = FactionId,
      role_id = RoleId,
      role_name = RoleName,
      role_level = RoleLevel
     },
    OnlineRankList = get_faction_online_role_rank(DoMapId,FactionId),
    case OnlineRankList =:= [] of
        true ->
            set_faction_online_role_rank(DoMapId,FactionId,[NewRoleRank]);
        _ ->
            OnlineRankLen = erlang:length(OnlineRankList),
            MinRoleRank = lists:nth(OnlineRankLen,OnlineRankList),
            [MaxRankNumber] = common_config_dyn:find(etc,max_faction_online_role_rank_number),
            case MinRoleRank#p_faction_online_rank.role_level >= RoleLevel of
                true ->
                    case OnlineRankLen >= MaxRankNumber of
                        true ->
                            ignore;
                        _ ->
                            set_faction_online_role_rank(DoMapId,FactionId,lists:append([OnlineRankList,[NewRoleRank]]))
                    end;
                _ ->							
                    OnlineRankList2 = 
                        lists:sort(
                          fun(RoleRankA,RoleRankB) ->
                                  RoleRankA#p_faction_online_rank.role_level > RoleRankB#p_faction_online_rank.role_level
                          end,[NewRoleRank|lists:keydelete(RoleId, #p_faction_online_rank.role_id, OnlineRankList)]),
                    set_faction_online_role_rank(DoMapId,FactionId,lists:sublist(OnlineRankList2,1,MaxRankNumber))
            end
    end,
    ok.

do_admin_quit_faction_online_rank({RoleId,FactionId,DoMapId}) ->
    OnlineRankList = lists:keydelete(RoleId,#p_faction_online_rank.role_id,get_faction_online_role_rank(DoMapId,FactionId)),
    set_faction_online_role_rank(DoMapId,FactionId,OnlineRankList),
    ok.
do_admin_uplevel_faction_online_rank({RoleId,RoleName,FactionId,RoleLevel,DoMapId}) ->
    OnlineRankList = lists:keydelete(RoleId,#p_faction_online_rank.role_id,get_faction_online_role_rank(DoMapId,FactionId)),
    set_faction_online_role_rank(DoMapId,FactionId,OnlineRankList),
    do_admin_join_faction_online_rank({RoleId,RoleName,FactionId,RoleLevel,DoMapId}),
    ok.

%% 查询当前国家在线玩家榜数据
do_query_faction_online_rank(Unique, Module, Method, DataRecord, RoleId, PId) ->
    [DoMapId] = common_config_dyn:find(etc,do_faction_online_role_rank_map_id),
    case mod_map_actor:get_actor_mapinfo(RoleId,role) of
        undefined ->
            Reason = ?_LANG_ROLE2_QUERY_FACTION_ONLINE_RANK_ERROR,
            do_query_faction_online_rank_error(Unique,Module,Method,DataRecord,RoleId,PId,Reason,0);
        #p_map_role{faction_id = FactionId} ->
            global:send(common_map:get_common_map_name(DoMapId),
                        {mod_role2,{admin_query_faction_online_rank,{Unique,Module,Method,DataRecord,RoleId,DoMapId,FactionId}}})
    end.
do_admin_query_faction_online_rank({Unique,Module,Method,DataRecord,RoleId,DoMapId,FactionId}) ->
    OnlineRankList = get_faction_online_role_rank(DoMapId,FactionId),
    SendSelf=#m_role2_query_faction_online_rank_toc{
      op_type = DataRecord#m_role2_query_faction_online_rank_tos.op_type,
      faction_id = DataRecord#m_role2_query_faction_online_rank_tos.faction_id,
      succ = true,
      online_rank = OnlineRankList},
    common_misc:unicast({role,RoleId}, Unique, Module, Method, SendSelf),
    ok.

do_query_faction_online_rank_error(Unique,Module,Method,DataRecord,_RoleId,PId,Reason,ReasonCode) ->
    SendSelf=#m_role2_query_faction_online_rank_toc{
      op_type = DataRecord#m_role2_query_faction_online_rank_tos.op_type,
      faction_id = DataRecord#m_role2_query_faction_online_rank_tos.faction_id,
      succ = false,
      reason = Reason,
      reason_code = ReasonCode,
      online_rank = []},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_choose_category(Unique,Module,Method,Category,RoleID,PID,_MapState) ->
	case common_transaction:t(fun() -> t_choose_category(RoleID,Category) end) of
		{atomic, {ok,Head,_FactionID}} ->
			Change = [{#p_map_role.category,Category}],
			?UNICAST_TOC(#m_role2_choose_category_toc{category=Category,head=Head}),
			mod_map_role:update_map_role_info(RoleID, Change);
		{aborted, {error,ErrCode,Reason}} ->
			?UNICAST_TOC(#m_role2_choose_category_toc{err_code=ErrCode,reason=Reason});
		{aborted, Reason} ->
			?ERROR_MSG("do_choose_category error,RoleID=~w,Category=~w,Reason=~w",[RoleID,Category,Reason])
	end.
t_choose_category(RoleID,ChooseCategory) ->
	{ok,#p_role_attr{category=Category}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
	[CategoryList] = common_config_dyn:find(etc,category_list),
	case lists:member(ChooseCategory, CategoryList) =:= true andalso Category =:= 0 of
		true -> next;
		false -> ?THROW_ERR_REASON(<<"您已经有职业了">>)
	end,
	{ok,#p_role_base{sex=Sex,faction_id=FactionID}=RoleBase} = mod_map_role:get_role_base(RoleID),
	NewRoleAttr = RoleAttr#p_role_attr{category=ChooseCategory},
	NewHead = ChooseCategory*10+Sex,
	NewRoleBase = RoleBase#p_role_base{head=NewHead},
	mod_map_role:set_role_base(RoleID, NewRoleBase),
	mod_map_role:set_role_attr(RoleID, NewRoleAttr),
	{ok,NewHead,FactionID}.

%% 玩家死亡掉落道具 
hook_role_dead(RoleID) ->
    MapID = mgeem_map:get_mapid(),
    [DropItemList] = common_config_dyn:find(item_special,role_dead_drop_item),
    [MapItemList] = common_config_dyn:find(item_special, map_item_reflect),
    %%获得所有特殊地图才会掉落的所有物品id集合
    G = fun({_MapList, ItemList}, AccIn) ->
            lists:append(ItemList -- AccIn, AccIn)
        end,
    SpecialDropItemList = lists:foldl(G, [], MapItemList),
    %%获得所有会掉落的物品id的集合
    H = fun({_Rate, ItemTypeID, _DropNum}, AccIn) ->
            [ItemTypeID | AccIn]
        end,
    DropItemIDList = lists:foldl(H, [], DropItemList),
    %%得到所有地图都会掉落的物品id列表
    AllMapDropItemList = DropItemIDList -- SpecialDropItemList,
    %%获得当前地图会才掉落的所有物品id集合
    F = fun({MapList, ItemList}, AccIn) ->
            case lists:member(MapID, MapList) of
                true ->
                    lists:append(ItemList, AccIn);
                false ->
                    []
            end
        end,
    MapDropItemList = lists:foldl(F, [], MapItemList),
    %%当前地图会掉落的物品id列表为：所有地图都会掉落的物品id集合+当前地图才会掉落的物品id集合
    DropItemList1 = lists:append(AllMapDropItemList, MapDropItemList),
    %%根据当前地图会掉落的物品id，找到掉落概率等信息
    K = fun({_Rate, ItemTypeID, _DropNum}) ->
            lists:member(ItemTypeID, DropItemList1)
        end,
    DropItemListInfo = lists:filter(K, DropItemList),
    lists:foreach(fun({Rate,ItemTypeID,DropNum}) ->
                          case common_tool:random(1,10000) =< Rate of
                              true ->
                                  role_dead_drop_item(RoleID,ItemTypeID,DropNum);
                              false ->
                                  ignore
                          end
                  end, DropItemListInfo).

%%掉落物品
role_dead_drop_item(RoleID,ItemTypeID,Num) when Num >0 ->
    %%找出符合丢弃条件的装备
    {ok,#p_role_attr{equips=Equips}} = mod_map_role:get_role_attr(RoleID),
    F = fun(#p_goods{typeid = TypeID}) ->
            TypeID =:= ItemTypeID
        end,
    DropEquips = lists:filter(F, Equips),
    %%先把装备卸下来，放到背包里
    case DropEquips =:= [] of
        true ->
            ignore;
        false ->
            G = fun
                (#p_goods{bagid = BagID, bagposition = Pos, id = EquipID}) ->
                    Tos = #m_equip_unload_tos{
                        equipid  = EquipID, 
                        bagid    = BagID, 
                        position = Pos
                    },
                    mod_role_equip:handle({?DEFAULT_UNIQUE, ?EQUIP, ?EQUIP_UNLOAD, 
                        Tos, RoleID, common_misc:get_role_pid(RoleID), 0})
            end,
            lists:foreach(G, DropEquips)
    end,
    case mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ItemTypeID) of  
        {ok,ItemNum} when ItemNum > 0 ->
            DropNum = erlang:min(ItemNum,Num),
            TransFun = fun()-> 
                               mod_bag:decrease_goods_by_typeid(RoleID,ItemTypeID,DropNum)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic, {ok,UpdateList,DeleteList}} ->
                    if
                        UpdateList =:= [] ->
                            [Goods | _] = DeleteList;
                        DeleteList =:= [] ->
                            [Goods | _] = UpdateList;
                        true ->
                            Goods = []
                    end,
                    DropThing = #p_map_dropthing{num=1,roles=[],
                                                 colour=1,goodstype=Goods#p_goods.type,goodstypeid=ItemTypeID,
                                                 drop_property=#p_drop_property{colour=1,quality=1}},
                    DropThingList = lists:duplicate(DropNum, DropThing),
                    mgeem_map:absend({mod_map_drop, {dropthing, RoleID, DropThingList}}),
                    common_item_logger:log(RoleID,ItemTypeID,ItemNum,undefined,?LOG_ITEM_TYPE_DIAO_LUO_SHI_QU),
                    common_misc:del_goods_notify({role,RoleID},DeleteList),
                    common_misc:update_goods_notify({role,RoleID},UpdateList);
                Reason ->
                    ?ERROR_MSG("hook_role_dead ERROR:~w",[Reason])
            end;
        _ ->
            ignore
    end.
	
check_position() ->
    MapID = mgeem_map:get_mapid(),
    MapID =:= 10512 orelse MapID =:= 10513. %% 屏蔽在温泉更炸宝地图打坐
