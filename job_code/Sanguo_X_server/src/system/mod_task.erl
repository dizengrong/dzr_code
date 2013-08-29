-module(mod_task). 

-behaviour(gen_callback_server).

-include("common.hrl").
%% -include("gen_callback_server.hrl").


-define(TASK_CACHE_REF, cache_util:get_register_name(player_task)).

%%    任务类型                  ID参数      数量参数
%% -----------------------------------------------------
%%   1  -   打怪                怪物ID      怪物数量
%%   2  -   谈话                0           0
%%   3  -   穿装备              装备ID      1次
%%   4  -   雇佣佣兵            佣兵id      1次
%%   9  -   副本                副本ID      1次
%%   20  -   收集                物品ID     物品数量
%%   21  -   宝石                 宝石ID    1
%%   24  -   强化主角装备到n级   物品ID     强化等级
%%   30  -   爬塔                层数       1
%%   32  -   采集                NPCID      1次 
%%   37  -   技能                技能ID
%%   39  -   神器修炼            0          1

-define(REQ_TYPES_DEPENDING_ON_PLAYER_STATE, [3]).
-define(REQ_TYPES_NEED_ITEM_PURGING, [20]).

-record(state, 
    {
        player_id   :: player_id()

    }).

-export([
        update_monster_group_killing_task/2,
        update_monster_killing_task/3,      %% 打怪
        update_collecting_task/3,           %% 收集一定物品
        update_harvesting_task/3,           %% 采集
        update_clothing_task/3,             %% 穿装备
        update_inten_equipment_task/3,      %% 强化主角装备到n级
        update_employ_task/3,               %% 雇佣佣兵
        update_skill_task/2,                %% 升级技能
        update_dungeon_task/3,              %% 通关副本
        updata_shenqi_task/3,               %% 修炼神器
        updata_inlay_task/3,                %% 镶嵌宝石
        updata_marstower_task/3             %% 爬塔
    ]).

-export([
        start_link/1,
        update_task_state/4,
        client_update_task_state/4,
        client_check_can_complete_tip/3,
        client_get_current_cyclic_task/1
    ]).

%% gen_callback_server callbacks
-export([init/1, handle_action/2, handle_info/2, terminate/2, code_change/3]).

start_link(PlayerID) ->
    gen_callback_server:start_link(?MODULE, [PlayerID], []).

client_get_current_cyclic_task(PlayerID) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            get_current_cyclic_task,
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17021)
        ).

%% 谈话任务不需要更新，可以直接提交，所以这里没有对应的处理函数

%% 打怪比较特殊，传过来的一般是怪物组合ID，所以加一层代码，把怪物组合转换成独立怪物
%% 而且这个有可能在server进程上下文里被调用（野外怪？），所以把主要工作发到mod_task进程里做
update_monster_group_killing_task(PlayerID, MonsterGroupID) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {update_mon_group_killing_task, MonsterGroupID}
        ).

update_monster_killing_task(PlayerID, MonID, Num) ->
    ?INFO(task,"Kill Moster,AccountID:~w,MonID:~w,Num:~w",[PlayerID, MonID, Num]),
    client_update_task_state(PlayerID, 1, MonID, Num).

update_collecting_task(PlayerID, ItemID, AlterNum) ->
    client_update_task_state(PlayerID, 20, ItemID, AlterNum).

update_harvesting_task(PlayerID, ItemID, AlterNum) ->
    client_update_task_state(PlayerID, 32, ItemID, AlterNum).

update_clothing_task(PlayerID, ItemID, AlterNum) ->
    case ItemID =:= 10 orelse ItemID =:=11 of
        true ->
            ItemID1 = 9;
        false ->
            ItemID1 = ItemID
    end,
    client_update_task_state(PlayerID, 3, ItemID1, AlterNum).

update_inten_equipment_task(PlayerID, ItemID, AlterNum) ->
    case ItemID =:= 10 orelse ItemID =:=11 of
        true ->
            ItemID1 = 9;
        false ->
            ItemID1 = ItemID
    end,
    client_update_task_state(PlayerID, 24, ItemID1, AlterNum).

update_employ_task(PlayerID,ID,AlterNum) ->
    ?INFO(task,"********************************PlayerID = ~w,ID =~w,Num=~w",[PlayerID,ID,AlterNum]),   
    client_update_task_state(PlayerID,4,ID,AlterNum).

update_skill_task(PlayerID,SkillID) ->
    SkillType = SkillID div 1000,
    SKillLevel = SkillID rem 1000,
    case SkillType =:= 111 orelse SkillType =:= 116 orelse SkillType =:= 106 of
        true ->
            client_update_task_state(PlayerID, 37, 106001, SKillLevel);
        false ->
            case SkillType =:= 112 orelse SkillType =:= 117 orelse SkillType =:= 107 of
                true ->
                    client_update_task_state(PlayerID, 37, 107001, SKillLevel);
                false ->
                    void
            end
    end.
    % Fun = fun(N,SkillID) ->
    %     %% 取得目标集
    %     SkillList = data_task:getTargetSet(N),
    %     F1 = fun({N,SkillID1,SkillID}) ->
    %         case (SkillID1 div 1000) =:= (SkillID div 1000) andalso SkillID > SkillID1 of
    %             true ->
    %                 client_update_task_state(PlayerID, 37, N, SkillID - SkillID1);
    %             false ->
    %                 void
    %         end
    %     end,
    %     [F1({N,SkillID1,SkillID})|SkillID1 <- SkillList]
    % end,
    % [Fun(N,SkillID)|N <-data_task:getTargetList(37)].
update_dungeon_task(PlayerID,DungeonId,Num) ->
    client_update_task_state(PlayerID,9,DungeonId,Num).

updata_shenqi_task(PlayerID,TargetID,Num) ->
    client_update_task_state(PlayerID,39,TargetID,Num).

