%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     宗族技能、宗族BUFF模块
%%%     注意:: 该模块属于mod_family的子模块，只能在mod_family中被调用！
%%% @end
%%% Created : 2011-03-01
%%%-------------------------------------------------------------------
-module(mod_family_skill).
-include("mgeew.hrl").
-include("mgeew_family.hrl").

%% API
-export([do_handle_info/1]).
-export([msg_tag/0]).
-export([delete_family_skill/1]).

msg_tag()->
    [fetch_family_buff_result].

%% ====================================================================
%% API functions
%% ====================================================================


%%研究宗族技能
do_handle_info({Unique, ?FMLSKILL, ?FMLSKILL_RESEARCH, Record, RoleID, _PID, Line}) ->
    do_fmlskill_research({Unique, ?FMLSKILL, ?FMLSKILL_RESEARCH, Record, RoleID, _PID, Line});
%%遗忘宗族技能
do_handle_info({Unique, ?FMLSKILL, ?FMLSKILL_FORGET, Record, RoleID, _PID, Line}) ->
    do_fmlskill_forget({Unique, ?FMLSKILL, ?FMLSKILL_FORGET, Record, RoleID, _PID, Line});
%%获取（已研究的）宗族技能
do_handle_info({Unique, ?FMLSKILL, ?FMLSKILL_LIST, Record, RoleID, _PID, Line}) ->
    do_fmlskill_list({Unique, ?FMLSKILL, ?FMLSKILL_LIST, Record, RoleID, _PID, Line});
%%获取宗族BUFF列表
do_handle_info({Unique, ?FMLSKILL, ?FMLSKILL_LIST_BUFF, Record, RoleID, _PID, Line}) ->
    do_fmlskill_list_buff({Unique, ?FMLSKILL, ?FMLSKILL_LIST_BUFF, Record, RoleID, _PID, Line});
%%领取宗族BUFF
do_handle_info({Unique, ?FMLSKILL, ?FMLSKILL_FETCH_BUFF, Record, RoleID, _PID, Line}) ->
    do_fmlskill_fetch_buff({Unique, ?FMLSKILL, ?FMLSKILL_FETCH_BUFF, Record, RoleID, _PID, Line});
%%执行领取宗族BUFF的结果
do_handle_info({fetch_family_buff_result,IsSuccess,Request}) ->
    do_fetch_family_buff_result(IsSuccess,Request);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知信息", Info]).


%%@doc 解散宗族的时候，删除宗族已研究的宗族技能
delete_family_skill(FamilyID)->
    MatchHead = #r_family_skill_research{research_key='$1', family_id=FamilyID, _='_' },
    Guard = [],
    Result = ['$1'],
    
    TransFun = 
        fun() ->
                FamilySkills = db:select(?DB_FAMILY_SKILL_RESEARCH,[{MatchHead, Guard, Result}]),
                case FamilySkills of
                    []->
                        ignore;
                    _ ->
                        ?INFO_MSG("FamilySkills=~w",[FamilySkills]),
                        lists:foreach(fun(Key)->
                                              db:delete(?DB_FAMILY_SKILL_RESEARCH,Key,write)
                                      end, FamilySkills)
                end,
                ok
        end,
    case db:transaction(TransFun) of
        {atomic, ok} ->
            ok;
        {aborted, Reason} ->
            ?ERROR_MSG_STACK("do_learn_family_skill",Reason),
            {error,Reason}
    end.


%% ====================================================================
%% Internal functions
%% ====================================================================


