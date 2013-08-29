-module(pp_task).

-export([handle/3]).

-include("common.hrl").
%% -include("gen_callback_server.hrl").
%% -include("task.hrl").


 %% 接受
handle(17000, PlayerID, {_Type, TaskID}) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {receive_task, PS, TaskID},
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17000)
        );

%% 提交
handle(17001, PlayerID, {_Type, TaskID}) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {complete_task, PS, TaskID},
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17001)
        );
    
%% 放弃
handle(17002, PlayerID, {_Type, TaskID})->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {give_up_task, TaskID},
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17002)
        );
        
%% 请求获取所有任务数据(包括已完成/已接受) 分两个协议发
handle(17004, PlayerID, _NoUse) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            get_completed_list,
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17006)
        ),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            get_received_list,
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17007)
        );

%% 请求自动完成某一任务
handle(17008,PlayerID,TaskID) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            {auto_complete_task, TaskID},
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17001)
        );


%% 请求循环任务信息
handle(17021, PlayerID, _NoUse) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_sync(PS#player_status.task_pid, activate_cyclic_task),
    mod_task:client_get_current_cyclic_task(PlayerID);

%% 自动完成循环任务信息请求
handle(17022,PlayerID, _NoUse) ->
    PS = mod_player:get_player_status(PlayerID),
    gen_callback_server:do_async(
            PS#player_status.task_pid,
            auto_complete_info,
            ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17022)
        );

handle(17023,PlayerID,{Flag1,Flag2}) ->
    PS = mod_player:get_player_status(PlayerID),
    case Flag1 =:= 1 of
        true ->
            gen_callback_server:do_async(
                PS#player_status.task_pid,
                auto_complete_gank_cyclic_task,
                ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17023)
            );
        false ->
            void
    end,
    case Flag2 =:= 1 of
        true ->
            gen_callback_server:do_async(
                PS#player_status.task_pid,
                auto_complete_school_cyclic_task,
                ?CLIENT_REPLY_CB(PS#player_status.send_pid, 17023)
            );
        false ->
            void
    end.



