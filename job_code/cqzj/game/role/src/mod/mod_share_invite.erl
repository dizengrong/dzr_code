%% Author: lulijin
%% Created: 2013-4-18
%% Description: TODO: Add description to mod_share_invite
-module(mod_share_invite).

-include("mgeer.hrl").

-export([handle/1]).

-export([init/2, delete/1, 
         cast_share_invite_info/1,
         cast_share_invite_info/2,
         first_pay_award/1,
         level_upgrade_award/2,
         send_init/1,
         gm_set_invite_info/2
        ]).
-compile(export_all).

-define(STATUS_CAN_NOT_OP, 0).
-define(STATUS_CAN_OP,     1).
-define(STATUS_ALREADY_OP, 2).
-define(INVITE_TPYE_ID,    10011). %% 邀请好友

-define(_common_error, Unique, ?COMMON, ?COMMON_ERROR, #m_common_error_toc).
-define(MOD_UNICAST(RoleID, Method, Msg), 
        common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?QQ, Method, Msg)).

%%
%% API Functions
%%

init(RoleID, RoleRec)->
    RoleShareInvite = case is_record(RoleRec, r_role_share_invite) of
        true ->
            get_new_share_invite(RoleID, RoleRec);
        _ ->
            get_init_share_invite(RoleID, RoleRec)
    end,
    set_info({r_role_share_invite, RoleID}, RoleShareInvite).

delete(RoleID) ->
    mod_role_tab:erase({r_role_share_invite, RoleID}).

set_info({Tag,RoleID}, QQShareInviteRec) ->
    mod_role_tab:put({Tag, RoleID}, QQShareInviteRec).

cast_share_invite_info(RoleID, ActivityID) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case get_share_invite_info(RoleID,RoleLevel) of
        {error, _Reason} ->
            ignore;
        ShareInviteInfo ->
            #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info    = FriendsInfo
                         } = ShareInviteInfo,
            MaxFetchTimes = cfg_share_invite:daily_share_fetch_times(),
            InActivity = lists:member(ActivityID, ShareActivity),
            ShareList = get_share_today(RoleID,ShareActivity),
            InShare = case lists:keyfind(ActivityID, 2, ShareList) of
                          #p_share_info{done_times = DoneTimes} ->
                              DoneTimes > cfg_share_invite:share_total_times(ActivityID);
                          _ -> false
                      end,
            if
                FetchTimes >= MaxFetchTimes ->
                    ignore;
                InActivity =:= true ->
                    ignore;
                InShare =:= true ->
                    ignore;
                true ->
                    ShareStatus     = get_share_status(FetchTimes,ShareList),
                    InviteList      = get_invite_today(FriendsInfo),
                    InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                                            {_, T, _} -> T;
                                            _         ->  0
                                    end, 
                    Msg = #m_qq_share_invite_info_toc{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_status    = ShareStatus,
                            share_list      = ShareList,
                            invite_times    = InviteTimes,
                            invite_list     = InviteList
                          },
                    ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
            end
    end.

cast_share_invite_info(RoleID) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case get_share_invite_info(RoleID,RoleLevel) of
        {error, _Reason} ->
            ignore;
        ShareInviteInfo ->
            #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info    = FriendsInfo
                         } = ShareInviteInfo,
            ShareList       = get_share_today(RoleID,ShareActivity),
            ShareStatus     = get_share_status(FetchTimes,ShareList),
            InviteList      = get_invite_today(FriendsInfo),
            InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                                    {_, T, _} -> T;
                                    _         ->  0
                            end, 
            Msg = #m_qq_share_invite_info_toc{
                    share_times     = ShareTimes,
                    fetch_times     = FetchTimes,
                    share_status    = ShareStatus,
                    share_list      = ShareList,
                    invite_times    = InviteTimes,
                    invite_list     = InviteList
                  },
            ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
    end.


