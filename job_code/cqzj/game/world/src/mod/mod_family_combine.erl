%%%-------------------------------------------------------------------
%%% @author fangshaokong 
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     家族合并模块
%%%     注意:: 该模块属于mod_family的子模块，只能在mod_family中被调用！
%%% @end
%%% Created : 2011-03-16
%%%-------------------------------------------------------------------
-module(mod_family_combine).
-include("mgeew.hrl").
-include("mgeew_family.hrl").

%% API
-export([do_handle_info/1]).
-export([method_list/0,msg_tag/0]).

%% ====================================================================
%% API functions
%% ====================================================================

%% 宏定义要求同样的命名规约
-define(SEND_ERROR_TOC(RecName,Reason),        
        R2 = #RecName{succ=false,reason=Reason},common_misc:unicast2(PID, Unique, Module, Method, R2)
       ).
-define(SEND_COMBINE_REQUEST_ERR_TOC(RoleID,Reason),        
        R2 = #m_family_combine_request_toc{succ=false,reason=Reason},
        common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE_REQUEST, R2)
       ).
-define(SEND_COMBINE_ERR_TOC(RoleID,Reason),        
        R2 = #m_family_combine_toc{succ=false,reason=Reason},
        common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE, R2)
       ).

-define(COMBINE_FAMILY_LETTER_TITLE,"并入家族 <font color=\"#3be450\">~s</font>的通知").

%% 合并信息
-define(COMBINE_FAMILY,combine_family).

method_list()->
    [?FAMILY_COMBINE_PANEL,
     ?FAMILY_COMBINE_REQUEST,
     ?FAMILY_COMBINE
    ].

msg_tag()->
    [family_map_roles,
     family_combine_response,
     family_combined_dismiss,
     update_family_state
    ].

do_handle_info({Unique, Module, ?FAMILY_COMBINE_PANEL, Record, RoleID, PID, _Line}) ->
    do_combine_panel(Unique, Module, ?FAMILY_COMBINE_PANEL, Record, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_COMBINE_REQUEST, Record, RoleID, PID, _Line}) ->
    do_combine_request(Unique, Module, ?FAMILY_COMBINE_REQUEST, Record, RoleID, PID);
do_handle_info({_Unique, _Module, ?FAMILY_COMBINE, Record, ResponseRoleID, _PID, _Line}) ->
    do_combine_reponse(Record, ResponseRoleID);
do_handle_info({family_map_roles,MapRoles,CombineTerm}) ->
    check_family_map_roles(MapRoles,CombineTerm);
do_handle_info({family_combine_response, RequestRoleID, Confirm, ResponseRoleID, SrcFamilyInfo}) ->
    family_combine_response(RequestRoleID, Confirm, ResponseRoleID, SrcFamilyInfo);
do_handle_info({update_family_state,CombineFamily,TargetFamily}) ->
    update_family_state(CombineFamily,TargetFamily);
do_handle_info({family_combined_dismiss,FamilyID}) ->
    mod_family:update_state(false),
    hook_family:delete(FamilyID),
    exit(self(), normal);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知信息", Info]).

do_combine_panel(Unique, Module, Method, _Record, RoleID, PID)->
    case catch check_do_combine_panel(RoleID) of
        {ok,FamilyInfo,TeammateFamilyInfo} ->
            #p_family_info{family_id=FamilyID1,family_name=FamilyName1} = FamilyInfo,
            #p_family_info{family_id=FamilyID2,family_name=FamilyName2} = TeammateFamilyInfo,
            DataRecord = #m_family_combine_panel_toc{family_id_1=FamilyID1,family_name_1=FamilyName1,
                                                     family_id_2=FamilyID2,family_name_2=FamilyName2},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord);
        {error,not_auth} ->
            ?SEND_ERROR_TOC(m_family_combine_panel_toc,?_LANG_FAMILY_COMBINE_NOT_AUTH_ERROR);
        {error,err_distance} ->
            ?SEND_ERROR_TOC(m_family_combine_panel_toc,?_LANG_FAMILY_COMBINE_NPC_RANGE);
        {error,not_leader} ->
            ?SEND_ERROR_TOC(m_family_combine_panel_toc,?_LANG_FAMILY_COMBINE_NOT_LEADER_ERROR);
        Error ->
            ?ERROR_MSG("打开家族合并窗口出错:~w",[Error])
    end.

