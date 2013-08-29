%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     common_config_code,用于动态生成代码
%%% @end
%%% Created : 2010-12-2
%%%-------------------------------------------------------------------
-module(common_mission_code).


%% API
-export([gen_mission_beam/0]).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mission.hrl").


%% ====================================================================
%% API Functions
%% ====================================================================


%% --------------------------------------------------------------------
%% 生成任务数据的erlang bin object
%% --------------------------------------------------------------------
gen_mission_beam() ->
    
    MissionDataDir = common_config:get_mission_file_path(),
    MissionSettingList = common_config:get_mission_setting(),
    code_create_setting_module(MissionSettingList, ?MODULE_MISSION_DATA_SETTING),
    
    FileListFun = 
        fun(FileName, {NoGroupKeyList, GroupKeyList, MissionList}) ->
                %%?ERROR_MSG("-----Load mission data-----~p", [FileName]),
                case filename:extension(FileName) of
                    ".detail" ->%%任务详细信息
                        {ok, MissionList2} = file:consult(MissionDataDir ++ FileName),
                        {NoGroupKeyList, GroupKeyList, MissionList2++MissionList};
                    ".nogroup_keyto" ->%%没分组的key==>任务ID
                        {ok, NoGroupKeyList2} = file:consult(MissionDataDir ++ FileName),
                        NoGroupKeyList3 = code_filter_list(NoGroupKeyList, NoGroupKeyList2),
                        {NoGroupKeyList3, GroupKeyList, MissionList};
                    ".group_keyto" ->%%有分组的key==>分组ID
                        {ok, GroupKeyList2} = file:consult(MissionDataDir ++ FileName),
                        GroupKeyList3 = code_filter_list(GroupKeyList, GroupKeyList2),
                        {NoGroupKeyList, GroupKeyList3, MissionList};
                    _ ->
                        {NoGroupKeyList, GroupKeyList, MissionList}
                end
        end,

    case file:list_dir(MissionDataDir) of
        {ok, FileList} ->
            {NoGroupKeyList, GroupKeyList, MissionList} = lists:foldl(FileListFun, {[], [], []}, FileList),
            %%没有分组的任务 一个key对应多个任务
            {module, ModuleNameKeyNoGroup} = code_create_key_module(NoGroupKeyList, ?MODULE_MISSION_DATA_KEY_NO_GROUP),
            %%分组的任务 一个key对应多个组 获取任务时实际是从每个组里随机取一条
            {module, ModuleNameKeyGroup} = code_create_key_module(GroupKeyList, ?MODULE_MISSION_DATA_KEY_GROUP),
            {module, ModuleNameDetail} = code_create_detail_module(MissionList, ?MODULE_MISSION_DATA_DETAIL),
            {ModuleNameKeyNoGroup, ModuleNameKeyGroup, ModuleNameDetail};
        _ ->
            exit(killed)
    end.
  
%% --------------------------------------------------------------------
%% 生成任务详细信息的查询模块
%% --------------------------------------------------------------------
code_create_detail_module(MissionList, ModuleNameTmp) ->
    ModuleName = erlang:atom_to_list(ModuleNameTmp),
    {CodeSrc, GroupList} =
    lists:foldl(fun(MissionBaseInfo, {CodeSrc2, GroupList2}) ->
       MissionID = MissionBaseInfo#mission_base_info.id,
       SmallGroup = MissionBaseInfo#mission_base_info.small_group,
       if
            SmallGroup =/= 0 ->
                GroupList3 = code_filter_list(GroupList2, [{SmallGroup, MissionID}]);
            true ->
                GroupList3 = GroupList2
       end,
       CodeSrc3 = CodeSrc2 ++ io_lib:format("~nget(~w) -> ~w;", [MissionID, MissionBaseInfo]),
       {CodeSrc3, GroupList3}
    end, {"", []}, MissionList), 
    
    {CodeSrc4, CodeSrc5} =
    lists:foldl(fun({SmallGroup, MissionIDList}, {CodeSrc6, CodeSrc7}) ->
                        
       CodeSrc8 = CodeSrc6 ++ io_lib:format(
         "~nget_group(~w) -> lists:map(fun(MissionID) -> "++ModuleName++":get(MissionID) end, ~w);",
         [SmallGroup, MissionIDList]),
       
       CodeSrc9 = CodeSrc7 ++ io_lib:format("~nget_group_random_one(~w) ->~n
            List = ~w, ~n
            random:seed(erlang:now()), ~n
            N = random:uniform(erlang:length(List)), ~n
            lists:nth(N, List);",
            %%"++ModuleName++":get(lists:nth(N, List));",
         [SmallGroup, MissionIDList]),
        {CodeSrc8, CodeSrc9}
    end, {"", ""}, GroupList),  
    
    CodeSrc10 = io_lib:format(?MISSION_DATA_DETAIL_HEADER(ModuleName), [CodeSrc, CodeSrc4, CodeSrc5]),
    
	Src = lists:flatten(CodeSrc10),
	file:write_file(lists:concat(["../config/src/", ModuleName, ".erl"]), Src, [write, binary, {encoding, utf8}]),
	{module, ModuleName}.
 
%% --------------------------------------------------------------------
%% 生成任务key查询一级KEY的代码
%% -------------------------------------------------------------------- 
code_create_key_module(KeyList, ModuleNameTmp) -> 
    ModuleName = erlang:atom_to_list(ModuleNameTmp),
    CodeSrc =
    lists:foldl(fun({Key, IDList}, CodeSrc2) -> 
        CodeSrc2 ++ io_lib:format("~nget(~w) -> ~w;", [Key, IDList])
    end, "", KeyList),
    CodeSrc3 = io_lib:format(?MISSION_DATA_KEY_HEADER(ModuleName), [CodeSrc]),
	
	Src = lists:flatten(CodeSrc3),
	file:write_file(lists:concat(["../config/src/", ModuleName, ".erl"]), Src, [write, binary, {encoding, utf8}]),
	{module, ModuleName}.

%% --------------------------------------------------------------------
%% 生成任务配置代码
%% -------------------------------------------------------------------- 
code_create_setting_module(SettingList, ModuleNameTmp) ->
    ModuleName = erlang:atom_to_list(ModuleNameTmp),
    CodeSrc =
    lists:foldl(fun({Key, Data}, CodeSrc2) -> 
        CodeSrc2 ++ io_lib:format("~nget(~w) -> ~w;", [Key, Data])
    end, "", SettingList),
    CodeSrc3 = io_lib:format(?MISSION_DATA_KEY_HEADER(ModuleName), [CodeSrc]),
	
	Src = lists:flatten(CodeSrc3),
	file:write_file(lists:concat(["../config/src/", ModuleName, ".erl"]), Src, [write, binary, {encoding, utf8}]),
	{module, ModuleName}.
    

%% --------------------------------------------------------------------
%% 因为任务数据是分多个文件的 所以读取到以后要用这个函数做下合并
%% 将相同key的任务ID或者分组ID归档即相同KEY的放进同一个列表里
%% -------------------------------------------------------------------- 
code_filter_list(CurrentKeyList, KeyList) ->
    lists:foldl(fun({Key, ID}, Result) ->
        case lists:keyfind(Key, 1, Result) of
            false ->
                [{Key, [ID]}|Result];
            {Key, List} ->
                ResultUnique = lists:keydelete(Key, 1, Result),
                UniqueList = lists:delete(ID, List),
                [{Key, [ID|UniqueList]}|ResultUnique]
        end
    end, CurrentKeyList, KeyList).
