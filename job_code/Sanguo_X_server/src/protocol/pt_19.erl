%% Author: Administrator
%% Created: 2011-10-7
%% Description: TODO: Add description to pt_19
-module(pt_19).

-include("common.hrl").
%%
%% Exported Functions
%%
-export([write/2, read/2]).

%% create guild
read(19000, Bin) ->
	{ok, get_create_guild_info(Bin)};

%% apply join
read(19001, <<SortType:8, Page:16, GuildID:16>>) ->
	?INFO(pt_19, "GuildID = ~w", [GuildID]),
	{ok, {SortType, Page, GuildID}};

%% quit
read(19002, <<_Dummy:8>>) ->
	{ok, 0};
	
%% dismiss, cancel dismiss
read(19003, <<Op:8>>) ->
	?INFO(guild, "Op = ~w", [Op]),
	IsCancel = if (Op == 1) -> true; true -> false end,
	{ok, IsCancel};

%% designate
read(19005, <<IDDes:32, Rank:8>>) ->
	{ok, {IDDes, Rank}};

read(19007, <<SortType:8, Page:16, GuildListBin/binary>>) ->
	GuildList = get_guild_list(GuildListBin),
	{ok, {SortType, Page, GuildList}};

%% query guild event
read(19009, <<GuildID:16>>) ->
	{ok, GuildID};
	
%% get information of the specified guild
read(19010, <<GuildID:16>>) ->
	{ok, GuildID};

%% get information of the player's guild
read(19011, <<ID:32>>) ->
	{ok, ID};

%% get guild apply list
read(19012, <<Page:16>>) ->
	{ok, Page};

read(19013, Bin) ->
	{Name, <<SearchType:8, Page:16>>} = pt:read_string(Bin),
	?INFO(pt_19, "Name = ~s, Type = ~w, Page = ~w", [Name, SearchType, Page]),
	{ok, {Name, SearchType, Page}};

%% modify manifesto
read(19014, Bin) ->
	{Manifesto, <<>>} = pt:read_string(Bin),
	{ok, Manifesto};

read(19015, <<Silver:32, Gold:32>>) ->
	{ok, {Silver, Gold}};

%% get welfare from guild 
read(19017, _) ->
	{ok, []};

%% fire member
read(19018, <<MemberID:32>>) ->
	{ok, MemberID};

%% approve join guild
read(19019, <<AppID:32, IsApprove:8>>) ->
	B = if (IsApprove == 1) -> true; true -> false end,
	{ok, {AppID, B}};

%% get guild member list
read(19028, <<SortType:8, Page:16>>) ->
	{ok, {SortType, Page}};

read(19029, _) ->
	{ok, 0};

%% guild store
read(19040, <<ID:32, Count:8>>) ->
	{ok, {ID, Count}};

%% learn guild skill
read(19041, <<SkillID:32, Level:8>>) ->
	{ok, {SkillID, Level}};

read(19100, _) ->
	{ok, []}.

-spec write(Cmd, Data) -> Bin when
	Cmd  :: integer(),
	Data :: term(),
	Bin  :: binary().
	
write(19000, GuildID) ->
	pt:pack(19000, <<GuildID:16>>);

write(19009, {GuildID, EvtTab}) ->
	Num = EvtTab#guild_event_tab.num,
	Bin = get_guild_event_bin(EvtTab),
	pt:pack(19009, <<GuildID:16, Num:16, Bin/binary>>);

write(19010, Guild) ->
	Bin = get_guild_info_bin(Guild),
	pt:pack(19010, Bin);

write(19011, {Guild, GuildMem}) ->
	Bin = get_guild_member_info(GuildMem, Guild),
	pt:pack(19011, Bin);

%% get apply list, T : total pages, C ：current Page
write(19012, {GuildID, List, T, C}) ->
	Len = length(List),
	Bin = get_apply_list_bin(GuildID, List),
	pt:pack(19012, <<T:16, C:16, Len:16, Bin/binary>>);
	
