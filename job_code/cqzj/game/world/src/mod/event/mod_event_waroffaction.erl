%%%-------------------------------------------------------------------
%%% @author liuwei <>
%%% @copyright (C) 2010, liuwei
%%% @doc
%%%
%%% @end
%%% Created :  7 Oct 2010 by liuwei <>
%%%-------------------------------------------------------------------
-module(mod_event_waroffaction).

%%-behaviour(mod_event).

-include("mgeew.hrl").

%% Corba callbacks
-export([
         init_config/0,
         handle_info/1,
         handle_call/1,
         handle_msg/1,
         reload_config/1
        ]).


%%--------------------------------------------------------------------
init_config() -> 
    do_calc_next_war_time().


handle_info(Info) ->
    do_handle_info(Info),
    ok.


handle_call(Request) ->
    do_handle_call(Request).


handle_msg(_Msg) ->
    ok.


reload_config(_Config) ->
    ok.

do_handle_call(get_info) ->
    do_get_waroffaction_info();
do_handle_call(Request) ->
    ?ERROR_MSG("~ts:~w", ["未知的CALL调用", Request]).


do_handle_info({declare_war,AttackFactionID,DefenceFactionID,RoleID,RoleName}) ->
    ?ERROR_MSG("declare_war , ~w ~w",[AttackFactionID,DefenceFactionID]),
    global:send(mgeew_office,{deduct_faction_silver_declare_war,AttackFactionID,DefenceFactionID,RoleID,RoleName}),
    {H,M,S} = time(),
    Seconds = 19 * 60 * 60 + (23-H) * 60 * 60 + (59-M)*60 + 60 - S,
    do_declare_war(AttackFactionID,DefenceFactionID,Seconds);
do_handle_info({begin_apply,AttackFactionID,DefenceFactionID}) ->
    do_begin_apply(AttackFactionID,DefenceFactionID);
do_handle_info({begin_war,AttackFactionID,DefenceFactionID}) ->
    do_begin_war(AttackFactionID,DefenceFactionID);
do_handle_info({end_war,AttackFactionID,DefenceFactionID}) ->
    do_end_war(AttackFactionID,DefenceFactionID);
do_handle_info(reset) ->
    do_reset();
%% do_handle_info({reborn_war_building,FactionID}) ->
%%     do_reborn_war_building(FactionID);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知得消息", Info]).

%%后台获取现在的国战信息，即最近的一场还没打的国战的信息
do_get_waroffaction_info() ->
    case do_calc_next_war_time2() of
        [] ->
            no_war;
        List ->
            lists:foldr(
              fun({AttackFactionID,DefenceFactionID,Seconds},{Acc1,Acc2,MinAcc}) ->
                      case MinAcc > Seconds of
                          true ->
                              {AttackFactionID,DefenceFactionID,Seconds};
                          false ->
                              {Acc1,Acc2,MinAcc}
                      end
              end,{0,0,2000000000},List)
    end.


do_declare_war(AttackFactionID,DefenceFactionID,Seconds) ->
     %%开始进入战前准备阶段
    erlang:send_after((Seconds+30*60)*1000 , self(), {mod_event_waroffaction,{begin_apply,AttackFactionID,DefenceFactionID}}),  
    %%国战开始
    erlang:send_after((Seconds+60*60)*1000 , self(), {mod_event_waroffaction,{begin_war,AttackFactionID,DefenceFactionID}}),
    %%国战结束时间
    erlang:send_after((Seconds+60*60*2)*1000 , self(), {mod_event_waroffaction,{end_war,AttackFactionID,DefenceFactionID}}).

get_war_map_name(DefenceFactionID) when DefenceFactionID > 0 andalso DefenceFactionID < 4 ->
    case DefenceFactionID of
        1 ->
            PinJiangMapName = common_misc:get_map_name(10260),
            JingChengMapName = common_misc:get_map_name(10260);
        2 ->
            PinJiangMapName = common_misc:get_map_name(10260),
            JingChengMapName = common_misc:get_map_name(10260);
        3 ->
            PinJiangMapName = common_misc:get_map_name(10260),
            JingChengMapName = common_misc:get_map_name(10260)     
    end,
    {PinJiangMapName,JingChengMapName};
get_war_map_name(_) ->
    error.


