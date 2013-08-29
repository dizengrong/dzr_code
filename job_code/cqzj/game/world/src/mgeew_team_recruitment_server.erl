%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     处理玩家的队友招募
%%% @end
%%% Created : 2011-12-02
%%%-------------------------------------------------------------------
-module(mgeew_team_recruitment_server).

-behaviour(gen_server).
-include("mgeew.hrl").

-export([start/0,
         start_link/0]).

%% admin helper function
-export([test_get_queues/0,
         test_clean_queues/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(recruitment_queue, recruitment_queue).

%% faction_and_type : {faction_id, recruitment_type}
-record(r_recruitment_queue, {faction_and_type, queue}).

-record(r_recruitment_info, {team_id, role_ids, create_time}).

-record(state, {}).

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent,10000, worker,
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    init_queues(),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
get_role_type_info(RoleID) ->
	erlang:get({type_info, RoleID}).

set_role_type_info(RoleID, FactionAndType) ->
	erlang:put({type_info, RoleID}, FactionAndType).

erase_role_type_info(RoleID) ->
	case erlang:get({type_info, RoleID}) of
		undefined ->
			ignore;
		_ ->
			erlang:erase({type_info, RoleID})
	end.

init_queues() ->
	erlang:erase(),
    erlang:put(?recruitment_queue,[]).

get_queues() ->
    erlang:get(?recruitment_queue).

get_queue_by_type(FactionAndType) ->
    Queues = get_queues(),
    lists:keyfind(FactionAndType, #r_recruitment_queue.faction_and_type, Queues).

set_queue_by_type(FactionAndType, Queue) ->
    NewQueues = lists:keydelete(FactionAndType, #r_recruitment_queue.faction_and_type, get_queues()),
    erlang:put(?recruitment_queue, [Queue|NewQueues]),
    ok.
        
insert_queue_by_type(FactionAndType, RoleIds, TeamId) ->
    CreateTime = common_tool:now(),
    RecruitmentInfo = #r_recruitment_info{role_ids=RoleIds, team_id=TeamId, create_time=CreateTime},
    NewRecruitmentQueue = case get_queue_by_type(FactionAndType) of 
                              false ->
                                  #r_recruitment_queue{faction_and_type=FactionAndType, queue=[RecruitmentInfo]};
                              RecruitmentQueue ->
                                  update_recruitment_queue(RecruitmentQueue, RecruitmentInfo)
                          end,
    set_queue_by_type(FactionAndType, NewRecruitmentQueue),
    ok.

update_recruitment_queue(RecruitmentQueue, RecruitmentInfo) ->
    #r_recruitment_queue{queue=Queue} = RecruitmentQueue, 
    #r_recruitment_info{role_ids=RoleIds} = RecruitmentInfo,
    case lists:keyfind(RoleIds, #r_recruitment_info.role_ids, Queue) of
        false ->
            NewQueue = sort_queue([RecruitmentInfo|Queue]),
            RecruitmentQueue#r_recruitment_queue{queue=NewQueue};
        _ ->
            %% already in queue
            RecruitmentQueue
    end.

%% 队列排序，队伍排前，个人排最后，然后再按加入的时间排
sort_queue(Queue) ->
    lists:sort(
      fun(Info1, Info2) ->
              #r_recruitment_info{team_id=TeamId1, create_time=CreateTime1} = Info1,
              #r_recruitment_info{team_id=TeamId2, create_time=CreateTime2} = Info2,
              if TeamId1 =:= 0 andalso TeamId2 =:= 0 ->
                     if CreateTime1 < CreateTime2 ->
                            true;
                        true ->
                            false
                     end;
                 TeamId1 =:= 0 andalso TeamId2 =/= 0 ->
                     false;
                 TeamId1 =/= 0 andalso TeamId2 =:= 0 ->
                     true;
                 TeamId1 =/= 0 andalso TeamId2 =/= 0 ->
                     if CreateTime1 < CreateTime2 ->
                            true;
                        true ->
                            false
                     end
              end
      end, Queue).

delete_match_recruitment_info_in_queue(FactionAndType, MathcRoleList) ->
    case get_queue_by_type(FactionAndType) of
        false ->
            {error, not_in_queue};
        RecruitmentQueue ->
            #r_recruitment_queue{queue=Queue} = RecruitmentQueue,
            NewQueue = lists:filter(
                         fun(RoleInfo) ->
                                 case lists:keyfind(RoleInfo#r_recruitment_info.role_ids, #r_recruitment_info.role_ids, MathcRoleList) of 
                                     false ->
                                         true;
                                     _ ->
                                         false
                                 end
                         end, Queue),
            set_queue_by_type(FactionAndType, RecruitmentQueue#r_recruitment_queue{queue=NewQueue}),
            ok
    end.

do_handle_info({sign_up,Msg}) ->
    do_sign_up(Msg);

do_handle_info({sign_up_other,Msg}) ->
    do_sign_up_other(Msg);

do_handle_info({cancel,Msg}) ->
    do_cancel(Msg);

do_handle_info({offline, Msg}) ->
    do_offline(Msg);

do_handle_info({info_query, Msg}) ->
    do_info_query(Msg);

do_handle_info({admin_queues,Msg}) ->
    do_admin_queues(Msg);

do_handle_info(Info) ->
    ?ERROR_MSG("招募进程无法处理此消息 Info=~w",[Info]),
    ok.

do_sign_up({RoleID, TeamID, TeamRoleIdList, FactionAndType}) ->
    {_FactionId, Type} = FactionAndType,
    RoleIDs = get_team_members(RoleID, TeamID, TeamRoleIdList),
    insert_queue_by_type(FactionAndType, RoleIDs, TeamID),
    case match_recruitment(FactionAndType, RoleIDs, TeamID) of
        {not_match_all, MathcRoleList} ->
            MatchRoleIDList = lists:flatten(lists:map(fun(RoleInfo) -> RoleInfo#r_recruitment_info.role_ids end, MathcRoleList)),
            lists:foreach(
              fun(SendRoleID) ->
					  set_role_type_info(SendRoleID, FactionAndType),
                      case common_misc:is_role_online(SendRoleID) of
                          true ->
                              common_misc:send_to_rolemap(SendRoleID, {mod_map_team, {update_recruitmemt_info, {update, SendRoleID, Type, MatchRoleIDList}}});
                          false ->
                              update_offline_role_recruitment_state(SendRoleID, Type)
                      end
              end, MatchRoleIDList);
        {ok, MathcRoleList} ->
            delete_match_recruitment_info_in_queue(FactionAndType, MathcRoleList),
            MatchRoleIDList = lists:flatten(lists:map(fun(RoleInfo) -> RoleInfo#r_recruitment_info.role_ids end, MathcRoleList)),
            lists:foreach(
              fun(SendRoleID) ->
					  erase_role_type_info(SendRoleID),
                      case common_misc:is_role_online(SendRoleID) of
                          true ->
                              common_misc:send_to_rolemap(SendRoleID, {mod_map_team, {update_recruitmemt_info, {finish, SendRoleID, Type, MatchRoleIDList}}});
                          false ->
                              update_offline_role_recruitment_state(SendRoleID, 0)
                      end
              end, MatchRoleIDList),
            notify_roles_to_join_or_build_team(MathcRoleList);
        {error, not_in_queue} ->
            ?ERROR_MSG("recruitment error: can't match, not found this type= ~w of recruitment in queue", [FactionAndType])
    end.

update_offline_role_recruitment_state(RoleID, Type) ->
    case db:transaction(
           fun() ->
                   [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID),
                   if RoleAttr#p_role_attr.recruitment_type_id =/= Type ->
                          NewRoleAttr = RoleAttr#p_role_attr{recruitment_type_id=Type},
                          db:write(?DB_ROLE_ATTR, NewRoleAttr, write);
                      true ->
                          ignore
                   end,
                   ok
           end) of
        {atomic, ok} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("玩家下线后，更新role_attr 失败  error ~w", [Error])
    end.
            

do_sign_up_other({RoleID, TeamID, TeamRoleIdList,OldFactionAndType, NewFactionAndType}) ->
    %% 获取之前匹配的所有招募队员信息
    RoleIDs = get_team_members(RoleID, TeamID, TeamRoleIdList),
    {not_match_all, MathcRoleList} = match_recruitment(OldFactionAndType, RoleIDs, TeamID),
    MatchRoleIDList = lists:flatten(lists:map(fun(RoleInfo) -> RoleInfo#r_recruitment_info.role_ids end, MathcRoleList)),
    %% 通知以前的招募其他成员更新
    NotifyToUpdateRoleIds = lists:filter(fun(Elem) -> not lists:member(Elem, RoleIDs) end, MatchRoleIDList),
    {_, OldType} = OldFactionAndType,
    lists:foreach(
               fun(SendRoleID) ->
                       case common_misc:is_role_online(SendRoleID) of
                          true ->
                              common_misc:send_to_rolemap(SendRoleID, {mod_map_team, {update_recruitmemt_info, {update, SendRoleID, OldType, NotifyToUpdateRoleIds}}});
                          false ->
                              ignore
                       end
               end, NotifyToUpdateRoleIds),
    delete_recruitment_info_in_queue(OldFactionAndType, RoleID, TeamID),
    do_sign_up({RoleID, TeamID, TeamRoleIdList, NewFactionAndType}).

get_team_members(RoleID, TeamID, TeamRoleIdList) ->
    if TeamID =:= 0 ->
           [RoleID];
       true ->
           lists:sort(TeamRoleIdList)
    end.

match_recruitment(FactionAndType, RoleIDs, TeamID) ->
    case get_queue_by_type(FactionAndType) of
        false ->
            {error, not_in_queue};
        RecruitmentQueue ->
            {MatchNum, MatchList} = match(RecruitmentQueue, RoleIDs, TeamID),
            if MatchNum =< 0 ->
                   {ok, MatchList};
               true ->
                   {not_match_all, MatchList}
            end
    end.

match(RecruitmentQueue, RoleIDs, TeamID) ->
    #r_recruitment_queue{faction_and_type=FactionAndType, queue=Queue} = RecruitmentQueue,
    {_FactionId, Type} = FactionAndType,
    #r_recruitment_config{need_member_num=NeedMemberNum} = get_recruitment_type(Type),
    [R] = lists:filter(fun(RecruitmentInfo) -> RecruitmentInfo#r_recruitment_info.role_ids =:= RoleIDs end, Queue),
    {MatchNum, MatchList} = lists:foldl(
      fun(RecruitmentInfo, {NeedNum, AccTeamMembers})->
              #r_recruitment_info{role_ids= QRoleIDs, team_id=QTeamID} = RecruitmentInfo,
			  %% NeedNum =< 0 因为组队申请招募超过所需的人数时，需直接返回
              if NeedNum =< 0 orelse QRoleIDs =:= RoleIDs ->
                     {NeedNum, AccTeamMembers};
                 true ->
                     %% 玩家组队来招募
                     if TeamID =/= 0 ->
                            %% 匹配个人
                            if QTeamID =:= 0->
                                   {NeedNum - 1, [RecruitmentInfo | AccTeamMembers]};
                               true ->
                                   {NeedNum, AccTeamMembers}
                            end;
                        %% 玩家个人来招募
                        true ->
                            if QTeamID =/= 0 ->
                                   {NeedNum - erlang:length(QRoleIDs), [RecruitmentInfo | AccTeamMembers]};
                               true ->
                                   {NeedNum - 1, [RecruitmentInfo | AccTeamMembers]}
                            end
                     end
              end
      end, {NeedMemberNum - erlang:length(RoleIDs),[R]}, Queue),
    SortMatchList = lists:sort(fun(Elem1, Elem2) -> Elem1#r_recruitment_info.create_time < Elem2#r_recruitment_info.create_time end, MatchList),
    {MatchNum, SortMatchList}.

do_cancel({RoleID, TeamID, TeamRoleIdList, IsLeaderCancel}) ->
	case get_role_type_info(RoleID) of
		undefined ->
			ignore;
		FactionAndType ->
			do_cancel2({RoleID, TeamID, TeamRoleIdList, IsLeaderCancel, FactionAndType})
	end.

do_cancel2({RoleID, TeamID, TeamRoleIdList, IsLeaderCancel, FactionAndType}) ->
    {_FactionId, Type} = FactionAndType,
    %% 获取之前匹配的所有招募队员信息
    RoleIDs = get_team_members(RoleID, TeamID, TeamRoleIdList),
    {not_match_all, MathcRoleList} = match_recruitment(FactionAndType, RoleIDs, TeamID),
    MatchRoleIDList = lists:flatten(lists:map(fun(RoleInfo) -> RoleInfo#r_recruitment_info.role_ids end, MathcRoleList)),
    
    if TeamID =:= 0 orelse IsLeaderCancel ->
           delete_recruitment_info_in_queue(FactionAndType, RoleID, TeamID);
       true ->
           update_team_recruitment_info_in_queue(FactionAndType, RoleID, TeamID)
    end,
	
    if TeamID =:= 0 orelse IsLeaderCancel ->
           %% 通知自己或队伍取消成功
           lists:foreach(
             fun(SendRoleID) ->
                     erase_role_type_info(SendRoleID),
                     case common_misc:is_role_online(SendRoleID) of
                          true ->
                              common_misc:send_to_rolemap(SendRoleID, {mod_map_team, {cancel_recruitmemt, {SendRoleID, Type}}});
                          false ->
                              update_offline_role_recruitment_state(SendRoleID, 0)
                     end
             end, RoleIDs),
           %% 通知其他成员更新
           NotifyToUpdateRoleIds = lists:filter(fun(Elem) -> not lists:member(Elem, RoleIDs) end, MatchRoleIDList),
           lists:foreach(
             fun(SendRoleID) ->
                     case common_misc:is_role_online(SendRoleID) of
                          true ->
                              common_misc:send_to_rolemap(SendRoleID, {mod_map_team, {update_recruitmemt_info, {update, SendRoleID, Type, NotifyToUpdateRoleIds}}});
                          false ->
                              ignore
                     end
             end, NotifyToUpdateRoleIds);
       true ->
           %% 通知队伍中的自己取消成功
           erase_role_type_info(RoleID),
           case common_misc:is_role_online(RoleID) of
               true ->
                   common_misc:send_to_rolemap(RoleID, {mod_map_team, {cancel_recruitmemt, {RoleID, Type}}});
               false ->
                   update_offline_role_recruitment_state(RoleID, 0)
           end,
           
           %% 通知其他成员更新
           NotifyToUpdateRoleIds = lists:delete(RoleID, MatchRoleIDList),
           lists:foreach(
             fun(SendRoleID) ->
                     case common_misc:is_role_online(SendRoleID) of
                          true ->
                              common_misc:send_to_rolemap(SendRoleID, {mod_map_team, {update_recruitmemt_info, {update, SendRoleID, Type, NotifyToUpdateRoleIds}}});
                          false ->
                              ignore
                     end
             end, NotifyToUpdateRoleIds)
    end.

do_offline({RoleID, TeamID, TeamRoleIdList, false}) ->
    do_cancel({RoleID, TeamID, TeamRoleIdList, false}).

do_info_query({RoleID, TeamID, TeamRoleIdList}) ->
    case get_role_type_info(RoleID) of
        undefined ->
            ignore;
        FactionAndType ->
            do_info_query2(RoleID, TeamID, TeamRoleIdList, FactionAndType)
    end.

do_info_query2(RoleID, TeamID, TeamRoleIdList, FactionAndType) ->
    {_FactionId, Type} = FactionAndType,
    %% 获取之前匹配的所有招募队员信息
    RoleIDs = get_team_members(RoleID, TeamID, TeamRoleIdList),
    {not_match_all, MathcRoleList} = match_recruitment(FactionAndType, RoleIDs, TeamID),
    MatchRoleIDList = lists:flatten(lists:map(fun(RoleInfo) -> RoleInfo#r_recruitment_info.role_ids end, MathcRoleList)),
    common_misc:send_to_rolemap(RoleID, {mod_map_team, {update_recruitmemt_info, {update, RoleID, Type, MatchRoleIDList}}}).

delete_recruitment_info_in_queue(FactionAndType, RoleID, TeamID) ->
    RecruitmentQueue = get_queue_by_type(FactionAndType),
    NewQueue = if TeamID =:= 0 ->
                      lists:keydelete([RoleID], #r_recruitment_info.role_ids, RecruitmentQueue#r_recruitment_queue.queue);
                  true ->
                      lists:keydelete(TeamID, #r_recruitment_info.team_id, RecruitmentQueue#r_recruitment_queue.queue)
               end,
    set_queue_by_type(FactionAndType, RecruitmentQueue#r_recruitment_queue{queue=NewQueue}).
     
update_team_recruitment_info_in_queue(FactionAndType, RoleID, TeamID) ->
    RecruitmentQueue = get_queue_by_type(FactionAndType),
    MapQueue = lists:map(
      fun(RecruitmentInfo) ->
              #r_recruitment_info{team_id=QTeamID,role_ids=QRoleIDs} = RecruitmentInfo,
              case TeamID =:= QTeamID andalso lists:member(RoleID, QRoleIDs) of
                  true ->
                      RecruitmentInfo#r_recruitment_info{role_ids=lists:delete(RoleID, QRoleIDs)};
                  false ->
                      RecruitmentInfo
              end
      end,RecruitmentQueue#r_recruitment_queue.queue),
    %% 过滤 role_ids 为空的recruitment_info
    NewQueue = lists:filter(fun(RecruitmentInfo) -> erlang:length(RecruitmentInfo#r_recruitment_info.role_ids) =/= 0 end, MapQueue),
    set_queue_by_type(FactionAndType, RecruitmentQueue#r_recruitment_queue{queue=NewQueue}).

notify_roles_to_join_or_build_team(RoleList) ->
    {TeamRecuitInfos, RoleRecuitInfos} = lists:foldl(
      fun(RecruitmentInfo, {TeamInfos, RoleInfos}) ->
              if RecruitmentInfo#r_recruitment_info.team_id =/= 0 ->
                     {[RecruitmentInfo | TeamInfos], RoleInfos};
                 true ->
                     {TeamInfos, [RecruitmentInfo | RoleInfos]}
              end
      end, {[],[]}, RoleList),
    if erlang:length(TeamRecuitInfos) > 1 ->
           error;
       erlang:length(TeamRecuitInfos) =:= 1 ->
           [#r_recruitment_info{team_id=TeamId}] = TeamRecuitInfos,
           lists:foreach(fun(RoleInfos) -> 
                            [RoleId] = RoleInfos#r_recruitment_info.role_ids,
                            common_misc:send_to_rolemap(RoleId, {mod_map_team, {recruitment_join, {RoleId, TeamId}}})     
                         end, RoleRecuitInfos);
       erlang:length(TeamRecuitInfos) =:= 0 andalso erlang:length(RoleRecuitInfos) > 0->
           [LeaderRoleInfo | T] = lists:reverse(RoleRecuitInfos),
           [LeaderRoleId] = LeaderRoleInfo#r_recruitment_info.role_ids,
           MemberRoleIdList = lists:map(fun(RoleInfo) -> [RoleId] = RoleInfo#r_recruitment_info.role_ids, RoleId end, T),
           case MemberRoleIdList of 
               undefined ->
                   [];
               _ ->
                   MemberRoleIdList
           end,
           common_misc:send_to_rolemap(LeaderRoleId, {mod_map_team, {recruitment_create, {LeaderRoleId, MemberRoleIdList}}})
    end,
    ok.

get_recruitment_type(TypeId) ->
   case common_config_dyn:find(team_recruitment, {recruitment_type, TypeId}) of
        [] ->
            error;     
        [RecruitmentConfig] ->
            RecruitmentConfig
    end.

do_admin_queues({Msg}) ->
    case Msg of
        get_all ->
            ?DBG("team_recruitment all queue info ~w", [get_queues()]);
        clear_all ->
            init_queues(),
            ?DBG("team_recruitment all queue info ~w", [get_queues()]);
        _ ->
            ignore
    end,
    ok.

%%=============test helper function====================
test_get_queues() ->
    global:send(mgeew_team_recruitment_server, {admin_queues,{get_all}}).

test_clean_queues() ->
    global:send(mgeew_team_recruitment_server, {admin_queues,{clear_all}}).
