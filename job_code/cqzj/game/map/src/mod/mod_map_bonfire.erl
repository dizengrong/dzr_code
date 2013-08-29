-module(mod_map_bonfire).
-include("mgeem.hrl").
-export([
         init/1, 
         handle/1, 
         send_bonfire_info/1,
         erase_role_info/1, 
         loop_check/0,
         get_bonfire_add_exp/4,
         del_range_role/1,
         change_range_has_bonfire/1
        ]).

-define(bonfire(ID),{bonfire,ID}).
-define(bonfire_pos(X,Y),{bonfire_pos,X,Y}).
-define(bonfire_slice(Slice),{bonfire_slice,Slice}).
-define(bonfire_range(ID),{bonfire_range,ID}).
-define(bonfire_role_list(ID),{bonfire_role_list,ID}).
-define(bonfire_add_rate(ID),{rate_list,ID}).
-define(bonfire_add_fagot(ID, RoleID), {bonfire_add_fagot,ID, RoleID}).

-define(FAGOT_TYPE, 11600016).
-define(BONFIRE_BURN_STATE, 1).
-define(BONFIRE_QUENCH_STATE, 2).

-define(BONFIRE_TYPE_FAMILY, 1).
-define(BONFIRE_TYPE_TEAM, 2).
-define(BONFIRE_TYPE_PERSONAL, 3).

init(MapID) ->
    case common_config_dyn:find(map_bonfire,MapID) of
        [{X,Y}] ->
            case common_config_dyn:find(bonfire, MapID) of
                [BonfireConfig] ->
                    new_bonfire(BonfireConfig,X,Y);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

