%% Author: cjr
%% Created: 2011-10-27
%% Description: 用户行为日志模块

-module(mod_user_log).
%%
%% Include files
%%
-include("common.hrl").

%%
%% Exported Functions
%%
-export([init/1, handle_cast/2,code_change/3,handle_call/3,handle_info/2,terminate/2]).
-behavior(gen_server).

%%
%% API Functions
%%
-export([start_link/0,log_user/3]).
%% 日志记录
		
start_link() ->
	gen_server:start_link({local,?MODULE},?MODULE,[],[]).

log_user(Behavior,Id,Data_list)->
	gen_server:cast(?MODULE, {Behavior,Id,Data_list}).


init([]) ->
	erlang:process_flag(trap_exit, true),
    {ok, []}.

%%
%% Local Functions
%%

handle_cast({economy,ID,Data_list},State) ->
	?INFO(economy,"economy log of data: ~w", [Data_list]),
	[OldEconomyRec,NewEconomyRec,LogType]=Data_list,
	%%银币记录
	if OldEconomyRec#economy.gd_silver /= NewEconomyRec#economy.gd_silver -> 
			Data_list1 = [ID,0,0,OldEconomyRec#economy.gd_silver,NewEconomyRec#economy.gd_silver,LogType,0,0,0],
			gen_server:cast(?MODULE,{silver,ID,Data_list1});
		true ->ok
	end,
	%%金币记录
	if
		(OldEconomyRec#economy.gd_gold /= NewEconomyRec#economy.gd_gold) or (OldEconomyRec#economy.gd_bind_gold /= NewEconomyRec#economy.gd_bind_gold) ->
			Data_list2 = [ID,0,0,OldEconomyRec#economy.gd_gold,NewEconomyRec#economy.gd_gold,LogType,OldEconomyRec#economy.gd_bind_gold,NewEconomyRec#economy.gd_bind_gold,0,0],
			gen_server:cast(?MODULE,{gold,ID,Data_list2});
		true ->ok
	end,
	%%历练记录
	if
		OldEconomyRec#economy.gd_practice /= NewEconomyRec#economy.gd_practice ->
			Data_list3 = [ID,0,OldEconomyRec#economy.gd_practice,NewEconomyRec#economy.gd_practice,LogType],
			gen_server:cast(?MODULE,{log_practice,ID,Data_list3});
		true ->ok
	end,
	%%声望/军威记录
	if
		OldEconomyRec#economy.gd_popularity /= NewEconomyRec#economy.gd_popularity ->
			Data_list4 = [ID,0,OldEconomyRec#economy.gd_popularity,NewEconomyRec#economy.gd_popularity,LogType],
			gen_server:cast(?MODULE,{log_popularity,ID,Data_list4});
		true ->ok
	end,
    %%灵力记录，差数据库表
    if
		OldEconomyRec#economy.gd_lingli /= NewEconomyRec#economy.gd_lingli ->
			Data_list5 = [ID,0,OldEconomyRec#economy.gd_lingli,NewEconomyRec#economy.gd_lingli,LogType],
			gen_server:cast(?MODULE,{log_lingli,ID,Data_list5});
		true ->ok
	end,
    {noreply,State};







handle_cast({Behavior,Id,Data_list},State)->
	case Behavior of
		silver ->
			%% silver data [holy_level,alter_silver,old_silver,new_silver,type,NewBindSilver, Old2Silver, New2Silver]
			?INFO(user_log, "silver log of data: ~w", [Data_list]),
			Sql = db_sql:make_insert_sql('Log_Silver',
					["gd_AccountID","log_HolyLevel","log_AlterSilver","log_OldSilver",
					 "log_NewSilver","log_Type",
					 "log_NewBindSilver", "log_Old2Silver", "log_New2Silver"],
					Data_list);
		gold ->
			%% gold data [Holy_level,Alter_gold,TotalOldGold,Type,OldBindGold, NewBindGold, OldGold, NewGlod]
			?INFO(user_log, "gold log of data: ~w", [Data_list]),
			Sql = db_sql:make_insert_sql('Log_Gold',
					["gd_AccountID","log_HolyLevel","log_AlterGold","log_OldGold","log_Type",
					 "log_OldBindGold", "log_NewBindGold", "log_Old2Gold", "log_NewGold"],
					Data_list);
%% 		log_mer_foster -> %% 佣兵培养log
%% 			Sql = log_mer_foster(Id, Data_list);
		log_mer_train -> %% 佣兵训练log
			Sql = log_mer_train(Id, Data_list);
		log_speed_up -> %% 佣兵突飞log
			Sql = log_speed_up(Id, Data_list);
		log_dungeon -> %% 副本进入和离开的log
			Sql = log_dungeon(Id, Data_list);
		log_exp -> %% 记录经验的log
			Sql = log_exp(Id, Data_list);
		log_employ -> %% 记录招募、解雇的log
			Sql = log_employ(Id, Data_list);
		log_item_rise ->
			Sql = log_item_rise(Id, Data_list);
		log_item ->
			Sql = log_item(Id, Data_list);
		log_holy ->
			Sql = log_holy(Id, Data_list);
		log_clear_cd ->
			Sql = log_clear_cd(Id, Data_list);
		log_loginlog ->
			Sql = log_loginlog(Id, Data_list);
		log_create_role ->
			Sql = log_create_role(Id, Data_list);
		log_account_access ->
			Sql = log_account_access(Id, Data_list);
		log_visitor2player ->
			Sql = log_visitor2player(Id, Data_list);
		log_achieve ->
			Sql = log_achieve(Id, Data_list);
		log_pet_lv ->
			Sql = log_pet_lv(Id, Data_list);
		log_pet_using ->
			Sql = log_pet_using(Id, Data_list);
		log_item_change ->
			Sql = log_item_change(Data_list);
		log_garden ->
			Sql = log_garden(Id, Data_list);
		log_trade ->
			Sql = log_trade(Id, Data_list);
		log_guild_salary ->
			Sql = log_guild_salary(Id, Data_list);
		log_task ->
			Sql = log_task(Id, Data_list);

		log_refresh_gem ->
			Sql = log_refresh_gem(Id, Data_list);
		log_commit_task ->
			Sql = log_commit_task(Id, Data_list);
		log_grab_info ->
			Sql = log_grab_info(Id, Data_list);
		log_add_counter->
			Sql = log_add_counter(Id, Data_list);
		log_energy ->
			Sql = log_energy(Id, Data_list);
		log_alchemy ->
			Sql = log_alchemy(Id, Data_list);
		log_online_award ->
			Sql = log_online_award(Id, Data_list);
		log_login_award ->
			Sql = log_login_award(Id, Data_list);
		log_dragon_hunt ->
			Sql = log_dragon_hunt(Id, Data_list);
		log_tower ->
			Sql = log_tower(Id, Data_list); 
		log_practice ->
			Sql = log_practice(Id, Data_list);
		log_popularity ->
			Sql = log_popularity(Id, Data_list);
		log_lingli ->
			Sql = log_lingli(Id,Data_list);
		_->
			Sql = ""
	end,
	if 
		Sql == "" ->
			?ERR(user_log,"unknown user log request",[]);
		true ->
			db_sql:execute(?USER_LOG_DB,Sql)
	end,
	{noreply, State}.


code_change(_OldVsn,State,_Extra)->
	error_logger:warning_msg("code changed ~w~w", [?MODULE,?LINE]),
	{ok, State}.

handle_call(_Message,_From,LoopData) ->
	{reply, ok, LoopData}.

handle_info({'EXIT', _, Reason}, State) ->
    ?INFO(terminate,"exit:~w", [Reason]),
    {stop, Reason, State}.

terminate(_Reason,_State) ->
	ok.

%% log_mer_foster(Id, Data_list) -> 
%% 	[HolyLevel, MerId, MerLevel, Reincarnation, FosterType, OldAttri, NewAttri, Type, PF] = Data_list,
%% 	?INFO(log, "log mercenary foster for player ~w's mer ~w", [Id, MerId]),
%% 	MerMode = data_mercenary:get(MerId),
%% 	[OldAttri1, OldAttri2, OldAttri3] = if
%% 		MerMode#mercenary.gd_careerID == ?CAREER_FIGHTER orelse MerMode#mercenary.gd_careerID == ?CAREER_MILITANT ->
%% 			[Strong, _, Constitution, Accurate] = OldAttri,
%% 			[Strong, Constitution, Accurate];
%% 		true ->
%% 			[_, Intelligence, Constitution, Accurate] = OldAttri,
%% 			[Intelligence, Constitution, Accurate]
%% 	end,
%% 	[NewAttri1, NewAttri2, NewAttri3] = if
%% 		MerMode#mercenary.gd_careerID == ?CAREER_FIGHTER orelse MerMode#mercenary.gd_careerID == ?CAREER_MILITANT ->
%% 			[P1, _P2, P3, P4] = PF,
%% 			PF1 = [P1, P3, P4],
%% 			[Strong1, _, Constitution1, Accurate1] = NewAttri,
%% 			[Strong1, Constitution1, Accurate1];
%% 		true ->
%% 			[_P1, P2, P3, P4] = PF,
%% 			PF1 = [P2, P3, P4],
%% 			[_, Intelligence1, Constitution1, Accurate1] = NewAttri,
%% 			[Intelligence1, Constitution1, Accurate1]
%% 	end,
%% 	Sql = io_lib:format(<<"insert into `log_foster` "
%% 						  "(gd_AccountID, "
%% 						  "log_HolyLevel, "
%% 						  "log_RoleID, "
%% 						  "log_RoleLevel, "
%% 						  "log_ReriseCount, "
%% 						  "log_FosterType, "
%% 						  "log_OldAttribute1, "
%% 						  "log_OldAttribute2, "
%% 						  "log_OldAttribute3, "
%% 						  "log_NewAttribute1, "
%% 						  "log_NewAttribute2, "
%% 						  "log_NewAttribute3, "
%% 						  "log_type, "
%% 						  "log_protectFlag) "
%% 						  "values "
%% 					     "(~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, '~w' )">>,
%% 				  		[Id, HolyLevel, MerId, MerLevel, Reincarnation, FosterType,
%% 						 OldAttri1, OldAttri2, OldAttri3, NewAttri1, NewAttri2, NewAttri3, Type, PF1]),
%% 	Sql.

log_mer_train(Id, Data_list) ->
	[MerId, MerLevel, Reincarnation, TimeMode, TrainMode, Operation, HolyLevel, Holy5Level, _] = Data_list,
	?INFO(log, "log mercenary train for player ~w's mer ~w", [Id, MerId]),
	Sql = io_lib:format(<<"insert into `log_train` "
						  "(gd_AccountID, "
						  "gd_RoldID, "
						  "gd_RoleLevel, "
						  "gd_ReriseNum, "
						  "cfg_TrainType, "
						  "cfg_TrainModel, "
						  "log_Type, "
						  "gd_LifeCrysLv, "
						  "gd_FireCrysLv, "
						  "gd_YanCrysLv) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w)">>, 
						[Id, MerId, MerLevel, Reincarnation, TimeMode, TrainMode, Operation, HolyLevel, Holy5Level, 0]),
	Sql.

log_speed_up(Id, Data_list) ->
	%[MerId, MerLevel, Reincarnation, Type, HolyLevel, Holy5Level, _] = Data_list,
	?INFO(log, "log player ~w's speed up: ~w", [Id, Data_list]),
	Sql = io_lib:format(<<"insert into `log_speed` "
						  "(gd_AccountID, "
						  "gd_RoldID, "
						  "gd_RoleLevel, "
						  "gd_ReriseNum, "
						  "cfg_SpeedType, "
						  "gd_LifeCrysLv, "
						  "gd_FireCrysLv, "
						  "gd_YanCrysLv) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_dungeon(Id, Data_list) ->
	%[HolyLevel, TeamState, Action, ProcessId, IsFinished] = Data_list,
	?INFO(log, "log player ~w's dungeon log: ~w", [Id, Data_list]),
	Sql = io_lib:format(<<"insert into `log_dungeon` "
						  "(gd_AccountId, "
						  "log_HolyLevel, "
						  "log_TeamState, "
						  "log_Action, "
						  "log_ProcessId, "
						  "log_IsFinished) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_exp(Id, Data_list) ->
	%[HolyLevel, MerId, AddExp, TotalExp, Type] = Data_list,
	?INFO(log, "log_exp: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `log_exp` "
						  "(gd_AccountID, "
						  "log_CrystalLevel, "
						  "gd_RoleID, "
						  "log_exp, "
						  "log_TotalExp, "
						  "log_type) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_employ(Id, Data_list) ->
	%[RecruitRank, MerId, CrystalLevel, RoleLevel, Type] = Data_list,
	?INFO(log, "log_employ: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `log_recruit` "
						  "(gd_AccountID, "
						  "log_RecruitRank, "
						  "log_RoleID, "
						  "log_CrystalLevel, "
						  "log_RoleLevel) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_item_rise(Id, Data_list) ->
	?INFO(log, "log_item_rise: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `LOG_ItemRiseLog` "
						  "(gd_AccountID, "
						  "log_CrystalLevel, "
						  "gd_WorldItemID, "
						  "cfg_ItemId, "
						  "log_OperType, "
						  "log_Change, "
						  "log_NewLv) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_item(Id, Data_list) ->
	?INFO(log, "log_item: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `LOG_ItemLog` "
						  "(gd_AccountID, "
						  "gd_WorldItemID, "
						  "cfg_ItemId, "
						  "log_OperType, "
						  "log_Change, "
						  "log_NewStack, "
						  "cfg_BagType, "
						  "cfg_BagPos, "
						  "gd_RiseLv, "
						  "log_SrcDel) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w, '~s')">>, 
						[Id | Data_list]),
	Sql.

log_holy(Id, Data_list) ->
	?INFO(log, "log_holy: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `Log_Crystal` "
						  "(gd_AccountID, "
						  "log_LifeCryslv, "
						  "log_CrystallID, "
						  "log_CrystallLevel, "
						  "log_UseTime) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_clear_cd(Id, Data_list) ->
	?INFO(log, "log_clear_cd: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `Log_ClearCD` "
						  "(gd_AccountID, "
						  "log_CurCrstlLev, "
						  "log_CDType, "
						  "log_UesGold, "
						  "log_ClearTime) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_loginlog(Id, Data_list) ->
	?INFO(log, "log_loginlog: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `log_loginlog` "
						  "(gd_AccountID, "
						  "gd_Account, "
						  "log_LoginIP, "
						  "log_LoginTime) "
						  "values "
					     "(~w,'~s', '~s', ~w)">>, 
						[Id | Data_list]),
	Sql.

log_create_role(Id, Data_list) ->
	?INFO(log, "log_create_role: ~w", [[Id | Data_list]]),
	Sql = db_sql:make_insert_sql("LOG_AccountCreateLog", 
								 ["gd_AccountId", "gd_Account", "gd_RoleName", 
								  "cfg_MercenaryId", "log_IP"], 
								 [Id | Data_list]),
	Sql.

log_account_access(Id, Data_list) ->
	?INFO(log, "log_account_access: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `LOG_AccountAccess` "
						  "(log_Type, "
						  "gd_Account, "
						  "log_AccessIP, "
						  "gd_AccountRank) "
						  "values "
					     "(~w,'~s', '~s', ~w)">>, 
						Data_list),
	Sql.

log_visitor2player(Id, Data_list) ->
	?INFO(log, "log_visitor2player: ~w", [[Id | Data_list]]),
	Sql = db_sql:make_insert_sql("log_visitorcreater", 
								 ["gd_AccountId", "gd_Account", "gd_RoleName", "log_IP"], 
								 [Id | Data_list]),
	Sql.

log_achieve(Id, Data_list) ->
	?INFO(log, "log_achieve: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `log_Achv` "
						  "(gd_AccountId, "
						  "gd_crystalLv, "
						  "gd_Achvid) "
						  "values "
					     "(~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_pet_lv(Id, Data_list) ->
	?INFO(log, "log_pet_lv: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `log_PetLevel` "
						  "(gd_AccountId, "
						  "log_petLevel) "
						  "values "
					     "(~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_pet_using(Id, Data_list) ->
	?INFO(log, "log_pet_using: ~w", [[Id | Data_list]]),
	Sql = io_lib:format(<<"insert into `log_petuse` "
						  "(gd_AccountId, "
						  "gd_holylevel, "
						  "gd_petlevel, "
						  "gd_type) "
						  "values "
					     "(~w, ~w, ~w, ~w)">>, 
						[Id | Data_list]),
	Sql.

log_item_change(Data_list) ->
	?INFO(log, "log_item_change: ~w", [Data_list]),
	Sql = io_lib:format(<<"insert into `log_ItemChange` "
						  "(gd_NewWorldItemID, "
						  "gd_OldWorldItemID, "
						  "gd_NewAccountID, "
						  "gd_OldAccountID, "
						  "log_OperType, "
						  "log_SrcDel) "
						  "values "
					     "(~w, ~w, ~w, ~w, ~w, ~w)">>, 
						Data_list),
	Sql.

log_garden(ID, DataList) ->
	?INFO(log, "log_garden: ID=~w, DataList=~w", [ID, DataList]),
	SQL = io_lib:format("INSERT INTO `log_gardenop` "
						"  (gd_AccountID, log_GuestID, gd_FieldID, log_Operation, log_OpResult, log_Loot) "
						"VALUES"
						"  (~w, ~w, ~w, ~w, ~w, '~w');", 
						[ID | DataList]),
	SQL.

log_trade(TradeCode, DataList) ->
	?INFO(log, "log_trade: ID=~w, DataList=~w", [TradeCode, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_trade` "
						  "(gd_TradeCode, "
						  "gd_AccountID1, "
						  "gd_AccountID2, "
						  "gd_Gold1, "
						  "gd_Gold2, "
						  "gd_ItemList1, "
						  "gd_ItemList2) "
						  "values "
						  "(~w, ~w, ~w, ~w, ~w, ~w, ~w)">>,
						  [TradeCode | DataList]),
	SQL.

log_guild_salary(ID, DataList) ->
	?INFO(log, "log_guild_salary: ID=~w, DataList=~w", [ID, DataList]),
	SQL = io_lib:format("INSERT INTO `log_guildsalary` "
						"  (gd_AccountID, log_SalaryTimes, log_Silver, log_Practice, log_BindGold) "
						"VALUES "
						"  (~w, ~w, ~w, ~w, ~w);", 
						[ID | DataList]),
	SQL.

log_task(ID, DataList) ->
	?INFO(log, "log_task: ID=~w, DataList=~w", [ID, DataList]),
	SQL = io_lib:format("INSERT INTO `log_tasks` "
						"  (gd_AccountID, cfg_TaskID, cfg_TaskTypeID, log_Op, log_Tips) "
						"VALUES "
						"  (~w, ~w, ~w, ~w, '~w');", 
						[ID | DataList]),
	SQL.

log_refresh_gem(ID, DataList) ->
	?INFO(log, "log refresh gem: ID = ~w, DataList = ~w", [ID, DataList]),
	Sql = io_lib:format(
			"INSERT INTO `log_rbrefresh` "
			"(gd_AccountID, log_Gold, log_OldType, log_NewType) "
			"VALUES (~w, ~w, ~w, ~w);", [ID | DataList]),
	Sql.

log_commit_task(ID, DataList) ->
	Sql = io_lib:format(
			"INSERT INTO `log_rbcommit` "
			"(gd_AccountID, log_Type, log_Silver) "
			"VALUES (~w, ~w, ~w);", [ID | DataList]),
	Sql.

log_grab_info(ID, DataList) ->
	Sql = io_lib:format(
			"INSERT INTO `log_rbgrab` "
			"(gd_AccountID, log_AccountID, log_Silver) "
			"VALUES (~w, ~w, ~w);", [ID | DataList]),
	Sql.

log_energy(Id, DataList) ->
	Sql = io_lib:format(
			"INSERT INTO `log_energy` "
			"(gd_AccountID, log_CrystalLevel, log_AlterEnergy, log_OldEnergy, log_Type, log_lastTime) "
			"VALUES (~w, ~w, ~w, ~w, ~w, ~w);", [Id | DataList]),
	Sql.

%% create table LOG_Counter
%% (
%%    log_type             varchar(50)
%%                          not null comment '[arena,arena_brought]',
%%    gd_AccountId         int not null,
%%    log_CounterModifyType smallint not null,
%%    log_CounterModifyNumber smallint not null,
%%    log_Time             timestamp not null default CURRENT_TIMESTAMP
%% );

log_add_counter(Id, Data_list)->
	{Type,N} = Data_list,
	Sql = io_lib:format(
			"INSERT INTO `LOG_Counter` "
			"(log_type, gd_AccountId, log_CounterModifyType,log_CounterModifyNumber) "
			"VALUES (~w, ~w, ~w,~w);", [Type,Id,1,N]
		),
	Sql.

log_alchemy(Id, DataList) ->
	?INFO(log, "log_trade: ID=~w, DataList=~w", [Id, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_alchemy` "
						  "(gd_AccountID, "
						  "log_Type, "
						  "log_OldLevel, "
						  "log_NewLevel, "
						  "log_FreeTimes, "
						  "log_Silver, "
						  "log_Gold, "
						  "log_CfgItemID) "
						  "values "
						  "(~w, ~w, ~w, ~w, ~w, ~w, ~w, ~w)">>,
						  [Id | DataList]),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.

log_online_award(Id, DataList) ->
	?INFO(log, "log_trade: ID=~w, DataList=~w", [Id, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_olaward` "
						  "(gd_AccountID, "
						  "log_Times, "
						  "log_Index) "
						  "values "
						  "(~w, ~w, ~w)">>,
						  [Id | DataList]),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.

log_login_award(Id, DataList) ->
	?INFO(log, "log_trade: ID=~w, DataList=~w", [Id, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_loginaward` "
						  "(gd_AccountID, "
						  "log_Index, "
						  "log_Days, "
						  "log_CfgItemID) "
						  "values "
						  "(~w, ~w, ~w, ~w)">>,
						  [Id | DataList]),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.

log_dragon_hunt(ID, DataList) ->
	?INFO(log, "log_dragon_hunt: ID=~w, DataList=~w", [ID, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_dragonhunt` "
						  "(gd_AccountID, log_Times, log_GoldCost, log_PrizeList) "
						  "VALUES (~w, ~w, ~w, '~w');">>, 
						[ID | DataList]),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.

log_tower(Id, DataList) ->
	?INFO(log, "log_tower: ID=~w, DataList=~w", [Id, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_tower` "
						  "(gd_AccountID, "
						  "log_holyLevel, "
						  "log_maxlayer, "
						  "log_curlayer, "
						  "log_type) "
						  "values "
						  "(~w, ~w, ~w, ~w, ~w)">>,
						  [Id | DataList]),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.	

log_practice(Id, DataList) ->
	?INFO(log, "log_practice: ID=~w, DataList=~w", [Id, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_practice` "
						  "(gd_AccountID, "
						  "log_CrystalLevel, "
						  "log_old_practice, "
						  "log_alter_practice, "
						  "log_type) "
						  "values "
						  "(~w, ~w, ~w, ~w, ~w)">>,
						  DataList),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.

log_popularity(Id, DataList) ->
	?INFO(log, "log_popularity: ID=~w, DataList=~w", [Id, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_popularity` "
						  "(gd_AccountID, "
						  "log_CrystalLevel, "
						  "log_old_popularity, "
						  "log_alter_popularity, "
						  "log_type) "
						  "values "
						  "(~w, ~w, ~w, ~w, ~w)">>,
						  DataList),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.

log_lingli(Id,DataList) ->
	?INFO(log, "log_lingli: ID=~w, DataList=~w", [Id, DataList]),
	SQL = io_lib:format(<<"INSERT INTO `log_lingli` "
						  "(gd_AccountID, "
						  "log_CrystalLevel, "
						  "log_old_lingli, "
						  "log_alter_lingli, "
						  "log_type) "
						  "values "
						  "(~w, ~w, ~w, ~w, ~w)">>,
						  DataList),
	?INFO(log, "Sqlcmd: ~s", [SQL]),
	SQL.
