%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 功勋值计算
%%%
%%% @end
%%% Created : 10 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_gongxun).

-include("mgeem.hrl").

%% API
-export([change/7, add_gongxun/2, reduce_gongxun/3]).

-define(last_add_gongxun_time, last_add_gongxun_time).

-define(ADD_GONGXUN_INTERVAL, 30 * 60).
-define(ADD_GONGXUN_NOTICE, "你获得~w点战功").
-define(REDUCE_GONGXUN_NOTICE, "你失去了~w点战功").

%% RoleID 被杀者
%% SrcRoleID 杀人者
change(RoleID, FactionID, _FamilyID, SRoleID, SFactionID, SFamilyID, Flag) ->
    
    {ok, #p_role_attr{level=Level}}  = mod_map_role:get_role_attr(RoleID),
    {ok, #p_role_attr{level=SLevel}} = mod_map_role:get_role_attr(SRoleID),
    MapId = mgeem_map:get_mapid(),
    case FactionID =:= SFactionID orelse Flag =:= true orelse MapId =:= ?COUNTRY_TREASURE_MAP_ID of
        false ->
            
            %%判断是否超过上次杀害同一人而增加功勋的时间 30分钟以上
            case get({?last_add_gongxun_time, {SRoleID, RoleID}}) of
                undefined ->
                    GongxunMul = get_mul(SRoleID, FactionID, SFactionID,Level,SLevel),
                    do_add_gongxun(RoleID, Level, SRoleID, SLevel, SFamilyID, GongxunMul),
                    ok;
                LastAddTime ->
                    case common_tool:now() - LastAddTime > ?ADD_GONGXUN_INTERVAL of
                        true ->
                            GongxunMul = get_mul(SRoleID, FactionID, SFactionID,Level,SLevel),
                            do_add_gongxun(RoleID, Level, SRoleID, SLevel, SFamilyID, GongxunMul),
                            ok;
                        false ->
                            %%do_add_gongxun(RoleID, Level, SRoleID, SLevel, SFamilyID, GongxunMul),
                            ignore
                    end
            end,
            
            do_reduce_gongxun(RoleID, Level, SRoleID, SLevel, FactionID, MapId),
            ok;
        _ ->
            ignore
    end.

%% @doc 增加功勋
add_gongxun(RoleID, Add) ->
    case common_transaction:transaction(
           fun() ->
                   {ok, #p_role_attr{gongxun=G}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   mod_map_role:set_role_attr(RoleID, RoleAttr#p_role_attr{gongxun=G+Add}),
                   {G, G+Add, RoleAttr}
           end)
    of
        {atomic, {Value, NewValue, RoleAttr}} ->
            %%通知前端属性变化
            RR = #m_role2_attr_change_toc{roleid=RoleID, 
                                          changes=[#p_role_attr_change{change_type=?ROLE_GONGXUN_CHANGE, 
                                                                       new_value=NewValue}
                                                  ]},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, RR),
            
            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
            #p_role_base{role_id=RoleID,faction_id=FactionID,family_name=FamilyName} = RoleBase,
            #p_role_attr{role_name=RoleName,level=Level,exp=Exp} = RoleAttr,
            
            RankSendInfo2 = get_rank_send_info(RoleID,RoleAttr,NewValue),
            common_rank:update_element(ranking_role_gongxun,RankSendInfo2),
            common_rank:update_element(ranking_role_today_gongxun,{add,Add,RoleID,RoleName,Level,Exp,FactionID,FamilyName}),       
            
            Notice = io_lib:format(?ADD_GONGXUN_NOTICE, [NewValue-Value]),
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(Notice)),
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["增加角色功勋值失败", Error])
    end.

get_rank_send_info(RoleID,RoleAttr,NewGongXun)->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{faction_id=FactionID,family_name=FamilyName} = RoleBase,
    #p_role_attr{role_name=RoleName,level=Level,exp=Exp} = RoleAttr,
    
    {RoleID,RoleName,Level,Exp,NewGongXun,FactionID,FamilyName}.

