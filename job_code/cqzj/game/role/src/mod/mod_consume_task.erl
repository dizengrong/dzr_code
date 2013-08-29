%%消费任务（大R线）
-module(mod_consume_task).

-include("mgeer.hrl").

-export([init/2, delete/1, start/1, handle/1, handle_event/3, hook_role_online/1]).

-define(STATUS_INIT, 0).
-define(STATUS_DONE, 1).

-define(_common_error,			?DEFAULT_UNIQUE,	?COMMON,		?COMMON_ERROR,			#m_common_error_toc).%}
-define(_consume_task_info,		?DEFAULT_UNIQUE,	?CONSUME_TASK,	?CONSUME_TASK_INFO,		#m_consume_task_info_toc).%}
-define(_consume_task_notice,	?DEFAULT_UNIQUE,	?CONSUME_TASK,	?CONSUME_TASK_NOTICE,	#m_consume_task_notice_toc).%}
-define(_goods_update,			?DEFAULT_UNIQUE,	?GOODS,			?GOODS_UPDATE,			#m_goods_update_toc).%}

init(RoleID, Task) when is_record(Task, r_consume_task) ->
	mod_role_tab:put({r_consume_task, RoleID}, Task),
	case is_task_done(Task#r_consume_task.status) of
		true -> ignore;
		_ ->
			Events = cfg_consume_task:events(Task#r_consume_task.id),
			add_event_handler(RoleID, Events)
	end;
init(_RoleID, _) -> ignore.

delete(RoleID) ->
	mod_role_tab:get({r_consume_task, RoleID}).

hook_role_online(RoleID) ->
	Task = mod_role_tab:get({r_consume_task, RoleID}),
	is_record(Task, r_consume_task) andalso
		common_misc:unicast({role, RoleID}, ?_consume_task_notice{}).

start(RoleID) ->
	Task = mod_role_tab:get({r_consume_task, RoleID}),
	case is_record(Task, r_consume_task) of
		true -> ignore;
		_ ->
			start_new_task(RoleID, 1),
			common_misc:unicast({role, RoleID}, ?_consume_task_notice{})
	end.

handle({_Unique, ?CONSUME_TASK, ?CONSUME_TASK_INFO, _DataIn, RoleID, PID, _Line}) ->
	case mod_role_tab:get({r_consume_task, RoleID}) of
		#r_consume_task{id = TaskID, status = TaskStatus} ->
			{_, TaskStatus2} = lists:foldl(fun
				({_, S, _}, {I, L}) ->
					{I+1, [{I, S}|L]}
			end, {1, []}, TaskStatus),
			common_misc:unicast2(PID, ?_consume_task_info{
				task_id     = TaskID,
				task_status = TaskStatus2,
				task_reward = cfg_consume_task:reward(TaskID)
			});
		_ ->
			ignore
	end;

%%领取奖励
handle({Unique, ?CONSUME_TASK, ?CONSUME_TASK_DRAW, _DataIn, RoleID, PID, Line}) ->
	case mod_role_tab:get({r_consume_task, RoleID}) of
		#r_consume_task{id = TaskID, status = TaskStatus} ->
			case do_task_draw(RoleID, TaskID, TaskStatus) of
				{ok, UpdateList, CreateInfos} ->
					start_new_task(RoleID, TaskID + 1),
					common_misc:unicast2(PID, ?_goods_update{goods = UpdateList}),
					common_item_logger:log(RoleID, 
						CreateInfos, ?LOG_ITEM_TYPE_CONSUME_TASK_AWARD),
					handle({Unique, ?CONSUME_TASK, 
						?CONSUME_TASK_INFO, nil, RoleID, PID, Line});
				{error, Reason} ->
					common_misc:unicast2(PID, ?_common_error{error_str = Reason});
				_ ->
					ignore
			end;
		_ ->
			ignore
	end.

do_task_draw(RoleID, TaskID, TaskStatus) ->
	case is_task_done(TaskStatus) of
		true ->
			CreateInfos = [#r_goods_create_info{
				bind    = true, 
				type    = TypeID div 10000000,
				type_id = TypeID, 
				num     = Num
			}||{TypeID, Num}<-cfg_consume_task:reward(TaskID)],
			case common_transaction:t(fun
					()-> 
						mod_bag:create_goods(RoleID, CreateInfos)
				 end) of
				{atomic, {ok, UpdateList}} ->
					{ok, UpdateList, CreateInfos};
				{aborted, {bag_error, {not_enough_pos, _BagID}}} ->
					{error, ?_LANG_GOODS_BAG_NOT_ENOUGH};
				{_, Error} ->
					?ERROR_LOG("create goods error: ~p", [Error]),
					error
			end;
		_ ->
			{error, <<"任务未完成">>}
	end.

is_task_done(TaskStatus) ->
	lists:all(fun
		({_, Status, _}) -> Status == ?STATUS_DONE
	end, TaskStatus).

start_new_task(RoleID, TaskID) ->
	case cfg_consume_task:events(TaskID) of
		[]     -> ignore;
		Events ->
			Status = lists:foldr(fun
				({EventTag, _}, Acc) ->
					[{EventTag, ?STATUS_INIT, 0}|Acc]
			end, [], Events),
			Task = #r_consume_task{id = TaskID, status = Status},
			mod_role_tab:put({r_consume_task, RoleID}, Task),
			add_event_handler(RoleID, Events),
			trigger_event(RoleID, Events)
	end.

add_event_handler(RoleID, Events) ->
	lists:foreach(fun
		({EventTag, Args}) ->
			mod_role_event:add_handler(RoleID, EventTag, {?MODULE, Args})
	end, Events).

delete_event_handler(RoleID, EventTag) ->
	mod_role_event:delete_handler(RoleID, EventTag, ?MODULE).

trigger_event(RoleID, Events) ->
	lists:foreach(fun
		({?ROLE_EVENT_VIP_LV, Args}) ->
			VipLevel = mod_vip:get_role_vip_level(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_VIP_LV, VipLevel}, Args);
		({PetEvent, Args}) when PetEvent == ?ROLE_EVENT_PET_GET;
								PetEvent == ?ROLE_EVENT_PET_LV;
								PetEvent == ?ROLE_EVENT_PET_ZZ;
								PetEvent == ?ROLE_EVENT_PET_WX ->
			PetBag = mod_map_pet:get_role_pet_bag_info(RoleID),
			lists:foreach(fun
				(#p_pet_id_name{pet_id = PetID}) ->
					PetInfo = mod_map_pet:get_pet_info(RoleID, PetID),
					handle_event(RoleID, {PetEvent, PetInfo}, Args)
			end, PetBag#p_role_pet_bag.pets);
		({?ROLE_EVENT_PET_CZ, Args}) ->
			PetBag = mod_map_pet:get_role_pet_bag_info(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_PET_CZ, PetBag}, Args);
		({?ROLE_EVENT_PET_GROW, Args}) ->
			GrowInfo = mod_pet_grow:get_role_pet_grow_info(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_PET_GROW, GrowInfo}, Args);
		({?ROLE_EVENT_SKILL_LV, Args}) ->
			SkillList = lists:foldr(fun
		    	(#r_role_skill_info{skill_id = SkillID, cur_level = CurLevel}, Acc) ->
					[ #p_role_skill{skill_id = SkillID, cur_level = CurLevel}|Acc]
			end, [], mod_role_skill:get_role_skill_list(RoleID)),
			handle_event(RoleID, {?ROLE_EVENT_SKILL_LV, SkillList}, Args);
		({?ROLE_EVENT_FASHION_GET, Args}) ->
			#r_role_fashion{
				fashion = Fashion,
				wings   = Wings,
				mounts  = Mounts
			} = mod_role_fashion:fetch(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_FASHION_GET, Fashion}, Args),
			handle_event(RoleID, {?ROLE_EVENT_FASHION_GET, Wings}, Args),
			handle_event(RoleID, {?ROLE_EVENT_FASHION_GET, Mounts}, Args);
		({?ROLE_EVENT_EQUIP_PUT, {Num, Args}}) ->
			handle_event(RoleID, {?ROLE_EVENT_EQUIP_PUT, RoleID}, {Num, Args});
		({?ROLE_EVENT_EQUIP_PUT, Args}) ->
			{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			lists:foreach(fun
				(Equip) ->
					handle_event(RoleID, {?ROLE_EVENT_EQUIP_PUT, Equip}, Args)
			end, RoleAttr#p_role_attr.equips);
		(_) -> ignore
	end, Events).

handle_event(RoleID, {EventTag, EventArgs}, Args) ->
	OldTask = mod_role_tab:get({r_consume_task, RoleID}),
	case is_record(OldTask, r_consume_task) of
		true ->
			case do_handle_event({EventTag, EventArgs}, Args, OldTask) of
				NewTask when is_record(NewTask, r_consume_task) ->
					mod_role_tab:put({r_consume_task, RoleID}, NewTask),
					NewTaskStatus = NewTask#r_consume_task.status,
					case lists:keyfind(EventTag, 1, NewTaskStatus) of
						{_, ?STATUS_DONE, _} ->
							delete_event_handler(RoleID, EventTag);
						_ ->
							ignore
					end,
					is_task_done(NewTaskStatus) andalso
						common_misc:unicast({role, RoleID}, ?_consume_task_notice{});
				_ ->
					ignore
			end;
		_ ->
			delete_event_handler(RoleID, EventTag)
	end.

do_handle_event({?ROLE_EVENT_EQUIP_PUT, Equip}, {Num, Args}, Task) when is_integer(Num) ->
	case is_integer(Equip) orelse check_equip(Equip, Args) of
		true ->
			RoleID = if
				is_integer(Equip) ->
					Equip;
				true ->
					Equip#p_goods.roleid
			end,
			{ok, RoleAttr}  = mod_map_role:get_role_attr(RoleID),
			SatisfyEquipNum = lists:foldl(fun
				(Equip1, Sum) ->
					case check_equip(Equip1, Args) of
						true -> Sum + 1;
						_    -> Sum
					end
			end, 0, RoleAttr#p_role_attr.equips),
			SatisfyEquipNum >= Num andalso
				update_task(Task, ?ROLE_EVENT_EQUIP_PUT, ?STATUS_DONE, 0);
		_ ->
			ignore
	end;

do_handle_event({?ROLE_EVENT_EQUIP_PUT, Equip}, Args, Task) ->
	check_equip(Equip, Args) andalso
		update_task(Task, ?ROLE_EVENT_EQUIP_PUT, ?STATUS_DONE, 0);

do_handle_event({?ROLE_EVENT_FASHION_GET, Fashion}, Args, Task) ->
	check_fashion(Fashion, Args) andalso
		update_task(Task, ?ROLE_EVENT_FASHION_GET, ?STATUS_DONE, 0);

do_handle_event({?ROLE_EVENT_VIP_LV, VipLevel}, Args, Task) ->
	check_vip_level(VipLevel, Args) andalso
		update_task(Task, ?ROLE_EVENT_VIP_LV, ?STATUS_DONE, 0);

%%招财
do_handle_event({?ROLE_EVENT_ZHAO_CAI, AddCount}, _Args, Task) ->
	update_task(Task, ?ROLE_EVENT_ZHAO_CAI, ?STATUS_INIT, AddCount);

do_handle_event({?ROLE_EVENT_KILL_BOSS, BossType}, Args, Task) ->
	check_boss_type(BossType, Args) andalso
		update_task(Task, ?ROLE_EVENT_KILL_BOSS, ?STATUS_DONE, 0);

%%宠物获得
do_handle_event({?ROLE_EVENT_PET_GET, Pet}, Args, Task) ->
	check_pet(Pet, Args) andalso
		update_task(Task, ?ROLE_EVENT_PET_GET, ?STATUS_DONE, 0);

%%宠物升级
do_handle_event({?ROLE_EVENT_PET_LV, Pet}, Args, Task) ->
	check_pet(Pet, Args) andalso
		update_task(Task, ?ROLE_EVENT_PET_LV, ?STATUS_DONE, 0);

%%宠物资质
do_handle_event({?ROLE_EVENT_PET_ZZ, Pet}, Args, Task) ->
	check_pet(Pet, Args) andalso
		update_task(Task, ?ROLE_EVENT_PET_ZZ, ?STATUS_DONE, 0);

%%宠物悟性
do_handle_event({?ROLE_EVENT_PET_WX, Pet}, Args, Task) ->
	check_pet(Pet, Args) andalso
		update_task(Task, ?ROLE_EVENT_PET_WX, ?STATUS_DONE, 0);

%%宠物砸蛋
do_handle_event({?ROLE_EVENT_PET_ZD, AddCount}, _Args, Task) ->
	update_task(Task, ?ROLE_EVENT_PET_ZD, ?STATUS_INIT, AddCount);

do_handle_event({?ROLE_EVENT_PET_TF, AddCount}, _Args, Task) ->
	update_task(Task, ?ROLE_EVENT_PET_TF, ?STATUS_INIT, AddCount);

do_handle_event({?ROLE_EVENT_PET_CZ, PetBag}, Args, Task) ->
	check_pet_bag(PetBag, Args) andalso
		update_task(Task, ?ROLE_EVENT_PET_CZ, ?STATUS_DONE, 0);

do_handle_event({?ROLE_EVENT_PET_GROW, GrowInfo}, Args, Task) ->
	check_pet_grow(GrowInfo, Args) andalso
		update_task(Task, ?ROLE_EVENT_PET_GROW, ?STATUS_DONE, 0);

do_handle_event({?ROLE_EVENT_PET_EQUIP, [Pet, Equip]}, {Num, Args}, Task) when is_integer(Num) ->
	case check_equip(Equip, Args) of
		true ->
			SatisfyEquipNum = lists:foldl(fun
				(Equip1, Sum) when is_record(Equip1, p_goods) ->
					case check_equip(Equip1, Args) of
						true -> Sum + 1;
						_    -> Sum
					end;
				(_, Sum) -> Sum
			end, 0, tuple_to_list(Pet#p_pet.equips)),
			SatisfyEquipNum >= Num andalso
				update_task(Task, ?ROLE_EVENT_PET_EQUIP, ?STATUS_DONE, 0);
		_ ->
			ignore
	end;

do_handle_event({?ROLE_EVENT_PET_EQUIP, [_Pet, Equip]}, Args, Task) ->
	check_equip(Equip, Args) andalso
		update_task(Task, ?ROLE_EVENT_PET_EQUIP, ?STATUS_DONE, 0);

do_handle_event({?ROLE_EVENT_GEMS_PUT, GemHoles}, {Num, Args}, Task) when is_integer(Num) ->
	check_gem_holes(GemHoles, Args) >= Num andalso
		update_task(Task, ?ROLE_EVENT_GEMS_PUT, ?STATUS_DONE, 0);

do_handle_event({?ROLE_EVENT_SKILL_LV, Skills}, Args, Task) ->
	check_skills(Skills, Args) andalso
		update_task(Task, ?ROLE_EVENT_SKILL_LV, ?STATUS_DONE, 0);

do_handle_event({?ROLE_EVENT_OPEN_BOX, AddCount}, _Args, Task) ->
	update_task(Task, ?ROLE_EVENT_OPEN_BOX, ?STATUS_INIT, AddCount);
		
do_handle_event(_Event, _Args, _Task) -> ignore.

update_task(Task, EventTag, NewStatus, AddCount) ->
	#r_consume_task{id = TaskID, status = TaskStatus} = Task,
	Task#r_consume_task{
		status = [case S of
			{EventTag, _OldStatus, OldCount} ->
				NewCount   = OldCount + AddCount,
				NewStatus2 = case AddCount > 0 andalso 
						lists:keyfind(EventTag, 1, cfg_consume_task:events(TaskID)) of
					{EventTag, {count, ReqCount}} when ReqCount =< NewCount ->
						?STATUS_DONE;
					{EventTag, Args} when is_list(Args) ->
						case lists:keyfind(count, 1, Args) of
							{_, ReqCount} ->
								if 
									ReqCount =< NewCount -> 
										?STATUS_DONE;
									true -> NewStatus
								end;
							false -> 
								NewStatus
						end;
					_ ->
						NewStatus
				end,
				{EventTag, NewStatus2, NewCount};
			_ ->
				S
		end||S <- TaskStatus]
	}.

check_equip(Equip, Args) ->
	lists:all(fun
		({position, Pos}) ->
			Equip#p_goods.loadposition == Pos;
		({color, Color}) ->
			Equip#p_goods.current_colour >= Color;
		({level, Level}) ->
			Equip#p_goods.level >= Level;
		({qianghua, Level}) ->
			Equip#p_goods.reinforce_result >= Level;
		(_) ->
			false
	end, Args).

check_fashion(Fashion, Args) ->
	lists:all(fun
		({type, Type}) ->
			Fashion#r_fashion.type == Type;
		({rank, Rank}) ->
			Fashion#r_fashion.rank >= Rank;
		(_) ->
			false
	end, Args).

check_vip_level(VipLevel, [{level, Level}]) ->
	VipLevel >= Level.

check_boss_type(BossType, Args) ->
	lists:all(fun
		({type, Type}) ->
			BossType == Type;
		(_) ->
			false
	end, Args).

check_pet(Pet, Args) ->
	lists:all(fun
		({type, Type}) ->
			Pet#p_pet.type_id == Type;
		({color, Color}) ->
			Pet#p_pet.color == Color;
		({level, Level}) ->
			Pet#p_pet.level >= Level;
		({zz_amount, ZzAmount}) ->
			mod_pet_aptitude:get_pet_total_aptitude(Pet) >= ZzAmount;
		({wx, Wx}) ->
			Pet#p_pet.understanding >= Wx;
		(_) -> false
	end, Args).

check_gem_holes(GemHoles, Args) ->
	case lists:keytake(index, 1, Args) of
		{value, {index, Index}, Args2} ->
			check_gem_holes2(element(Index, GemHoles), Args2);
		_ ->
			[_|AllGemHoles] = tuple_to_list(GemHoles),
			check_gem_holes2(lists:flatten(AllGemHoles), Args)
	end.

check_gem_holes2(GemHoles, Args) ->
	lists:foldl(fun
		(GemHole, Sum) ->
			case check_gem(GemHole, Args) of
				true  -> Sum + 1;
				false -> Sum
			end
	end, 0, GemHoles).

check_gem(#p_gem_hole{gem_typeid=GemTypeID}, [{level, Level}]) ->
	mod_equip_gems:get_gem_level(GemTypeID) >= Level.

check_skills(Skills, [{id, SkillIDs}, {level, SkillLevel}]) ->
	lists:any(fun
		(SkillID) ->
			case lists:keyfind(SkillID, #p_role_skill.skill_id, Skills) of
				#p_role_skill{cur_level = CurLevel} ->
					CurLevel >= SkillLevel;
				_ ->
					false
			end
	end, SkillIDs);
check_skills(Skills, ReqSkills) ->
	lists:any(fun
		({SkillID, SkillLevel}) ->
			case lists:keyfind(SkillID, #p_role_skill.skill_id, Skills) of
				#p_role_skill{cur_level = CurLevel} ->
					CurLevel >= SkillLevel;
				_ ->
					false
			end
	end, ReqSkills).

check_pet_bag(PetBag, [{amount, Amount}]) ->
	case PetBag of
		#p_role_pet_bag{summoned_pet_id = SummonPetID, hidden_pets = HiddenPets} ->
			if SummonPetID > 0 -> 1; true -> 0 end + length(HiddenPets) >= Amount;
		_ -> 
			false
	end.

check_pet_grow(GrowInfo, [{level, Level}]) ->
	GrowInfo#p_role_pet_grow.con_level           >= Level orelse
	GrowInfo#p_role_pet_grow.phy_attack_level    >= Level orelse
	GrowInfo#p_role_pet_grow.magic_attack_level  >= Level orelse
	GrowInfo#p_role_pet_grow.phy_defence_level   >= Level orelse
	GrowInfo#p_role_pet_grow.magic_defence_level >= Level.