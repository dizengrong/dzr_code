%% Author: chixiaosheng
%% Created: 2011-3-22
%% Description:  mod_mission_data
-module(mod_mission_data).

%%
%% Include files
%%
-include("mission.hrl").

%%
%% Exported Functions
%%

%% 配置数据相关
-export([
         get_base_info/1, 
         get_setting/1,
         get_list_by_key/1,
         get_role_mission_key/1,
         get_status_data/2,
         get_mission_item_use_point/2
         ]).

%% 玩家的任务数据
-export([get_mission_data/1,
         get_mission_by_big_group/2]).
-export([reload/0]).
-export([get_listener_greate_than/3]).
-export([
         get_counter/2,
         get_commit_times/2,
         
         get_succ_times/2,
         set_succ_times/3,
         
         get_fail_times/2,
         set_fail_times/3,
         
         get_pinfo/2,
         set_pinfo/2,
         set_pinfo/3,
         del_pinfo/2,
         del_pinfo/3,
         get_pinfo_list/1,
         set_pinfo_list/3,
         
         get_role_auto_list/1,
         set_role_auto_list/2,
         
         get_listener/3,
         set_listener/2,
         del_listener/3,
         get_listener_list/1,
         
         %%热加载任务数据
         code_build_mission_bin/0,
         
         set_counter/2,
         
         join_to_listener/4,
         remove_from_listener/4,
         
         get_group_random_one/1,
         
         get_extend/2,
         set_extend/3,
         del_extend/2]).

-export([init_role_data/2,
         reload_role_pinfo_list/2,
         persistent/1,
         erase_mission_data/1]).

-export([set_vs/1, get_vs/0]).
%%
%% API Functions
%%

reload()->
    
    lists:foreach(fun(Node) ->
        rpc:call(Node, mod_mission_data, code_build_mission_bin, [])                          
    end, [node()|nodes()]).

%% --------------------------------------------------------------------
%% 获取基础信息
%% --------------------------------------------------------------------
get_base_info(MissionID) ->
    ?MODULE_MISSION_DATA_DETAIL:get(MissionID).

%% --------------------------------------------------------------------
%% 获取某项配置信息
%% --------------------------------------------------------------------
get_setting(Key) ->
    ?MODULE_MISSION_DATA_SETTING:get(Key).

%%@doc 获取任务版本号
get_vs() ->
    case get(?MISSION_VS_DICT_KEY) of
        undefined ->
            VS = get_setting(data_version),
            put(?MISSION_VS_DICT_KEY, VS),
            VS;
        VS ->
            VS
    end.

%%@doc 设置一个新的任务版本号
set_vs(VS) ->
    put(?MISSION_VS_DICT_KEY, VS).        

%% --------------------------------------------------------------------
%% 通过玩家的key获取任务列表 - 该方法返回的任务数据还需要进一步判断权限
%% --------------------------------------------------------------------
get_list_by_key(Key) ->
    NoGroup = ?MODULE_MISSION_DATA_KEY_NO_GROUP:get(Key),
    GroupIDList = ?MODULE_MISSION_DATA_KEY_GROUP:get(Key),
    if
        GroupIDList =/= false ->
            Group = lists:map(fun(SmallGroup) ->
                get_group_random_one(SmallGroup)
            end, GroupIDList),
            NoGroup ++ Group;
        true ->
            NoGroup
    end.

%% --------------------------------------------------------------------
%% 随机获取分组里的一个任务
%% --------------------------------------------------------------------
get_group_random_one(MissionSmallGroup) ->
    ?MODULE_MISSION_DATA_DETAIL:get_group_random_one(MissionSmallGroup).

%% --------------------------------------------------------------------
%% 处理侦听器数据
%% --------------------------------------------------------------------
%% 设置侦听器列表
set_listener_list(RoleID, ListenerList) ->
    MissionData = get_mission_data(RoleID),
    NewMissionData = MissionData#mission_data{listener_list=ListenerList},
    set_mission_data(RoleID, NewMissionData).
%% 获取侦听器列表
get_listener_list(RoleID) ->
    (get_mission_data(RoleID))#mission_data.listener_list.

%%@param Type:1=怪物,2=道具
get_listener_key(Type, Value) ->
    {Type, Value}.

%% 获取单个大于条件的侦听器
get_listener_greate_than(RoleID, Type, Value) ->
    ListenerList = get_listener_list(RoleID),
    get_listener_greate_than_2(ListenerList,Type,Value).

