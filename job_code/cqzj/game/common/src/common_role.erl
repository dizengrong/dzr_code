%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created : 21 Dec 2010 by  <>
%%%-------------------------------------------------------------------
-module(common_role).

-include("common.hrl").
-include("common_server.hrl").

%% API
-export([
         on_transaction_begin/0,
         on_transaction_rollback/0,
         on_transaction_commit/0,
         is_in_role_transaction/0,
         update_role_id_list_in_transaction/3,
         get_state_string/1
        ]).

-export([
         is_use_store_cache/0,
         rename/2,
         t_rename/2,
         do_update_family_member_name/3,
         get_attr_change_list/1
        ]).

-export([
         get_grow_safe_val/2,
		 get_grow_level_max_limit/1,
		 get_grow_level_limit/2,
		 get_fighting_power/2,
		 get_equip_fighting_power/2,
		 get_fighting_power_rank/1
        ]).




%%%===================================================================
%%% API
%%%===================================================================

%%@doc 是否使用存储缓存
is_use_store_cache()->
    false.

get_attr_change_list(KeyValueList) ->
    [begin
         #p_role_attr_change{change_type=get_attr_change_type(Key), new_value=Value}
     end || {Key, Value} <- KeyValueList].

get_attr_change_type(hp) ->
    ?ROLE_HP_CHANGE;
get_attr_change_type(mp) ->
    ?ROLE_MP_CHANGE;
get_attr_change_type(max_mp) ->
    ?ROLE_MAX_HP_CHANGE;
get_attr_change_type(remain_skill_points) ->
    ?ROLE_SKILL_POINT_CHANGE;
get_attr_change_type(remain_attr_points) ->
    ?ROLE_ATTR_POINT_CHANGE;
get_attr_change_type(exp) ->
    ?ROLE_EXP_CHANGE;
get_attr_change_type(silver) ->
    ?ROLE_SILVER_CHANGE;
get_attr_change_type(silver_bind) ->
    ?ROLE_SILVER_BIND_CHANGE;
get_attr_change_type(gold) ->
    ?ROLE_GOLD_CHANGE;
get_attr_change_type(gold_bind) ->
    ?ROLE_GOLD_BIND_CHANGE;
get_attr_change_type(energy) ->
    ?ROLE_ENERGY_CHANGE;
get_attr_change_type(gongxun) ->
    ?ROLE_GONGXUN_CHANGE;
get_attr_change_type(family_contribute) ->
    ?ROLE_FAMILY_CONTRIBUTE_CHANGE;
get_attr_change_type(family_id) ->
    ?ROLE_FAMILYID_CHANGE;
get_attr_change_type(charm) ->
    ?ROLE_CHARM_CHANGE;
get_attr_change_type(active_points) ->
    ?ROLE_ACTIVE_POINTS_CHANGE;
get_attr_change_type(energy_remain) ->
    ?ROLE_CUR_PRESTIGE_CHANGE;
get_attr_change_type(is_payed) ->
    ?ROLE_PAYED_CHANGE;
get_attr_change_type(jingjie) ->
    ?ROLE_JINGJIE_CHANGE;
get_attr_change_type(cur_prestige) ->
    ?ROLE_CUR_PRESTIGE_CHANGE;
get_attr_change_type(yueli) ->
    ?ROLE_YUELI_ATTR_CHANGE;
get_attr_change_type(recruitment_type_id) ->
    ?ROLE_RECRUITMENT_TYPE;
get_attr_change_type(juewei) ->
    ?ROLE_JUEWEI_ATTR_CHANGE;
get_attr_change_type(jungong) ->
    ?ROLE_JUNGONG_CHANGE;
get_attr_change_type(_) ->
    0.
    

on_transaction_begin() ->
    erlang:put(?role_id_list_in_transaction, []),
    case erlang:get(?mod_map_role_transaction_flag) of
        undefined ->
            erlang:put(?mod_map_role_transaction_flag, true),
            ok;
        _ ->
            %% 禁止嵌套事务
            erlang:throw({nesting_transaction, mod_map_role})
    end,
    ok.

on_transaction_rollback() ->
    RoleIdList = erlang:get(?role_id_list_in_transaction),
    case RoleIdList of
        undefined->
            ignore;
        _ ->
            lists:foreach(
              fun({RoleId, Key, KeyBk}) ->
                      DataBk = erlang:erase({KeyBk, RoleId}),
                      mod_role_tab:rollback({Key, RoleId}, DataBk) 
                      orelse erlang:put({Key, RoleId}, DataBk)
              end, RoleIdList)
    end,
    erlang:erase(?mod_map_role_transaction_flag),
    erlang:erase(?role_id_list_in_transaction).

