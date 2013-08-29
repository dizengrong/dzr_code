%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 提供给mochiweb消息处理
%%% @end
%%% Created :  7 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_admin_db).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

-export([do_handle_call/1,
        get_broadcast_admin_message_list/0]).

%% 返回操作结果 {ok,Recird} or {error,Record}
do_handle_call({mochiweb_broadcast,add,Record})
  when erlang:is_record(Record,m_broadcast_admin_tos) ->
    do_add_broadcast_message(Record);
%% 返回操作结果 {ok,Recird} or {error,Record}
do_handle_call({mochiweb_broadcast,edit,Record})
  when erlang:is_record(Record,m_broadcast_admin_tos) ->
    do_update_broadcast_message(Record);
%% 返回操作结果 [{ok,Id},{error,Id},...]
do_handle_call({mochiweb_broadcast,del,IdList})
  when erlang:is_list(IdList) ->
    do_delete_broadcast_message(IdList);
    
%% 返回操作结果 [{ok,Id},{error,Id},...]
do_handle_call({mochiweb_broadcast,copy,Record})
  when erlang:is_record(Record,m_broadcast_admin_tos) ->
    do_copy_broadcast_message(Record);

do_handle_call(DataRecord) ->
    ?ERROR_MSG("~ts,DataRecord=~w",["无法处理此消息",DataRecord]),
    ok.

%% 增加消息广播
do_add_broadcast_message(Record) ->
    Record2 = Record#m_broadcast_admin_tos{id =  common_tool:now_nanosecond()},
    MessageRecord = #r_broadcast_message{id =Record2#m_broadcast_admin_tos.id,
                                         foreign_id = Record2#m_broadcast_admin_tos.foreign_id,
                                         unique = ?DEFAULT_UNIQUE,
                                         msg_type = ?BROADCAST_ADMIN,
                                         msg_record = Record2,
                                         create_time = common_tool:now(),
                                         expected_time = common_tool:now(),
                                         send_time = 0, %% 最后发送时间
                                         send_times = 0, %% 发送次数
                                         send_flag = 0, %% 消息发送状态 0：新增，1：发送成功，2：发送失败，3：发送中，9：其它错误
                                         send_desc = ""},
    case do_add_broadcast_message2(MessageRecord) of
        ok ->
            %%TODO  发送消息通知道 admin处理添加的消息广播
            self() ! {?DEFAULT_UNIQUE, ?BROADCAST, ?BROADCAST_ADMIN, Record2},
            {ok,Record2};
        error ->
            {error,Record}
    end.
%% 将需要持久化的消息插入数据库
do_add_broadcast_message2(MessageRecord) ->
    case catch db:transaction(fun() ->  insert_t_broadcast_message_record(MessageRecord)  end) of
        {atomic, ok} ->
            ok;
        {aborted,R} ->
            ?ERROR_MSG("~ts ~w",["新增广播消息出错",R]),
            error
    end.
insert_t_broadcast_message_record(MessageRecord) ->
    ?DEBUG("~ts,MessageRecord=~w",["新增的消息广播记录",MessageRecord]),
    db:write(?DB_BROADCAST_MESSAGE, MessageRecord, write),
    ok.

do_copy_broadcast_message(Record)->
    Id = Record#m_broadcast_admin_tos.id,
    Partten = #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, id = Id, _ = '_'},
    case db:dirty_match_object(?DB_BROADCAST_MESSAGE,Partten) of
        [] ->
           
            MessageRecord = #r_broadcast_message{id =Id,
                                                 foreign_id = Record#m_broadcast_admin_tos.foreign_id,
                                                 unique = ?DEFAULT_UNIQUE,
                                                 msg_type = ?BROADCAST_ADMIN,
                                                 msg_record = Record,
                                                 create_time = common_tool:now(),
                                                 expected_time = common_tool:now(),
                                                 send_time = 0, %% 最后发送时间
                                                 send_times = 0, %% 发送次数
                                                 send_flag = 0, %% 消息发送状态 0：新增，1：发送成功，2：发送失败，3：发送中，9：其它错误
                                                 send_desc = ""},
            case do_add_broadcast_message2(MessageRecord) of
                ok ->
                    %%TODO  发送消息通知道 admin处理添加的消息广播
                    self() ! {?DEFAULT_UNIQUE, ?BROADCAST, ?BROADCAST_ADMIN, Record},
                    {ok,Record};
                error ->
                    {error,Record}
            end;
        [MessageRecord] when erlang:is_record(MessageRecord, r_broadcast_message) ->
            do_update_broadcast_message(Record);
        _ ->
            {error,"读取数据表错误"}
    end.
        

