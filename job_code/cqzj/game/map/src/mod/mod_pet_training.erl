-module(mod_pet_training).
-include("mgeem.hrl").

-export([handle/1, init_pet_training/1,
		 eat_pet_card/2,
         check_pet_is_training/2,
		 get_common_add_pet_exp/3]).

-define(MAX_TRAINING_ROOM,5).
%% 地图统计异兽训练间隔时间
-define(MAP_COUNTER_SPACE_TIME,60).

%% 配置文件计算经验间隔时间(秒)
-define(PET_TRAINING_ADD_EXP_SPACE_TIME,15).
%% 加经验间隔时间 （秒）
-define(ADD_EXP_SPACE_TIME,900).
%% 重设突飞猛进时间间隔
-define(CUT_FLY_CD_TIME,1200).
%% 突飞猛进最大冷却时间
-define(FLY_TRAINING_MAX_CD_TIME,7200).
%% 突飞猛进每次费用
-define(SILVER_FLY_COST,4200).
%% 突飞猛进每天次数
-define(SILVER_FLY_MAX_TIMES,72).

%% 秒完CD基数
-define(RESET_PET_FLY_TRAINING_BASE_CD_TIME,600).
%% 秒完CD扣费（每秒完CD基数扣费（绑定）元宝）
-define(RESET_PET_FLY_TRAINING_CD_TIME_COST,1).

%% 获取训练信息
-define(GET_PET_TRAINING_INFO,1).
%% 添加训练空位
-define(ADD_PET_TRAINING_ROOM,2).
%% 开始训练
-define(START_PET_TRAINING,3).
%% 结束训练
-define(STOP_PET_TRAINING,4).
%% 突飞猛进
-define(FLY_PET_TRAINING,5).
%% 清除突飞猛进cd时间
-define(RESET_PET_FLY_TRAINING_CD_TIME,6).
%% 训练模式
-define(SET_PET_TRAINING_MODE,7).
%% 异兽加经验结果
-define(SET_PET_ADD_EXP,8).
%% 元宝突飞
-define(GOLD_FLY_PET_TRAINING,9).



%% 异兽训练获得经验与玩家等级有关
-record(pet_training_exp,{role_level,add_exp}).

%% 训练模式
-define(TRAINING_MODE_1,1).
-define(TRAINING_MODE_2,2).
-define(TRAINING_MODE_3,3).
-define(TRAINING_MODE_4,4).
-define(TRAINING_MODE_5,5).