%%@interface 显示宗族BUFF的列表
do_fmlskill_list_buff({Unique, Module, Method, _Record, RoleID, _PID, Line})->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    #p_family_info{level=FamilyLevel} = FamilyInfo,
    if
        FamilyLevel<1 ->
            ?SEND_ERR_TOC(m_fmlskill_list_buff_toc,<<"必须升级到1级宗族才能领取宗族技能福利。">>);
        true->
            BuffLevel = do_get_buff_level(FamilyLevel),
            List1 = common_config_dyn:list(family_buff),
            BuffList2 = [ #p_fml_buff{fml_buff_id=FmlBuffID,level=BuffLevel} ||{FmlBuffID,_}<-List1 ],

            IsFetched = not mod_family:is_today_not_parttake(RoleID,fetch_buff),

            R2 = #m_fmlskill_list_buff_toc{succ=true,buffs=BuffList2,is_fetched=IsFetched},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R2)
    end.

%%获取宗族等级对应的宗族BUFF等级
do_get_buff_level(FamilyLevel) when (FamilyLevel>=6)->
    3;
do_get_buff_level(FamilyLevel) when (FamilyLevel>=3)->
    2;
do_get_buff_level(FamilyLevel) when (FamilyLevel>=1)->
    1.


%%@interface 领取宗族BUFF
do_fmlskill_fetch_buff({Unique, Module, Method, Record, RoleID, _PID, Line})->
    #m_fmlskill_fetch_buff_tos{fml_buff_id=FmlBuffID} = Record,
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    #p_family_info{level=FamilyLevel} = FamilyInfo,
    if
        FamilyLevel<1 ->
            ?SEND_ERR_TOC(m_fmlskill_fetch_buff_toc,<<"必须升级到1级宗族才能领取宗族技能福利。">>);
        true->
            case mod_family:is_today_not_parttake(RoleID,fetch_buff) of
                true->
                    do_fmlskill_fetch_buff_2({Unique, Module, Method, RoleID, Line},FmlBuffID,FamilyLevel);
                _ ->
                    ?SEND_ERR_TOC(m_fmlskill_fetch_buff_toc,<<"每天只能领取一次宗族技能状态！">>)
            end
    end.

do_fmlskill_fetch_buff_2({Unique, Module, Method, RoleID, Line},FmlBuffID,FamilyLevel)->
    BuffLevel = do_get_buff_level(FamilyLevel),
    [FmlBuffList] = common_config_dyn:find(family_buff,FmlBuffID),
    #r_family_buff{need_family_contribute=NeedFamilyConb} = lists:keyfind(BuffLevel,#r_family_buff.buff_level,FmlBuffList),
    
    %%判断宗族贡献度
    CurConb = mod_family:get_contribution(RoleID),
    case CurConb>=NeedFamilyConb of
        true->
            %%先扣除贡献度
            mod_family:do_add_contribution(RoleID,-NeedFamilyConb),
            mgeer_role:absend(RoleID, {mod_map_family,{fetch_family_buff,self(),RoleID,FmlBuffID,BuffLevel}});
        _ ->
            ?SEND_ERR_TOC(m_fmlskill_fetch_buff_toc,<<"你的宗族贡献度不足，请通过参加宗族活动获得！">>)
    end.


%%@doc 执行领取宗族BUFF的结果(从地图节点返回)
do_fetch_family_buff_result(false,{RoleID,Reason,FmlBuffID,BuffLevel})->
    %%重新返回宗族贡献度
    [FmlBuffList] = common_config_dyn:find(family_buff,FmlBuffID),
    #r_family_buff{need_family_contribute=NeedFamilyConb} = lists:keyfind(BuffLevel,#r_family_buff.buff_level,FmlBuffList),
    mod_family:do_add_contribution(RoleID,NeedFamilyConb),
    
    R2 = #m_fmlskill_fetch_buff_toc{succ=false,reason=Reason},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FMLSKILL, ?FMLSKILL_FETCH_BUFF, R2);
do_fetch_family_buff_result(true,{RoleID,FmlBuffID})->
    mod_family:do_parttake_family_role(RoleID,fetch_buff),
    
    R2 = #m_fmlskill_fetch_buff_toc{succ=true,fml_buff_id=FmlBuffID},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FMLSKILL, ?FMLSKILL_FETCH_BUFF, R2),
    ok.

%%@interface 研究宗族技能
do_fmlskill_research({Unique, Module, Method, Record, RoleID, _PID, Line}=InterfaceInfo)->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    #m_fmlskill_research_tos{skill_id=SkillID} = Record,
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) orelse mod_family:is_intermanager(RoleID, FamilyInfo) of
        true ->
            case common_config_dyn:find(family_skill,SkillID) of
                []->
                    ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"没有此宗族技能可以研究">>);
                [SkillDetails]->
                    do_fmlskill_research_2(InterfaceInfo,FamilyInfo,SkillDetails)
            end;
        _ ->
            ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"只有族长,副族长或内务使才能研究宗族技能">>)
    end.

do_fmlskill_research_2({Unique, Module, Method, Record, RoleID, _PID, Line}=InterfaceInfo,FamilyInfo,SkillDetails)->
    #m_fmlskill_research_tos{skill_id=SkillID} = Record,
    #p_family_info{family_id=FamilyID,level=FamilyLevel,money=FamilyMoney,active_points=FamilyActivePt} = FamilyInfo,
    [#r_family_skill_limit{skill_count=SkillCount,skill_level=LimitSkillLevel}] = common_config_dyn:find(family_skill_limit,FamilyLevel),
    case db:dirty_read(?DB_FAMILY_SKILL_RESEARCH,{FamilyID,SkillID}) of
        []->
            NextSkillLevel = 1;
        [#r_family_skill_research{family_id=FamilyID,cur_level=CurSkillLevel}]->
            NextSkillLevel = CurSkillLevel+1
    end,
    MaxFamilySkillLevel = get_max_family_level(),
    if
        FamilyLevel < 1 ->
            ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"必须升级到1级宗族，才能研究宗族技能">>);
        NextSkillLevel > MaxFamilySkillLevel->
            ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"已达到最高的宗族技能等级，不需要继续研究">>);
        NextSkillLevel > LimitSkillLevel ->
            ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"必须升级宗族，才能继续研究下一级宗族技能">>);
        true->
            FamilySkillDetail = get_family_skill(NextSkillLevel,SkillDetails),
            #r_family_skill{need_family_money=DeductMoney,need_family_active_point=DeductActivePt} = FamilySkillDetail,
            if
                DeductMoney>FamilyMoney ->
                    ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"宗族资金不足，不能研究该技能">>);
                DeductActivePt>FamilyActivePt ->
                    ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"宗族繁荣度不足，不能研究该技能">>);
                true->
                    do_fmlskill_research_3(InterfaceInfo,FamilyInfo,FamilySkillDetail,SkillCount)
            end
    end.

