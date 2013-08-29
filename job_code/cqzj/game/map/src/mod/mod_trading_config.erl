%%%--------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 商贸活动配置模块
%%% @end
%%% Created : 16 Dec 2010 by  <caochuncheng>
%%%--------------------------------------------------------------------
-module(mod_trading_config).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").
-include("trading.hrl").

-define(DEFINE_TRADING_CONFIG(Name),{Name,codegen_name(Name)}).
-define(TRADING_CONFIG_LIST,[
                             ?DEFINE_TRADING_CONFIG(?TRADING_GOODS_CONFIG)
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
%% trading_goods.config -> trading_goods_config_codegen.beam
init() ->
    try
        do_load_config(?TRADING_CONFIG_LIST)
    catch
        Error:Reason ->
            ?ERROR_MSG("~ts,Error=~w,Reason=~w",["初始化商贸活动配置数据出错",Error,Reason]),
            erlang:throw({Error,Reason})
    end,
    ?INFO_MSG("~ts",["初始化商贸活动配置数据成功"]),
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
                do_load_config(?TRADING_CONFIG_LIST);
            ?TRADING_GOODS_CONFIG ->
                do_load_config([?DEFINE_TRADING_CONFIG(?TRADING_GOODS_CONFIG)]);
            _ ->
                ?ERROR_MSG("~ts,ConfigName=~w",["热更新商贸活动配置数据参数出错",ConfigName]),
                ignore
        end
    catch
        Error:Reason ->
            ?ERROR_MSG("~ts,Error=~w,Reason=~w",["热更新商贸活动配置数据出错",Error,Reason]),
            erlang:throw({Error,Reason})
    end,
    ?DEBUG("~ts,ConfigName=~w",["热更新商贸活动配置数据成功",ConfigName]),
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
