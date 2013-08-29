%% Author: dizengrong
%% Created: 2012-11-16
%% Description: 装备宝石系统(注意：与另一个宝石stone是不同的东东)
-module(mod_equip_gems).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([
        handle/1,
        role_level_up/2,
        recalc/2,
        get_gem_level/1,
        get_role_gems_info/1,
        hook_gems_skin/1,
        hook_gems_skin/2
    ]).

%% export for role_misc callback
-export([init/2, delete/1]).

%% for debug
-compile(export_all).


-define(ROLE_GEMS, role_gems).
-define(MOD_UNICAST(RoleID, Method, Msg), 
        common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GEMS, Method, Msg)).

-define(GEM_STATE_NOT_OPEN,     0).     %% 没开启
-define(GEM_STATE_OPEN,         1).     %% 已开启，但没有激活
-define(GEM_STATE_ACTIVATIED,   2).     %% 已激活

-define(GEM_STATUS_NO_INLAY,    0).     %% 无宝石可镶嵌
-define(GEM_STATUS_CAN_INLAY,   1).     %% 有可以镶嵌的宝石

-define(ADD_EXP_TYPE_1,         1).     %% 注入灵液加经验方式
-define(ADD_EXP_TYPE_2,         2).     %% 一键升级
-define(ADD_EXP_TYPE_3,         3).     %% 快速提升方式，即一键使用背包中所有的灵液来加经验
%% 前面的3种现在没有了，，先保留吧
-define(ADD_EXP_TYPE_4,         4).     %% 使用请求的灵液个数来加经验

%% ===================error string============================
-define(ERR_ALREADY_ACTIVATED,          <<"该宝石孔已激活了，无需再次激活">>).
-define(ERR_HOLE_NOT_OPEN,              <<"该宝石孔还没有开启">>).
-define(ERR_HOLE_NOT_ACTIVATED,         <<"该宝石孔还没有激活">>).
-define(ERR_PRE_HOLE_NOT_ACTIVATED,     <<"您必须先激活前一个宝石孔才能激活当前的">>).
-define(ERR_HOLE_LEVEL_CURRENT_FULL,    <<"当前宝石孔等级已满，请提升人物的等级">>).
-define(ERR_ADD_EXP_ITEM_NOT_ENOUGH,    <<"宝石灵液数量不足">>).
-define(ERR_ONE_KEY_LEVEL_GOLD_NOT_ENOUGH, <<"宝石孔一键升级时，元宝不足">>).


%%
%% API Functions
%%
init(RoleID, RoleGemsRec) ->
    case RoleGemsRec of
        false ->
            RoleGemsRec1 = default_gems();
        _ ->
            RoleGemsRec1 = RoleGemsRec
    end,
    set_role_gems_info(RoleID, RoleGemsRec1).

delete(RoleID) ->
    mod_role_tab:erase({?ROLE_GEMS, RoleID}).

default_gems() ->
    #p_role_gems{
                head     = [],
                body     = [],
                wrist    = [],
                hand     = [],
                neck     = [],
                waist    = [],
                bracelet = [],
                foot     = []
    }.
%% ========================进程字典操作接口========================
set_role_gems_info(RoleID, RoleGemsRec) ->
    mod_role_tab:put({?ROLE_GEMS, RoleID}, RoleGemsRec).

get_role_gems_info(RoleID) ->
    Ret = mod_role_tab:get({?ROLE_GEMS, RoleID}),
    case erlang:is_record(Ret, p_role_gems) of
        true  -> Ret;
        false -> default_gems()
    end.
%% ========================进程字典操作接口========================

%% ==========================handle处理============================
handle({_Unique, ?GEMS, ?GEMS_INFO, DataIn, RoleID, _PID, _Line}) ->
    PutOnPos = DataIn#m_gems_info_tos.put_on_pos,
    RoleGemsRec = get_role_gems_info(RoleID),
    send_role_gems_to_client(RoleID, RoleGemsRec, PutOnPos);

%% 请求给宝石孔注入灵液，级给宝石孔加经验升级
handle({_Unique, ?GEMS, ?GEMS_ADD_EXP, DataIn, RoleID, _PID, _Line}) ->
    PutOnPos         = DataIn#m_gems_add_exp_tos.put_on_pos,
    % HoleId           = DataIn#m_gems_add_exp_tos.hole_id,
    AddNum           = DataIn#m_gems_add_exp_tos.item_num,
    LingYeItemTypeID = DataIn#m_gems_add_exp_tos.use_item_type,
    do_add_hole_exp(RoleID, PutOnPos, AddNum, LingYeItemTypeID);

handle({_Unique, ?GEMS, ?GEMS_PUT_ON, DataIn, RoleID, _PID, _Line}) ->
    PutOnPos = DataIn#m_gems_put_on_tos.put_on_pos,
    HoleId   = DataIn#m_gems_put_on_tos.hole_id,
    GemTypeId   = DataIn#m_gems_put_on_tos.gem_typeid,
    do_put_on(RoleID, PutOnPos, HoleId, GemTypeId);

handle({_Unique, ?GEMS, ?GEMS_TAKE_OFF, DataIn, RoleID, _PID, _Line}) ->
    PutOnPos = DataIn#m_gems_take_off_tos.put_on_pos,
    HoleId   = DataIn#m_gems_take_off_tos.hole_id,
    do_take_off(RoleID, PutOnPos, HoleId);
    
handle({_Unique, ?GEMS, ?GEMS_ALL_ATTR, _DataIn, RoleID, _PID, _Line}) ->
    do_get_all_attr(RoleID);

handle(Msg) ->
    ?ERROR_MSG("uexcept msg = ~w",[Msg]).
%% ==========================handle处理============================

