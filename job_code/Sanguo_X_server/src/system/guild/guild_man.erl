%% guild manager

-module(guild_man).
-behaviour(gen_server).

-include("common.hrl").
-define(GUILD_DONATE_GOLD, 0).
-define(GUILD_DONATE_SILVER, 1).

-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).
-export(
   [
		apply_join_guild/5, 
		buy_items/2, 
		cancel_dismiss_guild/2,
		change_manifesto/3, 
		create_guild/5, 
		designate_rank/4, 
		delete_all_member/1,
		dismiss_guild/2, 
		donate/4,
		fire_member/3, 
		get_guild_name/1, 
		get_guild_member_num/1, 
		get_guild_welfare/3,
		get_next_guild_id/0, 
		join_guild/4, 
		login/1, 
		logout/1,
		quit_guild/2,
		transfer_president/3 
   ]).


start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []). 

init([]) ->
	init_ets(),
	NextGuildID = get_next_guild_id(),
	{ok, #guild_state {next_id = NextGuildID}}.

init_ets() ->
	%% ets:new(?ETS_GUILD_NAME,  [set, public, named_table]),
	ets:new(?ETS_GUILD_APPLY, [set, public, named_table, {keypos, #guild_apply.id}]),
	ets:new(?ETS_GUILD_CD,    [set, public, named_table, {keypos, #guild_cd.id}]).
	
%% create a new guild
handle_cast({create_guild, ID, Name, GuildName, Manifesto, Type}, 
	State = #guild_state {next_id = NID}) ->
	IsMember = 
		case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
			[] -> false;
			_  -> true
		end,
	IsNameExist = 
		case ets:match(?ETS_GUILD_INFO, #guild_info {guild_name = GuildName, _ = '_'}) of
			[] -> false;
			_  -> true
		end,
	
	?INFO(guild_man, "create guild..."),
	if  (IsMember == true) -> 
			Success = false,
			?INFO(guild_man, "Player ~w is already in a guild", [ID]);
			
		(IsNameExist == true) ->
			{ok, ErrBin} = pt_err:write(19001),
			Success = {false, ErrBin},
			?INFO(guild_man, "GuildName ~s is already exist", [GuildName]);
			
		true -> 
			IsPayMoney = 
				case Type of
					0 -> consume_money(ID, Type, 100); %% 100 gold or 150000 silver to create 
					_ -> consume_money(ID, Type, 150000)
				end,
			
			if (IsPayMoney == false) ->
				Success = false,
				?INFO(guild_man, "not enough money to create a guild");
			   
			true ->					
				%% Insert GuildInfo => Guild_Info Table
				Success = true,
				Now = util:unixtime(),
				Guild =
					#guild_info {
						guild_id       = NID,
						guild_name     = GuildName,
						level          = 1,
						manifesto      = Manifesto,
						creator        = ID,
						create_time    = Now,
						president      = ID,
						president_name = Name,
						members        = [ID],
						max_member     = 20,
						exp            = 0,
						event          = guild_event:create_event_tab(),
						apply_list     = []
					},
				
				%% Reverse Index Table
				GuildMember = 
					#guild_member {
						id           = ID,
						name         = Name,
						guild_id     = NID,
						rank         = ?GUILD_PRESIDENT,
						donate_time  = 0,
						join_time    = Now,
						exp          = 0,
						total_exp    = 0,
						welfare_time = 0
					},
				
				gen_cache:insert(?CACHE_GUILD_INFO, Guild),
				gen_cache:insert(?CACHE_GUILD_MEM, GuildMember),
					
				lib_send:send(ID, pt_19:write(19000, NID)),
				lib_send:send(ID, pt_19:write(19100, Guild)),

				?Catch(guild:set_guild_id(ID, NID))
			end
	end,
	
	case Success of
		true ->
			%% 成就通知
			catch mod_achieve:joinGankNotify(ID,1),
			{noreply, State#guild_state {next_id = NID + 1}};
		false ->
			{noreply, State};
		{false, ErrCode} -> 
			catch lib_send:send(ID, ErrCode), {noreply, State}
	end;

%% apply / cancel apply for joining a guild, 
%% add / remove the application in the join list
handle_cast({apply_join_guild, AppID, Name, SortType, Page, GuildID}, State) ->
	?INFO(guild_man, "apply_join_guild.. AppID = ~w, Name = ~w, GuildID = ~w", [AppID, Name, GuildID]),
	
	case gen_cache:lookup(?CACHE_GUILD_MEM, AppID) of
		[] ->
			case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
				[#guild_info {max_member = MaxMem, members = MemList, apply_list = AppList}] ->
					IsApplied = 
						case lists:keysearch(AppID, 1, AppList) of
							false -> false;
							_  -> true
						end,
					
					?INFO(guild_man, "join_guild..."),
					
					%% if this player has not apply, we append his ID to the list
					%% otherwise remove his ID from the list
					case length(MemList) < MaxMem andalso not IsApplied of
						true ->
							Now = util:unixtime(),
							case ets:lookup(?ETS_GUILD_APPLY, AppID) of
								[] -> %% this player has not applied joining any guild
 									Apply = 
										#guild_apply {
											id         = AppID,
											name       = Name, 
											apply_list = [{GuildID, Now}]
										},
									ets:insert(?ETS_GUILD_APPLY, Apply),
									gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
										{#guild_info.apply_list, [{AppID, Now} | AppList]});
								
								[#guild_apply {apply_list = List}] ->
									if (length(List) >= 20) ->
										?INFO(guild, "can not apply more... apply list is full"),
										ok; %% can not apply more 
									true ->
										gen_cache:update_element(?CACHE_GUILD_INFO, GuildID,
											{#guild_info.apply_list, [{AppID, Now} | AppList]}),
										ets:update_element(?ETS_GUILD_APPLY, AppID, 
											{#guild_apply.apply_list, [{GuildID, Now} | List]})
									end
							end;
						false -> 
							if (IsApplied == true) ->
								case ets:lookup(?ETS_GUILD_APPLY, AppID) of
									[] -> ok;
									[#guild_apply {apply_list = List}] ->
										if (length(List) == 0) ->
											ets:delete_object(?ETS_GUILD_APPLY, AppID);
										true ->
											ets:update_element(?ETS_GUILD_APPLY, AppID, 
												{#guild_apply.apply_list, lists:keydelete(GuildID, 1, List)})
										end
								end,
								gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
									{#guild_info.apply_list, lists:keydelete(AppID, 1, AppList)});
							true ->
								ok
							end
					end;
				_ -> 
					?INFO(guild_man, "Guild ~w is not exist", [GuildID]), ok	
			end;
		_  ->
			?INFO(guild_man, "Player ~w is already in a guild", [AppID]),
			ok %% already in a guild
	end,
	guild:get_guild_list(AppID, "", SortType, Page),
	{noreply, State};

%% join a guild, the player must not be in any guild
%% the guild must be exist
handle_cast({join_guild, AppID, IsApproved, OfficerID, GuildID}, State) ->
	?INFO(guild_man, "handling join_guild"),

	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		%% AppList = [{ID, AppTime}]
		[#guild_info {max_member = MaxMem, members = MemList, apply_list = AppList, event = EvtTab}] ->
			
			IsApplied = lists:member(AppID, AppList),
			%% whether approved or not, we must delete this AppID from the AppList
			%% means we have known this event.
			gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
				{#guild_info.apply_list, lists:keydelete(AppID, 1, AppList)}),
			
			case ets:lookup(?ETS_GUILD_APPLY, AppID) of
				[] -> ok; 
				%% first check this record, ... if the record is not exist
				%% it means that the play has not applied. or $he/she may join in some guild then quit the guild$
				%% and we need not handle this application
				[Apply = #guild_apply {apply_list = GAppList}] ->
					case (IsApproved == true) andalso (gen_cache:lookup(?CACHE_GUILD_MEM, AppID) == []) of
					true ->
						case length(MemList) >= MaxMem orelse not IsApplied of
						true  -> ok; %% can not add more member or not in apply list
						false ->
							%% the player is not in any guild, 
							%% so .. the GuildApply record must not be []
							Now = util:unixtime(),
							
							GuildMem = 
								#guild_member {
									id           = AppID,
									name         = Apply#guild_apply.name, 
									guild_id     = GuildID,
									rank         = ?GUILD_MEMBER,
									donate_time  = 0,
									join_time    = Now,
									exp          = 0,
									total_exp    = 0,
									welfare_time = 0
								},
							Event = 
								#guild_event {type = 1, time = Now, content = {AppID, Apply#guild_apply.name}},
							
							%% update member table
							gen_cache:insert(?CACHE_GUILD_MEM, GuildMem),
							%% update guild table
							gen_cache:update_element(?CACHE_GUILD_INFO, GuildID,
								[{#guild_info.members, [AppID | MemList]}, 
								 {#guild_info.event, guild_event:add_event(EvtTab, Event)}]),
							ets:delete(?ETS_GUILD_APPLY, AppID),
							catch guild:set_guild_id(AppID, GuildID)
						end;
					false ->
						%% already in the other guild or not approved
						%% just delete the applied record.
						ets:update_element(?ETS_GUILD_APPLY, AppID, 
							{#guild_apply.apply_list, lists:keydelete(GuildID, 1, GAppList)})
					end
			end;
		[] -> ok %% the guild is not exist
	end,
	guild:get_guild_apply_list(OfficerID, 1),
	{noreply, State};


%% quit the guild
handle_cast({quit_guild, ID, GuildID}, State) ->
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[#guild_member {guild_id = GuildID, rank = Rank}] ->
			if (Rank == ?GUILD_PRESIDENT) ->
				?INFO(guild_man, "president can not quit guild"),
				ok; %% can not simply, quit the guild, must transfer 
			true ->		
				[Info] = gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
				MemList = Info#guild_info.members,
				
				gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, {#guild_info.members, lists:delete(ID, MemList)}),
				?INFO(guild, "gen_cache:delete... ID = ~w", [ID]),
				gen_cache:delete(?CACHE_GUILD_MEM, #guild_item {id = ID}),
				guild:set_guild_id(ID, 0)
			end;
		_ ->
			ok
	end,
	{noreply, State};

handle_cast({designate_rank, IDFrom, IDTo, Rank, GuildID}, State) ->
	case is_in_same_guild(IDFrom, IDTo) of
		{true, GuildID} ->
			[MemFrom] = gen_cache:lookup(?CACHE_GUILD_MEM, IDFrom),
			[MemTo]   = gen_cache:lookup(?CACHE_GUILD_MEM, IDTo),
			
			%% check (1) IDFrom's rank is higher than To's rank
			%% (2) IDFrom's rank is is not lower than Rank
			%% (3) IDTo's rank is lower than Rank
			if (MemFrom#guild_member.rank >= MemTo#guild_member.rank) ->
				?ERR(guild_man, "IDFrom ~w 's rank must higher than IDTo ~w 's rank", [IDFrom, IDTo]);
			   (MemFrom#guild_member.rank >= Rank) ->
				?ERR(guild_man, "IDFrom ~w 's rank must higher than ~w", [IDFrom, Rank]);
			   (MemFrom#guild_member.rank > ?GUILD_OFFICER) ->
				?ERR(guild_man, "only Rank higher than officer can designate rank to others");
			true ->
				gen_cache:update_element(?CACHE_GUILD_MEM, IDTo, {#guild_member.rank, Rank})
			end;
		false ->
			ok %% no in the same guild
	end,
	catch guild:get_guild_basic_info(IDTo),
	{noreply, State};

%% transfer guild to another player
handle_cast({transfer_president, IDFrom, IDTo, GuildID}, State) ->
	case is_in_same_guild(IDFrom, IDTo) of
		{true, GuildID} -> 
			[MemFrom] = gen_cache:lookup(?CACHE_GUILD_MEM, IDFrom),
			[MemTo]   = gen_cache:lookup(?CACHE_GUILD_MEM, IDTo),
		
			case MemFrom#guild_member.rank == ?GUILD_PRESIDENT of
				true ->
					gen_cache:update_element(?CACHE_GUILD_MEM, IDTo,   {#guild_member.rank, ?GUILD_PRESIDENT}),
					gen_cache:update_element(?CACHE_GUILD_MEM, IDFrom, {#guild_member.rank, ?GUILD_MEMBER}),
					gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
						[{#guild_info.president, IDTo}, 
						 {#guild_info.president_name, MemTo#guild_member.name}]);
				false ->
					ok %% IDFrom is not a president, ignore
			end;
		false ->
			ok		%% not in the same guild
	end,
	guild:get_guild_player_info(IDFrom),
	guild:get_guild_player_info(IDTo),
	{noreply, State};

%% Dismiss a guild
%% (1) check the state to see if it is in the normal state
%% (2) set the state to dismiss, and save the current time
%% (3) start a timer to notify us
handle_cast({begin_dismiss_guild, ID, GuildID}, State) ->
	?INFO(guild, "begin dismiss guild"),
	
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[#guild_info {president = ID, state = S}] ->
			case S of
				normal ->
					{ok, TRef} = timer:send_after(?THREE_DAYS_SECS * 1000, {dismiss_guild, GuildID}),
					%% update the guild state, and save the current time
					Now = util:unixtime(),
					gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
						[{#guild_info.state, {dismiss, Now, TRef}},
						 {#guild_info.dismiss_time, Now + ?THREE_DAYS_SECS}]);
				{dismiss, _Time, _TRef} ->
					ok %% already in the waiting state
			end,
			guild:get_guild_info(ID, GuildID);
		_ ->
			%% ID is not the president or the guild is not exist
			ok
	end,
	guild:get_guild_info(ID, GuildID),
	{noreply, State};

handle_cast({cancel_dismiss_guild, ID, GuildID}, State) ->
	?INFO(guild, "cancel dimiss guild"),
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[#guild_info {president = ID, state = GState}] ->
			case GState of
				{dismiss, _, TRef} ->
					timer:cancel(TRef),
					gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
						[{#guild_info.state, normal}, 
						 {#guild_info.dismiss_time, 0}]);
				_ ->
					ok
			end;
		Other ->
			?ERR(guild_man, "Other = ~w", [Other]),
			ok
	end,
	guild:get_guild_info(ID, GuildID),
	{noreply, State};

%% IDHigh want to delete IDLow in the guild
handle_cast({fire_member, IDHigh, IDLow, GuildID}, State) ->
	case is_in_same_guild(IDHigh, IDLow) of
		{true, GuildID} ->
			[Info] = gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
			[Mem1] = gen_cache:lookup(?CACHE_GUILD_MEM,  IDHigh),
			[Mem2] = gen_cache:lookup(?CACHE_GUILD_MEM,  IDLow),
			case (Mem1#guild_member.rank < Mem2#guild_member.rank) andalso 
				(Mem1#guild_member.rank =< 3) of
				true ->
					gen_cache:delete(?CACHE_GUILD_MEM, #guild_member {id = IDLow}),
					MemList = Info#guild_info.members,
					gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
						{#guild_info.members, lists:delete(IDLow, MemList)});
				false ->
					ok
			end;
		false ->
			ok %% not in the same guild
	end,
	{noreply, State};
	

%% when exp reach the limit, the guild will upgrade
handle_cast({donate, ID, GuildID, Silver, Gold}, State) ->
	?INFO(guild_man, "handling donation ..."),
	
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[Mem = #guild_member {id = ID, guild_id = GuildID, name = Name, 
			donate_time = DTime, donate_count = DCount}] ->
			
			%% this operation must be successful
			[#guild_info {level = L, exp = Exp, event = EvtTab}] = 
				gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
			
			DLimit = data_guild:get_guild_donate(L),
			{S, G} = donate_money(ID, min(Silver, DLimit - DCount), Gold),
			
			case S == 0 andalso G == 0 of
				true -> ok;
				_    ->
					ExpAdd = trunc(Silver / 100) + Gold * 10,
					Now    = util:unixtime(),
					EvtDonate = 
						#guild_event {
							time    = Now,
							type    = ?GUILD_EVENT_DONATE,
							content = {ID, Name, ExpAdd}
						},
					%% the gold may be a very large number, so we must take special care
					%% to handle this situation!!
					
					case can_upgrade(L, Exp, ExpAdd) of
						{true, NLevel} ->
							EvtUpgrade =
								#guild_event {
									time    = Now, 
									type    = ?GUILD_EVENT_UPGRADE_LEVEL, 
									content = {NLevel}
								},
							NEvtTab = guild_event:add_event(EvtTab, [EvtDonate, EvtUpgrade]),
							
							%% Member Limit is increased
							MemberLimit = (NLevel - 1) * 2 + 20,
							
							gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
								[{#guild_info.exp,   Exp + ExpAdd},
								 {#guild_info.level, NLevel},
								 {#guild_info.max_member, MemberLimit},
								 {#guild_info.event, NEvtTab}]);
						
						_ -> 
							NEvtTab = guild_event:add_event(EvtTab, EvtDonate),
							gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, 
								[{#guild_info.exp, Exp + ExpAdd},
								 {#guild_info.event, NEvtTab}])
					end,
					
					MemExp  = Mem#guild_member.exp,
					MemTExp = Mem#guild_member.total_exp,
					
					NDCount = 
						case util:check_other_day(DTime) of
							false -> DCount + S;
							true  -> S
						end,
					
					gen_cache:update_element(?CACHE_GUILD_MEM, ID, 
						[{#guild_member.exp, MemExp + ExpAdd}, 
						 {#guild_member.total_exp, MemTExp + ExpAdd},
						 {#guild_member.donate_time, Now},
						 {#guild_member.donate_count, NDCount}
						]),
				
					%% pt 19010, 19011
					catch guild:get_guild_info(ID, GuildID),
					catch guild:get_guild_player_info(ID),
					catch guild:get_guild_basic_info(ID)
			end;
		_ ->
			ok
	end,
	{noreply, State};

handle_cast({change_manifesto, ID, GuildID, Manifesto}, State) ->
	?INFO(guild_man, "calling change manifesto"),
	
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[#guild_info {president = ID}] ->
			?INFO(guild_man, "changing manifesto"),
			gen_cache:update_element(?CACHE_GUILD_INFO, GuildID, {#guild_info.manifesto, Manifesto}),
			Result = 1; %% success
		_ ->
			Result = 0  %% failure
	end,
	guild:change_manifesto_done(ID, Result),
	{noreply, State};

handle_cast({get_guild_welfare, ID, GuildID, Now}, State) ->
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[#guild_member {welfare_time = WelTime, rank = Rank, exp = Exp}] ->
			case util:get_diff_day(Now, WelTime) of
				the_same_day -> ok;
				_ -> 
					[#guild_info {level = Level}] = gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
					gen_cache:update_element(?CACHE_GUILD_MEM, ID, {#guild_member.welfare_time, Now}),
					guild:get_welfare_done(ID, Exp, Level, Rank)
			end;
		[] ->
			ok
	end,
	{noreply, State};	


%% we don't need to check those trivial things in guild_man
%% all we need to do is subtract the exp from the player.
handle_cast({buy_items, ID, ExpCost}, State) ->
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[#guild_member {exp = Exp}] ->
			gen_cache:update_element(?CACHE_GUILD_MEM, ID, {#guild_member.exp, max(0, Exp - ExpCost)}),
			catch guild:get_guild_player_info(ID);
		_ ->
			ok
	end,
	{noreply, State};

handle_cast({set_leave_time, ID, Time}, State) ->
	?INFO(guild_man, "handling set leave time. ID = ~w, Time = ~w", [ID, Time]),
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[] -> 
			?INFO(guild_man, "can not find ID ~w", [ID]),
			ok;
		_  -> 
			?INFO(guild_man, "updating leave time"),
			gen_cache:update_element(?CACHE_GUILD_MEM, ID, {#guild_member.leave_time, Time})
	end,
	{noreply, State};

handle_cast(_, State) ->
	{noreply, State}.

handle_info({dismiss_guild, GuildID}, State) ->
	?INFO(guild_man, "dismiss guild!"),
	
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[#guild_info {state = GuildState, members = MemList}] when GuildState =/= normal ->
			%% delete the guild!!
			?INFO(guild_man, "delete the guild! memlist = ~w", [MemList]),
			delete_all_member(MemList),
			gen_cache:delete(?CACHE_GUILD_INFO, #guild_info {guild_id = GuildID}),
			ok;
		_ ->
			%% if gen_cache:lookup returns [] or the state is normal(player cancel it), 
			%% just ignore this message
			?INFO(guild_man, "the guild has been dismissed"),
			ok
	end,
	{noreply, State};

handle_info({debug, _ID, _Field}, State) ->
	{noreply, State};
	
handle_info(Msg, State) ->
	?INFO(guild_man, "Unknown msg111: ~w", [Msg]),
	{noreply, State}.

handle_call(_Msg, _From, _State) ->
	{reply, ok, _State}.

terminate(_, _) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%========================================================================================================
% external function
%========================================================================================================

create_guild(ID, Name, GuildName, Manifesto, Type) ->
	gen_server:cast(?MODULE, {create_guild, ID, Name, GuildName, Manifesto, Type}).

apply_join_guild(ID, Name, SortType, Page, GuildID) ->
	gen_server:cast(?MODULE, {apply_join_guild, ID, Name, SortType, Page, GuildID}).

join_guild(AppID, IsApproved, OfficerID, GuildID) ->
	gen_server:cast(?MODULE, {join_guild, AppID, IsApproved, OfficerID, GuildID}).

quit_guild(ID, GuildID) ->
	gen_server:cast(?MODULE, {quit_guild, ID, GuildID}).

dismiss_guild(ID, GuildID) ->
	gen_server:cast(?MODULE, {begin_dismiss_guild, ID, GuildID}).

cancel_dismiss_guild(ID, GuildID) ->
	gen_server:cast(?MODULE, {cancel_dismiss_guild, ID, GuildID}).

designate_rank(IDFrom, IDTo, Rank, GuildID) ->
	if (IDFrom =/= IDTo) ->
		gen_server:cast(?MODULE, {designate_rank, IDFrom, IDTo, Rank, GuildID});
	true ->
		ok
	end.

transfer_president(IDFrom, IDTo, GuildID) ->
	if (IDFrom =/= IDTo) ->
		gen_server:cast(?MODULE, {transfer_president, IDFrom, IDTo, GuildID});
	true ->
		ok
	end.

fire_member(IDHigh, IDLow, GuildID) ->
	if (IDHigh =/= IDLow) ->
		gen_server:cast(?MODULE, {fire_member, IDHigh, IDLow, GuildID});
	true ->
		ok
	end.

change_manifesto(ID, GuildID, Manifesto) ->
	gen_server:cast(?MODULE, {change_manifesto, ID, GuildID, Manifesto}).

donate(ID, GuildID, Silver, Gold) ->
	gen_server:cast(?MODULE, {donate, ID, GuildID, Silver, Gold}).

get_guild_welfare(ID, GuildID, Now) ->
	gen_server:cast(?MODULE, {get_guild_welfare, ID, GuildID, Now}).

buy_items(ID, Exp) ->
	gen_server:cast(?MODULE, {buy_items, ID, Exp}).

%========================================================================================================
% internal function 
%========================================================================================================
login(ID) ->
	gen_server:cast(?MODULE, {set_leave_time, ID, 0}).

logout(ID) ->
	Now = util:unixtime(),
	gen_server:cast(?MODULE, {set_leave_time, ID, Now}).

get_next_guild_id() ->
	case db_sql:get_one("SELECT MAX(guild_id) FROM gd_guild") of
		?UNDEFINED -> 1;
		GuildID -> GuildID + 1
	end.

get_table_size(Table) ->
	case gen_cache:info(Table, size) of
		undefined -> 0;
		Value -> Value
	end.

get_guild_member_num(GuildID) ->
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[] -> 0;
		[#guild_info {members = MemList}] ->
			length(MemList)
	end.

get_guild_name(GuildID) ->
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[] -> "";
		[#guild_info {guild_name = GuildName}] ->
			GuildName
	end.

delete_all_member([MemID | Rest]) ->
	gen_cache:delete(?CACHE_GUILD_MEM, #guild_member {id = MemID}),
	case ets:lookup(?ETS_ONLINE, MemID) of
		[] -> ok;
		_  -> 
			%% player is online, guild_man notice him the guild is dismiss
			%% but we don't care the result
			catch guild:set_guild_id(MemID, 0)
	end,
	delete_all_member(Rest);

delete_all_member([]) ->
	ok.

%% is_in_same_guild find out whether two players are in the same guild
-spec is_in_same_guild(player_id(), player_id()) -> false | {true, guild_id()}.
															 
is_in_same_guild(ID1, ID2) ->
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID1) of
		[] -> false;
		[#guild_member {guild_id = GuildID1}] ->
			case gen_cache:lookup(?CACHE_GUILD_MEM, ID2) of
				[] -> false;
				[#guild_member {guild_id = GuildID2}] ->
					if (GuildID1 =:= GuildID2) ->
						{true, GuildID1};
					true ->
						false
					end
			end
	end.

%=======================================================================================================
% helper functions
%=======================================================================================================

-spec consume_money(ID :: player_id(), Type :: integer(), Amount :: integer()) -> boolean().
consume_money(ID, Type, Amount) ->
	?INFO(guild_man, "calling consume money, ID = ~w, Type = ~w, Amount = ~w", [ID, Type, Amount]),
	case Type == ?GUILD_DONATE_GOLD of %% 0 - use gold 1 - use silver
		true  ->
			case catch mod_economy:check_and_use_gold(ID, Amount, ?GOLD_GUILD_CREATE) of
				true  -> true;
				false -> false;
				{'EXIT', Err} -> 
					?ERR(guild_man, "using gold fail: ~w", [Err]), false
			end;
		false ->
			case catch mod_economy:check_and_use_silver(ID, Amount, ?SILVER_GUILD_CREATE) of
				true  -> true;
				false -> false;
				{'EXIT', Err} -> 
					?ERR(guild_man, "using silver fail: ~w", [Err]), false
			end
	end.

donate_money(ID, Silver, Gold) ->
	CostSilver = 
		if (Silver =/= 0) ->
			case consume_money(ID, ?GUILD_DONATE_SILVER, Silver) of
				true  -> Silver;
				false -> 0
			end;
		true ->
			0
		end,
	CostGold = 
		if (Gold =/= 0) ->
			case consume_money(ID, ?GUILD_DONATE_GOLD, Gold) of
				true  -> Gold;
				false -> 0
			end;
		true ->
			false
		end,
	{CostSilver, CostGold}.

-spec can_upgrade(Level :: integer(), CurrentExp :: integer(), ExpAdd :: integer()) -> 
	false | {true, NewLevel :: integer()}.

can_upgrade(Level, CurExp, ExpAdd) ->
	case find_next_level(Level, CurExp, ExpAdd) of
		Level  -> false;
		NLevel -> {true, NLevel}
	end.

find_next_level(Level, CurExp, ExpAdd) ->
	NextExp = data_guild:get_guild_exp(Level + 1),
	if  (not is_integer(NextExp)) -> 
			Level;
		(CurExp + ExpAdd < NextExp) -> 
			Level;
		true ->
			find_next_level(Level + 1, CurExp, ExpAdd)
	end.
			
%=======================================================================================================
% Debug function
%=======================================================================================================




























































































