-module(pt_17).

-include("common.hrl").
-include("task.hrl").

-export([write/2, read/2]).

%% 接受任务
read(17000, <<Type:8, TaskID:16>>) ->
    {ok, {Type, TaskID}};

%% 提交任务
read(17001, <<Type:8, TaskID:16>>) ->
    {ok, {Type, TaskID}};

%% 放弃任务
read(17002, <<Type:8, TaskID:16>>) ->
    {ok, {Type, TaskID}};

%% 客户端请求全部任务信息
read(17004, _NoUse) ->
    {ok, _NoUse};

read(17008,<<TaskID:16>>) ->
    {ok,TaskID};

read(17021, _NoUse) ->
    {ok, _NoUse};

%% 请求自动完成循环任务的消耗以及奖励（17022）C->S
read(17022,_NoUse) ->
    {ok, _NoUse};

% 请求自动完成循环任务（17023）C->S
% Int8: 是否自动完成帮派任务  1是 0否
% Int8: 是否自动完成师门任务
read(17023, <<Flag1:8,Flag2:8>>) ->
    {ok, {Flag1,Flag2}}.


%% 压任务接收成功包
write(17000, TaskID)->
    {ok, pt:pack(17000, <<TaskID:16>>)};

%% 压任务提交成功包
write(17001, TaskID)->
    {ok, pt:pack(17001, <<TaskID:16>>)};

%% 压放弃任务成功包
write(17002, TaskID)->
    {ok, pt:pack(17002, <<TaskID:16>>)};

%% 压完成任务数据
write(17006, CompList) ->
    F = fun(TaskID, {AccBin, CurBitSize}) ->
        PaddingBitSize = TaskID - CurBitSize - 1,
        {<<AccBin/bitstring, 0:PaddingBitSize, 1:1>>, TaskID}
    end,

    Sorted = lists:sort(CompList),
    {CompBin, CurBitSize} = lists:foldl(F, {<<>>, 0}, Sorted),

    Payload = case CurBitSize < 2048 of
        true ->
            <<CompBin/bitstring, 0:(2048 - CurBitSize)>>;
        false ->
            CompBin
    end,
    Len = size(Payload),
    {ok, pt:pack(17006, <<Len:16, Payload/binary>>)};

%% 压已接任务数据
write(17007, RecList)->
    Bin = get_task_rec_bin(RecList),
    {ok, pt:pack(17007, <<Bin/binary>>)};

%% 压任务更新数据
write(17005, UpdateList)->
     Bin = get_task_rec_bin(UpdateList),
     {ok, pt:pack(17005, <<Bin/binary>>)};

%% 可接循环任务
write(17021, CyclicInfoList) ->
    F = fun({TaskID, CanRec, RemTimes}) ->
        <<TaskID:16, CanRec:8, RemTimes:8>>
    end,
    Bin = list_to_binary([<<(length(CyclicInfoList)):16>> | lists:map(F, CyclicInfoList)]),
    {ok, pt:pack(17021, Bin)};

% 返回自动完成循环任务需要的消耗和奖励（17022）S->C
% int16:  自动完成帮派任务需要消耗的元宝  元宝数为0代表该循环任务已完成
% int32:  自动完成帮派任务获得的帮会贡献
% int32:  自动完成帮派任务获得的银币
% int16:  自动完成师门任务需要消耗的元宝  
% int32:  自动完成师门任务获得的经验
% int32:  自动完成师门任务获得的银币
write(17022,{GoldCost1,Gongxian,SilverGet1,GoldCost2,Exp,SilverGet2}) ->
    {ok,pt:pack(17022,<<GoldCost1:16,Gongxian:32,SilverGet1:32,GoldCost2:16,Exp:32,SilverGet2:32>>)};


%% 自动完成循环任务返回（17023）S->C
%% Int8: 1:全部循环任务已完成  2:帮派任务已完成  3:师门任务已完成
write(17023,Type) ->
    {ok,pt:pack(17023,<<Type:8>>)}.

%% private functions

%% 组装已接任务包
get_task_rec_bin(RecList) ->
    Len = length(RecList),
    Fun = fun(TaskState, AccBin) -> 
        TaskID = TaskState#task_state.id,
        R1 = get_task_tips_bin(TaskState#task_state.tips),
        <<AccBin/binary, TaskID:16, R1/binary>>
    end,
    lists:foldl(Fun, <<Len:16>>, RecList).

get_task_tips_bin(Tips) ->
    Len = length(Tips),
    Fun = fun(Tip, AccBin) -> 
        {_, [ID|_Res]} = Tip#task_tip.key,
        Finish = Tip#task_tip.finish,
        <<AccBin/binary, ID:32, Finish:16>>
    end,    
    lists:foldl(Fun, <<Len:16>>, Tips).