check_pet_is_training(RoleID,PetID)->
    {ok,RoleMapExt} = mod_map_role:get_role_map_ext_info(RoleID),
    PetTrainingList = (RoleMapExt#r_role_map_ext.training_pets)#r_pet_training.pet_training_list,
    case lists:keyfind(PetID,#r_pet_training_detail.pet_id,PetTrainingList) of
        PetTrainingDetail when is_record(PetTrainingDetail,r_pet_training_detail)->
            true;
        _->false
    end.

%% 异兽添加经验过程
do_add_pet_training_exp(PetTrainingDetail,Now,RoleID)->
    {ok,#p_role_attr{level=RoleLevel}}=mod_map_role:get_role_attr(RoleID),
	AddTimes=(Now - PetTrainingDetail#r_pet_training_detail.last_add_exp_time) div ?PET_TRAINING_ADD_EXP_SPACE_TIME,
    [{Rate,_}]=common_config_dyn:find(pet_training,{training_mode,PetTrainingDetail#r_pet_training_detail.training_mode}),
    AddExpArg=(AddTimes*Rate) div 100,
	%% 新的经验记录 需要重新获取
	{ok,#r_role_map_ext{training_pets=TrainingPets}=RoleMapExtInfo}=mod_map_role:get_role_map_ext_info(RoleID),
    case db:transaction(
           fun()-> 
                   {ok,NewPetInfo,RealAddExp,NoticeType}=mod_map_pet:t_common_add_pet_exp(RoleID,PetTrainingDetail#r_pet_training_detail.pet_id,AddExpArg,special),
                   {Status,NewPetTrainingDetail} = get_new_training_detail(NewPetInfo,RoleLevel,PetTrainingDetail,Now,AddTimes*?PET_TRAINING_ADD_EXP_SPACE_TIME,RealAddExp),
					case Status of
                       continue->
                           PetTrainingList = [NewPetTrainingDetail|lists:delete(PetTrainingDetail, TrainingPets#r_pet_training.pet_training_list)];    
                       stop->
                           PetTrainingList = lists:delete(PetTrainingDetail, TrainingPets#r_pet_training.pet_training_list)                       
                   end,
                   NewTrainingPets =TrainingPets#r_pet_training{pet_training_list =PetTrainingList},
                   mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExtInfo#r_role_map_ext{training_pets=NewTrainingPets}),
                   {ok,NewTrainingPets,NewPetTrainingDetail,Status,NewPetInfo,NoticeType}
           end)
        of
		{aborted, {full_level,Reason}} ->
			R2 = #m_pet_training_request_toc{op_type=?STOP_PET_TRAINING,succ=false,reason=Reason,reason_code=100},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_TRAINING_REQUEST, R2);
		{aborted, Reason} ->
            if
                (Reason =:= ?_LANG_PET_NOT_EXIST)orelse(Reason=:={throw,?_LANG_PET_NOT_EXIST})
						orelse (Reason=:={throw,no_pet_info})->
                    NewPetTrainingList = lists:delete(PetTrainingDetail, TrainingPets#r_pet_training.pet_training_list),
                    NewRoleMapExt = RoleMapExtInfo#r_role_map_ext{training_pets=TrainingPets#r_pet_training{pet_training_list = NewPetTrainingList}},
                    mod_map_role:set_role_map_ext_info(RoleID,NewRoleMapExt);
                true->
                    ?ERROR_MSG("RoleID:~w,PetTrainingDetail:~w,宠物训练加经验失败 Reason:~w~n",[RoleID,PetTrainingDetail,Reason])
            end;
        {atomic, {ok,NewTrainingPets,NewPetTrainingDetail,Status,NewPetInfo,NoticeType}} ->
            PetLevel = NewPetInfo#p_pet.level,
            case NoticeType of
                levelup->
                    hook_pet:hook_pet_levelup(RoleID,PetTrainingDetail#r_pet_training_detail.pet_id,PetLevel);
                _->
                    ignore
            end,
            %% 加经验结果
            mod_map_pet:send_pet_info_to_client(RoleID, NewPetInfo),  
            case Status of
                stop->
                   R2 = #m_pet_training_request_toc{op_type=?STOP_PET_TRAINING,
                                                    cur_room=NewTrainingPets#r_pet_training.cur_room,
                                                    pet_training_list=transfer(NewTrainingPets#r_pet_training.pet_training_list),
                                                    pet_training_info=transfer(NewPetTrainingDetail)},
                   common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_TRAINING_REQUEST, R2);
                _->
                    R2 = #m_pet_training_request_toc{op_type=?GET_PET_TRAINING_INFO,
                                                    cur_room=NewTrainingPets#r_pet_training.cur_room,
                                                    pet_training_list=transfer(NewTrainingPets#r_pet_training.pet_training_list),
                                                    pet_training_info=transfer(NewPetTrainingDetail)},
                   common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_TRAINING_REQUEST, R2)  
            end,
            {training_result, Status}
    end.

%% 获取新的异兽训练信息
get_new_training_detail(#p_pet{level=_PetLevel},_RoleLevel,PetTrainingDetail,Now,PassTime,RealAddExp)->
    #r_pet_training_detail{last_add_exp_time=LastAddExpTime,
                           training_end_time=TrainingEndTime,
                           total_get_exp = TotalGetExp}=PetTrainingDetail,
    NewLastAddExpTime = LastAddExpTime+PassTime,
    case TrainingEndTime>Now 
        andalso NewLastAddExpTime+?ADD_EXP_SPACE_TIME=<TrainingEndTime %%下次加经验时间要不大于训练结束时间
        of
        true->Status = continue;
        false->Status = stop
    end,
    {Status,PetTrainingDetail#r_pet_training_detail{last_add_exp_time = NewLastAddExpTime,
                                                    next_add_exp_time = NewLastAddExpTime+?ADD_EXP_SPACE_TIME,
                                                    total_get_exp = TotalGetExp+RealAddExp}}.

init_pet_training(RoleID) ->
    Now = common_tool:now(),
    {ok,#r_role_map_ext{training_pets=TrainingPets}} = mod_map_role:get_role_map_ext_info(RoleID),
    [do_training(RoleID, PetTrainingDetail, Now) || PetTrainingDetail <- TrainingPets#r_pet_training.pet_training_list].

do_training(RoleID, PetTrainingDetail, Now) ->
    case PetTrainingDetail#r_pet_training_detail.next_add_exp_time =< Now of
        true-> 
            case do_add_pet_training_exp(PetTrainingDetail,Now,RoleID) of
                {training_result, stop} ->
                    ok;
                {training_result, continue} -> %% 继续
                    setup_pet_training_timer(RoleID, PetTrainingDetail#r_pet_training_detail.pet_id, ?ADD_EXP_SPACE_TIME);
                _ ->
                    ignore
            end;
        false->
            SpaceTime = PetTrainingDetail#r_pet_training_detail.next_add_exp_time - Now,
            setup_pet_training_timer(RoleID, PetTrainingDetail#r_pet_training_detail.pet_id, SpaceTime)
    end.


%% ---------------------训练相关请求处理-----------------------------------
handle({Unique, DataIn, RoleID, PID, _Line, _State}) when erlang:is_record(DataIn,m_pet_training_request_tos) ->
    case DataIn#m_pet_training_request_tos.op_type of
        ?GET_PET_TRAINING_INFO->
            do_get_pet_training_info(Unique, DataIn, RoleID, PID);
        ?ADD_PET_TRAINING_ROOM->
            do_add_pet_training_room(Unique, DataIn, RoleID, PID);
        ?START_PET_TRAINING->
            do_start_pet_training(Unique, DataIn, RoleID, PID);
        ?STOP_PET_TRAINING->
            do_stop_pet_training(Unique, DataIn, RoleID, PID);
        % ?FLY_PET_TRAINING->(t6没有银币突飞了)
        %     do_fly_pet_training(Unique, DataIn, RoleID, PID);
        ?RESET_PET_FLY_TRAINING_CD_TIME->
            do_reset_pet_fly_training_cd_time(Unique, DataIn, RoleID, PID);
        ?SET_PET_TRAINING_MODE->
            do_set_pet_training_mode(Unique,DataIn,RoleID,PID);
		?GOLD_FLY_PET_TRAINING ->
			do_gold_fly_pet_training(Unique, DataIn, RoleID, PID);
        _->
            ?ERROR_MSG("mod_pet_training undefine op_type Msg:~w~n",[{Unique, DataIn, RoleID, PID, _Line, _State}])
    end;
handle({pet_training_timer, RoleID, PetID})->
    Now = common_tool:now(),
    {ok,#r_role_map_ext{training_pets=TrainingPets}} = mod_map_role:get_role_map_ext_info(RoleID),
    Fun = fun(PetTrainingDetail) ->
        case PetTrainingDetail#r_pet_training_detail.pet_id == PetID of
            true ->
                do_training(RoleID, PetTrainingDetail, Now);
            false -> 
                ignore
        end
    end,
    [Fun(PetTrainingDetail1) || PetTrainingDetail1 <- TrainingPets#r_pet_training.pet_training_list];

handle(Msg)->
    ?ERROR_MSG("mod_pet_training ignore Msg:~w~n",[Msg]).

%%--------------添加训练槽---------------
do_add_pet_training_room(Unique, DataIn, RoleID, PID)->
    {ok,RoleMapExtInfo}=mod_map_role:get_role_map_ext_info(RoleID),
    TrainingPets= RoleMapExtInfo#r_role_map_ext.training_pets,
    NewCurRoom = TrainingPets#r_pet_training.cur_room+1,
	case NewCurRoom>?MAX_TRAINING_ROOM of
		true->
			do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},?_LANG_PET_ADD_TRAINING_ROOM_ENOUGH,0);
		false-> 
			[AddRoomCost]=common_config_dyn:find(pet_training,{training_room,NewCurRoom}),
			case common_transaction:transaction(
				   fun()-> 
                           common_bag2:check_money_enough_and_throw(gold_any,AddRoomCost,RoleID),
						   mod_map_role:t_set_role_map_ext_info(RoleID, 
																RoleMapExtInfo#r_role_map_ext{training_pets=TrainingPets#r_pet_training{cur_room=NewCurRoom}}),
                           NewRoleAttr=
                               case common_bag2:t_deduct_money(gold_any,AddRoomCost,RoleID,?CONSUME_TYPE_GOLD_ADD_PET_TRAINING_ROOM) of
                                    {ok,RoleAttr}->
                                       RoleAttr;
                                    {error, Reason} ->
                                        db:abort({Reason,2});
                                    _ ->
                                       db:abort({?_LANG_NOT_ENOUGH_GOLD,2})
                               end,
						   {ok,NewRoleAttr}
				   end) 
				of
				{aborted,{Reason,ReasonCode}}->
					do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode);
                {aborted, {error, ErrorCode, ErrorStr}} ->
                    common_misc:send_common_error(RoleID, ErrorCode, ErrorStr);
				{atomic,{ok,NewRoleAttr}}->
					R = #m_pet_training_request_toc{op_type = DataIn#m_pet_training_request_tos.op_type,
													cur_room= NewCurRoom},
					common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R),
					?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("添加训练槽，花费~w元宝", [AddRoomCost])),
					common_misc:send_role_gold_change(RoleID, NewRoleAttr)
			end
	end.

%%---------------获取训练信息---------------
do_get_pet_training_info(Unique, DataIn, RoleID, PID)-> 
    {ok,#r_role_map_ext{training_pets=TrainingPets}}=mod_map_role:get_role_map_ext_info(RoleID),
	#r_pet_training{cur_room=CurRoom,fly_cd_end_time=FlyCDEndTime,last_fly_time=LastFlyTime,pet_training_list=PetTrainingList,
					fly_times=FlyTimes} = TrainingPets,
	{FlyMaxTimes,CostSilver,_TrainingCostDiscount} = vip_training_fly_conf(RoleID),
    R = #m_pet_training_request_toc{op_type=?GET_PET_TRAINING_INFO,
									add_exp=get_fly_pet_training_addexp(RoleID,DataIn#m_pet_training_request_tos.pet_id),
                                    cur_room=CurRoom,
									cost_silver=CostSilver,
									fly_cd_end_time = FlyCDEndTime,
									max_fly_times=FlyMaxTimes,
									remain_fly_times = get_remain_fly_times(RoleID,LastFlyTime,FlyTimes),
                                    pet_training_list=transfer(PetTrainingList)},
    common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R).

%% --------------开始训练  默认普通的训练模式---------------------
do_start_pet_training(Unique, DataIn, RoleID, PID)->
    case catch check_can_start_pet_training(DataIn,RoleID) of
        {ok,RoleMapExt,PetInfo}->
            do_start_pet_training2(Unique, DataIn, RoleID, PID, RoleMapExt,PetInfo);
        {error,Reason,ReasonCode}->
            do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode)
    end.

check_can_start_pet_training(#m_pet_training_request_tos{pet_id=PetID,training_hours=TrainingHours},RoleID)->
    case TrainingHours>0 andalso TrainingHours=<24 of
		true->
			next;
		false->
			erlang:throw({error,?_LANG_PET_TRAINING_HOURS_ILLEGAL,0})
	end,
	{ok,#r_role_map_ext{training_pets=TrainingPets}=RoleMapExt}=mod_map_role:get_role_map_ext_info(RoleID),
	% %% 检查空位(t6不在需要训练槽了)
	% case TrainingPets#r_pet_training.cur_room>erlang:length(TrainingPets#r_pet_training.pet_training_list) of
	% 	true->
	% 		next;
	% 	false->
	% 		erlang:throw({error,?_LANG_PET_ADD_TRAINING_ROOM_ENOUGH,0})
	% end,
	case lists:keyfind(PetID, #r_pet_training_detail.pet_id, TrainingPets#r_pet_training.pet_training_list) of
		false->
			next;
		_->
			erlang:throw({error,?_LANG_PET_IS_TRAINING,0})
	end,
	%%是否有这只宠    
	case mod_map_pet:check_role_has_pet(RoleID,PetID) of
		error->
			PetInfo=undefined,
			erlang:throw({error,?_LANG_PET_NOT_EXIST,0});
		{ok,PetInfo}->
			next
	end,
	case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
		PetID ->
			PetInfo1 = mod_role_tab:get(RoleID, {?ROLE_PET_INFO,PetID});
		_->
			PetInfo1 = PetInfo
	end,
	{ok,RoleMapExt,PetInfo1}.

setup_pet_training_timer(RoleID, PetID, SpaceTime) ->
    erlang:send_after((SpaceTime + 1)*1000, self(), {?MODULE, {pet_training_timer, RoleID, PetID}}).

do_start_pet_training2(Unique, DataIn, RoleID, PID, RoleMapExt,PetInfo)->
    Now = mgeem_map:get_now(),
    PetLevel = PetInfo#p_pet.level,
	{_FlyMaxTimes,_CostSilver,TrainingCostDiscount} = vip_training_fly_conf(RoleID),
	TrainingCost = common_tool:ceil(math:pow(PetLevel, 1.4)*erlang:abs(DataIn#m_pet_training_request_tos.training_hours)*TrainingCostDiscount),
	case common_transaction:transaction(fun()-> t_start_pet_training(RoleID,DataIn,RoleMapExt,TrainingCost,Now) end) of
		{aborted, {Reason,ReasonCode}} ->
			do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode);
		{atomic, {ok,NewTrainingPets,NewRoleAttr}} ->
			write_pet_training_log(RoleID,
								   NewRoleAttr#p_role_attr.role_name,
								   DataIn#m_pet_training_request_tos.training_hours,
								   DataIn#m_pet_training_request_tos.pet_id,
								   PetLevel,
								   TrainingCost),
            %% 特殊任务事件
            % hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_PET_TRAINING),
            mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_PET_TRAINING]}),
            %% 完成活动
            hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_PET_TRAIN),
            
            setup_pet_training_timer(RoleID, DataIn#m_pet_training_request_tos.pet_id, ?ADD_EXP_SPACE_TIME),
			R = #m_pet_training_request_toc{op_type=DataIn#m_pet_training_request_tos.op_type,
											cur_room=NewTrainingPets#r_pet_training.cur_room,
											pet_training_list=transfer(NewTrainingPets#r_pet_training.pet_training_list)},
			common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R),
			?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("开始训练成功，花费~s钱币",[common_misc:format_silver(TrainingCost)])),
			common_misc:send_role_silver_change(RoleID, NewRoleAttr)
	end.
                     
t_start_pet_training(RoleID,DataIn,#r_role_map_ext{training_pets=TrainingPets}=RoleMapExt,Cost,Now)->
    NewRoleAttr=
        case common_bag2:t_deduct_money(silver_any,Cost,RoleID,?CONSUME_TYPE_SILVER_PET_TRAINING_START) of
            {ok,RoleAttr}->
                RoleAttr;
            {error, Reason} ->
                db:abort({Reason,1});
            _ ->
                db:abort({?_LANG_NOT_ENOUGH_SILVER,1})
        end,
    #r_pet_training{pet_training_list=PetTrainingList}=TrainingPets,
    NewPetTrainingList = [#r_pet_training_detail{pet_id=DataIn#m_pet_training_request_tos.pet_id,
                                training_start_time=Now,
                                training_end_time=Now+DataIn#m_pet_training_request_tos.training_hours*3600,
                                last_add_exp_time=Now,
                                next_add_exp_time=Now+?ADD_EXP_SPACE_TIME,
                                training_mode=?TRAINING_MODE_1,
                                total_get_exp=0}|PetTrainingList],
    NewTrainingPets = TrainingPets#r_pet_training{pet_training_list=NewPetTrainingList},
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt#r_role_map_ext{training_pets=NewTrainingPets}),
    {ok,NewTrainingPets,NewRoleAttr}.

%% ------------------------终止训练----------------------------   
do_stop_pet_training(Unique, DataIn, RoleID, PID)->
    case catch check_can_stop_pet_training(DataIn, RoleID) of
        {ok,RoleMapExt,TrainingPets,PetTrainingInfo}->
            do_stop_pet_training2(Unique, DataIn, RoleID, PID, RoleMapExt,TrainingPets,PetTrainingInfo);
        {error,Reason,ReasonCode}->
            do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode)
    end.

check_can_stop_pet_training(#m_pet_training_request_tos{pet_id=PetID},RoleID)->
    {ok,#r_role_map_ext{training_pets=TrainingPets}=RoleMapExt}=mod_map_role:get_role_map_ext_info(RoleID),
    case lists:keyfind(PetID, #r_pet_training_detail.pet_id, TrainingPets#r_pet_training.pet_training_list) of
        false->
            PetTrainingInfo=undefined,
            erlang:throw({error,?_LANG_PET_IS_FREE,0});
        PetTrainingInfo->
            next
    end,
    %%是否有这只宠    
    case mod_map_pet:check_role_has_pet(RoleID,PetID) of
        error->
            erlang:throw({error,?_LANG_PET_NOT_EXIST,0});
        _->
            next
    end,
    {ok,RoleMapExt,TrainingPets,PetTrainingInfo}.

do_stop_pet_training2(Unique, _DataIn, RoleID, PID,RoleMapExt,TrainingPets,PetTrainingInfo)->
    NewPetTrainingList = lists:delete(PetTrainingInfo, TrainingPets#r_pet_training.pet_training_list),
    mod_map_role:set_role_map_ext_info(
      RoleID, 
      RoleMapExt#r_role_map_ext{training_pets=TrainingPets#r_pet_training{pet_training_list = NewPetTrainingList}}),
    R = #m_pet_training_request_toc{op_type=?STOP_PET_TRAINING,
                                     cur_room = TrainingPets#r_pet_training.cur_room,
                                     pet_training_list = transfer(NewPetTrainingList),
                                     pet_training_info = transfer(PetTrainingInfo)},
    common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R).



%% --------------------------突飞猛进--------------------------
%% do_fly_pet_training(Unique, DataIn, RoleID, PID)->
%%      Now =mgeem_map:get_now(),
%%     case catch check_can_fly_pet_training(DataIn,RoleID,Now) of
%%         {ok,RoleMapExt,TrainingPets}->
%%             do_fly_pet_training2(Unique, DataIn, RoleID, PID, RoleMapExt,TrainingPets,Now);
%%         {error,Reason,ReasonCode}->
%%             do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode)
%%     end.

%% check_can_fly_pet_training(#m_pet_training_request_tos{pet_id=PetID},RoleID,Now)->
%%     {ok,#r_role_map_ext{training_pets=TrainingPets}=RoleMapExt}=mod_map_role:get_role_map_ext_info(RoleID),
%%     case lists:keyfind(PetID, #r_pet_training_detail.pet_id, TrainingPets#r_pet_training.pet_training_list) of
%%         false->
%%             erlang:throw({error,?_LANG_PET_IS_FREE,0});
%%         _PetTrainingDetail->
%%             next
%%     end,
%%     case TrainingPets#r_pet_training.fly_cd_end_time-Now > ?FLY_TRAINING_MAX_CD_TIME of
%%         true->
%%             erlang:throw({error,?_LANG_PET_FLY_TRAINING_CDING,0});
%%         false->
%%             next
%%     end,
%% 	case get_remain_fly_times(RoleID,TrainingPets#r_pet_training.last_fly_time,TrainingPets#r_pet_training.fly_times) =< 0 of
%% 		true ->
%%             erlang:throw({error,?_LANG_PET_SILVER_FLY_MAX_TIMES,0});
%% 		false ->
%% 			next
%% 	end,
%%     {ok,RoleMapExt,TrainingPets}.
%% 
%% do_fly_pet_training2(Unique, DataIn, RoleID, PID, RoleMapExt,TrainingPets,Now)->
%%     {ok,RoleAttr}=mod_map_role:get_role_attr(RoleID),
%% 	#m_pet_training_request_tos{pet_id=PetID,op_type=OpType} = DataIn,
%% 	#r_pet_training{fly_cd_end_time=FlyCDEndTime,fly_times=FlyTimes,last_fly_time=LastFlyTime} = TrainingPets,
%% 	AddExp = get_fly_pet_training_addexp(RoleAttr,PetID),
%%     case db:transaction(
%%            fun()-> 
%% 				   {FlyMaxTimes,CostSilver,_TrainingCostDiscount} = vip_training_fly_conf(RoleID),
%% 				   NewRoleAttr =
%% 					   case common_bag2:t_deduct_money(silver_any,CostSilver,RoleAttr,?CONSUME_TYPE_SILVER_FLY_PET_TRAINING) of
%% 						   {ok,RoleAttr2}->
%% 							   mod_map_role:set_role_attr(RoleID, RoleAttr2),
%% 							   RoleAttr2;
%% 						   _ ->
%% 							   db:abort({?_LANG_PET_TRAINING_SILVER_FLY_NOT_ENOUGH,0})
%% 					   end,
%% 				   {ok,NewPetInfo,_RealAddExp,NoticeType} = mod_map_pet:t_common_add_pet_exp(RoleID,PetID,AddExp,fly),
%% 				   case FlyCDEndTime < Now of
%% 					   true->
%% 						   NewFlyCDEndTime = Now+?CUT_FLY_CD_TIME;
%% 					   false->
%% 						   NewFlyCDEndTime = FlyCDEndTime+?CUT_FLY_CD_TIME
%% 				   end,
%% 				   NewFlyTimes = FlyMaxTimes-get_remain_fly_times(RoleID,LastFlyTime,FlyTimes)+1,
%% 				   NewTrainingPets = TrainingPets#r_pet_training{fly_cd_end_time=NewFlyCDEndTime,
%% 																 fly_times=NewFlyTimes,last_fly_time=Now},
%% 				   mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt#r_role_map_ext{training_pets=NewTrainingPets}),
%%                    {ok,NewPetInfo,NoticeType,NewRoleAttr,NewFlyCDEndTime,NewFlyTimes,CostSilver}
%%            end) of
%%         {aborted, {full_level,Reason}} ->
%%             do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,undefined);
%%         {aborted, {Reason,ReasonCode}} ->
%%             do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode);
%%         {atomic, {ok,NewPetInfo,NoticeType,NewRoleAttr,NewFlyCDEndTime,NewFlyTimes,CostSilver}} ->
%%             mod_map_pet:notice_after_add_exp(RoleID, NoticeType, NewPetInfo),
%%             mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_6),
%%             %% 特殊任务事件
%%             hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_PET_FLY_TRAINING_SILVER),
%% 			common_misc:send_role_silver_change(RoleID, NewRoleAttr),
%% 			?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("钱币突飞成功，花费~s钱币，异兽获得~w经验",[common_misc:format_silver(CostSilver),AddExp])),
%% 			{FlyMaxTimes,CostSilver,_TrainingCostDiscount} = vip_training_fly_conf(RoleID),
%% 			R1 = #m_pet_training_request_toc{op_type=OpType,add_exp=get_fly_pet_training_addexp(RoleID,PetID),
%% 											 cost_silver=CostSilver,
%% 											 remain_fly_times = get_remain_fly_times(RoleID,Now,NewFlyTimes),
%% 											 max_fly_times=FlyMaxTimes,
%% 											 cur_room = TrainingPets#r_pet_training.cur_room,
%% 											 fly_cd_end_time = NewFlyCDEndTime},
%% 			common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R1)
%%     end.

%% --------------------------元宝突飞猛进--------------------------
do_gold_fly_pet_training(Unique, DataIn, RoleID, PID)->
	#m_pet_training_request_tos{pet_id=PetID,op_type=OpType,training_hours=FlyNum} = DataIn,
	case db:transaction(fun()-> t_gold_fly_pet_training(RoleID,PetID,erlang:abs(FlyNum)) end ) of
		{atomic, {ok,RoleAttr,NoticeType,NewPetInfo,ActualDeductMoney,ActualFlyNum,ActualAddExp}} ->
			AttrChangeList = [#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value = RoleAttr#p_role_attr.gold_bind},
                              #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value = RoleAttr#p_role_attr.gold}],
			common_misc:role_attr_change_notify({role, RoleID},RoleID,AttrChangeList),
            
            mod_map_pet:notice_after_add_exp(RoleID, NoticeType, NewPetInfo),
            
			?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("礼券突飞成功~w次，花费~w礼券，灵宠获得~w经验",[ActualFlyNum,ActualDeductMoney,ActualAddExp])),
			{_FlyMaxTimes,CostSilver,_TrainingCostDiscount} = vip_training_fly_conf(RoleID),
            %% 完成成就
            mod_achievement2:achievement_update_event(RoleID, 23005, 1),
            mod_achievement2:achievement_update_event(RoleID, 32003, 1),
            mod_achievement2:achievement_update_event(RoleID, 34001, 1),
			mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_6),
            mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_TF, FlyNum}),
			R1 = #m_pet_training_request_toc{op_type=OpType,cost_silver=CostSilver,
											 add_exp=get_fly_pet_training_addexp(RoleID,PetID)},
            % hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_PET_FLY_TRAINING_GOLD),
            mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_PET_FLY_TRAINING_GOLD]}),
			common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R1);
		{aborted, {full_level,Reason}} ->
			do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,0);
		{aborted, {Reason,ReasonCode}} ->
			do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode)
	end.

