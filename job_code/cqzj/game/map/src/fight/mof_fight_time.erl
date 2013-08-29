%% Author: xierfongfeng
%% Created: 2013-3-6
%% Description:
-module(mof_fight_time).

%%
%% Include files
%%
-include("mgeem.hrl").

-define(last_attack_time, last_attack_time).
-define(last_skill_time,  last_skill_time).


%%
%% Exported Functions
%%
-export([
	check_cd/5,
	update_cd/3,
	set_last_skill_time/3,
    set_last_skill_time/4,
	erase_last_skill_time/2,
	get_last_skill_time/2,
    get_last_skill_time/3
]).

%%
%% API Functions
%%
check_cd(RoleID, SkillID, CoolTime, AttackSpeed, Now) ->
    %%怒气技能不计算公共CD
    cfg_fight:is_nuqi_skill(SkillID) orelse begin
    	LastSkillTime = get_last_skill_time(role, RoleID, SkillID),
    	timer:now_diff(Now, LastSkillTime) / 1000 > CoolTime - 100 
    		orelse throw({error, 90001, ?_LANG_FIGHT_ILLEGAL_SKILL_INTERVAL}),
    	LastAttackTime = get_last_attack_time(role, RoleID),
    	timer:now_diff(Now, LastAttackTime) / 1000 > 1000000 / AttackSpeed - 200 
    		orelse throw({error, 90000, ?_LANG_FIGHT_ATTACK_SPEED_ILLEGAL})
    end.

update_cd(RoleID, SkillID, Now) ->
	set_last_skill_time(role, RoleID, SkillID, Now),
	set_last_attack_time(role, RoleID, Now).

get_last_attack_time(ActorType, ActorID) ->
    case erlang:get({?last_attack_time, ActorType, ActorID}) of
        undefined ->
            {0, 0, 0};
        AttackTime ->
            AttackTime
    end.

set_last_attack_time(ActorType, ActorID, Now) ->
    erlang:put({?last_attack_time, ActorType, ActorID}, Now).

set_last_skill_time(ActorType, ActorID, SkillTime) ->
    erlang:put({?last_skill_time, ActorType, ActorID}, SkillTime).

get_last_skill_time(ActorType, ActorID) ->
    case erlang:get({?last_skill_time, ActorType, ActorID}) of
        undefined ->
            [];
        SkillTime ->
            SkillTime
    end.

erase_last_skill_time(ActorType, ActorID) ->
    erlang:erase({?last_skill_time, ActorType, ActorID}).

set_last_skill_time(ActorType, ActorID, SkillID, Now) ->
    SkillTime = get_last_skill_time(ActorType, ActorID),
    SkillTime2 = [{SkillID, Now}|lists:keydelete(SkillID, 1, SkillTime)],
    set_last_skill_time(ActorType, ActorID, SkillTime2).

get_last_skill_time(ActorType, ActorID, SkillID) ->
    SkillTime = get_last_skill_time(ActorType, ActorID),
    case lists:keyfind(SkillID, 1, SkillTime) of
        false ->
            {0, 0, 0};
        {_, LastUseTime} ->
            LastUseTime
    end.


%%
%% Local Functions
%%

