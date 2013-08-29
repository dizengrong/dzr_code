%%%-------------------------------------------------------------------
%%% @doc
%%%     家族神像模块
%%% @end
%%% Created : 2012-07-05
%%%-------------------------------------------------------------------
-module(mod_map_fml_idol).

-behaviour(gen_server).

-include("mgeem.hrl").

-define(IDOL_OPEN,  ?DEFAULT_UNIQUE, ?FAMILY_IDOL, ?FAMILY_IDOL_OPEN).
-define(IDOL_CLOSE, ?DEFAULT_UNIQUE, ?FAMILY_IDOL, ?FAMILY_IDOL_CLOSE).
-define(IDOL_PRAY,  ?DEFAULT_UNIQUE, ?FAMILY_IDOL, ?FAMILY_IDOL_PRAY).
-define(IDOL_UPDATE,?DEFAULT_UNIQUE, ?FAMILY_IDOL, ?FAMILY_IDOL_UPDATE).

-define(IDOL_ERROR(Msg), ?DEFAULT_UNIQUE, ?FAMILY_IDOL, ?FAMILY_IDOL_ERROR, #m_family_idol_error_toc{mesg = Msg}).

-define(MAX_EXP_ADDITION, 500).
-define(MAX_PRAY_RECORD_COUNT, 20).
-define(ADD_EXP_INTERVAL, 10).


-record(state, {}).

%% API
-export([start/0, start_link/0, handle/1, add_donate_record/2, get_token_times/1, add_donate_token_times/2, add_donate_token_times/3, add_token_times/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start() ->
	supervisor:start_child(mgeem_sup, {?MODULE, {?MODULE, start_link, []}, transient, 30000, worker, [?MODULE]}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
init([]) ->
	random:seed(now()),
	{ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% --------------------------------------------------------------------
% handle_call(get, _From, State) ->
% 	{reply, get(), State};

handle_call({get, Key}, _From, State) ->
	{reply, mod_role_tab:get(Key), State};

handle_call({put, Key, Val}, _From, State) ->
	{reply, mod_role_tab:put(Key, Val), State};

handle_call(_Request, _From, State) ->
	{reply, ignore, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
	{noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% --------------------------------------------------------------------
handle_info(Info, State) ->
	?DO_HANDLE_INFO(Info, State),
	{noreply, State}.

do_handle_info({init, RoleID, Rec}) ->
	mod_role_tab:put({r_role_family_misc, RoleID}, Rec);

do_handle_info({delete, RoleID}) ->
	mod_role_tab:erase({r_role_family_misc, RoleID});

do_handle_info({open, PID, FamilyID, RoleID, RoleLevel}) ->
	add_watcher(FamilyID, RoleID),
	R = #m_family_idol_open_toc{
		pray_times     = get_pray_times(RoleID),
		max_pray_times = get_max_pray_times(RoleID, RoleLevel),
		pray_records   = get_pray_records(FamilyID)
	},
	common_misc:unicast2(PID, ?IDOL_OPEN, R);

do_handle_info({close, FamilyID, RoleID}) ->
	del_watcher(FamilyID, RoleID);


%%2012-12-20增加捐献的数据也要在列表里面显示, 所以加载这个list里面
do_handle_info({pray, FamilyID, PrayRecord}) ->
	add_pray_times(PrayRecord#p_family_pray_rec.role_id),
	add_pray_record(FamilyID, PrayRecord),
	lists:foreach(fun
		(RoleID) ->
		 	R = #m_family_idol_update_toc{pray_record=PrayRecord},
		 	common_misc:unicast({role, RoleID}, ?IDOL_UPDATE, R)
	end, get_watchers(FamilyID));

do_handle_info({donate, FamilyID, PrayRecord}) ->
	add_pray_record(FamilyID, PrayRecord),
	lists:foreach(fun
		(RoleID) ->
		 	R = #m_family_idol_update_toc{pray_record=PrayRecord},
		 	common_misc:unicast({role, RoleID}, ?IDOL_UPDATE, R)
	end, get_watchers(FamilyID));

%%同步令牌
do_handle_info({donate_token, RoleID, Times}) ->
	add_donate_token_times(RoleID, Times).

%% --------------------------------------------------------------------
%% Function: terminate/2
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.


%%%该handle为玩家进程的处理, 非神像进程
handle({_Unique, ?FAMILY_IDOL, ?FAMILY_IDOL_OPEN, _DataIn, RoleID, PID, _Line}) ->
	% #p_map_role{
	% 	family_id = FamilyID, 
	% 	level	  = RoleLevel
	% } = mod_map_actor:get_actor_mapinfo(RoleID, role),
	{ok, #p_role_base{
		family_id = FamilyID
	}} = mod_map_role:get_role_base(RoleID),
	{ok, #p_role_attr{
		level = RoleLevel
	}} = mod_map_role:get_role_attr(RoleID),
	global:send(?MODULE, {open, PID, FamilyID, RoleID, RoleLevel});

handle({_Unique, ?FAMILY_IDOL, ?FAMILY_IDOL_CLOSE, _DataIn, RoleID, _PID, _Line}) ->
	% #p_map_role{
	% 	family_id = FamilyID 
	% } = mod_map_actor:get_actor_mapinfo(RoleID, role),
	{ok, #p_role_base{
		family_id = FamilyID
	}} = mod_map_role:get_role_base(RoleID),
	global:send(?MODULE, {close, FamilyID, RoleID});

handle({_Unique, ?FAMILY_IDOL, ?FAMILY_IDOL_PRAY, DataIn, RoleID, PID, _Line}) ->
	#m_family_idol_pray_tos{type=Type} = DataIn,
	PrayItem = element(Type, hd( common_config_dyn:find(family_party, pray_item) )),
	{PrayType,PrayCost} = element(Type, hd( common_config_dyn:find(family_party, pray_cost) )),
	% #p_map_role{
	% 	family_id = FamilyID, 
	% 	level     = RoleLevel, 
	% 	role_name = RoleName
	% } = mod_map_actor:get_actor_mapinfo(RoleID, role),

	{ok, #p_role_base{
		family_id = FamilyID
	}} = mod_map_role:get_role_base(RoleID),
	{ok, #p_role_attr{
		role_name = RoleName,
		level = RoleLevel
	}} = mod_map_role:get_role_attr(RoleID),

	PrayTimes = get_pray_times(RoleID),
	MaxPrayTimes = get_max_pray_times(RoleID,RoleLevel),
	case PrayTimes >= MaxPrayTimes of
	true ->
		common_misc:unicast2(PID, ?IDOL_ERROR(<<"今日祈福次数已达上限">>));
	false ->
		case common_transaction:t(fun() ->
			pay_by_item_or_gold(RoleID, 
				PrayItem, ?LOG_ITEM_TYPE_LOST_FAMILY_PRAY,
				PrayType, PrayCost, 
				?CONSUME_TYPE_GOLD_FAMILY_PRAY, ?CONSUME_TYPE_SILVER_FAMILY_PRAY)
			end) of
		{atomic, {ok, PayItem, PrayType1, PayGold}} ->
			%% 完成成就
			case Type of
				3 -> %% 高级祭献
					mod_achievement2:achievement_update_event(RoleID, 33006, 1),
					mod_achievement2:achievement_update_event(RoleID, 42005, 1),
					mod_achievement2:achievement_update_event(RoleID, 44002, 1);
				2 -> %% 中级祭献
					mod_achievement2:achievement_update_event(RoleID, 41005, 1);
				_ -> ignore
			end,
			%% 完成活动
			hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_FAMILY_PRAY),
			AddFamilyExp = cfg_family:pray_add_family_exp(Type),
			AddContribute = cfg_family:pray_add_contribute(Type),
			%%add_pray_times(RoleID),
			NewPrayRecord1 = #p_family_pray_rec{
				role_id        = RoleID, 
				role_name      = RoleName, 
				pray_item      = PayItem, 
				pray_cost      = PayGold, 
				pray_time      = common_tool:now(),
				add_family_exp = AddFamilyExp,
				add_contribute = AddContribute
			},
			NewPrayRecord = case PrayType1 of
				silver_any ->
					NewPrayRecord1#p_family_pray_rec{active_type = ?PRAY_TYPE_SILVER};
				gold_any ->
					NewPrayRecord1#p_family_pray_rec{active_type = ?PRAY_TYPE}
			end, 

			R = #m_family_idol_pray_toc{
				pray_times 	   = PrayTimes+1,
				max_pray_times = MaxPrayTimes
			},
			common_misc:unicast2(PID, ?IDOL_PRAY, R),
			send_family_pray_info(FamilyID, RoleID, AddFamilyExp, AddContribute),
			global:send(?MODULE, {pray, FamilyID, NewPrayRecord});

		{_, {error, Msg}} ->
			common_misc:unicast2(PID, ?IDOL_ERROR(Msg));
		{_, {error, ErrorCode, ErrorStr}} ->
			common_misc:send_common_error(RoleID, ErrorCode, ErrorStr);
		_Other ->
			ignore
		end
	end. 

