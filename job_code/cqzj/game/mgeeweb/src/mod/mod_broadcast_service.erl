%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 消息广播接口
%%% @end
%%% Created :  3 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_service).

-include("mgeeweb.hrl").

-define(RFC4627_FROM_RECORD(RName, R),
    rfc4627:from_record(R, RName, record_info(fields, RName))).

-define(RFC4627_TO_RECORD(RName, R),
    rfc4627:to_record(R, #RName{}, record_info(fields, RName))).

%% API
-export([
         handle/3
        ]).

%% -record(r_broadcast_message,{id,foreign_id,unique,msg_type,msg_record,create_time,expected_time,send_time,send_times,send_flag,send_desc}).
%% 游戏管理后台消息广播处理
%% //后台广播消息，聊天频道的消息以世界广播方式发送
%% message m_broadcast_admin_tos {
%%     required int32   id = 1;//消息唯一标记，使用时间截处理
%%     required int32   foreign_id = 2;//消息外键，即中央管理发送的消息唯一标记，如果不是中央管理即默认为0
%%     required int32   type = 2;  //消息类型 2906:系统消息,2908:喇叭消息,2909:中央广播消息,2910:聊天频道消息,2911:弹窗消息
%%     required string  content = 3;//内容
%%     required int32   send_strategy =4;//0,立即，1.特定日期时间范围, 2.星期 3.开服后,4.持续一段时间内间隔发送
%%     optional string  start_date =5;//如果是日期，即格式为：yyyy-MM-dd
%%     optional string  end_date =6;//如果是日期，即格式为：yyyy-MM-dd
%%     optional string  start_time = 6;//如果为时间，即格式为：HH:mm:ss
%%     optional string  end_time = 8;//如果为时间，即格式为：HH:mm:ss
%%     optional int32   interval = 9 [default=0];//间隔时间 单位：秒
%% }
%% @post
handle("/copy",Req,_DocRoot)->
    do_copy(Req,_DocRoot);
%% @get
handle("/list" ++ _RemainPath,Req, DocRoot) ->
    do_list(Req, DocRoot);
handle("/add" ++ _RemainPath,Req, DocRoot) ->
    do_add(Req, DocRoot);
handle("/show" ++ _RemainPath,Req, DocRoot) ->
    do_show(Req, DocRoot);
handle("/edit" ++ _RemainPath,Req, DocRoot) ->
    do_edit(Req, DocRoot);
handle("/del" ++ _RemainPath,Req, DocRoot) ->
    do_del(Req, DocRoot);
handle("/save" ++ _RemainPath,Req, DocRoot) ->
    do_save(Req, DocRoot);
handle(RemainPath, Req, DocRoot) ->
    ?ERROR_MSG("~ts,RemainPath=~w, Req=~w, DocRoot=~w",["无法处理此消息", RemainPath, Req, DocRoot]),
    Req:not_found().


%%循环消息同步接口
do_copy(Req,_DocRoot)->
    QueryString = Req:parse_post(),
    Id = proplists:get_value("id", QueryString),
    ForeignId = proplists:get_value("foreign_id", QueryString),
    Type = proplists:get_value("type", QueryString),
    SendStrategy = proplists:get_value("send_strategy", QueryString),
    StartDate = proplists:get_value("start_date", QueryString),
    EndDate = proplists:get_value("end_date", QueryString),
    StartTime = proplists:get_value("start_time", QueryString),
    EndTime = proplists:get_value("end_time", QueryString),
    Interval = proplists:get_value("interval", QueryString),
    Base64Content = proplists:get_value("content", QueryString),
    Content = base64:decode_to_string(base64:decode_to_string(Base64Content)),
    ?DEBUG("~ts,Id=~w,ForeignId=~w,Type=~w,Content=~w",["获取的数据为",Id,ForeignId,Type,Content]),
    R = #m_broadcast_admin_tos{id = common_tool:to_integer(Id),
                               foreign_id = common_tool:to_integer(ForeignId),
                               type = common_tool:to_integer(Type),
                               content = Content,
                               send_strategy = common_tool:to_integer(SendStrategy),
                               start_date = StartDate,
                               end_date = EndDate,
                               start_time = StartTime,
                               end_time = EndTime,
                               interval = common_tool:to_integer(Interval)
                              },
    ?DEBUG("~ts,Record=~w",["保存消息广播接收到的消息为",R]),
    {_ResultCode,ResultDesc,_R2} = case copy_broadcast_message(R) of
            {ok,ROK} ->
                 {0,"保存成功",ROK};
             {error,RError} ->
                 {1,"保存失败",RError}
         end,

    %%R3 = R2#m_broadcast_admin_tos{content = Base64Content},
    %%ResultDataJson = record_to_json(R3),
    %%Result = result_to_json(ResultCode,ResultDesc,ResultDataJson),
    %%?DEBUG("~ts,Result=~w",["查询消息广播结果是",Result]),
    mgeeweb_tool:return_json([{result,ResultDesc}],Req).
    %%mgeeweb_tool:return_json_error(Req).

%% 查询消息广播列表
do_list(Req, _DocRoot) ->
    List = get_broadcast_message_list(),
    Result = record_list_to_json(List),
    %% Result = record_to_json(R),
    ?DEBUG("~ts,Result=~w",["查询消息广播结果是",Result]),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

get_broadcast_message_list()->
    Parrten = #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, _ = '_'},
    case mnesia:dirty_match_object(?DB_BROADCAST_MESSAGE,Parrten) of
        {aborted, Reason} ->
            ?ERROR_MSG("~ts Reason=~w.", ["查询广播消息出错",Reason]),
            [];
        [] -> 
            ?DEBUG("~ts",["系统中没有广播消息记录"]),
            [];
        RecordList when erlang:is_list(RecordList) ->
            lists:map(fun(Record) ->
                              MsgRecord = Record#r_broadcast_message.msg_record,
                              Content = MsgRecord#m_broadcast_admin_tos.content,
                              Base64Content = base64:encode_to_string(Content),
                              MsgRecord#m_broadcast_admin_tos{content = Base64Content}
                      end,RecordList);
            %% [R#r_broadcast_message.msg_record || R <- RecordList];
        Error ->
            ?ERROR_MSG("~ts Error=~w.", ["查询广播消息出错",Error]),
            []
    end.
    

do_add(Req, _DocRoot)->
    R = #m_broadcast_admin_tos{id = 0,foreign_id = 0,type = 0,send_strategy = 0,interval = 0},
    Result = record_to_json(R),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

do_show(Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    IdStr = proplists:get_value("id", QueryString),
    Id = common_tool:to_integer(IdStr),
    Type = proplists:get_value("type", QueryString),
    R = get_broadcast_message(Id,Type),
    {ResultCode,ResultDesc} = 
        if R#m_broadcast_admin_tos.id =:= 0 ->
            %% 错误信息
                {0,"查看详细查询成功"};
           true ->
                {1,"查看详细查询记录失败"}
        end,
    ResultDataJson = record_to_json(R),
    Result = result_to_json(ResultCode,ResultDesc,ResultDataJson),
    ?DEBUG("~ts,Id=~w,type=~w,Result=~w",["查询消息广播记录",Id,Type,Result]),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).
%% 根据id或者foreign_id查询消息广播记录信息
%% Type  "id","foreign_id"
get_broadcast_message(Id,Type) ->
    Parrten = 
        case Type of
            "id" ->
                #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, id = Id, _ = '_'};
            "foreign_id" ->
                #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, foreign_id = Id, _ = '_'};
            _ ->
                #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, id = Id, _ = '_'}
        end,
    ?DEBUG("~ts,Parrten=~w",["查询条件为",Parrten]),
    case mnesia:dirty_match_object(?DB_BROADCAST_MESSAGE,Parrten) of
        {aborted, Reason} ->
            ?ERROR_MSG("~ts,Id=~w,Type=~w,Reason=~w.", ["查询广播消息出错",Id,Type,Reason]),
            #m_broadcast_admin_tos{id = 0,foreign_id = 0,type = 0,send_strategy = 0,interval = 0};
        [] ->
            #m_broadcast_admin_tos{id = 0,foreign_id = 0,type = 0,send_strategy = 0,interval = 0};
        RecordList when erlang:is_list(RecordList),
                        erlang:length(RecordList) =:= 1 ->
            [Record] = RecordList,
            MsgRecord = Record#r_broadcast_message.msg_record,
            Content = MsgRecord#m_broadcast_admin_tos.content,
            Base64Content = base64:encode_to_string(Content),
            MsgRecord#m_broadcast_admin_tos{content = Base64Content};
        Error ->
            ?ERROR_MSG("~ts,Id=~w,Type=~w,Error=~w.", ["查询广播消息出错",Id,Type,Error]),
            #m_broadcast_admin_tos{id = 0,foreign_id = 0,type = 0,send_strategy = 0,interval = 0}
    end.
    

do_edit(Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    IdStr = proplists:get_value("id", QueryString),
    Id = common_tool:to_integer(IdStr),
    Type = proplists:get_value("type", QueryString),
    R = get_broadcast_message(Id,Type),
    {ResultCode,ResultDesc} = 
        if R#m_broadcast_admin_tos.id =:= 0 ->
            %% 错误信息
                {1,"编辑查询记录失败"};
           true ->
                {0,"编辑查询成功"}
        end,
    ResultDataJson = record_to_json(R),
    Result = result_to_json(ResultCode,ResultDesc,ResultDataJson),
    ?DEBUG("~ts,Id=~w,type=~w,Result=~w",["查询消息广播记录",Id,Type,Result]),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

do_del(Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    Ids = proplists:get_value("ids", QueryString),
    ?DEBUG("~ts,Ids=~w",["获取的数据为",Ids]),
    StrIds = string:tokens(Ids,","),
    IdList = [common_tool:to_integer(IdR) || IdR <- StrIds],
    DeleteResultList = send_game_broadcast_service(del,IdList),
    ErrorList = [EId || {EF,EId} <- DeleteResultList,EF =:= error],
    {ResultCode,ResultDesc} = 
        if erlang:length(ErrorList) > 0 ->
                {1,lists:concat(["以下此记录删除失败：",ErrorList])};
           true ->
                {0,"删除成功"}
        end,
    List = get_broadcast_message_list(),
    ResultDataJson = record_list_to_json(List),
    Result = result_to_json(ResultCode,ResultDesc,ResultDataJson),
    ?DEBUG("~ts,Result=~w",["查询消息广播结果是",Result]),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

do_save(Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    Id = proplists:get_value("id", QueryString),
    ForeignId = proplists:get_value("foreign_id", QueryString),
    Type = proplists:get_value("type", QueryString),
    SendStrategy = proplists:get_value("send_strategy", QueryString),
    StartDate = proplists:get_value("start_date", QueryString),
    EndDate = proplists:get_value("end_date", QueryString),
    StartTime = proplists:get_value("start_time", QueryString),
    EndTime = proplists:get_value("end_time", QueryString),
    Interval = proplists:get_value("interval", QueryString),
    Base64Content = proplists:get_value("content", QueryString),
    Content = base64:decode_to_string(Base64Content),
    ?DEBUG("~ts,Id=~w,ForeignId=~w,Type=~w,Content=~w",["获取的数据为",Id,ForeignId,Type,Content]),
    R = #m_broadcast_admin_tos{id = common_tool:to_integer(Id),
                               foreign_id = common_tool:to_integer(ForeignId),
                               type = common_tool:to_integer(Type),
                               content = Content,
                               send_strategy = common_tool:to_integer(SendStrategy),
                               start_date = StartDate,
                               end_date = EndDate,
                               start_time = StartTime,
                               end_time = EndTime,
                               interval = common_tool:to_integer(Interval)
                              },
    ?DEBUG("~ts,Record=~w",["保存消息广播接收到的消息为",R]),
    {ResultCode,ResultDesc,R2} = case save_broadcast_message(R) of
            {ok,ROK} ->
                 {0,"保存成功",ROK};
             {error,RError} ->
                 {1,"保存失败",RError}
         end,
    R3 = R2#m_broadcast_admin_tos{content = Base64Content},
    ResultDataJson = record_to_json(R3),
    Result = result_to_json(ResultCode,ResultDesc,ResultDataJson),
    ?DEBUG("~ts,Result=~w",["查询消息广播结果是",Result]),
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).

save_broadcast_message(Record) ->
    Id = Record#m_broadcast_admin_tos.id,
    if Id =:= 0 ->
            %% 新增
            send_game_broadcast_service(add,Record);
       true ->
            send_game_broadcast_service(edit,Record)
    end.

%% 将操作结果组装备成json返回
result_to_json(ResultCode,ResultDesc,ResultDataJson) ->
    lists:concat(["{",
                  "\"ResultCode\":\"",ResultCode,"\"",","
                  "\"ResultDesc\":\"",ResultDesc,"\"",","
                  "\"ResultData\":",ResultDataJson,
                  "}"]).


%% 将记录结果集转换成json格式的数据
%% [r_xxx_xx,...] -> [{"X":1,"Y":"xxx",...},....]
record_list_to_json(RecordList) ->
    Length = erlang:length(RecordList),
    {JsonStr,_} = 
        lists:foldl(fun(Record,Acc) ->
                            {AccStr,Index}= Acc,
                            JsonRecordStr = record_to_json(Record,false),
                            AccStr2 =
                                if Index + 1 < Length ->
                                        lists:concat([AccStr,JsonRecordStr,","]);
                                   true ->
                                        lists:concat([AccStr,JsonRecordStr])
                                end,
                            {AccStr2,Index + 1}
                    end,{"",0},RecordList),
    if JsonStr =/= "" ->
            lists:concat(["[",JsonStr,"]"]);
       true ->
            lists:concat(["[",JsonStr,"]"])
    end.
%% 将单个记录结果转换成jsno格式数据
%% {r_xxx_xxx,X,Y,Z,...} -> [{"X":1,"Y":"xxx",...}]
record_to_json(Record) ->
    record_to_json(Record,true).

%% 将单个记录结果转换成jsno格式数据
%% {r_xxx_xxx,X,Y,Z,...} -> [{"X":1,"Y":"xxx",...}] or []
record_to_json(Record,true) ->
    {obj,Json} = ?RFC4627_FROM_RECORD(m_broadcast_admin_tos,Record),
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
    end;
%% 将单个记录结果转换成jsno格式数据
%% {r_xxx_xxx,X,Y,Z,...} -> {"X":1,"Y":"xxx",...} or ""
record_to_json(Record,false) ->
    {obj,Json} = ?RFC4627_FROM_RECORD(m_broadcast_admin_tos,Record),
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
            ""
    end.

value_to_json(Value)when erlang:is_integer(Value) ->
    lists:concat([Value]);
value_to_json(Value)when erlang:is_number(Value) ->
    lists:concat([Value]);
value_to_json(Value) ->
    lists:concat(["\"",Value,"\""]).

%% 发送消息到游戏服务器的消息广播模块
send_game_broadcast_service(add,Record)->
    DataRecord = {mochiweb_broadcast,add,Record},
    %% {mochiweb_broadcast,add,id}
    send_game_broadcast_service(DataRecord);

send_game_broadcast_service(edit,Record) ->
    DataRecord = {mochiweb_broadcast,edit,Record},
    %% {mochiweb_broadcast,edit,id}
    send_game_broadcast_service(DataRecord);

send_game_broadcast_service(del,Ids) ->
    DataRecord = {mochiweb_broadcast,del,Ids},
    %% {mochiweb_broadcast,del,id}
    send_game_broadcast_service(DataRecord).

send_game_broadcast_service(DataRecord) ->
    Result = gen_server:call({global,"mod_broadcast_server"},{?BROADCAST_ADMIN,DataRecord}),
    ?DEBUG("~ts,Result=~w",["接收到的远程调用返回结果",Result]),
    Result.

copy_broadcast_message(Record) ->
    Result = gen_server:call({global,"mod_broadcast_server"},{?BROADCAST_ADMIN,{mochiweb_broadcast,copy,Record}}),
    ?DEBUG("~ts,Result=~w",["接收到的远程调用返回结果",Result]),
    Result.