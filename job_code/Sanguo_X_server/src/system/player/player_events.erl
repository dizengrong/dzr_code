-module(player_events).

-include("common.hrl").

-export([
        post_event/3
    ]).


%% 打败某怪物组合
post_event(PS, 'monster.kill_group', {MonsterGroupID} = EvContent) ->
    ?INFO(player_events, "Player event triggered: monster.kill_group, ~w", [EvContent]),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {update_mon_group_killing_task, MonsterGroupID}
        );

%% 背包中物品数量改变
post_event(PlayerId, 'items.bag_count_alter', {ItemID, AlterNum} = EvContent) ->
    ?INFO(player_events, "Player event triggered: items.bag_count_alter, ~w", [EvContent]),
    %% 采集任务
    mod_task:update_collecting_task(PlayerId,ItemID,AlterNum);

%% 打一次怪物(不论输赢)
post_event(PS,'monster.fight_monster',{_MonsterGroupID}=EvContent) ->
	?INFO(player_events, "Player event triggered: monster.fight_group, ~w", [EvContent]),
    gen_server:cast(PS#player_status.guaji_pid,useGuaji);

%% 打怪中被怪打死了
post_event(PS,'monster.monster_win',{_MonsterGroupID} = EvContent) ->
	?INFO(player_events, "Player event triggered: monster.monster_win, ~w", [EvContent]),
	gen_server:cast(PS#player_status.guaji_pid,{stopGuaji,6}).