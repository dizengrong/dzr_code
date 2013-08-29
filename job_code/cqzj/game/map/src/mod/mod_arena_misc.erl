%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     竞技场的一些外部方法
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_arena_misc).

-include("arena.hrl").
-export([
		 get_min_arena_title/0,
         get_role_arena_record/1,
         add_arena_score/2,
         send_role_chllg_money_change/3,
         process_arena_h2h_result/2
        ]).

%%辅助方法
-export([
         update_hero_score_to_manager/1,
         send_role_arena_result/4,
         get_arena_type/1,
         get_arena_total_score/1,
         get_arena_partake_times_today/1,
         get_arena_chllg_times_today/1,
         get_arena_be_chllged_times_today/1
        ]).

-export([
         t_gain_challenge_money/3,
         t_deduct_addhp_money/2,
         t_deduct_announce_money/2,
         t_deduct_challenge_money/3
        ]).

-define(CHALLENGE_MONEY_TYPE_GOLD,1).
-define(CHALLENGE_MONEY_TYPE_SILVER,2).


%%@doc 竞技场的最小参与境界：武林新秀
get_min_arena_title()->
	110.


process_arena_h2h_result(CurrInfo,Result)   %%挑战者获胜
  when (Result=:=?RESULT_WIN_CHALLENGER) orelse (Result=:=?RESULT_QUIT_PREPARE_OWNER)
           orelse (Result=:=?RESULT_QUIT_FIGHT_OWNER)-> 
    %%A返还挑战金额；
    #p_arena_info{owner_id=OwnerId,challenger_id=ChllgId}=CurrInfo,
    TransFun = fun()->
                       case get(?ARENA_CHALLENGE_INFO) of
                           #r_arena_challenge_info{money_type=MoneyType,chllg_money=ChllgMoney,chllg_score=ChllgScore}->
                               next;
                           undefined->
                               MoneyType = ChllgMoney = ChllgScore = null,
                               ?ERROR_MSG("process_arena_h2h_result error",[]),
                               ?THROW_ERR(?ERR_ARENA_RESULT_GET_CHLLG_MONEY)
                       end,
                       ChllgResultA = #p_arena_chllg_result{money_type=MoneyType,chllg_money=ChllgMoney},
                       {ok,RoleAttr2} = t_gain_challenge_money(ChllgId,MoneyType,ChllgMoney),
                       {ok,RoleAttr2,MoneyType,ChllgScore,ChllgResultA}
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2,MoneyType,ChllgScore,ChllgResultA}}->
            %%A获得挑战积分，B扣除挑战积分。
            #r_role_arena{total_score=OldScoreA} = RecordChllg = get_role_arena_record(ChllgId),
            #r_role_arena{total_score=OldScoreB} = RecordOwner = get_role_arena_record(OwnerId),
            
            MyChllgScore = ChllgScore,
            MyOwnerScore = -ChllgScore,
            TotalChllgScore = OldScoreA+ChllgScore,
            if
                OldScoreB-ChllgScore>=0->   
                    TotalOwnerScore = OldScoreB-ChllgScore;
                true->
                    TotalOwnerScore = 0
            end,
            db:dirty_write(?DB_ROLE_ARENA,RecordChllg#r_role_arena{total_score=TotalChllgScore}),
            db:dirty_write(?DB_ROLE_ARENA,RecordOwner#r_role_arena{total_score=TotalOwnerScore}),
            
            send_role_chllg_money_change(MoneyType,ChllgId,RoleAttr2),
            send_role_arena_result(CurrInfo,Result,ChllgId,{MyChllgScore,MyOwnerScore,TotalChllgScore},ChllgResultA),
            send_role_arena_result(CurrInfo,Result,OwnerId,{MyOwnerScore,MyChllgScore,TotalOwnerScore},undefined),
            
            update_hero_score_to_manager( [{ChllgId,TotalChllgScore},{OwnerId,TotalOwnerScore}] );
        {aborted,{error,ErrCode,Reason}}->
            R2 = #m_arena_challenge_toc{role_id=ChllgId,error_code=ErrCode,reason=Reason},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2)
    end;
process_arena_h2h_result(CurrInfo,Result)   %%挑战者失败
  when (Result=:=?RESULT_WIN_OWNER) orelse (Result=:=?RESULT_QUIT_PREPARE_CHALLENGER)
           orelse (Result=:=?RESULT_QUIT_FIGHT_CHALLENGER)-> 
    %%B获得挑战金额；积分不变。
    #p_arena_info{owner_id=OwnerId,challenger_id=ChllgId}=CurrInfo,
    TransFun = fun()->
                       case get(?ARENA_CHALLENGE_INFO) of
                           #r_arena_challenge_info{money_type=MoneyType,chllg_money=ChllgMoney}->
                               next;
                           undefined->
                               MoneyType = ChllgMoney = null,
                               ?ERROR_MSG("process_arena_h2h_result error",[]),
                               ?THROW_ERR(?ERR_ARENA_RESULT_GET_CHLLG_MONEY)
                       end,
                       ChllgResultB = #p_arena_chllg_result{money_type=MoneyType,chllg_money=ChllgMoney},
                       {ok,RoleAttr2} = t_gain_challenge_money(OwnerId,MoneyType,ChllgMoney),
                       {ok,RoleAttr2,MoneyType,ChllgResultB}
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2,MoneyType,ChllgResultB}}->
            #r_role_arena{total_score=OldScoreA} = get_role_arena_record(ChllgId),
            #r_role_arena{total_score=OldScoreB} = get_role_arena_record(OwnerId),
            
            send_role_chllg_money_change(MoneyType,OwnerId,RoleAttr2),
            send_role_arena_result(CurrInfo,Result,ChllgId,{0,0,OldScoreA},undefined),
            send_role_arena_result(CurrInfo,Result,OwnerId,{0,0,OldScoreB},ChllgResultB),
            ok;
        {aborted,{error,ErrCode,Reason}}->
            ?ERROR_MSG("ErrCode=~w,Reason=~w",[ErrCode,Reason])
    end;
