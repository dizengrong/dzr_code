%% Author: liuwei
%% Created: 2011-2-10
-module(mod_map_pet).
-include("mgeem.hrl").
-export([
         notice_after_add_exp/3,
         set_pet_process_info/2,
         get_pet_process_info/1,
		 get_pet_transfer_info/1,
         persistent_pet_process_info/1,
         get_pet_info/2,
         set_pet_info/2,
		 get_role_pet_bag_info/1,
		 set_role_pet_bag_info/2,
         get_pet_task/1,
         set_pet_task/1
        ]).

-export([
         init/0,
         handle/2,
         send_role_pet_bag_info/1,
         get_pet_pos_from_owner/1,
         t_get_new_pet/7,
         update_role_pet_slice/4,
         get_role_pet_map_info_list/1,
         role_pet_enter/1,
         role_pet_quit/1,
		 pet_quit/3,
         get_summoned_pet_info/1,
         pet_add_hp/2,
         pet_reduce_hp/4,
         set_pet_pk_mode/2,
         add_pet_exp/3,
         hook_role_pk_mode_change/2,
         auto_summon_role_pet/2,
		 auto_summon_mirror_pet/2,
         reduce_role_pet_hp_on_pet_wall/4,
         check_pet_can_relive_owner/1,
         t_deduct_item/2,
         t_deduct_silver/3,
         t_common_add_pet_exp/4,
         check_role_has_pet/2,
		 hook_role_level_change/1,
		 hook_pet_levelup/2,
		 get_pet_exp/2,
		 mirror_pet_quit/1,
         is_pet_summoned/2,
         get_pet_character/1,        %% 获取宠物性格id
         is_pet_learned_trick/2,
         do_call_back/5,
         send_pet_info_to_client/2,
         gm_set_pet_attr/4,
         remove_pet_buff_add_to_owner/2
        ]).

-export([refresh_qrhl_data/1, write_pet_action_log/6]).

%% =============== 与宠物任务、心情、亲密度相关的api =================
-export([
        add_pet_mood/3,      %% 增加宠物心情
		do_summon/5
        ]).

-define(ROLE_PET_EGG_INFO,role_pet_egg_info).

%%
%% API Functions
%%
%%异兽模块初始化
init() ->
	ok.

handle({_Unique, ?PET, ?PET_SUMMON, DataIn, RoleID, PID, _Line}, State) ->
    #m_pet_summon_tos{pet_id = PetID } = DataIn,
    case cfg_pet_helper:can_summon_pet(State#map_state.mapid) of
        true ->
            do_summon(RoleID, PetID, PID, false, State);
        false ->
            do_summon_error(RoleID, <<"不能在这里召唤灵宠">>)
    end; 

handle({Unique, ?PET, ?PET_CALL_BACK, DataIn, RoleID, _PID, Line}, State) -> 
    do_call_back(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_THROW, DataIn, RoleID, _PID, Line}, State) -> 
    do_throw({Unique, DataIn, RoleID, Line}, State);