%% 计算所有宝石孔的属性加成
%% 返回#p_property_add{}
gem_attrs(RoleGemsRec) ->
    L = [{#p_role_gems.head, RoleGemsRec#p_role_gems.head},
         {#p_role_gems.body, RoleGemsRec#p_role_gems.body},
         {#p_role_gems.wrist, RoleGemsRec#p_role_gems.wrist},
         {#p_role_gems.hand, RoleGemsRec#p_role_gems.hand},
         {#p_role_gems.neck, RoleGemsRec#p_role_gems.neck},
         {#p_role_gems.waist, RoleGemsRec#p_role_gems.waist},
         {#p_role_gems.bracelet, RoleGemsRec#p_role_gems.bracelet},
         {#p_role_gems.foot, RoleGemsRec#p_role_gems.foot}
    ],
    GemsAddAttrRec = calc_add_property2(L, #p_gems_add_attr{_ = 0}),
    case cfg_gems:get_addtional_add(get_all_hole_big_lv(RoleGemsRec)) of
        [] ->
            GemsAddAttrRec1 = GemsAddAttrRec;
        AddtionalAdd ->
            GemsAddAttrRec1 = GemsAddAttrRec#p_gems_add_attr{
                att           = AddtionalAdd#p_gems_add_attr.att + GemsAddAttrRec#p_gems_add_attr.att,
                p_def         = AddtionalAdd#p_gems_add_attr.p_def + GemsAddAttrRec#p_gems_add_attr.p_def,
                m_def         = AddtionalAdd#p_gems_add_attr.m_def + GemsAddAttrRec#p_gems_add_attr.m_def,
                hp            = AddtionalAdd#p_gems_add_attr.hp + GemsAddAttrRec#p_gems_add_attr.hp,
                tough         = AddtionalAdd#p_gems_add_attr.tough + GemsAddAttrRec#p_gems_add_attr.tough,
                miss          = AddtionalAdd#p_gems_add_attr.miss + GemsAddAttrRec#p_gems_add_attr.miss,
                hit           = AddtionalAdd#p_gems_add_attr.hit + GemsAddAttrRec#p_gems_add_attr.hit,
                double_attack = AddtionalAdd#p_gems_add_attr.double_attack + GemsAddAttrRec#p_gems_add_attr.double_attack,
                bless         = AddtionalAdd#p_gems_add_attr.bless + GemsAddAttrRec#p_gems_add_attr.bless,
                crit          = AddtionalAdd#p_gems_add_attr.crit + GemsAddAttrRec#p_gems_add_attr.crit
            }
    end,
    GemProps = propertyAdd_add_gemAddAttr(#p_property_add{_ = 0}, GemsAddAttrRec1),
    mod_role_attr:transform(GemProps).

calc_add_property2([], GemsAddAttrRec) -> GemsAddAttrRec;
calc_add_property2([{GemPos, Holes} | Rest], GemsAddAttrRec) ->
    GemsAddAttrRec1 = calc_add_property3(GemPos, Holes, GemsAddAttrRec),
    calc_add_property2(Rest, GemsAddAttrRec1).

calc_add_property3(_GemPos, [], GemsAddAttrRec) -> GemsAddAttrRec;
calc_add_property3(GemPos, [GemHoleRec | Rest], GemsAddAttrRec) ->
    case is_record(GemHoleRec, p_gem_hole) andalso GemHoleRec#p_gem_hole.state of
        ?GEM_STATE_ACTIVATIED ->
            GemLv = get_gem_level(GemHoleRec#p_gem_hole.gem_typeid),
            Rec   = cfg_gems:get_add_attr(GemPos, GemLv),
            Rec1  = cal_cao_add_effect(Rec, GemHoleRec#p_gem_hole.level),
            GemsAddAttrRec1 = gemAddAttr_add_gemAddAttr(GemsAddAttrRec, Rec1),
            calc_add_property3(GemPos, Rest, GemsAddAttrRec1);
        _ ->
            calc_add_property3(GemPos, Rest, GemsAddAttrRec)
    end.

%% 计算镶嵌槽的加成
cal_cao_add_effect(GemAddAttr, 0) -> GemAddAttr;
cal_cao_add_effect(GemAddAttr, CaoLv) ->
    AddRate = cfg_gems:cao_add_effect(CaoLv),
    GemAddAttr#p_gems_add_attr{
        att           = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.att),
        p_def         = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.p_def),
        m_def         = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.m_def),
        hp            = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.hp),
        tough         = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.tough),
        double_attack = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.double_attack),
        miss          = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.miss),
        hit           = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.hit),
        no_defence    = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.no_defence),
        vigour        = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.vigour),
        hurt_rebound  = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.hurt_rebound),
        anti          = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.anti),
        bless         = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.bless),
        crit          = trunc((1 + AddRate)* GemAddAttr#p_gems_add_attr.crit)
    }.
gemAddAttr_add_gemAddAttr(Rec1, Rec2) ->
    #p_gems_add_attr{
        att           = Rec1#p_gems_add_attr.att + Rec2#p_gems_add_attr.att,
        p_def         = Rec1#p_gems_add_attr.p_def + Rec2#p_gems_add_attr.p_def,
        m_def         = Rec1#p_gems_add_attr.m_def + Rec2#p_gems_add_attr.m_def,
        hp            = Rec1#p_gems_add_attr.hp + Rec2#p_gems_add_attr.hp,
        tough         = Rec1#p_gems_add_attr.tough + Rec2#p_gems_add_attr.tough,
        miss          = Rec1#p_gems_add_attr.miss + Rec2#p_gems_add_attr.miss,
        hit           = Rec1#p_gems_add_attr.hit + Rec2#p_gems_add_attr.hit,
        double_attack = Rec1#p_gems_add_attr.double_attack + Rec2#p_gems_add_attr.double_attack,
        no_defence    = Rec1#p_gems_add_attr.no_defence + Rec2#p_gems_add_attr.no_defence,
        vigour        = Rec1#p_gems_add_attr.vigour + Rec2#p_gems_add_attr.vigour,
        hurt_rebound  = Rec1#p_gems_add_attr.hurt_rebound + Rec2#p_gems_add_attr.hurt_rebound,
        anti          = Rec1#p_gems_add_attr.anti + Rec2#p_gems_add_attr.anti,
        bless         = Rec1#p_gems_add_attr.bless + Rec2#p_gems_add_attr.bless,
        crit          = Rec1#p_gems_add_attr.crit + Rec2#p_gems_add_attr.crit
    }.