process_arena_h2h_result(CurrInfo,?RESULT_DRAW=Result)-> %%平局
    %%A获得80%的挑战金,B获得20%的挑战金；积分不变。
    #p_arena_info{challenger_id=ChllgId,owner_id=OwnerId}=CurrInfo,
    TransFun = fun()->
                       case get(?ARENA_CHALLENGE_INFO) of
                           #r_arena_challenge_info{money_type=MoneyType,chllg_money=ChllgMoney}->
                               next;
                           undefined->
                               MoneyType = ChllgMoney = null,
                               ?ERROR_MSG("process_arena_h2h_result error",[]),
                               ?THROW_ERR(?ERR_ARENA_RESULT_GET_CHLLG_MONEY)
                       end,
                       ChllgMoneyA = 8*ChllgMoney div 10,
                       ChllgMoneyB = 2*ChllgMoney div 10,
                       ChllgResultA = #p_arena_chllg_result{money_type=MoneyType,chllg_money=ChllgMoneyA},
                       ChllgResultB = #p_arena_chllg_result{money_type=MoneyType,chllg_money=ChllgMoneyB},
                       {ok,RoleAttr2A} = t_gain_challenge_money(ChllgId,MoneyType,ChllgMoneyA),
                       {ok,RoleAttr2B} = t_gain_challenge_money(OwnerId,MoneyType,ChllgMoneyB),
                       {ok,RoleAttr2A,RoleAttr2B,MoneyType,ChllgResultA,ChllgResultB}
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2A,RoleAttr2B,MoneyType,ChllgResultA,ChllgResultB}}->
            #r_role_arena{total_score=OldScoreA} = get_role_arena_record(ChllgId),
            #r_role_arena{total_score=OldScoreB} = get_role_arena_record(OwnerId),
            
            send_role_chllg_money_change(MoneyType,ChllgId,RoleAttr2A),
            send_role_chllg_money_change(MoneyType,OwnerId,RoleAttr2B),
            send_role_arena_result(CurrInfo,Result,ChllgId,{0,0,OldScoreA},ChllgResultA),
            send_role_arena_result(CurrInfo,Result,OwnerId,{0,0,OldScoreB},ChllgResultB),
            ok;
        {aborted,{error,ErrCode,Reason}}->
            R2 = #m_arena_challenge_toc{role_id=ChllgId,error_code=ErrCode,reason=Reason},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2)
    end;