send_init(RoleID) ->
    case mod_role_tab:get({r_role_share_invite, RoleID}) of
        undefined ->
            ignore;
        RoleRec ->
            ShareInviteInfo = get_init_share_invite(RoleID, RoleRec),
            #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info    = FriendsInfo
                         } = ShareInviteInfo,
            set_info({r_role_share_invite, RoleID}, ShareInviteInfo),
            ShareList       = get_share_today(RoleID,ShareActivity),
            ShareStatus     = get_share_status(FetchTimes,ShareList),
            InviteList      = get_invite_today(FriendsInfo),
            InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                              {_, T, _} -> T;
                              _         ->  0
                          end,
            Msg = #m_qq_share_invite_info_toc{
                    share_times     = ShareTimes,
                    fetch_times     = FetchTimes,
                    share_status    = ShareStatus,
                    share_list      = ShareList,
                    invite_times    = InviteTimes,
                    invite_list     = InviteList
                  },
            {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
            case RoleLevel < cfg_share_invite:open_level() of
                true ->
                    ignore;
                _ ->
                    ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
            end
    end.

handle({gm_set_invite_info, RoleID, Type}) ->
    gm_set_invite_info(RoleID, Type);

handle({_Unique, ?QQ, ?QQ_SHARE, DataIn, RoleID, _PID, _Line}) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case get_share_invite_info(RoleID,RoleLevel) of
        {error, Reason} ->
            Msg = #m_qq_share_toc{succ = false, reason = Reason},
            ?MOD_UNICAST(RoleID, ?QQ_SHARE, Msg);
        ShareInviteInfo ->
            #m_qq_share_tos{ id =  ShareID } = DataIn,
            do_share(RoleID,ShareID,ShareInviteInfo)
    end;

handle({_Unique, ?QQ, ?QQ_SHARE_FETCH, _DataIn, RoleID, _PID, _Line}) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case get_share_invite_info(RoleID,RoleLevel) of
        {error, Reason} ->
            Msg = #m_qq_share_fetch_toc{succ = false, reason = Reason},
            ?MOD_UNICAST(RoleID, ?QQ_SHARE_FETCH, Msg);
        ShareInviteInfo ->
            do_share_fetch(RoleID,ShareInviteInfo)
    end;

handle({_Unique, ?QQ, ?QQ_INVITE, _DataIn, RoleID, _PID, _Line}) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case get_share_invite_info(RoleID,RoleLevel) of
        {error, Reason} ->
            Msg = #m_qq_invite_toc{succ = false, reason = Reason},
            ?MOD_UNICAST(RoleID, ?QQ_INVITE, Msg);
        ShareInviteInfo ->
            do_invite(RoleID,ShareInviteInfo)
    end;

handle({_Unique, ?QQ, ?QQ_INVITE_FETCH, DataIn, RoleID, _PID, _Line}) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case get_share_invite_info(RoleID,RoleLevel) of
        {error, Reason} ->
            Msg = #m_qq_invite_fetch_toc{succ = false, reason = Reason},
            ?MOD_UNICAST(RoleID, ?QQ_INVITE_FETCH, Msg);
        ShareInviteInfo ->
            #m_qq_invite_fetch_tos{ id = AwardID } = DataIn,
            do_invite_fetch(RoleID,AwardID,ShareInviteInfo)
    end;
   
handle({Unique, ?QQ, ?QQ_SHARE_INVITE_INFO, _DataIn, RoleID, PID, _Line}) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case get_share_invite_info(RoleID,RoleLevel) of
        {error, Reason} ->
            common_misc:unicast2(PID, ?_common_error{error_str = Reason});
        ShareInviteInfo ->
            #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info    = FriendsInfo
                         } = ShareInviteInfo,
            ShareList       = get_share_today(RoleID,ShareActivity),
            ShareStatus     = get_share_status(FetchTimes,ShareList),
            InviteList      = get_invite_today(FriendsInfo),
            InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                              {_, T, _} -> T;
                              _         ->  0
                          end,
            Msg = #m_qq_share_invite_info_toc{
                    share_times     = ShareTimes,
                    fetch_times     = FetchTimes,
                    share_status    = ShareStatus,
                    share_list      = ShareList,
                    invite_times    = InviteTimes,
                    invite_list     = InviteList
                  },
            ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
    end.

first_pay_award(RoleID) ->
    erlang:spawn(
        fun() ->
            case mod_qq_api:get_app_friends(RoleID) of
                [] ->
                    ignore;
                FriendList ->
                    lists:foreach(fun(OpenID) ->
                        FriendRoleID = mod_qq_cache:get_roleid(OpenID),
                        if
                            FriendRoleID =:= RoleID ->
                                ignore;
                            FriendRoleID =:= 0 ->
                                ignore;
                            true ->
                                update_friends_pay_role_info(FriendRoleID)
                        end
                    end, FriendList)
        end
    end).