propertyAdd_add_gemAddAttr(PropertyAddRec, GemAddAttrRec) ->
    PropertyAddRec#p_property_add{
        min_physic_att = PropertyAddRec#p_property_add.min_physic_att + GemAddAttrRec#p_gems_add_attr.att,
        max_physic_att = PropertyAddRec#p_property_add.max_physic_att + GemAddAttrRec#p_gems_add_attr.att,
        min_magic_att  = PropertyAddRec#p_property_add.min_magic_att + GemAddAttrRec#p_gems_add_attr.att,
        max_magic_att  = PropertyAddRec#p_property_add.max_magic_att + GemAddAttrRec#p_gems_add_attr.att,
        physic_def     = PropertyAddRec#p_property_add.physic_def + GemAddAttrRec#p_gems_add_attr.p_def,
        magic_def      = PropertyAddRec#p_property_add.magic_def + GemAddAttrRec#p_gems_add_attr.m_def,
        blood          = PropertyAddRec#p_property_add.blood + GemAddAttrRec#p_gems_add_attr.hp,
        tough          = PropertyAddRec#p_property_add.tough + GemAddAttrRec#p_gems_add_attr.tough,
        dead_attack    = PropertyAddRec#p_property_add.dead_attack + GemAddAttrRec#p_gems_add_attr.double_attack,
        dodge          = PropertyAddRec#p_property_add.dodge + GemAddAttrRec#p_gems_add_attr.miss,
        hit_rate       = PropertyAddRec#p_property_add.hit_rate + GemAddAttrRec#p_gems_add_attr.hit,
        % no_defence     = PropertyAddRec#p_property_add.no_defence + GemAddAttrRec#p_gems_add_attr.no_defence,
        vigour         = PropertyAddRec#p_property_add.vigour + GemAddAttrRec#p_gems_add_attr.vigour,
        % phy_anti           = PropertyAddRec#p_property_add.phy_anti + GemAddAttrRec#p_gems_add_attr.anti,
        % magic_anti           = PropertyAddRec#p_property_add.magic_anti + GemAddAttrRec#p_gems_add_attr.anti,
        hurt_rebound   = PropertyAddRec#p_property_add.hurt_rebound + GemAddAttrRec#p_gems_add_attr.hurt_rebound,
        bless          = PropertyAddRec#p_property_add.bless + GemAddAttrRec#p_gems_add_attr.bless,
        crit           = PropertyAddRec#p_property_add.crit + GemAddAttrRec#p_gems_add_attr.crit
    }.

get_gem_level(GemTypeId) -> 
    GemTypeId rem 10. 

get_all_hole_min_lv(RoleGemsRec) ->
    AllHoles = RoleGemsRec#p_role_gems.head
                ++ RoleGemsRec#p_role_gems.body
                ++ RoleGemsRec#p_role_gems.wrist
                ++ RoleGemsRec#p_role_gems.hand
                ++ RoleGemsRec#p_role_gems.neck
                ++ RoleGemsRec#p_role_gems.waist
                ++ RoleGemsRec#p_role_gems.bracelet
                ++ RoleGemsRec#p_role_gems.foot,
    get_all_hole_min_lv(AllHoles, 100000).

