%% Author: xierf
%% Created: 2012-5-22
%% Description: 镜像模块
-module(mod_mirror).

%%
%% Include files
%%
-include("mgeem.hrl"). 
-include("mirror.hrl").


%%
%% Exported Functions
%%
-export([is_mirror/2, mirrors/0, register/1, copy/1, handle/2]).

-define(ROLE_PET_GROW_INFO,role_pet_grow_info).

%%
%% API Functions
%%
is_mirror(ActorType, ActorID) ->
	case mod_map_actor:get_actor_mapinfo(ActorID, ActorType) of
		#p_map_role{is_mirror=true} ->
			true;
		#p_map_pet{is_mirror=true} ->
			true;
		_ ->
			false
	end.

mirrors() ->
	case get(mirrors) of
		undefined ->
			[];
		Mirrors ->
			Mirrors
	end.

register(Who) ->
	put(mirrors, [Who|lists:delete(Who, mirrors())]).

read(?DB_ROLE_SKILL_P, RoleID) ->
	[R] = db:dirty_read(?DB_ROLE_SKILL_P, RoleID),
	{{?role_skill, RoleID}, R#r_role_skill.skill_list};
read(?DB_ROLE_MISC_P, Roleid) ->
	[R] = db:dirty_read(?DB_ROLE_MISC_P, Roleid),
	R#r_role_misc.tuples;
read(?DB_ROLE_PET_BAG_P, Roleid) ->
	case db:dirty_read(?DB_ROLE_PET_BAG_P, Roleid) of 
		[] -> #p_role_pet_bag{role_id = Roleid, content = 0, summoned_pet_id = 0, hidden_pets = [], pets = [], show_list = []};
		[R] -> R
	end;
read(Tab, Roleid) ->
	[R] = db:dirty_read(Tab, Roleid),
	R.

copy(RoleID) ->
	case mod_role_tab:is_exist(RoleID) of
	true ->
		copy(RoleID, mod_role_tab:list(RoleID));
	false ->
		RolePetBag = read(?DB_ROLE_PET_BAG_P, RoleID),
		RolePetLst = [
			{{?ROLE_PET_INFO, PetID}, read(?DB_PET_P, PetID)}||
			#p_pet_id_name{pet_id=PetID} <- RolePetBag#p_role_pet_bag.pets
		],
		copy(RoleID, [
			read(?DB_ROLE_ATTR, RoleID),
			read(?DB_ROLE_BASE, RoleID),
			read(?DB_ROLE_POS, RoleID),
			read(?DB_ROLE_FIGHT, RoleID),
			read(?DB_ROLE_SKILL_P, RoleID),
			RolePetBag
		] ++ RolePetLst)
	end.

copy(RoleID, RecList) ->
	MirrorRoleID = get_minus(RoleID),
	lists:foldl(fun
		(Rec, Acc) when is_record(Rec, p_role_attr) ->
		 	[Rec#p_role_attr{role_id=MirrorRoleID}|Acc];
		(Rec, Acc) when is_record(Rec, p_role_base) ->
			Buffs = [B#p_actor_buf{actor_id=MirrorRoleID}||B<-Rec#p_role_base.buffs],
		 	[Rec#p_role_base{role_id=MirrorRoleID, buffs=Buffs, pk_mode=?PK_ALL}|Acc];
		(Rec, Acc) when is_record(Rec, p_role_fight) ->
			[Rec#p_role_fight{role_id=MirrorRoleID}|Acc];
		(Rec, Acc) when is_record(Rec, p_role_pet_bag) ->
		 	#p_role_pet_bag{
				summoned_pet_id = SummonedPetID,
				hidden_pets     = HiddenPets,
				pets            = Pets
			} = Rec,
		 	[Rec#p_role_pet_bag{
		 		role_id 		= MirrorRoleID,
		 		summoned_pet_id = get_minus(SummonedPetID),
				hidden_pets     = [get_minus(HiddenPetID)||HiddenPetID<-HiddenPets],
				pets            = [Pet#p_pet_id_name{
					pet_id = get_minus(Pet#p_pet_id_name.pet_id)
				}||Pet<-Pets]
		 	}|Acc];
		({{?ROLE_PET_INFO, PetID}, Rec}, Acc) ->
		 	MirrorPetID = get_minus(PetID),
		 	[{{?ROLE_PET_INFO, MirrorPetID}, Rec#p_pet{role_id=MirrorRoleID, pet_id=MirrorPetID}}|Acc];
		({{?role_skill, _}, Rec}, Acc) ->
			[{{?role_skill, MirrorRoleID}, Rec}|Acc];
		({{r_skill_ext, _}, Rec}, Acc) ->
			[{{r_skill_ext, MirrorRoleID}, Rec}|Acc];
		({r_fulu, Data}, Acc) ->
			[{r_fulu, Data}|Acc];
		(_Rec, Acc) ->
		 	Acc
	end, [], RecList).

handle({summon, MirrorTab}, MapState) ->
	enter(MirrorTab, MapState);

handle({prepare, EnemyRoleID}, _MapState) ->
	lists:foreach(fun
		({role, RoleID}) ->
			mod_role2:modify_pk_mode_without_check(RoleID, ?PK_PEACE),
			mod_mirror_ai:add_ai_state(role, RoleID, EnemyRoleID),
			add_role_prepare_drivers(RoleID, mod_skill:get_role_skill_list(RoleID));
		({pet, PetID}) ->
			mod_mirror_ai:add_ai_state(pet, PetID, EnemyRoleID),
			#p_map_pet{role_id=RoleID} = mod_map_actor:get_actor_mapinfo(PetID, pet),
			#p_pet{tricks=Tricks, skills=Skills} = mod_map_pet:get_pet_info(RoleID, PetID),
			add_pet_prepare_drivers(PetID, Tricks, Skills)
	end, mirrors());

handle({activate, EnemyRoleID}, _MapState) ->
	lists:foreach(fun
		({role, RoleID}) ->
			mod_mirror_ai:add_ai_state(role, RoleID, EnemyRoleID),
			{ok, #p_role_attr{category=Category}} = mod_map_role:get_role_attr(RoleID),
			add_role_fight_drivers(Category, RoleID, EnemyRoleID, mod_skill:get_role_skill_list(RoleID));
		(_) ->
			ignore
	end, mirrors());

handle(unsummon, MapState) ->
	handle({unsummon, mirrors()}, MapState);

handle(inactivate, MapState) ->
	handle({inactivate, mirrors()}, MapState);

handle({unsummon, Mirrors}, MapState) ->
	handle({inactivate, Mirrors}, MapState),
	lists:foreach(fun
		({ActorType, ActorID}) ->
			mod_map_actor:do_mirror_quit(ActorID, ActorType, MapState)
	end, Mirrors),
	erase(mirrors);

handle({inactivate, Mirrors}, _MapState) ->
	lists:foreach(fun
		({ActorType, ActorID}) ->
			mof_skill_cast:stop(ActorType, ActorID),
			mod_mirror_ai:del_ai_state(ActorType, ActorID)
	end, Mirrors);

handle({pet_reborn, PetInfo}, MapState) ->
	mod_map_pet:auto_summon_mirror_pet(PetInfo, MapState).

%%
%% Local Functions
%%
enter(MirrorTab, MapState) ->
	[RoleBase] = ets:lookup(MirrorTab, p_role_base),
	RoleBase2  = mod_role_buff:hook_mirror_enter(RoleBase),
	ets:insert(MirrorTab, RoleBase2),
	RoleID      = RoleBase2#p_role_base.role_id,
	[RoleAttr]  = ets:lookup(MirrorTab, p_role_attr),
	[RoleFight] = ets:lookup(MirrorTab, p_role_fight),
	RoleFight2  = RoleFight#p_role_fight{
		role_id = RoleID, 
		hp      = RoleBase2#p_role_base.max_hp, 
		mp      = RoleBase2#p_role_base.max_mp
	},
	MapID = MapState#map_state.mapid,
	{_, TX, TY} = common_misc:get_born_info_by_map(MapID),
	RolePos = #p_role_pos{
		map_id           = MapID,
		role_id          = RoleID,
		pos              = #p_pos{tx=TX+2, ty=TY-2},
		map_process_name = mgeer_role:proc_name(get(role_id))
	},
	ets:insert(MirrorTab, RoleFight2),
	ets:insert(MirrorTab, RolePos),
	MapInfo = get_role_map_info(RoleBase2, RoleAttr, RolePos),
	mod_map_actor:do_enter(?DEFAULT_UNIQUE, mirror, RoleID, role, MapInfo, undefined, MapState),
	[#p_role_pet_bag{summoned_pet_id=SummonedPetID}] = ets:lookup(MirrorTab, p_role_pet_bag),
	case ets:lookup(MirrorTab, {?ROLE_PET_INFO, SummonedPetID}) of
		[{_, SummonedPet}] when is_record(SummonedPet, p_pet) ->
			mod_map_pet:auto_summon_mirror_pet(SummonedPet, MapState);
		_ ->
			ignore
	end.

get_role_map_info(RoleBase, RoleAttr, RolePos) ->
	#p_role_base{
		role_id         = RoleID, 
		role_name       = RoleName, 
		faction_id      = FactionID, 
		family_id       = FamilyID,
		family_name     = FamilyName, 
		max_hp          = MaxHP, 
		max_mp          = MaxMP, 
		move_speed      = MoveSpeed, 
		cur_title       = CurTitle,
		cur_title_color = Color, 
		pk_points       = PkPoint,
		buffs 			= Buffs
	} = RoleBase,
	#p_role_attr{
		level           = Level, 
		skin            = Skin, 
		show_cloth      = ShowCloth, 
		jingjie         = Jingjie
	} = RoleAttr,
	#p_map_role{
		role_id          = RoleID, 
		role_name        = RoleName,
		faction_id       = FactionID,
		cur_title        = CurTitle , 
		cur_title_color  = Color, 
		family_id        = FamilyID,
		family_name      = FamilyName,
		pos              = RolePos#p_role_pos.pos, 
		hp               = MaxHP, 
		max_hp           = MaxHP,
		mp               = MaxMP, 
		max_mp           = MaxMP, 
		skin             = Skin, 
		move_speed       = MoveSpeed, 
		level            = Level, 
		pk_point         = PkPoint, 
		show_cloth       = ShowCloth,
		sex              = RoleBase#p_role_base.sex, 
		category         = RoleAttr#p_role_attr.category,
		jingjie          = Jingjie, 
		state_buffs      = Buffs,
		is_mirror        = true
	}.

add_role_fight_drivers(Category, MirrorRoleID, EnemyRoleID, Skills) ->
	AttackSkillID = case Category of
		0 -> 1;
		_ -> Category
	end,
	AttackDistance = case Category of
		0 -> 1;
		1 -> 1;
		2 -> 1;
		3 -> 1;
		4 -> 3
	end,
	mod_mirror_ai:add_stop_driver(role, MirrorRoleID),
	mod_mirror_ai:add_follow_driver(role, MirrorRoleID, role, EnemyRoleID, AttackDistance),
	mod_mirror_ai:add_attack_driver(role, MirrorRoleID, role, EnemyRoleID, AttackDistance, AttackSkillID),
	lists:foreach(fun
		(#r_role_skill_info{skill_id=SkillID, cur_level=SkillLevel}) when SkillID > 10 ->
			mod_mirror_ai:add_skill_driver(role, MirrorRoleID, role, EnemyRoleID, SkillID, SkillLevel);
		(_) ->
			ignore
	end, Skills).

add_role_prepare_drivers(MirrorRoleID, Skills) ->
	lists:foreach(fun
		(#r_role_skill_info{skill_id=SkillID, cur_level=SkillLevel}) when SkillID > 10 ->
			mod_mirror_ai:add_prepare_driver(role, MirrorRoleID, SkillID, SkillLevel);
		(_) ->
			ignore
	end, Skills).

add_pet_prepare_drivers(MirrorPetID, Tricks, Skills) ->
	lists:foreach(fun
		(#p_pet_skill{skill_id=SkillID, skill_level=SkillLevel}) when SkillID > 10 ->
			mod_mirror_ai:add_prepare_driver(pet, MirrorPetID, SkillID, SkillLevel);
		(_) ->
			ignore
	end, Tricks),
	lists:foreach(fun
		(#r_role_skill_info{skill_id=SkillID, cur_level=SkillLevel}) when SkillID > 10 ->
			mod_mirror_ai:add_prepare_driver(pet, MirrorPetID, SkillID, SkillLevel);
		(_) ->
			ignore
	end, Skills).

get_minus(Num) when is_integer(Num) ->
	-abs(Num);
get_minus(Num) ->
	Num.