on_transaction_commit() ->
    lists:foreach(
      fun({RoleId, _Key, KeyBk}) ->
              erlang:erase({KeyBk, RoleId})
      end, erlang:get(?role_id_list_in_transaction)),

    erlang:erase(?mod_map_role_transaction_flag),
    erlang:erase(?role_id_list_in_transaction).

is_in_role_transaction() ->
    case erlang:get(?mod_map_role_transaction_flag) of
        undefined ->
            false;
        _ ->
            true
    end.

update_role_id_list_in_transaction(RoleId, Key, KeyBk) ->
    case erlang:get(?role_id_list_in_transaction) of
        undefined ->
            erlang:throw({error, not_in_transaction});
        BkList ->
            case lists:member({RoleId, Key, KeyBk}, BkList) of
                true ->
                    ignore;
                _ ->
                    erlang:put(?role_id_list_in_transaction, [{RoleId, Key, KeyBk}|BkList]),
                    OldValue = case mod_role_tab:backup({Key, RoleId}) of
                        undefined -> erlang:get({Key, RoleId});
                        Value -> Value
                    end,
                    OldValue =/= undefined andalso erlang:put({KeyBk, RoleId}, OldValue)
            end
    end.

get_state_string(Status) ->
    case Status of
        ?ROLE_STATE_ZAZEN ->
            ?_LANG_ROLE_STATE_ZAZEN_STRING;
        ?ROLE_STATE_DEAD ->
            ?_LANG_ROLE_STATE_DEAD_STRING;
        ?ROLE_STATE_STALL_SELF ->
            ?_LANG_ROLE_STATE_STALL_SELF_STRING;
        ?ROLE_STATE_STALL_AUTO ->
            ?_LANG_ROLE_STATE_STALL_AUTO_STRING;
        ?ROLE_STATE_YBC_FAMILY ->
            ?_LANG_ROLE_STATE_YBC_FAMILY_STRING;
        ?ROLE_STATE_NORMAL ->
            ?_LANG_ROLE_STATE_NORMAL_STRING;
        ?ROLE_STATE_FIGHT ->
            ?_LANG_ROLE_STATE_FIGHT_STRING;
        ?ROLE_STATE_EXCHANGE ->
            ?_LANG_ROLE_STATE_EXCHANGE_STRING;
        ?ROLE_STATE_COLLECT ->
            ?_LANG_ROLE_STATE_COLLECT_STRING;
        _ ->
            <<>>
    end.

%%@doc 根据级别获取培养配置的安全值
%%@return Val
get_grow_safe_val(_,undefined)->
    0;
get_grow_safe_val(_,0)->
    0;
get_grow_safe_val(MaxVal,Val) when is_integer(MaxVal)->
    if
        Val>MaxVal-> MaxVal;
        true-> Val
    end.


%%@doc 根据等级获取 Vip 3 培养配置的基数、终值
%%@return {BaseVal,MaxVal}
get_grow_level_max_limit(RoleLevel) ->
	case common_config:is_debug() of
        true->
            {1,9999999999};     %%用于GM的测试模式
        _ ->
            get_grow_level_limit(12, RoleLevel)
    end.

%%@doc 根据等级获取培养配置的基数、终值
%%@return {BaseVal,MaxVal}
get_grow_level_limit(VipLevel, RoleLevel) when is_integer(RoleLevel) ->
	[ConfigList] = common_config_dyn:find(role_grow,{grow_level_limit, VipLevel}),
	get_grow_level_limit_2(RoleLevel,ConfigList).

get_grow_level_limit_2(_,[])->
    {0,0};
get_grow_level_limit_2(RoleLevel,[H|T])->
    {MinLevel,MaxLevel,BaseVal,MaxVal} = H,
    if
        RoleLevel>=MinLevel andalso MaxLevel>=RoleLevel ->
            {BaseVal,MaxVal};
        true->
            get_grow_level_limit_2(RoleLevel,T)
    end.