process_arena_h2h_result(CurrInfo,Result)->
    ?ERROR_MSG("{CurrInfo,Result}=~w",[{CurrInfo,Result}]),
    ignore.


get_role_arena_record(RoleID)->
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{}=R1]->
            R1;
        _ ->
            {ok,#p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
            #r_role_arena{role_id=RoleID,faction_id=FactionId,total_score=?DEFAULT_ARENA_SCORE}
    end.



%%扣除补血补蓝的钱币
t_deduct_addhp_money(RoleID,DeductMoney)->
    case common_bag2:t_deduct_money(silver_any,DeductMoney,RoleID,?CONSUME_TYPE_SILVER_ARENA_ADD_HP) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,Reason}->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_SYS_ERR()
    end.

%%扣除个人摆擂的钱币
t_deduct_announce_money(RoleID,DeductMoney)->
    case common_bag2:t_deduct_money(silver_any,DeductMoney,RoleID,?CONSUME_TYPE_SILVER_ARENA_ANNOUNCE) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,Reason}-> %% 传递一个error code，客户端匹配不到，然后就显示Reason了
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_SYS_ERR()
    end. 

%%获赠百强挑战的金钱
t_gain_challenge_money(RoleID,MoneyType,ChllgMoney)->
    case MoneyType of
        ?CHALLENGE_MONEY_TYPE_GOLD->
            ConsumeLogType = ?GAIN_TYPE_GOLD_FROM_ARENA_HERO_CHALLENGE,
            DeductMoney = ChllgMoney,
            case common_bag2:t_gain_money(gold_unbind,DeductMoney,RoleID,ConsumeLogType) of
                {ok,RoleAttr2}->
                    {ok,RoleAttr2};
                {error,gold_unbind}->
                    ?THROW_ERR( ?ERR_ARENA_GAIN_CHLLG_MONEY_GOLD )
            end;
        ?CHALLENGE_MONEY_TYPE_SILVER->
            ConsumeLogType = ?GAIN_TYPE_SILVER_ARENA_HERO_CHALLENGE,
            DeductMoney = ChllgMoney,
            case common_bag2:t_gain_money(silver_any,DeductMoney,RoleID,ConsumeLogType) of
                {ok,RoleAttr2}->
                    {ok,RoleAttr2};
                {error,silver_any}->
                    ?THROW_ERR( ?ERR_ARENA_GAIN_CHLLG_MONEY_SILVER )
            end
    end.

%%扣除百强挑战的金钱
t_deduct_challenge_money(RoleID,MoneyType,ChllgMoney)->
    case MoneyType of
        ?CHALLENGE_MONEY_TYPE_GOLD->
            ConsumeLogType = ?CONSUME_TYPE_GOLD_ARENA_HERO_CHALLENGE,
            DeductMoney = ChllgMoney,
            case common_bag2:t_deduct_money(gold_unbind,DeductMoney,RoleID,ConsumeLogType) of
                {ok,RoleAttr2}->
                    {ok,RoleAttr2};
                {error,Reason}->
                    ?THROW_ERR(?ERR_OTHER_ERR, Reason)
            end;
        ?CHALLENGE_MONEY_TYPE_SILVER->
            ConsumeLogType = ?CONSUME_TYPE_SILVER_ARENA_HERO_CHALLENGE,
            DeductMoney = ChllgMoney,
            case common_bag2:t_deduct_money(silver_any,DeductMoney,RoleID,ConsumeLogType) of
                {ok,RoleAttr2}->
                    {ok,RoleAttr2};
                {error,Reason}->
                    ?THROW_ERR(?ERR_OTHER_ERR, Reason)
            end
    end.

send_role_chllg_money_change(MoneyType,ChllgId,RoleAttr2) when is_record(RoleAttr2,p_role_attr)->
    case MoneyType of
        ?CHALLENGE_MONEY_TYPE_SILVER->
            common_misc:send_role_silver_change(ChllgId,RoleAttr2);
        ?CHALLENGE_MONEY_TYPE_GOLD->
            common_misc:send_role_gold_change(ChllgId,RoleAttr2)
    end.