t_gold_fly_pet_training(RoleID,PetID,FlyNum) ->
	[{BaseNeedMoney,BaseAddExp}] = common_config_dyn:find(pet_training, gold_fly),
	{ok, RoleAttr0} = mod_map_role:get_role_attr(RoleID),
    RoleGold = RoleAttr0#p_role_attr.gold + RoleAttr0#p_role_attr.gold_bind,
    {ActualDeductMoney,ActualFlyNum} = calc_gold_fly_deduct_money(RoleGold,BaseNeedMoney,FlyNum),
    case common_bag2:t_deduct_money(gold_any,ActualDeductMoney,RoleID,?CONSUME_TYPE_GOLD_FLY_PET_TRAINING) of
        {ok,RoleAttr}->
            ActualAddExp = BaseAddExp * ActualFlyNum,
            {ok,NewPetInfo,_RealAddExp,NoticeType} = mod_map_pet:t_common_add_pet_exp(RoleID,PetID,ActualAddExp,fly),
            {ok,RoleAttr,NoticeType,NewPetInfo,ActualDeductMoney,ActualFlyNum,ActualAddExp};
        {error,gold_unbind}->
            db:abort({?_LANG_PET_TRAINING_GOLD_FLY_NOT_ENOUGH,0});
        {error, Reason} ->
            db:abort({Reason,0});
        _Other ->
            db:abort({?_LANG_PET_TRAINING_GOLD_FLY_NOT_ENOUGH,0})
    end.