check_do_combine_panel(RoleID) ->
    [RoleBase] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    #p_role_base{team_id=TeamID} = RoleBase,
    case global:whereis_name(common_misc:get_team_proccess_name(TeamID)) of %%队伍是否存在
        true ->
            ?ERROR_MSG("~ts",["组队重构过，在这里不可以获得队员的列表，这里修改为只要组队就可以"]),
            ok;
        false ->
            throw({error,not_auth})
    end.
do_combine_request(Unique, Module, Method, Record, RoleID, PID)->
    #m_family_combine_request_tos{target_family_id=TargetFamilyID} = Record,
    TeammateHasConfirm = false,
    case catch check_do_combine_request(TeammateHasConfirm,TargetFamilyID, RoleID) of
        {error,repeat_request} ->
            ?SEND_ERROR_TOC(m_family_combine_request_toc,?_LANG_FAMILY_COMBINE_REPEAT_REQUEST);
        {error,join_warofking,FamilyName} ->
            ?SEND_ERROR_TOC(m_family_combine_request_toc,io_lib:format(?_LANG_FAMILY_COMBINE_ERROR_WHEN_JOIN_WAROFKING,[common_tool:to_list(FamilyName)]));
        {error,members_full} ->
            ?SEND_ERROR_TOC(m_family_combine_request_toc,?_LANG_FAMILY_COMBINE_FULL_MEMBERS_ERROR);
        {error,not_auth} ->
            ?SEND_ERROR_TOC(m_family_combine_request_toc,?_LANG_FAMILY_COMBINE_NOT_AUTH_ERROR);
        {error,ybc_doing,FamilyName} ->
            ?SEND_ERROR_TOC(m_family_combine_request_toc,io_lib:format(?_LANG_FAMILY_COMBINE_YBC_DOING_ERROR,[common_tool:to_list(FamilyName)]));
        {error,ybc_publishing,FamilyName} ->
            ?SEND_ERROR_TOC(m_family_combine_request_toc,io_lib:format(?_LANG_FAMILY_COMBINE_YBC_PUBLISHING_ERROR,[common_tool:to_list(FamilyName)]));
        next ->
            ingore;
        {ok,CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo} ->
            send_combine_request(CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo);
        Error ->
            ?ERROR_MSG("合并家族出错:~s",[Error])
    end.

check_do_combine_request(TeammateHasConfirm, TargetFamilyID, RoleID) ->
    case catch check_do_combine_panel(RoleID) of
        {ok, FamilyInfo, TeammateFamilyInfo} ->
            #p_family_info{family_id=LeaderFamilyID,level=Level,cur_members=CurMembers} = FamilyInfo,
            #p_family_info{family_id=TeammateFamilyID,owner_role_id=TeammateOwnerRoleID,level=TeammateLevel,
                           cur_members=TeammateCurMembers} = TeammateFamilyInfo,
            case check_repeat_request(TeammateOwnerRoleID,TeammateHasConfirm) of
                true ->
                    throw({error,repeat_request});
                false ->
                    {MaxMember,CombineFamily,TargetFamily} = if
                                                                 TargetFamilyID =:= LeaderFamilyID ->
                                                                     {mod_family:get_max_member(Level),TeammateFamilyInfo,FamilyInfo};
                                                                 TargetFamilyID =:= TeammateFamilyID ->
                                                                     {mod_family:get_max_member(TeammateLevel),FamilyInfo,TeammateFamilyInfo};
                                                                 true ->
                                                                     ?ERROR_MSG("RoleID:~w,TargetFamilyID:~w illegal",[RoleID,TargetFamilyID]),
                                                                     throw({error,illegal})
                                                             end,
                    case (TeammateCurMembers + CurMembers) > MaxMember of
                        true ->
                            throw({error,members_full});
                        false ->
                            check_do_combine_request2(TeammateHasConfirm,CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo)
                    end
            end;
        {error,_} ->
            throw({error,not_auth})
    end.