%%@doc 给指定人发送积分结果
send_role_arena_result(CurrInfo,Result,RoleID,ScoreInfo) ->
    send_role_arena_result(CurrInfo,Result,RoleID,ScoreInfo,undefined).
send_role_arena_result(CurrInfo,Result,RoleID,ScoreInfo,ChllgResult) ->
    {MyScore,OpponentScore,MyTotalScore} = ScoreInfo,
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        MapRole when is_record(MapRole, p_map_role) ->
            ResultInfo = CurrInfo#p_arena_info{result=Result},
            R2 = #m_arena_result_toc{result_info=ResultInfo,my_score=MyScore,opponent_score=OpponentScore,
                                     total_score=MyTotalScore,chllg_result=ChllgResult},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_RESULT, R2);
        _ ->
            ?ERROR_MSG("send_role_arena_result err,RoleID=~w",[RoleID])
    end.

%%@doc 根据竞技场的ID，获取对应的类型
%%@return integer()
get_arena_type(Id)->
    [SiteList] =common_config_dyn:find(arena,arena_site),
    get_arena_type_2(SiteList,Id).

get_arena_type_2([],_Id)->
    0;
get_arena_type_2([H|T],ArenaId)->
    {MinArenaId,MaxArenaId,Type,_MapId} = H,
    case ArenaId>=MinArenaId andalso MaxArenaId>=ArenaId of
        true->
            Type;
        _ ->
            get_arena_type_2(T,ArenaId)
    end.

%%@doc 获取目前的竞技场积分值
get_arena_total_score(RoleID) ->
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{total_score=TotalScore}]->
            TotalScore;
        _ ->
            ?DEFAULT_ARENA_SCORE
    end.

%%@return {ok,NewScore}
add_arena_score(RoleID,AddScore) when is_integer(RoleID),is_integer(AddScore)->
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{total_score=TotalScore}=Rd1]->
            NewScore = if (TotalScore+AddScore)>0 ->(TotalScore+AddScore); true-> 0 end,
            Rd2 = Rd1#r_role_arena{total_score=NewScore},
            db:dirty_write(?DB_ROLE_ARENA,Rd2);
        _ ->
            NewScore = if (?DEFAULT_ARENA_SCORE+AddScore)>0 ->(?DEFAULT_ARENA_SCORE+AddScore); true-> 0 end,
            Rd2 = #r_role_arena{role_id=RoleID,
                                total_score=NewScore}
    end,
    db:dirty_write(?DB_ROLE_ARENA,Rd2),
    {ok,NewScore}.

%%@doc 获取今日的个人擂台参与次数
get_arena_partake_times_today(RoleID) when is_integer(RoleID) ->
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{}=RoleArenaInfo] ->
            get_arena_partake_times_today(RoleArenaInfo);
        _ ->    0
    end;
get_arena_partake_times_today(RoleArenaInfo) when is_record(RoleArenaInfo,r_role_arena) ->
    #r_role_arena{partake_times=Val, partake_date=EnterDate} = RoleArenaInfo,
    case EnterDate =:= date() of
        true->
            Val;
        _ ->    0
    end.

%%@doc 获取今日的百强挑战次数
get_arena_chllg_times_today(RoleID) when is_integer(RoleID) ->
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{chllg_times=Val, chllg_date=ChllgDate}] ->
            case ChllgDate =:= date() of
                true->  Val;
                _ -> 0
            end;
        _ ->    0
    end.

%%@doc 获取今日的百强挑战次数
get_arena_be_chllged_times_today(RoleID) when is_integer(RoleID) ->
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{be_chllged_times=Val, be_chllged_date=BeChllgedDate}] ->
            case BeChllgedDate =:= date() of
                true->  Val;
                _ -> 0
            end;
        _ ->    0
    end.

update_hero_score_to_manager(ScoreList) when is_list(ScoreList)->
    SendInfo = {update_hero_score,ScoreList},
    case global:whereis_name(mod_arena_manager) of
        undefined->
            ?ERROR_MSG("严重,mod_arena_manager is down!!",[]);
        Pid->
            erlang:send(Pid,SendInfo)
    end.
    