calc_gold_fly_deduct_money(RoleMoney,NeedMoney,FlyNum) ->
	Fee = NeedMoney * FlyNum,
	if RoleMoney < Fee ->
		   FlyTimes = RoleMoney div NeedMoney,
		   DeductGold = 
			   case FlyTimes > 0 of
				   true ->
					   NeedMoney * FlyTimes;
				   false ->
					   db:abort({?_LANG_PET_TRAINING_GOLD_FLY_NOT_ENOUGH,0})
			   end,
		   {DeductGold,FlyTimes};
	   true ->
		   {Fee,FlyNum}
	end.

%% ------------清除突飞猛进冷却时间---------------
do_reset_pet_fly_training_cd_time(Unique, DataIn, RoleID, PID)->
    Now = mgeem_map:get_now(),    
    case catch check_can_reset_pet_fly_training_cd_time(RoleID,Now) of
        {ok,RoleMapExt,TrainingPets}->
            do_reset_pet_fly_training_cd_time2(Unique, DataIn, RoleID, PID, RoleMapExt,TrainingPets,Now);
        {error,Reason,ReasonCode}->
            do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode)
    end.

check_can_reset_pet_fly_training_cd_time(RoleID,Now)->
    {ok,#r_role_map_ext{training_pets=TrainingPets}=RoleMapExt}=mod_map_role:get_role_map_ext_info(RoleID),
    case TrainingPets#r_pet_training.fly_cd_end_time<Now of
        true->
            erlang:throw({error,?_LANG_PET_NEED_NOT_TO_RESET_FLY_CD_TIME,0});
        false->
            next
    end,
    {ok,RoleMapExt,TrainingPets}.

do_reset_pet_fly_training_cd_time2(Unique, DataIn, RoleID, PID, RoleMapExt,TrainingPets,Now)->
    case common_transaction:transaction(fun()->t_reset_pet_fly_training_cd_time(RoleID,RoleMapExt,TrainingPets,Now) end ) of
        {atomic, {ok,NewRoleAttr,NewFlyCDEndTime,Cost}} ->
            R=#m_pet_training_request_toc{op_type=DataIn#m_pet_training_request_tos.op_type,
                                          fly_cd_end_time=NewFlyCDEndTime},
            common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R),
			?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("秒完成功，花费~w元宝",[Cost])),
            common_misc:send_role_gold_change(RoleID, NewRoleAttr);
        {aborted, {Reason,ReasonCode}} ->
            do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode);
        {aborted, {error, ErrorCode, ErrorStr}} ->
            common_misc:send_common_error(RoleID, ErrorCode, ErrorStr)
    end.