add_donate_record(FamilyID, DonateRecord) ->
	global:send(?MODULE, {donate, FamilyID, DonateRecord}).

%% ====================================================================
%% Internal functions
%% ====================================================================

add_pray_times(RoleID) ->
	FamilyMisc = get_role_family_misc(RoleID),
	mod_role_tab:put({r_role_family_misc, RoleID}, FamilyMisc#r_role_family_misc{
		pray_times = FamilyMisc#r_role_family_misc.pray_times+1, 
		pray_date  = date()
	}).

add_token_times(RoleID, Times) ->
	% global:send(?MODULE, {donate_token, RoleID, Times}),
	add_donate_token_times(RoleID, Times).

%%增加家族令捐献
%%返回次数
add_donate_token_times(RoleID, Times) ->
	FamilyMisc = get_role_family_misc(RoleID),
	add_donate_token_times(RoleID, FamilyMisc, Times).

add_donate_token_times(RoleID, FamilyMisc, Times) ->
	mod_role_tab:put({r_role_family_misc, RoleID}, FamilyMisc#r_role_family_misc{
		donate_token_times = FamilyMisc#r_role_family_misc.donate_token_times+Times, 
		donate_date  = date()
	}), 
	FamilyMisc#r_role_family_misc.donate_token_times+Times.

