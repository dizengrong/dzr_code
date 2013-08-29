%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录游戏中的声望日志，该接口必须是事务内调用
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(common_prestige_logger).

%% API
-export([use_prestige/1,gain_prestige/1]).

-export([on_transaction_begin/0, on_transaction_commit/0, on_transaction_rollback/0]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-define(PRESTIGE_LOG_LIST, prestige_log_list).


%% ====================================================================
%% API Functions
%% ====================================================================

on_transaction_begin() ->
    case erlang:get(?PRESTIGE_LOG_LIST) of
        undefined ->
            erlang:put(?PRESTIGE_LOG_LIST, []);
        _ ->
            %% 防止重复调用这个方法，也能防止这个模块的三个事务接口没有一起调用
            erlang:throw(prestige_log_transaction_error)
    end.

on_transaction_commit() ->
    case erlang:get(?PRESTIGE_LOG_LIST) of
        undefined->
            ignore;
        []->
            ignore;
        Val ->
             global:send(mgeew_prestige_log_server, {prestige_logs, Val})
    end,
    erlang:erase(?PRESTIGE_LOG_LIST),
    ok.

on_transaction_rollback() ->
    erlang:erase(?PRESTIGE_LOG_LIST),
    ok.

%% @doc 使用声望
%% @param RoleID::integer() 玩家ID 
%% @param UsePrestige::integer() 花费的声望
%% @param MType::integer() 操作类型, 请使用common.hrl中定义的PRESTIGE_TYPE_**
%% @param MDetail::string() 操作内容 ,可以使用global_lang.hrl中定义的字符串
use_prestige({RoleID, UsePrestige, MType, MDetail}) ->
	InitRecord = get_prestige_log(),
	case mod_role_tab:get({?role_attr, RoleID}) of
		undefined ->
			RemPrestige = -1,
			RoleName = undefined;
		#p_role_attr{cur_prestige=Prestige,role_name=RoleName} ->
			RemPrestige = Prestige - UsePrestige
	end,
	Record = InitRecord#r_prestige_log{ role_id=RoleID, user_name=RoleName, use_prestige=UsePrestige, rem_prestige=RemPrestige, mtype=MType, mdetail=MDetail},
	do_write_record(Record).

%% @doc 获得元宝
%% @param 参数请参考use_gold
gain_prestige({RoleID, UsePrestige, MType, MDetail}) ->
    use_prestige({RoleID, get_gain_use(UsePrestige), MType, MDetail}).

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
            throw(no_prestige_log_transaction)
    end,
	#r_prestige_log{ use_prestige=UsePrestige } = Record,
	case UsePrestige=:=0 of
		true->
			ignore;
		false->
            common_misc:update_dict_queue(?PRESTIGE_LOG_LIST,Record)
	end.

get_prestige_log()->
    LogTime = common_tool:now(), %% now_seconds
    #r_prestige_log{mtime=LogTime}.

get_gain_use(UseAmount) when (UseAmount>0) ->
	-UseAmount;
get_gain_use(UseAmount) ->
	UseAmount.

is_in_transaction()->
   erlang:get(?PRESTIGE_LOG_LIST) =/= ?PRESTIGE_LOG_LIST.