do_fmlskill_research_3(InterfaceInfo,FamilyInfo,FamilySkillDetail,SkillCount) 
  when is_record(FamilyInfo,p_family_info) andalso is_record(FamilySkillDetail,r_family_skill)->
    {Unique, Module, Method, Record, RoleID, _PID, Line} = InterfaceInfo,
    #m_fmlskill_research_tos{skill_id=SkillID} = Record,
    #r_family_skill{level=NextSkillLevel,need_family_money=DeductMoney,need_family_active_point=DeductActivePt} = FamilySkillDetail,
    #p_family_info{family_id=FamilyID,money=FamilyMoney,active_points=FamilyActivePt} = FamilyInfo,
    case db:transaction( fun()-> t_fmlskill_research_3(FamilyID,SkillID,NextSkillLevel,SkillCount) end ) of
        {atomic,ok}->
            [#p_skill{name=SkillName}] = common_config_dyn:find(skill,SkillID),
            State = mod_family:get_state(),
            NewFamilyInfo = FamilyInfo#p_family_info{money=(FamilyMoney-DeductMoney),active_points=(FamilyActivePt-DeductActivePt)},
            mod_family:update_state(State#family_state{family_info=NewFamilyInfo}),
            
            NextSkill = #p_role_skill{skill_id=SkillID,cur_level=NextSkillLevel},
            R2 = #m_fmlskill_research_toc{succ=true,skill=NextSkill},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R2),
            
            #p_family_info{money=NewFamilyMoney,active_points=NewFamilyActpoint}=NewFamilyInfo,
            ChangeInfoList = [{?FAMILY_MONEY_CHANGE,NewFamilyMoney},{?FAMILY_ACTIVEPOINT_CHANGE,NewFamilyActpoint}],
            notify_family_info_change(ChangeInfoList),
            
            RoleName = common_misc:get_dirty_rolename(RoleID),
            FamilyMsg = common_misc:format_lang(<<"<font color=\"#FFFF00\">[~s]</font>成功研究宗族技能【~s】，大家可以进入宗族地图找“宗族研究员”学习该技能。">>,[RoleName,SkillName]),
            broadcast_to_family_channel(FamilyID,FamilyMsg);
        {aborted,{error,max_skill_count}}->
            ?SEND_ERR_TOC(m_fmlskill_research_toc,<<"宗族技能个数达到上限，必须升级宗族才能研究新技能">>);
        {aborted,Error}->
            ?ERROR_MSG("研究宗族技能出错，Error=~w",[Error]),
            ?SEND_ERR_TOC(m_fmlskill_research_toc,?_LANG_SYSTEM_ERROR)
    end.


t_fmlskill_research_3(FamilyID,SkillID,NextSkillLevel,SkillCount) 
  when is_integer(NextSkillLevel) andalso is_integer(SkillCount) ->
    case db:match_object(?DB_FAMILY_SKILL_RESEARCH,#r_family_skill_research{_='_', family_id=FamilyID},read) of
        []->
            Key = {FamilyID,SkillID},
            R = #r_family_skill_research{research_key=Key, family_id=FamilyID, skill_id=SkillID, cur_level=1},
            db:write(?DB_FAMILY_SKILL_RESEARCH,R,write);
        SkillsList when is_list(SkillsList)->
            IsLearnNew = NextSkillLevel=:=1,
            if
                
                IsLearnNew andalso length(SkillsList)>= SkillCount ->
                    db:abort({error,max_skill_count});
                true->
                    Key = {FamilyID,SkillID},
                    R = #r_family_skill_research{research_key=Key, family_id=FamilyID, skill_id=SkillID, cur_level=NextSkillLevel},
                    db:write(?DB_FAMILY_SKILL_RESEARCH,R,write)
            end
    end.

%%@interface 遗忘宗族技能
do_fmlskill_forget({Unique, Module, Method, _Record, RoleID, _PID, Line}=InterfaceInfo)->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) orelse mod_family:is_intermanager(RoleID, FamilyInfo)  of
        true ->
            do_fmlskill_forget_2(InterfaceInfo,FamilyInfo);
        _ ->
            ?SEND_ERR_TOC(m_fmlskill_forget_toc,<<"只有族长或副族长才能遗忘宗族技能">>)
    end.
do_fmlskill_forget_2({Unique, Module, Method, Record, RoleID, _PID, Line},FamilyInfo)->
    #m_fmlskill_forget_tos{skill_id=SkillID} = Record,
    #p_family_info{family_id=FamilyID,level=FamilyLevel,money=FamilyMoney} = FamilyInfo,
    [#r_family_skill_limit{forget_family_money=DeductMoney}] = common_config_dyn:find(family_skill_limit,FamilyLevel),
    if
        DeductMoney>FamilyMoney->
            ?SEND_ERR_TOC(m_fmlskill_forget_toc,<<"宗族资金不足，不能遗忘该技能">>);
        true->
            case db:transaction( fun()-> t_fmlskill_forget_3(FamilyID,SkillID) end ) of
                {atomic,ok}->
                    State = mod_family:get_state(),
                    NewFamilyInfo = FamilyInfo#p_family_info{money=(FamilyMoney-DeductMoney)},
                    mod_family:update_state(State#family_state{family_info=NewFamilyInfo}),
                    
                    R2 = #m_fmlskill_forget_toc{succ=true,skill_id=SkillID},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, R2),
                    
                    #p_family_info{money=NewFamilyMoney}=NewFamilyInfo,
                    ChangeInfoList = [{?FAMILY_MONEY_CHANGE,NewFamilyMoney}],
                    notify_family_info_change(ChangeInfoList);
                {aborted,{error,not_exists_skill}}->
                    ?SEND_ERR_TOC(m_fmlskill_forget_toc,<<"宗族尚未研究该技能，不需要遗忘">>);
                {aborted,Error}->
                    ?ERROR_MSG("遗忘宗族技能出错，Error=~w",[Error]),
                    ?SEND_ERR_TOC(m_fmlskill_forget_toc,?_LANG_SYSTEM_ERROR)
            end
    end.

notify_family_info_change(ChangeInfoList) when is_list(ChangeInfoList)->
    Changes = [ #p_family_info_change{change_type=Type,new_value=Val}||{Type,Val}<-ChangeInfoList ],
    R = #m_family_info_change_toc{changes=Changes},
    mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_INFO_CHANGE, R).

t_fmlskill_forget_3(FamilyID,SkillID)->
    Key = {FamilyID,SkillID},
    case db:read(?DB_FAMILY_SKILL_RESEARCH,Key) of
        []->
            {error,not_exists_skill};
        [#r_family_skill_research{family_id=FamilyID}]->
            ok = db:delete(?DB_FAMILY_SKILL_RESEARCH,Key,write)
    end.

%%@interface 获取（已研究的）宗族技能
do_fmlskill_list({Unique, Module, Method, _Record, RoleID, _PID, Line})->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    #p_family_info{family_id=FamilyID} = FamilyInfo,
    case dirty_get_family_skill(FamilyID) of
        {fail,Reason} ->
            ?SEND_ERR_TOC(m_fmlskill_list_toc,Reason);
        SkillLevelList ->
            R2 = #m_fmlskill_list_toc{skills=SkillLevelList},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R2)
    end.
    
dirty_get_family_skill(FamilyID) when is_integer(FamilyID) ->
    Pattern = #r_family_skill_research{family_id = FamilyID, _ = '_'},
    case catch db:dirty_match_object(?DB_FAMILY_SKILL_RESEARCH,Pattern) of
        [] ->
            [];
        List when is_list(List) ->
            lists:foldr(
              fun(FamilySkillInfo,Acc) ->
                      #r_family_skill_research{skill_id = SkillID, cur_level = CurLevel} = FamilySkillInfo, 
                      [#p_role_skill{skill_id=SkillID,cur_level=CurLevel}|Acc]
              end,[],List);
        _ ->    
            {fail,?_LANG_PARAM_ERROR}
    end.

get_max_family_level()->
    [Level] = common_config_dyn:find(family_skill,max_family_level),
    Level.

get_family_skill(SkillLevel,SkillDetails) when is_integer(SkillLevel) andalso is_list(SkillDetails)->
    lists:keyfind(SkillLevel, 3, SkillDetails).



%%@doc 广播给宗族频道
broadcast_to_family_channel(FamilyID,Content) when is_integer(FamilyID) ->
    common_broadcast:bc_send_msg_family(FamilyID,[?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_FAMILY,Content).