new_bonfire(#p_bonfire{map_id=ID,state=State,time=Time}, X, Y) ->
    case get_pos_bonfire(X, Y) of
        undefined ->
            Now = common_tool:now(),
            Pos = #p_pos{tx=X,ty=Y,px=1,py=1,dir=0},
            MapBonfire = 
                if State =:= ?BONFIRE_BURN_STATE ->
                        #p_map_bonfire{id=ID,state=State,pos=Pos,start_time=Now,end_time=Now+Time,rate=0};
                   true ->
                        #p_map_bonfire{id=ID,state=State,pos=Pos,start_time=0,end_time=0,rate=0}
                end,
            up_bonfire(MapBonfire),
            {ok, MapBonfire};
        _ ->
            {error, notpos}
    end.

send_bonfire_info(RoleID) ->
    ?DEBUG("send_bonfire_info:~w ~w~n",[RoleID, self()]),
    case get_all_bonfire() of
        [] -> ignore;
        UpL ->
            NewUpL = 
                lists:foldl(
                  fun(#p_map_bonfire{id=ID}=Info,Acc) -> 
                          add_bonfire_role_list(ID,RoleID),
                          {_,Rate} = clac_rate(RoleID),
                          [Info#p_map_bonfire{rate=Rate, members=length(get_range_roleids(ID)),fagot=get_sum_fagot(ID, get_range_roleids(ID))}|Acc]
                  end,[],UpL),
            Data = #m_bonfire_up_toc{bnfires=NewUpL},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?BONFIRE, ?BONFIRE_UP, Data)
    end.

erase_role_info(RoleID) ->
    lists:foreach(
      fun(#p_map_bonfire{id=ID}) ->
              reduce_bonfire_role_list(ID, RoleID)
      end,get_all_bonfire()).

loop_check() ->
	Now = common_tool:now(),
	lists:foreach(
	  fun(#p_map_bonfire{id=ID, state=State,start_time=StartTime, end_time=EndTime}=Bonfire) -> 
			  if State =:= ?BONFIRE_QUENCH_STATE ->
					 if Now < StartTime orelse Now > EndTime ->
							erase_range_roleids(ID),
							ignore;
						true ->
							case get(family_id) of
								undefined ->
									ignore;
								FamilyID ->
									(catch global:send(common_misc:make_family_process_name(FamilyID), call_member_bonfire))
							end,
							?DEBUG("RoleIDs:~w Bonfire:~w~n",[get_bonfire_role_list(ID),Bonfire]),
							NewBonfire = Bonfire#p_map_bonfire{state=?BONFIRE_BURN_STATE},
							up_bonfire(NewBonfire),
							Data = #m_bonfire_up_toc{bnfires=[NewBonfire]},
							mgeem_map:broadcast(get_bonfire_role_list(ID), ?BONFIRE, ?BONFIRE_UP, Data)
					 end;
				 EndTime < Now andalso StartTime =/= EndTime  ->
					 NewBonfire = Bonfire#p_map_bonfire{state=?BONFIRE_QUENCH_STATE},
					 up_bonfire(NewBonfire),
					 erase_range_roleids(ID),
					 Data = #m_bonfire_up_toc{bnfires=[NewBonfire]},
					 mgeem_map:broadcast(get_bonfire_role_list(ID), ?BONFIRE, ?BONFIRE_UP, Data);
				 true ->
					 ignore
			  end,
			  check_range(Bonfire)
	  end, get_all_bonfire()).

change_range_has_bonfire(RoleID) ->
    catch lists:foldl(
            fun(#p_map_bonfire{id=ID}, false) ->
                    lists:member(RoleID, get_range_roleids(ID));
               (_, true) ->
                    throw(true)
            end,false,get_all_bonfire()).

calc_bonfire_add(#p_map_bonfire{id=ID}) ->
    [#p_bonfire{type_list=TypeList}] = common_config_dyn:find(bonfire, ID),
    {RateList, _} = 
        lists:foldl(
          fun(?BONFIRE_TYPE_FAMILY, {Acc,RoleIDs}) -> %%只有宗族地图才有这种，篝火类型
                  ?DEBUG("RoleIDs:~w~n",[RoleIDs]),
                  Rate1 = get_sum_num_rate(RoleIDs),
                  Rate2 = get_sum_fagot_rate(ID, RoleIDs),
                  {[{Rate1, Rate2, RoleIDs}|Acc],[]};
             (?BONFIRE_TYPE_TEAM, {Acc,[RoleID|RoleIDs]}) ->
                  TeamRoleIDs = common_misc:team_get_team_member(RoleID),
                  {NTRoleIDs,NRoleIDs} = lists:partition(fun(R) -> lists:member(R,TeamRoleIDs) end, [RoleID|RoleIDs]),
                  Rate1 = get_sum_num_rate(NTRoleIDs),
                  Rate2 = get_sum_fagot_rate(ID, NTRoleIDs),
                  {[{Rate1, Rate2, NTRoleIDs}|Acc],NRoleIDs};
             (?BONFIRE_TYPE_PERSONAL, {Acc,RoleIDs}) ->
                  {Acc, RoleIDs}
          end,{[],get_range_roleids(ID)}, TypeList),
    RateList.

handle({Unique, ?BONFIRE, ?BONFIRE_ADD_FAGOT, DataIn, RoleID, PID, _Line, _State}) ->
    ?DEBUG("mapid:~w~n",[_State#map_state.mapid]),
    #m_bonfire_add_fagot_tos{bonfire_id=ID} = DataIn,
    Data = case check_add_fagot(ID, RoleID) of
               {ok, Bonfire}  ->
                   case common_transaction:transaction(
                          fun() ->
                                  mod_bag:decrease_goods_by_typeid(RoleID, ?FAGOT_TYPE, 1)
                          end)
                   of
                       {aborted, Reason}->
                           ?ERROR_MSG("Add Fagot error:~w~n",[Reason]),
                           Reason1 = case Reason of
                                         {bag_error,num_not_enough} ->
                                             ?_LANG_BONFIRE_NOT_FAGOT;
                                         _ ->
                                             Reason
                                     end,
                           #m_bonfire_add_fagot_toc{succ=false, reason=Reason1};
                       {atomic, {ok,FinalUpdateList,FinalDeleteList}}  ->
                           UpL = lists:foldl(fun(Goods, Acc) -> [Goods#p_goods{current_num=0}|Acc] end,FinalUpdateList,FinalDeleteList),
                           common_misc:update_goods_notify({role,RoleID}, UpL),
                           put_add_fagot(ID, RoleID),
                           {_,Rate} = clac_rate(RoleID),
                           #m_bonfire_add_fagot_toc{succ=true, bonfire=Bonfire#p_map_bonfire{rate=Rate, members=length(get_range_roleids(ID)),
                                                                                             fagot=get_sum_fagot(ID, get_range_roleids(ID))}}
                   end;
               {error, Reason} ->
                   #m_bonfire_add_fagot_toc{succ=false,reason=Reason}
           end,
    common_misc:unicast2(PID, Unique, ?BONFIRE, ?BONFIRE_ADD_FAGOT, Data);
handle({Unique, ?BONFIRE, ?BONFIRE_GET, DataIn, RoleID, PID, _Line, _State}) ->
    #m_bonfire_get_tos{bonfire_id=ID}=DataIn,
    case get_bonfire(ID) of
        undefined ->
            common_misc:unicast2(PID, Unique, ?BONFIRE, ?BONFIRE_GET, 
                                 #m_bonfire_get_toc{succ=false,reason=?_LANG_BONFIRE_NOT_BONFIRE});
        Bonfire  ->
            {_, Rate} = clac_rate(RoleID),
            common_misc:unicast2(PID, Unique, ?BONFIRE, ?BONFIRE_GET, 
                                 #m_bonfire_get_toc{succ=true,bonfire_info=Bonfire#p_map_bonfire{rate=Rate, members=length(get_range_roleids(ID)),
                                                                                                 fagot=get_sum_fagot(ID, get_range_roleids(ID))}})
    end;
handle({bonfire_start_time,FamilyID, StartTime}) ->
    put(family_id, FamilyID),
    lists:foreach(
      fun(#p_map_bonfire{id=ID, state=?BONFIRE_QUENCH_STATE}=Bonfire) -> 
              [#p_bonfire{time=Time}] = common_config_dyn:find(bonfire, ID),
               ?DEBUG("bonfire:~w start_time:~w~n",[Bonfire,StartTime]),
               NewBonfire = Bonfire#p_map_bonfire{start_time=StartTime, end_time=StartTime+Time},
               up_bonfire(NewBonfire);
         (_) ->
              ignore
      end, get_all_bonfire());
handle({send_family_info,RoleID}) ->
    send_bonfire_info(RoleID);
handle(_) ->
    ignore.

%%获取角色的加成率
sum_rate(RoleID) ->
    case clac_rate(RoleID) of
        {false, _} ->
            0;
        {true, TmpRate} ->
            TmpRate/100+1
    end.

clac_rate(RoleID) ->
    case mod_map_actor:get_actor_txty_by_id(RoleID, role) of
        {X,Y} ->
            ?DEBUG("All Bonfire:~w~n",[get_all_bonfire()]),
            lists:foldl(
              fun(#p_map_bonfire{id=ID,state=?BONFIRE_BURN_STATE, pos=#p_pos{tx=TX,ty=TY}}=Bonfire,{Falg,Rate1}) ->
                      [#p_bonfire{range=Range}] = common_config_dyn:find(bonfire, ID),
                      XV = abs(TX-X),
                      XY = abs(TY-Y),
                      case XV*XV+XY*XY > Range*Range of
                          true  ->
                              {Falg, Rate1};
                          false ->
                              up_range_roleids(ID,RoleID),
                              RateList = calc_bonfire_add(Bonfire),
                              ?DEBUG("RateList:~w~n",[RateList]),
                              {true, lists:foldl(
                                       fun({Rate_1,Rate_2,RL}, SumRate) ->
                                               case lists:member(RoleID, RL) of
                                                   true -> SumRate+Rate_1+Rate_2;
                                                   false -> SumRate
                                               end
                                       end,Rate1,RateList)}
                      end;
                 (_, {Falg,Rate1}) ->
                      {Falg, Rate1}
              end,{false,0},get_all_bonfire());
        _ -> {false,0}
    end.

check_range(#p_map_bonfire{id=ID, pos=#p_pos{tx=TX,ty=TY}}) ->
    [#p_bonfire{range=Range}] = common_config_dyn:find(bonfire, ID),
    RoleIDs = get_range_roleids(ID),
    lists:foreach(
      fun(RoleID) ->
              case mod_map_actor:get_actor_txty_by_id(RoleID, role) of
                  undefined ->
                      rd_range_roleids(ID,RoleID);
                  {X,Y} ->
                      XV = abs(TX-X),
                      XY = abs(TY-Y),
                      case XV*XV+XY*XY > Range*Range of
                          true ->
                              rd_range_roleids(ID,RoleID);
                          false ->
                              ignore
                      end
              end
      end,RoleIDs).

del_range_role(RoleID) ->
    lists:foreach(
      fun(#p_map_bonfire{id=ID}) ->
              rd_range_roleids(ID,RoleID)
      end,get_all_bonfire()).
    
get_range_roleids(ID) ->
    case get(?bonfire_range(ID)) of
        undefined -> [];
        L -> L
    end.

get_bonfire_add_exp(RoleID, FactionID, Level, Colour) ->
    [Value] = common_config_dyn:find(drunk_buff_value, {Level,Colour}),
    %% 全民喝酒时间加倍
    case mod_activity:is_in_drunk_time(FactionID) of
        true ->
            [Multi] = common_config_dyn:find(etc, drunk_multi);
        _ ->
            Multi = 1
    end,
    ?DEBUG("add_exp_role:~w BaseValue:~w~n",[RoleID,Value]),
    round(Value*Multi*sum_rate(RoleID)).

get_all_bonfire() ->
    case get(bonfire_list) of
        undefined -> [];
        IDList -> get_bonfire(IDList)
    end.

get_pos_bonfire(X,Y) ->
    get(?bonfire_pos(X,Y)).

get_bonfire([]) ->
    [];
get_bonfire([_|_]=L) ->
    get_bonfire(L,[]);
get_bonfire(ID) ->
    get(?bonfire(ID)).
get_bonfire([], Acc) ->
    [R || R <- Acc, R =/= undefined];
get_bonfire([ID|T], Acc) ->
    get_bonfire(T, [get_bonfire(ID)|Acc]).
    
get_bonfire_role_list(ID) ->
    case get(?bonfire_role_list(ID)) of
        undefined ->
            [];
        List ->
            List
    end.

get_sum_fagot(ID, RoleIDList) ->
    lists:sum(
      [case get(?bonfire_add_fagot(ID, RoleID)) of
           undefined -> 0;
           {_, Count} -> Count
       end || RoleID <- RoleIDList]).

get_sum_fagot_rate(ID, RoleIDList) ->
    lists:foldl(
      fun(RoleID, Sum) ->
              case get(?bonfire_add_fagot(ID, RoleID)) of
                  undefined -> Sum;
                  {_, Count} -> 
                      if Sum+Count > 100 -> 
                              100;
                         true ->
                              Sum+Count
                      end
              end
      end, 0, RoleIDList).

get_sum_num_rate(RoleIDList) ->
    Size = length(RoleIDList),
    case (Size-1)*5 > 25 of
        true -> 25;
        false -> (Size-1)*5
    end.
              
check_add_fagot(ID, RoleID) ->
    Now = common_tool:now(),
    case get_bonfire(ID) of
        undefined ->
            {error, ?_LANG_BONFIRE_NOT_BONFIRE};
        #p_map_bonfire{}=Bonfire  ->
            case get(?bonfire_add_fagot(ID, RoleID)) of
                undefined ->
                    {ok, Bonfire};
                {Time,Count} ->
                    if Time+86400 > Now andalso Count > 2 ->
                            {error, ?_LANG_BONFIRE_ADD_FAGOT_FAIL};
                       true ->
                            {ok, Bonfire}
                    end
            end
    end.

put_add_fagot(ID, RoleID) ->
    Now = common_tool:now(),
    case get(?bonfire_add_fagot(ID, RoleID)) of
        undefined -> put(?bonfire_add_fagot(ID, RoleID),{Now,1});
        {_, Count} -> put(?bonfire_add_fagot(ID, RoleID),{Now,1+Count})
    end.

up_range_roleids(ID,RoleID) ->
    put(?bonfire_range(ID),[RoleID|lists:delete(RoleID,get_range_roleids(ID))]).

rd_range_roleids(ID,RoleID) ->
    put(?bonfire_range(ID),lists:delete(RoleID,get_range_roleids(ID))).

erase_range_roleids(ID) ->
    put(?bonfire_range(ID), []).

up_bonfire(#p_map_bonfire{id=ID, pos=Pos}=Info) ->
    put(?bonfire(ID),Info),
    put(?bonfire_pos(Pos#p_pos.tx,Pos#p_pos.ty),ID),
    put(bonfire_list,[ID|lists:delete(ID,get_all_bonfire())]).

add_bonfire_role_list(ID, RoleID) ->
    RoleIDs = [RoleID|lists:delete(RoleID,get_bonfire_role_list(ID))],
    put(?bonfire_role_list(ID), RoleIDs).

reduce_bonfire_role_list(ID, RoleID) ->
    RoleIDs = lists:delete(RoleID,get_bonfire_role_list(ID)),
    put(?bonfire_role_list(ID), RoleIDs).