do_begin_apply(AttackFactionID,DefenceFactionID) ->
    {PinJiangMapName,JingChengMapName} = get_war_map_name(DefenceFactionID),
    catch global:send(PinJiangMapName,{mod_waroffaction,{begin_apply,AttackFactionID,DefenceFactionID}}),
    catch global:send(JingChengMapName,{mod_waroffaction,{begin_apply,AttackFactionID,DefenceFactionID}}),
    ok.


do_begin_war(AttackFactionID,DefenceFactionID) ->
    {PinJiangMapName,JingChengMapName} = get_war_map_name(DefenceFactionID),
    catch global:send(PinJiangMapName,{mod_waroffaction,{begin_war,AttackFactionID,DefenceFactionID}}),
    catch global:send(JingChengMapName,{mod_waroffaction,{begin_war,AttackFactionID,DefenceFactionID}}),
    ok.


do_end_war(_AttackFactionID,DefenceFactionID) ->
    {_PinJiangMapName,JingChengMapName} = get_war_map_name(DefenceFactionID),
    catch global:send(JingChengMapName,{mod_waroffaction,end_war_when_time_out}),
    ok.

%%启动服务器的时候计算当前还没打的国战的开始时间
do_calc_next_war_time() ->
    case do_calc_next_war_time2() of
        [] ->
            [];
        List ->
            lists:foreach(
              fun({AttackFactionID,DefenceFactionID,Seconds}) ->
                      do_declare_war(AttackFactionID,DefenceFactionID,Seconds)
              end,List)
    end.

do_calc_next_war_time2() ->
    case db:dirty_match_object(?DB_FACTION,#p_faction{_='_'}) of
        [] ->
            [];
        FactionInfoList ->
            NowDay = calendar:date_to_gregorian_days(date()),
            lists:foldl(
              fun(FactionInfo,Acc) ->
                      #p_faction{last_attack_day = LastAttackDay} = FactionInfo,
                      Yesterday = NowDay-1,
                      case LastAttackDay of
                          NowDay ->      %%第二天会有一场国战
                              {H,M,S} = time(),
                              Seconds = 19 * 60 * 60 + (23-H) * 60 * 60 + (59-M)*60 + 60 - S,
                              do_calc_next_war_time3(LastAttackDay,Seconds,FactionInfoList,FactionInfo,Acc);
                          Yesterday ->      %%当天或许会有一场国战
                              {H,M,S} = time(),
                              case H >= 20 of  
                                  true ->
                                      Acc; %%超过晚上8点了就不再开始
                                  false ->
                                      Seconds = (18-H) * 60 * 60 + (59-M)*60 + 60 - S,
                                      case Seconds + 30*60 >= 0 of
                                          true ->
                                              do_calc_next_war_time3(LastAttackDay,Seconds,FactionInfoList,FactionInfo,Acc);
                                          false ->
                                              Acc
                                      end
                              end;
                          _ ->      %%国战已经举行过了
                              Acc
                      end    
              end,[],FactionInfoList)               
    end.


do_calc_next_war_time3(LastAttackDay,Seconds,FactionInfoList,AttackFactionInfo,Acc2) ->
  
    case lists:foldl(
           fun(FactionInfo,Acc) ->
                   %%相互交战的两个国家的attackday和defenceday必须一样
                   case FactionInfo#p_faction.last_defence_day  =:= LastAttackDay of
                       true ->
                          
                           FactionInfo;
                       false ->
                           Acc
                   end
           end,[],FactionInfoList) of
        [] ->
            Acc2;
        DefenceFactionInfo ->
            AttackFactionID = AttackFactionInfo#p_faction.faction_id,
            DefenceFactionID = DefenceFactionInfo#p_faction.faction_id,
            [{AttackFactionID,DefenceFactionID,Seconds}|Acc2]
    end.
            
            
do_reset() ->
     case db:transaction(fun() -> t_reset() end) of
        {atomic,_} ->
            %%TODO 添加NPC管理记录;
            ignore;
        {aborted,_Reason} ->
            ignore
    end.



t_reset() ->
      lists:foreach(
        fun(FactionID)->
                [FactionInfo] = db:read(?DB_FACTION, FactionID, write),
                db:write(?DB_FACTION,FactionInfo#p_faction{last_attack_day=undefined,last_defence_day=undefined},write)
        end,lists:seq(1, 3)).

    
                     
        
    