t_reset_pet_fly_training_cd_time(RoleID,RoleMapExt,TrainingPets,Now)->
	CDTime =TrainingPets#r_pet_training.fly_cd_end_time-Now,
	Cost=common_tool:ceil(CDTime/?RESET_PET_FLY_TRAINING_BASE_CD_TIME)*?RESET_PET_FLY_TRAINING_CD_TIME_COST,
    common_bag2:check_money_enough_and_throw(gold_any,Cost,RoleID),
	NewTrainingPets = TrainingPets#r_pet_training{fly_cd_end_time=0},
	mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt#r_role_map_ext{training_pets=NewTrainingPets}),
    NewRoleAttr =
        case common_bag2:t_deduct_money(gold_any,Cost,RoleID,?CONSUME_TYPE_GOLD_RESET_FLY_TRAINING_CD_TIME) of
            {ok,RoleAttr2}->
                RoleAttr2;
            {error, Reason} ->
                db:abort({Reason,2});
            _ ->
                db:abort({?_LANG_NOT_ENOUGH_GOLD,2})
        end,
	{ok,NewRoleAttr,0,Cost}.



%% -------------------训练模式设置------------------------
do_set_pet_training_mode(Unique,DataIn,RoleID,PID)->
    case catch check_can_set_pet_training_mode(DataIn,RoleID) of
        {ok,RoleMapExt,TrainingPets,PetTrainingDetail}->
            do_set_pet_training_mode2(Unique, DataIn, RoleID, PID, RoleMapExt,TrainingPets,PetTrainingDetail);
        {error,Reason,ReasonCode}->
            do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode)
    end.