get_all_hole_min_lv([], MinLv) -> MinLv;
get_all_hole_min_lv([GemHoleRec | Rest], MinLv) ->
    if
        GemHoleRec#p_gem_hole.level == 0 ->
            0;
        GemHoleRec#p_gem_hole.level < MinLv ->
            get_all_hole_min_lv(Rest, GemHoleRec#p_gem_hole.level);
        true ->
            get_all_hole_min_lv(Rest, MinLv)
    end.

get_all_hole_big_lv(RoleGemsRec) ->
    AllHoles = RoleGemsRec#p_role_gems.head
                ++ RoleGemsRec#p_role_gems.body
                ++ RoleGemsRec#p_role_gems.wrist
                ++ RoleGemsRec#p_role_gems.hand
                ++ RoleGemsRec#p_role_gems.neck
                ++ RoleGemsRec#p_role_gems.waist
                ++ RoleGemsRec#p_role_gems.bracelet
                ++ RoleGemsRec#p_role_gems.foot,
    AllNeedCalLevel = cfg_gems:all_gems_level(),
    Result = [{Lv, 0, false} || {Lv, _Num} <- AllNeedCalLevel],
    Result1 = get_all_hole_big_lv(AllHoles, AllNeedCalLevel, Result),
    Fun = fun({Lv, _Num, IsSatisfyNeed}, BigLv) ->
        case IsSatisfyNeed of
            true  -> erlang:max(BigLv, Lv);
            false -> BigLv
        end
    end,
    lists:foldl(Fun, 0, Result1).

get_all_hole_big_lv([], _AllNeedCalLevel, Result) -> Result;
get_all_hole_big_lv([GemHoleRec | Rest], AllNeedCalLevel, Result) ->
    Fun = fun({Lv, NeedNum}, Result1) ->
        case is_record(GemHoleRec, p_gem_hole) andalso GemHoleRec#p_gem_hole.gem_typeid =/=0
            andalso get_gem_level(GemHoleRec#p_gem_hole.gem_typeid) >= Lv of
            true ->
                {Lv, Num, _IsSatisfyNeed} = lists:keyfind(Lv, 1, Result1),
                IsSatisfyNeed1 = (Num + 1 >= NeedNum),
                lists:keystore(Lv, 1, Result1, {Lv, Num + 1, IsSatisfyNeed1});
            false -> Result1
        end
    end,
    get_all_hole_big_lv(Rest, AllNeedCalLevel, lists:foldl(Fun, Result, AllNeedCalLevel)).

%% 玩家升级时的回调通知
role_level_up(RoleID, NewLevel) ->
    RoleGemsRec        = get_role_gems_info(RoleID),
    DefaultOpenHoleNum = cfg_gems:get_misc(open_gem_hole),

    Ret = case NewLevel >= cfg_gems:get_misc(open_level) of
        true ->
            case length(RoleGemsRec#p_role_gems.head) >= DefaultOpenHoleNum of
                true  -> ignore;
                false -> open_gem_system(DefaultOpenHoleNum)
            end;
        false -> ignore
    end,
    case Ret of
        ignore -> ignore;
        {open_system, RoleGemsRec1} ->
            set_role_gems_info(RoleID, RoleGemsRec1),
            send_role_gems_to_client(RoleID, RoleGemsRec1, 0);
        {open_new_hole, RoleGemsRec1} ->
            set_role_gems_info(RoleID, RoleGemsRec1),
            send_role_gems_to_client(RoleID, RoleGemsRec1, 0)
    end.


%% 打开该系统，并默认给玩家的每个装备位置开启DefaultOpenHoleNum个宝石孔
open_gem_system(DefaultOpenHoleNum) ->
    Fun = fun(HoleId, Acc) ->
        GemHoleRec = create_activated_hole(HoleId),
        [GemHoleRec | Acc]
    end,
    DefaultGemHoles = lists:foldl(Fun, [], lists:seq(1, DefaultOpenHoleNum)),
    RoleGemsRec = #p_role_gems{
        head     = DefaultGemHoles,
        body     = DefaultGemHoles,
        wrist    = DefaultGemHoles,
        hand     = DefaultGemHoles,
        neck     = DefaultGemHoles,
        waist    = DefaultGemHoles,
        bracelet = DefaultGemHoles,
        foot     = DefaultGemHoles
    },
    {open_system, RoleGemsRec}.

do_put_on(RoleID, PutOnPos, 0, _) ->
    GemPos      = put_pos_2_gem_pos(PutOnPos),
    RoleGemsRec = get_role_gems_info(RoleID),
    CosumeMoney = cfg_gems:xiangqian_cost(),
    case put_on_gems(RoleID, RoleGemsRec, GemPos, CosumeMoney) of
        {false, _, Reason} ->
            case Reason of
                undefined -> common_misc:send_common_error(RoleID, 0, <<"该部位已经镶嵌满了宝石！">>);
                _ -> 
                    common_misc:send_common_error(RoleID, 0, Reason)
            end;
        {true, Num, _} ->
            case common_bag2:use_money(RoleID, silver_any, CosumeMoney*Num, ?CONSUME_TYPE_SILVER_XIANGQIAN_GEMS) of
                true ->
                    Msg = #m_gems_put_on_toc{
                        put_on_pos = PutOnPos
                    },
                    ?MOD_UNICAST(RoleID, ?GEMS_PUT_ON, Msg),
                    NewRoleGemsRec = get_role_gems_info(RoleID),
                    send_role_gems_to_client(RoleID, NewRoleGemsRec, PutOnPos),
                    ?TRY_CATCH(mod_open_activity:hook_gems_event(RoleID)),
                    update_role_base(RoleID, RoleGemsRec, NewRoleGemsRec),
                    mod_role_event:notify(RoleID, {?ROLE_EVENT_GEMS_PUT, NewRoleGemsRec}),
                    hook_gems_skin(RoleID, NewRoleGemsRec),
                    ok;
                {error, Reason} ->
                    common_misc:send_common_error(RoleID, 0, Reason)
            end
    end;

do_put_on(RoleID, PutOnPos, HoleId, GemTypeId) ->
    GemPos      = put_pos_2_gem_pos(PutOnPos),
    RoleGemsRec = get_role_gems_info(RoleID),
    CosumeMoney = cfg_gems:xiangqian_cost(),
    case put_on_common_check(RoleID, RoleGemsRec, GemPos, HoleId, GemTypeId) of
        {error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
        {true, GemHoleRec} ->
            case common_bag2:use_money(RoleID, silver_any, CosumeMoney, ?CONSUME_TYPE_SILVER_XIANGQIAN_GEMS) of
                true ->
                    OldGemTypeId = GemHoleRec#p_gem_hole.gem_typeid,
                    case OldGemTypeId =/= 0 of
                        true ->
                            {true, _ } = mod_bag:add_items(RoleID, [{OldGemTypeId, 1, ?TYPE_ITEM, true}], ?LOG_ITEM_TYPE_CHAI_XIE_HUO_DE);
                        _ -> ignore
                    end,
                    GemHoleRec1    = GemHoleRec#p_gem_hole{gem_typeid = GemTypeId},
                    ok             = mod_bag:use_item(RoleID, GemTypeId, 1, ?LOG_ITEM_TYPE_XIANG_QIAN_SHI_QU),
                    Holes          = get_gem_pos_holes(RoleGemsRec, GemPos),
                    NewHoles       = lists:keystore(HoleId, #p_gem_hole.id, Holes, GemHoleRec1),
                    NewRoleGemsRec = set_gem_pos_holes(RoleGemsRec, GemPos, NewHoles),
                    set_role_gems_info(RoleID, NewRoleGemsRec),
                    mod_qrhl:send_event(RoleID, baoshi, GemTypeId rem 100),
                    Msg = #m_gems_put_on_toc{
                        put_on_pos = PutOnPos,
                        hole_id    = HoleId,
                        gem_typeid = GemTypeId
                    },
                    ?MOD_UNICAST(RoleID, ?GEMS_PUT_ON, Msg),
                    send_role_gems_to_client(RoleID, NewRoleGemsRec, PutOnPos),
                    ?TRY_CATCH(mod_open_activity:hook_gems_event(RoleID)),
                    update_role_base(RoleID, RoleGemsRec, NewRoleGemsRec),
                    mod_role_event:notify(RoleID, {?ROLE_EVENT_GEMS_PUT, NewRoleGemsRec}),
                    hook_gems_skin(RoleID, NewRoleGemsRec);
               {error, _Reason} ->
                    common_misc:send_common_error(RoleID, 0, <<"铜币不足,无法镶嵌！">>)
            end
    end.

put_on_common_check(RoleID, RoleGemsRec, GemPos, HoleId, GemTypeId) ->
    true = lists:member(GemTypeId, cfg_gems:all_gems(GemPos)),
    case is_hole_activated(RoleID, RoleGemsRec, GemPos, HoleId) of
        false -> {error, <<"该宝石孔没有开启">>};
        {true, GemHoleRec} ->
            case get_item_num(RoleID, GemTypeId) of
                0 -> {error, <<"您的背包中无该宝石">>};
                _ ->
                    case GemHoleRec#p_gem_hole.gem_typeid =/= 0 of
                        true -> %% 表示要替换宝石
                            case mod_bag:get_empty_bag_pos_num(RoleID, 1) of
                                {ok,Num} when Num > 0 -> {true, GemHoleRec};
                                _ -> {error, <<"背包空间不足，无法卸载宝石">>}
                            end;
                        false -> {true, GemHoleRec}
                    end
            end
    end.

do_take_off(RoleID, PutOnPos, 0) ->
    GemPos      = put_pos_2_gem_pos(PutOnPos),
    RoleGemsRec = get_role_gems_info(RoleID),
    case take_off_gems(RoleID, RoleGemsRec, GemPos) of
        {false, Reason} ->
            case Reason of
                undefined -> common_misc:send_common_error(RoleID, 0, <<"该部位没有宝石可拆卸">>);
                _ -> 
                    common_misc:send_common_error(RoleID, 0, Reason)
            end;
        {true, _} ->
            Msg = #m_gems_take_off_toc{
                put_on_pos = PutOnPos
            },
            ?MOD_UNICAST(RoleID, ?GEMS_TAKE_OFF, Msg),
            NewRoleGemsRec = get_role_gems_info(RoleID),
            send_role_gems_to_client(RoleID, NewRoleGemsRec, PutOnPos),
			?TRY_CATCH(mod_open_activity:hook_gems_event(RoleID)),
            update_role_base(RoleID, RoleGemsRec, NewRoleGemsRec),
            hook_gems_skin(RoleID, NewRoleGemsRec),
            ok
    end;

do_take_off(RoleID, PutOnPos, HoleId) ->
    GemPos      = put_pos_2_gem_pos(PutOnPos),
    RoleGemsRec = get_role_gems_info(RoleID),
    case take_off_common_check(RoleID, RoleGemsRec, GemPos, HoleId) of
        {error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
        {true, GemHoleRec} ->
            GemTypeId      = GemHoleRec#p_gem_hole.gem_typeid,
            LogType        = ?LOG_ITEM_TYPE_CHAI_XIE_HUO_DE,
            mod_bag:add_items(RoleID, [{GemTypeId, 1, ?TYPE_ITEM, true}], LogType),
            Holes          = get_gem_pos_holes(RoleGemsRec, GemPos),
            GemHoleRec1    = GemHoleRec#p_gem_hole{gem_typeid = 0},
            NewHoles       = lists:keystore(HoleId, #p_gem_hole.id, Holes, GemHoleRec1),
            NewRoleGemsRec = set_gem_pos_holes(RoleGemsRec, GemPos, NewHoles),
            set_role_gems_info(RoleID, NewRoleGemsRec),
            Msg = #m_gems_take_off_toc{
                put_on_pos = PutOnPos,
                hole_id    = HoleId
            },
            ?MOD_UNICAST(RoleID, ?GEMS_TAKE_OFF, Msg),
			?TRY_CATCH(mod_open_activity:hook_gems_event(RoleID)),
            send_role_gems_to_client(RoleID, NewRoleGemsRec, PutOnPos),
            update_role_base(RoleID, RoleGemsRec, NewRoleGemsRec),
            hook_gems_skin(RoleID, NewRoleGemsRec),
            ok
    end.

do_get_all_attr(RoleID) ->
    Msg = #m_gems_all_attr_toc{
        level = get_all_hole_big_lv(get_role_gems_info(RoleID))
    },
    ?MOD_UNICAST(RoleID, ?GEMS_ALL_ATTR, Msg).

take_off_common_check(RoleID, RoleGemsRec, GemPos, HoleId) ->
    case is_hole_activated(RoleID, RoleGemsRec, GemPos, HoleId) of
        false -> {error, <<"该部位宝石孔没有开启">>};
        {true, GemHoleRec} ->
            case GemHoleRec#p_gem_hole.gem_typeid == 0 of
                true -> {error, <<"该部位没有宝石可拆卸">>};
                false ->
                    case mod_bag:get_empty_bag_pos_num(RoleID, 1) of
                        {ok, Num} when Num > 0 -> {true, GemHoleRec};
                        _ -> {error, <<"背包空间不足，无法卸载宝石">>}
                    end
            end
    end.

%% 激活一个宝石孔时调用，激活的宝石孔默认为1级
create_activated_hole(_GemPos, GemHoleRec) ->
    GemHoleRec#p_gem_hole{
        state     = ?GEM_STATE_ACTIVATIED,
        exp       = 0,
        level     = 0   
    }.