updata_inlay_task(PlayerID,JewelId,Num) ->
    client_update_task_state(PlayerID,21,JewelId,Num).

updata_marstower_task(PlayerID,Level,Num) ->
    client_update_task_state(PlayerID,20,Level,Num).
%% -- 通用任务更新方法 ---------------------------------
update_task_state(PlayerID, ReqType, ID, Num) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {update_task_state, ReqType, ID, Num}
        ).


client_update_task_state(PlayerID, ReqType, ID, Num) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {update_task_state, ReqType, ID, Num},
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17005)
        ).

client_check_can_complete_tip(PlayerID, ReqType, ID) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {check_can_complete_tip, ReqType, ID}, 
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17005)
        ).


init([PlayerID]) ->
    erlang:process_flag(trap_exit, true),
    erlang:put(id, PlayerID),
    mod_player:update_module_pid(PlayerID, ?MODULE, self()),

    PlayerTask = get_player_task(PlayerID),

    %% 检查已接任务的数据是不是被改过，有改过的话放弃掉
    check_received_tasks(PlayerTask#player_task.gd_receivedList),

    %% XXX: 因为这两个操作要用到别的模块，别的模块又要通过mod_player:get_player_status(...)
    %%      拿状态，这时PlayerStatus又没准备好，所以只能延时去做……
    erlang:send_after(2000, self(), check_task_state),
    %%erlang:send_after(2000, self(), activate_cyclic_task),

    NewState = #state{player_id = PlayerID},
    {ok, NewState}.


handle_action(get_player_task, State) ->
    Reply = {ok, get_player_task(State#state.player_id)},
    {reply, Reply, State};


handle_action(get_received_list, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    Reply = {ok, PlayerTask#player_task.gd_receivedList},
    {reply, Reply, State};


handle_action(get_completed_list, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    Reply = {ok, PlayerTask#player_task.gd_completedList},
    {reply, Reply, State};


handle_action({update_mon_group_killing_task, MonGroupID}, State) ->
    MonList = (data_mon_group:get(MonGroupID))#mon_group.pos,
    MonList1 = combine(MonList),
    F = fun({MonID, Num}) ->
        update_monster_killing_task(State#state.player_id, MonID, Num)
    end,
    [F(MonInfo) || MonInfo <- MonList1],
    {reply, ok, State};


handle_action({update_task_state, ReqType, ID, Num}, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    RecList = PlayerTask#player_task.gd_receivedList,
    PlayerID = State#state.player_id,

    ?INFO(task,"Update task state,Type =~w,ID =~w,Num =~w",[ReqType,ID,Num]),
    Param = {{ReqType, ID, Num, PlayerID}, fun update_tip_by_req/2},
    {_, UpdateList, NewRecList} = 
        lists:foldl(fun update_task_state_helper/2, {Param, [], []}, RecList),
    gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
        [{#player_task.gd_receivedList, NewRecList}]),
    case UpdateList of
        []->
            Reply = ok;
        _NotNull ->
            Reply = {ok, UpdateList}
    end,
    {reply, Reply, State};


handle_action({check_can_complete_tip, ReqType, ID}, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    RecList = PlayerTask#player_task.gd_receivedList,
    PlayerID = State#state.player_id,

    Param = {{ReqType, ID, 0, PlayerID}, fun update_tip_by_player_state/2},
    {_, UpdateList, NewRecList} = 
        lists:foldl(fun update_task_state_helper/2, {Param, [], []}, RecList),
    gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id,
        [{#player_task.gd_receivedList, NewRecList}]),

    case UpdateList of
        []->
            Reply = ok;
        _NotNull ->
            Reply = {ok, UpdateList}
    end,
    {reply, Reply, State};


handle_action({complete_task, _PlayerStatus, TaskID}, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    Reply = 
    case lists:keytake(TaskID, #task_state.id, PlayerTask#player_task.gd_receivedList) of
        {value, TaskState, RestRecList} ->
            TaskInfo = data_task:get(TaskID),
            case is_finished(TaskState, completing) andalso check_complete_npc(State#state.player_id, TaskInfo) of
                true ->
                    RewardList = 
                    case is_cyclic_task(TaskInfo) of
                        false ->
                            TaskInfo#task.reward;
                        true ->
                            PlayerLevel = mod_role:get_main_level(State#state.player_id),
                            RecvCount = get_received_times(State#state.player_id, TaskInfo#task.type),
                            data_task:get_cyclic_task_reward(TaskInfo#task.type, PlayerLevel, RecvCount)
                    end,
                    case send_reward(State#state.player_id, RewardList) of
                        ok ->
                            %% TODO: 记log
                            purge_task_items(State#state.player_id, TaskState),
                            NewPlayerTask = 
                            case is_cyclic_task(TaskInfo) of
                                false ->
                                    NewCompList = lists:umerge([TaskID], PlayerTask#player_task.gd_completedList),
                                    %% 成就通知
                                    mod_achieve:taskNotify(State#state.player_id,TaskID),
                                    PlayerTask#player_task{
                                        gd_completedList = NewCompList,
                                        gd_receivedList  = RestRecList
                                    };
                                true ->
                                    %% 循环任务成就通知
                                    case TaskInfo#task.type of
                                        ?TASK_TYPE_CYCLIC_SCHOOL ->
                                            mod_achieve:schoolTaskNotify(State#state.player_id,1);
                                        ?TASK_TYPE_CYCLIC_GANK ->
                                            mod_achieve:gankTaskNotify(State#state.player_id,1);
                                        _ElSE ->
                                            void
                                    end,
                                    %% 完成的循环任务不进入已完成列表，而是要刷新下一个循环任务
                                    gen_callback_server:do_async(self(), {refresh_current_cyclic_task, TaskInfo#task.type}),
                                    client_get_current_cyclic_task(State#state.player_id),
                                    PlayerTask#player_task{
                                        gd_receivedList = RestRecList
                                    }
                            end,
                            gen_cache:update_record(?TASK_CACHE_REF, NewPlayerTask),
                            {ok, TaskID};
                        {error, ErrCode} ->
                            {error, ErrCode}
                    end;

                false ->
                    ?INFO(task, "Condition check failed, can't complete task #~w", [TaskID]),
                    {error, quiet}
            end;

        false ->
            ?INFO(task, "Task #~w not found in the received list", [TaskID]),
            {error, quiet}
    end,
    {reply, Reply, State};


handle_action({receive_task, _PlayerStatus, TaskID}, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    Reply = 
    case lists:keyfind(TaskID, #task_state.id, PlayerTask#player_task.gd_receivedList) of
        false ->
            TaskInfo = data_task:get(TaskID),
            %% 循环任务不需要检查前置任务是不是已完成
            %% 如果TaskID不合法，is_cur_cyclic_task(...)这里就会挂掉，没必要另外检查合法性
            case ((not is_cyclic_task(TaskInfo) andalso is_prev_completed(PlayerTask, TaskInfo)) orelse 
                    (is_cur_cyclic_task(PlayerTask, TaskInfo) andalso 
                        can_receive_cyclic(State#state.player_id, TaskInfo))) andalso
                    check_req_level(State#state.player_id, TaskInfo) andalso 
                    check_receive_npc(State#state.player_id, TaskInfo) of
                true ->
                    case send_reward(State#state.player_id, TaskInfo#task.rec_reward) of
                        ok ->
                            %% TODO: 记log
                            trigger_task_state_check(State#state.player_id, TaskInfo#task.tips, receiving),
                            NewTaskState = #task_state{
                                id   = TaskID,
                                tips = TaskInfo#task.tips
                            },
                            NewRecList = [NewTaskState | PlayerTask#player_task.gd_receivedList],
                            gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                                [{#player_task.gd_receivedList, NewRecList}]),

                            case is_cyclic_task(TaskInfo) of
                                false -> void;
                                true  ->
                                    %% XXX: 这里的更新和上面RecList的更新分开来了，大丈夫？
                                    NewCyclicList = PlayerTask#player_task.gd_curCyclicList -- [TaskID],
                                    gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                                        [{#player_task.gd_curCyclicList, NewCyclicList}]),
                                    update_cyclic_counter(State#state.player_id, TaskInfo#task.type)
                            end,

                            {ok, TaskID};

                        {error, ErrCode} ->
                            {error, ErrCode}
                    end;

                false ->
                    ?INFO(task, "Condition check failed for task #~w", [TaskID]),
                    {error, quiet}
            end;

        _ ->
            ?INFO(task, "Task #~w already received", [TaskID]),
            {error, quiet}
    end,
    {reply, Reply, State};


handle_action({give_up_task, TaskID}, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    Reply = 
    case lists:keytake(TaskID, #task_state.id, PlayerTask#player_task.gd_receivedList) of
        {value, _TaskState, RestRecList} ->
            gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                [{#player_task.gd_receivedList, RestRecList}]),

            TaskInfo = data_task:get(TaskID),
            case is_cyclic_task(TaskInfo) of
                true ->
                    case is_cur_cyclic_task(PlayerTask, TaskInfo) of
                        false ->
                            OldCycList = PlayerTask#player_task.gd_curCyclicList,
                            gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                                [{#player_task.gd_curCyclicList, lists:umerge([TaskID], OldCycList)}]);
                        true ->
                            void
                    end;
                false ->
                    void
            end,

            {ok, TaskID};

        false ->
            ?INFO(task, "Task #~w not received yet", [TaskID]),
            {error, quiet}
    end,
    {reply, Reply, State};


handle_action(activate_cyclic_task, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    TypeList = data_task:get_cyclic_type_list(),
    case util:check_other_day(PlayerTask#player_task.gd_lastTime) of
        true ->
            F = fun(Type) ->
                take_out_receive_task_by_type(State#state.player_id,Type),
                gen_callback_server:do_async(self(), {refresh_current_cyclic_task, Type})
            end,
            [F(T) || T <- TypeList],
            gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                [{#player_task.gd_lastTime, util:unixtime()}]);
        false ->
            CurFullList = get_full_cyclic_list(PlayerTask),
            CurTypeList = lists:usort([(data_task:get(TID))#task.type || TID <- CurFullList]),
            F = fun(Type) ->
                case lists:member(Type, CurTypeList) of
                    true  -> void;
                    false -> gen_callback_server:do_async(self(), {refresh_current_cyclic_task, Type})
                end
            end,
            [F(T) || T <- TypeList]
    end,

    {reply, ok, State};


handle_action(get_current_cyclic_task, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    RecList = get_received_cyclic_list(PlayerTask),
    FullList = lists:umerge(lists:usort(RecList), PlayerTask#player_task.gd_curCyclicList),

    F = fun(TID) ->
        T = data_task:get(TID),
        CanRec = 
        case lists:member(TID, RecList) of
            true -> 0;
            _    -> 1
        end,
        %% TODO: 把10放到data文件里
        RemTimes = 10 - get_received_times(State#state.player_id, T#task.type),
        NRemTimes = 
        case RemTimes > 0 of
            true -> 
                RemTimes;
            _  ->
                0
        end,
        {TID, CanRec, NRemTimes}
    end,
    RepList = [F(TID) || TID <- FullList],
    {reply, {ok, RepList}, State};


handle_action({refresh_current_cyclic_task, Type}, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    PlayerLevel = mod_role:get_main_level(State#state.player_id),
    case gen_new_cyclic_task(Type, PlayerLevel) of
        0 ->
            void;
        NewTaskID ->
            NewList = lists:umerge([NewTaskID], PlayerTask#player_task.gd_curCyclicList),
            gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                [{#player_task.gd_curCyclicList, NewList}])
    end,
    {reply, ok, State};

%% 自动完成某一个任务
handle_action({auto_complete_task, TaskID}, State) ->
    TaskInfo = data_task:get(TaskID),
    PlayerTask = get_player_task(State#state.player_id),
    Reply =
    case lists:keytake(TaskID, #task_state.id, PlayerTask#player_task.gd_receivedList) of
        {value, _TaskState, RestRecList} ->
            case TaskInfo#task.auto_complete =:= 1 of
                true ->
                    case auto_complete_helper(State#state.player_id, TaskID) of
                        ok ->
                            case is_cyclic_task(TaskInfo) of
                                true ->
                                    %% 循环任务成就通知
                                    case TaskInfo#task.type of
                                        ?TASK_TYPE_CYCLIC_SCHOOL ->
                                            mod_achieve:schoolTaskNotify(State#state.player_id,1);
                                        ?TASK_TYPE_CYCLIC_GANK ->
                                            mod_achieve:gankTaskNotify(State#state.player_id,1);
                                        _ElSE ->
                                            void
                                    end,
                                    gen_callback_server:do_async(self(), {refresh_current_cyclic_task, TaskInfo#task.type}),
                                    client_get_current_cyclic_task(State#state.player_id),
                                    gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                                    [{#player_task.gd_receivedList,  RestRecList}]),
                                    ?INFO(task,"Auto complete cycle task! ID is ~w",[TaskID]);
                                false ->
                                    NewCompleteList = lists:umerge([TaskID], PlayerTask#player_task.gd_completedList),
                                    gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
                                    [{#player_task.gd_completedList, NewCompleteList},
                                     {#player_task.gd_receivedList,  RestRecList}]),
                                    %% 成就通知
                                    mod_achieve:taskNotify(State#state.player_id,TaskID),
                                    ?INFO(task,"Auto complete task! ID is ~w",[TaskID])
                            end,
                            {ok, TaskID};
                        {error,ErrCode} ->
                            {error,ErrCode}
                    end;
                false ->
                    {error, quiet}
            end;
        false ->
            ?INFO(task, "Task #~w not found in the received list", [TaskID]),
            {error, quiet}
    end,
    {reply, Reply, State};           

%% 自动完成循环任务的消耗与奖励（给客户端信息）
handle_action(auto_complete_info,State)->
    RemTimes1 = 10 - get_received_times(State#state.player_id, ?TASK_TYPE_CYCLIC_GANK), %% 帮派次数
    GankRemTimes = 
    case RemTimes1 > 0 of
        true -> RemTimes1;
        _    -> 0
    end,
    RemTimes2 = 10 - get_received_times(State#state.player_id, ?TASK_TYPE_CYCLIC_SCHOOL), %% 师门次数
    SchoolRemTimes = 
    case RemTimes2 > 0 of
        true -> RemTimes2;
        _    -> 0
    end,
    GankReward = getGankReward(State#state.player_id,GankRemTimes),
    SchoolReward = getSchoolReward(State#state.player_id,SchoolRemTimes),
    GankRewardInfo = rewardListToClientInfo(GankReward),
    SchoolRewardInfo = rewardListToClientInfo(SchoolReward),
    ?INFO(task,"SchoolRewardInfo = ~w,GankRewardInfo = ~w",[SchoolRewardInfo,GankRewardInfo]),
    GoldCost1 = 20*GankRemTimes,
    GoldCost2 = 20*SchoolRemTimes,
    {_ ,Gongxian} = lists:keyfind(?TASK_REWARD_GANG_POINT,1,GankRewardInfo),
    {_ ,SilverGet1} = lists:keyfind(?TASK_REWARD_MONEY,1,GankRewardInfo),
    {_ ,Exp} = lists:keyfind(?TASK_REWARD_EXP,1,SchoolRewardInfo),
    {_ ,SilverGet2} = lists:keyfind(?TASK_REWARD_MONEY,1,SchoolRewardInfo),
    Reply = {ok,{GoldCost1,Gongxian,SilverGet1,GoldCost2,Exp,SilverGet2}},
    {reply,Reply,State};


%% 一键完成循环任务（帮派）
handle_action(auto_complete_gank_cyclic_task,State) ->
    RemTimes1 = 10 - get_received_times(State#state.player_id, ?TASK_TYPE_CYCLIC_GANK), %% 帮派次数
    GankRemTimes = 
    case RemTimes1 > 0 of
        true -> RemTimes1;
        _    -> 0
    end,
    GankReward = getGankReward(State#state.player_id,GankRemTimes),
    GoldCost = 20 * GankRemTimes,
    Reply =
    case mod_economy:check_and_use_bind_gold(State#state.player_id,GoldCost,?GOLD_COMPLETE_DAILY_TASK) of
        true ->
            send_reward(State#state.player_id,GankReward),
            update_cyclic_counter(State#state.player_id, ?TASK_TYPE_CYCLIC_GANK, GankRemTimes),
            take_out_receive_task_by_type(State#state.player_id,?TASK_TYPE_CYCLIC_GANK),
            %% 成就通知
            mod_achieve:gankTaskNotify(State#state.player_id,GankRemTimes),
            {ok,1};
        false ->
            {error,?ERR_NOT_ENOUGH_GOLD}
    end,
    {reply,Reply,State};


%% 一键完成循环任务（师门）
handle_action(auto_complete_school_cyclic_task,State) ->
    RemTimes2 = 10 - get_received_times(State#state.player_id, ?TASK_TYPE_CYCLIC_SCHOOL), %% 师门次数
    SchoolRemTimes = 
    case RemTimes2 > 0 of
        true -> RemTimes2;
        _    -> 0
    end,
    SchoolReward = getSchoolReward(State#state.player_id,SchoolRemTimes),
    GoldCost = 20 * SchoolRemTimes,
    Reply =
    case mod_economy:check_and_use_bind_gold(State#state.player_id,GoldCost,?GOLD_COMPLETE_DAILY_TASK) of
        true ->
            send_reward(State#state.player_id,SchoolReward),
            update_cyclic_counter(State#state.player_id, ?TASK_TYPE_CYCLIC_SCHOOL, SchoolRemTimes),
            take_out_receive_task_by_type(State#state.player_id,?TASK_TYPE_CYCLIC_SCHOOL),
            %% 成就通知
            mod_achieve:gankTaskNotify(State#state.player_id,SchoolRemTimes),
            {ok,2};
        false ->
            {error,?ERR_NOT_ENOUGH_GOLD}
    end,
    {reply,Reply,State};

%%%%%%%%%%%%%%%%%%%%% GM命令 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handle_action({gm_complete_task_until, TaskID}, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    NewCompleteList = gm_complete_helper(State#state.player_id, TaskID, PlayerTask#player_task.gd_completedList),
    gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
        [{#player_task.gd_completedList, NewCompleteList},
         {#player_task.gd_receivedList,  []}]),
    {reply, ok, State};


handle_action(gm_reset_tasks, State) ->
    gen_cache:update_element(?TASK_CACHE_REF, State#state.player_id, 
        [{#player_task.gd_completedList, []},
         {#player_task.gd_receivedList,  []}]),
    {reply, ok, State};


%%%%%%%%%%%%%%%%%%%%% GM命令end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


handle_action(Msg, State) ->
    ?INFO(task, "Unknown message: ~w", [Msg]),
    {reply, ok, State}.

handle_info(check_task_state, State) ->
    PlayerTask = get_player_task(State#state.player_id),
    [trigger_task_state_check(State#state.player_id, T#task_state.tips, initializing) || 
        T <- (PlayerTask#player_task.gd_receivedList)],
    {noreply, State};

handle_info(Info, State) ->
    ?INFO(task, "Unknown info: ~w", [Info]),
    {noreply, State}.

terminate(Reason, _State) ->
    ?INFO(task, "Reason = ~w", [Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                              private functions                                                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



get_player_task(PlayerID) ->
    case gen_cache:lookup(?TASK_CACHE_REF, PlayerID) of
        [PlayerTask] ->
            PlayerTask;
        [] ->
            NewPlayerTask = 
                #player_task {
                    gd_accountID = PlayerID,
                    gd_completedList = [],
                    gd_receivedList = [],
                    gd_curCyclicList = []
                },
            gen_cache:insert(?TASK_CACHE_REF, NewPlayerTask),
            NewPlayerTask
    end.

is_finished(TaskState, Context) ->
    Fun = case Context of
        updating   -> fun is_tip_update_finished/1;
        completing -> fun is_tip_finished/1
    end,
    lists:all(Fun, TaskState#task_state.tips).

is_tip_finished(TaskTip) ->
    ?INFO(task,"check finish, finish Times = ~w,need Times = ~w",[TaskTip#task_tip.finish,TaskTip#task_tip.need]),
    (TaskTip#task_tip.finish >= TaskTip#task_tip.need).
is_tip_update_finished(TaskTip) ->
    {ReqType, _} = TaskTip#task_tip.key,
    (TaskTip#task_tip.finish >= TaskTip#task_tip.need) andalso
    (not lists:member(ReqType, ?REQ_TYPES_DEPENDING_ON_PLAYER_STATE)).

check_complete_npc(PlayerID, TaskInfo) ->
    check_npc_position(PlayerID, TaskInfo#task.npc2).

check_receive_npc(PlayerID, TaskInfo) ->
    check_npc_position(PlayerID, TaskInfo#task.npc1).

check_npc_position(_PlayerID, _NPC) ->
    %%{SceneID, X, Y} = scene:get_position(PlayerID),
    %%lib_scene:check_npc(NPC, SceneID, X, Y).
    true.

send_reward(PlayerID, RewardList) ->
    case count_reward_item_num(RewardList) of
        0 ->
            lists:foreach(
                fun(R) ->
                    send_single_reward(PlayerID, R)
                end,
                RewardList
            ),
            ok;

        ItemNum ->
            case mod_items:getBagNullNum(PlayerID) >= ItemNum of
                true ->
                    lists:foreach(
                        fun(R) ->
                            send_single_reward(PlayerID, R)
                        end,
                        RewardList
                    ),
                    ok;
                false ->
                    {error, ?ERR_ITEM_BAG_NOT_ENOUGH}
            end
    end.

%% TODO: 加上其他类型的奖励(由于数据量不多，策划说写死就好，所以就不另外配表了)
%% 物品奖励
send_single_reward(PlayerID, #task_reward{type = ?TASK_REWARD_ITEM} = R) ->
    case R#task_reward.value of
        9 ->
            %% 奖励物品是武器，则为每个职业筛选合适的武器
            RoleRec = mod_role:get_main_role_rec(PlayerID),
            case RoleRec#role.gd_careerID of
            ?CAREER_HUWEI ->
                ItemList = [{10,1,1}];
            ?CAREER_MENGJIANG ->
                ItemList = [{9,1,1}];
            _ElSE ->
                ItemList = [{11,1,1}]
            end;
        17 ->
            RoleRec = mod_role:get_main_role_rec(PlayerID),
            case RoleRec#role.gd_careerID of
            ?CAREER_HUWEI ->
                ItemList = [{18,1,1}];
            ?CAREER_MENGJIANG ->
                ItemList = [{17,1,1}];
            _ElSE ->
                ItemList = [{19,1,1}]
            end;
        426 ->
            RoleRec = mod_role:get_main_role_rec(PlayerID),
            case RoleRec#role.gd_careerID of
            ?CAREER_HUWEI ->
                ItemList = [{426,1,1}];
            ?CAREER_MENGJIANG ->
                ItemList = [{428,1,1}];
            _ElSE ->
                ItemList = [{430,1,1}]
            end;
        427 ->
            RoleRec = mod_role:get_main_role_rec(PlayerID),
            case RoleRec#role.gd_careerID of
            ?CAREER_HUWEI ->
                ItemList = [{427,1,1}];
            ?CAREER_MENGJIANG ->
                ItemList = [{429,1,1}];
            _ElSE ->
                ItemList = [{431,1,1}]
            end;
        92 ->
            RoleRec = mod_role:get_main_role_rec(PlayerID),
            case RoleRec#role.gd_careerID of
            ?CAREER_HUWEI ->
                ItemList = [{92,1,1}];
            ?CAREER_MENGJIANG ->
                ItemList = [{92,1,1}];
            _ElSE ->
                ItemList = [{102,1,1}]
            end;
        _Res ->
            ItemList =[{R#task_reward.value, 1, 1}]
    end,
    ?INFO(task,"createItems,PlayerID = ~w,Itemlist = ~w",[PlayerID,ItemList]),
    mod_items:createItems(PlayerID, ItemList, ?ITEM_FROM_TASK),
    ok;

%% 加经验
send_single_reward(PlayerID, #task_reward{type = ?TASK_REWARD_EXP} = R) ->
    MainRole = mod_role:get_main_role_rec(PlayerID),
    {_, RoleID} = MainRole#role.key,
    mod_role:add_exp(PlayerID, {RoleID, R#task_reward.value}, ?EXP_FROM_TASK),
    ok;

%% 加银币
send_single_reward(PlayerID, #task_reward{type = ?TASK_REWARD_MONEY} = R) ->
    mod_economy:add_silver(PlayerID, R#task_reward.value, ?SILVER_TASK),
    ok;

%% 加军功
send_single_reward(PlayerID,#task_reward{type = ?TASK_REWARD_MERIT} = R) ->
    mod_economy:add_popularity(PlayerID, R#task_reward.value, ?POPULARITY_FROM_TASK),
    ok;

send_single_reward(_PlayerID, place_holder) ->
    ok;
send_single_reward(_PlayerID, R) ->
    ?INFO(todo, "Add clause for reward: ~w", [R]),
    ok.

count_reward_item_num(RewardList) ->
    F = fun(R, Count) ->
        if
            is_record(R, task_reward) andalso R#task_reward.type =:= ?TASK_REWARD_ITEM ->
                Count + 1;
            true ->
                Count
        end
    end,
    lists:foldl(F, 0, RewardList).

check_req_level(PlayerID, TaskInfo) ->
    PlayerLevel = mod_role:get_main_level(PlayerID),
    PlayerLevel >= TaskInfo#task.req_level.

is_prev_completed(PlayerTask, TaskInfo) ->
    PrevID = TaskInfo#task.prev_id,
    case PrevID of
        0 ->
            true;
        _ ->
            lists:member(PrevID, PlayerTask#player_task.gd_completedList)
    end.

trigger_task_state_check(PlayerID, TipList, Context) ->
    TriggerFun = case Context of
        initializing ->
            fun(ReqType, ID) ->
                gen_callback_server:do_async(self(), {check_can_complete_tip, ReqType, ID})
            end;
        receiving ->
            fun(ReqType, ID) ->
                client_check_can_complete_tip(PlayerID, ReqType, ID)
            end
    end,

    F = fun(Tip) ->
        {ReqType, ID} = Tip#task_tip.key,
        case lists:member(ReqType, ?REQ_TYPES_DEPENDING_ON_PLAYER_STATE) of
            true ->
                TriggerFun(ReqType, ID);
            false ->
                void
        end
    end,

    lists:foreach(F, TipList).

update_task_state_helper(TaskState, {{{ReqType, ID, _Num, _PlayerID} = Req, TipUpdateFun} = Param, UpdateList, RecList}) ->
    case is_finished(TaskState, updating) of
        false ->
            TipList = TaskState#task_state.tips,
            ?INFO(task,"^^^^^^^^^^^^ReqType = ~w,ID = ~w,TipList = ~w",[ReqType, ID, TipList]),
            case is_receive_task({ReqType, ID}, TipList) of
                Tip when is_record(Tip, task_tip) ->
                    case TipUpdateFun(Tip, Req) of
                        {updated, NewTip} ->
                            NewTipList   = lists:keyreplace(Tip#task_tip.key, #task_tip.key, TipList, NewTip),
                            NewTaskState = TaskState#task_state{tips = NewTipList},
                            {Param, [NewTaskState | UpdateList], [NewTaskState | RecList]};
                        not_updated ->
                            {Param, UpdateList, [TaskState | RecList]}
                    end;

                false ->
                    {Param, UpdateList, [TaskState | RecList]}
            end;

        true ->
            {Param, UpdateList, [TaskState | RecList]}
    end.

%% 采集、打怪各样更新数据
update_tip_by_req(Tip, {_ReqType, _ID, Num, _PlayerID}) ->
    case Num of
        0 -> 
            not_updated;
        _ -> 
            FinishNum = max(Tip#task_tip.finish + Num, 0),
            {updated, Tip#task_tip{finish = FinishNum}}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                  接任务时根据玩家状态来确定已完成的数量，不一定从0开始                              %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 采集
update_tip_by_player_state(Tip, {20, ID, _Num, PlayerID}) ->
    RealNum = mod_items:getNumByItemID(PlayerID, ID),
    case RealNum of
        0 ->
            not_updated;
        _ ->
            FinishNum = max(RealNum, 0),
            {updated, Tip#task_tip{finish = FinishNum}}
    end;

%% 穿装备
update_tip_by_player_state(Tip, {3, ID, _Num, PlayerID}) ->
    RoleID = mod_account:get_main_role_id(PlayerID),
    ItemList = mod_items:getRoleItems(PlayerID,RoleID),
    case lists:keyfind(ID,#item.cfg_ItemID,ItemList) of
        false ->
            not_updated;
        _NotNull ->
            {updated,Tip#task_tip{finish = 1}}
    end;

%% 强化装备
update_tip_by_player_state(Tip, {24, ID, _Num, PlayerID}) ->
    RoleID = mod_account:get_main_role_id(PlayerID),
    ItemList = mod_items:getRoleItems(PlayerID,RoleID),
    case lists:keyfind(ID,#item.cfg_ItemID,ItemList) of
        false ->
            not_updated;
        Item ->
            {updated,Tip#task_tip{finish = Item#item.gd_IntensifyLevel}}
    end;

%% 神器
update_tip_by_player_state(Tip, {39, ID, _Num, PlayerID}) ->
    RoleID = mod_account:get_main_role_id(PlayerID),
    ItemList = mod_items:getRoleItems(PlayerID,RoleID),
    case lists:keyfind(ID,#item.cfg_ItemID,ItemList) of
        false ->
            not_updated;
        Item ->
            {updated,Tip#task_tip{finish = Item#item.gd_IntensifyLevel}}
    end;

update_tip_by_player_state(_Tip, {_ReqType, _ID, _Num, _PlayerID}) ->
    not_updated.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
purge_task_items(PlayerID, TaskState) ->
    F = fun(T) ->
        {ReqType, ID} = T#task_tip.key,
        case lists:member(ReqType, ?REQ_TYPES_NEED_ITEM_PURGING) of
            true ->
                mod_items:useNumByItemID(PlayerID, ID, T#task_tip.need);
            false ->
                void
        end
    end,
    lists:foreach(F, TaskState#task_state.tips).

check_received_tasks(ReceivedList) ->
    F = fun(TaskState) ->
        ID = TaskState#task_state.id,
        case get_task_info_quiet(ID) of
            none ->
                %% 1. 任务被删掉了
                gen_callback_server:do_async(self(), {give_up_task, ID});

            TaskInfo ->
                TipList = TaskState#task_state.tips,
                NewTipList = TaskInfo#task.tips,
                if
                    length(TipList) =/= length(NewTipList) ->
                        %% 2. tip数不一样了
                        gen_callback_server:do_async(self(), {give_up_task, ID});
                    true ->
                        case lists:any(fun(T) -> is_tip_modified(T, NewTipList) end, TipList) of
                            true ->
                                %% 3. 任意一条tip被删除或者和原来不一样了
                                gen_callback_server:do_async(self(), {give_up_task, ID});
                            false ->
                                void
                        end
                end
        end
    end,
    lists:foreach(F, ReceivedList).

is_tip_modified(T, NewTipList) ->
    case lists:keyfind(T#task_tip.key, #task_tip.key, NewTipList) of
        false ->
            true;
        NewT ->
            not is_same_tip(T, NewT)
    end.

is_same_tip(T1, T2) ->
    T1#task_tip.key =:= T2#task_tip.key andalso
    T1#task_tip.need =:= T2#task_tip.need.

gm_complete_helper(PlayerID, TaskID, OldCompleteList) ->
    case lists:member(TaskID, OldCompleteList) of
        false ->
            case get_task_info_quiet(TaskID) of
                none ->
                    OldCompleteList;
                TaskInfo ->
                    send_reward(PlayerID, TaskInfo#task.reward),
                    gm_complete_helper(PlayerID, TaskInfo#task.prev_id, lists:umerge([TaskID], OldCompleteList))
            end;

        true ->
            OldCompleteList
    end.

%% 自动完成某项任务
auto_complete_helper(PlayerID, TaskID) ->
    TaskInfo = data_task:get(TaskID),
        GoldCost = 20,
        case mod_economy:check_and_use_bind_gold(PlayerID,GoldCost,?GOLD_COMPLETE_DAILY_TASK) of
            true ->
                RewardList = 
                case is_cyclic_task(TaskInfo) of
                    false ->
                        TaskInfo#task.reward;
                    true ->
                        PlayerLevel = mod_role:get_main_level(PlayerID),
                        RecvCount = get_received_times(PlayerID, TaskInfo#task.type),
                        data_task:get_cyclic_task_reward(TaskInfo#task.type, PlayerLevel, RecvCount)
                end,
                send_reward(PlayerID,RewardList),
                ok;
            false ->
                {error,?ERR_NOT_ENOUGH_GOLD}
        end.


is_cyclic_task(TaskInfo) ->
    TaskInfo#task.type >= ?TASK_TYPE_CYCLIC_MIN andalso
    TaskInfo#task.type =< ?TASK_TYPE_CYCLIC_MAX.

cyclic_type_to_counter_type(CyclicType) ->
    CyclicType - ?TASK_TYPE_CYCLIC_MIN + ?COUNTER_CYCLIC_TASK_MIN.

is_cur_cyclic_task(PlayerTask, TaskInfo) ->
    lists:member(TaskInfo#task.id, PlayerTask#player_task.gd_curCyclicList).

can_receive_cyclic(PlayerID, TaskInfo) ->
    CounterType = cyclic_type_to_counter_type(TaskInfo#task.type),
    %% TODO: 把10移到data文件里去
    mod_counter:get_counter(PlayerID, CounterType) < 10.

get_received_times(PlayerID, TaskType) ->
    CounterType = cyclic_type_to_counter_type(TaskType),
    mod_counter:get_counter(PlayerID, CounterType).

update_cyclic_counter(PlayerID, TaskType) ->
    CounterType = cyclic_type_to_counter_type(TaskType),
    mod_counter:add_counter(PlayerID, CounterType).

update_cyclic_counter(PlayerID, TaskType, Times) ->
    CounterType = cyclic_type_to_counter_type(TaskType),
    mod_counter:add_counter(PlayerID, CounterType, Times).

gen_new_cyclic_task(CyclicType, PlayerLevel) ->
    RandList = get_cyclic_task_list_quiet(CyclicType, PlayerLevel),
    lists:nth(util:rand(1, length(RandList)), RandList).

get_received_cyclic_list(PlayerTask) ->
    ReceivedCyclicList = lists:filter(
        fun(S) ->
            T = data_task:get(S#task_state.id),
            is_cyclic_task(T)
        end,
        PlayerTask#player_task.gd_receivedList
    ),
    [S#task_state.id || S <- ReceivedCyclicList].

get_full_cyclic_list(PlayerTask) ->
    RecList = get_received_cyclic_list(PlayerTask),
    lists:umerge(lists:usort(RecList), PlayerTask#player_task.gd_curCyclicList).

get_task_info_quiet(TaskID) ->
    try 
        data_task:get(TaskID)
    catch error: function_clause ->
        none
    end.

get_cyclic_task_list_quiet(Type, Level) ->
    try
        data_task:get_cyclic_task_list(Type, Level)
    catch error: function_clause ->
        [0]
    end.

%% 取得帮派循环任务余下次数的奖励
getGankReward(PlayerID,GankRemTimes) ->
    PlayerLevel = mod_role:get_main_level(PlayerID),
    sumReward(?TASK_TYPE_CYCLIC_GANK,PlayerLevel,GankRemTimes).

%% 取得师门循环任务余下次数的奖励
getSchoolReward(PlayerID,SchoolRemTimes) ->
    PlayerLevel = mod_role:get_main_level(PlayerID),
    sumReward(?TASK_TYPE_CYCLIC_SCHOOL,PlayerLevel,SchoolRemTimes).

%% 汇总某类循环任务剩下的奖励
sumReward(_Type,_PlayerLevel,0) ->
    [];
sumReward(Type,PlayerLevel,RemTimes) ->
    case PlayerLevel >=30 of
        true ->
            RewardThis = data_task:get_cyclic_task_reward(Type, PlayerLevel, 11-RemTimes),
            RewardThis ++ sumReward(Type,PlayerLevel,RemTimes-1);
        false ->
            []
    end.


%% 从奖励列表中汇总出客户端需要的信息
rewardListToClientInfo(RewardList) ->
    Fun = fun(Reward,[{?TASK_REWARD_EXP,Value1},{?TASK_REWARD_SCHOOL_POINT,Value2},{?TASK_REWARD_GANG_POINT,Value3},{?TASK_REWARD_MONEY,Value4}]) ->
        if
            Reward#task_reward.type =:= ?TASK_REWARD_EXP ->
                [{?TASK_REWARD_EXP,Value1+Reward#task_reward.value},{?TASK_REWARD_SCHOOL_POINT,Value2},{?TASK_REWARD_GANG_POINT,Value3},{?TASK_REWARD_MONEY,Value4}];
            Reward#task_reward.type =:= ?TASK_REWARD_SCHOOL_POINT ->
                [{?TASK_REWARD_EXP,Value1},{?TASK_REWARD_SCHOOL_POINT,Value2+Reward#task_reward.value},{?TASK_REWARD_GANG_POINT,Value3},{?TASK_REWARD_MONEY,Value4}];
            Reward#task_reward.type =:= ?TASK_REWARD_GANG_POINT ->
                [{?TASK_REWARD_EXP,Value1},{?TASK_REWARD_SCHOOL_POINT,Value2},{?TASK_REWARD_GANG_POINT,Value3+Reward#task_reward.value},{?TASK_REWARD_MONEY,Value4}];
            Reward#task_reward.type =:= ?TASK_REWARD_MONEY ->
                [{?TASK_REWARD_EXP,Value1},{?TASK_REWARD_SCHOOL_POINT,Value2},{?TASK_REWARD_GANG_POINT,Value3},{?TASK_REWARD_MONEY,Value4+Reward#task_reward.value}];
            true ->
                [{?TASK_REWARD_EXP,Value1},{?TASK_REWARD_SCHOOL_POINT,Value2},{?TASK_REWARD_GANG_POINT,Value3},{?TASK_REWARD_MONEY,Value4}]
            end
        end,
    lists:foldl(Fun,[{?TASK_REWARD_EXP,0},{?TASK_REWARD_SCHOOL_POINT,0},{?TASK_REWARD_GANG_POINT,0},{?TASK_REWARD_MONEY,0}],RewardList).

take_out_receive_task_by_type(PlayerID,Type)->
    PlayerTask = get_player_task(PlayerID),
    NewReceivedList = lists:filter(
        fun(S) ->
            T = data_task:get(S#task_state.id),
            T#task.type =/= Type
        end,
        PlayerTask#player_task.gd_receivedList
    ),
    NewCyclicList = lists:filter(
        fun(S) ->
            T = data_task:get(S),
            T#task.type =/= Type
        end,
        PlayerTask#player_task.gd_curCyclicList
    ),
    gen_cache:update_element(?TASK_CACHE_REF, PlayerID, 
    [{#player_task.gd_receivedList,  NewReceivedList},
     {#player_task.gd_curCyclicList, NewCyclicList}]).

%% 处理怪物列表
combine(MonList) ->
    combine_helper(MonList,[]).

combine_helper([],NewList) -> 
    NewList;
combine_helper([MonFirst|Res],NewList) ->
    {MonID, _} = MonFirst,
    case lists:keyfind(MonID,1,NewList) of
        false ->
            combine_helper(Res,NewList++[{MonID,1}]);
        {_MonID,Num} ->
            NewList1 = lists:keyreplace(MonID,1,NewList,{MonID,Num+1}),
            combine_helper(Res,NewList1)
    end.

is_receive_task({_ReqType, _ID},[]) ->
    false;
is_receive_task({ReqType, ID}, [First|TipList]) ->
    {ReqType1,IDList} = First#task_tip.key,
    case ReqType =:= ReqType1 andalso lists:member(ID,IDList) of
        true ->
            First;
        false ->
            is_receive_task({ReqType, ID},TipList)
    end.