write(19013, {SortType, GuildList, TotalPage, Page, AppList}) ->
	Len = length(GuildList),
	Bin = get_guild_list_bin(Page, GuildList, AppList),
	pt:pack(19013, <<SortType:8, TotalPage:16, Page:16, Len:16, Bin/binary>>);

%% return guild welfare
write(19017, Silver) ->
	pt:pack(19017, <<Silver:32>>);

%% pt 19028
write(19028, {SortType, MemList, Total, Cur}) ->
	Len = length(MemList),
	Bin = get_mem_list_bin(MemList),
	pt:pack(19028, <<SortType:8, Total:16, Cur:16, Len:16, Bin/binary>>);

%% pt 19029 query limit of donation
write(19029, {SilverDonated, Limit}) ->
	pt:pack(19029, <<SilverDonated:32, Limit:32>>);

%% pt 19100
write(19100, 0) ->
	pt:pack(19100, <<0:16, (pt:write_string(""))/binary, 0:16>>);
write(19100, Guild) ->
	?INFO(pt_19, "Guild = ~w", [Guild]),
	
	ID    = Guild#guild_info.guild_id,
	Name  = Guild#guild_info.guild_name,
	Level = Guild#guild_info.level,
	pt:pack(19100, <<ID:16, (pt:write_string(Name))/binary, Level:16>>);


write(_, _) ->
	<<>>.


%=============================================================================================================
% helper function
%=============================================================================================================

%% pt 19000
get_create_guild_info(Bin) ->
	{Name, Bin1} = pt:read_string(Bin),
	{Manifesto, <<Type:8>>} = pt:read_string(Bin1),
	?INFO(guild, "Create Guild: Name = ~s, Manifesto = ~s, Type = ~w", [Name, Manifesto, Type]),
	{Name, Manifesto, Type}.
	
%% pt 19007
get_guild_list(Bin) ->
	get_guild_list(Bin, 0, []).

get_guild_list(<<GuildID:16, Bin/binary>>, Num, List) ->
	if (Num < 20) ->
		get_guild_list(Bin, Num + 1, [GuildID | List]);
	true -> %% Num > 20 
		List
	end;

get_guild_list(<<>>, _Num, List) -> List.

%% pt 19009
get_guild_event_bin(EvtTab) ->
	?INFO(guild, "Event Table = ~w", [EvtTab]),
	Evts = guild_event:get_event(EvtTab),
	?INFO(pt_19, "GuildEvent = ~w", [Evts]),
	get_guild_event_bin(<<>>, Evts).
	
