%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  9 Jul 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_family).

-behaviour(gen_server).

-include("mgeew.hrl").
-include("mgeew_family.hrl").

-define(DICT_KEY_STATE, dict_key_state).

%%dump数据的周期，也用于检查家族的拉镖状态
-define(DUMP_TICKET, 60 * 1000).

-define(CHECH_FAMILY_MAP_START_TICKET, 3 * 1000).

-define(clear_gongxun, clear_gongxun).


-define(MAP_CLOSE,1).
-define(DOWN_LEVEL,2).
-define(GATHER_CARD_USE_LIMIT,5).

%% //召唤类型：1表示打BOSS的召唤，2表示族长的正常召唤
-define(CALL_TYPE_BOSS,1).
-define(CALL_TYPE_FAMILY_OWNER,2).
-define(CALL_TYPE_FAMILY_BONFIRE,3).


%%田地状态；0=未开垦，1=未种植，2=种子期,3=成长期,4=成熟期
-define(FARM_STATUS_NOT_SOW,1).
%%默认家族地图中的初始化田地大小
-define(DEFAULT_FARM_SIZE,10).

%%更新最后登录时间的间隔
-define(REFRESH_LOGIN_TIME_INTERVAL,1*60).
-define(last_refresh_login_time,last_refresh_login_time).

%% API
-export([
         start_link/1,
         notify_world_update/2,
         get_max_gongxun/0
        ]).
-export([is_special_family_date/0,can_join_family_in_special_date/1,
         add_family_join_times/1,join_family_for_role/4,check_last_set_owner_time/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% Internal API
-export([get_state/0, update_state/1,get_family_id/0]).
-export([broadcast_to_all_members/3,broadcast_to_all_members_except/4,
         broadcast_to_family_channel/1]).
-export([is_owner_or_second_owner/2,is_owner/2,is_intermanager/2]).
-export([do_add_exp/1,do_add_ac/1,do_add_money/1,add_exp_for_role/2,do_add_contribution/2]).
-export([get_contribution/1]).
-export([is_today_not_parttake/2,do_parttake_family_role/2]).
-export([get_max_member/1]).
-export([get_text_with_npc/3]).

-export([t_clear_family_request/1]).

-define(SERVER, ?MODULE). 



%%每隔六个小时检查一次在线人数并且添加AC
-define(CHK_ONLINE_MEMBER_INTERVAL,60*60*6000).

%%每日扣除家族维护费用
-define(CHK_FAMILY_MAINTAIN_INTERVAL,60*60*24*1000).




%%%===================================================================
%%% API
%%%===================================================================

start_link(FamilyID) ->
    gen_server:start_link(?MODULE, [FamilyID], []).

%%@doc 将家族的更新，通知给地图
notify_world_update(RoleID, clear_role_family_skill) ->
    case global:whereis_name(mgeer_role:proc_name(RoleID)) of
        undefined -> 
            ignore;
        PID ->
            PID ! {mod_map_family,{clear_role_family_skill, RoleID}}
    end;
notify_world_update(RoleID, FamilyInfo) when is_record(FamilyInfo, p_family_info) ->
    case global:whereis_name(mgeer_role:proc_name(RoleID)) of
        undefined -> 
            ignore;
        PID ->
            PID ! {mod_map_family,{update_role_family_info, RoleID, FamilyInfo}}
    end;
notify_world_update(RoleID, _) ->
    case global:whereis_name(mgeer_role:proc_name(RoleID)) of
        undefined -> 
            [RoleBase] = db:dirty_read(?DB_ROLE_BASE, RoleID),
            db:dirty_write(?DB_ROLE_BASE, RoleBase#p_role_base{family_id=0, family_name=[]});
        PID ->
            PID ! {mod_map_family,{cancel_role_family_info, RoleID}}
    end.

notify_world_update(RoleID, family_contribute, NewFC) ->
    mgeer_role:absend(RoleID, {mod_map_family,{update_role_family_info, RoleID, family_contribute,NewFC}}).


%%@doc 将Record广播给每个族员
broadcast_to_all_members(Module, Method, RB) ->
    RoleList = get_member_role_id_list(),
    common_misc:broadcast_to_line(RoleList, Module, Method, RB).

%%@doc 将Record广播给每个族员（排除指定的RoleID之外）
broadcast_to_all_members_except(Module, Method, RB, RoleID) ->
    RoleList = get_member_role_id_list(),
    RoleList2 = lists:delete(RoleID, RoleList),
    common_misc:broadcast_to_line(RoleList2, Module, Method, RB).

%%@doc 广播通知家族成员，2911:弹窗消息
broadcast_to_family_channel(MsgContent)->
    State = get_state(),
    lists:foreach(fun(E)->
                          case E#p_family_member_info.online of
                              true->
                                  RoleID = E#p_family_member_info.role_id,
                                  common_broadcast:bc_send_msg_role(RoleID,?BC_MSG_TYPE_POP,MsgContent);
                              _ ->
                                  ignore
                          end
                  end, State#family_state.family_members ).

%%判断是否为家族的特殊日期，例如指定的日期或开服当天
is_special_family_date()->
    true.

%% 判断玩家加入家族的次数
can_join_family_in_special_date(RoleID)->
    Today = date(),
    case ets:lookup(ets_family_join_history,RoleID) of
        [{RoleID,Today,Times}]->
            Times < 2;
        _->
            true
    end.


%%@doc 获取家族贡献度
get_contribution(RoleID)->
    State = get_state(),
    Members = State#family_state.family_members,
    case lists:keyfind(RoleID, #p_family_member_info.role_id, Members) of
        false ->
            0;
        Member ->
            Member#p_family_member_info.family_contribution
    end.

join_family_for_role(RoleID,RoleName,FamilyName,RoleLevel)->
    case RoleLevel<50 of
        true->
            Title = ?JOIN_FAMILY_LETTER_TITLE_FOR_ROLE,
            Content = common_letter:create_temp(?FAMILY_ROLE_JOIN_LETTER,[RoleName, FamilyName,?NPC_SHANG_MAO]),
            ?COMMON_FAMILY_LETTER(RoleID, Content, Title, 14);
        false->
            ignore
    end,
    add_family_join_times(RoleID).
    
%%增加玩家加入家族的次数
add_family_join_times(RoleID)->
    Today = date(),
    case ets:lookup(ets_family_join_history,RoleID) of
        [{RoleID,Today,Times}]->
            ets:insert(ets_family_join_history, {RoleID,Today,Times+1});
        _ ->
            ets:insert(ets_family_join_history, {RoleID,Today,1})
    end.

%%--------------------------------------------------------------------
init([FamilyID]) ->
    ?DEBUG("~ts:~w", ["初始化家族进程", FamilyID]),
    erlang:process_flag(trap_exit, true),
    global:register_name(common_misc:make_family_process_name(FamilyID), self()),
    %%插入数据
    [FamilyInfo] = db:dirty_read(?DB_FAMILY, FamilyID),
    [FamilyExtInfo]  = db:dirty_read(?DB_FAMILY_EXT, FamilyID),
    %%获取总组成员列表，因为考虑这部分的操作可能比较频繁，所以采用内存缓存的方式
    Members = FamilyInfo#p_family_info.members,
    Members2 = init_online(Members),
    Requests = FamilyInfo#p_family_info.request_list,
    Invites = FamilyInfo#p_family_info.invite_list,    
    %% 启动时判断家族拉镖状态
    #p_family_info{ybc_status=YbcStatus, ybc_begin_time=YbcBeginTime} = FamilyInfo,
    case YbcStatus =:= ?FAMILY_YBC_STATUS_DOING andalso common_tool:now() - YbcBeginTime >= 86400 of
        true ->
            %% 清理对应的所有家族成员的状态
            YbcID = FamilyExtInfo#r_family_ext.ybc_id,
            case YbcID > 0 of
                true ->
                    case catch db:dirty_read(?DB_YBC, YbcID) of
                        [#r_ybc{role_list=RoleList}] ->
                            lists:foreach(
                              fun({RID, _RName, _Level, _SB, _S}) ->
                                      db:dirty_write(?DB_ROLE_STATE, #r_role_state{role_id=RID, normal=true})
                              end, RoleList),
                            FamilyInfo2 = FamilyInfo#p_family_info{ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN};
                        _ ->
                            %% 有可能是地图尚未启动造成的，发个消息延迟处理这个问题
                            erlang:send_after(60 * 1000, self(), {ybc_time_out}),
                            FamilyInfo2 = FamilyInfo
                    end;
                false ->
                    FamilyInfo2 = FamilyInfo,
                    ignore
            end;
        false ->
            FamilyInfo2 = FamilyInfo
    end,
    State = #family_state{family_info=FamilyInfo2, family_members=Members2,
                          invites=Invites, requests=Requests, ext_info=FamilyExtInfo},
    init_state(State),
    case FamilyInfo#p_family_info.enable_map of
        true ->
            resume_for_map(),
            active_map();
        false ->
            ?DEBUG("~ts", ["家族副本尚未开启，忽略"])
    end,
    %%判断是否需要自动重生升级boss
    [IsOpenFamilyUpLevelBoss] = common_config_dyn:find(family_base_info,is_open_family_uplevel_boss),
    case IsOpenFamilyUpLevelBoss =:= true
        andalso FamilyInfo#p_family_info.kill_uplevel_boss =:= false 
        andalso FamilyInfo#p_family_info.uplevel_boss_called of
        true ->            
            erlang:send_after(1000, self(), reborn_uplevel_boss);
        false ->
            ignore
    end,
    %%判断是否需要自动重生家族普通boss
    #r_family_ext{common_boss_call_time=CommonBossCallTime, common_boss_killed=CommonBossKilled, 
                  common_boss_called=CommonBossCalled} = FamilyExtInfo,
    {Today, _} = calendar:local_time(),
    case Today =:= CommonBossCallTime of
        true ->
            case CommonBossCalled andalso (not CommonBossKilled) of
                true ->
                    erlang:send_after(1000, self(), reborn_common_boss);
                false ->
                    ignore
            end;
        false ->
            ignore
    end,
    %%在每周六 18点的时候清空功勋
    erlang:send_after((common_time:diff_next_weekdaytime(6, 18, 0) + 1) * 1000, self(), ?clear_gongxun),
    %%家族维护费用,每日一次（每天凌晨一点的时候进行处理）
    erlang:send_after(common_time:diff_next_daytime(1,0) * 1000,self(),family_maintain_cost),
    %%定时dump数据
    erlang:send_after(?DUMP_TICKET, self(), dump_data),
    %%定时计算家族的繁荣度
    erlang:send_after(?CHK_ONLINE_MEMBER_INTERVAL,self(),{add_active_point_by_online_num}),
    {ok, State}.


%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

-define(MATCH_MSG_TAG(MsgTagList),
        is_tuple(Info) andalso lists:member( erlang:element(1, Info), MsgTagList) ). 

%%--------------------------------------------------------------------
handle_info({'EXIT', _, _Reason}, State) ->
    {stop, normal, State};

handle_info({debug,Req}, State) ->
    ?DEBUG_HANDLE_INFO(Req,State);
handle_info(Info, State) ->
    try 
        handle_info_in_catch(Info)
    catch _:Reason -> 
              ?ERROR_LOG("Info:~w, State=~w, Reason: ~w, Stack:~w", [Info,State, Reason, erlang:get_stacktrace()]) 
    end,
    {noreply, State}.
handle_info_in_catch({_Unique, ?FMLSKILL, _Method, _Record, _RoleID, _PID, _Line}=Info) ->
    mod_family_skill:do_handle_info(Info);
handle_info_in_catch({_Unique, ?FMLDEPOT, _Method, _Record, _RoleID, _PID, _Line}=Info) ->
    mod_family_depot:do_handle_info(Info);
handle_info_in_catch({_Unique, ?FMLSHOP, _Method, _Record, _RoleID, _PID, _Line}=Info) ->
    mod_family_shop:handle(Info);
handle_info_in_catch({_Unique, ?FAMILY, Method, _Record, _RoleID, _PID, _Line}=Info) ->
    case lists:member(Method, mod_family_ybc:method_list()) of
        true->
            mod_family_ybc:do_handle_info(Info);
        _ ->
            case lists:member(Method, mod_family_combine:method_list()) of
                true ->
                    mod_family_combine:do_handle_info(Info);
                _ ->
                    do_handle_info(Info)
            end
    end;
handle_info_in_catch({mod_family_welfare, {get_welfare_error, RoleID}}) ->
    mod_family_welfare:handle_info({get_welfare_error, RoleID});
handle_info_in_catch(Info) ->
    handle_info_in_catch_2(Info,[mod_family_skill,
                                 mod_family_depot,
                                 mod_family_combine,
                                 mod_family_ybc]).

handle_info_in_catch_2(Info,[]) ->
    do_handle_info(Info);
handle_info_in_catch_2(Info,[Module|T]) ->
    case is_tuple(Info) andalso lists:member( erlang:element(1, Info), Module:msg_tag()) of
        true->
            Module:do_handle_info(Info);
        _ ->
            handle_info_in_catch_2(Info,T)
    end.     
     
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    case get_state() of
        %%设置为false，说明家族解散了
        false ->
            ignore;
        _ ->
            do_dump_data()
    end,
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

send_to_family_map_process(FamilyID,Request)->
    MapName = lists:concat(["map_family_", FamilyID]),
    global:send(MapName, {mod_map_family,Request}).

%%将进程中的家族数据写入到mnesia中去
do_handle_info(dump_data) ->
    erlang:send_after(?DUMP_TICKET, self(), dump_data),
    
    do_dump_data(),
%%  mod_family_welfare:loop(),
    mod_family_ybc:check_ybc_status();

%%友情提示：接口的注释，请参看对应函数的注释
do_handle_info({Unique, Module, ?FAMILY_REQUEST, Record, RoleID, _PID, Line})
  when is_record(Record, m_family_request_tos) ->
    do_request(Unique, Module, ?FAMILY_REQUEST, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_INVITE, Record, RoleID, _PID, Line})
  when is_record(Record, m_family_invite_tos) ->
    do_invite(Unique, Module, ?FAMILY_INVITE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_CANCEL_INVITE, Record, RoleID, _, Line})
  when is_record(Record, m_family_cancel_invite_tos) ->
    do_cancel_invite(Unique, Module, ?FAMILY_CANCEL_INVITE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_AGREE, Record, RoleID, _PID, Line}) ->
    do_agree(Unique, Module, ?FAMILY_AGREE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_REFUSE, Record, RoleID, _PID, Line}) ->
    do_refuse(Unique, Module, ?FAMILY_REFUSE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_AGREE_F, Record, RoleID, _PID, Line}) ->
    do_agree_f(Unique, Module, ?FAMILY_AGREE_F, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_REFUSE_F, Record, RoleID, _PID, Line}) ->
    do_refuse_f(Unique, Module, ?FAMILY_REFUSE_F, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_FIRE, Record, RoleID, _PID, Line}) ->
    do_fire(Unique, Module, ?FAMILY_FIRE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_UPDATE_PUB_NOTICE, Record, RoleID, _, Line}) ->
    do_update_pub_notice(Unique, Module, ?FAMILY_UPDATE_PUB_NOTICE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_UPDATE_PRI_NOTICE, Record, RoleID, _PID, Line}) ->
    do_update_pri_notice(Unique, Module, ?FAMILY_UPDATE_PRI_NOTICE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_UPDATE_QQ, Record, RoleID, _PID, Line}) ->
    do_update_qq(Unique, Module, ?FAMILY_UPDATE_QQ, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_LEAVE, _, RoleID, _PID, Line}) ->
    do_leave(Unique, Module, ?FAMILY_LEAVE, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_DISMISS, _, RoleID, _PID, Line}) ->
    do_dismiss(Unique, Module, ?FAMILY_DISMISS, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_SET_TITLE, Record, RoleID, _PID, Line}) ->
    do_set_title(Unique, Module, ?FAMILY_SET_TITLE, Record, RoleID, Line);

%%设置家族的自动加入状态
do_handle_info({Unique, Module, ?FAMILY_AUTO_STATE, Record, RoleID, _PID, Line}) ->
    do_set_auto_join(Unique, Module, ?FAMILY_AUTO_STATE, Record, RoleID, Line);

do_handle_info({Unique, Module, ?FAMILY_SET_OWNER, Record, RoleID, _PID, Line}) ->
    do_set_owner(Unique, Module, ?FAMILY_SET_OWNER, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_SET_SECOND_OWNER, Record, RoleID, _PID, Line}) ->
    do_set_second_owner(Unique, Module, ?FAMILY_SET_SECOND_OWNER, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_UNSET_SECOND_OWNER, Record, RoleID, _PID, Line}) ->
    do_unset_second_owner(Unique, Module, ?FAMILY_UNSET_SECOND_OWNER, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_SELF, _, RoleID, _PID, Line}) ->
    do_self(Unique, Module, ?FAMILY_SELF, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_ENTER_MAP, _, RoleID, _PID, Line}) ->
    do_enter_map(Unique, Module, ?FAMILY_ENTER_MAP, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_LEAVE_MAP, _, RoleID, _PID, Line}) ->
    do_leave_map(Unique, Module, ?FAMILY_LEAVE_MAP, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_CANCEL_TITLE, Record, RoleID, _PID, Line}) ->
    do_cancel_title(Unique, Module, ?FAMILY_CANCEL_TITLE, Record, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_UPLEVEL, _, RoleID, _PID, Line}) ->
    case common_config:is_debug() of
    true ->
        do_uplevel(Unique, Module, ?FAMILY_UPLEVEL, RoleID, Line);
    false ->
        ignore
    end;
do_handle_info({Unique, Module, ?FAMILY_ENABLE_MAP, _, RoleID, _PID, Line}) ->
    do_enable_map(Unique, Module, ?FAMILY_ENABLE_MAP, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_CALL_UPLEVELBOSS, _, RoleID, _PID, Line}) ->
    do_call_uplevelboss(Unique, Module, ?FAMILY_CALL_UPLEVELBOSS, RoleID, Line);
do_handle_info({Unique, Module, ?FAMILY_CALL_COMMONBOSS, _, RoleID, _PID, Line}) ->
    do_call_commonboss(Unique, Module, ?FAMILY_CALL_COMMONBOSS, RoleID, Line);
%%族长召唤族员到家族地图
do_handle_info({Unique, Module, ?FAMILY_CALLMEMBER, Record, RoleID, _PID, Line}) ->
    do_call_member(Unique, Module, ?FAMILY_CALLMEMBER, Record, RoleID, Line);
%%成员同意参与副本boss战斗的传送
do_handle_info({Unique, Module, ?FAMILY_MEMBER_ENTER_MAP,Record,RoleID,_Pid,Line})->
    do_member_enter_map(Unique,Module,?FAMILY_MEMBER_ENTER_MAP,Record,RoleID,Line);
%%发送拉镖 普通boss状态
do_handle_info({Unique, Module, ?FAMILY_ACTIVESTATE, Record, RoleID, _PID, Line}) ->
    do_familytask_state(Unique, Module, ?FAMILY_ACTIVESTATE, Record, RoleID, Line);
%%发送在线族员列表
do_handle_info({Unique, Module, ?FAMILY_NOTIFY_ONLINE, Record, RoleID, _PID, Line}) ->
    do_notify_online(Unique, Module, ?FAMILY_NOTIFY_ONLINE, Record, RoleID, Line);

do_handle_info({gather_members, DestMapID, DistMapPos}) ->
    do_gather_members(DestMapID, DistMapPos);

%% 门派令使用后，Client发送召集帮众的请求
do_handle_info({Unique, Module, ?FAMILY_GATHERREQUEST,_Record,RoleID,Pid,Line})->
    ?DEBUG("deliver_member reply_back",[]),
    DoingYbc = common_map:is_doing_ybc(RoleID),
    [#r_role_state{trading = Trading}] = db:dirty_read(?DB_ROLE_STATE,RoleID),
    {ok, #p_role_pos{map_id=MapID}} = common_misc:get_dirty_role_pos(RoleID),
    [JailMapID] = common_config_dyn:find(jail, jail_map_id),
    if
        DoingYbc =:= true ->
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_YBC_CAN_NOT_MEMBERGATHER);
        Trading =:= 1 ->
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_ITEM_FAMILY_INVALID_TRADING_STATE);
        JailMapID =:= MapID ->
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_FAMILY_GATHERREQUEST_IN_JAIL);
        true ->
            do_member_gather_request(Unique, Module, ?FAMILY_GATHERREQUEST, RoleID, Pid, Line)
    end;