check_can_set_pet_training_mode(#m_pet_training_request_tos{pet_id=PetID,training_mode=TrainingMode},RoleID)->
    {ok,#r_role_map_ext{training_pets=TrainingPets}=RoleMapExt}=mod_map_role:get_role_map_ext_info(RoleID),
    case lists:keyfind(PetID, #r_pet_training_detail.pet_id, TrainingPets#r_pet_training.pet_training_list) of
        false->
            PetTrainingDetail=undefined,
            erlang:throw({error,?_LANG_PET_IS_FREE,0});
        PetTrainingDetail->
            next
    end,
    if TrainingMode=<PetTrainingDetail#r_pet_training_detail.training_mode 
         orelse  TrainingMode =< 1 
         orelse TrainingMode>5 ->
            erlang:throw({error,?_LANG_PET_TRAINING_MODE_ILLEGAL,0});
       TrainingMode >=3 ->
           VipLevel = mod_vip:get_role_vip_level(RoleID),
           case TrainingMode-2 > VipLevel of
               true->
                   erlang:throw({error,?_LANG_PET_TRAINING_NOT_VIP,0});
               false->
                   next
           end;
       true->
           next
    end,
    {ok,RoleMapExt,TrainingPets,PetTrainingDetail}.
  
do_set_pet_training_mode2(Unique, DataIn, RoleID, PID, RoleMapExt,TrainingPets,PetTrainingDetail)->
    TrainingMode = DataIn#m_pet_training_request_tos.training_mode,
    [{_,GoldCost}] = common_config_dyn:find(pet_training, {training_mode,TrainingMode}),
    case common_transaction:transaction(
           fun()->t_set_pet_training_mode(RoleID,RoleMapExt,TrainingPets,PetTrainingDetail,GoldCost,TrainingMode) end ) of
        {atomic, {ok,NewRoleAttr,NewPetTrainingDetail}} ->
            R=#m_pet_training_request_toc{op_type=DataIn#m_pet_training_request_tos.op_type,
                                          pet_training_info=transfer(NewPetTrainingDetail)},
            common_misc:unicast2(PID, Unique, ?PET, ?PET_TRAINING_REQUEST, R),
            common_misc:send_role_gold_change(RoleID, NewRoleAttr);
        {aborted, {Reason,ReasonCode}} ->
            do_pet_training_error({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID},Reason,ReasonCode);
        {aborted, {error, ErrorCode, ErrorStr}} ->
            common_misc:send_common_error(RoleID, ErrorCode, ErrorStr)
    end.

t_set_pet_training_mode(RoleID,RoleMapExt,TrainingPets,PetTrainingDetail,Cost,TrainingMode)->
    common_bag2:check_money_enough_and_throw(gold_any,Cost,RoleID),
    NewPetTrainingDetail=PetTrainingDetail#r_pet_training_detail{training_mode=TrainingMode},
    NewPetTrainingList = [NewPetTrainingDetail|lists:delete(PetTrainingDetail,TrainingPets#r_pet_training.pet_training_list)],
    NewTrainingPets = TrainingPets#r_pet_training{pet_training_list=NewPetTrainingList},
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt#r_role_map_ext{training_pets=NewTrainingPets}),
    NewRoleAttr=
    case common_bag2:t_deduct_money(gold_any,Cost,RoleID,?CONSUME_TYPE_GOLD_PET_CHANGE_TRAINING_MODE) of
        {ok,RoleAttr}->
            RoleAttr;
        {error, Reason} ->
            db:abort({Reason,2});
        _ ->
            db:abort({?_LANG_NOT_ENOUGH_GOLD,2})
    end,
    {ok,NewRoleAttr,NewPetTrainingDetail}.

do_pet_training_error({Unique, Module, Method, DataRecord, _RoleId, PId},Reason,ReasonCode)
    when erlang:is_record(DataRecord,m_pet_training_request_tos)->
    TocRecord = #m_pet_training_request_toc{op_type=DataRecord#m_pet_training_request_tos.op_type,
                                            succ= false,
                                            reason=Reason,
                                            reason_code=ReasonCode},
    common_misc:unicast2(PId, Unique, Module, Method, TocRecord);
do_pet_training_error({RoleID,Module,Method,OpType},Reason,ReasonCode)->
    TocRecord = #m_pet_training_request_toc{op_type=OpType,
                                            succ= false,
                                            reason=Reason,
                                            reason_code=ReasonCode},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, Module, Method, TocRecord).

transfer(List) when is_list(List)->
    [transfer(Detail)||Detail<-List];
transfer(Detail) when is_record(Detail,r_pet_training_detail)->
    #p_pet_training_info{pet_id = Detail#r_pet_training_detail.pet_id,
                         training_start_time = Detail#r_pet_training_detail.training_start_time,
                         training_end_time = Detail#r_pet_training_detail.training_end_time,
                         training_mode = Detail#r_pet_training_detail.training_mode,
                         total_get_exp = Detail#r_pet_training_detail.total_get_exp};
transfer(Info)->Info.

write_pet_training_log(RoleID,RoleName,TrainingHours,PetID,PetLevel,TrainingCost) ->
    catch global:send(mgeew_pet_log_server,{log_pet_training,{RoleID,RoleName,TrainingHours,PetID,PetLevel,TrainingCost}}).

%% 特殊经验计算方法
get_common_add_pet_exp(AddExpArg,Level,special) ->
	#pet_training_exp{add_exp=AddExpConfig} = cfg_pet_training:training_exp(Level),
	AddExpArg * AddExpConfig;
get_common_add_pet_exp(AddExpArg,_Level,_Other) ->
	AddExpArg.

get_fly_pet_training_addexp(RoleAttr,PetID) when is_record(RoleAttr,p_role_attr)->
	#p_role_attr{role_id=RoleID, level=RoleLevel} = RoleAttr,
	case mod_map_pet:get_pet_info(RoleID, PetID) of
		undefined ->
			db:abort({?_LANG_PET_NOT_VALID,0});
		PetInfo ->
			#p_pet{level=Level,period=Period} = PetInfo,
            #pet_level{next_level_exp=NextLevelExp} = cfg_pet_level:level_info(Level),
			RoleLevelArg = RoleLevel div 100,
            if
                Period > 3 ->
                    erlang:trunc(erlang:max((NextLevelExp div erlang:max((40 * common_tool:to_integer(math:pow(Period,2)) div erlang:max(RoleLevelArg,1)),1)),1));
                true ->
                    erlang:trunc(erlang:max((NextLevelExp div erlang:max((20 * Period div erlang:max(RoleLevelArg,1)),1)),1))
            end
	end;
get_fly_pet_training_addexp(RoleID,PetID) ->
	case mod_map_role:get_role_attr(RoleID) of
		{ok,RoleAttr} ->
			get_fly_pet_training_addexp(RoleAttr,PetID);
		_ ->
			db:abort({?_LANG_PET_NOT_VALID,0})
	end.

get_remain_fly_times(RoleID,LastFlyTime,FlyTimes) ->
	{FlyMaxTimes,_CostSilver,_TrainingCostDiscount} = vip_training_fly_conf(RoleID),
	case FlyTimes > FlyMaxTimes of
		true ->
			FlyMaxTimes;
		false ->
			case common_time:time_to_date(LastFlyTime) =:= common_time:time_to_date(mgeem_map:get_now()) of
				true ->
					erlang:max(FlyMaxTimes-FlyTimes,0);
				false ->
					FlyMaxTimes
			end
	end.

vip_training_fly_conf(RoleID) ->
    VipLevel = mod_vip:get_role_vip_level(RoleID),
	[List] = common_config_dyn:find(pet_training,vip_training_fly),
	case lists:keyfind(VipLevel, 1, List) of
		false ->
			{?SILVER_FLY_MAX_TIMES,?SILVER_FLY_COST,1};
		{_,FlyMaxTimes,CostSilver,TrainingCostDiscount} ->
			{FlyMaxTimes,CostSilver,TrainingCostDiscount}
	end.

%% ========================吃宠物卡得经验================================
-define(ERR_EAT_CARD_VIP_LV, <<"您的vip等级不足，不能使用一键吞噬功能">>).
-define(ERR_EAT_CARD_NO_CARD, <<"您的背包中没有对应的宠物卡了">>).
-define(ERR_EAT_CARD_NOT_TRAINING, <<"宠物不在训练中，不能吞噬宠物卡">>).
-define(ERR_EAT_CARD_NO_ANY_CARD, <<"您的背包中没有任何的宠物卡">>).

%% 宠物卡的物品类型id
% -define(ITEM_TYPE_ID_PET_CARD,  14110005).
-define(ITEM_TYPE_ID_PET_CARD,  10100080).

-define(_assert(Condition, Reason), 
        case Condition of true -> ok; _ -> throw(Reason) end).

eat_pet_card(RoleID, DataIn) ->
    case common_transaction:t(fun() -> t_eat_pet_card(RoleID, DataIn) end) of
        {atomic, {true, NewPetInfo, AddExp}} ->
            %% 通知客户端
            Msg = #m_pet_eat_pet_card_toc{
                pet_id   = DataIn#m_pet_eat_pet_card_tos.pet_id,
                gain_exp = AddExp
            },
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_EAT_PET_CARD, Msg),
            Msg2 = #m_pet_info_toc{succ=true, pet_info=NewPetInfo},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_INFO, Msg2),
			mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_8);
        {aborted, {common_error, Reason}} ->
            common_misc:send_common_error(RoleID, 0, Reason);
        {aborted, {full_level, Reason}} ->
            common_misc:send_common_error(RoleID, 0, Reason);
        {aborted, no_pet_info} ->
            common_misc:send_common_error(RoleID, 0, ?_LANG_PET_NOT_EXIST)
    end.