do_update_broadcast_message(Record) ->
    case do_update_broadcast_message2(Record) of
        ok ->
            %%TODO  发送消息通知道 admin处理更新的消息广播
            self() ! {update_broadcast_admin_message, Record},
            {ok,Record};
        error ->
            {error,Record}
    end.

do_update_broadcast_message2(Record) ->
    case catch db:transaction(fun() ->  update_t_broadcast_message_record(Record)  end) of
        {atomic, ok} ->
            ok;
        {aborted,R} ->
            ?ERROR_MSG("~ts ~w",["修改广播消息出错",R]),
            error
    end.
update_t_broadcast_message_record(Record) ->
    Id = Record#m_broadcast_admin_tos.id,
    Parrten = #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, id = Id, _ = '_'},
    case db:dirty_match_object(?DB_BROADCAST_MESSAGE,Parrten) of
        {aborted, Reason} ->
            erlang:throw({error,Reason});
        [] ->
            erlang:throw({error,not_found});
        RecordList when erlang:is_list(RecordList),
                        erlang:length(RecordList) =:= 1 ->
            [MessageRecord] = RecordList,
            update_broadcast_message_record2(Record,MessageRecord),
            ok;
        Error ->
            erlang:throw({error,Error})
    end.
update_broadcast_message_record2(Record,MessageRecord) ->
    MessageRecord2 = MessageRecord#r_broadcast_message{id =Record#m_broadcast_admin_tos.id,
                                                       foreign_id = Record#m_broadcast_admin_tos.foreign_id,
                                                       unique = ?DEFAULT_UNIQUE,
                                                       msg_type = ?BROADCAST_ADMIN,
                                                       msg_record = Record,
                                                       create_time = common_tool:now(),
                                                       expected_time = common_tool:now(),
                                                       send_time = 0, %% 最后发送时间
                                                       send_flag = 0, %% 消息发送状态 0：新增，1：发送成功，2：发送失败，3：发送中，9：其它错误
                                                       send_desc = ""},
    db:write(?DB_BROADCAST_MESSAGE, MessageRecord2, write).

do_delete_broadcast_message(IdList) ->
    ResultList = 
        lists:map(fun(Id) ->
                          Parrten = #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, id = Id, _ = '_'},
                          case db:dirty_match_object(?DB_BROADCAST_MESSAGE,Parrten) of
                              {aborted, _Reason} ->
                                  {error,Id};
                              [] ->
                                  {ok,Id};
                              RecordList when erlang:is_list(RecordList),
                                              erlang:length(RecordList) =:= 1 ->
                                  [MessageRecord] = RecordList,
                                  db:dirty_delete_object(?DB_BROADCAST_MESSAGE,MessageRecord),
                                  {ok,Id};
                              _Error ->
                                  {error,Id}
                          end
                  end,IdList),
    DeleteIdList = [Id || {Flag,Id} <- ResultList,Flag =:= ok],
    self() ! {delete_broadcast_admin_message, DeleteIdList},
    ResultList.
    
%% 查询出所有后台消息广播记录
get_broadcast_admin_message_list()->
    Parrten = #r_broadcast_message{msg_type = ?BROADCAST_ADMIN, _ = '_'},
    case db:dirty_match_object(?DB_BROADCAST_MESSAGE,Parrten) of
        {aborted, Reason} ->
            ?ERROR_MSG("~ts Reason=~w.", ["查询广播消息出错",Reason]),
            [];
        [] -> 
            ?DEBUG("~ts",["系统中没有广播消息记录"]),
            [];
        RecordList when erlang:is_list(RecordList) ->
            [R#r_broadcast_message.msg_record || R <- RecordList,
            (R#r_broadcast_message.msg_record)#m_broadcast_admin_tos.send_strategy =/= 0];
        Error ->
            ?ERROR_MSG("~ts Error=~w.", ["查询广播消息出错",Error]),
            []
    end.