%%设置篝火开始时间
do_handle_info({Unique, Module, ?FAMILY_SET_BONFIRE_START_TIME=Method,DataIn,RoleID,Pid,_Line})->
    #m_family_set_bonfire_start_time_tos{hour=H,minute=M}=DataIn,
    case get_state() of
        undefined ->
            common_misc:unicast2(Pid, Unique, Module, Method, #m_family_set_bonfire_start_time_toc{succ=false,reason=?_LANG_SYSTEM_ERROR});
        #family_state{family_info=#p_family_info{family_id=FamilyID,owner_role_id=ORoleID,hour=OH,minute=OM,seconds=Old}=Info,family_members=Members} = State ->
            if RoleID =:= ORoleID ->
                    {NewState,NewS} = 
                        case is_integer(Old) andalso Old > common_tool:today(0,0,0) of
                            true ->
                                {State#family_state{family_info=Info#p_family_info{hour=H,minute=M}},Old};
                            false ->
                                {State#family_state{family_info=Info#p_family_info{hour=H,minute=M,seconds=common_tool:today(OH,OM,0)}},Old}
                        end,
                    update_state(NewState),
                    Data = #m_family_set_bonfire_start_time_toc{succ=true,hour=H,minute=M,seconds=NewS, reason=?_LANG_FAMILY_HAS_BURN},
                    lists:foreach(
                      fun(#p_family_member_info{online=true,role_id=RoleID1})when RoleID1 =/= RoleID ->
                              common_misc:unicast({role,RoleID1}, 0, Module, Method, Data#m_family_set_bonfire_start_time_toc{reason=""});
                         (_) ->
                              ok
                      end, Members),
                    common_broadcast:bc_send_msg_family(FamilyID,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_FAMILY,?_LANG_FAMILY_CHANGE_BONFIRE_BURN),
                    common_misc:unicast2(Pid, Unique, Module, Method, Data);
               true ->
                    common_misc:unicast2(Pid, Unique, Module, Method, #m_family_set_bonfire_start_time_toc{succ=false,reason=?_LANG_FAMILY_YOU_NOT_OWNER})
            end
    end;
do_handle_info({Unique, Module, ?FAMILY_SET_INTERIOR_MANAGER, Record, RoleID, _PID, Line}) ->
    do_set_Interior_Manager(Unique, Module, ?FAMILY_SET_INTERIOR_MANAGER, Record, RoleID, Line); 
do_handle_info({Unique, Module, ?FAMILY_UNSET_INTERIOR_MANAGER, Record, RoleID, _PID, Line}) ->
    do_unset_interior_manager(Unique, Module, ?FAMILY_UNSET_INTERIOR_MANAGER, Record, RoleID, Line); 
do_handle_info({Unique, ?FAMILY_WELFARE, Method, Record, RoleID, PID, Line}) ->
    mod_family_welfare:handle_info({Unique, ?FAMILY_WELFARE, Method, Record, RoleID, PID, Line});
    
do_handle_info({role_online, RoleID}) ->
    do_role_online(RoleID);
do_handle_info({role_offline, RoleID}) ->
    do_role_offline(RoleID);
do_handle_info(init_family_map) ->
    active_map();
%%do_handle_info(calc_active_points) ->
%%do_calc_active_points();
do_handle_info(resume_for_map) ->
    resume_for_map();
do_handle_info(reborn_uplevel_boss) ->
    reborn_uplevel_boss();

do_handle_info(reborn_common_boss) ->
    reborn_common_boss();

do_handle_info({common_boss_dead, RoleNum, RoleIDList}) ->
    do_common_boss_dead(RoleIDList, RoleNum);

do_handle_info({uplevel_boss_dead, RoleNum, RoleIDList}) ->
    do_uplevel_boss_dead(RoleIDList, RoleNum);

%%删除某个人的对本家族申请请求
do_handle_info({clear_family_request,RoleID})->
    do_clear_family_request(RoleID);
%%删除某家族召唤BOSS的时间
do_handle_info({clear_commonboss_calltime})->
    do_clear_commonboss_calltime();

%% 地图争夺战发过来的扣钱消息
do_handle_info({reduce_money, Money, From, SuccInfo, FailedInfo}) ->
    do_reduce_money(Money, From, SuccInfo, FailedInfo);

%%GM相关命令处理
do_handle_info({gm_add_active_points, Num}) ->
    do_add_ac(Num);
do_handle_info(gm_family_maintain) ->
    mod_family_change:family_maintain_cost();
do_handle_info({gm_add_money, Num}) ->
    do_add_money(Num);
do_handle_info({gm_uplevel,RoleID}) ->
    do_gm_uplevel(RoleID);

%% 直接加入家族
do_handle_info({join_family_direct, RoleID, FamilyID}) ->
    check_auto_join(RoleID, FamilyID);

%%25级自动加入家族
do_handle_info({join_25_family_direct, RoleID, FamilyID}) ->
    check_25_auto_join(RoleID, FamilyID);

%% GM开启家族地图
do_handle_info({gm_enable_map, RoleID}) ->
    do_gm_enable_map(RoleID);

%%member levelup callback 
do_handle_info({member_levelup,MemberID,NewLevel})->
    do_member_level_up(MemberID,NewLevel);

do_handle_info({add_gongxun, Add}) ->
    do_add_gongxun(Add);

do_handle_info(family_maintain_cost)->
    do_family_maintain_cost();

do_handle_info({add_exp, Exp}) ->
    do_add_exp(Exp);
    
do_handle_info({add_money, Money}) ->
    do_add_money(Money);

do_handle_info({add_contribution, RoleID, C}) ->
    do_add_contribution(RoleID, C);

do_handle_info({add_prize_when_family_collect_end, Score, RoleNum}) ->
    do_add_family_collect_prize(Score, RoleNum);

do_handle_info({send_to_online_members,RoleID,Module,Method,RecMember}) ->
    broadcast_to_all_members_except(Module, Method, RecMember, RoleID);

%%族员个人镖车被攻击求救
do_handle_info({person_ybc_sos,RoleID,RoleName,Pos,MapID}) ->
    R = #m_personybc_sos_toc{pos=Pos,map_id=MapID,role_name=RoleName},
    broadcast_to_all_members_except(?PERSONYBC, ?PERSONYBC_SOS, R, RoleID),
    ok;

do_handle_info(?clear_gongxun) ->
    do_clear_gongxun(),
    erlang:send_after((common_time:diff_next_weekdaytime(6, 18, 0) + 1)*1000, self(), ?clear_gongxun);

%%每三小时检查一次在线
do_handle_info({add_active_point_by_online_num})->
    do_add_active_points_by_online();

%% 异步开启地图扣元宝的返回结果
do_handle_info({?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr, reduce_gold_for_enable_map_successful}) ->
    do_reduce_role_gold_for_enble_map_succ(RoleID, RoleAttr);
do_handle_info({?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason, reduce_gold_for_enable_map_failed}) ->
    do_reduce_role_gold_for_enble_map_failed(RoleID, Reason);
do_handle_info(reduce_gold_for_enable_map_timeout) ->
    do_reduce_gold_for_enable_map_timeout();

%%自定义命令
do_handle_info({func,Fun,ArgLists})->
    Result = (catch apply(Fun,ArgLists)),
    ?ERROR_MSG("~w",[Result]);
do_handle_info({gm_set_owner,_FamilyID,OldOwnerID,NewOwnerID})->
    do_set_owner3(?DEFAULT_UNIQUE,?FAMILY, ?FAMILY_SET_OWNER, NewOwnerID, OldOwnerID, undifined);
do_handle_info({gm_set_familyinfo,Money,ActivePoint}) ->
    do_add_ac(ActivePoint),
    do_add_money(Money);

do_handle_info({update_member_name, RoleID, RoleName}) ->
    do_update_member_name(RoleID, RoleName);

do_handle_info({rename, NewFamilyName}) ->
    do_rename(NewFamilyName);

%%召集族员来玩火     
do_handle_info(call_member_bonfire) ->
    %%召集族员来玩火                    
    R = #m_family_callmember_toc{succ=true, message="家族篝火已经点燃，饮酒拿经验，快去参加吧！",call_type=?CALL_TYPE_FAMILY_BONFIRE},
    #family_state{family_info=#p_family_info{family_id=FamilyID}} = get_state(),
    OutsideMapMembers = get_online_and_outside_map_members(get_state()),
    common_broadcast:bc_send_msg_family(FamilyID,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_FAMILY,"家族篝火已经点燃，饮酒拿经验，快去参加吧！"),
    common_misc:broadcast_to_line(OutsideMapMembers, ?FAMILY, ?FAMILY_CALLMEMBER, R);

%% 家族捐献
do_handle_info({family_donate,RoleID,AddContribute,AddExp})->
    do_add_exp(AddExp),
    do_add_contribution(RoleID, AddContribute);

do_handle_info({family_pray, RoleID, AddFamilyExp, AddContribute}) ->
    do_add_exp(AddFamilyExp),
    do_add_contribution(RoleID, AddContribute);

do_handle_info({Handler, Info}) ->
    Handler:handle(Info);

do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知信息", Info]).

%% 家族令使用完后通知所有本家族玩家
do_gather_members(DestMapID, DistMapPos) ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    %% 对死亡状态和摆摊者的族员，不进行传送
    OwnerID = FamilyInfo#p_family_info.owner_role_id,
    OnlineFamilyMemberIds = 
        lists:foldl(fun(E,Acc)->
                            MemberRoleID = E#p_family_member_info.role_id,
                            case (not E#p_family_member_info.online orelse MemberRoleID =:= OwnerID) of
                                true ->
                                    Acc;
                                false ->
                                    {ok, #p_role_base{status=Status}} = common_misc:get_dirty_role_base(MemberRoleID),
                                    {ok, #r_role_state{stall_self=IsStallSelf}} = common_misc:get_dirty_role_state(MemberRoleID),
                                    case (Status =:= ?ROLE_STATE_DEAD orelse (IsStallSelf =:= true)) of
                                        true->
                                            Acc;
                                        _ -> 
                                            {ok, #p_role_attr{level=RoleLevel}} = common_misc:get_dirty_role_attr(MemberRoleID),
                                            %%只有符合级别条件的族员才能收到消息
                                            case check_map_level(DestMapID,RoleLevel) of
                                                true->
                                                    [MemberRoleID|Acc];
                                                _ ->
                                                    Acc
                                            end
                                    end                                                 
                            end
                    end,[],FamilyInfo#p_family_info.members),
    ExtInfo = State#family_state.ext_info,
    #r_family_ext{last_card_use_day=LastUseDay} = ExtInfo,
    NowDay = date(),
    LastCardUseCount = case is_integer(ExtInfo#r_family_ext.last_card_use_count) andalso LastUseDay =:= NowDay of
                           true->
                               ExtInfo#r_family_ext.last_card_use_count;
                           _ ->
                               0
                       end,
    MergedExtInfo = case  is_record(DistMapPos,p_role_pos) of
                        true->
                            ExtInfo#r_family_ext{ last_card_use_day = NowDay,
                                                  last_card_use_count = LastCardUseCount+1,
                                                  last_deliver_dist_pos=DistMapPos };
                        _ ->
                            ExtInfo#r_family_ext{ last_card_use_day = NowDay,
                                                  last_card_use_count = LastCardUseCount+1 }
                    end,
    ?ERROR_MSG("MergedExtInfo=~w",[MergedExtInfo]),
    NewState = State#family_state{ ext_info = MergedExtInfo },
    update_state(NewState),
    R_toc = #m_family_membergather_toc{ message = ?_LANG_FAMILY_MEMBER_GATHER},
    lists:foreach(
      fun(T)->
              common_misc:unicast({role,T},?DEFAULT_UNIQUE,?FAMILY,?FAMILY_MEMBERGATHER,R_toc)
      end, OnlineFamilyMemberIds),
    ok.    

%% 根据地图等级，检查族员是否可到达
check_map_level(DestMapID,RoleLevel)->
    case common_config_dyn:find(map_level_limit, DestMapID) of
        [Level]->
            RoleLevel >= Level;
        _ ->
            false
    end.

set_role_online(RoleID, Flag) ->
    erlang:put({role_online, RoleID}, Flag).


%% 玩家改名后，对应的宗族信息也需要更新
do_update_member_name(RoleID, RoleName) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Members = State#family_state.family_members,
    case FamilyInfo#p_family_info.create_role_id =:= RoleID of
        true ->
            FamilyInfo2 = FamilyInfo#p_family_info{create_role_name=RoleName};
        false ->
            FamilyInfo2 = FamilyInfo
    end,
    case FamilyInfo2#p_family_info.owner_role_id =:= RoleID of
        true ->
            FamilyInfo3 = FamilyInfo2#p_family_info{owner_role_name=RoleName};
        false ->
            FamilyInfo3 = FamilyInfo2
    end,
    case lists:keyfind(RoleID, #p_family_member_info.role_id, Members) of
        false ->
            NewMembers = Members;
        R ->
            NewMembers = lists:keyreplace(RoleID, #p_family_member_info.role_id, Members, R#p_family_member_info{role_name=RoleName})
    end,
    SecondOwners = FamilyInfo3#p_family_info.second_owners,
    case lists:keyfind(RoleID, #p_family_second_owner.role_id, SecondOwners) of
        false ->
            FamilyInfo4 = FamilyInfo3;
        SecondOwner ->
            NewSecondOwner = SecondOwner#p_family_second_owner{role_id=RoleID, role_name=RoleName},
            NewSecondOwners = lists:keyreplace(RoleID, #p_family_second_owner.role_id, SecondOwners, NewSecondOwner),
            FamilyInfo4 = FamilyInfo3#p_family_info{second_owners=NewSecondOwners}
    end,
    FamilyInfo5 = FamilyInfo4#p_family_info{members=NewMembers},
    update_state(State#family_state{family_info=FamilyInfo5, family_members=NewMembers}),
    broadcast_to_all_members(?FAMILY, ?FAMILY_SELF, #m_family_self_toc{family_info=FamilyInfo5}).

%% 宗族在线重命名
do_rename(NewFamilyName) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Members = State#family_state.family_members,
    db:transaction(
      fun() ->
              lists:foreach(
                fun(#p_family_member_info{role_id=RoleID}) ->
                        RoleTabName = mod_role_tab:name(RoleID),
                        ets:update_element(RoleTabName, p_role_base, [{#p_role_base.family_name, NewFamilyName}])
                end, Members)
      end),
    NewFamilyInfo = FamilyInfo#p_family_info{family_name=NewFamilyName}, 
    update_state(State#family_state{family_info=NewFamilyInfo}),
    %% 通知所有宗族玩家，通知地图场景
    broadcast_to_all_members(?FAMILY, ?FAMILY_SELF, #m_family_self_toc{family_info=NewFamilyInfo}),
    lists:foreach(
      fun(#p_family_member_info{role_id=RoleID}) ->
              notify_world_update(RoleID, NewFamilyInfo)
      end, Members),
    do_dump_data().


%% @doc 给玩家加额外经验
%% 打Common BOSS，门派拉镖，都调用此接口
add_exp_for_role(RoleID, Exp) ->
    %%需要计算特殊活动的收成
    common_misc:add_exp_unicast(RoleID, Exp),
    ok.

%%加经验的递归
add_exp_loop(Exp, _, Level, NextExp) when Level >= 12 ->
    {Exp, Level, NextExp};
add_exp_loop(Exp, AddExp, Level, NextExp) when (Exp + AddExp) >= NextExp ->
    NewLevel = Level + 1,
    #r_family_config{
        next_level_exp = NewNextExp
    } = cfg_family:level_config(NewLevel), 
    add_exp_loop(0, (Exp + AddExp) - NextExp, NewLevel, NewNextExp);
add_exp_loop(Exp, AddExp, Level, NextExp) ->
    {Exp + AddExp, Level, NextExp}.

do_add_exp(AddExp) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    #p_family_info{level=Level, exp=Exp, next_level_exp=NextLevelExp} = FamilyInfo,

    {NewExp, NewLevel, NewNextLevelExp} = add_exp_loop(Exp, AddExp, Level, NextLevelExp),
    if 
    {Level, Exp, NextLevelExp} =/= {NewExp, NewLevel, NewNextLevelExp} ->
        update_state(State#family_state{
            family_info = FamilyInfo#p_family_info{
                exp            = NewExp,
                level          = NewLevel, 
                next_level_exp = NewNextLevelExp
            }
        }),
        R = #m_family_exp_toc{level=NewLevel, exp=NewExp, next_level_exp=NewNextLevelExp},
        broadcast_to_all_members(?FAMILY, ?FAMILY_EXP, R);
    true ->
        ignore
    end,
    if
    NewLevel > Level ->
        do_uplevel2();
    true ->
        todo
    end,
    ok.

do_add_ac(AC) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    #p_family_info{active_points=Cur} = FamilyInfo,
    update_state(State#family_state{family_info=FamilyInfo#p_family_info{active_points=Cur+AC}}),
    R = #m_family_active_points_toc{new_points=Cur + AC},
    broadcast_to_all_members(?FAMILY, ?FAMILY_ACTIVE_POINTS, R),
    ok.

  
%%@doc 增加玩家的家族贡献度，
%%@param AddFmlConb 新增的贡献度，可以是正数/负数 
do_add_contribution(RoleID, AddFmlConb) when is_integer(RoleID) and is_integer(AddFmlConb) ->
    State = get_state(),
    Members = State#family_state.family_members,
    case lists:keyfind(RoleID, #p_family_member_info.role_id, Members) of
        false ->
            ignore;
        Member ->
            NewFmlConb = case Member#p_family_member_info.family_contribution + AddFmlConb of
                               C1 when C1<0 ->
                                   0;
                               C2 -> C2
                          end,
            NewMember = Member#p_family_member_info{family_contribution=NewFmlConb}, 
            do_update_contribution_trans(RoleID,NewFmlConb),
            
            R = #m_role2_attr_change_toc{roleid=RoleID, changes=[#p_role_attr_change{change_type=?ROLE_FAMILY_CONTRIBUTE_CHANGE, new_value=NewFmlConb}]},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, R),
            hook_family:hook_family_conbtribute_change(RoleID,NewFmlConb),
            catch notify_world_update(RoleID, family_contribute,NewFmlConb),
            NewMembers = lists:keyreplace(RoleID, #p_family_member_info.role_id, Members, NewMember),
            update_state(State#family_state{family_members=NewMembers})
    end,
    ok.


%%doc 家族采集活动结束后增加家族资金
do_add_family_collect_prize(_Score,RoleNum) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Level = FamilyInfo#p_family_info.level,
    AddPoint = Level * 3 + trunc(RoleNum/3),
    do_add_ac(AddPoint),
    Content = io_lib:format(?_LANG_FAMILY_COLLECT_END_BROADCAST, [AddPoint]),
    common_broadcast:bc_send_msg_family(FamilyInfo#p_family_info.family_id,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_FAMILY,Content).
  

%%@doc 事务真正修改玩家的家族贡献度
do_update_contribution_trans(RoleID,NewFmlConb)->
    TransFun = fun()->
                       RoleTab = mod_role_tab:name(RoleID),
                       ets:update_element(RoleTab, p_role_attr, [{#p_role_attr.family_contribute, NewFmlConb}])
               end,
    case db:transaction(TransFun) of
        {atomic,_} ->
            hook_family:role_contribution_change(RoleID, NewFmlConb),
            ok;
        {aborted,Reason} ->
            ?ERROR_MSG_STACK("do_update_contribution_trans error",Reason),
            {error,Reason}
    end.

%%@doc 在进程内部删除该玩家的申请记录
do_clear_family_request(TargetRoleID)->
    State = get_state(),
    RequestList = State#family_state.requests,
    case lists:keyfind(TargetRoleID, 2, RequestList) of
        false ->
            ignore;
        _ ->
            
            %%发送删除前端缓存的请求
            FamilyInfo = State#family_state.family_info,
            SecondOwners = FamilyInfo#p_family_info.second_owners,
            OwnersList = case is_list(SecondOwners) of
                             true->
                                 SecOwnerIDList = [ SecOwenID ||#p_family_second_owner{role_id=SecOwenID} <- SecondOwners],
                                 [ FamilyInfo#p_family_info.owner_role_id | SecOwnerIDList ];
                             _ ->
                                 [ FamilyInfo#p_family_info.owner_role_id ]
                         end,
            lists:foreach(fun(OwnerID)-> 
                                  R2 = #m_family_del_request_toc{role_id=TargetRoleID},
                                  common_misc:unicast({role,OwnerID},?DEFAULT_UNIQUE,?FAMILY,?FAMILY_DEL_REQUEST,R2)
                          end, OwnersList),
            
            NewRequestList = lists:keydelete(TargetRoleID, 2, RequestList),
            NewState = State#family_state{requests=NewRequestList},
            update_state(NewState),
            ok
    end.


do_reduce_money(Money, From, SuccInfo, FailedInfo) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    #p_family_info{money=CurMoney} = FamilyInfo,
    case CurMoney >= Money of
        true ->
            From ! SuccInfo,
            update_state(State#family_state{family_info=FamilyInfo#p_family_info{money=CurMoney - Money}}),
            R = #m_family_money_toc{new_money=CurMoney - Money},
            broadcast_to_all_members(?FAMILY, ?FAMILY_MONEY, R);
        false ->
            From ! FailedInfo
    end.


check_delivery_condition()->
    State = get_state(),
    ExtInfo = State#family_state.ext_info,
    LastCardUseDay  = ExtInfo#r_family_ext.last_card_use_day,
    LastCardUseCount = ExtInfo#r_family_ext.last_card_use_count,
    Result = (date() =/= LastCardUseDay) orelse (LastCardUseCount =< ?GATHER_CARD_USE_LIMIT),
    Result.


do_member_gather_request(Unique,Module,?FAMILY_GATHERREQUEST,RoleID,Pid,Line)->
    State = get_state(),
    ExtInfo = State#family_state.ext_info,
    EleRoleStatus = mod_role_tab:get({?role_base, RoleID}),
    [#r_role_state{stall_self=StallState}] = db:dirty_read(?DB_ROLE_STATE,RoleID),
    TotalCondition =  
        ((not (StallState =:= true)) 
         andalso EleRoleStatus#p_role_base.status =/= ?ROLE_STATE_DEAD 
         andalso check_delivery_condition()),
    if TotalCondition  ->
        do_member_gather_request2(Unique,Module,RoleID,Pid,Line,ExtInfo);
       true ->
            Reason = ?_LANG_ITEM_FAMILY_INVALID_STATE,
        do_member_gather_request_error(RoleID,Reason)
    end.
do_member_gather_request2(_Unique,_Module,RoleID,_Pid,_Line,ExtInfo)->
    DbPos = ExtInfo#r_family_ext.last_deliver_dist_pos,
    case DbPos of
        undefined ->
            ignore;
        _ ->
            #p_role_pos{map_id=MapID, pos=#p_pos{tx=TX, ty=TY}} = DbPos,
            DistMap_tos = #m_map_change_map_toc{mapid = MapID, tx = TX, ty = TY},
            R_toc = #m_family_gatherrequest_toc{succ = true,reason = ""},
            common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?FAMILY,?FAMILY_GATHERREQUEST,R_toc),
            common_misc:send_to_rolemap(RoleID, {mod_map_role,{family_membergather,RoleID,DistMap_tos}})
    end.

%% error统一添加通知
do_member_gather_request_error(RoleID,Reason)->
    R_toc = #m_family_gatherrequest_toc{succ = false,reason = Reason},
    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?FAMILY,?FAMILY_GATHERREQUEST,R_toc).

do_member_level_up(MemberID,NewLevel)->
    ?DEBUG("LevelUpHookForFamily ~p ~p",[MemberID,NewLevel]),
    State = get_state(),
    Members = State#family_state.family_members,
    case lists:keyfind(MemberID,#p_family_member_info.role_id,Members) of 
    false ->
        ignore;
    TargetRole ->
        NewAttr =  TargetRole#p_family_member_info{role_level=NewLevel},
        NewMemberList = lists:keyreplace(MemberID,#p_family_member_info.role_id,Members,NewAttr),
        NewState = State#family_state{family_members = NewMemberList},      
        update_state(NewState),
        notify_all_members(MemberID,NewLevel,Members)
    end.

%%level up notice 
notify_all_members(MemberID,NewLevel,Members)->
    MemberLevelupMsg_toc = #m_family_memberuplevel_toc{
      role_id = MemberID,
      new_level = NewLevel
     },
    lists:foreach(fun(Ele)->
              T = Ele#p_family_member_info.role_id,
              _R = (catch common_misc:unicast({role,T},?DEFAULT_UNIQUE,?FAMILY,?FAMILY_MEMBERUPLEVEL,MemberLevelupMsg_toc))
          end,
          Members).
            
%%成员同意进入家族地图 
do_member_enter_map(Unique,Module,Method,Record,RoleID,Line)->
    %% DoingYbc = common_map:is_doing_ybc(RoleID),
    %% 商贸状态 add by caochuncheng 2011-01-14
    [RoleState] = db:dirty_read(?DB_ROLE_STATE, RoleID),
    RoleYbcState = RoleState#r_role_state.ybc,
    Trading = RoleState#r_role_state.trading,
    {ok, #p_role_pos{map_id=MapID}} = common_misc:get_dirty_role_pos(RoleID),
    [JailMapID] = common_config_dyn:find(jail, jail_map_id),
    if 
        RoleYbcState =:= 1 orelse RoleYbcState =:= 2 orelse RoleYbcState =:= 3 ->
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_YBC_CAN_NOT_FAMILY_MAP_ENTER);
        Trading =:= 1 ->
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_ITEM_FAMILY_INVALID_TRADING_STATE);
        MapID =:= JailMapID ->
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_FAMILY_MEMBER_ENTER_MAP_ERROR_IN_JAIL);
        true -> 
            State = get_state(),
            Members = State#family_state.family_members,
            case lists:keyfind(RoleID, #p_family_member_info.role_id, Members) of
                false ->
                    do_member_enter_map_error(Unique,Module,Method,?_LANG_FAMILY_NOT_MEMBER,RoleID,Line);                    
                _ ->
                    do_member_enter_map2(Unique,Module,Method,Record,RoleID,Line)
            end
    end.    
   

%% CALL_TYPE_BOSS，需要检查家族副本是够开启,并且boss未被打死
%% CALL_TYPE_FAMILY_OWNER，不需要检查
do_member_enter_map2(Unique,Module,Method,Record,RoleID,Line)->
    #m_family_member_enter_map_tos{call_type=CallType} = Record,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Ext = State#family_state.ext_info,
    %% x_boss_dead =:= false
    
    Result = case CallType of
                 ?CALL_TYPE_BOSS->
                     (FamilyInfo#p_family_info.uplevel_boss_called  =:= true  andalso FamilyInfo#p_family_info.kill_uplevel_boss =:= false)
                         orelse (Ext#r_family_ext.common_boss_called =:= true andalso Ext#r_family_ext.common_boss_killed =:= false );
                 ?CALL_TYPE_FAMILY_OWNER->
                     true;
                 ?CALL_TYPE_FAMILY_BONFIRE ->
                     true
             end,
    
    if FamilyInfo#p_family_info.enable_map ->
           case  Result of
               true ->
                   %%获取家族地图的出生点
                   {MapID,Tx0,Ty0} = common_misc:get_born_info_by_map( ?DEFAULT_FAMILY_ID ),
                   {Tx,Ty} = case CallType of
                                 ?CALL_TYPE_FAMILY_BONFIRE -> {43,54 };
                                 _ -> {Tx0,Ty0}
                             end,
                   do_member_enter_map3(Unique,Module,Method,RoleID,Line,MapID,Tx,Ty);
               false->
                   do_member_enter_map_error(Unique,Module,Method,?_LANG_FAMILY_BOSS_NOT_ALIVE_OR_CALLED,RoleID,Line)
           end;
       true  ->
           do_member_enter_map_error(Unique,Module,Method,?_LANG_FAMILY_MAP_DISABLE,RoleID,Line)
    end.
    

do_member_enter_map3(Unique,Module,Method,RoleID,Line,MapID,Tx,Ty)->    
    State = get_state(),
    FamilyID =  (State#family_state.family_info)#p_family_info.family_id,
    %%家族地图名字??
    MapName = lists:concat(["map_family_",FamilyID]),
    case global:whereis_name(MapName) of
        undefined ->
            do_member_enter_map_error(Unique,Module,Method,?_LANG_FAMILY_NO_SUCH_MAP,RoleID,Line);
        _ ->
            R = #m_map_change_map_toc{mapid = MapID,
                                      tx = Tx,
                                      ty = Ty},
            Msg = {mod_map_role, {family_member_enter_map_copy,RoleID, R}},
            common_misc:send_to_rolemap(RoleID,Msg)
    end.
    
    
do_member_enter_map_error(Unique,Module,Method,Reason,RoleID,Line)->
    ?INFO_MSG("wuzesen,do_member_enter_map_error,Reason=~w",[Reason]),
    R = #m_family_member_enter_map_toc{
                                       succ = false,
                                       reason = Reason
                                      },
    common_misc:unicast(Line,RoleID,Unique,Module,Method,R).

    




%%家族功勋清零
do_clear_gongxun() ->
    State = get_state(),
    NewFamilyInfo = (State#family_state.family_info)#p_family_info{gongxun=0},
    update_state(State#family_state{family_info=NewFamilyInfo}).


%%每三个小时检查在线,以添加活跃点
do_add_active_points_by_online()->
    TotalOnline = do_count_online_member(),
    ActivePoint = common_tool:ceil(TotalOnline/10),
    AddPoint = if ActivePoint > 3 ->
               3;
          true->
               ActivePoint
           end,
    ?DEBUG("addactivepoint TotalOnline ~p ActivePoint ~p",[TotalOnline,AddPoint]),
    if AddPoint > 0 ->
        do_add_ac(AddPoint);
       true -> 
        ignore
    end,
    erlang:send_after(?CHK_ONLINE_MEMBER_INTERVAL,self(),{add_active_point_by_online_num}).



%%返回此时在线的人数
do_count_online_member()->
    State = get_state(),
    Members = State#family_state.family_members,
    TotalOnline = lists:foldl(fun(Ele,Count)->
                      Online = Ele#p_family_member_info.online,
                      if Online ->
                          Count+1;
                     true  ->
                          Count
                      end
                  end,0,Members),
    TotalOnline.
    

   
do_add_gongxun(Add) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    NewFamilyInfo = FamilyInfo#p_family_info{gongxun=FamilyInfo#p_family_info.gongxun + Add},
    update_state(State#family_state{family_info=NewFamilyInfo}).


reborn_common_boss() ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Level = FamilyInfo#p_family_info.level,
    FamilyID = FamilyInfo#p_family_info.family_id,
    %%家族boss的id，todo 移动到配置文件中
    MonsterType = mod_family_misc:get_common_boss_type(Level),
    
    send_to_family_map_process(FamilyID, {reborn_family_common_boss, FamilyID, MonsterType}).


do_uplevel_boss_dead(RoleIDList, _RoleNum) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Members = State#family_state.family_members,
    #p_family_info{level=Level, money=Money, active_points=AC} = FamilyInfo,
    FCAdd = mod_family_misc:get_uplevel_boss_fc(Level+1),
    ACAdd = mod_family_misc:get_uplevel_boss_ac(Level+1),
    MoneyAdd = mod_family_misc:get_uplevel_boss_money(Level+1),
    ?DEBUG("upleveltotaldead ~p ~p  ",[FCAdd,RoleIDList]),
    NewMembers = lists:map(
                   fun(M) ->
                           #p_family_member_info{role_id=RID, family_contribution=FC} = M,
                           case lists:member(RID, RoleIDList) of
                               true ->
                                   do_update_contribution_trans(RID,FC+FCAdd),
                                   
                                   hook_family:hook_family_conbtribute_change(RID,FC+FCAdd),
                                   M#p_family_member_info{family_contribution=FC+FCAdd};
                               false ->
                                   M
                           end
                   end, Members),
    NewFamilyInfo = FamilyInfo#p_family_info{kill_uplevel_boss=true, active_points=AC+ACAdd, money=Money+MoneyAdd},
    NewState = State#family_state{family_info=NewFamilyInfo, family_members=NewMembers},
    update_state(NewState),
    
    %%通知得到的家族繁荣度等值
    BcMsg = common_tool:get_format_lang_resources(?_LANG_FAMILY_JOIN_ACTIVITY_BOSS_BC_MSG_1,[FCAdd,common_misc:format_silver(MoneyAdd),ACAdd]),
    lists:foreach(fun(RoleID) -> common_broadcast:bc_send_msg_role(RoleID,?BC_MSG_TYPE_SYSTEM,BcMsg) end,RoleIDList),
    
    %%通知前端家族信息更新了
    NewFamilyInfo2 = NewFamilyInfo#p_family_info{members=NewMembers, request_list=State#family_state.requests, 
                                                 invite_list=State#family_state.invites},
    R = #m_family_self_toc{family_info=NewFamilyInfo2},
    broadcast_to_all_members(?FAMILY, ?FAMILY_SELF, R),
    ok.



%% 家族地图 10300
get_in_map_copy_memberlist()->
    State = get_state(),
    FamilyMembers = State#family_state.family_members,
    InMapMemberList = [R#p_family_member_info.role_id || R<-FamilyMembers,check_in_family_map(R#p_family_member_info.role_id)],
    ?DEBUG("in_family_map_members ~w",[InMapMemberList]),
    InMapMemberList.



%%处理普通boss死亡后的逻辑
do_common_boss_dead(RoleIDList, RoleNum) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    ExtInfo = State#family_state.ext_info,
    Members = State#family_state.family_members,
    #p_family_info{level=Level, money=Money, active_points=AC} = FamilyInfo,
    NewExtInfo = ExtInfo#r_family_ext{common_boss_called=false, 
                                      common_boss_killed=true},
    FCAdd = mod_family_misc:get_common_boss_fc(Level),
    ACAdd = common_tool:ceil( mod_family_misc:get_common_boss_ac(Level) * (1+RoleNum/20)),
    MoneyAdd = common_tool:ceil( mod_family_misc:get_common_boss_money(Level)*(1+RoleNum/20)),
    MembersTagList = [ do_add_actpoint_conb_to_members(RoleIDList,M,FCAdd) ||M<-Members],
    NewMembers = [ M2||{M2,_Tag}<-MembersTagList ],
    
    %%所有在家族地图的成员,脏读
    InMapMemberList = get_in_map_copy_memberlist(),
    %%给每一个成员加相应的经验
    do_add_exp_to_members(InMapMemberList,Level),
    NewFamilyInfo = FamilyInfo#p_family_info{active_points=AC+ACAdd, money=Money+MoneyAdd},
    NewState = State#family_state{ext_info=NewExtInfo, family_info=NewFamilyInfo,family_members=NewMembers},
    update_state(NewState),
    
    do_parttake_family(InMapMemberList,common_boss),
    
    %%通知得到的家族繁荣度等值, 参与打boss的，完成相应的目标
    lists:foreach(fun({M,MemberTag})-> 
                          #p_family_member_info{role_id=RoleID} = M,
                          case MemberTag of
                              true->
                                  BcMsg = common_tool:get_format_lang_resources(?_LANG_FAMILY_JOIN_ACTIVITY_BOSS_BC_MSG_2,[FCAdd,common_misc:format_silver(MoneyAdd),ACAdd,2]);
                              _ ->
                                  BcMsg = common_tool:get_format_lang_resources(?_LANG_FAMILY_JOIN_ACTIVITY_BOSS_BC_MSG_3,[common_misc:format_silver(MoneyAdd),ACAdd])
                          end,
                          common_broadcast:bc_send_msg_role(RoleID,?BC_MSG_TYPE_SYSTEM,BcMsg)
                  end, MembersTagList),
    
    %%通知前端家族信息更新了
    NewFamilyInfo2 = NewFamilyInfo#p_family_info{members=NewMembers, invite_list=State#family_state.invites, 
                                                 request_list=State#family_state.requests},
    R = #m_family_self_toc{family_info=NewFamilyInfo2},
    broadcast_to_all_members(?FAMILY, ?FAMILY_SELF, R),
    ok.


%%@doc 给家族成员加额外经验
%%@param MemberList :lists of p_family_member_info ,
%%@param Level 当前家族的等级
do_add_exp_to_members(MemberList,Level)->
    ExpBase = mod_family_misc:get_common_boss_exp_base(Level),
    lists:foreach(fun(RoleID)->
                          #p_role_attr{level = MemberLevel} = mod_role_tab:get({?role_attr, RoleID}),
                          NotParttakeExp = 
                              case mod_family:is_today_not_parttake(RoleID,common_boss) of
                                  true->
                                      GainExp = MemberLevel*MemberLevel*ExpBase,
                                      hook_activity_family:hook_activity_expr(RoleID,GainExp);
                                  _ ->
                                      0
                              end,
                          add_exp_for_role(RoleID,NotParttakeExp+get_family_boss_exp(MemberLevel,Level))
                  end,MemberList).

%% 家族boss死亡时，只要在家族地图需要给的经验
get_family_boss_exp(Level,FamilyLevel) ->
    case common_config_dyn:find(family_boss, {family_boss_exp,FamilyLevel}) of
        [] ->
            0;
        [Arg] ->
            Arg * common_family:get_family_boss_base_exp(Level)
    end.

%%给家族成员增加活跃度、家族贡献度
%%@return {#p_family_member_info(),IsTodayNotParttake}
do_add_actpoint_conb_to_members(RoleIDList,M,FCAdd) when is_record(M,p_family_member_info)->
    #p_family_member_info{role_id=RoleID, family_contribution=FC} = M,
    
    IsFamilyMember = lists:member(RoleID, RoleIDList),
    IsTodayNotParttake = is_today_not_parttake(RoleID,common_boss),
    case IsFamilyMember andalso IsTodayNotParttake of
        true ->
            do_update_contribution_trans(RoleID,FC+FCAdd),
            %%增加2点活跃度
            catch common_misc:done_task(RoleID,?ACTIVITY_TASK_FAMILY_BOSS),
            
            %%增加家族贡献度
            hook_family:hook_family_conbtribute_change(RoleID,FC+FCAdd),
            {M#p_family_member_info{family_contribution=FC+FCAdd},true};
        false ->
            {M,false}
    end.

-define(CHECK_ISNOT_PARTAKE(Key),
        Today = date(),
        case db:dirty_read(?DB_ROLE_FAMILY_PARTTAKE,RoleID) of
            [#r_role_family_parttake{Key=Today}]->
                false;
            _ ->
                true
        end).

%%@doc 判断今天是否没参与指定活动
is_today_not_parttake(RoleID,common_boss)->
    ?CHECK_ISNOT_PARTAKE(com_boss_date);
is_today_not_parttake(RoleID,family_ybc)->
    ?CHECK_ISNOT_PARTAKE(family_ybc_date);
is_today_not_parttake(RoleID,fetch_buff)->
    ?CHECK_ISNOT_PARTAKE(fetch_buff_date).


do_parttake_family(RoleList,Type) when is_list(RoleList)->
    lists:foreach(fun(RoleID)-> 
                          do_parttake_family_role(RoleID,Type)
                  end, RoleList).

%%@doc 修改族员参与家族活动的记录
do_parttake_family_role(RoleID,Type) when is_atom(Type)->
    case db:dirty_read(?DB_ROLE_FAMILY_PARTTAKE,RoleID) of
        []->
            R2 = #r_role_family_parttake{role_id=RoleID};
        [R1] when is_record(R1,r_role_family_parttake)->
            R2 = R1
    end,
    Today=date(),   
    do_parttake_family_2(R2,Today,Type).
do_parttake_family_2(R2,Today,common_boss)->
    R3 = R2#r_role_family_parttake{com_boss_date=Today},
    db:dirty_write(?DB_ROLE_FAMILY_PARTTAKE,R3);
do_parttake_family_2(R2,Today,family_ybc)->
    R3 = R2#r_role_family_parttake{family_ybc_date=Today},
    db:dirty_write(?DB_ROLE_FAMILY_PARTTAKE,R3);
do_parttake_family_2(R2,Today,fetch_buff)->
    R3 = R2#r_role_family_parttake{fetch_buff_date=Today},
    db:dirty_write(?DB_ROLE_FAMILY_PARTTAKE,R3).
              


do_gm_enable_map(RoleID) ->
    Unique = ?DEFAULT_UNIQUE, 
    Module = ?FAMILY,
    Method = ?FAMILY_ENABLE_MAP,
    active_map(),
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    NewFamilyInfo = FamilyInfo#p_family_info{enable_map=true},
    NewState = State#family_state{family_info=NewFamilyInfo},
    update_state(NewState),
    do_dump_data(),
    R = #m_family_enable_map_toc{},
    common_misc:unicast({role, RoleID}, Unique, Module, Method, R),
    RO = #m_family_enable_map_toc{return_self=false},
    broadcast_to_all_members_except(Module, Method, RO, RoleID).

%%族长召唤族员到家族地图（免费）
do_call_member(Unique, Module, Method, Record, RoleID, Line)->
    ?DEBUG("in function do_call_member,RoleID=~w",[RoleID]),
    #m_family_callmember_tos{message=FMessage} = Record,
    %%判断是否为族长、判断目前是否在家族地图中
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            MsgToc = case is_owner(RoleID, FamilyInfo) of
                         true->
                             common_tool:get_format_lang_resources(?_LANG_FAMILY_CONVENE_MEMBER_BC_1,[FMessage]);
                         _ ->
                             common_tool:get_format_lang_resources(?_LANG_FAMILY_CONVENE_MEMBER_BC_2,[FMessage])
                     end,
            R = #m_family_callmember_toc{succ=true, message=MsgToc,call_type=?CALL_TYPE_FAMILY_OWNER},
            OutsideMapMembers = get_online_and_outside_map_members(State),
            ?INFO_MSG("broadcast_to_line,RoleID=~w,R=~w,OutsideMapMembers=~w",[RoleID,R,OutsideMapMembers]),
            common_misc:broadcast_to_line(OutsideMapMembers, Module, Method, R);
        _ ->
            do_call_member_error(Unique, Module, Method, ?_LANG_FAMILY_NO_RIGHT_CALL_MEMBER, RoleID, Line)
    end.

do_call_member_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_callmember_toc{succ=false, reason=Reason,call_type=?CALL_TYPE_FAMILY_OWNER},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_clear_commonboss_calltime()->
    State = get_state(),
    FamilyID = (State#family_state.family_info)#p_family_info.family_id,
    FamilyExt = State#family_state.ext_info,
    FamilyExt2 = FamilyExt#r_family_ext{common_boss_call_time=0},
    NewState = State#family_state{ext_info=FamilyExt2},
    update_state(NewState),
    ?ERROR_MSG("do_clear_commonboss_calltime success,FamilyID=~w",[FamilyID]),
    ok.


%%召唤家族boss（不是升级boss）
do_call_commonboss(Unique, Module, Method, RoleID, Line) ->
    State = get_state(),
    FamilyID = (State#family_state.family_info)#p_family_info.family_id,
    FamilyExt = State#family_state.ext_info,
    FamilyInfo = State#family_state.family_info,

    LastCallDate = FamilyExt#r_family_ext.common_boss_call_time,
    LastCallCount = FamilyExt#r_family_ext.common_boss_call_count,
    MaxCallCount = hook_activity_family:get_common_boss_max_call_count(),
    Today = erlang:date(),
    if
        Today =/= LastCallDate ->
            do_call_commonboss2(Unique, Module, Method, RoleID, Line, FamilyID, FamilyInfo, FamilyExt, State);
        Today =:= LastCallDate andalso LastCallCount < MaxCallCount ->
            do_call_commonboss2(Unique, Module, Method, RoleID, Line, FamilyID, FamilyInfo, FamilyExt, State);
        true->
            Reason = common_tool:get_format_lang_resources(?_LANG_FAMILY_CALL_GENERAL_BOSS_MAX_TIMES,[MaxCallCount]),
            do_call_commonboss_error(Unique, Module, Method, Reason, RoleID, Line)
    end.

do_call_commonboss2(Unique, Module, Method, RoleID, Line, FamilyID, FamilyInfo, FamilyExt, State) ->
    case is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            Level = (State#family_state.family_info)#p_family_info.level,
            case Level > 0 of
                true ->
                    #r_family_ext{common_boss_call_time=OldCallDate,common_boss_call_count=OldCallCount} = FamilyExt,
                    MonsterType = mod_family_misc:get_common_boss_type(Level),
                    {Date, _} = calendar:local_time(),
                    send_to_family_map_process(FamilyID,
                                               {call_family_common_boss, Unique, Module, Method, {FamilyID, MonsterType}, RoleID, Line}),
                    
                    FamilyExt2 = FamilyExt#r_family_ext{common_boss_called=true, common_boss_killed=false, 
                                                    common_boss_call_time=Date},
                    NewExt = case (OldCallDate=:=Date) of
                                 true->
                                    FamilyExt2#r_family_ext{common_boss_call_count=OldCallCount+1};
                                 _ ->
                                    FamilyExt2#r_family_ext{common_boss_call_count=1}
                             end,
                    NewState = State#family_state{ext_info=NewExt},
                    update_state(NewState),
                    
                    %%召唤的后续处理
                    dealing_after_callboss({RoleID,common});
                
                false ->
                    Reason = ?_LANG_FAMILY_ZERO_LEVEL_CANNT_CALL_BOSS,
                    do_call_commonboss_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_FAMILY_ONLY_OWNER_OR_SEC_OWNER_CAN_CALL_COMMON_BOSS,
            do_call_commonboss_error(Unique, Module, Method, Reason, RoleID, Line)
    end.


do_call_commonboss_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_call_commonboss_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).




%% 1.家族频道广播  2。给自己的提示  3.召唤家族成员参与战斗
dealing_after_callboss({RoleID,BossType})->
    family_channelbrd_and_gather_members({RoleID,BossType}),
    self_tips(RoleID,BossType).

    

%% 检查是否在家族地图中
check_in_family_map(RoleID)->
    case common_misc:get_dirty_mapid_by_roleid(RoleID) of
        {ok, MapID} ->
            MapID =:= ?DEFAULT_FAMILY_ID;
        _ ->
            false
    end.
    
%%获取在线并且在家族地图外的族员列表
%%      排除掉特殊状态（包括摆摊、死亡、训练营）
get_online_and_outside_map_members(State)->
    OnlineRoleIds = lists:foldl(fun(E,Acc)->
                                        if E#p_family_member_info.online ->
                                               [E#p_family_member_info.role_id | Acc ];
                                           true  ->
                                               Acc
                                        end
                                end,[],State#family_state.family_members),
    
    %%添加了异常状态的判断
    lists:foldl(fun(RoleID,Acc)->
                        %%加了状态判断
                        {ok, #p_role_base{status=Status}} = common_misc:get_dirty_role_base(RoleID),
                        case Status =:= ?ROLE_STATE_DEAD of
                            true->
                                Acc;
                            _ ->
                                {ok, #r_role_state{stall_self=IsStallSelf}} = common_misc:get_dirty_role_state(RoleID),
                                IsSpecialMember = (IsStallSelf=:=true) orelse check_in_family_map(RoleID),
                                case IsSpecialMember of
                                    true->
                                        Acc;
                                    _ ->
                                        [RoleID | Acc]
                                end
                        end
                end,[],OnlineRoleIds).
  

    
%% 召唤后的家族广播和成员通知
family_channelbrd_and_gather_members({RoleID,BossType})->
    State = get_state(),
    MsgRoleTitle = 
    if (State#family_state.family_info)#p_family_info.owner_role_id =:= RoleID ->
        "族长";
       true->
        "副族长"
    end,
    
    MsgBossType = 
    if BossType =:= common ->
        "普通boss";
       true  ->
        "升级boss"
    end,
    %% 组装通知
    MsgContent = lists:concat([MsgRoleTitle,"召唤",MsgBossType,"成功,请速速参与战斗"]),
 
    OnlineAndOutsideMapIds = get_online_and_outside_map_members(State),
    
    %% 给成员发家族频道通知
    broadcast_to_family_channel(MsgContent),
    

    %%召唤成员来种族地图打怪
    R_toc = #m_family_callmember_toc{ succ=true,message = MsgContent,call_type=?CALL_TYPE_BOSS },
    ?DEBUG("mimibug ~w ~w ",[OnlineAndOutsideMapIds,R_toc]),

    %% todo:需要判定成员此刻的位置,如果已经在家族地图内,则不发送该通知
    lists:foreach(fun(T)->
              common_misc:unicast({role,T},?DEFAULT_UNIQUE,?FAMILY,?FAMILY_CALLMEMBER,R_toc),
              ?DEBUG("mimibugmenot ~p ~p",[T,R_toc])
          end,OnlineAndOutsideMapIds).
    
              
%% todo: 给自己的提示信心
self_tips(RoleID,BossType)->
    BossTypePrompt = if BossType =:= common ->
                 "普通boss";
            true ->
                 "升级boss"
             end,

    MsgContent = lists:concat(["成功召唤",BossTypePrompt]),
    %%MsgContent = lists:flatten(io_lib:format("成功召唤~p",[BossTypePrompt])),
    common_broadcast:bc_send_msg_role(RoleID,?BC_MSG_TYPE_SYSTEM,MsgContent),
    ignore.

%%增加家族财富
do_add_money(Num) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    M = FamilyInfo#p_family_info.money,
    NewFamilyInfo = FamilyInfo#p_family_info{money=M+Num},
    NewState = State#family_state{family_info=NewFamilyInfo},
    update_state(NewState),
    R = #m_family_money_toc{new_money=M+Num},
    broadcast_to_all_members(?FAMILY, ?FAMILY_MONEY, R).

    
%%重生没打死的升级boss
reborn_uplevel_boss() ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Level = FamilyInfo#p_family_info.level,
    FamilyID = FamilyInfo#p_family_info.family_id,
    %%家族boss的id，todo 移动到配置文件中
    MonsterType = mod_family_misc:get_uplevel_boss_type(Level+1),
    
    send_to_family_map_process(FamilyID,{reborn_family_uplevel_boss, FamilyID, MonsterType}).


%%召唤家族升级boss
do_call_uplevelboss(Unique, Module, Method, RoleID, Line) ->
    %%向家族地图发消息
    [IsOpenFamilyUpLevelBoss] = common_config_dyn:find(family_base_info,is_open_family_uplevel_boss),
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case IsOpenFamilyUpLevelBoss =:= true andalso FamilyInfo#p_family_info.enable_map of
        true ->
            %%判断是否族长或者副族长
            case is_owner_or_second_owner(RoleID, FamilyInfo) of
                true ->
                    do_call_uplevelboss2(Unique, Module, Method, RoleID, Line, FamilyInfo);
                false ->
                    Reason = ?_LANG_FAMILY_ONLY_OWNER_OR_SEC_OWNER_CAN_CALL_UPLEVEL_BOSS,
                    do_call_uplevelboss_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        false ->
            R = 
                case IsOpenFamilyUpLevelBoss =:= false of
                    true ->
                        #m_family_call_uplevelboss_toc{succ=false, reason=?_LANG_FAMILY_UPLEVEL_BOSS_NOT_OPEN};
                    _ ->
                        #m_family_call_uplevelboss_toc{succ=false, reason=?_LANG_FAMILY_MAP_NOT_ENABLE}
                end,
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
    end.

do_call_uplevelboss2(Unique, Module, Method, RoleID, Line, FamilyInfo) ->
   %  State = get_state(),
    case FamilyInfo#p_family_info.uplevel_boss_called of
        true ->
            case FamilyInfo#p_family_info.kill_uplevel_boss of
                true ->
                    R = #m_family_call_uplevelboss_toc{succ=false, reason=?_LANG_FAMILY_UPLEVEL_BOSS_KILLED},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
                    ok;
                false ->
                    R = #m_family_call_uplevelboss_toc{succ=false, reason=?_LANG_FAMILY_UPLEVEL_BOSS_CALLED},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
            end;
        false ->
            Level = FamilyInfo#p_family_info.level,
            case Level < 6 of
                true ->
            do_call_uplevelboss3(Unique,Module,Method,RoleID,Line,FamilyInfo);
                false ->
                    Reason = ?_LANG_FAMILY_ALREADY_TOP_LEVEL,
                    do_call_uplevelboss_error(Unique, Module, Method, Reason, RoleID, Line)
            end
    end.


do_call_uplevelboss3(Unique,Module,Method,RoleID,Line,FamilyInfo)->
    Ap = FamilyInfo#p_family_info.active_points,
    Level = FamilyInfo#p_family_info.level,
    State = get_state(),
    RemainAp = Ap - mod_family_misc:get_uplevel_activepoints(Level+1),
    case RemainAp >= 0  of
        true ->
            NewFamilyInfo = FamilyInfo#p_family_info{uplevel_boss_called=true,kill_uplevel_boss=false},
            NewState = State#family_state{family_info = NewFamilyInfo},
            update_state(NewState),
            
            FamilyID = FamilyInfo#p_family_info.family_id,
            MonsterType = mod_family_misc:get_uplevel_boss_type(Level+1),
            
            send_to_family_map_process(FamilyID,{call_family_uplevel_boss,Unique,Module,Method,{FamilyID,MonsterType},RoleID,Line}),
            %% 召唤boss之后的处理
            dealing_after_callboss({RoleID,uplevel});
        false->
            %%Reason = ?_LANG_FAMILY_ACTIVE_POINTS_NOT_ENOUGH,
            Reason = lists:concat(["家族繁荣度不足",mod_family_misc:get_uplevel_activepoints(Level+1),",不能召唤"]),
            do_call_uplevelboss_error(Unique,Module,Method,Reason,RoleID,Line)
    
    end.
        



do_call_uplevelboss_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_call_uplevelboss_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_gm_uplevel(RoleID)->
    Unique = ?DEFAULT_UNIQUE,
    Module = ?FAMILY,
    Method = ?FAMILY_UPLEVEL,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.level >= 6 of
        false ->
            do_uplevel2();
        true ->
            Reason = ?_LANG_FAMILY_MAX_LEVEL,
            do_uplevel_error(Unique, Module, Method, Reason, RoleID, 6001)
    end.

%%@interface 家族升级
do_uplevel(Unique, Module, Method, RoleID, Line) ->
    %%获取当前家族，判断是否已经满级了
    %%判断升级家族的条件是否达到：是否打败了升级boss，是否满足家族繁荣度和家族资金
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.level >= 12 of
        false ->
            case catch check_uplevel_condition() of
                {'EXIT', Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            ?ERROR_MSG("~ts:~w", ["检查家族升级条件出错", Error]),
                            Reason = ?_LANG_SYSTEM_ERROR
                    end,
                    do_uplevel_error(Unique, Module, Method, Reason, RoleID, Line);
                ok ->
                    do_uplevel2()
            end;
        true ->
            Reason = ?_LANG_FAMILY_MAX_LEVEL,
            do_uplevel_error(Unique, Module, Method, Reason, RoleID, Line)
    end.

do_uplevel2() ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    #p_family_info{money=Money, active_points=ActivePoints, level=Level, faction_id = FactionID,
                   owner_role_id=OwnerID, family_id=FamilyID, family_name=FamilyName} = FamilyInfo,
    NextLevel = Level+1,    
    %%扣除费用，更新状态,并补偿当天的维护费用
    CompensateMoney = mod_family_misc:get_resume_silver(NextLevel),
    CompensateActivePt = mod_family_misc:get_resume_points(NextLevel),
    NewMoney = Money - mod_family_misc:get_uplevel_money(NextLevel) + CompensateMoney,
    NewActivePoints = ActivePoints - mod_family_misc:get_uplevel_activepoints(NextLevel) + CompensateActivePt,
    NewFamilyInfo = FamilyInfo#p_family_info{money=NewMoney, active_points=NewActivePoints, 
                                             level=Level+1, kill_uplevel_boss=false,
                                            uplevel_boss_called=false},    
    NewState = State#family_state{family_info=NewFamilyInfo},
    update_state(NewState),
    hook_family:level_up(State#family_state.family_members, Level + 1),
    %%广播通知所有的好友
    FList = mod_friend_server:get_dirty_friend_list(OwnerID),
    RF = #m_friend_update_family_toc{role_id=OwnerID, family_id=FamilyID, family_name=FamilyName, level=Level+1},
    lists:foreach(
      fun(#r_friend{friendid=FID}) ->
              common_misc:unicast({role, FID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_UPDATE_FAMILY, RF)
      end, FList),
    R = #m_family_uplevel_toc{return_self=false, new_level=Level+1, money=NewMoney, active_points=NewActivePoints},
    broadcast_to_all_members(?FAMILY, ?FAMILY_UPLEVEL, R),
    %%家族升级成功之后世界中央广播 by natsuki
    
    %%恭喜 蚩尤家族 [家族名字] 升级至 xx 级
    FactionName = common_misc:get_faction_name(FactionID),
    WorldBrdContent = lists:concat(["恭喜",common_tool:to_list(FactionName),"的家族 ",common_tool:to_list(FamilyName)," 升级至",Level+1,"级"]),
    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,WorldBrdContent).

do_uplevel_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_uplevel_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


check_uplevel_condition() ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    %%检查家族资金、家族繁荣度和家族升级任务
    case common_config_dyn:find(family_base_info,is_open_family_uplevel_boss) of
        [true] ->
            case FamilyInfo#p_family_info.kill_uplevel_boss of
                true ->
                    ok;
                _ ->
                    throw({'EXIT', ?_LANG_FAMILY_SHOULD_KILL_BOSS_FIRST})
            end;
        _ ->
            ok
    end,
    case FamilyInfo#p_family_info.money >= mod_family_misc:get_uplevel_money(FamilyInfo#p_family_info.level + 1) of
        true ->
            ok;
        false ->
            throw({'EXIT', ?_LANG_FAMILY_NOT_ENOUGH_MONEY_FOR_UPLEVEL})
    end,
    case FamilyInfo#p_family_info.active_points >= mod_family_misc:get_uplevel_activepoints(FamilyInfo#p_family_info.level+1) of
        true ->
            ok;
        false ->
            throw({'EXIT', ?_LANG_FAMILY_NOT_ENOUGH_ACTIVE_POINTS_FOR_UPLEVEL})
    end.



do_reduce_gold_for_enable_map_timeout() ->
    case get_enable_map_request() of
        undefined ->
            ignore;
        {Unique, Module, Method, RoleID, Line} ->
            R = #m_family_enable_map_toc{succ=false, reason=?_LANG_FAMILY_ENABLE_MAP_TIMEOUT},
            common_misc:unicast(Line,RoleID,Unique,Module,Method,R),
            erase_enable_map_request()
    end.


do_reduce_role_gold_for_enble_map_succ(RoleID, RoleAttr) ->
    #p_role_attr{gold=NewGold, gold_bind=NewGoldBind} = RoleAttr,
    Record = #m_role2_attr_change_toc{
      roleid  = RoleID,
      changes = [
                 #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=NewGold},
                 #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=NewGoldBind}
                ]
     },
    R = #m_family_enable_map_toc{},
    case get_enable_map_request() of
        undefined ->
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_ENABLE_MAP, R),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, Record),
            %% 直接开启家族地图
            ok;
        {Unique, Module, Method, RoleID, Line} ->            
            common_misc:unicast(Line,RoleID,Unique,Module,Method,R),
            common_misc:unicast(Line,RoleID,?DEFAULT_UNIQUE,?ROLE2,?ROLE2_ATTR_CHANGE,Record),
            ok
    end,     
    erase_enable_map_request(),
    active_map(),
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    NewState = State#family_state{family_info = FamilyInfo#p_family_info{enable_map=true}},
    update_state(NewState),
    Content = lists:flatten(io_lib:format("~s 家族成功创建家族地图",[FamilyInfo#p_family_info.family_name])),
    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,Content),
    Ro = #m_family_enable_map_toc{return_self=false},
    broadcast_to_all_members_except(?FAMILY, ?FAMILY_ENABLE_MAP, Ro, RoleID),
    ok.

do_reduce_role_gold_for_enble_map_failed(RoleID, Reason) ->
    case get_enable_map_request() of
        undefined ->
            R = #m_family_enable_map_toc{succ=false, reason=Reason},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_ENABLE_MAP, R);
        {Unique, Module, Method, RoleID, Line} ->
            erase_enable_map_request(),
            do_enable_map_error(Unique,Module,Method,Reason,RoleID,Line)
    end.

    
%% 激活家族地图
do_enable_map(Unique, Module, Method, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.enable_map of
        true ->
            Reason = ?_LANG_FAMILY_ALREADY_ENABLE_MAP,
            do_enable_map_error(Unique, Module, Method, Reason, RoleID, Line);
        false ->
            %% 需要至少5位在线成员
            case if_online_more_than(4) of
                true ->
                    do_enable_map2(Unique, Module, Method, RoleID, Line);
                false ->
                    Reason = ?_LANG_FAMILY_ENABLE_MAP_NEED_ONLINE,
                    do_enable_map_error(Unique, Module, Method, Reason, RoleID, Line)
            end
    end.
do_enable_map2(Unique,Module,Method,RoleID,Line)->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    %%族长限定
    case FamilyInfo#p_family_info.owner_role_id =:= RoleID  of
    true ->
            case get_enable_map_request() of
                undefined ->           
                    erlang:send_after(5000, erlang:self(), reduce_gold_for_enable_map_timeout),
                    [FamilyEnableMapGold] = common_config_dyn:find(family_base_info,family_enable_map_gold),
                    common_role_money:reduce(RoleID, {undefined, {gold_any, FamilyEnableMapGold,?CONSUME_TYPE_GOLD_ENABLE_MAP,""}}, 
                                             reduce_gold_for_enable_map_successful, 
                                             reduce_gold_for_enable_map_failed),
                    set_enable_map_request(Unique, Module, Method, RoleID, Line);
                _ ->
                    R = #m_family_enable_map_toc{succ=false, reason=?_LANG_FAMILY_ENABLE_MAP_IN_LAST_REQUEST},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
            end;
    false  ->
        Reason = ?_LANG_FAMILY_ONLY_OWNER_CAN_ENABLE_MAP,
        do_enable_map_error(Unique,Module,Method,Reason,RoleID,Line)
    end.

-define(family_enable_map_request, family_enable_map_request).

get_enable_map_request() ->
    erlang:get(?family_enable_map_request).
set_enable_map_request(Unique, Module, Method, RoleID, Line) ->
    erlang:put(?family_enable_map_request, {Unique, Module, Method, RoleID, Line}).
erase_enable_map_request() ->
    erlang:erase(?family_enable_map_request).

do_enable_map_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_enable_map_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


if_online_more_than(N) ->
    State = get_state(),
    Members = State#family_state.family_members,
    Onlines = lists:foldl(
                fun(M, Acc0) ->
                        case M#p_family_member_info.online of
                            true ->
                                Acc0 + 1;
                            false ->
                                Acc0
                        end
                end, 0, Members),
    Onlines > N.
    
    

%%取消玩家称号
do_cancel_title(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_cancel_title_tos{role_id=TargetRoleID} = Record,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case is_owner_or_second_owner(TargetRoleID, FamilyInfo) of
        false ->
            case is_owner_or_second_owner(RoleID, FamilyInfo) of
                true ->
                    do_cancel_title2(Unique, Module, Method, TargetRoleID, RoleID, Line);
                false ->
                    Reason = ?_LANG_FAMILY_NO_RIGHT_CANCEL_TITLE,
                    do_cancel_title_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        true ->
            Reason = ?_LANG_FAMILY_CANNT_CANCEL_TITLE_ON_OWNER_OR_SEC_OWNER,
            do_cancel_title_error(Unique, Module, Method, Reason, RoleID, Line)
    end.

do_cancel_title2(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    State = get_state(),
    OldMembers = State#family_state.family_members,
    case lists:keyfind(TargetRoleID, 2, OldMembers) of
        false ->
            Reason = ?_LANG_FAMILY_NOT_FAMILY_MEMBER_WHEN_CANCEL_TITLE,
            do_cancel_title_error(Unique, Module, Method, Reason, RoleID, Line);
        OldMemberInfo ->
            NewMemberInfo = OldMemberInfo#p_family_member_info{title=?DEFAULT_FAMILY_MEMBER_TITLE},
            NewMembers = lists:keyreplace(TargetRoleID, 2, OldMembers, NewMemberInfo),
            NewState = State#family_state{family_members=NewMembers},
            update_state(NewState),
            R = #m_family_cancel_title_toc{role_id=TargetRoleID},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,?DEFAULT_FAMILY_MEMBER_TITLE),
            broadcast_to_all_members_except(Module, Method, R, RoleID)
    end.

do_cancel_title_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_cancel_title_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).
   

do_role_online(RoleID) ->
    set_role_online(RoleID, true),
    ?DEBUG("role_online_callback in family",[]),
    NotNeedRefresh = (get(?last_refresh_login_time) =/= undefined andalso ((common_tool:to_integer(get(?last_refresh_login_time)) + ?REFRESH_LOGIN_TIME_INTERVAL) > common_tool:now())),
    if (NotNeedRefresh) ->
            ignore;
    true->
         refresh_last_login_time()
    end,
    State = get_state(),
    Members = State#family_state.family_members,   
    NewMembers = lists:map(
                   fun(M) ->
                           MID = M#p_family_member_info.role_id,
                           case MID =:= RoleID of
                               true ->
                                   M#p_family_member_info{online=true};
                               false ->
                                   M
                           end
                   end, Members),
    NewState = State#family_state{family_members=NewMembers},
    update_state(NewState),
    R = #m_family_role_online_toc{role_id=RoleID},
    catch send_family_info(RoleID),
    broadcast_to_all_members(?FAMILY, ?FAMILY_ROLE_ONLINE, R).

send_family_info(RoleID) ->
    State = get_state(),
    FamilyID =  (State#family_state.family_info)#p_family_info.family_id,
    %%家族地图名字??
    MapName = lists:concat(["map_family_",FamilyID]),
    case global:whereis_name(MapName) of
        undefined ->
            ignore;
        _Pid ->
            todo
            %%erlang:send(Pid,{mod_map_bonfire,{send_family_info,RoleID}})
    end,
    mod_family_welfare:handle_info({role_online, RoleID}).

do_role_offline(RoleID) ->
    set_role_online(RoleID, false),
    State = get_state(),
    Members = State#family_state.family_members,   
    NewMembers = lists:map(
                   fun(M) ->
                           MID = M#p_family_member_info.role_id,
                           case MID =:= RoleID of
                               true ->
                                   M#p_family_member_info{online=false};
                               false ->
                                   M
                           end
                   end, Members),
    NewState = State#family_state{family_members=NewMembers},
    update_state(NewState),
    R = #m_family_role_offline_toc{role_id=RoleID},
    broadcast_to_all_members_except(?FAMILY, ?FAMILY_ROLE_OFFLINE, R, RoleID).


do_leave_map(Unique, Module, Method, RoleID, Line) ->
    #p_role_base{faction_id=FactionID} = mod_role_tab:get({?role_base, RoleID}),
    MapID = common_misc:get_home_map_id(FactionID),
    {MapID, TX, TY} = common_misc:get_born_info_by_map(MapID),
    R = #m_map_change_map_toc{mapid=MapID, tx=TX, ty=TY},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%%进入家族地图
do_enter_map(Unique, _Module, _Method, RoleID, Line) ->
    State = get_state(),
    #p_family_info{family_id=FamilyID,hour=H,minute=M} = (State#family_state.family_info),
    case (State#family_state.family_info)#p_family_info.enable_map of
        true->
            case  common_map:is_doing_ybc(RoleID) of
                true ->
                    R = #m_map_change_map_toc{succ=false, reason=?_LANG_YBC_CAN_NOT_FAMILY_MAP_ENTER},
                    common_misc:unicast(Line, RoleID, Unique, ?MAP, ?MAP_CHANGE_MAP, R);
                false ->
                    Info = {enter_family_map, Unique, RoleID, FamilyID, Line, common_tool:today(H,M,0)},
                    common_misc:send_to_rolemap(RoleID, Info)
            end;
        false ->
            R = #m_map_change_map_toc{succ=false, reason=?_LANG_FAMILY_MAP_NOT_ENABLE},
            common_misc:unicast(Line, RoleID, Unique, ?MAP, ?MAP_CHANGE_MAP, R)
    end.


%%取消对某个玩家的邀请
do_cancel_invite(Unique, Module, Method, Record, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    %%检查权限是否足够
    case is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            #m_family_cancel_invite_tos{role_id=TargetRoleID} = Record,
            case db:transaction(fun() -> t_do_cancel_invite(TargetRoleID, FamilyInfo#p_family_info.family_id) end) of
                {atomic, _} ->            
                    Invites = State#family_state.invites,
                    NewInvites = lists:keydelete(TargetRoleID, #p_family_invite.role_id, Invites),
                    NewState = State#family_state{invites=NewInvites},
                    update_state(NewState),
                    R = #m_family_cancel_invite_toc{},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
                    RB = #m_family_cancel_invite_toc{return_self=false, role_id=TargetRoleID},
                    broadcast_to_owner_and_second_owners_except(Module, Method, RB, RoleID);
                {aborted, Error} ->
                    case Error of
                        error ->
                            Invites = State#family_state.invites,
                            NewInvites = lists:keydelete(TargetRoleID, #p_family_invite.role_id, Invites),
                            NewState = State#family_state{invites=NewInvites},
                            update_state(NewState);
                        _ ->
                            ?ERROR_MSG("~ts:~w", ["取消邀请出错", Error])
                    end,
                    R = #m_family_cancel_invite_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
            end;
        false ->
            R = #m_family_cancel_invite_toc{succ=false, reason=?_LANG_FAMILY_NO_RIGHT_TO_CANCEL_INVITE},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
    end.

t_do_cancel_invite(TargetRoleID, FamilyID) ->
    case db:match_object(?DB_FAMILY_INVITE, 
                             #p_family_invite_info{target_role_id=TargetRoleID, family_id=FamilyID, _='_'},
                             write)
    of
        [R] ->
            db:delete_object(?DB_FAMILY_INVITE, R, write),
            R;
        [] ->
            db:abort(error)
    end.
        

%%刷新上次登录时间
refresh_last_login_time()->
    ?DEBUG("refresh_last_login_time",[]),
    State = get_state(),
    Members = State#family_state.family_members,
    NewMembers = lists:map(
    fun(Ele)->
            RoleID = Ele#p_family_member_info.role_id,
            case common_misc:get_dirty_role_ext(RoleID) of                
                {ok,Ext} ->
                    LastLoginTime = Ext#p_role_ext.last_login_time,
                    Ele#p_family_member_info{last_login_time=LastLoginTime};
                _ ->
                    Ele
            end
    end,Members),
    NewState = State#family_state{
        family_members = NewMembers
    },
    update_state(NewState),
    put(?last_refresh_login_time,common_tool:now()).

    

%%查看本家族信息
do_self(Unique, Module, Method, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Members = State#family_state.family_members,
    Requests = State#family_state.requests,
    Invites = State#family_state.invites,
    Info = FamilyInfo#p_family_info{members=Members, request_list=Requests, invite_list=Invites},
    R = #m_family_self_toc{family_info=Info},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%取消副族长
do_unset_second_owner(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_unset_second_owner_tos{role_id=TargetRoleID} = Record,
    %%判断是否是族长
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    SecondOwners = FamilyInfo#p_family_info.second_owners,
    case FamilyInfo#p_family_info.owner_role_id =:= RoleID of
        true ->
            %%判断对方是否是副族长
            case lists:any(fun(S) -> S#p_family_second_owner.role_id =:= TargetRoleID end, SecondOwners) of
                true ->
                    do_unset_second_owner2(Unique, Module, Method, TargetRoleID, RoleID, Line);
                false ->
                    Reason = ?_LANG_FAMILY_NOT_SECOND_OWNER,
                    do_unset_second_owner_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_UNSET_SECOND_OWNER,
            do_unset_second_owner_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_unset_second_owner2(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    %%更新该成员的家族称号，更新副族长列表
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.ybc_status of
        ?FAMILY_YBC_STATUS_DOING ->
            do_unset_second_owner_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_UNSET_SECOND_OWNER_WHEN_YBC_DOING, RoleID, Line);
        ?FAMILY_YBC_STATUS_PUBLISHING ->
            do_unset_second_owner_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_UNSET_SECOND_OWNER_WHEN_YBC_PUBLISHING, RoleID, Line);
        _ ->
            SecondOwners = FamilyInfo#p_family_info.second_owners,
            NewSecondOwners = lists:filter(fun(S) -> S#p_family_second_owner.role_id =/= TargetRoleID end, SecondOwners),
            OldMembers = State#family_state.family_members,
            NewMembers = lists:map(
                           fun(M) ->
                                   ID = M#p_family_member_info.role_id,
                                   case ID =:= TargetRoleID of
                                       true ->
                                           M#p_family_member_info{title=?DEFAULT_FAMILY_MEMBER_TITLE};
                                       false ->
                                           M
                                   end
                           end, OldMembers),
            NewFamilyInfo = FamilyInfo#p_family_info{second_owners=NewSecondOwners},
            NewState = State#family_state{family_members=NewMembers, family_info=NewFamilyInfo},
            update_state(NewState),
            R = #m_family_unset_second_owner_toc{role_id=TargetRoleID},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,?DEFAULT_FAMILY_MEMBER_TITLE),
            RB = #m_family_unset_second_owner_toc{return_self=false, role_id=TargetRoleID},
            broadcast_to_all_members_except(Module, Method, RB, RoleID)
    end.
                           
    
do_unset_second_owner_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_unset_second_owner_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%%设置副族长
do_set_second_owner(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_set_second_owner_tos{role_id=TargetRoleID} = Record,
    %%判断是否是族长
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.owner_role_id =:= RoleID of
        true ->
            %%判断是否为内务使
            case is_intermanager(TargetRoleID, FamilyInfo) of
                true ->
                    do_unset_interior_manager(?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_UNSET_INTERIOR_MANAGER, 
                                              #m_family_unset_interior_manager_tos{role_id = TargetRoleID}, 
                                              RoleID, Line);
                _ ->
                    ignore
            end,
            do_set_second_owner2(Unique, Module, Method, TargetRoleID, RoleID, Line);
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_SET_SECOND_OWNER,
            do_set_second_owner_error(Unique, Module, Method, Reason, RoleID, Line)
    end.

do_set_second_owner2(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    OldSecondOwners = FamilyInfo#p_family_info.second_owners,
    OldMembers = State#family_state.family_members,
    %%判断数量是否已经达到限制
    case erlang:length(OldSecondOwners) >= get_max_number_of_second_owner(FamilyInfo#p_family_info.level) of
        false ->
            %%更新副族长列表，更对对应玩家的称号，广播通知族员
            TargetRoleName = lists:foldl(
                               fun(M, Acc) ->
                                       ID = M#p_family_member_info.role_id,
                                       case ID =:= TargetRoleID of
                                           true ->
                                               M#p_family_member_info.role_name;
                                           false ->
                                               Acc
                                       end
                               end, [], OldMembers),
            NS = #p_family_second_owner{role_id=TargetRoleID, role_name=TargetRoleName},
            NewSecondOwners = [NS | OldSecondOwners],
            NewMembers = lists:map(
                           fun(M) ->
                                   ID = M#p_family_member_info.role_id,
                                   case ID =:= TargetRoleID of
                                       true ->
                                           M#p_family_member_info{title=?FAMILY_TITLE_SECOND_OWNER};
                                       false ->
                                           M
                                   end
                           end, OldMembers),
            NewFamilyInfo = FamilyInfo#p_family_info{second_owners=NewSecondOwners},
            NewState = State#family_state{family_info=NewFamilyInfo, family_members=NewMembers},
            update_state(NewState),
            R = #m_family_set_second_owner_toc{role_id=TargetRoleID, role_name=TargetRoleName},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,?FAMILY_TITLE_SECOND_OWNER),
            RB = #m_family_set_second_owner_toc{return_self=false, role_id=TargetRoleID, role_name=TargetRoleName},
            broadcast_to_all_members_except(Module, Method, RB, RoleID);
        true ->
            Reason = ?_LANG_FAMILY_SECOND_OWNER_NUMBER_LIMIT,
            do_set_second_owner_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
            
do_set_second_owner_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_set_second_owner_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


check_last_set_owner_time(LastSetTime) ->
    case LastSetTime of        
        {Year, M, D} ->
            {{Y2, M2, D2}, _} = calendar:local_time(),
            case (Y2 > Year) orelse (M2 > M) orelse (D2 > D) of
                true ->
                    true;
                false ->
                    false
            end;
        _ ->
            true
    end.

%%转让族长
do_set_owner(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_set_owner_tos{role_id=TargetRoleID} = Record,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    %%    FamilyExt = State#family_state.ext_info,
    %%    LastSetTime = FamilyExt#r_family_ext.last_set_owner_time,
    case FamilyInfo#p_family_info.owner_role_id =:= RoleID of
        true ->
            case FamilyInfo#p_family_info.interiormanager =:= TargetRoleID of
                true ->
                    Reason = ?_LANG_FAMILY_CANT_SET_OWNER_TO_INTEROR,
                    do_set_owner_error(Unique, Module, Method, Reason, RoleID, Line);
                _ ->
                    do_set_owner2(Unique, Module, Method, TargetRoleID, RoleID, Line)
            end;
        %%            case check_last_set_owner_time(LastSetTime) of
        %%                true ->
        %%                    do_set_owner2(Unique, Module, Method, TargetRoleID, RoleID, Line);
        %%                false ->
        %%                    do_set_owner_error(Unique, Module, Method, ?_LANG_FAMILY_SET_OWNER_INTERVAL, RoleID, Line)
        %%            end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_SET_OWNER,
            do_set_owner_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_set_owner2(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    State = get_state(),
    case (State#family_state.family_info)#p_family_info.ybc_status of
        ?FAMILY_YBC_STATUS_DOING ->
            do_set_owner_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_SET_OWNER_WHEN_YBC_DOING, RoleID, Line);
        ?FAMILY_YBC_STATUS_PUBLISHING ->
            do_set_owner_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_SET_OWNER_WHEN_YBC_PUBLISHING, RoleID, Line);
        _ ->
            do_set_owner3(Unique, Module, Method, TargetRoleID, RoleID, Line)
    end.
            
do_set_owner3(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    %%更新家族信息
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    FamilyExt = State#family_state.ext_info,
    {Date, _} = calendar:local_time(),
    NewExt = FamilyExt#r_family_ext{last_set_owner_time=Date},
    SecondOwners = FamilyInfo#p_family_info.second_owners,
    OldMembers = State#family_state.family_members,
    FamilyID=FamilyInfo#p_family_info.family_id,
    OldOwnerName = FamilyInfo#p_family_info.owner_role_name,
    %%判断对方是普通组员还是副族长
    case lists:keyfind(TargetRoleID, #p_family_second_owner.role_id, SecondOwners) of
        false ->
            TargetRole = lists:keyfind(TargetRoleID, #p_family_member_info.role_id, OldMembers),
            TargetRoleName = TargetRole#p_family_member_info.role_name,
            NewTitleForOldOwner = ?DEFAULT_FAMILY_MEMBER_TITLE,
            NewSecondOwners = SecondOwners,
            ok;
        TargetRole ->
            TargetRoleName = TargetRole#p_family_second_owner.role_name,
            NewTitleForOldOwner = ?FAMILY_TITLE_SECOND_OWNER,
            NewSecondOwnersTmp = lists:keydelete(TargetRoleID, #p_family_second_owner.role_id, SecondOwners),
            NewSecond = #p_family_second_owner{role_id=RoleID, role_name=FamilyInfo#p_family_info.owner_role_name},
            NewSecondOwners = [NewSecond | NewSecondOwnersTmp]
    end,
    NewFamilyInfo = FamilyInfo#p_family_info{second_owners=NewSecondOwners, owner_role_id=TargetRoleID,
                                             owner_role_name=TargetRoleName},
    %%更新家族成员列表中的称号
    NewMembers = lists:map(
                   fun(M) ->
                           ID = M#p_family_member_info.role_id,
                           case ID =:= RoleID of
                               true ->
                                   M#p_family_member_info{title=NewTitleForOldOwner};
                               false ->
                                   case ID =:= TargetRoleID of
                                       true ->
                                           M#p_family_member_info{title=?FAMILY_TITLE_OWNER};
                                       false ->
                                           M
                                   end
                           end
                   end, OldMembers),
    NewState = State#family_state{family_info=NewFamilyInfo, family_members=NewMembers, ext_info=NewExt},
    update_state(NewState),
    R = #m_family_set_owner_toc{role_id=TargetRoleID},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
    common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,?FAMILY_TITLE_OWNER),
    common_title_srv:add_title(?TITLE_FAMILY, RoleID, NewTitleForOldOwner),
    RB = #m_family_set_owner_toc{return_self=false, role_id=TargetRoleID},  
    
    Content = common_tool:get_format_lang_resources(?_LANG_FAMILY_CHANGE_OWNER, [OldOwnerName,TargetRoleName]),
    common_broadcast:bc_send_msg_family(FamilyID,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_FAMILY,Content),
    broadcast_to_all_members_except(Module, Method, RB, RoleID).
    
                                   
do_set_owner_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_set_owner_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%设置成员称号
do_set_title(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_set_title_tos{role_id=TargetRoleID, title=Title} = Record,
    Title2 = common_tool:to_binary(Title),
    case Title2 =:= <<>> of
        true ->
            Title3 = ?DEFAULT_FAMILY_MEMBER_TITLE;
        false ->
            Title3 = Title2
    end,
    case cfg_title:family_title_forbidden(common_tool:to_list(Title)) of
        false ->
            State = get_state(),
            FamilyInfo = State#family_state.family_info,
            %%验证是否有权限，验证是否可以被设置称号
            case is_owner_or_second_owner(RoleID, FamilyInfo) of
                true ->
                    case is_owner_or_second_owner(TargetRoleID, FamilyInfo) of
                        false ->
                            do_set_title2(Unique, Module, Method, {TargetRoleID, Title3}, RoleID, Line);
                        true ->
                            Reason = ?_LANG_FAMILY_OWNER_OR_SEC_OWNER_CANNT_SET_TITLE,
                            do_set_title_error(Unique, Module, Method, Reason, RoleID, Line)
                    end;
                false ->
                    Reason = ?_LANG_FAMILY_NO_RIGHT_TO_SET_TITLE,
                    do_set_title_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        _ ->
            Reason = ?_LANG_FAMILY_CAN_USE_SYSTEM_TITLE_TO_SET_TITLE,
            do_set_title_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_set_title2(Unique, Module, Method, {TargetRoleID, Title}, RoleID, Line) ->    
    State = get_state(),
    Members = State#family_state.family_members,
    case lists:keyfind(TargetRoleID, 2, Members) of
        false ->
            Reason = ?_LANG_FAIMLY_NOT_MEMBER,
            do_set_title_error(Unique, Module, Method, Reason, RoleID, Line);
        MemberInfo ->
            NewMemberInfo = MemberInfo#p_family_member_info{title=Title},
            NewMembersList = lists:keyreplace(TargetRoleID, 2, Members, NewMemberInfo), 
            NewState = State#family_state{family_members=NewMembersList},
            update_state(NewState),
            common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,Title),
            %%广播
            RB = #m_family_set_title_toc{return_self=false, role_id=TargetRoleID, 
                                         role_name=MemberInfo#p_family_member_info.role_name,
                                         title=Title},
            broadcast_to_all_members_except(Module, Method, RB, RoleID),
            R = #m_family_set_title_toc{role_id=TargetRoleID, title=Title},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
    end.
            
do_set_title_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_set_title_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%设置家族自动加入状态
do_set_auto_join(Unique, Module, ?FAMILY_AUTO_STATE, Record, RoleID, Line) ->
    #m_family_auto_state_tos{auto_state = AS} = Record,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    %%验证玩家是否是家族长
    case is_owner(RoleID, FamilyInfo) of
        true ->
            NewFamilyInfo = FamilyInfo#p_family_info{is_auto_join = AS},
            NewState = State#family_state{family_info = NewFamilyInfo},
            update_state(NewState),
            db:dirty_write(?DB_FAMILY, FamilyInfo),
            R = #m_family_auto_state_toc{err_code = 0},
            common_misc:unicast(Line, RoleID, Unique, Module, ?FAMILY_AUTO_STATE, R);
        false ->
            R = #m_family_auto_state_toc{err_code = 2, reason = ?_LANG_FAMILY_AUTO_STATE_CHANGE},
            common_misc:unicast(Line, RoleID, Unique, Module, ?FAMILY_AUTO_STATE, R)
    end.

%%解散家族
do_dismiss(Unique, Module, Method, RoleID, Line) ->
    %%判断是否是族长，将来可能有更多的判断，例如家族站期间不能解散家族
    State = get_state(),
    #p_family_info{owner_role_id=OwnerRoleID, faction_id=FactionID} = State#family_state.family_info,
    case OwnerRoleID =:= RoleID of
        true ->
             case common_warofking:is_begin_war(FactionID) of
                 true ->
                     do_dismiss_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_CHANGE_MEMBER_WHEN_JOIN_WAROFKING, RoleID, Line);
                 false ->
                     do_dismiss2(Unique, Module, Method, RoleID, Line)
             end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_TO_DISMISS,
            do_dismiss_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_dismiss2(Unique, Module, Method, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.ybc_status of
        ?FAMILY_YBC_STATUS_DOING ->
            do_dismiss_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_DISMISS_WHEN_DOING_YBC, RoleID, Line);
        ?FAMILY_YBC_STATUS_PUBLISHING ->
            do_dismiss_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_DISMISS_WHEN_PUBLISHING_YBC, RoleID, Line);
        _ ->
            if
                FamilyInfo#p_family_info.cur_members =:= 1->
                    FamilyID = FamilyInfo#p_family_info.family_id,
                    %%FamilyName = FamilyInfo#p_family_info.family_name,
                    Members = State#family_state.family_members,
                    case db:transaction(fun() -> t_do_dismiss(FamilyID, Members) end) of
                        {atomic, _} ->
                            %%db:remove(?DB_FAMILY_P, ?DB_FAMILY, FamilyID),
                            R = #m_family_dismiss_toc{},
                            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
                            RB = #m_family_dismiss_toc{return_self=false},
                            lists:foreach(
                              fun(#p_family_member_info{role_id=MID}) ->
                                      common_title_srv:remove_by_typeid(?TITLE_FAMILY,MID),
                                      hook_family_change:hook(change, {MID, 0, FamilyID})
                              end, Members),
                            RoleIDList = get_member_role_id_list(),
                            lists:foreach(
                              fun(RID) ->
                                      notify_world_update(RID, undefined)
                              end, RoleIDList),
                            broadcast_to_all_members_except(Module, Method, RB, RoleID),
                            hook_family:delete(FamilyID),
                            update_state(false),
                            hook_update_donate_info({donate_delete_family,FamilyID}),
                            %%结束本进程
                            exit(self(), normal);
                        {aborted, Error} ->
                            case erlang:is_binary(Error) of
                                true ->
                                    Reason = Error;
                                false ->
                                    ?ERROR_MSG("~ts:~w", ["解散家族出错", Error]),
                                    Reason = ?_LANG_SYSTEM_ERROR
                            end,
                            R = #m_family_dismiss_toc{succ=false, reason=Reason},
                            common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
                    end;
                true->
                     do_dismiss_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_DISMISS_WHEN_HAS_MEMBER, RoleID, Line)
            end
    end.
    
do_dismiss_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_dismiss_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).
    

%%退出家族
do_leave(Unique, Module, Method, RoleID, Line) ->
    %%判断是否是对应家族的成员，是否是族长或者副族长，更新玩家信息，广播通知族内所有人
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    FactionID = FamilyInfo#p_family_info.faction_id,
    case common_warofking:is_begin_war(FactionID) of
        true ->
            do_leave_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_CHANGE_MEMBER_WHEN_JOIN_WAROFKING, RoleID, Line);
        _ ->
            case RoleID =:= FamilyInfo#p_family_info.owner_role_id of
                true ->
                    case FamilyInfo#p_family_info.cur_members =:= 1 of
                        true ->
                            %%族长离开家族，实际上就是解散
                            do_leave_owner(Unique, Module, Method, RoleID, Line);
                        false ->
                            Reason = ?_LANG_FAMILY_OWNER_CANNT_LEAVE_WHEN_MORE_THAN_ONE_MEMBER,
                            do_leave_error(Unique, Module, Method, Reason, RoleID, Line)
                    end;
                false ->
                    do_leave2(Unique, Module, Method, RoleID, Line)
            end
    end.
    
do_leave2(Unique, Module, Method, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    FamilyID = FamilyInfo#p_family_info.family_id,
    
    case (State#family_state.family_info)#p_family_info.ybc_status  of
        ?FAMILY_YBC_STATUS_DOING ->
            do_leave_error(Unique, Module, Method, ?_LANG_FAMILY_MEMBER_CANNT_LEAVE_WHEN_DOING_YBC, RoleID, Line);
        ?FAMILY_YBC_STATUS_PUBLISHING ->
            do_leave_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_LEAVE_WHEN_PUBLISHING_YBC, RoleID, Line);
        _ ->
            case db:transaction(fun() -> t_do_leave(RoleID, FamilyID) end) of
                {atomic, true} ->
                    NewCurMembers = FamilyInfo#p_family_info.cur_members - 1,
                    SecondOwners = FamilyInfo#p_family_info.second_owners,
                    OldMembers = State#family_state.family_members,
                    
                    case lists:any(fun(S) -> S#p_family_second_owner.role_id =:= RoleID end, SecondOwners) of
                        true ->
                            %%如果是副族长，则还需要更新副族长列表
                            NewSecondOwners = lists:keydelete(RoleID, 2, SecondOwners),
                            NewFamilyInfo = FamilyInfo#p_family_info{second_owners=NewSecondOwners, cur_members=NewCurMembers};
                        false ->                    
                            NewFamilyInfo = FamilyInfo#p_family_info{cur_members=NewCurMembers}
                    end,
                    NewMembers = lists:keydelete(RoleID, 2, OldMembers),
                    NewState = State#family_state{family_info=NewFamilyInfo, family_members=NewMembers},
                    update_state(NewState),
                    mod_family:notify_world_update(RoleID, undefined),
                    F = fun() ->
                            db:write(?DB_FAMILY, FamilyInfo#p_family_info{cur_members = NewCurMembers, members = NewMembers}, write)
                        end,
                    db:transaction(F),
                    hook_family_change:hook(change, {RoleID, 0, FamilyID}),
                    %%hook_family:hook_family_changed({0,RoleID}),
                    R = #m_family_leave_toc{role_id=RoleID},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
                    common_title_srv:remove_by_typeid(?TITLE_FAMILY,RoleID),
                    %%更新家族贡献度清零
                    hook_family:hook_family_conbtribute_change(RoleID,0),
                    catch notify_world_update(RoleID, clear_role_family_skill),
                    catch notify_world_update(RoleID, family_contribute,0),
                    
                    RB = #m_family_leave_toc{role_id=RoleID, return_self=false},
                    broadcast_to_all_members_except(Module, Method, RB, RoleID),
                    hook_update_donate_info({donate_delete_role,FamilyID,RoleID}),
                    %%将族员踢出地图
                    common_family:kick_member_in_map_online(FamilyID, RoleID);
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            ?ERROR_MSG("~ts:~w", ["退出家族失败", Error]),
                            Reason = ?_LANG_SYSTEM_ERROR
                    end,
                    do_leave_error(Unique, Module, Method, Reason, RoleID, Line)
            end
    end.

t_do_leave(RoleID, FamilyID) ->
    RoleBase = mod_role_tab:get({?role_base, RoleID}),
    case RoleBase#p_role_base.family_id =:= FamilyID of
        true ->
            RoleAttr = mod_role_tab:get({?role_attr, RoleID}),
            RoleExt = mod_role_tab:get({role_ext, RoleID}),
            
            %%家族贡献度清零
            NewRoleAttr = RoleAttr#p_role_attr{family_contribute=0},
            NewRoleBase = RoleBase#p_role_base{family_id=0, family_name=[]},
            NewRoleExt = RoleExt#p_role_ext{family_last_op_time=common_tool:now()},
            mod_role_tab:put({?role_attr, RoleID}, NewRoleAttr),
            mod_role_tab:put({role_ext, RoleID}, NewRoleExt),
            mod_role_tab:put({?role_base, RoleID}, NewRoleBase),
            true;
        false ->
            db:abort(?_LANG_FAMILY_NOT_MEMBER)
    end.



%%族长离开家族，前面条件已经判断，这里要做的是解散
do_leave_owner(Unique, Module, Method, RoleID, Line) ->
    State = get_state(),
    case (State#family_state.family_info)#p_family_info.ybc_status  of
        ?FAMILY_YBC_STATUS_DOING ->
            do_leave_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_LEAVE_WHEN_DOING_YBC, RoleID, Line);
        ?FAMILY_YBC_STATUS_PUBLISHING ->
            do_leave_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_LEAVE_WHEN_PUBLISHING_YBC, RoleID, Line);
        _ ->
            FamilyInfo = State#family_state.family_info,
            FamilyID = FamilyInfo#p_family_info.family_id,
            Members = State#family_state.family_members,
            case db:transaction(fun() -> t_do_dismiss(FamilyID, Members) end) of
                {atomic, _} ->
                    R2 = #m_family_dismiss_toc{},
                    common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE, Module, ?FAMILY_DISMISS, R2),
                    common_title_srv:remove_by_typeid(?TITLE_FAMILY,RoleID),
                    notify_world_update(RoleID, undefined),
                    hook_family:delete(FamilyID),
                    hook_update_donate_info({donate_delete_family,FamilyID}),
                    update_state(false),
                    %%结束本进程
                    exit(self(), normal);
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            Reason = ?_LANG_SYSTEM_ERROR,
                            ?ERROR_MSG("~ts:w", ["离开家族出错", Error])
                    end,
                    R = #m_family_leave_toc{succ=false, reason=Reason},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
                    ok
            end
    end.


%%解散家族，删除家族的操作由db模块来完成
t_do_dismiss(FamilyID, Members) ->
    %%更新所有成员的family_id
    lists:foreach(
      fun(M) ->
              RoleID = M#p_family_member_info.role_id,
              RoleTab = mod_role_tab:name(RoleID),
              ets:update_element(RoleTab, p_role_base, 
                [{#p_role_base.family_id, 0}, {#p_role_base.family_name, <<>>}]),
              %%更新最后离开家族的时间
              ets:update_element(RoleTab, p_role_ext, 
                [{#p_role_ext.family_last_op_time, common_tool:now()}]),
              db:delete(?DB_FAMILY_EXT, FamilyID, write),
              db:delete(?DB_FAMILY, FamilyID, write)
      end, Members).
                                   
          
do_leave_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_leave_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).
                                                   


%%更新对外公告
do_update_pub_notice(Unique, Module, Method, Record, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            #m_family_update_pub_notice_tos{content=Content} = Record,
            case erlang:length(Content) > 750 of
                false ->
                    NewFamilyInfo = FamilyInfo#p_family_info{public_notice=Content},
                    NewState = State#family_state{family_info=NewFamilyInfo},
                    update_state(NewState),
                    %%广播通知所有人公告更新成功
                    RB = #m_family_update_pub_notice_toc{return_self=false, content=Content},
                    broadcast_to_all_members_except(Module, Method, RB, RoleID),
                    R = #m_family_update_pub_notice_toc{content=Content},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R);
                true ->
                    Reason = ?_LANG_FAMILY_PUBLIC_NOTICE_LEN_LIMIT,
                    do_update_pub_notice_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_SET_PUBLIC_NOTICE,
            do_update_pub_notice_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_update_pub_notice_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_update_pub_notice_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).
            

%%更新对内公告
do_update_pri_notice(Unique, Module, Method, Record, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            #m_family_update_pri_notice_tos{content=Content} = Record,
            case erlang:length(Content) > 750 of
                false ->
                    NewFamilyInfo = FamilyInfo#p_family_info{private_notice=Content},
                    NewState = State#family_state{family_info=NewFamilyInfo},
                    update_state(NewState),
                    %%广播通知所有人公告更新成功
                    RB = #m_family_update_pri_notice_toc{return_self=false, content=Content},
                    broadcast_to_all_members_except(Module, Method, RB, RoleID),
                    R = #m_family_update_pri_notice_toc{content=Content},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R);
                true ->
                    Reason = ?_LANG_FAMILY_PRIVATE_NOTICE_LEN_LIMIT,
                    do_update_pri_notice_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_SET_PRI_NOTICE,
            do_update_pri_notice_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_update_pri_notice_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_update_pri_notice_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%更新QQ
do_update_qq(Unique, Module, Method, Record, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            #m_family_update_qq_tos{content=Content} = Record,
            case erlang:length(Content) > 20 of
                false ->
                    NewFamilyInfo = FamilyInfo#p_family_info{qq=Content},
                    NewState = State#family_state{family_info=NewFamilyInfo},
                    update_state(NewState),
                    %%广播通知所有人公告更新成功
                    RB = #m_family_update_qq_toc{return_self=false, content=Content},
                    broadcast_to_all_members_except(Module, Method, RB, RoleID),
                    R = #m_family_update_qq_toc{content=Content},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R);
                true ->
                    Reason = ?_LANG_FAMILY_QQ_LEN_LIMIT,
                    do_update_qq_error(Unique, Module, Method, Reason, RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_SET_PRI_NOTICE,
            do_update_qq_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_update_qq_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_update_qq_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%同意某人加入家族的请求
do_agree_f(Unique, Module, Method, Record, RoleID, Line) ->
    %%判断族员是否已满，判断对方是否有家族，判断是否是同一国家的
    #m_family_agree_f_tos{role_id=TargetRoleID} = Record,
    State = get_state(),
    RequestList = State#family_state.requests,
    FamilyInfo = State#family_state.family_info,
%%     FactionID = FamilyInfo#p_family_info.faction_id,
    %%判断家族是否满员
    case FamilyInfo#p_family_info.cur_members >= get_max_member(FamilyInfo#p_family_info.level) of
        false ->  
             do_agree_f2(Unique, Module, Method, {State, RequestList, FamilyInfo, TargetRoleID}, RoleID, Line);
        true ->
            Reason = ?_LANG_FAMILY_MEMBER_LIMIT_WHEN_AGREE_F,
            do_agree_f_error(Unique, Module, Method, Reason, RoleID, Line)
    end.



do_agree_f2(Unique, Module, Method, {State, RequestList, FamilyInfo, TargetRoleID}, RoleID, Line) ->
    %%判断是否有权限
    case is_owner_or_second_owner(RoleID, FamilyInfo) orelse FamilyInfo#p_family_info.interiormanager =:= RoleID of
        true ->
            case is_special_family_date() of
                true->
                    case can_join_family_in_special_date(TargetRoleID) of
                        true->
                            do_agree_f3(Unique, Module, Method, {State, RequestList, FamilyInfo, TargetRoleID}, RoleID, Line);
                        _ ->
                            do_agree_f_error(Unique,Module,Method,?_LANG_JOIN_FAMILY_MAX_TIMES_OPPOSITE,RoleID,Line)
                    end;
                _ ->
                    do_agree_f3(Unique, Module, Method, {State, RequestList, FamilyInfo, TargetRoleID}, RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_TO_AGREE_F,
            do_agree_f_error(Unique, Module, Method, Reason, RoleID, Line)
    end.


do_agree_f3(Unique, Module, Method, {State, RequestList, FamilyInfo, TargetRoleID}, RoleID, Line) ->
    #p_family_info{family_id=FamilyID, family_name=FamilyName} = FamilyInfo,
   case db:transaction(fun() -> t_do_agree_f(TargetRoleID, FamilyID, FamilyName) end) of
        {atomic, NewRoleBase} ->
            #p_role_base{role_name=RoleName, sex=Sex, head=Head} = NewRoleBase,     
        %%bug fix 
            {ok, RoleAttr} = common_misc:get_dirty_role_attr(TargetRoleID),       
            #p_role_attr{office_name=OfficeName,level=RoleLevel} = RoleAttr,
            Online = true,
            NewMember = #p_family_member_info{title=?DEFAULT_FAMILY_MEMBER_TITLE,
                                              role_id=TargetRoleID, role_name=RoleName, office_name=OfficeName,
                                              family_contribution=0,sex=Sex, head=Head, online=Online,
                          role_level = RoleLevel,last_login_time=get_last_login_time(RoleID)
             },
            hook_family:hook_family_conbtribute_change(TargetRoleID,0),
            mod_family:notify_world_update(TargetRoleID, FamilyInfo),
            OldMemberList = State#family_state.family_members,
            %%删除该申请记录
            NewRequestList = lists:keydelete(TargetRoleID, 2, RequestList),
            %%写入玩家到最新的家族成员列表中
            NewMemberList = [NewMember | OldMemberList],
            NewFamily = FamilyInfo#p_family_info{cur_members=erlang:length(NewMemberList), members=NewMemberList},
            NewState = State#family_state{family_members=NewMemberList, requests=NewRequestList, family_info=NewFamily},
            %%通知所有族员，在更新家族成员列表之前完成
            RB = #m_family_member_join_toc{member=NewMember},
            broadcast_to_all_members(Module, ?FAMILY_MEMBER_JOIN, RB),
            %%更新内存中的家族信息
            update_state(NewState),
            %%通知对应的玩家
            RTarget = #m_family_agree_f_toc{return_self=false, family_info=NewFamily,admit_role_id=RoleID},
            common_misc:unicast({role, TargetRoleID}, ?DEFAULT_UNIQUE, Module, Method, RTarget),
            %%通知同意操作者
            RSelf = #m_family_agree_f_toc{},
            ?DEBUG("~ts:~w ~w", ["同意玩家进入家族，即将触发家族信息改变的hook", RoleID, FamilyID]),
        %%这是以前写的,后端统计用
            hook_family_change:hook(change, {TargetRoleID, FamilyID, 0}),
        %%这是role_attr新加了family_id字段,需要通知更新
        %%hook_family:hook_family_changed({FamilyID,TargetRoleID}),
            common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,?DEFAULT_FAMILY_MEMBER_TITLE),
            join_family_for_role(TargetRoleID,RoleName,FamilyName,RoleLevel),
            %%add_family_join_times(TargetRoleID),

           common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf);
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    Reason = ?_LANG_SYSTEM_ERROR,
                    ?ERROR_MSG("~ts:~w", ["同意玩家加入家族申请失败", Error])
            end,
            %%删除该申请记录
            NewRequestList = lists:keydelete(TargetRoleID, 2, RequestList),
            NewState = State#family_state{requests=NewRequestList},
            update_state(NewState),
            do_agree_f_error(Unique, Module, Method, Reason, RoleID, Line)
    end.


do_agree_f_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_agree_f_toc{succ=false, reason=Reason,admit_role_id = RoleID},
    ?DEBUG("jionfamily ~w ",[R,RoleID]),
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


t_do_agree_f(RoleID, FamilyID, FamilyName) ->
    RoleBase = mod_role_tab:get({?role_base, RoleID}),
    case RoleBase#p_role_base.family_id > 0 of
        true ->
            %%这种情况下应该删除这条申请记录
            db:abort(?_LANG_FAMILY_TARGET_ALREADY_HAVE_FAMILY_WHEN_AGREE_F);
        false ->
            ok
    end,
    case db:match_object(?DB_FAMILY_REQUEST, #p_family_request_info{role_id=RoleID, family_id=FamilyID}, write) of
        [] ->
            db:abort(?_LANG_FAMILY_NOT_IN_REQUEST_LIST);
        _ ->
            ok
    end,
    %%其他条件都不用检查了
    NewRoleBase = RoleBase#p_role_base{family_id=FamilyID, family_name=FamilyName},
    mod_role_tab:put({?role_base, RoleID}, NewRoleBase),
    %% 删除所有邀请本玩家的记录
    Object = db:match_object(?DB_FAMILY_INVITE, 
                             #p_family_invite_info{target_role_id=RoleID,  _='_'}, write),
    lists:foreach(fun(Invite) -> db:delete_object(?DB_FAMILY_INVITE, Invite, write) end, Object),
    %% 删除所有申请记录
    t_clear_family_request(RoleID),
    NewRoleBase.

%%事务内删除玩家的申请请求
t_clear_family_request(RoleID)->
    %% 删除所有申请记录
    Requests = db:match_object(?DB_FAMILY_REQUEST, #p_family_request_info{role_id=RoleID, _='_'}, write),
    lists:foreach(fun(Request) -> db:delete_object(?DB_FAMILY_REQUEST, Request, write) end, Requests),
    lists:foreach(fun(R) -> 
                          #p_family_request_info{family_id=FamilyID} = R,
                          ProcessName = common_misc:make_family_process_name(FamilyID),
                          case global:whereis_name(ProcessName) of
                              undefined ->
                                  ignore;
                              PID ->
                                  erlang:send(PID, {clear_family_request,RoleID}),
                                  ok
                          end
                  end, Requests).


%%拒绝某个玩家加入家族的请求
do_refuse_f(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_refuse_f_tos{role_id=TargetRoleID} = Record,
    %%删除记录，并通知双方
    State = get_state(),
    #p_family_info{family_id=FamilyID, family_name=FamilyName} = State#family_state.family_info,
    RequestList = State#family_state.requests,
    %%删除对应玩家的申请记录
    R = #p_family_request_info{role_id=TargetRoleID, family_id=FamilyID},
    db:dirty_delete_object(?DB_FAMILY_REQUEST, R),
    case lists:keyfind(TargetRoleID, 2, RequestList) of
        false ->
            ignore;
        _ ->
            NewRequestList = lists:keydelete(TargetRoleID, 2, RequestList),
            NewState = State#family_state{requests=NewRequestList},
            update_state(NewState),
            RT = #m_family_refuse_f_toc{return_self=false, family_name=FamilyName},
            common_misc:unicast({role, TargetRoleID}, ?DEFAULT_UNIQUE, Module, Method, RT)
    end,
    R2 = #m_family_refuse_f_toc{},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R2).


%%开除成员
do_fire(Unique, Module, Method, Record, RoleID, Line) ->
    ?DEBUG("fireme",[]),
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    #m_family_fire_tos{role_id=TargetRoleID} = Record,
    %%族长或者副族长不能被直接开除
    %%只有族长和副族长才能开除成员
    case is_owner_or_second_owner(TargetRoleID, FamilyInfo) of
        false ->
            case is_owner_or_second_owner(RoleID, FamilyInfo) of
                true ->
                    do_fire2(Unique, Module, Method, TargetRoleID, RoleID, Line);
                false ->
                    Reason = ?_LANG_FAMILY_NO_RIGHT_TO_FIRE,
                    do_fire_error(Unique, Module, Method, Reason ,RoleID, Line)
            end;
        true ->
            Reason = ?_LANG_FAMILY_CANNT_FIRE_OWNER_OR_SECOND_OWNER,
            do_fire_error(Unique, Module, Method, Reason ,RoleID, Line)
    end.
do_fire2(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    %%检查是不是家族成员
    State = get_state(),
    #p_family_info{ faction_id=FactionID, ybc_status=YbcStatus} = State#family_state.family_info,
    case YbcStatus of
        ?FAMILY_YBC_STATUS_DOING ->
            do_fire_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_FIRE_WHEN_YBC_DOING, RoleID, Line);
        ?FAMILY_YBC_STATUS_PUBLISHING ->
            do_fire_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_FIRE_WHEN_YBC_PUBLISHING, RoleID, Line);
        _ ->
            Members = State#family_state.family_members,
            case lists:keyfind(TargetRoleID, 2, Members) of
                false ->
                    Reason = ?_LANG_FAMILY_NOT_MEMBER_WHEN_FIRE,
                    do_fire_error(Unique, Module, Method, Reason, RoleID, Line);
                _ ->
                    case common_warofking:is_begin_war(FactionID) of
                        true ->
                            do_fire_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_CHANGE_MEMBER_WHEN_JOIN_WAROFKING, RoleID, Line);
                        false ->
                            do_fire3(Unique, Module, Method, TargetRoleID, RoleID, Line)
                    end
            end
    end.

do_fire3(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    State = get_state(),
    Members = State#family_state.family_members,
    case db:transaction(fun() -> t_do_fire(TargetRoleID) end) of
        {atomic, TargetRoleName} ->
            R = #m_family_fire_toc{role_id=TargetRoleID},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            %%删除对应的成员
            NewMembers = lists:keydelete(TargetRoleID, 2, Members),
            FamilyInfo = State#family_state.family_info,
            CurMembers = FamilyInfo#p_family_info.cur_members,
            NewFamilyInfo = FamilyInfo#p_family_info{cur_members=CurMembers-1},
            NewState = State#family_state{family_members=NewMembers, family_info=NewFamilyInfo},
            FamilyInfo = State#family_state.family_info,
            notify_world_update(TargetRoleID, undefined),
            update_state(NewState),
            F = fun() ->
                    db:write(?DB_FAMILY, FamilyInfo#p_family_info{cur_members = CurMembers - 1, members = NewMembers}, write)
                end,
            db:transaction(F),
            FamilyID = FamilyInfo#p_family_info.family_id,
            case TargetRoleName of
                {error,not_found} ->
                    nil;
                _ ->
                    RB = #m_family_fire_toc{return_self=false, role_id=TargetRoleID, role_name=TargetRoleName},
                    broadcast_to_all_members_except(Module, Method, RB, RoleID),
                    hook_family_change:hook(change, {TargetRoleID, 0, FamilyID}),
                    common_title_srv:remove_by_typeid(?TITLE_FAMILY,TargetRoleID),
                    send_message_to_expel_member(TargetRoleID,RoleID,FamilyInfo#p_family_info.family_name)
            end,
            hook_update_donate_info({donate_delete_role,FamilyID,TargetRoleID}),
            %%将族员踢出地图
            common_family:kick_member_in_map_online(FamilyInfo#p_family_info.family_id, TargetRoleID),
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    Reason = ?_LANG_SYSTEM_ERROR,
                    ?ERROR_MSG("~ts:~w", ["T人失败", Error])
            end,
            do_fire_error(Unique, Module, Method, Reason, RoleID, Line)
    end.


send_message_to_expel_member(TargetRoleID,RoleID,FamilyName)->
    RoleName = common_misc:get_dirty_rolename(RoleID),
    Content = common_letter:create_temp(?FAMILY_FIRE_MEMBER_LETTER,[common_tool:to_list(RoleName),FamilyName]),
    common_letter:sys2p(TargetRoleID,Content,"族长给你的信",3).

t_do_fire(TargetRoleID) ->
    case mod_role_tab:get({?role_base, TargetRoleID}) of
        RoleBase when is_record(RoleBase, p_role_base) ->
            NewRoleBase = RoleBase#p_role_base{family_id=0, family_name=[]},
            mod_role_tab:put({?role_base, TargetRoleID}, NewRoleBase),
            %%更新角色最后一次离开家族的时间
            RoleExt = mod_role_tab:get({role_ext, TargetRoleID}),
            NewRoleExt = RoleExt#p_role_ext{family_last_op_time=common_tool:now()},
            mod_role_tab:put({role_ext, TargetRoleID}, NewRoleExt),
            NewRoleBase#p_role_base.role_name;
        _ ->
            {error,not_found}
    end.     

do_fire_error(Unique, Module, Method, Reason ,RoleID, Line) ->
    R = #m_family_fire_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).
    

get_member_role_id_list() ->
    State = get_state(),
    Members = State#family_state.family_members,
    [ RoleID || #p_family_member_info{role_id=RoleID} <- Members].

%% 判断是否为族长
is_owner(RoleID, FamilyInfo) ->
    FamilyInfo#p_family_info.owner_role_id =:= RoleID.

%% 判断是否为族长或副族长
is_owner_or_second_owner(RoleID, FamilyInfo) ->
    case FamilyInfo#p_family_info.owner_role_id =:= RoleID of
        true ->
            true;
        false ->
            lists:any(
              fun(S) ->
                      S#p_family_second_owner.role_id =:= RoleID
              end, FamilyInfo#p_family_info.second_owners)
    end.
%%判断是否为内务使
is_intermanager(RoleID, FamilyInfo) ->
    FamilyInfo#p_family_info.interiormanager =:= RoleID.


%%拒绝某个家族邀请
do_refuse(Unique, Module, Method, _Record, RoleID, Line) ->
    OldState = get_state(),
    FamilyInfo = OldState#family_state.family_info,
    FamilyID = FamilyInfo#p_family_info.family_id,
    case db:transaction(
           fun() ->
                   case db:match_object(
                          ?DB_FAMILY_INVITE, 
                          #p_family_invite_info{target_role_id=RoleID, family_id=FamilyID, _='_'},
                          write) 
                   of
                       [R] ->
                           db:delete_object(?DB_FAMILY_INVITE, R, write);
                       [] ->
                           db:abort(error)
                   end
           end)
    of
        {atomic, ok} ->
            %%直接删除邀请记录
            InviteList = OldState#family_state.invites,
            NewInviteList = lists:keydelete(RoleID, 2, InviteList),
            NewState = OldState#family_state{invites=NewInviteList},
            update_state(NewState),
            R = #m_family_refuse_toc{},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            RoleBase = mod_role_tab:get({?role_base, RoleID}),
            RoleName = RoleBase#p_role_base.role_name,
            RO = #m_family_refuse_toc{return_self=false, role_id=RoleID, role_name=RoleName},
            broadcast_to_owner_and_second_owners(Module, Method, RO);
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["拒绝家族邀请出错", Error]),
            R = #m_family_refuse_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
    end.
%%获取家族活动状态
do_familytask_state(Unique, Module, Method, _Record, RoleID, Line)->
    State = get_state(),     
    FamilyExt = State#family_state.ext_info,
%%    FamilyInfo = State#family_state.family_info,
    
    LastCallDate = FamilyExt#r_family_ext.common_boss_call_time,
    LastCallCount = FamilyExt#r_family_ext.common_boss_call_count,
    MaxCallCount = hook_activity_family:get_common_boss_max_call_count(),
    BossKill = (FamilyExt#r_family_ext.common_boss_called =:= true andalso FamilyExt#r_family_ext.common_boss_killed =:= false ),
%%    LastFinishDate = FamilyExt#r_family_ext.last_ybc_finish_date,
%%    {Date, _} = calendar:local_time(),
%%    case Date =:= LastFinishDate of
%%        true ->
%%            Ybstate = 4;
%%        false ->
%%            Ybstate = FamilyInfo#p_family_info.ybc_status
%%   end,
 
    Today = erlang:date(),
    if
        Today =/= LastCallDate ->
            AllowSum = 0;
        Today =:= LastCallDate andalso LastCallCount < MaxCallCount ->
            AllowSum = 0;
        true->
            AllowSum = 1
    end, 
    case AllowSum of
        0->
            case BossKill  of
                false->
                    Common_boss_state = 0; %%未发起 
                true->
                    Common_boss_state = 1  %%进行中
            end;
        1 ->
            case BossKill  of
                false->
                    Common_boss_state = 2; %%已结束  
                true->
                    Common_boss_state = 1  %%进行中
            end           
    end,
%%屏蔽家族拉镖
%%     ResList = [#p_family_task{id=10001,status=Ybstate},#p_family_task{id=10002,status=Common_boss_state}],
    ResList = [#p_family_task{id=10002,status=Common_boss_state}],
    R = #m_family_activestate_toc{succ=true,familytasklist=ResList},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R). 

%%同意某个邀请而加入某个家族
do_agree(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_agree_tos{family_id=FamilyID} = Record,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    InviteList = State#family_state.invites,
    case FamilyInfo#p_family_info.cur_members >= get_max_member(FamilyInfo#p_family_info.level) of
        false ->
            case lists:keyfind(RoleID, 2, InviteList) of
                false ->
                    Reason = ?_LANG_FAMILY_NOT_IN_INVITE_LIST,
                    do_agree_error(Unique, Module, Method, Reason, RoleID, Line);
                _ ->
                    do_agree2(Unique, Module, Method, FamilyID, RoleID, Line)
            end;
        true ->
            Reason = ?_LANG_FAMILY_MEMBER_LIMIT_WHEN_AGREE,
            do_agree_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_agree2(Unique, Module, Method, FamilyID, RoleID, Line) ->
    State = get_state(),
    OldFamilyInfo = State#family_state.family_info,
    FamilyName = OldFamilyInfo#p_family_info.family_name,
%%     FactionID = OldFamilyInfo#p_family_info.faction_id,
%%     case common_warofking:is_begin_war(FactionID) of
%%         true ->
%%             do_agree_error(Unique, Module, Method, ?_LANG_FAMILY_CANNT_CHANGE_MEMBER_WHEN_JOIN_WAROFKING, RoleID, Line);
%%         false ->
            %%检查是否真的有邀请，检查对方家族是否已经满员，检查角色等级是否满足、检查是否已有家族
            case db:transaction(fun() -> t_do_agree(RoleID, FamilyID, FamilyName) end) of
                {atomic, RoleBase} ->            
                    #p_role_base{role_name=RoleName, sex=Sex, head=Head} = RoleBase,
                    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
                    #p_role_attr{office_name=OfficeName,level=RoleLevel} = RoleAttr,
                    NewMember = #p_family_member_info{role_id=RoleID, role_name=RoleName,
                                                      office_name=OfficeName, sex=Sex,
                                                      head=Head, title=?DEFAULT_FAMILY_MEMBER_TITLE,
                                                      family_contribution=0,online=true,role_level = RoleLevel,
                              last_login_time = get_last_login_time(RoleID)
                                                     },
                    hook_family:hook_family_conbtribute_change(RoleID,0),
                    OldMembers = State#family_state.family_members,
                    NewMembers = [NewMember | OldMembers],
                    OldCurMember = OldFamilyInfo#p_family_info.cur_members,
                    NewFamilyInfo = OldFamilyInfo#p_family_info{cur_members=OldCurMember+1, members=NewMembers},
                    mod_family:notify_world_update(RoleID, NewFamilyInfo),
                    Invites = State#family_state.invites,
                    NewInvites = lists:keydelete(RoleID, 2, Invites),
                    NewState = State#family_state{family_info=NewFamilyInfo, family_members=NewMembers, invites=NewInvites},
                    RB = #m_family_agree_toc{return_self=false, member_info=NewMember},
                    %%更新成员列表之前广播
                    broadcast_to_all_members(Module, Method, RB),
                    update_state(NewState),
                    R = #m_family_agree_toc{family_info=NewFamilyInfo},
                    hook_family_change:hook(change, {RoleID, FamilyID, 0}),

                    %%通知前段改变role_attr
                    %%hook_family:hook_family_changed({FamilyID,RoleID}),
                    join_family_for_role(RoleID,RoleName,FamilyName,RoleLevel),
                    %%add_family_join_times(RoleID),
                    
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R);
                {aborted, ErrorInfo} ->
                    case erlang:is_binary(ErrorInfo) of
                        true ->
                            Reason = ErrorInfo;
                        false ->
                            Reason = ?_LANG_SYSTEM_ERROR
                    end,
                    do_agree_error(Unique, Module, Method, Reason, RoleID, Line)
            end.
%%     end.
%%成功则返回该玩家的基本属性
t_do_agree(RoleID, FamilyID, FamilyName) ->
    %%检查是否真的有邀请，检查目标家族是否已经满员，检查是否已有家族
    RoleBase = mod_role_tab:get({?role_base, RoleID}),
    case RoleBase#p_role_base.family_id > 0 of
        true ->
            db:abort(?_LANG_FAMILY_ALREADY_HAVE_FAMILY_WHEN_AGREE);
        false ->
            ok
    end,
    %% 删除所有邀请本玩家的记录
    Object = db:match_object(?DB_FAMILY_INVITE, 
                             #p_family_invite_info{target_role_id=RoleID,  _='_'}, write),
    lists:foreach(fun(Invite) -> db:delete_object(?DB_FAMILY_INVITE, Invite, write) end, Object),
    %% 删除所有申请记录
    t_clear_family_request(RoleID),
    NewRoleBase = RoleBase#p_role_base{family_id=FamilyID, family_name=FamilyName},
    mod_role_tab:put({?role_base, RoleID}, NewRoleBase),
    NewRoleBase. 

do_agree_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_agree_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).              
                   

%%玩家申请加入某个家族
%%条件：等级、同国家、没有加入其他家族、上一次家族操作超过24小时
do_request(Unique, Module, Method, RoleID, Line) ->
    case catch do_request_check(RoleID) of
        ok ->
            do_request2(Unique, Module, Method, RoleID, Line);
        Error when is_binary(Error) ->
            do_request_error(Unique, Module, Method, Error, RoleID, Line);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["检查申请加入家族条件时出错", Error]),
            Reason = ?_LANG_SYSTEM_ERROR,
            do_request_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
do_request2(Unique, Module, Method, RoleID, Line) ->
    State = get_state(),
    FamilyID = (State#family_state.family_info)#p_family_info.family_id,
    case db:transaction(fun() -> t_do_request(RoleID, FamilyID) end) of
    {atomic, ok} ->
        OldRequests = State#family_state.requests,
        {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
        {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
        #p_role_attr{level=Level, office_name=OfficeName} = RoleAttr,
        #p_role_base{role_name=RoleName} = RoleBase,
        FightPower = common_role:get_fighting_power(RoleBase, RoleAttr),
        NR = #p_family_request{role_id=RoleID, role_name=RoleName, level=Level,
                               office_name=OfficeName, fighting_power=FightPower,
                               request_time=common_tool:now()},
        NewRequests = [NR | OldRequests],
        NewState = State#family_state{requests=NewRequests},
        update_state(NewState),
        R = #m_family_request_toc{family_id=FamilyID},
        common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
        R2 = #m_family_request_toc{return_self=false, request=NR},
        broadcast_to_owner_and_second_owners(Module, Method, R2),
        ok;
    {aborted, Error} ->
        case erlang:is_binary(Error) of
        true ->
            Reason = Error;
        false ->
            Reason = ?_LANG_SYSTEM_ERROR,
            ?ERROR_MSG("~ts:~w", ["写入玩家家族申请失败", Error])
        end,
        do_request_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
                   

t_do_request(RoleID, FamilyID) ->
    db:write(?DB_FAMILY_REQUEST, #p_family_request_info{role_id=RoleID, family_id=FamilyID}, write).


do_request_check(RoleID) ->
    do_request_check_role(RoleID),
    do_request_check_family(RoleID).
    
%%检查加入家族的条件是否满足
do_request_check_role(RoleID) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
    %%检查玩家等级
    [MinLevelJoinFamily] = common_config_dyn:find(family_base_info,min_level_join_family),
    case RoleAttr#p_role_attr.level >= MinLevelJoinFamily of
        true ->
            ok;
        false ->
            throw(common_tool:get_format_lang_resources(?_LANG_FAMILY_LEVE_NOT_ENOUGH,[MinLevelJoinFamily]))
    end,
    %%检查是否已有家族
    case RoleBase#p_role_base.family_id > 0 of
        true ->
            throw(?_LANG_FAMILY_ALREADY_HAVE);
        false ->
            ok
    end,
    
    %%判断是否同一个国家
    case FamilyInfo#p_family_info.faction_id =:= RoleBase#p_role_base.faction_id of
        true ->
            ok;
        false ->
            throw(?_LANG_FAMILY_NOT_SAME_FACTION)
    end,
    case is_special_family_date() of
        true->
            case can_join_family_in_special_date(RoleID) of
                true->
                    ok;
                _ ->
                    throw(?_LANG_JOIN_FAMILY_MAX_TIMES)
            end;
        _ ->
            ok
    end.

do_request_check_family(RoleID) ->
    State = get_state(),
    Requests = State#family_state.requests,
    FamilyInfo = State#family_state.family_info,
    case lists:keyfind(RoleID, 2, Requests) of
        false ->
            ok;
        _ ->
            throw(?_LANG_FAMILY_ALREADY_REQUEST)
    end,
    case FamilyInfo#p_family_info.cur_members >= get_max_member(FamilyInfo#p_family_info.level) of
        true ->
            throw(?_LANG_FAIMLY_MEMBER_LIMIT_WHEN_REQUEST);
        false ->
            ok
    end.


do_request_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_request_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%%邀请，不用事务判断
do_invite(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_invite_tos{role_name=TargetRoleName} = Record,
    TargetRoleName2 = common_tool:to_binary(TargetRoleName),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{_='_', role_name=TargetRoleName2}) of
        [] ->
            Reason = ?_LANG_FAMILY_ROLE_NOT_EXISTS,
            do_invite_error(Unique, Module, Method, Reason, RoleID, Line);
        [TRole] ->
            TargetRoleID = TRole#p_role_base.role_id,
            case catch do_invite_check(RoleID, TargetRoleID) of
                ok ->
                    do_invite2(Unique, Module, Method, TargetRoleID, RoleID, Line);
                Error when is_binary(Error) orelse is_list(Error)->
                    do_invite_error(Unique, Module, Method, Error, RoleID, Line);
                {'EXIT', Error} ->
                    ?ERROR_MSG("~ts:~w", ["检查邀请加入家族条件时出错", Error]),
                    Reason = ?_LANG_SYSTEM_ERROR,
                    do_invite_error(Unique, Module, Method, Reason, RoleID, Line)
            end
    end.
do_invite2(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    {ok, TargetRoleBase} = common_misc:get_dirty_role_base(TargetRoleID),
    {ok, TargetRoleAttr} = common_misc:get_dirty_role_attr(TargetRoleID),
    IR = #p_family_invite{role_id=TargetRoleID, role_name=TargetRoleBase#p_role_base.role_name,
                         level=TargetRoleAttr#p_role_attr.level,
                         office_name=TargetRoleAttr#p_role_attr.office_name},
    State = get_state(),
    OldInvites = State#family_state.invites,
    FamilyInfo = State#family_state.family_info,
    #p_family_info{family_id=FamilyID, family_name=FamilyName} = FamilyInfo,
    {ok, SrcRoleBase} = common_misc:get_dirty_role_base(RoleID),
    SrcRoleName = SrcRoleBase#p_role_base.role_name,
    case db:transaction(fun() -> t_do_invite(FamilyID, FamilyName, TargetRoleID, RoleID, SrcRoleName) end) of
        {atomic, ok} ->
            NewInvites = [IR | OldInvites],
            NewState = State#family_state{invites=NewInvites},
            update_state(NewState),
            R = #m_family_invite_toc{},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
            RT = #m_family_invite_toc{return_self=false, role_name=SrcRoleName, family_id=FamilyID, family_name=FamilyName},
            common_misc:unicast({role, TargetRoleID}, Unique, Module, Method, RT);
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["写入家族邀请玩家记录失败", Error]),
            Reason = ?_LANG_SYSTEM_ERROR,
            do_invite_error(Unique, Module, Method, Reason, RoleID, Line)
    end.
                       

t_do_invite(FamilyID, FamilyName, TargetRoleID, RoleID, RoleName) ->
    R = #p_family_invite_info{target_role_id=TargetRoleID, family_id=FamilyID, family_name=FamilyName,
                         src_role_id=RoleID, src_role_name=RoleName},
    db:write(?DB_FAMILY_INVITE, R, write).
    

do_invite_check(RoleID, TargetRoleID) ->      
    {ok, TargetRoleBase} = common_misc:get_dirty_role_base(TargetRoleID),
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    %%判断是否同一个国家的
    case TargetRoleBase#p_role_base.faction_id =:= FamilyInfo#p_family_info.faction_id of
        true ->
            ok;
        false ->
            throw(?_LANG_FAMILY_NOT_SAME_FACTION_CANNT_INVITE)
    end,
    %%判断对方是否已有家族
    case TargetRoleBase#p_role_base.family_id > 0 of
        true ->
            throw(?_LANG_FAMILY_TARGET_ALREADY_HAS_A_FAMILY);
        false ->
            ok
    end,
    {ok, TargetRoleAttr} = common_misc:get_dirty_role_attr(TargetRoleID),
      %%判断玩家等级是否达到
    [MinLevelJoinFamily] = common_config_dyn:find(family_base_info,min_level_invite_join_family),
    case TargetRoleAttr#p_role_attr.level >= MinLevelJoinFamily of
        true ->
            ok;
        false ->
            throw(common_misc:format_lang(?_LANG_FAMILY_LEVE_NOT_ENOUGH,[common_tool:to_list(MinLevelJoinFamily)]))
    end,

    %%判断对方上次离开家族的时间
    case is_special_family_date() of
        true->
            case can_join_family_in_special_date(TargetRoleID) of
                true->
                    ok;
                _ ->
                    throw(?_LANG_JOIN_FAMILY_MAX_TIMES_OPPOSITE)
            end;
        _ ->
            ok
    end,
    do_invite_check2(RoleID, TargetRoleID).

do_invite_check2(RoleID, TargetRoleID) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    %%判断是否有权利邀请
    Owner = FamilyInfo#p_family_info.owner_role_id,
    SecondOwner = FamilyInfo#p_family_info.second_owners,
    case (Owner =:= RoleID orelse lists:any(fun(O) -> O#p_family_second_owner.role_id =:= RoleID end, SecondOwner)) of
        true ->
            ok;
        false ->
            throw(?_LANG_FAMILY_NO_RIGHT_TO_INVITE)
    end,
    %%判断是否满员
    case (FamilyInfo#p_family_info.cur_members >= get_max_member(FamilyInfo#p_family_info.level)) of
        true ->
            throw(?_LANG_FAMILY_MEMBER_LIMIT);
        false ->
            ok
    end,
    %%判断对方是否已经在邀请列表了
    Invites = State#family_state.invites,
    case lists:keyfind(TargetRoleID, 2, Invites) of
        false ->
            ok;
        _ ->
            throw(?_LANG_FAMILY_ALREADY_IN_INVITE_LIST)
    end,
    FamilyID = FamilyInfo#p_family_info.family_id,
    case db:dirty_match_object(?DB_FAMILY_INVITE, 
                                   #p_family_invite_info{target_role_id=TargetRoleID, family_id=FamilyID, _='_'}) of
        [] ->
            ok;
        _ ->
            throw(?_LANG_FAMILY_ALREADY_IN_INVITE_LIST)
    end.

do_invite_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_invite_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


update_state(State) ->
    erlang:put(?DICT_KEY_STATE, State),
    ok.

update_state(NewMemberList, NewFamilyInfo) ->
    State = get_state(),
    NewState = State#family_state{family_members=NewMemberList, family_info=NewFamilyInfo},
    update_state(NewState).

init_state(State) when erlang:is_record(State, family_state) ->
    erlang:put(?DICT_KEY_STATE, State),
    ok.
get_state() ->
    erlang:get(?DICT_KEY_STATE).
get_family_id() ->
    State = get_state(),
    (State#family_state.family_info)#p_family_info.family_id.

%%获得对应家族等级能够容纳的家族人数
get_max_member(Level) ->
    #r_family_config{max_member=V} = cfg_family:level_config(Level),
    V.


%%家族每个等级最多可以设置多少副族长
get_max_number_of_second_owner(Level) ->
    #r_family_config{second_owners=V} = cfg_family:level_config(Level),
    V.
    

%%广播消息给族长和副族长与内务使
broadcast_to_owner_and_second_owners(Module, Method, R) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    OwnerID = FamilyInfo#p_family_info.owner_role_id,
    common_misc:unicast({role, OwnerID}, ?DEFAULT_UNIQUE, Module, Method, R),
    case FamilyInfo#p_family_info.interiormanager>0 of
        true ->
            common_misc:unicast({role, FamilyInfo#p_family_info.interiormanager}, ?DEFAULT_UNIQUE, Module, Method, R);
        false ->
            ignore
    end,    
    lists:foreach(
      fun(S) ->
              common_misc:unicast({role, S#p_family_second_owner.role_id},
                                  ?DEFAULT_UNIQUE, Module, Method, R)
      end, FamilyInfo#p_family_info.second_owners).


broadcast_to_owner_and_second_owners_except(Module, Method, R, RoleID) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    OwnerID = FamilyInfo#p_family_info.owner_role_id,
    case OwnerID =/= RoleID of
        true ->
            common_misc:unicast({role, OwnerID}, ?DEFAULT_UNIQUE, Module, Method, R);
        false ->
            ignore
    end,
    lists:foreach(
      fun(#p_family_second_owner{role_id=TID})  ->
              case TID =/= RoleID of
                  true ->
                      common_misc:unicast({role, TID}, ?DEFAULT_UNIQUE, Module, Method, R);
                  false ->
                      ignore
              end
      end, FamilyInfo#p_family_info.second_owners).
    

%%将gen_server state中的家族信息保存到数据库中
do_dump_data() ->
    State = get_state(),
    do_dump_data_2(State).

do_dump_data_2(false) ->
    erlang:exit(erlang:self(), normal),
    ok;
do_dump_data_2(undefined) ->
    ok;
do_dump_data_2(State) ->
    FamilyMembers = State#family_state.family_members,
    Requests = State#family_state.requests,
    Invites = State#family_state.invites,
    OldFamilyInfo = State#family_state.family_info,
    FamilyExt = State#family_state.ext_info,
    CurMembers = erlang:length(FamilyMembers),
    FamilyInfo = OldFamilyInfo#p_family_info{members=FamilyMembers, request_list=Requests, 
                                             invite_list=Invites,
                                            cur_members=CurMembers},
    
    hook_family:update(FamilyInfo),    
    db:dirty_write(?DB_FAMILY, FamilyInfo), 
    db:dirty_write(?DB_FAMILY_EXT, FamilyExt),
    ok.



%%每日的家族维护费用,仅在地图打开的情况下才激活
do_family_maintain_cost()->
    erlang:send_after(common_time:diff_next_daytime(1,0) * 1000,self(),family_maintain_cost),
    case common_config_dyn:find(family_base_info,is_open_family_maintain) of
        [true] ->
            mod_family_change:family_maintain_cost();
        _ ->
            ignore
    end,
    get_max_gongxun().

    

%%扣除今天家族地图需要消耗的家族资金和家族繁荣度
resume_for_map() ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    FamilyExtInfo = State#family_state.ext_info,
    Level = FamilyInfo#p_family_info.level,
    %%每天扣一次
    case FamilyExtInfo#r_family_ext.last_resume_time - common_tool:now() > 86400 of
        true ->
            ResumeActivePoints = mod_family_misc:get_resume_points(Level),
            ResumeSilver = mod_family_misc:get_resume_silver(Level),
            OldActivePoints = FamilyInfo#p_family_info.active_points,
            OldMoney = FamilyInfo#p_family_info.money,
            resume_for_map2(ResumeActivePoints, ResumeSilver, OldActivePoints, OldMoney);
        false ->
            ignore
    end.

resume_for_map2(ResumeActivePoints, ResumeSilver, OldActivePoints, OldMoney) ->
    case OldActivePoints >= ResumeActivePoints of
        true ->
            case OldMoney >= ResumeSilver of
                true ->
                    resume_for_map3(ResumeActivePoints, ResumeSilver, OldActivePoints, OldMoney);
                false ->
                    downlevel_map(?_LANG_FAMILY_DOWNLEVEL_NOT_ENOUGH_SILVER)
            end;
        false ->
            downlevel_map(?_LANG_FAMILY_DOWNLEVEL_NOT_ENOUGH_ACTIVE_POINTS)
    end.


resume_for_map3(ResumeActivePoints, ResumeSilver, OldActivePoints, OldMoney) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    NewPoints = OldActivePoints - ResumeActivePoints, 
    NewMoney = OldMoney - ResumeSilver,
    NewFamilyInfo = FamilyInfo#p_family_info{active_points=NewPoints, money=NewMoney},
    FamilyExtInfo = State#family_state.ext_info,
    NewFamilyExtInfo = FamilyExtInfo#r_family_ext{last_resume_time=common_tool:now()},
    NewState = State#family_state{family_info=NewFamilyInfo, ext_info=NewFamilyExtInfo},
    update_state(NewState),
    Time = 86400 - calendar:time_to_seconds(erlang:time()),
    erlang:send_after(Time * 1000, self(), resume_for_map).
    

%%家族地图降级（就是家族降级），不需要递归计算，每天最多只降一级
downlevel_map(Reason) ->
    ?ERROR_MSG("降级 ",[]),
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    Level = FamilyInfo#p_family_info.level,
    Level2 = Level -1,
    NewFamilyInfo = FamilyInfo#p_family_info{level=Level2},
    FamilyExtInfo = State#family_state.ext_info,
    NewFamilyExtInfo = FamilyExtInfo#r_family_ext{last_resume_time=common_tool:now()},
    NewState = State#family_state{family_info=NewFamilyInfo, ext_info=NewFamilyExtInfo},
    update_state(NewState),
    R = #m_family_downlevel_toc{level=Level2, reason=Reason},
    broadcast_to_all_members(?FAMILY, ?FAMILY_DOWNLEVEL, R).


    

%%启动家族地图
active_map() ->
    State = get_state(),
    #p_family_info{family_id=FamilyID,hour=H,minute=M} = (State#family_state.family_info),

    %%初始化种植田地
    %%init_farm_for_family_map(FamilyID),
    case gen_server:call({global, mgeem_router}, {family_map_init, FamilyID, common_tool:today(H,M,0)}) of
        {ok,_Pid} ->
            ?DEBUG("~ts", ["开启家族地图成功"]);
        error ->
            ?ERROR_MSG("~ts", ["开启家族地图失败"]),
            erlang:send_after(?CHECH_FAMILY_MAP_START_TICKET, self(), init_family_map)
    end.


%%初始化家族成员的在线信息
init_online(Members) ->
    lists:map(
      fun(M) ->
              case db:dirty_read(?DB_USER_ONLINE, M#p_family_member_info.role_id) of
                  [] ->
                      M#p_family_member_info{online=false};                      
                  _ ->
                      M#p_family_member_info{online=true}
              end
      end, Members).


get_last_login_time(RoleID)->
    case mod_role_tab:get({role_ext, RoleID}) of
        #p_role_ext{last_login_time=LastLoginTime} ->
            LastLoginTime;
        _->
            0
    end.

get_text_with_npc(TextContent,FactionID,List)->
    lists:flatten(
      io_lib:format(
        TextContent,lists:map(
          fun(Element)->
                  case Element of
                      {HWnpc,YLnpc,WLnpc} ->  
                          case FactionID of
                              1->HWnpc;
                              2->YLnpc;
                              3->WLnpc
                          end;
                      Tmp->
                          Tmp
                  end
          end,List))).

clear_old_protector() ->
    State = get_state(),
    LastMembers = State#family_state.family_members,
    FamilyInfo = State#family_state.family_info,   
    #p_family_info{ leftprotector = Left ,rightprotector = Right} = FamilyInfo,
    TempMembers = do_set_family_title(Left,LastMembers,?DEFAULT_FAMILY_MEMBER_TITLE),
    NewMembers = do_set_family_title(Right,TempMembers,?DEFAULT_FAMILY_MEMBER_TITLE),
    NewState = State#family_state{family_members= NewMembers,family_info=FamilyInfo#p_family_info{ leftprotector = 0 ,rightprotector = 0}},
    update_state(NewState). 

get_max_gongxun() ->
    clear_old_protector(),
    State = get_state(),
    ALLMember = State#family_state.family_members,
    FamilyInfo = State#family_state.family_info,
    Checkzz = fun(X) ->
                 case is_owner_or_second_owner(X, FamilyInfo) orelse is_intermanager(X, FamilyInfo) of  
                    true ->
                        false;
                    false ->
                        true
                 end
              end,
    F = fun(XRoleID,BRoleID) -> 
                case common_misc:get_dirty_role_attr(XRoleID) of
                    {ok, #p_role_attr{gongxun=GongXun}}-> 
                        case common_misc:get_dirty_role_attr(BRoleID) of
                            {ok, #p_role_attr{gongxun=GongXun1}} ->
                                GongXun>GongXun1;
                            _ ->
                                false
                        end;
                    _ ->
                        false
                end
        end,
    MemFzzlist = lists:filter(Checkzz, [M#p_family_member_info.role_id||M <- ALLMember]),
    GongList = lists:sort(F,MemFzzlist),
    case erlang:length(GongList)>=2 of
        true ->
           [Left,Right|_] = GongList,
           common_title_srv:add_title(?TITLE_FAMILY,Left,?FAMILY_TITLE_LEFT_PROTECTOR),
           common_title_srv:add_title(?TITLE_FAMILY,Right,?FAMILY_TITLE_RIGHT_PROTECTOR), 
           LeftMembers = do_set_family_title(Left,ALLMember,?FAMILY_TITLE_LEFT_PROTECTOR),
           LastMembers = do_set_family_title(Right,LeftMembers,?FAMILY_TITLE_RIGHT_PROTECTOR),
           NewState = State#family_state{family_members= LastMembers,family_info=FamilyInfo#p_family_info{ leftprotector = Left ,rightprotector = Right}},
           update_state(NewState);
        false ->
           if erlang:length(GongList)=:=1 ->
                  [Left] = GongList,
                  common_title_srv:add_title(?TITLE_FAMILY,Left,?FAMILY_TITLE_LEFT_PROTECTOR),
                  LastMembers = do_set_family_title(Left,ALLMember,?FAMILY_TITLE_LEFT_PROTECTOR),
                  NewState = State#family_state{family_members= LastMembers,family_info=FamilyInfo#p_family_info{ leftprotector = Left , rightprotector =0}},
                  update_state(NewState);
              true ->
                  NewState = State#family_state{family_info=FamilyInfo#p_family_info{ leftprotector = 0 , rightprotector =0}},
                  update_state(NewState)
            end                
    end.       


%%设置内务使
do_set_Interior_Manager(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_set_interior_manager_tos{role_id=TargetRoleID} = Record,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,    
    %%不能是族长与副族长
    case is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            case is_owner_or_second_owner(TargetRoleID, FamilyInfo) of
                true ->
                    Reason = ?_LANG_FAMILY_NO_ACT_ITERNER,
                    do_set_interior_manager_error(Unique, Module, Method, Reason, RoleID, Line);                    
                false ->
                    do_set_Interior_Manager2(Unique, Module, Method, TargetRoleID, RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_FAMILY_NO_RIGHT_SET_INTERIOR_MANAGER,
            do_set_interior_manager_error(Unique, Module, Method, Reason, RoleID, Line)
    end.

do_set_family_title(RoleID,Members,Title) ->
    UpdateTile =fun(M) ->
                       ID = M#p_family_member_info.role_id,
                        case ID =:= RoleID of
                            true ->
                                M#p_family_member_info{title=Title};
                            false ->
                                M
                        end
                end,    
    lists:map(UpdateTile,Members).

do_set_Interior_Manager2(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    State = get_state(),
    #family_state{family_info=OldFamilyInfo}=State,
    OleInterID = OldFamilyInfo#p_family_info.interiormanager,
    case OleInterID>0 of
        true ->
            OldMembers = State#family_state.family_members,
            NewMembers = lists:map(
                           fun(M) ->
                                   ID = M#p_family_member_info.role_id,
                                   case ID =:= OleInterID of
                                       true ->
                                           M#p_family_member_info{title=?DEFAULT_FAMILY_MEMBER_TITLE};
                                       false ->
                                           M
                                   end
                           end, OldMembers),
            common_title_srv:add_title(?TITLE_FAMILY,OleInterID,?DEFAULT_FAMILY_MEMBER_TITLE);      
        false ->
            NewMembers = State#family_state.family_members
    end,
    LastMembers = lists:map(fun(X) ->
                                   TogID = X#p_family_member_info.role_id,
                                   case TogID =:= TargetRoleID of
                                       true ->
                                           X#p_family_member_info{title=?FAMILY_TITLE_INTERIOR_MANAGER};
                                       false ->
                                           X
                                   end
                           end, NewMembers),    
    NewState = State#family_state{family_members= LastMembers, family_info=OldFamilyInfo#p_family_info{interiormanager = TargetRoleID}},
    update_state(NewState),
    TargetRoleName =common_misc:get_dirty_rolename(TargetRoleID),
    OldInterName = common_misc:get_dirty_rolename(OleInterID),
    R = #m_family_set_interior_manager_toc{role_id=TargetRoleID, role_name=TargetRoleName,oldrole_id= OleInterID,oldrole_name =OldInterName},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
    common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,?FAMILY_TITLE_INTERIOR_MANAGER),
    RB = #m_family_set_interior_manager_toc{return_self=false, role_id=TargetRoleID, role_name=TargetRoleName,oldrole_id= OleInterID,oldrole_name =OldInterName},
    broadcast_to_all_members_except(Module, Method, RB, RoleID).



do_set_interior_manager_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_set_interior_manager_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%% 解除内务使
do_unset_interior_manager(Unique, Module, Method, Record, RoleID, Line) ->
    #m_family_unset_interior_manager_tos{role_id=TargetRoleID} = Record,
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    case is_intermanager(TargetRoleID,FamilyInfo) of
        true ->
            do_uset_nws(Unique, Module, Method, TargetRoleID, RoleID, Line);
        false ->
            Reason = ?_LANG_FAMILY_NOT_NWS,
            do_unset_interior_manager_error(Unique, Module, Method, Reason, RoleID, Line)
    end.

do_uset_nws(Unique, Module, Method, TargetRoleID, RoleID, Line) ->
    State = get_state(),
    FamilyInfo = State#family_state.family_info,
    OldMembers = State#family_state.family_members,
    NewMembers = lists:map(fun(M) ->
                            ID = M#p_family_member_info.role_id,
                                   case ID =:= TargetRoleID of
                                       true ->
                                           M#p_family_member_info{title=?DEFAULT_FAMILY_MEMBER_TITLE};
                                       false ->
                                           M
                                   end
                           end, OldMembers),
    NewFamilyInfo = FamilyInfo#p_family_info{interiormanager=0},
    NewState = State#family_state{family_members=NewMembers, family_info=NewFamilyInfo},
    update_state(NewState),
    R = #m_family_unset_interior_manager_toc{role_id=TargetRoleID},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R),
    common_title_srv:add_title(?TITLE_FAMILY,TargetRoleID,?DEFAULT_FAMILY_MEMBER_TITLE),
    RB = #m_family_unset_interior_manager_toc{return_self=false, role_id=TargetRoleID},
    broadcast_to_all_members_except(Module, Method, RB, RoleID).  

do_unset_interior_manager_error(Unique, Module, Method, Reason, RoleID, Line) ->
    R = #m_family_unset_interior_manager_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_notify_online(Unique, Module, Method, _Record, RoleID, Line)->
    State = get_state(),
    Members = State#family_state.family_members,   
    OnlineMembers = lists:foldl(
                   fun(M,NewList) ->
                           case M#p_family_member_info.online of
                               true ->
                                   [M|NewList];
                               false ->
                                   NewList
                           end
                   end,[], Members),
    R = #m_family_notify_online_toc{online_list=OnlineMembers},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

hook_update_donate_info(Info)->
    case global:whereis_name(mod_family_manager) of
        undefined ->
            ignore;
        GPID ->
            GPID ! Info
    end.

%%家族设置自动加入，则加入家族的时候，不通过申请，直接加入
join_family_direct(RoleID, FamilyID) ->
    #p_role_base{family_id = FID,
                 role_name = RoleName,
                 sex = Sex,
                 head = Head} = RoleBaseRec = mod_role_tab:get({?role_base, RoleID}),
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
    #p_role_attr{office_name = OfficeName, level = RoleLevel} = RoleAttr,
    %%判断玩家是否已经有家族
    case FID > 0 of
        false ->
            [FamilyInfo] = db:dirty_read(?DB_FAMILY, FamilyID),
            #p_family_info{cur_members = CM, level = LV, family_name = FamilyName, members = Members} = FamilyInfo,
            #r_family_config{max_member = MM} = cfg_family:level_config(LV),
            %%判断家族是否满人
            case CM < MM of
                true ->
                    NewMember = #p_family_member_info{title = ?DEFAULT_FAMILY_MEMBER_TITLE,
                                                      role_id = RoleID,
                                                      role_name = RoleName,
                                                      office_name = OfficeName,
                                                      family_contribution = 0,
                                                      sex = Sex,
                                                      head = Head,
                                                      online = true,
                                                      role_level = RoleLevel,
                                                      last_login_time = get_last_login_time(RoleID)},
                    %%改变玩家的家族状态
                    mod_role_tab:put({?role_base, RoleID}, RoleBaseRec#p_role_base{family_id = FamilyID, family_name = FamilyName}),
                    %%更新家族相关操作
                    hook_family_change:hook(change, {RoleID, FamilyID, 0}),
                    hook_family:hook_family_conbtribute_change(RoleID, 0),
                    %%将家族的更新通知给地图
                    NewFamilyInfo = FamilyInfo#p_family_info{cur_members = CM + 1, members = [NewMember|Members]},
                    mod_family:notify_world_update(RoleID, NewFamilyInfo),
                    %%更新数据库
                    db:dirty_write(?DB_FAMILY, NewFamilyInfo),
                    %%更新内存中的家族信息
                    update_state([NewMember|Members], NewFamilyInfo),
                    %%通知所有族员
                    RB = #m_family_member_join_toc{member = NewMember},
                    broadcast_to_all_members(?FAMILY, ?FAMILY_MEMBER_JOIN, RB),
                    %%这是role_attr新加了family_id字段,需要通知更新
                    common_title_srv:add_title(?TITLE_FAMILY, RoleID, ?DEFAULT_FAMILY_MEMBER_TITLE),
                    join_family_for_role(RoleID, RoleName, FamilyName, RoleLevel),
                    ReturnRec = NewFamilyInfo,
                    %%已经自动加入适合的家族，返回加入的家族id给前段
                    #m_family_auto_join_toc{
                        family_id = FamilyID,
                        family_info = ReturnRec
                    };
                false ->
                    []
            end;
        true ->
            []
    end.

check_auto_join(RoleID, FamilyID) ->
    case catch do_request_check(RoleID) of
        ok ->
            join_family_direct(RoleID, FamilyID),
            [FamilyInfo] = db:dirty_read(?DB_FAMILY, FamilyID),
            R = #m_family_agree_f_toc{return_self=false, family_info = FamilyInfo, admit_role_id = 0},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_AGREE_F, R);
        Error when is_binary(Error) ->
            R = #m_family_request_toc{succ=false, reason=Error},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_REQUEST, R);
        Error when is_list(Error) ->
            R = #m_family_request_toc{succ = false, reason = list_to_binary(Error)},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_REQUEST, R);
        {'EXIT', _Error} ->
            R = #m_family_request_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_REQUEST, R)
    end.

check_25_auto_join(RoleID, FamilyID) ->
    case catch do_request_check(RoleID) of
        ok ->
            R = join_family_direct(RoleID, FamilyID),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_AUTO_JOIN, R);
        Error when is_binary(Error) ->
            R = #m_family_request_toc{succ=false, reason=Error},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_REQUEST, R);
        Error when is_list(Error) ->
            R = #m_family_request_toc{succ = false, reason = list_to_binary(Error)},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_REQUEST, R);
        {'EXIT', _Error} ->
            R = #m_family_request_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_REQUEST, R)
    end.