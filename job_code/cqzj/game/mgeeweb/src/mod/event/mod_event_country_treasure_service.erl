%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 大明宝藏副本事件处理
%%% @end
%%% Created : 12 Mar 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_event_country_treasure_service).

-include("mgeeweb.hrl").

%% op_code 0:查询成功 1:查询失败 2:开启成功 3:开启失败 4:重置成功 5:重置失败 6:上次宝藏还未结束，不可重置配置
-record(r_event_country_treasure,{normal_open_time = "",op_code = 0,is_open = false}).

-define(RFC4627_FROM_RECORD(RName, R),
    rfc4627:from_record(R, RName, record_info(fields, RName))).

-define(RFC4627_TO_RECORD(RName, R),
    rfc4627:to_record(R, #RName{}, record_info(fields, RName))).
%% API
-export([
         handle/3
        ]).

handle("/list" ++ _RemainPath,Req, DocRoot) ->
    do_list(Req, DocRoot);
handle("/start" ++ _RemainPath,Req, DocRoot) ->
    do_start(Req, DocRoot);
handle("/reset" ++ _RemainPath,Req, DocRoot) ->
    do_reset(Req, DocRoot);
handle(RemainPath, Req, DocRoot) ->
    ?ERROR_MSG("~ts,RemainPath=~w, Req=~w, DocRoot=~w",["无法处理此消息", RemainPath, Req, DocRoot]),
    Req:not_found().

do_list(Req, _DocRoot) ->
    Result = get_ct_base_info(0),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

get_ct_base_info(OpCode) ->
    [OpenTimesList] = common_config_dyn:find(country_treasure,open_times),
    [IsOpenCountryTreasure] = common_config_dyn:find(country_treasure,is_open_country_treasure),
    OpenTimesList2 = 
        lists:sort(fun({WeekA,_},{WeekB,_}) -> WeekA < WeekB end,OpenTimesList),
    NowSeconds = common_tool:now(),
    {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
    TodayWeek = calendar:day_of_the_week(NowDate),
    OpenTimesStr = 
        lists:foldl(
          fun({Week,_} = OpenTimes,Acc) ->
                  if TodayWeek =:= Week ->
                          lists:concat([Acc,"<li><font color='#FF0000'>",lists:flatten(io_lib:format("~w", [OpenTimes])),"</font></li>"]);
                     true ->
                          lists:concat([Acc,"<li>",lists:flatten(io_lib:format("~w", [OpenTimes])),"</li>"])
                  end
          end,"",OpenTimesList2),
    Record = #r_event_country_treasure{normal_open_time = OpenTimesStr,op_code = OpCode,is_open = IsOpenCountryTreasure},
    ?DEBUG("Record=~w",[Record]),
    record_to_json(Record).

do_start(Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    StartSeconds = proplists:get_value("startSeconds", QueryString),
    KeepInterval = proplists:get_value("keepInterval", QueryString),
    NStartSeconds = common_tool:to_integer(StartSeconds),
    NKeepInterval = common_tool:to_integer(KeepInterval),
    OpCode = 
        case get_country_treasure_config(start,NStartSeconds,NKeepInterval) of
            {ok,ModuleName,ModuleDataList} ->
                mgeeweb_tool:call_nodes(common_config_dyn,load_gen_src,[ModuleName,ModuleDataList,ModuleDataList]),
                catch global:send(common_map:get_common_map_name(?COUNTRY_TREASURE_MAP_ID),{mod,mod_country_treasure,{admin_open_fb}}),
                2;
            _ ->
                3
        end,
    Result = get_ct_base_info(OpCode),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).
do_reset(Req, _DocRoot) ->
    [OpenTimesList] = common_config_dyn:find(country_treasure,open_times),
    NowSeconds = common_tool:now(),
    {NowDate,NowTime} = common_tool:seconds_to_datetime(NowSeconds),
    TodayWeek = calendar:day_of_the_week(NowDate),
    Flag = 
        lists:foldl(
          fun({Week,OpenTimeList},Acc) ->
                  if Acc =:= false andalso TodayWeek =:= Week ->
                          lists:foldl(
                            fun({OpenStartTime,OpenEndTime},SubAcc) -> 
                                    if SubAcc =:= false 
                                       andalso NowTime >= OpenStartTime 
                                       andalso OpenEndTime >= NowTime ->
                                            true;
                                       true ->
                                            SubAcc
                                    end
                            end,false,OpenTimeList);
                     true ->
                          Acc
                  end
          end,false,OpenTimesList),
    OpCode = 
        case Flag of 
            true ->
                6;
            false ->
                case get_country_treasure_config(reset,0,0) of
                    {ok,ModuleName,ModuleDataList} ->
                        mgeeweb_tool:call_nodes(common_config_dyn,load_gen_src,[ModuleName,ModuleDataList,ModuleDataList]),
                        catch global:send(common_map:get_common_map_name(?COUNTRY_TREASURE_MAP_ID),{mod,mod_country_treasure,{admin_open_fb}}),
                        4;
                    _ ->
                        5
                end
        end,
    Result = get_ct_base_info(OpCode),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

get_country_treasure_config(OpType,StartSeconds,NKeepInterval) ->
    NowSeconds = common_tool:now(),
    {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
    TodayWeek = calendar:day_of_the_week(NowDate),
    EndSeconds = StartSeconds + NKeepInterval * 60,
    Name = country_treasure,
    NameFilePath = common_config:get_map_config_file_path(Name),
    {ok,NameDataList} = file:consult(NameFilePath),
    NameDataList2 = 
        case OpType of
            start ->
                lists:foldl(
                  fun({Key,Value},Acc) ->
                          case Key of
                              open_times ->
                                  Value2 = 
                                      lists:foldl(
                                        fun({Week,TimeList},AccValue) ->
                                                if Week =:= TodayWeek ->
                                                        {_NowDate,StartTime} = common_tool:seconds_to_datetime(StartSeconds),
                                                        {_NowDate,EndTime} = common_tool:seconds_to_datetime(EndSeconds),
                                                        TimeList2 =[{StartTime,EndTime}],
                                                        [{Week,TimeList2}|AccValue];
                                                   true ->
                                                        [{Week,TimeList}|AccValue]
                                                end
                                        end,[],Value),
                                  io:format("open_times=~p~n",[Value2]),
                                  [{Key,Value2}|Acc];
                              open_day_flag ->
                                  Value2 = false,
                                  [{Key,Value2}|Acc];
                              _ ->
                                  [{Key,Value}|Acc]
                          end
                  end,[],NameDataList);
            reset ->
                NameDataList
        end,
    {ok,Name,NameDataList2}.

%% 将单个记录结果转换成jsno格式数据
%% {r_xxx_xxx,X,Y,Z,...} -> [{"X":1,"Y":"xxx",...}] or []
record_to_json(Record) ->
    {obj,Json} = ?RFC4627_FROM_RECORD(r_event_country_treasure,Record),
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
