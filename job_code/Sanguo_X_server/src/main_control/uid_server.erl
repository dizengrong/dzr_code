%% 本模块用于分配全局唯一id的
%% 要添加某一类别的唯一id，请先在uid_server.hrl头文件中添加相应的宏定义
%% 如：
%% 		定义每一个uid的类别
%% 		-define(UID_ITEM, 2).
%% ets表uid_count中存的id为当前数据库中的已存在的最大id，若没有则为0
-module(uid_server).

-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-export([get_seq_num/1, save_all_uid/0]).

-include("common.hrl").


%===========================================================================================
% global functions
%===========================================================================================

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% return: Num | {false, sys_error}
get_seq_num(Type) ->
	Num = gen_server:call(?MODULE, {get_seq_num, Type}),
	?INFO(uid_server, "~w:get_seq_num return ~w", [?MODULE, Num]),
	Num.

%===========================================================================================
% callback functions
%===========================================================================================

init([]) ->
	ets:new(uid_count, [ordered_set, public, named_table, {keypos, #uid.key}]),
	ServerIndex = util:get_app_env(server_index),
	ServerUidList = cache_util:select(uid, map_data:map(uid), ServerIndex),
	ets:insert(uid_count, ServerUidList),

	erlang:process_flag(trap_exit, true),
	{ok, null}.


%% 处理获取uid的call请求
%% 参数Type为uid的类别，具体见common.hrl中的宏定义：-define(UID_ITEM, 2).
handle_call({get_seq_num, Type}, _From, _LoopData) ->
	ServerIndex = util:get_app_env(server_index),
	Reply = 
		case ets:lookup(uid_count, {ServerIndex, Type}) of
			[] -> 
				UidRec = #uid{key = {ServerIndex, Type}},
				cache_util:insert(uid, UidRec),
				ets:insert(uid_count, UidRec),
				UidRec#uid.max_id;
			[UidRec] ->
				ServerIndex = util:get_app_env(server_index),
				ets:update_counter(uid_count, {ServerIndex, Type}, {3, 1}),
				case util:get_app_env(server_mode) of
					debug ->
						save_all_uid();
					_ ->
						ok
				end,
				UidRec#uid.max_id
		end,
	{reply, Reply, null};
	
handle_call(stop, _From, _LoopData) ->
	{stop, admin_quest, null};

handle_call(_, _From, _LoopData) ->
	{reply, {error, unknown_message}, null}.

%====================================================================================
% handle_cast
%====================================================================================


handle_cast(_Message, _LoopData) ->
	{noreply, null}.
	
handle_info(_Message, _LoopData) ->
	{noreply, null}.

terminate(Reason, _LoopData) ->
	save_all_uid(),
	?INFO(uid_server, "~w terminated, reason:~w", [?MODULE, Reason]),
	ok.

save_all_uid() ->
	save_all_uid(ets:tab2list(uid_count)).

save_all_uid([]) -> ok;
save_all_uid([UidRec | Rest]) ->
	cache_util:update(uid, UidRec),
	save_all_uid(Rest).

%%=================================================================================================
% private functions
%%=================================================================================================


