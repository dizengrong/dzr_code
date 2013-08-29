%%%--------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 炼制功能配置文件接口模块
%%% 提供炼制功能读取配置文件内容接口
%%% 提供热更新炼制功能配置功能接口
%%% @end
%%% Created : 16 Dec 2010 by  <>
%%%--------------------------------------------------------------------
-module(mod_forging_config).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").
-include("refining.hrl").

-define(DEFINE_FORGING_CONFIG(Name),{Name,codegen_name(Name)}).
-define(FORGING_CONFIG_LIST,[
                             ?DEFINE_FORGING_CONFIG(?REFINING_FORGING_CUSTOM),
                             ?DEFINE_FORGING_CONFIG(?REFINING_FORGING_FORMULA)
                            ]).

%% API
-export([
         %% 初始化
         init/0,
         %% 更新
         update/1,
         %% 查找
         find/2,
         %% 返回结果
         get/1
        ]).

%% ====================================================================
%% API Functions
%% ====================================================================
%% 初始化函数，处理config转成beam
%% 处理的配置文件有
%% forging_custom.config -> forging_custom_config_codegen.beam
%% forging_formula.config -> forging_formula_config_codegen.beam
init() ->
    try
        do_load_config(?FORGING_CONFIG_LIST)
    catch
        Error:Reason ->
            ?ERROR_MSG("~ts,Error=~w,Reason=~w",["初始化天工炉炼制配置数据出错",Error,Reason]),
            erlang:throw({Error,Reason})
    end,
    ?INFO_MSG("~ts",["初始化天工炉炼制配置数据成功"]),
    ok.

do_load_config(ForgingConfigList) ->
    lists:foreach(
      fun({Name,ModuleName}) ->
              NameFilePath = common_config:get_map_config_file_path(Name),
              {ok,NameDataList} = file:consult(NameFilePath),
              ErlSrc = gen_src(ModuleName,NameDataList),
              {Mod, Code} = dynamic_compile:from_string(ErlSrc),
              code:load_binary(Mod, ModuleName ++ ".erl", Code)
      end,ForgingConfigList).

%% 更新炼制配置文件
%% ConfigName 配置文件名称
%% 如果更新全部，即使用 all
update(ConfigName) ->
    try
        case ConfigName of 
            all ->
                do_load_config(?FORGING_CONFIG_LIST);
            ?REFINING_FORGING_CUSTOM ->
                do_load_config([?DEFINE_FORGING_CONFIG(?REFINING_FORGING_CUSTOM)]);
            ?REFINING_FORGING_FORMULA ->
                do_load_config([?DEFINE_FORGING_CONFIG(?REFINING_FORGING_FORMULA)]);
            _ ->
                ?ERROR_MSG("~ts,ConfigName=~w",["热更新天工炉炼制配置数据参数出错",ConfigName]),
                ignore
        end
    catch
        Error:Reason ->
            ?ERROR_MSG("~ts,Error=~w,Reason=~w",["热更新天工炉炼制配置数据出错",Error,Reason]),
            erlang:throw({Error,Reason})
    end,
    ?INFO_MSG("~ts,ConfigName=~w",["热更新天工炉炼制配置数据成功",ConfigName]),
    ok.
        
             
%% 查找值
%% 参数
%% ConfigName 配置文件名称
%% Key 要查询的Key
%% 返回结果 tuple
find(ConfigName,Key) ->
    ModuleName = common_tool:list_to_atom(codegen_name(ConfigName)),
    ModuleName:find_by_key(Key).
%% 返回配置文件所有的数据
%% ConfigName 配置文件名称
%% 返回结果 []
get(ConfigName) ->
    ModuleName = common_tool:list_to_atom(codegen_name(ConfigName)),
    ModuleName:get().

%% 动态模块名称
codegen_name(Name)->
    lists:concat([Name,"_config_codegen"]).

%% 根据配置文件成生erl文件
%%　参数
%% ModuleName 模块名称
%% DataList 数据列表
%%　返回 erl 原文件
gen_src(ModuleName,DataList) ->
    KeyValues = [begin K = element(2,Rec), {K,Rec} end 
                 || Rec <- DataList],
    FindCases = 
        lists:foldl(
          fun({Key, Value}, C) ->
                  lists:concat(["     ", Key, " -> ", lists:flatten(io_lib:format("~w", [Value])) , ";\n", C])
          end, "", KeyValues),
    GetFun = lists:flatten(io_lib:format("~w", [DataList])),
"
-module(" ++ common_tool:to_list(ModuleName) ++ ").
-export([get/0, find_by_key/1]).
get()-> 
" ++ GetFun ++ "
.
find_by_key(Key) ->
    case Key of 
        " ++ FindCases ++ "
        _ -> undefined
    end.
".

