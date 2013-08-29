%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     竞技场的管理Server
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mod_arena_manager).

-behaviour(gen_server).

-include("arena.hrl").

%% --------------------------------------------------------------------
-export([clear/0,
         start/0,
         start_link/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% Macro
%% ====================================================================
-define(CHECK_REQ_INTERVAL,5*1000).
-define(DUMP_DATA_INTERVAL,60*1000).    %%将日志数据持久化到mysql的间隔
-define(CHECK_ARENA_REQ,check_arena_req).
-define(MSG_DUMP_DATA,msg_dump_data).

-define(ARENA_REQ(Id),{arena_req,Id}).
-define(ARENA_REQ_LIST,arena_req_list).


-define(ARENA_ALL_LOGS,{arena_all_logs}).
-define(ARENA_ALL_LOGS_LENGTH,10).

-define(ARENA_SITE_LIST,arena_site_list).
-define(JINGJIE_RANKING_LIST,jingjie_ranking_list).
-define(JINGJIE_ONLINE_LIST,jingjie_online_list).
-define(CHALLENGE_MONEY_INFO,challenge_money_info).
-define(TO_CHALLENGER_INFO,to_challenger_info).


%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    supervisor:start_child(mgeem_sup, 
                           {?MODULE,
                            {?MODULE, start_link, []},
                            permanent, 30000, worker, [?MODULE]}).


start_link() ->
    gen_server:start_link(?MODULE, [], []).

%% mt_init()->
%% 	global:send(mod_arena_manager, {init_arena_info}).

 

%% --------------------------------------------------------------------
init([]) ->
    case global:whereis_name(?MODULE) of
        undefined ->
            global:register_name(?MODULE, self()),
            do_init_arena_info(),
            
            erlang:send_after(?CHECK_REQ_INTERVAL, self(), ?CHECK_ARENA_REQ),
            erlang:send_after(?DUMP_DATA_INTERVAL, self(), ?MSG_DUMP_DATA),
            
            init_arena_logs(),
            {ok, #state{}};
        %%该进程已经启动了，这个进程在分布式的环境中只能有一个
        _ ->
            {stop, alread_start}
    end.

%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
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

clear()->
    SendInfo = {clear_arena_data},
    global:send( mod_arena_manager , SendInfo),
    ok.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%@doc 初始化空擂台的信息
do_init_arena_info()->
    [List] = common_config_dyn:find(arena,arena_site),
    SiteList = lists:foldr(
                 fun(E,Acc)->
                         {MinArenaId,MaxArenaId,Type,_MapId} = E,
                         lists:foldr(
                           fun(Id,AccIn2)->
                                   [#p_arena_info{id=Id,type=Type,status=0}|AccIn2]
                           end, Acc, lists:seq(MinArenaId, MaxArenaId))
                 end, [], List),
    put(?ARENA_SITE_LIST,SiteList),
    ok.

set_jingjie_ranking(RankList)->
    put(?JINGJIE_RANKING_LIST,RankList),
    ok.

set_hero_online_list(RankList)->
    RoleOnlineList = 
        lists:foldl(
          fun(E,AccIn)-> 
                  #p_jingjie_rank{role_id=RoleID} = E,
                  IsOnline = common_misc:is_role_online(RoleID),
                  [{RoleID,IsOnline}|AccIn]
          end, [], RankList),
    put(?JINGJIE_ONLINE_LIST,RoleOnlineList),
    ok.


get_jingjie_ranking()->
    get(?JINGJIE_RANKING_LIST).

init_arena_logs()->
    try
        Sql = mod_mysql:get_esql_select(t_log_arena_fight,record_info(fields,p_arena_log), ""),
        {ok,ResultList} = mod_mysql:select(Sql),
        case ResultList of
            []->ignore;
            _->
                Logs = [ list_to_tuple([p_arena_log|E]) ||E<-ResultList ],
                store_arena_logs(Logs)
        end
    catch
        _:Reason->
            ?ERROR_MSG("init_arena_logs error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

store_arena_logs([])->
    ignore;
store_arena_logs(Logs)->
    Logs2 = lists:sort(
              fun(E1,E2)->
                      #p_arena_log{end_time=End1} = E1,
                      #p_arena_log{end_time=End2} = E2,
                      End1>End2
              end,Logs),
    put(?ARENA_ALL_LOGS,Logs2).

%% 竞技场接口
do_handle_info({_,?ARENA, ?ARENA_LIST, _,_,_,_}=Info) ->
    do_arena_list_req(Info);
do_handle_info({_,?ARENA, ?ARENA_ANNOUNCE, _,_,_,_}=Info) ->
    do_arena_announce_req(Info);
do_handle_info({_,?ARENA, ?ARENA_CHALLENGE, _,_,_,_}=Info) ->
    do_arena_challenge_req(Info);
do_handle_info({_,?ARENA, ?ARENA_CHLLG_ANSWER, _,_,_,_}=Info) ->
    do_arena_chllg_answer_req(Info);
do_handle_info({_,?ARENA, ?ARENA_WATCH, _,_,_,_}=Info) ->
    do_arena_watch_req(Info);
do_handle_info({_,?ARENA, ?ARENA_SHOWLOG, _,_,_,_}=Info) ->
    do_arena_showlog_req(Info);

do_handle_info({change_arena_status,ArenaInfo})->
    #p_arena_info{id=Id,status=Status}=ArenaInfo,
    do_change_arena_status(Id,Status,ArenaInfo);
do_handle_info({announce_response,ArenaId})->
    do_arena_response(ArenaId);
do_handle_info({challenge_response,ArenaId})->
    do_arena_response(ArenaId);
do_handle_info({answer_response,ArenaId})->
    do_arena_response(ArenaId);
do_handle_info({clear_arena_data})->
    do_init_arena_info();
do_handle_info({sync_jingjie_ranking,RankList})->
    set_hero_online_list(RankList),
    set_jingjie_ranking(RankList);
do_handle_info({update_hero_online,RoleID,IsOnline})->
    do_update_hero_online(RoleID,IsOnline);
do_handle_info({to_chllger_offline,RoleID})->
    do_to_chllger_offline(RoleID);
do_handle_info({update_hero_score,ScoreList})->
    lists:foreach(
      fun(E)->
              {RoleID,Score} = E,
              do_update_hero_score(RoleID,Score)
      end, ScoreList);

  
do_handle_info(?CHECK_ARENA_REQ)->
    ?TRY_CATCH( do_check_arena_req() ),
    erlang:send_after(?CHECK_REQ_INTERVAL, self(), ?CHECK_ARENA_REQ);
do_handle_info(?MSG_DUMP_DATA)->
    ?TRY_CATCH( do_dump_data() ),
    erlang:send_after(?DUMP_DATA_INTERVAL, self(), ?MSG_DUMP_DATA);
do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.


%%检查竞技场的请求是否超期
do_check_arena_req()->
    case get(?ARENA_REQ_LIST) of
        undefined->
            ignore;
        []->
            ignore;
        List ->
            Now = common_tool:now(),
            lists:foreach(
              fun(E)->
                      do_check_arena_req_1(E,Now)                    
              end, List)
    end,
    %%处理外服目前存在的部分情况下没有擂主，而且状态还是Finish的情况：
    lists:foreach(
      fun(E)-> fix_arena_list(E) end, 
      get(?ARENA_SITE_LIST)),
    ok.


get_arena_logs()->
    case get(?ARENA_ALL_LOGS) of
        undefined->
            [];
        List->
            List
    end.

%%将日志数据持久化到mysql
do_dump_data()->
    case get_arena_logs() of
        []->
            ignore;
        Logs->
            Tab = t_log_arena_fight,
            SQL = mod_mysql:get_esql_delete(Tab, [] ),
            {ok,_} = mod_mysql:delete(SQL),

            FieldNames = record_info(fields,p_arena_log),
            BatchValues = logs_to_fields_value(Logs),
            mod_mysql:batch_insert(Tab,FieldNames,BatchValues,1000)
    end.

logs_to_fields_value(Logs) when is_list(Logs)->
    lists:map(
      fun(E)->
              [_H|T] = tuple_to_list(E),
              T
      end, Logs).

fix_arena_list(E)->
    #p_arena_info{id=Id,owner_id=OwnerId,status=Status}=E,
    case Status == ?STATUS_FINISH andalso (OwnerId=:=undefined)  of
        true->
            ?ERROR_MSG("try to fix_arena_list,E=~w",[E]),
            Type = mod_arena_misc:get_arena_type(Id),
            R=#p_arena_info{id=Id,type=Type,status=0},
            del_arena_request(Id),
            set_arena_site_info(Id,R);
        _ ->
            ignore
    end.
do_check_arena_req_1(Id,Now)->
    case get(?ARENA_REQ(Id)) of
        {_,_,EndTime} when Now>=EndTime->
            del_arena_request(Id);
        _ ->
            ignore
    end.

get_arena_site_list(Type)->
    SiteList = get(?ARENA_SITE_LIST),
    lists:filter(fun(#p_arena_info{type=TheType})-> TheType=:=Type end, SiteList).

get_arena_site_info(Id)->
    SiteList = get(?ARENA_SITE_LIST),
    lists:keyfind(Id, #p_arena_info.id, SiteList).

set_arena_site_info(Id,ArenaInfo)->
    SiteList = get(?ARENA_SITE_LIST),
    List2 = lists:keystore(Id,#p_arena_info.id,SiteList,ArenaInfo),
    put(?ARENA_SITE_LIST,List2).

%%@doc 在竞技场管理Server中 更新竞技场的状态
do_change_arena_status(Id,Status,ChangeArenaInfo) when is_record(ChangeArenaInfo,p_arena_info)->
    case get_arena_site_info(Id) of
        #p_arena_info{type=Type}=CurrInfo->
            Now = common_tool:now(),
            case Status of
                ?STATUS_BLANK->
                    set_arena_site_info(Id,ChangeArenaInfo#p_arena_info{type=Type,change_time=Now});
                ?STATUS_ANNOUNCE->
                    del_arena_request(Id),
                    set_arena_site_info(Id,ChangeArenaInfo#p_arena_info{type=Type,change_time=Now});
                ?STATUS_PREPARE->
                    del_arena_request(Id),
                    #p_arena_info{challenger_id=RoleID,challenger_head=Head,challenger_faction=FactionId,challenger_team=TeamId,
                                  challenger_name=RoleName} = ChangeArenaInfo,
                    Info2 = CurrInfo#p_arena_info{status=Status,challenger_id=RoleID,challenger_head=Head,
                                                  challenger_faction=FactionId,challenger_team=TeamId,
                                                  challenger_name=RoleName,change_time=Now},
                    set_arena_site_info(Id,Info2);
                ?STATUS_FIGHT->
                    del_arena_request(Id),
                    Info2 = CurrInfo#p_arena_info{status=Status,change_time=Now},
                    set_arena_site_info(Id,Info2);
                ?STATUS_FINISH->
                    #p_arena_info{result=Result} = ChangeArenaInfo,
                    update_fight_logs(CurrInfo,Now,Result),
                    Info2 = CurrInfo#p_arena_info{status=Status,result=Result,change_time=Now},
                    set_arena_site_info(Id,Info2)
            end;
        _->
            ?ERROR_MSG("do_change_arena_status,ArenaId=~w is not found!",[Id]),
            error
    end.


%%@doc 处理擂台的结果返回
do_arena_response(ArenaId)->
    %%     case get(?ARENA_REQ(ArenaId)) of
    %%         {?STATUS_PREPARE,_,_}->
    %%             ok;
    %%         Val ->
    %%             ?ERROR_MSG("do_challenge_response error!{ArenaId,IsSucc,Val}=~w",[{ArenaId,IsSucc,Val}])
    %%     end,
    del_arena_request(ArenaId).


%%@interface 显示擂台列表
do_arena_list_req({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_list_tos{list_type=ListType} = DataIn,
    Score = mod_arena_misc:get_arena_total_score(RoleID),
    
    case ListType of
        ?TYPE_ONE2ONE->
            SiteList = get_arena_site_list(ListType),
            TakeTimes = mod_arena_misc:get_arena_partake_times_today(RoleID),
            ?UNICAST_TOC( #m_arena_list_toc{list_type=ListType,arena_list=SiteList,total_score=Score,
                                            partake_times=[TakeTimes]});
        ?TYPE_HERO2HERO->
            ChllgTimes = mod_arena_misc:get_arena_chllg_times_today(RoleID),
            BeChllgedTimes = mod_arena_misc:get_arena_be_chllged_times_today(RoleID),
            ?UNICAST_TOC( #m_arena_list_toc{list_type=ListType,hero_list=[],total_score=Score,
                                            partake_times=[ChllgTimes,BeChllgedTimes]})
    end.

%%@doc 更新竞技场的请求状态，当玩家地图逻辑处理完之后，需要发数据过来清除掉该状态
set_arena_request(ArenaId,Status) when is_integer(Status)->
    StartTime = common_tool:now(),
    EndTime = StartTime+5,
    put( ?ARENA_REQ(ArenaId), {Status,StartTime,EndTime}),
    common_misc:update_dict_set(?ARENA_REQ_LIST,ArenaId).

del_arena_request(ArenaId)->
    case get_arena_request(ArenaId) of
        undefined->
            ignore;
        _ ->
            erase( ?ARENA_REQ(ArenaId) ),
            case get(?ARENA_REQ_LIST) of
                undefined->
                    ignore;
                []->
                    ignore;
                List->
                    put(?ARENA_REQ_LIST, lists:delete(ArenaId, List))
            end
    end.

get_arena_request(ArenaId)->
    get( ?ARENA_REQ(ArenaId) ).

router_to_role_map(RoleID,Info)->
    common_misc:send_to_rolemap_mod(RoleID,mod_arena,Info).

%% 判断竞技场ID是否合法
assert_arena_id_valid(Id)->
    [SiteList] =common_config_dyn:find(arena,arena_site),
    assert_arena_id_valid_2(SiteList,Id).

assert_arena_id_valid_2([],_Id)->
    ?THROW_ERR(?ERR_ARENA_ID_INVALID );
assert_arena_id_valid_2([H|T],ArenaId)->
    {MinArenaId,MaxArenaId,_Type,_MapId} = H,
    case ArenaId>=MinArenaId andalso MaxArenaId>=ArenaId of
        true->
            ok;
        _ ->
            assert_arena_id_valid_2(T,ArenaId)
    end.


%%@interface 摆擂/挑擂
do_arena_announce_req({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_announce_tos{id=Id,action=Action} = DataIn,
    case catch check_announce_condition(RoleID,DataIn) of
        ok->
            case Action of
                ?ANNOUNCE_TYPE_OWN->
                    set_arena_request(Id,?STATUS_ANNOUNCE);
                ?ANNOUNCE_TYPE_CHLLG->
                    set_arena_request(Id,?STATUS_PREPARE)
            end,
            Info = {Unique, Module, Method, DataIn, RoleID, PID, _Line},
            router_to_role_map(RoleID,Info);
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_announce_toc{id=Id,error_code=ErrCode,reason=Reason})
    end.

get_avariable_site_id(Type)->
    get_avariable_site_id_2( get_arena_site_list(Type) ).
get_avariable_site_id_2([])->
    ?THROW_ERR(?ERR_ARENA_NO_AVARIABLE_ID );
get_avariable_site_id_2([H|T])->
    case H of
        #p_arena_info{id=Id,status=?STATUS_BLANK}->
            Id;
        _ ->
            get_avariable_site_id_2(T)
    end.

check_announce_condition(RoleID,DataIn)->
    #m_arena_announce_tos{id=Id,action=Action} = DataIn,
    case Action of
        ?ANNOUNCE_TYPE_OWN->
            check_announce_own_condition(RoleID,Id);
        ?ANNOUNCE_TYPE_CHLLG->
            check_announce_chllg_condition(RoleID,Id)
    end.

check_announce_own_condition(RoleID,Id)->
    assert_role_takeparting(RoleID),
    case get_arena_request(Id) of
        undefined->
            next;
        _ ->
            ?THROW_ERR(?ERR_ARENA_ANNOUNCE_STATUS_USED )
    end,
    case get_arena_site_info(Id) of
        #p_arena_info{status=?STATUS_BLANK}->
            next;
        _ ->
            ?THROW_ERR(?ERR_ARENA_ANNOUNCE_STATUS_USED )
    end,
    ok.
check_announce_chllg_condition(RoleID,Id)->
    case get_arena_site_info(Id) of
        #p_arena_info{status=?STATUS_BLANK}->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_STATUS_BLANK );
        #p_arena_info{status=?STATUS_PREPARE}->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_STATUS_PREPARE );
        #p_arena_info{status=?STATUS_FIGHT}->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_STATUS_FIGHT );
        #p_arena_info{status=?STATUS_FINISH}->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_STATUS_FINISH );
        #p_arena_info{owner_id=OwnerId} when (RoleID=:=OwnerId)->
            ?THROW_ERR_REASON(?_LANG_ARENA_NOT_CHALLENGE_SELF );
        _ ->
            next
    end,
    assert_role_takeparting(RoleID),
    case get_arena_request(Id) of
        undefined->
            next;
        _ ->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_STATUS_PREPARE )
    end,
    ok.

set_challenge_money_info(ChllgId,ToChllgId,MoneyType,ChllgMoney)->
    Key = {ChllgId,ToChllgId},
    MoneyInfo = {Key,MoneyType,ChllgMoney},
    case get(?CHALLENGE_MONEY_INFO) of
        undefined->
            put(?CHALLENGE_MONEY_INFO,[MoneyInfo]);
        List->
            put(?CHALLENGE_MONEY_INFO,lists:keystore(Key, 1, List, MoneyInfo))
    end,
    case get(?TO_CHALLENGER_INFO) of
        undefined->
            put(?TO_CHALLENGER_INFO,[{ToChllgId,ChllgId}]);
        List2->
            put(?TO_CHALLENGER_INFO,lists:keystore(ToChllgId, 1, List2, {ToChllgId,ChllgId}))
    end,
    ok.

del_challenge_money_info(ChllgId,ToChllgId)->
    Key = {ChllgId,ToChllgId},
    case get(?CHALLENGE_MONEY_INFO) of
        undefined->
            ignore;
        List->
            put(?CHALLENGE_MONEY_INFO,lists:keydelete(Key, 1, List))
    end,
    case get(?TO_CHALLENGER_INFO) of
        undefined->
            ignore;
        List2->
            put(?TO_CHALLENGER_INFO,lists:keydelete(ToChllgId, 1, List2))
    end,
    ok.

get_challenge_money_info(ChllgId,ToChllgId)->
    Key = {ChllgId,ToChllgId},
    case get(?CHALLENGE_MONEY_INFO) of
        undefined->
            false;
        List->
            lists:keyfind(Key, 1, List)
    end.

get_to_challenger_info(ToChllgId)->
    case get(?TO_CHALLENGER_INFO) of
        undefined->
            false;
        List2->
            lists:keyfind(ToChllgId, 1, List2)
    end.

%%@interface 挑战擂台
do_arena_challenge_req({Unique, Module, Method, DataIn, RoleID, PID, _Line}=Info)->
    #m_arena_challenge_tos{role_id=ToChllgId,money_type=MoneyType,chllg_money=ChllgMoney} = DataIn,
    case catch check_challenge_condition(RoleID,ToChllgId) of
        ok->
            set_challenge_money_info(RoleID,ToChllgId,MoneyType,ChllgMoney),
            router_to_role_map(RoleID,Info);
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_challenge_toc{role_id=ToChllgId,error_code=ErrCode,reason=Reason})
    end.

check_challenge_condition(RoleID,ToChllgId)->
    case get_jingjie_ranking() of
        undefined->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_NO_HERO_LIST );
        RankList->
            case lists:keyfind(RoleID, #p_jingjie_rank.role_id, RankList) of
                #p_jingjie_rank{ranking=RoleRank} when RoleRank>0->
                    case lists:keyfind(ToChllgId, #p_jingjie_rank.role_id, RankList) of
                        #p_jingjie_rank{ranking=ToChllgRank} when ToChllgRank>0->
                            case RoleRank>=ToChllgRank andalso (ToChllgRank+20)>=RoleRank of
                                true->
                                    ok;
                                _ ->
                                    ?THROW_ERR(?ERR_ARENA_CHALLENGE_RANK_NUM_NOT_CORRECT )
                            end;
                        _ ->
                            ?THROW_ERR(?ERR_ARENA_CHALLENGE_HIM_NOT_IN_RANK )
                    end;
                _ ->
                    ?THROW_ERR(?ERR_ARENA_CHALLENGE_ROLE_NOT_IN_RANK )
            end
    end,
    ok.

%%@interface 对邀请的应答
do_arena_chllg_answer_req({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_chllg_answer_tos{chllg_id=ChllgId,action=Action} = DataIn,
    case catch check_chllg_answer_condition(RoleID,DataIn) of
        {ok,MoneyType,ChllgMoney}->
            ArenaId = get_avariable_site_id(?TYPE_HERO2HERO),
            ChallengeAnswerInfo = {ArenaId,MoneyType,ChllgMoney},
            SendInfo = {Unique, Module, Method, DataIn, RoleID, PID, ChallengeAnswerInfo},
            if
                Action=:=?ANSWER_ACTION_AGREE ->
                    %%set_arena_request(ChllgId,?STATUS_PREPARE);
                    ok;
                true->
                    ignore
            end,
            del_challenge_money_info(ChllgId,RoleID),
            router_to_role_map(RoleID,SendInfo);
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_chllg_answer_toc{chllg_id=ChllgId,error_code=ErrCode,reason=Reason})
    end.

check_chllg_answer_condition(RoleID,DataIn)->
    #m_arena_chllg_answer_tos{chllg_id=ChllgId,action=Action} = DataIn,
    case get_challenge_money_info(ChllgId,RoleID) of
        false->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_STATUS_BLANK ),
            error;
        {_,MoenyType,ChllgMeney}->
            if
                Action=:=?ANSWER_ACTION_AGREE ->
                    assert_role_takeparting(RoleID);
                true->
                    next
            end,
            {ok,MoenyType,ChllgMeney}
    end.

%%@doc 判断是否重复参与
assert_role_takeparting(RoleID)->
    assert_role_takeparting(RoleID,?ERR_ARENA_ROLE_TAKEPARTING).

assert_role_takeparting(RoleID,Err)->
    SiteList = get(?ARENA_SITE_LIST),
    assert_role_takeparting_2(RoleID,SiteList,Err).

assert_role_takeparting_2(_RoleID,[],_Err)->
    ok;
assert_role_takeparting_2(RoleID,[H|T],Err)->
    #p_arena_info{status=Status,owner_id=OId,challenger_id=CId} = H,
    if
        Status =:= ?STATUS_BLANK->
            assert_role_takeparting_2(RoleID,T,Err);
        OId=:=RoleID orelse CId=:=RoleID ->
            ?THROW_ERR(Err);
        true->
            assert_role_takeparting_2(RoleID,T,Err)
    end.

%%@interface 观战
do_arena_watch_req({Unique, Module, Method, DataIn, RoleID, PID, _Line}=Info)->
    #m_arena_watch_tos{id=Id} = DataIn,
    case catch check_watch_condition(Id) of
        ok->
            router_to_role_map(RoleID,Info);
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_watch_toc{id=Id,error_code=ErrCode,reason=Reason})
    end.

%%@interface 查看最新战况
do_arena_showlog_req({Unique, Module, Method, DataIn, _RoleID, PID, _Line})->
    #m_arena_showlog_tos{type=Type} = DataIn,
    case catch check_showlog_condition(Type) of
        ok->
            Logs = get_arena_logs(),
            R2 = #m_arena_showlog_toc{logs=Logs},
            ?UNICAST_TOC(R2);
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_showlog_toc{error_code=ErrCode,reason=Reason})
    end.

check_showlog_condition(_Type)->
    ok.



check_watch_condition(Id)->
    assert_arena_id_valid(Id),
    case get_arena_site_info(Id) of
        #p_arena_info{status=?STATUS_BLANK}->
            ?THROW_ERR(?ERR_ARENA_WATCH_STATUS_BLANK);
        #p_arena_info{status=?STATUS_FINISH}->
            ?THROW_ERR(?ERR_ARENA_WATCH_STATUS_FINISH );
        _ ->
            next
    end,
    ok.


%%更新最新战况
update_fight_logs(CurrInfo,Now,Result) when
      (Result=:=?RESULT_WIN_OWNER orelse Result=:=?RESULT_WIN_CHALLENGER orelse Result=:=?RESULT_DRAW 
       orelse Result=:=?RESULT_QUIT_FIGHT_OWNER orelse Result=:=?RESULT_QUIT_FIGHT_CHALLENGER )->
    #p_arena_info{type=Type,change_time=PrepareTime,owner_faction=OwnerFaction,owner_name=OwnerName,
                  challenger_faction=ChllgFaction,challenger_name=ChllgName} = CurrInfo,
    LastFightTime = Now-PrepareTime,
    if
        Result=:=?RESULT_DRAW->
            LogFightResult = ?LOG_FIGHT_RESULT_DRAW,
            WinFaction = OwnerFaction,
            WinName = OwnerName,
            LoserFaction = ChllgFaction,
            LoserName = ChllgName;
        Result=:=?RESULT_WIN_OWNER orelse Result=:=?RESULT_QUIT_FIGHT_CHALLENGER ->
            LogFightResult = ?LOG_FIGHT_RESULT_WIN,
            WinFaction = OwnerFaction,
            WinName = OwnerName,
            LoserFaction = ChllgFaction,
            LoserName = ChllgName;
        true->
            LogFightResult = ?LOG_FIGHT_RESULT_WIN,
            WinFaction = ChllgFaction,
            WinName = ChllgName,
            LoserFaction = OwnerFaction,
            LoserName = OwnerName
    end,
    Log = #p_arena_log{type=Type,result=LogFightResult,end_time=Now,last_time=LastFightTime,
                       winner_faction=WinFaction,winner_name=WinName,loser_faction=LoserFaction,loser_name=LoserName},
    case get(?ARENA_ALL_LOGS) of
        undefined->
            put(?ARENA_ALL_LOGS,[Log]);
        []->
            put(?ARENA_ALL_LOGS,[Log]);
        List ->
            List1 = [Log|List],
            if
                length(List1)>10->
                    put(?ARENA_ALL_LOGS,lists:sublist(List1, ?ARENA_ALL_LOGS_LENGTH));
                true->
                    put(?ARENA_ALL_LOGS,List1)
            end
    end;
update_fight_logs(_,_,_)->
    ignore.


%%被挑战者突然下线了
do_to_chllger_offline(ToChllgId)->
    case get_to_challenger_info(ToChllgId) of
        {ToChllgId,ChllgId}->
            RoleID = ToChllgId,
            Action = ?ANSWER_ACTION_GIVEUP,
            DataIn = #m_arena_chllg_answer_tos{chllg_id=ChllgId,action=Action},
            case catch check_chllg_answer_condition(RoleID,DataIn) of
                {ok,MoneyType,ChllgMoney}->
                    del_challenge_money_info(ChllgId,RoleID),
                    %% 选择放弃，B被挑战方被系统扣除2%的积分
                    deduct_challenger_score(ToChllgId,MoneyType,ChllgMoney),
                    
                    %%挑战者要返回挑战资金
                    ChallengeInfo = #r_arena_challenge_info{arena_id=0,owner_id=RoleID,chllg_id=ChllgId,money_type=MoneyType,
                                            chllg_money=ChllgMoney,chllg_score=0},
                    SendMsg = {inner_arena_chllg_answer,Action,ChallengeInfo},
                    common_misc:send_to_rolemap_mod(ChllgId, mod_arena, SendMsg),
                    ok;
                {error,ErrCode,Reason}->
                    ?ERROR_MSG("ErrCode=~w,Reason=~w",[ErrCode,Reason]),
                    ignore
            end;
        _ ->
            ignore
    end.

%% 选择放弃，B被挑战方被系统扣除2%的积分
deduct_challenger_score(ToChllgId,MoneyType,ChllgMoney) when is_integer(ToChllgId)->
    RoleID = ToChllgId,
    ChllgScore = mod_arena:get_role_chllg_score(RoleID,MoneyType,ChllgMoney),
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{total_score=OldScore}=OldArenaRec] when OldScore>1 ->
            DeductScore = if 
                              ChllgScore>50-> ChllgScore div 50;
                              true-> 1
                          end,
            NewScore = (OldScore-DeductScore),
            db:dirty_write(?DB_ROLE_ARENA,OldArenaRec#r_role_arena{total_score=NewScore}),
            mod_arena_misc:update_hero_score_to_manager([{RoleID,NewScore}]),
            ok;
        _->     
            ignore
    end.
 
do_update_hero_online(RoleID,IsOnline)->
    case get(?JINGJIE_ONLINE_LIST) of
        undefined->
            ignore;
        RoleOnlineList->
            case lists:keyfind(RoleID, 1, RoleOnlineList) of
                false-> ignore;
                _ -> 
                    List2 = lists:keystore(RoleID, 1, RoleOnlineList, {RoleID,IsOnline}),
                    put(?JINGJIE_ONLINE_LIST,List2)
            end
    end.

do_update_hero_score(RoleID,Score)->
    case get_jingjie_ranking() of
        undefined->
            ignore;
        RankList->
            case lists:keyfind(RoleID, #p_jingjie_rank.role_id, RankList) of
                #p_jingjie_rank{}=Rank1->
                    Rank2 = Rank1#p_jingjie_rank{arena_score=Score},
                    List2 = lists:keystore(RoleID, #p_jingjie_rank.role_id, RankList, Rank2),
                    put(?JINGJIE_RANKING_LIST,List2);
                _ ->
                    ignore
            end
    end,
    ok.