%% 计算装备战斗力
get_equip_fighting_power(Category,PGoods) ->
	#p_goods{add_property=AddProperty} = PGoods,
	#p_property_add{
        blood           = MaxHP,
        magic           = MaxMP,
        max_physic_att  = MaxPhyAttack,
        min_physic_att  = MinPhyAttack,
        max_magic_att   = MaxMagicAttack,
        min_magic_att   = MinMagicAttack,
        hurt            = HurtRate,
        physic_def      = PhyDefence,
        magic_def       = MagicDefence,
        move_speed      = MoveSpeed,
        hurt_rebound    = HurtRebound,
        dead_attack     = DoubleAttack,
        dodge           = Miss,
        hit_rate        = HitRate,
        no_defence      = NoDefence,
        phy_anti        = PhyAnti,
        magic_anti      = MagicAnti,
        tough           = Tough,
        vigour          = Vigour,
        crit            = Crit,
        bless           = Bless
    } = AddProperty,
    Attack = case Category of
        1 ->
            (MaxPhyAttack + MinPhyAttack)/2;
        3 ->
            (MaxMagicAttack + MinMagicAttack)/2
    end,
	calc_fighting_power(Attack, PhyDefence, MagicDefence, 
        MaxHP, MaxMP, MoveSpeed, PhyAnti, MagicAnti, HurtRate, 
        NoDefence, HurtRebound, Vigour, Miss, HitRate, DoubleAttack, Tough, Crit, Bless, 0).

%% 计算战斗力
get_fighting_power(RoleBase,RoleAttr) ->
	#p_role_base{
        role_id          = RoleID,
        max_hp           = MaxHP,
        max_mp           = MaxMP,
        max_phy_attack   = MaxPhyAttack,
        min_phy_attack   = MinPhyAttack,
        max_magic_attack = MaxMagicAttack,
        min_magic_attack = MinMagicAttack,
        phy_hurt_rate    = PhyHurtRate,
        magic_hurt_rate  = MagicHurtRate,
        phy_defence      = PhyDefence,
        magic_defence    = MagicDefence,
        move_speed       = MoveSpeed,
        hurt_rebound     = HurtRebound,
        double_attack    = DoubleAttack,
        miss             = Miss,
        hit_rate         = HitRate,
        no_defence       = NoDefence,
        phy_anti         = PhyAnti,
        magic_anti       = MagicAnti,
        tough            = Tough,
        vigour           = Vigour,
        crit             = Crit,
        bless            = Bless
	} = RoleBase,
	#p_role_attr{category=Category} = RoleAttr,
    case Category of
        1 ->
            Attack = (MaxPhyAttack + MinPhyAttack)/2, HurtRate = PhyHurtRate;
        3 ->
            Attack = (MaxMagicAttack + MinMagicAttack)/2, HurtRate = MagicHurtRate
    end,
    #r_role_skill_info{
        skill_id = NuqiSkillID,
        cur_level = NuqiSkillLevel
    } = mod_role_skill:get_role_nuqi_skill_info_persistent(RoleID),
    NuqiSkillShape = mod_role_skill:get_nuqi_skill_shape_num(NuqiSkillID),

    NuqiPingfen = cfg_zhanli:get_nuqi_pingfen(NuqiSkillShape, NuqiSkillLevel), 

	calc_fighting_power(Attack, PhyDefence, MagicDefence, 
        MaxHP, MaxMP, MoveSpeed, PhyAnti, MagicAnti, HurtRate, 
        NoDefence, HurtRebound, Vigour, Miss, HitRate, DoubleAttack, Tough, Crit, Bless, NuqiPingfen).


calc_fighting_power(Attack, PhyDefence, MagicDefence, 
    MaxHP, MaxMP, MoveSpeed, PhyAnti, MagicAnti, HurtRate, 
    NoDefence, HurtRebound, Vigour, Miss, HitRate, DoubleAttack, Tough, Crit, Bless, NuqiPingfen) ->
	Defence = (PhyDefence + MagicDefence) / 2,
	Anti    = (PhyAnti    + MagicAnti) / 2,
	Zhanli = cfg_zhanli:calc(Attack, Defence, MaxHP, MaxMP, MoveSpeed, Anti, 
        HurtRate, NoDefence, HurtRebound, Vigour, Miss, HitRate, DoubleAttack, Tough, Crit, Bless, NuqiPingfen),
    Zhanli.