check_repeat_request(TeammateRoleID,TeammateHasConfirm) ->
    case TeammateHasConfirm of
        false ->
            case get(?COMBINE_FAMILY) of
                {DictTeammateRoleID,_DictTargetFamilyID} ->
                    DictTeammateRoleID =:= TeammateRoleID;
                _Other ->
                    false
            end;
        true ->
            false
    end.

check_do_combine_request2(TeammateHasConfirm,CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo) ->
    #p_family_info{ybc_status=CombineYbcStatus,faction_id=CombineFactionID,family_id=CombineFamilyID,enable_map=CombineEnableMap,family_name=CombineFamilyName} = CombineFamily,
    #p_family_info{ybc_status=TargetYbcStatus,family_name=TargetFamilyName} = TargetFamily,
    IsBeginWar = common_warofking:is_begin_war(CombineFactionID),
    if
        IsBeginWar =:= true ->
            throw({error,join_warofking,CombineFamilyName});
        CombineYbcStatus =:= ?FAMILY_YBC_STATUS_DOING -> 
            throw({error,ybc_doing,CombineFamilyName});
        CombineYbcStatus =:= ?FAMILY_YBC_STATUS_PUBLISHING -> 
            throw({error,ybc_publishing,CombineFamilyName});
        TargetYbcStatus =:= ?FAMILY_YBC_STATUS_DOING ->
            throw({error,ybc_doing,TargetFamilyName});
        TargetYbcStatus =:= ?FAMILY_YBC_STATUS_PUBLISHING ->
            throw({error,ybc_publishing,TargetFamilyName});
        true ->
            if
                CombineEnableMap =:= true -> %%有家族地图
                    %%查看家族地图是否有玩家
                    CombineTerm = {TeammateHasConfirm,CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo},
                    common_map:family_info(CombineFamilyID,{family_map_roles,self(),CombineTerm}),
                    next;
                true ->
                    {ok,CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo}
            end
    end.