get_listener_greate_than_2([],_Type,_Value)->
    false;
get_listener_greate_than_2([H|T],Type,Value)->
    case H of
        #mission_listener_trigger_data{key={Type, KeyValue}} when (Value>=KeyValue)->
            H;
        _ ->
            get_listener_greate_than_2(T,Type,Value)
    end.

%% 获取单个侦听器
get_listener(RoleID, Type, Value) ->
    ListenerList = get_listener_list(RoleID),
    Key = get_listener_key(Type, Value),
    lists:keyfind(Key, #mission_listener_trigger_data.key, ListenerList).
%% 删除任务侦听器
del_listener(RoleID, Type, Value) ->
    ListenerList = get_listener_list(RoleID),
    Key = get_listener_key(Type, Value),
    NewListenerList = lists:keydelete(
                       Key, 
                       #mission_listener_trigger_data.key, 
                       ListenerList),
    set_listener_list(RoleID, NewListenerList),
    NewListenerList.
%% 单条设置任务数据侦听器
set_listener(RoleID, ListenerData) ->   
    Type = ListenerData#mission_listener_trigger_data.type,
    Value = ListenerData#mission_listener_trigger_data.value,
    NewListenerList = del_listener(RoleID, Type, Value),
    set_listener_list(RoleID, [ListenerData|NewListenerList]).
%% 将某个任务加入到侦听器列表中
join_to_listener(RoleID, MissionID, Type, Value) ->
    ListenerData = get_listener(RoleID, Type, Value),
    if
        ListenerData =:= false ->
            Key = get_listener_key(Type, Value),
            NewListenerData = #mission_listener_trigger_data{
                key=Key,
                type=Type,
                value=Value,
                mission_id_list=[MissionID]
            };
        true ->
            MissionIDList = ListenerData#mission_listener_trigger_data.mission_id_list,
            Exists = lists:member(MissionID, MissionIDList),
            if
                Exists =:= false ->
                    NewListenerData = ListenerData#mission_listener_trigger_data{
                    mission_id_list=[MissionID|MissionIDList]};
                true ->
                    NewListenerData = ListenerData
            end
    end,
    set_listener(RoleID, NewListenerData).
%% 将某个任务从侦听器列表中移除
remove_from_listener(RoleID, MissionID, Type, Value) ->
    ListenerData = get_listener(RoleID, Type, Value),
    if
        ListenerData =:= false ->
            ignore;
        true ->
            MissionIDList = ListenerData#mission_listener_trigger_data.mission_id_list,
            UniqueMissionIDList = lists:delete(MissionID, MissionIDList),
            case UniqueMissionIDList of
                []->
                    del_listener(RoleID, Type, Value);
                _ ->
                    NewListenerData = 
                        ListenerData#mission_listener_trigger_data{ mission_id_list=UniqueMissionIDList},
                    set_listener(RoleID, NewListenerData)
            end
    end.

%%------
%% --------------------------------------------------------------------
%% 处理任务的计数器
%% --------------------------------------------------------------------
%% 获取计数器的counter的查询key
%% @return {KeyType,ID} KeyType=0表示普通任务,=1表示循环任务
get_counter_key(MissionID, 0) ->
    {0, MissionID};
get_counter_key(_MissionID, MissionBigGroup) ->
    {1, MissionBigGroup}.

%% 设置计数器整体数据(列表)
set_counter(RoleID, NewCounterList) ->
    MissionData = get_mission_data(RoleID),
    NewMissionData = MissionData#mission_data{counter_list=NewCounterList},
    set_mission_data(RoleID, NewMissionData).

%% 新建一个计数为 0 的counter record
new_zero_counter(MissionID, MissionBigGroup, LastClearCounterTime) ->
    Key = get_counter_key(MissionID, MissionBigGroup),
    #mission_counter{
        key=Key,
        id=MissionID,
        big_group=MissionBigGroup,
        last_clear_counter_time=LastClearCounterTime,
        commit_times=0,
        succ_times=0,
        other_data=null}.