get_mul(SRoleID, FactionID, SFactionID,Level,SLevel) ->
    [KillerRoleState] = db:dirty_read(?DB_ROLE_STATE, SRoleID),
    KillerShouBianState = KillerRoleState#r_role_state.shou_bian,
    
    {ok, KillerRoleBase} = mod_map_role:get_role_base(SRoleID),
    KillerRoleNameStr = common_tool:to_list(KillerRoleBase#p_role_base.role_name),
    %%守边获得双倍战功
    if
        KillerShouBianState =:= 1 andalso FactionID =/= SFactionID ->
            %%有战功才有广播
            case Level < 40 orelse (SLevel > Level andalso SLevel-Level > 5) of
                false ->
                    common_broadcast:bc_send_msg_world(
                        ?BC_MSG_TYPE_CENTER, 
                        ?BC_MSG_SUB_TYPE, 
                         common_misc:format_lang(?_LANG_MISSION_SHOU_BIAN_MUL_GONGXUN, [KillerRoleNameStr]));
                true ->
                    ignore
            end,
            2;
         true ->
            1
    end.
    
%% @doc 减少功勋
reduce_gongxun(RoleID, Reduce, Type) ->
    case common_transaction:transaction(
           fun() ->
                   {ok, #p_role_attr{gongxun=G}=RoleAttr} = mod_map_role:get_role_attr(RoleID),

                   case G-Reduce >= 0 of
                       true ->
                           G2 = G - Reduce;
                       _ ->
                           G2 = 0
                   end,
                   
                   mod_map_role:set_role_attr(RoleID, RoleAttr#p_role_attr{gongxun=G2}),
                   {G, G2, RoleAttr}
           end)
    of
        {atomic, {Value, NewValue, RoleAttr}} ->
            case Value =:= NewValue of
                true ->
                    ok;
                _ ->
                    %%通知前端属性变化
                    RR = #m_role2_attr_change_toc{roleid=RoleID, 
                                                  changes=[#p_role_attr_change{change_type=?ROLE_GONGXUN_CHANGE, 
                                                                               new_value=NewValue}
                                                          ]},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, RR),
                    
                    RankSendInfo2 = get_rank_send_info(RoleID,RoleAttr,NewValue),
                    common_rank:update_element(ranking_role_gongxun,RankSendInfo2),
                    case Type of
                        dead ->
                            common_rank:update_element(ranking_role_today_gongxun,{reduce,Reduce,RoleID});
                        _ ->
                            ignore
                    end,
                    Notice = io_lib:format(?REDUCE_GONGXUN_NOTICE, [Value-NewValue]),
                    common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(Notice)),
                    ok
            end;
        {aborted, Error} ->
            ?ERROR_MSG("do_reduce_gongxun, error: ~w", [Error])
    end.


%% SrcRoleID 是杀人者
do_add_gongxun(RoleID, Level, SrcRoleID, SrcLevel, FamilyID, GongxunMul) ->
    %%杀死40级以下玩家或低于自身5级以上的玩家不获战功
    case Level < 40 orelse (SrcLevel > Level andalso SrcLevel-Level > 5) of
        false ->
            case Level >= SrcLevel of
                true ->
                    Add = 20 * GongxunMul;
                _ ->
                    Add = 10 * GongxunMul
            end,

            %% 国战期间加功勋
            do_add_waroffaction_gongxun(RoleID, SrcRoleID),

            common_family:info(FamilyID, {add_gongxun, Add}),
            put({?last_add_gongxun_time, {SrcRoleID, RoleID}}, common_tool:now()),
            
            add_gongxun(SrcRoleID, Add);
        true ->
            ignore
    end,
    ok.

%% @doc 国战期间攻击方或防守方杀人给周围同国的人加功勋
do_add_waroffaction_gongxun(RoleID, SRoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        
        RoleMapInfo ->
            #p_map_role{pos=Pos, faction_id=FactionID} = RoleMapInfo,
            case mod_map_role:is_in_waroffaction(FactionID) of
                true ->
                    case mod_map_actor:get_actor_mapinfo(SRoleID, role) of
                        undefined ->
                            ignore;
                        
                        SRoleMapInfo ->
                            #p_pos{tx=TX, ty=TY} = Pos,
                            do_add_waroffaction_gongxun2(SRoleMapInfo, TX, TY)
                    end;
                _ ->
                    ignore
            end
    end.

do_add_waroffaction_gongxun2(SRoleMapInfo, TX, TY) ->
    #p_map_role{faction_id=FactionID} = SRoleMapInfo,
    %%
    case mod_map_role:is_in_waroffaction(FactionID) of
        true ->
            #map_state{offsetx=OffsetX, offsety=OffsetY} = mgeem_map:get_state(),
            AllSlice = mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY),
            RoleIDList = mgeem_map:get_all_in_sence_user_by_slice_list(AllSlice),
            
            [AllZgv] = common_config_dyn:find(faction_war, fac_war_die_zg), 
            AllPerson =lists:foldl(
                         fun(RoleID,Sum) ->
                                case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                                     #p_map_role{faction_id=FactionID} ->
                                         Sum+1;
                                      _ ->
                                         Sum
                                end
                        end,0,RoleIDList),

            case round(AllZgv/AllPerson)>0 of
                true ->
                    AveGongxun = round(AllZgv/AllPerson);
                false ->
                    AveGongxun =1
            end,
            ?DEBUG("~w个人，每人获得战功~w~n",[AllPerson,AveGongxun]),
            lists:foreach(
              fun(RoleID) ->
                      case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                          #p_map_role{faction_id=FactionID} ->
                              add_gongxun(RoleID, AveGongxun);
                          _ ->
                              ignore
                      end
              end, RoleIDList);
        _ ->
            ignore
    end.

%%被外国玩家减战功
%%被等级大于自己的玩家杀死扣1点，被小于自己等级1－5级的玩家杀玩扣2点，其它3点
do_reduce_gongxun(RoleID, Level, _SRoleID, SLevel, FactionID, MapID) ->
    %% 在本国被杀不扣战功
    case common_misc:if_in_self_country(FactionID, MapID) of
        true ->
            ignore;
        _ ->
            if
                SLevel >= Level ->
                    Reduce = 5;
                Level-SLevel =< 5 ->
                    Reduce = 10;
                true ->
                    Reduce = 15
            end,

            case mod_waroffaction:check_in_waroffaction_time() of
                true ->
                    ignore;
                false ->
                    reduce_gongxun(RoleID, Reduce, dead)
            end
    end.
