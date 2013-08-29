-module(guild).
-behaviour(gen_server).

-include("common.hrl").

-define(gpid, get_guild_pid(ID)).

-export([start_link/1, init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).
-export(
	[
	 	apply_join_guild/4,
	 	approve_join_guild/3,
		batch_apply_join_guild/4,
		buy_items/3, 
		change_manifesto/2,
		change_manifesto_done/2,
		create_guild/4, 
		debug_guild/1,
		designate_rank/3, 
		dismiss_guild/2,
		donate/3,
		fire_member/2, 
		get_donate_info/1, 
		get_guild_apply_list/2, 
		get_guild_basic_info/1, 
		get_guild_event/2, 
		get_guild_info/2, 
		get_guild_list/4,
		get_guild_member_list/1,
		get_guild_member_list/3,
		get_guild_name/1,
		get_guild_pid/1,
		get_guild_player_info/1, 
		get_member_info/2,
		get_welfare/1,
		get_welfare_done/4,
		learn_skill/3,
		query_guild_id/1,
		quit_guild/1,
		set_guild_id/2
	]
).

-export([is_in_guild/1]).

start_link(ID) ->
	gen_server:start_link(?MODULE, [ID], []).

init([ID]) ->
	process_flag(trap_exit, true),
	mod_player:update_module_pid(ID, ?MODULE, self()),
	put(id, ID),
	GuildID = query_guild_id(ID),
	?INFO(guild, "Init guild........ GuildID = ~w", [GuildID]),
	guild_man:login(ID),
	{ok, {ID, GuildID}}.

handle_cast({set_guild_id, GuildID}, {ID, _}) ->
	Bin = 
		case GuildID of
			0 -> pt_19:write(19100, 0);
			_ -> 
				case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
					[] -> 
						pt_19:write(19100, 0);
					[Guild] ->
						pt_19:write(19100, Guild)
				end
		end,
	lib_send:send(ID, Bin),
	{noreply, {ID, GuildID}};

handle_cast({create_guild, Name, GuildName, Manifesto, Type}, State = {ID, GuildID}) ->
	%% Level = mod_role:get_main_level(ID),
	CheckFilter = 	
		case mod_word_filter:find_prohibited_words(GuildName) of
			not_found ->
				case mod_word_filter:find_prohibited_words(Manifesto) of 
					not_found ->
						true;
					{found, _PosLen} ->
						mod_err:send_err(ID, ?ERR_PROHIBIT_WORD),
						false
				end;
			{found, _PosLen} ->
				mod_err:send_err(ID, ?ERR_PROHIBIT_WORD),
				false
		end,

	if (GuildID =/= 0) ->
		?INFO(guild, "already in a guild"), ok;
	(length(Manifesto) == 0) -> 
		?INFO(guild, "manifesto can not be null"), ok;	
%% 	(Level < 15) ->
%% 		?INFO(guild, "level not reach 15"), ok;
	CheckFilter == false->
		{ok, Bin} = pt_err:write(?GUILD_ERROR_PROHIBITED_WORDS),
		lib_send:send(ID, Bin),
		?ERR(todo, "send error code");
	true ->
		%% me must trim all the space from the GuildName to avoid further trouble
		GuildName1 = re:replace(GuildName,  "^\s*", "", [{return, list}]),
		GuildName2 = re:replace(GuildName1, "\s*$", "", [{return, list}]),
		
		guild_man:create_guild(ID, Name, GuildName2, Manifesto, Type)
	end,
	{noreply, State};

handle_cast({apply_join_guild, SortType, Page, GID}, State = {ID, GuildID}) when GID =/= 0 ->
	?INFO(guild, "handling apply_join_guild, GID = ~w", [GID]),
%%	Level = mod_role:get_main_level(ID),
	
	if (GuildID =/= 0)  -> 
		?INFO(guild, "already in a guild"), ok;
%% 	(Level < 15) -> 
%% 		?INFO(guild, "level not reach 15"), ok;
	true ->
		Name = mod_account:get_player_name(ID),
		guild_man:apply_join_guild(ID, Name, SortType, Page, GID)   
	end,
	{noreply, State};

%% batch join guild
handle_cast({batch_apply_join_guild, SortType, Page, GuildList}, State = {_ID, GuildID}) ->
	if (GuildID =/= 0) -> 
		?INFO(guild, "already in a guild"), ok;
	true ->
		F = fun(Gid) ->
				gen_server:cast(self(), {apply_join_guild, SortType, Page, Gid})
			end,
		lists:foreach(F, GuildList)
	end,
	{noreply, State};

handle_cast({approve_join_guild, AppID, IsApprove}, State = {ID, GuildID}) ->
	?INFO(guild, "handling approve join guild, AppID = ~w, IsApprove = ~w", [AppID, IsApprove]),
	if (GuildID == 0) -> ok;
	true ->
		case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
			[#guild_member {guild_id = GuildID, rank = Rank}] ->
				case Rank =< ?GUILD_VICE_PRESIDENT of
					true ->
						guild_man:join_guild(AppID, IsApprove, ID, GuildID);
					false ->
						ok
				end;
			_ ->
				ok
		end
	end,
	{noreply, State};

handle_cast(quit_guild, State = {ID, GuildID}) ->
	if (GuildID == 0) ->
		ok;
	true ->
		guild_man:quit_guild(ID, GuildID)
	end,
	{noreply, State};

handle_cast({dismiss_guild, IsCancel}, State = {ID, GuildID}) ->
	if (GuildID == 0) ->
		ok;
	true ->
		if (IsCancel == false) ->
			guild_man:dismiss_guild(ID, GuildID);
		true ->
			guild_man:cancel_dismiss_guild(ID, GuildID)
		end
	end,
	{noreply, State};

handle_cast({designate_rank, IDFrom, IDTo, Rank}, State = {_, GuildID}) ->
	?INFO(guild, "handling designate rank, Rank = ~w", [Rank]),
	
	Guild = gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
	case Guild of
		[] -> ok;
		[#guild_info {level = Level}] ->
			case gen_cache:lookup(?CACHE_GUILD_MEM, IDTo) of
				[] -> ok;
				[#guild_member {rank = MemRank, exp = Exp}] ->
					if (Rank == ?GUILD_PRESIDENT) ->
						EnoughExp = check_top_ten_exp(IDTo, GuildID),
							%% check whether IDTo's exp is top 5
							%% and also satisfied the exp value's formula
						if (MemRank > ?GUILD_ELITE) ->
							%% only can transfer to elite member;
							?INFO(guild, "only rank not lower than elite can designate");
						(EnoughExp == false) ->
							%% only can transfer to top ten member;
							mod_err:send_err(IDFrom, 19013),
							?INFO(guild, "not enough exp");
						true -> 
							guild_man:transfer_president(IDFrom, IDTo, GuildID)
						end;
					true ->
						EnoughExp = check_exp(Rank, Level, Exp),
						if (EnoughExp == true) ->
							guild_man:designate_rank(IDFrom, IDTo, Rank, GuildID);
						true ->
							ok
						end
					end
			end
	end,
	{noreply, State};

%% !! check the silver or gold is negative?
handle_cast({donate, Silver, Gold}, State = {ID, GuildID}) ->
	if	(GuildID == 0) ->
			ok;
		(Silver < 0 orelse Gold < 0) -> %% silver or gold can not be negative
			ok;
		(Silver == 0 andalso Gold == 0) ->
			ok;
		true ->
			[Guild]    = gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
			[GuildMem] = gen_cache:lookup(?CACHE_GUILD_MEM, ID),
			?INFO(guild, "Level = ~w", [Guild#guild_info.level]),
			DonateLim  = data_guild:get_guild_donate(Guild#guild_info.level),
			LastTime   = GuildMem#guild_member.donate_time,
	
			case util:check_other_day(LastTime) of
				false -> DonateCount = GuildMem#guild_member.donate_count;
				true  -> DonateCount = 0 
			end, 
			
			NSilver = max(0, min(Silver, DonateLim - DonateCount)),
			NGold   = max(0, Gold),
			
			?INFO(guild, "NSilver = ~w, NGold = ~w", [NSilver, NGold]),
			
			if (NSilver == 0 andalso NGold == 0) ->
				?INFO(guild, "Silver == 0, reach the donate limit"),
				ok;
			true ->
				guild_man:donate(ID, GuildID, NSilver, NGold)
			end
	end,
	{noreply, State};

%% pt 19028
handle_cast({get_guild_member_list, SortType, Page}, State = {ID, GuildID}) ->
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[#guild_info {members = MemList}] ->
			F = fun(MemID, Acc) ->
					case gen_cache:lookup(?CACHE_GUILD_MEM, MemID) of
						[] -> Acc;
						[Mem] -> [Mem | Acc]
					end
				end,
			MemList1 = lists:foldl(F, [], MemList),
			MemList2 = get_member_info(MemList1, SortType),
			{SubList, Total, Cur} = select_page_from_list(MemList2, Page, ?GUILD_PAGE_SIZE),
			Bin = pt_19:write(19028, {SortType, SubList, Total, Cur}),
			lib_send:send(ID, Bin);
		_ ->
			ok
	end,
	{noreply, State};

%% pt 19100
handle_cast(get_guild_basic_info, State = {ID, GuildID}) ->
	?INFO(guild, "GuildID = ~w", [GuildID]),
	if (GuildID == 0) ->
		Bin = pt_19:write(19100, 0);
	true ->
		[Guild] = gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
		Bin = pt_19:write(19100, Guild)
	end,
	lib_send:send(ID, Bin),
	{noreply, State};

%% pt 19009 guild event...
handle_cast({get_guild_event, GuildID}, State = {ID, _}) ->
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[#guild_info {event = EventTab}] ->
			Bin = pt_19:write(19009, {GuildID, EventTab}),
			lib_send:send(ID, Bin);
		_ ->
			ok
	end,
	{noreply, State};

%% pt 19010
handle_cast({get_guild_info, GuildID}, State = {ID, _}) ->
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[] -> ok;
		[Guild] ->
			Bin = pt_19:write(19010, Guild),
			lib_send:send(ID, Bin)
	end,
	{noreply, State};

%% pt 19011
handle_cast(get_guild_player_info, State = {ID, GuildID}) ->
	if (GuildID == 0) ->
		ok;
	true ->
		[GuildMem] = gen_cache:lookup(?CACHE_GUILD_MEM, ID),
		[Guild] = gen_cache:lookup(?CACHE_GUILD_INFO, GuildID),
		Bin = pt_19:write(19011, {GuildMem, Guild}),
		lib_send:send(ID, Bin)
	end,
	{noreply, State};

%% pt 19012
handle_cast({get_guild_apply_list, Page}, State = {ID, GuildID}) ->
	?INFO(guild, "handling get_guild_apply_list.."),
	
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[#guild_info {apply_list = AppList}] -> 
			%% AppList :: [player_id()]
			SortFun = 
				fun({_, T1}, {_, T2}) ->
					if (T1 > T2) -> true; true -> false end
				end,
			
			AppList1 = lists:map(fun({P, _}) -> P end, lists:sort(SortFun, AppList)),
						
			{SubList, Total, Current} = select_page_from_list(AppList1, Page, 10),
			?INFO(guild, "SubList = ~w, Total = ~w, Current = ~w", [SubList, Total, Current]),
			
			F = fun(AppID, Acc) ->
					case ets:lookup(?ETS_GUILD_APPLY, AppID) of
						[] -> Acc;
						[AppRec] -> [AppRec | Acc]
					end
				end,
			SubListRec = lists:foldl(F, [], SubList),			
			
			Bin = pt_19:write(19012, {GuildID, SubListRec, Total, Current}),
			?INFO(guild, "app list bin = ~w", [Bin]),
			lib_send:send(ID, Bin);
		_ -> 
			ok
	end,
	{noreply, State};

%% pt 19013
%% when Search type 
handle_cast({get_guild_list, Name, SearchType, PageHint}, State = {ID, _}) ->
	?INFO(guild, "handling get_guild_list: Name = ~w, SearchType = ~w, PageHint = ~w", 
		  [Name, SearchType, PageHint]),
	
	List  = gen_cache:tab2list(?CACHE_GUILD_INFO),
	List1 = match_name(List, Name),
	List2 = lists:sort(get_guild_sort_fun(SearchType), List1),
	
	{SubList, TotalPage, CurrentPage} = 
		select_page_from_list(List2, PageHint, 10),

	AppList = 
		case ets:lookup(?ETS_GUILD_APPLY, ID) of
			[] -> [];
			[#guild_apply {apply_list = L}] -> L
		end,
	Bin = pt_19:write(19013, {SearchType, SubList, TotalPage, CurrentPage, AppList}),
	lib_send:send(ID, Bin),
	{noreply, State};

%% pt 19014
handle_cast({change_manifesto, Manifesto}, State = {ID, GuildID}) ->
	?INFO(guild, "handling change manifesto"),
	CheckFilter = 	
		case mod_word_filter:find_prohibited_words(Manifesto) of
			not_found ->
				true;
			{found, _PosLen} ->
				mod_err:send_err(ID, ?ERR_PROHIBIT_WORD),
				false
		end,
	
	if (CheckFilter == true) -> %% ok
		case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
			[#guild_info {president = ID}] ->
				guild_man:change_manifesto(ID, GuildID, Manifesto);
			_ -> 
				?ERR(guild, "can not find guild id ~w", [GuildID]), 
				ok
		end;
	true->
		?ERR(guild, "~w contains prohibit word", [Manifesto])
	end,
	{noreply, State};

handle_cast({change_manifesto_done, Result}, State = {ID, _}) ->
	Bin = pt:pack(19014, <<Result:8>>),
	lib_send:send(ID, Bin),
	{noreply, State};

%% pt 19017
handle_cast(get_welfare, State = {ID, GuildID}) ->
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[] -> ok;
		[#guild_member {welfare_time = WelTime, donate_time = DonateTime}] ->
			CheckWelTime = util:check_other_day(WelTime),
			CheckDonateTime = util:check_other_day(DonateTime),
			
			if (CheckWelTime == false) ->
				mod_err:send_err(ID, 19012),
				?INFO(guild, "you have go your welfare today!");
			   
			(CheckDonateTime == true) ->
				mod_err:send_err(ID, 19005),
				?INFO(guild, "you have not donated today yet!");
			   
			true ->
				guild_man:get_guild_welfare(ID, GuildID, util:unixtime())
			end
	end,
	{noreply, State};

%% welfare silver = cell(3000+0.05 * exp) * (1 + 0.05 * level) * ranking_parameter
%% president      1
%% vice_president 0.7
%% officer	      0.63
%% elite		  0.56
%% member		  0.5
handle_cast({get_welfare_done, Exp, Level, Rank}, State = {ID, _}) ->
	RankParam = 
		case Rank of
			?GUILD_PRESIDENT      -> 1;
			?GUILD_VICE_PRESIDENT -> 0.7;
			?GUILD_OFFICER        -> 0.63;
			?GUILD_ELITE          -> 0.56;
			?GUILD_MEMBER         -> 0.5
		end,
	Silver = util:ceil((3000 + 0.05 * Exp) * (1 + 0.05 * Level) * RankParam),
	mod_economy:add_silver(ID, Silver, ?SILVER_FROM_GUILD_COMP),
	
	Bin = pt_19:write(19017, Silver),
	lib_send:send(ID, Bin),
	{noreply, State};

%% pt 19018
handle_cast({fire_member, IDHigh, IDLow}, State = {_, GuildID}) ->
	if (GuildID == 0) -> ok;
	true ->
		case check_top_ten_exp(IDLow, GuildID) of
			true  -> 
				%% can not fire this member
				mod_err:send_err(IDHigh, 19033),
				?INFO(guild, "can not fire member whose exp is top 5");
			false -> 
				guild_man:fire_member(IDHigh, IDLow, GuildID)
		end
	end,
	{noreply, State};

%% pt 19029
handle_cast(get_donate_info, State = {ID, GuildID}) ->
	DonateInfo = 
		case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
			[] -> {0, 0};
			[#guild_info {level = Level}] ->
				Limit = data_guild:get_guild_donate(Level),
				
				[#guild_member {donate_count = C}] = 
					gen_cache:lookup(?CACHE_GUILD_MEM, ID),
				{C, Limit}
		end,
	Bin = pt_19:write(19029, DonateInfo),
	lib_send:send(ID, Bin),
	{noreply, State};

%% pt 19040 guild items
handle_cast({buy_items, ItemID, Count}, State = {ID, GuildID}) ->
	?INFO(guild, "handling buy_items..."),
	
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[#guild_member {guild_id = GuildID, exp = Exp}] ->
			case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
				[#guild_info {level = Level}] ->
					GuildItem = data_guild_item:get(ItemID),
					if (GuildItem == ?UNDEFINED) -> 
						?INFO(guild, "ItemID ~w is not in data_guild_item", [ItemID]),
						ok; 
					true ->
						ItemExp = GuildItem#guild_item.exp,
						ItemLev = GuildItem#guild_item.level,
						if (ItemLev =< Level andalso (ItemExp * Count)=< Exp) -> %% create items
							try 
								Bags = mod_items:getBagNullNum(ID),
								?INFO(guild, "Bags = ~w", [Bags]),
								if (Bags < Count) -> 
									ok;
								true ->
									?INFO(guild,"createItems,PlayerID = ~w,Itemlist = ~w",[ID,[{ItemID, Count, 1}]]),
									guild_man:buy_items(ID, ItemExp * Count),
									mod_items:createItems(ID, [{ItemID, Count, 1}], ?ITEM_FROM_GUILD_COMP)
								end
							catch Ty:Er ->
								?ERR(guild, "error occurs when createItem, type = ~w, error = ~w", [Ty, Er])
							end;
						true ->
							?INFO(guild, "not enough level or exp"), ok
						end
					end;
				_ -> 
					ok
			end;	
		_ -> 
			ok %% not in any guild or GuildID not match;
	end,
	{noreply, State};

%% learn skill
handle_cast({learn_skill, SkillID, Level}, State = {ID, GuildID}) ->
	{noreply, State};

handle_cast(Msg, State) ->
	?INFO(guild, "unknown message: ~w", [Msg]),
	{noreply, State}.

handle_info(debug, State) ->
	?INFO(guild, "debug info: self = ~w, State = ~w", [self(), State]),
	{noreply, State};

handle_info(_Msg, State) ->
	{noreply, State}.

handle_call(get_guild_member_list, _From, State = {_, GuildID}) ->
	Reply = 
		case GuildID == 0 of
			true  -> [];
			false ->
				case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
					[] -> [];
					[#guild_info {members = Members, president = President}] -> [President | Members]
				end
		end,
	{reply, Reply, State};

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

terminate(_Reason, _State = {ID, GuildID}) ->
	?INFO(guild, "guild terminating.. call logout"),
	if (GuildID == 0) -> 
		ok;
	true ->
		guild_man:logout(ID)
	end.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%===========================================================================================================================
% internal function
%===========================================================================================================================

set_guild_id(ID, GuildID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {set_guild_id, GuildID}).

%% query the guild id from ets table
query_guild_id(ID) ->
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[] -> 0;
		[#guild_member {guild_id = GuildID}] -> GuildID
	end.

is_in_guild(ID) ->
	query_guild_id(ID) > 0.

get_guild_pid(ID) ->
	if is_integer(ID) ->
			Ps = mod_player:get_player_status(ID),
			Ps#player_status.guild_pid;
	   is_pid(ID) -> ID;
	   true -> erlang:exit("guild id not correct")
	end.

%% pt 19000: create a new guild, the player will become president of the guild.
-spec create_guild(ID, GuildName, Manifesto, Type) -> ok when
	ID :: integer(), %% player id
	GuildName :: string(),
	Manifesto :: string(),
	Type :: integer(). 

create_guild(ID, GuildName, Manifesto, Type) ->
	Gpid = get_guild_pid(ID),
	Name = mod_account:get_player_name(ID),
	gen_server:cast(Gpid, {create_guild, Name, GuildName, Manifesto, Type}).

%% pt 19001:join a guild
-spec apply_join_guild(ID, SortType, Page, GuildID) -> ok when 
	ID       :: integer(),	
	SortType :: integer(),
	Page     :: integer(),
	GuildID  :: integer().

apply_join_guild(ID, SortType, Page, GuildID) ->
	?INFO(guild, "app join: GuildID = ~w", [GuildID]),
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {apply_join_guild, SortType, Page, GuildID}).

approve_join_guild(ID, AppID, IsApprove) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {approve_join_guild, AppID, IsApprove}).

get_guild_apply_list(ID, Page) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {get_guild_apply_list, Page}).

%% pt 19002: quit a guild
-spec quit_guild(ID) -> ok when
	ID :: integer().

quit_guild(ID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, quit_guild).

%% pt 19003: dismiss/cancel dismiss a guild, only the president of the guild can do this
-spec dismiss_guild(ID, IsCancel) -> ok when 
	ID       :: integer(),						  
	IsCancel :: boolean().
													 
dismiss_guild(ID, IsCancel) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {dismiss_guild, IsCancel}).

-spec designate_rank(IDFrom, IDTo, Rank) -> ok when
	IDFrom  :: integer(),
	IDTo    :: integer(),
	Rank    :: integer().

%% pt 19005 designate 
designate_rank(IDFrom, IDTo, Rank) ->
	Gpid = get_guild_pid(IDFrom),
	?INFO(guild, "designate ... Rank = ~w, Gpid = ~w", [Rank, Gpid]),
	gen_server:cast(Gpid, {designate_rank, IDFrom, IDTo, Rank}).


batch_apply_join_guild(ID, SortType, Page, GuilList) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {batch_apply_join_guild, SortType, Page, GuilList}).

%% pt 19017 get guild welfare
get_welfare(ID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, get_welfare).

get_welfare_done(ID, Exp, Level, Rank) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {get_welfare_done, Exp, Level, Rank}).

%% pt 19018
-spec fire_member(IDHigh, IDLow) -> ok when
	IDHigh  :: integer(),
	IDLow   :: integer().

fire_member(IDHigh, IDLow) ->
	Gpid = get_guild_pid(IDHigh),
	gen_server:cast(Gpid, {fire_member, IDHigh, IDLow}).

%% pt 19015 guild donation
donate(ID, Silver, Gold) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {donate, Silver, Gold}).

%% pt 19013 get guild list
get_guild_list(ID, GuildName, SearchType, Page) ->
	?INFO(guild, "calling get_guild_list..."),
	Gpid = get_guild_pid(ID),
	
	case lists:member(SearchType, lists:seq(1, 4)) of
		true  -> NSearchType = SearchType; 
		false -> NSearchType = 1
	end,
	?INFO(guild, "done"),
	gen_server:cast(Gpid, {get_guild_list, GuildName, NSearchType, Page}).

%% pt 19014 change manifesto
change_manifesto(ID, Manifesto) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {change_manifesto, Manifesto}).

change_manifesto_done(ID, Result) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {change_manifesto_done, Result}).

%% pt 19028 get member list of a specified guild?
get_guild_member_list(ID, SortType, Page) ->
	Gpid = get_guild_pid(ID),
	case lists:member(SortType, lists:seq(1, 4)) of
		true  -> NSortType = 1;
		false -> NSortType = 1
	end,
	gen_server:cast(Gpid, {get_guild_member_list, NSortType, Page}).

get_member_info(MemList, SortType) ->
	lists:sort(get_mem_sort_fun(max(1, min(SortType, 4))), MemList).
	
get_mem_sort_fun(Type) ->
	fun (L, R) ->
		Rank1 = L#guild_member.rank,
		Rank2 = R#guild_member.rank,
		Exp1  = L#guild_member.exp,
		Exp2  = R#guild_member.exp,
		ID1   = L#guild_member.id,
		ID2   = R#guild_member.id,
		Left1 = L#guild_member.leave_time,
		Left2 = R#guild_member.leave_time,
		Rec1  = role_base:get_main_role_rec(ID1),
		Rec2  = role_base:get_main_role_rec(ID2),
		Lev1  = Rec1#role.gd_roleLevel,
		Lev2  = Rec2#role.gd_roleLevel,
	
		%% if Left is 'greater than' Right; returns true;
		%% if Left is 'less than' Right; returns false,
		%% this strategy can make the larger element ahead of the less one
		case Type of
			%% default: Rank -> Exp -> Level -> ID
			1 -> if (Left1 == 0 andalso Left2 > 0) -> true;
				  	(Left1 > 0 andalso Left2 == 0) -> false;
				    (Rank1 < Rank2) -> true;
				    (Rank1 > Rank2) -> false;
				    (Exp1 > Exp2)   -> true;
				    (Exp1 < Exp2)   -> false;
				    (Lev1 > Lev2)   -> true;
				    (Lev1 < Lev2)   -> false;
				    (ID1 < ID2)     -> false;
				    true            -> true
				 end;
			%% sort according to rank
			2 -> if (Rank1 < Rank2) -> true; 
					(Rank1 > Rank2) -> fasle;
					(Left1 == 0 andalso Left2 > 0) -> true;
					(Left1 > 0 andalso Left2 == 0) -> true;
					(Exp1 > Exp2) -> true;
					(Exp1 < Exp2) -> false;
					(ID1 < ID2) -> false;
					true -> true
				 end;
			%% sort according to exp
			3 -> if (Exp1 < Exp2) -> false; 
					(Exp1 > Exp2) -> true;
					(Left1 == 0 andalso Left2 > 0) -> true;
					(Left1 > 0 andalso Left2 == 0) -> true;
					(Rank1 < Rank2) -> true; 
					(Rank1 > Rank2) -> fasle;
					(ID1 < ID2) -> false;
					true -> true 
				 end;
			4 -> if (Left1 == 0 andalso Left2 > 0) -> true;
					(Left1 > 0 andalso Left1 == 0) -> true;
					(Left1 > Left2) -> true;
					true -> false
				 end
		end
	end.

get_guild_sort_fun(Type) ->
	fun (G1, G2) ->
		Exp1 = G1#guild_info.exp,
		Exp2 = G2#guild_info.exp,
		Lev1 = G1#guild_info.level,
		Lev2 = G2#guild_info.level,
		Mem1 = length(G1#guild_info.members),
		Mem2 = length(G2#guild_info.members),
		ID1  = G1#guild_info.guild_id,
		ID2  = G2#guild_info.guild_id,
		
		case Type of
			1 -> %% Default 
				if (Exp1 < Exp2) -> false;
				   (Exp1 > Exp2) -> true;
				   (Lev1 < Lev2) -> false;
				   (Lev2 > Lev1) -> true;
				   (Mem1 < Mem2) -> false;
				   (Mem1 > Mem2) -> true;
				   (ID1  < ID2 ) -> false;
				   true -> true
				end;  
			2 -> if (Lev1 =< Lev2) -> false; true -> true end;
			3 -> if (Exp1 =< Exp2) -> false; true -> true end;
			4 -> if (Mem1 =< Mem2) -> false; true -> true end
		end
	end.

%% pt:19009 get guild event
get_guild_event(ID, GuildID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {get_guild_event, GuildID}).
						
%% pt:19100 get guild basic information
get_guild_basic_info(ID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, get_guild_basic_info).

%% pt:19010 get guild's information
get_guild_info(ID, GuildID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {get_guild_info, GuildID}).

%% pt 19011: get player's information of the guild 
get_guild_player_info(ID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, get_guild_player_info).


%% pt 19029: get donate info
get_donate_info(ID) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, get_donate_info).

%% pt 19040: buy guild item
buy_items(ID, ItemID, Count) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {buy_items, ItemID, Count}).

%% pt 19041: learn guild skill
learn_skill(ID, SkillID, Level) ->
	Gpid = get_guild_pid(ID),
	gen_server:cast(Gpid, {learn_skill, SkillID, Level}).

%% guild item
show_guild_item() ->
	ok.

match_name(List, Name) ->
	if (Name == "") -> List;
	true -> match_name(List, Name, [])
	end.

match_name([Guild | Rest], Name, GuildList) ->
	case (string:str(Guild#guild_info.guild_name, Name) > 0) of
		true  -> match_name(Rest, Name, [Guild | GuildList]);
		false -> match_name(Rest, Name, GuildList)
	end;

match_name([], _Name, NameList) ->
	NameList.

%% seleft a page from a list, every page is assumed to be of len PageLen
%% PageHint is just a hint, indicate which page to return 
-spec select_page_from_list(List, PageHint, PageLen) ->
	{SubList, TotalPage, CurrentPage} when
	
	List        :: [term()],
	SubList     :: [term()],
	PageHint    :: integer(),
	PageLen     :: integer(),   %% length of each page, must be > 0
	TotalPage   :: integer(), 
	CurrentPage :: integer().
																				 
select_page_from_list(List, PageHint, PageLen) when PageLen > 0 ->
	Len = max(1, length(List)),
	TotalPages = (Len - 1) div PageLen + 1,

	CurrentPage = 
		if (TotalPages =< PageHint) -> 
			TotalPages;
		true ->
			PageHint
		end,
	SubList = lists:sublist(List, (CurrentPage - 1) * PageLen + 1, PageLen),
	{SubList, TotalPages, CurrentPage}.

%% check if the player's exp is top ten.
%% if is top ten returns true, otherwise returns false
check_top_ten_exp(ID, GuildID) ->
	case gen_cache:lookup(?CACHE_GUILD_INFO, GuildID) of
		[] -> true; %% can not delete the player
		[Guild] ->
			Members = Guild#guild_info.members,
			F = fun(Mem, Acc) ->
					case gen_cache:lookup(?CACHE_GUILD_MEM, Mem) of
						[] -> Acc;
						[#guild_member {id = MemID, exp = Exp}] ->
							[{MemID, Exp} | Acc]
					end
				end,
			ExpList = lists:keysort(2, lists:foldl(F, [], Members)),
			check_top_ten_exp(ID, 1, ExpList)
	end.

check_top_ten_exp(_ID, _Index, []) -> true;
check_top_ten_exp(_ID, Index, _ExpList) when Index > 5 -> false;
check_top_ten_exp(ID, _Index, [{ID, _}]) -> true;
check_top_ten_exp(ID, Index, ExpList) ->
	check_top_ten_exp(ID, Index + 1, tl(ExpList)).

check_exp(Rank, Level, Exp) ->
	case Rank of
		?GUILD_MEMBER         -> true;
		?GUILD_ELITE          -> Exp >= 100 * Level * Level;
		?GUILD_OFFICER        -> Exp >= 200 * Level * Level;
		?GUILD_VICE_PRESIDENT -> Exp >= 400 * Level * Level;
		?GUILD_PRESIDENT      -> true
	end.
	
%================================================================================================================
% synchronized function
%================================================================================================================
get_guild_name(ID) ->
	case gen_cache:lookup(?CACHE_GUILD_MEM, ID) of
		[] -> "";
		[#guild_member {guild_id = Gid}] ->
			case gen_cache:lookup(?CACHE_GUILD_INFO, Gid) of
				[] -> "";
				[#guild_info{guild_name = Name}] -> Name
			end
	end.

get_guild_member_list(ID) ->
	gen_server:call(?gpid, get_guild_member_list).

debug_guild(ID) ->
	?gpid ! debug.





