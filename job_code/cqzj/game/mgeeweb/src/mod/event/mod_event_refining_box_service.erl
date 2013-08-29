%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 天工炉开箱子功能后台管理
%%% @end
%%% Created :  7 Jun 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_event_refining_box_service).

-include("mgeeweb.hrl").

%% op_code 0:查询成功 1:查询失败 2:设置成功 3:设置失败 4:重置成功 5:重置失败
-record(r_event_refining_box,{is_box_open,op_code = 0}).

-define(RFC4627_FROM_RECORD(RName, R),
    rfc4627:from_record(R, RName, record_info(fields, RName))).

-define(RFC4627_TO_RECORD(RName, R),
    rfc4627:to_record(R, #RName{}, record_info(fields, RName))).
%% API
-export([
         handle/3
        ]).

%%%===================================================================
%%% API
%%%===================================================================

handle("/list" ++ _RemainPath,Req, DocRoot) ->
	do_list(Req, DocRoot);
handle("/set" ++ _RemainPath,Req, DocRoot) ->
    do_set(Req, DocRoot);
handle("/reset" ++ _RemainPath,Req, DocRoot) ->
    do_reset(Req, DocRoot);
handle(RemainPath, Req, DocRoot) ->
    ?ERROR_MSG("~ts,RemainPath=~w, Req=~w, DocRoot=~w",["无法处理此消息", RemainPath, Req, DocRoot]),
    Req:not_found().

do_list(Req, _DocRoot) ->
    Result = get_box_base_info(0),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

get_box_base_info(OpCode) ->
    [IsBoxOpen] = common_config_dyn:find(get_config_name(),is_box_open),
    NIsBoxOpen = 
        case IsBoxOpen of
            true ->
                1;
            _ ->
                0
        end,
    Record = #r_event_refining_box{is_box_open = NIsBoxOpen,op_code = OpCode},
    record_to_json(Record).


do_set(Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    IsBoxOpen = proplists:get_value("isBoxOpen", QueryString),
    NIsBoxOpen = common_tool:to_integer(IsBoxOpen),
    OpCode = 
        case get_refining_box_config(set,NIsBoxOpen) of
            {ok,ModuleName,ModuleDataList} ->
                mgeeweb_tool:call_nodes(common_config_dyn,load_gen_src,[ModuleName,ModuleDataList,ModuleDataList]),
                catch mod_treasbox:handle({box_fun_config_change}),
                2;
            _ ->
                3
        end,
    Result = get_box_base_info(OpCode),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).
do_reset(Req, _DocRoot) ->
    OpCode = 
        case get_refining_box_config(reset,1) of
            {ok,ModuleName,ModuleDataList} ->
                mgeeweb_tool:call_nodes(common_config_dyn,load_gen_src,[ModuleName,ModuleDataList,ModuleDataList]),
                catch mod_treasbox:handle({box_fun_config_change}),
                4;
            _ ->
                5
        end,
    Result = get_box_base_info(OpCode),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

get_refining_box_config(OpType,NIsBoxOpen) ->
    IsBoxOpen = if NIsBoxOpen =:= 1 -> true; true -> false end,
    Name = get_config_name(),
    NameFilePath = common_config:get_world_config_file_path(Name),
    {ok,NameDataList} = file:consult(NameFilePath),
    NameDataList2 = 
        case OpType of
            set ->
                lists:foldl(
                  fun({Key,Value},Acc) ->
                          case Key of
                              is_box_open ->
                                  [{Key,IsBoxOpen}|Acc];
                              _ ->
                                  [{Key,Value}|Acc]
                          end
                  end,[],NameDataList);
            _ ->
                NameDataList
        end,
    {ok,Name,NameDataList2}.

%% 将单个记录结果转换成jsno格式数据
%% {r_xxx_xxx,X,Y,Z,...} -> [{"X":1,"Y":"xxx",...}] or []
record_to_json(Record) ->
    {obj,Json} = ?RFC4627_FROM_RECORD(r_event_refining_box,Record),
    Length = erlang:length(Json),
    {JsonStr,_} = 
        lists:foldl(fun({Key,Value},Acc) ->
                            {AccStr,Index} = Acc,
                            Value2 = value_to_json(Value),
                            AccStr2 = 
                                if (Index + 1) < Length ->
                                        lists:concat([AccStr,"\"",Key,"\"",":",Value2,","]);
                                   true ->
                                        lists:concat([AccStr,"\"",Key,"\"",":",Value2])
                                end,
                            {AccStr2,Index + 1}
                    end,{"",0},Json),
    if JsonStr =/= "" ->
            lists:concat(["{",JsonStr,"}"]);
       true ->
            lists:concat(["{",JsonStr,"}"])
    end.

value_to_json(Value)when erlang:is_integer(Value) ->
    lists:concat([Value]);
value_to_json(Value)when erlang:is_number(Value) ->
    lists:concat([Value]);
value_to_json(Value) ->
    lists:concat(["\"",common_tool:to_list(Value),"\""]).

get_config_name() ->
    case common_config:get_opened_days() > 3 of
        true ->
            treasbox;
        false ->
            treasbox_3day
    end.
