%% Author: liuzhe
%% Created: 2012-10-10
%% Description: 公告进程
-module(g_bulletin).
-behaviour(gen_fsm).

%%
%% Include files
%%
-include("common.hrl").

-record(bulletin_info, {id,
						type, 
						start_time,
						end_time, 
						interval, 
						desc, 
						send_times, 
						sent_times,
						last_sent}).

-define(INTERVAL_UNIT, (1)).
-define(TIMEOUT, (1*60*1000)).
%%-define(ETS_EXPIRED_BULLETIN, ets_expired_bulletin).

-define(BULLETIN_STATE_ACTIVE,  0).
-define(BULLETIN_STATE_EXPIRED, 1).
-define(BULLETIN_STATE_DELETED, 99).

-define(SELECT_ACTIVE_ANNOUNCE(Now), 
		io_lib:format("SELECT "
							"gd_BulletinID, "
							"gd_Type, "
					 		"gd_StartTime, "
							"gd_EndTime, "
							"gd_PerTime, "
							"gd_BulletinDesc, "
							"gd_BulletinSendTimes "
						"FROM "
							"gd_Bulletin "
						"WHERE "
							"gd_BulletinState = ~w AND "
							%%"gd_StartTime <= ~w AND "
							"gd_EndTime > ~w; ",
					  [?BULLETIN_STATE_ACTIVE, Now])).

-define(UPDATE_SENT(ID, LastPopTime),
		io_lib:format("UPDATE "
							"gd_Bulletin "
						"SET "
							"gd_LastPopTime = ~w "
						"WHERE "
							"gd_BulletinID = ~w; ", 
					  [LastPopTime, ID])).

-define(UPDATE_STATE(ID, State),
		io_lib:format("UPDATE "
							"gd_Bulletin "
						"SET "
							"gd_BulletinState = ~w "
						"WHERE "
							"gd_BulletinID = ~w; ", 
					  [State, ID])).

%%
%% Exported Functions
%%
-export([start_link/0]).

-export([waiting/2]).

-export([
		 init/1,
		 handle_event/3,
		 handle_sync_event/4,
		 code_change/4,
		 handle_info/3,
		 terminate/3,
		 reload/0
		]).

%%
%% API Functions
%%
start_link() ->
	gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

%%
%% gen_fsm 状态转换
%%
waiting(timeout, State) ->
	ActiveAnnounce = State,
	?INFO(bulletin, "ActiveAnnounce: ~w", [ActiveAnnounce]),
	
	%% 发送公告信息，丢掉已经过期的
	{_, NewActive} = handle_announce(ActiveAnnounce, send_popup),
	{next_state, waiting, NewActive, ?TIMEOUT};

waiting(reload, _State)->
	NewActive = read_db(),
	{next_state, waiting, NewActive, 0}.

