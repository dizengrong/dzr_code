%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     宗族变更的相关逻辑
%%%     注意:: 该模块属于mod_family的子模块，只能在mod_family中被调用！
%%% @end
%%% Created : 2011-03-01
%%%-------------------------------------------------------------------
-module(mod_family_change).
-include("mgeew.hrl").
-include("mgeew_family.hrl").


%%降级信件
-define(WARNING_FAMILY_LETTER_TITLE,"家族降级提示").
-define(WARNING_FAMILY_LETTER_CONTENT,).
-define(FAMILY_LEVEL_DOWN_LETTER_CONTENT,).
-define(NPC_ZONG_ZU_GUAN_LI_YUAN,{"11100120","12100120","13100120"}).



%% API
-export([check_owner_duty/0]).
-export([family_maintain_cost/0]).
-export([family_level_down_warning_letter/1,family_level_down_letter/1]).

%% ====================================================================
%% API functions
%% ====================================================================

%%@doc 每日的宗族维护费用
family_maintain_cost() ->
    ?DEBUG("开始家族维护费用",[]),
    State = mod_family:get_state(),
    T =  (State#family_state.family_info)#p_family_info.enable_map,
    ?DEBUG("是否该扣钱:~w",[T]),
    ?DEBUG("是否开启地图:~w",[(State#family_state.family_info)#p_family_info.enable_map]),
    if  T  ->
        family_maintain_cost2();
    true ->
        ignore
    end,
    %%每日判断族长是否离线时间
    mod_family_change:check_owner_duty(),
    case mod_family:get_state() of
        undefined ->
            ignore;
        #family_state{family_info=#p_family_info{family_id=FamilyID}} ->
            MapName = lists:concat(["map_family_", FamilyID]),
            case global:whereis_name(MapName) of
                undefined ->
                    ignore;
                _Pid ->
					todo
                    %%erlang:send(Pid,{mod_map_bonfire,{bonfire_start_time,FamilyID,common_tool:today(H,M,0)}})
            end
    end.

%只有打开了地图的情况下才再次send_after
family_maintain_cost2()->
    ?DEBUG("宗族地图cost2",[]),
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    Level = FamilyInfo#p_family_info.level,
    APToDeduct = mod_family_misc:get_resume_points(Level),
    MoneyToDeduct = mod_family_misc:get_resume_silver(Level),
    CurMoney = FamilyInfo#p_family_info.money,
    CurAp = FamilyInfo#p_family_info.active_points,
    if CurMoney >= MoneyToDeduct ->
        if CurAp >= APToDeduct ->
           family_maintain_cost3();
           true ->
            do_family_maintain_cost_fail(?_LANG_FAMILY_MAINTAIN_FAMILY_AP_NOT_ENOUGH)
        end;
       true ->
        do_family_maintain_cost_fail(?_LANG_FAMILY_MAINTAIN_FAMILY_MONEY_NOT_ENOUGH)
    end.
        

family_maintain_cost3()->
    ?DEBUG("宗族地图cost3",[]),
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    Level = FamilyInfo#p_family_info.level,
    NewMoney = FamilyInfo#p_family_info.money - mod_family_misc:get_resume_silver(Level),
    NewAp = FamilyInfo#p_family_info.active_points - mod_family_misc:get_resume_points(Level),
    NewState = State#family_state{family_info = FamilyInfo#p_family_info{money=NewMoney,active_points=NewAp}},

    ?DEBUG("扣之前:~w  扣之后 ~w  ac扣之前:~w 扣之后:~w",[FamilyInfo#p_family_info.level,
                             NewMoney,FamilyInfo#p_family_info.active_points,NewAp]),

    ?DEBUG("扣之后现状 ~w",[{FamilyInfo#p_family_info.level, NewMoney,FamilyInfo#p_family_info.active_points,NewAp}]),
    R = #m_family_money_toc{
      new_money = NewMoney
     },
    mod_family:broadcast_to_all_members(?FAMILY,?FAMILY_MONEY,R),
    
    APR = #m_family_active_points_toc{
      new_points = NewAp
     },
    mod_family:broadcast_to_all_members(?FAMILY,?FAMILY_ACTIVE_POINTS,APR),
    mod_family_change:family_level_down_warning_letter(NewState),
    mod_family:update_state(NewState).

%%不管怎样,先降级
do_family_maintain_cost_fail(_Reason)->
    ?DEBUG("钱不够,降级逻辑 ~w",[_Reason]),
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    ExtInfo = State#family_state.ext_info,
    #p_family_info{family_id=FamilyID,level=Level} = FamilyInfo,
    ?DEBUG("现在级别 ~w",[Level]),
    %%降级
    if Level > 1 ->
        NewState = State#family_state{family_info=FamilyInfo#p_family_info{level=Level-1},
                                          ext_info=ExtInfo#r_family_ext{last_resume_time = common_tool:now()}},
        ?DEBUG("降级之后状态 ~w",[NewState]),
        Message = lists:concat(["由于你所在的家族所需的日常维护的资金或家族繁荣度不够，你的家族已经降至",Level-1,"级。需要重新升级家族"]),
        mod_family:update_state(NewState);
       %%关闭地图 Level =:= 1 close_map enalbe_map = false
       true ->
        NewFamilyInfo = FamilyInfo#p_family_info{
                  level = 0,
                  enable_map = false,
                  kill_uplevel_boss = false,
                  uplevel_boss_called = false
                 },
        NewExtInfo = ExtInfo#r_family_ext{
               common_boss_killed = false,
               common_boss_called = false,
               last_resume_time = common_tool:now()
              },
        NewState = State#family_state{family_info=NewFamilyInfo,ext_info=NewExtInfo},
        mod_family:update_state(NewState),
            RB = #m_family_map_closed_toc{},
            mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_MAP_CLOSED, RB),
        close_map(FamilyID),
        Message = lists:concat(["由于你所在的家族所需的日常维护的资金或家族繁荣度不够，你的家族已经降至",0,"级。需要重新开启家族地图"])
    end,
    ?ERROR_MSG("~p ~p", [Level, common_config_dyn:find(family_level_reduce, Level) ]),
    %% 降级补偿
    case common_config_dyn:find(family_level_reduce, Level) of
        [] ->
            ignore;
        [#r_family_level_reduce{money=AddMoney, ac=AddAc}] ->
            ?ERROR_MSG("~p ~p", [AddMoney, AddAc]),
            mod_family:do_add_money(AddMoney),
            mod_family:do_add_ac(AddAc)
    end,
    RB2 = #m_family_downlevel_toc{level=Level - 1, reason=""},
    mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_DOWNLEVEL, RB2),
    
    ?DEBUG("宗族msg:~p   ",[Message]),
    mod_family:broadcast_to_family_channel(Message),
    mod_family_change:family_level_down_letter(NewState).


%%@doc 宗族降级的警告信件
family_level_down_warning_letter(State)->
     FamilyInfo = State#family_state.family_info,
     Level = FamilyInfo#p_family_info.level,
     ResumeSilver= mod_family_misc:get_resume_silver(Level),
     ResumePoints= mod_family_misc:get_resume_points(Level),
     FamilyMoney=FamilyInfo#p_family_info.money,
     FamilyPoint=FamilyInfo#p_family_info.active_points,
     ?DEBUG("FMLMONEY:~w  FMLPOINT:~w~n",[FamilyMoney,FamilyPoint]),
     Ding=FamilyMoney div 10000,
     Liang=(FamilyMoney-Ding*10000) div 100,
     Wen = FamilyMoney-Ding*10000-Liang*100,
     ?DEBUG("d~w, l:~w , w:~w~n",[Ding,Liang,Wen]),
     case FamilyMoney>ResumeSilver*3 andalso FamilyPoint>ResumePoints*3 of
         true->ignore;
         _->
             FamilyName=FamilyInfo#p_family_info.family_name,
             RoleList=[FamilyInfo#p_family_info.owner_role_id|lists:map(fun(SecondOwner)-> SecondOwner#p_family_second_owner.role_id end,FamilyInfo#p_family_info.second_owners)],
             lists:foreach(fun(RoleID)->
                                   Title = ?WARNING_FAMILY_LETTER_TITLE,
                                   Content =common_letter:create_temp(?FAMILY_LEVEL_DOWN_WARNING_LETTER,[FamilyName,Ding,Liang,Wen,FamilyPoint,ResumeSilver div 100,ResumePoints]),
                                   ?COMMON_FAMILY_LETTER(RoleID,Content,Title,3)
                           end,RoleList) 
     end.

%%@doc 宗族降级通知信件
family_level_down_letter(State)->
    FamilyInfo = State#family_state.family_info,
    Level = FamilyInfo#p_family_info.level,
    {BackMoney,BackAc}=case common_config_dyn:find(family_level_reduce, Level+1) of
                           [] ->
                               {0,0};
                           [#r_family_level_reduce{money=_BackMoney, ac=_BackAc}] ->
                               {_BackMoney, _BackAc}
                       end,
    FactionID=FamilyInfo#p_family_info.faction_id,
    Tips = case Level>0 of
               true -> 
                   lists:flatten(io_lib:format("返还家族繁荣度~w点和家族资金~w文。",[BackAc,BackMoney]));
               false -> 
                   mod_family:get_text_with_npc("需要重新激活家族地图。\n      激活条件：50元宝、5个在线的家族族员，找<a href=\"event:N|~s\"><font color=\"#FFFF00\"><u>王城—家族管理员</u></font></a>。",FactionID,[?NPC_ZONG_ZU_GUAN_LI_YUAN])
           end,
    RoleList=[{FamilyInfo#p_family_info.owner_role_id,FamilyInfo#p_family_info.owner_role_name}|
                  lists:map(fun(SecondOwner)-> {SecondOwner#p_family_second_owner.role_id,SecondOwner#p_family_second_owner.role_name}end,FamilyInfo#p_family_info.second_owners)],
    lists:foreach(fun({RoleID,RoleName})->
                          Title = ?WARNING_FAMILY_LETTER_TITLE,
                          Content = common_letter:create_temp(?FAMILY_LEVEL_DOWN_LETTER,[RoleName,Level,Tips]),
                          ?COMMON_FAMILY_LETTER(RoleID,Content,Title,5)
                  end,RoleList).



%%@doc 检查族长是否7天内上线
check_owner_duty()->
    State=mod_family:get_state(),
    OwnerRoleID = (State#family_state.family_info)#p_family_info.owner_role_id,
    Members = State#family_state.family_members,
    %%Check1 = lists:any(fun(Member)->Member#p_family_member_info.online=:=true end,Members),
    %%?ERROR_MSG("1 Check1:~w ~n",[Check1]),
    Check2 = length(Members)>1,
    if Check2  ->
           case lists:keyfind(OwnerRoleID, #p_family_member_info.role_id, Members) of
               false->
                   none;
               MemberInfo->
                   #p_family_member_info{online=Online,role_id=RoleID} = MemberInfo,
                   if Online =:=false ->
                          Now=common_tool:now(),
                          LastOfflineTime1 =case common_misc:get_dirty_role_ext(RoleID) of
                                {ok,RoleExt}->#p_role_ext{last_offline_time=LastOfflineTime} = RoleExt,
                                              LastOfflineTime;
                                _->0
                             end,
                          %%调试 去掉 24*60*
                           if Now-7*24*60*60>LastOfflineTime1 ->
                                 %%换族长
                                 change_family_owner();
                             Now-6*24*60*60>LastOfflineTime1->
                                 %%发警告信
                                 send_fire_warning_owner_letter();
                             true->
                                 ignore
                          end;
                      true->ignore
                   end
           end;
       true->ignore
    end.

%%@doc 更好宗族的族长人选
change_family_owner()->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    OwnerID = FamilyInfo#p_family_info.owner_role_id,
    Members = State#family_state.family_members,
    SecondOwners = FamilyInfo#p_family_info.second_owners,
    %%从副族长中获取符合条件的人
    {SOwnerInfo,_} =
        case  SecondOwners of
            [H|_] when is_record(H,p_family_second_owner) ->
                get_owner_from_second_owners(SecondOwners,Members);
            _->{none,0}
        end,
    {OwnerInfo1,SecondOwners1} = 
        case SOwnerInfo of
            none->
                %%从族员中获取符合条件的人
                {NewOwnerInfo,_} = get_owner_from_members(Members),
                {NewOwnerInfo,SecondOwners};
            _-> 
                NewSecondOwners=lists:delete(
                                  lists:keyfind(
                                    SOwnerInfo#p_family_member_info.role_id, 
                                    #p_family_second_owner.role_id, 
                                    SecondOwners), 
                                  SecondOwners),
                {SOwnerInfo,NewSecondOwners}
        end,
    ?DEBUG("NewOwnerInfo1:~w~n",[OwnerInfo1]),
    ?DEBUG("NewSecondOwners1:~w~n",[SecondOwners1]),
    %%组装数据，更新数据，通知前端
    if OwnerInfo1=/=none andalso OwnerID=/=OwnerInfo1#p_family_member_info.role_id ->
           OldOwnerInfo = lists:keyfind(OwnerID, #p_family_member_info.role_id,Members),
           Members1=[OldOwnerInfo#p_family_member_info{title=?DEFAULT_FAMILY_MEMBER_TITLE}|lists:delete(OldOwnerInfo,Members)],
           Members2=[OwnerInfo1#p_family_member_info{title=?FAMILY_TITLE_OWNER}|lists:delete(OwnerInfo1,Members1)],
           #p_family_member_info{role_id=NewOwnerID,role_name=NewOwnerName}=OwnerInfo1,
           NewFamilyInfo =  FamilyInfo#p_family_info{second_owners=SecondOwners1,
                                                     owner_role_id=NewOwnerID,
                                                     owner_role_name=NewOwnerName,
                                                     members=Members2},
           NewState = State#family_state{family_info=NewFamilyInfo,
                                         family_members=Members2},
           %%发解雇信
           send_fire_owner_letter(NewOwnerName),
           %%修改数据
           mod_family:update_state(NewState),
           %%发送广播
           Message =lists:flatten(io_lib:format("[~s] 成为了家族族长",[NewOwnerName])),
           mod_family:broadcast_to_family_channel(Message),
           %%推送取消副族长数据
           if SOwnerInfo=/=none ->
                  R1 = #m_family_unset_second_owner_toc{role_id=NewOwnerID,return_self=false},
                  mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_UNSET_SECOND_OWNER, R1);
              true->ignore
           end,
           %%推送设置族长数据
           R = #m_family_set_owner_toc{role_id=NewOwnerID,return_self=false},
           mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_SET_OWNER, R),
           %%修改称号 
           common_title_srv:add_title(?TITLE_FAMILY,NewOwnerID,?FAMILY_TITLE_OWNER),
           common_title_srv:add_title(?TITLE_FAMILY, OwnerID, ?DEFAULT_FAMILY_MEMBER_TITLE);
       true->
           ignore
    end.

send_fire_warning_owner_letter()->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    OwnerName = FamilyInfo#p_family_info.owner_role_name,
    FamilyName = FamilyInfo#p_family_info.family_name,
    OwnerID =FamilyInfo#p_family_info.owner_role_id,
    Title = "来自宗族的信件",
    Content = common_letter:create_temp(?FAMILY_FIRE_OWNER_WARNING_LETTER,[OwnerName,FamilyName]),
    ?COMMON_FAMILY_LETTER(OwnerID, Content, Title, 14).
    
send_fire_owner_letter(NewOwnerName)->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    OwnerName = FamilyInfo#p_family_info.owner_role_name,
    FamilyName = FamilyInfo#p_family_info.family_name,
    OwnerID =FamilyInfo#p_family_info.owner_role_id,
    Title = "族长身份被取消通知",
    Content = common_letter:create_temp(?FAMILY_FIRE_OWNER_LETTER,[OwnerName,NewOwnerName,FamilyName]),
    ?COMMON_FAMILY_LETTER(OwnerID, Content, Title, 14).

get_owner_from_second_owners(SOwners,Members)->
    lists:foldl(
      fun(SOwner,{SOwnerInfo,Contribute})->
              NewSOwnerID=SOwner#p_family_second_owner.role_id,
              case if_member_fit(NewSOwnerID,Members) of
                  none->
                      {SOwnerInfo,Contribute};
                  NewSOwnerInfo->
                      NewContribute=NewSOwnerInfo#p_family_member_info.family_contribution,
                      if NewContribute>=Contribute ->
                             {NewSOwnerInfo,NewContribute};
                         true->
                             {SOwnerInfo,Contribute}
                      end   
              end
      end ,{none,0},SOwners).

get_owner_from_members(Members)->
    lists:foldl(fun(NewOwnerInfo,{OwnerInfo,Contribute})->
                        case if_member_fit(NewOwnerInfo) of
                            none->{OwnerInfo,Contribute};
                            _->
                                NewContribute=NewOwnerInfo#p_family_member_info.family_contribution,
                                if NewContribute>=Contribute ->
                                       {NewOwnerInfo,NewContribute};
                                   true->{OwnerInfo,Contribute}
                                end
                        end
                end,{none,0},Members).

if_member_fit(RoleID,People)->
     case lists:keyfind(RoleID, #p_family_member_info.role_id, People) of
        false->
            none;
        MemberInfo->
            if_member_fit(MemberInfo)
    end.

if_member_fit(MemberInfo)->
    #p_family_member_info{role_id=RoleID,online=Online} = MemberInfo,
    if Online =:=false ->
           Now=common_tool:now(),
           LastOfflineTime1 =case common_misc:get_dirty_role_ext(RoleID) of
                                {ok,RoleExt}->#p_role_ext{last_offline_time=LastOfflineTime} = RoleExt,
                                              LastOfflineTime;
                                _->0
                             end,
           %%调试
           if Now-LastOfflineTime1<7*24*60*60 ->
                  MemberInfo;
              true->
                  none
           end;
       true->MemberInfo
    end.

%%先弹出用户,在关掉地图进程
close_map(FamilyID)->
    common_family:kick_member_in_map_online(FamilyID),
    common_map:family_info(FamilyID, kill_family_map).