update_friends_pay_role_info(FriendRoleID) ->
    FirstPayList = cfg_share_invite:first_pay_list(),
    case mod_role_tab:get({r_role_share_invite, FriendRoleID}) of
        undefined ->
            RoleMisc = case db:dirty_read(?DB_ROLE_MISC_P, FriendRoleID) of
                [] ->
                    #r_role_misc{role_id=FriendRoleID, tuples=[]};
                [RoleMisc2] ->
                    RoleMisc2
            end,
            TuplesInfo = RoleMisc#r_role_misc.tuples,
            case lists:keyfind(r_role_share_invite, 1, TuplesInfo) of
                false ->
                    ignore;
                ShareInviteInfo ->
                    #r_role_share_invite{
                            friends_info    = FriendsInfo
                         } = ShareInviteInfo,
                    TotalFriendsInfo = lists:foldl(
                        fun(AwardID, AccIn) ->
                            {Num,_} = cfg_share_invite:invite_condition(AwardID),
                            Times = case lists:keyfind(AwardID, 1, FriendsInfo) of
                                      {_, T2, FetchStatus} -> T2;
                                      _ -> FetchStatus = 0
                                  end,
                            case Times < Num of
                                true -> 
                                    NewTimes = Times + 1,
                                    NewFetchStatus = case NewTimes =:= Num andalso FetchStatus =:= ?STATUS_CAN_NOT_OP of
                                                    true -> ?STATUS_CAN_OP;
                                                    _ -> FetchStatus
                                                end,
                                    NewInviteListInfo = {AwardID, NewTimes, NewFetchStatus},
                                    lists:keystore(AwardID, 1, AccIn, NewInviteListInfo);
                                _ ->
                                    AccIn
                            end        
                        end, FriendsInfo, FirstPayList),
                    NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                                                           friends_info = TotalFriendsInfo
                                                                  },
                    NewTuples = lists:keystore(r_role_share_invite, 1,TuplesInfo,NewShareInviteInfo),
                    db:dirty_write(?DB_ROLE_MISC_P, RoleMisc#r_role_misc{tuples = NewTuples})
            end;
        ShareInviteInfo ->
            #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info    = FriendsInfo
                         } = ShareInviteInfo,
            TotalFriendsInfo = lists:foldl(
                fun(AwardID, AccIn) ->
                    {Num,_} = cfg_share_invite:invite_condition(AwardID),
                    Times = case lists:keyfind(AwardID, 1, FriendsInfo) of
                              {_, T2, FetchStatus} -> T2;
                              _ -> FetchStatus = 0
                          end,
                    case Times < Num of
                        true -> 
                            NewTimes = Times + 1,
                            NewFetchStatus = case NewTimes =:= Num andalso FetchStatus =:= ?STATUS_CAN_NOT_OP of
                                            true -> ?STATUS_CAN_OP;
                                            _ -> FetchStatus
                                        end,
                            NewInviteListInfo = {AwardID, NewTimes, NewFetchStatus},
                            lists:keystore(AwardID, 1, AccIn, NewInviteListInfo);
                        _ ->
                            AccIn
                    end        
                end, FriendsInfo, FirstPayList),
            NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                                                   friends_info = TotalFriendsInfo
                                                                  },
            set_info({r_role_share_invite, FriendRoleID}, NewShareInviteInfo),
            ShareList       = get_share_today(FriendRoleID,ShareActivity),
            ShareStatus     = get_share_status(FetchTimes,ShareList),
            NewInviteList1  = get_invite_today(TotalFriendsInfo),
            InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                            {_, T1, _} -> T1;
                            _         ->  0
                        end,
            Msg = #m_qq_share_invite_info_toc{
                  share_times     = ShareTimes,
                  fetch_times     = FetchTimes,
                  share_status    = ShareStatus,
                  share_list      = ShareList,
                  invite_times    = InviteTimes,
                  invite_list     = NewInviteList1
              },
            ?MOD_UNICAST(FriendRoleID, ?QQ_SHARE_INVITE_INFO, Msg)
    end.
      

