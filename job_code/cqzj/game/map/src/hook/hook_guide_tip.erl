%%% @author wuzesen <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     游戏的引导性提示
%%% @end
%%% Created : 2011-12-30
%%%-------------------------------------------------------------------
-module(hook_guide_tip).

-include("mgeem.hrl").

%% API
-export([
			done_guide_task/2,
			hook_role_enter_map/2,
			hook_zazen_end/1,
			hook_role_energy_guide_tip/2,
			hook_buy_guide_mission/1,
            init/2,
            delete/1
		]).

-define(GUIDE_TIP_CANCEL_TIMES,guide_tip_cancel_times).
-define(THROW_FALSE(),throw(false)).

% -record(r_guide_buy_mission, {
%     nuqi_guide = true
% }).
init(RoleID, Rec) when is_record(Rec, r_guide_buy_mission) ->
    mod_role_tab:put({r_guide_buy_mission, RoleID}, Rec);
init(RoleID, _) ->
    mod_role_tab:put({r_guide_buy_mission, RoleID}, #r_guide_buy_mission{}).
delete(RoleID) ->
    mod_role_tab:erase({r_guide_buy_mission, RoleID}).

%%%===================================================================
%%% API
%%%===================================================================

%%@doc 结束打坐，进行引导性提示
hook_zazen_end(RoleID) ->
    case can_role_guide_tip(RoleID) of
        true->
            do_guide_tip(RoleID);
        _ ->
            ignore
    end.

%%@doc 进入地图，进行引导性提示
hook_role_enter_map(RoleID,MapID) ->
    case can_role_guide_tip(RoleID) of
        true->
            [GuideEnterMapList] = common_config_dyn:find(guide_tip,guide_tip_enter_map),
            case lists:member(MapID, GuideEnterMapList) of
                true->
                    hook_role_enter_map_2(RoleID);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
hook_role_enter_map_2(RoleID)->
    [MinOnlineTime] = common_config_dyn:find(guide_tip,guide_min_online_time),
    case common_misc:get_dirty_role_ext(RoleID) of
        {ok, #p_role_ext{last_login_time=LastLoginTime}} when is_integer(LastLoginTime),LastLoginTime>0->
            Now = common_tool:now(),
            case Now>=(LastLoginTime+MinOnlineTime) of
                true->
                    do_guide_tip(RoleID);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

hook_role_energy_guide_tip(RoleID, Energy) ->
	if Energy =:= 0 ->
		   GuideId = 
			   case check_role_enery_guide_tip(RoleID, [10800032,10800033]) of
				   notify_buy ->
					   1002;
				   notify_use ->
					   1001;
				   not_notify ->
					   0
			   end,
		   if GuideId > 0 ->
				  R2C = #m_newcomer_guide_tip_toc{guide_id=GuideId},
				  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NEWCOMER, ?NEWCOMER_GUIDE_TIP, R2C);
			  true ->
				  ignore
		   end;
	   true ->
		   ignore
	end.

check_role_enery_guide_tip(RoleID, DrugItemIdList) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			#r_role_map_ext{energy_drug_usage=RoleEnergyUsage} = RoleExtInfo,
			#r_role_energy_drug_usage{count=Count, last_use_time=LastUseTime} = RoleEnergyUsage,
			[CountLimit] = common_config_dyn:find(etc, energy_drug_usage_limit),
			LastUseDate = common_time:time_to_date(LastUseTime),
			case {Count < CountLimit, LastUseDate =:= date()} of
				{true, true} ->
					check_use_energy_drug(RoleID, DrugItemIdList);
				{_, false} ->
					check_use_energy_drug(RoleID, DrugItemIdList);
				{_, _} -> 
					not_notify
			end;
		_ ->
			notify_buy
	end.

check_use_energy_drug(_RoleID,[]) ->
	notify_buy;
check_use_energy_drug(RoleID,[DrugItemID|T]) ->
	case mod_bag:check_inbag_by_typeid(RoleID, DrugItemID) of
		{ok, _} ->
			notify_use;
		_ ->
			check_use_energy_drug(RoleID,T)
	end.

%%@doc 完成引导性的活动
done_guide_task(RoleID,ActTaskId)->
    case get_guide_by_act_task_id(ActTaskId) of
        {ok,GuideId}->
            TransFun = fun()-> t_done_guide_task(RoleID,GuideId) end,
            case common_transaction:t( TransFun ) of
                {atomic,_ } ->
                    ok;
                {aborted, AbortErr} ->
                    ?ERROR_MSG("AbortErr=~w",[AbortErr]),
                    error
            end;
        _ ->
            ignore
    end.


%%@doc 根据活动ID获取对应的引导ID
%%@return GuideId ::integer()
get_guide_by_act_task_id(ActTaskId)->
    [ConfGuideTips] = common_config_dyn:find(guide_tip,guide_tips),
    get_guide_by_act_task_id_2(ActTaskId,ConfGuideTips).

get_guide_by_act_task_id_2(_ActTaskId,[])->
    {error,not_found};
get_guide_by_act_task_id_2(ActTaskId,[H|T])->
    case H of
        #r_guide_tip{guide_id=Id,check_type=check_activity,
                     params=[ActTaskId]}->
            {ok,Id};
        _ ->
            get_guide_by_act_task_id_2(ActTaskId,T)
    end.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_guide_tip(RoleID)->
    [ConfGuideTips] = common_config_dyn:find(guide_tip,guide_tips),
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{role_guide=RoleGuideInfo}} ->
            #r_role_guide_tip{guides=RoleGuides} = RoleGuideInfo,
            case mod_map_role:get_role_attr(RoleID) of
                {ok,#p_role_attr{jingjie=Jingjie}} when Jingjie>0->
                    do_guide_tip_2(RoleID,ConfGuideTips,RoleGuides,Jingjie);
                _R2 ->
                    ignore
            end;
        _ ->
            ignore
    end.
do_guide_tip_2(RoleID,ConfGuideTips,RoleGuides,Jingjie)->
    case select_role_guide_tip(RoleID,ConfGuideTips,RoleGuides,Jingjie) of
        {ok,GuideId} when GuideId>0->
            TransFun = fun()-> t_notice_guide_tip(RoleID,GuideId) end,
            case common_transaction:t( TransFun ) of
                {atomic,_ } ->
                    R2C = #m_newcomer_guide_tip_toc{guide_id=GuideId},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NEWCOMER, ?NEWCOMER_GUIDE_TIP, R2C);
                {aborted, AbortErr} ->
                    ?ERROR_MSG("AbortErr=~w",[AbortErr]),
                    error
            end; 
        _ ->
            ignore
    end.

select_role_guide_tip(_RoleID,[],_,_)->
    no_guides;
select_role_guide_tip(RoleID,[H|T],RoleGuides,Jingjie) when is_list(RoleGuides)->
    #r_guide_tip{guide_id=GuideId,min_jingjie=MinJingjie,max_jingjie=MaxJingjie,
                 check_type=CheckType,params=Params,max_all_times=MaxAllTimes} = H,
    case Jingjie>=MinJingjie andalso MaxJingjie>=Jingjie of
        true->
            case is_guide_avariable_today(GuideId,RoleGuides,MaxAllTimes) of
                true->
                    case check_guide_trigger(CheckType,RoleID,Params) of
                        true->
                            {ok,GuideId};
                        _ ->
                            select_role_guide_tip(RoleID,T,RoleGuides,Jingjie)
                    end;
                _ ->
                    select_role_guide_tip(RoleID,T,RoleGuides,Jingjie)
            end;
        _ ->
            select_role_guide_tip(RoleID,T,RoleGuides,Jingjie)
    end.