check_family_map_roles(MapRoles,CombineTerm) ->
    {TeammateHasConfirm,CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo} = CombineTerm,
    #p_family_info{family_name=CombineFamilyName,owner_role_id=CombineOwnerRoleID} = CombineFamily,
    #p_family_info{owner_role_id=OwnerRoleID} = FamilyInfo,
    #p_family_info{owner_role_id=TargetOwnerRoleID} = TargetFamily,
    if TeammateHasConfirm =:= false ->
            case erlang:length(MapRoles) > 0 of
                true ->
                    DataRecord = #m_family_combine_request_toc{succ=false,reason=io_lib:format(?_LANG_FAMILY_COMBINE_MAP_EXIST_ROLES_ERROR,[common_tool:to_list(CombineFamilyName)])},
                    common_misc:unicast({role, OwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE_REQUEST, DataRecord);
                false ->
                    send_combine_request(CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo)
            end;
       true ->
            case erlang:length(MapRoles) > 0 of
                true ->
                    DataRecord = #m_family_combine_toc{succ=false,reason=io_lib:format(?_LANG_FAMILY_COMBINE_MAP_EXIST_ROLES_ERROR,[common_tool:to_list(CombineFamilyName)])},
                    common_misc:unicast({role, TargetOwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE, DataRecord),
                    common_misc:unicast({role, CombineOwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE, DataRecord);
                false ->
                    family_combine_finish(CombineFamily,TargetFamily)
            end
    end.

send_combine_request(CombineFamily,TargetFamily,FamilyInfo,TeammateFamilyInfo) ->
    #p_family_info{owner_role_id=OwnerRoleID} = FamilyInfo,
    #p_family_info{family_name=TeammateFamilyName,owner_role_id=TeammateOwnerRoleID,owner_role_name=TeammateOwnerRoleName} = TeammateFamilyInfo,
    #p_family_info{family_name=CombineFamilyName} = CombineFamily,
    #p_family_info{family_id=TargetFamilyID,family_name=TargetFamilyName} = TargetFamily,
    ReasonSelf = io_lib:format(?_LANG_FAMILY_COMBINE_REQUEST_SUCC,[common_tool:to_list(TeammateFamilyName),common_tool:to_list(TeammateOwnerRoleName)]),
    DataRecordSelf = #m_family_combine_request_toc{return_self=true,reason=ReasonSelf},
    common_misc:unicast({role, OwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE_REQUEST, DataRecordSelf),
    Reason = io_lib:format(?_LANG_FAMILY_COMBINE_REQUEST_MSG,[common_tool:to_list(CombineFamilyName),common_tool:to_list(TargetFamilyName),common_tool:to_list(CombineFamilyName)]),
    DataRecord = #m_family_combine_request_toc{return_self=false,reason=Reason,request_role_id=OwnerRoleID},
    common_misc:unicast({role, TeammateOwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE_REQUEST, DataRecord),
    erlang:put(?COMBINE_FAMILY,{TeammateOwnerRoleID,TargetFamilyID}).

do_combine_reponse(Record, ResponseRoleID)->
    #m_family_combine_tos{confirm=Confirm,request_role_id=RequestRoleID} = Record,
    [RoleBase] = db:dirty_read(?DB_ROLE_BASE, RequestRoleID),
    #p_role_base{family_id=FamilyID} = RoleBase,
    State = mod_family:get_state(),
    FamilyInfo = (State#family_state.family_info)#p_family_info{members=State#family_state.family_members},
    common_family:info(FamilyID, {family_combine_response,RequestRoleID,Confirm,ResponseRoleID, FamilyInfo}).

family_combine_response(RequestRoleID, Confirm, ResponseRoleID, ResponseFamilyInfo) ->
    case Confirm of
        true ->
            TeammateHasConfirm = true,
            case get(?COMBINE_FAMILY) of
                {TeammateOwnerRoleID, TargetFamilyID} ->
                    case TeammateOwnerRoleID =:= ResponseRoleID of
                        true -> %%判断是否有发过邀请
                            State = mod_family:get_state(),
                            RequestFamilyInfo = (State#family_state.family_info)#p_family_info{members=State#family_state.family_members},
                            case TargetFamilyID =:= RequestFamilyInfo#p_family_info.family_id of
                                true ->
                                    TargetFamilyInfo = RequestFamilyInfo,
                                    CombineFamily = ResponseFamilyInfo;
                                false ->
                                    TargetFamilyInfo = ResponseFamilyInfo,
                                    CombineFamily = RequestFamilyInfo
                            end,
                            case catch check_do_combine_request(TeammateHasConfirm, TargetFamilyID, RequestRoleID) of
                                {error,join_warofking,FamilyName} ->
                                    ?SEND_COMBINE_ERR_TOC(ResponseRoleID,
                                                          io_lib:format(?_LANG_FAMILY_COMBINE_ERROR_WHEN_JOIN_WAROFKING,
                                                                        [common_tool:to_list(FamilyName)]));
                                {error,members_full} ->
                                    ?SEND_COMBINE_ERR_TOC(ResponseRoleID,?_LANG_FAMILY_COMBINE_FULL_MEMBERS_ERROR);
                                {error,not_auth} ->
                                    ?SEND_COMBINE_ERR_TOC(ResponseRoleID,?_LANG_FAMILY_COMBINE_NOT_AUTH_ERROR);
                                {error,ybc_doing,FamilyName} ->
                                    ?SEND_COMBINE_ERR_TOC(ResponseRoleID,
                                                          io_lib:format(?_LANG_FAMILY_COMBINE_YBC_DOING_ERROR,
                                                                        [common_tool:to_list(FamilyName)]));
                                {error,ybc_publishing,FamilyName} ->
                                    ?SEND_COMBINE_ERR_TOC(ResponseRoleID,
                                                          io_lib:format(?_LANG_FAMILY_COMBINE_YBC_PUBLISHING_ERROR,
                                                                        [common_tool:to_list(FamilyName)]));
                                next ->
                                    ingore;
                                {ok, _CombineFamily, _TargetFamily, _FamilyInfo, _TeammateFamilyInfo} ->
                                    family_combine_finish(CombineFamily, TargetFamilyInfo);
                                Error ->
                                    ?ERROR_MSG("合并家族出错:~p",[Error])
                            end;
                        false ->
                            ?SEND_COMBINE_ERR_TOC(ResponseRoleID,?_LANG_FAMILY_COMBINE_HAS_INVALID)
                    end;
                undefined ->
                    ?SEND_COMBINE_ERR_TOC(ResponseRoleID,?_LANG_FAMILY_COMBINE_HAS_INVALID)
            end;		
        false -> 
            ?SEND_COMBINE_ERR_TOC(RequestRoleID,?_LANG_FAMILY_COMBINE_NOT_AGREE)
    end,
    %%无论如何，只要响应，删除进程字典
    erase(?COMBINE_FAMILY).

family_combine_finish(CombineFamily,TargetFamily) ->
    #p_family_info{family_id=CombineFamilyID,owner_role_id=CombineOwnerRoleID,family_name=CombineFamilyName,members=CombineMembers} = CombineFamily,
    #p_family_info{family_id=TargetFamilyID,owner_role_id=TargetOwnerRoleID,family_name=TargetFamilyName} = TargetFamily,
    case db:transaction(fun() -> t_combine_finish(CombineFamily,TargetFamily) end) of
        {atomic, _} ->
            RDismiss = #m_family_dismiss_toc{},
            common_misc:unicast({role, CombineOwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_DISMISS, RDismiss),
            lists:foreach(
              fun(#p_family_member_info{role_id=RoleID,role_name=RoleName,role_level=RoleLevel}) ->
                      mod_family:notify_world_update(RoleID, TargetFamily),
                      common_title_srv:remove_by_typeid(?TITLE_FAMILY,RoleID),
                      hook_family_change:hook(change, {RoleID, 0, CombineFamilyID}),
                      hook_family_change:hook(change, {RoleID, TargetFamilyID, CombineFamilyID}),
                      hook_family:hook_family_changed({TargetFamilyID,RoleID}),
                      common_title_srv:add_title(?TITLE_FAMILY,RoleID,?DEFAULT_FAMILY_MEMBER_TITLE),
                      mod_family:join_family_for_role(RoleID,RoleName,TargetFamilyName,RoleLevel)
              end, CombineMembers),
            %%更新新家族状态
            common_family:info(TargetFamilyID, {update_family_state,CombineFamily,TargetFamily}),
            %%通知被合并家族解散
            common_family:info(CombineFamilyID, {family_combined_dismiss,CombineFamilyID}),
            BroadCastMsg = io_lib:format(?_LANG_FAMILY_COMBINE_SUCC_BROADCAST,
                                         [common_tool:to_list(CombineFamilyName),common_tool:to_list(TargetFamilyName)]),
            common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT_WORLD,BroadCastMsg),
            common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_WORLD,BroadCastMsg),
            RSucc = #m_family_combine_toc{reason=io_lib:format(?_LANG_FAMILY_COMBINE_SUCC,
                                                               [common_tool:to_list(CombineFamilyName),common_tool:to_list(TargetFamilyName)])},
            common_misc:unicast({role, CombineOwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE, RSucc),
            common_misc:unicast({role, TargetOwnerRoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_COMBINE, RSucc),
            hook_family:combine(CombineFamily,TargetFamily);
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    ?ERROR_MSG("~ts:~w", ["合并家族出错", Error]),
                    Reason = ?_LANG_SYSTEM_ERROR
            end,
            ?SEND_COMBINE_ERR_TOC(CombineOwnerRoleID,Reason),
            ?SEND_COMBINE_ERR_TOC(TargetOwnerRoleID,Reason)
    end.

update_family_state(CombineFamily,TargetFamily) ->
    #p_family_info{members=CombineMembers,family_name=CombineFamilyName,owner_role_name=CombineOwnerRoleName} = CombineFamily,
    #p_family_info{owner_role_id=TargetOwnerRoleID,family_name=TargetFamilyName} = TargetFamily,
    lists:foreach(
      fun(Member) ->
              State = mod_family:get_state(),
              FamilyInfo = State#family_state.family_info,
              NewMember = Member#p_family_member_info{title=?DEFAULT_FAMILY_MEMBER_TITLE},
              OldMemberList = State#family_state.family_members,
              NewMemberList = [NewMember | OldMemberList],
              NewFamily = FamilyInfo#p_family_info{cur_members=erlang:length(NewMemberList), members=NewMemberList},
              NewState = State#family_state{family_members=NewMemberList,family_info=NewFamily},
              RB = #m_family_member_join_toc{member=NewMember},
              mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_MEMBER_JOIN, RB),
              mod_family:update_state(NewState)
      end, CombineMembers),
    NewFamilyInfo = (mod_family:get_state())#family_state.family_info,
    lists:foreach(
      fun(#p_family_member_info{role_id=RoleID,role_name=RoleName}) ->
              RCombine = #m_family_agree_f_toc{return_self=false, family_info=NewFamilyInfo,admit_role_id=TargetOwnerRoleID},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_AGREE_F, RCombine),
              send_offline_role_combine_letter(RoleID,RoleName,CombineFamilyName,TargetFamilyName,CombineOwnerRoleName)
      end, CombineMembers).

send_offline_role_combine_letter(RoleID,RoleName,CombineFamilyName,TargetFamilyName,CombineOwnerRoleName) ->
    case common_misc:is_role_online(RoleID) of
        false ->
            Title = io_lib:format(?COMBINE_FAMILY_LETTER_TITLE,[common_tool:to_list(TargetFamilyName)]),
            Content = common_letter:create_temp(?FAMILY_COMBINE_LETTER,
                                                [RoleName,CombineFamilyName,TargetFamilyName,TargetFamilyName,CombineFamilyName,CombineOwnerRoleName]),
            ?COMMON_FAMILY_LETTER(RoleID, Content, Title, 7);
        true ->
            ignore
    end.

t_combine_finish(CombineFamily,TargetFamily) ->
    #p_family_info{family_id=CombineFamilyID,members=CombineMembers} = CombineFamily,
    #p_family_info{family_id=TargetFamilyID,family_name=TargetFamilyName} = TargetFamily,
    lists:foreach(
      fun(Member) ->
              #p_family_member_info{role_id=RoleID} = Member,
              [RoleBase] = db:read(?DB_ROLE_BASE, RoleID, write),
              NewRoleBase = RoleBase#p_role_base{family_id=TargetFamilyID, family_name=TargetFamilyName},
              ok = db:write(?DB_ROLE_BASE, NewRoleBase, write),
              Object = db:match_object(?DB_FAMILY_INVITE, 
                                       #p_family_invite_info{target_role_id=RoleID,  _='_'}, write),
              lists:foreach(fun(Invite) -> db:delete_object(?DB_FAMILY_INVITE, Invite, write) end, Object),
              mod_family:t_clear_family_request(RoleID)
      end, CombineMembers),
    db:delete(?DB_FAMILY_EXT, CombineFamilyID, write),
    db:delete(?DB_FAMILY, CombineFamilyID, write).


