-module(g_charge).
-behaviour(gen_server).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-export([start_link/0,
		 get_account_id/2]).

-include("common.hrl").
-define(UPDATE_TIME, 10).


start_link()->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%10秒钟刷新一次
init([])->
	timer:apply_after(?UPDATE_TIME*1000, gen_server, cast, [self(),{charge}]),
	{ok, null}.

handle_call(_Request, _From, State)->
	Reply = skip,		
	{reply, Reply, State}.

handle_cast({charge}, State)->
	?INFO(g_charge, "select charge indent from sql ,and begain deal them", []),
	SqlCmd = <<"select log_GoldChargelogID, "
			   "log_OutChargeID, "
			   "cfg_PayPlatformID, "
			   "gd_AccountID, "
			   "gd_Account, "
			   "log_Money, "
			   "log_Gold, "
			   "log_ChargeType, "
			   "log_GoldChargeStatus, "
			   "log_ChargeTime, "
			   "log_RecordedTime "
			   "from `gd_GoldChargeLog` "
			   "where log_GoldChargeStatus = 0 "
			   "order by log_GoldChargelogID">>,
	case db_sql:get_all(SqlCmd) of
		[] ->
			?INFO(charge, "no charge indent info to deal", []),
			skip;
		RechargeList when is_list(RechargeList) ->
			ok = charge(RechargeList);
		_ ->
			?INFO(charge, "execute sql wrong", [])
	end,
	timer:apply_after((?UPDATE_TIME)*1000, gen_server, cast, [self(), {charge}]),
	{noreply,State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _Sate)->
	 ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%=======================================internal functions==============================
%%=======================================================================================

charge([])->
	skip;

charge([RechargeInfo|RestRechargeList])->
	%%获取每一条charge indent 的信息
	[GoldChargelogID, _OutChargeID, _PayPlatformID, Account, _Money, Gold1, GoldType, 
		_GoldChargeStatus, _ChargeTime, _RecordedTime, Log_ZoneID] = RechargeInfo, 
	try deal_one_indent(Account, Log_ZoneID, GoldType, Gold1) of
		{AccountID, RoleLevel,State} ->
				SqlCmd = db_sql:make_update_sql('gd_GoldChargeLog', ["gd_AccountID", "log_GoldChargeStatus","log_RecordedTime","gd_RoleLevel"], 
											[AccountID, State,util:unixtime(),RoleLevel], "log_GoldChargelogID", GoldChargelogID),				
				db_sql:execute(SqlCmd)
			catch
				error: _ ->
					UpdSql = db_sql:make_update_sql('gd_GoldChargeLog', ["log_GoldChargeStatus","log_RecordedTime"],
												[2,util:unixtime()], "log_GoldChargelogID", GoldChargelogID),
					db_sql:execute(UpdSql)
	end,
	charge(RestRechargeList).


deal_one_indent(Account, Log_ZoneID, GoldType, Gold1)->
	case get_account_id(Account, Log_ZoneID) of
		{AccountID, RoleLevel} ->
			%%在线与否同样处理
			%%check充值的津贴
			case charge_bonus(AccountID, Gold1) of
				Gold when is_integer(Gold) ->
					case GoldType of
						0 -> %% 金币
							State1 = charge_gold(AccountID, Gold),
							{AccountID, RoleLevel,State1};
						_ ->
							State1 = 2,
							{AccountID, RoleLevel,State1}
					end;
				Other ->
					?ERR(charge, "ErrMsg=~w", [Other]),
					State1 = 2,
					{AccountID, RoleLevel,State1}
			end;
		Other ->
			?ERR(charge, "ErrMsg=~w", [Other]),
			skip
	end.


charge_bonus(AccountID, Gold)->
	%%开服前3天充值,奖励10%
	ok = early_charge(AccountID, Gold),