level_upgrade_award(RoleID, Level) ->
    AwardLevelList = cfg_share_invite:arward_level_list(),
    case lists:member(Level, AwardLevelList) of
        true ->
            erlang:spawn(
                fun() ->
                    case mod_qq_api:get_app_friends(RoleID) of
                        [] ->
                            ignore;
                        FriendList ->
                            lists:foreach(fun(OpenID) ->
                                FriendRoleID = mod_qq_cache:get_roleid(OpenID),
                                if
                                    FriendRoleID =:= 0 ->
                                        ignore;
                                    FriendRoleID =:= RoleID ->
                                        ignore;
                                    true ->
                                        update_lv_up_role_info(FriendRoleID, Level)
                                end
                            end, FriendList)
                    end
                end);
        _ ->
            ignore
    end.

update_lv_up_role_info(FriendRoleID, Level) ->
    LevelUPList = cfg_share_invite:level_up_list(),
    case mod_role_tab:get({r_role_share_invite, FriendRoleID}) of
        undefined ->
            RoleMisc = case db:dirty_read(?DB_ROLE_MISC_P, FriendRoleID) of
                [] ->
                    #r_role_misc{role_id=FriendRoleID, tuples=[]};
                [RoleMisc2] ->
                    RoleMisc2
            end,
            TuplesInfo = RoleMisc#r_role_misc.tuples,
            case lists:keyfind(r_role_share_invite, 1, TuplesInfo) of
                false ->
                    ignore;
                ShareInviteInfo ->
                    #r_role_share_invite{
                                    friends_info    = FriendsInfo
                                 } = ShareInviteInfo,
                    TotalFriendsInfo = lists:foldl(
                        fun(AwardID, AccIn) ->
                            {Num,LV} = cfg_share_invite:invite_condition(AwardID),
                            Times = case lists:keyfind(AwardID, 1, FriendsInfo) of
                                {_, T, FetchStatus} -> T;
                                _ -> FetchStatus = 0
                            end,
                            case Times < Num of
                                true ->
                                    case LV =:= Level of
                                        true ->
                                            NewTimes = Times + 1,
                                            NewFetchStatus = case NewTimes =:= Num andalso FetchStatus =:= ?STATUS_CAN_NOT_OP of
                                                    true -> ?STATUS_CAN_OP;
                                                    _ -> FetchStatus
                                                end,
                                            NewInviteListInfo = {AwardID, NewTimes, NewFetchStatus},
                                            lists:keystore(AwardID, 1, AccIn, NewInviteListInfo);
                                        _ ->
                                            AccIn
                                    end;
                                _ ->
                                    AccIn
                            end        
                        end, FriendsInfo, LevelUPList),
                    NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                                                           friends_info = TotalFriendsInfo
                                                                  },
                    NewTuples = lists:keystore(r_role_share_invite, 1,TuplesInfo,NewShareInviteInfo),
                    db:dirty_write(?DB_ROLE_MISC_P, RoleMisc#r_role_misc{tuples = NewTuples })
            end;
        ShareInviteInfo ->
            #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info    = FriendsInfo
                         } = ShareInviteInfo,
            TotalFriendsInfo = lists:foldl(
                fun(AwardID, AccIn) ->
                    {Num,LV} = cfg_share_invite:invite_condition(AwardID),
                    Times = case lists:keyfind(AwardID, 1, FriendsInfo) of
                        {_, T, FetchStatus} -> T;
                        _ -> FetchStatus = 0
                    end,
                    case Times < Num of
                        true ->
                            case LV =:= Level of
                                true ->
                                    NewTimes = Times + 1,
                                    NewFetchStatus = case NewTimes =:= Num andalso FetchStatus =:= ?STATUS_CAN_NOT_OP of
                                            true -> ?STATUS_CAN_OP;
                                            _ -> FetchStatus
                                        end,
                                    NewInviteListInfo = {AwardID, NewTimes, NewFetchStatus},
                                    lists:keystore(AwardID, 1, AccIn, NewInviteListInfo);
                                _ ->
                                    AccIn
                            end;
                        _ ->
                            AccIn
                    end        
                end, FriendsInfo, LevelUPList),
            NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                                               friends_info = TotalFriendsInfo
                                                              },
            set_info({r_role_share_invite, FriendRoleID}, NewShareInviteInfo),
            ShareList       = get_share_today(FriendRoleID,ShareActivity),
            ShareStatus     = get_share_status(FetchTimes,ShareList),
            NewInviteList1   = get_invite_today(TotalFriendsInfo),
            InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                            {_, T1, _} -> T1;
                            _         ->  0
                        end,
            Msg = #m_qq_share_invite_info_toc{
                  share_times     = ShareTimes,
                  fetch_times     = FetchTimes,
                  share_status    = ShareStatus,
                  share_list      = ShareList,
                  invite_times    = InviteTimes,
                  invite_list     = NewInviteList1
              },
            ?MOD_UNICAST(FriendRoleID, ?QQ_SHARE_INVITE_INFO, Msg)
    end.

