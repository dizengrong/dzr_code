%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created : 26 Aug 2010 by  <>
%%%-------------------------------------------------------------------
-module(mgeel_s2s_client).

-include("mgeel.hrl").
-include("define.hrl").
-include("behavior_lang.hrl").

-behaviour(gen_server).

%% API
-export([start/0,start/1,start_link/1,post/6]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 
%% 一次发送多少条投诉记录给后台管理
-define(DEFAULT_SEND_MAX_RECORD,10).

%% 定时多少秒执行一次数据同步 10秒
-define(DEFAULT_SEND_INTERVAL_TIME,10*1000).

%% 消息最多发送三次，不成功即删除
-define(DEFAULT_MAX_SEND_TIMES,3).
%% 缓存玩家投诉数据
-define(ETS_S2S_COMPLAINT,ets_s2s_complaint).
%% 状态记录,data 结构为：adm_gm_complaint，send_flag 发送标志 0新增，1成功，2，失败
-define(ETS_S2S_SCORT,ets_s2s_scort).
%%
-record(r_role_complaint,{data,send_times,send_flag}).
-record(r_role_scort,{data,send_times,send_flag}).

-record(r_msg,{unique, module,method,data, roleid, pid, line, state}).
-record(state, {socket,complaint_num}).

%%%===================================================================
%%% API
%%%===================================================================
start() ->
    start(undefined).
start(AdminSocket) ->
    supervisor:delete_child(mgeel_sup,?MODULE),
    {ok,_} = supervisor:start_child(mgeel_sup, {?MODULE,
                                                 {?MODULE, start_link, [AdminSocket]},
                                                 temporary, brutal_kill, worker, 
                                                 [?MODULE]}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link(AdminSocket) ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [AdminSocket], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([AdminSocket]) ->
    ets:new(?ETS_S2S_COMPLAINT, [protected, named_table, set]),
    ets:new(?ETS_S2S_SCORT, [protected, named_table, set]),
    [AgentID] = common_config_dyn:find(common, agent_id),
    [GameID] = common_config_dyn:find(common, server_id),        
    erlang:put(agentid_and_gameid,{AgentID,GameID}),
    erlang:send_after(?DEFAULT_SEND_INTERVAL_TIME, self(), {send_message, ?DEFAULT_SEND_INTERVAL_TIME}),
    {ok, #state{socket=AdminSocket,complaint_num=10}}.
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DO_HANDLE_INFO_STATE(Info, State),
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%% 接收玩家的 投诉/评分消息
do_handle_info({Unique, ?GM, Method, DataIn, RoleID, Pid, Line}=Info, State) ->
    ?DEBUG("GM模块的消息,Info=~w",[Info]),
    do_gm(#r_msg{unique=Unique,module=?GM,method=Method,data=DataIn, roleid=RoleID,pid=Pid,line=Line,state=State});

%% 本模块内部的消息机制
do_handle_info({send_message,IntervalTime},_State)->
    try
        do_send_complaint_message(),
        do_send_scort_message()
    catch
        _:Reason->
           ?ERROR_MSG("处理发送GM消息出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end,
    
    erlang:send_after(IntervalTime, self(), {send_message,IntervalTime});

%%@doc 通知GM的回复结果 到管理后台
do_handle_info({gm_notify_reply,ReplyID,Succ,Reason,LetterID},_State) ->
    ?DEBUG("通知GM的回复结果 到管理后台,ReplyID=~w,Succ=~w",[ReplyID,Succ]),
    case Succ of
        true->
            ets:insert(?ETS_S2S_SCORT,{LetterID,ReplyID});
        false->
            %% 只有在失败的时候，才需要更新通知到管理后台
            ModuleTuple = ?B_GM,
            MethodTuple = ?B_GM_NOTIFY_REPLY,
            Record=#adm_gm_notify_reply{reply_id=ReplyID,succ=Succ,reason=Reason},
            
            BinaryList = [ encod_data(gm_notify_reply,Record)  ],
            mgeel_s2s_behavior_client:send( ModuleTuple, MethodTuple, BinaryList )
    end;
do_handle_info(Info,_State) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息",Info]).


%% ====================================================================
%% 接收玩家的 投诉/评分消息
%% ====================================================================

do_gm(Msg)when Msg#r_msg.method =:= ?GM_COMPLAINT ->
    do_gm_complaint(Msg);
do_gm(Msg)when Msg#r_msg.method =:= ?GM_SCORE ->
    do_gm_scort(Msg);
do_gm(Other) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息",Other]).

%%@doc 玩家的GM投诉 
do_gm_complaint(Msg) ->
    {ok, RoleBase} = common_misc:get_dirty_role_base(Msg#r_msg.roleid),
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(Msg#r_msg.roleid),
    ?DEBUG("RoleBase:~w, roleid: ~w~n",[RoleBase, RoleBase#p_role_base.role_id]),
    ?DEBUG("Complaint toc:~w~n",[Msg#r_msg.data]),
    Complaint = #adm_gm_complaint{
                  role_id = RoleBase#p_role_base.role_id,
                  account_name = RoleBase#p_role_base.account_name,
                  role_name = RoleBase#p_role_base.role_name,
                  pay_amount = RoleAttr#p_role_attr.gold,
                  level = RoleAttr#p_role_attr.level,
                  mtime = common_tool:now(),
                  mtype = (Msg#r_msg.data)#m_gm_complaint_tos.type,
                  mtitle = (Msg#r_msg.data)#m_gm_complaint_tos.title,
                  content = (Msg#r_msg.data)#m_gm_complaint_tos.content
                },
    unicast(Msg, #m_gm_complaint_toc{succ=true}),
    RoleComplaintRecord = #r_role_complaint{data = Complaint,send_times = 0,send_flag = 0},
    ets:insert(?ETS_S2S_COMPLAINT,{Complaint#adm_gm_complaint.mtime,RoleComplaintRecord}).



%%@doc 玩家对GM回复进行评分
do_gm_scort(Msg) ->
    ?DEBUG("Msg:~w~n",[Msg]),
    #m_gm_score_tos{id=LetterID,fraction=Mark}=Msg#r_msg.data,
    case ets:lookup(?ETS_S2S_SCORT,LetterID) of
        [{LetterID,ReplyID}] ->
            Data = #adm_gm_evaluate{reply_id=ReplyID,role_id=Msg#r_msg.roleid,mark=Mark},
            R = #r_role_scort{data=Data,send_times=common_tool:now(),send_flag=0},
            ets:insert(?ETS_S2S_SCORT,{erlang:make_ref(),R}),
            unicast(Msg,#m_gm_score_toc{succ = true});
        [] ->
            unicast(Msg,#m_gm_score_toc{succ = true,reason=?_LANG_SYSTEM_ERROR})
    end.


%% ====================================================================
%% 将玩家投诉、玩家的GM评分 发送到管理后台
%% ====================================================================

%% 将GM投诉消息发送到后台
do_send_complaint_message() ->
    MatchHead = {_='_',#r_role_complaint{send_times='$1',send_flag ='$2',_='_'}},
    Guard = [{'<', '$1', ?DEFAULT_MAX_SEND_TIMES},{'=/=', '$2', 1}],
    Result = ['$_'],
    case ets:select(?ETS_S2S_COMPLAINT, [{MatchHead, Guard, Result}], ?DEFAULT_SEND_MAX_RECORD) of
        '$end_of_table' ->
            %% 当前表没有记录不需要处理
            ignore;
        {RecordList,_Continuation} when erlang:is_list(RecordList) ->
%%             ?DEBUG("~ts,RecordListLength=~w,Continuation=~p",["获取到投诉记录，并开始处理",erlang:length(RecordList), Continuation]),
            do_send_complaint_message(RecordList)
    end.

do_send_complaint_message(RecordList) ->
    lists:foreach(fun({Key,_Record}) ->
                          ets:delete(?ETS_S2S_COMPLAINT, Key)
                  end,RecordList),
    
    %% 使用admin发送接口发送数据到后台管理
    ModuleTuple = ?B_GM,
    MethodTuple = ?B_GM_COMPLAINT,
    BinaryList = [ encod_data(complaint,R) || {_Key,R} <- RecordList ],
    
    mgeel_s2s_behavior_client:send( ModuleTuple, MethodTuple, BinaryList ),
    %% mgeel_s2s_http:post(AgentID, GameID, ModuleTuple, MethodTuple, BinaryList),
    ok.

%% 将玩家的GM评分发送到管理后台
do_send_scort_message() ->
    MatchHead = {_='_',#r_role_scort{_='_'}},
    Result = ['$_'],
    case ets:select(?ETS_S2S_SCORT, [{MatchHead, [], Result}], ?DEFAULT_SEND_MAX_RECORD) of
        '$end_of_table' ->
            %% 当前表没有记录不需要处理
            ignore;
        {RecordList,Continuation} when erlang:is_list(RecordList) ->
            ?DEBUG("~ts,RecordListLength=~w,Continuation=~p",["获取到投诉记录，并开始处理",erlang:length(RecordList), Continuation]),
            do_send_scort_message(RecordList)
    end.

do_send_scort_message(RecordList) ->
    lists:foreach(fun({Key,_Record}) ->
                          ets:delete(?ETS_S2S_SCORT, Key)
                  end,RecordList),
    
    ModuleTuple = ?B_GM,
    MethodTuple = ?B_GM_EVALUATE,
    BinaryList = [ encod_data(evaluate,R) || {_Key,R} <- RecordList ],
    
    mgeel_s2s_behavior_client:send( ModuleTuple, MethodTuple, BinaryList ),
    
    %%mgeel_s2s_http:post(AgentID, GameID, ModuleTuple, MethodTuple, BinaryList),
    ok.


%%@doc encod_data to binary
encod_data(gm_notify_reply, Data)->
    term_to_binary(Data);
encod_data(complaint, #r_role_complaint{data = Data} )->
    term_to_binary(Data);
encod_data(evaluate, #r_role_scort{data = Data})->
    term_to_binary(Data).

    
%%-------------------------------------------------------------------------------------------------------
unicast(Msg,R)->
    #r_msg{line=Line,
           roleid=RoleID,
           unique=Unique,
           module=Module,
           method=Method}=Msg,
    common_misc:unicast(Line,RoleID,Unique,Module,Method, R).    

post(Socket,Module,Method,ModuletTuple,MethodTuple,Record) ->
    Data = encode(Module,Method,Record),
    Bin = erlang:term_to_binary({ModuletTuple,MethodTuple,Data}),
    gen_tcp:send(Socket,<<0:32,Bin/binary>>).

encode(Module, Method, DataRecord) ->
    EncodeFunc = get_pb_record_name(Module, Method),
    apply(behavior_pb, EncodeFunc, [DataRecord]).

get_pb_record_name(Module, Method) ->
    common_tool:list_to_atom(
      lists:concat(["encode_adm_", 
                    common_tool:to_list(Module), 
                    "_", 
                    common_tool:to_list(Method)
                   ])
     ).
