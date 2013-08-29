%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 数据库更新
%%%
%%% Created : 2010-09-17
%%% -------------------------------------------------------------------
-module(mgeed_transform).

-define(BACKUP_PATH, "/data/backup/ming2/game_db/").
-export([start/3]).

%% 开始
start(VSModDIR, VS, EbinPath) -> 
    code:add_path(EbinPath),
    {ok, VSList} = file:list_dir(VSModDIR),
    backup_db(VS),
    try
        do_transform(VSList)
    catch
        _:Error ->
            io:format("发生了错误 :~n~w", [Error])
    end,
    ok.

%% 执行更新指令
do_transform([]) -> ok ;
do_transform([VSMod|VSList]) ->
    case string:substr(VSMod, 1, 5) of
        "tstb_" ->
            Mod = erlang:list_to_atom(filename:basename(VSMod, ".erl")),
            do_alter(Mod, Mod:get_alter_tables()),
            do_del(Mod, Mod:get_del_tables()),
            do_transform(VSList);
        _ ->
            do_transform(VSList)
    end.

do_alter(_Mod, []) -> ok ;
do_alter(Mod, [Table|UpdateList]) ->
    io:format("~w", [Table]),
    {TableName, NewAttrList, NewRecordName} = Table,
    Fun = fun(Data) -> Mod:alter_table(TableName, Data) end,
    if
        NewRecordName =:= ignore ->
            {atomic, _} = db:transform_table(TableName, Fun, NewAttrList);
        true ->
            {atomic, _} = db:transform_table(TableName, Fun, NewAttrList, NewRecordName)
    end,
    do_alter(Mod, UpdateList).

do_del(_Mod, []) -> ok ;
do_del(Mod, [Table|DELList]) ->
    {TableName, AttrList} = Table,
    Fun = fun(Data) -> Mod:del_table(TableName, Data), Data  end,
    {atomic, _} = db:transform_table(TableName, Fun, AttrList),
    {atomic, _} = db:delete_table(TableName),
    do_del(Mod, DELList).

%% 备份数据库
backup_db(VS) ->
    filelib:ensure_dir(?BACKUP_PATH),
    PathName = get_backup_path(?BACKUP_PATH, VS),
    ok = db:backup(PathName),
    PathName. 

%% 回滚数据
%% restore_db(RemoteIP, Path) ->
%%     DBNode = get_db_node(RemoteIP),
%%     {atomic, _} = rpc:call(DBNode, mnesia, restore, [Path, [{default_op, clear_tables}]]).

%% 获取备份路径
get_backup_path(Path, VS) ->
    {{Year, Month, Day}, {H, I, S}} = calendar:local_time(),
    PathName =  [Path, 
                 "mnesia.",
                 "vs.", VS, ".time.",
                 Year, ".",
                 Month, ".",
                 Day, ".", 
                 H, ".",
                 I, ".",
                 S, ".bk"],
    lists:concat(PathName).