t_done_guide_task(RoleID,GuideId)->
    {ok,RoleMapExt1} = mod_map_role:get_role_map_ext_info(RoleID),
    #r_role_map_ext{role_guide=RoleGuideInfo} = RoleMapExt1,
    #r_role_guide_tip{guides=RoleGuides1} = RoleGuideInfo,
    Today = date(),
    
    case lists:keyfind(GuideId, #r_guide_rec.guide_id, RoleGuides1) of
        #r_guide_rec{} = Rec1->
            Rec2=Rec1#r_guide_rec{done_date=Today};
        _ ->
            Rec2=#r_guide_rec{guide_id=GuideId,done_date=Today}
    end,
    
    RoleGuides2 = lists:keystore(GuideId, #r_guide_rec.guide_id, RoleGuides1, Rec2),
    RoleMapExt2=RoleMapExt1#r_role_map_ext{role_guide=RoleGuideInfo#r_role_guide_tip{guides=RoleGuides2}},
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2),
    ok.

t_notice_guide_tip(RoleID,GuideId)->
    {ok,RoleMapExt1} = mod_map_role:get_role_map_ext_info(RoleID),
    #r_role_map_ext{role_guide=RoleGuideInfo} = RoleMapExt1,
    #r_role_guide_tip{guides=RoleGuides1} = RoleGuideInfo,
    Today = date(),
    Now = common_tool:now(),
    
    case lists:keyfind(GuideId, #r_guide_rec.guide_id, RoleGuides1) of
        #r_guide_rec{notice_times=OldTimes} = Rec1->
            Rec2=Rec1#r_guide_rec{notice_date=Today,notice_times=(OldTimes+1)};
        _ ->
            Rec2=#r_guide_rec{guide_id=GuideId,notice_date=Today,notice_times=1}
    end,
    
    RoleGuides2 = lists:keystore(GuideId, #r_guide_rec.guide_id, RoleGuides1, Rec2),
    RoleMapExt2=RoleMapExt1#r_role_map_ext{role_guide=RoleGuideInfo
                                          #r_role_guide_tip{guides=RoleGuides2,
                                                            last_tip_time=Now}},
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2),
    ok.