get_pray_times(RoleID) ->
	#r_role_family_misc{
		pray_times = Times, 
		pray_date  = Date
	} = FamilyMisc = get_role_family_misc(RoleID),
	case Date == date() of
    	true ->
    		Times;
    	false ->
            mod_role_tab:put({r_role_family_misc, RoleID}, FamilyMisc#r_role_family_misc{
                pray_times = 0, 
                pray_date  = date()
            }),
    		0
	end.

%%获得家族令现有次数
get_token_times(RoleID) ->
	#r_role_family_misc{
		donate_token_times = Times, 
		donate_date  = Date
	} = get_role_family_misc(RoleID),
	case Date == date() of
	true ->
		Times;
	false ->
		0
	end.

get_max_pray_times(_RoleID,RoleLevel) ->
	case common_config_dyn:find(family_party, {max_pray_times,RoleLevel}) of
		[MaxTimes] ->
			MaxTimes;
		_ ->
			20
	end.

get_role_family_misc(RoleID) ->
	%mod_role_tab:get({r_role_family_misc, RoleID}, #r_role_family_misc{}).
	case mod_role_tab:get({r_role_family_misc, RoleID}) of
	undefined ->
		#r_role_family_misc{};
	Mount ->
		Mount
	end.
	
get_watchers(FamilyID) ->
	get({watchers, FamilyID}, []).

add_watcher(FamilyID, RoleID) ->
	put({watchers, FamilyID}, [RoleID|lists:delete(RoleID, get_watchers(FamilyID))]).

del_watcher(FamilyID, RoleID) ->
	put({watchers, FamilyID}, lists:delete(RoleID, get_watchers(FamilyID))).

get_pray_records(FamilyID) ->
	get({pray_records, FamilyID}, []).

add_pray_record(FamilyID, Record) ->
	put({pray_records, FamilyID}, lists:sublist([Record|get_pray_records(FamilyID)], ?MAX_PRAY_RECORD_COUNT)).

pay_by_item_or_gold(RoleID, Item, ItemLogType, PrayType, PrayCost, GoldLogType, SilverLogType) ->
	case catch mod_bag:decrease_goods_by_typeid(RoleID, Item, 1) of
	{ok, UpdateList, DelList} ->
        common_misc:update_goods_notify({role,RoleID}, UpdateList++DelList),
		common_item_logger:log(RoleID, Item, 1, true, ItemLogType),
		{ok, Item, 0};
	{bag_error, num_not_enough} ->
		case PrayType of
			gold_any ->
				common_bag2:check_money_enough_and_throw(gold_unbind, PrayCost, RoleID),
				case common_bag2:t_deduct_money(gold_unbind, PrayCost, RoleID, GoldLogType) of
				{ok, NewRoleAttr} ->
					ChangeList = [
						#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
						#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind}],
					common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
					{ok, Item, PrayType, PrayCost};
				_Other ->
				%%因为现在没扣道具了,所以修改提示
					{error, <<"元宝不足">>}
				end;
			silver_any ->
				case common_bag2:t_deduct_money(silver_any, PrayCost, RoleID, SilverLogType) of
				{ok, NewRoleAttr} ->
					ChangeList = [
						#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=NewRoleAttr#p_role_attr.silver},
						#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.silver_bind}],
					common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
					{ok, Item, PrayType, PrayCost};
				_Other ->
				%%因为现在没扣道具了,所以修改提示
					{error, <<"铜钱不足">>}
					% {error, <<"缺少道具或铜钱">>}
				end
		end
	end.

send_family_pray_info(FamilyID, RoleID, AddFamilyExp, AddContribute) ->
	FamilyProcName = common_misc:make_family_process_name(FamilyID),
	catch global:send(FamilyProcName, {family_pray, RoleID, AddFamilyExp, AddContribute}).

get(Key, Default) ->
	case get(Key) of
	undefined -> Default;
	Val -> Val
	end.