%%
%% Local Functions
%%

get_new_share_invite(RoleID, RoleRec) ->
    Date = date(),
    case RoleRec#r_role_share_invite.date == Date of
        true ->
            RoleRec#r_role_share_invite{date=Date};
        _ ->
            RoleRec2 = get_init_share_invite(RoleID, RoleRec),
            FriendsInfo = RoleRec2#r_role_share_invite.friends_info,
            FirstPayList = cfg_share_invite:first_pay_list(),
            NewDayFriendsInfo = lists:foldl(fun(AwardID, AccIn) ->
                                  case lists:keyfind(AwardID, 1, FriendsInfo) of
                                        false -> AccIn;
                                        {_, _, ?STATUS_CAN_NOT_OP} ->
                                            NewInviteListInfo = {AwardID, 0, ?STATUS_CAN_NOT_OP},
                                            lists:keystore(AwardID, 1, AccIn, NewInviteListInfo);
                                        _-> AccIn
                                  end        
                          end, FriendsInfo, FirstPayList),
            RoleRec2#r_role_share_invite{friends_info = NewDayFriendsInfo}
            
    end.

get_init_share_invite(_RoleID, RoleRec) when is_record(RoleRec, r_role_share_invite) ->
    FriendsInfo = RoleRec#r_role_share_invite.friends_info,
    FirstPayList = cfg_share_invite:first_pay_list(),
    NewDayFriendsInfo = lists:foldl(fun(AwardID, AccIn) ->
                            case lists:keyfind(AwardID, 1, FriendsInfo) of
                                false -> AccIn;
                                {_, _, ?STATUS_CAN_NOT_OP} ->
                                    NewInviteListInfo = {AwardID, 0, ?STATUS_CAN_NOT_OP},
                                    lists:keystore(AwardID, 1, AccIn, NewInviteListInfo);
                                _-> AccIn
                            end        
                  end, FriendsInfo, FirstPayList),
    #r_role_share_invite{
        share_times     = 0,
        fetch_times     = 0,
        share_activity  = [],
        friends_info    = NewDayFriendsInfo,
        date            = erlang:date()
    };

get_init_share_invite(_RoleID, _RoleRec) ->
    #r_role_share_invite{
        share_times     = 0,
        fetch_times     = 0,
        share_activity  = [],
        friends_info    = [],
        date            = erlang:date()
    }.

get_share_invite_info(RoleID,RoleLevel) ->
    OpenLevel =  cfg_share_invite:open_level(),
    case RoleLevel < OpenLevel of
        true ->
            {error,  <<"等级不足">>};
        false ->
            mod_role_tab:get({r_role_share_invite, RoleID})
    end.

