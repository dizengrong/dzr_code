%% Author:xierongfeng
%% Created: 2013-2-24
%% Description:普通攻击模块(可以闪避)
-module(mof_normal_attack).

%%
%% Include files
%%
-include("mgeem.hrl").

-define(MAX_COMBOS_NUM, 2).

%%
%% Exported Functions
%%
-export([handle/6, handle2/6, calc_damage/3]).

%%
%% API Functions
%%
handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState) ->
	{CasterAttr, TargetAttr, SkillBaseInfo2, SkillLevelInfo2} = 
		mof_before_attack:handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState),
	
	TargetAttr#actor_fight_attr.actor_type == ?TYPE_PET andalso throw({error, "无效目标"}),
	is_miss(CasterAttr, TargetAttr) andalso throw([
		#p_attack_result{
			dest_id   = TargetAttr#actor_fight_attr.actor_id, 
			dest_type = TargetAttr#actor_fight_attr.actor_type, 
			modifier  = ?MODIFIER_MISS
	}]),
	handle2(CasterAttr, TargetAttr, Pos, SkillBaseInfo2, SkillLevelInfo2, MapState).
handle2(CasterAttr, TargetAttr, Pos, SkillBaseInfo2, SkillLevelInfo2, MapState) ->
	Damage  = calc_damage(CasterAttr#actor_fight_attr.category, CasterAttr, TargetAttr),
	IsCrit  = mof_common:if_crit(CasterAttr, TargetAttr),
	AttResult = attack_result(TargetAttr, Damage, IsCrit),
	mof_after_attack:handle(CasterAttr, TargetAttr, 
		AttResult, Pos, SkillBaseInfo2, SkillLevelInfo2, MapState),
	mof_hurt_rebound:handle(CasterAttr, TargetAttr, MapState),
	mof_common:erase_attack_result().

attack_result(TargetAttr, Damage, IsCrit) ->
	case IsCrit of 
		true -> Modifier = ?MODIFIER_CRIT,   Damage2 = Damage*2; 
		_    -> Modifier = ?MODIFIER_NORMAL, Damage2 = Damage 
	end,
	#p_attack_result{
		dest_id      = TargetAttr#actor_fight_attr.actor_id,
		dest_type    = TargetAttr#actor_fight_attr.actor_type,
		result_type  = ?RESULT_TYPE_REDUCE_HP,
		result_value = Damage2,
		modifier     = Modifier
	}.

calc_damage(Category, CasterAttr, TargetAttr) ->
	CasterLevel = CasterAttr#actor_fight_attr.actor_level,
	TargetLevel = TargetAttr#actor_fight_attr.actor_level,
	{CasterAttack,  CasterHurtValue}  = get_attack(Category, CasterAttr),
	{TargetDefence, TargetAntiValue}  = get_defence(Category, TargetAttr),
	#actor_fight_attr{no_defence = CasterNoDefenceValue} = CasterAttr,
	Random = common_tool:random(500, 1000) * 0.0001,
	CasterNoDefenceRate = cfg_fight:nodefence_rate(CasterLevel, CasterNoDefenceValue),
	CasterHurtRate      = cfg_fight:hurt_rate(CasterLevel, CasterHurtValue),
	TargetAntiRate      = cfg_fight:anti_rate(TargetLevel, TargetAntiValue),
	Damage = max(0, (CasterAttack-TargetDefence*(1-CasterNoDefenceRate/10000))*
	    (1+CasterHurtRate/10000-TargetAntiRate/10000))+CasterAttack*Random,
	case CasterAttr#actor_fight_attr.actor_type == ?TYPE_ROLE andalso 
		 TargetAttr#actor_fight_attr.actor_type == ?TYPE_ROLE of
		true ->  
			AddJueweiSup = cfg_juewei:hurt_suppress(CasterAttr#actor_fight_attr.juewei, 
													TargetAttr#actor_fight_attr.juewei),
			Damage1 = Damage * (1 + AddJueweiSup);
		false -> 
			Damage1 = Damage
	end,
    max(1, round(Damage1)).

%%
%% Local Functions
%%
is_miss(#actor_fight_attr{actor_level=CasterLevel, hit_rate=CasterHitValue}, 
		#actor_fight_attr{actor_level=TargetLevel, miss=TargetMissValue}) ->
	CasterHitRate  = cfg_fight:hit_rate(CasterLevel, CasterHitValue),
	TargetMissRate = cfg_fight:miss_rate(TargetLevel, TargetMissValue),
    random:uniform(10000) < 10000 - (CasterHitRate-TargetMissRate).

get_attack(phy, FightAttr) ->
	#actor_fight_attr{
		min_phy_attack = MinAttack, 
		max_phy_attack = MaxAttack,
		luck           = Luck,
		phy_hurt_rate  = Hurt
	} = FightAttr,
	Attack = random_attack(MinAttack, MaxAttack, random:uniform(100) + Luck),
	{Attack, Hurt};
get_attack(magic, FightAttr) ->
	#actor_fight_attr{
		min_magic_attack = MinAttack, 
		max_magic_attack = MaxAttack,
		luck             = Luck,
		magic_hurt_rate  = Hurt
	} = FightAttr,
	Attack = random_attack(MinAttack, MaxAttack, random:uniform(100) + Luck),
	{Attack, Hurt}.

random_attack(MinAttack, MaxAttack, Luck) ->
	if 
        Luck > 100 ->
            MaxAttack;
        Luck < 1 ->
            MinAttack;
        true ->
            MinAttack + random:uniform(trunc(abs(MinAttack-MaxAttack))+1) - 1
    end.

get_defence(phy, FightAttr) ->
	#actor_fight_attr{phy_defence=Defence, phy_anti=Anti} = FightAttr, 
	{Defence, Anti};
get_defence(magic, FightAttr) ->
	#actor_fight_attr{magic_defence=Defence, magic_anti=Anti} = FightAttr, 
	{Defence, Anti}.