%% 获取计数器 返回所有中间数据
get_counter_return_all(RoleID, MissionBaseInfo) ->
    MissionData = get_mission_data(RoleID),
    CounterListTmp = MissionData#mission_data.counter_list,
    MissionID = MissionBaseInfo#mission_base_info.id,
    MissionBigGroup = MissionBaseInfo#mission_base_info.big_group,
    
    Key = get_counter_key(MissionID, MissionBigGroup),
    case lists:keyfind(Key, #mission_counter.key, CounterListTmp) of
        false ->
            Now =calendar:local_time(),
            CounterData = new_zero_counter(MissionID, MissionBigGroup, Now),
            CounterList = CounterListTmp;
        CounterDataTmp ->
            CounterData = counter_reset_if_expire(MissionBaseInfo, CounterDataTmp),
            %%返回的数据去除命中的counter
            CounterList = lists:keydelete(Key, #mission_counter.key, CounterListTmp)
    end,
    {MissionData, CounterList, CounterData}.

%% 如果任务计数器过期则重置
counter_reset_if_expire(MissionBaseInfo,CounterData) ->
    TimeLimitType = MissionBaseInfo#mission_base_info.time_limit_type,
    if
        TimeLimitType =:= ?MISSION_TIME_LIMIT_NO ->
            CounterData;
        true ->
            MissionID = MissionBaseInfo#mission_base_info.id,
            MissionBigGroup = MissionBaseInfo#mission_base_info.big_group,
            LastClear = CounterData#mission_counter.last_clear_counter_time,
            Now = calendar:local_time(),
            Expire = check_counter_expire(TimeLimitType, Now, LastClear),
            
            if
                Expire =:= true ->
                    new_zero_counter(MissionID, MissionBigGroup, Now);
                true ->
                    CounterData
            end
    end.

%% 每天清零
check_counter_expire(?MISSION_TIME_LIMIT_DAILY, Now, LastClear) ->
    {NowDay, _NowTime} = Now,
    {LastClearDay, _} = LastClear,
    if
        LastClearDay =/= NowDay ->
            true;
        true ->
            false
    end;

%% 每周-x - 每周-y 清零
check_counter_expire(?MISSION_TIME_LIMIT_WEEK, Now, LastClear) ->
    {Diff, _} = calendar:time_difference(Now, LastClear),
    if
       Diff >= 7 ->
           true;
       true ->
           false
    end;

%% 每月-x - 每月-y 清零
check_counter_expire(?MISSION_TIME_LIMIT_MONTH, Now, LastClear) ->
    {{_, NowM, _}, _} = Now,
    {{_, ClearM, _}, _} = LastClear,
    if
       NowM =/= ClearM ->
           true;
       true ->
           false
    end;
%%指定时间内的循环任务
check_counter_expire(?MISSION_TIME_LIMIT_SOMEDAY,  Now, LastClear) ->
    {NowDay, _NowTime} = Now,
    {LastClearDay, _} = LastClear,
    if
        LastClearDay =/= NowDay ->
            true;
        true ->
            false
    end;
%%@doc 其他一律是不过期的
check_counter_expire(_, _, _) ->
    false.

%% 获取某个任务的计数器
%% @return #mission_counter{}
get_counter(RoleID, MissionBaseInfo) ->
   {_MissionData, _CounterList, CounterData} = 
       get_counter_return_all(RoleID, MissionBaseInfo),
   CounterData.

%%------
%% --------------------------------------------------------------------
%% 处理提交次数
%% --------------------------------------------------------------------
%% 获取某个任务提交次数
get_commit_times(RoleID, MissionBaseInfo) ->
    (get_counter(RoleID, MissionBaseInfo))#mission_counter.commit_times.

%%------
%% --------------------------------------------------------------------
%% 处理任务成功次数
%% --------------------------------------------------------------------
%% 获取某个任务成功次数
get_succ_times(RoleID, MissionBaseInfo) ->
    (get_counter(RoleID, MissionBaseInfo))#mission_counter.succ_times.
%% 设置某个任务成功次数
set_succ_times(RoleID, MissionBaseInfo, AddNum) ->
    {MissionData, CounterList, CounterData} = 
        get_counter_return_all(RoleID, MissionBaseInfo),
    
    CurrentCommitTimes = CounterData#mission_counter.commit_times,
    CurrentSuccTimes = CounterData#mission_counter.succ_times,
    if
        AddNum < 0 ->
            NewCounterData = CounterData#mission_counter{
                commit_times= -AddNum + CurrentCommitTimes};
        true ->
            NewCounterData = CounterData#mission_counter{
                commit_times= AddNum + CurrentCommitTimes,
                succ_times= AddNum + CurrentSuccTimes}
    end,
    NewCounterList = [NewCounterData|CounterList],
    NewMissionData = MissionData#mission_data{counter_list=NewCounterList},
    set_mission_data(RoleID, NewMissionData).