create_activated_hole(HoleId) ->
    #p_gem_hole{
        id    = HoleId,
        state = ?GEM_STATE_ACTIVATIED,
        exp   = 0,
        level = 0   
    }.

do_add_hole_exp(RoleID, PutOnPos, AddNum, LingYeItemTypeID) ->
    GemPos      = put_pos_2_gem_pos(PutOnPos),
    RoleGemsRec = get_role_gems_info(RoleID),
    Ret = case add_hole_exp_common_check(RoleID, RoleGemsRec, GemPos) of
        {error, Reason} ->
            {error, Reason};
        true ->
            HoleId     = 1,
            GemHoleRec = get_gem_pos_hole(RoleGemsRec, GemPos, HoleId),
            ItemHave   = get_item_num(RoleID, LingYeItemTypeID),
            AddNum1    = erlang:min(ItemHave, AddNum),
            Result     = get_total_exp_add_and_cost(RoleID, GemHoleRec, AddNum1, LingYeItemTypeID),
            {NewLevel, NewExp, ItemCost} = Result,
            if
                AddNum1 == 0 ->
                    {error, ?ERR_ADD_EXP_ITEM_NOT_ENOUGH};
                true ->
                    LogType1 = ?LOG_ITEM_TYPE_ADD_TO_GEM_HOLE_LOST,
                    ok = mod_bag:use_item(RoleID, LingYeItemTypeID, ItemCost, LogType1),
                    do_add_hole_exp2(RoleGemsRec, GemPos, NewLevel, NewExp)
            end
    end,
    case Ret of
        {error, Reason1} ->
            common_misc:send_common_error(RoleID, 0, Reason1);
        {IsLevelUp, _NewLevel2, NewRoleGemsRec} ->
            set_role_gems_info(RoleID, NewRoleGemsRec),
            Msg = #m_gems_add_exp_toc{
                put_on_pos = PutOnPos,
                hole_data  = get_added_attr(GemPos, get_gem_pos_holes(NewRoleGemsRec, GemPos))
            },
            ?MOD_UNICAST(RoleID, ?GEMS_ADD_EXP, Msg),
            send_role_gems_to_client(RoleID, NewRoleGemsRec, PutOnPos),
            case IsLevelUp of
                true -> 
                    update_role_base(RoleID, RoleGemsRec, NewRoleGemsRec),
                    check_all_gems_level(RoleID, NewRoleGemsRec);
                false -> ok
            end
    end.