%%@doc 检查是否可以触发引导
check_guide_trigger(check_stone,RoleID,ExcludedTypeIdList) when is_list(ExcludedTypeIdList)->
    case mod_bag:check_stone_inbag(RoleID) of
        {ok,_GoodsInfo}->   true;
        _ ->    false
    end;
check_guide_trigger(check_item,RoleID,PropTypeIdList) when is_list(PropTypeIdList)->
    check_guide_trigger_2(check_item,RoleID,PropTypeIdList);
check_guide_trigger(check_activity,_RoleID,_)->
    true;
check_guide_trigger(_,_RoleID,_Params)->
    false.

check_guide_trigger_2(check_item,_RoleID,[])->
    false;
check_guide_trigger_2(check_item,RoleID,[PropTypeId|T])->
    case mod_bag:check_inbag_by_typeid(RoleID, PropTypeId) of
        {ok,_GoodsInfo}->   true;
        _ ->    check_guide_trigger_2(check_item,RoleID,T)
    end.

%%@doc 判断今天是否可以进行引导
is_guide_avariable_today(GuideId,RoleGuides,MaxAllTimes)->
     Today = date(),
     case lists:keyfind(GuideId, #r_guide_rec.guide_id, RoleGuides) of 
         #r_guide_rec{notice_date=Today}->
             false;
         #r_guide_rec{done_date=Today}->
             false;
         #r_guide_rec{notice_times=NoticeTimes} when is_integer(NoticeTimes) andalso NoticeTimes>=MaxAllTimes->
             false;
         _ ->
             true
     end.

%%判断能否对玩家进行引导提示
%%@return true | false
can_role_guide_tip(RoleID)->
    %%引导提示的最小境界
    case mod_map_role:get_role_attr(RoleID) of
        {ok,#p_role_attr{jingjie=Jingjie}}->
            [MinJingjie] = common_config_dyn:find(guide_tip,guide_min_jingjie),
            if
                Jingjie>=MinJingjie->
                    case catch can_role_guide_tip_2(RoleID) of
                        ok->
                            true;
                        _ ->
                            false
                    end;
                true->
                    false
            end;
        _ ->
            false
    end.
can_role_guide_tip_2(RoleID)->
    %%本国大地图才能进行引导提示
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        #p_map_role{faction_id=FactionID}->
            MapID = mgeem_map:get_mapid(),
            case common_misc:if_in_self_country(FactionID, MapID) of
                true->
                    case mod_warofking:is_fb_map_id(MapID) of
                        true-> ?THROW_FALSE();
                        _ ->
                            next
                    end;
                _ ->
                    ?THROW_FALSE()
            end;
        _ ->
            ?THROW_FALSE()
    end,
    Now = common_tool:now(),
    CancelSecTimes = get_guide_cancel_times_today(),
    case is_in_guide_cancel_times(Now,CancelSecTimes) of
        true->  
            ?THROW_FALSE();
        _ ->
            next
    end,
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{role_guide=RoleGuideInfo}} ->
            #r_role_guide_tip{last_tip_time=LastTipTime} = RoleGuideInfo,
            [GuideMinInterval] = common_config_dyn:find(guide_tip,guide_min_interval_time),
            if
                LastTipTime=:=0->
                    next;
                Now>=(LastTipTime+GuideMinInterval)->
                    next;
                true->
                    ?THROW_FALSE()
            end;
        _ ->
            ?THROW_FALSE()
    end,
    ok.

get_guide_cancel_times_today()->
    Today = date(),
    case get(?GUIDE_TIP_CANCEL_TIMES) of
        {Today,CancelSecTimes}->
            next;
        _ ->
            {ok,CancelSecTimes} = update_guide_cancel_times()
    end,
    CancelSecTimes.


%%更新引导的禁止时间
update_guide_cancel_times()->
    [ConfCancelTime] = common_config_dyn:find(guide_tip,guide_tip_cancel_times),
    Today = date(),
    
    CancelSecTimes = 
        lists:foldl(
          fun(E,AccIn)-> 
                  {StartMinuteConf,EndMinuteConf} = E,
                  StartSeconds = common_tool:datetime_to_seconds({Today,StartMinuteConf}),
                  EndSeconds = common_tool:datetime_to_seconds({Today,EndMinuteConf}),
                  [{StartSeconds,EndSeconds}|AccIn]
          end, [], ConfCancelTime),
    put(?GUIDE_TIP_CANCEL_TIMES,{Today,CancelSecTimes}),
    {ok,CancelSecTimes}.

%%是否属于引导的禁止时间
is_in_guide_cancel_times(_Now,[])->
    false;
is_in_guide_cancel_times(Now,[H|T])->
    {StartTime,EndTime} = H,
    if
        Now>=StartTime andalso EndTime>=Now ->
            true;
        true->
            is_in_guide_cancel_times(Now,T)
    end.

%% 显示任务消费引导(购买装备、坐骑、时装界面)图标(1=显示,0=不显示)
hook_buy_guide_mission(RoleID) ->
	case common_config_dyn:find(guide_tip,guide_buy_mission) of
		[] ->
			ignore;
		[{EquipConf,MountConf,MountConf2,FashionConf, FashionConf2,PetConf,PetConf2}] ->
			{ok,#p_role_attr{
                equips=Equips,
                level=Level
            }} = mod_map_role:get_role_attr(RoleID),
            Pets = case mod_map_pet:get_role_pet_bag_info(RoleID) of
                #p_role_pet_bag{pets = PetsRec} -> PetsRec;
                _ -> []
            end,
			RoleVipLevel = mod_vip:get_role_vip_level(RoleID),
            #r_role_fashion{
                mounts  = #r_fashion{rank = MountID},
                fashion = #r_fashion{rank = FashionID}
            } = mod_role_fashion:fetch(RoleID),

            % #r_guide_buy_mission{
            %     show_nuqi_guide = ShowNuqiGuide
            % } = mod_role_tab:get({r_guide_buy_mission, RoleID}),
            ShowNuqiGuide = false,

			IsShowEquip = not role_own_equip(RoleID,Equips,RoleVipLevel,Level,EquipConf),
			case role_own_mount(RoleID,MountID,RoleVipLevel,Level,MountConf) of
				true ->
					IsShowMount = true,
					IsShowMount2 = false;
				_ ->
					IsShowMount = false,
					IsShowMount2 = role_own_mount(RoleID,MountID,RoleVipLevel,Level,MountConf2)
			end,
			case role_own_fashion(RoleID,FashionID,RoleVipLevel,Level,FashionConf) of
				true ->
					IsShowFashion = true,
					IsShowFashion2 = false;
				_ ->
					IsShowFashion = false,
					IsShowFashion2 = role_own_fashion(RoleID,FashionID,RoleVipLevel,Level,FashionConf2)
			end,
			case not role_own_pet(RoleID, Pets,RoleVipLevel, Level, PetConf) of
				true ->
					IsShowPet = true,
					IsShowPet2 = false;
				_ ->
					IsShowPet = false,
					IsShowPet2 = not role_own_pet(RoleID, Pets,RoleVipLevel, Level, PetConf2)
			end,
			case IsShowEquip orelse IsShowMount orelse IsShowFashion 
				orelse IsShowPet orelse ShowNuqiGuide orelse IsShowMount2 orelse IsShowFashion2 orelse IsShowPet2 of
				true ->
					R2 = #m_role2_guide_buy_mission_toc{is_show=[IsShowEquip,IsShowMount,IsShowFashion,IsShowPet, ShowNuqiGuide,IsShowMount2,IsShowFashion2,IsShowPet2]},
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_GUIDE_BUY_MISSION, R2);
				false ->
					ignore
			end
	end.