%%------
%% --------------------------------------------------------------------
%% 处理失败次数
%% --------------------------------------------------------------------
%% 获取失败次数
get_fail_times(RoleID, MissionBaseInfo) ->
    {_MissionData, _CounterList, CounterData} = get_counter_return_all(RoleID, MissionBaseInfo),
    CommitTimes = CounterData#mission_counter.commit_times,
    SuccTimes = CounterData#mission_counter.succ_times,
    CommitTimes - SuccTimes.
%% 设置失败次数
set_fail_times(RoleID, MissionBaseInfo, AddNum) ->
    set_succ_times(RoleID, MissionBaseInfo, -AddNum).

%%------
%% --------------------------------------------------------------------
%% 处理任务进程字典数据
%% --------------------------------------------------------------------
%% 初始化任务进程字典数据
init_role_data(RoleID, MissionData) ->
    TransFun = fun()-> 
                   set_mission_data(RoleID, MissionData),
                   RoleMissionDataVS = MissionData#mission_data.data_version,
                   VS = get_vs(),
                   if
                       RoleMissionDataVS =/= VS ->
                           NewPInfoList = reload_role_pinfo_list(RoleID, MissionData),
                           NewMissionData = MissionData#mission_data{data_version=VS, mission_list=NewPInfoList},
                           set_mission_data(RoleID, NewMissionData),
                           NewMissionData;
                       true ->
                           MissionData
                   end
               end,
    case common_transaction:transaction( TransFun ) of
        {atomic,_}->
            ok;
        Error->
            ?ERROR_MSG("RoleID=~w,MissionData=~w,Error=~w",[RoleID,MissionData,Error]),
            error
    end.

%%@doc 根据分组ID获取玩家对应的分组任务
%% 基于同一时间玩家只有一种分组ID的分组任务
get_mission_by_big_group(RoleID,BigGroup)->
    RoleMissionKey = mod_mission_data:get_role_mission_key(RoleID),
    %%获取新的任务ID列表
    MissionIDList = mod_mission_data:get_list_by_key(RoleMissionKey),
    get_mission_by_big_group2(MissionIDList,BigGroup).

get_mission_by_big_group2([],_)->
    undefined;
get_mission_by_big_group2([MissID|T],BigGroup)->
    case mod_mission_data:get_base_info(MissID) of
        #mission_base_info{big_group=BigGroup} = Mission ->
            Mission;
        _ ->
            get_mission_by_big_group2(T,BigGroup)
    end.

get_old_group_mission_list(RoleLevel,OldPInfoList)->
	lists:foldl(
	  fun(PInfo, AccIn) ->
			  MissionID = PInfo#p_mission_info.id,
			  #mission_base_info{big_group=BigGroup,min_level=MinLv,max_level=MaxLv} = 
									mod_mission_data:get_base_info(MissionID),
			  if
				  (BigGroup > 0) andalso (RoleLevel>=MinLv) andalso (MaxLv>=RoleLevel) ->
					  [{BigGroup, PInfo}|AccIn];
				  true ->
					  AccIn
			  end
	  end, [], OldPInfoList).

get_doing_mission_id_list(undefined)->
	[];
get_doing_mission_id_list([])->
	[];
get_doing_mission_id_list(OldPInfoList)->
	lists:foldl(
	  fun(E,AccIn)->
			  #p_mission_info{id=Id,current_status=Status,type=Type} = E,
			  case Status>?MISSION_STATUS_NOT_ACCEPT andalso Type=/=?MISSION_TYPE_LOOP of
				  true->
					  %%主线、支线、称号的已接任务，可以继续显示
					  [Id|AccIn];
				  _ ->
					  AccIn
			  end
	  end,[],OldPInfoList).