do_add_hole_exp2(RoleGemsRec, GemPos, NewLevel, NewExp) ->
    Holes  = get_gem_pos_holes(RoleGemsRec, GemPos),
    Fun = fun(GemHoleRec) ->
        GemHoleRec#p_gem_hole{
            exp       = NewExp,
            level     = NewLevel
        }
    end,
    Holes1        = [Fun(R) || R <- Holes],
    RoleGemsRec1  = set_gem_pos_holes(RoleGemsRec, GemPos, Holes1),
    OldGemHoleRec = erlang:hd(Holes),
    IsLevelUp     = (NewLevel > OldGemHoleRec#p_gem_hole.level),
    {IsLevelUp, NewLevel, RoleGemsRec1}.

get_total_exp_add_and_cost(RoleID, GemHoleRec, AddNum, LingYeItemTypeID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    {NewLevel, NewExp, LeftNum} = add_exp_help(RoleAttr#p_role_attr.level, GemHoleRec, AddNum, LingYeItemTypeID),
    {NewLevel, NewExp, AddNum - LeftNum}.

%% 给一个宝石孔加LeftNum个宝石灵液，直到达到最大级或是用完LeftNum个宝石灵液
add_exp_help(_RoleLv, GemHoleRec, 0, _LingYeItemTypeID) -> {GemHoleRec#p_gem_hole.level, GemHoleRec#p_gem_hole.exp, 0};
add_exp_help(RoleLv, GemHoleRec, LeftNum, LingYeItemTypeID) ->
    LevelUpExp = cfg_gems:level_up_exp(GemHoleRec#p_gem_hole.level),
    LingyeExp  = cfg_gems:get_misc({gem_lingye_exp, LingYeItemTypeID}),
    case GemHoleRec#p_gem_hole.exp + LingyeExp >= LevelUpExp of
        true ->
            MaxHoleLv = cfg_gems:max_level(RoleLv),
            case GemHoleRec#p_gem_hole.level + 1 >= MaxHoleLv of
                true ->
                    {GemHoleRec#p_gem_hole.level + 1, 0, LeftNum - 1};
                false ->
                    GemHoleRec1 = GemHoleRec#p_gem_hole{
                        level = GemHoleRec#p_gem_hole.level + 1, 
                        exp   = GemHoleRec#p_gem_hole.exp + LingyeExp - LevelUpExp
                    },
                    add_exp_help(RoleLv, GemHoleRec1, LeftNum - 1, LingYeItemTypeID)
            end;
        false ->
            GemHoleRec1 = GemHoleRec#p_gem_hole{
                exp = GemHoleRec#p_gem_hole.exp + LingyeExp
            },
            add_exp_help(RoleLv, GemHoleRec1, LeftNum - 1, LingYeItemTypeID)
    end.


add_hole_exp_common_check(RoleID, RoleGemsRec, GemPos) ->
    Holes = get_gem_pos_holes(RoleGemsRec, GemPos),
    GemHoleRec = lists:keyfind(1, #p_gem_hole.id, Holes),
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    MaxHoleLv      = cfg_gems:max_level(RoleAttr#p_role_attr.level),
    case GemHoleRec#p_gem_hole.level >= MaxHoleLv of
        true -> %% 超过人物等级限制的上限了
            {error, ?ERR_HOLE_LEVEL_CURRENT_FULL};
        false ->
            true
    end.


get_item_num(RoleID, ItemTypeID) ->
    {ok, Num} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ItemTypeID),
    Num.

%% 检测所有的宝石的等级并做一些事情
check_all_gems_level(RoleID, RoleGemsRec) ->
    MinLv = get_all_hole_min_lv(RoleGemsRec),
    %% 完成成就
    if
        MinLv >= 9 -> 
            mod_achievement2:achievement_update_event(RoleID, 14002, 1);
        MinLv >= 8 -> 
            mod_achievement2:achievement_update_event(RoleID, 13002, 1);
        MinLv >= 6 ->
            mod_achievement2:achievement_update_event(RoleID, 12002, 1);
        MinLv >= 4 ->
            mod_achievement2:achievement_update_event(RoleID, 11002, 1);
        true -> 
            ok
    end.


%% ===================================================================
%% 调用者要保证HoleId为正确范围内的值，
%% 如果开启返回{true, GemHoleRec}，否则返回false
is_hole_activated(RoleID, RoleGemsRec, GemPos, HoleId) ->
    OpenLv = cfg_gems:open_level_require(HoleId),
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case RoleAttr#p_role_attr.level >= OpenLv of
        true ->
            Holes = get_gem_pos_holes(RoleGemsRec, GemPos),
            {true, lists:keyfind(HoleId, #p_gem_hole.id, Holes)};
        false ->
            false
    end.

%% 获取宝石孔的状态
get_hole_state(RoleGemsRec, GemPos, HoleId) ->
    Holes = get_gem_pos_holes(RoleGemsRec, GemPos),
    case lists:keyfind(HoleId, #p_gem_hole.id, Holes) of
        false ->  %% 都还没有开启呢
            ?GEM_STATE_NOT_OPEN;
        GemHoleRec ->
            GemHoleRec#p_gem_hole.state
    end.
%% ==============================================================
%% ====================== local function ========================
send_role_gems_to_client(RoleID, RoleGemsRec, 0) ->
    PutOnPosList = [?PUT_ARM, ?PUT_NECKLACE, ?PUT_ARMET, ?PUT_BREAST,
                  ?PUT_CAESTUS, ?PUT_BANGLE, ?PUT_SHOES, ?PUT_HAND],
    Fun = fun(PutOnPos) -> 
        GemPos = put_pos_2_gem_pos(PutOnPos),
        #p_pos_gems{
            pos   = PutOnPos,
           % status = get_gem_status(RoleID, GemPos, RoleGemsRec),
            holes = get_added_attr(GemPos, get_gem_pos_holes(RoleGemsRec, GemPos))}
    end,
    Msg = #m_gems_info_toc{data = [Fun(P) || P <- PutOnPosList]},
    ?MOD_UNICAST(RoleID, ?GEMS_INFO, Msg);
send_role_gems_to_client(RoleID, RoleGemsRec, PutOnPos) ->
    GemPos = put_pos_2_gem_pos(PutOnPos),
    Holes  = get_gem_pos_holes(RoleGemsRec, GemPos),
    Msg    = #m_gems_info_toc{
        data = [#p_pos_gems{
                    pos = PutOnPos,
                %    status = get_gem_status(RoleID, GemPos, RoleGemsRec),
                    holes = get_added_attr(GemPos, Holes)
                           }]
    },
    ?MOD_UNICAST(RoleID, ?GEMS_INFO, Msg).

get_added_attr(GemPos, GemHoleRecs) ->
    get_added_attr(GemPos, GemHoleRecs, []).
get_added_attr(_GemPos, [], GemHoleRecs) -> GemHoleRecs;
get_added_attr(GemPos, [GemHoleRec | Rest], GemHoleRecs) ->
    GemHoleRec1 = get_gem_added_attr(GemPos, GemHoleRec),
    get_added_attr(GemPos, Rest, [GemHoleRec1 | GemHoleRecs]).

get_gem_added_attr(GemPos, GemHoleRec) ->
    %% 组装宝石孔的激活条件给客户端
    CaoLv = get_gem_level(GemHoleRec#p_gem_hole.level),
    case GemHoleRec#p_gem_hole.state of
        ?GEM_STATE_OPEN ->
            Cond                = [0,0,0],
            AddAttr             = #p_gems_add_attr{};
        ?GEM_STATE_ACTIVATIED ->
            Cond    = [0,0,0],
            AddAttr = cfg_gems:get_add_attr(GemPos, get_gem_level(GemHoleRec#p_gem_hole.gem_typeid))
    end,
    GemHoleRec#p_gem_hole{
        add_attr  = cal_cao_add_effect(AddAttr, CaoLv),
        condition = Cond,
        cao_attr  = trunc(cfg_gems:cao_add_effect(CaoLv) * 10000),
        max_exp   = cfg_gems:level_up_exp(GemHoleRec#p_gem_hole.level)
    }.

%% 将装备中定义的位置转化为p_role_gems记录中对应的位置
put_pos_2_gem_pos(?PUT_ARM)         -> #p_role_gems.hand;
put_pos_2_gem_pos(?PUT_NECKLACE)    -> #p_role_gems.neck;
put_pos_2_gem_pos(?PUT_ARMET)       -> #p_role_gems.head;
put_pos_2_gem_pos(?PUT_BREAST)      -> #p_role_gems.body;
put_pos_2_gem_pos(?PUT_CAESTUS)     -> #p_role_gems.waist;
put_pos_2_gem_pos(?PUT_BANGLE)      -> #p_role_gems.bracelet;
put_pos_2_gem_pos(?PUT_SHOES)       -> #p_role_gems.foot;
put_pos_2_gem_pos(?PUT_HAND)        -> #p_role_gems.wrist.

%% 获取对应位置上的宝石孔list，GemPos为p_role_gems记录中对应字段的索引
get_gem_pos_holes(RoleGemsRec, GemPos) ->
    erlang:element(GemPos, RoleGemsRec).

%% 设置对应位置上的宝石孔list为新的值NewHoles
set_gem_pos_holes(RoleGemsRec, GemPos, NewHoles) -> 
    erlang:setelement(GemPos, RoleGemsRec, NewHoles).
%% 获取对应位置上的宝石孔记录
get_gem_pos_hole(RoleGemsRec, GemPos, HoleId) ->
    Holes = get_gem_pos_holes(RoleGemsRec, GemPos),
    lists:keyfind(HoleId, #p_gem_hole.id, Holes).

get_gem_status(RoleID, GemPos, RoleGemsRec) ->
    GemsList = cfg_gems:all_gems(GemPos),
    Holes = get_gem_pos_holes(RoleGemsRec, GemPos),
    Status =
        lists:foldr(
            fun(HoleID, AccIn) ->
                AccIn orelse
                  case lists:keyfind(HoleID, #p_gem_hole.id, Holes) of
                      false -> 
                          AccIn;
                      GemHoleRec ->
                          case GemHoleRec#p_gem_hole.gem_typeid == 0 of
                              true ->
                                  lists:foldr(
                                    fun(GemID, GemAccIN) ->
                                        case GemAccIN of
                                            true -> true;
                                            _ ->
                                                case status_check(RoleID, RoleGemsRec, GemPos, HoleID, GemID) of
                                                    {true, _} -> true;
                                                    _ -> GemAccIN
                                                end
                                        end
                                    end, false, GemsList);
                              _ ->
                                  AccIn
                          end
                  end
            end, false, lists:seq(1, cfg_gems:get_misc(max_hole))),
    case Status of
        true -> ?GEM_STATUS_CAN_INLAY;
        _    -> ?GEM_STATUS_NO_INLAY
    end.

status_check(RoleID, RoleGemsRec, GemPos, HoleId, GemTypeId) ->
    case is_hole_activated(RoleID, RoleGemsRec, GemPos, HoleId) of
        false -> {error, <<"该部位宝石孔没有开启">>};
        {true, GemHoleRec} ->
            case get_item_num(RoleID, GemTypeId) of
                0 -> {error, <<"您的背包中无该宝石，请先购买宝石！">>};
                _ ->
                     {true, GemHoleRec}
            end
    end.

put_on_gems(RoleID, RoleGemsRec, GemPos, CosumeMoney) ->
    GemsList = cfg_gems:all_gems(GemPos),
    OldHoles = get_gem_pos_holes(RoleGemsRec, GemPos),
    Status =
        lists:foldr(
            fun(GemHoleRec, {AccIn1, Num1, Reason1}) ->
                case GemHoleRec#p_gem_hole.gem_typeid == 0 of
                    true ->
                        HoleID = GemHoleRec#p_gem_hole.id,
                        {PutStatus, HoldNum, HoldReason} = lists:foldr(
                            fun(GemID, {AccIn2, Num2, Reason2}) ->
                                case AccIn2 of
                                    true ->
                                        {AccIn2, Num2, Reason2};
                                    _ ->
                                        {GemInBag, Reason3} = status_check(RoleID, RoleGemsRec, GemPos, HoleID, GemID),
                                        case GemInBag of
                                            true ->
                                                case common_bag2:check_money_enough(silver_any, CosumeMoney * (Num2+1), RoleID) of
                                                    true -> 
                                                        NewGemHoleRec  = GemHoleRec#p_gem_hole{gem_typeid = GemID},
                                                        ok             = mod_bag:use_item(RoleID, GemID, 1, ?LOG_ITEM_TYPE_XIANG_QIAN_SHI_QU),
                                                        RoleGemsRec1 = get_role_gems_info(RoleID),
                                                        Holes          = get_gem_pos_holes(RoleGemsRec1, GemPos),
                                                        NewHoles       = lists:keystore(HoleID, #p_gem_hole.id, Holes, NewGemHoleRec),
                                                        NewRoleGemsRec = set_gem_pos_holes(RoleGemsRec1, GemPos, NewHoles),
                                                        set_role_gems_info(RoleID, NewRoleGemsRec),
                                                        mod_qrhl:send_event(RoleID, baoshi, GemID rem 100),
                                                        {true, Num2+1, Reason2};
                                                    _ -> 
                                                        {AccIn2, Num2, <<"铜币不足,无法镶嵌！">>}
                                                end;
                                            _ ->
                                                case Reason2 of
                                                    undefined ->
                                                        {AccIn2, Num2, Reason3};
                                                    _ -> {AccIn2, Num2, Reason2}
                                                end
                                        end
                                    end
                            end, {false, Num1, Reason1}, GemsList),
                        case PutStatus of
                            true -> {true, HoldNum, HoldReason};
                            _ -> 
                                case AccIn1 of
                                    true -> {AccIn1, Num1, Reason1};
                                    _ -> {AccIn1, HoldNum, HoldReason}
                                end
                        end;
                    _ ->
                        {AccIn1 ,Num1, Reason1}
                end
            end, {false, 0, undefined}, OldHoles),
    Status.

take_off_gems(RoleID, RoleGemsRec, GemPos) ->
    OldHoles = get_gem_pos_holes(RoleGemsRec, GemPos),
    Status =
        lists:foldr(
            fun(GemHoleRec, {AccIn, Reason}) ->
                HoleID = GemHoleRec#p_gem_hole.id,
                case take_off_gems_check(RoleID, RoleGemsRec, GemPos, HoleID) of
                    {error, Reason1} -> 
                        case AccIn orelse GemHoleRec#p_gem_hole.gem_typeid == 0 of
                            true -> {AccIn, Reason};
                            _ ->
                                case Reason of
                                    undefined -> {AccIn, Reason1};
                                    _ ->        {AccIn, Reason}
                            end
                        end;
                    {true, _GemHoleRec} ->
                        GemID = GemHoleRec#p_gem_hole.gem_typeid,
                        LogType        = ?LOG_ITEM_TYPE_CHAI_XIE_HUO_DE,
                        mod_bag:add_items(RoleID, [{GemID, 1, ?TYPE_ITEM, true}], LogType),
                        RoleGemsRec1 = get_role_gems_info(RoleID),
                        Holes          = get_gem_pos_holes(RoleGemsRec1, GemPos),
                        GemHoleRec1    = GemHoleRec#p_gem_hole{gem_typeid = 0},
                        NewHoles       = lists:keystore(HoleID, #p_gem_hole.id, Holes, GemHoleRec1),
                        NewRoleGemsRec = set_gem_pos_holes(RoleGemsRec1, GemPos, NewHoles),
                        set_role_gems_info(RoleID, NewRoleGemsRec),
                        {true, Reason}
                end
            end, {false, undefined}, OldHoles),
    Status.
    
take_off_gems_check(RoleID, RoleGemsRec, GemPos, HoleId) ->
    case is_hole_activated(RoleID, RoleGemsRec, GemPos, HoleId) of
        false -> {error, <<"该宝石孔没有开启">>};
        {true, GemHoleRec} ->
            case GemHoleRec#p_gem_hole.gem_typeid == 0 of
                true -> {error, <<"该部位没有宝石可拆卸">>};
                false ->
                    case mod_bag:get_empty_bag_pos_num(RoleID, 1) of
                        {ok, Num} when Num > 0 -> {true, GemHoleRec};
                        _ -> {error, <<"背包空间不足，无法卸载宝石">>}
                    end
            end
    end.

update_role_base(RoleID, OldRoleGem, NewRoleGem) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    NewRoleBase    = mod_role_attr:calc(RoleBase, 
        '-', gem_attrs(OldRoleGem), '+', gem_attrs(NewRoleGem)),
    mod_role_attr:reload_role_base(NewRoleBase).

recalc(RoleBase, _RoleAttr) ->
    Gem = get_role_gems_info(RoleBase#p_role_base.role_id),
    mod_role_attr:calc(RoleBase, '+', gem_attrs(Gem)).

% get_role_gems_info(RoleID),
hook_gems_skin(RoleID) ->
    Gem = get_role_gems_info(RoleID),
    hook_gems_skin(RoleID, Gem).

hook_gems_skin(RoleID, GemsRec) ->
    #p_role_gems{
        head = Heads,
        body = Bodys,
        wrist = Wrists,
        hand = Hands,
        neck = Necks,
        waist = Waists,
        bracelet = Bracelets,
        foot = Foots
    } = GemsRec,

    AllRoleGems = Heads ++ Bodys ++ Wrists ++ Hands ++ Necks ++ Waists ++ Bracelets ++ Foots,

    QualistList = lists:foldl(fun(H, Acc) ->
        #p_gem_hole{gem_typeid = GemTypeID} = H,
        if
            GemTypeID == 0 -> Acc;
            true -> 
                GemLevel = get_gem_level(GemTypeID),
                % orddict:append(GemLevel, 1, Acc)
                orddict:update_counter(GemLevel, 1, Acc)
        end
    end, orddict:new(), AllRoleGems),

    GemShape = lists:foldl(fun(H, TempNum) ->
        {Level, Num} = H, 
        TempNum1 = cfg_gems:get_gem_shape(Level, Num),
        if
            TempNum < TempNum1 -> TempNum1;
            true -> TempNum
        end
    end, 0, QualistList),

    mgeem_map:send({apply, mod_map_role, 
    do_update_role_skin, [RoleID, [{#p_skin.gem, GemShape}]]}).

 