%% 玩家是否拥有某个装备(背包/身上)
role_own_equip(RoleID,Equips,RoleVipLevel,Level,{TypeIDList,MinShowVipLevel,MinShowLevel,MaxShowLevel}) when is_list(TypeIDList) ->
	lists:any(fun(TypeID) ->
					  role_own_equip(RoleID,Equips,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel})
			  end, TypeIDList);
role_own_equip(RoleID,Equips,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel}) ->
	case Level >= MinShowLevel andalso Level =< MaxShowLevel andalso MinShowVipLevel =< RoleVipLevel of
		true ->
			case mod_bag:check_inbag_by_typeid(RoleID, TypeID) of
				false ->
					lists:keyfind(TypeID, #p_goods.typeid, Equips) =/= false;
				_ ->
					true
			end;
		false ->
			true
	end.

role_own_mount(RoleID,MountID,RoleVipLevel,Level,{TypeIDList,MinShowVipLevel,MinShowLevel,MaxShowLevel}) when is_list(TypeIDList) ->
    lists:any(fun(TypeID) ->
                      role_own_mount(RoleID,MountID,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel})
              end, TypeIDList);
role_own_mount(_RoleID,MountID,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel}) ->
    case (Level >= MinShowLevel andalso Level =< MaxShowLevel) orelse (MinShowVipLevel > 0 andalso MinShowVipLevel =< RoleVipLevel) of
        true ->
            TypeID > MountID;
            % lists:member(TypeID, MountID);
        false ->
            false
    end.