do_share(RoleID, ShareID, ShareInviteInfo) ->
    #r_role_share_invite{
                     share_times    = ShareTimes,
                     fetch_times    = FetchTimes,
                     share_activity = ShareActivity,
                     friends_info    = FriendsInfo
                    } = ShareInviteInfo,
    MaxShareTimes = cfg_share_invite:daily_share_times(),
    ShareTodayList = cfg_share_invite:share_activity(),
    case lists:member(ShareID, ShareTodayList) of
        true ->
            case lists:member(ShareID, ShareActivity) of
                true ->
                    ?MOD_UNICAST(RoleID, ?QQ_SHARE, #m_qq_share_toc{succ = false, reason = <<"今天已经分享过该活动">>});
                _ ->
                    case ShareTimes >= MaxShareTimes of
                        true ->
                            ?MOD_UNICAST(RoleID, ?QQ_SHARE, #m_qq_share_toc{succ = false, reason = <<"今天已经到达分享次数上限">>});
                    _ ->
                        NewShareActivity = ShareActivity ++ [ShareID],
                        NewShareTimes = ShareTimes + 1,
                        NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                                                                 share_times = NewShareTimes,
                                                                 share_activity = NewShareActivity
                                                             },
                        set_info({r_role_share_invite, RoleID}, NewShareInviteInfo),
                        NewShareList    = get_share_today(RoleID,NewShareActivity),
                        ShareStatus     = get_share_status(FetchTimes,NewShareList),
                        InviteList      = get_invite_today(FriendsInfo),
                        InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                                    {_, T, _} -> T;
                                    _         ->  0
                            end,
                        Msg = #m_qq_share_invite_info_toc{
                                share_times     = NewShareTimes,
                                fetch_times     = FetchTimes,
                                share_status    = ShareStatus,
                                share_list      = NewShareList,
                                invite_times    = InviteTimes,
                                invite_list     = InviteList
                             },
                        ?MOD_UNICAST(RoleID, ?QQ_SHARE, #m_qq_share_toc{succ=true}),
                        ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
                    end
             end;
        _ ->
            ?MOD_UNICAST(RoleID, ?QQ_SHARE, #m_qq_share_toc{succ = false, reason = <<"系统错误">>})
    end.

do_invite(RoleID, ShareInviteInfo) ->
    #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info  = FriendsInfo 
                        } = ShareInviteInfo,
    AwardID = ?INVITE_TPYE_ID,
    {Num,_} = cfg_share_invite:invite_condition(AwardID),
    Times = case lists:keyfind(AwardID, 1, FriendsInfo) of
                {_, T, FetchStatus} -> T;
                _ -> FetchStatus = 0
            end,
    case Times >= Num of
        true ->
            ?MOD_UNICAST(RoleID, ?QQ_INVITE, #m_qq_invite_toc{succ=true});
        _ ->
            NewInviteListInfo = {AwardID, Times + 1, FetchStatus},
            NewFriendsInfo = lists:keystore(AwardID, 1, FriendsInfo, NewInviteListInfo),
            NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                               friends_info = NewFriendsInfo
                           },
            set_info({r_role_share_invite, RoleID}, NewShareInviteInfo),
            ShareList       = get_share_today(RoleID,ShareActivity),
            ShareStatus     = get_share_status(FetchTimes,ShareList),
            NewInviteList1   = get_invite_today(NewFriendsInfo),
            Msg = #m_qq_share_invite_info_toc{
                    share_times     = ShareTimes,
                    fetch_times     = FetchTimes,
                    share_status    = ShareStatus,
                    share_list      = ShareList,
                    invite_times    = Times + 1,
                    invite_list     = NewInviteList1
                },
            ?MOD_UNICAST(RoleID, ?QQ_INVITE, #m_qq_invite_toc{succ=true}),
            ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
    end.

do_share_fetch(RoleID,ShareInviteInfo) ->
    #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info    = FriendsInfo
                        } = ShareInviteInfo,
    MaxFetchTimes = cfg_share_invite:daily_share_fetch_times(),
    if
       FetchTimes >= MaxFetchTimes ->
           ?MOD_UNICAST(RoleID, ?QQ_SHARE_FETCH, #m_qq_share_fetch_toc{succ=false,reason= <<"今天已经到达抽奖次数上限">> });
       true ->
           ItemAwardList =  cfg_share_invite:share_reward(),
           case common_tool:random_from_tuple_weights(ItemAwardList, 4) of
               {ItemID, Num, IsBind,_} ->
                   case mod_bag:add_items(RoleID, [{ItemID, Num, 1, IsBind}], ?LOG_ITEM_TYPE_QQ_SHARE_AWARD) of 
                       {error, Reason1} ->
                           Msg = #m_qq_share_fetch_toc{succ=false,reason= Reason1 },
                           ?MOD_UNICAST(RoleID, ?QQ_SHARE_FETCH, Msg);
                       {true, _} ->
                           NewFetchTimes = FetchTimes + 1,
                           NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{fetch_times = NewFetchTimes},
                           set_info({r_role_share_invite, RoleID}, NewShareInviteInfo),
                           NewShareList    = get_share_today(RoleID,ShareActivity),
                           ShareStatus     = get_share_status(NewFetchTimes,NewShareList),
                           InviteList      = get_invite_today(FriendsInfo),
                           InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, FriendsInfo) of
                                            {_, Times, _} -> Times;
                                             _        ->  0
                                            end,
                           Msg = #m_qq_share_invite_info_toc{
                                   share_times     = ShareTimes,
                                   fetch_times     = FetchTimes + 1,
                                   share_status    = ShareStatus,
                                   share_list      = NewShareList,
                                   invite_times    = InviteTimes,
                                   invite_list     = InviteList
                                },
                           ?MOD_UNICAST(RoleID, ?QQ_SHARE_FETCH, #m_qq_share_fetch_toc{succ=true,item_id=ItemID}),
                           ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
                       end;
               false ->
                    Msg = #m_qq_share_fetch_toc{succ=false,reason= <<"系统错误">> },
                    ?MOD_UNICAST(RoleID, ?QQ_SHARE_FETCH, Msg)
           end
    end.
    

do_invite_fetch(RoleID,AwardID,ShareInviteInfo) ->
    #r_role_share_invite{
                            share_times     = ShareTimes,
                            fetch_times     = FetchTimes,
                            share_activity  = ShareActivity,
                            friends_info     = FriendsInfo 
                        } = ShareInviteInfo,
    Times = case lists:keyfind(AwardID, 1, FriendsInfo) of
                {_, T, Status} -> T;
                _ -> Status = 0
            end,
    {Num, _} = cfg_share_invite:invite_condition(AwardID),
    case Times >= Num of
        true ->
            case Status=:= ?STATUS_ALREADY_OP of
                true ->
                    Reason = <<"该奖励已经领取过">>,
                    ?MOD_UNICAST(RoleID, ?QQ_INVITE_FETCH, #m_qq_invite_fetch_toc{succ=true,reason=Reason});
                _ ->
                    Itemlist = cfg_share_invite:invite_reward(AwardID),
                    case mod_bag:add_items(RoleID, Itemlist, ?LOG_ITEM_TYPE_QQ_INVITE_AWARD) of 
                            {error, Reason} ->
                                Msg = #m_qq_invite_fetch_toc{ succ = false, reason = Reason},
                                ?MOD_UNICAST(RoleID, ?QQ_INVITE_FETCH, Msg);
                            {true, _} ->
                                NewInviteListInfo = {AwardID, Times, ?STATUS_ALREADY_OP},
                                NewFriendsInfo = lists:keystore(AwardID, 1, FriendsInfo, NewInviteListInfo),
                                NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                                                   friends_info = NewFriendsInfo
                                               },
                                set_info({r_role_share_invite, RoleID}, NewShareInviteInfo),
                                ShareList       = get_share_today(RoleID,ShareActivity),
                                ShareStatus     = get_share_status(FetchTimes,ShareList),
                                NewInviteList1   = get_invite_today(NewFriendsInfo),
                                InviteTimes = case lists:keyfind(?INVITE_TPYE_ID, 1, NewFriendsInfo) of
                                                    {_,Times1,_} -> Times1;
                                                    _            ->  0
                                              end,       
                                Msg = #m_qq_share_invite_info_toc{
                                        share_times     = ShareTimes,
                                        fetch_times     = FetchTimes,
                                        share_status    = ShareStatus,
                                        share_list      = ShareList,
                                        invite_times    = InviteTimes,
                                        invite_list     = NewInviteList1
                                    },
                                ?MOD_UNICAST(RoleID, ?QQ_INVITE_FETCH, #m_qq_invite_fetch_toc{succ=true}),
                                ?MOD_UNICAST(RoleID, ?QQ_SHARE_INVITE_INFO, Msg)
                     end
            end;
        _ ->
            Reason = <<"未达到领取奖励次数">>,
            ?MOD_UNICAST(RoleID, ?QQ_INVITE_FETCH, #m_qq_invite_fetch_toc{succ=true,reason=Reason})
    end.

get_share_today(RoleID,ShareActivity) ->
    {ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    {ok, #p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),
    ShareTodayList = cfg_share_invite:share_activity(),
    FilterFun = fun(ActivityID) ->
        #r_activity_today{need_level=NeedLevel} = cfg_activity:activity(ActivityID),
        RoleLevel>=NeedLevel
    end,
    MatchedList     = lists:filter(FilterFun, ShareTodayList),
    ActivityTaskRec = mod_daily_activity:get_task_rec(RoleID),
    [update_activity_status(RoleID, ActivityID, FamilyID, ActivityTaskRec#r_activity_task.tasks,ShareActivity) 
        || ActivityID <- MatchedList].
    
update_activity_status(_RoleID, ActivityID, FamilyID, DoneTasks,ShareActivity) ->
    #r_activity_today{
            need_family = IsNeedFamily
                     } = cfg_activity:activity(ActivityID),
    CheckFamiliy = ( IsNeedFamily=/=true orelse FamilyID>0 ),
    if
        CheckFamiliy->
            DoneTimes = get_done_times(ActivityID, DoneTasks),
            Status = case lists:member(ActivityID, ShareActivity) of
                true ->
                    ?STATUS_ALREADY_OP;
                _ ->
                    CfgTimes = cfg_share_invite:share_total_times(ActivityID),
                    case DoneTimes >= CfgTimes of
                        true ->
                            ?STATUS_CAN_OP;
                        _ ->
                            ?STATUS_CAN_NOT_OP
                    end
            end;
        true ->
            Status    = ?STATUS_CAN_NOT_OP,
            DoneTimes = 0
    end,
    #p_share_info{
            id          = ActivityID,
            status      = Status,
            done_times  = DoneTimes
        }.

get_done_times(ActivityID, DoneTasks) ->
    case lists:keyfind(ActivityID, 1, DoneTasks) of 
        false -> DoneTimes = 0;
        {_, DoneTimes} -> ok
    end,
    DoneTimes.

get_share_status(FetchTimes, NewShareList) ->
     CanFetchTimes = lists:foldl(fun(Rec,Times) ->
                 DoneTimes = Rec#p_share_info.done_times,
                 CfgTimes  = cfg_share_invite:share_total_times(Rec#p_share_info.id),
                 Status    = Rec#p_share_info.status,
                 case DoneTimes >= CfgTimes andalso Status =:= ?STATUS_ALREADY_OP of
                     true ->
                         Times + 1;
                     _ -> 
                         Times
                 end
         end,0,NewShareList),
     case FetchTimes < CanFetchTimes of
         true -> 1;
         _ -> 0
     end.

get_invite_today(FriendsInfo) ->
    InviteList = [update_friends_status({ID, Times, Status})|| {ID, Times, Status} <- FriendsInfo],
    lists:filter(fun(E) -> E#p_invite_info.status =/= ?STATUS_CAN_NOT_OP end, InviteList).

update_friends_status({ID, Times, Status}) ->
    {Num, _} = cfg_share_invite:invite_condition(ID),
    if
        Status =:= ?STATUS_ALREADY_OP ->
            #p_invite_info{id = ID, status = Status};
        Times >= Num ->
            #p_invite_info{id = ID, status = ?STATUS_CAN_OP};
        true ->
            #p_invite_info{id = ID, status = ?STATUS_CAN_NOT_OP}
    end.

gm_set_invite_info(RoleID, Type) ->
    case Type >=1 andalso Type =< 7 of
        true ->
            ShareInviteInfo = case mod_role_tab:get({r_role_share_invite, RoleID}) of
                undefined ->
                    #r_role_share_invite{
                        share_times     = 0,
                        fetch_times     = 0,
                        share_activity  = [],
                        friends_info    = [],
                        date            = erlang:date()
                    };
                RoleRec ->
                    RoleRec
            end,
            FriendsInfo = ShareInviteInfo#r_role_share_invite.friends_info,
            AwardID = cfg_share_invite:invite_type_id(Type),
            {Num,_} =  cfg_share_invite:invite_condition(AwardID),
            NewInviteListInfo = {AwardID, Num, ?STATUS_CAN_OP},
            NewFriendsInfo = lists:keystore(AwardID, 1, FriendsInfo, NewInviteListInfo),
            NewShareInviteInfo = ShareInviteInfo#r_role_share_invite{
                                       friends_info = NewFriendsInfo
                                   },
            set_info({r_role_share_invite, RoleID}, NewShareInviteInfo),
            cast_share_invite_info(RoleID);
        _ ->
            ignore
    end.