%% 角色改名
%% @return true | {false, Reason}
rename(RoleID, RoleNameTmp) ->
    RoleName = common_tool:to_binary(RoleNameTmp),
    RoleNameUtf8 = unicode:characters_to_list(RoleName, utf8),
    %% 判断长度
    case common_tool:utf8_len(RoleNameUtf8) < 2 orelse common_tool:utf8_len(RoleNameUtf8) > 7 of
        true ->
            {false, ?_LANG_ROLE_NAME_LENGTH_WRONG};
        false ->
            case db:transaction(fun() -> t_rename(RoleID, RoleName) end) of
                {atomic, FamilyID} ->
                    do_update_family_member_name(FamilyID, RoleID, RoleName),
                    mgeer_role:send(RoleID, {mod_map_role, {rename_notify, RoleID, RoleName}}),
                    true;
                {aborted, Error} ->
                    ?ERROR_MSG("~ts:~p", ["角色改名出错", Error]),
                    case erlang:is_binary(Error) of
                        true ->
                            {false, Error};
                        false ->
                            {false, ?_LANG_SYSTEM_ERROR}
                    end
            end
    end.

do_update_family_member_name(FamilyID, RoleID, RoleName) ->
    common_family:update_member_name(FamilyID, RoleID, RoleName).
   
t_rename(RoleID, RoleName) ->
    case db:read(?DB_ROLE_NAME, RoleName, write) of
        [] ->
            ok;
        _ ->
            db:abort(?_LANG_ROLE_NAME_ALREADY_EXIST_WHEN_RENAME)
    end,
    [#p_role_base{role_name=OldRoleName, family_id=FamilyID} = RoleBase] = db:read(?DB_ROLE_BASE, RoleID, write),
    db:write(?DB_ROLE_BASE, RoleBase#p_role_base{role_name=RoleName}, write),
    [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, write),
    db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{role_name=RoleName}, write),
    %% 处理充值日志
    lists:foreach(
      fun(R) ->
              db:write(?DB_PAY_LOG, R#r_pay_log{role_name=RoleName}, write)
      end, db:match_object(?DB_PAY_LOG, #r_pay_log{role_id=RoleID, _='_'}, write)),
    case db:read(?DB_USER_ONLINE, RoleID, write) of
        [] ->
            ignore;
        %% 在线列表
        [RoleOnline] ->
            db:write(?DB_USER_ONLINE, RoleOnline#r_role_online{role_name=RoleName}, write)
    end,
    %% 角色名表
    [RoleNameRecord] = db:read(?DB_ROLE_NAME, OldRoleName, write),
    db:write(?DB_ROLE_NAME, RoleNameRecord#r_role_name{role_name=RoleName}, write),
    db:delete(?DB_ROLE_NAME, OldRoleName, write),
    %% 全局信件
    case db:read(?DB_PUBLIC_LETTER, RoleID, write) of
        [] ->
            ignore;
        [PublicLetter] ->
            db:write(?DB_PUBLIC_LETTER, PublicLetter#r_public_letter{role_name=RoleName}, write)
    end,
    %% 场景大战副本
    case  db:read(?DB_SCENE_WAR_FB, RoleID, write) of
        [] ->
            ignore;
        [SceneWarFb] ->
            db:write(?DB_SCENE_WAR_FB, SceneWarFb#r_scene_war_fb{role_name=RoleName}, write)
    end,
    %% 开箱子记录
    lists:foreach(
      fun(R) ->
              db:write(?DB_BOX_GOODS_LOG, R#r_box_goods_log{role_name=RoleName}, write)
      end, db:match_object(?DB_BOX_GOODS_LOG, #r_box_goods_log{role_id=RoleID, _='_'}, write)),
    %% 禁言记录
    case db:read(?DB_BAN_USER, OldRoleName, write) of
        [] ->
            ignore;
        [BanUser] ->
            db:delete(?DB_BAN_USER, OldRoleName, write),
            db:write(?DB_BAN_USER, BanUser#r_ban_user{rolename=RoleName}, write)
    end,    
    lists:foreach(
      fun(R) ->
              db:write(?DB_BAN_CHAT_USER, R#r_ban_chat_user{role_name=RoleName}, write)
      end, db:match_object(?DB_BAN_CHAT_USER_P, #r_ban_chat_user{_='_'}, write)),
    %% 宗祠日志不处理了    
    FamilyID.    

%% 获取战斗力排名
get_fighting_power_rank(RoleID) ->
	case db:dirty_read(?DB_ROLE_FIGHTING_POWER_RANK_P, RoleID) of
		[FightingPowerRank] ->
			FightingPowerRank;
		_ ->
 			undefined
	end.