%%
%% gen_fsm 接口
%%
init([]) ->
	erlang:process_flag(trap_exit, true),
	%%?ETS_EXPIRED_BULLETIN = ets:new(?ETS_EXPIRED_BULLETIN, [set, protected, named_table, {keypos, #bulletin_info.id}]),
	
	NewInfo = read_db(),
	?INFO(bulletin, "NewInfo = ~w", [NewInfo]),
	
	{_, NewActive} = handle_announce(NewInfo, dont_send_popup),
	?INFO(bulletin, "NewActive = ~w", [NewActive]),
	{ok, waiting, NewActive, ?TIMEOUT}.

%% 这个 read_db 事件来自 mod_management ……
reload() ->
	gen_fsm:send_event(?MODULE,  reload).

%%handle_event({remove_bulletin, ID}, _StateName, State) ->
%%	CurActive = State,
%%	{ok, updated} = db_sql:execute(?UPDATE_STATE(ID, ?BULLETIN_STATE_EXPIRED)),
%%	NewActive = lists:keydelete(ID, #bulletin_info.id, CurActive),
%%	waiting(timeout, NewActive);

handle_event(stop, _StateName, State) ->
	{stop, normal, State}.

handle_sync_event(_Any, _From, StateName, State) ->
	{reply, {error, unhandled}, StateName, State}.

code_change(_OldVsn, StateName, State, _Extra) ->
	{ok, StateName, State}.

handle_info(_Any, StateName, State) ->
	{next_state, StateName, State}.

terminate(_Any, _StateName, _Opts) ->
	?INFO(bulletin, "Terminating...", []),
	%%ets:delete(?ETS_EXPIRED_BULLETIN),
    ok.

%%
%% Local Functions
%%
db_row_to_bulletin_info(Row) ->
	[ID, Type, StartTime, EndTime, Interval, Desc, SendTimes] = Row,
	#bulletin_info{id=ID,
				   type=Type,
				   start_time=StartTime,
				   end_time=EndTime,
				   interval=Interval,
				   desc=binary_to_list(Desc),
				   send_times=SendTimes,
				   sent_times=0,
				   last_sent=0}.

handle_normal_announce(Info, Now, Type, ExpiredInfoList, NewInfoList) ->
	case Now >= Info#bulletin_info.start_time of
		true ->
			Interval = Info#bulletin_info.interval * ?INTERVAL_UNIT,
			?INFO(bulletin,"a is ~w, b is ~w",[Now - Info#bulletin_info.last_sent, Interval]),
			{LastSent, SentTimes} = 
				case (Now - Info#bulletin_info.last_sent) >= Interval of
					true ->
						%%SendTimes = Info#bulletin_info.send_times,
						SendTimes = 1,
						{ok, Bin} = pt_16:write(16007, [SendTimes, Type, Info#bulletin_info.desc]),
						%% 不直接发免得公告堆在一起……
						gen_server:cast(g_bulletin_queue, {add_to_send_queue, Bin}),
						%% XXX: 这里就认为公告已经发出去了
						{ok, updated} = db_sql:execute(?UPDATE_SENT(Info#bulletin_info.id, Now)),
						{Now, Info#bulletin_info.sent_times+1};
					false ->
						{Info#bulletin_info.last_sent, Info#bulletin_info.sent_times}
				end,
		
			?INFO(bulletin, "Going to update bulletin info list, LastSent=~w, SentTimes=~w", 
				  [LastSent, SentTimes]),
			
			%% 普通公告忽略发送次数，是否过期只以时间为准
			case Now >= Info#bulletin_info.end_time of
				true ->
					?INFO(bulletin, "Drop expired bulletin info ~w", [Info]),
					{ok, updated} = 
						db_sql:execute(?UPDATE_STATE(Info#bulletin_info.id, ?BULLETIN_STATE_EXPIRED)),
					{[Info | ExpiredInfoList], NewInfoList};
				false ->
					NewInfo = Info#bulletin_info{sent_times=SentTimes, last_sent=LastSent},
					{ExpiredInfoList, [NewInfo | NewInfoList]}
			end;
		
		false ->
			%% 开始时间还没到，直接放回待处理列表里
			{ExpiredInfoList, [Info | NewInfoList]}
	end.

announce_folder(Info, {SendPopup, Now, ExpiredInfoList, NewInfoList}) ->
	case (Info#bulletin_info.type) of
		%% 弹框
		0 ->
			case SendPopup of
				send_popup ->
					SendTimes = Info#bulletin_info.send_times,
					{ok, Bin} = pt_16:write(16007, [SendTimes, 3, Info#bulletin_info.desc]),
					%% 弹窗公告直接发，不用队列……
					lib_send:broadcast_to_world(Bin),
					{ok, updated} = db_sql:execute(?UPDATE_SENT(Info#bulletin_info.id, Now)),
					{ok, updated} = 
						db_sql:execute(?UPDATE_STATE(Info#bulletin_info.id, ?BULLETIN_STATE_EXPIRED)),
					%% 弹框是“一次性”的，直接丢掉
					{SendPopup, Now, [Info | ExpiredInfoList], NewInfoList};
				dont_send_popup ->
					{ok, updated} = db_sql:execute(?UPDATE_SENT(Info#bulletin_info.id, Now)),
					{ok, updated} = 
						db_sql:execute(?UPDATE_STATE(Info#bulletin_info.id, ?BULLETIN_STATE_EXPIRED)),
					{SendPopup, Now, [Info | ExpiredInfoList], NewInfoList}
			end;
		
		%% 聊天框
		1 ->
			{ExpiredInfoList1, NewInfoList1} = 
				handle_normal_announce(Info, Now, 2, ExpiredInfoList, NewInfoList),
			{SendPopup, Now, ExpiredInfoList1, NewInfoList1};
		
		%% 上方横幅
		2 ->
			{ExpiredInfoList1, NewInfoList1} = 
				handle_normal_announce(Info, Now, 1, ExpiredInfoList, NewInfoList),
			{SendPopup, Now, ExpiredInfoList1, NewInfoList1}
	end.

handle_announce(ActiveAnnounce, SendPopup) ->
	Now = util:unixtime(),
	{_, _, Expired, Active} = lists:foldl(fun announce_folder/2, 
										  {SendPopup, Now, [], []}, ActiveAnnounce),
	{Expired, lists:reverse(Active)}.



read_db() ->
    put(date,{time(),date()}),
	%% 1. 从数据库读出新的公告信息
	SQL = ?SELECT_ACTIVE_ANNOUNCE(util:unixtime()),
	?INFO(bulletin, "SQL=~s", [SQL]),
	Rows = db_sql:get_all(SQL),
	%% 2. 过滤掉已经处理过的公告
	%%NotExpired = fun(Row) ->
	%%					[ID | _] = Row,
	%%					case ets:lookup(?ETS_EXPIRED_BULLETIN, ID) of
	%%						[] ->
	%%							true;
	%%						[_] ->
	%%							false
	%%					end
	%%			 end,
	%%NewRows = lists:filter(NotExpired, Rows),
	%%NewInfo = lists:map(fun db_row_to_bulletin_info/1, NewRows),
	NewInfo = lists:map(fun db_row_to_bulletin_info/1, Rows),
	
	%% 3. 记下已经处理过的公告
	%%ets:insert(?ETS_EXPIRED_BULLETIN, NewInfo),
	NewInfo.
