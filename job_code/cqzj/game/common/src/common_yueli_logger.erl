%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录游戏中的阅历日志，该接口必须是事务内调用
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(common_yueli_logger).

%% API
-export([use_yueli/1,gain_yueli/1]).

-export([on_transaction_begin/0, on_transaction_commit/0, on_transaction_rollback/0]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-define(YUELI_LOG_LIST, yueli_log_list).


%% ====================================================================
%% API Functions
%% ====================================================================

on_transaction_begin() ->
    case erlang:get(?YUELI_LOG_LIST) of
        undefined ->
            erlang:put(?YUELI_LOG_LIST, []);
        _ ->
            %% 防止重复调用这个方法，也能防止这个模块的三个事务接口没有一起调用
            erlang:throw(yueli_log_transaction_error)
    end.

on_transaction_commit() ->
    case erlang:get(?YUELI_LOG_LIST) of
        undefined->
            ignore;
        []->
            ignore;
        Val ->
             global:send(mgeew_yueli_log_server, {yueli_logs, Val})
    end,
    erlang:erase(?YUELI_LOG_LIST),
    ok.

on_transaction_rollback() ->
    erlang:erase(?YUELI_LOG_LIST),
    ok.

%% @doc 使用声望
%% @param RoleID::integer() 玩家ID 
%% @param UseYueli::integer() 花费的声望
%% @param MType::integer() 操作类型, 请使用common.hrl中定义的YUELI_TYPE_**
%% @param MDetail::string() 操作内容 ,可以使用global_lang.hrl中定义的字符串
use_yueli({RoleID, UseYueli, MType, MDetail}) ->
	InitRecord = get_yueli_log(),
	case mod_role_tab:get({?role_attr, RoleID}) of
		undefined ->
			RemYueli = -1,
			RoleName = undefined;
		#p_role_attr{yueli=Yueli,role_name=RoleName} ->
			RemYueli = Yueli - UseYueli
	end,
	Record = InitRecord#r_yueli_log{ role_id=RoleID, user_name=RoleName, use_yueli=UseYueli, rem_yueli=RemYueli, mtype=MType, mdetail=MDetail},
	do_write_record(Record).

%% @doc 获得元宝
%% @param 参数请参考use_gold
gain_yueli({RoleID, UseYueli, MType, MDetail}) ->
    use_yueli({RoleID, get_gain_use(UseYueli), MType, MDetail}).

%% ====================================================================
%% Local Functions
%% ====================================================================
%%@spec do_write_record/1
do_write_record(Record)->
    IsInTransaction = is_in_transaction(),
    if
        IsInTransaction ->
            next;
        true->
            throw(no_yueli_log_transaction)
    end,
	#r_yueli_log{ use_yueli=UseYueli } = Record,
	case UseYueli=:=0 of
		true->
			ignore;
		false->
            common_misc:update_dict_queue(?YUELI_LOG_LIST,Record)
	end.

get_yueli_log()->
    LogTime = common_tool:now(), %% now_seconds
    #r_yueli_log{mtime=LogTime}.

get_gain_use(UseAmount) when (UseAmount>0) ->
	-UseAmount;
get_gain_use(UseAmount) ->
	UseAmount.

is_in_transaction()->
   erlang:get(?YUELI_LOG_LIST) =/= ?YUELI_LOG_LIST.
