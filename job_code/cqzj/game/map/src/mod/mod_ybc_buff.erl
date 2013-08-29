%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     押镖车的BUFF处理
%%% @end
%%% Created : 2011-3-5
%%%-------------------------------------------------------------------
-module(mod_ybc_buff).

-include("mgeem.hrl").

-export([
         add_buff/5,
         remove_buff/5
        ]).
-export([
         clear_buff_timer_list/1,
         save_buff_timer_list/2
        ]).

%%
%% API Functions
%%
-define(YBC_BUFF_TIMER_LIST,ybc_buff_timer_list).

%%@doc 保存buff计时器列表
save_buff_timer_list(YbcID,BuffTimerList) when is_list(BuffTimerList)->
    ?DEBUG("bison,save_buff_timer_list,BuffTimerList=~w",[BuffTimerList]),
    erlang:put({?YBC_BUFF_TIMER_LIST,YbcID},BuffTimerList).

%%@doc 清空buff计时器列表，并返回剩下的计时器列表；
%%      目的是用于地图调整的计时器转储
%%@return BuffTimerList::list()
clear_buff_timer_list(YbcID)->
    ?DEBUG("bison,clear_buff_timer_list,YbcID=~w",[YbcID]),
    BuffTimerList = get_buff_timer_list(YbcID),
    lists:foldl(
      fun(E,Acc) ->
              #r_buff_timer_info{timer_ref=TimerRef} = E,
              case erlang:cancel_timer(TimerRef) of
                  false ->
                      Acc;
                  Time ->
                      [E#r_buff_timer_info{time=Time}|Acc]
              end
      end,[], BuffTimerList).

%%@doc 增加BUFF
%%@return #p_map_ybc
add_buff(_SrcActorID, _SrcActorType, [], _YbcID, YbcMapInfo) ->
    YbcMapInfo;
add_buff(SrcActorID, SrcActorType, AddBuffs, YbcID, YbcMapInfo) when is_list(AddBuffs) ->
    #p_map_ybc{buffs=OldBuffs} = YbcMapInfo,
    ?DEBUG("bison,AddBuffs=~w",[AddBuffs]),
    
    Buffs2 =
        lists:foldl(
          fun(BuffDetail, BuffsAcc) ->
                  case get_add_buff_method(BuffDetail, BuffsAcc) of
                      {ok, add_buff} ->
                          add_buff2(SrcActorID, SrcActorType, YbcID, BuffDetail, BuffsAcc);
                      {ok, replace_buff} ->
                          replace_buff(SrcActorID, SrcActorType, YbcID, BuffDetail, BuffsAcc);
                      _ ->
                          BuffsAcc
                  end
          end, OldBuffs, AddBuffs),
    ?DEBUG("bison,Buffs2=~w",[Buffs2]),
    
    YbcMapInfo2 = YbcMapInfo#p_map_ybc{buffs=Buffs2},
    
    %%重新计算镖车属性
    case calc_attr_after_attr_update(YbcMapInfo2, Buffs2) of
        {ok, YbcMapInfo3} ->
            YbcMapInfo3;
        _ ->
            YbcMapInfo
    end;
add_buff(SrcActorID, SrcActorType, AddBuff, YbcID, YbcMapInfo) ->
    add_buff(SrcActorID, SrcActorType, [AddBuff], YbcID, YbcMapInfo).


add_buff2(SrcActorID, SrcActorType, YbcID, BuffDetail, Buffs) ->
    ActorBuff = get_actor_buf_by_id(SrcActorID, SrcActorType, YbcID, BuffDetail),
    setup_buf_timer(SrcActorID,BuffDetail, ActorBuff),
    
    [ActorBuff|Buffs].


replace_buff(SrcActorID, SrcActorType, YbcID, BuffDetail, Buffs) ->
    
    ActorBuff = get_actor_buf_by_id(SrcActorID, SrcActorType, YbcID, BuffDetail),
    
    %%获取BUFF相应的处理函数
    BuffType = BuffDetail#p_buf.buff_type,
    
    %%删除原来的计时
    remove_buff_timer(YbcID,BuffType),
    setup_buf_timer(SrcActorID,BuffDetail, ActorBuff),
    
    Buffs2 = lists:keydelete(BuffType, #p_actor_buf.buff_type, Buffs),
    
    [ActorBuff|Buffs2].


%%@doc 删除BUFF
%%@return #p_map_ybc
remove_buff(_SrcActorID, _SrcActorType, [], _YbcID, YbcMapInfo) ->
    YbcMapInfo;
remove_buff(_SrcActorID, _SrcActorType, 0, _YbcID, YbcMapInfo) ->
    Buffs = YbcMapInfo#p_map_ybc.buffs,
    
    RemoveList =
        lists:foldl(
          fun(ActorBuff, Acc) ->
                  BuffID = ActorBuff#p_actor_buf.buff_id,
                  
                  {ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
                  
                  CanRemove = BuffDetail#p_buf.can_remove,
                  case CanRemove of
                      true ->
                          [ActorBuff|Acc];
                      
                      false ->
                          Acc
                  end
          end, [], Buffs),
    
    remove_buff2(RemoveList, YbcMapInfo);

remove_buff(_SrcActorID, _SrcActorType, RemoveList, _YbcID, YbcMapInfo) when is_list(RemoveList) ->
    remove_buff2(RemoveList, YbcMapInfo);

remove_buff(SrcActorID, SrcActorType, RemoveBuff, YbcID, YbcMapInfo) ->
    remove_buff(SrcActorID, SrcActorType, [RemoveBuff], YbcID, YbcMapInfo).

remove_buff2(RemoveList, YbcMapInfo) ->
    #p_map_ybc{buffs=Buffs,ybc_id=YbcID} = YbcMapInfo,
    Buffs2  = lists:foldl(fun(ActorBuff,Acc)-> 
                                  BuffType = ActorBuff#p_actor_buf.buff_type,
                                  lists:keydelete(BuffType, #p_actor_buf.buff_type, Acc)
                          end, Buffs, RemoveList),
    lists:foreach(fun(ActorBuff)-> 
                          BuffType = ActorBuff#p_actor_buf.buff_type,
                          remove_buff_timer(YbcID,BuffType)
                  end, RemoveList),
    
    YbcMapInfo2 = YbcMapInfo#p_map_ybc{buffs=Buffs2},
    
    %%重新计算镖车属性
    case calc_attr_after_attr_update(YbcMapInfo2, Buffs2) of
        {ok, YbcMapInfo3} ->
            YbcMapInfo3;
        _ ->
            YbcMapInfo2
    end.


%% ====================================================================
%% Local Functions
%% ====================================================================


get_buff_timer_list(YbcID)->
    case get({?YBC_BUFF_TIMER_LIST,YbcID}) of
        undefined-> [];
        BuffTimerList -> BuffTimerList
    end.

save_buff_timer(YbcID,BuffTimerInfo) when is_record(BuffTimerInfo,r_buff_timer_info)->
    ?DEBUG("bison,save_buff_timer,BuffTimerInfo=~w",[BuffTimerInfo]),
    BuffTimerList = get_buff_timer_list(YbcID),
    save_buff_timer_list(YbcID,[BuffTimerInfo|BuffTimerList]).

remove_buff_timer(_YbcID,undefined)->
    ignore;
remove_buff_timer(YbcID,TimerRef) when is_reference(TimerRef)->
    ?DEBUG("bison,remove_buff_timer,TimerRef=~w",[TimerRef]),
    erlang:cancel_timer(TimerRef),
    case get({?YBC_BUFF_TIMER_LIST,YbcID}) of
        undefined-> ignore;
        [] -> ignore;
        BuffTimerList->
            List2 = lists:keydelete(TimerRef, #r_buff_timer_info.timer_ref, BuffTimerList),
            save_buff_timer_list(YbcID,List2)
    end;
remove_buff_timer(YbcID,BuffType) when is_integer(BuffType)->
    case get({?YBC_BUFF_TIMER_LIST,YbcID}) of
        undefined-> ignore;
        [] -> ignore;
        BuffTimerList->
            case lists:keyfind(BuffType, #r_buff_timer_info.buff_type, BuffTimerList) of
                false->
                    BuffTimerList;
                #r_buff_timer_info{timer_ref=TimerRef}->
                    remove_buff_timer(YbcID,TimerRef)
            end
    end.


%%开始创建buff的计时器
setup_buf_timer(SrcActorID,BuffDetail, ActorBuff) when is_record(BuffDetail,p_buf) ->
    #p_buf{buff_type=BuffType,last_type=LastType, last_value=LastTime, last_interval=_LastInterval} = BuffDetail,
    
    YbcID = ActorBuff#p_actor_buf.actor_id,
    
    %%目前的技能一般是 BUFF_LAST_TYPE_REAL_TIME
    case LastType of
        ?BUFF_LAST_TYPE_REAL_TIME ->
            BuffMsg = {mod_map_ybc, {remove_buff, SrcActorID, ybc, [ActorBuff], YbcID}},
            TimerRef = erlang:send_after(LastTime*1000, self(), BuffMsg),
            save_buff_timer(YbcID,#r_buff_timer_info{buff_type=BuffType,timer_ref=TimerRef,msg=BuffMsg});
        ?BUFF_LAST_TYPE_ONLINE_TIME ->
            BuffMsg = {mod_map_ybc, {remove_buff, SrcActorID, ybc, [ActorBuff], YbcID}},
            TimerRef = erlang:send_after(LastTime*1000, self(), BuffMsg),
            save_buff_timer(YbcID,#r_buff_timer_info{buff_type=BuffType,timer_ref=TimerRef,msg=BuffMsg});
        
        _ ->
            TimerRef = nil
    end,
    
    TimerRef.


%%重新计算属性
calc_attr_after_attr_update(YbcMapInfo0, Buffs) ->
    %%先设置默认值
    YbcMapInfo1 = YbcMapInfo0#p_map_ybc{move_speed= mod_ybc_person:get_default_speed()},
    YbcMapInfo2 = 
        lists:foldl(
          fun(Buf, Acc0) ->
                  #p_actor_buf{buff_id=BuffID, buff_type=Type} = Buf,
                  {ok, #p_buf{value=Value} } = mod_skill_manager:get_buf_detail(BuffID),
                  {ok, Func} = mod_skill_manager:get_buff_func_by_type(Type),
                  
                  case Func of
                      add_biaoche_speed ->
                          Old = Acc0#p_map_ybc.move_speed,
                          Acc = Acc0#p_map_ybc{move_speed=Old+Value};
                      _ ->
                          Acc = Acc0
                  end,
                  Acc
          end, YbcMapInfo1, Buffs),
    {ok,YbcMapInfo2}.


get_actor_buf_by_id(SrcActorID, SrcActorType, YbcID, BuffDetail) ->
    #p_buf{ buff_id=BuffID,
            last_value=LastValue,
            value=Value,
            buff_type=BuffType
          } = BuffDetail,
    
    BeginTime = common_tool:now(),
    
    #p_actor_buf{ buff_id=BuffID,
                  buff_type=BuffType,
                  actor_id=YbcID,
                  actor_type=?TYPE_YBC,
                  from_actor_id=SrcActorID,
                  from_actor_type=mof_common:actor_type_int(SrcActorType),
                  value=Value,
                  start_time=BeginTime,
                  end_time=BeginTime+LastValue,
                  remain_time=LastValue
                }.
                  
%%BUFF处理方式
get_add_buff_method(BuffDetail, Buffs) ->
    #p_buf{buff_type=BuffType, level=Level} = BuffDetail,
    
    %%没有的话就加上
    case lists:keyfind(BuffType, #p_actor_buf.buff_type, Buffs) of
        false ->
            {ok, add_buff};
        ActorBuff ->
            %%如果新加的BUFF等级较高则替换或则无操作
            BuffID = ActorBuff#p_actor_buf.buff_id,
            {ok, ActorBuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
            
            ActorBuffLevel = ActorBuffDetail#p_buf.level,
            case ActorBuffLevel >= Level of
                true ->
                    {ok, replace_buff};
                
                _ ->
                    {ok, no_operate}
            end
    end.


   
