%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 29 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeew_office).

-behaviour(gen_server).

-include("mgeew.hrl").
-include("office.hrl").

%% API
-export([start/0, start_link/0]).

-export([init_faction_info/0,send_appoint_offline_msg/1]).

-define(DONATE_TYPE_PERSONAL,1).
-define(DONATE_TYPE_KING_COLLECT,2).

-define(OFFICE_OFFLINE_MSG_TYPE,1).
-define(warofking_has_begin, warofking_has_begin).

-define(KING_LETTER_TITLE,"九龙玉玺").
%%张居正NPC ID
-define(NPC_ZHANG_JU_ZHENG(FactionID),erlang:element(2,lists:keyfind(FactionID,1,[{1,11100110},{2,12100110},{3,13100110}]))).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent, 30000, worker, 
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%%--------------------------------------------------------------------
init([]) ->
    init_faction_info(),
    init_titleid_officeid_map(),
    %% 每天0点恢复国库钱币
    erlang:send_after(common_time:diff_next_daytime(0, 0)*1000, self(), add_silver_per_day),
    {ok, #state{}}.

%%--------------------------------------------------------------------
handle_call(Request, _From, State) ->
    Reply = do_handle_call(Request),
    {reply, Reply, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


%% for mochiweb
do_handle_call({set_king, RoleName}) ->
    catch do_set_king(RoleName);
do_handle_call({set_faction_silver, FactionID, Silver}) ->
    catch do_set_faction_silver(FactionID, Silver);
do_handle_call(Request) ->
    ?ERROR_MSG("~ts:~w", ["未知的call", Request]),
    ok.


do_handle_info({Unique, Module, Method, DataRecord, RoleID, PID, Line}) ->
    if Method =:= ?OFFICE_APPOINT andalso erlang:is_record(DataRecord, m_office_appoint_tos) -> 
            do_appoint(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_DISAPPOINT andalso erlang:is_record(DataRecord, m_office_disappoint_tos) -> 
            do_disappoint(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_AGREE_APPOINT -> 
            do_agree_appoint(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_REFUSE_APPOINT -> 
            do_refuse_appoint(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_CANCEL_APPOINT andalso erlang:is_record(DataRecord, m_office_cancel_appoint_tos) ->
            do_cancel_appoint(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_LAUNCH_COLLECTION andalso erlang:is_record(DataRecord, m_office_launch_collection_tos) -> 
            do_launch_collection(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_DONATE andalso erlang:is_record(DataRecord, m_office_donate_tos) -> 
            do_donate(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_PANEL -> 
            do_panel(Unique, Module, Method, DataRecord, RoleID, Line);
       Method =:= ?OFFICE_SET_NOTICE andalso erlang:is_record(DataRecord, m_office_set_notice_tos) ->
            do_set_notice(Unique, Module, Method, DataRecord, RoleID, PID);
       Method =:= ?OFFICE_TAKE_EQUIP andalso erlang:is_record(DataRecord, m_office_take_equip_tos) ->
            do_take_equip(Unique, Module, Method, DataRecord, RoleID, PID);
       Method =:= ?OFFICE_EQUIP_PANEL ->
            do_equip_panel(Unique, Module, Method, DataRecord, RoleID, PID);
       true -> 
            ?ERROR_MSG("~ts:~w ~w", ["未知的方法", Method, {Unique, Module, Method, DataRecord, RoleID, PID, Line}])
    end;
do_handle_info({set_king, RoleID}) ->
    do_set_king(RoleID);
do_handle_info({gm_set_office, RoleID, OfficeID,OfficeName}) ->
    do_gm_set_office(RoleID,OfficeID,OfficeName);
do_handle_info({?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr,  {donate,Unique,Line,Money}}) ->
    do_donate_back(RoleID,RoleAttr,Money,Line,Unique);
do_handle_info({?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason, {donate,Unique,Line}}) ->
    do_donate_error(Unique, ?OFFICE, ?OFFICE_DONATE, Reason, RoleID, Line);
do_handle_info({deduct_faction_silver_buy_guarder,FactionID,Silver,RoleID}) ->
    do_deduct_faction_silver_buy_guarder(FactionID,Silver,RoleID);
do_handle_info({deduct_faction_silver_declare_war,AttackFactionID,DefenceFactionID,RoleID,RoleName}) ->
    do_deduct_faction_silver_declare_war(AttackFactionID,DefenceFactionID,RoleID,RoleName);
do_handle_info(add_silver_per_day) ->
    do_add_silver_per_day();
do_handle_info({reduce_faction_silver, FactionID, ReduceType, ReduceSilver}) ->
    do_reduce_faction_silver(FactionID, ReduceType, ReduceSilver);
do_handle_info({send_appoint_offline_msg, RoleID}) ->
    send_appoint_offline_msg(RoleID);
do_handle_info({set_warofking_status, Status}) ->
    put(?warofking_has_begin,Status);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知的消息", Info]).

do_set_notice(Unique, Module, Method, DataRecord, RoleID, PID) ->
    Content = string:strip(DataRecord#m_office_set_notice_tos.notice_content),
    case catch do_check_set_notice(RoleID, Content) of
        ok ->
            [#p_role_base{faction_id=FactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
            %% 设置公告,过滤内容暂时由客户端完成
            [FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
            db:dirty_write(?DB_FACTION, FactionInfo#p_faction{notice_content=Content}),
            common_misc:unicast2(PID, Unique, Module, Method, #m_office_set_notice_toc{}),
            ok;
        {error, Reason} ->
            do_set_notice_error(Unique, Module, Method, Reason, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["设置国家公告时发生系统错误", Error]),
            do_set_notice_error(Unique, Module, Method, ?_LANG_OFFICE_SYSTEM_ERROR_WHEN_SET_NOTICE, PID)
    end.

do_equip_panel(Unique, Module, Method, _DataRecord, RoleID, PID) ->
    [#p_role_base{faction_id=FactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    Num = 1,
    OfficeEquip = [
                   #p_office_equip{type=?TYPE_EQUIP,type_id=?OFFICE_EQUIP_KING,office_id=?OFFICE_ID_KING,office_name=common_title:get_king_name(FactionID),equip_num=Num},
                   #p_office_equip{type=?TYPE_EQUIP,type_id=?OFFICE_EQUIP_MINISTER,office_id=?OFFICE_ID_MINISTER,office_name=?OFFICE_NAME_MINISTER,equip_num=Num},
                   #p_office_equip{type=?TYPE_EQUIP,type_id=?OFFICE_EQUIP_GENERAL,office_id=?OFFICE_ID_GENERAL,office_name=?OFFICE_NAME_GENERAL,equip_num=Num},
                   #p_office_equip{type=?TYPE_EQUIP,type_id=?OFFICE_EQUIP_JINYIWEI,office_id=?OFFICE_ID_JINYIWEI,office_name=?OFFICE_NAME_JINYIWEI,equip_num=Num}
                  ],
    R = #m_office_equip_panel_toc{office_equip=OfficeEquip},
    common_misc:unicast2(PID, Unique, Module, Method, R).

do_take_equip(Unique, Module, Method, DataRecord, RoleID, PID) ->
    TakeOfficeID = DataRecord#m_office_take_equip_tos.take_office_id,
    TakeNum = DataRecord#m_office_take_equip_tos.take_num,
    case catch do_check_take_equip(RoleID,TakeOfficeID) of
        ok ->
            common_misc:send_to_rolemap(RoleID,{mod_map_office,{take_equip,RoleID,TakeOfficeID,TakeNum,Unique,Module,Method,PID}});
        {error, Reason} ->
            do_take_equip_error(Unique, Module, Method, Reason, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["领取官职装备出错", Error]),
            do_take_equip_error(Unique, Module, Method, ?_LANG_OFFICE_SYSTEM_ERROR_WHEN_TAKE_EQUIP, PID)
    end.

do_take_equip_error(Unique, Module, Method, Reason, PID) ->
    R = #m_office_take_equip_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).

do_check_take_equip(RoleID,TakeOfficeID) ->
    [#p_role_attr{office_id=OfficeID}] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
    %%系统判断玩家的当前官职是否符合
    case OfficeID =:= TakeOfficeID of
        true ->
            ok;
        false ->
            erlang:throw({error, common_misc:format_lang(?_LANG_OFFICE_NOT_RIGHT_TO_TAKE_OFFICE_EQUIP,[common_tool:to_list(?OFFICE_NAME(TakeOfficeID))])})
    end,
    %%王座争霸战期间
    check_has_begin_warofking(?_LANG_OFFICE_NOT_TAKE_OFFICE_EQUIP_IN_WAR_OF_KING).

do_set_notice_error(Unique, Module, Method, Reason, PID) ->
    R = #m_office_set_notice_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).

do_check_set_notice(RoleID, Content) ->
    %%检查是否满足权限
    [#p_role_attr{office_id=OfficeID}] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
    case OfficeID =:= ?OFFICE_ID_KING of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_OFFICE_NOT_RIGHT_TO_SET_NOTICE})
    end,
    case erlang:length(Content) > 600 of
        true ->
            erlang:throw({error, ?_LANG_OFFICE_SET_NOTICE_MAX_LENGTH_LIMIT});
        false ->
            ok
    end,
    ok.

do_gm_set_office(RoleID,NewOfficeID,OfficeName)->
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
    NewRoleAttr = RoleAttr#p_role_attr{office_id=NewOfficeID, office_name=OfficeName},    
    db:dirty_write(?DB_ROLE_ATTR, NewRoleAttr),
    
    R2 = #m_office_change_toc{office_id=NewOfficeID, office_name=OfficeName},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?OFFICE, ?OFFICE_CHANGE,R2),
    ok.


do_set_king(RoleName) when erlang:is_list(RoleName) ->
    TRoleName = common_tool:to_binary(RoleName),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{role_name=TRoleName, _='_'}) of
        [] ->
            ?ERROR_MSG("~ts:~s", ["设置国王失败，原因是角色不存在", RoleName]),
            error;
        [#p_role_base{role_id=RoleID}] ->
            do_set_king(RoleID)
    end;
%%设置国王
do_set_king(RoleID) ->
    [#p_role_base{faction_id=FactionID, role_name=RoleName, head=Head}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    KingName = common_office:get_king_name(FactionID),
    %%更新国家中的国王
    [FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
    OfficeInfo = FactionInfo#p_faction.office_info,
    OldKingRoleID = OfficeInfo#p_office.king_role_id,
    if
        OldKingRoleID =:= RoleID ->
            send_king_letter(RoleID,RoleName,FactionID);
        true ->
            case db:transaction(fun() -> t_do_set_king(RoleID, OldKingRoleID, ?OFFICE_ID_KING, KingName) end) of
                {atomic, {OldOfficeID, _NewRoleAttr, _NewOldKingRoleAttr}} ->                
                    NewOfficeInfo = OfficeInfo#p_office{king_role_id=RoleID, king_role_name=RoleName, king_head=Head},
                    db:dirty_write(?DB_FACTION, FactionInfo#p_faction{office_info=NewOfficeInfo}),
                    %%添加称号
                    common_title_srv:add_title(?TITLE_KING, RoleID, FactionID),
                    
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?OFFICE, ?OFFICE_CHANGE, 
                                        #m_office_change_toc{office_id=?OFFICE_ID_KING, office_name=KingName}),
                    case OldKingRoleID > 0 of
                        true ->
                            lose_office_retrieve_equip(OldKingRoleID,common_office:get_king_name(FactionID)),
                            common_misc:unicast({role, OldKingRoleID}, ?DEFAULT_UNIQUE, ?OFFICE, ?OFFICE_CHANGE, 
                                                #m_office_change_toc{office_id=0, office_name=[]});
                        false ->
                            ignore
                    end,
                    case OldOfficeID =:= ?OFFICE_ID_KING of
                        true ->
                            ignore;
                        false ->
                            case OldOfficeID > 0 of
                                true ->
                                    common_title_srv:remove_by_typeid(get_titleid_by_officeid(OldOfficeID), RoleID),
                                    OldOffices = NewOfficeInfo#p_office.offices,                            
                                    case lists:keyfind(OldOfficeID, #p_office_position.office_id, OldOffices) of
                                        false ->
                                            ignore;
                                        OldOffice ->
                                            NewOffice = OldOffice#p_office_position{role_id=0, role_name=[], head=0},                            
                                            NewOffices = lists:keyreplace(OldOfficeID, #p_office_position.office_id, OldOffices, NewOffice),
                                            NewOfficeInfo2 = NewOfficeInfo#p_office{offices=NewOffices},
                                            db:dirty_write(?DB_FACTION, FactionInfo#p_faction{office_info=NewOfficeInfo2})
                                    end;
                                false ->
                                    ignore
                            end
                    end,       
                    send_king_letter(RoleID,RoleName,FactionID),
                    %% 通知玩家：官职改变了
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            ignore;
                        false ->
                            ignore
                    end,
                    ?ERROR_MSG("~ts:~w", ["设置国王处理出错", Error]),
                    error
            end
    end.

send_king_letter(RoleID,RoleName,FactionID) ->
    Title = ?KING_LETTER_TITLE,
    Content = common_letter:create_temp(?KING_OFFER_LETTER,[common_tool:to_list(RoleName),common_tool:to_list(?NPC_ZHANG_JU_ZHENG(FactionID))]),
    common_letter:sys2p(RoleID, Content, Title, 7).

%%更改玩家的官职
t_do_set_king(RoleID, OldKingRoleID, OfficeID, KingName) ->
    [#p_role_attr{office_id=OldOfficeID} = RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, write),
    NewRoleAttr = RoleAttr#p_role_attr{office_id=OfficeID, office_name=KingName},    
    case OldKingRoleID > 0 andalso RoleID =/= OldKingRoleID of
        true ->
            [OldKingRoleAttr] = db:read(?DB_ROLE_ATTR, OldKingRoleID, write),
            NewOldKingRoleAttr = OldKingRoleAttr#p_role_attr{office_id=0, office_name=[]},
            db:write(?DB_ROLE_ATTR, NewOldKingRoleAttr, write);
        false ->
            NewOldKingRoleAttr = none
    end,
    db:write(?DB_ROLE_ATTR, NewRoleAttr, write),
    {OldOfficeID, NewRoleAttr, NewOldKingRoleAttr}.

%%设置国库钱币
do_set_faction_silver(FactionID, Silver) ->
    case db:transaction(fun() -> t_set_faction_silver(FactionID,Silver) end) of
        {atomic,_} ->
            %%TODO 添加NPC管理记录;
            ok;
        {aborted,_Reason} ->
            _Reason
    end.

t_set_faction_silver(FactionID,Silver) ->
    [FactionInfo] = db:read(?DB_FACTION, FactionID, write),
    db:write(?DB_FACTION, FactionInfo#p_faction{silver=Silver}, write).

%% 卸任官职，收回官印，并发送通知
lose_office_retrieve_equip(RoleID,OfficeName) ->
    lists:foreach(fun(OfficeID) ->
                          lose_office_retrieve_equip(RoleID,OfficeID,OfficeName)
                  end,[?OFFICE_ID_MINISTER,?OFFICE_ID_GENERAL,?OFFICE_ID_JINYIWEI,?OFFICE_ID_KING]).

lose_office_retrieve_equip(RoleID,OfficeID,OfficeName) ->
    Msg = common_misc:format_lang(?_LANG_OFFICE_RETRIEVE_OFFICE_EQUIP, [common_tool:to_list(OfficeName),
                                                              common_tool:to_list(get_equipname(?OFFICE_EQUIP(OfficeID)))]),
    common_office:retrieve_office_equip(RoleID,OfficeID,Msg).

get_equipname(TypeID) ->
    case common_config_dyn:find_equip(TypeID) of
        [BaseInfo] -> 
            BaseInfo#p_equip_base_info.equipname;
        [] ->
            ?_LANG_ITEM_NO_TYPE_EQUIP
    end.

%% 指派官职
do_appoint(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_office_appoint_tos{role_name=TRoleNameT, office_id=OfficeID} = DataRecord,
    TRoleName = common_tool:to_binary(TRoleNameT),
    case catch do_appoint_check(RoleID, TRoleName, OfficeID) of
        {ok, KingRoleName, OfficeName, TRoleID, FactionInfo} ->
            %%发送操作结果
            R = #m_office_appoint_toc{office_id=OfficeID, role_name=TRoleName},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            %%如果要指派的玩家不在线，则放入离线消息表里
            R2 = #m_office_appoint_toc{return_self=false, role_name=KingRoleName, office_name=OfficeName},
            case common_misc:is_role_online(TRoleID) of
                true ->
                    common_misc:unicast({role, TRoleID}, ?DEFAULT_UNIQUE, Module, Method, R2);
                false ->
                    write_appoint_offline_msg(TRoleID,R2)
            end,
            %%更新国家表的记录
            OfficeInfo = FactionInfo#p_faction.office_info,
            Offices  = OfficeInfo#p_office.offices,
            OldOffice = lists:keyfind(OfficeID, #p_office_position.office_id, Offices),
            NewOffice = OldOffice#p_office_position{invite_role_id=TRoleID, invite_role_name=TRoleName},
            NewOffices = lists:keyreplace(OfficeID, #p_office_position.office_id, Offices, NewOffice),
            NewFactionInfo = FactionInfo#p_faction{office_info=OfficeInfo#p_office{offices=NewOffices}},
            db:dirty_write(?DB_FACTION, NewFactionInfo),
            ok;
        {error, Reason} ->
            do_appoint_error(Unique, Module, Method, Reason, RoleID, Line);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["处理指派官职出错", Error]),
            do_appoint_error(Unique, Module, Method, ?_LANG_OFFICE_SYSTEM_ERROR_WHEN_APPOINT, RoleID, Line)
    end.

write_appoint_offline_msg(RoleID,Msg) ->
    OfflineMsg = {?OFFICE_OFFLINE_MSG_TYPE,Msg},
    MsgList = db:dirty_read(?DB_OFFLINE_MSG, RoleID),
    case MsgList of
        [] ->
            db:dirty_write(?DB_OFFLINE_MSG,#r_offline_msg{role_id=RoleID,msg_list=[OfflineMsg]});
        [OfflineMsgList] ->
            List = OfflineMsgList#r_offline_msg.msg_list,
            NewMsgList = lists:keyreplace(?OFFICE_OFFLINE_MSG_TYPE,1,List,OfflineMsg),%%只会收到一条离线指派请求
            db:dirty_write(?DB_OFFLINE_MSG,#r_offline_msg{role_id=RoleID,msg_list=NewMsgList})
    end.

%% 发送离线指派请求
send_appoint_offline_msg(RoleID) ->
    MsgList = db:dirty_read(?DB_OFFLINE_MSG, RoleID),
    case MsgList of
        [] ->
            ignore;
        [OfflineMsgList] ->
            List = OfflineMsgList#r_offline_msg.msg_list,
            case lists:keyfind(?OFFICE_OFFLINE_MSG_TYPE,1,List) of
                false ->
                    ignore;
                {?OFFICE_OFFLINE_MSG_TYPE,Msg} ->
                    NewMsgList = lists:keydelete(?OFFICE_OFFLINE_MSG_TYPE,1,List),
                    case NewMsgList of
                        [] ->
                            db:dirty_delete({?DB_OFFLINE_MSG,RoleID});
                        _ ->
                            db:dirty_write(?DB_OFFLINE_MSG,#r_offline_msg{role_id=RoleID,msg_list=NewMsgList})
                    end,
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?OFFICE, ?OFFICE_APPOINT, Msg)
            end
    end.

do_appoint_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_office_appoint_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


do_appoint_check(RoleID, TRoleName, OfficeID) ->
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{role_name=TRoleName, _='_'}) of
        [] ->
            throw({error, ?_LANG_OFFICE_ROLE_NOT_EXISTS});
        [#p_role_base{role_id=TRoleID, faction_id=TFactionID}] ->
            do_appoint_check2(RoleID, TRoleID, TFactionID, OfficeID)
    end.


do_appoint_check2(RoleID, TRoleID, TFactionID, OfficeID) ->  
    [#p_role_base{faction_id=FactionID, role_name=RoleName}] = db:dirty_read(?DB_ROLE_BASE, RoleID),   
    [#p_role_attr{office_id=TOfficeID}] = db:dirty_read(?DB_ROLE_ATTR, TRoleID),
    case TOfficeID > 0 of
        true ->
            throw({error, ?_LANG_OFFICE_ALREADY_HAS_OFFICE});
        false ->
            ok
    end,
    %%判断是否是本国人
    case FactionID =:= TFactionID of
        true ->
            ok;
        false ->
            throw({error, ?_LANG_OFFICE_NOT_SAME_FACTION})
    end,    
    case RoleID =:= TRoleID of
        true ->
            throw({error, ?_LANG_OFFICE_CANNT_APPOINT_SELF});
        false ->
            ok
    end,
    [#p_faction{office_info=OfficeInfo} = FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
    %% 验证这个是人是否是本国的国王
    #p_office{king_role_id=KingRoleID} = OfficeInfo,
    case KingRoleID =:= RoleID of
        true ->
            ok;
        false ->
            throw({error, ?_LANG_OFFICE_NOT_RIGHT_TO_APPOINT})
    end,
    %% 验证这个官职是否已经有人了，或者已经任命其他人了（需要撤销)
    do_appoint_check_office(TRoleID, OfficeID, OfficeInfo#p_office.offices),
    #p_office_position{office_name=OfficeName} = lists:keyfind(OfficeID, #p_office_position.office_id,  OfficeInfo#p_office.offices),
    {ok, RoleName, OfficeName, TRoleID, FactionInfo}.


%% 检查这个官职是否已经有人任职，或者已经任命其他人了
do_appoint_check_office(TRoleID, OfficeID, Offices) ->
    case lists:keyfind(OfficeID, #p_office_position.office_id, Offices) of
        false ->
            throw({error, ?_LANG_OFFICE_NOT_VALID_OFFICEID});
        OfficeInfo ->
            #p_office_position{role_id=RoleID, invite_role_id=IRoleID} = OfficeInfo,
            case RoleID > 0 of
                true ->
                    throw({error, ?_LANG_OFFICE_ALREADY_APPOINT});
                false ->
                    case IRoleID > 0 of
                        true ->
                            throw({error, ?_LANG_OFFICE_ALREADY_APPOINT_NOT_AGREE});
                        false ->
                            %% 严重是否已经任命这个人其他官职了
                            case lists:keyfind(TRoleID, #p_office_position.invite_role_id, Offices) of
                                false ->
                                    ok;
                                #p_office_position{office_name=_OfficeName} ->                                     
                                    throw({error, ?_LANG_OFFICE_APPOINT_ANOTHER_ALREADY})
                            end
                    end
            end
    end.        


init_titleid_officeid_map() ->
    put(?OFFICE_ID_GENERAL, ?TITLE_OFFICE_GENERAL),
    put(?OFFICE_ID_JINYIWEI, ?TITLE_OFFICE_JINYIWEI),
    put(?OFFICE_ID_MINISTER, ?TITLE_OFFICE_MINISTER).

get_titleid_by_officeid(OfficeID) ->
    get(OfficeID).


%% 解除官职
do_disappoint(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_office_disappoint_tos{office_id=OfficeID} = DataRecord,
    case catch do_disappoint_check(RoleID, OfficeID) of
        {ok, TRoleID, OfficeName, FactionInfo} ->
            case db:transaction(fun() -> t_do_disappoint(TRoleID) end) of
                {atomic, ok} ->
                    %%更新国家结构
                    OfficeInfo = FactionInfo#p_faction.office_info,
                    Offices  = OfficeInfo#p_office.offices,
                    OldOffice = lists:keyfind(OfficeID, #p_office_position.office_id, Offices),
                    NewOffice = OldOffice#p_office_position{role_id=0, role_name=[], head=0},
                    NewOffices = lists:keyreplace(OfficeID, #p_office_position.office_id, Offices, NewOffice),
                    NewFactionInfo = FactionInfo#p_faction{office_info=OfficeInfo#p_office{offices=NewOffices}},
                    db:dirty_write(?DB_FACTION, NewFactionInfo),
                    %%解除指定玩家的指定称号
                    common_title_srv:remove_by_typeid(get_titleid_by_officeid(OfficeID), TRoleID),
                    %%通知双方操作结果
                    R = #m_office_disappoint_toc{office_id=OfficeID,office_name=OfficeName},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
                    R2 = #m_office_disappoint_toc{return_self=false, office_id=OfficeID, office_name=OfficeName},
                    common_misc:unicast({role, TRoleID}, Unique, Module, Method, R2),
                    lose_office_retrieve_equip(TRoleID,OfficeID,OfficeName),
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            ?ERROR_MSG("~ts:~w", ["免除官职处理出错", Error]),
                            Reason = ?_LANG_SYSTEM_ERROR
                    end,
                    do_disappoint_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        {error, Reason} ->
            do_disappoint_error(Unique, Module, Method, Reason, RoleID, Line);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w",["解除官职出错", Error]),
            do_disappoint_error(Unique, Module, Method, ?_LANG_SYSTEM_ERROR, RoleID, Line)
    end.

t_do_disappoint(TRoleID) ->
    [RoleAttr] = db:read(?DB_ROLE_ATTR, TRoleID, write),
    db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{office_id=0, office_name=[]}, write).


do_disappoint_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_office_disappoint_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).    

%% 解除官职前的安全检查
do_disappoint_check(RoleID, OfficeID) ->
    check_has_begin_warofking(?_LANG_OFFICE_NOT_DISAPPOINT_IN_WAR_OF_KING),
    [#p_role_base{faction_id=FactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    [#p_faction{office_info=OfficeInfo} = FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
    KingRoleID = OfficeInfo#p_office.king_role_id,
    %%判断是否有权利解除官职
    case KingRoleID =:= RoleID of
        true ->
            ok;
        false ->
            throw({error, ?_LANG_OFFICE_NO_RIGHT_TO_DISAPPOINT})
    end,
    Offices = OfficeInfo#p_office.offices,
    %%判断该官职是否有人任职
    case lists:keyfind(OfficeID, #p_office_position.office_id, Offices) of
        false ->
            throw({error, ?_LANG_OFFICE_NOT_VALID_OFFICEID});
        OfficePosition ->
            #p_office_position{role_id=TRoleID, office_name=OfficeName} = OfficePosition,
            case TRoleID > 0 of
                true ->
                    {ok, TRoleID, OfficeName, FactionInfo};
                false ->
                    throw({error, ?_LANG_OFFICE_NOT_APPOINTED})
            end
    end.


%% 同意指派
do_agree_appoint(Unique, Module, Method, _DataRecord, RoleID, Line) ->
    case catch do_agree_appoint_check(RoleID) of
        {ok, RoleName, Head, FactionID, OldOffice, FactionInfo} ->
            OfficeName = OldOffice#p_office_position.office_name,
            OfficeID = OldOffice#p_office_position.office_id,
            case db:transaction(fun() -> t_do_agree_appoint(RoleID, OfficeID, OfficeName) end) of
                {atomic, _} ->
                    KingRoleID = (FactionInfo#p_faction.office_info)#p_office.king_role_id,
                    %%更新国家结构
                    OfficeInfo = FactionInfo#p_faction.office_info,
                    Offices  = OfficeInfo#p_office.offices,
                    OldOffice = lists:keyfind(OfficeID, #p_office_position.office_id, Offices),
                    NewOffice = OldOffice#p_office_position{role_id=RoleID, role_name=RoleName, head=Head,
                                                            invite_role_id=0,
                                                            invite_role_name=[]},
                    NewOffices = lists:keyreplace(OfficeID, #p_office_position.office_id, Offices, NewOffice),
                    NewFactionInfo = FactionInfo#p_faction{office_info=OfficeInfo#p_office{offices=NewOffices}},
                    db:dirty_write(?DB_FACTION, NewFactionInfo),
                    %%设置称号
                    common_title_srv:add_title(get_titleid_by_officeid(OfficeID), RoleID, FactionID),
                    %% 通知结果
                    R = #m_office_agree_appoint_toc{office_name=OfficeName},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
                    R2 = #m_office_agree_appoint_toc{return_self=false, office_name=OfficeName,
                                                     role_name=RoleName},
                    common_misc:unicast({role, KingRoleID}, ?DEFAULT_UNIQUE, Module, Method, R2),
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            ?ERROR_MSG("~ts:~w", ["同意任命官职处理出错", Error]),
                            Reason = ?_LANG_SYSTEM_ERROR
                    end,
                    do_agree_appoint_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        {error, Reason} ->
            do_agree_appoint_error(Unique, Module, Method, Reason, RoleID, Line)
    end.

t_do_agree_appoint(RoleID, OfficeID, OfficeName) ->
    [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, write),
    case RoleAttr#p_role_attr.office_id > 0 of
        true ->
            db:abort(?_LANG_OFFICE_HAS_ALREADY);
        false ->
            db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{office_id=OfficeID, office_name=OfficeName}, write)
    end.


do_agree_appoint_check(RoleID) ->
    check_has_begin_warofking(?_LANG_OFFICE_NOT_DISAPPOINT_IN_WAR_OF_KING),
    [#p_role_base{faction_id=FactionID, role_name=RoleName, head=Head}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    %% 检查是否有任命
    [#p_faction{office_info=OfficeInfo} = FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
    Offices = OfficeInfo#p_office.offices,
    case lists:keyfind(RoleID, #p_office_position.invite_role_id, Offices) of
        false ->
            throw({error, ?_LANG_OFFICE_NOT_APPOINTED});
        OldOffice ->
            {ok, RoleName, Head, FactionID, OldOffice, FactionInfo}
    end.

do_agree_appoint_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_office_agree_appoint_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%% 拒绝指派
do_refuse_appoint(Unique, Module, Method, _DataRecord, RoleID, Line) ->
    case catch do_refuse_appoint_check(RoleID) of
        {ok, RoleName, OldOffice, FactionInfo} ->
            OfficeName = OldOffice#p_office_position.office_name,
            OfficeID = OldOffice#p_office_position.office_id,
            KingRoleID = (FactionInfo#p_faction.office_info)#p_office.king_role_id,
            %%更新国家结构
            OfficeInfo = FactionInfo#p_faction.office_info,
            Offices  = OfficeInfo#p_office.offices,
            OldOffice = lists:keyfind(OfficeID, #p_office_position.office_id, Offices),
            NewOffice = OldOffice#p_office_position{role_id=0, role_name=[],head=0, 
                                                    invite_role_id=0,
                                                    invite_role_name=[]},
            NewOffices = lists:keyreplace(OfficeID, #p_office_position.office_id, Offices, NewOffice),
            NewFactionInfo = FactionInfo#p_faction{office_info=OfficeInfo#p_office{offices=NewOffices}},
            db:dirty_write(?DB_FACTION, NewFactionInfo),
            %% 通知结果
            R = #m_office_refuse_appoint_toc{office_name=OfficeName},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            R2 = #m_office_refuse_appoint_toc{return_self=false, office_name=OfficeName,
                                              role_name=RoleName},
            common_misc:unicast({role, KingRoleID}, ?DEFAULT_UNIQUE, Module, Method, R2),
            ok;
        {error, Reason} ->
            do_refuse_appoint_error(Unique, Module, Method, Reason, RoleID, Line);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["拒绝任命官职出错", Error])
    end.


do_refuse_appoint_check(RoleID) ->
    [#p_role_base{faction_id=FactionID, role_name=RoleName}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    %% 检查是否有任命
    [#p_faction{office_info=OfficeInfo} = FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
    Offices = OfficeInfo#p_office.offices,
    case lists:keyfind(RoleID, #p_office_position.invite_role_id, Offices) of
        false ->
            throw({error, ?_LANG_OFFICE_NOT_APPOINTED});
        OldOffice ->
            {ok, RoleName, OldOffice, FactionInfo}
    end.


do_refuse_appoint_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_office_refuse_appoint_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%% 取消指派
do_cancel_appoint(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_office_cancel_appoint_tos{office_id=OfficeID} = DataRecord,
    case catch do_cancel_appoint_check(RoleID, OfficeID) of
        {ok, OldOffice, FactionInfo} ->
            %%更新国家结构
            OfficeInfo = FactionInfo#p_faction.office_info,
            Offices  = OfficeInfo#p_office.offices,
            OldOffice = lists:keyfind(OfficeID, #p_office_position.office_id, Offices),
            NewOffice = OldOffice#p_office_position{role_id=0, role_name=[], 
                                                    invite_role_id=0,
                                                    invite_role_name=[]},
            NewOffices = lists:keyreplace(OfficeID, #p_office_position.office_id, Offices, NewOffice),
            NewFactionInfo = FactionInfo#p_faction{office_info=OfficeInfo#p_office{offices=NewOffices}},
            db:dirty_write(?DB_FACTION, NewFactionInfo),
            %% 通知结果
            R = #m_office_cancel_appoint_toc{office_id=OfficeID},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            ok;
        {error, Reason} ->
            do_cancel_appoint_error(Unique, Module, Method, Reason, RoleID, Line);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["拒绝任命官职出错", Error])
    end.

do_cancel_appoint_check(RoleID, OfficeID) ->
    [#p_role_base{faction_id=FactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    %% 检查是否有任命
    [#p_faction{office_info=OfficeInfo} = FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
    Offices = OfficeInfo#p_office.offices,
    case lists:keyfind(OfficeID, #p_office_position.office_id, Offices) of
        false ->
            throw({error, ?_LANG_SYSTEM_ERROR});
        OldOffice ->
            case OldOffice#p_office_position.invite_role_id > 0 of
                false ->
                    throw({error, ?_LANG_OFFICE_NOT_APPOINT_WHEN_CANCEL});
                true ->
                    {ok, OldOffice, FactionInfo}
            end
    end.

do_cancel_appoint_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_office_cancel_appoint_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%% 发起募捐
do_launch_collection(Unique, Module, Method, _DataRecord, RoleID, Line) ->
    [#p_role_base{role_name=RoleName, faction_id=FactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    case db:dirty_read(?DB_FACTION, FactionID) of
        [] ->
            do_launch_collection_error(Unique, Module, Method, ?_LANG_SYSTEM_ERROR, RoleID, Line);
        [#p_faction{last_launch_collection_day=LastDay, office_info=OfficeInfo}] ->
            NowDay = calendar:date_to_gregorian_days(date()),
            case LastDay =:= undefined orelse NowDay > LastDay of
                true ->
                    case check_role_launch_right(OfficeInfo,RoleID) of
                        {ok,OfficeName} ->
                            Record = #m_office_launch_collection_toc{succ=true, role_name=RoleName, office_name=OfficeName},
                            common_misc:chat_broadcast_to_faction(FactionID, Module, Method, Record);
                        error ->
                            do_launch_collection_error(Unique, Module, Method, ?_LANG_OFFICE_NOT_RIGHT_TO_LANUCH_COLLECTION, RoleID, Line)
                    end;

                false ->
                    do_launch_collection_error(Unique, Module, Method, ?_LANG_FACTION_LANUCH_COLLECTED_TODAY, RoleID, Line)
            end
    end.

%%检查玩家是否有发动募捐的权限,国王和天纵神将可以
check_role_launch_right(OfficeInfo,RoleID) ->
    #p_office{king_role_id=KingID,offices=Offices} = OfficeInfo,
    case KingID =:= RoleID of
        true ->
            {ok,"国王"};
        false ->
            case common_office:get_general_roleid(Offices) =:= RoleID of
                true ->
                    {ok,?OFFICE_NAME_GENERAL};
                false ->
                    error
            end
    end.

check_has_begin_warofking(ErrorMsg) ->
    %%判断是否正在进行王座争霸战
    case get(?warofking_has_begin) of
        true ->
            throw({error, ErrorMsg});
        _Other ->
            ok
    end.


do_launch_collection_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_office_launch_collection_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

-define(OFFICE_DONATE_BC_OFFICE, "尊敬的~s<font color=\"#FFFF00\">[~s]</font>在国家事务官处向国库捐款~s，感谢~s为我~s的民生福利和国防事业做出贡献。").

-define(OFFICE_DONATE_BC_NORMAL, "尊敬的<font color=\"#FFFF00\">[~s]</font>在国家事务官处向国库捐款~s，感谢~s为我~s的民生福利和国防事业做出贡献。").

%% 捐款
do_donate(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_office_donate_tos{money=Money} = DataRecord,
    Money2 = erlang:abs(Money),
    case Money2 > 0 of
        true ->
            %% 如果当前国库已经是最大值，则不能再捐了
            {ok, #p_role_base{faction_id=FactionID}} = common_misc:get_dirty_role_base(RoleID),
            [#p_faction{silver=Silver}] = db:dirty_read(?DB_FACTION, FactionID),
            [MaxSilver] = common_config_dyn:find(office, max_silver),
            case Silver >= MaxSilver of
                true ->
                    do_donate_error(Unique, Module, Method, ?_LANG_OFFICE_DONATE_FACTION_SILVER_LIMITED, RoleID, Line);
                _ ->
                    case Silver + Money2 > MaxSilver of
                        true ->
                            Money3 = MaxSilver - Silver;
                        _ ->
                            Money3 = Money2
                    end,
                    common_role_money:reduce(RoleID,{{silver_any, Money3, ?CONSUME_TYPE_SILVER_DONATE_FACTION_SILVER, ""},undefined},
                                             {donate,Unique,Line,Money2},{donate,Unique,Line})
            end;
        false ->
            do_donate_error(Unique, Module, Method, ?_LANG_OFFICE_DONATE_MUST_MORE_THAN_ZERO, RoleID, Line)
    end.

do_donate_back(RoleID,RoleAttr,Money,Line,Unique) ->
    [#p_role_base{role_name=RoleName, faction_id=FactionID, sex=Sex}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    %%扣玩家的钱币，必须要不绑定
    case db:transaction(fun() -> t_do_donate(RoleID, FactionID, Money) end) of
        {atomic, _} ->
            %%玩家捐款超过1锭的时候全国广播

            NewSilver = RoleAttr#p_role_attr.silver,
            case Money >= 10000 of
                true ->
                    case Sex of
                        1 ->
                            SexName = "他";
                        2 ->
                            SexName = "她"
                    end,
                    FactionName = common_misc:get_faction_name(FactionID),
                    OfficeName=RoleAttr#p_role_attr.office_name,
                    case OfficeName of
                        [] ->
                            Content = common_misc:format_lang(?OFFICE_DONATE_BC_NORMAL, [RoleName, common_misc:format_silver(Money), SexName, FactionName]);
                        _ ->
                            Content = common_misc:format_lang(?OFFICE_DONATE_BC_OFFICE, [OfficeName, RoleName, common_misc:format_silver(Money), SexName, FactionName])
                    end,
                    %%广播通知
                    common_broadcast:bc_send_msg_faction(FactionID, ?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_COUNTRY, Content);
                false ->
                    ignore
            end,
            RR = #m_role2_attr_change_toc{roleid=RoleID, 
                                          changes=[#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, 
                                                                       new_value=NewSilver}
                                                  ]},
            common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, RR),
            RR2 = #m_office_donate_toc{succ=true},
            common_misc:unicast(Line, RoleID, Unique, ?OFFICE, ?OFFICE_DONATE, RR2),
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    ?ERROR_MSG("~ts:~w", ["捐款处理出错", Error]),
                    Reason = ?_LANG_SYSTEM_ERROR
            end,
            do_donate_error(Unique, ?OFFICE, ?OFFICE_DONATE, Reason, RoleID, Line)
    end.


t_do_donate(_RoleID, FactionID, Money) ->    
    [#p_faction{silver=FS} = FactionInfo] = db:read(?DB_FACTION, FactionID),
    [MaxSilver] = common_config_dyn:find(office, max_silver),
    NewFS = FS + Money,
    case NewFS > MaxSilver of
        true ->
            NewFS2 = MaxSilver;
        _ ->
            NewFS2 = NewFS
    end,
    db:write(?DB_FACTION, FactionInfo#p_faction{silver=NewFS2}, write).

do_donate_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_office_donate_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%% 打开官职面板
do_panel(Unique, Module, Method, _DataRecord, RoleID, Line) ->
    [#p_role_base{faction_id=FactionID}] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    [FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),
    R = #m_office_panel_toc{faction_info=FactionInfo},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
    ok.

%%初始化国家信息
init_faction_info() ->
    [DefaultSilver] = common_config_dyn:find(office, default_silver),
    lists:foreach(
      fun(FactionID) ->
              case db:dirty_read(?DB_FACTION, FactionID) of
                  [] ->
                      Offices = [
                                 #p_office_position{office_id=?OFFICE_ID_MINISTER, office_name=?OFFICE_NAME_MINISTER},
                                 #p_office_position{office_id=?OFFICE_ID_GENERAL, office_name=?OFFICE_NAME_GENERAL},
                                 #p_office_position{office_id=?OFFICE_ID_JINYIWEI, office_name=?OFFICE_NAME_JINYIWEI}
                                ],
                      OfficeInfo = #p_office{faction_id=FactionID, king_role_id=0, king_role_name=[], king_head=0,offices=Offices},
                      R = #p_faction{faction_id=FactionID, succ_times_waroffaction=0, silver=DefaultSilver,
                                     office_info=OfficeInfo},
                      db:dirty_write(?DB_FACTION, R);
                  _ ->
                      ignore
              end
      end, ?FACTIONID_LIST).


do_deduct_faction_silver_buy_guarder(FactionID,Silver,_RoleID) ->
    case db:transaction(fun() -> t_decute_faction_silver(FactionID,Silver) end) of
        {atomic,_} ->
            %%TODO 添加NPC管理记录;
            ignore;
        {aborted,_Reason} ->
            ignore
    end.



t_decute_faction_silver(FactionID,Silver) ->
    [#p_faction{silver=FS} = FactionInfo] = db:read(?DB_FACTION, FactionID, write),
    NewFS = FS - Silver,
    db:write(?DB_FACTION, FactionInfo#p_faction{silver=NewFS}, write).


do_deduct_faction_silver_declare_war(AttackFactionID,_DefenceFactionID,_RoleID,_RoleName) ->
    case db:transaction(fun() -> t_decute_faction_silver_declarea_war(AttackFactionID,_DefenceFactionID) end) of
        {atomic,_} ->
            %%TODO 添加NPC管理记录;
            ignore;
        {aborted,_Reason} ->
            ignore
    end.

t_decute_faction_silver_declarea_war(AttackFactionID,DefenceFactionID) ->
    [#p_faction{silver=FS} = AttackFactionInfo] = db:read(?DB_FACTION, AttackFactionID, write),
    [DefenceFactionInfo] = db:read(?DB_FACTION, DefenceFactionID, write),
    %%国战宣战花费10锭钱币
    NewFS = FS - 100000,
    NowDay = calendar:date_to_gregorian_days(date()),
    db:write(?DB_FACTION,AttackFactionInfo#p_faction{silver=NewFS,last_attack_day=NowDay}, write),
    db:write(?DB_FACTION,DefenceFactionInfo#p_faction{last_defence_day=NowDay}, write).

%% @doc 每天恢复国库钱币   
do_add_silver_per_day() ->
    erlang:send_after(24*3600*1000, self(), add_silver_per_day),

    [DefaultAdd] = common_config_dyn:find(office, silver_add_per_day),
    [MaxSilver] = common_config_dyn:find(office, max_silver),

    lists:foreach(
      fun(FactionID) ->
              [#p_faction{silver=Silver}=FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),

              case Silver + DefaultAdd > MaxSilver of
                  true ->
                      Silver2 = MaxSilver;
                  _ ->
                      Silver2 = Silver + DefaultAdd
              end,

              FactionInfo2 = FactionInfo#p_faction{silver=Silver2},
              db:dirty_write(?DB_FACTION, FactionInfo2)
      end, ?FACTIONID_LIST).

%% @doc 扣除国库钱币，地图那边做了判断，如果还是不够置0
do_reduce_faction_silver(FactionID, _ReduceType, ReduceSilver) ->
    [#p_faction{silver=Silver}=FactionInfo] = db:dirty_read(?DB_FACTION, FactionID),

    case Silver > ReduceSilver of
        true ->
            Silver2 = Silver - ReduceSilver;
        _ ->
            Silver2 = 0
    end,

    FactionInfo2 = FactionInfo#p_faction{silver=Silver2},
    db:dirty_write(?DB_FACTION, FactionInfo2).
