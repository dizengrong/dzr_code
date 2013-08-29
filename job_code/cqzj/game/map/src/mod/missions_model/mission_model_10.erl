%% Author: chixiaosheng
%% Created: 2011-4-5
%% Description: 刺探模型
-module(mission_model_10, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  
%%[蚩尤,神农,轩辕]
-record(mission_citan_extend_data, {last_clear, choose_list={0,0,0}}).
-define(MISSION_MODEL_10_STATUS_DOING, 1).
-define(MISSION_MODEL_10_STATUS_FINISH, 2).

%%
%% Exported Functions
%%
-export([
         auth_accept/1,
         auth_show/1,
         do/2,
         cancel/2,
         listener_trigger/3,
         init_pinfo/1]).

%%
%% API Functions
%%
%%@doc 验证是否可接
%%@return  true | {false, ReasonCode, ReasonIntData}
auth_accept(_PInfo) -> 
    Auth = mod_mission_auth:auth_accept(RoleID, MissionBaseInfo),
    if
        Auth =:= true ->
            {_, {H, _, _}} = calendar:local_time(),
            if
                H > 1 andalso H < 12 ->
                    {false, ?MISSION_CODE_AUTHFAIL_TIME_LIMIT, []};
                true ->
                    true
            end;
        true ->
            Auth
    end.

%%@doc 验证是否可以出现在任务列表
%%@return  true | {false, ReasonCode, ReasonIntData}
auth_show(_PInfo) -> 
    Auth = mod_mission_auth:auth_show(RoleID, MissionBaseInfo),
    if
        Auth =:= true ->
            {_, {H, _, _}} = calendar:local_time(),
            if
                H > 1 andalso H < 12 ->
                    {false, ?MISSION_CODE_AUTHFAIL_TIME_LIMIT, []};
                true ->
                    true
            end;
        true ->
            Auth
    end.

%%@doc 执行任务 接-做-交
do(PInfo, RequestRecord) ->
    TransFun = fun() ->
                       CurrentModelStatus = PInfo#p_mission_info.current_model_status,
                       do_citan(CurrentModelStatus, PInfo, RequestRecord)
               end,
    ?DO_TRANS_FUN( TransFun ).

do_citan(?MISSION_MODEL_STATUS_FIRST, PInfo, RequestRecord) ->
    {ok, #p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
    case mod_spy:get_spy_faction_state(FactionID) of
        {ok, in_spy_faction} ->
            IsFactionType = 1;
        _ ->
            IsFactionType = 0
    end,
    
    [ChooseNPCID] = RequestRecord#m_mission_do_tos.int_list_1,
    ChooseFactionID = ChooseNPCID div 1000000 rem 10,
    
    %%{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    %%RoleSelfFactionID = RoleBase#p_role_base.faction_id,
    if
        %%RoleSelfFactionID =:= ChooseFactionID
            %%orelse
            ChooseFactionID =/= 1 
            andalso 
            ChooseFactionID =/= 2 
            andalso 
            ChooseFactionID =/= 3 ->
            throw({?MISSION_ERROR_MAN, 
                   ?MISSION_CODE_FAILE_CITAN_CHOOSE_A_FACTION, 
                   [ChooseFactionID]});
        true ->
            ignore
    end,
    GoFactionData = get_citan_go_faction_data(),
    ChooseTupleList = GoFactionData#mission_citan_extend_data.choose_list,
    ChooseTimes = erlang:element(ChooseFactionID, ChooseTupleList),
    MaxDoTimes = MissionBaseInfo#mission_base_info.max_do_times,
    HalfTime = MaxDoTimes div 2,
    if
        ChooseTimes >= HalfTime ->
            throw({?MISSION_ERROR_MAN, 
                   ?MISSION_CODE_FAILE_CITAN_CHOOSE_A_FACTION_LIMIT, 
                   [ChooseFactionID]});
        true ->
            ignore
    end,
    %%这里虽然保存了已经选择了的国家列表
    %%但当该任务不能接时会被从列表里移除 所以不能作为保存依据
    NewPInfo = PInfo#p_mission_info{int_list_2=[ChooseNPCID], int_list_3=[IsFactionType]},
    mission_model_common:common_do(RoleID, MissionID, MissionBaseInfo, RequestRecord, NewPInfo);

do_citan(?MISSION_MODEL_10_STATUS_DOING, PInfo, RequestRecord) ->
    [ChooseNPCID] = PInfo#p_mission_info.int_list_2,
    NPCID = RequestRecord#m_mission_do_tos.npc_id,
    if
        ChooseNPCID =/= NPCID ->
            ?ERROR_MSG("~ts:RoleID:~w, ChooseNPCID:~w, NPCID:~w", ["坑爹啦！！！有外挂啊！！玩家做刺探任务时居然能找不是自己选择的NPC对话", RoleID, ChooseNPCID, NPCID]),
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_SYS, [ChooseNPCID]});
        true ->
            ignore
    end,
    mission_model_common:common_do(RoleID, MissionID, MissionBaseInfo, RequestRecord, PInfo);



do_citan(?MISSION_MODEL_10_STATUS_FINISH, PInfo, RequestRecord) ->
    [ChooseNPCID] = PInfo#p_mission_info.int_list_2,
    ChooseFactionID = ChooseNPCID div 1000000 rem 10,
    
    [PinfoIsFactionType] = PInfo#p_mission_info.int_list_3,
    
    {ok, #p_role_base{faction_id=RoleFactionID}} = mod_map_role:get_role_base(RoleID),
    case mod_spy:get_spy_faction_state(RoleFactionID) of
        {ok, in_spy_faction} ->
            IsFactionType = 1;
        _ ->
            IsFactionType = 0
    end,
    
    GoFactionData = get_citan_go_faction_data(),
    ChooseTupleList = GoFactionData#mission_citan_extend_data.choose_list,
    ChooseTimes = erlang:element(ChooseFactionID, ChooseTupleList),
    NewChooseTupleList = erlang:setelement(ChooseFactionID, ChooseTupleList, ChooseTimes+1),
    NewGoFactionData = GoFactionData#mission_citan_extend_data{choose_list=NewChooseTupleList},
    mod_mission_data:set_extend(RoleID, ?MISSION_EXTEND_DATA_KEY_CI_TAN, NewGoFactionData),
    ChooseList = erlang:tuple_to_list(NewChooseTupleList),
    
    SuccTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
    NewSuccTimes = SuccTimes+1,
    
    CitanRewardList = mod_mission_data:get_setting(citan_reward),
    Level = PInfo#p_mission_info.accept_level,
    {Level, Exp, SilverBind, SpyExp, SpySilverBind, Prestige, SpyPrestige} = lists:keyfind(Level, 1, CitanRewardList),
    
    if
        PinfoIsFactionType =:= 1 andalso IsFactionType =:= 1 ->
            UseExp = SpyExp,
            UsePrestige = Prestige,
            UseSilverBind = SpySilverBind;
        true ->
            UseExp = Exp,
            UsePrestige = SpyPrestige,
            UseSilverBind = SilverBind
    end,
    
    BaseRewardData = #mission_reward_data{rollback_times=1,
                                          prop_reward_formula=?MISSION_PROP_REWARD_FORMULA_ALL,
                                          attr_reward_formula=?MISSION_ATTR_REWARD_FORMULA_NORMAL,
                                          exp=UseExp*NewSuccTimes,
                                          prestige=UsePrestige,
                                          silver=0,
                                          silver_bind=UseSilverBind*NewSuccTimes,
                                          prop_reward=[]},
    
    %% 从这里开始 代码有严格的顺序要求 fuck!!!
    
    NewMissionBaseInfo = MissionBaseInfo#mission_base_info{reward_data=BaseRewardData},
    Result = mission_model_common:common_complete(RoleID, MissionID,  NewMissionBaseInfo, RequestRecord),
    
    %% 成就 add by caochuncheng 2011-03-08
    if IsFactionType =:= 1 ->
           Func = {func,fun()->  
                                catch mod_accumulate_exp:role_do_spy(RoleID),
                                %% 增加刺探的日志记录
                                FailTimes = mod_mission_data:get_fail_times(RoleID, MissionBaseInfo),
                                catch common_loop_mission_logger:log_guotan( {RoleID,1,NewSuccTimes,FailTimes} )
                   end};
       true ->
           Func = {func,fun()->  
                                catch mod_accumulate_exp:role_do_spy(RoleID),
                                %% 增加刺探的日志记录
                                FailTimes = mod_mission_data:get_fail_times(RoleID, MissionBaseInfo),
                                catch common_loop_mission_logger:log_citan( {RoleID,1,NewSuccTimes,FailTimes} )
                   end}
    end,
    mod_mission_misc:push_trans_func(RoleID,Func),
    
    NewPInfo = mod_mission_data:get_pinfo(RoleID, MissionID),
    if
        NewPInfo =:= false ->
            ignore;
        true ->
            NewPInfo2 = NewPInfo#p_mission_info{int_list_1=ChooseList, int_list_2=[]},
            mod_mission_data:set_pinfo(RoleID, NewPInfo2)
    end,
    Result.


%%@doc 获取是否为国探
get_faction_type(RoleID)->
    {ok, #p_role_base{faction_id=RoleFactionID}} = mod_map_role:get_role_base(RoleID),
    case mod_spy:get_spy_faction_state(RoleFactionID) of
        {ok, in_spy_faction} ->
            1;
        _ ->
            0
    end.

%%获取玩家去了某个国家的次数
get_citan_go_faction_data() ->
    ExtendDataRecord = mod_mission_data:get_extend(RoleID, ?MISSION_EXTEND_DATA_KEY_CI_TAN),
    {Now, _} = calendar:local_time(),
    
    if
        ExtendDataRecord =:= false ->
            #mission_citan_extend_data{last_clear=Now};
        true ->
            ExtendData = ExtendDataRecord#mission_data_extend.extend_data,
            LastClear = ExtendData#mission_citan_extend_data.last_clear,
            {Now, _} = calendar:local_time(),
            if
                Now =/= LastClear ->
                    #mission_citan_extend_data{last_clear=Now};
                true ->
                    ExtendData
            end
    end.

%%@doc 取消任务
cancel(PInfo, RequestRecord) ->
    TransFun = fun() ->
                       mission_model_common:common_cancel(RoleID, MissionID, MissionBaseInfo,RequestRecord, PInfo)
               end,
    TransResult = ?DO_TRANS_FUN( TransFun ),
    case TransResult of
        {atomic, _}->
            SuccTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
            FailTimes = mod_mission_data:get_fail_times(RoleID, MissionBaseInfo),
            case get_faction_type(RoleID) of
                1->
                    catch common_loop_mission_logger:log_guotan( {RoleID,3,SuccTimes,FailTimes} );
                _ ->
                    catch common_loop_mission_logger:log_citan( {RoleID,3,SuccTimes,FailTimes} )
            end;
        _ ->
            ignore
    end,
    TransResult.

%%@doc 侦听器触发
listener_trigger(_ListenerData, _PInfo,_TriggerParam) -> ok.

%%@doc 初始化任务pinfo
%%@return #p_mission_info{} | false
init_pinfo(OldPInfo) -> 
    NewPInfo = mission_model_common:init_pinfo(RoleID, OldPInfo, MissionBaseInfo),
    CurrentStatus = NewPInfo#p_mission_info.current_model_status,
    GoFactionData = get_citan_go_faction_data(),
    ChooseTupleList = GoFactionData#mission_citan_extend_data.choose_list,
    ChooseList = erlang:tuple_to_list(ChooseTupleList),
    
    if
        CurrentStatus =/= ?MISSION_MODEL_STATUS_FIRST ->
            NewPInfo#p_mission_info{int_list_1=ChooseList};
        true ->
            case auth_show(NewPInfo) of
                true->
                    NewPInfo#p_mission_info{int_list_1=ChooseList};
                _ ->
                    false
           end
    end.