handle({_Unique, ?PET, ?PET_LEARN_SKILL, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_skill:do_learn_skill(RoleID, DataIn);
    % do_learn_skill(Unique, DataIn, RoleID, Line, State);

handle({_Unique, ?PET, ?PET_JUEJI_UP_QUALITY, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_skill:do_up_jueji_quality(RoleID, DataIn);

handle({Unique, ?PET, ?PET_INFO, DataIn, RoleID, _PID, Line}, _State) -> 
    do_info(Unique, DataIn, RoleID, Line);

handle({_Unique, ?PET, ?PET_BAG_INFO, _DataIn, RoleID, _PID, _Line}, _State) -> 
    send_role_pet_bag_info(RoleID);

handle({Unique, ?PET, ?PET_ADD_BAG, DataIn, RoleID, _PID, Line}, State) -> 
    do_add_pet_bag(Unique, DataIn, RoleID, Line, State);

handle({_Unique, ?PET, ?PET_REFRESH_APTITUDE, DataIn, RoleID, _PID, _Line}, _State) ->
    mod_pet_aptitude:handle(?PET_REFRESH_APTITUDE, RoleID, DataIn); 

handle({_Unique, ?PET, ?PET_REFRESH_APTITUDE_REPLACE, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_aptitude:handle(?PET_REFRESH_APTITUDE_REPLACE, RoleID, DataIn); 

handle({_Unique, ?PET, ?PET_REFRESH_APTITUDE_KEEP, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_aptitude:handle(?PET_REFRESH_APTITUDE_KEEP, RoleID, DataIn); 

handle({Unique, ?PET, ?PET_ADD_UNDERSTANDING, DataIn, RoleID, _PID, Line}, State) -> 
    do_add_understanding(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_CHANGE_NAME, DataIn, RoleID, _PID, Line}, State) -> 
    do_change_name(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_TRAINING_REQUEST, DataIn, RoleID, PID, Line}, State)->
    mod_pet_training:handle({Unique, DataIn, RoleID, PID, Line, State});

handle({_Unique, ?PET, ?PET_EAT_PET_CARD, DataIn, RoleID, _PID, _Line}, _State)->
    mod_pet_training:eat_pet_card(RoleID, DataIn);    

handle({Unique, ?PET, ?PET_GROW_INFO, _DataIn, RoleID, PID, _Line}, _State) -> 
    mod_pet_grow:do_pet_grow_info(Unique, ?PET, ?PET_GROW_INFO, RoleID, PID);

handle({Unique, ?PET, ?PET_GROW_BEGIN, DataIn, RoleID, _PID, Line}, State) -> 
    mod_pet_grow:do_pet_grow_begin(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_GROW_COMMIT, DataIn, RoleID, _PID, Line}, State) -> 
    mod_pet_grow:do_pet_grow_commit(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_GROW_AUTO, DataIn, RoleID, _PID, Line}, State) -> 
    mod_pet_grow:do_pet_grow_auto(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_GROW_GIVE_UP, DataIn, RoleID, _PID, Line}, State) -> 
    mod_pet_grow:do_pet_grow_give_up(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_ADD_SKILL_GRID, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_add_skill_grid(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_FORGET_SKILL, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_forget_skill(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_CHANGE_POS, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_change_pos(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_REFINING, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_refining(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_REFINING_EXP, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_refining_exp(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_TRICK_LEARN, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_trick_learn(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_TRICK_UPGRADE, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_trick_upgrade(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_HIDDEN, DataIn, RoleID, PID, Line}, State) -> 
	#m_pet_hidden_tos{state=HiddenState,pet_id=PetID} = DataIn,
	mod_role_pet_mix:pet_hidden({Unique, ?PET, ?PET_HIDDEN, PetID, HiddenState, RoleID, PID, Line, State});

handle({Unique, ?PET, ?PET_BONE_UP, DataIn, RoleID, PID, Line}, _State) -> 
    mod_pet_bone:handle_client_req(Unique, ?PET_BONE_UP, DataIn, RoleID, PID, Line); 
    
handle({Unique, ?PET, ?PET_ADD_QINMIDU, DataIn, RoleID, PID, Line}, _State) -> 
    mod_pet_task:handle_client_req(Unique, ?PET_ADD_QINMIDU, DataIn, RoleID, PID, Line);

handle({Unique, ?PET, ?PET_USE_ITEM, DataIn, RoleID, PID, Line}, _State) -> 
    mod_pet_task:handle_client_req(Unique, ?PET_USE_ITEM, DataIn, RoleID, PID, Line);

handle({Unique, ?PET, ?PET_BUY_ITEM, DataIn, RoleID, PID, Line}, _State) -> 
    mod_pet_task:handle_client_req(Unique, ?PET_BUY_ITEM, DataIn, RoleID, PID, Line);
    
handle({Unique, ?PET, ?PET_EQUIP_ON, DataIn, RoleID, PID, Line}, _State) -> 
	mod_pet_equip:handle({Unique, ?PET, ?PET_EQUIP_ON, DataIn, RoleID, PID, Line});

handle({Unique, ?PET, ?PET_EQUIP_OFF, DataIn, RoleID, PID, Line}, _State) -> 
	mod_pet_equip:handle({Unique, ?PET, ?PET_EQUIP_OFF, DataIn, RoleID, PID, Line});

handle({Unique, ?PET, ?PET_REFRESH_FOSTER, DataIn, RoleID, PID, Line}, _State) -> 
    mod_pet_foster:handle(Unique, ?PET_REFRESH_FOSTER, DataIn, RoleID, PID, Line);

handle({Unique, ?PET, ?PET_SAVE_FOSTER, DataIn, RoleID, PID, Line}, _State) -> 
    mod_pet_foster:handle(Unique, ?PET_SAVE_FOSTER, DataIn, RoleID, PID, Line);

handle({Unique, ?PET, ?PET_FOSTER_SHOW, DataIn, RoleID, PID, Line}, _State) -> 
    mod_pet_foster:handle(Unique, ?PET_FOSTER_SHOW, DataIn, RoleID, PID, Line);
    
handle({_Unique, ?PET, ?PET_DA_DAN_INFO, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_da_dan:handle(?PET_DA_DAN_INFO, RoleID, DataIn);

handle({_Unique, ?PET, ?PET_DA_DAN, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_da_dan:handle(?PET_DA_DAN, RoleID, DataIn);

handle({_Unique, ?PET, ?PET_HUN_INFO, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_hun:handle(?PET_HUN_INFO, RoleID, DataIn);

handle({_Unique, ?PET, ?PET_UP_HUN, DataIn, RoleID, _PID, _Line}, _State) -> 
    mod_pet_hun:handle(?PET_UP_HUN, RoleID, DataIn);

handle({_Unique, ?PET, ?PET_SHOW, DataIn, RoleID, _PID, _Line}, _State) -> 
    do_pet_show(?PET_SHOW, RoleID, DataIn);

handle({Unique, ?PET, ?PET_EGG_USE, DataIn, RoleID, _PID, Line}, State) ->
    do_pet_egg_use(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_EGG_REFRESH, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_egg_refresh(Unique, DataIn, RoleID, Line, State);

handle({Unique, ?PET, ?PET_EGG_ADOPT, DataIn, RoleID, _PID, Line}, State) -> 
    do_pet_egg_adopt(Unique, DataIn, RoleID, Line, State);
    
handle({add_exp,RoleID,Exp}, _State) ->
    do_add_exp(RoleID,Exp,true);

handle({quit,RoleID,PetID}, State) ->
    pet_quit(RoleID, PetID,State);


handle({pet_color_goal,_RoleID,_Color},_State) ->
	todo;

handle(Msg,_State) ->
    ?ERROR_MSG("uexcept msg = ~w",[Msg]).

gm_set_pet_attr(RoleID, Index, Type, Data) ->
    PetBag = get_role_pet_bag_info(RoleID),
    Fun = fun(PetIdNameRec) ->
        (PetIdNameRec#p_pet_id_name.index + 1 == Index)
    end,
    case lists:filter(Fun, PetBag#p_role_pet_bag.pets) of
        [] -> "没有这个宠物哦";
        [PetIdNameRec1] ->
            % PetInfo = get_pet_info(RoleID, PetIdNameRec1#p_pet_id_name.pet_id),
            case Type of
                1 -> %% 增加经验
                    Fun1 = fun() ->t_common_add_pet_exp(RoleID, PetIdNameRec1#p_pet_id_name.pet_id, Data, normal) end,
                    {atomic,{ok,NewPetInfo,_RealAddExp,NoticeType}} = common_transaction:t(Fun1),
                    notice_after_add_exp(RoleID, NoticeType, NewPetInfo),
                    "增加宠物经验成功";
                _ -> %% 没有实现的可以在这里加
                    "暂时没有实现，正确使用:t4_set_pet_attr=第几个宠物=修改类型(1:增加经验)=数值"
            end
    end.

do_pet_show(?PET_SHOW, RoleID, DataIn) ->
    PetBagInfo = get_role_pet_bag_info(RoleID),
    PetId = DataIn#m_pet_show_tos.pet_id,
    IsInShowList = lists:member(PetId, PetBagInfo#p_role_pet_bag.show_list),
    if
        DataIn#m_pet_show_tos.is_show andalso IsInShowList == false ->
            PetBagInfo1 = PetBagInfo#p_role_pet_bag{show_list = [PetId | PetBagInfo#p_role_pet_bag.show_list]};
        DataIn#m_pet_show_tos.is_show == false andalso IsInShowList ->
            PetBagInfo1 = PetBagInfo#p_role_pet_bag{show_list = lists:delete(PetId, PetBagInfo#p_role_pet_bag.show_list)};
        true ->
            PetBagInfo1 = PetBagInfo
    end,
    set_role_pet_bag_info(RoleID, PetBagInfo1).


add_pet_mood(RoleID, PetId, AddMood) ->
    mod_pet_task:add_pet_mood(RoleID, PetId, AddMood).

set_pet_process_info(RoleID,PetProcessInfo) ->
    #r_pet_process_info{pet_bag=PetBagInfo,pet_grow=PetGrowInfo,
                        transfer_info=TransferInfo,pet_info=PetsInfo} = PetProcessInfo,
	mod_role_tab:put({?ROLE_PET_BAG_INFO,RoleID},PetBagInfo),
	mod_pet_grow:init_map_role_pet_grow_info(RoleID,PetGrowInfo),
	case TransferInfo of
		undefined ->
			ignore;
		_ ->
			lists:foreach(fun({Key,Value}) -> put(Key,Value) end, TransferInfo)
	end,
	case PetsInfo of
		undefined ->
			ignore;
		_ ->
			lists:foreach(fun
				(#p_pet{pet_id=PetID}=PetInfo) -> 
				 	mod_role_tab:put(RoleID, {?ROLE_PET_INFO,PetID}, PetInfo) 
			end, PetsInfo)
	end,
    PetTaskRec = PetProcessInfo#r_pet_process_info.pet_task,
    set_pet_task(PetTaskRec),
	ok.

set_pet_task(PetTaskRec) when is_record(PetTaskRec, r_pet_task) ->
  RoleID = PetTaskRec#r_pet_task.role_id,
  put({?ROLE_PET_TASK, RoleID}, PetTaskRec).

get_pet_task(RoleID) ->
  get({?ROLE_PET_TASK, RoleID}).

get_pet_process_info(RoleID) ->
    TransferInfo = get_pet_transfer_info(RoleID),
    PetGrowInfo  = mod_pet_grow:get_role_pet_grow_info(RoleID),
    PetBagInfo   = mod_role_tab:get({?ROLE_PET_BAG_INFO,RoleID}),
    PetTaskRec   = get_pet_task(RoleID),
    PetsInfo     = lists:foldl(fun
		(#p_pet_id_name{pet_id=PetID},Acc) -> 
			case mod_role_tab:get(RoleID, {?ROLE_PET_INFO,PetID}) of
				undefined ->
					Acc;
				Info ->
					[Info|Acc]
			end
	end,[], PetBagInfo#p_role_pet_bag.pets),
    #r_pet_process_info{
        pet_bag       = PetBagInfo,
        pet_grow      = PetGrowInfo,
        transfer_info = TransferInfo,
        pet_info      = PetsInfo,
        pet_task      = PetTaskRec
    }.

persistent_pet_process_info(RoleID) ->
	PetProcessInfo = get_pet_process_info(RoleID),
    PetBagInfo = mod_role_tab:get({?ROLE_PET_BAG_INFO,RoleID}),
    persistent_role_pet_bag(RoleID,PetBagInfo),
    lists:foreach(fun(#p_pet_id_name{pet_id=PetID}) -> 
                          PetInfo = mod_role_tab:erase(RoleID, {?ROLE_PET_INFO,PetID}),
                          persistent_pet_info(PetID,PetInfo)
                  end, PetBagInfo#p_role_pet_bag.pets),
    {ok,PetProcessInfo}.

send_role_pet_bag_info(RoleID) ->
	case get_role_pet_bag_info(RoleID) of
		undefined ->
			case db:dirty_read(?DB_ROLE_PET_BAG_P,RoleID) of
				[] ->
					PetBagInfo = #p_role_pet_bag{content=?DEFAULT_PET_BAG_CONTENT,role_id=RoleID,pets=[]};
				[PetBagInfo] ->
					ignore
			end;
		PetBagInfo ->
			ignore
	end,
    Record = #m_pet_bag_info_toc{info=PetBagInfo},
    common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_BAG_INFO, Record),
    {ok,PetBagInfo}.

get_role_pet_bag_info(RoleID) ->
	mod_role_tab:get({?ROLE_PET_BAG_INFO,RoleID}).

set_role_pet_bag_info(RoleID,PetBagInfo) -> 
    mod_role_tab:put({?ROLE_PET_BAG_INFO,RoleID},PetBagInfo).	

set_pet_info(PetID,PetInfo) ->
	#p_pet{role_id=RoleID} = PetInfo,
    mod_role_tab:put(RoleID,{?ROLE_PET_INFO,PetID},PetInfo).

persistent_role_pet_bag(_RoleID,PetBagInfo) ->
    mgeem_persistent:pet_bag_persistent(PetBagInfo).

persistent_pet_info(_PetID,PetInfo) ->
    mgeem_persistent:pet_persistent(PetInfo).

get_pet_info(RoleID, PetID) ->
	mod_role_tab:get(RoleID, {?ROLE_PET_INFO,PetID}).

auto_summon_mirror_pet(Pet, MapState) ->
    do_summon(Pet#p_pet.role_id, Pet, mirror, true, MapState).

auto_summon_role_pet(RoleID, MapState) ->
	PetBagInfo = get_role_pet_bag_info(RoleID),
	Pets = PetBagInfo#p_role_pet_bag.pets,
	SummonedPetID = PetBagInfo#p_role_pet_bag.summoned_pet_id,
	case lists:keyfind(SummonedPetID, #p_pet_id_name.pet_id, Pets) of
		false ->
			ignore;
		#p_pet_id_name{pet_id=PetID} ->
            PID = erlang:get({roleid_to_pid, RoleID}),
            do_summon(RoleID, PetID, PID, true, MapState)
	end.   


%%异兽肉墙帮主人承受伤害
reduce_role_pet_hp_on_pet_wall(RoleID,ReduceHp,SrcActorID, SrcActorType) ->
    case get_summoned_pet_info(RoleID) of
        undefined ->
            ignore;
        PetID ->
            pet_reduce_hp(PetID,ReduceHp, SrcActorID, SrcActorType)
    end.


%%检查是否有异兽复活主人的BUFF，有的话自动复活主人
-define(PET_RELIVE_OWNER_BUFF_TYPE,97).
check_pet_can_relive_owner(#p_role_base{role_id=RoleID,buffs=Buffs, max_hp=MaxHp}) ->
    case lists:keyfind(?PET_RELIVE_OWNER_BUFF_TYPE, #p_actor_buf.buff_type, Buffs) of
        false ->
            ignore;
        #p_buf{value=Value} ->
            case get_summoned_pet_info(RoleID) of
                undefined ->
                    ignore;
                {_PetID,_PetInfo} ->
                    Hp = trunc(MaxHp * Value /10000),
                    case Hp > MaxHp of
                        true ->
                            Hp2 = MaxHp;
                        false ->
                            Hp2 = Hp
                    end,
                    Hp2
            end
    end.


%%根据主人的位置和方向确定异兽的位置和方向
get_pet_pos_from_owner(RoleID) ->
    RolePos = mod_map_actor:get_actor_pos(RoleID,role),
    #p_pos{tx=Tx,ty=Ty,dir=Dir} = RolePos,
    Dis = ?ROLE_PET_DISTANCE,
    case Dir of
        0 ->
            #p_pos{tx=Tx+Dis, ty=Ty, dir=Dir};          % pet=new Pt(pt.x + dis, 0, pt.z);
        1 ->
            #p_pos{tx=Tx+Dis, ty=Ty+Dis-2, dir=Dir};      % pet=new Pt(pt.x + dis, 0, pt.z + dis-2);
        2 ->
            #p_pos{tx=Tx, ty=Ty+Dis, dir=Dir};      % pet=new Pt(pt.x, 0, pt.z + dis);
        3 ->
            #p_pos{tx=Tx+1-Dis, ty=Ty-1+Dis, dir=Dir};  % pet=new Pt(pt.x - (dis-1), 0, pt.z + (dis-1));
        4 ->
            #p_pos{tx=Tx-Dis, ty=Ty, dir=Dir};          % pet=new Pt(pt.x - dis, 0, pt.z);
        5 ->
            #p_pos{tx=Tx-Dis, ty=Ty+2-Dis, dir=Dir};  % pet=new Pt(pt.x - dis, 0, pt.z - (dis-2));
        6 ->
            #p_pos{tx=Tx, ty=Ty-Dis, dir=Dir};      % pet=new Pt(pt.x, 0, pt.z - dis);
        7 ->
            #p_pos{tx=Tx+Dis-1, ty=Ty+1-Dis, dir=Dir};  % pet=new Pt(pt.x + (dis-1), 0, pt.z - (dis-1));
        _ ->
            #p_pos{tx=Tx, ty=Ty, dir=Dir}
    end.


t_get_new_pet(RoleID,TypeID,RoleLevel,RoleName,Bind,RoleFaction,PetColor) ->
    get_new_pet(RoleID,TypeID,RoleLevel,RoleName,Bind,RoleFaction,PetColor).

%%跟新玩家出战的异兽的slice
update_role_pet_slice(RoleID, TX, TY, DIR) ->
    case get_summoned_pet_info(RoleID) of
        undefined ->
            ignore;
        {PetID, _} when is_integer(PetID)->
            mod_map_actor:update_slice_by_txty(PetID, pet, TX, TY, DIR);
        _ ->
            ignore
    end.
     

%%异兽进入地图时设置相应的信息到进程字典中
set_pet_info_in_process(RoleID,PetID,PetInfo) ->
   	mod_role_tab:put(RoleID,{?ROLE_PET_INFO,PetID},PetInfo).

%%获取玩家出战的异兽的ID和map_pet的列表
get_role_pet_map_info_list(RoleID) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        undefined ->
            {[], []};
        PetID when PetID > 0 ->
            case mod_map_actor:get_actor_mapinfo(PetID, pet) of
                undefined ->
                    {[], []};
                MapPetInfo ->
                    {[PetID],[MapPetInfo]}
            end;
        _ -> 
            {[], []}
    end.  

%%获取异兽地图切换时需要传送的相关信息
get_pet_transfer_info(RoleID) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        undefined ->
            [];
        PetID ->
            [{{map_pet_info,PetID}, mod_map_actor:get_actor_mapinfo(PetID,pet)}]
    end.

%%异兽在玩家切换地图时进入新的地图
role_pet_enter(RoleMapInfo) ->
	PetID  = RoleMapInfo#p_map_role.summoned_pet_id,
	case PetID > 0 of
		false ->
			ignore;
		true ->
			case mod_map_actor:get_actor_mapinfo(PetID, pet) of
				undefined ->
					ignore;
				MapPetInfo ->
					State   = mgeem_map:get_state(),
					RolePos = RoleMapInfo#p_map_role.pos,
					mod_map_actor:do_enter(0, PetID, PetID, pet, MapPetInfo#p_map_pet{pos=RolePos}, 0, State)
			end
	end.

%%异兽在玩家切换地图时退出老的地图
role_pet_quit(RoleID) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        undefined ->
            ignore;
        PetID when PetID > 0 ->
            State = mgeem_map:get_state(),
            pet_quit(RoleID, PetID, State);
        _ ->
            ignore
    end.

%%异兽在玩家切换地图时退出老的地图
mirror_pet_quit(RoleID) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        undefined ->
            ignore;
        PetID when PetID > 0 ->
            State = mgeem_map:get_state(),
            pet_mirror_quit(RoleID, PetID, State);
        _ -> 
            ignore
    end.

%%获取玩家被召唤出战的异兽的信息
get_summoned_pet_info(RoleID) ->
     case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        undefined ->
            undefined;
        PetID when PetID == 0 -> 
            undefined;
        PetID ->
            PetInfo = get_pet_info(RoleID, PetID),
            case is_record(PetInfo, p_pet) of 
                false -> undefined;
                true  -> {PetID, PetInfo}
            end
    end.

%%异兽加血
pet_add_hp(RoleID,AddValue) ->
    case get_role_pet_map_info_list(RoleID) of
        {[],[]} ->
            {error,?_LANG_PET_NOT_SUMMONED};
        {[PetID],[MapPetInfo]} ->
            MaxHp = MapPetInfo#p_map_pet.max_hp,
            Hp = MapPetInfo#p_map_pet.hp,
            case MaxHp =:= Hp of
                true ->
                    {error,?_LANG_PET_ADD_HP_FAIL_HP_FULL};
                false ->
                    case Hp + AddValue > MaxHp of
                        true ->
                            NewHp = MaxHp;
                        false ->
                            NewHp = Hp + AddValue
                    end,
                    %% 此函数只在处理道具的时候调用，使用道具是事务的，不可以在事务中发消息
                    %% del by caochuncheng 2011-10-18 
                    %% Record = #m_pet_attr_change_toc{pet_id=PetID,change_type=?PET_HP_CHANGE,value=NewHp},
                    %% common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_ATTR_CHANGE, Record),
                    mod_map_actor:set_actor_mapinfo(PetID,pet,MapPetInfo#p_map_pet{hp=NewHp}),
                    {ok,PetID,NewHp}
            end                           
    end.

%% 异兽扣血
pet_reduce_hp(PetID,ReduceValue, SrcActorID, SrcActorType) ->
    case mod_map_actor:get_actor_mapinfo(PetID,pet) of
        undefined ->
            ignore;
        PetMapInfo ->
            ?TRY_CATCH(hook_map_pet:be_attacked(PetMapInfo, SrcActorID, SrcActorType)),
            #p_map_pet{hp=HP,role_id=RoleID} = PetMapInfo,
            case HP =< 0 of
                true ->
                    pet_dead(PetID,PetMapInfo#p_map_pet{hp=0},RoleID);
                false ->
                    NewHP = HP - ReduceValue,
                    case NewHP =< 0 of
                        true ->
                            pet_dead(PetID,PetMapInfo#p_map_pet{hp=0},RoleID);
                        false ->
                            mod_map_actor:set_actor_mapinfo(PetID,pet,PetMapInfo#p_map_pet{hp=NewHP}),
                            Record = #m_pet_attr_change_toc{pet_id=PetID,change_type=?PET_HP_CHANGE,value=NewHP},
                            common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_ATTR_CHANGE, Record)
                    end
            end
    end.


%%设置异兽的攻击模式，始终与主人的攻击模式保持一致
set_pet_pk_mode(RoleID, PkMode) ->
    case get_summoned_pet_info(RoleID) of
        undefined ->
            ignore;
        {PetID,PetInfo} ->
            set_pet_info(PetID,PetInfo#p_pet{pk_mode=PkMode})
    end.


add_pet_exp(RoleID,AddExp,IsNotice) ->
    do_add_exp(RoleID,AddExp,IsNotice).


%%玩家攻击模式改变时异兽的攻击模式也要改变
hook_role_pk_mode_change(RoleID,PKMode) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        undefined ->
            ignore;
        PetID when PetID > 0 ->
            case get_pet_info(RoleID,PetID) of
                undefined ->
                    ignore;
                PetInfo ->
                    set_pet_info(PetID,PetInfo#p_pet{pk_mode=PKMode})
            end;
        _ ->
            ignore
    end.

%% 无论异兽是否出战都会给他加经验
t_common_add_pet_exp(RoleID,PetID,AddExpArg,Type)->
	case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
		PetID->
			PetInfo = get_pet_info(RoleID,PetID),
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			assert_add_exp2(PetInfo#p_pet.level,PetInfo#p_pet.pet_name, RoleAttr#p_role_attr.level),
			AddExp = mod_pet_training:get_common_add_pet_exp(AddExpArg,PetInfo#p_pet.level,Type),
			{NewPetInfo,NoticeType,RealAddExp} = calculate_add_pet_exp(PetInfo,AddExp),
			MapInfo = mod_map_actor:get_actor_mapinfo(PetID,pet),
			case NoticeType =:= levelup andalso is_record(MapInfo, p_map_pet) of 
				true ->
					#p_pet{max_hp=MaxHp,level=NewLevel} = NewPetInfo,
          mod_map_actor:set_actor_mapinfo(PetID,pet,MapInfo#p_map_pet{hp=MaxHp,max_hp=MaxHp,level=NewLevel});
				_->
					ignore
			end;
		_ ->
			PetInfo = common_pet:role_pet_backup(RoleID,PetID),
			case PetInfo#p_pet.role_id of
				RoleID ->   
                    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
					assert_add_exp2(PetInfo#p_pet.level,PetInfo#p_pet.pet_name, RoleAttr#p_role_attr.level),
					AddExp = mod_pet_training:get_common_add_pet_exp(AddExpArg,PetInfo#p_pet.level,Type),
					{NewPetInfo,NoticeType,RealAddExp} = calculate_add_pet_exp(PetInfo,AddExp);
				_ ->
					NewPetInfo = NoticeType = RealAddExp = null,
					common_transaction:abort(?_LANG_PET_NOT_EXIST)
			end
	end,
  mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_LV, NewPetInfo}),
  mod_role_pet:update_role_base(RoleID, '-', PetInfo, '+', NewPetInfo),
	set_pet_info(PetID, NewPetInfo),
	{ok,NewPetInfo,RealAddExp,NoticeType}.


calculate_add_pet_exp(PetInfo,AddExp)->
    #p_pet{exp=Exp,level=Level} = PetInfo,
    NewExp = Exp + AddExp,
    LevelExpInfo = cfg_pet_level:level_info(Level),
	NextLevelExp = LevelExpInfo#pet_level.next_level_exp,
	case NewExp >=NextLevelExp of
		true->
            NewPetInfo2 = level_up(NewExp,Level,PetInfo),
            ChangeAttrs = [
                {#p_pet.exp,            NewPetInfo2#p_pet.exp - PetInfo#p_pet.exp},
                {#p_pet.next_level_exp, NewPetInfo2#p_pet.next_level_exp - PetInfo#p_pet.next_level_exp},
                {#p_pet.level,          NewPetInfo2#p_pet.level - PetInfo#p_pet.level}
            ],
            NewPetInfo3 = mod_pet_attr:calc(PetInfo, '+', ChangeAttrs),
			{NewPetInfo3#p_pet{hp=NewPetInfo3#p_pet.max_hp},levelup,AddExp};
		false->
			{PetInfo#p_pet{exp=NewExp},attrchange,AddExp}
	end.
%%
%% Local Functions
%%

%%让异兽镜像出战
do_summon(RoleID, PetInfo, mirror, IsAutoSummon, State) ->
	do_summon2(RoleID, PetInfo#p_pet.pet_id, PetInfo#p_pet{pk_mode=?PK_ALL}, mirror, IsAutoSummon, State, false);

%%让异兽出战
do_summon(RoleID, PetID, PID, IsAutoSummon, State) ->
  case not IsAutoSummon andalso check_has_summon_other_pet(RoleID) of
    true ->
      do_summon_error(RoleID, ?_LANG_OTHER_PET_SUMMONED);
    false ->
      case check_role_has_pet(RoleID, PetID) of
        {ok,PetInfo} ->
            case mod_map_role:get_role_base(RoleID) of
                {error, _} ->
                    do_summon_error(RoleID, ?_LANG_SYSTEM_ERROR);
                {ok, RoleBase} ->
                    IsHidden = mod_role_pet_mix:is_pet_hidden(RoleID, PetID),
                    PkMode = RoleBase#p_role_base.pk_mode,
                    do_summon2(RoleID, PetID, PetInfo#p_pet{pk_mode=PkMode}, PID, IsAutoSummon, State, IsHidden)
            end;
        error ->
            do_summon_error(RoleID, ?_LANG_SYSTEM_ERROR)
      end
  end.

do_summon2(RoleID, PetID, PetInfo, PID, IsAutoSummon, State, IsHidden) ->
	#p_pet{
    type_id  = TypeID,
    pet_name = Name,
    level    = Level,
    hp       = HP,
    title    = Title,
    color    = Color,
    period   = Period
  } = PetInfo,
	case check_can_summon_pet(RoleID) of
    {error, Reason} ->
      do_summon_error(RoleID, Reason);
    {ok, RoleMapInfo, RoleBase} ->
      {NewRoleBase, NewPetInfo} = add_pet_buff_when_summon(RoleBase, PetInfo),
      AttackSpeed = NewPetInfo#p_pet.attack_speed,
      MaxHP       = NewPetInfo#p_pet.max_hp,
      HP2         = case HP > MaxHP orelse HP =:= 0 of
          true -> 
              MaxHP;
          false ->
              HP
      end,
      %% 对应的p_role_pet_bag记录中的summoned_pet_id是有正确值的
			MapPetInfo = #p_map_pet{
        pet_id       = PetID,
        type_id      = TypeID,
        pet_name     = Name,
        role_id      = RoleID,
        attack_speed = AttackSpeed,
        period       = Period,
        hp           = HP2,
        max_hp       = MaxHP,
        level        = Level,
        state_buffs  = [],
        pos          = RoleMapInfo#p_map_role.pos,
        state        = 1,
        title        = Title,
        color        = Color,
        is_mirror    = (PID == mirror)
      },
      mod_map_actor:do_enter(0, PID, PetID, pet, MapPetInfo, 0, State),
      NewPetInfo2 = NewPetInfo#p_pet{hp = HP2},

      OldPetBag = get_role_pet_bag_info(RoleID),
      {ok, NewPetBag} = set_summoned_pet_bag_info(RoleID, PetID, summoned, OldPetBag),
      #p_role_pet_bag{summoned_pet_id = SummonedPetID, hidden_pets = HiddenPets} = NewPetBag,
      ActivePets = case SummonedPetID of
                       undefined -> erlang:length(HiddenPets);
                       _         -> erlang:length(HiddenPets) + 1
                   end,
      mod_qrhl:send_event(RoleID, pet, ActivePets),
      set_pet_info_in_process(RoleID, PetID, NewPetInfo2),
      Record = #m_pet_summon_toc{succ = true, pet_info = NewPetInfo2},
      PID =/= mirror andalso 
          common_misc:unicast2_direct(PID, ?DEFAULT_UNIQUE, ?PET, ?PET_SUMMON, Record),
      IsAutoSummon orelse begin
          {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
          OldSummonPet = get_pet_info(RoleID, OldPetBag#p_role_pet_bag.summoned_pet_id),
          NewRoleBase1 = case IsHidden of
            true  -> NewRoleBase;
            false ->
              mod_role_pet:calc(NewRoleBase, [{'-', OldSummonPet}, {'+', NewPetInfo2}])
          end,
          mod_role_attr:reload_role_base(NewRoleBase1, false),
          MapRoleUpdates = mod_map_role:make_map_role_update_list(NewRoleBase1, RoleAttr),
          mod_map_role:do_update_map_role_info(RoleID, RoleMapInfo, 
            [{#p_map_role.summoned_pet_id,      PetID}, 
             {#p_map_role.summoned_pet_typeid,  TypeID}|MapRoleUpdates]),
          mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_CZ, NewPetBag})
      end
	end.

check_can_summon_pet(RoleID) ->
  case mod_map_actor:get_actor_mapinfo(RoleID, role) of
    undefined ->
      {error, ?_LANG_SYSTEM_ERROR};
    RoleMapInfo ->
      {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
      case lists:keymember(?BUFF_ID_LI_HUN, #p_actor_buf.buff_id, RoleBase#p_role_base.buffs) of
        true ->
          {error, <<"中了离魂术时，不能出战宠物">>};
        _ ->
          {ok, RoleMapInfo, RoleBase}
      end
  end.

set_summoned_pet_bag_info(RoleID, PetID, PetState) ->
  set_summoned_pet_bag_info(RoleID, PetID, PetState, get_role_pet_bag_info(RoleID)).
set_summoned_pet_bag_info(RoleID, PetID, PetState, PetBagInfo) ->
	Fun = fun
    () ->
			#p_role_pet_bag{hidden_pets=HiddenPets} = PetBagInfo,
			if PetState =:= summoned ->
				   NewPetBagInfo = PetBagInfo#p_role_pet_bag{summoned_pet_id=PetID,hidden_pets=lists:delete(PetID, HiddenPets)};
			   PetState =:= hidden ->
				   NewPetBagInfo = PetBagInfo#p_role_pet_bag{summoned_pet_id=undefined,hidden_pets=[PetID|lists:delete(PetID, HiddenPets)]};
			   true ->
				   NewPetBagInfo = PetBagInfo#p_role_pet_bag{summoned_pet_id=undefined,hidden_pets=lists:delete(PetID, HiddenPets)}
			end,
			set_role_pet_bag_info(RoleID, NewPetBagInfo),
			{ok, NewPetBagInfo}
	end,
	case common_transaction:t(Fun) of
		{atomic,{ok, NewPetBagInfo}} ->
			Record = #m_pet_bag_info_toc{info=NewPetBagInfo},
			common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_BAG_INFO, Record),
      {ok, NewPetBagInfo};
		{aborted,_Reason} ->
			ignore
	end.
    
%%检查玩家是否有某个异兽
check_role_has_pet(RoleID,PetID) ->
    case get_pet_info(RoleID,PetID) of
        undefined ->
            error;
        PetInfo ->
            case PetInfo#p_pet.role_id of
                RoleID ->
                    {ok,PetInfo};
                _ ->
                    error
            end
    end.

%%判断该玩家是不是已经召唤过宠物了
check_has_summon_other_pet(RoleID) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        undefined ->
            false;
        _ ->
            true
    end.
    
do_summon_error(RoleID, Reason) ->
    Record = #m_pet_summon_toc{succ=false, reason=Reason},
    common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_SUMMON, Record).

%%收回出战中的异兽
do_call_back(_Unique, DataIn, RoleID, _Line, State) ->
    #m_pet_call_back_tos{pet_id=PetID,is_hidden=IsHidden} = DataIn,
    case check_pet_is_summoned(RoleID,PetID) andalso get_pet_info(RoleID, PetID) of
      PetInfo when is_record(PetInfo, p_pet) ->
        pet_quit(RoleID, PetID, State),
        {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
        NewRoleBase0   = remove_pet_buff_add_to_owner(RoleBase, PetInfo),
        RolePetBag     = mod_map_pet:get_role_pet_bag_info(RoleID),
        NewRoleBase1   = mod_role_pet:calc(NewRoleBase0, RolePetBag, [{'-', PetInfo}]),
        PetState = case IsHidden of
    				true  -> hidden;
    				false -> quit
    		end,
        {ok, NewRolePetBag} = set_summoned_pet_bag_info(RoleID, PetID, PetState),
        Record = #m_pet_call_back_toc{succ=true, pet_id=PetID},
        common_misc:unicast2_direct({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_CALL_BACK, Record),
        case IsHidden of
          true  -> NewRoleBase2 = mod_role_pet:calc(NewRoleBase1, NewRolePetBag, [{'+', PetInfo}]);
          false -> NewRoleBase2 = NewRoleBase1
        end,
        mod_role_attr:reload_role_base(NewRoleBase2),
        true;
      _ ->
        false
    end.

%%检查被召唤出来的异兽ID
check_pet_is_summoned(RoleID,PetID) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
        PetID ->
            true;
        _ ->
            false
    end.

%% 宠物是否是跟随状态
is_pet_summoned(RoleID, PetID) ->
    case mod_role_tab:get({?ROLE_SUMMONED_PET_ID, RoleID}) of
        PetID ->
            true;
        _ ->
            false
    end.



%%异兽退出地图（战斗死亡，寿命用完，被收回或玩家下线）
pet_quit(RoleID, PetID, _State) ->
    mod_map_actor:do_quit(PetID,pet,mgeem_map:get_state()),
    RoleMapInfo1 = mod_map_actor:get_actor_mapinfo(RoleID, role),
    RoleMapInfo2 = RoleMapInfo1#p_map_role{
        summoned_pet_id     = 0,
        summoned_pet_typeid = 0
    },
    mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo2).

%%异兽镜像退出地图
pet_mirror_quit(RoleID, PetID, State) ->
    mod_map_actor:do_mirror_quit(PetID,pet,State),
	RoleMapInfo1 = mod_map_actor:get_actor_mapinfo(RoleID, role),
    RoleMapInfo2 = RoleMapInfo1#p_map_role{
        summoned_pet_id     = 0,
        summoned_pet_typeid = 0
    },
    mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo2).

%%丢弃异兽
do_throw({Unique, DataIn, RoleID, Line}, _State) ->
	#m_pet_throw_tos{pet_id=PetID} = DataIn,
	case check_role_has_pet(RoleID, PetID) of
		{ok,PetInfo} ->
			case common_transaction:transaction(fun() -> t_throw_pet(RoleID,PetID,PetInfo) end) of
				{atomic, {ok,NewPetBagInfo}} ->
					mgeem_persistent:pet_persistent({undefined,PetID}),
					write_pet_action_log(PetInfo,RoleID,?PET_ACTION_TYPE_THROW,"放生异兽",0,""),
					Record = #m_pet_throw_toc{succ=true, bag_info=NewPetBagInfo},
					common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_THROW, Record),
					refresh_qrhl_data(RoleID);
				{aborted,Reason} ->
					do_throw_error(Unique, RoleID, Line, PetID, Reason)
			end;
		_ ->
			do_throw_error(Unique, RoleID, Line, PetID, ?_LANG_PET_NOT_EXIST)
	end.
 
 %% 训练不能退役
t_throw_pet(RoleID,PetID,PetInfo) ->
    PetBagInfo = common_pet:role_pet_bag_backup(RoleID),
    common_pet:role_pet_backup(RoleID,PetID),
    case PetInfo#p_pet.state =:= ?PET_NORMAL_STATE of
        false ->
            common_transaction:abort(?_LANG_PET_REFINING_NOT_NORMAL_STATE);
        true ->
            ignore
    end,
    case is_pet_summoned(RoleID, PetID) of
        true ->
            common_transaction:abort(<<"跟随或合体状态下的灵宠无法放生">>);
        false ->
            ignore
    end,
    NewPets = lists:keydelete(PetID, #p_pet_id_name.pet_id, PetBagInfo#p_role_pet_bag.pets),
    {NewPets2,_} = lists:foldr(
                     fun(PetIDName,{Acc2,Acc3}) ->
                             {[PetIDName#p_pet_id_name{index=Acc3-1}|Acc2],Acc3-1}
                     end, {[],length(NewPets)}, NewPets),
    NewPetBagInfo=PetBagInfo#p_role_pet_bag{pets=NewPets2},
    set_role_pet_bag_info(RoleID, NewPetBagInfo),
    mod_role_tab:erase(RoleID,{?ROLE_PET_INFO,PetID}),
    {ok,NewPetBagInfo}.


do_throw_error(Unique, RoleID, Line, _PetID, Reason) ->
     Record = #m_pet_throw_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_THROW, Record).

t_deduct_item(NeedItemID,RoleID) ->
    case catch mod_bag:decrease_goods_by_typeid(RoleID, [1, 2, 3], NeedItemID, 1) of
        {bag_error,num_not_enough} ->
            db:abort(?_LANG_GOODS_NUM_NOT_ENOUGH);
        Other ->
            Other
    end.
t_deduct_item(NeedItemID,RoleID,Num,_Bind) ->
    mod_bag:decrease_goods_by_typeid(RoleID, [1, 2, 3], NeedItemID, Num).

t_deduct_silver(Attr,NeedSilver,DeduceLog) ->
    #p_role_attr{role_id=RoleID, silver_bind=BindSilver, silver=Silver} = Attr,
    case BindSilver >= NeedSilver of
        true ->
            common_consume_logger:use_silver({RoleID, NeedSilver, 0, DeduceLog,
                                              ""}),
            Attr#p_role_attr{silver_bind=BindSilver-NeedSilver};
        false ->
            common_consume_logger:use_silver({RoleID, BindSilver, NeedSilver-BindSilver, DeduceLog,
                                              ""}),
            Attr#p_role_attr{silver_bind=0, silver=Silver+BindSilver-NeedSilver}
    end.

%%获取异兽的详细信息
do_info(Unique, DataIn, RoleID, Line) ->
	#m_pet_info_tos{pet_id=PetID, role_id = PetRoleId} = DataIn,
	case get_pet_info(PetRoleId,PetID) of
		undefined ->
			Fun = fun() ->
						  case db:dirty_read(?DB_PET_P,PetID) of
							  [] ->
								  do_info_error(Unique, RoleID, Line, ?_LANG_PET_NOT_EXIST);
							  [PetInfo1] -> 
                                send_pet_info_to_client(RoleID, PetInfo1)
						  end
				  end,
			spawn(Fun);
		PetInfo2 -> 
            send_pet_info_to_client(RoleID, PetInfo2)
	end.
    

send_pet_info_to_client(RoleID, PetInfo) ->
    Msg = #m_pet_info_toc{succ=true, pet_info=PetInfo},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_INFO, Msg).


do_info_error(Unique, RoleID, Line, Reason) ->
     Record = #m_pet_info_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_INFO, Record).

%% 新建扩展栏费用
-define(ADD_PET_BAG_COST,58).
do_add_pet_bag(Unique, _DataIn, RoleID, Line, _State) ->
	Fun = 
		fun() ->
				PetBagInfo = common_pet:role_pet_bag_backup(RoleID),
				Content = PetBagInfo#p_role_pet_bag.content,
				case Content >= ?MAX_PET_BAG_CONTENT of
					true ->
						db:abort(?_LANG_PET_BAG_IS_FULL);
					false ->
						ignore
				end,
                common_bag2:check_money_enough_and_throw(gold_unbind, ?ADD_PET_BAG_COST, RoleID),
                set_role_pet_bag_info(RoleID, PetBagInfo#p_role_pet_bag{content=Content+1}),
				case common_bag2:t_deduct_money(gold_unbind, ?ADD_PET_BAG_COST, RoleID, ?CONSUME_TYPE_GOLD_ADD_PET_BAG) of
					{ok,RoleAttr}->
						next;
                    {error, Reason} ->
                        RoleAttr = null,
                        ?THROW_ERR(?ERR_OTHER_ERR, Reason);
					_ ->
						RoleAttr = null,
						?THROW_ERR(?ERR_GOLD_NOT_ENOUGH)
				end,
				{ok,RoleAttr,PetBagInfo#p_role_pet_bag{content=Content+1}}
		end,
	case common_transaction:t(Fun) of
		{atomic,{ok,RoleAttr,PetBagInfo}} ->
			common_misc:send_role_gold_change(RoleID, RoleAttr),
			Record = #m_pet_add_bag_toc{info=PetBagInfo},
			common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_ADD_BAG, Record);
        {aborted, {error, ErrorCode, ErrorStr}} ->
            common_misc:send_common_error(RoleID, ErrorCode, ErrorStr);
		% {aborted,{error,ErrCode,_}} ->
		% 	Record = #m_pet_add_bag_toc{succ=false,error_code=ErrCode},
		% 	common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_ADD_BAG, Record);
		{aborted,Reason} ->
			Record = #m_pet_add_bag_toc{succ=false, reason=Reason},
			common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_ADD_BAG, Record)
	end.

  
-define(UnderStandingDeductSilver(Period),
		case Period of
			1 -> 1000;
			2 -> 2000;
			3 -> 3000;
			_ -> 5000
		end).
%%异兽提悟
do_add_understanding(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_add_understanding_tos{pet_id=PetID,item_type=ItemType,auto_buy_item=AutoBuyItem,
								 to_max_understanding=IsToMaxUnderstanding,bind=Bind} = DataIn,
	Fun = fun() -> add_understanding(PetID,ItemType,Bind,IsToMaxUnderstanding,AutoBuyItem,RoleID) end,
    case db:transaction(Fun) of
        {aborted, {error,max_understanding,MaxUnderstanding}} ->
            hook_mission_event:hook_pet_understand(RoleID,MaxUnderstanding),
            do_add_understanding_error(Unique, RoleID, Line, ?_LANG_PET_UNDERSTANDING_IS_FULL);
        {aborted, Reason} ->
            do_add_understanding_error(Unique, RoleID, Line, Reason);
        {atomic, {Ret,ChangeList,DelList,NewPetInfo,RoleAttr,NewRoleAttr,OldUnderStanding}} ->
            NewUnderStanding = NewPetInfo#p_pet.understanding,
			DetailStr = io_lib:format("提悟前悟性=~w, 提悟后悟性=~w",[OldUnderStanding,NewUnderStanding]),
			write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_ADD_UNDERSTANDING,"异兽提悟",0,DetailStr),
			DataRecord = #m_pet_add_understanding_toc{succ=true,succ2=Ret,pet_info=NewPetInfo},
			#p_role_attr{gold=NewGold,gold_bind=NewGoldBind,silver=NewSilver,silver_bind=NewSilverBind} = NewRoleAttr,
			#p_role_attr{gold=Gold,gold_bind=GoldBind,silver=Silver,silver_bind=SilverBind} = RoleAttr,
			%% 通知客户端角色属性变动
			AttrChangeList = [
							  #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewGold},
							   #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewGoldBind},
							  #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=NewSilver},
							  #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=NewSilverBind}],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, AttrChangeList),
			mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_4),
      mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_WX, NewPetInfo}),
			%%广播花费情况
			CostSilver = (Silver-NewSilver)+(SilverBind-NewSilverBind),
            %% 完成成就
            case ItemType of
                12300123 -> %% 高级提悟
                    mod_achievement2:achievement_update_event(RoleID, 21004, 1),
                    mod_achievement2:achievement_update_event(RoleID, 22005, 1),
                    mod_achievement2:achievement_update_event(RoleID, 23002, 1),
                    mod_achievement2:achievement_update_event(RoleID, 24003, 1);
                _ -> ignore
            end,
			%%一定会扣钱币
			case CostSilver > 0 of
				true ->
					Msg1 = lists:concat(["操作成功，当前悟性：",NewPetInfo#p_pet.understanding,"；消耗"]),
					CostGold = (Gold-NewGold) + (GoldBind-NewGoldBind),
					Msg2 = 
						case CostGold > 0 of
							true ->
								lists:concat(["元宝：",CostGold,"，"]);
							false ->
								""
						end,
					Msg3 = lists:concat(["钱币：",common_misc:format_silver(CostSilver)]),
					?ROLE_SYSTEM_BROADCAST(RoleID,lists:concat([Msg1,Msg2,Msg3])),
                    
                    hook_mission_event:hook_pet_understand(RoleID,NewUnderStanding),
					
					%% 通知客户端物品变动
					case ChangeList of
						[] ->
							ignore;
						GoodsList ->
							lists:foreach( 
							  fun(Goods) ->
									  common_item_logger:log(RoleID,Goods,1,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
									  common_misc:update_goods_notify({line, Line, RoleID}, Goods)
							  end,GoodsList)
					end,
					case DelList of
						[] ->
							ignore;
						GoodsList2 ->
							lists:foreach( 
							  fun(Goods2) ->
									  common_item_logger:log(RoleID,Goods2,1,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
									  common_misc:del_goods_notify({line, Line, RoleID}, Goods2)
							  end,GoodsList2)
					end,
					common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_ADD_UNDERSTANDING, DataRecord);
				false ->
					do_add_understanding_error(Unique, RoleID, Line, ?_LANG_ROLE_MONEY_NOT_ENOUGH_SILVER_ANY)
			end
    end.

add_understanding(PetID,ItemType,Bind,IsToMaxUnderstanding,AutoBuyItem,RoleID)  ->
	PetInfo = common_pet:role_pet_backup(RoleID,PetID),
	case PetInfo#p_pet.role_id =:= RoleID of
		true ->	
			#p_pet{role_id=PRoleID,period=Period,understanding=UnderStanding,max_understanding=MaxUnderstanding} = PetInfo,
			case PRoleID =:= RoleID of
				true ->
					case UnderStanding >= MaxUnderstanding of
						true ->
							db:abort({error,max_understanding,MaxUnderstanding});
						false ->
							{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
							case catch calc_add_understanding(ItemType,Bind,UnderStanding,IsToMaxUnderstanding,AutoBuyItem,MaxUnderstanding,Period,RoleID,[],[],RoleAttr) of
								{error,Reason} ->
									db:abort(Reason);
								{ChangeList,DelList,NewUnderStanding,NewRoleAttr} ->
									mod_map_role:set_role_attr(RoleID, NewRoleAttr),
									case NewUnderStanding > UnderStanding of
										false ->
											case NewUnderStanding =:= UnderStanding of
												true ->
													NewPetInfo = PetInfo;
												false ->
													Title = common_pet:get_pet_title(PetInfo#p_pet.color),
													% check_pet_bag_color_change(RoleID,PetID,Color,PetInfo#p_pet.color),
                                                    PetInfo2 = mod_pet_attr:calc(PetInfo, '+', [{#p_pet.understanding, NewUnderStanding - UnderStanding}]),
													NewPetInfo = PetInfo2#p_pet{title=Title},
													set_pet_info(PetID, NewPetInfo)
											end,
											{false,ChangeList, DelList,NewPetInfo,RoleAttr,NewRoleAttr,UnderStanding};
										true ->
											Title = common_pet:get_pet_title(PetInfo#p_pet.color),
											% check_pet_bag_color_change(RoleID,PetID,Color,PetInfo#p_pet.color),
                                            PetInfo2 = mod_pet_attr:calc(PetInfo, '+', [{#p_pet.understanding, NewUnderStanding - UnderStanding}]),
                                            NewPetInfo = PetInfo2#p_pet{title=Title},
											set_pet_info(PetID, NewPetInfo),
											case NewUnderStanding >= 12 of
												true -> 
													Content = common_misc:format_lang(?_LANG_PET_ADD_UNDERSTANDING_MORE_THAN_TWELVE,[NewRoleAttr#p_role_attr.role_name,NewUnderStanding]),
													?TRY_CATCH(common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,Content));
												false ->
													ignore
											end,
											{true,ChangeList, DelList,NewPetInfo,RoleAttr,NewRoleAttr,UnderStanding}
									end      
							end
					end;
				false ->
					db:abort(?_LANG_PET_NOT_EXIST)
			end
	end.

%% 手工提悟
calc_add_understanding(ItemType,Bind,UnderStanding,IsToMaxUnderstanding,AutoBuyItem,_MaxUnderstanding,Period,RoleID,_,_,RoleAttr) when IsToMaxUnderstanding =:= false ->
	{Rand,_FailUnderStanding,ItemTypeList} = get_add_understanding_info(UnderStanding),
	case lists:member(ItemType, ItemTypeList) =:= false andalso AutoBuyItem =:= false of
		true ->
			throw({error,?_LANG_PET_ADD_UNDERSTANDING_ITEM_ERROR});
		false ->
			case common_bag2:t_deduct_money(silver_any,?UnderStandingDeductSilver(Period),RoleAttr,?CONSUME_TYPE_SILVER_PET_ADD_UNDERSTANDING) of
				{ok,NewRoleAttr}->
					CostItemType = 
						case AutoBuyItem of
							true ->
								lists:nth(1,ItemTypeList);
							false ->
								ItemType
						end,
					case catch t_deduct_item(CostItemType,RoleID,1,Bind) of
						{bag_error,num_not_enough} ->
							case AutoBuyItem of
								true ->
									{GoodsMoneyType,ItemPrice} = mod_shop:get_goods_price(CostItemType),
									case common_bag2:t_deduct_money(GoodsMoneyType,ItemPrice,NewRoleAttr,?CONSUME_TYPE_GOLD_PET_UNDERSTANDING_AUTO_BUY_ITEM) of
										{ok,NewRoleAttr2}->
											NewUnderStanding2 = get_add_understanding(RoleID,Rand,UnderStanding),
											{[],[],NewUnderStanding2,NewRoleAttr2};
                                        {error, Reason} ->
                                            throw({error,Reason});
										_ ->
											throw({error,?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD_ANY})
									end;
								false ->
									throw({error,?_LANG_GOODS_NUM_NOT_ENOUGH})
							end;
						{ok, ChangeList, DelList} ->
							NewUnderStanding = get_add_understanding(RoleID,Rand,UnderStanding),
							{ChangeList,DelList,NewUnderStanding,NewRoleAttr}
					end;
                {error, Reason} ->
                    throw({error,Reason});
				_ ->
					throw({error,?_LANG_NOT_ENOUGH_SILVER})
			end
	end;

%% 一键提悟，直到最高悟性
calc_add_understanding(_ItemType,Bind,UnderStanding,IsToMaxUnderstanding,AutoBuyItem,MaxUnderstanding,Period,RoleID,AccChangeList,AccDelList,RoleAttr) ->
	case UnderStanding >= MaxUnderstanding of
		true ->
			{AccChangeList,AccDelList,UnderStanding,RoleAttr};
		false ->
			{Rand,_FailUnderStanding,ItemTypeList} = get_add_understanding_info(UnderStanding),
			ItemType = lists:nth(1,ItemTypeList),
			case common_bag2:t_deduct_money(silver_any,?UnderStandingDeductSilver(Period),RoleAttr,?CONSUME_TYPE_SILVER_PET_ADD_UNDERSTANDING) of
				{ok,NewRoleAttr}->
					case catch t_deduct_item(ItemType,RoleID,1,Bind) of
						{bag_error,num_not_enough} ->
							{GoodsMoneyType,ItemPrice} = mod_shop:get_goods_price(ItemType),
							case common_bag2:t_deduct_money(GoodsMoneyType,ItemPrice,NewRoleAttr,?CONSUME_TYPE_GOLD_PET_TO_MAX_UNDERSTANDING_BUY_ITEM) of
								{ok,NewRoleAttr2}->
									NewUnderStanding = get_add_understanding(RoleID,Rand,UnderStanding),
									calc_add_understanding(ItemType,Bind,NewUnderStanding,IsToMaxUnderstanding,AutoBuyItem,MaxUnderstanding,Period,RoleID,AccChangeList,AccDelList,NewRoleAttr2);
                                {error, Reason} ->
                                     throw({error,Reason});
								_ ->
									throw({AccChangeList,AccDelList,UnderStanding,RoleAttr})
							end;
						{ok, ChangeList, DelList} ->
							NewUnderStanding = get_add_understanding(RoleID,Rand,UnderStanding),
							calc_add_understanding(ItemType,Bind,NewUnderStanding,IsToMaxUnderstanding,AutoBuyItem,MaxUnderstanding,Period,RoleID,lists:append(ChangeList,AccChangeList),lists:append(DelList,AccDelList),NewRoleAttr)
					end;
                {error, Reason} ->
                    throw({error,Reason});
				_ ->
					throw({AccChangeList,AccDelList,UnderStanding,RoleAttr})
			end
	end.
	
get_add_understanding(RoleID,Rand,UnderStanding) ->
	Rate = random:uniform(10000),
	Rate2 = Rate - mod_vip:get_vip_pet_understand_rate(RoleID),
	case Rate2 =< Rand of
		true ->
			UnderStanding+1;
		false ->
			UnderStanding
	end.

-record(r_pet_understanding,{understanding,info}).
%%12300121 初级提悟符  12300122 中级提悟符   12300123 高级提悟符
get_add_understanding_info(UnderStanding) ->
    #r_pet_understanding{info=Info} = cfg_pet_understanding:get(UnderStanding),
    Info.

            
do_add_understanding_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_add_understanding_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_ADD_UNDERSTANDING, Record).

%%异兽改名手续费10元宝
-define(PET_CHANGE_NAME_DEDUCT_GOLD,10).
do_change_name(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_change_name_tos{pet_id=PetID, pet_name=PetName} = DataIn,
    PetInfo = get_pet_info(RoleID, PetID),
    case PetInfo#p_pet.role_id =:= RoleID of
        false -> 
            do_change_name_error(Unique, RoleID, Line, PetID, PetInfo#p_pet.pet_name, ?_LANG_PET_NOT_EXIST);
        true ->
            case common_bag2:use_money(RoleID, gold_any, ?PET_CHANGE_NAME_DEDUCT_GOLD, ?CONSUME_TYPE_GOLD_PET_CHANGE_NAME) of
                true ->
                    PetBagInfo =  get_role_pet_bag_info(RoleID),
                    IDName     = lists:keyfind(PetID, #p_pet_id_name.pet_id, PetBagInfo#p_role_pet_bag.pets),
                    NewPets    = lists:keyreplace(PetID, #p_pet_id_name.pet_id, PetBagInfo#p_role_pet_bag.pets, IDName#p_pet_id_name{name=PetName}),
                    NewBagInfo = PetBagInfo#p_role_pet_bag{pets=NewPets},
                    set_role_pet_bag_info(RoleID, NewBagInfo),
                    set_pet_info(PetID, PetInfo#p_pet{pet_name=PetName}),
                    
                    Record = #m_pet_change_name_toc{succ=true, pet_id=PetID, pet_name=PetName},
                    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_CHANGE_NAME, Record),
                    %%以下为了方便客户端跟新信息，特意加的，不符合服务器端开发习惯
                    Record3 = #m_pet_bag_info_toc{info=NewBagInfo},
                    common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE, ?PET, ?PET_BAG_INFO, Record3);
                {error, Reason} ->
                    do_change_name_error(Unique, RoleID, Line, PetID, PetInfo#p_pet.pet_name, Reason)
            end
    end.

do_change_name_error(Unique, RoleID, Line, PetID, PetName, Reason) ->
    Record = #m_pet_change_name_toc{succ=false, reason=Reason, pet_id=PetID, pet_name=PetName},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_CHANGE_NAME, Record).

do_pet_add_skill_grid(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_add_skill_grid_tos{pet_id=PetID} = DataIn,
    Fun = 
        fun() ->   
                PetInfo = common_pet:role_pet_backup(RoleID,PetID),
                {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                #p_role_attr{gold_bind = BindGold, gold = Gold} = RoleAttr,
                MaxSkillGrid = PetInfo#p_pet.max_skill_grid,
                NeedGold = get_add_skill_grid_gold(MaxSkillGrid),
                NewPetInfo = PetInfo#p_pet{max_skill_grid=MaxSkillGrid + 1},
                case BindGold + Gold >= NeedGold of
                    false ->
                        common_transaction:abort(?_LANG_NOT_ENOUGH_GOLD);
                    true ->
						{ok,NewRoleAttr} = common_bag2:t_deduct_money(gold_any,NeedGold,RoleID,?CONSUME_TYPE_GOLD_PET_ADD_SKILL_GRID), 
                        set_pet_info(PetID,NewPetInfo),
                        {ok,NewPetInfo,NewRoleAttr}
                end
        end, 
    case common_transaction:transaction(Fun) of
        {aborted, Reason} ->
            do_pet_add_skill_grid_error(Unique, RoleID, Line, Reason);
        {atomic, {ok, NewPetInfo,NewRoleAttr}} ->
            write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_ADD_SKILL_GRID,"异兽增加技能栏",0,""),
            DataRecord = #m_pet_add_skill_grid_toc{succ=true,pet_info=NewPetInfo},
            common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_ADD_SKILL_GRID, DataRecord),

            common_misc:send_role_gold_change(RoleID, NewRoleAttr)
    end.


get_add_skill_grid_gold(MaxSkillGrid) ->
    case common_config_dyn:find(pet_etc,{pet_add_skill_grid,MaxSkillGrid}) of
        [] ->
            1000000;    %%哥们愿意花钱你管得着啊
        [Gold] ->
            Gold
    end.

do_pet_add_skill_grid_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_add_skill_grid_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_ADD_SKILL_GRID, Record).

do_pet_forget_skill(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_forget_skill_tos{pet_id=PetID,skill_id=SkillID} = DataIn,
    Fun = fun() ->
                  PetInfo = common_pet:role_pet_backup(RoleID,PetID),
                  case SkillID of
                      0 ->
                          forget_all_skills(PetInfo,RoleID,PetID);
                      _ ->
                          forget_single_skill(PetInfo,SkillID,RoleID,PetID)
                  end
          end,
    case common_transaction:transaction(Fun) of
        {aborted, Reason} ->
            do_pet_forget_skill_error(Unique, RoleID, Line, Reason);
        {atomic, {ok, NewPetInfo,NewRoleAttr}} -> 
            write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_FORGET_SKILL,"宠物遗忘技能",SkillID,""),
            DataRecord = #m_pet_forget_skill_toc{succ=true,pet_info=NewPetInfo},
            common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_FORGET_SKILL, DataRecord),
            common_misc:send_role_silver_change(RoleID,NewRoleAttr)
    end.



forget_all_skills(PetInfo,RoleID,PetID) ->
    OldBuffs = PetInfo#p_pet.buffs,
    OldSkills = PetInfo#p_pet.skills,
    if erlang:length(OldSkills) =:= 0 ->
           db:abort(?_LANG_PET_SKILL_FORGET_NOT_EXIST);
       true ->
           next
    end,
    NewBuffs = lists:foldl(
                 fun(Skill, AccBuff) ->
                         filter_buff_by_skill(AccBuff, Skill#p_pet_skill.skill_id)
                 end, OldBuffs, OldSkills),
    NewPetInfo = PetInfo#p_pet{skills=[], buffs=NewBuffs},
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{silver_bind = BindSilver,silver = Silver} = RoleAttr,
    case BindSilver + Silver >= 30000 of 
        true ->
            NewRoleAttr = t_deduct_silver(RoleAttr,30000,?CONSUME_TYPE_SILVER_PET_FORGET_SKILL),
            mod_map_role:set_role_attr(RoleID,NewRoleAttr),
            set_pet_info(PetID,NewPetInfo),
            {ok,NewPetInfo,NewRoleAttr};
        false ->
           db:abort(?_LANG_NOT_ENOUGH_SILVER)
    end.

forget_single_skill(PetInfo,SkillID,RoleID,PetID) ->
    OldSkills = PetInfo#p_pet.skills,
    case lists:keyfind(SkillID, #p_pet_skill.skill_id, OldSkills) of
        false ->
            db:abort(?_LANG_PET_SKILL_NOT_EXIST); 
        _ ->
            OldBuffs = PetInfo#p_pet.buffs,
            NewBuffs = filter_buff_by_skill(OldBuffs, SkillID),
            NewSkills = lists:keydelete(SkillID, #p_pet_skill.skill_id, OldSkills),
            NewPetInfo = PetInfo#p_pet{skills=NewSkills, buffs=NewBuffs},
            {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
            #p_role_attr{silver_bind = BindSilver,silver = Silver} = RoleAttr,
            case BindSilver + Silver >= 12000 of 
                true ->
                    NewRoleAttr = t_deduct_silver(RoleAttr,12000,?CONSUME_TYPE_SILVER_PET_FORGET_SKILL),
                    mod_map_role:set_role_attr(RoleID,NewRoleAttr),
                    set_pet_info(PetID,NewPetInfo), 
                    {ok,NewPetInfo,NewRoleAttr};
                false ->
                    db:abort(?_LANG_NOT_ENOUGH_SILVER)
            end
    end.

%% 用于异兽没出战，直接删除相关的buff，不重新计算属性
filter_buff_by_skill(OldBuffs, SkillID) ->
    {ok, SkillLevelInfo} = mod_skill_manager:get_skill_level_info(SkillID, 1),
    SkillBuffs = SkillLevelInfo#p_skill_level.buffs,
    lists:filter(
      fun(Buff) ->
              case lists:keyfind(Buff#p_actor_buf.buff_id, #p_buf.buff_id, SkillBuffs) of
                  fasle ->
                      true;
                  _ ->
                      false
              end
      end, OldBuffs).

do_pet_forget_skill_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_forget_skill_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_FORGET_SKILL, Record).


do_pet_change_pos(Unique, DataIn, RoleID, Line, _State) ->
	#m_pet_change_pos_tos{pet_id=PetID,pos=DestPos} = DataIn,
	Fun = fun() ->
				  PetBagInfo = common_pet:role_pet_bag_backup(RoleID),
				  #p_role_pet_bag{pets=Pets} = PetBagInfo,
				  case DestPos < 0 orelse DestPos >= length(Pets) of
					  true ->
						  common_transaction:abort({?_LANG_SYSTEM_ERROR,PetBagInfo});
					  false ->
						  case lists:keyfind(PetID, #p_pet_id_name.pet_id, Pets) of
							  false ->
								  do_pet_change_pos_error(Unique, RoleID, Line, ?_LANG_SYSTEM_ERROR,PetBagInfo);
							  #p_pet_id_name{index=OldPos} ->
								  NewPets = lists:foldr(
											  fun(IDName,Acc) ->
													  CurPos = IDName#p_pet_id_name.index,
													  NewPos = get_new_pos(CurPos,OldPos,DestPos),
													  [IDName#p_pet_id_name{index=NewPos}|Acc]
											  end, [], Pets),
								  NewBagInfo = PetBagInfo#p_role_pet_bag{pets=NewPets},
								  set_role_pet_bag_info(RoleID, NewBagInfo),
								  {ok,NewBagInfo}
						  end
				  end
		  end,
	case common_transaction:transaction(Fun) of
		{aborted, {Reason,PetBagInfo}} ->
			do_pet_change_pos_error(Unique, RoleID, Line, Reason,PetBagInfo);
		{atomic, {ok, NewBagInfo}} -> 
			Record = #m_pet_change_pos_toc{succ=true, info=NewBagInfo},
			common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_CHANGE_POS, Record)
	end.


get_new_pos(CurPos,OldPos,DestPos) when OldPos > DestPos ->
    get_new_pos_up(CurPos,OldPos,DestPos);
get_new_pos(CurPos,OldPos,DestPos) when OldPos =:= DestPos ->
    CurPos;
get_new_pos(CurPos,OldPos,DestPos) when OldPos < DestPos ->
    get_new_pos_down(CurPos,OldPos,DestPos).


get_new_pos_up(CurPos,OldPos,DestPos) when CurPos =:= OldPos->
    DestPos;
get_new_pos_up(CurPos,OldPos,_DestPos) when CurPos > OldPos ->
    CurPos;
get_new_pos_up(CurPos,_OldPos,DestPos) when CurPos < DestPos ->
    CurPos;
get_new_pos_up(CurPos,OldPos,DestPos) when CurPos >= DestPos andalso CurPos < OldPos ->
    CurPos + 1.

get_new_pos_down(CurPos,OldPos,DestPos) when CurPos =:= OldPos->
    DestPos;
get_new_pos_down(CurPos,OldPos,_DestPos) when CurPos < OldPos ->
    CurPos;
get_new_pos_down(CurPos,_OldPos,DestPos) when CurPos > DestPos ->
    CurPos;
get_new_pos_down(CurPos,OldPos,DestPos) when CurPos =< DestPos andalso CurPos > OldPos ->
    CurPos - 1.


do_pet_change_pos_error(Unique, RoleID, Line, Reason, PetBagInfo) ->
    Record = #m_pet_change_pos_toc{succ=false, reason=Reason, info=PetBagInfo},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_CHANGE_POS, Record).

%% 宠物归元消耗10礼券
-define(PET_RETURN_TO_CARD_COST, 10).

%% 异兽退役
do_pet_refining(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_refining_tos{pet_id=PetID,action=Action} = DataIn,
    case mod_pet_training:check_pet_is_training(RoleID,PetID) =:= true of
        true -> 
            do_pet_refining_error(Unique, RoleID, Line, ?_LANG_PET_SUMMONED_CAN_NOT_REFINING, undefined);
        _ ->
            Fun = fun() -> t_refining(PetID,RoleID,Action) end,
            case db:transaction(Fun) of
                {aborted, {bag_error,{not_enough_pos,_BagID}}} ->
                    do_pet_refining_error(Unique, RoleID, Line, ?_LANG_GOODS_BAG_NOT_ENOUGH, undefined);
                {aborted, {throw,{bag_error,{not_enough_pos,_BagID}}}} ->
                    do_pet_refining_error(Unique, RoleID, Line, ?_LANG_GOODS_BAG_NOT_ENOUGH, undefined);
                {aborted, {throw, Reason}} ->
                    do_pet_refining_error(Unique, RoleID, Line, Reason, undefined);
                {aborted, Reason} ->
                    do_pet_refining_error(Unique, RoleID, Line, Reason, undefined);
                {atomic, {ok, GoodsInfo,NewPetBagInfo,NewRoleAttr,OldPetInfo}} ->
                            mgeem_persistent:pet_persistent({undefined,PetID}),
                    write_pet_action_log(OldPetInfo,RoleID,?PET_ACTION_TYPE_REFINING,"异兽炼制",0,""),
                    %% 通知客户端角色属性变动 
                    case Action of
                        1 -> 
                            common_misc:send_role_silver_change(RoleID,NewRoleAttr);
                        2 ->
                            common_bag2:use_money(RoleID, gold_any, ?PET_RETURN_TO_CARD_COST, ?CONSUME_TYPE_GOLD_PET_RETURN_COST)
                    end,
                    %% 通知客户端物品变动
                    common_item_logger:log(RoleID,GoodsInfo,1,?LOG_ITEM_TYPE_PET_REFINING_HUO_DE),
                    common_misc:update_goods_notify({line, Line, RoleID}, GoodsInfo),
                    case Action of
                        2 -> ItemTypeId = cfg_pet:back_to_card(OldPetInfo#p_pet.type_id);
                        1 -> ItemTypeId = 0
                    end,
                    Record = #m_pet_refining_toc{succ=true, action = Action, info=NewPetBagInfo, item_typeid = ItemTypeId},
                    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_REFINING, Record)
            end
    end.


t_refining(PetID,RoleID,Action) ->
    PetInfo = common_pet:role_pet_backup(RoleID,PetID),
    #p_role_pet_bag{pets=Pets,hidden_pets=HiddenPets} = PetBagInfo = common_pet:role_pet_bag_backup(RoleID),
    case PetInfo#p_pet.role_id =:= RoleID of
        true ->	
            {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
            case Action of
                1 -> 	
                    NeedSilver = get_refining_silver(PetInfo#p_pet.level),
                    #p_role_attr{silver_bind = BindSilver,silver = Silver} = RoleAttr,
                    case BindSilver + Silver >= NeedSilver of 
                        true ->
                            NewRoleAttr = t_deduct_silver(RoleAttr,NeedSilver,?CONSUME_TYPE_SILVER_PET_REFINING),
                            mod_map_role:set_role_attr(RoleID, NewRoleAttr);
                        false ->
                            NewRoleAttr = RoleAttr,
                            common_transaction:abort(?_LANG_NOT_ENOUGH_SILVER)
                    end;
                2 -> %% 归元不消耗任何东西
                    case cfg_pet:back_to_card(PetInfo#p_pet.type_id) of
                        [] -> common_transaction:abort(<<"只有紫色或紫色以上的宠物才能归元">>);
                        _ -> ok
                    end,
                    case common_bag2:check_money_enough(gold_any,?PET_RETURN_TO_CARD_COST,RoleAttr) of
                        true  -> ok;
                        false -> common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD_BIND)
                    end,
                    NewRoleAttr = RoleAttr
            end;
        false ->
            NewRoleAttr = undefined,
            common_transaction:abort(?_LANG_PET_NOT_EXIST)
    end,
    case PetInfo#p_pet.state =:= ?PET_NORMAL_STATE of
        false ->
            common_transaction:abort(?_LANG_PET_REFINING_NOT_NORMAL_STATE);
        true ->
            ignore
    end,
    case is_pet_summoned(RoleID, PetID) of
        true ->
            common_transaction:abort(<<"跟随或合体状态下的灵宠无法放生">>);
        false ->
            ignore
    end,
    NewPets = lists:keydelete(PetID, #p_pet_id_name.pet_id, Pets),
    {NewPets2,_} = lists:foldr(
                     fun(PetIDName,{Acc2,Acc3}) ->
                             {[PetIDName#p_pet_id_name{index=Acc3-1}|Acc2],Acc3-1}
                     end, {[],length(NewPets)}, NewPets),
    case Action of
        1 ->
            {Exp1,Exp2} = get_refining_exp(PetInfo),
            CreateInfo = #r_goods_create_info{bind=true, type=?TYPE_ITEM, type_id=12300135, num=1},
            {ok,[GoodsInfo]} = mod_bag:create_goods(RoleID,CreateInfo),

            %%特殊处理，level表示高于1000000000的部分，quality表示小与1000000000的部分
            NewGoodsInfo = GoodsInfo#p_goods{level=Exp1,quality=Exp2},
            {ok,_} = mod_bag:update_goods(RoleID,NewGoodsInfo);
        2 ->
            CreateInfo = #r_goods_create_info{bind=true, type=?TYPE_ITEM, type_id=cfg_pet:back_to_card(PetInfo#p_pet.type_id), num=1},
            {ok,[NewGoodsInfo]} = mod_bag:create_goods(RoleID,CreateInfo)
    end,
            
	NewPetBagInfo = PetBagInfo#p_role_pet_bag{pets=NewPets2,hidden_pets=lists:delete(PetID, HiddenPets)},
    set_role_pet_bag_info(RoleID, NewPetBagInfo),
    mod_role_tab:erase(RoleID,{?ROLE_PET_INFO,PetID}),
    {ok,NewGoodsInfo,NewPetBagInfo,NewRoleAttr,PetInfo}.

%%获取异兽
get_refining_silver(Level) ->
    trunc(math:pow(Level,1.85)*10).

get_refining_exp(PetInfo) ->
    ReExp = get_refining_exp_2(PetInfo),
    {trunc(ReExp/1000000000),ReExp rem 1000000000}.

get_refining_exp_2(PetInfo) ->
	#p_pet{level=Level, exp=Exp, understanding=UnderStanding,max_hp_aptitude=HPAptitude, phy_defence_aptitude=PDAptitude, magic_defence_aptitude=MDAptitude,
		   phy_attack_aptitude=PAAptitude, magic_attack_aptitude=MAAptitude, double_attack_aptitude=DoubleAptitude}  = PetInfo,
	List = [HPAptitude, PDAptitude, MDAptitude, PAAptitude, MAAptitude, DoubleAptitude],
	MaxAptitude = lists:max(List) + common_pet:get_understanding_add_rate(UnderStanding),
	#pet_level{total_exp=TotalExp} = cfg_pet_level:level_info(Level),
	TotalExp2 = TotalExp + Exp,
	ReExp = trunc(TotalExp2 * math:pow(160/Level,0.25) * math:pow(MaxAptitude/100000,0.65)),
	case ReExp > 0 of
		true ->
			ReExp;
		false ->
			1
	end.

do_pet_refining_error(Unique, RoleID, Line, Reason, PetBagInfo) ->
    case is_binary(Reason) of
        true->
            Reason2 = Reason;
        _ ->
            ?ERROR_MSG("Reason=~w",[Reason]),
            Reason2 = ?_LANG_SYSTEM_ERROR
    end,
    Record = #m_pet_refining_toc{succ=false, reason=Reason2, info=PetBagInfo},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_REFINING, Record).
     

do_pet_refining_exp(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_refining_exp_tos{pet_id=PetID, action=Action} = DataIn,
    PetInfo = get_pet_info(RoleID,PetID),
    case Action of
        1 -> do_pet_refining_exp_2(PetInfo,PetID,RoleID,Line,Unique);
        2 -> 
            case cfg_pet:back_to_card(PetInfo#p_pet.type_id) of
                [] -> 
                    do_pet_refining_exp_error(Unique, RoleID, Line, <<"只有紫色或紫色以上的宠物才能归元">>);
                ItemTypeId ->
                    Msg = #m_pet_refining_exp_toc{
                            succ        = true, 
                            pet_id      = PetID,
                            pet_name    = PetInfo#p_pet.pet_name,
                            pet_color   = PetInfo#p_pet.color,
                            action      = 2,
                            silver      = ?PET_RETURN_TO_CARD_COST,
                            item_typeid = ItemTypeId
                    },
                    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_REFINING_EXP, Msg)
            end
    end.

do_pet_refining_exp_2(PetInfo,PetID,RoleID,Line,Unique) ->
    Exp = get_refining_exp_2(PetInfo),
    Silver = get_refining_silver(PetInfo#p_pet.level),
    Record = #m_pet_refining_exp_toc{succ=true, pet_id=PetID,pet_name=PetInfo#p_pet.pet_name,pet_color=PetInfo#p_pet.color,
                                     silver=Silver,exp=Exp,action = 1},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_REFINING_EXP, Record).

do_pet_refining_exp_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_refining_exp_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_REFINING_EXP, Record).

%%神宠蛋。。。挺蛋疼的名字
-define(ITEM_PET_EGG,12300139).
do_pet_egg_use(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_egg_use_tos{goods_id=GoodsID} = DataIn,
    case mod_bag:get_goods_by_id(RoleID,GoodsID) of
        {error,_} ->
            do_pet_egg_use_error(Unique, RoleID, Line, ?_LANG_PET_EGG_ITEM_NOT_EXIST);
        {ok,GoodsInfo} ->
            case GoodsInfo#p_goods.typeid =:= ?ITEM_PET_EGG of
                true ->
                    Now = mgeem_map:get_now(),
                    EggLeftTick = GoodsInfo#p_goods.end_time-Now,
                    %EggLeftTick = 60 * 60 * 15,
                    case EggLeftTick > 0 of
                        true ->
                            PetEggInfo = get({?ROLE_PET_EGG_INFO,RoleID}),
                            Fun = fun() -> egg_use(RoleID,PetEggInfo) end,
                            case common_transaction:transaction(Fun) of
                                {aborted, Reason} ->
                                    put({?ROLE_PET_EGG_INFO,RoleID},PetEggInfo),
                                    do_pet_egg_use_error(Unique, RoleID, Line, Reason);
                                {atomic, {ok, TypeList,Tick,PetEggInfo2}} ->
                                    case PetEggInfo2 =/= PetEggInfo of
                                        true ->
                                            db:dirty_write(?DB_PET_EGG_P, PetEggInfo2);
                                        false ->
                                            ignore
                                    end,
                                    Record = #m_pet_egg_use_toc{succ=true, type_id_list=TypeList,refresh_tick=Tick,goods_id=GoodsID,egg_left_tick=EggLeftTick},
									common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_EGG_USE, Record)
                            end;
                        false ->
                            do_pet_egg_use_error(Unique, RoleID, Line, ?_LANG_PET_EGG_OUT_OF_USE_TIME)
                    end;
                false ->
                    do_pet_egg_use_error(Unique, RoleID, Line, ?_LANG_PET_EGG_ITEM_NOT_EXIST)
            end
    end.

egg_use(RoleID,PetEggInfo) ->
    case PetEggInfo of
        undefined ->
            List = get_normal_typeid_list(),
            PetEggInfo2 = #p_role_pet_egg_type_list{role_id=RoleID,type_id_list=List},
            put({?ROLE_PET_EGG_INFO,RoleID},PetEggInfo2),
            {H,M,S} = erlang:time(),
            Tick = 7200 - (H rem 2) * 3600 - M * 60 - S,
            {ok,List,Tick,PetEggInfo2};
        #p_role_pet_egg_type_list{refresh_num=RefreshNum,type_id_list=List} -> 
            case RefreshNum > 0 of
                true ->
                    {ok,List,0,PetEggInfo};
                false ->
                    {H,M,S} = erlang:time(),
                    Tick = 7200 - (H rem 2) * 3600 - M * 60 - S,
                    {ok,List,Tick,PetEggInfo}
            end
    end.

do_pet_egg_use_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_egg_use_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_EGG_USE, Record).

do_pet_egg_refresh(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_egg_refresh_tos{goods_id=GoodsID} = DataIn,
    case mod_bag:get_goods_by_id(RoleID,GoodsID) of
        {error,_} ->
            do_pet_egg_refresh_error(Unique, RoleID, Line, ?_LANG_PET_EGG_ITEM_NOT_EXIST);
        {ok,GoodsInfo} ->
            case GoodsInfo#p_goods.typeid =:= ?ITEM_PET_EGG of
                true ->
                    Now = mgeem_map:get_now(),
                    EggLeftTick = GoodsInfo#p_goods.end_time-Now,
                    %EggLeftTick = 60 * 60 * 15,
                    case EggLeftTick > 0 of
                        true ->
                            PetEggInfo = get({?ROLE_PET_EGG_INFO,RoleID}),
                            Fun = fun() -> egg_refresh(RoleID,PetEggInfo) end,
                            case common_transaction:transaction(Fun) of
                                {aborted, Reason} ->
                                    put({?ROLE_PET_EGG_INFO,RoleID},PetEggInfo),
                                    do_pet_egg_refresh_error(Unique, RoleID, Line, Reason);
                                {atomic,  {ok,List,NewRoleAttr,PetEggInfo2}} ->
                                    mgeem_persistent:pet_egg_persistent(PetEggInfo2),
                                    Record = #m_pet_egg_refresh_toc{succ=true, type_id_list=List, goods_id=GoodsID, egg_left_tick=EggLeftTick},
                                    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_EGG_REFRESH, Record),

                                    common_misc:send_role_gold_change(RoleID, NewRoleAttr)
                            end;
                        false ->
                            do_pet_egg_refresh_error(Unique, RoleID, Line, ?_LANG_PET_EGG_OUT_OF_USE_TIME)
                    end;
                false ->
                    do_pet_egg_refresh_error(Unique, RoleID, Line, ?_LANG_PET_EGG_ITEM_NOT_EXIST)
            end        
    end.


-define(PET_EGG_REFRESH_GOLD,10).
egg_refresh(RoleID,PetEggInfo) -> 
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
	#p_role_attr{gold = Gold , gold_bind = GoldBind} = RoleAttr,
	case Gold >= ?PET_EGG_REFRESH_GOLD orelse GoldBind >=?PET_EGG_REFRESH_GOLD of
		false ->
			common_transaction:abort(?_LANG_NOT_ENOUGH_GOLD);
		true ->
			case PetEggInfo of
				undefined ->
					common_transaction:abort(?_LANG_SYSTEM_ERROR);
				#p_role_pet_egg_type_list{refresh_num=RefreshNum} -> 
					List = get_use_gold_typeid_list(RefreshNum),
					PetEggInfo2 = PetEggInfo#p_role_pet_egg_type_list{refresh_num=RefreshNum+1,type_id_list=List},
					{ok,NewRoleAttr} = common_bag2:t_deduct_money(gold_any,?PET_EGG_REFRESH_GOLD,RoleID,?CONSUME_TYPE_GOLD_PET_EGG_REFRESH),
					put({?ROLE_PET_EGG_INFO,RoleID},PetEggInfo2),
					{ok,List,NewRoleAttr,PetEggInfo2}
			end
	end.

do_pet_egg_refresh_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_egg_refresh_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_EGG_REFRESH, Record).

do_pet_egg_adopt(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_egg_adopt_tos{type_id=PetTypeID,goods_id=GoodsID} = DataIn,
    case mod_bag:check_inbag(RoleID,GoodsID) of
        {error,_} ->
            do_pet_egg_adopt_error(Unique, RoleID, Line, ?_LANG_PET_EGG_ITEM_NOT_EXIST,PetTypeID);
        {ok,GoodsInfo} ->
            case GoodsInfo#p_goods.typeid =:= ?ITEM_PET_EGG of
                true ->
                    Now = mgeem_map:get_now(),
                    EggLeftTick = GoodsInfo#p_goods.end_time-Now,
                    %EggLeftTick = 60 * 60 * 15,
                    case EggLeftTick > 0 of
                        true ->
                            PetEggInfo = get({?ROLE_PET_EGG_INFO,RoleID}),
                            Fun = fun() ->
                                          case PetEggInfo of
                                              undefined ->
                                                  common_transaction:abort(?_LANG_PET_EGG_NO_PET_IN_TYPE);
                                              #p_role_pet_egg_type_list{type_id_list=List} ->
                                                  case lists:member(PetTypeID, List) of
                                                      false ->
                                                          common_transaction:abort(?_LANG_PET_EGG_NO_PET_IN_TYPE);
                                                      true ->
                                                          erase({?ROLE_PET_EGG_INFO,RoleID})
                                                  end
                                          end,
                                          {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                                          #p_role_attr{level = RoleLevel} = RoleAttr,
                                          {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
                                          #p_role_base{faction_id=RoleFaction,role_name=RoleName} = RoleBase,
                                          [ItemBaseInfo] = common_config_dyn:find(item, ?ITEM_PET_EGG),
                                          PetColor = ItemBaseInfo#p_item_base_info.colour,
                                          case get_new_pet(RoleID,PetTypeID,RoleLevel,RoleName,false,RoleFaction,PetColor) of
                                              {error,R} ->
                                                  db:abort(R);
                                              _ ->
                                                  ignore
                                          end,
                                          mod_bag:delete_goods(RoleID,GoodsID)
                                  end,
                            case db:transaction(Fun) of
                                {aborted, Reason} ->
                                    put({?ROLE_PET_EGG_INFO,RoleID},PetEggInfo),
                                    do_pet_egg_adopt_error(Unique, RoleID, Line, Reason, PetTypeID);
                                {atomic,   {ok, [OldGoodsInfo] }} ->
                                    Record = #m_pet_egg_adopt_toc{succ=true, type_id=PetTypeID},
                                    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_EGG_ADOPT, Record),
                                    
                                    %% 通知客户端物品变动
                                    common_item_logger:log(RoleID,OldGoodsInfo,1,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
                                    common_misc:del_goods_notify({line, Line, RoleID}, OldGoodsInfo),
                                    refresh_qrhl_data(RoleID)
                            end;
                        false ->
                            do_pet_egg_adopt_error(Unique, RoleID, Line, ?_LANG_PET_EGG_OUT_OF_USE_TIME,PetTypeID)
                    end;
                false ->
                    do_pet_egg_adopt_error(Unique, RoleID, Line, ?_LANG_PET_EGG_ITEM_NOT_EXIST,PetTypeID)
            end             
    end.

do_pet_egg_adopt_error(Unique, RoleID, Line, Reason, TypeID) ->
    Record = #m_pet_egg_adopt_toc{succ=false, reason=Reason, type_id=TypeID},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_EGG_ADOPT, Record).

%%获取普通的宠物的列表
get_normal_typeid_list() ->
    case common_config_dyn:find(pet_etc,pet_egg_normal) of
        [{TotalRate,TypeList}] ->
            get_typeid_list(TotalRate,TypeList);
        _ ->
            db:abort(?_LANG_PET_EGG_CONFIG_FILE_ERROR)
    end.

%%获取用元宝刷新的宠物的列表
get_use_gold_typeid_list(Num) ->
    RandomType = get_random_type_by_refresh_num(Num),
    case common_config_dyn:find(pet_etc,{pet_egg_use_gold,RandomType}) of
        [{TotalRate,TypeList}] ->
            get_typeid_list(TotalRate,TypeList);
        _ ->
            db:abort(?_LANG_PET_EGG_CONFIG_FILE_ERROR)
    end.

get_random_type_by_refresh_num(Num) when Num =< 8 ->
    1;
get_random_type_by_refresh_num(Num) when Num =< 22 ->
    2;
get_random_type_by_refresh_num(Num) when Num =< 40 ->
    3;
get_random_type_by_refresh_num(Num) when Num =< 60 ->
    4;
get_random_type_by_refresh_num(Num) when Num =< 80 ->
    5;
get_random_type_by_refresh_num(_Num)  ->
    6.

get_typeid_list(TotalRate,TypeList) ->
    RateList = lists:map(fun(_) -> random:uniform(TotalRate) end, [1,2,3,4]),%%example:  [7286,13981,21427,15607]
    lists:map(
      fun(Rate) -> 
              Ret = lists:foldl(
                      fun({TypeID,R},{Flag,Acc}) ->
                              case Flag of
                                  false ->
                                      case Rate =< R+Acc of%%累加超过到比例数,然后就取
                                          true ->
                                              {true,TypeID};
                                          false ->
                                              {false,R+Acc}
                                      end;
                                  true ->
                                      {true,Acc}
                              end
                      end, {false,0}, TypeList),
              case Ret of
                  {false,_} ->
                      db:abort(?_LANG_PET_EGG_CONFIG_FILE_ERROR);
                  {true,ID} ->
                      ID
              end
      end,RateList).

%%异兽学习新的特技
-define(PET_TRICK_LEARN_SILVER,10000).
do_pet_trick_learn(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_trick_learn_tos{pet_id=PetID,type=LearnType} = DataIn,
    Fun = 
        fun() ->   
                PetInfo = common_pet:role_pet_backup(RoleID,PetID),
                {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                #p_role_attr{silver_bind = BindSilver, silver = Silver} = RoleAttr,
                case common_config_dyn:find(pet_etc,{pet_trick_level,LearnType}) of
                    [] ->
                        NeedLevel = 200,
                        common_transaction:abort(?_LANG_PET_TRICK_CONFIG_FILE_ERROR);
                    [NeedLevel2] ->
                        NeedLevel = NeedLevel2
                end,
                Skills = PetInfo#p_pet.skills,
                Skills2 = lists:keydelete(LearnType, #p_pet_skill.skill_type, Skills),
                SkillID = get_new_trick_skill(LearnType),
                Skills3 = lists:append(Skills2,[#p_pet_skill{skill_id=SkillID,skill_type=LearnType}]),
                NewPetInfo = PetInfo#p_pet{skills=Skills3}, 
                case PetInfo#p_pet.level >= NeedLevel of
                    true ->
                        case BindSilver + Silver >= ?PET_TRICK_LEARN_SILVER of 
                            false ->
                                common_transaction:abort(?_LANG_NOT_ENOUGH_SILVER);
                            true ->
                                NewRoleAttr = t_deduct_silver(RoleAttr,?PET_TRICK_LEARN_SILVER,?CONSUME_TYPE_SILVER_PET_TRICK_LEARN),
                                mod_map_role:set_role_attr(RoleID,NewRoleAttr),
                                set_pet_info(PetID,NewPetInfo),
                                {ok,NewPetInfo,NewRoleAttr,SkillID}
                        end;
                    false ->
                        common_transaction:abort(?_LANG_PET_TRICK_LEARN_ROLE_LEVELL_NOE_ENOUGH)
                end
        end, 
    case common_transaction:transaction(Fun) of
        {aborted, Reason} ->
            do_pet_trick_learn_error(Unique, RoleID, Line, Reason);
        {atomic, {ok, NewPetInfo,NewRoleAttr,SkillID}} ->
            write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_ADD_SKILL_GRID,"异兽学习特殊技能",SkillID,""),
            DataRecord = #m_pet_trick_learn_toc{succ=true,pet_info=NewPetInfo}, 
            common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_TRICK_LEARN, DataRecord),
            common_misc:send_role_silver_change(RoleID,NewRoleAttr)
    end.


%%获取异兽新特技的技能ID
get_new_trick_skill(LearnType) ->
    case common_config_dyn:find(pet_etc,{pet_trick_type,LearnType}) of
        [{TotalRate,SkillList}] ->
            Rate = random:uniform(TotalRate),
            Ret = lists:foldl(
                    fun({SkillID,R},{Flag,Acc}) ->
                            case Flag of
                                false ->
                                    case Rate =< R+Acc of
                                        true ->
                                            {true,SkillID};
                                        false ->
                                            {false,R+Acc}
                                    end;
                                true ->
                                    {true,Acc}
                            end
                    end, {false,0}, SkillList),
            case Ret of
                {false,_} ->
                    db:abort(?_LANG_PET_TRICK_CONFIG_FILE_ERROR);
                {true,ID} ->
                    ID
            end;
        _ ->
            db:abort(?_LANG_PET_TRICK_CONFIG_FILE_ERROR)
    end.
   


do_pet_trick_learn_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_trick_learn_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_TRICK_LEARN, Record).


%%异兽升级特技
do_pet_trick_upgrade(Unique, DataIn, RoleID, Line, _State) ->
    #m_pet_trick_upgrade_tos{pet_id=PetID,skill_id=SkillID} = DataIn,
    Fun = 
        fun() ->   
                PetInfo = common_pet:role_pet_backup(RoleID,PetID), 
                Skills = PetInfo#p_pet.skills,
                case lists:keyfind(SkillID, #p_pet_skill.skill_id, Skills) of
                    false ->
                        common_transaction:abort(?_LANG_PET_TRICK_UPGRADE_SKILL_NOT_LEARN); 
                    Skill ->
                        Level = Skill#p_pet_skill.skill_level + 1,
                        case  mod_skill_manager:get_skill_level_info(SkillID, Level) of
                            {ok,_} ->
                                Skills3 = lists:keyreplace(SkillID, #p_pet_skill.skill_id, Skills, Skill#p_pet_skill{skill_level=Level}),
                                NewPetInfo = PetInfo#p_pet{skills=Skills3}, 
                                [NeedItem] = common_config_dyn:find(pet_etc,{pet_trick_upgrade_item,Level}),
                                {ok, ChangeList, DelList} = t_deduct_item(NeedItem,RoleID),
                                set_pet_info(PetID,NewPetInfo),
                                {ok,NewPetInfo,SkillID,ChangeList, DelList};
                            _ ->
                                common_transaction:abort(?_LANG_PET_TRICK_SKILL_LEVEL_FULL)
                        end
                end

        end, 
    case common_transaction:transaction(Fun) of
        {aborted, Reason} ->
            do_pet_trick_upgrade_error(Unique, RoleID, Line, Reason);
        {atomic, {ok, NewPetInfo,SkillID,ChangeList, DelList}} ->
            write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_TRICK_UPGRADE,"异兽升级特殊技能",SkillID,""),
            DataRecord = #m_pet_trick_upgrade_toc{succ=true,pet_info=NewPetInfo}, 
            common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_TRICK_UPGRADE, DataRecord),
            
            %% 通知客户端物品变动
            case ChangeList of
                [] ->
                    ignore;
                [Goods] ->
                    common_item_logger:log(RoleID,Goods,1,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
                    common_misc:update_goods_notify({line, Line, RoleID}, Goods)
            end,
            
            case DelList of
                [] ->
                    ignore;
                [Goods2] ->
                    common_item_logger:log(RoleID,Goods2,1,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
                    common_misc:del_goods_notify({line, Line, RoleID}, Goods2)
            end
    end.


do_pet_trick_upgrade_error(Unique, RoleID, Line, Reason) ->
    Record = #m_pet_trick_upgrade_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_TRICK_UPGRADE, Record).


do_add_exp(RoleID,AddExp,IsNotice) ->
    case catch do_add_exp2(RoleID,AddExp,IsNotice) of
        {error,Reason} ->
            {error,Reason};
        {ok,NewPetInfo,NoticeType} ->
            {ok,NewPetInfo,NoticeType}
    end.
do_add_exp2(RoleID,AddExp,IsNotice) ->
    {PetID,PetInfo} = 
        case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
            D when D == undefined orelse D == 0 ->
                erlang:throw({error,?_LANG_PET_NOT_SUMMONED});
            PetIDT ->
                {PetIDT,mod_role_tab:get(RoleID,{?ROLE_PET_INFO,PetIDT})}
        end,
	#p_pet{exp=Exp,level=Level,pet_name=PetName}=PetInfo,
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	assert_add_exp(Level,PetName, RoleAttr#p_role_attr.level),
    NewExp = Exp + AddExp,
    LevelExpInfo = cfg_pet_level:level_info(Level),
    NextLevelExp = LevelExpInfo#pet_level.next_level_exp,
    case NewExp >= NextLevelExp of
		true ->
			%%异兽等级与玩家等级关联
            NewPetInfo2 = level_up(NewExp,Level,PetInfo),
            ChangeAttrs = [
                {#p_pet.exp,            NewPetInfo2#p_pet.exp - PetInfo#p_pet.exp},
                {#p_pet.next_level_exp, NewPetInfo2#p_pet.next_level_exp - PetInfo#p_pet.next_level_exp},
                {#p_pet.level,          NewPetInfo2#p_pet.level - PetInfo#p_pet.level}
            ],
            NewPetInfo3 = mod_pet_attr:calc(PetInfo, '+', ChangeAttrs),
            MaxHp       = NewPetInfo3#p_pet.max_hp,
            NewLevel    = NewPetInfo3#p_pet.level,
            NewPetInfo4 = NewPetInfo3#p_pet{hp=MaxHp},
            mgeem_map:run(fun() -> 
    			case mod_map_actor:get_actor_mapinfo(PetID,pet) of
    				undefined -> ignore;
    				MapInfo ->
    					mod_map_actor:set_actor_mapinfo(PetID,pet,MapInfo#p_map_pet{hp=MaxHp,max_hp=MaxHp,level=NewLevel})
    			end
            end),
            NoticeType = levelup,
            mod_role_tab:put(RoleID,{?ROLE_PET_INFO,PetID},NewPetInfo4),
            mod_role_pet:update_role_base(RoleID, '-', PetInfo, '+', NewPetInfo3);
		_ ->
            NewPetInfo4 = PetInfo#p_pet{exp=NewExp},
            mod_role_tab:put(RoleID,{?ROLE_PET_INFO,PetID},NewPetInfo4),
            NoticeType = attrchange
    end,
    case IsNotice of
        true->
            notice_after_add_exp(RoleID,NoticeType,NewPetInfo4);
        _ ->
            ignore
    end,
    
    {ok,NewPetInfo4,NoticeType}.

%%@doc 异兽增加经验后的通知处理（事务外调用）
notice_after_add_exp(RoleID,NoticeType,NewPetInfo4)->
    #p_pet{pet_id=PetID,level= NewPetLevel} = NewPetInfo4,
    case NoticeType of
        levelup ->
            hook_pet:hook_pet_levelup(RoleID, PetID,NewPetLevel),
            Record = #m_pet_level_up_toc{pet_info=NewPetInfo4},
            common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_LEVEL_UP, Record);
        attrchange ->
            Record = #m_pet_attr_change_toc{pet_id=PetID,change_type=?PET_EXP_CHANGE,value=NewPetInfo4#p_pet.exp},
            common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_ATTR_CHANGE, Record);
        _ ->
            ignore
    end.

%%异兽升级
level_up(Exp, Level, PetInfo) ->
	NextLevelExp = get_next_level_exp(Level),
	case Exp >= NextLevelExp of
		true ->
			level_up(Exp-NextLevelExp,Level+1,PetInfo);
		false ->
			PetInfo#p_pet{exp=Exp,level=Level,next_level_exp=NextLevelExp}
	end.
            

get_new_pet(RoleID,TypeID,RoleLevel,RoleName,Bind,RoleFaction,PetColor) ->
    BaseInfo = cfg_pet:get_base_info(TypeID),
    case BaseInfo#p_pet_base_info.carry_level > RoleLevel of
        true ->
            {error,?_LANG_ROLE_LEVEL_NOT_ENOUGH_TO_GET_PET};
        false ->
            PetBagInfo = common_pet:role_pet_bag_backup(RoleID),
            Content = PetBagInfo#p_role_pet_bag.content,
            Pets = PetBagInfo#p_role_pet_bag.pets,
            case length(Pets) < Content of
                true ->
                    get_new_pet_2(RoleID,BaseInfo,PetBagInfo,Pets,RoleName,Bind,RoleLevel,RoleFaction,PetColor);
                false ->
                    {error,?_LANG_PET_BAG_NOT_ENOUGH}
            end
    end.


get_new_pet_2(RoleID,BaseInfo,PetBagInfo,Pets,RoleName,Bind,RoleLevel,RoleFaction,PetColor) ->
    case init_pet_info(BaseInfo,RoleID,RoleName,Bind,PetColor) of
        {ok,PetInfo} ->
            PetIDName=#p_pet_id_name{pet_id=PetInfo#p_pet.pet_id, name=PetInfo#p_pet.pet_name, color=PetInfo#p_pet.color,
                                     type_id=PetInfo#p_pet.type_id,index=length(Pets),period=PetInfo#p_pet.period},
			NewPets = lists:append(Pets,[PetIDName]),
            NewPetBagInfo = PetBagInfo#p_role_pet_bag{pets=NewPets},
            set_role_pet_bag_info(RoleID, NewPetBagInfo),
            set_pet_info(PetInfo#p_pet.pet_id,PetInfo),
            write_pet_get_log(PetInfo,RoleID,RoleFaction,RoleLevel,?PET_GET_TYPE_USE_ITEM,"使用异兽召唤符或者异兽蛋获得"),
            %%商店购买的异兽需要广播
            [List] = common_config_dyn:find(pet_etc,get_new_pet_broadcast),
            case lists:keyfind(PetInfo#p_pet.type_id, 1, List) of
                false ->
                    ignore;
                {_,shop_pet} ->
                    %% 紫色以上才广播
                    if PetInfo#p_pet.color >= 4 ->
                           RGB = get_rgb_by_color(PetInfo#p_pet.color),
                           Content = common_misc:format_lang(?_LANG_PET_ROLE_GET_NEW_PET, [RoleName,PetInfo#p_pet.pet_id,RGB,PetInfo#p_pet.pet_name]),
                           ?TRY_CATCH(common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,Content));
                       true ->
                           ignore
                    end
			end,
            if 
                PetInfo#p_pet.color >= 4 -> %% 紫色
                    mod_achievement2:achievement_update_event(RoleID, 13006, 1),
                    mod_achievement2:achievement_update_event(RoleID, 21002, 1);
                PetInfo#p_pet.color >= 5 -> %% 橙色
                    mod_achievement2:achievement_update_event(RoleID, 24001, 1);
                true -> ignore
            end,
            self() ! {mod_map_pet,{pet_color_goal,RoleID,PetInfo#p_pet.color}}, 
            %% 添加拥有异兽的目标
            % self() ! {mod_map_pet,{get_new_pet_goal,RoleID, erlang:length(NewPets)}}, 
            Record = #m_pet_bag_info_toc{info=NewPetBagInfo},
            common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_BAG_INFO, Record),
            mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_GET, PetInfo}),
            {ok,PetBagInfo,PetInfo};
        
        {error,Reason} ->
            {error,Reason}
    end.

get_rgb_by_color(Color) ->
    case Color of
        2 ->
            "#00CC99";
        3 ->
            "#0d79ff";
        4 ->
            "#FE00E9";
        5 ->
            "#FF9000";
        6 ->
            "#FFFF00";
        _ ->
            "#FFFFFF"
    end.

%% 产生初始资质
gen_init_aptitude(PetColor, InitPetLevel, InitUnderstanding) ->   
    MaxAptitude = common_pet:get_pet_max_aptitude(InitPetLevel, PetColor, InitUnderstanding),
    [trunc(0.01 * common_tool:random(10, 50) * MaxAptitude) || _I <- lists:seq(1, 5)].
    
%%获取异兽宝宝的初始化信息
init_pet_info(BaseInfo,RoleID,RoleName,Bind,PetColor) ->
    #p_pet_base_info{
         type_id       = TypeID,
         pet_name      = Name,
         attack_type   = AttackType,
         category_type = CategoryType,
         base_str      = [MinBaseStr,MaxBaseStr],
         base_int2     = [MinBaseInt2,MaxBaseInt2],	
         base_con      = [MinBaseCon,MaxBaseCon],	
         base_dex      = [MinBaseDex,MaxBaseDex],
         base_men      = [MinBaseMen,MaxBaseMen],
         init_level    = InitPetLevel
    } = BaseInfo,
    PetID      = common_tool:t_new_pet_id(RoleID),
    Sex        = random:uniform(2),
    [HPAptitude, PDAptitude, MDAptitude, 
     PAAptitude, MAAptitude] = case BaseInfo#p_pet_base_info.init_aptitudes of
        [] -> gen_init_aptitude(PetColor, InitPetLevel, ?DEFAULT_PET_UNDERSTANDING);
        InitApttudes -> InitApttudes
    end,
    BaseStr = common_tool:random(MinBaseStr,MaxBaseStr),
    BaseInt = common_tool:random(MinBaseInt2,MaxBaseInt2),
    BaseCon = common_tool:random(MinBaseCon,MaxBaseCon),
    BaseDex = common_tool:random(MinBaseDex,MaxBaseDex),
    BaseMen = common_tool:random(MinBaseMen,MaxBaseMen),
    PetInfo = #p_pet{
        type_id                = TypeID, 
        role_id                = RoleID, 
        pet_id                 = PetID, 
        pet_name               = Name, 
        role_name              = RoleName,
        level                  = InitPetLevel,
        life                   = ?DEFAULT_PET_LIFE, 
        sex                    = Sex,
        attack_type            = AttackType,
        color                  = PetColor, 
        understanding          = ?DEFAULT_PET_UNDERSTANDING,
        title                  = common_pet:get_pet_title(PetColor),
        category_type          = CategoryType, 
        base_str               = BaseStr,
        base_int2              = BaseInt,
        base_con               = BaseCon, 
        base_dex               = BaseDex,
        base_men               = BaseMen,
        max_hp_aptitude        = HPAptitude,
        phy_defence_aptitude   = PDAptitude,
        magic_defence_aptitude = MDAptitude,
        phy_attack_aptitude    = PAAptitude,
        magic_attack_aptitude  = MAAptitude,
        next_level_exp         = get_next_level_exp(InitPetLevel),
        bind                   = Bind, 
        equips                 = #p_pet_equips{dan = undefined},
        mood                   = random:uniform(?MAX_PET_MOOD),
        bone                   = #p_pet_bone{},
        foster                 = #p_foster_attr{},
        tricks                 = BaseInfo#p_pet_base_info.default_trick,
        jueji                  = #p_pet_jue_ji{
            skill_id = BaseInfo#p_pet_base_info.heti_skill,
            level    = 1, 
            quality  = ?COLOUR_GREEN
        }
    },
    NewPetInfo = mod_pet_base:recalc(PetInfo, BaseInfo),
    {ok, NewPetInfo#p_pet{hp=NewPetInfo#p_pet.max_hp}}.

%%异兽死亡
pet_dead(PetID,PetMapInfo,RoleID) ->
    mod_map_actor:set_actor_mapinfo(PetID,pet,PetMapInfo),
    PetInfo = mod_role_tab:get(RoleID,{?ROLE_PET_INFO,PetID}),
    Life = PetInfo#p_pet.life,
    case Life > 20 of
        true ->
            NewLife = Life - 20;
        false ->
            NewLife = 0
    end,
	set_pet_info(PetID, PetInfo#p_pet{life=NewLife}),
	case PetMapInfo#p_map_pet.is_mirror of
	true ->
		erlang:send_after(1500, self(),{mod, mod_mirror, {pet_reborn, PetInfo}});
	false ->
    	write_pet_action_log(PetInfo,RoleID,?PET_ACTION_TYPE_DEAD,"异兽死亡",0,"")
	end, 
    State = mgeem_map:get_state(),
	Record1 = #m_pet_dead_toc{pet_id=PetID,life=NewLife},
   	mgeem_map:do_broadcast_insence_include([{role,RoleID}],?PET,?PET_DEAD,Record1,State),
	case PetMapInfo#p_map_pet.is_mirror of
	true ->
		Record2 = #m_pet_quit_toc{pet_id = PetID},
   		mgeem_map:do_broadcast_insence_include([{role,RoleID}],?PET,?PET_QUIT,Record2,State),
		pet_mirror_quit(RoleID, PetID, State);
	false ->
    	mgeer_role:absend(RoleID, {mod_map_pet,{quit,RoleID, PetID}})
	end, 
    ok.

get_pet_skill_buffs(PetInfo) ->
    {RoleBuffs1, PetBuffs1} = lists:foldr(fun
        (PetSkill, {RoleBuffsAcc, PetBuffsAcc}) ->
            {RoleBuffs, PetBuffs} = mod_pet_skill:get_pet_skill_buffs(PetSkill),
            {RoleBuffs++RoleBuffsAcc, PetBuffs++PetBuffsAcc}
    end, {[], []}, PetInfo#p_pet.skills),
    {RoleBuffs2, PetBuffs2} = lists:foldr(fun
        (PetTrick, {RoleBuffsAcc, PetBuffsAcc}) ->
            {RoleBuffs, PetBuffs} = mod_pet_skill:get_pet_trick_buffs(PetTrick),
            {RoleBuffs++RoleBuffsAcc, PetBuffs++PetBuffsAcc}
    end, {RoleBuffs1, PetBuffs1}, PetInfo#p_pet.tricks),
    {RoleBuffs2, PetBuffs2}.    


%%异兽召唤出来后添加被动BUFF技能给自己和主人
add_pet_buff_when_summon(RoleBase, PetInfo) ->
    {RoleBuffs, PetBuffs} = get_pet_skill_buffs(PetInfo),
    {mod_role_buff:add_buff2(RoleBase, RoleBuffs), mod_pet_buff:add_buff(PetInfo, PetBuffs)}.

%%异兽招回或者死亡时去除异兽加给主人的buff
remove_pet_buff_add_to_owner(RoleBase, PetInfo) when is_record(PetInfo, p_pet) ->
  {RoleBuffs, _PetBuffs} = get_pet_skill_buffs(PetInfo),
  mod_role_buff:del_buff2(RoleBase, RoleBuffs);
remove_pet_buff_add_to_owner(RoleBase, _PetInfo) -> RoleBase.

write_pet_action_log(PetInfo,RoleID,ActionType,ActionTypeStr,ActionDetail,ActionDetailStr) ->
    #p_pet{pet_id =PetID,pet_name=PetName,type_id=TypeID} = PetInfo,
    BaseInfo      = cfg_pet:get_base_info(TypeID),
    Name          = BaseInfo#p_pet_base_info.pet_name,
    ?TRY_CATCH(global:send(mgeew_pet_log_server,{log_pet_action,{PetID, PetName, TypeID, RoleID, ActionType, ActionDetail, Name, ActionTypeStr, ActionDetailStr}})).


write_pet_get_log(PetInfo,RoleID,RoleFaction,RoleLevel,GetWay,GetWayStr) ->
    #p_pet{pet_id=PetID,pet_name=PetName,type_id=TypeID,level=PetLevel} = PetInfo,
    #p_pet_base_info{pet_name=Name} = cfg_pet:get_base_info(TypeID),
    ?TRY_CATCH(global:send(mgeew_pet_log_server,{log_get_pet,{PetID, PetName, TypeID, PetLevel, GetWay, RoleID, RoleLevel,RoleFaction, Name, GetWayStr}})).


%%检查异兽的颜色是否变化，变化修改背包信息并通知前端
% check_pet_bag_color_change(RoleID,PetID,Color,OldColor) ->
%     case Color =:= OldColor of
%         true ->
%             ignore;
%         false ->
%             PetBag = common_pet:role_pet_bag_backup(RoleID),
%             Pets = PetBag#p_role_pet_bag.pets,
%             NewPets = lists:foldr(
%               fun(IDName,Acc) ->
%                       case IDName#p_pet_id_name.pet_id of
%                           PetID ->
%                               [IDName#p_pet_id_name{color=Color}|Acc];
%                           _ ->
%                               [IDName|Acc]
%                       end
%               end,[],Pets),
%             NewBagInfo = PetBag#p_role_pet_bag{pets=NewPets},
%             self() ! {mod_map_pet,{pet_color_goal,RoleID,Color}}, 
%             set_role_pet_bag_info(RoleID, NewBagInfo),
%             Record = #m_pet_bag_info_toc{info=NewBagInfo},
%             common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_BAG_INFO, Record)
%     end.
                    
get_next_level_exp(Level) ->
    LevelExpInfo = cfg_pet_level:level_info(Level),
    LevelExpInfo#pet_level.next_level_exp.

hook_role_level_change(_RoleID) -> ok.

hook_pet_levelup(RoleID,PetID) ->
    PetInfo             = get_pet_info(RoleID,PetID),
    NewMaxUnderstanding = cfg_pet_understanding:max_understanding(PetInfo#p_pet.level),
    NewMaxAptitude      = common_pet:get_pet_max_aptitude(PetInfo),
    case NewMaxUnderstanding > PetInfo#p_pet.max_understanding orelse
         NewMaxAptitude > PetInfo#p_pet.max_aptitude of
        true ->
            NewPetInfo = PetInfo#p_pet{
                max_understanding = NewMaxUnderstanding,
                max_aptitude      = NewMaxAptitude
            },
            set_pet_info(PetID, NewPetInfo),
            Msg = #m_pet_info_toc{succ=true, pet_info=NewPetInfo},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_INFO, Msg);
        false -> ignore
    end.

assert_add_exp(PetLevel,PetName, RoleLevel) ->
	case can_add_exp(PetLevel,PetName, RoleLevel) of
		true ->
			ignore;
		{false,Reason} ->
			throw({error,Reason})
	end.

assert_add_exp2(Level,PetName, RoleLevel) ->
	case can_add_exp(Level,PetName, RoleLevel) of
		true ->
			ignore;
		{false,Reason} ->
			db:abort({full_level,Reason})
	end.	

can_add_exp(Level, PetName, RoleLevel) ->
    PetLevelLimit = cfg_pet_level:max_level(RoleLevel),
    case PetLevelLimit > Level of
        true -> true;
        false ->
            [MaxLevel] = common_config_dyn:find(etc, max_level),
            PetName1 = common_tool:to_list(PetName),
            case Level >= MaxLevel of
                true  -> {false, common_misc:format_lang(<<"您的宠物【~ts】已满级了，无法继续获取经验">>, [PetName1])};
                false -> {false, common_misc:format_lang(<<"您的宠物【~ts】已无法继续获取经验了，需要提升角色等级">>, [PetName1])}
            end
    end.
	

get_pet_exp(RoleID,AddExp) ->
	case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
		P when P == undefined orelse P == 0 ->
			undefined;
		PetID ->
			case mod_role_tab:get(RoleID,{?ROLE_PET_INFO,PetID}) of
				undefined ->
					undefined;
				#p_pet{level=Level} ->
					case mod_map_role:get_role_attr(RoleID) of
						{ok,#p_role_attr{level=RoleLevel}} ->
							case Level < RoleLevel of
								true ->
									AddExp * Level div RoleLevel;
								false ->
									AddExp
							end;
						_ ->
							undefined
					end
			end
	end.

%% =================================================================
%% ========================宠物亲密度的定时器 ======================

%% 获取宠物性格id，具体定义见: pet.hrl
get_pet_character(PetTypeId) ->
    PetBaseInfo = cfg_pet:get_base_info(PetTypeId),
    PetBaseInfo#p_pet_base_info.character.

%% 判断宠物是否学会了指定的天赋技能，学会了则返回true，否则返回false
is_pet_learned_trick(_PetInfo, []) -> false;
is_pet_learned_trick(PetInfo, [PetTrick | Rest]) ->
    case lists:keymember(PetTrick, #p_pet_skill.skill_id, PetInfo#p_pet.tricks) of
        true -> {true, PetTrick};
        false -> is_pet_learned_trick(PetInfo, Rest)
    end.

refresh_qrhl_data(RoleID) ->
    PetBagInfo = get_role_pet_bag_info(RoleID),
    F = fun(PetIdName) ->
                PetID5 = PetIdName#p_pet_id_name.pet_id,
                PetInfo5 = get_pet_info(RoleID, PetID5),
                #p_pet{phy_attack_aptitude = V1,
                       phy_defence_aptitude = V2,
                       magic_defence_aptitude = V3,
                       max_hp_aptitude = V4,
                       double_attack_aptitude = V5} = PetInfo5,
                lists:sum([V1, V2, V3, V4, V5])
        end,
    List = [F(PetIdName) || PetIdName <- PetBagInfo#p_role_pet_bag.pets],
    Max =
        if List =:= [] ->
                0;
           true -> lists:max(List)
        end,
    mod_qrhl:send_event(RoleID, zizhi, Max).