get_guild_event_bin(Bin, [Evt = #guild_event {type = Ty, time = Tm} | Rest]) ->
	Fmt    = guild_event:format_event(Evt),
	FmtBin = pt:write_string(Fmt),
	NBin   = <<Bin/binary, Ty:8, Tm:32, FmtBin/binary>>,
	get_guild_event_bin(NBin, Rest);

get_guild_event_bin(Bin, []) ->
	Bin.

%% pt 19010
get_guild_info_bin(Guild) ->
	GuildID   = Guild#guild_info.guild_id,
	GuildName = pt:write_string(Guild#guild_info.guild_name),
	PresID    = Guild#guild_info.president,
	PresName  = pt:write_string(Guild#guild_info.president_name),
	Level     = Guild#guild_info.level,
	Members   = guild_man:get_guild_member_num(GuildID),
	MemberMax = Guild#guild_info.max_member,
	CTime     = Guild#guild_info.create_time,
	DTime     = Guild#guild_info.dismiss_time,
	Exp       = Guild#guild_info.exp,

	Manifesto = pt:write_string(Guild#guild_info.manifesto),
	?INFO(pt_19, "Manifesto = ~w", [Manifesto]),
	 
	Bin = <<GuildID:16, GuildName/binary, PresID:32, PresName/binary, Level:16,
	Members:16, MemberMax:16, CTime:32, DTime:32, Exp:32, Manifesto/binary>>,
	
	?INFO(pt_19, "Bin = ~w", [Bin]),
	Bin.
	
%% pt 19011
get_guild_member_info(_Guild, GuildMem) ->
	Rank     = GuildMem#guild_member.rank,
	Exp      = GuildMem#guild_member.exp,
	TotalExp = GuildMem#guild_member.total_exp,
	JoinTime = GuildMem#guild_member.join_time,
	Welfare  = 0,

	<<Rank:8, Exp:32, TotalExp:32, JoinTime:32, Welfare:8>>.
	

%% pt 19013 get guild list
get_guild_list_bin(Page, GuildList, AppList) ->
	get_guild_list_bin(<<>>, GuildList, (Page - 1) * 10 + 1, AppList).

get_guild_list_bin(Bin, [Guild | Rest], Index, AppList) ->
	GuildID   = Guild#guild_info.guild_id,
	GuildName = pt:write_string(Guild#guild_info.guild_name),
	Level     = Guild#guild_info.level,
	VIP       = 1,
	PreName   = pt:write_string(Guild#guild_info.president_name),
	TotalExp  = Guild#guild_info.exp,
	Member    = length(Guild#guild_info.members),
	MemberMax = Guild#guild_info.max_member,
	Applied   = 
		%% AppList = [{GuildID, AppliedTime}]
		case lists:keysearch(GuildID, 1, AppList) of
			{value, _} -> 1;
			false -> 0
		end,
	?INFO(pt_19, "applied  = ~w", [Applied]),
	
	NBin = 
		<<Bin/binary, GuildID:16, Index:16, GuildName/binary, Level:16, VIP:8,
			PreName/binary, TotalExp:32, Member:16, MemberMax:16, Applied:8>>,

	get_guild_list_bin(NBin, Rest, Index + 1, AppList);

get_guild_list_bin(Bin, [], _Index, _AppList) -> Bin.

%% pt 19012 get apply list
get_apply_list_bin(GuildID, List) ->
	get_apply_list_bin(<<>>, GuildID, List).

get_apply_list_bin(Bin, GuildID, [App | Rest]) ->
	?INFO(pt_19, "App = ~w", [App]),
	ID     = App#guild_apply.id,
	Name   = pt:write_string(App#guild_apply.name),
	Rec    = role_base:get_main_role_rec(ID),
	Power  = role_base:calc_combat_point(Rec),
	Level  = Rec#role.gd_roleLevel,
	Job    = Rec#role.gd_careerID,
	Time   = 
		case ets:lookup(?ETS_GUILD_APPLY, ID) of
			[#guild_apply {apply_list = AppList}] ->
				case lists:keysearch(GuildID, 1, AppList) of
					{value, {_, AppTime}} -> 
						AppTime;
					false -> 
						?ERR(guild, "can not find apply time"),
						util:unixtime()
				end;
			_ ->
				?ERR(guild, "can not find apply time"),
				util:unixtime()
		end,
	AppBin = <<ID:32, Name/binary, Level:16, Job:8, Power:32, Time:32>>, 
	get_apply_list_bin(<<Bin/binary, AppBin/binary>>, GuildID, Rest);
	
get_apply_list_bin(Bin, _, []) -> Bin.

%% pt 19028 get member list
get_mem_list_bin(MemList) ->
	get_mem_list_bin(<<>>, MemList).

get_mem_list_bin(Bin, [Mem | Rest]) ->
	ID     = Mem#guild_member.id,
	Name   = pt:write_string(Mem#guild_member.name),
	
	?INFO(guild, "ID = ~w", [ID]),

	Rec    = role_base:get_main_role_rec(ID),
	Power  = role_base:calc_combat_point(Rec),
	Job    = Rec#role.gd_careerID,
	Level  = Rec#role.gd_roleLevel,
	Rank   = Mem#guild_member.rank,
	Exp    = Mem#guild_member.exp,
	TExp   = Mem#guild_member.total_exp,
	State  = Mem#guild_member.leave_time,
	
	?INFO(guild, "Level = ~w, Power = ~w", [Level, Power]),
	MemBin = <<ID:32, Name/binary, Job:8, Level:16, Rank:8, Exp:32, TExp:32, Power:32, State:32>>,
	get_mem_list_bin(<<Bin/binary, MemBin/binary>>, Rest);
	
	
get_mem_list_bin(Bin, []) -> Bin.