%%  新的需求是首充给它额外的礼包
	case is_first_charge(AccountID) of
		true->   give_first_charge_bonus(AccountID);
		false -> ok
	end,
	Gold.

early_charge(Id, Gold)->
	RloeRec = mod_role:get_main_role_rec(Id),
	{{Year,Month,Day},_} = calendar:local_time(),
	{Start_Y,Start_M,Start_D} = util:get_app_env(server_first_run),%%修改配置文件
	
	{Launch_days,_} = calendar:time_difference({{Start_Y,Start_M,Start_D},{0,0,0}}, {{Year,Month,Day},{0,0,0}}),
	
%% 	Early_days = data_charge_bonus:get_early_charge_days(),
	Early_days = 3,
	
	if
		Early_days > Launch_days ->
%% 			Bonus_percentage = data_charge_bonus:get_early_charge_percentage(),
			Bonus_percentage = 0.1,
			%%find the user, 
			%%send a sys email to notify
			Extra_gold = round(Gold*Bonus_percentage),

%% 			Content_template = data_charge_bonus:get_early_charge_mail_content_template(),
			Content_template = "根据您本次充值金额,获得~w金币回馈奖励. \n活动时间至~w月~w日, 祝您游戏愉快, 完虐boss",
			End_days = calendar:date_to_gregorian_days(util:get_app_env(server_first_run)) + 3,
			{_E_Year,E_Month,E_day} = calendar:gregorian_days_to_date(End_days),
	
			Content = lists:flatten(io_lib:format(Content_template, [Extra_gold,E_Month,E_day])),


			send_bonus_notice_mail(RloeRec#role.gd_name,
%% 				data_charge_bonus:get_early_charge_mail_title(),
				"开服充值活动",
				Content,
				Extra_gold),
			
			?INFO(charge,"early charge, give ~w bonus",[Bonus_percentage]),
			ok;
		true->
			ok
	end.


give_first_charge_bonus(_AccountID) ->
	%%第一次充值礼包
%% 	FirstChargeRec = #first_charge{gd_accountId = AccountID, gd_awardState = 1},
	%%通知玩家=======
	ok.

send_bonus_notice_mail(Name,Title,Content,Gold)->
	%%通知玩家有礼包消息
	skip.

is_first_charge(AccountID)->
	SqlCmd = io_lib:format("SELECT log_goldchargelogID FROM gd_goldchargelog "
				"WHERE gd_accountid = ~w AND " 
				"log_goldchargestatus = 1 "
				"LIMIT 1",[AccountID]), 

	case db_sql:get_one(SqlCmd) of
		null->
			true;
		Charge_ID when is_integer(Charge_ID)->
			false
	end.


%%充值金币
charge_gold(AccountID, Gold) ->
	%%某些额外的活动会多送充值金额
	mod_economy:add_gold(AccountID, Gold, ?GOLD_CHARGE_MONEY).%%充值类型

	%%要不要记录在数据库


get_account_id(Account, _Log_ZoneID) ->
	%%根据账号从gen_cache中获取Id 和等级Level
	AccountId = mod_account:get_account_id_by_name(Account),
	AccountRec = mod_account:get_account_info_rec(AccountId),
%% 	Level = AccountRec#account.level,
	Level =1,
	{AccountId, Level}.
	

%% 	AccSql = io_lib:format(<<"Select gd_AccountID FROM GD_Account WHERE gd_Account='~s'">>, [Account]),
%% 		case db_sql:get_all(AccSql) of
%% 			[] ->
%% 				skip;
%% 			[[AccountID]] ->
%% 				SgSql = io_lib:format(<<"Select gd_roleLevel FROM gd_role WHERE gd_AccountID=~w">>, [AccountID]),
%% 				[[RoleLevel]] = db_sql:get_all(SgSql),
%% 				{AccountID, RoleLevel};
%% 			_ ->
%% 				?INFO(charge, "execute sql wrong", []),
%% 				skip
%% 		end.