role_own_fashion(RoleID,FashionID,RoleVipLevel,Level,{TypeIDList,MinShowVipLevel,MinShowLevel,MaxShowLevel}) when is_list(TypeIDList) ->
    lists:any(fun(TypeID) ->
                      role_own_fashion(RoleID,FashionID,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel})
              end, TypeIDList);
role_own_fashion(_RoleID,FashionID,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel}) ->
    case (Level >= MinShowLevel andalso Level =< MaxShowLevel) orelse (MinShowVipLevel > 0 andalso MinShowVipLevel =< RoleVipLevel) of
        true ->
           TypeID > FashionID;
            % lists:member(FashionID, TypeIDs);
            % lists:keymember(TypeID, #p_fashion.id, Fashions);
        false ->
            false
    end.

%%判断宠物是否存在
role_own_pet(RoleID, Pets,RoleVipLevel, Level, {TypeIDList,MinShowVipLevel,MinShowLevel,MaxShowLevel}) when is_list(TypeIDList) ->
    lists:any(fun(TypeID) ->
        role_own_pet(RoleID,Pets,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel})
    end, TypeIDList);

role_own_pet(_RoleID,Pets,RoleVipLevel,Level,{TypeID,MinShowVipLevel,MinShowLevel,MaxShowLevel}) ->
    case Level >= MinShowLevel andalso Level =< MaxShowLevel  andalso MinShowVipLevel =< RoleVipLevel of
        true ->
            lists:keymember(TypeID, #p_pet_id_name.type_id, Pets);
        false ->
            true
    end.