t_eat_pet_card(RoleID, DataIn) ->
    PetID    = DataIn#m_pet_eat_pet_card_tos.pet_id,
    CardIds  = DataIn#m_pet_eat_pet_card_tos.card_ids,
    IsEatAll = DataIn#m_pet_eat_pet_card_tos.is_eat_all,
    %% check是否在训练中
    {true, UsedItemIds1, RealAddExp1} = case IsEatAll of
        true ->
            %% 若是一键吞噬的话，还要检测是否有可用的宠物卡
            Fun = fun(ItemId, Acc) ->
                case mod_bag:check_inbag(RoleID, ItemId) of
                    {error,not_found} ->
                        throw({common_error, ?_LANG_PARAM_ERROR});
                    {ok, GoodsInfo} -> 
                        [GoodsInfo | Acc]
                end
            end,
            CardGoodsRecList = lists:foldl(Fun, [], CardIds),
            Exp = get_eat_card_exp(CardGoodsRecList),
            {ok, NewPetInfo, RealAddExp, _NoticeType} = 
                    mod_map_pet:t_common_add_pet_exp(RoleID, PetID, Exp, eat_card),
            UsedItemIds = get_used_goods_list(CardGoodsRecList, RealAddExp),
            {true, UsedItemIds, RealAddExp};
        false ->
            %% 不是一键吞噬的话，要判断是否背包有对应的宠物卡
            [CardId | _] = CardIds,
            case mod_bag:check_inbag(RoleID, CardId) of
                {ok, CardPGoodsRec} -> ok;
                _ ->
                    CardPGoodsRec = [],
                    throw({common_error, ?ERR_EAT_CARD_NO_CARD})
            end,
            Exp = get_eat_card_exp(CardPGoodsRec),
            {ok, NewPetInfo, RealAddExp, _NoticeType} = 
                    mod_map_pet:t_common_add_pet_exp(RoleID, PetID, Exp, eat_card),
            {true, [CardId], RealAddExp}
    end,
    LogType = ?LOG_ITEM_TYPE_PET_EAT_LOST,
    {ok, DeleteList} = mod_bag:delete_goods(RoleID, UsedItemIds1),
    common_item_logger:log(RoleID, DeleteList, LogType),
    common_misc:del_goods_notify({role, RoleID}, DeleteList),
    {true, NewPetInfo, RealAddExp1}.