%%@doc 重load 玩家任务数据
reload_role_pinfo_list(RoleID, MissionData) ->
	case mod_map_role:get_role_attr(RoleID) of
		{ok,#p_role_attr{level=RoleLevel}}->
			OldPInfoList = MissionData#mission_data.mission_list,
			OldGroupMissionList = get_old_group_mission_list(RoleLevel,OldPInfoList),
			RoleMissionKey = mod_mission_data:get_role_mission_key(RoleID),
			%%获取新的任务ID、当前的任务ID列表
			NewMissIDList = mod_mission_data:get_list_by_key(RoleMissionKey),
			DoingMissIDList = get_doing_mission_id_list(OldPInfoList),
			MissionIDList = lists:merge(NewMissIDList, DoingMissIDList),
			reload_role_pinfo_list_2(RoleID,MissionIDList,OldPInfoList,OldGroupMissionList);
		{error,Reason} ->
			{error,Reason}
	end.

reload_role_pinfo_list_2(RoleID,MissionIDList,OldPInfoList,OldGroupMissionList)->
	lists:foldl(
	  fun(MissionID, AccIn)-> 
			  #mission_base_info{big_group=BigGroup} = mod_mission_data:get_base_info(MissionID),
              case lists:keyfind(BigGroup,1,AccIn) of
				  false ->
					  case lists:keyfind(BigGroup, 1, OldGroupMissionList) of
						  {_, OldPInfo} ->
							  ok;
						  _ ->
							  OldPInfo =lists:keyfind(MissionID, #p_mission_info.id, OldPInfoList)
					  end,
					  case b_mission_model:call_mission_model(RoleID, MissionID, init_pinfo, [OldPInfo]) of
						  false ->
							  AccIn;
						  #p_mission_info{id=ID}=NewPInfo ->
							  case lists:keymember(ID, #p_mission_info.id, AccIn) of
								  true->
									  AccIn;
								  _ ->		
									  [NewPInfo|AccIn]
							  end
					  end;
				  _ ->
					  AccIn
			  end
	  end, [], MissionIDList).

%%@doc 设置任务进程字典数据
%%必须放在mision_transaction内才能调用！
set_mission_data(RoleID, MissionData) when is_record(MissionData,mission_data) ->
    case common_mission:is_in_transaction() of
        true->
            put(?MISSION_DATA_DICT_KEY_COPY(RoleID), MissionData),
            update_role_id_list_in_transaction(RoleID);
        _ ->
            throw({not_in_common_transaction})
    end.


%% 获取任务进程字典数据
get_mission_data(RoleID) ->
    Result = 
    case common_mission:is_in_transaction() of
        true->
            case get(?MISSION_DATA_DICT_KEY_COPY(RoleID)) of
                undefined->
                    KeyError = 1,
                    erlang:get(?MISSION_DATA_DICT_KEY(RoleID));
                Data->
                    KeyError = 2,
                    Data
            end;
        _ ->
            KeyError = 3,
            erlang:get(?MISSION_DATA_DICT_KEY(RoleID))
    end,
    
    if
        Result =:= undefined ->
            catch print_error(KeyError,RoleID),
            Result;
        true ->
            Result
    end.
%% 检查玩家任务数据
%% 返回 {ok,UseItemInfoTuple} or {error,nod_found}
%% UseItemInfoTuple=#mission_status_data_use_item
get_mission_item_use_point(RoleId,UseItemId) ->
    #mission_data{mission_list = CurMissionList} = get_mission_data(RoleId),
    case lists:foldl(
           fun(Mission,AccUseItemPointTuple) -> 
                   case AccUseItemPointTuple =:= undefined 
                            andalso (Mission#p_mission_info.model =:= ?MISSION_MODEL_16 
                                     orelse Mission#p_mission_info.model =:= ?MISSION_MODEL_17
                                     orelse Mission#p_mission_info.model =:= ?MISSION_MODEL_18) of
                       true ->
                           MissionBaseInfo = mod_mission_data:get_base_info(Mission#p_mission_info.id),
                           ModelStatusData = lists:nth(Mission#p_mission_info.current_model_status + 1,MissionBaseInfo#mission_base_info.model_status_data),
                           case lists:foldl(
                                  fun(MissionStatusDataUseItemInfo,AccUseItemPointFlag) -> 
                                          case AccUseItemPointFlag =:= undefined 
                                              andalso MissionStatusDataUseItemInfo#mission_status_data_use_item.item_id =:= UseItemId of
                                              true ->
                                                  MissionStatusDataUseItemInfo;
                                              _ ->
                                                  AccUseItemPointFlag
                                          end
                                  end, undefined, ModelStatusData#mission_status_data.use_item_point_list) of
                               undefined ->
                                   AccUseItemPointTuple;
                               UseItemPointTupleT ->
                                   UseItemPointTupleT
                           end;
                       _ ->
                           AccUseItemPointTuple
                   end
           
           end, undefined, CurMissionList) of
        undefined ->
            {error,not_found};
        UseItemPointTuple ->
            {ok,UseItemPointTuple}
    end.
print_error(KeyError,RoleID)->
    MapState = mgeem_map:get_state(),
    ?ERROR_MSG("相当严重，玩家的进程字典中找不到任务数据:KeyError=~w,RoleID=~w,MapState=~w,Stack:~w", 
               [KeyError,RoleID,MapState,erlang:get_stacktrace()]),
    ok.
    

%% --------------------------------------------------------------------
%% 操作任务列表
%% --------------------------------------------------------------------

%%@doc 获取代理任务列表
%%@return [#r_role_mission_auto{}]
get_role_auto_list(RoleID)->
    MissionData = get_mission_data(RoleID),
    MissionData#mission_data.auto_list.

set_role_auto_list(RoleID,AutoList) when is_list(AutoList)->
    MissionData = get_mission_data(RoleID),
    NewMissionData = MissionData#mission_data{auto_list=AutoList},
    set_mission_data(RoleID,NewMissionData).

%% 设置任务列表和新的版本号
%%@param MissionList:list() [#p_mission_info]
set_pinfo_list(RoleID, MissionList, NewDataVersion)->
    MissionData = get_mission_data(RoleID),
    NewMissionData = MissionData#mission_data{mission_list=MissionList,data_version=NewDataVersion},
    set_mission_data(RoleID, NewMissionData).
                                             
%% 设置任务列表
%%@param MissionList:list() [#p_mission_info]
set_pinfo_list(RoleID, MissionList) ->
    MissionData = get_mission_data(RoleID),
    NewMissionData = MissionData#mission_data{mission_list=MissionList},
    set_mission_data(RoleID, NewMissionData).
%% 获取任务列表
get_pinfo_list(RoleID) ->
    MissionData = get_mission_data(RoleID),
    MissionData#mission_data.mission_list.

%% 获取单条任务数据
get_pinfo(RoleID, MissionID) ->
    MissionList = get_pinfo_list(RoleID),
    lists:keyfind(MissionID, #p_mission_info.id, MissionList).

%% 删除任务 伴随通知
del_pinfo(RoleID, MissionID, notify) ->
    mod_mission_unicast:p_update_unicast(del, RoleID, MissionID),
    del_pinfo(RoleID, MissionID).
%% 删除任务 不通知
del_pinfo(RoleID, MissionID) ->
    PinfoList = get_pinfo_list(RoleID),
    NewPinfoList = lists:keydelete(MissionID, #p_mission_info.id, PinfoList),
    set_pinfo_list(RoleID, NewPinfoList),
    NewPinfoList.
%% 单条设置任务数据 伴随通知
set_pinfo(RoleID, PInfo, notify) when is_record(PInfo,p_mission_info) -> 
    mod_mission_unicast:p_update_unicast(update, RoleID, PInfo), 
    set_pinfo(RoleID, PInfo).
%% 单条设置任务数据 不通知
set_pinfo(RoleID, PInfo) when is_record(PInfo,p_mission_info) ->   
    MissionID = PInfo#p_mission_info.id,
    NewPinfoList = del_pinfo(RoleID, MissionID),
    set_pinfo_list(RoleID, [PInfo|NewPinfoList]).

%% --------------------------------------------------------------------
%% 处理扩展数据
%% --------------------------------------------------------------------
%% 设置扩展数据
set_extend_list(RoleID, ExtendList) ->
    MissionData = get_mission_data(RoleID),
    NewMissionData = MissionData#mission_data{extend_list=ExtendList},
    set_mission_data(RoleID, NewMissionData).
%%@doc 获取扩展数据列表
get_extend_list(RoleID) ->
    MissionData = get_mission_data(RoleID),
    MissionData#mission_data.extend_list.
%%@doc 获取单条扩展数据
get_extend(RoleID, Key) ->
    ExtendList = get_extend_list(RoleID),
    lists:keyfind(Key, #mission_data_extend.key, ExtendList).
%%@doc 设置单条扩展数据
set_extend(RoleID, Key, Data) ->
    ExtendList = get_extend_list(RoleID),
    UniqueList = lists:keydelete(Key, #mission_data_extend.key, ExtendList),
    ExtendData = #mission_data_extend{key=Key, extend_data=Data},
    set_extend_list(RoleID, [ExtendData|UniqueList]).
%%@doc 删除单挑扩展数据
del_extend(RoleID, Key) ->
    ExtendList = get_extend_list(RoleID),
    DelList = lists:keydelete(Key, #mission_data_extend.key, ExtendList),
    set_extend_list(RoleID, DelList).

%% --------------------------------------------------------------------
%% 生成任务数据的erlang bin object
%% --------------------------------------------------------------------
code_build_mission_bin() ->
    
    MissionDataDir = common_config:get_mission_file_path(),
    MissionSettingList = common_config:get_mission_setting(),
    code_create_setting_module(MissionSettingList, ?MODULE_MISSION_DATA_SETTING),
    
    FileListFun = 
        fun(FileName, {NoGroupKeyList, GroupKeyList, MissionList}) ->
                ?ERROR_MSG("-----Load mission data-----~p", [FileName]),
                case filename:extension(FileName) of
                    ".detail" ->%%任务详细信息
                        {ok, MissionList2} = file:consult(MissionDataDir ++ FileName),
                        {NoGroupKeyList, GroupKeyList, MissionList2++MissionList};
                    ".nogroup_keyto" ->%%没分组的key==>任务ID
                        {ok, NoGroupKeyList2} = file:consult(MissionDataDir ++ FileName),
                        NoGroupKeyList3 = code_filter_list(NoGroupKeyList, NoGroupKeyList2),
                        {NoGroupKeyList3, GroupKeyList, MissionList};
                    ".group_keyto" ->%%有分组的key==>分组ID
                        {ok, GroupKeyList2} = file:consult(MissionDataDir ++ FileName),
                        GroupKeyList3 = code_filter_list(GroupKeyList, GroupKeyList2),
                        {NoGroupKeyList, GroupKeyList3, MissionList};
                    _ ->
                        {NoGroupKeyList, GroupKeyList, MissionList}
                end
        end,

    case file:list_dir(MissionDataDir) of
        {ok, FileList} ->
            {NoGroupKeyList, GroupKeyList, MissionList} = lists:foldl(FileListFun, {[], [], []}, FileList),
            %%没有分组的任务 一个key对应多个任务
            {module, ModuleNameKeyNoGroup} = code_create_key_module(NoGroupKeyList, ?MODULE_MISSION_DATA_KEY_NO_GROUP),
            %%分组的任务 一个key对应多个组 获取任务时实际是从每个组里随机取一条
            {module, ModuleNameKeyGroup} = code_create_key_module(GroupKeyList, ?MODULE_MISSION_DATA_KEY_GROUP),
            {module, ModuleNameDetail} = code_create_detail_module(MissionList, ?MODULE_MISSION_DATA_DETAIL),
            {ModuleNameKeyNoGroup, ModuleNameKeyGroup, ModuleNameDetail};
        _ ->
            exit(killed)
    end.
  
%% --------------------------------------------------------------------
%% 生成任务详细信息的查询模块
%% --------------------------------------------------------------------
code_create_detail_module(MissionList, ModuleNameTmp) ->
    ModuleName = erlang:atom_to_list(ModuleNameTmp),
    {CodeSrc, GroupList} =
    lists:foldl(fun(MissionBaseInfo, {CodeSrc2, GroupList2}) ->
       MissionID = MissionBaseInfo#mission_base_info.id,
       SmallGroup = MissionBaseInfo#mission_base_info.small_group,
       if
            SmallGroup =/= 0 ->
                GroupList3 = code_filter_list(GroupList2, [{SmallGroup, MissionID}]);
            true ->
                GroupList3 = GroupList2
       end,
       CodeSrc3 = CodeSrc2 ++ io_lib:format("~nget(~w) -> ~w;", [MissionID, MissionBaseInfo]),
       {CodeSrc3, GroupList3}
    end, {"", []}, MissionList), 
    
    {CodeSrc4, CodeSrc5} =
    lists:foldl(fun({SmallGroup, MissionIDList}, {CodeSrc6, CodeSrc7}) ->
                        
       CodeSrc8 = CodeSrc6 ++ io_lib:format(
         "~nget_group(~w) -> lists:map(fun(MissionID) -> "++ModuleName++":get(MissionID) end, ~w);",
         [SmallGroup, MissionIDList]),
       
       CodeSrc9 = CodeSrc7 ++ io_lib:format("~nget_group_random_one(~w) ->~n
            List = ~w, ~n
            random:seed(erlang:now()), ~n
            N = random:uniform(erlang:length(List)), ~n
            lists:nth(N, List);",
            %%"++ModuleName++":get(lists:nth(N, List));",
         [SmallGroup, MissionIDList]),
        {CodeSrc8, CodeSrc9}
    end, {"", ""}, GroupList),  
    
    CodeSrc10 = io_lib:format(?MISSION_DATA_DETAIL_HEADER(ModuleName), [CodeSrc, CodeSrc4, CodeSrc5]),
    
    {Mod, Code} = dynamic_compile:from_string(lists:flatten(CodeSrc10)),
    code:load_binary(Mod, ModuleName++".erl", Code).
 
%% --------------------------------------------------------------------
%% 生成任务key查询一级KEY的代码
%% -------------------------------------------------------------------- 
code_create_key_module(KeyList, ModuleNameTmp) -> 
    ModuleName = erlang:atom_to_list(ModuleNameTmp),
    CodeSrc =
    lists:foldl(fun({Key, IDList}, CodeSrc2) -> 
        CodeSrc2 ++ io_lib:format("~nget(~w) -> ~w;", [Key, IDList])
    end, "", KeyList),
    CodeSrc3 = io_lib:format(?MISSION_DATA_KEY_HEADER(ModuleName), [CodeSrc]),
    {Mod, Code} = dynamic_compile:from_string(lists:flatten(CodeSrc3)),
    code:load_binary(Mod, ModuleName++".erl", Code).

%% --------------------------------------------------------------------
%% 生成任务配置代码
%% -------------------------------------------------------------------- 
code_create_setting_module(SettingList, ModuleNameTmp) ->
    ModuleName = erlang:atom_to_list(ModuleNameTmp),
    CodeSrc =
    lists:foldl(fun({Key, Data}, CodeSrc2) -> 
        CodeSrc2 ++ io_lib:format("~nget(~w) -> ~w;", [Key, Data])
    end, "", SettingList),
    CodeSrc3 = io_lib:format(?MISSION_DATA_KEY_HEADER(ModuleName), [CodeSrc]),
    {Mod, Code} = dynamic_compile:from_string(lists:flatten(CodeSrc3)),
    code:load_binary(Mod, ModuleName++".erl", Code).
    

%% --------------------------------------------------------------------
%% 因为任务数据是分多个文件的 所以读取到以后要用这个函数做下合并
%% 将相同key的任务ID或者分组ID归档即相同KEY的放进同一个列表里
%% -------------------------------------------------------------------- 
code_filter_list(CurrentKeyList, KeyList) ->
    lists:foldl(fun({Key, ID}, Result) ->
        case lists:keyfind(Key, 1, Result) of
            false ->
                [{Key, [ID]}|Result];
            {Key, List} ->
                ResultUnique = lists:keydelete(Key, 1, Result),
                UniqueList = lists:delete(ID, List),
                [{Key, [ID|UniqueList]}|ResultUnique]
        end
    end, CurrentKeyList, KeyList).

%% --------------------------------------------------------------------
%% 持久化任务
%% -------------------------------------------------------------------- 
persistent(RoleID) ->
    MissionData = get_mission_data(RoleID),
    if
        MissionData =:= undefined ->
            ignore;
        true ->
            MissionStoreTime = MissionData#mission_data.last_store_time,
            MissionStoreDiff = common_tool:now() - MissionStoreTime,
            if
                %%错开10秒 让玩家分批持久化
                MissionStoreDiff >= ?MISSION_PERSISTENT_TIME ->
                    mgeem_persistent:mission_data_persistent(RoleID, MissionData);
                true ->
                    ignore
            end
    end.

erase_mission_data(RoleID) ->
    erlang:erase(?MISSION_DATA_DICT_KEY(RoleID)).

%%@doc 获取玩家对应的mission_key
get_role_mission_key(RoleID) ->
    {ok, #p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
    {ok, #p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    
    RoleLevelKey = common_tool:ceil(RoleLevel/?MISSION_KEY_LEVEL_RANGE),
    {RoleLevelKey, FactionID}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
update_role_id_list_in_transaction(RoleID)->
    RoleIDList = erlang:get(?MISSION_ROLE_IDLIST_IN_TRANSACTION),
    case lists:member(RoleID, RoleIDList) of
        true ->
            ignore;
        _ ->
            put(?MISSION_ROLE_IDLIST_IN_TRANSACTION, [RoleID|RoleIDList])
    end.

%%%===================================================================
%%% 获取状态数据
%%%===================================================================
get_status_data(Status, MissionBaseInfo) ->
    StatusDataList = MissionBaseInfo#mission_base_info.model_status_data,
    %%/状态是从0开始计数的 所以要+1
    lists:nth(Status+1, StatusDataList).