get_eat_card_exp(CardPGoodsRec) when is_record(CardPGoodsRec, p_goods) ->
    cfg_pet_training:get_exp(CardPGoodsRec#p_goods.typeid) * CardPGoodsRec#p_goods.current_num;
get_eat_card_exp(CardGoodsRecList) when is_list(CardGoodsRecList) ->
    Fun = fun(CardPGoodsRec, Acc) ->
        cfg_pet_training:get_exp(CardPGoodsRec#p_goods.typeid) * CardPGoodsRec#p_goods.current_num + Acc
    end,
    lists:foldl(Fun, 0, CardGoodsRecList).

%% 从CardGoodsRecList按次序选出加的经验值>=RealAddExp时所使用的物品list
%% notice: 因为宠物卡是不能叠加的，因此这里可以这样计数的
get_used_goods_list(CardGoodsRecList, RealAddExp) ->
    get_used_goods_list(CardGoodsRecList, RealAddExp, 0, []).

get_used_goods_list([], _RealAddExp, _TotalExp, UsedItemIds) -> UsedItemIds;
get_used_goods_list([CardPGoodsRec | Rest], RealAddExp, TotalExp, UsedItemIds) ->
    TotalExp1 = CardPGoodsRec#p_goods.exp + TotalExp,
    UsedItemIds1 = [CardPGoodsRec#p_goods.id | UsedItemIds],
    case TotalExp1 >= RealAddExp of
        true ->
            UsedItemIds1;
        false ->
            get_used_goods_list(Rest, RealAddExp, TotalExp1, UsedItemIds1)
    end.


